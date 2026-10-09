public with sharing class DMT_FormattingUtils {

    // wrapper for new methods
    public class DisplayField {
        public String label { get; set; }
        public String value { get; set; }
        public Boolean boolValue {get; set; }
        public String size { get; set; }
        public List<String> fieldApiNames { get; set; }

        public DisplayField(String label, String value) {
            this.label = label;
            this.value = value;
            this.size = 'HALF';
        }

        public DisplayField(String label, Boolean value) {
            this.label = label;
            this.boolValue = value;
            this.size = 'HALF';
        }

        public DisplayField(String label, Boolean value, String size) {
            this.label = label;
            this.boolValue = value;
            this.size = size;
        }

        public DisplayField(String label, String value, String size) {
            this.label = label;
            this.value = value;
            this.size = size;
        }

        // CIBGLOBALD-4117 - carries which raw field(s) fed this display value, so getTrackedFields()
        // can derive the watch list from the same call site that builds the display, instead of a
        // separate hand-maintained list that can drift from what's actually rendered.
        public DisplayField(String label, String value, List<String> fieldApiNames) {
            this.label = label;
            this.value = value;
            this.size = 'HALF';
            this.fieldApiNames = fieldApiNames;
        }

        public DisplayField(String label, Boolean value, List<String> fieldApiNames) {
            this.label = label;
            this.boolValue = value;
            this.size = 'HALF';
            this.fieldApiNames = fieldApiNames;
        }
    }


    // Nuevo Wrapper exclusivo para Tablas de Datos Clásicas (Filas y Columnas)
    public class DataTableWrapper {
        public String title;
        public List<String> headers;
        public List<List<String>> rows;
        public String width;  // NEW: Support for custom width

        public DataTableWrapper(String title, List<String> headers) {
            this.title = title;
            this.headers = headers;
            this.rows = new List<List<String>>();
            this.width = '100%';  // Default to full width
        }

        public DataTableWrapper(String title, List<String> headers, String width) {
            this.title = title;
            this.headers = headers;
            this.rows = new List<List<String>>();
            this.width = width;
        }
    }


    public static String checkNull(Object value) {
        if (value == null || value == 'null') return ''; // If its null return empty string

        if (value instanceof Datetime) {
            return ((Datetime) value).format('yyyy-MM-dd'); // Format date time
        }

        if (value instanceof Date) {
            return ((Date) value).format(); // Returns user's local date format
        }
        return String.valueOf(value);
    }

    public static String formatCurrencyAmount(Object amount, String currencyIsoCode){
        String formattedAmount = '';
        if (amount == null || amount == '') {
            return formattedAmount;
        }
        formattedAmount = ((String) DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(new Map<String, Object>{'amount' => amount}, new Map<String, Object>(), new Map<String, Object>()).get('amount')+ ' ' + currencyIsoCode).trim();

        return formattedAmount;
    }

    public static String changeDateFormat(Object dateInput) {
        // First, normalize the input using checkNull (handles nulls, Date, DateTime, and others)
        String dateText = checkNull(dateInput);
        System.debug('Normalized dateText: ' + dateText);

        if (String.isBlank(dateText)) {
            return ''; // if checkNull returned an empty string, exit early
        }

        try {
            // Convert back to Date for formatting
            Date d = Date.valueOf(dateText); // this expects format 'yyyy-MM-dd'
            String formatted = DateTime.newInstance(d.year(), d.month(), d.day()).format('dd-MMM-yyyy');
            System.debug('Formatted dateText: ' + formatted);
            return formatted;
        } catch (Exception e) {
            System.debug('Invalid dateText: ' + dateText + ', error: ' + e.getMessage());
            return dateText; // fallback: return original text if parsing fails
        }
    }

    /* public static String formatEuroCurrency(Decimal value) {
        // Existing formatEuroCurrency logic
        return '';
    } */

    public static String traductorDate(String fechaText) {
        if (String.isBlank(fechaText)) return ' ';
        try {
            Integer fecha = Integer.valueOf(fechaText);
            // Excepción especial: 18 meses
            if (fecha == 548) {
                return '18M';
            }
            if (fecha < 30) return fecha + 'D';
            else if (fecha < 365) return (fecha / 30) + 'M';
            else return (fecha / 365) + 'Y';
        } catch (Exception e) {
            return ' ';
        }
    }

/*     public static String tableRow1column(String label, String value) {
        return  '<tr>'
            + '<td colspan="1" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
            + '<div><strong>'+label+'</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + value + '</div>'
            + '</td>'
            + '</tr>';
    } */
    public static String tableRow1column(String label, String value) {
        /*---- START NEW PDF BUILDER----*/
        return  '<tr data-dmt-row="field">'
            + '<td style="padding: 8px 10px 4px; vertical-align: top; border-top: none; border-left: none; border-right: none; border-bottom: 1px solid #ccc;">'
            + '<div data-dmt-label="' + label.escapeHtml4() + '" style="font-weight: bold; color: #333;">' + label + '</div>'
            + '<div data-dmt-value="true" style="min-height: 20px;">' + (String.isNotBlank(value) ? value : '&nbsp;') + '</div>'
            + '</td>'
            + '</tr>';
        /*---- END NEW PDF BUILDER----*/
    }
    public static String tableRow1columnWithHelper(String label, String helper, String value) {
        return  '<tr data-dmt-row="field">'
            + '<td colspan="2" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
            + '<div data-dmt-label="' + label.escapeHtml4() + '"><strong>' + label + '</strong></div>'
            + '<div style="font-size: 8px; font-style: italic; color: #888; margin-top: 2px; margin-bottom: 4px;">'
            + helper + '</div>'
            + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">'
            + value + '</div>'
            + '</td>'
            + '</tr>';
    }

    public static String tableRow2columns(String label, String value, String label2, String value2) {
        return '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="' + label.escapeHtml4() + '" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + label + '</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + value + '</td>'
            + '<td data-dmt-pair="2" data-dmt-label="' + label2.escapeHtml4() + '" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + label2 + '</strong></td>'
            + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + value2 + '</td>'
            + '</tr>';
    }

    public static String tableRow2columns_New(String label, String value, String label2, String value2) {
        String rightCell = '';
        if (String.isBlank(label2) && String.isBlank(value2)) {
            rightCell = '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;"></td>'; // Empty td to maintain alignment
        } else {
            rightCell = '<td data-dmt-pair="2" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                + '<div data-dmt-label="' + label2.escapeHtml4() + '"><strong>' + label2 + '</strong></div>'
                + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + value2 + '</div>'
                + '</td>';
        }
        return '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div data-dmt-label="' + label.escapeHtml4() + '"><strong>' + label + '</strong></div>'
            + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + value + '</div>'
            + '</td>'
            + rightCell
            + '</tr>';
    }

    // Same cell markup/style as tableRow2columns' pair 1 (two <td>s, data-dmt-pair="1" on both),
    // just without a second pair - for a trailing unpaired field in an otherwise-2-per-row table.
    // Distinct from tableRow1column, which stacks label+value in a single <td> via nested <div>s.
    public static String tableRow1columnPairStyle(String label, String value) {
        return '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="' + label.escapeHtml4() + '" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + label + '</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + value + '</td>'
            + '</tr>';
    }

    public static String tableRow1column_checkbox(String label, Boolean value) {
        return  '<tr data-dmt-row="field">'
            + '<td style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div>'
            + '<div data-dmt-label="' + label.escapeHtml4() + '"><strong>'+label+'</strong></div>'
            + '<div data-dmt-value="true" data-dmt-checked="' + (value == true) + '" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + '<input type="checkbox" disabled="" '+ (value ? 'checked' : '') +' />' + '</div>'
            + '</div>'
            + '</td>'
            +'<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;"></td>' // Empty td to maintain alignment
            + '</tr>';
    }

    public static String tableRow2columns_checkbox(String label, Boolean value, String label2, Boolean value2) {
        return '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div>'
            + '<div data-dmt-label="' + label.escapeHtml4() + '"><strong>'+label+'</strong></div>'
            + '<div data-dmt-value="true" data-dmt-checked="' + (value == true) + '" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + '<input type="checkbox" disabled="" '+ (value ? 'checked' : '') +' />' + '</div>'
            + '</div>'
            + '</td>'
            + '<td data-dmt-pair="2" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
            + '<div>'
            + '<div data-dmt-label="' + label2.escapeHtml4() + '"><strong>'+label2+'</strong></div>'
            + '<div data-dmt-value="true" data-dmt-checked="' + (value2 == true) + '" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + '<input type="checkbox" disabled="" '+ (value2 ? 'checked' : '') +' />' + '</div>'
            + '</div>'
            + '</td>'
            + '</tr>';
    }

    public static String getWarrantyNamesAsString(List<DMT_Warranty__c> warranties) {
        if (warranties == null || warranties.isEmpty()) return '';
        List<String> names = new List<String>();
        for (DMT_Warranty__c w : warranties) {
            if (w.Name != null) names.add(w.Name);
        }
        return String.join(names, ', ');
    }

    public static String renderTrafficLight(String color) {
        System.debug('DMT_FormattingUtils.renderTrafficLight color, '+ color);
        if (color == 'NOPINTAR' || color == 'GRAY' || String.isBlank(color)) return '';
        String redLight = 'CircleGrey';
        String yellowLight = 'CircleGrey';
        String greenLight = 'CircleGrey';
        String activeColor = 'GREY';
        if (color.toLowerCase() == 'red') { redLight = 'CircleRed'; activeColor = 'RED'; }
        else if (color.toLowerCase() == 'yellow') { yellowLight = 'CircleYellow'; activeColor = 'YELLOW'; }
        else if (color.toLowerCase() == 'green') { greenLight = 'CircleGreen'; activeColor = 'GREEN'; }
        return '<div class="traffic-light-container" data-dmt-traffic="' + activeColor + '" data-dmt-traffic-mode="triple" style="display: inline-block;">'
            + '<img src="/resource/' + redLight + '" style="width: 25px; height: 25px; margin: 1px;">'
            + '<img src="/resource/' + yellowLight + '" style="width: 25px; height: 25px; margin: 1px;">'
            + '<img src="/resource/' + greenLight + '" style="width: 25px; height: 25px; margin: 1px;">'
            + '</div>';
    }

    public static Map<String, Object> createTrafficLightJson(String color, String numCircle) {
        if(numCircle == 'ONE'){
            Map<String, Object> itemSection = new Map<String, Object>();
            String colorCircle;
            List<Object> contentListCustomOne = new List<Object>();
            Map<String, Object> stylesOne  = new Map<String, Object>();
                stylesOne.put('fontSize', 18);
                stylesOne.put('font', 'Zapfdingbats');
            Map<String, Object> colorOne  = new Map<String, Object>();
                if(color == 'RED'){colorCircle = '#D73F52';}
                else if(color == 'YELLOW'){colorCircle = '#F8CC52';}
                else if(color =='GREEN'){colorCircle = '#47AD5A';}
                else{colorCircle = '#BDBDBD';}
                colorOne.put('textColor',colorCircle);
                colorOne.put('fontSize',18);
                colorOne.put('font','Zapfdingbats');
            Map<String, Object> contentOne = new Map<String, Object>();
                contentOne.put('styles', colorOne);
                contentOne.put('content', 'l');
                contentListCustomOne.add(contentOne);

                itemSection.put('custom', contentListCustomOne);
                itemSection.put('styles', stylesOne);
                itemSection.put('content', '');
                itemSection.put('type', 'custom');

            return itemSection;
        }else{
            Map<String, Object> itemSection = new Map<String, Object>();
            System.debug('Color a Pintar --> ' + color);
         //   if (/*color != 'NOPINTAR' ||*/ color == 'RED' || color == 'YELLOW' || color =='GREEN' ) {
            if(new List<String>{'RED','YELLOW','GREEN'}.contains(color)) {
                List<Object> contentListCustom = new List<Object>();
                Map<String, Object> stylesSection  = new Map<String, Object>();
                    stylesSection .put('fontSize', 18);
                    stylesSection .put('font', 'Zapfdingbats');
                //CREATE COLOR
                Map<String, Object> colorRed  = new Map<String, Object>();
                    colorRed.put('textColor', color == 'RED' ? '#D73F52' : '#BDBDBD');
                    colorRed.put('fontSize',18);
                    colorRed.put('font','Zapfdingbats');
                Map<String, Object> contentRed  = new Map<String, Object>();
                    contentRed.put('styles', colorRed);
                    contentRed.put('content', 'l');
                    contentListCustom.add(contentRed);

                Map<String, Object> colorYellow  = new Map<String, Object>();
                    colorYellow.put('textColor', color == 'YELLOW' ? '#F8CC52' : '#BDBDBD');
                    colorYellow.put('fontSize',18);
                    colorYellow.put('font','Zapfdingbats');
                Map<String, Object> contentYellow  = new Map<String, Object>();
                    contentYellow.put('styles', colorYellow);
                    contentYellow.put('content', 'l');
                    contentListCustom.add(contentYellow);

                Map<String, Object> colorGreen  = new Map<String, Object>();
                    colorGreen.put('textColor', color == 'GREEN' ? '#47AD5A' : '#BDBDBD');
                    colorGreen.put('fontSize',18);
                    colorGreen.put('font','Zapfdingbats');
                Map<String, Object> contentGreen  = new Map<String, Object>();
                    contentGreen.put('styles', colorGreen);
                    contentGreen.put('content', 'l');
                    contentListCustom.add(contentGreen);

                itemSection.put('custom', contentListCustom);
                itemSection.put('styles', stylesSection);
                itemSection.put('content', '');
                itemSection.put('type', 'custom');
            }else{
                List<Object> contentListCustom = new List<Object>();
                Map<String, Object> stylesSection  = new Map<String, Object>();
                    stylesSection .put('fontSize', 18);
                    stylesSection .put('font', 'Zapfdingbats');
                //CREATE COLOR
                Map<String, Object> colorRed  = new Map<String, Object>();
                    colorRed.put('textColor', '#ffffff');
                    colorRed.put('fontSize',18);
                    colorRed.put('font','Zapfdingbats');
                Map<String, Object> contentRed  = new Map<String, Object>();
                    contentRed.put('styles', colorRed);
                    contentRed.put('content', 'l');
                    contentListCustom.add(contentRed);

                Map<String, Object> colorYellow  = new Map<String, Object>();
                    colorYellow.put('textColor', '#ffffff');
                    colorYellow.put('fontSize',18);
                    colorYellow.put('font','Zapfdingbats');
                Map<String, Object> contentYellow  = new Map<String, Object>();
                    contentYellow.put('styles', colorYellow);
                    contentYellow.put('content', 'l');
                    contentListCustom.add(contentYellow);

                Map<String, Object> colorGreen  = new Map<String, Object>();
                    colorGreen.put('textColor', '#ffffff');
                    colorGreen.put('fontSize',18);
                    colorGreen.put('font','Zapfdingbats');
                Map<String, Object> contentGreen  = new Map<String, Object>();
                    contentGreen.put('styles', colorGreen);
                    contentGreen.put('content', 'l');
                    contentListCustom.add(contentGreen);

                itemSection.put('custom', contentListCustom);
                itemSection.put('styles', stylesSection);
                itemSection.put('content', '');
                itemSection.put('type', 'custom');

            }
            return itemSection;
        }
    }

    public static String renderTrafficLightSingle(String color) {
        if (color == 'NOPINTAR') return '';
        String colorPaint = 'CircleGrey';
        String activeColor = 'GREY';
        if (color.toLowerCase() == 'red') { colorPaint = 'CircleRed'; activeColor = 'RED'; }
        else if (color.toLowerCase() == 'yellow') { colorPaint = 'CircleYellow'; activeColor = 'YELLOW'; }
        else if (color.toLowerCase() == 'green') { colorPaint = 'CircleGreen'; activeColor = 'GREEN'; }
        return '<div class="traffic-light-container" data-dmt-traffic="' + activeColor + '" data-dmt-traffic-mode="single" style="display: inline-block; vertical-align: middle;">'
            + '<img src="/resource/' + colorPaint + '" style="width: 25px; height: 25px; margin: 1px;">'
            + '</div>';
    }

    public static String getWorkflowColor(Map<String, Object> feature, List<DMT_Case_Steps_Controller.WRAPPER_Step> steps) {
        List<Object> listTasks = (List<Object>) feature.get('tasks');
        if(listTasks == null || listTasks.isEmpty()){
            return 'NOPINTAR';
        }
        for(DMT_Case_Steps_Controller.WRAPPER_Step currentTask : steps){
            if(currentTask.featureId == feature.get('id')){
                if(currentTask.caseStatus == 'Finished'){
                    if(currentTask.result == 'No'){
                        return 'RED';
                    }else if(currentTask.result == 'Yes'){
                        return 'GREEN';
                    }
                }
            }
        }
        // If there are tasks, but none are finished, return YELLOW
        return 'YELLOW';
    }

     public static List<Map<String, Object>> getListMap(Map<String, Object> feature, String listName) {
        List<Map<String, Object>> listMap = new List<Map<String, Object>>();
        List<Object> rawList = (List<Object>) feature.get(listName);
        if (rawList != null) {
            for (Object rawObj : rawList) {
                listMap.add((Map<String, Object>) rawObj);
            }
        }
        return listMap;
    }

    public static Decimal convertValue(Object value) {
        if (value == null) return 0;
        if (value instanceOf Decimal) return (Decimal) value;
        if (value instanceOf Long) return Decimal.valueOf((Long) value);
        if (value instanceOf String) return Decimal.valueOf((String) value);
        return 0;
    }

    public static String formatDecimalAbbreviation(Decimal value) {
        if (value == null) return '0';
        Decimal absValue = Math.abs(value);
        String suffix = '';
        Decimal result;
        if (absValue >= 1000000) {
            result = absValue / 1000000;
            suffix = 'M';
        } else if (absValue >= 1000) {
            result = absValue / 1000;
            suffix = 'K';
        } else {
            result = absValue;
            suffix = '';
        }
        result = result.setScale(2);
        return (value < 0 ? '-' : '') + result + suffix;
    }

    public static List<Object> createTitleWithCircles(String title, String color){
        List<Object> listTitleCircle = new List<Object>();
        Map<String, Object> contentComponent = new Map<String, Object>();

            // CREATE TITLE
            Map<String, Object> titleComponent = new Map<String, Object>();
            Map<String, Object> margin = new Map<String, Object>();
                margin.put('top', 2);
            Map<String, Object> styleTitle = new Map<String, Object>();
                styleTitle.put('nobreak', true);
                styleTitle.put('textColor', '#00FF00');
                styleTitle.put('fontSize', 12);
                titleComponent.put('margin', margin);
                titleComponent.put('styles', styleTitle);
                titleComponent.put('text', title);
                titleComponent.put('type', 'title');
                listTitleCircle.add(titleComponent);

            Map<String, Object> circleComponentGreen = new Map<String, Object>();
            Map<String, Object> marginCircleGreen = new Map<String, Object>();
                marginCircleGreen.put('top', -1.8);
            Map<String, Object> styleCircleGreen = new Map<String, Object>();
                //styleCircleGreen.put('nobreak', true);
                styleCircleGreen.put('fillColor', color == 'GREEN' ? '#47AD5A' : '#BDBDBD');
                styleCircleGreen.put('drawColor', color == 'GREEN' ? '#47AD5A' : '#BDBDBD');
                circleComponentGreen.put('style', styleCircleGreen);
                circleComponentGreen.put('x', 'right - 4');
                circleComponentGreen.put('radius', 2);
                circleComponentGreen.put('margin', marginCircleGreen);
                circleComponentGreen.put('type', 'circle');
                listTitleCircle.add(circleComponentGreen);

            Map<String, Object> circleComponentYellow = new Map<String, Object>();
            Map<String, Object> marginCircleYellow = new Map<String, Object>();
                marginCircleYellow.put('top', -1.8);
            Map<String, Object> styleCircleYellow = new Map<String, Object>();
                styleCircleYellow.put('nobreak', true);
                styleCircleYellow.put('fillColor', color == 'YELLOW' ? '#F8CC52' : '#BDBDBD');
                styleCircleYellow.put('drawColor', color == 'YELLOW' ? '#F8CC52' : '#BDBDBD');
                circleComponentYellow.put('style', styleCircleYellow);
                circleComponentYellow.put('x', 'right - 8.5');
                circleComponentYellow.put('radius', 2);
                circleComponentYellow.put('margin', marginCircleYellow);
                circleComponentYellow.put('type', 'circle');
                listTitleCircle.add(circleComponentYellow);

            Map<String, Object> circleComponentRed = new Map<String, Object>();
            Map<String, Object> marginCircleRed = new Map<String, Object>();
                marginCircleRed.put('top', -1.8);
            Map<String, Object> styleCircleRed = new Map<String, Object>();
                styleCircleRed.put('nobreak', true);
                styleCircleRed.put('fillColor', color == 'RED' ? '#D73F52' : '#BDBDBD');
                styleCircleRed.put('drawColor', color == 'RED' ? '#D73F52' : '#BDBDBD');
                circleComponentRed.put('style', styleCircleRed);
                circleComponentRed.put('x', 'right - 13');
                circleComponentRed.put('radius', 2);
                circleComponentRed.put('margin', marginCircleRed);
                circleComponentRed.put('type', 'circle');
                listTitleCircle.add(circleComponentRed);

        return listTitleCircle;
    }

    public static String formatObjectAbbreviation(Decimal value) {
        if (value == null) {
            return '0';
        }
        Boolean isNegative = value < 0;
        Decimal absValue = value.abs();
        Decimal scaledValue;
        String suffix = '';

        if (absValue >= 1000000000) { // Billions
            scaledValue = absValue / 1000000000;
            suffix = 'B';
        } else if (absValue >= 1000000) { // Millions
            scaledValue = absValue / 1000000;
            suffix = 'M';
        } else if (absValue >= 1000) { // Thousands
            scaledValue = absValue / 1000;
            suffix = 'K';
        } else { // Below 1,000
            scaledValue = absValue;
            suffix = '';
        }

        String formatted = formatCurrencyAmount(scaledValue, '');

        return (isNegative ? '-' : '') + formatted + suffix;
    }

    public static Map<String, Object> printRectTableDetail(String color){
        Map<String, Object> itemSection = new Map<String, Object>();
            List<Object> contentListCustomOne = new List<Object>();
            Map<String, Object> stylesOne  = new Map<String, Object>();
                stylesOne.put('fontSize', 10);
                stylesOne.put('font', 'Zapfdingbats');
            Map<String, Object> colorRect = new Map<String, Object>();
                colorRect.put('drawColor',color);
                colorRect.put('fillColor',color);
            Map<String, Object> contentList = new Map<String, Object>();
                contentList.put('height', 3);
                contentList.put('width', 3);
                contentList.put('type', 'rect');
            Map<String, Object> contentRect = new Map<String, Object>();

                contentRect.put('styles', colorRect);
                contentRect.put('content', contentList);
                contentListCustomOne.add(contentRect );

                itemSection.put('custom', contentListCustomOne);
                itemSection.put('styles', stylesOne);
                itemSection.put('content', '');
                itemSection.put('type', 'custom');

            return itemSection;
    }

    // Converts a raw stored amount to millions for sections labeled "(Figures in Mn)".
    public static Object toMillions(Object rawValue) {
        Decimal result;
        if (rawValue == null) return null;
        try {
            result = ((Decimal) rawValue) / 1000000;
            return result.setScale(2);
        } catch (Exception e) {
            try {
                result = Decimal.valueOf(String.valueOf(rawValue)) / 1000000;
                return result.setScale(2);
            } catch (Exception ex) {
                return null;
            }
        }
    }

    public static String formatDecimalEs(Object rawValue, Integer scale) {
        if (rawValue == null) return '';

        Decimal value;
        try {
            value = (Decimal) rawValue;
        } catch (Exception e) {
            try {
                value = Decimal.valueOf(String.valueOf(rawValue));
            } catch (Exception ex) {
                return '';
            }
        }

        // Use rounding instead of truncating
        Decimal rounded = value.setScale(scale, RoundingMode.HALF_UP);
        String raw = String.valueOf(rounded);

        List<String> parts = raw.split('\\.');
        String intPart = parts[0];
        String decPart = (parts.size() > 1) ? parts[1] : '';

        while (decPart.length() < scale) {
            decPart += '0';
        }

        String formattedInt = '';
        Integer count = 0;
        for (Integer i = intPart.length() - 1; i >= 0; i--) {
            formattedInt = intPart.substring(i, i+1) + formattedInt;
            count++;
            if (Math.mod(count, 3) == 0 && i > 0 && !intPart.startsWith('-')) {
                formattedInt = '.' + formattedInt;
            }
        }

        return formattedInt + ',' + decPart;
    }

    public static String formatProfitabilityDecimal(Object rawValue, Integer scale) {
        String formattedValue = formatDecimalEs(rawValue, scale);
        if (String.isBlank(formattedValue)) {
            return '';
        }

        Decimal value;
        try {
            value = (Decimal) rawValue;
        } catch (Exception e) {
            try {
                value = Decimal.valueOf(String.valueOf(rawValue));
            } catch (Exception ex) {
                return '';
            }
        }

        return removeGroupingSeparatorForSmallAmount(formattedValue, value);
    }

    private static String removeGroupingSeparatorForSmallAmount(String formattedValue, Decimal value) {
        if (String.isBlank(formattedValue) || value == null) {
            return formattedValue;
        }

        Decimal absValue = value < 0 ? value * -1 : value;
        if (absValue >= 1000 && absValue < 10000) {
            return formattedValue.replace('.', '');
        }

        return formattedValue;
    }

    public static String formatPercent(Object val) {
        if (val == null || String.valueOf(val).trim() == '') return '0.00 %';
        Decimal d;
        try { d = (Decimal)val; } catch (Exception e) { d = Decimal.valueOf(String.valueOf(val)); }
        Decimal percent = d * 100;
        return percent.setScale(2) + ' %';
    }

    public static String formatBps(Object value) {
        // Handle nulls or non-numeric input
        if (value == null) {
            return '0.000 bps';
        }

        Decimal numeric;
        try {
            numeric = Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            numeric = 0;
        }

        // Format to 3 decimal places
        return numeric.setScale(3, RoundingMode.HALF_UP) + ' bps';
    }

    public static String booleanToYesNo(Boolean value) {
        if (value == null) return 'No';
        return value ? 'Yes' : 'No';
    }


    // new html generator

public static String generateHtmlTable(List<DisplayField> fields) {
        // 1. Filtrar los campos que vienen vacíos (If you still need this logic, you can add it here!)

        // 2. Construir el HTML con 4 columnas base para soportar QUARTER (25%), HALF (50%) y FULL (100%)
        String html = '<table class="style-table" data-dmt-fieldgrid="true" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
                        + '<colgroup>'
                        + '<col style="width: 25%;"><col style="width: 25%;">'
/*                         + '<col style="width: 25%;"><col style="width: 25%;">' */
                        + '</colgroup>';

        Integer currentRowWidth = 0; // Tracks the width of the current row (max 4)

        // 3. Recorrer la lista dinámicamente
        for (DisplayField field : fields) {
            Integer fieldWidth = getFieldColspan(field.size);

            // If we are at the start of a new row
            if (currentRowWidth == 0) {
                html += '<tr>';
            } 
            // If adding this field exceeds the current row capacity, pad the remaining space and start a new row
            else if (currentRowWidth + fieldWidth > 4) {
                Integer remainingSpace = 4 - currentRowWidth;
                html += '<td colspan="' + remainingSpace + '" style="border:none;"></td></tr><tr>';
                currentRowWidth = 0; // Reset for the new row
            }

            // Render the cell with the calculated colspan
            html += renderHtmlCell(field, fieldWidth);
            currentRowWidth += fieldWidth;

            // If the row is perfectly full, close it
            if (currentRowWidth == 4) {
                html += '</tr>';
                currentRowWidth = 0;
            }
        }

        // 4. If the loop ends but the last row isn't full, pad it so the table structure doesn't break
        if (currentRowWidth > 0 && currentRowWidth < 4) {
            Integer remainingSpace = 4 - currentRowWidth;
            html += '<td colspan="' + remainingSpace + '" style="border:none;"></td></tr>';
        }

        html += '</table>';
        return html;
    }

    // Helper method to translate text sizes into HTML colspans
    private static Integer getFieldColspan(String size) {
        if (size == 'FULL') return 4;
        if (size == 'QUARTER') return 1;
        return 2; // Defaults to 'HALF'
    }

    // Método auxiliar actualizado para recibir el DisplayField completo y el colspan
    private static String renderHtmlCell(DisplayField field, Integer colspan) {
        String label = field.label;
        Object value = (field.boolValue == null) ? (Object)field.value : (Object)field.boolValue;

        // Decide the border style based on whether it's a real field or a blank spacer
        String borderStyle = String.isNotBlank(label) ? 'border-bottom: 1px solid #ccc; padding-bottom: 4px;' : '';

        // Determine how to display the value based on its object type
        String displayValue = '';

        if (value instanceof Boolean) {
            // It's a checkbox
            Boolean isChecked = (Boolean) value;
            displayValue = '<input type="checkbox" disabled="disabled" ' + (isChecked ? 'checked="checked"' : '') + ' />';
        } else {
            // It's a standard text/number/date value (handle null gracefully)
            displayValue = value != null ? String.valueOf(value) : '';
        }

        // Build and return the standardized HTML with the dynamic colspan
        return '<td data-dmt-row="field" colspan="' + colspan + '" style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top; word-wrap: break-word; overflow-wrap: break-word;">'
             + '<div data-dmt-label="' + (label != null ? label : '').escapeHtml4() + '"><strong>' + (label != null ? label : '') + '</strong></div>'
               + '<div data-dmt-value="true" style="min-height: 25px; word-wrap: break-word; overflow-wrap: break-word; word-break: break-all; white-space: normal; ' + borderStyle + '">' + displayValue + '</div>'
             + '</td>';
    }

    // Generic HTML Table Renderer
    public static String renderHtmlDataTable(DataTableWrapper tableData) {
        if (tableData.rows.isEmpty()) return ''; // No renderiza si está vacía

        String html = '<table class="style-table" data-dmt-table="true" style="width:' + tableData.width + '; border-collapse: collapse; table-layout: fixed; margin-bottom: 15px;">';
        html += '<tr data-dmt-table-title="true"><td colspan="' + tableData.headers.size() + '" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px; word-wrap: break-word;"><strong>' + tableData.title + '</strong></td></tr>';

        html += '<tr data-dmt-table-header="true">';
        for (String header : tableData.headers) {
            html += '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>' + header + '</strong></td>';
        }
        html += '</tr>';

        for (List<String> row : tableData.rows) {
            html += '<tr data-dmt-table-row="true">';
            for (String cell : row) {
                html += '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + cell + '</td>';
            }
            html += '</tr>';
        }
        html += '</table>';
        return html;
    }

    // Utility method to get the standard field label dynamically
    public static String getFieldLabel(String objectApiName, String fieldApiName) {
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType != null) {
                Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
                Schema.SObjectField field = describeResult.fields.getMap().get(fieldApiName);
                if (field != null) {
                    return field.getDescribe().getLabel();
                }
            }
        } catch (Exception e) {
            System.debug('Error retrieving field label: ' + e.getMessage());
        }
        return fieldApiName; // Fallback to API name if not found
    }

    public static String formatWithoutDecimals(Object rawValue) {
        if (rawValue == null || String.isBlank(String.valueOf(rawValue))) return '';
        try {
            Decimal val = Decimal.valueOf(String.valueOf(rawValue));
            // Strip decimals and apply the standard thousands separator
            val = val.setScale(0, RoundingMode.HALF_UP);
            return val.format();
        } catch (Exception e) {
            System.debug('Error formatting value: ' + e.getMessage());
            return '';
        }
    }

    private static final Integer SAFE_MULTILINE_BREAK_INTERVAL = 47;
    private static final String HTML_SOFT_BREAK_MARKUP = '<wbr/>';

    public static String formatToTwoDecimals(Object rawValue) {
        if (rawValue == null || String.isBlank(String.valueOf(rawValue))) return '';
        try {
            Decimal val = Decimal.valueOf(String.valueOf(rawValue));
            // Cap at 2 decimals, then strip unnecessary trailing zeros (e.g., .00)
            return val.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().format();
        } catch (Exception e) {
            return String.valueOf(rawValue);
        }
    }
    
    public static String toSafeMultilineHtml(String value) {
        String safeValue = value;
        if (safeValue == null) {
            safeValue = '';
        }

        safeValue = addSoftBreaksToLongRuns(safeValue.escapeHtml4());

        return safeValue
            .replace('\r\n', '<br/>')
            .replace('\n', '<br/>')
            .replace('\r', '<br/>');
    }

    private static String addSoftBreaksToLongRuns(String value) {
        if (String.isBlank(value)) {
            return value;
        }

        String result = '';
        Integer consecutiveCount = 0;
        Integer index = 0;

        while (index < value.length()) {
            if (value.substring(index, index + 1) == '&') {
                Integer semicolonOffset = value.substring(index).indexOf(';');
                if (semicolonOffset > 0) {
                    String entityToken = value.substring(index, index + semicolonOffset + 1);
                    result += entityToken;
                    consecutiveCount++;
                    if (consecutiveCount >= SAFE_MULTILINE_BREAK_INTERVAL) {
                        result += HTML_SOFT_BREAK_MARKUP;
                        consecutiveCount = 0;
                    }
                    index += semicolonOffset + 1;
                    continue;
                }
            }

            String currentChar = value.substring(index, index + 1);
            result += currentChar;

            if (currentChar == ' ' || currentChar == '\t' || currentChar == '\r' || currentChar == '\n') {
                consecutiveCount = 0;
            } else {
                consecutiveCount++;
                if (consecutiveCount >= SAFE_MULTILINE_BREAK_INTERVAL) {
                    result += HTML_SOFT_BREAK_MARKUP;
                    consecutiveCount = 0;
                }
            }

            index++;
        }

        return result;
    }

}