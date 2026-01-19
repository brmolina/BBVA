/**
* @File Name          : Arc_gen_Sales.cls
* @Description        : Class to call the 2 services of sales
* @Author             : isabel.ascaso.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 05-26-2025
* @Changes
*========================================================================================
* Ver         Date   Author                                           Modification
*========================================================================================
* 1.0    26/03/2024  isabel.ascaso.tech@bbva.com     Initial Version
**/
public class Arc_gen_Sales {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		26/03/2024
    * @author	isabel.ascaso.tech@bbva.com
    */ 
    private Arc_gen_Sales() {

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that retrieves the information of the selected objects and returns service response
    * -----------------------------------------------------------------------------------------------
    * @param String ahaId - Selected account has analysis id
    * @return Arc_gen_Sales_Wrappers.ResponseWrapper - Service response
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper dataResponse = processData(ahaId, response)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Arc_gen_Sales_Service.ResponseWrapper processData(List<arce__Account_has_Analysis__c> ahaObjList, String raipType) {
        Arc_gen_Sales_Service.ResponseWrapper responseEngine;
        if (ahaObjList.isEmpty()) {
            responseEngine = new Arc_gen_Sales_Service.ResponseWrapper(false, System.Label.Arc_Serv_AhaNotExist, null, null);
        } else {
            responseEngine = Arc_gen_Sales_Service.callIASOServiceEngineSales(ahaObjList[0], raipType);
            System.debug('processData ' + responseEngine);
        }

        return responseEngine;
    }

}