// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultPassportRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return '<div>Features data not provided</div>';
        }
        try{
            List<Map<String, Object>> approvalFeatures = new List<Map<String, Object>>();
            List<Map<String, Object>> otherFeatures = new List<Map<String, Object>>();
            for (Map<String, Object> feature : data.featuresList) {
                String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                if (name != null && name.toLowerCase().contains('approval')) {
                    approvalFeatures.add(feature);
                } else {
                    otherFeatures.add(feature);
                }
            }
            String table = '';
            if (!otherFeatures.isEmpty()) {
                table += '<div>'
                    + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Passport</h2>'
                    + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                    // Replace CSS variables with the equivalent hex color (#f3f3f3) to avoid rendering issues
                    +'<tr data-dmt-table-header="true">'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Feature</td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Capability</td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Workflow</td>'
                    + '</tr>';
                Integer i = 0;
                for (Map<String, Object> feature : otherFeatures) {
                    String colorWF = DMT_FormattingUtils.getWorkflowColor(feature, data.steps);
                    if (i == 0) { colorWF = 'NOPINTAR'; }
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    stateName = stateName != 'WHITE' ? stateName : 'NOPINTAR';
                    table += '<tr data-dmt-table-row="true">'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + name + '</strong></td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(colorWF) + '</td>'
                        + '</tr>';
                    i++;
                }
                table += '</table></div>&nbsp;</br>';
            }
            if (!approvalFeatures.isEmpty()) {
                table += '<div>'
                    + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr data-dmt-table-title="true">'
                    + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Approval Process</strong></td>'
                    + '</tr>'
                    // Replace CSS variables with the equivalent hex color (#f3f3f3) to avoid rendering issues
                    +'<tr data-dmt-table-header="true">'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Feature</td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Capability</td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Workflow</td>'
                    + '</tr>';
                Integer i = 0;
                for (Map<String, Object> feature : approvalFeatures) {
                    String colorWF = DMT_FormattingUtils.getWorkflowColor(feature, data.steps);
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    stateName = stateName != 'WHITE' ? stateName : 'NOPINTAR';
                    table += '<tr data-dmt-table-row="true">'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + name + '</strong></td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(colorWF) + '</td>'
                        + '</tr>';
                    i++;
                }
                table += '</table></div></br></br>';
            }
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultPassportRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}