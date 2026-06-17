/************************************************************************
* @name:               NONC_EditFormNonClient_ctlr_test
* @author              bbva.com developers
* @date:               2019
* @version:            1.0
* @group:              Global Desktop
* @description:        Test for NONC_EditFormNonClient_ctlr
***************************************************************************/
@isTest
public with sharing class NONC_EditFormNonClient_ctlr_test{
  /**
  * @description test Method, it created data test
  **/
  @testSetup static void setup(){
    Prospect_validation__c nonClientCS = new Prospect_validation__c();
    nonClientCS.ClassName_Validation__c = 'NONC_NClient_cls_Validation_propect_test';
    nonClientCS.Non_Client_RecordType__c = 'DES_No_Client';
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
    Test.startTest();
    NONC_EditFormNonClient_ctlr.validateNonClienteComponent(New Account(Site='sitio'));
    NONC_EditFormNonClient_ctlr.createNewAccount(JSON.serialize(New Account(Site='sitio')),false);
    NONC_EditFormNonClient_ctlr.createNewAccountNew(JSON.serialize(New Account(Site='sitio')),false,'Name','Name');
    NONC_EditFormNonClient_ctlr.getFieldSetFromAccount(false);
    NONC_EditFormNonClient_ctlr.getHelpText();
    Prospect_validation__c nonClientCS = [select id, Country_field__c from Prospect_validation__c];
    nonClientCS.Custom_validation_creation__c = true;
    update nonClientCS;
    NONC_EditFormNonClient_ctlr.validateNonClienteComponent(new Account());
    NONC_EditFormNonClient_ctlr.FieldSetMemberWrapperClass objedit=new NONC_EditFormNonClient_ctlr.FieldSetMemberWrapperClass();
    objedit.fieldValue='';
    objedit.pickListValues = new List<Schema.PicklistEntry>();
    NONC_EditFormNonClient_ctlr.ResultValidation objresult=new NONC_EditFormNonClient_ctlr.ResultValidation();
    objresult.message='';
    String lstCamposJSON = NONC_EditFormNonClient_ctlr.getFieldSetFromAccount(false);
    System.assertNotEquals(lstCamposJSON.length(),0);
    Test.stopTest();
  }
  /**
  * @description test Method
  **/
  @isTest static void testNClientFields() {
    Test.startTest();
    Prospect_validation__c nonClientCS = [select id, Country_field__c from Prospect_validation__c];
    nonClientCS.Additional_field_duplicate_validation__c = 'tr';
    update nonClientCS;
    nonClientCS = [select id, Country_field__c from Prospect_validation__c];
    nonClientCS.Additional_field_duplicate_validation__c = null;
    update nonClientCS;
    nonClientCS = [select id, Country_field__c from Prospect_validation__c];
    nonClientCS.Required_Unique_ID__c = true;
    nonClientCS.Unique_Id_field_name__c = 'Name';
    update nonClientCS;
    NONC_EditFormNonClient_ctlr.validateNonCliente(new Account(),nonClientCS);
    System.assertEquals(true, NONC_EditFormNonClient_ctlr.validateNonCliente(new Account(),nonClientCS).contains('error'),'error');
    Test.stopTest();
  }
    
}