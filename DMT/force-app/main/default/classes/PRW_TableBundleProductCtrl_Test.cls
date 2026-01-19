/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TableBundleProductCtrl_Test
* @Author   Global Hub
* @Date     Created: 2021-07-05
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_TableBundleProductCtrl and PRW_Bundles_Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2022-07-05 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_TableBundleProductCtrl_Test {

  /*
  * @description
  * @author Global Hub | 2022-02-08
  */
  @testSetup
  static void setupTestData() {
    final List<Account> accounts = cuco.Test_Utils.createAccounts(3);
    accounts.get(0).SER_CClient__c = 'DTestCuco1';
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

  /**
  * @description
  * @author Global Hub | 2022-07-05
  **/
  @isTest
  static void gtDataBundlesTest() {
    final Account acc = [SELECT id, SER_CClient__c from Account LIMIT 1];
    String laccountIds =  acc.SER_CClient__c ;
    final PRW_TableBundleProductCtrl instance = PRW_TableBundleProductCtrl.gtInstance();
    system.debug(instance);
    Test.startTest();
      final Map<String,Object> response = PRW_TableBundleProductCtrl.gtDataBundles(laccountIds, 'BUSINESS');
      system.assert(Boolean.valueOF(response.get('success')), 'success false');
    Test.stopTest();
  }

  /**
  * @description
  * @author Global Hub | 2022-07-05
  **/
  @isTest
  static void gtCatalogTest() {
    final PRW_TableBundleProductCtrl instance = PRW_TableBundleProductCtrl.gtInstance();
    system.debug(instance);
    Test.startTest();
      final Map<String,Object> response = PRW_TableBundleProductCtrl.gtCatalog();
      system.assert(Boolean.valueOF(response.get('success')), 'success false');
    Test.stopTest();
  }
}