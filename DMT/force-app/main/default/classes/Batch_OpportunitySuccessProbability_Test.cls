/**
*
* @author Global Desktop
*/
@isTest
public class Batch_OpportunitySuccessProbability_Test{
    /**
     * Test method for Batch_OpportunitySuccessProbability
     */
    @isTest
    public static void methodOne() {
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        insert acc;
        final Opportunity opp = utilTestClass.createOpportunity(acc);
        opp.DES_Expected_Probability__c = 20;
        insert opp;
      final AMH_Denorm_Account_Opportunity__c oppDenorm = new AMH_Denorm_Account_Opportunity__c ();
      oppDenorm.AMH_AccountId__c = acc.Id;
      oppDenorm.AMH_OpportunityId__c = opp.Id;
      insert oppDenorm;
        Id batchJobId = Database.executeBatch(new Batch_OpportunitySuccessProbability(), 200);
        System.assertEquals(oppDenorm.AMH_AccountId__c, acc.id, 'ERROR');
    }
}