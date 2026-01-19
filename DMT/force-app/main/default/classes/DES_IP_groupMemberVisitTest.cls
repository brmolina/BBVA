/**
*
* @author Global Desktop
*/
@IsTest
private class DES_IP_groupMemberVisitTest {
    /**
     * @author Global Desktop
     */
    private static DES_IP_UTIL_Test ipUtil = new DES_IP_UTIL_Test();
    /**
     * @author Global Desktop
     */
    private static DES_UtilTestClass util = new DES_UtilTestClass();
    /**
     * @author Global Desktop
     */
    private static final String USER_USERNAME_OWNER = 'ownertest@bbvatest.test';
    /**
     * @author Global Desktop
     */
    private static final String USER_USERNAME_INDUSER = 'industryusertest@bbvatest.test';
    /**
     * @author Global Desktop
     */
    private static final String USER_NAME = 'clientTest';
    /**
     * @author Global Desktop
     */
    private static final String VISIT_NAME_NORMAL = 'Normal Visit';
    /**
     * @author Global Desktop
     */
    private static final String VISIT_NAME_IP = 'IP Visit';
    /**
     * @author Global Desktop
     */
    private static final String VISIT_INFOTYPE = 'Inside information';
    /**
     * @author Global Desktop
     */
    private static final String IIF_NAME = 'Test IIF';

    @TestSetup
    static void setup () {
        Test.startTest();
        new DES_IP_UTIL_Test().init();
        Test.stopTest();
    }

  @IsTest
  static void visibleNormalVisit() {

    Test.startTest();

    ipUtil.clientsByName.get('clientTest').OwnerId = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    update ipUtil.clientsByName.get('clientTest');

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      final dwp_kitv__Visit__c visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
      visit.Name = VISIT_NAME_NORMAL;
      insert visit;

    }

    System.runAs(ipUtil.usersByUsername.get('managerusertest@bbvatest.test')) {

      final dwp_kitv__Visit__c visitManager = [SELECT Id, Name FROM dwp_kitv__Visit__c WHERE Name = :VISIT_NAME_NORMAL];
      System.assertEquals(VISIT_NAME_NORMAL, visitManager.Name, ' Managers should see a non IP Visit :( ');

    }

