/**********************************************************************************
 * @author       Global Desktop
 * @date         14/01/2020
 * @description  Test para el trigger de dwp_kitv__Visit_Topic__c
**********************************************************************************/
@isTest
public with sharing class Visit_Topic_Test {
  /**
  * TST
  */
  static final String TST = 'Test';
  /**
  * TEST1VAR
  */
  static final String TEST1VAR = 'test1';
  /**
  * TEST2VAR
  */
  public static final String TEST2VAR = 'test2';
  /**
  * TESTVISITTOPIC
  */
  public static final String TESTVISITTOPIC = 'Test visit topic';

  /**
  * Test setup
  */
  @TestSetup
  static void testSetup() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.g_customer_id__c = TEST1VAR;
    acc.Name = TEST1VAR;
    acc.DES_Tier__c = '00000021'; // CIB-Gold
    insert acc;

    final Account acc2 = tstClass.createClient();
    acc2.g_customer_id__c = TEST2VAR;
    acc2.Name = TEST2VAR;
    acc2.DES_Tier__c = '00000021'; // CIB-Gold
    insert acc2;

    final String profileUsr = tstClass.createProfile();
    final User usr = tstClass.createUser(profileUsr);
    usr.Email = 'testalertuser@test.com';
    insert usr;

    final User iUserStandard = tstClass.createUserWithProfileName('BBVA Desktop GCC Standard', 'testuser+gccstandarduser@test.com');
    insert iUserStandard;

    final List<DES_BBVA_Management_team__c> listBBVATeam = new List<DES_BBVA_Management_team__c>();
    final DES_BBVA_Management_team__c iBBVATeam = tstClass.createBBVAManagementTeamMember(usr, acc);
    listBBVATeam.add(iBBVATeam);
    final DES_BBVA_Management_team__c iBBVATeam2 = tstClass.createBBVAManagementTeamMember(usr, acc2);
    listBBVATeam.add(iBBVATeam2);
    final DES_BBVA_Management_team__c iBBVATeam3 = tstClass.createBBVAManagementTeamMember(iUserStandard, acc);
    listBBVATeam.add(iBBVATeam3);
    final DES_BBVA_Management_team__c iBBVATeam4 = tstClass.createBBVAManagementTeamMember(iUserStandard, acc2);
    listBBVATeam.add(iBBVATeam4);
    insert listBBVATeam;

    final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
    matrix.participant_child_id__c = acc.Id;
    matrix.participant_parent_id__c = acc2.Id;
    matrix.main_subsidiary_ind_type__c = true;
    insert matrix;

  }

  /**
  * @author Global Desktop
  * @description Test para el trigger de dwp_kitv__Visit_Topic__c
  */
  @isTest
  public static void test1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

	String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    insert userTest1;

    final Account iAccount = utilTestClass.createClient();
    insert iAccount;

    final dwp_kitv__Visit__c iVisit = new dwp_kitv__Visit__c();
    iVisit.dwp_kitv__visit_duration_number__c = '30';
    iVisit.dwp_kitv__visit_start_date__c = Date.today();
    insert iVisit;

    final Campaign iCampaign = new Campaign();
    iCampaign.Name = TST;
    iCampaign.StartDate = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iCampaign.EndDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month())+50);
    iCampaign.Status = 'Draft';
    iCampaign.description='d';
    iCampaign.cond__priority_campaign_type__c = 'Medium';
    iCampaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
    insert iCampaign;
	
	cond__Account_Campaign__c comAction2;
    comAction2 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(iCampaign,iAccount,false);
    insert comAction2;
	
    final cond__Account_Campaign__c iAccountCampaign = [SELECT Id FROM cond__Account_Campaign__c LIMIT 1];
    iAccountCampaign.cond__campaign_desc__c = TST;
    iAccountCampaign.cond__campaign_id__c = iCampaign.Id;
    iAccountCampaign.cond__participant_id__c = iAccount.Id;
    iAccountCampaign.cond__campaign_name__c = TST;
    iAccountCampaign.cond__data_source_name__c = TST;
    iAccountCampaign.cond__priority_campaign_type__c = 'Medium';
    iAccountCampaign.cond__solution_category_name__c = TST;
    iAccountCampaign.cond__solution_category_type__c = TST;
    iAccountCampaign.cond__Campaign_status_approval_type__c = 'Pending';
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

    Test.startTest();
      iAccountCampaign.cond__Campaign_status_approval_type__c = 'Pending';
      update iAccountCampaign;

      final List<dwp_kitv__Visit_Topic__c> listVisitTopicIns = new List<dwp_kitv__Visit_Topic__c>();
      final dwp_kitv__Visit_Topic__c iVisitTopic = new dwp_kitv__Visit_Topic__c();
      iVisitTopic.dwp_kitv__topic_desc__c = TST;
      iVisitTopic.dwp_kitv__visit_id__c = iVisit.Id;
      iVisitTopic.intt__participant_id__c = iAccountCampaign.Id;
      listVisitTopicIns.add(iVisitTopic);
      insert listVisitTopicIns;

      final cond__Account_Campaign__c iAccCampaignUpd = [SELECT Id,
                                                          Number_of_visits__c
                                                        FROM cond__Account_Campaign__c
                                                        WHERE Id = :iAccountCampaign.Id
                                                        LIMIT 1];
      System.assertEquals(1, iAccCampaignUpd.Number_of_visits__c, 'Number of visits is zero');
      delete iVisitTopic;

      List<dwp_kitv__Visit_Topic__c> listVisitGroup;
      listVisitGroup = new List<dwp_kitv__Visit_Topic__c>();
      Visit_Topic_Helper.getInstance();
      Visit_Topic_Helper.checkTeamInitiative(listVisitGroup);
    Test.stopTest();
  }

  /**
  * Test method 2
  */
  @isTest
  public static void test2() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
    iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1].Id;
    iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
    iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
    insert iCommercialAlert;

    Test.startTest();
      System.runAs(iUserStandard) {
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;

        final dwp_kitv__Visit__c iVisit = iUtilClass.createVisit(iAccount, iOpportunity);
        iVisit.commercial_alert_id__c = iCommercialAlert.Id;
        insert iVisit;

        final pith__Pitch__c iPitch = new pith__Pitch__c();
        iPitch.pith__solution_name_path_desc__c = 'Cash Management';
        iPitch.pith__solution_category_name__c = 'GTB';
        insert iPitch;

        final dwp_kitv__Visit_Topic__c iVisitTopic = new dwp_kitv__Visit_Topic__c();
        iVisitTopic.dwp_kitv__visit_id__c = iVisit.Id;
        iVisitTopic.pith__pitch_visit_topic_id__c = iPitch.Id;
        iVisitTopic.dwp_kitv__topic_desc__c = TESTVISITTOPIC;
        insert iVisitTopic;

        final pith__Pitch__c iPitchAlert = [SELECT Id, commercial_alert_id__c FROM pith__Pitch__c LIMIT 1];
        System.assertNotEquals(iPitchAlert.commercial_alert_id__c, null);
      }
    Test.stopTest();
  }

  /**
  * Test method 3
  */
  @isTest
  public static void test3() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
    iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1].Id;
    iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
    iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
    insert iCommercialAlert;

    Test.startTest();
      System.runAs(iUserStandard) {
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;

        final dwp_kitv__Visit__c iVisit = iUtilClass.createVisit(iAccount, iOpportunity);
        insert iVisit;

        final pith__Pitch__c iPitch = new pith__Pitch__c();
        iPitch.pith__solution_name_path_desc__c = 'Cash Management';
        iPitch.pith__solution_category_name__c = 'GTB';
        iPitch.commercial_alert_id__c = iCommercialAlert.Id;
        insert iPitch;

        final dwp_kitv__Visit_Topic__c iVisitTopic = new dwp_kitv__Visit_Topic__c();
        iVisitTopic.dwp_kitv__visit_id__c = iVisit.Id;
        iVisitTopic.pith__pitch_visit_topic_id__c = iPitch.Id;
        iVisitTopic.dwp_kitv__topic_desc__c = TESTVISITTOPIC;
        insert iVisitTopic;

        final dwp_kitv__Visit__c iVisitAlert = [SELECT Id, commercial_alert_id__c FROM dwp_kitv__Visit__c LIMIT 1];
        System.assertNotEquals(iVisitAlert.commercial_alert_id__c, null);
      }
    Test.stopTest();
  }

  /**
  * Test method 4
  */
  @isTest
  public static void test4() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
    iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1].Id;
    iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
    iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
    insert iCommercialAlert;

    //Test.startTest();
      System.runAs(iUserStandard) {
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;
          
		Test.startTest();

        final dwp_kitv__Visit__c iVisit = iUtilClass.createVisit(iAccount, iOpportunity);
        iVisit.commercial_alert_id__c = iCommercialAlert.Id;
        insert iVisit;

        final dwp_kitv__Visit_Topic__c iVisitTopic = new dwp_kitv__Visit_Topic__c();
        iVisitTopic.dwp_kitv__opportunity_id__c = iOpportunity.Id;
        iVisitTopic.dwp_kitv__visit_id__c = iVisit.Id;
        iVisitTopic.dwp_kitv__topic_desc__c = TESTVISITTOPIC;
        insert iVisitTopic;

        final Opportunity iOpportunityAlert = [SELECT Id, commercial_alert_id__c FROM Opportunity LIMIT 1];
        System.assertNotEquals(iOpportunityAlert.commercial_alert_id__c, null);
      }
    Test.stopTest();
  }

  /**
  * Test method 5
  */
  @isTest
  public static void test5() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
    iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1].Id;
    iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
    iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
    insert iCommercialAlert;

    Test.startTest();
      System.runAs(iUserStandard) {
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        iOpportunity.commercial_alert_id__c = iCommercialAlert.Id;
        insert iOpportunity;

        final dwp_kitv__Visit__c iVisit = iUtilClass.createVisit(iAccount, iOpportunity);
        insert iVisit;

        final dwp_kitv__Visit_Topic__c iVisitTopic = new dwp_kitv__Visit_Topic__c();
        iVisitTopic.dwp_kitv__opportunity_id__c = iOpportunity.Id;
        iVisitTopic.dwp_kitv__visit_id__c = iVisit.Id;
        iVisitTopic.dwp_kitv__topic_desc__c = TESTVISITTOPIC;
        insert iVisitTopic;

        final dwp_kitv__Visit__c iVisitAlert = [SELECT Id, commercial_alert_id__c FROM dwp_kitv__Visit__c LIMIT 1];
        System.assertNotEquals(iVisitAlert.commercial_alert_id__c, null);
      }
    Test.stopTest();
  }
}