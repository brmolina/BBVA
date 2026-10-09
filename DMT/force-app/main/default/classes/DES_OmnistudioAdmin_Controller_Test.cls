/**
 * @description      : Clase de prueba para DES_OmnistudioAdmin_Controller.
 * : Verifica la correcta activación/desactivación y consulta de Flexcards e Integration Procedures.
 * @author           : Aníbal Cortés
 * @group            :
 * @last modified on : 07-10-2025
 * @last modified by : Aníbal Cortés
**/
@isTest
public class DES_OmnistudioAdmin_Controller_Test {

    /**
     * @description Prepara los datos de prueba comunes para todos los métodos de test.
     * Crea dos versiones de una FlexCard y una versión de otra, además de un Integration Procedure.
     * Esto se ejecuta una sola vez antes de que se corran los tests.
    **/
    @TestSetup
    static void makeData(){
        // --- Crear FlexCards de prueba ---
        List<OmniUiCard> flexcardsToInsert = new List<OmniUiCard>();
        // FlexCard A, Versión 1 (activa)
        flexcardsToInsert.add(new OmniUiCard(
            Name = 'TestFC_A',
            VersionNumber = 1,
            IsActive = false
        ));
        // FlexCard A, Versión 2 (inactiva, es la más nueva)
        flexcardsToInsert.add(new OmniUiCard(
            Name = 'TestFC_A',
            VersionNumber = 2,
            IsActive = false
        ));
        // FlexCard B, Versión 1 (activa)
        flexcardsToInsert.add(new OmniUiCard(
            Name = 'TestFC_B',
            VersionNumber = 1,
            IsActive = false
        ));
        insert flexcardsToInsert;

        // --- Crear Integration Procedure de prueba ---
        OmniProcess ip = new OmniProcess(
            Name = 'TestIP_C',
            Type = 'Test',
            SubType = 'Pruebas',
            VersionNumber = 1,
            IsActive = true,
            IsIntegrationProcedure = true // Campo clave para ser encontrado por el método
        );
        insert ip;
    }

    /**
     * @description Prueba el método refreshAllFlexcardsLatestVersion.
     * Verifica que solo la última versión de cada FlexCard quede activa.
    **/
    @isTest
    static void testRefreshAllFlexcardsLatestVersion() {
        Test.startTest();
        String resultUrl = DES_OmnistudioAdmin_Controller.refreshAllFlexcardsLatestVersion();
        Test.stopTest();

        // --- Verificaciones ---
        // Buscar las FlexCards después de la ejecución
        OmniUiCard fc_A_v1 = [SELECT IsActive FROM OmniUiCard WHERE Name = 'TestFC_A' AND VersionNumber = 1];
        OmniUiCard fc_A_v2 = [SELECT IsActive FROM OmniUiCard WHERE Name = 'TestFC_A' AND VersionNumber = 2];
        OmniUiCard fc_B_v1 = [SELECT IsActive FROM OmniUiCard WHERE Name = 'TestFC_B' AND VersionNumber = 1];

        // Assert: La versión antigua (v1) de TestFC_A debe estar inactiva.
        System.assertEquals(false, fc_A_v1.IsActive, 'La versión 1 de TestFC_A debería estar inactiva.');

        // Assert: La versión más nueva (v2) de TestFC_A debe estar activa.
        System.assertEquals(true, fc_A_v2.IsActive, 'La versión 2 de TestFC_A debería estar activa.');

        // Assert: La única versión de TestFC_B debe terminar activa (se desactiva y reactiva).
        System.assertEquals(true, fc_B_v1.IsActive, 'La versión 1 de TestFC_B debería estar activa.');

        // Assert: La URL de retorno no debe ser nula y debe contener los IDs de las FlexCards activadas.
        System.assertNotEquals(null, resultUrl, 'La URL de resultado no puede ser nula.');
        System.assert(resultUrl.contains(fc_A_v2.Id), 'La URL debe contener el ID de la FlexCard A v2.');
        System.assert(resultUrl.contains(fc_B_v1.Id), 'La URL debe contener el ID de la FlexCard B v1.');
    }

    /**
     * @description Prueba el método refreshRecentlyModifiedFlexcards.
     * Verifica que activa las últimas versiones encontradas dentro de la ventana calculada.
    **/
    @isTest
    static void testRefreshRecentlyModifiedFlexcards() {
        Test.startTest();
        String resultUrl = DES_OmnistudioAdmin_Controller.refreshRecentlyModifiedFlexcards(null);
        Test.stopTest();

        OmniUiCard fc_A_v1 = [SELECT Id, IsActive FROM OmniUiCard WHERE Name = 'TestFC_A' AND VersionNumber = 1 LIMIT 1];
        OmniUiCard fc_A_v2 = [SELECT Id, IsActive FROM OmniUiCard WHERE Name = 'TestFC_A' AND VersionNumber = 2 LIMIT 1];
        OmniUiCard fc_B_v1 = [SELECT Id, IsActive FROM OmniUiCard WHERE Name = 'TestFC_B' AND VersionNumber = 1 LIMIT 1];

        System.assertEquals(false, fc_A_v1.IsActive, 'La versión 1 de TestFC_A debería quedar inactiva en el refresco reciente.');
        System.assertEquals(true, fc_A_v2.IsActive, 'La versión 2 de TestFC_A debería quedar activa en el refresco reciente.');
        System.assertEquals(true, fc_B_v1.IsActive, 'La versión 1 de TestFC_B debería quedar activa en el refresco reciente.');

        System.assertNotEquals(null, resultUrl, 'La URL de resultado no puede ser nula en el refresco reciente.');
        System.assert(resultUrl.contains(fc_A_v2.Id), 'La URL debe contener el ID de la FlexCard A v2 en el refresco reciente.');
        System.assert(resultUrl.contains(fc_B_v1.Id), 'La URL debe contener el ID de la FlexCard B v1 en el refresco reciente.');
    }

