/**
*
* @author Global Desktop
*/
@isTest
public class DES_IP_groupMemberTest { //NOSONAR
    /**
     * @author Global Desktop
     */
    private static DES_IP_UTIL_Test ipUtil = new DES_IP_UTIL_Test();
    /**
     * @author Global Desktop
     */
  	private static DES_UtilTestClass util = new DES_UtilTestClass();
    /*
     * @author Global Desktop
    **/
    public static final String OPP_NAME_AGUA = 'Operacion agua';
    /*
     * @author Global Desktop
    **/
    public static final String OPP_NAME_TIERRA = 'Operacion tierra';
    /*
     * @author Global Desktop
    **/
    public static final String IIF_TEST_NAME = 'Test IIF';
    /*
     * @author Global Desktop
    **/
    public static final String BAD_ID = 'badId';

    /**
     * Test method for isOwner function
     */
    @isTest
    public static void testIsOwner() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final Group grupo = new Group();
        grupo.DoesIncludeBosses = false;
        grupo.DeveloperName = 'test'+user1.Id;
        grupo.Name = user1.Id;
        insert grupo;
        Test.startTest();
        final List<DES_IP_groupMember.IpMemberGroup> mgList = new List<DES_IP_groupMember.IpMemberGroup>();
        final DES_IP_groupMember.IpMemberGroup memberGroup = new DES_IP_groupMember.IpMemberGroup();
        memberGroup.idGroup = grupo.Id;
        memberGroup.idUser = user1.Id;
        mgList.add(memberGroup);
        DES_IP_groupMember.memberToGroup(mgList);
        final List<DES_IP_groupMember.IpMemberGroup> mgList2 = new List<DES_IP_groupMember.IpMemberGroup>();
        final DES_IP_groupMember.IpMemberGroup mg2 = new DES_IP_groupMember.IpMemberGroup();
        mg2.idGroup = grupo.Id;
        mg2.idUser = user1.Id;
        mg2.operation = 'delete';
        mgList2.add(mg2);
        DES_IP_groupMember.memberToGroup(mgList2);
        /* system.runAs(user1) {
            final Opportunity opp = utilClass.createOpportunity(acc); //NOSONAR
            insert opp;
        }*/
        system.assert(true, grupo.Id);
        Test.stopTest();
    }

  @TestSetup
  static void setup() {

    Test.startTest();

    new DES_IP_UTIL_Test().init();

    Test.stopTest();

  }

  /**
   * Test that a normal Opportunity created by a normal user is visible by its manager
   */
  @IsTest
  static void visibleNormalOpportunity () {

    Test.startTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      final Opportunity opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = OPP_NAME_AGUA;
      insert opp;

    }

    System.runAs(ipUtil.usersByUsername.get('managerusertest@bbvatest.test')) {

      final Opportunity oppManager = [SELECT Id, Name FROM Opportunity WHERE Name = :OPP_NAME_AGUA];
      System.assertEquals(OPP_NAME_AGUA, oppManager.Name, 'Managers should see a non IP Opportunity :(');

    }

    Test.stopTest();

  }

  /**
   * Test that an IP Opportunity created by a normal user is visible by the user
   */
  @IsTest
  static void visibleIPOpportunityByItsCreator() {

    Test.startTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      final Opportunity opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = OPP_NAME_TIERRA;
      opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
      opp.disclosure_info_type__c = 'Inside information';
      insert opp;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_TEST_NAME);
      insert iif;

      DES_IP_groupMember.preparePrivateOpportunity( opp.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMember.addMemberFt( opp.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      final Opportunity oppTierra = [SELECT Id, Name FROM Opportunity WHERE Name = :OPP_NAME_TIERRA];
      System.assertEquals(OPP_NAME_TIERRA, oppTierra.Name, 'The IP Opportunity should be visible by its creator :(');

    }

  }

  /**
   * Test that an IP opportunity created by a normal user is not visible by its manager
   */
  @IsTest
  static void notVisibleIPOpportunityByManager () {

    Test.startTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      final Opportunity opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = OPP_NAME_TIERRA;
      opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
      opp.disclosure_info_type__c = 'Inside information';
      insert opp;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_TEST_NAME);
      insert iif;

      DES_IP_groupMember.preparePrivateOpportunity( opp.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMember.addMemberFt( opp.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get('managerusertest@bbvatest.test') ) {

      final List<Opportunity> oppTierra = [SELECT Id, Name FROM Opportunity WHERE Name = :OPP_NAME_TIERRA];
      System.assert( oppTierra.isEmpty(), 'Managers shouldn\'t see IP Opportunities that doesn\'t own :(' );
    }

  }

  /**
   * Test that if a normal opportunity the account team is copy to the opportunity team
   */
  @IsTest
  static void normalOpportunityCopyAccountTeam () {



    Opportunity opp;

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = 'Operacion agua';
      insert opp;

      new ProductToOpportunity( 'TestProduct', 'GTB', opp );
      ProductToOpportunity.insertAll();
      Test.startTest();
      update new Opportunity( Id = opp.Id, StageName = Label.DES_Proposal );

      final List<DES_Opportunity_Management_member__c> oppTeamMembers = [
          SELECT Id, Name, DES_Opportunity_member_role__c
          FROM DES_Opportunity_Management_member__c
          WHERE DES_Opportunity__c = :opp.Id
      ];

      System.assert( !oppTeamMembers.isEmpty(), 'Account members should have been copied to the Opportunity Team! :(' );
      Test.stopTest();

    }



  }

  /**
   * Test that the account Team is not copy to the opportunity Team when IP opportunity's stage switch to Proposal
   */
  @IsTest
  static void dontCopyAccountTeamToIPOpportunity () {

    Test.startTest();

    Opportunity opp;

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = OPP_NAME_TIERRA;
      opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
      opp.disclosure_info_type__c = 'Inside information';
      insert opp;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_TEST_NAME);
      insert iif;

      DES_IP_groupMember.preparePrivateOpportunity( opp.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMember.addMemberFt( opp.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      new ProductToOpportunity( 'TestProduct', 'GTB', opp );
      ProductToOpportunity.insertAll();

      update new Opportunity( Id = opp.Id, StageName = Label.DES_Proposal );
      final List<DES_Opportunity_Management_member__c> oppTeamMembers = [
          SELECT Id, Name, DES_Opportunity_member_role__c
          FROM DES_Opportunity_Management_member__c
          WHERE DES_Opportunity__c = :opp.Id
      ];

      System.debug( 'oppTeamMembers' + oppTeamMembers );

      System.assert( oppTeamMembers.isEmpty(), 'In case of IP opportunity, the Account Team shouldn\'t have been copied to Opportunity Team! :(' );

    }

  }

  /**
   * Test that in case of IP Opportunity, the members added to the opportunity team can see the opp
   */
  @IsTest
  static void oppMembersCanSeeIpOpportunities() {

    Test.startTest();

    Opportunity opp;

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = OPP_NAME_TIERRA;
      opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
      opp.disclosure_info_type__c = 'Inside information';
      insert opp;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_TEST_NAME);
      insert iif;

      DES_IP_groupMember.preparePrivateOpportunity( opp.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMember.addMemberFt( opp.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      // Add the industry head user to the opportunity
      insert new DES_Opportunity_Management_member__c(
          DES_User__c = ipUtil.usersByUsername.get('industryusertest@bbvatest.test').Id,
          DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD,
          DES_Scope__c = 'Global',
          DES_Opportunity__c = opp.Id
      );

      // Añadirlo al grupo público
      List<DES_IP_groupMember.IpMemberGroup> mgList2 = new List<DES_IP_groupMember.IpMemberGroup>();
      DES_IP_groupMember.IpMemberGroup mg2 = new DES_IP_groupMember.IpMemberGroup();
      mg2.idUser = ipUtil.usersByUsername.get('industryusertest@bbvatest.test').Id;
      mg2.recordId = opp.Id;
      mg2.operation = 'addMemberNF';
      mgList2.add(mg2);
      DES_IP_groupMember.memberToGroup(mgList2);

      DES_IP_groupMember.addMemberNF( opp.Id, ipUtil.usersByUsername.get( 'industryusertest@bbvatest.test' ).Id );

    }

    System.runAs( ipUtil.usersByUsername.get('industryusertest@bbvatest.test') ) {

      final List<Opportunity> ipOpp = [SELECT Id, Name FROM Opportunity WHERE Name = :OPP_NAME_TIERRA];
      System.assert( !ipOpp.isEmpty(), '' );

    }

  }

  /**
 * Test that the manager of an IP opportunity team member can not see the opportunity
 */
  @IsTest
  static void visibleOpportunityByOppMemberManager() {


    Opportunity opp;

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = 'Operacion agua';
      insert opp;

      // Add the industry head user to the opportunity
      insert new DES_Opportunity_Management_member__c(
          DES_User__c = ipUtil.usersByUsername.get('industryusertest@bbvatest.test').Id,
          DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD,
          DES_Scope__c = 'Global',
          DES_Opportunity__c = opp.Id
      );

      new ProductToOpportunity( 'TestProduct', 'GTB', opp );
      ProductToOpportunity.insertAll();
      Test.startTest();
      update new Opportunity( Id = opp.Id, StageName = Label.DES_Proposal );

    }

    System.runAs( ipUtil.usersByUsername.get('managerusertest@bbvatest.test') ) {

      final List<Opportunity> ipOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Operacion agua'];
      System.assert( !ipOpp.isEmpty(), 'Manager of normal Opp Team members should see the normal Opp :(' );

    }

    Test.stopTest();

  }

  /**
   * Test that the manager of an IP opportunity team member can not see the opportunity
   */
  @IsTest
  static void notVisibleIPOpportunityByOppMemberManager() {

    Test.startTest();

    Opportunity opp;

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
      opp.Name = OPP_NAME_TIERRA;
      opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
      opp.disclosure_info_type__c = 'Inside information';
      insert opp;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_TEST_NAME);
      insert iif;

      DES_IP_groupMember.preparePrivateOpportunity( opp.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMember.addMemberFt( opp.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get('ownertest@bbvatest.test') ) {

      // Add the industry head user to the opportunity
      insert new DES_Opportunity_Management_member__c(
          DES_User__c = ipUtil.usersByUsername.get('industryusertest@bbvatest.test').Id,
          DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD,
          DES_Scope__c = 'Global',
          DES_Opportunity__c = opp.Id
      );

      // Añadirlo al grupo público
      DES_IP_groupMember.addMemberFt( opp.Id, ipUtil.usersByUsername.get( 'industryusertest@bbvatest.test' ).Id );

    }

    System.runAs( ipUtil.usersByUsername.get('managerusertest@bbvatest.test') ) {

      final List<Opportunity> ipOpp = [SELECT Id, Name FROM Opportunity WHERE Name = :OPP_NAME_TIERRA];
      System.assert( ipOpp.isEmpty(), 'Manager of IP Opp Team members shouldn\'t see the Ipp Opp :(' );
    }

  }

  /**
   * Test to cover exception of the method preparePrivateOpportunity
   */
  @IsTest
  static void exceptionpreparePrivateOpportunity () {

    String exMsm;
    exMsm = '';
    try {
      DES_IP_groupMember.preparePrivateOpportunity(BAD_ID, BAD_ID, BAD_ID);
    } catch (Exception e) {
      exMsm = e.getMessage();
    }

    System.assertEquals('Invalid id: badId', exMsm, 'An invalid id exception should have been arisen! :(');

  }

  /**
   * Test to cover exception of the method addMemberNF
   */
  @IsTest
  static void exceptionAddMemberNF () {

    String exMsm;
    exMsm = '';
    try {
      DES_IP_groupMember.addMemberNF(BAD_ID, BAD_ID);
    } catch (Exception e) {
      exMsm = e.getMessage();
    }

    System.assertEquals('Invalid id: badId', exMsm, 'An invalid id exception should have been arisen! :(');

  }

  /**
   * Test the deleteGroup method
   */
  @IsTest
  static void deleteGroup () {

    Test.startTest();
    Opportunity opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
    opp.Name = 'Operacion agua';
    insert opp;
    Id groupId = DES_IP_groupMember.createGroup( opp.Id );

    List<DES_IP_groupMember.IpMemberGroup> mgList2 = new List<DES_IP_groupMember.IpMemberGroup>();
    DES_IP_groupMember.IpMemberGroup mg2 = new DES_IP_groupMember.IpMemberGroup();
    mg2.idGroup = groupId;
    mg2.operation = 'deleteGroup';
    mgList2.add(mg2);

    DES_IP_groupMember.memberToGroup(mgList2);
    Test.stopTest();

    List<Group> groups = [SELECT Id FROM Group WHERE Name = 'test'];
    System.assertEquals( true, groups.isEmpty(), 'The Group hasn\'t been deleted :(' );

  }

  /**
   * Test create a group from the memberToGroup invocable method
   */
  @IsTest
  static void memberToGroupCreateGroup () {

    Test.startTest();
    Opportunity opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
    opp.Name = OPP_NAME_TIERRA;
    opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
    opp.disclosure_info_type__c = 'Inside information';
    insert opp;

    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final User user1 = utilClass.createUser( utilClass.createProfile() );
    insert user1;

    List<DES_IP_groupMember.IpMemberGroup> mgList2 = new List<DES_IP_groupMember.IpMemberGroup>();
    DES_IP_groupMember.IpMemberGroup mg2 = new DES_IP_groupMember.IpMemberGroup();
    mg2.idUser = user1.Id;
    mg2.recordId = opp.Id;
    mg2.operation = 'createGroup';
    mgList2.add(mg2);
    DES_IP_groupMember.memberToGroup(mgList2);
    Test.stopTest();

    List<Group> ipGroup = [SELECT Id, Name FROM Group WHERE Name = :opp.Id];
    System.assertEquals( (String) opp.Id, ipGroup[0].Name , 'Should be created a group with the name of opportunity Id :(' );

  }

  /**
   * Test create a groupNF from the memberToGroup invocable method
   */
  @IsTest
  static void memberToGroupCreateGroupNF () {

    Test.startTest();
    Opportunity opp = util.createOpportunity( ipUtil.clientsByName.get('clientTest') );
    opp.Name = OPP_NAME_TIERRA;
    opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
    opp.disclosure_info_type__c = 'Inside information';
    insert opp;

    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final User user1 = utilClass.createUser( utilClass.createProfile() );
    insert user1;

    List<DES_IP_groupMember.IpMemberGroup> mgList2 = new List<DES_IP_groupMember.IpMemberGroup>();
    DES_IP_groupMember.IpMemberGroup mg2 = new DES_IP_groupMember.IpMemberGroup();
    mg2.idUser = user1.Id;
    mg2.recordId = opp.Id;
    mg2.operation = 'createGroupNF';
    mgList2.add(mg2);
    DES_IP_groupMember.memberToGroup(mgList2);
    Test.stopTest();

    List<Group> ipGroup = [SELECT Id, Name FROM Group WHERE Name = :opp.Id];
    System.assertEquals( (String) opp.Id, ipGroup[0].Name , 'Should be created a group with the name of opportunity Id :(' );

  }


}