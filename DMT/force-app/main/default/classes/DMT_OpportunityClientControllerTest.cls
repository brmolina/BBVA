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
    // una Local_Client__c con Alpha_code__c = 'TEST123'.

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

        // Crea un segundo DMT client sin rating externo; Alpha_code ya existe en Local_Client__c
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

        Local_Client__c subLc = new Local_Client__c(
            Cib_Client__c = subAcc.Id,
            Alpha_code__c = 'ES0182SUBTEST1'
        );
        insert subLc;

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
    static void testGetOppClientContext_NoAssociation_ThrowsAuraException() {
        // Crea una oportunidad sin ninguna Custom_Association_Opportunity__c
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity orphanOpp = buildOrphanOpportunity(acc.Id, '55555');

        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getOpportunityClientContext(orphanOpp.Id);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando no hay asociación para la oportunidad');
    }

    @isTest
    static void testGetOppClientContext_NoDmtClient_ThrowsAuraException() {
        // La asociación existe pero no hay DMT_Opportunity_Client__c para ese alphaCode
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp2 = buildOrphanOpportunity(acc.Id, '66666');

        // Asociación con un alphaCode que no tiene DMT client ni Local_Client__c
        Custom_Association_Opportunity__c assoc2 = new Custom_Association_Opportunity__c(
            Opportunity__c          = opp2.Id,
            g_customer_id__c        = 'NONEXISTENT_CODE',
            gf_customer_group_id__c = 'GNODMT6666666666'
        );
        insert assoc2;

        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getOpportunityClientContext(opp2.Id);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando no existe DMT client para el alphaCode');
    }

    // ─── getMainHolderData ─── ÉXITO ─────────────────────────────────────────

    @isTest
    static void testGetMainHolderData_Success_ReturnsExpectedKeys() {
        Opportunity opp = loadOpportunity();

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(ALPHA_CODE, result.get('alphaCode'),
            'alphaCode debe coincidir con el enviado');
        System.assertNotEquals(null, result.get('mainHolder'),
            'mainHolder debe estar presente');
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
            DMT_OpportunityClientController.getMainHolderData(opp.Id, ALPHA_CODE);
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.get('recordData');
        System.assertNotEquals(null, recordData, 'recordData no debe ser null');

        // Comprueba que la estructura de merge esté presente para al menos un campo
        Map<String, Object> counterpart = (Map<String, Object>) recordData.get('Counterpart__c');
        System.assertNotEquals(null, counterpart, 'Counterpart__c debe estar en recordData');
        System.assert(counterpart.containsKey('currentValue'),
            'Debe tener clave currentValue');
        System.assert(counterpart.containsKey('originalValue'),
            'Debe tener clave originalValue');
    }

    // ─── getMainHolderData ─── ERRORES ───────────────────────────────────────

    @isTest
    static void testGetMainHolderData_NullOpportunityId_ThrowsAuraException() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(null, ALPHA_CODE);
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
            DMT_OpportunityClientController.getMainHolderData(opp.Id, null);
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
            DMT_OpportunityClientController.getMainHolderData(opp.Id, '');
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
            DMT_OpportunityClientController.getMainHolderData(null, null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando ambos parámetros son null');
    }

    @isTest
    static void testGetMainHolderData_WrongAlphaCode_ThrowsAuraException() {
        Opportunity opp = loadOpportunity();
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(opp.Id, 'ALPHA_NO_EXISTE');
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando no existe DMT client para el alphaCode');
    }

    @isTest
    static void testGetMainHolderData_OppWithNoAssociation_ThrowsAuraException() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity orphanOpp = buildOrphanOpportunity(acc.Id, '77777');

        Boolean threw = false;
        Test.startTest();
        try {
            DMT_OpportunityClientController.getMainHolderData(orphanOpp.Id, ALPHA_CODE);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw,
            'Debe lanzar AuraHandledException cuando la oportunidad no tiene asociación');
    }
}