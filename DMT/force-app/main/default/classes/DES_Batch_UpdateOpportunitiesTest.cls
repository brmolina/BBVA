@isTest
private class DES_Batch_UpdateOpportunitiesTest{

    @isTest
    static void DES_Batch_UpdateOpportunitiesTest(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();    
        Account acc = testClass.createClient();
        insert acc;
        Opportunity opp = testClass.createOpportunity(acc);
        insert opp;
        
        Id batchInstanceId = Database.executeBatch(new DES_Batch_UpdateOpportunities(), 1);
    }


}