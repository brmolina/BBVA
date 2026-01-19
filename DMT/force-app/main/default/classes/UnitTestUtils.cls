/*
 * Author         JSS
 * Date           2016/08/01
 * Description    Clase Util para los tests
 * Revision
 *               2019/02/27 Para solucionar errores en los test se cambia el username en la creación de los usuarios
 *               2019/09/18 [JJS] parche para solucionar problema del campo DES_Scope_c en la creación de contacto
 */
@isTest
public class UnitTestUtils {
  public static User GetSysAdminUser() {
    string Aliasstring = 'Alias';
    Id SysAdminId = [Select Id from Profile Where Name = 'System Administrator' Limit 1].Id;
    User SampleUser = new User(

      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTestAdmin',
      ProfileId = SysAdminId,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      Asset_Class__c = 'FI;FX;EQ',
      ID_User__c = String.valueOf(Datetime.now()),
      isActive = True

      );

    return SampleUser;
  }

  public static User getFIUser() {
    string Aliasstring = 'Alias';
    Id AnalystFIId = [Select Id from Profile Where Name = 'Analyst FI' Limit 1].Id;
    User SampleUser = new User(
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTest2',
      ProfileId = AnalystFIId,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      ID_User__c = String.valueOf(Datetime.now()),
      Asset_Class__c = 'FI'
      );
    return SampleUser;
  }
  public static string createUserName() {

    return 'test_' + string.valueOf(system.now().hour()) + string.valueOf(system.now().minute()) + string.valueOf(system.now().second()) + string.valueOf(system.now().millisecond());
  }

  public static User GetEQUser() {
    User SampleUser;
    string Aliasstring = 'Alias';
    Id Profile = [select id from profile where name='Analyst EQ' limit 1].id;
    //Id UsrRole = [Select id from UserRole where name='BBVA S.A. EQ Sales' limit 1].id;
    //Id CallCentr = [Select id from CallCenter where internalName = 'DemoAdapterOpenCTI' limit 1].id;
    //UserLicense UsrLicense = [Select id from UserLicense where Name = 'Salesforce' limit 1];
    SampleUser = new User(
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTest',
      ProfileId = Profile,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      ID_User__c = String.valueOf(Datetime.now()),
      Asset_Class__c = 'EQ'
      );

    return SampleUser;

  }

  public static User GetFISalesUser() {
    User SampleUser;
    string Aliasstring = 'Alias';
    Id Profile = [select id from profile where name='Consultation IT' limit 1].id;
    //Id UsrRole = [Select id from UserRole where name='BBVA S.A. FI Sales' limit 1].id;
    //Id CallCentr = [Select id from CallCenter where internalName = 'DemoAdapterOpenCTI' limit 1].id;
    //UserLicense UsrLicense = [Select id from UserLicense where Name = 'Salesforce' limit 1];
    SampleUser = new User(
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTest',
      ProfileId = Profile,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      ID_User__c = String.valueOf(Datetime.now()),
      //userroleid = UsrRole,
      Asset_Class__c = 'FI',
      isActive = True
      );

    return SampleUser;

  }

  public static User GetEQSalesUser() {
    User SampleUser;
    string Aliasstring = 'Alias';
    Id Profile = [select id from profile where name='Sales Cash Equities' limit 1].id;
    Id UsrRole = [Select id from UserRole where name='BBVA S.A. EQ Sales' limit 1].id;
    //Id CallCentr = [Select id from CallCenter where internalName = 'DemoAdapterOpenCTI' limit 1].id;
    //UserLicense UsrLicense = [Select id from UserLicense where Name = 'Salesforce' limit 1];
    SampleUser = new User(
      //ID_User__c = 'ExternalEQ',
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTest',
      ProfileId = Profile,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      userroleid = UsrRole,
      ID_User__c = String.valueOf(Datetime.now()),
      Asset_Class__c = 'EQ',
      isActive = True
      );

    return SampleUser;

  }

  public static User GetDataloaderNewUser(String ExternalID, String AssetClass) {
    User SampleUser;
    string Aliasstring = 'Alias';
    //Id Profile = [select id from profile where name='Sales Cash Equities' limit 1].id;
    //Id UsrRole = [Select id from UserRole where name='BBVA S.A. EQ Sales' limit 1].id;
    //Id CallCentr = [Select id from CallCenter where internalName = 'DemoAdapterOpenCTI' limit 1].id;
    //UserLicense UsrLicense = [Select id from UserLicense where Name = 'Salesforce' limit 1];

    SampleUser = new User(
      //ProfileId = Profile,
      //userroleid = UsrRole,
      Dataloader_Role_Name__c = 'BBVA S.A. ' + AssetClass + ' Sales',
      Dataloader_Profile_Name__c = 'Sales ' + AssetClass,
      ID_User__c = ExternalID,
      FederationIdentifier = ExternalID,
      Firstname='NameTest',
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickName02',
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      Asset_Class__c = AssetClass,
      isActive = true
      );

    return SampleUser;

  }

  public static AccountShare GetAccountShareUser(id AccId, id UserId) {
    AccountShare SampleAccShare = new AccountShare(
      AccountId = AccId,
      UserOrGroupId = UserId,
      AccountAccessLevel = 'Edit',
      ContactAccessLevel = 'Edit',
      CaseAccessLevel = 'Edit',
      OpportunityAccessLevel = 'Edit'
      );
    return SampleAccShare;
  }

