public without sharing class DMT_NBC_OppSppiTestRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    // These are the same three SPPI fields DMT_OppApprovalProcessDataRenderer already tracks under
    // 'Approval Process Data'.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{
            'DMT_SPPI_File_Uploaded__c', 'DMT_SPPI_Status__c', 'DMT_SPPI_User__c',
            'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'
        };
    }

    // ====================================================================================================
    // DATA WRAPPER (centralizes values)
    // ====================================================================================================
    private class SppiTestData {
        public String fileUploaded = '';
        public String sppiTestStat = '';
        public String user = '';

        public SppiTestData(DMT_ViewController.LineDataWrapper data) {
            this.fileUploaded = data.opportunity.DMT_SPPI_File_Uploaded__c == null ? '': (data.opportunity.DMT_SPPI_File_Uploaded__c ? 'Yes' : 'No');
            this.sppiTestStat = DMT_FormattingUtils.checkNull(data.opportunity.DMT_SPPI_Status__c);
            this.user = DMT_FormattingUtils.checkNull(data.opportunity.DMT_SPPI_User__c);
        }
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            SppiTestData vals = new SppiTestData(data);

            String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'

                        + '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 2px;">'
                        + 'SPPI TEST'
                        + '</div>'

                        + '<div style="color: #888888; font-size: 10px; font-style: italic; margin-bottom: 12px;">'
                        + 'In application of the new IFRS 9 regulation all new deals that are presented to the NBC Passed'
                        + '</div>'

                        + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: left;">'
                        + '<colgroup>'
                            + '<col style="width: 15%;">'
                            + '<col style="width: 15%;">'
                            + '<col style="width: 18%;">'
                            + '<col style="width: 15%;">'
                            + '<col style="width: 7%;">'
                            + '<col style="width: 30%;">'
                        + '</colgroup>'
                        + '<tr>'
                        + '<td style="color: #004481; padding: 4px 6px 4px 0; vertical-align: top;">File Uploaded</td>'
                        + '<td style="color: #004481; padding: 4px 6px 4px 0; vertical-align: top;">' + vals.fileUploaded + '</td>'
                        + '<td style="color: #004481; padding: 4px 6px 4px 0; vertical-align: top;">SPPI Test Stat</td>'
                        + '<td style="color: #004481; padding: 4px 6px 4px 0; vertical-align: top;">' + vals.sppiTestStat + '</td>'
                        + '<td style="color: #004481; padding: 4px 6px 4px 0; vertical-align: top;">User</td>'
                        + '<td style="color: #004481; padding: 4px 0 4px 0; vertical-align: top;">' + vals.user + '</td>'
                        + '</tr>'
                        + '</table>'
                        + '</div>';

            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppSppiTestRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}