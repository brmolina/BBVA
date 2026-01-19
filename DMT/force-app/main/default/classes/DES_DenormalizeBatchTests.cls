@isTest
public class DES_DenormalizeBatchTests {

    @isTest
    public static void DES_DenormalizeOppSchedulableTest(){
		Test.startTest();
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_DenormalizeOppSchedulable());
		Test.stopTest();
    }

    @isTest
    public static void DES_DenormalizeVisitsSchedulableTest(){
    DES_UtilTestClass utilTest;
    utilTest = new DES_UtilTestClass();
		Test.startTest();
    Account acc;
    acc = utilTest.createClient();
    insert acc;
    Opportunity opp;
    opp = utilTest.createOpportunity(acc);
    insert opp;
    dwp_kitv__Visit__c vist = utilTest.createVisit(acc, opp);
    List<dwp_kitv__Visit__c> lVisit;
    lVisit = new List<dwp_kitv__Visit__c>();
    lVisit.add(vist);
    insert lVisit;

		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_DenormalizeVisitsSchedulable());

    DES_DenormalizeVisitsExecute batchTest;
    batchTest = new DES_DenormalizeVisitsExecute();
    batchTest.execute(null, lVisit);

		Test.stopTest();
    }

}