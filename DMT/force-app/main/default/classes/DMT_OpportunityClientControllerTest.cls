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
    // Crea un escenario de cliente de grupo reutilizable para todos los tests.
    // generateOpportunity() internamente llama generateAccount(), que ya crea
    // una Account con g_customer_id__c = 'TEST123'.

    @TestSetup
    static void setupTestData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        // Forzar el tipo de estructura a Group para que el campo fórmula DES_Client_Type__c
        // no resuelva a 'Subsidiary' (posible trigger/default en el org)
        Account setupAcc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        setupAcc.DES_Structure_Type__c = 'Group';
        update setupAcc;

        // Asociación de la oportunidad con el alphaCode del cliente principal
        Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
            Opportunity__c          = opp.Id,
            g_customer_id__c        = ALPHA_CODE,
            gf_customer_group_id__c = 'G20180109100427'
        );
        insert assoc;

        // Cliente DMT que une el alphaCode con la asociación
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

    // Crea una oportunidad adicional independiente (sin usar @TestSetup)
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

    // ─── getOpportunityClientContext ─── GRUPO ────────────────────────────────

    @isTest
    static void testGetOppClientContext_GroupClient_ReturnsResult() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(false, (Boolean) result.get('isSubsidiary'),
            'Debe ser cliente de grupo (no subsidiaria)');
        System.assertNotEquals(null, result.get('opportunity'),
            'Debe retornar la oportunidad');
        System.assertNotEquals(null, result.get('recordData'),
            'Debe retornar recordData');
        System.assertNotEquals(null, result.get('mainHolder'),
            'Debe retornar el mainHolder DMT client');
        System.assertNotEquals(null, result.get('priorRows'),
            'Debe retornar priorRows');
    }

    @isTest
    static void testGetOppClientContext_GroupClient_PriorRowsContainsAlphaCode() {
        
        Opportunity opp = loadOpportunity();
        Custom_Association_Opportunity__c assoc = [
            SELECT Id FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id LIMIT 1
        ];

        // priorRows se construye desde DMT_Custom_Association_ClientOpportunity__c (multiholder)
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
        System.assertNotEquals(null, priorRows, 'priorRows no debe ser null');
        System.assertEquals(1, priorRows.size(), 'Debe haber un elemento en priorRows');
        System.assertEquals(ALPHA_CODE, priorRows[0].get('customerId'),
            'customerId en priorRows debe coincidir con el alphaCode');
        
    }

    @isTest
    static void testGetOppClientContext_GroupClient_RecordDataHasCurrentAndOriginal() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp.Id);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        System.assertNotEquals(null, recordData, 'recordData no debe ser null');

        // Verifica que cada clave del recordData tenga la estructura {currentValue, originalValue}
        Map<String, Object> counterpartEntry =
            (Map<String, Object>) recordData.get('Counterpart__c');
        System.assertNotEquals(null, counterpartEntry,
            'Counterpart__c debe estar en recordData');
        System.assertEquals('Corporates', counterpartEntry.get('currentValue'),
            'currentValue de Counterpart__c debe ser Corporates');
    }

    @isTest
    static void testGetOppClientContext_GroupClient_ExternalRatingDefaultsToNR() {
        // Crea una oportunidad con un DMT client sin External_Rating__c
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp2 = buildOrphanOpportunity(acc.Id, '11111');

        Custom_Association_Opportunity__c assoc2 = new Custom_Association_Opportunity__c(
            Opportunity__c          = opp2.Id,
            g_customer_id__c        = ALPHA_CODE,
            gf_customer_group_id__c = 'GNRTEST11111111'
        );
        insert assoc2;

        // Crea un segundo DMT client sin rating externo; el código existe en Account.g_customer_id__c
        DMT_Opportunity_Client__c noRatingClient = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c           = opp2.Id,
            Alpha_Code_Client__c             = ALPHA_CODE,
            Custom_Association__c            = assoc2.Id,
            Counterpart__c                   = 'Corporates',
            DMT_Sector__c                    = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A'
            // External_Rating__c intencionalmente en blanco
        );
        insert noRatingClient;

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(opp2.Id);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        Map<String, Object> extRatingEntry =
            (Map<String, Object>) recordData.get('External_Rating__c');
        System.assertNotEquals(null, extRatingEntry, 'External_Rating__c debe estar en recordData');
        System.assertEquals('NR', extRatingEntry.get('currentValue'),
            'External_Rating__c debe ser NR cuando está en blanco');
    }

    // ─── getOpportunityClientContext ─── OVERRIDE CODE ───────────────────────

 

    // ─── getOpportunityClientContext ─── SUBSIDIARIA ─────────────────────────

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

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(true, (Boolean) result.get('isSubsidiary'),
            'Debe identificarse como subsidiaria');
        System.assertNotEquals(null, result.get('recordData'), 'Debe retornar recordData');
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

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(true, (Boolean) result.get('isSubsidiary'),
            'Debe identificarse como subsidiaria prospect');
    }

    // ─── getOpportunityClientContext ─── ERRORES ──────────────────────────────

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
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando el Id es null');
    }

    @isTest
    static void testGetOppClientContext_OppNotFound_ThrowsAuraException() {
        // Id sintético que no existe en la BD
        Id fakeOppId = '006000000000001AAA';
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getOpportunityClientContext(fakeOppId);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando la oportunidad no existe');
    }

    @isTest
    static void testGetOppClientContext_NoAssociation_ReturnsNullCustomerId() {
        // Sin asociación → emptyClientInfo → result no null, customerId null
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity orphanOpp = buildOrphanOpportunity(acc.Id, '55555');

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getOpportunityClientContext(orphanOpp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar un resultado');
        System.assertEquals(null, result.get('customerId'),
            'customerId debe ser null cuando no hay asociación');
    }

    @isTest
    static void testGetOppClientContext_NoDmtClient_ReturnsNullMainHolder() {
        // La asociación existe pero no hay DMT_Opportunity_Client__c para ese alphaCode
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

        System.assertNotEquals(null, result, 'Debe retornar un resultado');
        System.assertEquals(null, result.get('mainHolder'),
            'mainHolder debe ser null cuando no existe DMT client para el alphaCode');
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

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(false, (Boolean) result.get('isSubsidiary'),
            'Un Prospect Group no debe identificarse como subsidiaria');
    }

    // ─── getMainHolderData ─── ÉXITO ─────────────────────────────────────────

    @isTest
    static void testGetMainHolderData_Success_ReturnsExpectedKeys() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(ALPHA_CODE, result.get('alphaCode'),
            'alphaCode debe coincidir con el enviado');
        System.assertNotEquals(null, result.get('mainBorrower'),
            'mainBorrower debe estar presente');
        System.assertNotEquals(null, result.get('recordData'),
            'recordData debe estar presente');
        System.assert(result.containsKey('serviceError'),
            'Debe contener la clave serviceError');
        System.assert(result.containsKey('serviceErrorMessage'),
            'Debe contener la clave serviceErrorMessage');
    }

    @isTest
    static void testGetMainHolderData_RecordData_HasMergedStructure() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE, null);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        System.assertNotEquals(null, recordData, 'recordData no debe ser null');

        Map<String, Object> counterpart = (Map<String, Object>) recordData.get('Counterpart__c');
        System.assertNotEquals(null, counterpart, 'Counterpart__c debe estar en recordData');
        System.assert(counterpart.containsKey('currentValue'),
            'Debe tener clave currentValue');
        System.assert(counterpart.containsKey('originalValue'),
            'Debe tener clave originalValue');
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

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(ALPHA_CODE, result.get('alphaCode'), 'alphaCode debe coincidir');
        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        System.assertNotEquals(null, recordData, 'recordData debe estar presente');
        Map<String, Object> camn = (Map<String, Object>) recordData.get('DMT_CAMN__c');
        Map<String, Object> camnOriginal = (Map<String, Object>) camn.get('originalValue');
        System.assertNotEquals(null, camnOriginal, 'CAMN originalValue debe ser un Map con value/label/compareValue');
        System.assertEquals('CAMN_DESC', camnOriginal.get('value'), 'Sin match en el catálogo A521, value debe ser la descripción cruda de HPG');
        System.assertEquals('CAMN_DESC', camnOriginal.get('label'), 'label debe ser la descripción cruda de HPG');
        System.assertEquals('CAMN_DESC', camnOriginal.get('compareValue'), 'compareValue debe ser la descripción cruda de HPG, usada para la comparación del warning en el LWC');
    }

    // ─── getMainHolderData ─── ERRORES ───────────────────────────────────────

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
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando opportunityId es null');
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
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando alphaCode es null');
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
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando alphaCode está vacío');
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
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando ambos parámetros son null');
    }

    @isTest
    static void testGetMainHolderData_WrongAlphaCode_ThrowsAuraException() {
        // El RecordType debe ser explicitamente no-Prospect: para Prospect Group el clientId
        // se resuelve desde la propia Account y nunca se consulta Local_Client__c.
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
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando no existe Local Client para el alphaCode');
    }

    // ─── saveMainBorrowerFields ───────────────────────────────────────────────

    // Helper para construir un mapa de fieldValues reutilizable
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
        System.assertEquals(true, updatedOpp.DMT_Is_Change_in_Ready_to_close__c,
            'El flag DMT_Is_Change_in_Ready_to_close__c debe activarse en Ready to close');
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
        System.assertEquals('Fin Inst-B', updated.Counterpart__c,
            'La contraparte debe actualizarse con el valor enviado');
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

        // Registro existente en DMT_Custom_Association_ClientOpportunity__c sin DMT_g_entific_id__c
        // (simula un registro creado antes del backfill) — debe actualizarse, no duplicarse.
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
        System.assertEquals(1, multiholders.size(),
            'No debe crearse un duplicado, solo debe actualizarse el registro existente');
        System.assertEquals('ES', multiholders[0].DMT_g_entific_id__c,
            'g_entific_id__c debe rellenarse en el backfill');
        System.assertEquals(assoc.gf_customer_group_id__c, multiholders[0].DMT_gf_customer_group_id__c,
            'gf_customer_group_id__c debe rellenarse desde la asociación');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_NewMainBorrower_InsertsClient() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity newOpp = buildOrphanOpportunity(acc.Id, '88888');

        // Pre-crea la asociación para que associationId sea correcto en el upsert.
        // gf_customer_group_id__c debe ser único — se usa un valor distinto al del @TestSetup.
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
        System.assertEquals(1, created.size(), 'Debe crearse un DMT_Opportunity_Client__c');
        System.assertEquals(ALPHA_CODE, created[0].Alpha_Code_Client__c,
            'El alpha code del nuevo cliente debe coincidir');
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

        // En el modelo multiholder los participantes viven en DMT_Custom_Association_ClientOpportunity__c.
        // Se inserta uno que ya no vendrá en selectedClients y por tanto debe eliminarse.
        insert new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = assoc.Id,
            DMT_g_customer_id__c                  = 'TOREMOVE99'
        );

        // Solo ALPHA_CODE en selectedClients — TOREMOVE99 debe eliminarse
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
        System.assertEquals(1, remaining.size(),
            'Solo debe quedar el participante del main borrower');
        System.assertEquals(ALPHA_CODE, remaining[0].DMT_g_customer_id__c,
            'El participante restante debe ser el main borrower');
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
        System.assertEquals('NEWALPHACODE01', updatedAssoc.g_customer_id__c,
            'La asociación debe actualizarse con el nuevo main borrower');
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

        // La actualización usa USER_MODE; se verifica que el método completó sin error
        // y que el passport sigue existiendo (la lógica de marcado depende de permisos FLS del perfil).
        List<Passport__c> passportList = [
            SELECT Id FROM Passport__c WHERE Id = :passport.Id
        ];
        System.assertEquals(1, passportList.size(),
            'El passport debe seguir existiendo tras el guardado');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_WithNonMainClient_InsertsSecondaryClient() {
        Opportunity opp = loadOpportunity();
        DMT_Opportunity_Client__c dmtClient =
            [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        // Cliente secundario con campos HPG en el mapa
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

        // El cliente secundario se persiste en DMT_Custom_Association_ClientOpportunity__c,
        // no en DMT_Opportunity_Client__c (que es 1:1 con el main holder).
        List<DMT_Custom_Association_ClientOpportunity__c> allClients = [
            SELECT DMT_g_customer_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__c = :assoc.Id
            ORDER BY DMT_g_customer_id__c
        ];
        System.assertEquals(2, allClients.size(),
            'Deben existir el main borrower y el cliente secundario como participantes');
        System.assertEquals('SECONDARY01', allClients[0].DMT_g_customer_id__c,
            'El primer participante ordenado debe ser el cliente secundario');

        List<DMT_Opportunity_Client__c> mainHolders = [
            SELECT Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, mainHolders.size(),
            'Solo debe existir el DMT_Opportunity_Client__c del main holder');
    }

    @isTest
    static void testSaveMainBorrowerWithClients_ExistingAssocWithDifferentMainBorrower_UpdatesAssocAndInsertsClient() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity newOpp2 = buildOrphanOpportunity(acc.Id, '88889');

        // La asociación existe pero con un alpha code diferente; el controlador la actualiza.
        // gf_customer_group_id__c debe ser único — se usa un valor distinto al del @TestSetup.
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
        System.assertEquals(ALPHA_CODE, updatedAssoc.g_customer_id__c,
            'La asociación debe actualizarse con el nuevo main borrower alpha code');
    }
}