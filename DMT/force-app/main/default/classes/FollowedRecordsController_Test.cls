@isTest
private class FollowedRecordsController_Test {


    static testMethod void myUnitTest() {
    	//Data needed	
    	User sampleUser = UnitTestUtils.GetSysAdminUser();
    	sampleUser.ID_User__c = 'testID';
		sampleUser.My_Clients_Columns_To_Display__c = 'ClientStarID=true;Name=true;ManaYTDFranchise=true;ManaPercent=true;FIYTDFranchise=true;FXYTDFranchise=true;CEYTDFranchise=true;MiFID=true;Emir=true;DFA=true;CreditConsumpt=true;DerivConsumpt=true;DepoConsumpt=true;RepConsumpt=true';    	
    	insert sampleUser;
		system.debug(Logginglevel.INFO,'>>>>>>> sampleUser.id: ' + sampleUser.id );    	
    	
    	Account Acc = UnitTestUtils.GetStandardAccount();
        insert Acc;     	    	        	
		system.debug(Logginglevel.INFO,'>>>>>>> Acc.id: ' + Acc.id );
		
        EntitySubscription eS = new EntitySubscription();
        es.SubscriberId = sampleUser.Id;
        eS.ParentId = Acc.Id;
        insert eS;
		system.debug(Logginglevel.INFO,'>>>>>>> eS.id: ' + eS.id );
	    
	    Manager_Franchise__c manager = new Manager_Franchise__c(    
	        Name = sampleUser.LastName + ', ' + sampleUser.FirstName,
	        Account_Manager_Code__c = 'cod1',
	        Asset_Class__c = 'FI',
	        External_ID__c = 'cod1_FI',
	        Client_Account__c = Acc.Id,
	        MTD_Total_Franchise__c = 10,
	        Prior_year_Franchise__c = 30,
	        YTD_Total_Franchise__c = 20       
	        );   
	    insert manager;
		system.debug(Logginglevel.INFO,'>>>>>>> manager.id: ' + manager.id );	                                                 
                           	
    	FollowedRecordsController controller;

    	List<boolean> listCheckbox = new List<boolean>();
    	for(Integer i=0;i<16;i++){
    		listCheckbox.add(true);
    	}
    	
    	
    	//Test
    	System.runAs(sampleUser) { 
	        test.startTest();
	        	controller = new FollowedRecordsController(); 
				system.debug(Logginglevel.INFO,'>>>>>>> wrapperFollowedAccountList: ' + controller.wrapperFollowedAccountList );        	
	        	FollowedRecordsController.doRefreshColumns(listCheckbox);               
	        test.stopTest();
    	}
        

        //Verify the expressions are the same
       	System.assertNotEquals(controller.wrapperFollowedAccountList.size(),0);
        
    }
}