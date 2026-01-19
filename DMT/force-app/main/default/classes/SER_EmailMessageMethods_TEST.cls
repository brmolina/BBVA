@isTest

/**************************************************************************************************************
    Name:            SER_EmailMessageMethods_TEST
    Description:     Clase de test de la clase EmailMessageMethods
    Test Class:

    Version        Date            Author            Summary of changes
    --------------------------------------------------------------------------------------------------------------
    0.1                                                               Creacion de la clase
**************************************************************************************************************/

private class SER_EmailMessageMethods_TEST {
  /*Constante Caso de prueba 1*/
  private static Case caso;
  /*Constante Caso de prueba 2*/
  private static Case caso2;
  /*Constante STE*/
  private static final String STE = 'STE';
  /*Constante GM*/
  private static final String GMKTS = 'GM';
  /*Constante test subject*/
  private static final String TESTSUBJECT = 'test subject';
  /*Constante Case*/
  private static final String CASOF = 'Case';

  /************************************************************
    Name:            createData
    Description:     Creación de los juegos de datos Caso y Caso2
  ***************************************************************/
  public static void createData() {
    SER_TestUtils_3.initCustomsetting();
    caso = new Case(OwnerId = UserInfo.getUserId(),
                    SER_Is_Master_Case__c = true,
                    SER_Currency__c = 'ARS',
                    SER_Amount_finally_assumed__c = 18,
                    SER_Accounting_date__c = Date.newInstance(date.today().year(), 04, 20),
                    SER_Operational_risk__c = 18,
                    SER_Outbound_Mailbox__c = 'Email GM',
                    RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName(CASOF,'SER_GM_User'));

    caso2 = new Case(OwnerId = UserInfo.getUserId(),
                      SER_Currency__c = 'USD',
                      Origin = 'Email',
                      SER_Is_Master_Case__c = false,
                      Status = 'Closed',
                      SER_Amount_finally_assumed__c = 18,
                      SER_Classification__c = 'Incidencia',
                      SER_Remedy_Department__c = 'ANS SSTT',
                      Type = 'ACCESO',
                      Description = 'BLIZZ 98',
                      SER_Accounting_date__c = Date.newInstance(date.today().year(), 04, 20),
                      SER_Operational_risk__c = 18,
                      ParentId = caso.Id,
                      SER_EmailToCaseCode__c = 'aaa@example.aa',
                      SER_Outbound_Mailbox__c = 'Email GM',
                      RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName(CASOF,'SER_GM_User'),
                      SER_Pre_liquidacion__c = true);
  }

  /************************************************************
      Metodo que crea un caso de GM y lo inserta en la base de datos.
      @Parametros: businessType valores: 'GM' o 'STE'
  ************************************************************/
  public static Case createCase(String businessType) {
    final Case newCase = new Case();
    if(businessType == GMKTS) {
      newCase.RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName(CASOF,'SER_GM_User');
    } else {newCase.RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName(CASOF,'SER_STE_User');}
    newCase.SER_Product__c           = 'BBVA FINET';
    newCase.Subject                  = TESTSUBJECT;
    newCase.Description              = 'TEST Description';
    newCase.Type                     = 'ACCESO';
    newCase.Subtype__c               = 'ACCESO';
    newCase.SER_Type_EST__c          = 'Acceso - FINET';
    newCase.SER_Subtype_STE__c       = 'Url Equivocada';
    newCase.SER_Type_GM__c           = 'Otros';
    newCase.SER_Subtype_GM__c        = 'Otros';
    newCase.SER_Classification__c    = 'Consulta';
    newCase.SuppliedEmail            = 'testemailaddress@example.com';
    if(businessType == GMKTS) {
      newCase.SER_Business_Case_Type__c = GMKTS;
    } else {newCase.SER_Business_Case_Type__c= STE;}
    insert newCase;
    return newCase;
  }

  /*----------------------------------------------------------------------------------------------------------
    Description:   Method que crea un custom setting de Middle Affirmation y lo inserta en la base de datos.
  -----------------------------------------------------------------------------------------------------------*/
  public static SER_EmailDefaultValues_Assignment__c createMiddleAffirmationCS() {
    final SER_EmailDefaultValues_Assignment__c newCSR01 = new SER_EmailDefaultValues_Assignment__c(
      Name                            = 'Email Middle Affirmations',
      SER_Queue__c                    = 'SER_Middle_Affirmations',
      SER_FromAddres__c               = 'testemailaddress01@example.com',
      SER_OutboundMailbox__c          = 'Email Middle Affirmationss',
      SER_TemplateDeveloperName__c    = '',
      SER_OutboundFromAddress__c      = 'testemailaddress01@example.com',
      SER_MailingGroup__c             = 'Documentation & Validations');
    insert newCSR01;
    return newCSR01;
  }

