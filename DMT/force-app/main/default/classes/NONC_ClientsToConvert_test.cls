/************************************************************************
  * @name:                ClientsToConvert_test
  * @author               bbva.com developers
  * @date:                2019
  * @version:             1.0
  * @group:               º
  * @description:         Test for class to add method on account trigger and convert prospect
  ***************************************************************************/
@isTest
public class NONC_ClientsToConvert_test {
  /**
  * @description Method which creates test data
  **/
  @testSetup static void setup() {
    Prospect_validation__c nonClientCS = new Prospect_validation__c();
    nonClientCS.ClassName_Validation__c = 'NONC_NClient_cls_Validation_propect_test';
    nonClientCS.Non_Client_RecordType__c = 'Non_client';
    nonClientCS.Country_field__c = 'AccountSource';
    nonClientCS.Type_field__c = 'Type';
    nonClientCS.Unique_Id_field_name__c = 'AccountNumber';

    insert nonClientCS;
  }


  @isTest
  static void testmethod1() {
      Account acc1 = new Account();
      acc1.Name = 'Name';
      acc1.AccountNumber = '111';
      NONC_ClientsToConvert.getConvertedAccounts(new List<Account> {acc1});
      System.assertEquals(acc1.Name, 'Name', 'Error');
  }
}