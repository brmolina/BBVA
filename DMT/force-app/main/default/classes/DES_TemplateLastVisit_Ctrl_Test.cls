@isTest
private class DES_TemplateLastVisit_Ctrl_Test {
	
	@isTest static void test_method_one() {

		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

		Account client = utilTestClass.createClient();
		insert client;

		Opportunity opp = utilTestClass.createOpportunity(client);
		insert opp;

		dwp_kitv__Visit__c visit = utilTestClass.createVisit(client, opp);
		insert visit;

		DES_Denorm_AccountVisits__c accVisit = new DES_Denorm_AccountVisits__c();
		accVisit.DES_Start_Date__c = Date.today()-1; 
		accVisit.DES_Visit_new__c = visit.id;
		accVisit.DES_Client__c = client.id;
		insert accVisit;

		DES_Template__c tmp = new DES_Template__c();
		tmp.Pending_approval_type__c = false;
		tmp.opportunity_id__c = opp.id;
		tmp.RecordTypeID = Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get('GTB').getRecordTypeId();
		tmp.YTD_RORC_per_CDD__c = 1;
        tmp.Past_FY_RORC_per_CDD__c = 2;
        tmp.Standalone_CDD_RaR_number__c = 1;
        tmp.Standalone_CDD_RORC_number__c = 1;
		insert tmp;

		Test.startTest();
		DES_TemplateLastVisit_Ctrl.setLastVisit(tmp.id);

		System.assertEquals(tmp.Last_Visit_to_the_Client_desc__c, null);
		Test.stopTest();
	}
}