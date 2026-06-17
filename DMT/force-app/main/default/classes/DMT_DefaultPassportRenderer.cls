public with sharing class DMT_DefaultPassportRenderer implements DMT_ViewRenderer {
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
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
/*                     + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: var(--slds-g-color-neutral-base-1, var(--lwc-colorBackground,rgb(243, 243, 243))); font-weight: bold"><strong>Feature</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: var(--slds-g-color-neutral-base-1, var(--lwc-colorBackground,rgb(243, 243, 243))); font-weight: bold"><strong>Feature</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: var(--slds-g-color-neutral-base-1, var(--lwc-colorBackground,rgb(243, 243, 243))); font-weight: bold"><strong>Workflow</strong></td>'
                    + '</tr>'; */
                    // Sustituimos las variables por el color hexadecimal equivalente (#f3f3f3) para evitar problemas de renderizado en PDF
                    +'<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Feature</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Capability</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Workflow</td>'
                    + '</tr>';
                Integer i = 0;
                for (Map<String, Object> feature : otherFeatures) {
                    String colorWF = DMT_FormattingUtils.getWorkflowColor(feature, data.steps);
                    if (i == 0) { colorWF = 'NOPINTAR'; }
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    stateName = stateName != 'WHITE' ? stateName : 'NOPINTAR';
                    table += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + name + '</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(colorWF) + '</td>'
                        + '</tr>';
                    i++;
                }
                table += '</table></div>&nbsp;</br>';
            }
            if (!approvalFeatures.isEmpty()) {
                table += '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Approval Process</strong></td>'
                    + '</tr>'
/*                     + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: var(--slds-g-color-neutral-base-1, var(--lwc-colorBackground,rgb(243, 243, 243))); font-weight: bold"><strong>Feature</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: var(--slds-g-color-neutral-base-1, var(--lwc-colorBackground,rgb(243, 243, 243))); font-weight: bold"><strong>Capability</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: var(--slds-g-color-neutral-base-1, var(--lwc-colorBackground,rgb(243, 243, 243))); font-weight: bold"><strong>Workflow</strong></td>'
                    + '</tr>'; */
                    // Sustituimos las variables por el color hexadecimal equivalente (#f3f3f3) para evitar problemas de renderizado en PDF
                    +'<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Feature</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Capability</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #f3f3f3; font-weight: bold;">Workflow</td>'
                    + '</tr>';
                Integer i = 0;
                for (Map<String, Object> feature : approvalFeatures) {
                    String colorWF = DMT_FormattingUtils.getWorkflowColor(feature, data.steps);
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    stateName = stateName != 'WHITE' ? stateName : 'NOPINTAR';
                    table += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + name + '</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.renderTrafficLight(colorWF) + '</td>'
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

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListPassport = new List<Object>();
            Map<String, Object> passportComponent = new Map<String, Object>();
    
            // Table styles
            Map<String, Object> stylesTablePass = new Map<String, Object>();
            stylesTablePass.put('fontSize', 8);
            Map<String, Object> marginTable = new Map<String, Object>();
            marginTable.put('top', 1);
            marginTable.put('bottom', 1);
            stylesTablePass.put('margin', marginTable);
            Map<String, Object> lineWidthItem = new Map<String, Object>();
            lineWidthItem.put('top', 0.1);
            lineWidthItem.put('bottom', 0.1);
            stylesTablePass.put('lineWidth', lineWidthItem);
    
            // Add a page break before
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 30
            };
            
            contentListPassport.add(pageBreak);
    
            // Title
            contentListPassport.add(DMT_Create_Pdf_Controller.createTitle('Passport'));
    
            // Split features
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
    
            // Table for other features
            if (!otherFeatures.isEmpty()) {
                List<List<String>> headers = new List<List<String>>();
                List<String> listHeaders = new List<String>{'Feature', 'Capability', 'Workflow'};
                headers.add(listHeaders);
                Map<String, Object> tablePassport = new Map<String, Object>();
                List<Object> body = new List<Object>();
                Integer i = 0;
                System.debug('passportComponent: otherFeatures=' + JSON.serialize(otherFeatures));
                for (Map<String, Object> feature : otherFeatures) {
                    System.debug('passportComponent: feature=' + JSON.serialize(feature));
                    String colorWF = DMT_FormattingUtils.getWorkflowColor(feature, data.steps);
                    if (i == 0) { colorWF = 'NOPINTAR'; }
                    List<Object> row = new List<Object>();
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    row.add(name);
    
                    // Capability column
                    Object capability = DMT_FormattingUtils.createTrafficLightJson(stateName, '');
                    row.add(capability);
    
                    // Workflow column
                    Object workflow = '';
                    if (!colorWF.contains('NOPINTAR') && !DMT_FormattingUtils.createTrafficLightJson(colorWF, '').isEmpty()) {
                        workflow = DMT_FormattingUtils.createTrafficLightJson(colorWF, '');
                    }
                    row.add(workflow);
            
                    System.debug('passportComponent: name=' + name + ', stateName=' + stateName + ', colorWF=' + colorWF);
                    System.debug('passportComponent: DMT_FormattingUtils.createTrafficLightJson(stateName)=' + DMT_FormattingUtils.createTrafficLightJson(stateName, ''));
                    System.debug('passportComponent: DMT_FormattingUtils.createTrafficLightJson(colorWF)=' + DMT_FormattingUtils.createTrafficLightJson(colorWF, ''));
                    System.debug('passportComponent: row before add=' + row);
                    if (!row.isEmpty()) { body.add(row); }
                    i++;
                }
                Map<String, Object> featureColumnStyles = new Map<String, Object>();
    
                Map<String, Object> featureColumn0 = new Map<String, Object>();
                featureColumn0.put('halign', 'left');
                featureColumn0.put('cellWidth', 100); // Set width in points (number) or 'auto', 'wrap'
                featureColumnStyles.put('0', featureColumn0);
    
                tablePassport.put('margin', marginTable);
                tablePassport.put('style', stylesTablePass);
                tablePassport.put('columnStyles', featureColumnStyles);
                tablePassport.put('body', body);
                tablePassport.put('head', headers);
                tablePassport.put('type', 'table');
                contentListPassport.add(tablePassport);
            }
    
            // Table for approval features
            if (!approvalFeatures.isEmpty()) {
                List<List<String>> headers = new List<List<String>>();
    
                //CREATE TITLE SECTION
                contentListPassport.add(pageBreak);
                List<Object> titleSection = new List<Object>();
                titleSection = DMT_Create_Pdf_Controller.createTitleSection('Approval Process');
                contentListPassport.add(titleSection[0]);
                contentListPassport.add(titleSection[1]);
    
                List<String> listHeaders = new List<String>{'Feature', 'Capability', 'Workflow'};
                headers.add(listHeaders);
                Map<String, Object> tablePassport = new Map<String, Object>();
                List<Object> body = new List<Object>();
                Integer i = 0;
                for (Map<String, Object> feature : approvalFeatures) {
                    String colorWF = DMT_FormattingUtils.getWorkflowColor(feature, data.steps);
                    if (i == 0) { colorWF = 'NOPINTAR'; }
                    List<Object> row = new List<Object>();
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    row.add(name);
                    row.add(DMT_FormattingUtils.createTrafficLightJson(stateName, ''));
                    if (!colorWF.contains('NOPINTAR') && !DMT_FormattingUtils.createTrafficLightJson(colorWF, '').isEmpty()) {
                        row.add(DMT_FormattingUtils.createTrafficLightJson(colorWF, ''));
                    }
                    if (!row.isEmpty()) { body.add(row); }
                    i++;
                }
    
                Map<String, Object> approvalColumnStyles = new Map<String, Object>();
    
                Map<String, Object> approvalColumn0 = new Map<String, Object>();
                approvalColumn0.put('halign', 'left');
                approvalColumn0.put('cellWidth', 100); // Set width in points (number) or 'auto', 'wrap'
                approvalColumnStyles.put('0', approvalColumn0);
    
                tablePassport.put('margin', marginTable);
                tablePassport.put('style', stylesTablePass);
                tablePassport.put('columnStyles', approvalColumnStyles);
                tablePassport.put('body', body);
                tablePassport.put('head', headers);
                tablePassport.put('type', 'table');
                contentListPassport.add(tablePassport);
            }
    
            passportComponent.put('content', contentListPassport);
            passportComponent.put('name', 'Passport');
            return passportComponent;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultPassportRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultPassportRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}