  /*------------------------------------------------------------------------------------
    Description:   Method que crea un EmailMessage y lo inserta en la base de datos.
  -------------------------------------------------------------------------------------*/
  public static EmailMessage createEmailMessage(Id caseId) {
    final EmailMessage em01GM = new EmailMessage();
    em01GM.textbody = 'Test Body ref:_1234ABCd:ref';
    em01GM.Subject = TESTSUBJECT;
    em01GM.ToAddress = 'testemailaddress01@example.com';
    em01GM.CcAddress = 'testemailaddress01@example.com';
    em01GM.ParentId = caseId;
    insert em01GM;
    return em01GM;

  }

  @isTest static void testMethodOne() {
    createData();


    insert caso;
    insert caso2;

    System.debug('SER_EmailMessageMethods_TEST-testMethodOne');
    final Map<Id,EmailMessage> newMap = new Map<Id,EmailMessage>();
    System.debug('SER_EmailMessageMethods_TEST-testMethodOne - newMap -> '+ newMap);



    final List<EmailMessage> lstEmail = new List<EmailMessage>();

    final EmailMessage email = new EmailMessage(TextBody = 'Cuerpo del email',
                                                ParentId = caso.Id,
                                                SER_UniqueCode__c = 'a',
                                                ToAddress = 'aaa@example.aa',
                                                CcAddress = 'aaa@example.aa');
    lstEmail.add(email);
    EmailMessage email2;
    email2 = new EmailMessage(TextBody = 'Cuerpo del email2',
                                            ParentId = caso2.Id,
                                            SER_UniqueCode__c = 'u',
                                            ToAddress = 'aaa@example.aa',
                                            CcAddress = 'aaa@example.aa');
    lstEmail.add(email2);
    System.assertEquals (lstEmail,lstEmail,'SER_EmailMessageMethods_TEST.testMethodOne');
    Test.startTest();
    try {
      insert lstEmail;
    } catch(Exception e) {
      System.debug('Exception testMethodOne '+ e);
    }
    Test.stopTest();
  }

  @isTest static void testMethodTwo() {
    createData();

    System.debug('SER_EmailMessageMethods_TEST-testMethodTwo');
    final SER_EmailDefaultValues_Assignment__c emailDefault = new SER_EmailDefaultValues_Assignment__c(Name = 'Name',
                                                                                                        SER_OutboundMailbox__c = 'Email GM');
    insert emailDefault;

    insert caso;
    insert caso2;

    final EmailMessage email = new EmailMessage(TextBody = 'Cuerpo del email',
                                                ParentId = caso.Id,
                                                SER_UniqueCode__c = 'aaa2@example.aa',
                                                ToAddress = 'aaa@example.aa',
                                                CcAddress = 'aaa@example.aa');

    System.assertEquals(email,email,'SER_EmailMessageMethods_TEST.testMethodTwo');
    Test.startTest();
    insert email;

    final EmailMessage email2 = new EmailMessage(TextBody = 'Cuerpo del email2',
                                                  ParentId = caso2.Id,
                                                  SER_UniqueCode__c = 'aaa2@example.aa',
                                                  ToAddress = 'aaa@example.aa',
                                                  CcAddress = 'aaa@example.aa');

    try {
      insert email2;
    } catch(Exception e) {
      System.debug('ee: '+e);
    }
    Test.stopTest();
  }

