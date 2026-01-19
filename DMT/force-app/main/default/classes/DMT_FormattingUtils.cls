public with sharing class DMT_FormattingUtils {
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
            if (fecha < 30) return fecha + 'D';
            else if (fecha < 365) return (fecha / 30) + 'M';
            else return (fecha / 365) + 'Y';
        } catch (Exception e) {
            return ' ';
        }
    }

    public static String tableRow1column(String label, String value) {
        return  '<tr>'
            + '<td colspan="2" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
            + '<div><strong>'+label+'</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + value + '</div>'
            + '</td>'
            + '</tr>';
    }

    public static String tableRow1columnWithHelper(String label, String helper, String value) {
        return  '<tr>'
            + '<td colspan="2" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
            + '<div><strong>' + label + '</strong></div>'
            + '<div style="font-size: 8px; font-style: italic; color: #888; margin-top: 2px; margin-bottom: 4px;">'
            + helper + '</div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">'
            + value + '</div>'
            + '</td>'
            + '</tr>';
    }

    public static String tableRow2columns(String label, String value, String label2, String value2) {
        return '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + label + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + value + '</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + label2 + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + value2 + '</td>'
            + '</tr>';
    }

    public static String tableRow2columns_New(String label, String value, String label2, String value2) {
        String rightCell = '';
        if (String.isBlank(label2) && String.isBlank(value2)) {
            rightCell = '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;"></td>'; // Empty td to maintain alignment
        } else {
            rightCell = '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                + '<div><strong>' + label2 + '</strong></div>'
                + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + value2 + '</div>'
                + '</td>';
        }
        return '<tr>'
            + '<td style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div><strong>' + label + '</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + value + '</div>'
            + '</td>'
            + rightCell
            + '</tr>';
    }

    public static String tableRow1column_checkbox(String label, Boolean value) {
        return  '<tr>'
            + '<td style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div>'
            + '<div><strong>'+label+'</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + '<input type="checkbox" disabled="" '+ (value ? 'checked' : '') +' />' + '</div>'
            + '</div>'
            + '</td>'
            +'<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;"></td>' // Empty td to maintain alignment
            + '</tr>';
    }

    public static String tableRow2columns_checkbox(String label, Boolean value, String label2, Boolean value2) {
        return '<tr>'
            + '<td style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div>'
            + '<div><strong>'+label+'</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + '<input type="checkbox" disabled="" '+ (value ? 'checked' : '') +' />' + '</div>'
            + '</div>'
            + '</td>'
            + '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
            + '<div>'
            + '<div><strong>'+label2+'</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + '<input type="checkbox" disabled="" '+ (value2 ? 'checked' : '') +' />' + '</div>'
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
        if (color.toLowerCase() == 'red') redLight = 'CircleRed';
        else if (color.toLowerCase() == 'yellow') yellowLight = 'CircleYellow';
        else if (color.toLowerCase() == 'green') greenLight = 'CircleGreen';
        return '<div class="traffic-light-container" style="display: inline-block;">'
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
        if (color.toLowerCase() == 'red') colorPaint = 'CircleRed';
        else if (color.toLowerCase() == 'yellow') colorPaint = 'CircleYellow';
        else if (color.toLowerCase() == 'green') colorPaint = 'CircleGreen';
        return '<div class="traffic-light-container" style="display: inline-block; vertical-align: middle;">'
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
}