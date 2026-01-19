@isTest
private class UserCountryController_Test {

    static testMethod void myUnitTest() {
      //Data needed  
      User sampleUser = UnitTestUtils.GetSysAdminUser();
      sampleUser.ID_User__c = 'testID';      
      insert sampleUser;
    system.debug(Logginglevel.INFO,'>>>>>>> sampleUser.id: ' + sampleUser.id );      
      

      //Test
      System.runAs(sampleUser) { 
        test.startTest(); 
            PageReference softphone = Page.SoftphoneCAServerCTI;

            test.setCurrentPage(softphone);
            System.currentPageReference().getParameters().put('phone', '666666666');        
        
            UserCountryController controller_Ext = new UserCountryController (new CAServerCallContact());      
                
            String result = UserCountryController.getUserCountry();
            Final String results = UserCountryController.getUserPrefix();
            System.assertNotEquals(results,null, 'error');

        test.stopTest();
        

        //Verify the expressions are the same
        //System.assertNotEquals(result, '');
            
  }
  
        
    }
}