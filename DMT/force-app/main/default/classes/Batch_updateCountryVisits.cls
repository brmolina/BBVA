/*********************************************************************************
Name:            DES_Batch_firstUpdateRevenues
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------
0.1            21/03/2019      Global Desktop    Batch que actualiza campos de la visita en función del metadata oppCountry
***********************************************************************************/
public without sharing class Batch_updateCountryVisits implements Database.Batchable<Sobject>, Database.Stateful {

    /*
        ´Query to be executed
    */
    private static List<String> lstCodes = new List<String>();
     /*
        ´Query to be executed
    */
    private final String pQuery;

     /*
    * @author Global Desktop
    * @description Recupera información de la tabla de denorm opportunity
    */
    public Batch_updateCountryVisits() {
        pQuery = 'SELECT Id, Name, dwp_kitv__account_id__c, dwp_kitv__country_name__c FROM dwp_kitv__Visit__c WHERE dwp_kitv__country_name__c = \'\'' + (Test.isRunningTest() ? ' LIMIT 1000' : '');
    }
    /*
    * @author Global Desktop
    * @description Ejecuta la query
    */
    public Database.QueryLocator start(Database.BatchableContext bcd) {
        System.debug(':::QueryLocator:');
        System.debug(':::result: ' + Database.getQueryLocator(pQuery));
        return Database.getQueryLocator(pQuery);
    }
    /*
    * @author Global Desktop
    * @description Execute para recalcular campos de los clientes asociadas a las oportunidades
    */
    public void execute(Database.BatchableContext bcd,List<dwp_kitv__Visit__c> scope) {
        System.debug(':::execute:');
        getPickListValuesIntoList('dwp_kitv__Visit__c', 'dwp_kitv__country_name__c');
        final Set<Id> setAcc = populateSetAcc(scope);
        final Map<Id, Account> mapAcc  = populateMapAcc(setAcc);
        final List<dwp_kitv__Visit__c> lstNewVisits = putCountryPerVisit(scope, mapAcc);
        update lstNewVisits;
    }
     /*
    * @author Global Desktop
    * @description Method finish del batch
    */
    public void finish(Database.BatchableContext bcd) {
        System.debug(':::finish:');
    }

     /*
    * @author Global Desktop
    * @description Method populateSetAcc
    */
    private Set<Id> populateSetAcc(List<dwp_kitv__Visit__c> scope) {
        System.debug(':::populateSetAcc:');
        final Set<Id> setAcc = new Set<Id>();
        for(dwp_kitv__Visit__c visit : scope) {
            if(visit.dwp_kitv__account_id__c != null) {
                setAcc.add(visit.dwp_kitv__account_id__c);
            }
        }
        System.debug(':::::setAcc:: ' + setAcc);
        return setAcc;
    }
    /*
    * @author Global Desktop
    * @description Method populateMapAcc
    */
    private Map<Id,Account> populateMapAcc(Set<Id> setAcc) {
        System.debug(':::populateMapAcc:');
        // List<Account> lstACC = [SELECT Id, DES_Country_Client__c FROM Account];
        final Map<Id, Account> mapAcc = new Map<Id, Account>([SELECT Id, DES_Country_Client__c FROM Account WHERE Id IN :setAcc]);
        System.debug(':::::mapAcc:: ' + mapAcc);
        return mapAcc;
    }
    /*
    * @author Global Desktop
    * @description Method putCountryPerVisit
    */
    private List<dwp_kitv__Visit__c> putCountryPerVisit(List<dwp_kitv__Visit__c> lstOldVisits, Map<Id, Account> mapAcc) {
        System.debug(':::putCountryPerVisit:');
        final List<dwp_kitv__Visit__c> lstVisits = new List<dwp_kitv__Visit__c>();
        for(dwp_kitv__Visit__c visit : lstOldVisits) {
            if(visit.dwp_kitv__account_id__c != null) { //ej: Leads does not have related acc
                final Account acc =  mapAcc.get(visit.dwp_kitv__account_id__c);
                System.debug(':::::visit.dwp_kitv__account_id__c:: ' + visit.dwp_kitv__account_id__c);
                System.debug(':::::acc:: ' + acc);
                if(checkCountryAvailable(acc.DES_Country_Client__c)) {
                    visit.dwp_kitv__country_name__c = acc.DES_Country_Client__c;
                    lstVisits.add(visit);
                }
            }
        }
        System.debug(':::::old lstVisits:: ' + JSON.serialize(lstOldVisits));
        System.debug(':::::new lstVisits:: ' + JSON.serialize(lstVisits));
        return lstVisits;
    }
    /*
    * @author Global Desktop
    * @description Method checkCountryAvailable
    */
    private Boolean checkCountryAvailable(String country) {
        System.debug(':::checkCountryAvailable:');
        Boolean isAvailable;
        isAvailable = false;
        if(!lstCodes.isEmpty() && lstCodes.contains(country)) {
            isAvailable = true;
        }
        return isAvailable;
    }
    /*
    * @author Global Desktop
    * @description Method getPickListValuesIntoList
    */
    public static List<String> getPickListValuesIntoList(String objectApiName, String fieldApiName){
        System.debug(':::getPickListValuesIntoList:');
        final List<String> optionList = new List<String>();
        final Map<String,Schema.SObjectType> gdes = Schema.getGlobalDescribe();
        final Map<String, Schema.SObjectField> fieldMap = gdes.get(objectApiName).getDescribe().fields.getMap();

        // System.debug(':::picklistValues init de fieldMap: ' + fieldMap.get('dwp_kitv__country_name__c'));
        List<Schema.PicklistEntry> picklistValues = fieldMap.get(fieldApiName).getDescribe().getPickListValues();
        System.debug(':::picklistValues end:' + picklistValues);

        for (Schema.PicklistEntry pval : picklistValues) {
            optionlist.add(pval.getValue());
        }
        System.debug(':::optionlist: ' + optionlist);
        lstCodes = optionList;
        return optionlist;
    }
}
/*
SELECT Id, Name, dwp_kitv__account_id__c, dwp_kitv__account_id__r.DES_Country_Client__c,  dwp_kitv__account_id__r.name, dwp_kitv__region_name__c, dwp_kitv__country_name__c
    FROM dwp_kitv__Visit__c
    WHERE dwp_kitv__region_name__c = '' OR dwp_kitv__country_name__c = ''-

*/