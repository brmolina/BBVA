/**********************************************************************************
 * @author       Global Desktop
 * @date         14/01/2020
 * @description  Test para el trigger de intt__Pitch_Group__c
**********************************************************************************/
@isTest
public with sharing class Pitch_Group_Test {

  /*
   * Variable string
   */
  static final String TST = 'Test';

  /**
   * @author Global Desktop
   * @description Test para el trigger de intt__Pitch_Group__c
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

    final pith__Pitch__c iPitch = new pith__Pitch__c();
    iPitch.pith__solution_category_name__c = 'GTB';
    iPitch.pith__solution_name_path_desc__c = 'Client Resources';
    insert iPitch;

    final Campaign iCampaign = new Campaign();
    iCampaign.Name = TST;
    iCampaign.StartDate = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iCampaign.EndDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month())+50);
    iCampaign.Status = 'Draft';
    iCampaign.Description = 'description';
    iCampaign.cond__priority_campaign_type__c = 'Medium';
    iCampaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
    insert iCampaign;
    
    List<cond__Account_Campaign__c> aCamList = new List<cond__Account_Campaign__c>();
    cond__Account_Campaign__c comAction2;
    comAction2 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(iCampaign,iAccount,false);
    aCamList.add(comAction2);
    cond__Account_Campaign__c comAction3;
    comAction3 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(iCampaign,iAccount2,false);
    aCamList.add(comAction3);
    insert aCamList;

    final cond__Account_Campaign__c iAccountCampaign = [SELECT Id FROM cond__Account_Campaign__c LIMIT 1];
    iAccountCampaign.cond__campaign_desc__c = TST;
    iAccountCampaign.cond__campaign_id__c = iCampaign.Id;
    iAccountCampaign.cond__participant_id__c = iAccount.Id;
    iAccountCampaign.cond__campaign_name__c = TST;
    iAccountCampaign.cond__data_source_name__c = TST;
    iAccountCampaign.cond__priority_campaign_type__c = 'Medium';
    iAccountCampaign.cond__solution_category_name__c = TST;
    iAccountCampaign.cond__solution_category_type__c = TST;
    iAccountCampaign.cond__Campaign_status_approval_type__c = 'Draft';
    iAccountCampaign.RecordTypeId = Schema.SObjectType.cond__Account_Campaign__c.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
    update iAccountCampaign;

    iAccountCampaign.cond__Campaign_status_approval_type__c = 'Draft';
    update iAccountCampaign;

    intt__Team_initiative__c iTeamInitiative;
    iTeamInitiative = new intt__Team_initiative__c();
    iTeamInitiative.intt__gf_group_campaign_id__c = iAccountCampaign.Id;
    iTeamInitiative.intt__campaign_id__c = iCampaign.Id;
    iTeamInitiative.intt__manager_team_id__c = userTest1.Id;
    insert iTeamInitiative;

    iAccountCampaign.cond__Campaign_status_approval_type__c = 'Pending';
    update iAccountCampaign;

    Test.startTest();
      final intt__Pitch_Group__c iPitchGroup = new intt__Pitch_Group__c();
      iPitchGroup.intt__gf_pitch_id__c = iPitch.Id;
      iPitchGroup.intt__participant_id__c = iAccountCampaign.Id;
      insert iPitchGroup;

      List<intt__Pitch_Group__c> listPitchGroup;
      listPitchGroup = new List<intt__Pitch_Group__c>();
      listPitchGroup.add(iPitchGroup);

      final cond__Account_Campaign__c iAccCampaignUpd = [SELECT Id, Number_of_pitches__c FROM cond__Account_Campaign__c LIMIT 1];
      System.assertEquals(1, iAccCampaignUpd.Number_of_pitches__c, 'Number of pitches is zero');
      delete iPitchGroup;
    Test.stopTest();

    Pitch_Group_Helper.getInstance();
    Pitch_Group_Helper.checkTeamInitiative(listPitchGroup);
    Pitch_Group_TriggerHandler.getInstance();
  }
}