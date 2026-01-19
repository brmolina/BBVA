/**
* ____________________________________________________________________________
* Controller class for DPMX_SimulationResult.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-22
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_SimulationResult_Ctrl {
	/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_SimulationResult_Ctrl() {

    }
    /**
    * @description ??????????????????????
    * @param recordId : Client Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT Id,
                                                        Client_Information__c,
                                                        Devices__c,
                                                        Simulation_Result__c
                                                    FROM DPMX_Dynamic_Pricing__c
                                                    WHERE Id = :recordId];
        retMap.put('success', true);
        retMap.put('dynamicPricing', dynamicPricing);
        return retMap;
    }
}