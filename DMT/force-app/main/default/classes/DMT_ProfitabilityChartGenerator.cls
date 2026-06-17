public with sharing class DMT_ProfitabilityChartGenerator {

    /**
     * Clase de soporte para estructurar los datos del gráfico
     */
    public class ChartRequest {
        public List<Integer> years;
        public List<Decimal> eadEcoData;
        public List<Decimal> eadRegData;
        public List<Decimal> rorcData;
        public List<Decimal> raroecData;
    }

    /**
     * Construye el ChartRequest a partir del nodo JSON "profitability".
     */
    public static ChartRequest buildChartRequest(Map<String, Object> profitabilityNode) {
        // ... (El código de este método se mantiene EXACTAMENTE IGUAL) ...
        ChartRequest req = new ChartRequest();
        req.years = new List<Integer>();
        req.eadEcoData = new List<Decimal>();
        req.eadRegData = new List<Decimal>();
        req.rorcData = new List<Decimal>();
        req.raroecData = new List<Decimal>();

        if (profitabilityNode == null || !profitabilityNode.containsKey('results')) {
            return req;
        }

        List<Object> resultsList = (List<Object>) profitabilityNode.get('results');
        if (resultsList == null || resultsList.isEmpty()) {
            return req;
        }

        Map<Integer, Decimal> eadEcoMap = new Map<Integer, Decimal>();
        Map<Integer, Decimal> eadRegMap = new Map<Integer, Decimal>();
        Map<Integer, Decimal> rorcSumMap = new Map<Integer, Decimal>();
        Map<Integer, Decimal> raroecSumMap = new Map<Integer, Decimal>();
        Map<Integer, Integer> countMap = new Map<Integer, Integer>();

        try {
            for (Object resObj : resultsList) {
                Map<String, Object> resultItem = (Map<String, Object>) resObj;
                List<Object> totalYears = (List<Object>) resultItem.get('totalYears');

                if (totalYears != null) {
                    for (Object yearObj : totalYears) {
                        Map<String, Object> yearData = (Map<String, Object>) yearObj;
                        Integer y = Integer.valueOf(yearData.get('year'));

                        Decimal eadEco = getDecimal(yearData.get('eadEcoYearly'));
                        Decimal eadReg = getDecimal(yearData.get('eadRegYearly'));
                        Decimal rorc = getDecimal(yearData.get('rorcYearly'));
                        Decimal raroec = getDecimal(yearData.get('raroecYearly'));

                        if (!eadEcoMap.containsKey(y)) {
                            eadEcoMap.put(y, 0);
                            eadRegMap.put(y, 0);
                            rorcSumMap.put(y, 0);
                            raroecSumMap.put(y, 0);
                            countMap.put(y, 0);
                        }
                        
                        // Conservamos el máximo por año para EAD ECO/REG.
                        eadEcoMap.put(y, Math.max(eadEcoMap.get(y), eadEco));
                        eadRegMap.put(y, Math.max(eadRegMap.get(y), eadReg));
                        
                        // Los porcentajes sí podemos promediarlos
                        rorcSumMap.put(y, rorcSumMap.get(y) + rorc);
                        raroecSumMap.put(y, raroecSumMap.get(y) + raroec);
                        countMap.put(y, countMap.get(y) + 1);
                    }
                }
            }

            List<Integer> sortedYears = new List<Integer>(eadEcoMap.keySet());
            sortedYears.sort();

            if (sortedYears.isEmpty()) {
                return req;
            }

            Integer startYear = sortedYears[0];
            Integer endYear = sortedYears[sortedYears.size() - 1];

            for (Integer y = startYear; y <= endYear; y++) {
                req.years.add(y);
                req.eadEcoData.add(eadEcoMap.containsKey(y) ? eadEcoMap.get(y) : 0);
                req.eadRegData.add(eadRegMap.containsKey(y) ? eadRegMap.get(y) : 0);
                
                Integer c = countMap.containsKey(y) ? countMap.get(y) : 0;
                req.rorcData.add(c > 0 ? rorcSumMap.get(y) / c : 0);
                req.raroecData.add(c > 0 ? raroecSumMap.get(y) / c : 0);
            }
        } catch (Exception e) {
            System.debug('Error in DMT_ProfitabilityChartGenerator buildChartRequest: ' + e.getMessage());
        }

        return req;
    }

    /**
     * Genera el HTML mixto combinando HTML <div> para las barras y líneas conectoras.
     * Compatible con Blob.toPdf() (Flying Saucer / OpenPDF):
     */
    public static String getMixedChartHtml(ChartRequest req) {
        return getMixedChartHtml(req, 800.0);
    }

    /**
     * Sobrecarga que permite especificar el ancho base del gráfico.
     * @param req Datos del gráfico
     * @param baseWidth Ancho base en px (ej. 750 para A4 con márgenes estándar)
     */
    public static String getMixedChartHtml(ChartRequest req, Decimal baseWidth) {
        if (req == null || req.years == null || req.years.isEmpty()) {
            return '';
        }

        // Ajustado para aprovechar el ancho de un A4 estándar con márgenes.
        if (baseWidth == null || baseWidth <= 0) {
            baseWidth = 700.0; // Ancho por defecto ampliado
        }
        if (baseWidth > 800.0) {
            baseWidth = 800.0; // Límite máximo ampliado para evitar recortes en PDF
        }

        // ---CÁLCULO DE ESCALAS DINÁMICAS ---
        Decimal eadMax = 0;
        Decimal pctMax = 0;
        Decimal pctMin = 0;

        for (Integer i = 0; i < req.years.size(); i++) {
            Decimal eadEcoM = (req.eadEcoData[i] / 1000000.0).setScale(2, RoundingMode.HALF_UP);
            Decimal eadRegM = (req.eadRegData[i] / 1000000.0).setScale(2, RoundingMode.HALF_UP);
            if (eadEcoM > eadMax) eadMax = eadEcoM;
            if (eadRegM > eadMax) eadMax = eadRegM;

            Decimal rorcPct = (req.rorcData[i] * 100.0).setScale(2, RoundingMode.HALF_UP);
            Decimal raroecPct = (req.raroecData[i] * 100.0).setScale(2, RoundingMode.HALF_UP);
            if (rorcPct > pctMax) pctMax = rorcPct;
            if (rorcPct < pctMin) pctMin = rorcPct;
            if (raroecPct > pctMax) pctMax = raroecPct;
            if (raroecPct < pctMin) pctMin = raroecPct;
        }

        // Definimos un objetivo base para que el algoritmo busque la proporción ideal
        Integer targetTicks = 10;

        // --- CÁLCULO DE ESCALA IZQUIERDA DINÁMICA (EAD) ---
        Decimal leftStep = getNiceStep(eadMax, targetTicks);
        Decimal leftScaleMax = Math.ceil(eadMax / leftStep) * leftStep;
        if (leftScaleMax <= 0) leftScaleMax = leftStep; // Fallback por si eadMax es 0
        
        Integer leftAxisSteps = Integer.valueOf(leftScaleMax / leftStep);
        Integer leftDecimals = (leftStep - Math.floor(leftStep) > 0) ? 1 : 0;

        // --- CÁLCULO DE ESCALA DERECHA DINÁMICA (PORCENTAJES) ---
        Decimal maxPctRange = Math.max(Math.abs(pctMax), Math.abs(pctMin));
        Decimal pctStep = getNiceStep(maxPctRange, targetTicks);
        Decimal rightScaleMax = Math.ceil(pctMax / pctStep) * pctStep;
        Decimal rightScaleMin = Math.floor(pctMin / pctStep) * pctStep;
        
        if (rightScaleMax == rightScaleMin) {
            rightScaleMax += pctStep;
            rightScaleMin -= pctStep;
        }

        Decimal pctRange = rightScaleMax - rightScaleMin;
        if (pctRange <= 0) pctRange = pctStep; // Fallback
        
        Integer rightAxisSteps = Integer.valueOf(pctRange / pctStep);
        Integer rightDecimals = (pctStep - Math.floor(pctStep) > 0) ? 1 : 0;
        // --- COLORES CORPORATIVOS ---
        String colorEadEco = '#8eb4d3';
        String colorEadReg = '#aae2ff';
        String colorRorc   = '#ffc188';
        String colorRaroec = '#a0e89b';
        Decimal effectiveWidth = baseWidth * 0.80;

        // Contenedor principal.
        String html = '<div style="width:' + formatSafe(effectiveWidth, 0) + 'px; margin:0 auto; padding:5px 0; font-family:Arial,sans-serif; color:#5f6b7a; background-color:#ffffff; border:none;">';
        // Leyenda
        html += '<div style="text-align:center; font-size:8px; margin-bottom:15px; color:#6f7d8b;">';
        html += '<span style="display:inline-block; margin-right:20px;"><span style="display:inline-block; width:10px; height:8px; background-color:' + colorEadEco + '; margin-right:5px; vertical-align:middle; border:1px solid #66829a;"></span>EAD ECO (Mill €)</span>';
        html += '<span style="display:inline-block; margin-right:20px;"><span style="display:inline-block; width:10px; height:8px; background-color:' + colorEadReg + '; margin-right:5px; vertical-align:middle; border:1px solid #7bc6ff;"></span>EAD REG (Mill €)</span>';
        html += '<span style="display:inline-block; margin-right:20px;"><span style="display:inline-block; width:10px; height:7px; background-color:#ffffff; margin-right:5px; vertical-align:middle; border:2px solid ' + colorRorc + ';"></span>RORC (%)</span>';
        html += '<span style="display:inline-block;"><span style="display:inline-block; width:10px; height:7px; background-color:#ffffff; margin-right:5px; vertical-align:middle; border:2px solid ' + colorRaroec + ';"></span>RAROEC (%)</span>';
        html += '</div>';

        // Zona gráfica: dimensiones calculadas en función del ancho base.
        Decimal graphWidthPx = effectiveWidth;
        Decimal graphHeightPx = effectiveWidth * 0.45;


        // Ejes proporcionales al ancho base.
        Decimal leftAxisWidthPx = effectiveWidth * 0.06;
        Decimal rightAxisWidthPx = effectiveWidth * 0.08;
        Decimal plotInsetPx = effectiveWidth * 0.01;
        Decimal plotLeftPx = leftAxisWidthPx + plotInsetPx;
        Decimal plotRightPx = rightAxisWidthPx + plotInsetPx;
        Decimal plotWidthPx = graphWidthPx - plotLeftPx - plotRightPx;
        Decimal plotHeightPx = graphHeightPx;

        // Contenedor único del gráfico.
        Decimal containerHeightPx = graphHeightPx + 40.0;
        html += '<div style="position:relative; width:' + formatSafe(graphWidthPx, 0) + 'px; height:' + formatSafe(containerHeightPx, 0) + 'px; margin:0 auto 15px auto;">';

        // Declaramos una variable global para la altura (eje Y) de todos los textos inferiores
        Decimal topLabelPx = plotHeightPx + 14.0;


       // --- DIBUJAR CUADRÍCULA Y EJE IZQUIERDO---
        for (Integer i = 0; i <= leftAxisSteps; i++) {
            Decimal topPx = (plotHeightPx / leftAxisSteps) * i;
            Decimal leftVal = leftScaleMax - (i * leftStep);

            // Etiqueta izquierda (EAD)
            html += '<div style="position:absolute; left:0; top:' + formatSafe(topPx, 2) + 'px; margin-top:-7px; width:' + formatSafe(leftAxisWidthPx, 0) + 'px; text-align:right; font-size:10px; color:#7a8795;">' + formatSafe(leftVal, leftDecimals) + '</div>';

            // Línea horizontal de fondo (Se guía únicamente por los 10 saltos del eje izquierdo)
            String borderStyle = (i == leftAxisSteps) ? 'border-top:1px solid #d3dde8;' : 'border-top:1px solid #edf2f7;';
            html += '<div style="position:absolute; left:' + formatSafe(plotLeftPx, 0) + 'px; width:' + formatSafe(plotWidthPx, 0) + 'px; top:' + formatSafe(topPx, 2) + 'px; height:1px; ' + borderStyle + ' z-index:0;"></div>';
        }

        // --- DIBUJAR EJE DERECHO INDEPENDIENTE---
        // Las etiquetas derechas se colocan en su posición proporcional sin dibujar líneas grises
        for (Integer i = 0; i <= rightAxisSteps; i++) {
            Decimal rightVal = rightScaleMax - (i * pctStep);
            
            // Calculamos a qué altura exacta debe ir esta etiqueta en base a la escala de porcentajes
            Decimal topPx = plotHeightPx - (((rightVal - rightScaleMin) / pctRange) * plotHeightPx);

            // Etiqueta derecha (Porcentajes)
            html += '<div style="position:absolute; right:0; top:' + formatSafe(topPx, 2) + 'px; margin-top:-7px; width:' + formatSafe(rightAxisWidthPx, 0) + 'px; text-align:left; font-size:10px; color:#7a8795; white-space:nowrap;">' + formatSafe(rightVal, rightDecimals) + ' %</div>';
        }

        Integer numYears = req.years.size();
        Integer numSlots = Math.max(numYears, 3);

        // ---  LÍNEAS VERTICALES DE LA CUADRÍCULA ---
        String verticalGridHtml = '';
        Decimal verticalStepPx = plotWidthPx / numSlots;

        for (Integer j = 0; j <= numSlots; j++) {
            Decimal xGridPx = plotLeftPx + (j * verticalStepPx);
            String vBorderColor = (j == 0 || j == numSlots) ? '#d3dde8' : '#edf2f7';           
            verticalGridHtml += '<div style="position:absolute; left:' + formatSafe(xGridPx, 2) + 'px; top:0px; height:' + formatSafe(plotHeightPx, 0) + 'px; border-left:1px solid ' + vBorderColor + '; z-index:1;"></div>';
        }

        html += verticalGridHtml;
        // ------------------------------------------------

        //Padding interno del plot
        Decimal horizontalPaddingPx = plotWidthPx * 0.03; 
        Decimal usableWidthPx = plotWidthPx - (horizontalPaddingPx * 2.0);

        if (usableWidthPx <= 0) {
            usableWidthPx = plotWidthPx;
            horizontalPaddingPx = 0;
        }

        Decimal blockWidthPx = usableWidthPx / numSlots;

        // --- EQUILIBRIO DE BARRAS Y LÍNEAS ---
        Decimal groupWidthPx = blockWidthPx * 0.80;
        Decimal barGapPx = 10.0;
        Decimal barWidthPx = (groupWidthPx - barGapPx) / 2.0;
        if (barWidthPx < 15.0) { barWidthPx = 15.0; }

        Decimal minVisibleBarHeightPx = 3.0;        
        String barsHtml = '';
        String dotsHtml = '';
        String linesHtml = '';
        String labelsHtml = '';

        // Listas para almacenar posiciones absolutas de los puntos y trazar líneas.
        List<Decimal> rorcXPoints = new List<Decimal>();
        List<Decimal> rorcYPoints = new List<Decimal>();
        List<Decimal> raroecXPoints = new List<Decimal>();
        List<Decimal> raroecYPoints = new List<Decimal>();

        for (Integer i = 0; i < numSlots; i++) {
            // Coordenada local dentro del plot.
            Decimal centerLocalPx = horizontalPaddingPx + (i * blockWidthPx) + (blockWidthPx / 2.0);

            // Coordenada absoluta dentro del contenedor principal del gráfico.
            Decimal centerPx = plotLeftPx + centerLocalPx;
            

            if (i < numYears) {
                Integer y = req.years[i];

                Decimal eadEcoM = (req.eadEcoData[i] / 1000000.0).setScale(2, RoundingMode.HALF_UP);
                Decimal eadRegM = (req.eadRegData[i] / 1000000.0).setScale(2, RoundingMode.HALF_UP);

                Decimal heightEcoPx = (eadEcoM / leftScaleMax) * plotHeightPx;
                if (eadEcoM > 0 && heightEcoPx < minVisibleBarHeightPx) {
                    heightEcoPx = minVisibleBarHeightPx;
                }
                Decimal yEcoPx = plotHeightPx - heightEcoPx;

                Decimal heightRegPx = (eadRegM / leftScaleMax) * plotHeightPx;
                if (eadRegM > 0 && heightRegPx < minVisibleBarHeightPx) {
                    heightRegPx = minVisibleBarHeightPx;
                }
                Decimal yRegPx = plotHeightPx - heightRegPx;

                // Barras centradas en el slot: EAD ECO a la izquierda, EAD REG a la derecha.
                Decimal xEcoPx = centerPx - barWidthPx - (barGapPx / 2.0);
                Decimal xRegPx = centerPx + (barGapPx / 2.0);

                // Barras directamente sobre el contenedor principal.
                barsHtml += '<div style="position:absolute; left:' + formatSafe(xEcoPx, 0) + 'px; top:' + formatSafe(yEcoPx, 0) + 'px; width:' + formatSafe(barWidthPx, 0) + 'px; height:' + formatSafe(heightEcoPx, 0) + 'px; background-color:' + colorEadEco + '; border:1px solid #66829a; border-bottom:none; z-index:2;"></div>';
                barsHtml += '<div style="position:absolute; left:' + formatSafe(xRegPx, 0) + 'px; top:' + formatSafe(yRegPx, 0) + 'px; width:' + formatSafe(barWidthPx, 0) + 'px; height:' + formatSafe(heightRegPx, 0) + 'px; background-color:' + colorEadReg + '; border:1px solid #7bc6ff; border-bottom:none; z-index:2;"></div>';

                Decimal rorcPct = (req.rorcData[i] * 100.0).setScale(2, RoundingMode.HALF_UP);
                Decimal raroecPct = (req.raroecData[i] * 100.0).setScale(2, RoundingMode.HALF_UP);

                Decimal yRorcPx = plotHeightPx - (((rorcPct - rightScaleMin) / pctRange) * plotHeightPx);
                Decimal yRaroecPx = plotHeightPx - (((raroecPct - rightScaleMin) / pctRange) * plotHeightPx);

                rorcXPoints.add(centerPx);
                rorcYPoints.add(yRorcPx);
                raroecXPoints.add(centerPx);
                raroecYPoints.add(yRaroecPx);

                // Círculos
                dotsHtml += '<img src="/resource/DMT_ProfitabilityCircleOrange" style="position:absolute; left:' + formatSafe(centerPx, 0) + 'px; top:' + formatSafe(yRorcPx, 0) + 'px; margin-left:-3px; margin-top:-3px; width:6px; height:6px; z-index:10;" />';
                dotsHtml += '<img src="/resource/DMT_ProfitabilityCircleGreen" style="position:absolute; left:' + formatSafe(centerPx, 0) + 'px; top:' + formatSafe(yRaroecPx, 0) + 'px; margin-left:-3px; margin-top:-3px; width:6px; height:6px; z-index:10;" />';

                Decimal xLabelLeftPx = centerPx - 20.0;
                labelsHtml += '<div style="position:absolute; left:' + formatSafe(xLabelLeftPx, 0) + 'px; top:' + formatSafe(topLabelPx, 0) + 'px; width:40px; text-align:center; font-size:10px; color:#6f7d8b; z-index:25;">' + y + '</div>';
            } else {

                Integer nextYear = req.years[numYears - 1] + (i - numYears + 1);
                Decimal xLabelLeftPx = centerPx - 20.0;
                labelsHtml += '<div style="position:absolute; left:' + formatSafe(xLabelLeftPx, 0) + 'px; top:' + formatSafe(topLabelPx, 0) + 'px; width:40px; text-align:center; font-size:10px; color:#6f7d8b; z-index:25;">' + nextYear + '</div>';
            }
        }

        // Dibujar líneas conectoras entre puntos consecutivos (RORC y RAROEC).
        Decimal circleRadius = 3.0;
        for (Integer i = 0; i < rorcXPoints.size() - 1; i++) {
            Decimal x1 = rorcXPoints[i];
            Decimal y1 = rorcYPoints[i];
            Decimal x2 = rorcXPoints[i + 1];
            Decimal y2 = rorcYPoints[i + 1];
            Decimal dxR = x2 - x1;
            Decimal dyR = y2 - y1;
            Decimal lenR = Math.sqrt(dxR * dxR + dyR * dyR);
            if (lenR > 0) {
                Decimal uxR = dxR / lenR;
                Decimal uyR = dyR / lenR;
                linesHtml += buildConnectorSegments(x1 + uxR * circleRadius, y1 + uyR * circleRadius, x2 - uxR * circleRadius, y2 - uyR * circleRadius, colorRorc);
            }

            Decimal ax1 = raroecXPoints[i];
            Decimal ay1 = raroecYPoints[i];
            Decimal ax2 = raroecXPoints[i + 1];
            Decimal ay2 = raroecYPoints[i + 1];
            Decimal dxA = ax2 - ax1;
            Decimal dyA = ay2 - ay1;
            Decimal lenA = Math.sqrt(dxA * dxA + dyA * dyA);
            if (lenA > 0) {
                Decimal uxA = dxA / lenA;
                Decimal uyA = dyA / lenA;
                linesHtml += buildConnectorSegments(ax1 + uxA * circleRadius, ay1 + uyA * circleRadius, ax2 - uxA * circleRadius, ay2 - uyA * circleRadius, colorRaroec);
            }
        }

        html += barsHtml;
        html += linesHtml;
        html += dotsHtml;
        html += labelsHtml;

        // --- TEXTOS LATERALES USANDO IMÁGENES---
        Decimal midYPx = plotHeightPx / 2.0;
        Decimal imgTopPx = midYPx - 60.0;
        // Eje Izquierdo
        html += '<img src="/resource/DMT_LabelEAD" style="position:absolute; left:-35px; top:' + formatSafe(imgTopPx, 0) + 'px; height:120px; z-index:25;" />';
        // Eje Derecho
        html += '<img src="/resource/DMT_LabelPct" style="position:absolute; right:-40px; top:' + formatSafe(imgTopPx, 0) + 'px; height:120px; z-index:25;" />';
        html += '</div></div>';

        return html;
    }

    /**
     * Helper seguro para parsear JSON
     */
    private static Decimal getDecimal(Object val) {
        if (val == null) return 0.0;
        if (val instanceof Decimal) return (Decimal) val;
        if (val instanceof Integer) return (Decimal) ((Integer) val);
        if (val instanceof Double) return (Decimal) ((Double) val);
        try {
            return Decimal.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return 0.0;
        }
    }

    /**
     * Helper crucial para forzar punto en los decimales en HTML/CSS
     * Permite elegir la cantidad de decimales (scale).
     */
    private static String formatSafe(Decimal val, Integer scale) {
        if (val == null) return '0';
        return String.valueOf(val.setScale(scale, RoundingMode.HALF_UP)).replace(',', '.');
    }

    /**
     * Construye una línea conectora como varios segmentos HTML absolutos.
     * No usa transform ni SVG para maximizar compatibilidad en PDF.
     */
    private static String buildConnectorSegments(Decimal x1, Decimal y1, Decimal x2, Decimal y2, String color) {
        Decimal dx = x2 - x1;
        Decimal dy = y2 - y1;
        Decimal distance = Math.sqrt(dx * dx + dy * dy);

        if (distance <= 0) {
            return '';
        }

        Integer steps = Integer.valueOf(Math.ceil(distance * 2.5));
        if (steps < 1) {
            steps = 1;
        }

        Decimal stepX = dx / steps;
        Decimal stepY = dy / steps;
        Decimal dotSizePx = 1.2;
        Decimal dotOffsetPx = dotSizePx / 2.0;
        String html = '';

        for (Integer i = 0; i <= steps; i++) {
            Decimal px = x1 + (stepX * i);
            Decimal py = y1 + (stepY * i);
            html += '<div style="position:absolute; left:' + formatSafe(px - dotOffsetPx, 2) + 'px; top:' + formatSafe(py - dotOffsetPx, 2) + 'px; width:' + formatSafe(dotSizePx, 2) + 'px; height:' + formatSafe(dotSizePx, 2) + 'px; background-color:' + color + '; border-radius:2px; z-index:5;"></div>';
        }

        return html;
    }

    /**
     * ALGORITMO "NICE STEP": 
     * Encuentra el salto más redondo y limpio (1, 2, 2.5, 5, 10, 50, 100...) 
     * en función de la escala máxima provista.
     */
    private static Decimal getNiceStep(Decimal maxUnits, Integer targetTicks) {
        if (maxUnits <= 0) return 1.0;
        
        Decimal rawStep = maxUnits / targetTicks;
        Decimal power10 = 1.0;
        Decimal normalized = rawStep;
        
        // Extraer la potencia de 10
        if (normalized >= 1.0) {
            while (normalized >= 10.0) {
                normalized /= 10.0;
                power10 *= 10.0;
            }
        } else {
            while (normalized > 0 && normalized < 1.0) {
                normalized *= 10.0;
                power10 /= 10.0;
            }
        }
        
        // Encontrar la base redonda más cercana
        Decimal niceBase;
        if (normalized <= 1.0) niceBase = 1.0;
        else if (normalized <= 2.0) niceBase = 2.0;
        else if (normalized <= 2.5) niceBase = 2.5; // Muy útil para saltos de 0.5 o 25
        else if (normalized <= 5.0) niceBase = 5.0;
        else niceBase = 10.0;
        
        return niceBase * power10;
    }
}