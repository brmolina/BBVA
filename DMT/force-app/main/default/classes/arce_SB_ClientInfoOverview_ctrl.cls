/**
* ------------------------------------------------------------------------------------------------
* @Name     arce_SB_ClientInfoOverview_ctrl
* @Author   david.otero.carcia@bbva.com
* @Date     Created: 2024-11-08
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: arce_SB_ClientInfoOverview_ctrl
* -------------------------------------------------------------------------------------------------
*/
global with sharing class arce_SB_ClientInfoOverview_ctrl {
    @TestVisible
    private arce_SB_ClientInfoOverview_ctrl() {

    }

    /**
    * @description Get data from services
    * @param 
    * @return retMap accountLst
    */
    /* @AuraEnabled
    public static Map<String,Object> getInitialData (string accountRepresentativeId) {

        Map<String, Object> retMap = new Map<String, Object>();
        List<arce__Account_has_Analysis__c> ahaLst = new List<arce__Account_has_Analysis__c>();
        List<accinfo> accinfoLst = new List<accinfo>();
        List<accinfo> accinfoLstToShow = new List<accinfo>();
        accinfo accInfo = new accinfo();
        boolean succes = true;
        List<arce_Shadow_Banking__c> sbLst = new List<arce_Shadow_Banking__c>();
        Set<Id> agaIds = new Set<Id>();
        Map<String,String> insurerCountriesSBList =ARC_utils.bankCountriesEUSBList();

        ahaLst =ARC_utils.RepresentativeIfisList(accountRepresentativeId);

        for(arce__Account_has_Analysis__c aha : ahaLst){
            agaIds.add(aha.Id);
        }

        sbLst = ARC_utils.SBSelectorLst(agaIds);

        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('arce__AHA_Extension__c') ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('arce__IFIS_ClientType__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            for(arce__Account_has_Analysis__c aha : ahaLst){
                accInfo = new accinfo();
                if(pickListVal.getValue() == aha.arce__AHA_Extension__r.arce__IFIS_ClientType__c){
                    accInfo.aha = aha;
                    accInfo.type = pickListVal.getLabel();
                    accInfo.isSCRA = (pickListVal.getValue() == 'A');
                    accinfoLst.add(accInfo);
                }
            }
        }

        for(integer i = 0; i!= accinfoLst.size(); i++){
            for(arce_Shadow_Banking__c sb : sbLst){
                if(accinfoLst.get(i).aha.DES_Local_Client__r.Cib_Client__c == sb.ClientLKP__c){
                    accinfoLst.get(i).SB = sb.SB__c;
                    accinfoLst.get(i).scra = sb.SCRA__c;
                    break;
                }
            }
        }
        
        List<String> listId = new List<String>();
        Set<String> sinDuplicados = new Set<String>();
        for(accinfo accInf : accinfoLst){
            sinDuplicados.add(accInf.aha.DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c);
        }
        
        for(Integer i = 0; i < accinfoLst.size();i++) {
            if(sinDuplicados.contains(accinfoLst[i].aha.DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c)) {
                accinfoLstToShow.add(accinfoLst[i]);
                sinDuplicados.remove(accinfoLst[i].aha.DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c);
            }
        }

        if(accinfoLstToShow == null || accinfoLstToShow.size() == 0){
            succes = false;
        }

        retMap.put('succes', succes);
        retMap.put('acctList', accinfoLstToShow);

        return retMap;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap accountLst
    */
    /* @AuraEnabled
    public static Map<String,Object> getSearchData (string accountRepresentativeId, string field, string name) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<arce__Account_has_Analysis__c> ahaLst = new List<arce__Account_has_Analysis__c>();
        List<accinfo> accinfoLst = new List<accinfo>();
        List<accinfo> accinfoLstToShow = new List<accinfo>();
        accinfo accInfo = new accinfo();
        boolean succes = true;
        List<arce_Shadow_Banking__c> sbLst = new List<arce_Shadow_Banking__c>();
        Set<Id> agaIds = new Set<Id>();
        Map<String,String> insurerCountriesSBList =ARC_utils.bankCountriesEUSBList();

        if(name == null || name == ''){
            ahaLst =ARC_utils.RepresentativeIfisList(accountRepresentativeId);
        }else{
            if(field == 'FIC code'){
                ahaLst =ARC_utils.RepresentativeIfisListByFICCode(accountRepresentativeId, name);
            }else if(field == 'Representative client name'){
                ahaLst =ARC_utils.RepresentativeIfisListByAccName(accountRepresentativeId, name);
            }else if(field == 'Type'){
                ahaLst =ARC_utils.RepresentativeIfisListByType(accountRepresentativeId, name);
            }else if(field == '' || field == null){
                ahaLst =ARC_utils.RepresentativeIfisList(accountRepresentativeId);
            }else {
                ahaLst =ARC_utils.RepresentativeIfisList(accountRepresentativeId);
            }
        }

        for(arce__Account_has_Analysis__c aha : ahaLst){
            agaIds.add(aha.Id);
        }

        sbLst = ARC_utils.SBSelectorLst(agaIds);

        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('arce__AHA_Extension__c') ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('arce__IFIS_ClientType__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            for(arce__Account_has_Analysis__c aha : ahaLst){
                accInfo = new accinfo();
                if(pickListVal.getValue() == aha.arce__AHA_Extension__r.arce__IFIS_ClientType__c){
                    accInfo.aha = aha;
                    accInfo.type = pickListVal.getLabel();
                    accInfo.isSCRA = (pickListVal.getValue() == 'A');
                    accinfoLst.add(accInfo);
                }
            }
        }

        for(integer i = 0; i!= accinfoLst.size(); i++){
            for(arce_Shadow_Banking__c sb : sbLst){
                if(accinfoLst.get(i).aha.DES_Local_Client__r.Cib_Client__c == sb.ClientLKP__c){
                    accinfoLst.get(i).SB = sb.SB__c;
                    accinfoLst.get(i).scra = sb.SCRA__c;
                    break;
                }
            }
        }

        List<String> listId = new List<String>();
        Set<String> sinDuplicados = new Set<String>();
        for(accinfo accInf : accinfoLst){
            sinDuplicados.add(accInf.aha.DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c);
        }
        
        for(Integer i = 0; i < accinfoLst.size();i++) {
            if(sinDuplicados.contains(accinfoLst[i].aha.DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c)) {
                accinfoLstToShow.add(accinfoLst[i]);
                sinDuplicados.remove(accinfoLst[i].aha.DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c);
            }
        }

        if(accinfoLstToShow == null || accinfoLstToShow.size() == 0){
            succes = false;
        }
        
        retMap.put('succes', succes);
        retMap.put('acctList', accinfoLstToShow);

        return retMap;
    } */

    /* public class accinfo {
        @AuraEnabled
        public boolean SB {get; set;}
        @AuraEnabled
        public boolean scra {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public arce__Account_has_Analysis__c aha {get; set;}
        @AuraEnabled
        public boolean isSCRA {get; set;}
    } */
}