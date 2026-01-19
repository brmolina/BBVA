/**********************************************************************************
* @author
* @date
* @description Test para Batch para la eliminación de opp share
* @Revision
**********************************************************************************/
@isTest
public class Batch_deleteOppSharingTest {
	/* testBatch method */
  @isTest
  public static void testBatch() {
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();
    final String idProfileTest = testClass.createProfile();
    final User userTest = testClass.createUser(idProfileTest,'delopp1@oppven.com');
    insert userTest;
    system.runAs(userTest) {
      List<Account> accs;
      accs = new List <Account>();
      final Account acc = testClass.createClient();
      acc.DES_Country_Client__c = 'ES';
      accs.add(acc);
      final Account acc2 = testClass.createClient();
      acc2.DES_Country_Client__c = 'ES';
      accs.add(acc2);

      insert accs;

      final DES_Subsidiary_Group_Relation__c relation = new DES_Subsidiary_Group_Relation__c();
      relation.participant_child_id__c = acc.Id;
      relation.participant_parent_id__c = acc2.Id;
      relation.main_subsidiary_ind_type__c = true;

      insert relation;

      final Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;

      List<User> users;
      users = new List <user>();
      final User user1 = testClass.createUser(idProfile,'delopp2@oppven.com');
      final User user2 = testClass.createUser(idProfile,'delopp3@oppven.com');
      final User user3 = testClass.createUser(idProfile,'delopp4@oppven.com');
      users.add(user1);
      users.add(user2);
      users.add(user3);

      insert users;

      List<DES_BBVA_Management_team__c> lstTeamMag;
      lstTeamMag = new List<DES_BBVA_Management_team__c>();
      final DES_BBVA_Management_team__c teamMmg1 = new DES_BBVA_Management_team__c();
      teamMmg1.DES_Local_Banker_Country__c = 'ES';
      teamMmg1.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
      teamMmg1.DES_User__c = user1.Id;
      teamMmg1.DES_Client__c = acc.Id;
      lstTeamMag.add(teamMmg1);

      final DES_BBVA_Management_team__c teamMmg2 = new DES_BBVA_Management_team__c();
      teamMmg2.DES_Local_Banker_Country__c = 'Global';
      teamMmg2.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
      teamMmg2.DES_User__c = user2.Id;
      teamMmg2.DES_Client__c = acc2.Id;
      lstTeamMag.add(teamMmg2);

      final DES_BBVA_Management_team__c teamMmg3 = new DES_BBVA_Management_team__c();
      teamMmg3.DES_Local_Banker_Country__c = 'Global';
      teamMmg3.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
      teamMmg3.DES_User__c = user1.Id;
      teamMmg3.DES_Client__c = acc2.Id;
      lstTeamMag.add(teamMmg3);
      insert lstTeamMag;

      final Opportunity opp = testClass.createOpportunity(acc);
      insert opp;

      Test.startTest();
      final OpportunityShare oppsh = handlerDsktpUtls.newManualSharingOpportunity(opp.Id, user3.Id, 'Edit');
      insert oppsh;
      final Id batchInstanceId = Database.executeBatch(new Batch_deleteOppSharing(), 5);
      System.assertNotEquals(batchInstanceId, Null, 'Hay respuesta');
      Test.stopTest();
    }
  }

  /* testBatch method */
  @isTest
  public static void testBatch2() {
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();
    final String idProfileTest = testClass.createProfile();
    final User userTest = testClass.createUser(idProfileTest,'delopp5@oppven.com');
    insert userTest;
    system.runAs(userTest) {
      List<Account> accs;
      accs = new List <Account>();
      final Account acc = testClass.createClient();
      acc.DES_Country_Client__c = 'ES';
      accs.add(acc);
      final Account acc2 = testClass.createClient();
      acc2.DES_Country_Client__c = 'ES';
      accs.add(acc2);

      insert accs;

      final DES_Subsidiary_Group_Relation__c relation = new DES_Subsidiary_Group_Relation__c();
      relation.participant_child_id__c = acc.Id;
      relation.participant_parent_id__c = acc2.Id;
      relation.main_subsidiary_ind_type__c = true;

      insert relation;

      final Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;

      List<User> users;
      users = new List <user>();
      final User user1 = testClass.createUser(idProfile,'delopp6@oppven.com');
      final User user2 = testClass.createUser(idProfile,'delopp7@oppven.com');
      final User user3 = testClass.createUser(idProfile,'delopp8@oppven.com');
      users.add(user1);
      users.add(user2);
      users.add(user3);

      insert users;

      final Opportunity opp = testClass.createOpportunity(acc);
      insert opp;

      Test.startTest();
      final OpportunityShare oppsh = handlerDsktpUtls.newManualSharingOpportunity(opp.Id, user3.Id, 'Edit');
      insert oppsh;
      final Id batchInstanceId = Database.executeBatch(new Batch_deleteOppSharing(), 5);
      System.assertNotEquals(batchInstanceId, Null, 'Hay respuesta');
      Test.stopTest();
    }
  }
  /* testBatch method */
  @isTest
  public static void testBatch3() {
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();
    final String idProfileTest = testClass.createProfile();
    final User userTest = testClass.createUser(idProfileTest,'delopp9@oppven.com');
    insert userTest;
    system.runAs(userTest) {
      List<Account> accs;
      accs = new List <Account>();
      final Account acc = testClass.createClient();
      acc.DES_Country_Client__c = 'ES';
      accs.add(acc);
      final Account acc2 = testClass.createClient();
      acc2.DES_Country_Client__c = 'ES';
      accs.add(acc2);

      insert accs;

      final DES_Subsidiary_Group_Relation__c relation = new DES_Subsidiary_Group_Relation__c();
      relation.participant_child_id__c = acc.Id;
      relation.participant_parent_id__c = acc2.Id;
      relation.main_subsidiary_ind_type__c = true;

      insert relation;

      final Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;

      List<User> users;
      users = new List <user>();
      final User user1 = testClass.createUser(idProfile,'delopp10@oppven.com');
      final User user2 = testClass.createUser(idProfile,'delopp11@oppven.com');
      final User user3 = testClass.createUser(idProfile,'delopp12@oppven.com');
      users.add(user1);
      users.add(user2);
      users.add(user3);

      insert users;

      List<DES_BBVA_Management_team__c> lstTeamMag;
      lstTeamMag = new List<DES_BBVA_Management_team__c>();
      final DES_BBVA_Management_team__c teamMmg1 = new DES_BBVA_Management_team__c();
      teamMmg1.DES_Local_Banker_Country__c = 'ES';
      teamMmg1.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
      teamMmg1.DES_User__c = user1.Id;
      teamMmg1.DES_Client__c = acc.Id;
      lstTeamMag.add(teamMmg1);


      insert lstTeamMag;

      final Opportunity opp = testClass.createOpportunity(acc);
      insert opp;

      Test.startTest();
      final OpportunityShare oppsh = handlerDsktpUtls.newManualSharingOpportunity(opp.Id, user3.Id, 'Edit');
      insert oppsh;
      final Id batchInstanceId = Database.executeBatch(new Batch_deleteOppSharing(), 5);
      System.assertNotEquals(batchInstanceId, Null, 'Hay respuesta');
      Test.stopTest();
    }
  }
}