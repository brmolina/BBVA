public with sharing class DMT_OppCommercialProcessDataRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Error: Opportunity data not provided</div>';
        }
         try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            String table = '';
            //String table = '<div>Building Opp Commercial Process Data component....</div>';
            // Add Commercial Process Data section
            return table;
        } catch (Exception e){
            //System.debug('Error in DMT_OppCommercialProcessDataRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            return new Map<String, Object>();
        } catch (Exception e){
            //System.debug('Error in DMT_OppCommercialProcessDataRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_OppCommercialProcessDataRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}