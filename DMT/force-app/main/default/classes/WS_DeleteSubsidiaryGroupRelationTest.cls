@isTest
public class WS_DeleteSubsidiaryGroupRelationTest {
	
	@isTest
	public static void deleteSubsidiaryGroupRelation(){
		DES_UtilTestClass utils;
        utils = new DES_UtilTestClass();
        
        List<Account> accountsToInsert = new List<Account>();
        
        Account groupAccount;
        groupAccount = utils.createClient();
        accountsToInsert.add(groupAccount);
        
        Account subsidiaryAccount;
        subsidiaryAccount = utils.createClient();
        accountsToInsert.add(subsidiaryAccount);
        
        insert accountsToInsert;
        
        DES_Subsidiary_Group_Relation__c sgRelation;
        sgRelation = utils.createSubsidiaryGroupRelation(groupAccount, subsidiaryAccount);
        insert sgRelation;
		
        test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		
		req.requestURI = '/services/apexrest/deleteSubsidiaryGroupRelation';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		
		Id idJobResultado;
		idJobResultado = WS_DeleteSubsidiaryGroupRelation.runRelationBatch();
		Boolean response;
        response = idJobResultado == null ? false : true;
        System.assertEquals(true, response);
		System.abortJob(idJobResultado);
        
        Id batchInstanceId = Database.executeBatch(new DeleteSubsidiaryGroupRelation_Batch(), 2000);
		
        test.stopTest();
	}
	
}