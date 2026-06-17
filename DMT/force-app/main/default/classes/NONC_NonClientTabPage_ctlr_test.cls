/************************************************************************
* @name:                CreateAccountOverwrite_ctlr_test
* @author               bbva.com developers
* @date:                2019
* @version:             1.0
* @group:               Global Desktop
* @description:         test class of CreateAccountOverwrite_ctlr Controller
***************************************************************************/
@isTest
public class NONC_NonClientTabPage_ctlr_test {
    /**
    * @description Method which creates test data
    **/
  @testSetup static void setup() {
    Prospect_validation__c nonClientCS = new Prospect_validation__c();
        nonClientCS.ClassName_Validation__c = 'NClient_cls_Validation_prospect_test';
        nonClientCS.Non_Client_RecordType__c = 'Non_client';
        nonClientCS.Custom_duplicate_validation__c = true;
        nonClientCS.Country_field__c = 'AccountSource';
        nonClientCS.Unique_Id_field_name__c = 'Site';
        nonClientCS.Additional_field_duplicate_validation__c = 'Site';
        nonClientCS.List_View_Name__c = null;
        insert nonClientCS;
  }

  @isTest
  static void testNClientValidateWhitErrors() {
  try{
      NONC_NonClientTabPage_ctlr.getApiName();
      }catch(exception ex){
          system.assertEquals(ex.getMessage(), 'Script-thrown exception', 'exception');
      }
  }
  @isTest
  static void testNClientValidate() {

      Prospect_validation__c nonClientCS = [select id, List_View_Name__c from Prospect_validation__c];
      List <ListView> lstview = new List<ListView>([Select id,name, developerName from ListView LIMIT 1]);
      nonClientCS.List_View_Name__c = lstview.get(0).developerName;
      update nonClientCS;
      String ret1 = NONC_NonClientTabPage_ctlr.getApiName();
      system.assertEquals(lstview.get(0).developerName, ret1, 'lstview');
  }
}