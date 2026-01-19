/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TableVolumeCtrl_Test
* @Author   Global Hub
* @Date     Created: 2021-08-10
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_TableVolumeCtrl and PRW_Volume_Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2022-02-08 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_TableVolumeCtrl_Test {

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
    final PRW_TableVolumeCtrl instance = PRW_TableVolumeCtrl.gtInstance();
    system.debug(instance);
    Test.startTest();
      final List<cuco__profitability_sheet__c> cuco = [select id, cuco__gf_profitability_sheet_id__c, cuco__gf_prftbly_sheet_end_date__c, cuco__gf_prftbly_sheet_start_date__c from cuco__profitability_sheet__c LIMIT 1];
      final List<cuco__profitability_sheet_participant__c> participants = PRW_TableVolumeCtrl.gtParticipants(cuco.get(0).cuco__gf_profitability_sheet_id__c);
      system.assert(!participants.isEmpty(), 'not participant sheet');
    Test.stopTest();
  }

  /**
  * @description
  * @author Global Hub | 2022-02-09
  **/
  @isTest
  static void gtDataVolumeTest() {
    final List<Account> listAccount = [SELECT id, SER_CClient__c from Account LIMIT 3];
    String laccountIds = '';
    for(Account acc : listAccount) {
      laccountIds = laccountIds + acc.SER_CClient__c + '-';
    }
    laccountIds = laccountIds.removeEnd('-');
    final List<cuco__profitability_sheet__c> cuco = [select id, cuco__gf_profitability_sheet_id__c, cuco__gf_prftbly_sheet_end_date__c, cuco__gf_prftbly_sheet_start_date__c from cuco__profitability_sheet__c LIMIT 1];

    Test.startTest();
      final Map<String,Object> response = PRW_TableVolumeCtrl.gtDataVolume(laccountIds, cuco.get(0).cuco__gf_prftbly_sheet_start_date__c, cuco.get(0).cuco__gf_prftbly_sheet_end_date__c);
      system.assert(Boolean.valueOF(response.get('success')), 'success false');
    Test.stopTest();
  }

  /**
  * @description
  * @author Global Hub |  2022-02-09
  **/
  @isTest
  static void notebookPricingTest() {
    final PRW_Volume_Service.Datavalue dval = new PRW_Volume_Service.Datavalue();
    system.debug(dval);
    final PRW_Volume_Service.Datavalue dval1 = new PRW_Volume_Service.Datavalue('test', 'test');
    final PRW_Volume_Service.AcumulativeBlocks acum = new PRW_Volume_Service.AcumulativeBlocks();
    system.debug(acum);
    final PRW_Volume_Service.AcumulativeBlocks acum1 = new PRW_Volume_Service.AcumulativeBlocks('freq', dval1);
    final PRW_Volume_Service.Month month = new PRW_Volume_Service.Month();
    system.debug(month);
    final PRW_Volume_Service.Month month1 = new PRW_Volume_Service.Month('JUNE', '1995');
    final PRW_Volume_Service.DateBlocks dateb = new PRW_Volume_Service.DateBlocks();
    system.debug(dateb);
    final PRW_Volume_Service.DateBlocks dateb1 = new PRW_Volume_Service.DateBlocks(month1, dval1);
    final PRW_Volume_Service.Participant part = new PRW_Volume_Service.Participant();
    system.debug(part);
    final PRW_Volume_Service.Participant part1 = new PRW_Volume_Service.Participant('test', 'name');
    final PRW_Volume_Service.IdName idname = new PRW_Volume_Service.IdName();
    system.debug(idname);
    final PRW_Volume_Service.IdName idname1 = new PRW_Volume_Service.IdName('test', 'name');
    final PRW_Volume_Service.IdName idname2 = new PRW_Volume_Service.IdName('test', 'name');
    final PRW_Volume_Service.IdName idname3 = new PRW_Volume_Service.IdName('test', 'name');
    final PRW_Volume_Service.TransactionAux transaction1 = new PRW_Volume_Service.TransactionAux(idname1, idname2, idname3, 'test');
    system.debug(transaction1);
    final PRW_Volume_Service.Channel channel = new PRW_Volume_Service.Channel('test', 'description');
    final List<PRW_Volume_Service.Channel> channels = new List<PRW_Volume_Service.Channel>{channel};
    final List<PRW_Volume_Service.DateBlocks> dates = new List<PRW_Volume_Service.DateBlocks>{dateb1};
    final List<PRW_Volume_Service.AcumulativeBlocks> acums = new List<PRW_Volume_Service.AcumulativeBlocks>{acum1};
    final List<String> ids = new List<String>{'id1', 'id2'};
    final PRW_Volume_Service.PetitionBy pet = new PRW_Volume_Service.PetitionBy('test', ids);
    final PRW_Volume_Service.Response response = new PRW_Volume_Service.Response(pet, part1, transaction1, channels, dates, acums,System.today());
    system.debug(response);
    final PRW_Volume_Service.Request req = new PRW_Volume_Service.Request(pet, Date.today(), Date.today(), null);
    system.debug(req);
    final PRW_Volume_Service.TableDataWrap data = new PRW_Volume_Service.TableDataWrap('test', 'test', 'test', 'test', 'test', 'test', 'test',System.today());
    system.debug(data);
    system.assert(!pet.id_y.isEmpty(), 'empty');
  }
}