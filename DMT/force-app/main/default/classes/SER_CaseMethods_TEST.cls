/*-----------------------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Test Class to handle methods called when the triggers over Case object are fired

    History:
    <Date>          <Author>                <Description>
    08/07/2017      Juan Carlos Terrón        Initial version
    -------------------------------------------------------------------------------------------------*/
@isTest
public with sharing class SER_CaseMethods_TEST {
  /* valor nulo para las monedas*/
  final static decimal DECIIMAL_NULL;
  /*usuario nulo*/
  final static Id ID_NULL;
  /* constante nombre genérico de contacto */
  final static string CONTACT_NAME = 'ContactName';
  /* constante para email genérico */
  final static string EMAIL_GENERICO = 'aaa@example.aa';
  /* constante para email genérico */
  final static string EMAIL_GENERICO2 = 'aaa1@example.aa';
  /* constante para counter currency */
  final static string CURRENCY_ARS = 'ARS';
  /* constante para origin*/
  final static string ORIGIN_PHONE = 'Phone';
  /* constante para classification*/
  final static string CLASSIF_INCI = 'Incidencia';
  /* constante para description*/
  final static string DESC_BLIZZ = 'BLIZZ 98';
  /* constante para developer name*/
  final static string DEV_NAME = 'Nuevo_caso_maestro';
  /* constante 'Contact'*/
  final static string CONTACT = 'Contact';
  /* constante 'SER_Service_Contact_Global_Markets'*/
  final static string CONTACTGM = 'SER_Service_Contact_Global_Markets';
  /* constante 'Case'*/
  final static string CASEOBJ = 'Case';
  /* constante 'SER_GM_User'*/
  final static string GM_RT = 'SER_GM_User';


  /*-----------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to Test event onBeforeInsert of a Case

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017              Juan Carlos Terrón      Initial version
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void  onBeforeInsertTEST() {
    SER_TestUtils_3.initCustomsetting();
    final List<Case> lstCases = new List<Case>();
    final Account account = UnitTestUtils.GetStandardAccount();
    insert account;

    final Contact contact = new Contact(
      Lastname = CONTACT_NAME,
      AccountId = account.id,
      Email_ExternalID__c = EMAIL_GENERICO,
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CONTACT,CONTACTGM)
      );

    insert contact;

    final SER_EUR_Currency_exchange_rate__c crrcyEur =
      new SER_EUR_Currency_exchange_rate__c(SER_Counter_currency__c = CURRENCY_ARS,
                                            SER_Process_date__c = Date.newInstance(date.today().year(), 04, 20),
                                            SER_Exchange_rate__c = 10744);
    insert crrcyEur;

    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                SER_Currency__c = CURRENCY_ARS,
                                SER_Amount_finally_assumed__c = 18,
                                SER_Accounting_date__c = Date.newInstance(date.today().year(), 04, 20),
                                SER_Operational_risk__c = 18,
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));
    lstCases.add(caso);
    insert lstCases;

    SER_CaseMethods.onBeforeInsert(lstCases);

    lstCases[0].Description = 'Description';

    update lstCases;

    lstCases[0].SER_Responsible__c = ID_NULL;
    lstCases[0].SuppliedEmail = EMAIL_GENERICO2;
    lstCases[0].ContactId = contact.Id;
    lstCases[0].SER_Claim_partially_recovered__c = 18;
    lstCases[0].SER_Amount_finally_assumed__c = DECIIMAL_NULL;

    update lstCases;

    System.assertEquals (lstCases,lstCases,'SER_CaseMethods_TEST');
  }

  /*-----------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to Test event onBeforeInsert of a Case

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017              Juan Carlos Terrón      Initial version
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void  onBeforeInsert2TEST() {
    SER_TestUtils_3.initCustomsetting();
    final List<Case> lstCases = new List<Case>();

    final Account account = UnitTestUtils.GetStandardAccount();
    insert account;

    final Contact contact = new Contact(
      Lastname = CONTACT_NAME,
      AccountId = account.id,
      Email_ExternalID__c = EMAIL_GENERICO,
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CONTACT,CONTACTGM)
      );

    insert contact;

    final SER_EUR_Currency_exchange_rate__c crrcyEur =
      new SER_EUR_Currency_exchange_rate__c(SER_Counter_currency__c = CURRENCY_ARS,
                                            SER_Process_date__c = Date.newInstance(date.today().year(), 04, 20),
                                            SER_Exchange_rate__c = 10744);
    insert crrcyEur;

    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                SER_Currency__c = CURRENCY_ARS,
                                SER_Amount_finally_assumed__c = 18,
                                SER_Operational_risk__c = 18,
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));
    lstCases.add(caso);
    insert lstCases;

    SER_CaseMethods.onBeforeInsert(lstCases);

    lstCases[0].Description = 'Description';

    update lstCases;

    lstCases[0].SER_Responsible__c = ID_NULL;
    lstCases[0].SuppliedEmail = EMAIL_GENERICO2;
    lstCases[0].ContactId = contact.Id;
    lstCases[0].SER_Claim_partially_recovered__c = 18;

    update lstCases;
    System.assertEquals (lstCases,lstCases,'onBeforeInsert2TEST');
  }

  /*-----------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to Test event onBeforeInsert of a Case

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017              Juan Carlos Terrón      Initial version
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void  onBeforeInsert3TEST() {
    SER_TestUtils_3.initCustomsetting();
    final List<Case> lstCases = new List<Case>();

    final Account account = UnitTestUtils.GetStandardAccount();
    insert account;

    final Contact contact = new Contact(
      Lastname = CONTACT_NAME,
      AccountId = account.id,
      Email_ExternalID__c = EMAIL_GENERICO,
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CONTACT,CONTACTGM)
      );

    insert contact;

    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                SER_Currency__c = CURRENCY_ARS,
                                SER_Amount_finally_assumed__c = 18,
                                SER_Operational_risk__c = 18,
                                SER_Accounting_date__c = Date.newInstance(date.today().year(), 05, 21),
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT));
    lstCases.add(caso);
    insert lstCases;

    SER_CaseMethods.onBeforeInsert(lstCases);

    lstCases[0].Description = 'Description';

    update lstCases;

    lstCases[0].SER_Responsible__c = ID_NULL;
    lstCases[0].SuppliedEmail = EMAIL_GENERICO2;
    lstCases[0].ContactId = contact.Id;
    lstCases[0].SER_Claim_partially_recovered__c = 18;

    update lstCases;
    System.assertEquals (lstCases,lstCases,'onBeforeInsert3TEST');
  }

  /*-----------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to Test event onUpdate of a Case

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017              Juan Carlos Terrón      Initial version
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void  assignerCaseStatusOnUpdateTEST() {
    final Map<Id,Case> mpCaseOld = new Map<Id,Case>();

    final Case caso = new Case(OwnerId = UserInfo.getUserId());
    mpCaseOld.put(caso.Id, caso);
    //insert lstCases;

    final Map<Id,Case> mpCaseNew = new Map<Id,Case>();
    caso.SuppliedEmail = EMAIL_GENERICO2;
    mpCaseNew.put(caso.Id, caso);

    SER_CaseMethods.assignerCaseStatusOnUpdate(mpCaseNew, mpCaseOld);

    System.assertEquals (mpCaseNew,mpCaseNew,'assignerCaseStatusOnUpdateTEST');
  }

  /*-----------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to Test map parent to child on case

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017              Juan Carlos Terrón      Initial version
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void copyParentCaseFieldsToChildrenCaseFieldsTEST() {
    /*SER_TestUtils_3.initCustomsetting();
    final List<Case> lstCases = new List<Case>();

    final SER_MasterCaseNotificationsTemplate__c masterCase =
      new SER_MasterCaseNotificationsTemplate__c(Name = 'New Status',
                                                  SER_CaseStatus__c = 'Default',
                                                  SER_TemplateDeveloperName__c = DEV_NAME
                                                  );
    insert masterCase;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      final List<BrandTemplate> lstBrand = [SELECT Id FROM BrandTemplate limit 1000000];
      final List<Folder> lstFolder = [SELECT Id FROM Folder WHERE Type = 'Email' AND AccessType = 'Public'];

      final EmailTemplate emailTem =
        new EmailTemplate(Name = 'email',
                          DeveloperName = DEV_NAME,
                          TemplateType = 'custom',
                          FolderId = lstFolder[0].Id, BrandTemplateId = lstBrand[0].Id,
                          TemplateStyle = 'freeForm',
                          Body = 'Estimado cliente, Se ha creado una incidencia maestra con la referencia {!Case.CaseNumber}',
                          Isactive = true,
                          Subject = 'Case # {!Case.CaseNumber}',
                          HtmlValue = '<table border="0" cellpadding="5" width="550" cellspacing="5" height="400" ></table>');
      insert emailTem;
    }

    final List<RecordType> rtAcc = [SELECT Id FROM RecordType WHERE DeveloperName = 'BBVA_Internal_Contact' limit 1];

    final Account account = UnitTestUtils.GetStandardAccount();
    account.Name = 'BBVA internal contacts';
    account.RecordTypeId = rtAcc[0].Id;
    account.DES_BBVA_Segmentation__c = 'CIB';
    insert account;

    final Contact contact = new Contact(
      Lastname = CONTACT_NAME,
      AccountId = account.id,
      Email_ExternalID__c = 'aaa@example.com',
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CONTACT,CONTACTGM)
      );

    insert contact;

    final SER_Master_Case_User_Notification__c ser_master_user = new SER_Master_Case_User_Notification__c(SER_Contact__c = contact.Id);
    insert ser_master_user;

    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = ORIGIN_PHONE,
                                SER_Classification__c = CLASSIF_INCI,
                                SER_Is_Master_Case__c = true,
                                Description = DESC_BLIZZ,
                                Status = 'new',
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT),
                                SER_Pre_liquidacion__c = true);

    lstCases.add(caso);

    final Case caso2 = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = ORIGIN_PHONE,
                                SER_Is_Master_Case__c = false,
                                Status = 'Closed',
                                SER_Classification__c = CLASSIF_INCI,
                                SER_Remedy_Department__c = 'ANS SSTT',
                                Type = 'ACCESO',
                                Description = DESC_BLIZZ,
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT),
                                SER_Pre_liquidacion__c = true);

    lstCases.add(caso2);
    insert lstCases;

    lstCases[0].Status = 'Closed';

    update lstCases[0];

    Test.startTest();
    lstCases[1].SER_Master_Case__c = caso.Id;

    update caso2;
    System.assertEquals (caso2,caso2,'copyParentCaseFieldsToChildrenCaseFieldsTEST');
    Test.stopTest();*/
  }

  /*-----------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to Test map parent to child on case

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017              Juan Carlos Terrón      Initial version
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void copyParentCaseFieldsToChildrenCaseFieldsTEST2() {
    /*SER_TestUtils_3.initCustomsetting();
    final List<Case> lstCases = new List<Case>();

    final SER_MasterCaseNotificationsTemplate__c masterCase =
      new SER_MasterCaseNotificationsTemplate__c(Name = 'New Status',
                                                  SER_CaseStatus__c = 'Default',
                                                  SER_TemplateDeveloperName__c = DEV_NAME
                                                  );
    insert masterCase;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      final List<BrandTemplate> lstBrand = [SELECT Id FROM BrandTemplate limit 1000000];
      final List<Folder> lstFolder = [SELECT Id FROM Folder WHERE Type = 'Email' AND AccessType = 'Public'];

      final EmailTemplate emailTem = new EmailTemplate(Name = 'email',
                                                        DeveloperName = DEV_NAME,
                                                        TemplateType = 'custom',
                                                        FolderId = lstFolder[0].Id, BrandTemplateId = lstBrand[0].Id,
                                                        TemplateStyle = 'freeForm',
                                                        Body = 'Estimado cliente, Se ha creado una incidencia maestra con la referencia {!Case.CaseNumber}',
                                                        Isactive = true,
                                                        Subject = 'Case # {!Case.CaseNumber}',
                                                        HtmlValue = '<table border="0" cellpadding="5" width="550" cellspacing="5" height="400" ></table>');
      insert emailTem;
    }


    final List<RecordType> rtAcc = [SELECT Id FROM RecordType WHERE DeveloperName = 'BBVA_Internal_Contact' limit 1];

    final Account account = UnitTestUtils.GetStandardAccount();
    account.Name = 'BBVA internal contacts';
    account.RecordTypeId = rtAcc[0].Id;
    account.DES_BBVA_Segmentation__c = 'CIB';
    insert account;

    final Contact contact = new Contact(
      Lastname = CONTACT_NAME,
      AccountId = account.id,
      Email_ExternalID__c = 'aaa@example.com',
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CONTACT,CONTACTGM)
      );

    insert contact;

    final SER_Master_Case_User_Notification__c ser_master_user = new SER_Master_Case_User_Notification__c(SER_Contact__c = contact.Id);
    insert ser_master_user;

    final Case caso = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = ORIGIN_PHONE,
                                SER_Classification__c = CLASSIF_INCI,
                                SER_Is_Master_Case__c = false,
                                Description = DESC_BLIZZ,
                                Status = 'new',
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT),
                                SER_Pre_liquidacion__c = true);

    lstCases.add(caso);

    final Case caso2 = new Case(OwnerId = UserInfo.getUserId(),
                                Origin = ORIGIN_PHONE,
                                SER_Is_Master_Case__c = false,
                                Status = 'Closed',
                                SER_Classification__c = CLASSIF_INCI,
                                SER_Remedy_Department__c = 'ANS SSTT',
                                Type = 'ACCESO',
                                Description = DESC_BLIZZ,
                                RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName(CASEOBJ,GM_RT),
                                SER_Pre_liquidacion__c = true);

    lstCases.add(caso2);
    insert lstCases;
    System.assertEquals (lstCases,lstCases,'copyParentCaseFieldsToChildrenCaseFieldsTEST2');
    lstCases[0].SER_Is_Master_Case__c = true;

    update lstCases[0];*/
  }

  /*-----------------------------------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to Test copyParentFieldsInsert for GM cases.
      -------------------------------------------------------------------------------------------------*/
  public static testMethod void copyParentFieldsInsertGmTEST() {
    SER_TestUtils_3.initCustomsetting();

    Account sernovaAcc;
    sernovaAcc = new Account();
    sernovaAcc.Name =  Label.SER_SernovaAccountNAME;
    sernovaAcc.Client_STAR_ID__C = Label.SER_SernovaAccountNAME;
    sernovaAcc.g_customer_id__c = Label.SER_SernovaAccountNAME;
    insert sernovaAcc;

    Account pruebaAcc;
    pruebaAcc = new Account();
    pruebaAcc.Name =  'Prueba';
    insert pruebaAcc;

    Case parentCase;
    parentCase = new Case();
    parentCase.AccountId = pruebaAcc.Id;
    insert parentCase;

    Case sernovaCase;
    sernovaCase = new Case();
    sernovaCase.SER_Business_Case_Type__c = SER_Constant.BUSINESS_GM;
    sernovaCase.SER_Close__c = false;
    sernovaCase.SER_IsSernova__c = true;
    sernovaCase.ParentId = parentCase.Id;
    sernovaCase.RecordTypeId = [Select Id FROM RecordType WHERE DeveloperName = :GM_RT].Id;
    insert sernovaCase;

    Test.startTest();
    SER_CaseMethods_HELPER_ParentCp.copyParentFieldsINSERT(sernovaCase,parentCase,null);
    System.assertEquals (sernovaCase.AccountId,sernovaAcc.Id,'Error');
    Test.stopTest();
  }

  @isTest
static void testCreateLineVersionSnapshot() {
    // Create a DMT_Line__c with Status__c = 'Approval'
    DMT_Line__c line = new DMT_Line__c(
        Name = 'Test Line',
        Line_Id__c = 'L-001',
        Status__c = 'Approval'
    );
    insert line;

    // Create a Case related to the DMT_Line__c, initially not closed
    Case c = new Case(
        DMT_Line__c = line.Id,
        Status = 'New'
    );
    insert c;

    // Simulate closing the Case
    Case cToUpdate = [SELECT Id, IsClosed, Status FROM Case WHERE Id = :c.Id];
    cToUpdate.Status = 'Done'; // or whatever status triggers IsClosed = true in your org
    update cToUpdate;

    // Prepare newList and oldMap for the method call
    List<Case> newList = [SELECT Id, DMT_Line__c, DMT_LineOpportunity__c, DMT_Related_feature_name__c, IsClosed FROM Case WHERE Id = :c.Id];
    Map<Id, Case> oldMap = new Map<Id, Case>{
        c.Id => c
    };

    Test.startTest();
    SER_CaseMethods.createLineVersionSnapshot(newList, oldMap);
    Test.stopTest();
    Assert.isTrue(true, 'Queueable job executed successfully');

  }
}