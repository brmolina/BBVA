/*
* Test for NONC_OnboardingEmail class
*/
@isTest
public class NONC_OnboardingEmailTest {
  /**
  * @description test Method, it created data test
  **/
  @testSetup static void setup(){
    EmailTemplate etempl = new EmailTemplate (developerName = 'testEmail', FolderId = UserInfo.getUserId(), TemplateType= 'Visualforce', Name = 'test', Markup='<messaging:emailTemplate subject="Subj" recipientType="User" relatedToType="Account"> <messaging:htmlEmailBody> Test</messaging:htmlEmailBody> </messaging:emailTemplate>');
    etempl.IsActive = true;
    insert etempl;
  }
  /*
  * Test Method 1
  */
  @isTest
  public static void methodtest() {
    Prospect_validation__c nonClientCS = new Prospect_validation__c();
    nonClientCS.ClassName_Validation__c = 'NONC_NClient_cls_Validation_propect_test';
    nonClientCS.Non_Client_RecordType__c = 'Non_Client';
    nonClientCS.Custom_duplicate_validation__c = true;
    nonClientCS.Country_field__c = 'AccountSource';
    nonClientCS.Unique_Id_field_name__c = 'Site';
    nonClientCS.Additional_field_duplicate_validation__c = 'Site';
    nonClientCS.Form_Help_Text__c = 'Help';
    insert nonClientCS;

    List <EmailTemplate> templates = new List<EmailTemplate>([
      SELECT Id from EmailTemplate WHERE developerName = 'testEmail' Limit 1
    ]);
    Test.startTest();
    Account acc = new Account();
    acc.Name = 'Test';
    insert acc;

    NONC_OnboardingEmail.FlowInputs inputs = new NONC_OnboardingEmail.FlowInputs();
    inputs.record = acc.Id;
    inputs.addresses = 'test@test.com';
    inputs.templateId = templates.get(0).Id;

    List <NONC_OnboardingEmail.FlowInputs> listaInputs = new List <NONC_OnboardingEmail.FlowInputs>();
    listaInputs.add(inputs);
    system.assertEquals(inputs.record, acc.Id, 'assert');
    NONC_OnboardingEmail.sendEmail(listaInputs);
    Test.stopTest();
  }
}