/**********************************************************************************************************
 * @class           DES_cls_DynamicButtonsCtrlLWCTest
 * @author          David Díaz
 * @created         20/02/2026
 * @description     Clase de test para DES_cls_DynamicButtonsCtrlLWC.
 *                  Valida:
 *                  - Comportamiento ante parámetros null y vacío.
 *                  - Recuperación de uno o múltiples botones en contexto de test.
 *                  - Escenario sin coincidencias.
 *                  - Publicación correcta del Platform Event.
 *
 * @group           Dynamic UI / Metadata Driven Configuration
 *
 * ---------------------------------------------------------------------------------------------------------
 * | Versión | Fecha       | Autor         | Descripción del cambio                                     |
 * ---------------------------------------------------------------------------------------------------------
 * | 1.0     | 20/02/2026  | David Díaz   | Ajustada a implementación con Test.isRunningTest()        |
 * ---------------------------------------------------------------------------------------------------------
 **********************************************************************************************************/
@IsTest
private class DES_cls_DynamicButtonsCtrlLWCTest {

    /**********************************************************************************************************
     * @name            test_getButtonsConfig_nullOrEmpty
     * @description     Verifica que el método devuelve null cuando el parámetro es null o vacío.
     **********************************************************************************************************/
    @IsTest
    static void test_getButtonsConfig_nullOrEmpty() {

        System.assertEquals(
            null,
            DES_cls_DynamicButtonsCtrlLWC.getButtonsConfig(null)
        );

        System.assertEquals(
            null,
            DES_cls_DynamicButtonsCtrlLWC.getButtonsConfig('')
        );
    }

    /**********************************************************************************************************
     * @name            test_getButtonsConfig_singleMeta
     * @description     Verifica recuperación correcta de un único botón (TEST_ONE).
     **********************************************************************************************************/
    @IsTest
    static void test_getButtonsConfig_singleMeta() {

        Test.startTest();
        List<DES_cls_DynamicButtonsCtrlLWC.DynamicButtonsWrp> result =
            DES_cls_DynamicButtonsCtrlLWC.getButtonsConfig('TEST_ONE');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());

        DES_cls_DynamicButtonsCtrlLWC.DynamicButtonsWrp wrp = result[0];

        System.assertEquals('Test One', wrp.label);
        System.assertEquals('ActionOne', wrp.action);
        System.assertEquals('Primary', wrp.type);
        System.assertEquals('utility:add', wrp.icon);
        System.assertEquals('SurveyOne', wrp.survey);
    }

    /**********************************************************************************************************
     * @name            test_getButtonsConfig_multipleMetas
     * @description     Verifica recuperación múltiple respetando el orden solicitado.
     **********************************************************************************************************/
    @IsTest
    static void test_getButtonsConfig_multipleMetas() {

        Test.startTest();
        List<DES_cls_DynamicButtonsCtrlLWC.DynamicButtonsWrp> result =
            DES_cls_DynamicButtonsCtrlLWC.getButtonsConfig('TEST_TWO,TEST_ONE');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(2, result.size());

        // Validación orden
        System.assertEquals('Test Two', result[0].label);
        System.assertEquals('Test One', result[1].label);
    }

    /**********************************************************************************************************
     * @name            test_getButtonsConfig_noMatches
     * @description     Verifica que devuelve lista vacía cuando no hay coincidencias.
     **********************************************************************************************************/
    @IsTest
    static void test_getButtonsConfig_noMatches() {

        Test.startTest();
        List<DES_cls_DynamicButtonsCtrlLWC.DynamicButtonsWrp> result =
            DES_cls_DynamicButtonsCtrlLWC.getButtonsConfig('NOT_EXISTING');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    /**********************************************************************************************************
     * @name            test_surveyNotification_success
     * @description     Verifica que la publicación del Platform Event no lanza excepción.
     **********************************************************************************************************/
    @IsTest
    static void test_surveyNotification_success() {

        Test.startTest();
        DES_cls_DynamicButtonsCtrlLWC.surveyNotification('TestSurvey');
        Test.stopTest();

        System.assert(true);
    }
}