    /**
     * @description Prueba el método refreshRecentlyModifiedFlexcards cuando no existen FlexCards.
     * Verifica que devuelve null sin errores.
    **/
    @isTest
    static void testRefreshRecentlyModifiedFlexcardsWithoutData() {
        delete [SELECT Id FROM OmniUiCard];

        Test.startTest();
        String resultUrl = DES_OmnistudioAdmin_Controller.refreshRecentlyModifiedFlexcards(null);
        Test.stopTest();

        System.assertEquals(null, resultUrl, 'La URL debería ser nula cuando no existen FlexCards para refrescar.');
    }

    /**
     * @description Prueba el método refreshSpecificFlexcard.
     * Verifica que una FlexCard específica se reactiva correctamente.
    **/
    @isTest
    static void testRefreshSpecificFlexcard() {
        OmniUiCard flexcard = [SELECT Id, IsActive, Name FROM OmniUiCard WHERE Name = 'TestFC_B' LIMIT 1];

        Test.startTest();
        String resultUrl = DES_OmnistudioAdmin_Controller.refreshSpecificFlexcard(flexcard.Id, flexcard.Name);
        Test.stopTest();

        // --- Verificaciones ---
        OmniUiCard refreshedFlexcard = [SELECT IsActive FROM OmniUiCard WHERE Id = :flexcard.Id];

        // Assert: La FlexCard debe estar activa después de la operación.
        System.assertEquals(true, refreshedFlexcard.IsActive, 'La FlexCard específica debería estar activa.');

        // Assert: La URL debe contener el ID de la FlexCard.
        System.assert(resultUrl.contains(flexcard.Id), 'La URL de retorno debe contener el ID de la FlexCard refrescada.');
    }

    /**
     * @description Prueba el método refreshSpecificIntegrationProcedure.
     * Verifica que un IP específico se reactiva correctamente.
    **/
    @isTest
    static void testRefreshSpecificIntegrationProcedure() {
        OmniProcess ip = [SELECT Id, Name FROM OmniProcess WHERE Name = 'TestIP_C' LIMIT 1];

        Test.startTest();
        String resultUrl = DES_OmnistudioAdmin_Controller.refreshSpecificIntegrationProcedure(ip.Id, ip.Name);
        Test.stopTest();

        // --- Verificaciones ---
        OmniProcess refreshedIp = [SELECT IsActive FROM OmniProcess WHERE Id = :ip.Id];

        // Assert: El Integration Procedure debe estar activo.
        System.assertEquals(true, refreshedIp.IsActive, 'El Integration Procedure debería estar activo.');

        // Assert: La URL de retorno debe ser la correcta.
        String expectedEndUrl = '/apex/omnistudio__OmniLwcCompile?id=' + ip.Id +'&activate=true';
        System.assert(resultUrl.endsWith(expectedEndUrl), 'La URL de retorno no tiene el formato esperado.');
    }

    /**
     * @description Prueba el método returnAllFlexcardsWithVersions.
     * Verifica que devuelve todas las versiones de todas las FlexCards creadas.
    **/
    @isTest
    static void testReturnAllFlexcardsWithVersions() {
        List<DES_OmnistudioAdmin_Controller.WRAPPER_OmnistudioComponents> result;

        Test.startTest();
        result = DES_OmnistudioAdmin_Controller.returnAllFlexcardsWithVersions();
        Test.stopTest();

        // --- Verificaciones ---
        // Assert: Se deben devolver 3 registros de FlexCard (2 de TestFC_A y 1 de TestFC_B).
        System.assertEquals(3, result.size(), 'Deberían haberse devuelto 3 Flexcards en total.');
        System.assertEquals('TestFC_A', result[0].omniName, 'El nombre del primer elemento no es el esperado.');
    }

    /**
     * @description Prueba el método returnAllIntegrationProcedureWithVersions.
     * Verifica que devuelve todos los IPs creados.
    **/
    @isTest
    static void testReturnAllIntegrationProcedureWithVersions() {
        List<DES_OmnistudioAdmin_Controller.WRAPPER_OmnistudioComponents> result;

        Test.startTest();
        result = DES_OmnistudioAdmin_Controller.returnAllIntegrationProcedureWithVersions();
        Test.stopTest();

        // --- Verificaciones ---
        // Assert: Se debe devolver 1 registro de Integration Procedure.
        System.assertEquals(1, result.size(), 'Debería haberse devuelto 1 Integration Procedure.');
        System.assertEquals('TestIP_C', result[0].omniName, 'El nombre del IP no es el esperado.');
    }
}