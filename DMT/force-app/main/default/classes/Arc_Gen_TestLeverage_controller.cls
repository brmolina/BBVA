/**
* @File Name          : Arc_Gen_TestLeverage_controller.cls
* @Description        : Obtains the response of the service class for the test leverage
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 23/7/2019 23:11:29
* @Changes            :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version

**/

public without sharing class Arc_Gen_TestLeverage_controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_TestLeverage_controller controller = new Arc_Gen_TestLeverage_controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_TestLeverage_controller() {

    }
/**
*-------------------------------------------------------------------------------
* @description Method that inicializes the response of the leveraged
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param String analysisId of the account has analisis
* @return Arc_Gen_TestLeverage_service.leverageTestResponse - Wrapper with the response of the leveraged test
* @example public static Arc_Gen_TestLeverage_service.leverageTestResponse setupLeverage(String analysisId)
**/
    @AuraEnabled
    public static Arc_Gen_TestLeverage_service.leverageTestResponse setupLeverage(String analysisId) {
        return Arc_Gen_TestLeverage_service.setupLeverage(analysisId);
    }
}