/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TabContainerTest
* @Author   Global Hub
* @Date     Created: 2021-08-10
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_TabContainerCtrl
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-08-10 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_TabContainerTest {
  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return a JSON with the data to construct the policie table
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-26
  * @param recordId - Record Id of the account
  * @return List - Data of the conditions
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void gtInfoAccountTest() {
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final PRW_TabContainerCtrl instance = PRW_TabContainerCtrl.gtInstance();
    system.debug(instance);
    final Account acc = util.createClient();
    insert acc;
    final Account accAux = PRW_TabContainerCtrl.gtInfoAccount(acc.Id);
    system.assertEquals(acc.Name, accAux.Name, 'No account with id');
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Test method for gtProfSheet
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-08
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void gtProfSheetTest() {
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final Account acc = util.createClient();
    insert acc;
    final cuco__profitability_sheet__c cuco = new cuco__profitability_sheet__c();
    cuco.Name = 'test';
    cuco.cuco__gf_prftbly_sheet_stt_type_name__c = '01';
    cuco.cuco__gf_profitability_sheet_id__c = '0001';
    cuco.cuco__gf_prftbly_sheet_seg_type_name__c = '03';
    cuco.cuco__gf_prftbly_sheet_start_date__c = date.TODAY() - 10;
    cuco.cuco__gf_prftbly_sheet_end_date__c = date.TODAY() + 10;
    cuco.cuco__participant_id__c = acc.Id;
    insert cuco;
    final cuco__profitability_sheet_participant__c part = new cuco__profitability_sheet_participant__c();
    part.cuco__participant_id__c = acc.Id;
    part.cuco__gf_profitability_sheet_id__c = cuco.Id;
    part.cuco__gf_ps_participant_id__c = 'TestPart';
    insert part;
    final cuco__profitability_sheet_participant__c part2 = PRW_TabContainerCtrl.gtProfSheet(acc.id);
    final List<String> part3 = PRW_TabContainerCtrl.gtParticipants(cuco.Id);
    system.assertNotEquals(null, part2, 'not participant sheet');
  }

  /**
  * @description
  * @author ivan.garces.contractor@bbva.com | 2022-12-02
  **/
  @isTest
  static void gtCatalogTest() {
    final PRW_TabContainerCtrl instance = PRW_TabContainerCtrl.gtInstance();
    system.debug(instance);
    Test.startTest();
      final Map<String,Object> response = PRW_TabContainerCtrl.gtCatalog();
      system.assert(Boolean.valueOF(response.get('success')), 'success false');
    Test.stopTest();
  }
}