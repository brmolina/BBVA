public with sharing class DMT_CommercialProcessDataRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OppCommercialProcessDataRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try{
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Commercial Process renderer for record type Id: ' + data.recordTypeId);
            }
            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Commercial Process Data</h2>'
                + '</div>';

            html += renderer.renderHtml(data);

            if (data.opportunity != null && data.opportunity.CloseDate != null) {
                List<DMT_FormattingUtils.DisplayField> fieldsToRender = new List<DMT_FormattingUtils.DisplayField>{
                    new DMT_FormattingUtils.DisplayField('Estimated Closing Date', DMT_FormattingUtils.checkNull(data.opportunity.CloseDate))
                };

                html += '<div class="slds-scope">'
                    + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                    + '</div>'
                    + '</br></br>';
            }

            return html;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return new Map<String,Object>();
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Commercial Process renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderPdfJson(data);
        }catch (Exception e){
            System.debug(e.getMessage());
            return new Map<String, Object>();
        }
    }
}