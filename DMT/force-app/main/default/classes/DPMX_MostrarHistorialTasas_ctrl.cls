/**
* ____________________________________________________________________________
* Controller class for DPMX_AuthorizationDetails.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-07-30
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/


public class DPMX_MostrarHistorialTasas_ctrl {

/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_MostrarHistorialTasas_ctrl() {
		Map<String, Object> retMap = new Map<String, Object>();
    }
    /**
    * @description Get data from services
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId, String businessAgentId, String businessAuthorizesId) {
        Map<String, Object> retMap = new Map<String, Object>();

        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
        System.debug(businessAuthorizesId);
        System.debug(businessAgentId);
        user usAut = DPMX_Utils.userSelectorByIdExtUser(businessAuthorizesId);
        user usBus = DPMX_Utils.userSelectorByIdExtUser(businessAgentId);

        if(dynamicPricing.familia__c == 'Grandes_Superficies'){
          retMap.put('isGs', true);
        }else {
          retMap.put('isGs', false);
        }
        retMap.put('businessAgent', usBus.Name);
        retMap.put('businessAuthorizes', usAut.Name);

        return retMap;
    }
}