/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Customer_Controller
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-05-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_Validate_Customer_Service and
* Arc_Gen_Validate_Customer_Data.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-10-03 mariohumberto.ramirez.contractor@bbva.com
*             Added new param 'ratingStatus' to ResponseWrapper.
* |2020-06-09 mariohumberto.ramirez.contractor@bbva.com
*             Added new param 'analysisType' to ResponseWrapper.
* |2020-06-30 joseluis.garcia4.contractor@bbva.com
*             Change references to PoliciesWrapper.
* |2020-07-13 joseluis.garcia4.contractor@bbva.com
*             Check for edit permissions.
* |2020-08-11 juanignacio.hita.contractor@bbva.com
*             Changed logic success value in validateCustomer method
* |2020-08-18 joseluis.garcia4.contractor@bbva.com
*             Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
* |2020-08-27 joseluis.garcia4.contractor@bbva.com
*             Add call to validateLeveraged.
* |2020-09-02 joseluis.garcia4.contractor@bbva.com
*             Fixes clients with no leveraged test not being validated. Only validate and persist leveraged in bottom-up clients.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2022-06-06 juanignacio.hita.contractor@bbva.com
*             Adds validateRecalcRating validation in validateCustomer method
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_Validate_Customer_Controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Controller controller = new Arc_Gen_Validate_Customer_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Validate_Customer_Controller() {

    }

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Wrapper that contains the response of the validateCustomer method
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example ResponseWrapper wrapper = new ResponseWrapper()
    * ----------------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapper {
        /*
        *   @Description List<Map<string,string>> gblResponse
        */
        @AuraEnabled public List<Map<string,string>> gblResponse {get;set;}
        /*
        *   @Description String responseError
        */
        @AuraEnabled public String responseError {get;set;}
        /*
        *   @Description Boolean success
        */
        @AuraEnabled public Boolean success {get;set;}
        /*
        *   @Description List<string> ratingStatus
        */
        @AuraEnabled public List<string> ratingStatus {get;set;}
        /*
        *   @Description String analysisType
        */
        @AuraEnabled public String analysisType {get;set;}
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns a List<Map<string,string>> that contain the error message of the
    * Policies table validations
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @return a List<Map<string,string>> that contain the error message of the
    * Policies table validations
    * @example validateCustomer(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper validateCustomer(string accHasAId) {
        ResponseWrapper wrapper = new ResponseWrapper();

        if (arce.Arc_Gen_GenericUtilities.isButtonAvailable(accHasAId, 'Arc_Gen_BtnValidateGroup') ||
                arce.Arc_Gen_GenericUtilities.isButtonAvailable(accHasAId, 'Arc_Gen_BtnValidate')) {
            try {
                wrapper = Arc_Gen_Validate_Customer_Service.validateTable(accHasAId);
                Arc_Gen_Validate_Customer_Service.validateLeveraged(accHasAId, wrapper);
                Arc_Gen_Validate_Customer_Service.validateRecalcRating(accHasAId, wrapper);
                Arc_Gen_Validate_Customer_Service.changeStatusArce(accHasAId, wrapper);
                Arc_Gen_Validate_Customer_Service.activeCustomerFlag(accHasAId, wrapper);

                if(String.isBlank(wrapper.responseError)) {
                    wrapper.success = true;
                }else{
                    wrapper.success = false;
                }
            } catch (Exception exep) {
                wrapper.success = false;
                wrapper.responseError = exep.getTypeName() + ' : ' + exep.getMessage() + ' : ' + exep.getStackTraceString();
            }
        } else {
            wrapper.success = false;
            wrapper.responseError = System.Label.Arc_Gen_Generic_ButtonNotAllowed;
        }
        return wrapper;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that manage the leverage persistence service
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param analysisId - Accoun has analysis id object
    * @return Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper - wrapper with the operation status
    * @example leveragePersistence(analysisId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper leveragePersistence(String analysisId) {
        Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper wrapper = new Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper();
        try {
            if (analysisId == null) {
                throw new ListException(Label.Arc_Gen_EmptyList);
            }
            wrapper = Arc_Gen_TestLeverage_service.leveragePersistence(analysisId);
        } catch (Exception e) {
            wrapper.success = false;
            wrapper.messageError = e.getMessage();
        }
        return wrapper;
    }
}