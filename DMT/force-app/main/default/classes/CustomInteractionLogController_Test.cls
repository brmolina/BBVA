@isTest
private class CustomInteractionLogController_Test {

    static testMethod void myUnitTest() {
    	//Data needed	
    	User sampleUser = UnitTestUtils.GetSysAdminUser();
    	sampleUser.ID_User__c = 'testID';    	
    	insert sampleUser;
		system.debug(Logginglevel.INFO,'>>>>>>> sampleUser.id: ' + sampleUser.id );    	
    	
    	Account Acc = UnitTestUtils.GetStandardAccount();
        insert Acc;     	    	        	
		system.debug(Logginglevel.INFO,'>>>>>>> Acc.id: ' + Acc.id );
		

    	//Test
    	System.runAs(sampleUser) { 
        test.startTest(); 
            PageReference softphone = Page.SoftphoneCAServerCTI;

            test.setCurrentPage(softphone);
            System.currentPageReference().getParameters().put('phone', '666666666');        
        
			CustomInteractionLogController controller_Ext = new CustomInteractionLogController(new CAServerCallContact());
			controller_Ext.callLog = new Task();
			controller_Ext.callLogRelatedTo = String.valueOf(Acc.Id);
			
			        	
        	Task newTask = CustomInteractionLogController.saveCallLog('callLogComments', controller_Ext.callLogRelatedTo, 'Outbound', 'callLogObjectId', 99, '912345678');
        test.stopTest();
        

        //Verify the expressions are the same
        System.assertNotEquals(newTask, null);
        		
	}
	
        
    }
}