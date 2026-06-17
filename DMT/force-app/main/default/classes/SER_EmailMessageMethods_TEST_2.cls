/**************************************************************************
    Name:            SER_EmailMessageMethods_TEST_2
    Description:     Clase de test de la clase EmailMessageMethods

***************************************************************************/
@isTest
private class SER_EmailMessageMethods_TEST_2 {

  /*-----------------------------------------------------------------------
      Description: Init GTB data 1.
  ------------------------------------------------------------------------*/
  private static Map<Id,EmailMessage> initGTBData1() {
    Map<Id,EmailMessage> response;
    response = new Map<Id,EmailMessage>();

    SER_EmailDefaultValues_Assignment__c newCSR01;
    newCSR01 = new SER_EmailDefaultValues_Assignment__c(
      Name                            = 'GTB1',
      SER_Queue__c                    = 'SER_GTB1',
      SER_FromAddres__c               = 'testemailaddress01@example.com',
      SER_OutboundMailbox__c          = 'Email GTB',
      SER_OutboundFromAddress__c      = 'testemailaddress02@example.com',
      SER_MailingGroup__c             = SER_Constant.BUSINESS_GTB);
    insert newCSR01;

    Case newCase;
    newCase = createCase();

    SER_Case_TriggerHelper.map_EmailToCase.put(newCase.Id, newCase);

    EmailMessage em01GM;
    em01GM = createEmail(newCase.Id);

    Group gtbGroup;
    gtbGroup = new Group(DeveloperName = 'SER_GTB1', Email = 'dummy@noenviaremail.error',Name = SER_Constant.BUSINESS_GTB, Type = 'Queue');
    insert gtbGroup;

    QueueSobject mappingObject;
    mappingObject = new QueueSobject(QueueId = gtbGroup.Id, SobjectType = 'Case');

    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert mappingObject;
    }

    response.put(em01GM.Id, em01GM);

