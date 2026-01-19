/**
* -----------------------------------------------------------------------------------------------
* @Name           arce_SB_CountriesListCtrl_Test
* @Author         santiago.vidal.contractor@bbva.com
* @Date           17-07-2025
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class for arce_SB_CountriesListCtrl
* -----------------------------------------------------------------------------------------------
* @Changes
*
* -----------------------------------------------------------------------------------------------
**/
@isTest
private class arce_SB_CountriesListCtrl_Test {

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_SB_CountriesListCtrl.arce_SB_CountriesListCtrl() constructor
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testArce_SB_CountriesListCtrl() {

        arce_SB_CountriesListCtrl controller = new arce_SB_CountriesListCtrl();
        System.assert(controller != null, 'El controlador arce_SB_CountriesListCtrl debería haberse inicializado correctamente.');
        
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_SB_CountriesListCtrl.getInitialData() 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetInitialData() {

        Test.startTest();
        Map<String, Object> result = arce_SB_CountriesListCtrl.getInitialData();
        Test.stopTest();

        System.assert(result.get('bankCountriesSBList') != null, 'Key bankCountriesSBList should contain values');
        System.assert(result.get('insurerCountriesSBList') != null, 'Key insurerCountriesSBList should contain values');
    }
}