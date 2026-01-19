/**********************************************************************************
* @author       Global Desktop
* @date         18/02/2020
* @description  Test para el objeto pith__Related_opportunity_pitch__c
**********************************************************************************/
@isTest
public class Related_Opp_Pitch_Test {
  /*
  * TEST2VAR
  */
  public static final String TEST2VAR = 'test2';

  /**
  * Test setup
  */
  @TestSetup
  static void testSetup() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = 'test1';
    acc.Name = 'test1';
    acc.DES_Tier__c = '00000020'; // CIB-Platinum
    insert acc;

    final Account acc2 = tstClass.createClient();
    acc2.SER_CClient__c = TEST2VAR;
    acc2.Name = TEST2VAR;
    acc2.DES_Tier__c = '00000020'; // CIB-Platinum;
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
   * Test method 1
   */
  @isTest
  public static void test1() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1].Id;
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
      insert iCommercialAlert;

      System.runAs(iUserStandard) {
        System.debug('::::::::::UserInfo.getProfileId(): ' + UserInfo.getProfileId());
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        iOpportunity.commercial_alert_id__c = iCommercialAlert.Id;
        insert iOpportunity;

        final pith__Pitch__c iPitch = new pith__Pitch__c();
        iPitch.pith__solution_name_path_desc__c = 'Cash Management';
        iPitch.pith__solution_category_name__c = 'GTB';
        insert iPitch;

        final pith__Related_opportunity_pitch__c iRelatedOppPitch = new pith__Related_opportunity_pitch__c();
        iRelatedOppPitch.pith__opportunity_pitch_id__c = iOpportunity.Id;
        iRelatedOppPitch.pith__pitch_opportunity_id__c = iPitch.Id;
        insert iRelatedOppPitch;

        final pith__Pitch__c iPitchAlert = [SELECT Id, commercial_alert_id__c FROM pith__Pitch__c LIMIT 1];
        System.assertNotEquals(iPitchAlert.commercial_alert_id__c, null);
      }
    Test.stopTest();
  }

  /**
   * Test method 2
   */
  @isTest
  public static void test2() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1];
    final User iUserStandard = [SELECT Id, profile.Name FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    System.debug(':::::::::: iUserStandard.Profile.Name: ' + iUserStandard.Profile.Name);

    Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1].Id;
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
      insert iCommercialAlert;

      System.runAs(iUserStandard) {
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;

        final pith__Pitch__c iPitch = new pith__Pitch__c();
        iPitch.commercial_alert_id__c = iCommercialAlert.Id;
        iPitch.pith__solution_name_path_desc__c = 'Cash Management';
        iPitch.pith__solution_category_name__c = 'GTB';
        insert iPitch;

        final pith__Related_opportunity_pitch__c iRelatedOppPitch = new pith__Related_opportunity_pitch__c();
        iRelatedOppPitch.pith__opportunity_pitch_id__c = iOpportunity.Id;
        iRelatedOppPitch.pith__pitch_opportunity_id__c = iPitch.Id;
        insert iRelatedOppPitch;

        final Opportunity iOpportunityAlert = [SELECT Id, commercial_alert_id__c FROM Opportunity LIMIT 1];
        System.assertNotEquals(iOpportunityAlert.commercial_alert_id__c, null);
      }
    Test.stopTest();
  }
}