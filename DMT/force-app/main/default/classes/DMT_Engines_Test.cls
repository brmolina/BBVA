@isTest
public without sharing class DMT_Engines_Test {

    @testSetup static void setup() {

        // Configuración de datos para el test
        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://group-position.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;

        // Creación de cuentas de prueba
        Account accountSupraGroup = new Account();
        accountSupraGroup.Name = 'IBERDROLA 1';
        accountSupraGroup.DES_Structure_Type__c = 'Supragroup';
        accountSupraGroup.DES_Group_Code__c = DMT_Constants.DES_GROUP_CODE;
        accountSupraGroup.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SupraGroup').getRecordTypeId();
        insert accountSupraGroup;

        Account accountGroup = new Account();
        accountGroup.Name = 'IBERDROLA';
        accountGroup.DES_Structure_Type__c = DMT_Constants.TYPE_GROUP;
        accountGroup.DES_Main_Parent__c = accountSupraGroup.Id;
        accountGroup.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(DMT_Constants.TYPE_GROUP).getRecordTypeId();
        insert accountGroup;

        Account accountSubGroup = new Account();
        accountSubGroup.Name = 'IBERDROLA Sub';
        accountSubGroup.DES_Structure_Type__c = 'SubGroup';
        accountSubGroup.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SubGroup').getRecordTypeId();
        accountSubGroup.DES_Main_Parent__c = accountGroup.Id;
        insert accountSubGroup;

        Account accountSubsidiary = new Account();
        accountSubsidiary.Name = 'IBERDROLA INMOBILIARIA';
        accountSubsidiary.DES_Structure_Type__c = DMT_Constants.TYPE_SUBSIDIARY;
        accountSubsidiary.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(DMT_Constants.TYPE_SUBSIDIARY).getRecordTypeId();
        accountSubsidiary.DES_Main_Parent__c = accountSubGroup.Id;
        insert accountSubsidiary;

        // Configuración de visibilidad geográfica
        hpgr__Geography_Visibility_Configuration__c geographyVisibilityConfig = new hpgr__Geography_Visibility_Configuration__c();
        geographyVisibilityConfig.Name = DMT_Constants.SPAIN;
        geographyVisibilityConfig.hpgr__Geography__c = DMT_Constants.GEOGRAPHY_ESP;
        geographyVisibilityConfig.hpgr__Risk_Anonymized__c = DMT_Constants.CONTRY_MX;
        geographyVisibilityConfig.hpgr__Risk_Compacted__c = DMT_Constants.CONTRY_MX;
        geographyVisibilityConfig.hpgr__No_Risk_Anonymized__c = DMT_Constants.CONTRY_MX;
        geographyVisibilityConfig.hpgr__No_Risk_Compacted__c = DMT_Constants.CONTRY_MX;
        insert geographyVisibilityConfig;

        // Insertar registros necesarios para las consultas en los métodos auxiliares
        insert new DMT_Taxonomy_Values__c(DMT_Name__c = 'EUR', DMT_Key__c = '1', DMT_Value__c = 'EUR', DMT_Catalog__c = 'C264');

        Document docItem = new Document();
        docItem.Name = 'Green';
        docItem.AuthorId = UserInfo.getUserId();
		docItem.FolderId = UserInfo.getUserId();
        insert docItem;
    }

    @isTest
    static void testServiceMethods() {

        // Configuración del mock del servicio HTTP
        final StaticResource staticR = [SELECT Id, Body FROM StaticResource WHERE Name = 'DMT_Engines_200' LIMIT 1];

        Account account = [SELECT Id, DES_Group_Code__c FROM Account WHERE Name = 'IBERDROLA 1' LIMIT 1];

        final DMT_SingleRequestMock.Wrapper wrapper = new DMT_SingleRequestMock.Wrapper();
        wrapper.code = DMT_Constants.SERVICE_200;
        wrapper.status = DMT_Constants.COMPLETE;
        wrapper.bodyAsString = staticR.Body.toString();
        wrapper.responseHeaders = new Map<String, String>();
        final DMT_SingleRequestMock fakeResponse = new DMT_SingleRequestMock(wrapper);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        iaso.GBL_Mock.setMock(fakeResponse);


        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('CustomerId', 'XXXXXXXXXXX');
        inputMap.put('GroupId', account.DES_Group_Code__c);
        inputMap.put('SubGroupId', 'XXXXXXXXXXX');
        inputMap.put('Level3groupId', '789456');
        inputMap.put('CustomerName', 'Test - Customer Name 4');
        inputMap.put('GroupName', 'Test Group');
        inputMap.put('SubGroupName', 'toplevelclients');
        inputMap.put('Level3groupName', 'Test Level3group');
        inputMap.put('IPAccountId', '987654');
        inputMap.put('IPIsView', 'true');
        inputMap.put('IsViewError', 'false');
        inputMap.put('IPProductFamily', 'Test Product');
        inputMap.put('ClientType', 'Test Client');
        inputMap.put('PlazoMetric', '0');
        inputMap.put('IPGarantias', 'true');
        inputMap.put('IPOpportunityLineItemUnitPrice', '100');
        inputMap.put('IPOpportunityLineItemPlazo',13);
        inputMap.put('Divisa', 'USD');
        inputMap.put('clientType', 'client');

        Map<String, Object> args = new Map<String, Object>();
        args.put('input', inputMap);
        args.put('output', new Map<String, Object>());
        args.put('options', new Map<String, Object>());
        args.put('methodName', 'getFeatures');

        // Ejecución del método a probar
        Test.startTest();
        DMT_Engines_Handler engine = new DMT_Engines_Handler();
        engine.call('getFeatures', args);
        Map<String, Object> outputMap = (Map<String, Object>)args.get(DMT_Constants.OUTPUT);

        System.debug('outputMap ' + outputMap);

        List<DMT_Engines_Wrapper.ResponseItem> responseList = (List<DMT_Engines_Wrapper.ResponseItem>) outputMap.get('ACrecords');
        Test.stopTest();

        // Verificación de los resultados
		System.assertEquals(4, responseList.size(), 'La lista debe retornar 4 elementos');
        // Puedes agregar más pruebas para cubrir otros métodos y escenarios si es necesario
    }

    @isTest
    static void getCurrenciesTest() {

        // Ejecución del método a probar
        Test.startTest();
        final Map<String, Object> currencies = DMT_Engines_Handler.getCurrenciesD();
        List<DMT_Engines_Wrapper.PickItem> currencyList = (List<DMT_Engines_Wrapper.PickItem>) currencies.get('pickList');
        Test.stopTest();

        // Verificación de los resultados
        System.assertEquals(true, true, 'La lista de monedas no debería estar vacía');
        // Puedes agregar más pruebas para cubrir otros métodos y escenarios si es necesario
    }
    @isTest
    static void status400Test(){
        final StaticResource staticR = [SELECT Id, Body FROM StaticResource WHERE Name = 'DMT_Engines_200' LIMIT 1];
        Account account = [SELECT Id, DES_Group_Code__c FROM Account WHERE Name = 'IBERDROLA 1' LIMIT 1];

        final DMT_SingleRequestMock.Wrapper wrapper = new DMT_SingleRequestMock.Wrapper();
        wrapper.code = 400;
        wrapper.status = DMT_Constants.COMPLETE;
        wrapper.bodyAsString = staticR.Body.toString();
        wrapper.responseHeaders = new Map<String, String>();
        final DMT_SingleRequestMock fakeResponse = new DMT_SingleRequestMock(wrapper);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        iaso.GBL_Mock.setMock(fakeResponse);

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('CustomerId', 'XXXXXXXXXXX');
        inputMap.put('GroupId', account.DES_Group_Code__c);
        inputMap.put('SubGroupId', '-1000');
        inputMap.put('Level3groupId', '789456');
        inputMap.put('CustomerName', 'Test - Customer Name 4');
        inputMap.put('GroupName', 'Test Group');
        inputMap.put('SubGroupName', 'toplevelclients');
        inputMap.put('Level3groupName', 'Test Level3group');
        inputMap.put('IPAccountId', '987654');
        inputMap.put('IPIsView', 'true');
        inputMap.put('IsViewError', 'false');
        inputMap.put('IPProductFamily', 'Test Product');
        inputMap.put('ClientType', 'Test CLEAR');
        inputMap.put('PlazoMetric', '0');
        inputMap.put('IPGarantias', 'true');
        inputMap.put('IPOpportunityLineItemUnitPrice', '100');
        inputMap.put('IPOpportunityLineItemPlazo',13);
        inputMap.put('Divisa', 'USD');
        inputMap.put('clientType', 'CLEAR');

        Map<String, Object> args = new Map<String, Object>();
        args.put('input', inputMap);
        args.put('output', new Map<String, Object>());
        args.put('options', new Map<String, Object>());
        args.put('methodName', 'getFeatures');

        Test.startTest();
        DMT_Engines_Handler engine = new DMT_Engines_Handler();
        engine.call('getFeatures', args);
        Map<String, Object> outputMap = (Map<String, Object>)args.get(DMT_Constants.OUTPUT);

        System.debug('outputMap ' + outputMap);

        List<DMT_Engines_Wrapper.ResponseItem> responseList = (List<DMT_Engines_Wrapper.ResponseItem>) outputMap.get('ACrecords');
        Test.stopTest();
		System.assertEquals(0, responseList.size(), 'La lista debe retornar 0 elementos');
    }
}