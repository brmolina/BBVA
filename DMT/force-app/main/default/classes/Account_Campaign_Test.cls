/**********************************************************************************
 * @author       Global Desktop
 * @date         16/01/2020
 * @description  Test para el trigger de cond__Account_Campaign__c
 **********************************************************************************/
@isTest
public with sharing class Account_Campaign_Test {

	/*Variable global*/
	final private static String STRINGTEST = 'Test';

  /**
   * @author Global Desktop
   * @description Test para el trigger de cond__Account_Campaign__c
   */
  @isTest
  public static void test1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    final Account iAccount = utilTestClass.createClient();
    iAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Label.DES_RT_Subsidiary).getRecordTypeId();
    insert iAccount;

    final Campaign iCampaign = new Campaign();
    iCampaign.Name = STRINGTEST;
    iCampaign.description = STRINGTEST;
    iCampaign.StartDate = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iCampaign.EndDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()))+50;
    iCampaign.cond__priority_campaign_type__c = 'Medium';
    iCampaign.Status = 'Draft';
    iCampaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
    insert iCampaign;

    final List<cond__Account_Campaign__c> prevAccCampaign = [SELECT Id FROM cond__Account_Campaign__c LIMIT 100];
    delete prevAccCampaign;

    Test.startTest();
      final cond__Account_Campaign__c iAccountCampaign = new cond__Account_Campaign__c();
      iAccountCampaign.cond__campaign_desc__c = STRINGTEST;
      iAccountCampaign.cond__campaign_id__c = iCampaign.Id;
      //iAccountCampaign.Client_ID_Filtered__c = iAccount.Id;
      iAccountCampaign.cond__participant_id__c = iAccount.Id;
      iAccountCampaign.cond__campaign_name__c = STRINGTEST;
      iAccountCampaign.name = STRINGTEST;
      iAccountCampaign.cond__data_source_name__c = STRINGTEST;
      iAccountCampaign.cond__priority_campaign_type__c = 'Medium';
      iAccountCampaign.cond__solution_category_name__c = STRINGTEST;
      iAccountCampaign.cond__solution_category_type__c = STRINGTEST;
      iAccountCampaign.cond__Campaign_status_approval_type__c = 'Pending';
      iAccountCampaign.RecordTypeId = Schema.SObjectType.cond__Account_Campaign__c.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
      insert iAccountCampaign;
      prevAccCampaign.add(iAccountCampaign);
      Account_Campaign_Helper.getInstance();
      Account_Campaign_Helper.checkDiscartedStatus(prevAccCampaign);
    System.assertNotEquals(iAccountCampaign, null);
	  delete iAccountCampaign;
    Test.stopTest();
  }
}