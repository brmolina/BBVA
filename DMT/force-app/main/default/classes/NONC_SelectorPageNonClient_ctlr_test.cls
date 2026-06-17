/************************************************************************
* @name:          SelectorPageNonClient_ctlr_test
* @author         bbva.com developers
* @date:          2019
* @version:       1.0
* @group:         Global Desktop
* @description:   test class of SelectorPageNonClient_ctlr Controller
***************************************************************************/
@isTest
public class NONC_SelectorPageNonClient_ctlr_test {
  /**
  * @description Method which creates test data
  **/
  @testSetup static void setup(){

      Prospect_validation__c nonClientCS = new Prospect_validation__c();
      nonClientCS.ClassName_Validation__c = 'NONC_NClient_cls_Validation_propect_test';
      nonClientCS.Non_Client_RecordType__c = 'Non_Client';
      nonClientCS.Custom_duplicate_validation__c = true;
      nonClientCS.Country_field__c = 'AccountSource';
      nonClientCS.Unique_Id_field_name__c = 'Site';
      nonClientCS.Additional_field_duplicate_validation__c = 'Site';

      insert nonClientCS;
  }

  @isTest
  static void testNClientValidate() {
    new NONC_SelectorPageNonClient_ctlr.WrapperField('test', 'test');
    System.assertEquals(NONC_SelectorPageNonClient_ctlr.getJSONRecordType(),'emptyRecordType','Error');
  }
}