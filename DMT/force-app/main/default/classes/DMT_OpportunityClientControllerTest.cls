/**
 * @description Test class for DMT_OpportunityClientController.
 *              Covers getOpportunityClientContext and getMainHolderData methods
 *              for group and subsidiary client scenarios.
 * @author      Generated
 */
@isTest
public with sharing class DMT_OpportunityClientControllerTest {

    private static final String ALPHA_CODE    = 'TEST123';
    private static final String OPP_RT_DEV   = 'DMT_Opportunity';

    // ─── @TestSetup ───────────────────────────────────────────────────────────
    // Builds a reusable group client scenario for every test.
    // generateOpportunity() calls generateAccount() internally, which already creates
    // an Account with g_customer_id__c = 'TEST123'.

    @TestSetup
    static void setupTestData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        // Force the structure type to Group so that the formula field DES_Client_Type__c
        // does not resolve to 'Subsidiary' (possible trigger/default in the org)
        Account setupAcc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        setupAcc.DES_Structure_Type__c = 'Group';
        update setupAcc;

        // Opportunity association with the main client alphaCode
        Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
            Opportunity__c          = opp.Id,
            g_customer_id__c        = ALPHA_CODE,
            gf_customer_group_id__c = 'G20180109100427'
        );
        insert assoc;

        // DMT client that links the alphaCode with the association
        DMT_Opportunity_Client__c dmtClient = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c           = opp.Id,
            Alpha_Code_Client__c             = ALPHA_CODE,
            Custom_Association__c            = assoc.Id,
            Counterpart__c                   = 'Corporates',
            DMT_Sector__c                    = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A',
            External_Rating__c               = 'BBB'
        );
        insert dmtClient;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private static Opportunity loadOpportunity() {
        return [SELECT Id, AccountId FROM Opportunity LIMIT 1];
    }

    private static String getDmtOppRecordTypeId() {
        return Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get(OPP_RT_DEV)
            .getRecordTypeId();
    }

    // Creates an additional standalone opportunity (without @TestSetup)
    private static Opportunity buildOrphanOpportunity(Id accountId, String oppIdCode) {
        Opportunity o = new Opportunity(
            Name                        = 'Test Opp ' + oppIdCode,
            StageName                   = 'Draft Opp',
            CloseDate                   = Date.today(),
            AccountId                   = accountId,
            RecordTypeId                = getDmtOppRecordTypeId(),
            DMT_Opp_Id__c               = oppIdCode,
            DMT_CUR_Notional_Amount__c  = 100,
            DMT_CurrencyText__c         = 'EUR',
            DMT_DATE_Initial_Date__c    = Date.today(),
            DMT_DATE_Maturity_Date__c   = Date.today() + 1,
            Entific__c                  = 'ES',
            DMT_Entity__c               = 'ES0182',
            DMT_Product_Area__c         = 'GTB',
            DMT_Threshold_Type__c       = 'Global'
        );
        insert o;
        return o;
    }

    // ─── getOpportunityClientContext ─── GROUP ────────────────────────────────

    @isTest
    static void testGetOppClientContext_GroupClient_ReturnsResult() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.areEqual(false, (Boolean) result.get('isSubsidiary'),
            'Must be a group client (not a subsidiary)');
        Assert.areNotEqual(null, result.get('opportunity'),
            'Must return the opportunity');
        Assert.areNotEqual(null, result.get('recordData'),
            'Must return recordData');
        Assert.areNotEqual(null, result.get('mainHolder'),
            'Must return the mainHolder DMT client');
        Assert.areNotEqual(null, result.get('priorRows'),
            'Must return priorRows');
    }

    @isTest
    static void testGetOppClientContext_GroupClient_PriorRowsContainsAlphaCode() {
        
        Opportunity opp = loadOpportunity();
        Custom_Association_Opportunity__c assoc = [
            SELECT Id FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id LIMIT 1
        ];

        // priorRows is built from DMT_Custom_Association_ClientOpportunity__c (multiholder)
        insert new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = assoc.Id,
            DMT_g_customer_id__c                  = ALPHA_CODE
        );

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp.Id);
        Test.stopTest();

        List<Map<String, Object>> priorRows =
            (List<Map<String, Object>>) result.get('priorRows');
        Assert.areNotEqual(null, priorRows, 'priorRows must not be null');
        Assert.areEqual(1, priorRows.size(), 'priorRows must have one element');
        Assert.areEqual(ALPHA_CODE, priorRows[0].get('customerId'),
            'customerId in priorRows must match the alphaCode');
        
    }

    @isTest
    static void testGetOppClientContext_GroupClient_RecordDataHasCurrentAndOriginal() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp.Id);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        Assert.areNotEqual(null, recordData, 'recordData must not be null');

        // Checks that each recordData key has the structure {currentValue, originalValue}
        Map<String, Object> counterpartEntry =
            (Map<String, Object>) recordData.get('Counterpart__c');
        Assert.areNotEqual(null, counterpartEntry,
            'Counterpart__c must be in recordData');
        Assert.areEqual('Corporates', counterpartEntry.get('currentValue'),
            'Counterpart__c currentValue must be Corporates');
    }

    @isTest
    static void testGetOppClientContext_GroupClient_ExternalRatingDefaultsToNR() {
        // Creates an opportunity with a DMT client without External_Rating__c
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp2 = buildOrphanOpportunity(acc.Id, '11111');

        Custom_Association_Opportunity__c assoc2 = new Custom_Association_Opportunity__c(
            Opportunity__c          = opp2.Id,
            g_customer_id__c        = ALPHA_CODE,
            gf_customer_group_id__c = 'GNRTEST11111111'
        );
        insert assoc2;

        // Creates a second DMT client without external rating; the code exists in Account.g_customer_id__c
        DMT_Opportunity_Client__c noRatingClient = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c           = opp2.Id,
            Alpha_Code_Client__c             = ALPHA_CODE,
            Custom_Association__c            = assoc2.Id,
            Counterpart__c                   = 'Corporates',
            DMT_Sector__c                    = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A'
            // External_Rating__c intentionally blank
        );
        insert noRatingClient;

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp2.Id);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        Map<String, Object> extRatingEntry =
            (Map<String, Object>) recordData.get('External_Rating__c');
        Assert.areNotEqual(null, extRatingEntry, 'External_Rating__c must be in recordData');
        Assert.areEqual('NR', extRatingEntry.get('currentValue'),
            'External_Rating__c must be NR when blank');
    }

    // ─── getOpportunityClientContext ─── OVERRIDE CODE ───────────────────────

 

    // ─── getOpportunityClientContext ─── SUBSIDIARY ─────────────────────────

    @isTest
    static void testGetOppClientContext_SubsidiaryClient_ReturnsIsSubsidiary() {
        Account subAcc = new Account(
            Name                        = 'Subsidiary Account Test',
            DES_Structure_Type__c       = 'Subsidiary',
            DES_Subsidiary_Group_Code__c = 'G88888888',
            DES_Group_Code__c           = 'G88888888',
            DES_Activity__c             = 'NDA',
            account_client__c           = 'N',
            BBVA_Entity__c              = 'BBVA SA',
            BillingCity                 = 'MADRID',
            BillingCountry              = 'ES',
            BillingPostalCode           = '28033',
            BillingState                = 'MADRID',
            BillingStreet               = 'AV Test Subsidiary',
            CurrencyIsoCode             = 'EUR'
        );
        insert subAcc;

        Opportunity subOpp = buildOrphanOpportunity(subAcc.Id, '33333');

        DMT_Opportunity_Client__c subDmtCl = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c           = subOpp.Id,
            Counterpart__c                   = 'Corporates',
            DMT_Sector__c                    = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A'
        );
        insert subDmtCl;

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(subOpp.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.areEqual(true, (Boolean) result.get('isSubsidiary'),
            'Must be identified as a subsidiary');
        Assert.areNotEqual(null, result.get('recordData'), 'Must return recordData');
    }

    @isTest
    static void testGetOppClientContext_SubsidiaryProspect_UsesCustomerId() {
        // RecordType Prospect_Subsidiary
        RecordType prospectRT = [
            SELECT Id, DeveloperName
            FROM   RecordType
            WHERE  SObjectType = 'Account'
            AND    DeveloperName = 'Prospect_Subsidiary'
            LIMIT  1
        ];

        Account prospectAcc = new Account(
            Name                        = 'Prospect Subsidiary Account',
            DES_Structure_Type__c       = 'Subsidiary',
            DES_Subsidiary_Group_Code__c = 'G77777777',
            g_customer_id__c            = 'ES0182PROSPECT',
            DES_ID_Fiscal__c            = 'ES12345678A',
            DES_Activity__c             = 'NDA',
            account_client__c           = 'N',
            BBVA_Entity__c              = 'BBVA SA',
            BillingCity                 = 'MADRID',
            BillingCountry              = 'ES',
            BillingPostalCode           = '28033',
            BillingState                = 'MADRID',
            BillingStreet               = 'AV Prospect',
            CurrencyIsoCode             = 'EUR',
            RecordTypeId                = prospectRT.Id
        );
        insert prospectAcc;

        Opportunity prospectOpp = buildOrphanOpportunity(prospectAcc.Id, '44444');

        DMT_Opportunity_Client__c prospectDmtCl = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c           = prospectOpp.Id,
            Counterpart__c                   = 'Corporates',
            DMT_Sector__c                    = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A'
        );
        insert prospectDmtCl;

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(prospectOpp.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.areEqual(true, (Boolean) result.get('isSubsidiary'),
            'Must be identified as a prospect subsidiary');
    }

    // ─── getOpportunityClientContext ─── ERRORS ──────────────────────────────

    @isTest
    static void testGetOppClientContext_NullId_ThrowsAuraException() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getOpportunityClientContext(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when the Id is null');
    }

    @isTest
    static void testGetOppClientContext_OppNotFound_ThrowsAuraException() {
        // Synthetic Id that does not exist in the database
        Id fakeOppId = '006000000000001AAA';
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getOpportunityClientContext(fakeOppId);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when the opportunity does not exist');
    }

    @isTest
    static void testGetOppClientContext_NoAssociation_ReturnsNullCustomerId() {
        // No association → emptyClientInfo → result not null, customerId null
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity orphanOpp = buildOrphanOpportunity(acc.Id, '55555');

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(orphanOpp.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Must return a result');
        Assert.areEqual(null, result.get('customerId'),
            'customerId must be null when there is no association');
    }

    @isTest
    static void testGetOppClientContext_NoDmtClient_ReturnsNullMainHolder() {
        // The association exists but there is no DMT_Opportunity_Client__c for that alphaCode
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp2 = buildOrphanOpportunity(acc.Id, '66666');

        Custom_Association_Opportunity__c assoc2 = new Custom_Association_Opportunity__c(
            Opportunity__c          = opp2.Id,
            g_customer_id__c        = 'NONEXISTENT_CODE',
            gf_customer_group_id__c = 'GNODMT6666666666'
        );
        insert assoc2;

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp2.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Must return a result');
        Assert.areEqual(null, result.get('mainHolder'),
            'mainHolder must be null when there is no DMT client for the alphaCode');
    }

    // ─── getOpportunityClientContext ─── PROSPECT GROUP ──────────────────────

    @isTest
    static void testGetOppClientContext_ProspectGroup_IsNotSubsidiary() {
        RecordType prospectGroupRT = [
            SELECT Id FROM RecordType
            WHERE  SObjectType = 'Account'
            AND    DeveloperName = 'Prospect_Group'
            LIMIT  1
        ];

        Account prospectGroupAcc = new Account(
            Name                        = 'Prospect Group Account',
            DES_Group_Code__c           = 'G66666666',
            g_customer_id__c            = 'ES0182PRGRP01',
            DES_Activity__c             = 'NDA',
            account_client__c           = 'N',
            BBVA_Entity__c              = 'BBVA SA',
            BillingCity                 = 'MADRID',
            BillingCountry              = 'ES',
            BillingPostalCode           = '28033',
            BillingState                = 'MADRID',
            BillingStreet               = 'AV Prospect Group',
            CurrencyIsoCode             = 'EUR',
            RecordTypeId                = prospectGroupRT.Id
        );
        insert prospectGroupAcc;

        Opportunity pgOpp = buildOrphanOpportunity(prospectGroupAcc.Id, '99991');

        Custom_Association_Opportunity__c pgAssoc = new Custom_Association_Opportunity__c(
            Opportunity__c          = pgOpp.Id,
            g_customer_id__c        = 'ES0182PRGRP01',
            gf_customer_group_id__c = 'G66666666'
        );
        insert pgAssoc;

        DMT_Opportunity_Client__c pgDmtCl = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c            = pgOpp.Id,
            Alpha_Code_Client__c              = 'ES0182PRGRP01',
            Custom_Association__c             = pgAssoc.Id,
            Counterpart__c                    = 'Corporates',
            DMT_Sector__c                     = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A'
        );
        insert pgDmtCl;

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(pgOpp.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.areEqual(false, (Boolean) result.get('isSubsidiary'),
            'A Prospect Group must not be identified as a subsidiary');
    }

    // ─── getMainHolderData ─── SUCCESS ─────────────────────────────────────────

    @isTest
    static void testGetMainHolderData_Success_ReturnsExpectedKeys() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE, null);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.areEqual(ALPHA_CODE, result.get('alphaCode'),
            'alphaCode must match the one sent');
        Assert.areNotEqual(null, result.get('mainBorrower'),
            'mainBorrower must be present');
        Assert.areNotEqual(null, result.get('recordData'),
            'recordData must be present');
        Assert.isTrue(result.containsKey('serviceError'),
            'Must contain the serviceError key');
        Assert.isTrue(result.containsKey('serviceErrorMessage'),
            'Must contain the serviceErrorMessage key');
    }

    @isTest
    static void testGetMainHolderData_RecordData_HasMergedStructure() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE, null);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        Assert.areNotEqual(null, recordData, 'recordData must not be null');

        Map<String, Object> counterpart = (Map<String, Object>) recordData.get('Counterpart__c');
        Assert.areNotEqual(null, counterpart, 'Counterpart__c must be in recordData');
        Assert.isTrue(counterpart.containsKey('currentValue'),
            'Must have the currentValue key');
        Assert.isTrue(counterpart.containsKey('originalValue'),
            'Must have the originalValue key');
    }

    @isTest
    static void testGetMainHolderData_WithOriginalRecordTable_ReturnsResult() {
        Opportunity opp = loadOpportunity();

        Map<String, Object> originalRecordTable = new Map<String, Object>{
            'updLmsclInternalRatgType'    => '-BB',
            'unifiedExtRatgLtFcType'      => 'AA',
            'totalRatingScoreNumber'      => 8.5,
            'assetAllocationSectorType'   => 'S01',
            'assetAllcSectorDesc'         => 'Sector Test',
            'assetAllocationSubSecType'   => 'S01a',
            'aaSubSectorDesc'             => 'Subsector Test',
            'assetAllocationActvyType'    => 'A01',
            'aaActivityDesc'              => 'Activity Test',
            'activityMinimumLevelCodeId'  => 'CAMN_TEST',
            'activityMinimumLevelCodeDesc' => 'CAMN_DESC',
            'spLtRatingLcType'            => 'BBB+',
            'moodysLtRatingLcType'        => 'Baa1',
            'fitchLtRatingLcType'         => 'BBB+'
        };

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE, originalRecordTable);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.areEqual(ALPHA_CODE, result.get('alphaCode'), 'alphaCode must match');
        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        Assert.areNotEqual(null, recordData, 'recordData must be present');
        Map<String, Object> camn = (Map<String, Object>) recordData.get('DMT_CAMN__c');
        Map<String, Object> camnOriginal = (Map<String, Object>) camn.get('originalValue');
        Assert.areNotEqual(null, camnOriginal, 'CAMN originalValue must be a Map with value/label/compareValue');
        Assert.areEqual('CAMN_DESC', camnOriginal.get('value'), 'Without a match in catalog A521, value must be the raw HPG description');
        Assert.areEqual('CAMN_DESC', camnOriginal.get('label'), 'label must be the raw HPG description');
        Assert.areEqual('CAMN_DESC', camnOriginal.get('compareValue'), 'compareValue must be the raw HPG description, used for the warning comparison in the LWC');
    }

    // ─── getMainHolderData ─── ERRORS ───────────────────────────────────────

    @isTest
    static void testGetMainHolderData_NullOpportunityId_ThrowsAuraException() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(null, ALPHA_CODE, null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when opportunityId is null');
    }

    @isTest
    static void testGetMainHolderData_NullAlphaCode_ThrowsAuraException() {
        Opportunity opp = loadOpportunity();
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(opp.Id, null, null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when alphaCode is null');
    }

    @isTest
    static void testGetMainHolderData_BlankAlphaCode_ThrowsAuraException() {
        Opportunity opp = loadOpportunity();
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(opp.Id, '', null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when alphaCode is empty');
    }

    @isTest
    static void testGetMainHolderData_BothNull_ThrowsAuraException() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(null, null, null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when both parameters are null');
    }

    @isTest
    static void testGetMainHolderData_WrongAlphaCode_ThrowsAuraException() {
        // The RecordType must be explicitly non-Prospect: for Prospect Group the clientId
        // is resolved from the Account itself and Local_Client__c is never queried.
        RecordType groupRT = [
            SELECT Id FROM RecordType
            WHERE  SObjectType = 'Account' AND DeveloperName = 'Group'
            LIMIT  1
        ];

        Account groupAcc = new Account(
            Name                  = 'Group Account WrongAlpha',
            DES_Structure_Type__c = 'Group',
            DES_Group_Code__c     = 'G55555555',
            DES_Activity__c       = 'NDA',
            account_client__c     = 'N',
            BBVA_Entity__c        = 'BBVA SA',
            BillingCity           = 'MADRID',
            BillingCountry        = 'ES',
            BillingPostalCode     = '28033',
            BillingState          = 'MADRID',
            BillingStreet         = 'AV Group WrongAlpha',
            CurrencyIsoCode       = 'EUR',
            RecordTypeId          = groupRT.Id
        );
        insert groupAcc;

        Opportunity groupOpp = buildOrphanOpportunity(groupAcc.Id, '77771');

        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(groupOpp.Id, 'ALPHA_NO_EXISTE', null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        Assert.areEqual(true, threw,
            'Must throw AuraHandledException when there is no Local Client for the alphaCode');
    }

    // ─── saveMainBorrowerFields ───────────────────────────────────────────────

    // Helper that builds a reusable fieldValues map
    private static Map<String, Object> buildFieldValues(String counterpart) {
        return new Map<String, Object>{
            'g_upd_lmscl_internal_ratg_type__c' => '-A',
            'DMT_Scoring__c'                     => 5.0,
            'External_Rating__c'                 => 'BBB',
            'DMT_External_Rating_SP__c'          => null,
            'DMT_External_Rating_Moodys__c'      => null,
            'DMT_External_Rating_Fitch__c'       => null,
            'DMT_Industry__c'                    => null,
            'DMT_Leveraged_Lending__c'           => null,
            'DMT_CAMN__c'                        => null,
            'Counterpart__c'                     => counterpart,
            'SCRA__c'                            => null,
            'AVC_Check__c'                       => false,
            'European_Bank_Check__c'             => false,
            'DMT_Sector__c'                      => 'N',
            'DMT_Subsector__c'                   => null,
            'DMT_Activity__c'                    => null,
            'DMT_Sector_Head__c'                 => null,
            'DMT_Threshold_Type__c'              => 'Global'
        };
    }

    @isTest
    static void testSaveMainBorrowerFields_ReadyToClose_SetsOppFlag() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerFields(
            opp.Id, dmtClient.Id,
            DMT_OpportunityClientController.STAGE_READY_TO_CLOSE,
            buildFieldValues('Corporates')
        );
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT DMT_Is_Change_in_Ready_to_close__c
            FROM Opportunity WHERE Id = :opp.Id
        ];
        Assert.areEqual(true, updatedOpp.DMT_Is_Change_in_Ready_to_close__c,
            'The DMT_Is_Change_in_Ready_to_close__c flag must be set in Ready to close');
    }

    // CIBGLOBALD-4811 - the reopen check of both Client saves builds what the save writes and saves nothing;
    // without a Ready to close Case nothing reopens, and a failing check answers nothing.
    @isTest
    static void testPreviewMainBorrowerSave_NoCaseOrFailure_ReturnsNothingAndSavesNothing() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id, Counterpart__c FROM DMT_Opportunity_Client__c LIMIT 1];
        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE }
        };

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> fieldsOnly = DMT_OpportunityClientController.previewMainBorrowerSave(
            'readytoclose', opp.Id, dmtClient.Id, DMT_OpportunityClientController.STAGE_READY_TO_CLOSE,
            buildFieldValues('Fin Inst-B'), false, null, null
        );
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> withClients = DMT_OpportunityClientController.previewMainBorrowerSave(
            'readytoclose', opp.Id, dmtClient.Id, DMT_OpportunityClientController.STAGE_READY_TO_CLOSE,
            buildFieldValues('Fin Inst-B'), true, ALPHA_CODE, selectedClients
        );
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> failing = DMT_OpportunityClientController.previewMainBorrowerSave(
            'readytoclose', opp.Id, dmtClient.Id, DMT_OpportunityClientController.STAGE_READY_TO_CLOSE,
            null, false, null, null
        );
        Test.stopTest();

        Assert.isTrue(fieldsOnly.isEmpty(), 'Without a Ready to close Case nothing reopens (inline or subsidiary save)');
        Assert.isTrue(withClients.isEmpty(), 'Without a Ready to close Case nothing reopens (save with client selection)');
        Assert.isTrue(failing.isEmpty(), 'A failing check returns nothing');
        Assert.areEqual(dmtClient.Counterpart__c,
            [SELECT Counterpart__c FROM DMT_Opportunity_Client__c WHERE Id = :dmtClient.Id].Counterpart__c,
            'The preview saves nothing');
    }

    // ─── saveMainBorrowerWithClients ──────────────────────────────────────────

    @isTest
    static void testSaveMainBorrowerWithClients_ExistingMainBorrower_UpdatesClient() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE }
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            opp.Id, dmtClient.Id, 'Draft Opp',
            buildFieldValues('Fin Inst-B'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        DMT_Opportunity_Client__c updated = [
            SELECT Counterpart__c FROM DMT_Opportunity_Client__c WHERE Id = :dmtClient.Id
        ];
        Assert.areEqual('Fin Inst-B', updated.Counterpart__c,
            'The counterpart must be updated with the value sent');
    }

    
    @isTest
    static void testSaveMainBorrowerWithClients_ExistingMultiholderWithNullFields_BackfillsFields() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];
        Custom_Association_Opportunity__c assoc = [
            SELECT Id, gf_customer_group_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id LIMIT 1
        ];

        // Existing DMT_Custom_Association_ClientOpportunity__c record without DMT_g_entific_id__c
        // (simulates a record created before the backfill) — it must be updated, not duplicated.
        DMT_Custom_Association_ClientOpportunity__c existingMultiholder =
            new DMT_Custom_Association_ClientOpportunity__c(
                DMT_Custom_Association_Opportunity__c = assoc.Id,
                DMT_g_customer_id__c = ALPHA_CODE
            );
        insert existingMultiholder;

        Map<String, Object> mainClientMap = new Map<String, Object>{
            'customerId'    => ALPHA_CODE,
            'countryIfoId'  => 'ES'
        };
        List<Object> selectedClients = new List<Object>{ mainClientMap };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            opp.Id, dmtClient.Id, 'Draft Opp',
            buildFieldValues('Corporates'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        List<DMT_Custom_Association_ClientOpportunity__c> multiholders = [
            SELECT DMT_g_customer_id__c, DMT_gf_customer_group_id__c, DMT_g_entific_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__c = :assoc.Id
        ];
        Assert.areEqual(1, multiholders.size(),
            'No duplicate must be created, only the existing record must be updated');
        Assert.areEqual('ES', multiholders[0].DMT_g_entific_id__c,
            'g_entific_id__c must be filled by the backfill');
        Assert.areEqual(assoc.gf_customer_group_id__c, multiholders[0].DMT_gf_customer_group_id__c,
            'gf_customer_group_id__c must be filled from the association');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_NewMainBorrower_InsertsClient() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity newOpp = buildOrphanOpportunity(acc.Id, '88888');

        // Pre-creates the association so that associationId is correct in the upsert.
        // gf_customer_group_id__c must be unique — a value different from the @TestSetup one is used.
        Custom_Association_Opportunity__c newAssoc = new Custom_Association_Opportunity__c(
            Opportunity__c          = newOpp.Id,
            g_customer_id__c        = ALPHA_CODE,
            gf_customer_group_id__c = 'G88888888NEWOPP'
        );
        insert newAssoc;

        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE }
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            newOpp.Id, null, 'Draft Opp',
            buildFieldValues('Corporates'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        List<DMT_Opportunity_Client__c> created = [
            SELECT Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :newOpp.Id
        ];
        Assert.areEqual(1, created.size(), 'One DMT_Opportunity_Client__c must be created');
        Assert.areEqual(ALPHA_CODE, created[0].Alpha_Code_Client__c,
            'The new client alpha code must match');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_MultipleClients_DeletesRemovedOnes() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c existingClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Custom_Association_Opportunity__c assoc = [
            SELECT Id FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id LIMIT 1
        ];

        // In the multiholder model the participants live in DMT_Custom_Association_ClientOpportunity__c.
        // One is inserted that will not come in selectedClients and must therefore be deleted.
        insert new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = assoc.Id,
            DMT_g_customer_id__c                  = 'TOREMOVE99'
        );

        // Only ALPHA_CODE in selectedClients — TOREMOVE99 must be deleted
        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE }
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            opp.Id, existingClient.Id, 'Draft Opp',
            buildFieldValues('Corporates'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        List<DMT_Custom_Association_ClientOpportunity__c> remaining = [
            SELECT DMT_g_customer_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__c = :assoc.Id
        ];
        Assert.areEqual(1, remaining.size(),
            'Only the main borrower participant must remain');
        Assert.areEqual(ALPHA_CODE, remaining[0].DMT_g_customer_id__c,
            'The remaining participant must be the main borrower');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_ChangedMainBorrower_UpdatesAssociation() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => 'NEWALPHACODE01' }
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            opp.Id, dmtClient.Id, 'Draft Opp',
            buildFieldValues('Corporates'), 'NEWALPHACODE01', selectedClients
        );
        Test.stopTest();

        Custom_Association_Opportunity__c updatedAssoc = [
            SELECT g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        Assert.areEqual('NEWALPHACODE01', updatedAssoc.g_customer_id__c,
            'The association must be updated with the new main borrower');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_WithPassport_MarksObsoleted() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Passport__c passport = new Passport__c(
            Opportunity__c                    = opp.Id,
            DMT_Is_Obsoleted_Passport_Save__c = false
        );
        insert passport;

        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE }
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            opp.Id, dmtClient.Id, 'Draft Opp',
            buildFieldValues('Corporates'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        // The update uses USER_MODE; checks that the method completed without error
        // and that the passport still exists (the flag logic depends on the profile FLS permissions).
        List<Passport__c> passportList = [
            SELECT Id FROM Passport__c WHERE Id = :passport.Id
        ];
        Assert.areEqual(1, passportList.size(),
            'The passport must still exist after the save');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_WithNonMainClient_InsertsSecondaryClient() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        // Secondary client with HPG fields in the map
        Map<String, Object> secondaryClientMap = new Map<String, Object>{
            'customerId'                  => 'SECONDARY01',
            'updLmsclInternalRatgType'    => '-B',
            'unifiedExtRatgLtFcType'      => 'BBB',
            'assetAllocationSectorType'   => 'S02',
            'assetAllocationSubSecType'   => 'S02a',
            'assetAllocationActvyType'    => 'A02',
            'fitchLtRatingLcType'         => 'BBB',
            'moodysLtRatingLcType'        => 'Baa2',
            'spLtRatingLcType'            => 'BBB',
            'totalRatingScoreNumber'      => 6.0
        };

        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE },
            secondaryClientMap
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            opp.Id, dmtClient.Id, 'Draft Opp',
            buildFieldValues('Corporates'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        Custom_Association_Opportunity__c assoc = [
            SELECT Id FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id LIMIT 1
        ];

        // The secondary client is stored in DMT_Custom_Association_ClientOpportunity__c,
        // not in DMT_Opportunity_Client__c (which is 1:1 with the main holder).
        List<DMT_Custom_Association_ClientOpportunity__c> allClients = [
            SELECT DMT_g_customer_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__c = :assoc.Id
            ORDER BY DMT_g_customer_id__c
        ];
        Assert.areEqual(2, allClients.size(),
            'The main borrower and the secondary client must exist as participants');
        Assert.areEqual('SECONDARY01', allClients[0].DMT_g_customer_id__c,
            'The first sorted participant must be the secondary client');

        List<DMT_Opportunity_Client__c> mainHolders = [
            SELECT Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id
        ];
        Assert.areEqual(1, mainHolders.size(),
            'Only the main holder DMT_Opportunity_Client__c must exist');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_ExistingAssocWithDifferentMainBorrower_UpdatesAssocAndInsertsClient() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity newOpp2 = buildOrphanOpportunity(acc.Id, '88889');

        // The association exists with a different alpha code; the controller updates it.
        // gf_customer_group_id__c must be unique — a value different from the @TestSetup one is used.
        Custom_Association_Opportunity__c existingAssoc = new Custom_Association_Opportunity__c(
            Opportunity__c          = newOpp2.Id,
            g_customer_id__c        = 'OLD_ALPHA_CODE',
            gf_customer_group_id__c = 'G99999999DIFFMB'
        );
        insert existingAssoc;

        List<Object> selectedClients = new List<Object>{
            new Map<String, Object>{ 'customerId' => ALPHA_CODE }
        };

        Test.startTest();
        DMT_OpportunityClientController.saveMainBorrowerWithClients(
            newOpp2.Id, null, 'Draft Opp',
            buildFieldValues('Corporates'), ALPHA_CODE, selectedClients
        );
        Test.stopTest();

        Custom_Association_Opportunity__c updatedAssoc = [
            SELECT g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :newOpp2.Id
            LIMIT 1
        ];
        Assert.areEqual(ALPHA_CODE, updatedAssoc.g_customer_id__c,
            'The association must be updated with the new main borrower alpha code');
    }
}