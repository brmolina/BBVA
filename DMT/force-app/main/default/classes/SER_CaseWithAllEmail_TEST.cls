/*---------------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Class to test SER_CaseWithAllEmail.
----------------------------------------------------------------------------------------------*/
@isTest
public with sharing class SER_CaseWithAllEmail_TEST {

  /*-----------------------------------------------------------------------
      Description: createEmail.
  ------------------------------------------------------------------------*/
  private static Void createEmail(Id caseId) {
    EmailMessage em01STE;
    em01STE = new EmailMessage();
    em01STE.textbody = 'Test Body ref:_123ABC:ref';
    em01STE.Subject = 'test subject';
    em01STE.ToAddress = 'testemailaddress01@example.com';
    em01STE.ParentId = caseId;
    insert em01STE;
  }

  /*-----------------------------------------------------------------------
      Description: getSortEmailsTEST.
  ------------------------------------------------------------------------*/
  @isTest
  static void getSortEmailsTEST() {
    Case newCase;
    newCase = SER_TestUtils.ddCreateCase(true);
    createEmail(newCase.Id);
    new SER_CaseWithAllEmail();
    SER_CaseWithAllEmail instance;
    instance = new SER_CaseWithAllEmail(new ApexPages.StandardController(newCase));
    instance.csId = newCase.Id;
    List<EmailMessage> emailList;
    emailList = instance.getSortEmails();
    Id nullId;
    instance.csId = nullId;
    instance.getSortEmails();
    System.assert (emailList.size() > 0,'Error');
  }
}