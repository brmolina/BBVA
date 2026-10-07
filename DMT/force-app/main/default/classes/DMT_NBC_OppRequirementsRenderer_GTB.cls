/**
 * @description Renderer for the GTB Requirements and Risks section.
 */
public without sharing class DMT_NBC_OppRequirementsRenderer_GTB implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    /**
     * @description Builds the HTML for the GTB Requirements and Risks section.
     * @param data Line data wrapper used by the renderer.
     * @return HTML string.
     */
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity == null || data.oppClient == null) {
            return '<div>Opportunity data not provided</div>';
        }

        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            if (data.opportunity.DMT_Threshold_Type__c == 'Local') {
                return '';
            }

            // GTB Requirements content is intentionally not implemented yet — planned for a separate,
            // future ticket. This stub only exists so the delegator has a renderer to route GTB to.
            return '';
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppRequirementsRenderer_GTB renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}