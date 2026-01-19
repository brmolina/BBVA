/**-------------------------------------------------------------------------------------------
* @Name     DMT BarChart Static
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-01-21
* ------------------------------------------------------------------------------------------------
* @Description This class takes an input wrapper and returns a stacked barchart as html. It is intended
* to be used in a Visualforce rendered as PDF. The VF Page must have these css classes defined in the style tag.
*
*  .barchart_table { width: 100%; border-collapse: collapse; border:0px solid #000; }
*  .barchart_th, .barchart_td { border: 1px solid black; padding: 8px; text-align: left; }
*  .barchart_year { width: 10%; white-space: nowrap; border-right: 1px solid #000;}
*  .barchart_bar { height: 25px; width: 100%; display: table; position: relative; padding: 0px; border: 0px; }
*  .barchart_segment { height:25px; display: table-cell; }
*  .barchart_target-segment { position: relative; border: 0px; border-left: 2px solid red; display: table-cell; }
*  .barchart_target-line { position: absolute; height: 25px; width: 2px; background-color: red; top: auto; z-index:2}
*  .barchart_border { padding: 0.5px; border-left: solid 0px #062647; border-top: solid 0px #062647; border-bottom: solid 0px #062647; }
*  .barchart_borderleft { border: 0px; border-left: solid 0px #062647; }
*  .barchart_lastrow { border-bottom: 1px solid #000; }
*  .barchart_legend { border: 0px solid #000; white-space: nowrap; text-align: right;}
*
* ------------------------------------------------------------------------------------------------
*/
public class DMT_BarChartStatic {

    public class DataWrapper {
        public String legend;
        public Decimal val1;
        public Decimal val2;
        public Decimal val3;
        public Decimal val4;
        public Decimal val5;
        public Decimal target;

        public DataWrapper(String legend, Decimal val1, Decimal val2, Decimal val3, Decimal val4, Decimal val5, Decimal target) {
            this.legend = legend;
            this.val1 = val1;
            this.val2 = val2;
            this.val3 = val3;
            this.val4 = val4;
            this.val5 = val5;
            this.target = target;
        }
    }

    public class PercentageWrapper {
        public String legend;
        public Decimal val1;
        public Decimal val2;
        public Decimal val3;
        public Decimal val4;
        public Decimal val5;
        public Decimal remaining;
        public Decimal targetPercentage;

        public PercentageWrapper(String legend, Decimal val1, Decimal val2, Decimal val3, Decimal val4, Decimal val5, Decimal remaining, Decimal targetPercentage) {
            this.legend = legend;
            this.val1 = val1;
            this.val2 = val2;
            this.val3 = val3;
            this.val4 = val4;
            this.val5 = val5;
            this.remaining = remaining;
            this.targetPercentage = targetPercentage;
        }
    }

    public static Decimal findMaxValue(List<DataWrapper> data) {
        Decimal maxValue = 0;
        for (DataWrapper row : data) {
            maxValue = Math.max(maxValue, row.val1 + row.val2 + row.val3 + row.val4 + row.val5);
            maxValue = Math.max(maxValue, row.target);
        }
        //system.debug('max value: ' + maxValue);
        return roundToNextNumber(maxValue);
    }

    public static List<String> calculateXAxisValues(List<DataWrapper> data, Decimal maxChartValue) {
        List<String> xAxisValues = new List<String>();
        Decimal step = maxChartValue / 4;
        Decimal roundedStep = roundToOrderOfMagnitude(step);
        for (Integer i = 0; i <= 4; i++) {
            Decimal value = i * roundedStep;
            xAxisValues.add(formatValue(value));
        }
        return xAxisValues;
    }

    public static Decimal roundToOrderOfMagnitude(Decimal value) {
        Integer orderOfMagnitude = Math.log10(value).intValue();
        Decimal scale = Math.pow(10, orderOfMagnitude);
        return Math.ceil(value / scale) * scale;
    }

    public static Decimal roundToNextNumber(Decimal value) {
        Integer orderOfMagnitude = Math.log10(value).intValue() - 1;
        Decimal scale = Math.pow(10, orderOfMagnitude);
        return Math.ceil((value + scale) / scale) * scale;
    }

    public static String formatValue(Decimal value) {
        if (value >= 1000000000) {
            return (value / 1000000000).setScale(1) + 'B';
        } else if (value >= 1000000) {
            return (value / 1000000).setScale(1) + 'M';
        } else if (value >= 1000) {
            return (value / 1000).setScale(1) + 'K';
        } else {
            return value.setScale(1) + '';
        }
    }

