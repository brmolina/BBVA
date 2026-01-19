@isTest
private class DMT_DealManagement_HandlerTest {
    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateAccount();
        DMT_Test_DataFactory.generateTestSanctionLines();
        DMT_Test_DataFactory.generateTestTreasurySingularLines();

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://group-position.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;
    }

@isTest
    static void testCall() {
        Account acc = [SELECT ID,Name FROM Account WHERE Name='Test company 1' LIMIT 1];
        Map<String,Object> mapObjects =new Map<String,Object>();

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();


        input.put('originId',acc.Id);

        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Object result = handler.call('getGroup', mapObjects);
        Test.stopTest();

        Assert.areEqual(true, result!= null, 'GroupCode not found');
    }

@isTest
    static void testLastDate() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();

        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Object result = handler.call('lastDate', mapObjects);
        Test.stopTest();

        Assert.areNotEqual(null, output.get('returnedDate'),'Error en assert equals');
    }

    @isTest
    static void testgetLineId() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('DMT_Client_Entific__c','ES');

        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        Map<String,Object> result = (Map<String,Object>) handler.call('getLineId', mapObjects);
        Test.stopTest();

        System.debug('result ' + result);
        System.debug('result.get(lineId) ' + result.get('lineId'));

        Assert.areEqual('KDCO24OPP00000001ES', result.get('lineId'),'Error en assert equals');
    }

    @isTest
    static void testrenewButton() {
        TriggerBypass.setBypass();
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        Map<Id,DMT_Line__c> linesList = new Map<Id,DMT_Line__c>([SELECT ID FROM DMT_Line__c]);
		linesList.values()[0].Status__c = 'Closed';
        linesList.values()[0].Closed__c = 'Won';
        update linesList.values()[0];
        input.put('arguments',new List<Id>(linesList.keySet()));
        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        TriggerBypass.removeBypass();

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Object result = handler.call('renewButton', mapObjects);
        Test.stopTest();

        Assert.areEqual(true, output.get('result') != null,'Error en assert equals');
    }

    @isTest
    static void testinsertWarrantyCurrency() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        DMT_Risk_Line_Term__c risk = [SELECT ID FROM DMT_Risk_Line_Term__c LIMIT 1];
        List<String> warrantyList = new List<String>{'R02', 'O04'};
        List<String> currencyList = new List<String>{'EUR', 'USD'};
        input.put('warranty',warrantyList);
        input.put('currency',currencyList);
        input.put('riskId',risk.Id);
        input.put('origin','04');

        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();

        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Object result = handler.call('warrantyCurrency', mapObjects);
        Test.stopTest();

        Assert.areEqual(true, output.get('result') == 4,'Error en assert equals');
    }
    @isTest
    static void testreorderRisk() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        DMT_Line__c testLine = [SELECT Id,OwnerId FROM DMT_Line__c WHERE Line_Id__c = '00009' LIMIT 1];
        input.put('recordId',testLine.Id);
        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Object result = handler.call('reorderRisk', mapObjects);
        Test.stopTest();

        Assert.areEqual(true, output.get('result') != null ,'Error en assert equals');
    }

     @isTest
    static void testGetSerializedGroupFromRecordCode() {
        String recordCode = 'X';

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        String result = DMT_HPG_Utils.getSerializedGroupFromRecordCode(recordCode);
        Test.stopTest();
        Assert.isTrue(result.contains('X000'), 'result should contain X00000000000001');
    }

        @isTest
    static void testsingularTreasuryConsumption() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c where Line_Id__c = '00009' LIMIT 1];
        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
                Map<String, Object> fakeRisk = new Map<String, Object>{
            'tabletype' => 'Derivatives', // Suponiendo que DMT_Constants.RSK_DERIVATIVES = 'Derivatives'
            'amount' => 10000,
            'line' => line.Id,
            'initTerm' => '0',
            'endTerm' => '365',
            'maxDate' => '2025-12-31',
            'DMT_Singular_Operation__c' => 'Op123',
            'DMT_Singular__c' => true,
            'currency' => 'USD'
        };
        Map<String, Object> currencyInput = new Map<String, Object>{

            'currency' => 'USD'
        };

        // Poner la lista de riesgos en el mapa de entrada
        Map<String, Object> input = new Map<String, Object>{
            'riskSingularList' => new List<Object>{ fakeRisk , currencyInput }
        };
        //input.put('riskSingularList',riskInitList);
        mapObjects.put('input',input);
        mapObjects.put('output',output);
        mapObjects.put('options',options);

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Object result = handler.call('singularTreasury', mapObjects);
        Test.stopTest();
        Assert.areEqual(true, output.get('result') != null ,'Error en assert equals');
    }

     public class DMT_Singular_Risk_Wrapper {
         public Decimal amount;
         public String line ;
         public String initTerm;
         public String endTerm;
         public Date maxDate;
         public String tabletype;
     }

    @isTest
    static void testGetAlphaCode() {
        Account acc = [SELECT ID FROM Account WHERE Name='Test company 1' LIMIT 1];
        Local_Client__c localClient = new Local_Client__c(
            Cib_Client__c = acc.Id,
            Alpha_code__c = 'TEST123'
        );
        insert localClient;

        Test.startTest();
        String alphaCode = DMT_HPG_Utils.getAlphaCode(acc.Id);
        Test.stopTest();

        Assert.areEqual('TEST123', alphaCode, 'Alpha code should be TEST123');
    }

    @isTest
    static void testGetGroupFromClientAccount() {
        Account acc = [SELECT ID FROM Account WHERE Name='Test company 1' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getGroupFromClientAccount(acc.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    @isTest
    static void testBuildClientGroupStructure_Supragroup() {
        // Create Supragroup account
        Account supraGroupAcc = [SELECT ID FROM Account WHERE Name='Test company 1' LIMIT 1];
        supraGroupAcc.DES_Group_Code__c = 'X00000000000001';
        supraGroupAcc.DES_Structure_Type__c = 'Supragroup';
        update supraGroupAcc;

        // Create Group account as child of Supragroup
        Account accGroup = new Account(
            Name = 'Group Account',
            DES_Group_Code__c = 'GROUP001',
            DES_Structure_Type__c = 'Group',
            DES_Main_Parent__c = supraGroupAcc.Id
        );
        insert accGroup;

        // Create Subgroup account as child of Group
        Account subgroup = new Account(
            Name = 'Subgroup Account',
            DES_Group_Code__c = 'SUBG001',
            DES_Structure_Type__c = 'Subgroup',
            DES_Main_Parent__c = accGroup.Id
        );
        insert subgroup;

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getGroupFromClientAccount(supraGroupAcc.DES_Group_Code__c);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    @isTest
    static void testBuildClientGroupStructure_Group() {
        // Create Supragroup account
        Account supraGroupAcc = [SELECT ID FROM Account WHERE Name='Test company 1' LIMIT 1];
        supraGroupAcc.DES_Group_Code__c = 'SUpG002';
        supraGroupAcc.DES_Structure_Type__c = 'Supragroup';
        update supraGroupAcc;

        // Create Group account as child of Supragroup
        Account accGroup = new Account(
            Name = 'Group Account for Test',
            DES_Group_Code__c = 'X00000000000001',
            DES_Structure_Type__c = 'Group',
            DES_Main_Parent__c = supraGroupAcc.Id
        );
        insert accGroup;

        // Create Subgroup account as child of Group
        Account subgroup = new Account(
            Name = 'Subgroup for Group Test',
            DES_Group_Code__c = 'SUBG002',
            DES_Structure_Type__c = 'Subgroup',
            DES_Main_Parent__c = accGroup.Id
        );
        insert subgroup;

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getGroupFromClientAccount(accGroup.DES_Group_Code__c);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    @isTest
    static void testBuildClientGroupStructure_Subgroup() {
        // Create Supragroup account
        Account supraGroupAcc = [SELECT ID FROM Account WHERE Name='Test company 1' LIMIT 1];
        supraGroupAcc.DES_Group_Code__c = 'SUpG002';
        supraGroupAcc.DES_Structure_Type__c = 'Supragroup';
        update supraGroupAcc;

        // Create Group account as child of Supragroup
        Account accGroup = new Account(
            Name = 'Group Account for Subgroup Test',
            DES_Group_Code__c = 'GRU001',
            DES_Structure_Type__c = 'Group',
            DES_Main_Parent__c = supraGroupAcc.Id
        );
        insert accGroup;

        // Create Subgroup account as child of Group
        Account subgroup = new Account(
            Name = 'Subgroup Account for Test',
            DES_Group_Code__c = 'X00000000000001',
            DES_Structure_Type__c = 'Subgroup',
            DES_Main_Parent__c = accGroup.Id
        );
        insert subgroup;

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getGroupFromClientAccount(subgroup.DES_Group_Code__c);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetCountriesToCompact() {
        // Create a test user with a specific country
        User testUser = new User();
        testUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id;
        testUser.FirstName = 'User Name Test';
        testUser.LastName = 'Without Permissions';
        testUser.Alias = 'ATest';
        testUser.Email = 'useremail@test.comm';
        testUser.username= String.valueof(DateTime.now().getTime()) + 'useremail@test.comm';
        testUser.CommunityNickname = 'useremail@test.comm';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.Timezonesidkey='Europe/London';
        testUser.Localesidkey ='en_US';
        testUser.languagelocalekey='en_US';
        testUser.ID_User__c ='idtestUser'+Integer.valueof((Math.random() * 100000000));

        insert testUser;

        Test.startTest();
        System.runAs(testUser) {
            List<String> result = DMT_HPG_Utils.getCountriesToCompact();
            Assert.areNotEqual(null, result, 'Result should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCountries2Anonymize() {
        // Create a test user without a specific country to test the default list
        User testUser = new User();
        testUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id;
        testUser.FirstName = 'User Name Test';
        testUser.LastName = 'Without Permissions';
        testUser.Alias = 'ATest';
        testUser.Email = 'useremail@test.comm';
        testUser.username= String.valueof(DateTime.now().getTime()) + 'useremail@test.comm';
        testUser.CommunityNickname = 'useremail@test.comm';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.Timezonesidkey='Europe/London';
        testUser.Localesidkey ='en_US';
        testUser.languagelocalekey='en_US';
        testUser.ID_User__c ='idtestUser'+Integer.valueof((Math.random() * 100000000));

        insert testUser;

        Test.startTest();
        System.runAs(testUser) {
            List<String> result = DMT_HPG_Utils.getCountries2Anonymize();
            Assert.areNotEqual(null, result, 'Result should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testUserCanEdit() {
        User testUser = new User();
        testUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id;
        testUser.FirstName = 'User Name Test';
        testUser.LastName = 'Without Permissions';
        testUser.Alias = 'ATest';
        testUser.Email = 'useremail@test.comm';
        testUser.username= String.valueof(DateTime.now().getTime()) + 'useremail@test.comm';
        testUser.CommunityNickname = 'useremail@test.comm';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.Timezonesidkey='Europe/London';
        testUser.Localesidkey ='en_US';
        testUser.languagelocalekey='en_US';
        testUser.ID_User__c ='idtestUser'+Integer.valueof((Math.random() * 100000000));

        insert testUser;

        Test.startTest();
        System.runAs(testUser) {
            Boolean result = DMT_HPG_Utils.userCanEdit();
            Assert.areNotEqual(null, result, 'Result should not be null');
        }
        Test.stopTest();
    }
}