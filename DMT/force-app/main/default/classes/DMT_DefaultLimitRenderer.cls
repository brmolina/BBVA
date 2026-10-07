// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultLimitRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return '<div>Features data not provided</div>';
        }
        try {
            String table = '';
            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                if (i == 0) {
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    if (String.isNotBlank(stateName) && new List<String>{'RED', 'YELLOW', 'GREEN'}.contains(stateName)) {
                        table += '<table data-dmt-table="true" class="style-table" style="width: 100%; border-collapse: collapse; margin-bottom: 10px;">'
                            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="font-size: 16px; color: #004481; font-weight: bold; padding: 4px; text-align: left;">' + name + '</td>'
                            + '<td data-dmt-cell="true" style="text-align: right; padding: 4px;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td></tr>'
                            + '</table>';
                    }
                    table += '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">';
                    List<Map<String, Object>> validationLimitList = DMT_FormattingUtils.getListMap(feature, 'validations');
                    for (Map<String, Object> validationLimit : validationLimitList) {
                        table += '<tr data-dmt-table-row="true">'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; white-space: normal;"><strong>' + DMT_FormattingUtils.checkNull(validationLimit?.get('name')) + '</strong></td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; white-space: normal;">' + DMT_FormattingUtils.renderTrafficLightSingle(DMT_FormattingUtils.checkNull(validationLimit?.get('state'))) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; white-space: normal;">' + DMT_FormattingUtils.checkNull(validationLimit?.get('message')) + '</td>'
                            + '</tr>';
                    }
                    table += '</table></br></br>';
                }
            }
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}