public with sharing class DMT_ChartHtmlGenerator {

    /**
     * Clase de soporte para pasar los datos al generador
     */
    public class ChartRequest {
        public List<Object> labels;
        public List<Object> targets;
        public List<Object> limitLights;
        public List<Object> dataDraw;
        public List<Object> dataUndrawnCommitted;
        public List<Object> dataUndrawnUncommitted;
        public List<Object> dataPendingAuthorized;
        public List<Object> dataNewOpportunity;
        public List<Object> currencies;
        public List<Object> conditions;
    }

    /**
     * Construye una lista de ChartRequest a partir del LineDataWrapper.
     * Cada feature con consumptionLimits válidos genera un ChartRequest
     * que puede pasarse directamente a getHorizontalBarChartHtml.
     */
    public static List<ChartRequest> buildChartRequests(DMT_ViewController.LineDataWrapper data) {
        List<ChartRequest> chartRequests = new List<ChartRequest>();
        if (data == null || data.featuresList.isEmpty()) {
            return chartRequests;
        }
        try {
            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                List<Map<String, Object>> consumptionLimitsList = DMT_FormattingUtils.getListMap(feature, 'consumptionLimits');
                if (consumptionLimitsList.isEmpty() || i == 0) {
                    continue;
                }

                ChartRequest req = new ChartRequest();
                req.labels = new List<Object>();
                req.targets = new List<Object>();
                req.limitLights = new List<Object>();
                req.dataDraw = new List<Object>();
                req.dataUndrawnCommitted = new List<Object>();
                req.dataUndrawnUncommitted = new List<Object>();
                req.dataPendingAuthorized = new List<Object>();
                req.dataNewOpportunity = new List<Object>();
                req.currencies = new List<Object>();
                req.conditions = new List<Object>();

                Boolean hasValidData = false;
                for (Map<String, Object> consumtionLimits : consumptionLimitsList) {
                    Map<String, Object> amount = (Map<String, Object>) consumtionLimits.get('amount');
                    if (amount != null && !amount.isEmpty()) {
                        hasValidData = true;
                        req.conditions.add(consumtionLimits.get('conditionDesc'));
                        req.currencies.add(consumtionLimits.get('currencyId'));
                        req.labels.add(consumtionLimits.get('limitDesc'));
                        req.limitLights.add(consumtionLimits.get('stateName'));
                        req.targets.add(DMT_FormattingUtils.convertValue(amount.get('currentApprovedAmount')));
                        req.dataDraw.add(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')));
                        req.dataUndrawnCommitted.add(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')));
                        req.dataUndrawnUncommitted.add(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')));
                        req.dataPendingAuthorized.add(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')));
                        req.dataNewOpportunity.add(DMT_FormattingUtils.convertValue(amount.get('notSignedTrConsumptionAmount')));
                    }
                }
                if (hasValidData) {
                    chartRequests.add(req);
                }
            }
        } catch (Exception e) {
            System.debug('Error in DMT_ChartHtmlGenerator buildChartRequests, ' + e.getMessage() + ' ' + e.getLineNumber());
        }
        return chartRequests;
    }

    /**
     * Genera el HTML que representa visualmente el gráfico de barras horizontales
     */
    public static String getHorizontalBarChartHtml(ChartRequest req) {
        if (req == null || req.labels == null) {
            return '';
        }

        // Colores corporativos
        String colorDrawn = '#043263';
        String colorUndCom = '#1464a5';
        String colorUndUnc = '#2496ea';
        String colorPenAut = '#2dcccc';
        String colorNewOpp = '#8f8f8f';
        String colorLimit  = '#d90000';

        // Offset de la leyenda para alinear con inicio de barras (Blob.toPdf):
        // semáforo col (28px) + label col (180px) + paddings = ~208px
        // No se usa colgroup (no soportado por Blob.toPdf); anchos fijados en primera fila
        Integer barStartOffsetPx = 208;

        // Leyenda de colores centrada en la tabla con Drawn alineado al inicio de barras
        String html = '<table style="width:100%; border-collapse:collapse; font-family:Arial,sans-serif; margin-bottom:14px; page-break-inside:avoid;">';
        // Primera fila define anchos de columna (requerido por Blob.toPdf sin colgroup)
        html += '<tr>'
            + '<td style="width:28px; padding:0 0 4px 0;"></td>'
            + '<td style="width:180px; padding:0 0 4px 0;"></td>'
            + '<td style="padding:0 0 4px 0; vertical-align:middle;">'
            + '<table style="border-collapse:collapse;"><tr>'
            + '<td style="padding:1px 3px 1px 0; font-size:8px; line-height:11px; vertical-align:middle; white-space:nowrap;">'
            + '<span style="display:inline-block; width:18px; height:9px; background-color:' + colorDrawn + '; vertical-align:middle; margin-right:3px;"></span>Drawn</td>'
            + '<td style="padding:1px 3px 1px 0; font-size:8px; line-height:11px; vertical-align:middle; white-space:nowrap;">'
            + '<span style="display:inline-block; width:18px; height:9px; background-color:' + colorUndCom + '; vertical-align:middle; margin-right:3px;"></span>Undrawn Committed</td>'
            + '<td style="padding:1px 3px 1px 0; font-size:8px; line-height:11px; vertical-align:middle; white-space:nowrap;">'
            + '<span style="display:inline-block; width:18px; height:9px; background-color:' + colorUndUnc + '; vertical-align:middle; margin-right:3px;"></span>Undrawn Uncommitted</td>'
            + '<td style="padding:1px 3px 1px 0; font-size:8px; line-height:11px; vertical-align:middle; white-space:nowrap;">'
            + '<span style="display:inline-block; width:18px; height:9px; background-color:' + colorPenAut + '; vertical-align:middle; margin-right:3px;"></span>Pending Authorized</td>'
            + '<td style="padding:1px 0 1px 0; font-size:8px; line-height:11px; vertical-align:middle; white-space:nowrap;">'
            + '<span style="display:inline-block; width:18px; height:9px; background-color:' + colorNewOpp + '; vertical-align:middle; margin-right:3px;"></span>New Opportunity</td>'
            + '</tr></table>'
            + '</td></tr>';

        // Altura de barra: 30% más alta si solo hay una barra
        Integer barHeight = req.labels.size() == 1 ? 78 : 60;

        Decimal maxTotalGlobal = 0;

        // Primera pasada: obtener el Total Amount más grande (suma de segmentos)
        for (Integer i = 0; i < req.labels.size(); i++) {
            Decimal d1 = i < req.dataDraw.size() ? DMT_FormattingUtils.convertValue(req.dataDraw[i]) : 0;
            Decimal d2 = i < req.dataUndrawnCommitted.size() ? DMT_FormattingUtils.convertValue(req.dataUndrawnCommitted[i]) : 0;
            Decimal d3 = i < req.dataUndrawnUncommitted.size() ? DMT_FormattingUtils.convertValue(req.dataUndrawnUncommitted[i]) : 0;
            Decimal d4 = i < req.dataPendingAuthorized.size() ? DMT_FormattingUtils.convertValue(req.dataPendingAuthorized[i]) : 0;
            Decimal d5 = i < req.dataNewOpportunity.size() ? DMT_FormattingUtils.convertValue(req.dataNewOpportunity[i]) : 0;
            Decimal totalBars = d1 + d2 + d3 + d4 + d5;
            if (totalBars > maxTotalGlobal) {
                maxTotalGlobal = totalBars;
            }
        }

        String axisSuffix;
        Decimal divisor;
        Decimal thousandUnit = 10 * 10 * 10;
        Decimal millionUnit = thousandUnit * thousandUnit;
        if (maxTotalGlobal > millionUnit || maxTotalGlobal == millionUnit) {
            divisor = millionUnit;
            axisSuffix = 'M';
        } else if (maxTotalGlobal > thousandUnit || maxTotalGlobal == thousandUnit) {
            divisor = thousandUnit;
            axisSuffix = 'K';
        } else {
            divisor = 1;
            axisSuffix = '';
        }

        // Si el mayor total es 6, el final de escala será 7 (siempre +1)
        Decimal axisMaxUnitsRaw = Math.ceil(maxTotalGlobal / divisor) + 1;
        if (axisMaxUnitsRaw < 1) {
            axisMaxUnitsRaw = 1;
        }

        // Paso redondeado (1/2/5 * 10^n) para etiquetas legibles.
        Decimal axisTickStep = getNiceStep(axisMaxUnitsRaw, 6);
        Decimal axisMaxUnitsRounded = Math.ceil(axisMaxUnitsRaw / axisTickStep) * axisTickStep;

        // Número de intervalos realmente renderizados en el eje
        Integer axisMaxTicks = (Integer) Math.max(1, Math.ceil(axisMaxUnitsRounded / axisTickStep));
        Decimal axisScaleMax = axisMaxUnitsRounded * divisor;
        if (axisScaleMax <= 0) {
            axisScaleMax = 1;
        }

        for (Integer i = 0; i < req.labels.size(); i++) {
            Decimal limitVal = i < req.targets.size() ? DMT_FormattingUtils.convertValue(req.targets[i]) : 0;
            Decimal d1 = i < req.dataDraw.size() ? DMT_FormattingUtils.convertValue(req.dataDraw[i]) : 0;
            Decimal d2 = i < req.dataUndrawnCommitted.size() ? DMT_FormattingUtils.convertValue(req.dataUndrawnCommitted[i]) : 0;
            Decimal d3 = i < req.dataUndrawnUncommitted.size() ? DMT_FormattingUtils.convertValue(req.dataUndrawnUncommitted[i]) : 0;
            Decimal d4 = i < req.dataPendingAuthorized.size() ? DMT_FormattingUtils.convertValue(req.dataPendingAuthorized[i]) : 0;
            Decimal d5 = i < req.dataNewOpportunity.size() ? DMT_FormattingUtils.convertValue(req.dataNewOpportunity[i]) : 0;

            String curr = i < req.currencies.size() ? String.valueOf(req.currencies[i]) : 'EUR';
            String state = i < req.limitLights.size() ? String.valueOf(req.limitLights[i]) : 'GRAY';

            Decimal totalBars = d1 + d2 + d3 + d4 + d5;
            Decimal maxScale = axisScaleMax;

            // Fila: Semáforo + Label + Barra
            html += '<tr style="page-break-inside:avoid;">'
                + '<td style="width:28px; padding:2px; text-align:center; vertical-align:middle;">'
                + renderTrafficLightSingleLocal(state)
                + '</td>'
                + '<td style="width:180px; padding:2px 4px; font-size:10px; vertical-align:middle; font-weight:bold;">'
                + String.valueOf(req.labels[i])
                + '</td>'
                + '<td style="padding:3px 2px; vertical-align:middle;">';

            // Barra construida con tabla de segmentos + marcador de límite (compatible con toPdf)
            Decimal limitPct = limitVal > 0 ? ((limitVal / maxScale) * 100) : 0;
            Decimal barsPct = totalBars > 0 ? ((totalBars / maxScale) * 100) : 0;

            // Tabla de segmentos de barras (sin position:absolute para compatibilidad toPdf)
            String limitText = DMT_FormattingUtils.formatDecimalAbbreviation(limitVal) + ' ' + curr;
            html += '<table style="width:100%; border-collapse:collapse; table-layout:fixed; page-break-inside:avoid;">';
            html += '<tr style="height:' + barHeight + 'px;">';
            // Segmentos de barra con marcador de límite integrado
            Decimal accPct = 0;
            Boolean limitRendered = false;
            List<Decimal> segVals = new List<Decimal>{d1, d2, d3, d4, d5};
            List<String> segColors = new List<String>{colorDrawn, colorUndCom, colorUndUnc, colorPenAut, colorNewOpp};
            Boolean needsLimitTextInEmpty = false;
            for (Integer s = 0; s < segVals.size(); s++) {
                Decimal segVal = segVals[s];
                if (segVal <= 0) { continue; }
                Decimal segPct = (segVal / maxScale) * 100;
                Decimal nextAccPct = accPct + segPct;
                // Si el límite cae dentro o en la frontera de este segmento, dividirlo
                if (!limitRendered && limitVal >= 0 && limitPct >= accPct && limitPct <= nextAccPct) {
                    Decimal beforePct = limitPct - accPct;
                    Decimal afterPct = nextAccPct - limitPct;
                    if (beforePct > 0) {
                        html += '<td style="width:' + beforePct.setScale(2) + '%; background-color:' + segColors[s] + '; height:' + barHeight + 'px; padding:0; border:none;"></td>';
                    }
                    // Marcador rojo del límite
                    html += '<td style="width:3px; background-color:' + colorLimit + '; height:' + barHeight + 'px; padding:0; border:none;"></td>';
                    if (afterPct > 0) {
                        // Texto del límite justo después del marcador rojo, dentro del segmento
                        html += '<td style="width:' + afterPct.setScale(2) + '%; background-color:' + segColors[s] + '; height:' + barHeight + 'px; padding:0; border:none; font-size:10px; font-weight:bold; color:' + colorLimit + '; vertical-align:middle; padding-left:3px; white-space:nowrap;">' + limitText + '</td>';
                    } else {
                        // Límite justo al final del segmento: texto irá en el espacio vacío siguiente
                        needsLimitTextInEmpty = true;
                    }
                    limitRendered = true;
                } else {
                    html += '<td style="width:' + segPct.setScale(2) + '%; background-color:' + segColors[s] + '; height:' + barHeight + 'px; padding:0; border:none;"></td>';
                }
                accPct = nextAccPct;
            }
            // Marcador de límite si cae fuera de las barras
            if (!limitRendered && limitVal >= 0 && limitPct >= barsPct) {
                Decimal gapPct = limitPct - barsPct;
                if (gapPct > 0) {
                    html += '<td style="width:' + gapPct.setScale(2) + '%; background-color:#FAFAFA; height:' + barHeight + 'px; padding:0; border:none;"></td>';
                }
                html += '<td style="width:3px; background-color:' + colorLimit + '; height:' + barHeight + 'px; padding:0; border:none;"></td>';
                html += '<td style="background-color:#FAFAFA; height:' + barHeight + 'px; padding:0 0 0 3px; border:none; font-size:10px; font-weight:bold; color:' + colorLimit + '; vertical-align:middle; white-space:nowrap;">' + limitText + '</td>';
                limitRendered = true;
                accPct = limitPct + 0.4;
            }
            // Espacio vacío restante
            Decimal emptyPct = 100 - accPct - (limitRendered ? 0.4 : 0);
            if (emptyPct > 0) {
                if (needsLimitTextInEmpty || (!limitRendered && limitVal >= 0)) {
                    // Texto del límite en el espacio vacío (cuando cae justo al final del segmento o no se renderizó)
                    html += '<td style="width:' + emptyPct.setScale(2) + '%; background-color:#FAFAFA; height:' + barHeight + 'px; padding:0 0 0 3px; border:none; font-size:10px; font-weight:bold; color:' + colorLimit + '; vertical-align:middle; white-space:nowrap;">' + limitText + '</td>';
                } else {
                    html += '<td style="width:' + emptyPct.setScale(2) + '%; background-color:#FAFAFA; height:' + barHeight + 'px; padding:0; border:none;"></td>';
                }
            }
            html += '</tr></table>';

            html += '</td></tr>';

            // Separador entre barras
            html += '<tr><td colspan="3" style="height:5px;"></td></tr>';
        }

        // Eje X: escala proporcional debajo de las barras
        if (axisScaleMax > 0) {

            // Línea separadora del eje (ancho 81% para coincidir con barra)
            html += '<tr>'
                + '<td style="width:28px;"></td>'
                + '<td style="width:180px;"></td>'
                + '<td style="padding:0 2px;">'
                + '<table style="width:100%; border-collapse:collapse;"><tr><td style="border-top:1px solid #999; padding:0;"></td></tr></table>'
                + '</td></tr>';

            // Fila de marcas verticales (ticks) - ancho 81% alineado con barras
            html += '<tr>'
                + '<td style="width:28px;"></td>'
                + '<td style="width:180px;"></td>'
                + '<td style="padding:0 2px;">'
                + '<table style="width:100%; border-collapse:collapse; table-layout:fixed;"><tr style="height:5px;">';
            for (Integer t = 0; t <= axisMaxTicks; t++) {
                String tickBorder = 'border-left:1px solid #999;';
                if (t == axisMaxTicks) {
                    tickBorder = 'border-right:1px solid #999;';
                }
                Decimal cellWidthPct = t < axisMaxTicks ? (Decimal.valueOf(100) / axisMaxTicks) : 0;
                if (t < axisMaxTicks) {
                    html += '<td style="width:' + cellWidthPct.setScale(2) + '%; height:5px; padding:0; ' + tickBorder + '"></td>';
                }
            }
            html += '</tr></table></td></tr>';

            // Fila de etiquetas numéricas - primera y última celda mitad de ancho para alinear con ticks
            html += '<tr>'
                + '<td style="width:28px;"></td>'
                + '<td style="width:180px;"></td>'
                + '<td style="padding:0 2px;">'
                + '<table style="width:100%; border-collapse:collapse; table-layout:fixed;"><tr style="height:11px;">';
            Integer labelStep = axisMaxTicks > 6 ? (Integer)Math.ceil(Decimal.valueOf(axisMaxTicks + 1) / 6) : 1;
            Decimal halfCellPct = Decimal.valueOf(100) / (2 * axisMaxTicks);
            Decimal fullCellPct = Decimal.valueOf(100) / axisMaxTicks;
            for (Integer t = 0; t <= axisMaxTicks; t++) {
                Decimal tickLabelValue = Decimal.valueOf(t) * axisTickStep;
                Boolean shouldRenderLabel = Math.mod(t, labelStep) == 0 || t == axisMaxTicks;
                String tickLabel = shouldRenderLabel ? formatAxisTickLabel(tickLabelValue, axisSuffix) : '&nbsp;';
                if (t == 0) {
                    html += '<td style="width:' + halfCellPct.setScale(2) + '%; font-size:8px; color:#666; text-align:left; padding:0; white-space:nowrap;">'
                        + tickLabel + '</td>';
                } else if (t == axisMaxTicks) {
                    html += '<td style="width:' + halfCellPct.setScale(2) + '%; font-size:8px; color:#666; text-align:right; padding:0; white-space:nowrap;">'
                        + tickLabel + '</td>';
                } else {
                    html += '<td style="width:' + fullCellPct.setScale(2) + '%; font-size:8px; color:#666; text-align:center; padding:0; white-space:nowrap;">'
                        + tickLabel + '</td>';
                }
            }
            html += '</tr></table></td></tr>';
        }

        html += '</table>';
        return html;
    }

    private static String renderSegmentTd(Decimal val, Decimal max, String color) {
        if (val <= 0) {
            return '';
        }
        Decimal width = (val / max) * 100;
        return '<td style="width:' + width.setScale(2) + '%; background-color:' + color + '; height:60px; padding:0; border:none;"></td>';
    }

    private static Decimal getNiceStep(Decimal maxUnits, Integer targetTicks) {
        Decimal safeMaxUnits = maxUnits <= 0 ? 1 : maxUnits;
        Integer safeTargetTicks = targetTicks <= 0 ? 1 : targetTicks;

        Decimal rawStep = safeMaxUnits / safeTargetTicks;
        if (rawStep <= 1) {
            return 1;
        }

        Decimal normalized = rawStep;
        Decimal power10 = 1;
        while (normalized >= 10) {
            normalized = normalized / 10;
            power10 = power10 * 10;
        }

        Decimal niceBase;
        if (normalized <= 1) {
            niceBase = 1;
        } else if (normalized <= 2) {
            niceBase = 2;
        } else if (normalized <= 5) {
            niceBase = 5;
        } else {
            niceBase = 10;
        }
        return niceBase * power10;
    }

    private static String formatAxisTickLabel(Decimal value, String suffix) {
        String s = String.valueOf(value.setScale(0));
        Integer len = s.length();
        String grouped = '';
        Integer count = 0;

        for (Integer i = len - 1; i >= 0; i--) {
            grouped = s.substring(i, i + 1) + grouped;
            count++;
            if (count == 3 && i > 0) {
                grouped = '.' + grouped;
                count = 0;
            }
        }
        return grouped + suffix;
    }



    /**
     * Genera el HTML completo de Limit Visual a partir de LineDataWrapper.
     * Recorre las features, construye un ChartRequest por cada una,
     * genera el chart HTML con getHorizontalBarChartHtml y añade la tabla de detalle.
     */
    public static String renderLimitVisualHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return '';
        }
        try {
            String html = '';
            Integer chartIndex = 0;
            List<ChartRequest> chartRequests = buildChartRequests(data);

            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                List<Map<String, Object>> consumptionLimitsList = DMT_FormattingUtils.getListMap(feature, 'consumptionLimits');
                Boolean hasContent = !consumptionLimitsList.isEmpty();

                if (hasContent && i > 0) {
                    // Title with traffic light
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    if (String.isNotBlank(stateName) && new List<String>{'RED','YELLOW','GREEN'}.contains(stateName)) {
                        html += '<table class="style-table" style="width:100%; border-collapse: collapse; margin-bottom: 10px;">'
                            + '<tr><td style="font-size: 16px; color: #004481; font-weight: bold; padding: 4px; text-align: left;">' + name + '</td>'
                            + '<td style="text-align: right; padding: 4px;">' + renderTrafficLightLocal(stateName) + '</td></tr>'
                            + '</table>';
                    }

                    // Check if there's valid amount data
                    Boolean proceed = false;
                    for (Map<String, Object> consumtionLimits : consumptionLimitsList) {
                        Map<String, Object> amount = (Map<String, Object>) consumtionLimits.get('amount');
                        if (amount != null && !amount.isEmpty()) {
                            proceed = true;
                            break;
                        }
                    }

                    if (proceed) {
                        html += '<div style="page-break-inside:avoid; break-inside:avoid-page; -webkit-column-break-inside:avoid; margin-bottom:10px;">';
                        // Render chart using ChartRequest
                        if (chartIndex < chartRequests.size()) {
                            html += getHorizontalBarChartHtml(chartRequests[chartIndex]);
                            chartIndex++;
                        }

                        // Render detail table per consumption limit
                        html += '<table class="style-table" style="width:100%; border-collapse: collapse; page-break-inside:avoid; break-inside:avoid-page;">';
                        for (Map<String, Object> consumtionLimits : consumptionLimitsList) {
                            String stateNameLimit = DMT_FormattingUtils.checkNull(consumtionLimits?.get('stateName'));
                            String limitDesc = DMT_FormattingUtils.checkNull(consumtionLimits?.get('limitDesc'));
                            if (String.isNotBlank(limitDesc)) {
                                html += '<tr>'
                                    + '<td align="left" style="padding: 8px; border-bottom: 1px solid #ccc" width="10%">' + renderTrafficLightSingleLocal(stateNameLimit) + '</td>'
                                    + '<td colspan="2" style="padding: 8px; border-bottom: 1px solid #ccc" width="60%">' + limitDesc + '</td>'
                                    + '</tr>';
                                html += renderDetailTableHtml(consumtionLimits, data.currencyIsoCode);
                                html += '</table><table class="style-table" style="width:100%; border-collapse: collapse; page-break-inside:avoid; break-inside:avoid-page;">';
                            }
                        }
                        html += '</table></div><br/>';
                    }
                }
            }
            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_ChartHtmlGenerator renderLimitVisualHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    /**
     * Genera la tabla HTML de detalle de montos para un consumptionLimit.
     */
    private static String renderDetailTableHtml(Map<String, Object> consumptionLimits, String currencyIsoCode) {
        Map<String, Object> amount = (Map<String, Object>) consumptionLimits.get('amount');
        if (amount == null) {
            return '';
        }
        Decimal sumAmount = (DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('notSignedTrConsumptionAmount')));
        Decimal newOpportunity = (DMT_FormattingUtils.convertValue(amount.get('unavailableRiskAmount')) - sumAmount);
        Decimal totalAmount = (DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')));
        Decimal limits = amount.get('currentApprovedAmount') != null ? DMT_FormattingUtils.convertValue(amount.get('currentApprovedAmount')) : 0;

        String tableDetail = '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderColorSquare('#053363') + '</td>'
            + '<td style="padding: 4px; border-top: none;">Drawn</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderColorSquare('#1463a6') + '</td>'
            + '<td style="padding: 4px; border-top: none;">Undrawn committed</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderColorSquare('#2496eb') + '</td>'
            + '<td style="padding: 4px; border-top: none;">Undrawn uncommitted</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderColorSquare('#2dcccd') + '</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Pending authorized</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: none;">' + renderColorSquare('#ffffff') + '</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: none;">Total Amount</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(totalAmount) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderColorSquare('#bdbdbd') + '</td>'
            + '<td style="padding: 4px; border-top: none;">New Opportunity</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(newOpportunity) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderColorSquare('#d90000') + '</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Limit</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(limits) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-bottom: none; border-top: none;">' + renderColorSquare('#ffffff') + '</td>'
            + '<td style="padding: 4px; border-bottom: none; border-top: none;">Exceeded</td>'
            + '<td style="padding: 4px; border-bottom: none; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(limits - (totalAmount + newOpportunity)) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '</table>';
        return tableDetail;
    }

    /**
     * Genera un cuadrado de color HTML inline.
     */
    private static String renderColorSquare(String color) {
        String safeColor = String.isBlank(color) ? '#ffffff' : color;
        return '<span style="display:inline-block; width:12px; height:12px; background-color:' + safeColor + '; border:1px solid #d9d9d9; vertical-align:middle; font-size:0; line-height:0;">&#160;</span>';
    }

    private static String renderTrafficLightLocal(String color) {
        if (color == 'NOPINTAR' || color == 'GRAY' || String.isBlank(color)) return '';
        String redLight    = color.toLowerCase() == 'red'    ? 'CircleRed'    : 'CircleGrey';
        String yellowLight = color.toLowerCase() == 'yellow' ? 'CircleYellow' : 'CircleGrey';
        String greenLight  = color.toLowerCase() == 'green'  ? 'CircleGreen'  : 'CircleGrey';
        return '<div style="display:inline-block; vertical-align:middle; white-space:nowrap;">'
            + '<img src="/resource/' + redLight    + '" style="width:20px; height:20px; margin:1px; vertical-align:middle;">'
            + '<img src="/resource/' + yellowLight + '" style="width:20px; height:20px; margin:1px; vertical-align:middle;">'
            + '<img src="/resource/' + greenLight  + '" style="width:20px; height:20px; margin:1px; vertical-align:middle;">'
            + '</div>';
    }

    private static String renderTrafficLightSingleLocal(String color) {
        if (color == 'NOPINTAR' || color == 'GRAY' || String.isBlank(color)) return '';
        String imgName = 'CircleGrey';
        if (color.toLowerCase() == 'red')    { imgName = 'CircleRed'; }
        else if (color.toLowerCase() == 'yellow') { imgName = 'CircleYellow'; }
        else if (color.toLowerCase() == 'green')  { imgName = 'CircleGreen'; }
        return '<img src="/resource/' + imgName + '" style="width:20px; height:20px; margin:1px; vertical-align:middle;" />';
    }

    private static String renderTrafficLightDotLocal(String dotColor) {
        // Mantenido por compatibilidad; ya no se usa directamente
        return '<img src="/resource/CircleGrey" style="width:20px; height:20px; margin:1px; vertical-align:middle;" />';
    }
}