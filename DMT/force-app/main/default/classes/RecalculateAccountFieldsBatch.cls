public without sharing class RecalculateAccountFieldsBatch implements Database.Batchable<Sobject>, Database.Stateful {

    private String pQuery;
    private String groupRT = 'Group';
    private String supraGroupRT = 'SupraGroup';
    private String commercialClientRT = 'DES_Commercial_Client';
    private String closeWon = 'Closed Won';
    
    public RecalculateAccountFieldsBatch(){
        pQuery = 'SELECT Id FROM Opportunity WHERE DES_Date_Won_Lost__c = LAST_MONTH AND StageName = :closeWon'+(Test.isRunningTest()?' LIMIT 1':'');
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(pQuery);
    }
    
    public void execute(Database.BatchableContext bc,List<Opportunity> scope){
        
        set<Id> idsOpportunities = new set<Id>();
        for(Opportunity o : scope){
            idsOpportunities.add(o.Id);        
        }
        
        set<Id> idsRelatedAccounts = new set<Id>();
        list<dwp_acmh__Denorm_Account_Opportunity__c> relatedDenormOpp = [SELECT id, dwp_acmh__OpportunityId__c, dwp_acmh__AccountId__c, DES_Opportunity_Potential_Revenue_Rollup__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__OpportunityId__c IN :idsOpportunities];
        for(dwp_acmh__Denorm_Account_Opportunity__c i : relatedDenormOpp){
            idsRelatedAccounts.add(i.dwp_acmh__AccountId__c);    
        }
        
        map<Id,Account> relatedAccounts = new map<Id,Account>([SELECT Id, customer_won_oppy_number__c, customer_won_oppy_amount__c FROM Account WHERE (RecordType.DeveloperName = :groupRT OR RecordType.DeveloperName = :supraGroupRT OR RecordType.DeveloperName = :commercialClientRT) AND Id IN :idsRelatedAccounts]);
        for(Account a : relatedAccounts.values()){
            system.debug('Valor de a relatedAccounts: ' +a);
            a.customer_won_oppy_number__c = 0;
            a.customer_won_oppy_amount__c = 0;
        }
        
        for(dwp_acmh__Denorm_Account_Opportunity__c denormOpp : relatedDenormOpp){
            system.debug('Valor de denormOpp.dwp_acmh__AccountId__c: ' +denormOpp.dwp_acmh__AccountId__c);
            system.debug('Valor de relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_number__c: ' +relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_number__c);
            system.debug('Valor de relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_amount__c: ' +relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_amount__c);
            system.debug('Valor de denormOpp.DES_Opportunity_Potential_Revenue_Rollup__c: ' +denormOpp.DES_Opportunity_Potential_Revenue_Rollup__c);
            relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_number__c = relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_number__c + 1;
            relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_amount__c = relatedAccounts.get(denormOpp.dwp_acmh__AccountId__c).customer_won_oppy_amount__c + denormOpp.DES_Opportunity_Potential_Revenue_Rollup__c;
        }
        
        update relatedAccounts.values();
        
        
    }
    
    public void recursiveFxn(String accId){
    
    }
    
    public void finish(Database.BatchableContext bc){
    }

}