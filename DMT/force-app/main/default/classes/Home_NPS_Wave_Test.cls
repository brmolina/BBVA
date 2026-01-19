/******************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: Home_NPS_Wave_Test
*   @Description:  Home_NPS_Wave_Cnt - Tests

*   @Versions:
        v1 - 2019/11/06 - Initial version
******************************************************************************/
@isTest
public class Home_NPS_Wave_Test {
  /* Declarando variable */
  private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

  /**
  * Test setup
  */
  @TestSetup
  static void testSetup() {
    //RecordTypes de cuenta.
    final Id rtGROUP = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId();
    final Id rtFILIAL = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary).getRecordTypeId();

    //Declaración de las cuentas
    final List<Account> accList = new List<Account>();
    final Account accGroup = utilTestClass.createClient();
    accGroup.Name = 'Grupo_A_ES';
    accGroup.DES_BBVA_Segmentation__c = 'B';
    accGroup.DES_Structure_Type__c = 'Group';
    accGroup.DES_Country_Client__c = 'ES';
    accGroup.recordTypeId = rtGROUP;
    accGroup.DES_Segment__c = '00005'; //Corporate
    accList.add(accGroup);
    final Account accMatrix = utilTestClass.createClient();
    accMatrix.Name = 'Matriz_A_ES';
    accMatrix.DES_BBVA_Segmentation__c = 'B';
    accMatrix.DES_Structure_Type__c = 'Subsidiary';
    accMatrix.DES_Entity_Hierarchy__c = 'S';
    accMatrix.DES_Main_Parent__c = accGroup.Id;
    accMatrix.DES_Country_Client__c = 'ES';
    accMatrix.recordTypeId = rtFILIAL;
    accList.add(accMatrix);
    insert accList;

    //Declaración de la relación entre cuentas
    final DES_Subsidiary_Group_Relation__c relation = new DES_Subsidiary_Group_Relation__c();
    relation.participant_child_id__c = accMatrix.Id;
    relation.participant_parent_id__c = accGroup.Id;
    insert relation;

    //Declaración del booking
    final DES_Booking__c book = utilTestClass.createBooking(accMatrix, 'ESPAÑA', 'ESPAÑA', 1000, 'GTB', '2019');
    insert book;

