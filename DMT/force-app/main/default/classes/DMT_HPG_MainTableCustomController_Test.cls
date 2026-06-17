/**
* ------------------------------------------------------------------------------------------------
* @Name     DMT_HPG_MainTableCustomController_Test
* @Author   Global Hub
* @Date     Created: 2023-09-12
* ------------------------------------------------------------------------------------------------
* @Description Test class for DMT_HPG_MainTableCustomController
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class DMT_HPG_MainTableCustomController_Test {
  @testSetup
  static void setupTestData() {
    TriggerBypass.setBypass();
    final Id userId = UserInfo.getUserId();
    User user = [SELECT Id, DES_Country__c FROM User WHERE Id =: userId];
    user.DES_Country__c = 'ESP';
    update user;
    hpgr__Geography_Visibility_Configuration__c config = new hpgr__Geography_Visibility_Configuration__c();
    config.hpgr__Risk_Compacted__c = 'ES';
    config.hpgr__No_Risk_Compacted__c = 'ES';
    config.hpgr__Geography__c = 'ESP';
    insert config;
    TestFactory.createLocalClient();

    DMT_Test_DataFactory.generateOpportunity();

    List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false));
    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false));
    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint', 'https://group-position.ok', 'ServicesPartition', false));
    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPG_CommonEndPoint', 'https://group-position.ok', 'ServicesPartition', false));

    // Perform one single DML
    insert settingsToInsert;

    TriggerBypass.removeBypass();
  }
  @isTest
  static void fetchClientDataFromServiceTest() {
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchClientDataFromService(supraGroupAccount.Id, '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'N', null);
        Test.stopTest();
        System.assertEquals(true, wrapper.success, 'fetchClientDataFromServiceTest - Not passed - success');
      }
  }

  @isTest
  static void getClientIdTest1() {
    Account account = New Account();
    account.Name = 'Test Account';
    account.DES_Structure_Type__c = 'Group';
    account.DES_Group_Code__c = 'ES7202';
    insert account;
    Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
    Test.startTest();
      String alphaCode = DMT_HPG_MainTableCustomController.getClientId(account.Id);
      Test.stopTest();
      System.assertEquals(account.DES_Group_Code__c, alphaCode, 'getClientIdTest1 - Not passed - alphaCode');
  }
  @isTest
  static void getClientIdTest2() {
    final Local_Client__c localClient = [SELECT Id, Cib_Client__c, Alpha_code__c FROM Local_Client__c LIMIT 1 ];
    Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
    Test.startTest();
      String alphaCode = DMT_HPG_MainTableCustomController.getClientId(localClient.Cib_Client__c);
      Test.stopTest();
      System.assertEquals(localClient.Alpha_code__c, alphaCode, 'getClientIdTest2 - Not passed - alphaCode');
  }
  @isTest
  static void fetchUsedTablesDataFromServiceTest() {
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    update testUser;

    Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
    System.runAs(testUser) {
      Test.startTest();
        DMT_HPG_UsedTables.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchUsedTablesDataFromService(Date.newInstance(2023,09,11), '1', '10');
        System.assertEquals(true, wrapper.success, 'fetchUsedTablesDataFromServiceTest - Not passed - success');
      Test.stopTest();
    }
  }

  @isTest
  static void userIsAdminTest() {
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    update testUser;
    Test.startTest();
      System.runAs(testUser) {
        String userIsAdmin = DMT_HPG_MainTableCustomController.userIsAdmin();
        System.assertEquals('false', userIsAdmin, 'userIsAdminTest - Not passed - userIsAdmin');
      }
    Test.stopTest();
  }

  @isTest
  static void fetchDataTest() {
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        Object res = DMT_HPG_MainTableCustomController.fetchData('', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
        Test.stopTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
        System.assertEquals(true, wrapper.success, 'fetchDataDataReportTest - Not passed - success');
      }
  }

@IsTest
  static void getAccountIdFromRecordIdTest() {
    Account account = New Account();
    account.Name = 'Test Account';
    account.DES_Structure_Type__c = 'Group';
    account.DES_Group_Code__c = 'ES7202';
    insert account;
    final Id accountId = DMT_HPG_MainTableCustomController.getAccountIdFromRecordId(account.Id);
    System.assertEquals(account.Id, accountId, 'getAccountIdFromRecordIdTest - Not passed');
  }

  @IsTest
  static void getAccountIdFromRecordIdTestOpp() {
    Account account = [Select Id FROM Account WHERE Name='Test company 1' LIMIT 1];
    Opportunity oppTest = [Select Id FROM Opportunity WHERE Name='Test Opp' AND AccountId=:account.Id LIMIT 1];
    final Id accountId = DMT_HPG_MainTableCustomController.getAccountIdFromRecordId(oppTest.Id);
    System.assertEquals(account.Id, accountId, 'getAccountIdFromRecordIdTest - Not passed');
  }

  @isTest
    static void calculateSegmentTest() {
        String res1 = DMT_HPG_MainTableCustomController.calculateSegment('00006');
        System.assertEquals('Fin Inst-B', res1, 'Segment 00006 no coincide');

        String res2 = DMT_HPG_MainTableCustomController.calculateSegment('00001');
        System.assertEquals('Sov', res2, 'Segment 00001 no coincide');

        String res3 = DMT_HPG_MainTableCustomController.calculateSegment('00002');
        System.assertEquals('Pub Inst', res3, 'Segment 00002 no coincide');

        String res4 = DMT_HPG_MainTableCustomController.calculateSegment('00003');
        System.assertEquals('FINS', res4, 'Segment 00003 no coincide');

        String res5 = DMT_HPG_MainTableCustomController.calculateSegment('XXXX');
        System.assertEquals('', res5, 'Segment default no coincide');
    }

  @isTest
    static void saveOpportunityClientsTest() {

        Account acc = new Account(
            Name = 'Test Acc',
            g_customer_id__c = 'ALPHA1'
        );
        insert acc;

        Account groupAcc = new Account(
            Name = 'Group Acc',
            DES_Segment__c = '00005'
        );
        insert groupAcc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp SaveClients',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Custom_Association_Opportunity__c assoc =
            new Custom_Association_Opportunity__c(
                Opportunity__c = opp.Id,
                g_customer_id__c = 'GROUP_OLD',
                Group__c = groupAcc.Id,
                gf_customer_group_id__c = 'OLD_GROUP'
            );
        insert assoc;

        DMT_Opportunity_Client__c existing =
            new DMT_Opportunity_Client__c(
                DMT_MDE_Opportunity__c = opp.Id,
                Alpha_Code_Client__c = 'OLD_ALPHA'
            );
        insert existing;

        Map<String,Object> row = new Map<String,Object>{
            'customerId' => 'NEW_ALPHA',
            'assetAllocationActvyType' => 'ACT',
            'assetAllocationSectorType' => 'SEC',
            'assetAllocationSubSecType' => 'SUB'
        };

        List<Object> selectedClients = new List<Object>{ row };

        Test.startTest();

        DMT_HPG_MainTableCustomController.saveOpportunityClients(
            selectedClients,
            opp.Id
        );

        Test.stopTest();

        List<DMT_Opportunity_Client__c> records =
            [SELECT Alpha_Code_Client__c, Counterpart__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id];

        System.assertEquals(1, records.size(), 'The result is 1');
        System.assertEquals('NEW_ALPHA', records[0].Alpha_Code_Client__c, 'The result is NEW_ALPHA');

        System.assertEquals('Corporates', records[0].Counterpart__c, 'The result is Corporates');
    }

  @isTest
  static void updateMainHolderOnAssociationTest() {

      Account acc = new Account(
          Name='Test Acc 2',
          g_customer_id__c='ALPHA_MAIN'
      );
      insert acc;

      Opportunity opp = new Opportunity(
          Name='Test Opp Assoc',
          StageName='Prospecting',
          CloseDate=Date.today(),
          AccountId=acc.Id
      );
      insert opp;

      Custom_Association_Opportunity__c assoc =
          new Custom_Association_Opportunity__c(
              Opportunity__c = opp.Id,
              g_customer_id__c = 'GROUP_OLD_2',
              gf_customer_group_id__c = 'OLD_GROUP'
          );
      insert assoc;

      Test.startTest();
      DMT_HPG_MainTableCustomController.updateMainHolderOnAssociation(
          opp.Id,
          'NEW_MAIN'
      );
      Test.stopTest();

      assoc = [
          SELECT g_customer_id__c
          FROM Custom_Association_Opportunity__c
          WHERE Id = :assoc.Id
      ];

      System.assertEquals('NEW_MAIN', assoc.g_customer_id__c, 'The result is NEW_MAIN');
  }


  @isTest
    static void updateMainHolderApprovalDataTest() {

        // Account
        Account acc = new Account(
            Name = 'Test Account',
            g_customer_id__c = 'ACC_ALPHA'
        );
        insert acc;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        // OLD main holder (source)
        DMT_Opportunity_Client__c oppClientOld =
            new DMT_Opportunity_Client__c(
                DMT_MDE_Opportunity__c = opp.Id,
                Alpha_Code_Client__c = 'OLD_ALPHA',
                DMT_comments__c = 'Old Comment',
                Current_FY_Cash_Management_amount__c = 100
            );
        insert oppClientOld;

        // NEW main holder (target)
        DMT_Opportunity_Client__c oppClientNew =
            new DMT_Opportunity_Client__c(
                DMT_MDE_Opportunity__c = opp.Id,
                Alpha_Code_Client__c = 'NEW_ALPHA'
            );
        insert oppClientNew;

        Test.startTest();

        DMT_HPG_MainTableCustomController.updateMainHolderApprovalData(
            opp.Id,
            'OLD_ALPHA',
            'NEW_ALPHA'
        );

        Test.stopTest();

        oppClientNew = [
            SELECT DMT_comments__c,
                Current_FY_Cash_Management_amount__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oppClientNew.Id
        ];

        System.assertEquals(
            'Old Comment',
            oppClientNew.DMT_comments__c,
            'The result is Old Comment'
        );

        System.assertEquals(
            100,
            oppClientNew.Current_FY_Cash_Management_amount__c,
            'The result is 100'
        );
    }


    @isTest
    static void fetchClientDataFromServiceLineTest() {
        User testUser = TestFactory.createUser('testUserNameHPGLine', 'System Administrator');
        testUser.DES_Country__c = 'ESP';
        update testUser;

        System.runAs(testUser) {
            Account supraGroupAccount = new Account();
            supraGroupAccount.Name = 'Test Supragroup Account Line';
            supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
            supraGroupAccount.DES_Group_Code__c = 'X00000000000001';
            insert supraGroupAccount;
            Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
            Test.startTest();
                DMT_HPG_GlobalPosition.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchClientDataFromServiceLine(supraGroupAccount.Id, '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'N', null);
            Test.stopTest();
            System.assertEquals(true, wrapper.success, 'fetchClientDataFromServiceLineTest - Not passed - success');
        }
    }

    @isTest
    static void fetchClientInitialDataTest() {
        User testUser = TestFactory.createUser('testUserNameHPGClientInitial', 'System Administrator');
        testUser.DES_Country__c = 'ESP';
        update testUser;

        System.runAs(testUser) {
            Account supraGroupAccount = new Account();
            supraGroupAccount.Name = 'Test Supragroup Account Client Initial';
            supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
            supraGroupAccount.DES_Group_Code__c = 'X00000000000002';
            insert supraGroupAccount;
            Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
            Test.startTest();
                Object res = DMT_HPG_MainTableCustomController.fetchClientInitialData('', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
            Test.stopTest();
            DMT_HPG_GlobalPosition.Wrapper wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
            System.assertEquals(true, wrapper.success, 'fetchClientInitialDataTest - Not passed - success');
        }
    }


    @isTest
    static void saveLineClientsInsertTest() {
        TriggerBypass.setBypass();
        DMT_Line__c line = new DMT_Line__c();
        insert line;

        Custom_Association__c assoc = new Custom_Association__c(
            Name = 'Test custom 21',
            DMT_Line__c = line.Id,
            gf_customer_group_id__c = 'ESCD25LIN02080978ES'
        );
        insert assoc;
        TriggerBypass.removeBypass();

        Map<String, Object> row = new Map<String, Object>{
            'customerId'                      => 'ALPHA_NEW',
            'groupId'                         => 'GROUP_001',
            'updSmsclInternalRatgType'        => 'AAA',
            'customerName'                    => 'Test Client',
            'countryIfoId'                    => 'ES',
            'currentRatingToolDate'           => '2023-09-11T00:00:00',
            'customerCounterpartiesCodesDesc' => 'STAR_CODE',
            'operationMitigantDesc'           => 'CONTRACT_DESC',
            'term'                            => '12M'
        };

        Test.startTest();
        DMT_HPG_MainTableCustomController.saveLineClients(
            new List<Object>{ row },
            line.Id
        );
        Test.stopTest();

        List<Custom_Association_Client__c> clients = [
            SELECT Alpha_Code_Client__c, DMT_Term__c, Name
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :assoc.Id
        ];
        System.assertEquals(1, clients.size(), 'Debe haberse creado 1 Custom_Association_Client__c');
        System.assertEquals('ALPHA_NEW', clients[0].Alpha_Code_Client__c, 'El alpha code debe ser ALPHA_NEW');
        System.assertEquals('12M', clients[0].DMT_Term__c, 'El term debe ser 12M');
    }

    @isTest
    static void saveLineClientsDeleteDeselectedTest() {
        TriggerBypass.setBypass();
        DMT_Line__c line = new DMT_Line__c();
        insert line;

        Custom_Association__c assoc = new Custom_Association__c(
            Name = 'Test custom 3',
            DMT_Line__c = line.Id,
            gf_customer_group_id__c = 'ESCD25LIN00080978ES'
        );
        insert assoc;

        Custom_Association_Client__c oldClient = new Custom_Association_Client__c(
            Custom_Association__c = assoc.Id,
            Alpha_Code_Client__c  = 'OLD_ALPHA',
            g_customer_id__c      = 'OLD_ALPHA',
            Name                  = 'Old Client'
        );
        insert oldClient;
        TriggerBypass.removeBypass();

        Map<String, Object> row = new Map<String, Object>{
            'customerId'   => 'NEW_ALPHA',
            'customerName' => 'New Client',
            'term'         => '6M'
        };

        Test.startTest();
        DMT_HPG_MainTableCustomController.saveLineClients(
            new List<Object>{ row },
            line.Id
        );
        Test.stopTest();

        List<Custom_Association_Client__c> remaining = [
            SELECT Alpha_Code_Client__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :assoc.Id
        ];
        System.assertEquals(1, remaining.size(), 'Solo debe quedar 1 cliente');
        System.assertEquals('NEW_ALPHA', remaining[0].Alpha_Code_Client__c, 'El cliente restante debe ser NEW_ALPHA');

        List<Custom_Association_Client__c> deleted = [
            SELECT Id FROM Custom_Association_Client__c WHERE Id = :oldClient.Id
        ];
        System.assertEquals(0, deleted.size(), 'OLD_ALPHA debe haberse eliminado');
    }

    @isTest
    static void saveLineClientsAlreadyExistsTest() {
        TriggerBypass.setBypass();
        DMT_Line__c line = new DMT_Line__c();
        insert line;

        Custom_Association__c assoc = new Custom_Association__c(
            Name = 'Test custom 7',
            DMT_Line__c = line.Id,
            gf_customer_group_id__c = 'ESCD25LIN00009978ES'
        );
        insert assoc;

        Custom_Association_Client__c existingClient = new Custom_Association_Client__c(
            Custom_Association__c = assoc.Id,
            Alpha_Code_Client__c  = 'EXISTING_ALPHA',
            g_customer_id__c      = 'EXISTING_ALPHA',
            Name                  = 'Existing Client'
        );
        insert existingClient;
        TriggerBypass.removeBypass();

        Map<String, Object> row = new Map<String, Object>{
            'customerId'   => 'EXISTING_ALPHA',
            'customerName' => 'Existing Client',
            'term'         => '3M'
        };

        Test.startTest();
        DMT_HPG_MainTableCustomController.saveLineClients(
            new List<Object>{ row },
            line.Id
        );
        Test.stopTest();

        List<Custom_Association_Client__c> clients = [
            SELECT Id FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :assoc.Id
        ];
        System.assertEquals(1, clients.size(), 'No debe haber duplicados, solo 1 cliente');
    }


    @isTest
static void saveCustomAssociationInsertTest() {
    Account groupAcc = new Account(
        Name = 'Group Acc CA',
        DES_Segment__c = '00005'
    );
    insert groupAcc;

    TriggerBypass.setBypass();
    DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'L111', Name = 'Linea Test 0');
    insert line;
    TriggerBypass.removeBypass();

    Test.startTest();
    DMT_HPG_MainTableCustomController.saveCustomAssociation(
        line.Id, 'ALPHA_MAIN', 'EUR', 'GROUP_ID_01', groupAcc.Id, 'EXT_LINE_001'
    );
    Test.stopTest();

    List<Custom_Association__c> assocList = [
        SELECT Id, g_customer_id__c, g_group_Id__c, gf_customer_group_Id__c, Group__c
        FROM Custom_Association__c
        WHERE DMT_Line__c = :line.Id
    ];
    System.assertEquals(1, assocList.size(), 'Debe haberse creado 1 Custom_Association__c');
    System.assertEquals('ALPHA_MAIN', assocList[0].g_customer_id__c, 'El alpha code debe ser ALPHA_MAIN');
    System.assertEquals('GROUP_ID_01', assocList[0].g_group_Id__c, 'El group id debe ser GROUP_ID_01');
    System.assertEquals('EXT_LINE_001', assocList[0].gf_customer_group_Id__c, 'El external line id debe ser EXT_LINE_001');

    DMT_Line__c updatedLine = [SELECT Custom_Association__c FROM DMT_Line__c WHERE Id = :line.Id];
    System.assertEquals(assocList[0].Id, updatedLine.Custom_Association__c, 'La línea debe apuntar a la nueva asociación');
}

@isTest
static void saveCustomAssociationUpdateTest() {
    TriggerBypass.setBypass();
    DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'L11', Name = 'Linea Test 1');
    insert line;

    Custom_Association__c existingAssoc = new Custom_Association__c(
        Name = 'Test custom',
        DMT_Line__c = line.Id,
        gf_customer_group_id__c = 'ESCD25LIN00000978ES'
    );
    insert existingAssoc;
    TriggerBypass.removeBypass();

    Test.startTest();
    DMT_HPG_MainTableCustomController.saveCustomAssociation(
        line.Id, 'NEW_ALPHA', 'USD', 'GROUP_ID_02', null, 'EXT_LINE_002'
    );
    Test.stopTest();

    Custom_Association__c updatedAssoc = [
        SELECT g_customer_id__c FROM Custom_Association__c WHERE Id = :existingAssoc.Id
    ];
    System.assertEquals('NEW_ALPHA', updatedAssoc.g_customer_id__c, 'El alpha code debe haberse actualizado a NEW_ALPHA');
}

@isTest
static void saveLineClientFieldsTest() {
    TriggerBypass.setBypass();
    DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'L1', Name = 'Linea Test');
    insert line;

    Custom_Association__c assoc = new Custom_Association__c(
        Name = 'Test custom 2',
        DMT_Line__c = line.Id,
        gf_customer_group_id__c = 'ESCD25LIN00050978ES'
    );
    insert assoc;

    Custom_Association_Client__c client = new Custom_Association_Client__c(
        Custom_Association__c = assoc.Id,
        Alpha_Code_Client__c = 'ALPHA_CLI',
        g_customer_id__c = 'ALPHA_CLI'
    );
    insert client;
    TriggerBypass.removeBypass();

    Map<String, Object> row = new Map<String, Object>{
        'customerId' => 'ALPHA_CLI',
        'term'       => '12M',
        'amount'     => '5000',
        'amountFD'   => '1000',
        'amountDVP'  => '2000'
    };

    Test.startTest();
    DMT_HPG_MainTableCustomController.saveLineClientFields(
        new List<Object>{ row }, line.Id
    );
    Test.stopTest();

    Custom_Association_Client__c updated = [
        SELECT DMT_Term__c, DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c
        FROM Custom_Association_Client__c
        WHERE Id = :client.Id
    ];
    System.assertEquals('12M', updated.DMT_Term__c,      'El term debe ser 12M');
    System.assertEquals(5000,  updated.DMT_Amount__c,    'El amount debe ser 5000');
    System.assertEquals(1000,  updated.DMT_FDAmount__c,  'El FD amount debe ser 1000');
    System.assertEquals(2000,  updated.DMT_DVPAmount__c, 'El DVP amount debe ser 2000');
}

@isTest
static void saveLineClientFieldsNoAssociationTest() {
    TriggerBypass.setBypass();
    DMT_Line__c line = new DMT_Line__c();
    insert line;
    TriggerBypass.removeBypass();

    Map<String, Object> row = new Map<String, Object>{
        'customerId' => 'ALPHA_X',
        'term' => '6M',
        'amount' => '100'
    };

    Test.startTest();
    DMT_HPG_MainTableCustomController.saveLineClientFields(
        new List<Object>{ row }, line.Id
    );
    Test.stopTest();

    System.assert(true, 'No debe lanzar excepción si no hay Custom_Association__c');
}



}