/************************************************************************
 * @name:                GBL_TeamInitiativeTest
 * @author               bbva.com developers
 * @date:                2019
 * @version:             1.0
 * @group:               Global  Desktop
 * @description:         Test class logic Team
 ***************************************************************************/
@isTest
public class GBL_TeamInitiativeTest {
  @testSetup
  static void setup() {
    GBL_TestDataFactory_Initiative.newDb('ESPAÑA');
    GBL_TestDataFactory_Initiative.newAccount(1,2);
    GBL_TestDataFactory_Initiative.newCondCamp(1,1);
    GBL_TestDataFactory_Initiative.newCondCamp(1,2);
  }

  private static User createUser() {
    final User objUser = GBL_TestDataFactory_Initiative.getUser(true);
    objUser.gf_user_work_product_desc__c = 'codeR';
    objUser.gf_user_work_country_desc__c = 'ES';
    update objUser;
    return objUser;
  }

  private static Account createAcc() {
    final Account acc3 = new Account();
    acc3.Name = 'Acc3';
    acc3.DES_Tier__c = '00000020'; //CIB-Platinum
    acc3.DES_Segment__c = '00005'; // Corporate
    insert acc3;

    return acc3;
  }

  private static List<AccountTeamMember> createAccMem(Account acc3, User objUser) {
    List<AccountTeamMember> listAccTeam;
    listAccTeam = new List<AccountTeamMember>();

    AccountTeamMember iAccTeamMember;
    iAccTeamMember = new AccountTeamMember();
    iAccTeamMember.AccountId = acc3.id;
    iAccTeamMember.UserId = objUser.id;
    iAccTeamMember.TeamMemberRole = 'Transactional Banker';
    listAccTeam.add(iAccTeamMember);

    final AccountTeamMember iAccTeamMember2 = new AccountTeamMember();
    iAccTeamMember2.AccountId = acc3.id;
    iAccTeamMember2.UserId = objUser.id;
    iAccTeamMember2.TeamMemberRole = 'Global Banker';
    listAccTeam.add(iAccTeamMember2);

    insert listAccTeam;
    return listAccTeam;
  }

  private static DES_Booking__c createBooking (Account acc3) {
    final DES_Booking__c iBooking = new DES_Booking__c();
    iBooking.DES_Client__c = acc3.Id;
    iBooking.DES_Country__c = 'ESPAÑA';
    insert iBooking;
    return iBooking;
  }

  private static Campaign createCamp () {
    final Campaign camp3 = new Campaign();
    camp3.Status = system.Label.Draft_Status;
    camp3.cond__priority_campaign_type__c = 'Medium';
    camp3.description = 'des';
    camp3.Name = 'camp2';
    camp3.tier_desc__c = '00000020';
    camp3.segment_desc__c = '00005';
    camp3.country_name__c = 'ESPAÑA';
    final Id recType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Initiative').getRecordTypeId();
    camp3.RecordTypeId = recType;
    camp3.StartDate = system.today();
    camp3.EndDate = system.today().addDays(7);
    camp3.soluction_category_id__c = 'GM';
    camp3.solution_name_path_desc__c = 'codeR';
    camp3.gf_user_country_name__c = 'ES';
    insert camp3;
    return camp3;
  }

  private static DES_BBVA_Management_team__c createObjMember (List<cond__Account_Campaign__c> listAccCampaign, User objUser) {
    DES_BBVA_Management_team__c objMember;
    objMember = new DES_BBVA_Management_team__c();
    objMember.DES_Client__c = listAccCampaign[0].cond__participant_id__c;
    objMember.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
    objMember.DES_User__c = objUser.id;
    insert objMember;
    return objMember;
  }

  @isTest
  static void testDefaultClientFilter() {
    final User objUser = createUser();
    final Account acc3 = createAcc();
    final List<AccountTeamMember> iAccTeamMember = createAccMem(acc3, objUser);
    System.debug(iAccTeamMember);
    final DES_Booking__c iBooking = createBooking(acc3);
    System.debug(iBooking);
    final Campaign camp3 = createCamp();

    System.assertNotEquals(camp3, null, 'ERROR');

    Test.startTest();
      final List<cond__Account_Campaign__c> listAccCampaign = [SELECT Id,
                                                                cond__campaign_id__c,
                                                                cond__participant_id__c
                                                              FROM cond__Account_Campaign__c
                                                              LIMIT 50];

      final DES_BBVA_Management_team__c objMember = createObjMember(listAccCampaign, objUser);
      System.debug(objMember);

      Map<Id, cond__Account_Campaign__c> mapFilialId;
      mapFilialId = new Map<Id, cond__Account_Campaign__c>();
      mapFilialId.put(listAccCampaign[0].cond__participant_id__c,listAccCampaign[0]);
      GBL_TeamInitiative objGTeam;
      objGTeam = new GBL_TeamInitiative();
      objGTeam.clientInitiativeTeamFilterAux(mapFilialId);

      final GBL_TeamInitiative iController = new GBL_TeamInitiative();
      iController.ClientInitiativeTeamFilter(listAccCampaign);
      iController.InitiativeTeamFilter(camp3);

      intt__Team_initiative__c team;
      team = GBL_TestDataFactory_Initiative.getTeamInitiative(camp3, objUser, true);
      team.intt__gf_group_campaign_id__c=listAccCampaign[0].id;

      final User objUser2 = GBL_TestDataFactory_Initiative.getUser(true);
      intt__Team_initiative__c team2;
      team2 = GBL_TestDataFactory_Initiative.getTeamInitiative(camp3, objUser2, true);
      team2.intt__gf_group_campaign_id__c=listAccCampaign[0].id;

      List<intt__Team_initiative__c> oldList;
      oldList = new List<intt__Team_initiative__c>();
      oldList.add(team);
      oldList.add(team2);
      Team_Initiative_Helper.shareTeamInitiative(oldList);
      Team_Initiative_Helper.deleteShareTeamInitiative(oldList);
      Team_Initiative_Helper.getInstance();
      Team_Initiative_TriggerHandler.getInstance();
      Team_Initiative_TriggerHandler.onAfterDelete(oldList);
    Test.stopTest();
  }
}