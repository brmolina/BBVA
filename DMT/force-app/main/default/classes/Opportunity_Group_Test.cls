/**********************************************************************************
 * @author       Global Desktop
 * @date         14/01/2020
 * @description  Test para el trigger de intt__Opportunity_Group__c
**********************************************************************************/
@isTest
public with sharing class Opportunity_Group_Test {
  /**
   * @author Global Desktop
   * @description Test para el trigger de intt__Opportunity_Group__c
   */
  @isTest
  public static void test1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    insert userTest1;

    final Account iAccount = utilTestClass.createClient();
    insert iAccount;
    final Account iAccount2 = utilTestClass.createClient();
    insert iAccount2;

    final Opportunity iOpportunity = utilTestClass.createOpportunity(iAccount);
    insert iOpportunity;

    final Campaign iCampaign = new Campaign();
    iCampaign.Name = 'Test Name';
    iCampaign.StartDate = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iCampaign.EndDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month())+50);
    iCampaign.Status = 'Draft';
    iCampaign.cond__priority_campaign_type__c = 'Medium';
    iCampaign.Description = 'Description';
    iCampaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
    insert iCampaign;
    
    List<cond__Account_Campaign__c> aCamList = new List<cond__Account_Campaign__c>();
    cond__Account_Campaign__c comAction2;
    comAction2 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(iCampaign,iAccount,false);
    //insert comAction2;
    aCamList.add(comAction2);
    cond__Account_Campaign__c comAction3;
    comAction3 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(iCampaign,iAccount2,false);
    aCamList.add(comAction3);
    insert aCamList;
      
    final cond__Account_Campaign__c iAccountCampaign = [SELECT Id FROM cond__Account_Campaign__c LIMIT 1];
    iAccountCampaign.cond__campaign_desc__c = 'Test desc';
    iAccountCampaign.cond__campaign_id__c = iCampaign.Id;
    iAccountCampaign.cond__participant_id__c = iAccount.Id;
    iAccountCampaign.cond__campaign_name__c = 'Test campaign';
    iAccountCampaign.cond__data_source_name__c = 'Test data source';
    iAccountCampaign.cond__priority_campaign_type__c = 'Medium';
    iAccountCampaign.cond__solution_category_name__c = 'Test solution name';
    iAccountCampaign.cond__solution_category_type__c = 'Test solution type';
    iAccountCampaign.cond__Campaign_status_approval_type__c = 'Draft';
    iAccountCampaign.RecordTypeId = Schema.SObjectType.cond__Account_Campaign__c.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
    update iAccountCampaign;
    
    iAccountCampaign.cond__Campaign_status_approval_type__c = 'Draft';
    update iAccountCampaign;
    
    final intt__Team_initiative__c iTeamInitiative = new intt__Team_initiative__c();
    iTeamInitiative.intt__gf_group_campaign_id__c = iAccountCampaign.Id;
    iTeamInitiative.intt__campaign_id__c = iCampaign.Id;
    iTeamInitiative.intt__manager_team_id__c = userTest1.Id;
    insert iTeamInitiative;
      
    iAccountCampaign.cond__Campaign_status_approval_type__c = 'In Progress';
    update iAccountCampaign;
    
    Test.startTest();
      final intt__Opportunity_Group__c iOppGroup = new intt__Opportunity_Group__c();
      iOppGroup.intt__opportunity_id__c = iOpportunity.Id;
      iOppGroup.intt__participant_id__c = iAccountCampaign.Id;
      insert iOppGroup;
      final List<intt__Opportunity_Group__c> listOppGroup=new List<intt__Opportunity_Group__c>();
      listOppGroup.add(iOppGroup);
      final cond__Account_Campaign__c iAccCampaignUpd = [SELECT Id,
                                                         Number_of_opportunities__c
                                                         FROM cond__Account_Campaign__c
                                                         LIMIT 1];
      
      System.assertEquals(1, iAccCampaignUpd.Number_of_opportunities__c, 'Number of opp is zero');
      iAccountCampaign.cond__Campaign_status_approval_type__c = 'Pending';
      update iAccountCampaign;
      delete iOppGroup;
      Opportunity_Group_Helper.getInstance(); 
      Opportunity_Group_TriggerHandler.getInstance();
      Opportunity_Group_Helper.checkTeamInitiative(listOppGroup);
    Test.stopTest();
  }
}