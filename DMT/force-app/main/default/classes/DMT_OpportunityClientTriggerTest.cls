@isTest
public with sharing class DMT_OpportunityClientTriggerTest {

    @TestSetup
    static void makeData() {
        // Bypass to avoid heavy synchronous triggers during setup
        TriggerBypass.setBypass();

        // 1. Create Opportunity
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Client Sync Opp',
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId
        );
        insert opp;

        // 2. Create X-Sells FIRST (Simulating the async job finishing before the Client record is made)
        List<DMT_X_Sell__c> xsells = new List<DMT_X_Sell__c>{
            new DMT_X_Sell__c(Opportunity__c = opp.Id, XSELL_Value_PY__c = 150, XSELL_Value_CY__c = 250),
            new DMT_X_Sell__c(Opportunity__c = opp.Id, XSELL_Value_PY__c = 50, XSELL_Value_CY__c = 50)
        };
        insert xsells;
        
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testBeforeInsert_SyncXSellTotals() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Client Sync Opp' LIMIT 1];
        
        Test.startTest();
        
        // Insert the Client record. The before insert trigger should query the 2 existing X-Sells and sum them (150+50 = 200).
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert client;
        
        Test.stopTest();

        // Assert that the fields were populated correctly BEFORE the record was saved
        DMT_Opportunity_Client__c savedClient = [
            SELECT Past2_FY_Child_X_Sell_amount__c, Past_FY_Child_X_Sell_amount__c, Current_FY_Child_X_Sell_amount__c, Next_FY_Child_X_Sell_amount__c
            FROM DMT_Opportunity_Client__c 
            WHERE Id = :client.Id
        ];
        
        Assert.areEqual(200, savedClient.Past2_FY_Child_X_Sell_amount__c, 'PY total should be synced on insert');
        Assert.areEqual(300, savedClient.Past_FY_Child_X_Sell_amount__c, 'CY total should be synced on insert');
        Assert.areEqual(0, savedClient.Current_FY_Child_X_Sell_amount__c, 'NY total should default to 0 if null');
        Assert.areEqual(0, savedClient.Next_FY_Child_X_Sell_amount__c, 'NY1 total should default to 0 if null');
    }
    
    @isTest
    static void testBeforeInsert_NoXSells() {
        // Create a new Opp with NO X-Sells
        TriggerBypass.setBypass();
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity oppEmpty = new Opportunity(
            Name = 'Test Empty Opp',
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId
        );
        insert oppEmpty;
        TriggerBypass.removeBypass();
        
        Test.startTest();
        
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = oppEmpty.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert client;
        
        Test.stopTest();
        
        DMT_Opportunity_Client__c savedClient = [
            SELECT Past2_FY_Child_X_Sell_amount__c
            FROM DMT_Opportunity_Client__c 
            WHERE Id = :client.Id
        ];
        
        // If there are no X-Sells, the values should remain exactly what we inserted (null)
        Assert.areEqual(null, savedClient.Past2_FY_Child_X_Sell_amount__c, 'PY total should remain null if no X-Sells exist');
    }

    // CIBGLOBALD-3981 - infer Client RORC NBC Last FY (%), Client RORC NBC YTD (%) and Client RWA
    // Last 12m from the Account's group on Opportunity Client creation.
    private static Account createTestAccount(String accName, String structureType) {
        Account acc = new Account();
        acc.Name = accName;
        acc.account_client__c = 'N';
        acc.Advising__c = false;
        acc.BBVA_Entity__c = 'BBVA SA';
        acc.BillingCity = 'MADRID';
        acc.BillingCountry = 'ES';
        acc.BillingPostalCode = '28033';
        acc.BillingState = 'MADRID';
        acc.BillingStreet = 'AV GRAN Test DE HORTALEZA 0321';
        acc.CurrencyIsoCode = 'EUR';
        acc.cust_first_income_country_amount__c = 4508815;
        acc.cust_first_income_country_name__c = 'ESPAÑA (2222815.0 EUR)';
        acc.DES_Activity__c = 'NDA';
        acc.CIB_Commercial_Prospect__c = 'Commercial';
        acc.Revenues_Last_Year_number__c = 13;
        acc.DES_Structure_Type__c = structureType;
        return acc;
    }

    @isTest
    static void testBeforeInsert_InfersFromParentGroupForSubsidiary() {
        Account groupAcc = createTestAccount('Test Group CIBGLOBALD-3981', 'Group');
        groupAcc.DES_RORC_NBC__c = 111;
        groupAcc.DES_RORC_YTD__c = 22.5;
        groupAcc.DES_RWA_Last12m__c = 333;
        groupAcc.DES_BDI_Last12m__c = 444;
        insert groupAcc;

        Account subAcc = createTestAccount('Test Subsidiary CIBGLOBALD-3981', 'Subsidiary');
        subAcc.DES_Main_Parent__c = groupAcc.Id;
        insert subAcc;

        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Infer Subsidiary Opp',
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId,
            AccountId = subAcc.Id
        );
        insert opp;

        Test.startTest();
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert client;
        Test.stopTest();

        DMT_Opportunity_Client__c savedClient = [
            SELECT DMT_Clients_Global_RORC_CIB_Past_FY__c, DMT_Client_RORC_YTD__c, DMT_Client_RWA__c, DMT_Client_Net_Incomes__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :client.Id
        ];
        Assert.areEqual(111, savedClient.DMT_Clients_Global_RORC_CIB_Past_FY__c, 'RORC NBC Last FY should be inferred from the parent Group account, not the Subsidiary');
        Assert.areEqual(22.5, savedClient.DMT_Client_RORC_YTD__c, 'RORC YTD should be inferred from the parent Group account');
        Assert.areEqual(333, savedClient.DMT_Client_RWA__c, 'RWA should be inferred from the parent Group account');
        Assert.areEqual(444, savedClient.DMT_Client_Net_Incomes__c, 'BDI Last12m (Net Incomes) should be inferred from the parent Group account');
    }

    @isTest
    static void testBeforeInsert_InfersFromAccountItselfWhenAlreadyGroup() {
        Account groupAcc = createTestAccount('Test Already Group CIBGLOBALD-3981', 'Group');
        groupAcc.DES_RORC_NBC__c = 44;
        groupAcc.DES_RORC_YTD__c = 5.5;
        groupAcc.DES_RWA_Last12m__c = 66;
        groupAcc.DES_BDI_Last12m__c = 77;
        insert groupAcc;

        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Infer Group Opp',
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId,
            AccountId = groupAcc.Id
        );
        insert opp;

        Test.startTest();
        // Pre-populate one of the four fields - it must survive untouched (never overwritten).
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N',
            DMT_Client_RWA__c = 999
        );
        insert client;
        Test.stopTest();

        DMT_Opportunity_Client__c savedClient = [
            SELECT DMT_Clients_Global_RORC_CIB_Past_FY__c, DMT_Client_RORC_YTD__c, DMT_Client_RWA__c, DMT_Client_Net_Incomes__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :client.Id
        ];
        Assert.areEqual(44, savedClient.DMT_Clients_Global_RORC_CIB_Past_FY__c, 'RORC NBC Last FY should be inferred directly from the Account when it is already a Group');
        Assert.areEqual(5.5, savedClient.DMT_Client_RORC_YTD__c, 'RORC YTD should be inferred directly from the Account when it is already a Group');
        Assert.areEqual(999, savedClient.DMT_Client_RWA__c, 'RWA already set by the user must not be overwritten by the inferred value');
        Assert.areEqual(77, savedClient.DMT_Client_Net_Incomes__c, 'BDI Last12m (Net Incomes) should be inferred directly from the Account when it is already a Group');
    }

    @isTest
    static void testBeforeInsert_NoAccount_DoesNotThrow() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Client Sync Opp' LIMIT 1];

        Test.startTest();
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert client;
        Test.stopTest();

        DMT_Opportunity_Client__c savedClient = [
            SELECT DMT_Clients_Global_RORC_CIB_Past_FY__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :client.Id
        ];
        Assert.areEqual(null, savedClient.DMT_Clients_Global_RORC_CIB_Past_FY__c, 'No Account on the Opportunity means nothing to infer from - field stays null, no exception');
    }
}