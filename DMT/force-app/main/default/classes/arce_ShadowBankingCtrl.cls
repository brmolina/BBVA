/**
* ____________________________________________________________________________
* Controller class for arce_ShadowBanking.cmp aura Component
* ____________________________________________________________________________
* @author      DAvid Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-10-10
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class arce_ShadowBankingCtrl {

    /**
    * @description Private constructor to avoid sonar err
    */
    public arce_ShadowBankingCtrl() {

    }

    /**
    * @description Get Client data
    * @param clientId 
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String clientId) {
        Map<String, Object> retMap = new Map<String, Object>();
        String clientActivity = '';
        String clientType = '';
        List<Local_Client__c> lstClientInfo = Arc_Utils.getAcctAndLocalClientInfo(clientId);
        if(!lstClientInfo.isEmpty()){
            Local_Client__c clientInfo = lstClientInfo[0];

            List<arce_Shadow_Banking__c> lstSbAndScra = Arc_Utils.getSbAndScraInfo(clientId);

            if(!lstSbAndScra.isEmpty()){
                arce_Shadow_Banking__c sbAndScra = lstSbAndScra[0];

                // Shadow Banking
                if(sbAndScra.Fecha_Shadow_Banking__c != null){
                    retMap.put('SBBool', sbAndScra.SB__c);
                    retMap.put('optionBankAct', sbAndScra.Option_banking_activities_GDT__c);
                    retMap.put('optionBankOrInsuranceCompany', sbAndScra.Option_consolidates_within_bank_GDT__c);
                    retMap.put('optionEUBankCorpo', sbAndScra.Option_EU_bank_corpo_GDT__c);
                    retMap.put('optionInsuranceCorpo', sbAndScra.Option_insurance_corpo_GDT__c);
                    retMap.put('optionEUInsuranceCorpo', sbAndScra.Option_EU_insurance_corpo_GDT__c);
                    retMap.put('optionMMFOrAIFs', sbAndScra.Option_MMF_or_AIFs_GDT__c);
                    retMap.put('optionRegulatedFund', sbAndScra.Option_regulated_funds_GDT__c);
                    retMap.put('optionInstitutions', sbAndScra.Option_institutions_GDT__c);
                    retMap.put('optionInsurance', sbAndScra.Option_insurance_GDT__c);
                    retMap.put('commentSB', sbAndScra.ComentSB__c);
                    retMap.put('flowSelectSB', sbAndScra.Selected_Flow_GDT__c);
                }else{
                    retMap.put('SBBool', null);
                }
                

                // SCRA
                if(sbAndScra.Fecha_SCRA__c != null){
                    retMap.put('scraBool', sbAndScra.SCRA__c);
                    retMap.put('markSCRA', sbAndScra.MarkScra__c);
                    retMap.put('commentSCRA', sbAndScra.CommentSCRA__c);
                }else{
                    retMap.put('scraBool', null);
                }
                
            }else{
                retMap.put('SBBool', null);
                retMap.put('scraBool', null);
            }

            // Iterate through DES_Activity__c and find the matching developer name to get label
            Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('Account') ;
            Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
            Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get('DES_Activity__c').getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.getValue() == clientInfo.Cib_Client__r.DES_Activity__c){
                    clientType = pickListVal.getLabel();
                }
            }
            
            retMap.put('clientType', clientType);
            retMap.put('clientInfo', clientInfo);
        }
        return retMap;
    }

    /**
    * @description checks if provided country is in european country list for insurance or banks
    * @param clientFlowId // 1,2,3 or 4
    * @param countryCode // ISO code of the country
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> checkCountryIsInList (String clientFlowId, String countryCode) {
        Map<String,String> bankCountriesSBList = ARC_utils.bankCountriesSBList();
        Map<String,String> insurerCountriesSBList = ARC_utils.insurerCountriesSBList();
        Map<String, Object> retMap = new Map<String, Object>();
        boolean countryIsInList = false;
        
        //1 - Banks, Institutions & Investment Firms
        //2 - Insurance 
        //3 - Financial Corporations engaged in Lending, Leasing...
        //4 - Funds
        if(clientFlowId == '1' || clientFlowId == '3'){
            countryIsInList = bankCountriesSBList.containsKey(countryCode);
            System.debug('Flow 1 & 3 (Banks and Financial Corp) countryIsInList Bool: ' + countryIsInList);
        }else if(clientFlowId == '2'){
            countryIsInList = insurerCountriesSBList.containsKey(countryCode);
            System.debug('Flow 2 (Insurance) countryIsInList Bool: ' + countryIsInList);
        }

        retMap.put('countryIsInList', countryIsInList);
        
        return retMap;
    }
    
    /**
    * @description insert or update Shadow Banking and SCRA information related to Clients (Account)
    * @param 
    * @return retMap Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> saveInfo (Local_Client__c localClient, Boolean sBBool, Boolean scraBool, string markSCRA, string commentarioTxt, string isScraOrSB, String optionBankAct, String optionBankOrInsuranceCompany, String optionEUBankCorpo, String optionInsuranceCorpo, String optionEUInsuranceCorpo, String optionMMFOrAIFs, String optionRegulatedFund, String optionInstitutions, String optionInsurance, String selectedFlowId) {
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String ,arce_Shadow_Banking__c> mapClientSB = new Map<String ,arce_Shadow_Banking__c>(); 
        Set<String> setClients = new Set<String>();
        List<arce_Shadow_Banking__c> lstSbScra = new List<arce_Shadow_Banking__c>();
        DateTime today = DateTime.now();
        Date consultDate = today.date();

        if(!String.isBlank(localClient.local_customer_id__c)){
            setClients = ARC_utils.getRelatedClients(localClient.local_customer_id__c);
        }
        
        if(!setClients.isEmpty()){
            //SB Selector returns a Map with the client as key and SB&SCRA object as the value 
            mapClientSB = ARC_utils.SBSelector(setClients);

            for(String clientId : setClients){
                arce_Shadow_Banking__c sbScra = new arce_Shadow_Banking__c();
                // If SB already exists, get Id
                if(mapClientSB.containsKey(clientId)){
                    sbScra.id = mapClientSB.get(clientId).Id;
                }
                
                sbScra.ClientLKP__c = clientId;
                if(isScraOrSB == 'SB'){
                    sbScra.SB__c = sBBool;
                    sbScra.Option_banking_activities_GDT__c = optionBankAct;
                    sbScra.Option_consolidates_within_bank_GDT__c = optionBankOrInsuranceCompany;
                    sbScra.Option_EU_bank_corpo_GDT__c = optionEUBankCorpo;
                    sbScra.Option_insurance_corpo_GDT__c = optionInsuranceCorpo;
                    sbScra.Option_EU_insurance_corpo_GDT__c = optionEUInsuranceCorpo;
                    sbScra.Option_MMF_or_AIFs_GDT__c = optionMMFOrAIFs;
                    sbScra.Option_regulated_funds_GDT__c = optionRegulatedFund;
                    sbScra.Option_institutions_GDT__c = optionInstitutions;
                    sbScra.Option_insurance_GDT__c = optionInsurance;
                    sbScra.Fecha_Shadow_Banking__c = consultDate;
                    sbScra.ComentSB__c = commentarioTxt;
                    sbScra.Selected_Flow_GDT__c = selectedFlowId;
                }else if (isScraOrSB == 'SCRA'){
                    sbScra.SCRA__c = scraBool;
                    sbScra.MarkScra__c = markSCRA;
                    sbScra.CommentSCRA__c = commentarioTxt;
                    sbScra.Fecha_SCRA__c = consultDate;
                }

                lstSbScra.add(sbScra);
            }

            if(!lstSbScra.isEmpty()){
                upsert lstSbScra;
            }
        }
    
        return retMap;
    }
}