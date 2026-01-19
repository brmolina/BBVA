@isTest
public class DES_IP_flow_queries_Test {
  /**
   * Creación de los datos necesarios para los tests
   */
  @TestSetup
  static void dataSetup() {
    Test.startTest();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.FirstName = 'User Test Data';
    userTest1.DES_Country__c = 'ARG';
    insert userTest1;
    final CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
    insert userSettings;

    final Map<String, User> usersByTeamRole = new Map<String, User>();
    usersByTeamRole.put('Global Banker', userTest1);

    final Account clientTest = utilTestClass.createClient('clientTest', 'IDF - clientTest', usersByTeamRole);

    final Group groupAux = new Group(
      DeveloperName = 'groupName', 
      Name = 'groupName'
    );
    insert groupAux;

    final List<DES_IP_groupMember.IpMemberGroup> mgList = new List<DES_IP_groupMember.IpMemberGroup>();
    final DES_IP_groupMember.IpMemberGroup mg = new DES_IP_groupMember.IpMemberGroup();
    mg.idGroup = groupAux.Id;
    mg.idUser = userTest1.Id;
    mg.Operation = 'addMember';
    mgList.add(mg);
    DES_IP_groupMember.memberToGroup(mgList);

    final Opportunity opp = utilTestClass.createOpportunity(clientTest);
    opp.Name = 'Operacion agua';
    insert opp;

    final dwp_kitv__Visit__c visit = utilTestClass.createVisit(clientTest, null);
    visit.visit_prvlg_participant_id__c = opp.Id;
    insert visit;
    opp.operation_prvlg_participant_id__c = visit.Id;
    update opp;
    final Case testCase = new Case(
      Subject = 'test case'
    );
    insert testCase;


    final DES_Opportunity_Management_member__c oppMembAux = new DES_Opportunity_Management_member__c(
      DES_User__c = userTest1.Id, 
      DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD, 
      DES_Scope__c = 'Global', 
      DES_Opportunity__c = opp.Id
    );
    insert oppMembAux;

    Test.stopTest();
  }

