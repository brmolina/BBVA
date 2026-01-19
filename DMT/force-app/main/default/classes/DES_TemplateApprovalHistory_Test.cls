@isTest
private class DES_TemplateApprovalHistory_Test {

    @testSetup
    static void testSetup() {
		DES_UtilTestClass testClass = new DES_UtilTestClass();
		String productName = 'TestProduct';
		String newProfileTest = testClass.createProfile();
        UserRole roltest = [SELECT id FROM UserRole where developerName = 'GM_GLOBAL_MARKETS' limit 1];
		User newUserTest = testClass.createUser(newProfileTest);
        newUserTest.UserRoleId = roltest.id;
        newUserTest.FirstName = 'testeo_DES_TemplateApprovalHistory_Test';
		insert newUserTest;
    }

	@isTest static void templateApprovalHistory() {

		DES_UtilTestClass testClass = new DES_UtilTestClass();
		String productName = 'TestProduct';
		String newProfileTest = testClass.createProfile();

		User newUserTest = [SELECT id, UserRole.Name, Profile.Name FROM User where FirstName = 'testeo_DES_TemplateApprovalHistory_Test' limit 1];
        System.debug('AAAAAAAAAAAAAAA' + newUserTest.UserRole.Name + ',,,,' + newUserTest.Profile.Name);
		Account newAcc = testClass.createClient();
		insert newAcc;
		Opportunity newOpp = testClass.createOpportunity(newAcc);
		insert newOpp;
		Product2 newProd = testClass.createProduct(productName);
		insert newProd;
		PricebookEntry newProdEntry = testClass.createPricebookEntry(newProd);
		insert newProdEntry;
		OpportunityLineItem newOppLineItem = testClass.createOppLineItem(newOpp, newProd, newProdEntry);
		insert newOppLineItem;
		DES_Template__c newTemplate = testClass.createTemplate(newOpp,newOppLineItem);
		newTemplate.YTD_RORC_per_CDD__c = 1;
        newTemplate.Past_FY_RORC_per_CDD__c = 2;
        newTemplate.Standalone_CDD_RaR_number__c = 1;
        newTemplate.Standalone_CDD_RORC_number__c = 1;
		insert newTemplate;


		system.runAs(newUserTest){
			test.startTest();
				Approval.ProcessSubmitRequest newApproval = new Approval.ProcessSubmitRequest();
			    newApproval.setComments('Test');
			    newApproval.setObjectId(newTemplate.id);
				newApproval.setSubmitterId(newUserTest.Id);
            	newApproval.setNextApproverIds(new Id[] {newUserTest.Id});
				Approval.ProcessResult appResult = Approval.process(newApproval);

				System.assert(appResult.isSuccess());
				List<Id> newWorkItemIds = appResult.getNewWorkitemIds();

				String result = DES_TemplateApprovalHistory.setFindCurrentApprover(newTemplate.id);
				System.assertNotEquals(result,null);

			test.stopTest();
			}
		}



}