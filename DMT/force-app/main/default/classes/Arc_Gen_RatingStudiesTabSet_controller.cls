/**
* @File Name          : Arc_Gen_RatingStudiesTabSet_controller.cls
* @Description        : Controller of the rating studies dynamic form component
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 27/07/2020 13:00:00
* @Changes   :
* Ver       Date            Author      		    Modification
* -----------------------------------------------------------------------------------------------
* 1.0    17/10/2019   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    27/07/2020   juanignacio.hita.contractor@bbva.com            Add methods for build dynamic rating studies table
**/
public class Arc_Gen_RatingStudiesTabSet_controller {
    /**
    * @Class: dynamicFormParameters
    * @Description: Wrapper that contains the parameters of the studies dynamic form
    * @author ARCE Team
    */
    public class DynamicFormParameters {
        /**
        * @description: Standard Id of the selected rating record
        **/
        @AuraEnabled public String ratingId {get; set;}
        /**
        * @description: Name of the Dynamic form template
        **/
        @AuraEnabled public String templateName {get; set;}
        /**
        * @description: Table wrapper json serialize
        **/
        @AuraEnabled public String tableWrapper {get;set;}
    }
    /**
    * @description: Empty constructor
    **/
    @TestVisible
    private Arc_Gen_RatingStudiesTabSet_controller() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method used in the selection event. This updates of the selection verification
    * and get the rating id for the load dynamic form
    --------------------------------------------------------------------------------
    * @author  eduardoefrain.hernandez.contractor@bbva.com
    * @date    17/10/2019
    * @param   String jsonSetup - Json string of dwp table wrapper
    * @param   String ffssId - Standard Id of the selected Financial statement
    * @return  DynamicFormParameters - Wrapper of parameters
    * @example DynamicFormParameters dynform = getAnalyzedClient(jsonSetup, ffssId);
    **/
    @AuraEnabled
    public static DynamicFormParameters getAnalyzedClient(String jsonSetup, String ffssId) {
        final DynamicFormParameters dynParams = new DynamicFormParameters();
        try {
            final Arc_Gen_DwpTableWrapper tableWrapper = Arc_Gen_DwpTableWrapper_Controller.evtSelectRow(jsonSetup, ffssId);
            final List<String> lstParams = Arc_Gen_RatingStudiesTabSet_service.getAnalyzedClientId(ffssId);
            dynParams.tableWrapper = JSON.serialize(tableWrapper);
            dynParams.ratingId = lstParams.get(0);
            dynParams.templateName = lstPArams.get(1);
        } catch(ListException e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return dynParams;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get init data for create component
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    27/07/2020
    * @param   String recordId - Standard id of account has analysis
    * @return  List<String> - Financial statement id list
    * @example DynamicFormParameters dyn = getInitData(recordId);
    **/
    @AuraEnabled
    public static List<String> getInitData(String recordId) {
        List<String> lstEeffRating = new List<String>();
        try {
            lstEeffRating = Arc_Gen_RatingStudiesTabSet_service.getInitData(recordId);
        } catch(Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return lstEeffRating;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that build the rating wrapper object that contains the table of eeff valid
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    27/07/2020
    * @param   List<String> ffssId - List of financial statement valid id
    * @return  String - Returns a serialize json of RatingWrapper object to create the dynamic table in the component
    * @example String jsonTable = getJsonTable(new List<String> ffssId {ffssRecordId});
    **/
    @AuraEnabled
    public static String getJsonTable(List<String> ffssId) {
        Arc_Gen_DwpTableWrapper tableWrapper = new Arc_Gen_DwpTableWrapper();
        try {
            final List<arce__Financial_Statements__c> lstEeffValid = Arc_Gen_RatingStudiesTabSet_data.getListEEFF(ffssId);
            // Generation dwp table wrapper with the data of financial statements
            tableWrapper = Arc_Gen_RatingStudiesTabSet_service.getJsonTable(lstEeffValid);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return JSON.serialize(tableWrapper);
    }
}