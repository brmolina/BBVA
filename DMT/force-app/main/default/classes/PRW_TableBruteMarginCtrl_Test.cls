/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TableBruteMarginCtrl_Test
* @Author   Global Hub
* @Date     Created: 2022-05-27
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_TableBruteMarginCtrl and PRW_Margin_Service
* ------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_TableBruteMarginCtrl_Test {

  /*
  * @description
  * @author Global Hub | 2022-02-08
  */
  @testSetup
  static void setupTestData() {
    final List<Account> accounts = cuco.Test_Utils.createAccounts(3);
    accounts.get(0).SER_CClient__c = 'DTestCuco1';
    accounts.get(1).SER_CClient__c = 'DTestCuco2';
    accounts.get(2).SER_CClient__c = 'DTestCuco3';
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
  * @author Global Hub | 2022-02-08
  **/
  @isTest
  static void gtParticipantsTest() {
    final PRW_TableBruteMarginCtrl instance = PRW_TableBruteMarginCtrl.gtInstance();
    system.debug(instance);
    Test.startTest();
      final List<cuco__profitability_sheet__c> cuco = [select id, cuco__gf_profitability_sheet_id__c, cuco__gf_prftbly_sheet_end_date__c, cuco__gf_prftbly_sheet_start_date__c from cuco__profitability_sheet__c LIMIT 1];
      final List<cuco__profitability_sheet_participant__c> participants = PRW_TableBruteMarginCtrl.gtParticipants(cuco.get(0).cuco__gf_profitability_sheet_id__c);
      system.assert(!participants.isEmpty(), 'not participant sheet');
    Test.stopTest();
  }

  /**
  * @description
  * @author Global Hub | 2022-02-09
  **/
  @isTest
  static void gtDataMarginTest() {
    final List<Account> listAccount = [SELECT id, SER_CClient__c from Account LIMIT 3];
    String laccountIds = '';
    for(Account acc : listAccount) {
      laccountIds = laccountIds + acc.SER_CClient__c + '-';
    }
    laccountIds = laccountIds.removeEnd('-');
    final List<cuco__profitability_sheet__c> cuco = [select id, cuco__gf_profitability_sheet_id__c, cuco__gf_prftbly_sheet_end_date__c, cuco__gf_prftbly_sheet_start_date__c from cuco__profitability_sheet__c LIMIT 1];

    Test.startTest();
      final Map<String,Object> response = PRW_TableBruteMarginCtrl.gtDataMargin(laccountIds, cuco.get(0).cuco__gf_prftbly_sheet_start_date__c, cuco.get(0).cuco__gf_prftbly_sheet_end_date__c);
      system.assert(Boolean.valueOF(response.get('success')), 'success false');
    Test.stopTest();
  }

  /**
  * @description
  * @author Global Hub |  2022-02-09
  **/
  @isTest
  static void notebookPricingTest() {
    final PRW_Margin_Service.Datavalue dval = new PRW_Margin_Service.Datavalue();
    system.debug(dval);
    final PRW_Margin_Service.Datavalue dval1 = new PRW_Margin_Service.Datavalue('test', 'test');
    final PRW_Margin_Service.AcumulativeBlocks acum = new PRW_Margin_Service.AcumulativeBlocks();
    system.debug(acum);
    final PRW_Margin_Service.AcumulativeBlocks acum1 = new PRW_Margin_Service.AcumulativeBlocks('freq', dval1);
    final PRW_Margin_Service.Month month = new PRW_Margin_Service.Month();
    system.debug(month);
    final PRW_Margin_Service.Month month1 = new PRW_Margin_Service.Month('JUNE', '1995');
    final PRW_Margin_Service.DateBlocks dateb = new PRW_Margin_Service.DateBlocks();
    system.debug(dateb);
    final PRW_Margin_Service.DateBlocks dateb1 = new PRW_Margin_Service.DateBlocks(month1, dval1);
    final PRW_Margin_Service.Participant part = new PRW_Margin_Service.Participant();
    system.debug(part);
    final PRW_Margin_Service.Participant part1 = new PRW_Margin_Service.Participant('test', 'name');
    final PRW_Margin_Service.IdName idname = new PRW_Margin_Service.IdName();
    system.debug(idname);
    final PRW_Margin_Service.IdName idname1 = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname2 = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname3 = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname1PA = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname2PA = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname3PA = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname4PA = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname5PA = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.IdName idname6PA = new PRW_Margin_Service.IdName('test', 'name');
    final PRW_Margin_Service.ProductClassification prodClass1 = new PRW_Margin_Service.ProductClassification(idname1PA,idname2PA,idname3PA,idname4PA,idname5PA,idname6PA);
    final PRW_Margin_Service.ProductAux product1 = new PRW_Margin_Service.ProductAux(prodClass1);
    final PRW_Margin_Service.Channel channel = new PRW_Margin_Service.Channel('test', 'description');
    final List<PRW_Margin_Service.Channel> channels = new List<PRW_Margin_Service.Channel>{channel};
    final List<PRW_Margin_Service.DateBlocks> dates = new List<PRW_Margin_Service.DateBlocks>{dateb1};
    final List<PRW_Margin_Service.AcumulativeBlocks> acums = new List<PRW_Margin_Service.AcumulativeBlocks>{acum1};
    final List<String> ids = new List<String>{'id1', 'id2'};
    final PRW_Margin_Service.PetitionBy pet = new PRW_Margin_Service.PetitionBy('test8', ids);
    final Date maxDate = Date.newInstance(2022,07,07);
    final PRW_Margin_Service.Response response = new PRW_Margin_Service.Response(pet, part1, product1, 'test9', channels, dates, acums,maxDate);
    final PRW_Margin_Service.Request req = new PRW_Margin_Service.Request(pet, Date.today(), Date.today(), null, 'test18' ,'test19');
    final PRW_Margin_Service.TableDataWrap data = new PRW_Margin_Service.TableDataWrap('test10', 'test11', 'test12', 'test13', 'test14', 'test15', 'test16', 'test17','test18');
    system.assert(!pet.id_y.isEmpty(), 'empty');
  }
}