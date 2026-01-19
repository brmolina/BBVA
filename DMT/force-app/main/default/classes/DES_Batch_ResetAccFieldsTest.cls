@isTest
public class DES_Batch_ResetAccFieldsTest {
	
	@isTest
	static void testBatchAccFields(){
		final DES_UtilTestClass testClass = new DES_UtilTestClass();
		
		Test.StartTest();
		Account acc = testClass.createClient();
		acc.cf_revenue_cyr_amount__c = 5000;
		acc.gf_revenue_cyr_amount__c = 5000;
		acc.gm_revenue_cyr_amount__c = 5000;
		acc.gtb_revenue_cyr_amount__c = 5000;
		acc.gf_ibf_cyr_revenue_amount__c = 5000;
		insert acc;
		
		Id batchInstanceId = Database.executeBatch(new DES_Batch_ResetAccFields(), 10000);
		Boolean response;
        response = batchInstanceId == null ? false : true;
        System.assertEquals(true, response);
		Test.StopTest();
	}
	
}