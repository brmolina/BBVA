/**
* ____________________________________________________________________________
* Controller class for DPMX_AuthorizationDetails.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-05-04
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/

public class DPMX_AuthorizationDetails_ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_AuthorizationDetails_ctrl() {
		Map<String, Object> retMap = new Map<String, Object>();
    }
    /**
    * @description Get data from services
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_authorization__c coments = [SELECT LKP_Dynamic_Pricing__c,
                                                LKP_Dynamic_Pricing__r.Name, 
                                                OwnerFullName__c, 
                                                STR_AuthBai__c, 
                                                STR_AuthCredit__c, 
                                                STR_AuthDebit__c, 
                                                STR_AuthInternational__c, 
                                                STR_AuthProfitability__c, 
                                                STR_AuthResult__c, 
                                                isGs__c,
                                                STR_BaseCredit__c,
                                                STR_BaseDebit__c,
                                                STR_BaseInter__c,
                                                STR_BaseRenta__c,
                                                STR_BaseBai__c,
                                                STR_AuthFamily__c
                                          FROM DPMX_authorization__c
                                          WHERE Id =:recordId];

        retMap.put('authTypeName', coments.LKP_Dynamic_Pricing__r.Name);
        retMap.put('authSolicitudeName', coments.OwnerFullName__c);
        retMap.put('authBai', coments.STR_AuthBai__c);
        retMap.put('authCredit', coments.STR_AuthCredit__c);
        retMap.put('authDebit', coments.STR_AuthDebit__c);
        retMap.put('authInternational', coments.STR_AuthInternational__c);
        retMap.put('authProfitability', coments.STR_AuthProfitability__c);
        retMap.put('authResult', coments.STR_AuthResult__c);
        retMap.put('isGs', coments.isGs__c);
        retMap.put('creditBase', coments.STR_BaseCredit__c);
        retMap.put('debitBase', coments.STR_BaseDebit__c);
        retMap.put('internationalBase', coments.STR_BaseInter__c);
        retMap.put('rentaBase', coments.STR_BaseRenta__c);
        retMap.put('baiBase', coments.STR_BaseBai__c);
        retMap.put('authFamily', coments.STR_AuthFamily__c);

        return retMap;
    }
}