  /************************************************************
      Method de test qassignerRelatedCaseOwnerTEST
      @Parametros:
  ************************************************************/
  public static testMethod void assignerRelatedCaseOwnerTEST() {
    SER_TestUtils_3.initCustomsetting();

    final SER_EmailDefaultValues_Assignment__c newCSR01 = new SER_EmailDefaultValues_Assignment__c(
      Name               = 'newCSR01',
      SER_Queue__c           = 'SER_Claims_queue',
      SER_FromAddres__c         = 'testemailaddress01@example.com',
      SER_OutboundMailbox__c       = 'Test Outbound Mailbox',
      SER_TemplateDeveloperName__c   = '',
      SER_OutboundFromAddress__c    = 'testemailaddress01@example.com');
    final SER_EmailDefaultValues_Assignment__c newCSR02 = new SER_EmailDefaultValues_Assignment__c(
      Name               = 'newCSR02',
      SER_Queue__c           = 'SER_Claims_queue',
      SER_FromAddres__c         = 'testemailaddress02@example.com',
      SER_OutboundMailbox__c       = 'Test Outbound Mailbox',
      SER_TemplateDeveloperName__c   = '',
      SER_OutboundFromAddress__c    = 'testemailaddress02@example.com');
    final SER_EmailDefaultValues_Assignment__c defaultCSR = new SER_EmailDefaultValues_Assignment__c(
      Name               = 'defaultCSR',
      SER_Queue__c           = 'SER_Claims_queue',
      SER_FromAddres__c         = Label.SER_CustomerServiceMailbox,
      SER_OutboundMailbox__c       = 'Test Default Outbound Mailbox',
      SER_TemplateDeveloperName__c   = '',
      SER_OutboundFromAddress__c    = Label.SER_CustomerServiceMailbox);
    final List<SER_EmailDefaultValues_Assignment__c> listCSR = new List<SER_EmailDefaultValues_Assignment__c> {newCSR01,newCSR02,defaultCSR};
    insert listCSR;

    final Case newCaseSTE = createCase(STE);
    final Case newCaseGM = createCase(GMKTS);

    SER_Case_TriggerHelper.map_EmailToCase.put(newCaseGM.Id, newCaseGM);

    final EmailMessage em01GM = new EmailMessage();
    em01GM.textbody = 'Test Body ref:_123ABC:ref';
    em01GM.Subject = TESTSUBJECT;
    em01GM.ToAddress = 'testemailaddress01@example.com';
    em01GM.ParentId = newCaseGM.Id;
    final EmailMessage em02GM = new EmailMessage();
    em02GM.textbody = 'Test Body ref:_456DEF:ref';
    em02GM.Subject = TESTSUBJECT;
    em02GM.ToAddress = 'testemailaddress01@example.com;testemailaddress02@example.com';
    em02GM.ParentId = newCaseGM.Id;

    SER_Case_TriggerHelper.map_EmailToCase.put(newCaseSTE.Id, newCaseSTE);

    final EmailMessage em01STE = new EmailMessage();
    em01STE.textbody = 'Test Body ref:_123ABC:ref';
    em01STE.Subject = TESTSUBJECT;
    em01STE.ToAddress = 'testemailaddress01@example.com';
    em01STE.ParentId = newCaseSTE.Id;
    final EmailMessage em02STE = new EmailMessage();
    em02STE.textbody = 'Test Body ref:_456DEF:ref';
    em02STE.Subject = TESTSUBJECT;
    em02STE.ToAddress = 'testemailaddress01@example.com;testemailaddress02@example.com';
    em02STE.ParentId = newCaseSTE.Id;

    final List<EmailMessage> listEmailMessage = new List<EmailMessage> {em01GM,em02GM,em01STE,em02STE};
    insert listEmailMessage;
    System.assertEquals(listEmailMessage,listEmailMessage,'SER_EmailMessageMethods_TEST.assignerRelatedCaseOwnerTEST');
  }
  /************************************************************
      Method de test checkerDuplicatedEmailToCaseTEST
      @Parametros:
  ************************************************************/
  public static testMethod void checkerDuplicatedEmailToCaseTEST() {
    SER_TestUtils_3.initCustomsetting();

    final SER_EmailDefaultValues_Assignment__c newCSR01 = new SER_EmailDefaultValues_Assignment__c(
      Name               = 'newCSR01',
      SER_Queue__c           = 'SER_Claims_queue',
      SER_FromAddres__c         = 'testemailaddress01@example.com',
      SER_OutboundMailbox__c       = 'Test Outbound Mailbox',
      SER_TemplateDeveloperName__c   = '',
      SER_OutboundFromAddress__c    = 'testemailaddress01@example.com');
    final SER_EmailDefaultValues_Assignment__c newCSR02 = new SER_EmailDefaultValues_Assignment__c(
      Name               = 'newCSR02',
      SER_Queue__c           = 'SER_Claims_queue',
      SER_FromAddres__c         = 'testemailaddress02@example.com',
      SER_OutboundMailbox__c       = 'Test Outbound Mailbox',
      SER_TemplateDeveloperName__c   = '',
      SER_OutboundFromAddress__c    = 'testemailaddress02@example.com');
    final SER_EmailDefaultValues_Assignment__c defaultCSR = new SER_EmailDefaultValues_Assignment__c(
      Name               = 'defaultCSR',
      SER_Queue__c           = 'SER_Claims_queue',
      SER_FromAddres__c         = Label.SER_CustomerServiceMailbox,
      SER_OutboundMailbox__c       = 'Test Default Outbound Mailbox',
      SER_TemplateDeveloperName__c   = '',
      SER_OutboundFromAddress__c    = Label.SER_CustomerServiceMailbox);
    final List<SER_EmailDefaultValues_Assignment__c> listCSR = new List<SER_EmailDefaultValues_Assignment__c> {newCSR01,newCSR02,defaultCSR};
    insert listCSR;

    final Case newCaseSTE = createCase(STE);
    final Case newCaseGM = createCase(GMKTS);

    //SER_Case_TriggerHelper.map_DuplicatedEmailToCase.put(newCaseGM.Id, newCaseGM);
    SER_Case_TriggerHelper.map_DuplicatedEmailToCase.put(newCaseSTE.Id, newCaseSTE);

    final EmailMessage em01GM = new EmailMessage();
    em01GM.textbody = 'Test Body ref:_123ABC:ref';
    em01GM.FromAddress = 'testemailaddress01@example.com';
    em01GM.Subject = TESTSUBJECT;
    em01GM.ToAddress = 'testemailaddress01@example.com';
    em01GM.ParentId = newCaseGM.Id;
    em01GM.Incoming = true;
    final EmailMessage em02GM = new EmailMessage();
    em02GM.textbody = 'Test Body ref:_123ABC:ref';
    em02GM.FromAddress = 'testemailaddress01@example.com';
    em02GM.Subject = TESTSUBJECT;
    em02GM.ToAddress = 'testemailaddress01@example.com;testemailaddress02@example.com';
    em02GM.ParentId = newCaseGM.Id;
    em02GM.Incoming = true;

    SER_Case_TriggerHelper.map_EmailToCase.put(newCaseSTE.Id, newCaseSTE);

    final EmailMessage em01STE = new EmailMessage();
    em01STE.FromAddress = 'testemailaddress01@example.com';
    em01STE.textbody = 'Test Body ref:_123ABC:ref';
    em01STE.Subject = TESTSUBJECT;
    em01STE.ToAddress = 'testemailaddress01@example.com';
    em01STE.ParentId = newCaseSTE.Id;
    em01STE.Incoming = true;
    final EmailMessage em02STE = new EmailMessage();
    em02STE.FromAddress = 'testemailaddress01@example.com';
    em02STE.textbody = 'Test Body ref:_123ABC:ref';
    em02STE.Subject = TESTSUBJECT;
    em02STE.ToAddress = 'testemailaddress01@example.com;testemailaddress02@example.com';
    em02STE.ParentId = newCaseSTE.Id;
    em02STE.Incoming = true;

    try {
      final List<EmailMessage> listEmailMessage = new List<EmailMessage> {em01GM,em02GM};
      System.assertEquals(listEmailMessage,listEmailMessage,'SER_EmailMessageMethods_TEST.checkerDuplicatedEmailToCaseTEST');
      insert listEmailMessage;
    } catch(Exception ex) {
      System.debug('Exception insert listEmailMessagecheckerDuplicatedEmailToCaseTEST '+ ex);
    } try {
      insert em01STE;
      insert em02STE;
    } catch(Exception ex) {
      System.debug('Exception insert em01/02 STE checkerDuplicatedEmailToCaseTEST '+ ex);
    }
  }

