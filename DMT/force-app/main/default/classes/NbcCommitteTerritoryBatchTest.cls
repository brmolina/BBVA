@isTest

/**
* Clase test para territorio nbc
*
 */

public class NbcCommitteTerritoryBatchTest {

    @isTest static void testMethodOne() {

        Test.startTest();
        DES_UtilTestClass utils;
        utils = new DES_UtilTestClass();
        User usr;
        usr = utils.createUser(utils.createProfile());
        insert usr;
        Account acc;
        acc = utils.createGroupClient('Account Name', null, usr.id);
        upsert acc;
        NBC__c nbc;
        nbc = utils.createNBC();
        nbc.Committee_Start_Date__c = Date.today();
        upsert nbc;
        Opportunity opp;
        opp = utils.createOpportunity(acc);
        opp.Template_approved_type__c = true;
        opp.Committee_id__c = nbc.id;
        upsert opp;
        Product2 prod;
        prod = utils.createProduct('Product Name');
        upsert prod;
        PricebookEntry pbookEntry;
        pbookEntry = utils.createPricebookEntry(prod);
        upsert pbookEntry;
        OpportunityLineItem oppLine;
        oppLine = utils.createOppLineItem(opp, prod, pbookEntry);
        upsert oppLine;
        final Id batchInstanceId = Database.executeBatch(new NbcCommitteTerritoryBatch(), 8);
        Database.executeBatch(new OpportunityTerritoryBatch(), 8);
        Test.stopTest();
        System.assertNotEquals(batchInstanceId, null);
    }


}