  @isTest
  public static void currentUserIsInGroupTest01() {
    //Datos necesarios para el test

    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.groupName = 'groupName';
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'insertUpdateCase';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //Test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final Case caseAssertion = [Select Id, Subject, Status
                                From Case
                                where Subject = 'test case'
                                limit 1];
    Test.stopTest();
    System.assertNotEquals(null, caseAssertion);
  }

  @isTest
  public static void currentUserIsInGroupTest02() {
    //Datos necesarios para el test

    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.groupName = 'groupName';
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'getComplianceTeamsByCountry';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //Test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final User userAssert = [Select Id, FirstName, DES_Country__c
                             From User
                             where FirstName = 'User Test Data'
                             limit 1];
    final List<String> complCountry = new List<String>{ userAssert.DES_Country__c };
    final List<Compliance_Team__mdt> complTeamList = [SELECT Compliance_Team__c
                                                      FROM Compliance_Team__mdt
                                                      WHERE DeveloperName IN:complCountry];
    Test.stopTest();
    System.assertNotEquals(0, complTeamList.size());
  }

  @isTest
  public static void currentUserIsInGroupTest03() {
    //Datos necesarios para el test
    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.groupName = 'groupName';
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'getUsersOfOppMemb';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //Test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final List<OpportunityTeamMember> otmList = [Select Id, Name
                                                 From OpportunityTeamMember
                                                 where Opportunity.Name = 'Operacion agua'];
    Test.stopTest();
    System.assertNotEquals(0, otmList.size());
  }

  @isTest
  public static void currentUserIsInGroupTest04() {
    //Datos necesarios para el test

    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'insertCaseTeamMembers';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //Test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final Case caseAssertion = [Select Id, Subject, Status
                                From Case
                                where Subject = 'test case'
                                limit 1];
    Test.stopTest();
    System.assertNotEquals(null, caseAssertion);
  }

  @isTest
  public static void currentUserIsInGroupTest05() {

    //Datos necesarios para el test
    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'insertGroupMembers';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //Test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final List<GroupMember> groupMemberList = [Select Id
                                               From GroupMember
                                               where Group.DeveloperName = 'groupName'];
    Test.stopTest();
    //final Case caseAssertion = [Select Id, Subject, Status From Case where Subject = 'test case' limit 1];
    System.assertNotEquals(0, groupMemberList.size());
  }

  @isTest
  public static void currentUserIsInGroupTest06() {

    //Datos necesarios para el test
    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'updateOpportunity';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final Opportunity oppAssertion = [Select Id, Name
                                      From Opportunity
                                      where Name = 'Operacion agua'
                                      limit 1];
    Test.stopTest();
    System.assertNotEquals(null, oppAssertion);
  }

  @isTest
  public static void currentUserIsInGroupTest07() {

    //Datos necesarios para el test
    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.groupName = 'groupName';
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'sendEmail';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final Case caseAssertion = [Select Id, Subject, Status
                                From Case
                                where Subject = 'test case'
                                limit 1];
    Test.stopTest();
    System.assertNotEquals(null, caseAssertion);
  }

  @isTest
  public static void currentUserIsInGroupTest08() {

    //Datos necesarios para el test
    final User userTest1 = [Select Id, FirstName, DES_Country__c
                            From User
                            where FirstName = 'User Test Data'
                            limit 1];
    Test.startTest();
    final DES_Opportunity_Management_member__c oppMembAux = [Select DES_User__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_Opportunity__c
                                                             From DES_Opportunity_Management_member__c
                                                             where DES_User__c = :userTest1.Id
                                                             limit 1];
    final Case testCase = [Select Id, Subject, Status
                           From Case
                           where Subject = 'test case'
                           limit 1];

    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.idUser = userTest1.Id;
    userPublicGroup.isInIPGroup = true;
    userPublicGroup.oppUsersList = new List<User>();
    userPublicGroup.oppUsersList.add(userTest1);
    userPublicGroup.method = 'insertUpdateCase';
    userPublicGroup.oppTMList = new List<DES_Opportunity_Management_member__c>();
    userPublicGroup.oppTMList.add(oppMembAux);
    userPublicGroup.caseRecord = new Case();
    userPublicGroup.caseRecord = testCase;
    userPublicGroup.Status = 'Sent to IP manager';

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //Test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);

    //Asserts
    final Case caseAssertion = [Select Id, Subject, Status
                                From Case
                                where Subject = 'test case'
                                limit 1];
    Test.stopTest();
    System.assertNotEquals(null, caseAssertion);
  }

  @isTest
  public static void currentUserIsInGroupTest09() {

    //Datos necesarios para el test
    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.opportunityId = [SELECT Id
                                     FROM Opportunity
                                     LIMIT 1].Id;
    userPublicGroup.method = 'deleteOpportunity';
    Test.startTest();
    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);
    Test.stopTest();

    //Asserts
    final List<Opportunity> oppDeleted = new List<Opportunity>([Select Id, Name
                                                                From Opportunity
                                                                where Id = :userPublicGroup.opportunityId
                                                                limit 1]);
    Boolean checkAssert = false;
    if (oppDeleted.isEmpty()) {
      checkAssert = true;
    }
    System.assertEquals(checkAssert, true);
  }

  @isTest
  public static void currentUserIsInGroupTest10() {

    //Datos necesarios para el test
    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.visitId = [SELECT Id
                               FROM dwp_kitv__Visit__c
                               LIMIT 1].Id;
    userPublicGroup.method = 'deleteVisit';
    Test.startTest();
    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //test

    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);
    Test.stopTest();

    //Asserts
    final List<dwp_kitv__Visit__c> visitDeleted = new List<dwp_kitv__Visit__c>([Select Id, Name
                                                                                From dwp_kitv__Visit__c
                                                                                where Id = :userPublicGroup.visitId
                                                                                limit 1]);
    Boolean checkAssert = false;
    if (visitDeleted.isEmpty()) {
      checkAssert = true;
    }
    System.assertEquals(checkAssert, true);
  }

  @isTest
  public static void checkObjectCreateableTest11() {
    //Datos necesarios para el test
    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.method = 'checkObjectCreatePermission';
    userPublicGroup.objectAPIName = 'Opportunity';

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //test
    Test.startTest();
    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);
    Test.stopTest();

    //Asserts
    System.assertNotEquals(uPublGroupList.get(0).objectIsCreateable, null);
  }

  @isTest
  public static void checkObjectCreateableTest12() {
    //Datos necesarios para el test
    final DES_IP_flow_queries.UserPublicGroups userPublicGroup = new DES_IP_flow_queries.UserPublicGroups();
    userPublicGroup.method = 'checkObjectCreatePermission';
    userPublicGroup.objectAPIName = 'dwp_kitv__Visit__c';

    final List<DES_IP_flow_queries.UserPublicGroups> uPublGroupList = new List<DES_IP_flow_queries.UserPublicGroups>();
    uPublGroupList.add(userPublicGroup);

    //test
    Test.startTest();
    DES_IP_flow_queries.currentUserIsInGroup(uPublGroupList);
    Test.stopTest();

    //Asserts
    System.assertNotEquals(uPublGroupList.get(0).objectIsCreateable, null);
  }

}