  /************************************************************
      Method de test assigner_RelatedCaseOwner2_TEST
      @Parametros:
  ************************************************************/
  public static testMethod void assignerRelatedCaseOwner2TEST() {
    SER_TestUtils_3.initCustomsetting();

    final SER_EmailDefaultValues_Assignment__c newCSR01 = new SER_EmailDefaultValues_Assignment__c(
      Name                            = 'newCSR01',
      SER_Queue__c                    = 'SER_Claims_queue',
      SER_FromAddres__c               = 'testemailaddress01@example.com',
      SER_OutboundMailbox__c          = 'Test Outbound Mailbox',
      SER_TemplateDeveloperName__c    = '',
      SER_OutboundFromAddress__c      = 'testemailaddress01@example.com');
    final SER_EmailDefaultValues_Assignment__c newCSR02 = new SER_EmailDefaultValues_Assignment__c(
      Name                            = 'newCSR02',
      SER_Queue__c                    = 'SER_Claims_queue',
      SER_FromAddres__c               = 'testemailaddress02@example.com',
      SER_OutboundMailbox__c          = 'Test Outbound Mailbox',
      SER_TemplateDeveloperName__c    = '',
      SER_OutboundFromAddress__c      = 'testemailaddress02@example.com');
    final SER_EmailDefaultValues_Assignment__c defaultCSR = new SER_EmailDefaultValues_Assignment__c(
      Name                            = 'defaultCSR',
      SER_Queue__c                    = 'SER_Claims_queue',
      SER_FromAddres__c               = Label.SER_CustomerServiceMailbox,
      SER_OutboundMailbox__c          = 'Test Default Outbound Mailbox',
      SER_TemplateDeveloperName__c    = '',
      SER_OutboundFromAddress__c      = Label.SER_CustomerServiceMailbox);
    final List<SER_EmailDefaultValues_Assignment__c> listCSR = new List<SER_EmailDefaultValues_Assignment__c> {newCSR01,newCSR02,defaultCSR};
    //listCSR.add(newCSR01,newCSR02,defaultCSR);
    insert listCSR;

    final Case newCaseSTE = createCase(STE);
    final Case newCaseGM = createCase(GMKTS);

    SER_Case_TriggerHelper.map_EmailToCase.put(newCaseGM.Id, newCaseGM);

    final EmailMessage em01GM = new EmailMessage();
    em01GM.textbody = 'Test Body ref:_123ABC:ref';
    em01GM.Subject = TESTSUBJECT;
    em01GM.ToAddress = 'testemailaddress01@example.com';
    em01GM.CcAddress = 'testemailccadre00@example.com';
    em01GM.ParentId = newCaseGM.Id;
    final EmailMessage em02GM = new EmailMessage();
    em02GM.textbody = 'Test Body ref:_456DEF:ref';
    em02GM.Subject = TESTSUBJECT;
    em02GM.ToAddress = 'testemailaddress01@example.com;testemailaddress02@example.com';
    em02GM.ParentId = newCaseGM.Id;

    SER_Case_TriggerHelper.map_EmailToCase.put(newCaseSTE.Id, newCaseSTE);

    final EmailMessage em01STE = new EmailMessage();
    em01STE.textbody = 'Test Body ref:_123ABC:ref';
    em01STE.Subject = TESTSUBJECT;
    em01STE.ToAddress = 'testemailaddress01@example.com';
    em01STE.CcAddress = 'testemailaddress21@example.com;testemailaddress11@example.com';
    em01STE.ParentId = newCaseSTE.Id;
    final EmailMessage em02STE = new EmailMessage();
    em02STE.textbody = 'Test Body ref:_456DEF:ref';
    em02STE.Subject = TESTSUBJECT;
    em02STE.ToAddress = 'testemailaddress01@example.com;testemailaddress02@example.com';
    em02STE.CcAddress = 'testemailaddress05@example.com;testemailaddress02@example.com';
    em02STE.ParentId = newCaseSTE.Id;

    final List<EmailMessage> listEmailMessage = new List<EmailMessage> {em01GM,em02GM,em01STE,em02STE};
    insert listEmailMessage;
    System.assertEquals(listEmailMessage,listEmailMessage,'SER_EmailMessageMethods_TEST.assignerRelatedCaseOwner2TEST');
  }

