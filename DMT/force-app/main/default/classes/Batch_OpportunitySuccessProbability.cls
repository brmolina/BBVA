/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de Potencial revenues Revenues de las denorm
* @Revision
**********************************************************************************/
public without sharing class Batch_OpportunitySuccessProbability implements Database.Batchable<Sobject>, Database.Stateful {

    /*
    * Private Attribute pQuery
    */
    private final String pQuery;

    /*
    * Private Attribute recordsProcessed
    */
    private Integer recordsProcessed = 0;

    /*
    * Public Constructor
    */
    public Batch_OpportunitySuccessProbability() {
        pQuery = 'SELECT Id, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.DES_Expected_Probability__c, success_probability_per__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE success_probability_per__c = null';
    }

    /*
    * start method
    */
    public Database.QueryLocator start(Database.BatchableContext bch) {
        system.debug('>>>>> query : ' + pQuery);
        return Database.getQueryLocator(pQuery);
    }

    /*
    * Execute method
    */
    public void execute(Database.BatchableContext bch, List<dwp_acmh__Denorm_Account_Opportunity__c> listOpps) {
        List<dwp_acmh__Denorm_Account_Opportunity__c> lOppDenorm = new List<dwp_acmh__Denorm_Account_Opportunity__c> ();
        for(dwp_acmh__Denorm_Account_Opportunity__c oppDenorm : listOpps) {
            oppDenorm.success_probability_per__c = oppDenorm.dwp_acmh__OpportunityId__r.DES_Expected_Probability__c;
            lOppDenorm.add(oppDenorm);
        }
        Database.update(lOppDenorm, false);
    }


    /*
    * Finish method
    */
    public void finish(Database.BatchableContext bch) {

    }
}