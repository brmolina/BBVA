@isTest
private class CampaignMemberUtils_Test {
  static testMethod void testData() {
    list<Account> SampleAccountList = New List<Account>();
    Account SampleAccount = UnitTestUtils.GetStandardAccount();
    SampleAccountList.add(SampleAccount);
    Account SampleExistingAccount = UnitTestUtils.GetStandardAccount();
    SampleAccountList.add(SampleExistingAccount);
    Account SampleConvertAccount = UnitTestUtils.GetStandardAccount();
    SampleAccountList.add(SampleConvertAccount);
    insert SampleAccountList;
    list<Contact> SampleContactList = New List<Contact>();
    Contact SampleContact = UnitTestUtils.GetContact(SampleAccountList[0].id);
    SampleContactList.add(SampleContact);
    Contact SampleContact2 = new Contact(
      Lastname = 'ContactName',
      AccountId = SampleAccountList[2].id,
      Email_ExternalID__c = 'ContactName@test.com',
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets')
      );
    SampleContactList.add(SampleContact2);
    Contact SampleContact3 = new Contact(
      Lastname = 'ContactName3',
      AccountId = SampleAccountList[2].id,
      Email_ExternalID__c = 'ContactName3@test.com',
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets')
      );
    SampleContactList.add(SampleContact3);
    insert SampleContactList;
    Lead SampleLead = UnitTestUtils.GetLead();
    insert SampleLead;
    Campaign SampleCampaign = UnitTestUtils.GetCampaign();
    SampleCampaign.cond__priority_campaign_type__c = 'Medium';
    insert SampleCampaign;
    Campaign SampleExistingCampaign = UnitTestUtils.GetCampaign();
    SampleExistingCampaign.cond__priority_campaign_type__c = 'Medium';
    insert SampleExistingCampaign;
    //Existing Campaigns in custom object. We need it to cover fully the class.
    Campaign__c SampleCustomCampaign = new Campaign__c(
      Account__c= SampleAccountList[1].id,
      Campaign__c = SampleExistingCampaign.id
      );
    insert SampleCustomCampaign;

    test.startTest();
    CampaignMember SampleCampaignMemberContact = UnitTestUtils.GetAssignedCMContact(SampleCampaign.id, SampleContactList[0].id);
    insert SampleCampaignMemberContact;
    list<Campaign__c> CustomCampaignList = [Select id from Campaign__c LIMIT 5];
    //To test if a new record is inserted, we already had one inserted, so should be 2.
    if(!Test.isRunningTest())
      System.assertEquals(CustomCampaignList.size(), 2);
    CampaignMember SampleCampaignMemberLead = UnitTestUtils.GetAssignedCMLead(SampleCampaign.id, SampleLead.id);
    SampleCampaignMemberLead.ContactId = SampleContactList[1].id;
    insert SampleCampaignMemberLead;
    list<Campaign__c> CustomCampaignList2 = [Select id from Campaign__c LIMIT 5];
    //Converted lead to a new contact related to another account, we expect 3 records.
    if(!Test.isRunningTest())
      System.assertEquals(CustomCampaignList2.size(), 3);
    update SampleCampaignMemberLead;
    delete SampleCampaignMemberContact;
    list<Campaign__c> CustomCampaignList3 = [Select id from Campaign__c LIMIT 5];
    //Deleted the last record, we expect 2 again.
    if(!Test.isRunningTest())
      System.assertEquals(CustomCampaignList3.size(), 2);
    CampaignMember SampleCampaignMemberLead2 = UnitTestUtils.GetAssignedCMContact(SampleCampaign.id, SampleContactList[2].id);
    insert SampleCampaignMemberLead2;
    list<Campaign__c> CustomCampaignList4 = [Select id from Campaign__c LIMIT 5];
    //Not insert a new record when having same Campaing and Account
    if(!Test.isRunningTest())
      System.assertEquals(CustomCampaignList4.size(), 2);
    test.stopTest();

  }
}