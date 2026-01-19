/**************************************************************************************************************
Name:            DES_Batch_firstUpdateRevenues
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/01/2019      Global Desktop    Batch que actualiza campos del cliente en función de sus oportunidades relacionadas
**************************************************************************************************************/
public without sharing class DES_Batch_firstUpdateRevenues implements Database.Batchable<Sobject>, Database.Stateful {

    /*
        ´Query to be executed
    */
    private final String pQuery;
    /**
    * @author Global Desktop
    * @description Variables para filtrar la query dinamica
    */
    final String closeWon = Label.DES_Closed_Won;
    /**
    * @author Global Desktop
    * @description Variables para filtrar la query dinamica
    */
    final String closeLost = Label.DES_Closed_Lose;
    /**
    * @author Global Desktop
    * @description Variables para filtrar la query dinamica
    */
    final String draftOpp = Label.DES_Draft;

    /*
    * @author Global Desktop
    * @description Recupera información de la tabla de denorm opportunity
    */
    public DES_Batch_firstUpdateRevenues() {
        System.debug(':::closeWon : ' + closeWon);
        System.debug(':::closeLost : ' + closeLost);
        pQuery = 'SELECT Id, dwp_acmh__AccountId__c, dwp_acmh__OpportunityId__c, convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c) FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__OpportunityId__r.StageName != :closeWon AND dwp_acmh__OpportunityId__r.StageName != :closeLost AND dwp_acmh__OpportunityId__r.StageName != :draftOpp ORDER BY dwp_acmh__AccountId__c'+(Test.isRunningTest()?' LIMIT 1':'');
    }

    /*
    * @author Global Desktop
    * @description Ejecuta la query
    */
    public Database.QueryLocator start(Database.BatchableContext bcd) {
        return Database.getQueryLocator(pQuery);
    }

    /*
    * @author Global Desktop
    * @description Execute para recalcular campos de los clientes asociadas a las oportunidades
    */
    public void execute(Database.BatchableContext bcd,List<dwp_acmh__Denorm_Account_Opportunity__c> scope) {
        final set<Id> idRelatedAccounts = new set<Id>();
        for(dwp_acmh__Denorm_Account_Opportunity__c adao : scope) {
            idRelatedAccounts.add(adao.dwp_acmh__AccountId__c);
        }
        Map<Id,Account> accMap = new map<Id,Account>([SELECT id, customer_open_oppy_number__c,
                                                    customer_open_oppy_amount__c
                                                    FROM Account WHERE id IN :idRelatedAccounts]);

        accMap = inicializateVars(scope,accMap);

        accMap = calculateVars(scope,accMap);

        update accMap.values();
    }


    /**
    * @author Global Desktop
    * @description Auxiiliar para resetear las variables
    */
    public static Map<Id,Account> inicializateVars(List<dwp_acmh__Denorm_Account_Opportunity__c> scope, Map<Id,Account> accMap) {
        for(dwp_acmh__Denorm_Account_Opportunity__c idao : scope) {
            accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_number__c = 0;
            accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = 0;
        }
        return accMap;
    }

     /**
    * @author Global Desktop
    * @description Auxiiliar para calcular las variables
    */
    public static Map<Id,Account> calculateVars(List<dwp_acmh__Denorm_Account_Opportunity__c> scope, Map<Id,Account> accMap) {
        for(dwp_acmh__Denorm_Account_Opportunity__c idao : scope) {
            if(accMap.get(idao.dwp_acmh__AccountId__c) != null && accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_number__c == null && accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_amount__c == null) {
                accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_number__c = 1;
                accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = idao.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c;
            } else if(accMap.get(idao.dwp_acmh__AccountId__c) != null && accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_number__c != null && accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_amount__c != null) {
                accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_number__c = accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_number__c +1;
                accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = accMap.get(idao.dwp_acmh__AccountId__c).customer_open_oppy_amount__c +idao.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c;
            }
        }
        return accMap;
    }


    /*
    * @author Global Desktop
    * @description Method finish del batch
    */
    public void finish(Database.BatchableContext bcd) {
        //actualiza los parent de los grupos
        final Batch_UpdateParentAccount batchPrntAcc = new Batch_UpdateParentAccount();
        Database.executeBatch(batchPrntAcc,200);
    }

}