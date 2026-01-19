/**********************************************************************************************************
 * @name            CUCO_UtilsTest
 * @author          David Díaz
 * @created         05/08/2025
 * @description     Clase de pruebas unitarias para validar el comportamiento de los métodos definidos en CUCO_Utils.
 **********************************************************************************************************/

@isTest
private class CUCO_UtilsTest {

/**********************************************************************************************************
 * @name            getPicklistLabelTest
 * @description     Prueba unitaria del método 'getPicklistLabel' para verificar que se obtiene correctamente
 *                  la etiqueta asociada a un valor de picklist en el objeto especificado.
 **********************************************************************************************************/

@IsTest
    public static void getPicklistLabelTest() {
        CUCO_Utils cucoUtils = new CUCO_Utils();
        System.assertEquals('Mr.', CUCO_Utils.getPicklistLabel('Lead', 'Salutation', 'Mr.'), 'Correct Picklist Label');
    }
}