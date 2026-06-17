/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class DailyDataQualityJobTest {

    // Utilidad para crear datos
    static void crearCasoDePrueba(Boolean  includeGBL_Account_Relationship, Boolean  includeSubsidiary, Integer activeCount, Integer inactiveCount) {
        List<Account> accs = new List<Account>();

        // Cuentas activas
        for (Integer i = 0; i < activeCount; i++) {
            accs.add(new Account(
                Name = 'Active ' + i,
                gf_prtcpt_act_status_ind_type__c = true
            ));
        }

        // Cuentas inactivas
        for (Integer i = 0; i < inactiveCount; i++) {
            accs.add(new Account(
                Name = 'Inactive ' + i,
                gf_prtcpt_act_status_ind_type__c = false
            ));
        }

        insert accs;

        // Crear relación DWP (con campos obligatorios)
        if (includeGBL_Account_Relationship) {
            insert new dwp_acmh__GBL_Account_Relationship__c(
                dwp_acmh__parent_account__c = accs[0].Id,
                dwp_acmh__vision__c = 'TEST'
            );
        }

        // Crear relación DES (con campos obligatorios)
        if (includeSubsidiary) {
            insert new DES_Subsidiary_Group_Relation__c(
                main_subsidiary_ind_type__c = true
            );
        }
    }

    //  Caso 1: Todo OK → NO email
    @isTest
    static void testAllOk() {
        crearCasoDePrueba(true, true, 10, 0);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(0, result.length(), 'No deberia haber errores');
    }

    //  Caso 2: Todo falla → email
    @isTest
    static void testAllFail() {
        crearCasoDePrueba(false, false, 1, 9);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('% de Cuentas Activas') && result.contains('Registros de Relaciones') && result.contains('Registros de Grupo Subsidiario'), 'Debe contener todos los fallos');
    }


    //  Caso 3: No relaciones →  email
    @isTest
    static void testNoRelations() {
        crearCasoDePrueba(false, false, 10, 0);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('Registros de Relaciones') && result.contains('Registros de Grupo Subsidiario'), 'Debe contener la falta de dwp_acmh__GBL_Account_Relationship y DES_Subsidiary_Group_Relation');
    }


    //  Caso 4: % activo bajo → email
    @isTest
    static void testLowActivePercentage() {
        crearCasoDePrueba(true, true, 1, 9); // 10% activos

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('% de Cuentas Activas'), 'Debe contener % bajo');
    }

    //  Caso 5: Sin relaciones GBL_Account_Relationship → email
    @isTest
    static void testMissingGBLAccountRelationship() {
        crearCasoDePrueba(false, true, 10, 0);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('Registros de Relaciones'), 'Debe contener la falta de dwp_acmh__GBL_Account_Relationship');
    }

    //  Caso 6: Sin relaciones DES_Subsidiary_Group_Relation → email
    @isTest
    static void testMissingSubsidiaryGroupRelation() {
        crearCasoDePrueba(true, false, 10, 0);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('Registros de Grupo Subsidiario'), 'Debe contener la falta de DES_Subsidiary_Group_Relation');
    }

    //  Caso 7: Sin relaciones GBL_Account_Relationship y % activo bajo → email
    @isTest
    static void testMissingGBLLowPercentage() {
        crearCasoDePrueba(false, true, 1, 9);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('% de Cuentas Activas') && result.contains('Registros de Relaciones'), 'Debe contener la falta de dwp_acmh__GBL_Account_Relationship y % bajo');
    }

    //  Caso 8: Sin relaciones DES_Subsidiary_Group_Relation y % activo bajo → email
    @isTest
    static void testMissingSubsidiaryLowPercentage() {
        crearCasoDePrueba(true, false, 1, 9);

        Test.startTest();
        DailyDataQualityJob job = new DailyDataQualityJob();
        String result = job.executeDataQualityChecks();
        Test.stopTest();

        System.assertEquals(true, result.contains('% de Cuentas Activas') && result.contains('Registros de Grupo Subsidiario'), 'Debe contener la falta de DES_Subsidiary_Group_Relation y % bajo');
    }
}