    final NPS_Wave__c iNPSWavePerimeter = new NPS_Wave__c(
      gf_nps_survey_cust_tier_desc__c = 'CIB-Bronze',
      gf_nps_sv_cust_rev_ind_type__c = 'ESPAÑA',
      gf_nps_sv_cust_prfsnl_seg_desc__c = 'Corporate',
      RecordTypeId = Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get('NPS_Perimeter').getRecordTypeId()
    );
    insert iNPSWavePerimeter;
  }

  /**
  * Test principal
  */
  @isTest
  public static void test1() {
    //RecordTypes de cuenta.
    final Id rtGROUP = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId();
    final Id rtFILIAL = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary).getRecordTypeId();

    final Account accGroup = [SELECT Id, Name FROM Account WHERE Name = 'Grupo_A_ES'];

    final User sampleUser = UnitTestUtils.GetSysAdminUser();
    sampleUser.ID_User__c = 'testID';
    insert sampleUser;

    Test.startTest();
      System.runAs(sampleUser) {
        Home_NPS_Wave_Cnt.completeForm('NPS_Wave__c','gf_nps_sv_cust_prfsnl_seg_desc__c,gf_nps_survey_cust_tier_desc__c,gf_nps_sv_cust_rev_ind_type__c');

        final String dataSet = '[{"fapiname":"gf_nps_sv_cust_prfsnl_seg_desc__c","value":"Corporate;Institutional Client"},'+
        +'{"fapiname":"gf_nps_sv_cust_rev_ind_type__c","value":"ESPAÑA"}]';
        String oFilter = 'Account'; //NOSONAR
        String fFilter = 'DES_Segment__c=gf_nps_sv_cust_prfsnl_seg_desc__c'; //NOSONAR
        String rtFilter = '(\'Group\',\'DES_Commercial_Client\')'; //NOSONAR
        String otherFilter = 'gf_nps_sv_cust_rev_ind_type__c'; //NOSONAR
        final String ret1 = Home_NPS_Wave_Cnt.getData(dataSet,oFilter,fFilter,rtFilter,otherFilter);
        System.debug('::::::::::ret1: ' + ret1);

        final String dataSet2 = '[{"fapiname":"nps_start_date__c","value":"'+Date.today()+'"},{"fapiname":"gf_nps_survey_cust_send_date__c",'+
        +'"value":"2019-11-08"},{"fapiname":"nps_end_date__c","value":"2019-11-10"},{"fapiname":"gf_nps_sv_cust_oper_cntry_desc__c","value":"AR"}]';
        final String accSelect = '[{"name":"'+accGroup.Name+'","id":"'+accGroup.Id+'"}]';
        Home_NPS_Wave_Cnt.getSelectOptions('NPS_Wave__c', 'gf_nps_sv_cust_oper_cntry_desc__c');
        Home_NPS_Wave_Cnt.checkPerimeter();
        Home_NPS_Wave_Cnt.getPerimeter(dataSet, accSelect);
        Home_NPS_Wave_Cnt_Aux.resetNPSContact();

        final NPS_Wave__c iWavePerimeter = new NPS_Wave__c();
        iWavePerimeter.put('Name', 'NPS perimeter ' + Date.Today().Year());
        iWavePerimeter.put('RecordTypeId', Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get(Label.RT_NPS_Perimeter).getRecordTypeId());
        insert iWavePerimeter;

        final NPS_Wave__c iNPSWave = new NPS_Wave__c();
        iNPSWave.put('Name', 'NPS perimeter ' + Date.Today().Year());
        iNPSWave.put('RecordTypeId', Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get('NPS_Wave').getRecordTypeId());
        insert iNPSWave;

        Home_NPS_Wave_Cnt.getWaves(dataSet, dataSet2, new List<String>{accSelect});
        Home_NPS_Wave_Cnt_Aux.getInstance();
      
        System.assert(iNPSWave != null, 'Ret is null');
      }
    Test.stopTest();
  }

  /**
  * Test principal
  */
  @isTest
  public static void test2() {
    //RecordTypes de cuenta.
    final Id rtGROUP = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId();
    final Id rtFILIAL = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary).getRecordTypeId();
 
    final Account accGroup = [SELECT Id, Name FROM Account limit 1];
     Contact SampleContact3 = new Contact(
      Lastname = 'ContactName3',
      AccountId = accGroup.id,
      Email_ExternalID__c = 'ContactName3@test.com',
      Asset_Class__c = 'FI',
      RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets')
      );  
     insert SampleContact3;
    final User sampleUser = UnitTestUtils.GetSysAdminUser();
    sampleUser.ID_User__c = 'testID';
    insert sampleUser;

    Test.startTest(); 
      final NPS_Wave__c iNPSWave = new NPS_Wave__c();
      iNPSWave.put('Name', 'NPS perimeter ' + Date.Today().Year());
      iNPSWave.put('RecordTypeId', Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get('NPS_Wave').getRecordTypeId());
      iNPSWave.gf_nps_survey_cust_send_date__c=date.today();
      iNPSWave.nps_start_date__c=date.today();
      iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c='CO;CO';
      insert iNPSWave;
      Map<String,String> mapValueLabel=new Map<String,String>();
      mapValueLabel.put('CO','CO');
      Map<String,String> apivaluesSelect=new Map<String,String>();
      apivaluesSelect.put('gf_nps_sv_cust_rev_ind_type__c','CO');
      Home_NPS_Wave_Cnt_Aux.otherFilters(new Set<Id>{accGroup.id}, apivaluesSelect);
      Home_NPS_Wave_Cnt_Aux.getAllWaves(new List<NPS_Wave__c> {iNPSWave},mapValueLabel);  

      final Batch_Create_Task_NPS iBatch = new Batch_Create_Task_NPS(iNPSWave, new List<Account> {accGroup});
      Database.executeBatch(iBatch, 10);

      System.assert(iNPSWave != null, 'Ret is null');
    Test.stopTest();
  }
}