    public static List<PercentageWrapper> calculatePercentages(List<DataWrapper> data, Decimal maxChartValue) {
        List<PercentageWrapper> percentages = new List<PercentageWrapper>();
        for (DataWrapper row : data) {
            Decimal total = row.val1 + row.val2 + row.val3 + row.val4 + row.val5;
            Decimal remaining = maxChartValue - total;
            Decimal targetPercentage = (row.target / maxChartValue) * 100;
            percentages.add(new PercentageWrapper(
                row.legend,
                (row.val1 / maxChartValue) * 100,
                (row.val2 / maxChartValue) * 100,
                (row.val3 / maxChartValue) * 100,
                (row.val4 / maxChartValue) * 100,
                (row.val5 / maxChartValue) * 100,
                (remaining / maxChartValue) * 100,
                targetPercentage
            ));
        }
        return percentages;
    }

    public static String generateBarChartHTML(List<DataWrapper> data) {
        Decimal maxChartValue = findMaxValue(data);
        List<String> xAxisValues = calculateXAxisValues(data, maxChartValue);
        List<PercentageWrapper> percentages = calculatePercentages(data, maxChartValue);
        Integer i = 0;

        String html = '<table cellpadding="3" cellspacing="0">';
            //+ '<tr><td colspan="2" class="barchart_year">TEST CHART</td></tr>';

        for (PercentageWrapper row : percentages) {

            i++;

            if (row.val1 > 0 || row.val2 > 0 || row.val3 > 0 || row.val4 > 0 || row.val5 > 0) {
                html += '<tr><td class="barchart_year">' + row.legend + '</td><td';

                if (i >= percentages?.size()) {
                    html += ' class="barchart_lastrow"';
                }

                html += '><div class="barchart_bar">';

                if (row.targetPercentage > 0 && row.targetPercentage < 100) {
                    Decimal roundedTargetPercentage = row.targetPercentage.setScale(2);
                    html += '<div class="barchart_target-line" style="left: ' + roundedTargetPercentage + '%;">';
                } else if (row.targetPercentage <= 0) {
                    html += '<div class="barchart_target-line" style="left: 0%;">';
                } else if (row.targetPercentage >= 100) {
                    html += '<div class="barchart_target-line" style="left: 100%;">';
                }

                html += '</div><table class="barchart_bar" cellspacing="0" celpadding="0">'
                    + '<tr>';

                if (row.val1 > 0) {
                    Decimal roundedVal1 = row.val1.setScale(2);
                    html += '<td class="barchart_segment barchart_border" style="width: ' + roundedVal1 + '%; background-color: #043263;"></td>';
                }
                if (row.val2 > 0) {
                    Decimal roundedVal2 = row.val2.setScale(2);
                    html += '<td class="barchart_segment barchart_border" style="width: ' + roundedVal2 + '%; background-color: #1464A5;"></td>';
                }
                if (row.val3 > 0) {
                    Decimal roundedVal3 = row.val3.setScale(2);
                    html += '<td class="barchart_segment barchart_border" style="width: ' + roundedVal3 + '%; background-color: #2496EA;"></td>';
                }
                if (row.val4 > 0) {
                    Decimal roundedVal4 = row.val4.setScale(2);
                    html += '<td class="barchart_segment barchart_border" style="width: ' + roundedVal4 + '%; background-color: #2DCCCD;"></td>';
                }
                if (row.val5 > 0) {
                    Decimal roundedVal5 = row.val5.setScale(2);
                    html += '<td class="barchart_segment barchart_border" style="width: ' + roundedVal5 + '%; background-color: #BDBDBD;"></td>';
                }

                Decimal roundedRemaining = row.remaining.setScale(2);
                html += '<td class="barchart_segment barchart_border" style="width: ' + roundedRemaining + '%;"></td>'
                    + '</tr>'
                    + '</table>'
                    + '</div></td></tr>';
            }
        }

        html += '<tr><td></td><td><table class="barchart_bar" cellspacing="0" celpadding="0"><tr>';

        Integer iXAxis = 0;
        for (String xaxisValue : xAxisValues) {
            if (iXAxis < xAxisValues.size() - 1) {
                html += '<td class="barchart_legend" style="width:25%;"><div class="barchart_xaxis" style="left:' + iXAxis * 25 + '%"></div>' + xaxisValue + ' EUR</td>';
            }
            iXAxis++;
        }

        html += '</tr></table></td></tr>';
        html += '</table>';

        return html;
    }
}