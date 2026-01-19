/*
* Test
*/
@isTest
public with sharing class PRW_CucoFromGroup_test {
  /*
  * Test
  */
  @testSetup
  static void setupTestData() {
    final List<Account> accounts = cuco.Test_Utils.createAccounts(3);
    insert accounts;

    final List<DES_Subsidiary_Group_Relation__c> lMatrix = new List<DES_Subsidiary_Group_Relation__c>();
    final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c(participant_child_id__c=accounts.get(0).id, participant_parent_id__c=accounts.get(1).id);
  	lMatrix.add(matrix);
    final DES_Subsidiary_Group_Relation__c matrix2 = new DES_Subsidiary_Group_Relation__c(participant_child_id__c=accounts.get(2).id, participant_parent_id__c=accounts.get(1).id);
  	lMatrix.add(matrix2);
    insert lMatrix;

    final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accounts[0]);
    profSheets.get(0).cuco__gf_prftbly_sheet_end_date__c = Date.today().addDays(1);
    insert profSheets;

    final List<cuco__profitability_sheet_participant__c> participants = cuco.Test_Utils.createProfSheetParticipant(1, profSheets[0].Id, new List<Id>{accounts[0].Id});
    insert participants;
  }


  /*
  * Test
  */
  @isTest
  static void constructorTest() {
    Test.startTest();
      PRW_CucoFromGroup res = PRW_CucoFromGroup.gtInstance();
      system.debug('res ' + res);
      final List<DES_Subsidiary_Group_Relation__c> lAcc = [SELECT id, participant_parent_id__c, participant_parent_id__r.Name FROM DES_Subsidiary_Group_Relation__c LIMIT 2];
      PRW_CucoFromGroup.isClientGroup(lAcc.get(0).participant_parent_id__c);
      final String wrapper = PRW_CucoFromGroup.getCucoFromGroup(lAcc.get(0).participant_parent_id__c, null, null);
      PRW_CucoFromGroup.getCucoFromGroup(lAcc.get(0).participant_parent_id__c, lAcc.get(0).participant_parent_id__r.Name, wrapper);
      system.assertNotEquals(null, lAcc.get(0).participant_parent_id__r.Name, 'not participant sheet');
    Test.stopTest();
  }
}