    return response;
  }

  /*-----------------------------------------------------------------------
      Description: Init GTB data 2.
  ------------------------------------------------------------------------*/
  private static Map<Id,EmailMessage> initGTBData2() {
    Map<Id,EmailMessage> response;
    response = new Map<Id,EmailMessage>();

    SER_EmailDefaultValues_Assignment__c newCSR01;
    newCSR01 = new SER_EmailDefaultValues_Assignment__c(
      Name                            = 'GTB2',
      SER_Queue__c                    = 'SER_GTB2',
      SER_FromAddres__c               = 'testemailaddress01@example.com',
      SER_OutboundMailbox__c          = 'Email GTB',
      SER_OutboundFromAddress__c      = 'testemailaddress03@example.com',
      SER_MailingGroup__c             = SER_Constant.BUSINESS_GTB);
    insert newCSR01;

    Case newCase;
    newCase = createCase();

    SER_Case_TriggerHelper.map_EmailToCase.put(newCase.Id, newCase);

    EmailMessage em01GM;
    em01GM = createEmail(newCase.Id);

    Group gtbGroup;
    gtbGroup = new Group(DeveloperName = 'SER_GTB2', Email = 'dummy@noenviaremail.error',Name = SER_Constant.BUSINESS_GTB, Type = 'Queue');
    insert gtbGroup;

    response.put(em01GM.Id, em01GM);

    Id gtbProfileId;
    gtbProfileId  = [Select Id from Profile Where Name = 'BBVA Desktop GTB Standard' Limit 1].Id;
    User testUser;
    testUser    = new User(
      Lastname   = 'LastNameTest',
      Alias      = 'Alias',
      Email      = 'ppp@ppp.com',
      username   = 'testUser69@testUser.com',
      ProfileId  = gtbProfileId,
      ID_User__c = 'XEPrueba',
      isActive   = True,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey ='en_US',
      languagelocalekey='en_US');
    insert testUser;

    Assignment_GTB_owners__c gtbCS;
    gtbCS = new Assignment_GTB_owners__c(
      fromEmail__c = 'test@test.com',
      SER_ID_User__c   = 'XEPrueba',
      Name         = 'csTest');
    insert gtbCS;

    return response;
  }

  /*-----------------------------------------------------------------------
      Description: createCase.
  ------------------------------------------------------------------------*/
  private static Case createCase() {
    SER_TestUtils_3.initCustomsetting();
    Case newCase;
    newCase = new Case();
    newCase.RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName('Case','SER_GTB_User');
    newCase.SER_Product__c            = 'BBVA FINET';
    newCase.Subject                   = 'test subject';
    newCase.Description               = 'TEST Description';
    newCase.Type                      = 'ACCESO';
    newCase.Subtype__c                = 'ACCESO';
    newCase.SER_Type_EST__c           = 'Acceso - FINET';
    newCase.SER_Classification__c     = 'Consulta';
    newCase.SuppliedEmail             = 'testemailaddress@example.com';
    newCase.SER_Business_Case_Type__c = SER_Constant.BUSINESS_GTB;
    newCase.SER_ToAddresses__c        = 'testemailaddress@example.com';
    newCase.origin                    = 'Email GTB';
    insert newCase;
    return newCase;
  }

  /*-----------------------------------------------------------------------
      Description: createEmail.
  ------------------------------------------------------------------------*/
  private static EmailMessage createEmail(Id caseId) {
    EmailMessage em01GM;
    em01GM = new EmailMessage();
    em01GM.textbody    = 'Test Body ref:_1234ABCd:ref';
    em01GM.Subject     = 'test subject';
    em01GM.ToAddress   = 'testemailaddress01@example.com';
    em01GM.CcAddress   = 'testemailaddress06@example.com';
    em01GM.FromAddress = 'test@test.com';
    em01GM.ParentId    = caseId;
    em01GM.Incoming    = true;
    em01GM.Status = '0';
    insert em01GM;
    return em01GM;
  }




  /*-----------------------------------------------------------------------
      Description:   Method to test SER_E2C_CaseRedirect.setCaseFields
      the GTB casuistry to put Owner by default.
  ------------------------------------------------------------------------*/
  @isTest
  static void gtbE2cDefaultCaseOwnerTEST() {
    Map<Id,EmailMessage> newMap;
    newMap = initGTBData1();
    Test.startTest();
    SER_EmailMessageMethods.assigner_RelatedCaseOwner(newMap);
    Case newCase;
    newCase = [SELECT Id, Owner.Name FROM Case WHERE origin = 'Email GTB' LIMIT 1];
    System.assertEquals(SER_Constant.BUSINESS_GTB, newCase.Owner.Name, 'Error1');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
      Description:   Method to test SER_E2C_CaseRedirect.setCaseFields
      the GTB casuistry to put GTB Owner.
  ------------------------------------------------------------------------*/
  @isTest
  static void gtbE2cCaseOwnerTEST() {
    Map<Id,EmailMessage> newMap;
    newMap = initGTBData2();
    Test.startTest();
    SER_EmailMessageMethods.assigner_RelatedCaseOwner(newMap);
    Case newCase;
    newCase = [SELECT Id, Owner.Name FROM Case WHERE origin = 'Email GTB' LIMIT 1];
    System.assertNotEquals(null, newCase.Id, 'Error2');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
      Description:   Method to test cleaner_MasterCaseNotifications.
  ------------------------------------------------------------------------*/
  @isTest
  static void cleanerMasterCaseNotificationsTEST() {
    Map<Id,EmailMessage> newMap;
    newMap = initGTBData2();
    Test.startTest();
    SER_TriggerHelper.set_MetodFired('send_ChildCasesEmail_UPDATE_PRESENDING', true);
    Case newCase;
    newCase = [SELECT Id, Owner.Name FROM Case WHERE origin = 'Email GTB' LIMIT 1];
    SER_Case_TriggerHelper.map_NotifiedMasterCases.put(newMap.values()[0].ParentId,newCase);
    SER_EmailMessageMethods.cleaner_MasterCaseNotifications(newMap);
    System.assertNotEquals(null, newCase.Id, 'Error3');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
      Description:   Method to test UpdateAddress.
  ------------------------------------------------------------------------*/
  @isTest
  static void updateAddressTEST() {
    Case newCase;
    newCase = createCase();
    EmailMessage email;
    email = createEmail(newCase.Id);
    email.ToAddress = 'qwertyuiopñlkjhgfdsazxcvbnmñlkjhgfdsaqwertyu@poiuhjklklliiuyi.com';
    List<EmailMessage> emails;
    emails = new List<EmailMessage>();
    emails.add(email);
    Test.startTest();
    SER_EmailMessageMethods.UpdateAddress(emails);
    System.assertNotEquals(null, newCase.Id, 'Error4');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
      Description:   Method to test customSplit.
  ------------------------------------------------------------------------*/
  @isTest
  static void customSplitTEST() {
    String toSplit;
    toSplit = 'jjj@jjj.com,ttt@ttt.com';
    String splitKey;
    splitKey = ',';
    Test.startTest();
    SER_EmailMessageMethods.customSplit(toSplit,splitKey);
    System.assertNotEquals(null, toSplit, 'Error5');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
      Description:   Method to test generate_UniqueCode.
  ------------------------------------------------------------------------*/
  @isTest
  static void generateUniqueCodeTEST() {
    Case newCase;
    newCase = createCase();
    newCase.SER_ToAddresses__c = '';
    update newCase;
    EmailMessage email;
    email = createEmail(newCase.Id);
    email.ToAddress = 'qwertyuiopñlkjhgfdsazxcvbnmñlkjhgfdsaqwertyu@poiuhjklklliiuyi.com';
    email.HtmlBody = 'HtmlBody';
    email.textbody = '';
    List<EmailMessage> emails;
    emails = new List<EmailMessage>();
    emails.add(email);
    Test.startTest();
    SER_EmailMessageMethods.UpdateAddress(emails);
    SER_EmailMessageMethods.generate_UniqueCode(emails);
    SER_EmailMessageMethods.assigner_RelatedCaseOwner(null);
    SER_EmailMessageMethods.checker_duplicatedEmailToCase(null);
    SER_EmailMessageMethods.generate_UniqueCode(null);
    SER_EmailMessageMethods.validateFromAddress(null);
    SER_TriggerHelper.set_MetodFired('send_ChildCasesEmail_UPDATE_PRESENDING',true);
    SER_EmailMessageMethods.cleaner_MasterCaseNotifications(null);
    System.assertNotEquals(null, newCase, 'Error6');
    Test.stopTest();
  }
}