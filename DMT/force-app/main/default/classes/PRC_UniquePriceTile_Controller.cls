/** ********************************************************************************
* @author       JSS
* @date         02/06/2020
* @description  Controlador del componente lighning PRC_UniquePriceTile
* @Revision
********************************************************************************* */
public with sharing class PRC_UniquePriceTile_Controller {
    // ---------------
    // Public Methods
    // ---------------
   
    
    
    /**
    * @author       JSS
    * @description  Método que devuelve el registro de PricingDetail a partir del id de opportunity que recibe

    */    
    @auraEnabled
    public static PRC_Pricing_Detail__c getPricingDetail(String oppId) {
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        final List<Id> oppIdList = new List<id>{oppId};
        final list<PRC_Pricing_Detail__c> pdList = pricingLogic.getPricingDetailsDataFromList(oppIdList);
        system.debug('>>>>>>>>>> getPricingDetail oppId: ' + oppId + '. Lista de pricingDetails (' +  pdList.size() + '): ' + pdList);
        return (pdList.size() != 1 ? null : pdList.get(0));
    }


}