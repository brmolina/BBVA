public without sharing class DMT_LineSanctionApprovalInfoRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER: Build the DisplayField List
    // ==========================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        
        // Format Term (Safely append 'month(s)' if it doesn't already exist)
        String termLabel = '';
        if (String.isNotBlank(data.line.Line_Term__c)) {
            termLabel = data.line.Line_Term__c + (data.line.Line_Term__c.containsIgnoreCase('month') ? '' : ' month(s)');
        }
        String busTermLabel = '';
        if (data.line.DMT_Business_Approval_Term_n__c != null) {
            busTermLabel = String.valueOf(data.line.DMT_Business_Approval_Term_n__c) + ' month(s)';
        }

        // Format Percentages (Leveraging your existing formatPercent utility which multiplies by 100)
        String raroec = data.line.gf_min_raroec_wo_fcg_per__c != null ? DMT_FormattingUtils.formatPercent(data.line.gf_min_raroec_wo_fcg_per__c) : '';
        String rorc = data.line.gf_min_rorc_wo_fcg_per__c != null ? DMT_FormattingUtils.formatPercent(data.line.gf_min_rorc_wo_fcg_per__c) : '';

        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Line Id:', DMT_FormattingUtils.checkNull(data.line.Line_Id__c)),
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(data.line.Name)),
            

            // Row 2
            new DMT_FormattingUtils.DisplayField('Entific', DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c)),
            new DMT_FormattingUtils.DisplayField('Risk Approval Start Date', DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c)),


            // Row 3
            new DMT_FormattingUtils.DisplayField('Risk Approval End Date', DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c)),
            new DMT_FormattingUtils.DisplayField('Risk Approval Term', termLabel),
            

            // Row 4
            new DMT_FormattingUtils.DisplayField('Business Approval Start Date', DMT_FormattingUtils.changeDateFormat(data.line.DMT_Bussiness_Approved_Date__c)),
            new DMT_FormattingUtils.DisplayField('Business Approval End Date', DMT_FormattingUtils.changeDateFormat(data.line.DMT_Business_Approved_End_Date__c)),
            
            // Row 5 (Using the clean, updated labels!)
            new DMT_FormattingUtils.DisplayField('Business Approval Term', busTermLabel),
            new DMT_FormattingUtils.DisplayField('Minimum percentage RAROEC without financing', raroec),
            

            // Row 6
            new DMT_FormattingUtils.DisplayField('Minimum percentage RORC without financing', rorc),
            new DMT_FormattingUtils.DisplayField('Approval Comments', DMT_FormattingUtils.checkNull(data.line.DMT_Comments__c))

            //new DMT_FormattingUtils.DisplayField('', '') // Empty space to balance the 2-column grid

            
        };
    }

    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Approval Info data not provided</div>';
        }

        try {
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Info</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionApprovalInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}