  public static User GetFXSalesUser() {
    User SampleUser;
    string Aliasstring = 'Alias';
    Id Profile = [select id from profile where name='Consultation IT' limit 1].id;
    //Id CallCentr = [Select id from CallCenter where internalName = 'DemoAdapterOpenCTI' limit 1].id;
    SampleUser = new User(
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTest',
      ProfileId = Profile,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      Asset_Class__c = 'FX',
      ID_User__c = String.valueOf(Datetime.now()),
      isActive = True
      );

    return SampleUser;

  }

  public static User GetFI_FXeSalesUser() {
    User SampleUser;
    string Aliasstring = 'Alias';
    Id Profile = [select id from profile where name='eSales' limit 1].id;
    //Id CallCentr = [Select id from CallCenter where internalName = 'DemoAdapterOpenCTI' limit 1].id;
    SampleUser = new User(
      Lastname='LastNameTest',
      Alias = Aliasstring,
      Email = Aliasstring + '@bbva.com',
      username = createUserName() + '@bbva.com',
      CommunityNickname = 'ComunityNickNameTest',
      ProfileId = Profile,
      EmailEncodingKey = 'UTF-8',
      Timezonesidkey='Europe/London',
      Localesidkey='en_US',
      languagelocalekey='en_US',
      ID_User__c = String.valueOf(Datetime.now()),
      Asset_Class__c = 'FI;FX',
      isActive = True
      );

    return SampleUser;

  }

  public static Account GetStandardAccount() {
    Integer RandomNumber = Math.round(Math.random()*1000);
    ID StardRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Account').getRecordTypeId();
    Account SampleAccount = new Account(
      Name = 'NameTest',
      Type = 'Corporate',
      Sector__c = 'Asset Management',
      //Master_Agreements__c = 'CMOF09',
      BBVA_Entity__c = 'BBVA SA',
      Asset_Class__c = 'FI;FX;Cash Equity',
      Last_Trade_Date_Cash_Equity__c = date.today(),
      Last_Trade_Date_FI__c = date.today(),
      Last_Trade_Date_FX__c = date.today(),
      MTD_Total_Franchise__c = 12345,
      DES_Country_Client__c = 'ES',
      recordTypeId = StardRecordType,
      Client_STAR_ID__c = String.valueOf(Datetime.now().getTime()) + RandomNumber
      );
    return SampleAccount;
  }

  public static Contact GetContact(Id AccId) {
    Contact SampleContact = New Contact(
      Lastname = 'LastNameTest',
      AccountId = Accid,       //Acc.id
      Email_ExternalID__c = String.valueof(DateTime.now().getTime()) + '@test.comm',
      Asset_Class__c = 'FI',
	  DES_Scope__c = 'ES'
      );
    return SampleContact;
  }
  public static Opportunity GetOpportunity(Account Acc) {
    Opportunity SampleOpportunity = New Opportunity(
      Name = 'OppNameTest',
      AccountId = Acc.Id,
      CloseDate = system.today(),
      StageName = 'Needs Analysis',
      Asset_Class__c = 'FI'

      );
    return SampleOpportunity;
  }

  public static Lead GetLead() {
    Lead SampleLead = new Lead(
      Status = 'Contacted',
      LastName = 'LastNameTest',
      Company = 'CompanyTest',
      Email = 'EmailTest@Test.com',
      Asset_Class__c = 'FI'
      );
    return SampleLead;
  }

  public static Campaign GetCampaign() {
    Campaign SampleCampaign = new Campaign(
      Name = 'CampaignNameTest',
      StartDate = Date.newInstance(1960, 2, 17),
      EndDate = date.today(),
      Description = 'desc',
      IsActive = True
      );
    return SampleCampaign;
  }

  public static Task GetTask(Id UserId, Id WatId, Id ContactId) {
    system.debug('+++UserID: ' + UserId);
    system.debug('+++WhatId: ' + WatId);
    system.debug('+++ContactId: ' + ContactId);
    Task SampleTask = New Task(
      WhatId = WatId,
      OwnerId = UserId,
      WhoId = ContactId,
      Status = 'Not Started',
      Priority = 'Normal',
      Subject = 'Call',
      ActivityDate =  system.today()

      );
    return SampleTask;
  }

  public static Event GetEvent(Id UserId, Id WatId, Id ContactId ) {
    Event SampleEvent = New Event(
      WhatId = WatId,
      OwnerId = UserId,
      WhoId = ContactId,
      StartDateTime = system.today(),
      EndDateTime = system.today() + 1

      );
    return SampleEvent;
  }

  public static CampaignMember GetAssignedCMContact(Id CampId, Id ContId) {
    CampaignMember SampleCampaignMember = New CampaignMember(
      CampaignId = CampId,
      ContactId = ContId
      );
    return SampleCampaignMember;
  }

  public static CampaignMember GetAssignedCMLead(Id CampId, Id LId) {
    CampaignMember SampleCampaignMember = New CampaignMember(
      CampaignId = CampId,
      LeadId = LId
      );
    return SampleCampaignMember;
  }

}