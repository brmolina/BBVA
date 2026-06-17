/************************************************************************
* @name:               CustomLookUpControllerMobile_test
* @author              bbva.com developers
* @date:               2020
* @version:            1.0
* @group:              Global Desktop
* @description:        Test for CustomLookUpControllerMobile
***************************************************************************/
@isTest
public with sharing class NONC_CustomLookUpControllerMobile_test {
  /**
  * @description test Method, it created data test
  **/
  @testSetup static void setup(){
    Prospect_validation__c nonClientCS = new Prospect_validation__c();
    nonClientCS.ClassName_Validation__c = 'NONC_NClient_cls_Validation_propect_test';
    nonClientCS.Non_Client_RecordType__c = 'Non_Client';
    nonClientCS.Custom_duplicate_validation__c = true;
    nonClientCS.Country_field__c = 'AccountSource';
    nonClientCS.Unique_Id_field_name__c = 'Site';
    nonClientCS.Additional_field_duplicate_validation__c = 'Site';
    nonClientCS.Form_Help_Text__c = 'Help';
    insert nonClientCS;
  }

  /**
  * @description test Method
  **/
  @isTest
  static void testNClient() {
    Account acc = new Account();
    acc.Name = 'Name Name';
    insert acc;
    List<Id> fixedSearchResults= new List<Id>();
    fixedSearchResults.add(acc.id);
    Test.setFixedSearchResults(fixedSearchResults);
    NONC_CustomLookUpControllerMobile.fetchLookUpValues('Name', 'Account', 'AccountNumber', '');
    System.assertEquals(acc.Name, 'Name Name', 'error');
  }
}