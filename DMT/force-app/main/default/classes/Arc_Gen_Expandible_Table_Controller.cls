/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Expandible_Table_Controller
* @Author   BBVA
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_Expandible_Table_cmp
* ------------------------------------------------------------------------------------------------
* @Changes
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Deleted some global wrapper classes
*             Added new wrappers deleted in the global wrapper classes
*             - Arc_Gen_DataTable, Arc_Gen_TableColumns and Arc_Gen_TableRow
*             Change to SOC
* |2019-08-14 mariohumberto.ramirez.contractor@bbva.com
*             Deleted call to the method verifyTypologiesInserted in Arc_Gen_Expandible_Table_Service
* |2019-09-30 mariohumberto.ramirez.contractor@bbva.com
*             Added new method sumTypologies
* |2019-10-11 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getHeaderDate
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             modify method getproducts and added new method changeServiceFlag
* |2020-01-30 javier.soto.carrascosa@bbva.com
*             Add HU 787 missing functionality
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Add Group Risk Detail Table method setLimitsToAha
* |2020-04-30 joseluis.garcia4.contractor@bbva.com
*             Update limit values in insertProducts method.
* |2020-07-16 joseluis.garcia4.contractor@bbva.com
*             Clear leveraged test results when group policies table is updated.
* |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
*             Add getTypeOfAnalysis and getLastProposeInfo methods
* |2020-09-18 joseluis.garcia4.contractor@bbva.com
*             Updates materiality of leveraged when policies are updated
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-06 juanignacio.hita.contractor@bbva.com
*             Added call limit and exposure persistence service when insert and edit a product in persDelRecords method
*             Added arce__limits_typology_id__c in insertProducts method
* |2020-10-27 juanignacio.hita.contractor@bbva.com
*             Added callServRefreshEvent method for call to persistence service when update event fires
* |2021-01-25 joseluis.garcia4.contractor@bbva.com
*             Add method to check if ARCE is in sanction to control action visibility.
* |2021-03-22 juanignacio.hita.contractor@bbva.com
*             Remove callServRefreshEvent unused method
* |2021-05-21 juanignacio.hita.contractor@bbva.com
*             Add logic hasManualTablePerm for insertProducts method.
* |2021-07-16 juanignacio.hita.contractor@bbva.com
*             Created updateStatusLimitPers method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount, sf:TooManyFields')
public without sharing class Arc_Gen_Expandible_Table_Controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller controller = new Arc_Gen_Expandible_Table_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Expandible_Table_Controller() {
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the policie table
    * -----------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param void
    * @return all the information to create the table
    * @example ResponseWrapper wrapper = new ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapper {
        /**
        * @Description: Boolean that represent a succesfull call
        */
        @AuraEnabled public Boolean successResponse {get;set;}
        /**
        * @Description: Map with some info in the data
        */
        @AuraEnabled public Arc_Gen_DataTable jsonResponse {get;set;}
        /**
        * @Description: String with an error response
        */
        @AuraEnabled public String errorResponse {get;set;}
        /**
        * @Description: Map with some the info of the delete response
        */
        @AuraEnabled public Map<String,String> deleteResponse {get;set;}
        /**
        * @Description: Map with some the info of the delete response
        */
        @AuraEnabled public List<String> productResponse {get;set;}
        /**
        * @Description: Map with some the info of the delete response
        */
        @AuraEnabled public List<Map<String,String>> gblProductResp {get;set;}
        /**
        * @Description: Map with values to insert products
        */
        @AuraEnabled public Map<String,Double> values2Insert {get;set;}
        /**
        * @Description: Limit typology record id
        */
        @AuraEnabled public String limitTypologyId {get;set;}

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a JSON with the data to construct the policie table
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param recordId - Id of the account_has_analysis.
    * @param inputClass - String with whe name of the controller class
    * @return response - Wrapper with the data to construct the policie tablew
    * @example dataResponse(recordId, inputClass)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper dataResponse(Id recordId, String inputClass) {
        ResponseWrapper response = new ResponseWrapper();
        response.successResponse = true;
        final String def = 'default';
        Arc_Gen_DataTable dataJson = new Arc_Gen_DataTable();
        if (inputClass == def) {
            final arce__analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce((String)recordId);
            final string sanctionResult = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(New List<Id>{arceVar.Id})[0].arce__anlys_wkfl_sanction_rslt_type__c;
            dataJson.columns = Arc_Gen_Expandible_Table_Service.getColumns(sanctionResult);
            dataJson.data = Arc_Gen_Expandible_Table_Service.buildNestedData(recordId);
            response.jsonResponse = dataJson;
        } else {
            System.Type objType = Type.forName(inputClass);
            final Arc_Gen_Expandible_Table_Interface interfaceClass = (Arc_Gen_Expandible_Table_Interface)objType.newInstance();
            response.jsonResponse = interfaceClass.getData(recordId);
        }
        return response;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get date of sanction to show in politics header table
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-10-11
    * @param recordId - id of the account_has_analysis.
    * @return String - date of sanction
    * @example getHeaderDate(recordId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getHeaderDate(Id recordId) {
        return Arc_Gen_Expandible_Table_Service.getHeaderDate(recordId);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Delete records
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param recordId - id of the account_has_analysis.
    * @return response. map of data for policies deletition
    * @example deleteRecords(recordId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Map<String,String> deleteRecords(Id recordId) {
        final ResponseWrapper response = new ResponseWrapper();
        response.deleteResponse = Arc_Gen_Expandible_Table_Service.deleteRecord(recordId);
        return response.deleteResponse;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return's the record Id of a record type
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param recordTypeName - name of the record type
    * @return recordIdResponse - String with the Id of the record type
    * @example getRecordId(recordTypeName)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getRecordId(String recordTypeName) {
        final String recordIdResponse = Arc_Gen_Expandible_Table_Service.getRecordTypeId(recordTypeName);
        return recordIdResponse;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description get a list of products
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param tipologia - name of the typology
    * @return lista. list of typologys
    * @example getProducts(tipologia)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper getProducts(String tipologia) {
        ResponseWrapper response = new ResponseWrapper();
        try {
            final arce__limits_typology__c limitTypology = Arc_Gen_LimitsTypologies_Data.getTypologiesByDevName(tipologia);
            response.successResponse = true;
            response.gblProductResp = Arc_Gen_Expandible_Table_Service.getProductsService(tipologia);
            response.limitTypologyId = limitTypology.Id;
        } catch (Exception e) {
            response.successResponse = false;
            response.errorResponse = e.getMessage() + ' : ' + e.getLineNumber();
        }
        return response;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description change the status of the validate client to false
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-06-20
    * @param recordId - id of the account has analysis object
    * @param desactivate - string to desactivate the flag
    * @param limitId - id of the record edited
    * @return ResponseWrapper wrapper for policies to validate status
    * @example desactivateValidFlag()
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper desactivateValidFlag(string recordId, string desactivate) {
        final ResponseWrapper wrapper = new ResponseWrapper();
        try {
            // Reset Leveraged Test.
            Arc_Gen_Expandible_Table_Service.clearTestLeveraged(recordId);

            // Update leveraged materiality.
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> { recordId })[0];
            Arc_Gen_TestLeverage_service.updateLimitLeverage(aha);

            // Deactivate flag/change ARCE state.
            Arc_Gen_Validate_Customer_Data.activeCustomerFlag(recordId, desactivate);
            wrapper.successResponse = Arc_Gen_TabSet_service.changeArceState(recordId);
            wrapper.errorResponse = System.Label.Arc_Gen_Success_Parrilla_Message;
        } catch (Exception e) {
            wrapper.errorResponse = System.Label.Arc_Gen_ApexCallError + ' : ' + e.getMessage() + ' : ' + e.getLineNumber();
        }
        return wrapper;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that sum 2 typologies
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2019-09-30
    * @param recordId - Id of the account has analysis object
    * @return String
    * @example String ret = sumTypologies(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String sumTypologies(Id recordId) {
        return Arc_Gen_Expandible_Table_Service.sumTypologies(recordId);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that sum 2 typologies
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-01-28
    * @param recordId - Id of the account has analysis object
    * @return ResponseWrapper
    * @example changeServiceFlag(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper changeServiceFlag(Id recordId) {
        ResponseWrapper wrapper = new ResponseWrapper();
        try {
            wrapper.successResponse = true;
            Arc_Gen_Auto_ExpTable_Service.changeServiceFlag(recordId);
        } catch (Exception e) {
            wrapper.successResponse = false;
            wrapper.errorResponse = System.Label.Arc_Gen_ApexCallError + ' : ' + e.getMessage() + ' : ' + e.getLineNumber();
        }
        return wrapper;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that return the amount of the selected product
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-01-28
    * @param accHasAId - Id of the account has analysis object
    * @param tipologia - developer name of the typology
    * @param prodId - Id of the selected product
    * @return ResponseWrapper
    * @example insertProducts(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper insertProducts(String accHasAId, String tipologia, String prodId, String recordId) {
        ResponseWrapper wrapper = new ResponseWrapper();
        try {
            wrapper.successResponse = true;
            if(Arc_Gen_Auto_ExpTable_Service_Helper.hasManualTablePerm(accHasAId) == false) {
                System.Type objType = Type.forName('Arc_Gen_Auto_ExpTable_Service');
                final Arc_Gen_Expandible_Table_Interface interfaceClass = (Arc_Gen_Expandible_Table_Interface)objType.newInstance();
                wrapper.values2Insert = interfaceClass.insertProducts(accHasAId, tipologia, prodId);

                // Update limits retrieved by service in arce__limits_exposures__c record.
                arce__limits_exposures__c limitsRecord = new arce__limits_exposures__c(
                    Id = recordId,
                    arce__last_approved_amount__c = wrapper.values2Insert.get('lastApproved'),
                    arce__curr_approved_commited_amount__c = wrapper.values2Insert.get('commited'),
                    arce__curr_apprv_uncommited_amount__c = wrapper.values2Insert.get('uncommited'),
                    arce__current_formalized_amount__c = wrapper.values2Insert.get('currentLimit'),
                    arce__outstanding_amount__c = wrapper.values2Insert.get('outstanding'),
                    arce__current_approved_amount__c = 0
                );

                arce.Arc_Gen_LimitsExposures_Data.updateExposureData(new List<arce__limits_exposures__c> { limitsRecord });
            }
        } catch (Exception e) {
            wrapper.successResponse = false;
            wrapper.errorResponse = System.Label.Arc_Gen_ApexCallError + ' : ' + e.getMessage() + ' : ' + e.getLineNumber();
        }
        return wrapper;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that copies the authorized, outstanding, formalized and proposed limit amounts to AccHasAnalysis
    * ----------------------------------------------------------------------------------------------------
    * @Author eduardoefrain.hernandez.contractor@bbva.com
    * @Date 2020-03-26
    * @param accHasAnId - Id of the account has analysis object
    * @return String
    * @example setLimitsToAha(accHasAnId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String setLimitsToAha(String accHasAnId) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnId});
        String result;
        try {
            result = Arc_Gen_GroupRiskDetailTable_service.setupRiskTable(arce.Arc_Gen_GenericUtilities.getHighestTypLimits(ahaList.get(0)), ahaList.get(0));
        } catch(Exception e) {
            result = JSON.serialize(new Map<String, String>{'status' => 'false', 'message' => e.getMessage()});
        }
        Return result;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get type of analysis
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-08-04
    * @param recordId - id of the account_has_analysis.
    * @return String - type of analysis
    * @example getTypeOfAnalysis(recordId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getTypeOfAnalysis(Id recordId) {
        return Arc_Gen_Expandible_Table_Service.getTypeOfAnalysis(recordId);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description check if ARCE is currently in sanction status
    * --------------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2021-01-25
    * @param recordId - id of the account_has_analysis.
    * @return Boolean - if ARCE is in sanction
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean checkInSanction(Id recordId) {
        final arce__Analysis__c analys = arce.Arc_Gen_ArceAnalysis_Data.gerArce(recordId);
        return analys.arce__wf_status_id__c == '08';
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get propose info of the previous arce
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-08-04
    * @param recordId - id of the account_has_analysis.
    * @return String - TRUE/FALSE
    * @example getLastProposeInfo(recordId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getLastProposeInfo(Id recordId) {
        return Arc_Gen_Expandible_Table_Service.getLastProposeInfo(recordId);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that call add limit service persistence
    * ----------------------------------------------------------------------------------------------------
    * @Author juanignacio.hita.contractor@bbva.com
    * @Date   2020-10-14
    * @param  accHasAId - Id of the account has analysis object
    * @param  limitId - Id of the limit exposure object
    * @return Boolean
    * @example Boolean ret = addLimitPersService(accHasAnId, limitId);
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean addLimitPersService(String accHasAId, String limitId) {
        return Arc_Gen_PersistenceLimits_service.callAddLimitService(accHasAId, limitId);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that call delete limit persistence service
    * --------------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2019-10-14
    * @param  accHasId - id of the account_has_analysis.
    * @param  recordId - id of limit deleted
    * @return Boolean
    * @example Boolean status = persDelRecords(recordId, accHasId):
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean delLimitPersService(Id accHasId, Id recordId) {
        // Call delete limit persistence service
        return Arc_Gen_PersistenceLimits_service.callDeleteLimitService(accHasId, recordId);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that call all limits persistence service
    * --------------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2019-10-14
    * @param  accHasId - id of the account_has_analysis.
    * @return Boolean
    * @example Boolean status = allLimitsPersistence(accHasId):
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean allLimitsPersistence(Id accHasId) {
        final arce__Account_has_Analysis__c newAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(accHasId, new List<String>{'arce__currency_id__c', 'arce__magnitude_unit_type__c', 'arce__limit_exposure_ext_ind_type__c'});
        final List<arce__limits_exposures__c> lstLimitExp = arce.Arc_Gen_LimitsExposures_Data.getExposurDataMod(new List<Id>{accHasId});
        return Arc_Gen_PersistenceLimits_service.callLimitsPersService(accHasId, newAha, lstLimitExp);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Update the status limit persistence service flag of aha
    * --------------------------------------------------------------------------------------
    * @param String accHasId : Account has analysis id
    * @param Boolean callout : flag response service
    * @return void
    * @example updateStatusLimitPers(accHasId);
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void updateStatusLimitPers(String accHasId, Boolean callout) {
        Arc_Gen_Validate_Customer_Data.updateStatusLimitPers(accHasId, callout);
    }
}