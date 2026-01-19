/**
*Name:      ManagerFranchise_TriggerHandler_Test
*Description:   Class to test ManagerFranchise_TriggerHandler class
*Test Class:    -
*
*Version    Date          Author      Summary of changes
*--------------------------------------------------------------------------------------------------------------------------------
*0.1        05/03/2019    JSS         Class creation
*/
@isTest
private class ManagerFranchise_TriggerHandler_Test {
  
  @isTest static void test_method_one() {
    //Data
    User sampleFISalesUser = UnitTestUtils.GetFISalesUser();
    sampleFISalesUser.Business_area_desc__c = 'MAD CORPORATE GLOBALES';
    sampleFISalesUser.Business_line_desc__c = '';
    sampleFISalesUser.coverage_country_name__c = null;
    sampleFISalesUser.solution_name_path_desc__c = 'Credit'; 
    sampleFISalesUser.ID_User__c ='testCodeUser';
    insert sampleFISalesUser;

    Account acc = UnitTestUtils.GetStandardAccount();
    insert acc;

    //start test
    Test.startTest();
      Manager_Franchise__c mf = new Manager_Franchise__c();
      mf.External_ID__c = 'TestExternalID';
      mf.Client_Account__c = acc.Id;
      mf.Account_Manager_Code__c = 'testCodeUser';
      insert mf;
    Test.stopTest();

    //Check result
    User checkUser = new List<User>([Select Id, ID_User__c, Business_area_desc__c, Business_line_desc__c, coverage_country_name__c, solution_name_path_desc__c FROM User Where id = :sampleFISalesUser.id LIMIT 1]).get(0);
    Manager_Franchise__c checkMF = new List<Manager_Franchise__c>([Select Id, Client_Account__c, Account_Manager_Code__c, Business_area_desc__c, Business_line_desc__c, coverage_country_name__c, solution_name_path_desc__c FROM Manager_Franchise__c Where id = :mf.id LIMIT 1]).get(0);
    System.assertEquals(checkUser.Business_area_desc__c, checkMF.Business_area_desc__c);
    System.assertEquals(checkUser.Business_line_desc__c, checkMF.Business_line_desc__c);
    System.assertEquals(checkUser.coverage_country_name__c, checkMF.coverage_country_name__c);
    System.assertEquals(checkUser.solution_name_path_desc__c, checkMF.solution_name_path_desc__c);
  }
  

}