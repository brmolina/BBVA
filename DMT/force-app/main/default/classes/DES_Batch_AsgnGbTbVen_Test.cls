/***********************************************************************************************
  Name:            DES_Batch_AsgnGbTbVen_Test
  Description:     Test Class for DES_Batch_AsgnGbTbVenVisit and DES_Batch_AssignGbTbVenOPP

  Version        Date            Author            Summary of changes
  ------------------------------------------------------------------------------------------------
  1.0            26/05/2020     Global Desktop    Class creation

***********************************************************************************************/
@isTest
public with sharing class DES_Batch_AsgnGbTbVen_Test {

  @isTest
  static void visitTest() {
    initialRecVisits();
    final Id batchJobId = Database.executeBatch(new DES_Batch_AsgnGbTbVenVisit(), 200);
    final AsyncApexJob job = [SELECT NumberOfErrors, JobItemsProcessed FROM AsyncApexJob WHERE Id = :batchJobId];
    system.debug('>>>> Number of Jobs Errors: ' + job.NumberOfErrors + ' Jobs Processed: ' + job.JobItemsProcessed);
    system.assertNotEquals(batchJobId, null, 'msg');
  }

  @isTest
  static void oppTest() {

    initialRecOpps();
    final Id batchJobId = Database.executeBatch(new DES_Batch_AssignGbTbVenOPP(), 200);
    final AsyncApexJob job = [SELECT NumberOfErrors, JobItemsProcessed FROM AsyncApexJob WHERE Id = :batchJobId];
    system.debug('>>>> Number of Jobs Errors: ' + job.NumberOfErrors + ' Jobs Processed: ' + job.JobItemsProcessed);
    system.assertNotEquals(batchJobId, null, 'msg');

  }

  static void initialRecOpps() {

    DES_UtilTestClass utilsTest;
    utilsTest = new DES_UtilTestClass();

    List<Account> accs;
    accs = new List <Account>();
    final Account acc = utilsTest.createClient();
    acc.DES_Country_Client__c = 'VE';
    accs.add(acc);
    final Account acc2 = utilsTest.createClient();
    acc2.DES_Country_Client__c = 'VE';
    accs.add(acc2);
    insert accs;

    final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
    matrix.participant_parent_id__c = acc2.Id;
    matrix.participant_child_id__c = acc.Id;
    matrix.main_subsidiary_ind_type__c = true;
    insert matrix;

    final Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;

    List<User> users;
    users = new List <user>();
    final User user1 = utilsTest.createUser(idProfile);
    final User user2 = utilsTest.createUser(idProfile,'Heyhey@oppven.com');
    users.add(user1);
    users.add(user2);
    insert users;

    List<DES_BBVA_Management_team__c> lstTeamMag;
    lstTeamMag = new List<DES_BBVA_Management_team__c>();
    final DES_BBVA_Management_team__c teamMmg1 = new DES_BBVA_Management_team__c();
    teamMmg1.DES_Local_Banker_Country__c = 'VE';
    teamMmg1.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
    teamMmg1.DES_User__c = user1.Id;
    teamMmg1.DES_Client__c = acc2.Id;
    lstTeamMag.add(teamMmg1);

    final DES_BBVA_Management_team__c teamMmg2 = new DES_BBVA_Management_team__c();
    teamMmg2.DES_Local_Banker_Country__c = 'Global';
    teamMmg2.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
    teamMmg2.DES_User__c = user2.Id;
    teamMmg2.DES_Client__c = acc2.Id;
    lstTeamMag.add(teamMmg2);
    insert lstTeamMag;

    final Opportunity opp = utilsTest.createOpportunity(acc);
    insert opp;

  }

  static void initialRecVisits() {
    DES_UtilTestClass utilsTest;
    utilsTest = new DES_UtilTestClass();

    List<Account> accs;
    accs = new List <Account>();
    final Account acc = utilsTest.createClient();
    acc.DES_Country_Client__c = 'VE';
    accs.add(acc);
    final Account acc2 = utilsTest.createClient();
    acc2.DES_Country_Client__c = 'VE';
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
    final User user1 = utilsTest.createUser(idProfile);
    final User user2 = utilsTest.createUser(idProfile,'Heyhey@oppven.com');
    users.add(user1);
    users.add(user2);

    insert users;

    List<DES_BBVA_Management_team__c> lstTeamMag;
    lstTeamMag = new List<DES_BBVA_Management_team__c>();
    final DES_BBVA_Management_team__c teamMmg1 = new DES_BBVA_Management_team__c();
    teamMmg1.DES_Local_Banker_Country__c = 'VE';
    teamMmg1.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
    teamMmg1.DES_User__c = user1.Id;
    teamMmg1.DES_Client__c = acc2.Id;
    lstTeamMag.add(teamMmg1);

    final DES_BBVA_Management_team__c teamMmg2 = new DES_BBVA_Management_team__c();
    teamMmg2.DES_Local_Banker_Country__c = 'Global';
    teamMmg2.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
    teamMmg2.DES_User__c = user2.Id;
    teamMmg2.DES_Client__c = acc2.Id;
    lstTeamMag.add(teamMmg2);

    insert lstTeamMag;

    dwp_kitv__Visit__c newVisit;
    newVisit = new dwp_kitv__Visit__c();
    newVisit.dwp_kitv__disclosure_info_type__c = 'Not applicable';
    newVisit.Name = 'Test Visit';
    newVisit.dwp_kitv__visit_start_date__c =  Date.valueOf('2020-05-20T06:47:00.000+0000');
    newVisit.dwp_kitv__account_id__c = acc.Id;
    newVisit.dwp_kitv__visit_duration_number__c = '15';

    insert newVisit;
  }
}