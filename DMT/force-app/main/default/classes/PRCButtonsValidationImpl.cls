/**
* @author GlobalDesktop
*/
global with sharing class PRCButtonsValidationImpl implements dwp_dbpn.DynamicFlowValidationInterface {

    /**
    * @author GlobalDesktop
    * Description: Si se queda cacheada la pestaña de oportunidades y aparece el botón pero en realidad no se tendría que mostrar dicho botón,
                   con esta clase puedo controlar que muestre un mensaje y no haga nada al pinchar en el botón.
    */
    global static List<String> getErrorMessagesList(String recordId, String source, String validationClass) {
        system.debug('>>>>>>>>> ValidationClass: ' + validationClass);
        List<String> lstErrorMessage = new List<String>();


        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();

        if(source == LABEL.Opportunity_Name) {
            system.debug('>>>>>>>>> Es Oportunitdad. ValidationClass: ' + validationClass);
            final Map<Id, OpportunityLineItem> mapProducts = new Map<Id, OpportunityLineItem>([SELECT Id, DES_Product_Family__c, opportunity_stage_type__c, solution_name_path_desc__c, solution_classification_desc__c,
                                     OpportunityId, opportunity.gf_amiweb_opportunity_id__c, opportunity.gf_workflow_opportunity_id__c
                                     FROM OpportunityLineItem WHERE OpportunityId = :recordId]);

            Opportunity opp = new Opportunity();
            PRCButtonsValidationImpl.validationhelper( mapProducts, opp);
            if (PRCButtonsValidationImpl.validationhelperPricingDetails(mapProducts, opp, validationClass, pricingLogic)) {
                lstErrorMessage.add('In order to use the "Price Details" button, the opportunity must only have a single "IBF" or "GTB" product.');
            }

            if (PRCButtonsValidationImpl.validationhelperWorkflow(mapProducts, opp, validationClass, pricingLogic)) {
                lstErrorMessage.add('Something changed in the opportunity record, you cannot use "Submit for approval process" button. Please refresh opportunity page.');
            }

            if (PRCButtonsValidationImpl.validationhelperDownload(mapProducts, opp, validationClass, pricingLogic)) {
                lstErrorMessage.add('Something changed in the opportunity record, you cannot use "' + Label.PRC_Download_Pricing + '" button. Please refresh opportunity page.');
            }
        }
		system.debug('>>>>>> PRCButtonsValidationImpl. lstErrorMessage :' + lstErrorMessage);
        return lstErrorMessage;
    }

   /**
    * @author GlobalDesktop
    * Description: Se separa logica en varios methods para bajar la complejidad ciclomática.
    */
    public static void validationhelper(Map<Id, OpportunityLineItem> mapProducts, Opportunity opp) {
        if (mapProducts.size() == 1) {
            opp.id = mapProducts.values().get(0).OpportunityId;
            opp.gf_amiweb_opportunity_id__c = mapProducts.values().get(0).opportunity.gf_amiweb_opportunity_id__c;
            opp.gf_workflow_opportunity_id__c = mapProducts.values().get(0).opportunity.gf_workflow_opportunity_id__c;
        }
    }

    /**
    * @author GlobalDesktop
    * Description: Se separa logica en varios methods para bajar la complejidad ciclomática.
    */
    public static Boolean validationhelperPricingDetails(Map<Id, OpportunityLineItem> mapProducts, Opportunity opp, String validationClass, PRCPricingUtils pricingLogic) {
        Boolean resultado;
        if ((validationClass == 'Pricing_details') && (mapProducts.values().get(0).opportunity_stage_type__c == Label.DES_Draft || !pricingLogic.displayAmiwebButton(opp, mapProducts.values())) ) {
            resultado = true;
            system.debug('>>>>> No se puede añadir botón de Pricing Details porque algo cambió en el registro de Oportunidad');
        } else {
            resultado = false;
        }
        return resultado;
    }

   /**
    * @author GlobalDesktop
    * Description: Se separa logica en varios methods para bajar la complejidad ciclomática.
    */
    public static Boolean validationhelperWorkflow(Map<Id, OpportunityLineItem> mapProducts, Opportunity opp, String validationClass, PRCPricingUtils pricingLogic) {
        Boolean resultado;
        if ((validationClass == 'Send_to_Workflow') && (mapProducts.values().get(0).opportunity_stage_type__c == Label.DES_Draft || !pricingLogic.displayWorkflowButton(opp, mapProducts.values())) ) {
            resultado = true;
            system.debug('>>>>> No se puede añadir botón de Pricing Details porque algo cambió en el registro de Oportunidad');
        } else {
            resultado = false;
        }
        return resultado;
    }

  /**
  * @author GlobalDesktop
  * Description: Se separa logica en varios methods para bajar la complejidad ciclomática.
  */
  public static Boolean validationhelperDownload(Map<Id, OpportunityLineItem> mapProducts, Opportunity opp, String validationClass, PRCPricingUtils pricingLogic) {
    Boolean resultado;
    if (validationClass == 'Download_Pricing' && (mapProducts.values().get(0).opportunity_stage_type__c == Label.DES_Draft || !pricingLogic.displayPricingSection(opp, mapProducts.values())) ) {
      resultado = true;
      system.debug('>>>>> No se puede añadir botón de Download PDF PRicing porque algo cambió en el registro de Oportunidad');
    } else {
      resultado = false;
    }
    return resultado;
  }
}