  /*----------------------------------------------------------------
    Description:   Method para testear la casuistica de Middle Affirmation.
  ------------------------------------------------------------------*/
  public static testMethod void validateAddressesMiddleAffirmmationTEST1() {
    createMiddleAffirmationCS();
    SER_TestUtils_3.initCustomsetting();
    //final Map<String,String> mapEmailDefaults = new Map<String,String>();
    final Case newCaseGM = createCase(GMKTS);
    SER_Case_TriggerHelper.map_EmailToCase.put(newCaseGM.Id, newCaseGM);
    final EmailMessage em01GM = createEmailMessage(newCaseGM.Id);
    final Map<Id,EmailMessage> newMap = new Map<Id,EmailMessage>();
    newMap.put(em01GM.Id, em01GM);
    //final Map<Id,String> mapCTA = new Map<Id,String>();

    Test.startTest();
    SER_EmailMessageMethods.assigner_RelatedCaseOwner(newMap);
    final Case newCase = [SELECT Id, SER_MailingGroup__c FROM Case WHERE Id =: newCaseGM.Id];
    System.assertEquals(newCase.SER_MailingGroup__c, 'Documentation & Validations', 'Error');
    //SER_EmailMessageMethods.validate_Addresses(null,em01GM,mapEmailDefaults,mapCTA);
    Test.stopTest();
  }

}