    Test.stopTest();


  }

  @IsTest
  static void visibleIPVisitByItsCreator() {

    Test.startTest();

    ipUtil.clientsByName.get('clientTest').OwnerId = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    update ipUtil.clientsByName.get('clientTest');

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      final dwp_kitv__Visit__c visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
      visit.Name = VISIT_NAME_NORMAL;
      visit.RecordTypeId = ipUtil.visitIPRecordTypeId;
      visit.disclosure_info_type__c = VISIT_INFOTYPE;
      insert visit;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_NAME);
      insert iif;

      DES_IP_groupMemberVisit.preparePrivateVisit( visit.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMemberVisit.addMemberFt( visit.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      final dwp_kitv__Visit__c ipVisit = [SELECT Id, Name FROM dwp_kitv__Visit__c WHERE Name = :VISIT_NAME_NORMAL];
      System.assertEquals(VISIT_NAME_NORMAL, ipVisit.Name, 'The IP Visit should be visible by its creator :(');

    }

  }

  @IsTest
  static void notVisibleIPVisitByManager() {

    Test.startTest();

    ipUtil.clientsByName.get('clientTest').OwnerId = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    update ipUtil.clientsByName.get('clientTest');

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      final dwp_kitv__Visit__c visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
      visit.Name = VISIT_NAME_IP;
      visit.RecordTypeId = ipUtil.visitIPRecordTypeId;
      visit.disclosure_info_type__c = VISIT_INFOTYPE;
      insert visit;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_NAME);
      insert iif;

      DES_IP_groupMemberVisit.preparePrivateVisit( visit.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMemberVisit.addMemberFt( visit.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get('managerusertest@bbvatest.test') ) {

      final List<dwp_kitv__Visit__c> ipVisit = [SELECT Id, Name FROM dwp_kitv__Visit__c WHERE Name = :VISIT_NAME_IP];
      System.assert( ipVisit.isEmpty(), 'Managers shouldn\'t see IP Visit that  doesn\'t own :(' );

    }

  }

  /**
   * Test that in case of IP Opportunity, the members added to the opportunity team can see the opp
   */
  @IsTest
  static void visitMembersCanSeeIpVisit() {

    Test.startTest();

    dwp_kitv__Visit__c visit;

    ipUtil.clientsByName.get('clientTest').OwnerId = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    update ipUtil.clientsByName.get('clientTest');

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
      visit.Name = VISIT_NAME_IP;
      visit.RecordTypeId = ipUtil.visitIPRecordTypeId;
      visit.disclosure_info_type__c = VISIT_INFOTYPE;
      insert visit;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_NAME);
      insert iif;

      DES_IP_groupMemberVisit.preparePrivateVisit( visit.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMemberVisit.addMemberFt( visit.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      insert new dwp_kitv__Visit_Management_Team__c(
          dwp_kitv__user_id__c = ipUtil.usersByUsername.get(USER_USERNAME_INDUSER).Id,
          DES_Member_Role__c = Label.DES_ROLE_INDUSTRY_HEAD,
          dwp_kitv__visit_id__c = visit.Id
      );

      // Añadirlo al grupo público
      DES_IP_groupMemberVisit.addMemberNF( visit.Id, ipUtil.usersByUsername.get(USER_USERNAME_INDUSER).Id );

    }

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_INDUSER) ) {

      final List<dwp_kitv__Visit__c> ipVisit = [SELECT Id, Name FROM dwp_kitv__Visit__c WHERE Name = :VISIT_NAME_IP];
      System.assert( !ipVisit.isEmpty(), 'The members of the visit should see the IP visit');

    }

  }

  /**
   * Test that a IP visit is correctly converted to a confidential one
   */
  @IsTest
  static void changeOwnerClient() {

    Test.startTest();

    dwp_kitv__Visit__c visit;

    final dwp_kitv__Visit_validations_acc_cs__c validationsAccCs = new dwp_kitv__Visit_validations_acc_cs__c();
    validationsAccCs.dwp_kitv__bypass__c = true;
    insert validationsAccCs;

    ipUtil.clientsByName.get('clientTest').OwnerId = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    update ipUtil.clientsByName.get('clientTest');

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
      visit.Name = VISIT_NAME_IP;
      visit.RecordTypeId = ipUtil.visitIPRecordTypeId;
      visit.disclosure_info_type__c = VISIT_INFOTYPE;
      insert visit;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_NAME);
      insert iif;

      DES_IP_groupMemberVisit.preparePrivateVisit( visit.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMemberVisit.addMemberFt( visit.Id, UserInfo.getUserId() );

    }

    Test.stopTest();

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      insert new dwp_kitv__Visit_Management_Team__c(
          dwp_kitv__user_id__c = ipUtil.usersByUsername.get(USER_USERNAME_INDUSER).Id,
          DES_Member_Role__c = Label.DES_ROLE_INDUSTRY_HEAD,
          dwp_kitv__visit_id__c = visit.Id
      );

      // Añadirlo al grupo público
      DES_IP_groupMemberVisit.addMemberNF( visit.Id, ipUtil.usersByUsername.get(USER_USERNAME_INDUSER).Id );

    }

    final List<DES_IP_groupMemberVisit.IpVisitMemberGroup> mgList2 = new List<DES_IP_groupMemberVisit.IpVisitMemberGroup>();
    final DES_IP_groupMemberVisit.IpVisitMemberGroup mg2 = new DES_IP_groupMemberVisit.IpVisitMemberGroup();
    mg2.recordId = visit.Id;
    mg2.operation = 'closeVisit';
    mgList2.add(mg2);
    DES_IP_groupMemberVisit.memberToGroup(mgList2);

    System.runAs( ipUtil.usersByUsername.get('managerusertest@bbvatest.test') ) {

      final List<dwp_kitv__Visit__c> ipVisit = [SELECT Id, Name FROM dwp_kitv__Visit__c WHERE Name = :VISIT_NAME_IP];
      System.assert( !ipVisit.isEmpty(), 'Once the visit is closed, the manager should see the visit :(');

    }

  }

  /**
   * Test the deleteGroup method
   */
  @IsTest
  static void deleteGroup () {

    Test.startTest();

    final dwp_kitv__Visit__c visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
    visit.Name = 'test';
    insert visit;

    final Id groupId = DES_IP_groupMemberVisit.createGroup( visit.Id );

    final List<DES_IP_groupMemberVisit.IpVisitMemberGroup> mgList2 = new List<DES_IP_groupMemberVisit.IpVisitMemberGroup>();
    final DES_IP_groupMemberVisit.IpVisitMemberGroup mg2 = new DES_IP_groupMemberVisit.IpVisitMemberGroup();

    mg2.idUser = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    mg2.idGroup = groupId;
    mg2.operation = 'deleteGroup';
    mgList2.add(mg2);
    DES_IP_groupMemberVisit.memberToGroup(mgList2);

    Test.stopTest();

    final List<Group> groups = [SELECT Id FROM Group WHERE Name = 'test'];
    System.assert(groups.isEmpty(), 'The Group hasn\'t been deleted :(');

  }

  /**
   * Test create a group from the memberToGroup invocable method
   */
  @IsTest
  static void memberToGroupCreateGroup () {

    Test.startTest();

    final dwp_kitv__Visit__c visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
    visit.Name = 'test';
    insert visit;

    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final User user1 = utilClass.createUser( utilClass.createProfile() );
    insert user1;

    final List<DES_IP_groupMemberVisit.IpVisitMemberGroup> mgList2 = new List<DES_IP_groupMemberVisit.IpVisitMemberGroup>();
    final DES_IP_groupMemberVisit.IpVisitMemberGroup mg2 = new DES_IP_groupMemberVisit.IpVisitMemberGroup();
    mg2.idUser = user1.Id;
    mg2.recordId = visit.Id;
    mg2.operation = 'createGroup';
    mgList2.add(mg2);
    DES_IP_groupMemberVisit.memberToGroup(mgList2);
    Test.stopTest();

    final List<Group> ipGroup = [SELECT Id, Name FROM Group WHERE Name = :visit.Id];
    System.assertEquals( (String) visit.Id, ipGroup[0].Name , 'Should be created a group with the name of visit Id :(' );

  }

  /**
   * Test create a group from the memberToGroup invocable method
   */
  @IsTest
  static void memberToGroupCreateGroupNF () {

    Test.startTest();

    final dwp_kitv__Visit__c visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
    visit.Name = 'test';
    insert visit;

    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final User user1 = utilClass.createUser( utilClass.createProfile() );
    insert user1;

    final List<DES_IP_groupMemberVisit.IpVisitMemberGroup> mgList2 = new List<DES_IP_groupMemberVisit.IpVisitMemberGroup>();
    final DES_IP_groupMemberVisit.IpVisitMemberGroup mg2 = new DES_IP_groupMemberVisit.IpVisitMemberGroup();
    mg2.idUser = user1.Id;
    mg2.recordId = visit.Id;
    mg2.operation = 'createGroupNF';
    mgList2.add(mg2);
    DES_IP_groupMemberVisit.memberToGroup(mgList2);
    Test.stopTest();

    final List<Group> ipGroup = [SELECT Id, Name FROM Group WHERE Name = :visit.Id];
    System.assertEquals( (String) visit.Id, ipGroup[0].Name , 'Should be created a group with the name of visit Id :(' );

  }

  @IsTest
  static void deleteMemberTest () {

    Test.startTest();

    dwp_kitv__Visit__c visit;

    ipUtil.clientsByName.get('clientTest').OwnerId = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    update ipUtil.clientsByName.get('clientTest');

    System.runAs( ipUtil.usersByUsername.get(USER_USERNAME_OWNER) ) {

      visit = util.createVisit( ipUtil.clientsByName.get(USER_NAME), null );
      visit.Name = VISIT_NAME_IP;
      visit.RecordTypeId = ipUtil.visitIPRecordTypeId;
      visit.disclosure_info_type__c = VISIT_INFOTYPE;
      insert visit;

      final Inside_information_form__c iif = new Inside_information_form__c(Name = IIF_NAME);
      insert iif;

      DES_IP_groupMemberVisit.preparePrivateVisit( visit.Id, UserInfo.getUserId(), iif.Id );
      DES_IP_groupMemberVisit.addMemberFt( visit.Id, UserInfo.getUserId() );

    }

    final Id groupId = [SELECT Id, Name FROM Group WHERE Name = :visit.Id].Id;

    final List<DES_IP_groupMemberVisit.IpVisitMemberGroup> mgList2 = new List<DES_IP_groupMemberVisit.IpVisitMemberGroup>();
    final DES_IP_groupMemberVisit.IpVisitMemberGroup mg2 = new DES_IP_groupMemberVisit.IpVisitMemberGroup();

    mg2.idUser = ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id;
    mg2.idGroup = groupId;
    mg2.operation = 'delete';
    mgList2.add(mg2);
    DES_IP_groupMemberVisit.memberToGroup(mgList2);

    Test.stopTest();

    final List<GroupMember> groupMembers = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :ipUtil.usersByUsername.get(USER_USERNAME_OWNER).Id];
    System.assert( groupMembers.isEmpty(), 'The groupmember hasn\'t been deleted :(' );

  }

}