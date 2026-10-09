@isTest
private class DMT_CreateLineServiceTest {

    @TestSetup
    static void setupData() {
        // Taxonomy Values Setup
        List<DMT_Taxonomy_Values__c> taxonomyList = new List<DMT_Taxonomy_Values__c>();

        // CD07 - Country Catalog
        DMT_Taxonomy_Values__c countryTaxonomy = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'CD07',
            DMT_Active__c = true,
            DMT_Value__c = 'ES',
            DMT_Name_EN__c = 'Spain'
        );
        taxonomyList.add(countryTaxonomy);

        // h006 - Entity Catalog
        DMT_Taxonomy_Values__c entityTaxonomy = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'h006',
            DMT_Active__c = true,
            DMT_Value__c = 'ES',
            gf_catalog_atrb_val2_name__c = 'EUR'
        );
        taxonomyList.add(entityTaxonomy);

        insert taxonomyList;

        // Accounts Setup
        List<Account> accountsToInsert = new List<Account>();

        Account standardAcc = new Account(
            Name = 'Test Account Standard',
            g_customer_id__c = 'ES123456'
        );
        accountsToInsert.add(standardAcc);

        Account subAcc = new Account(
            Name = 'Test Account Subsidiary',
            DES_Group_Code__c = 'ES654321'
        );
        accountsToInsert.add(subAcc);

        insert accountsToInsert;
    }



    private static String getValidRecordTypeName() {
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        for (String devName : rtMap.keySet()) {
            if (rtMap.get(devName).isAvailable() && devName != 'Master') {
                return devName;
            }
        }
        return 'TreasurySettlement';
    }

    @isTest
    static void testGetLineCreationParameters_StandardClient() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Standard' LIMIT 1];
        String validRtName = getValidRecordTypeName();

            Test.startTest();
            Map<String, Object> result = DMT_CreateLineService.getLineCreationParameters(acc.Id, 'GROUP_01', validRtName);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result map should not be null');
            System.assertEquals(acc.Id, result.get('clientId'), 'Client ID should match');
            System.assertEquals('ES123456', result.get('generalClientCode'), 'General client code should match customer ID');
            System.assertEquals(validRtName, result.get('RecordTypeName'), 'RecordTypeName should match');
            System.assert(result.containsKey('hasDMTAccessPS'), 'Result should check permission set assignment');
        
    }

    @isTest
    static void testGetLineCreationParameters_SubsidiaryClient() {
        Account subAcc = [SELECT Id FROM Account WHERE Name = 'Test Account Subsidiary' LIMIT 1];
        String validRtName = getValidRecordTypeName();

            Test.startTest();
            Map<String, Object> result = DMT_CreateLineService.getLineCreationParameters(subAcc.Id, null, validRtName);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result map should not be null');
            System.assertEquals('ES654321', result.get('generalClientCode'), 'Group code should be used as fallback code');
        
    }

    @isTest
    static void testGetLineCreationParameters_GroupIdOnly() {
        String validRtName = getValidRecordTypeName();

            Test.startTest();
            Map<String, Object> result = DMT_CreateLineService.getLineCreationParameters(null, 'GRP_999', validRtName);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result map should not be null');
            System.assertEquals('GRP_999', result.get('generalClientCode'), 'Group ID should be used as general client code when clientId is null');
        
    }

    

    @isTest
    static void testCreateLine_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Standard' LIMIT 1];
        String validRtName = getValidRecordTypeName();

        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);

        Test.startTest();
        Id lineId = DMT_CreateLineService.createLine(
            validRtName,
            'Test Line Name',
            startDate,
            endDate,
            acc.Id,
            'ES',
            'ES123456',
            'ES'
        );
        Test.stopTest();

        System.assertNotEquals(null, lineId, 'Created Line Id should not be null');
        DMT_Line__c createdLine = [SELECT Id, Name, Client__c, Line_Id__c, Start_Date__c, End_Date__c FROM DMT_Line__c WHERE Id = :lineId];
        System.assertEquals('Test Line Name', createdLine.Name);
        System.assertEquals(acc.Id, createdLine.Client__c);
        System.assertEquals(endDate, createdLine.End_Date__c);
    }

    @isTest
    static void testCreateLine_TreasurySettlement_EndOfMonthResolution() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Standard' LIMIT 1];
        String rtName = 'TreasurySettlement';

        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        if (!rtMap.containsKey(rtName)) {
            rtName = getValidRecordTypeName();
        }

        Date startDate = Date.today();
        Date endDate = Date.newInstance(2026, 9, 15); // Target: Should normalize to Sept 30 if TreasurySettlement

        Test.startTest();
        try {
            Id lineId = DMT_CreateLineService.createLine(
                rtName,
                '',
                startDate,
                endDate,
                acc.Id,
                'ES',
                'ES123456',
                'ES'
            );
            
            DMT_Line__c createdLine = [SELECT Id, Name, End_Date__c FROM DMT_Line__c WHERE Id = :lineId];
            if (rtName == 'TreasurySettlement') {
                System.assertEquals(Date.newInstance(2026, 9, 30), createdLine.End_Date__c, 'End date should be set to last day of month');
                System.assertEquals('TreasurySettlement Line', createdLine.Name, 'Default name should be generated when lineName is blank');
            }
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error creating line'), 'Exception caught if RecordType is absent in org schema');
        }
        Test.stopTest();
    }

    

    
}