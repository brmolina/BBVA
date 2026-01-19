/*
* batch upadate contact active
*/
public without sharing class Batch_normalizeContactRelation implements Database.Batchable<Sobject>, Database.Stateful {
    private final String pQuery; //NOSONAR
    private Set<String> setAccIdHierarchyForContact = new Set<String>(); //NOSONAR

    /*
    * constructor method
    */
    public Batch_normalizeContactRelation() {
        pQuery = 'Select Id, AccountId, CurrencyIsoCode from Contact' + (Test.isRunningTest()?' LIMIT 1':'');
    }

    /*
    * start method
    */
    public Database.QueryLocator start(Database.BatchableContext bch) {
        return Database.getQueryLocator(pQuery);
    }

    /*
    * Execute method
    */
    public void execute(Database.BatchableContext bch,List<Contact> scope) {

        final Map<String,AccountContactRelation> acrToInsert = new  Map<String,AccountContactRelation>();
        final Map<String,AccountContactRelation> acrExist = new  Map<String,AccountContactRelation>();
        final Set<Id> setContact = new Set<Id>();

        for(Contact con : scope) {
            if(!setContact.contains(con.Id)) {
                setContact.add(con.Id);
            }
        }

        final List<AccountContactRelation> accountRelations = [SELECT accountId, contactId from AccountContactRelation where contactId in :setContact];

        for(AccountContactRelation acr : accountRelations) {
            acrExist.put(acr.accountId + '_' + acr.contactId, acr);
        }

        system.debug('++ acrExist -> ' + JSON.serialize(acrExist));

        for (Contact contact: scope) {
            setAccIdHierarchyForContact.clear();
            recursiveFxn(contact.AccountId, contact.AccountId);
            system.debug('++ AccsIdHierarchy -> ' + contact.Id + ' ' + setAccIdHierarchyForContact);
            if (!setAccIdHierarchyForContact.isEmpty()) {
                for( String accId : setAccIdHierarchyForContact) {
                    if(acrExist.get(accId + '_' + contact.Id) == null) {
                        final AccountContactRelation accountContactRel = new AccountContactRelation(AccountId=accId, ContactId=contact.Id, CurrencyIsoCode=contact.CurrencyIsoCode, record_created_hierarchy_type__c = true);
                        acrToInsert.put(accId + '_' + contact.Id,accountContactRel);
                    }
                 }
            }
        }

        system.debug('++ acrToInsert -> ' + JSON.serialize(acrToInsert));

        if (!ACRtoInsert.isEmpty()) {
            System.debug('>>>>>>>>>> Lista de registros a insertar en AccountContactRelation: ' + ACRtoInsert);
            insert ACRtoInsert.values();
        }
    }

    /*
    * Finish method
    */
    public void finish(Database.BatchableContext bch) {
        final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }

    /*
    * Method to add parents of hierarchy in a set
    */
    private void recursiveFxn(string accId, string accInicial) {
        if (accId != null && accId != accInicial) {
            //system.debug('Adding Account Id >> Acc:' + accId);
            setAccIdHierarchyForContact.add(accId);
        }

        //Retrieve the parents for the account passed
        final List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT Id, dwp_acmh__Parent_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c = :accId];
        //system.debug('listAccRel:' + listAccRel);

        //iterate to recursively add the opportunity to each parent in the hierarchy
        for (dwp_acmh__GBL_Account_Relationship__c accRel : listAccRel) {
            recursiveFxn(accRel.dwp_acmh__Parent_Account__c, accInicial);
        }
 	}


}