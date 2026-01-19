/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ToogleRatingPrerating_Ctrl
* @Author   alberto.martinez.carrero.next@bbva.com
* @Date     Created: 2023-08-31
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Apex controller to Arc_Gen_ToogleRatingPrerating.cmp
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-08-31 alberto.martinez.carrero.next@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_ToogleRatingPrerating_Ctrl {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		2023-08-31
    * @author	alberto.martinez.carrero.next@bbva.com
    */
    @testVisible
    private Arc_Gen_ToogleRatingPrerating_Ctrl() {

    }
    /*
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a String with JSON format with the init information
    * -----------------------------------------------------------------------------------------------
    * @param String ahaId - id account has analysis
    * @return String with JSON format with the init information
    * @example getInitInfo(recordId)
    * -----------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getInitInfo(String ahaId) {
        String resp;
        try {
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
            final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
            resp = jsonInitInfo(aha, analysis);
        } catch(Exception ex) {
            resp = jsonKO(ex.getMessage());
        }
        return resp;
    }
    /*
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a String with JSON format with the DML result
    * -----------------------------------------------------------------------------------------------
    * @param String ahaId - id account has analysis
    * @param String ratingType - string with 'Prerating' or 'Rating' value
    * @return String with JSON format
    * @example setRatingTypeSelected(ahaId,ratingType)
    * -----------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String setRatingTypeSelected(String ahaId, String ratingType) {
        final List<SObject> recordsToUpdate = new List<SObject>();
        arce.Arc_Gen_RatingGlobal_data.SaveResult saveRes = new arce.Arc_Gen_RatingGlobal_data.SaveResult();
        try {
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
            aha.arce__recalculate_rating__c = String.valueOf(0);
            recordsToUpdate.add(aha);
            final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
            analysis.arce__rating_prerating_type__c = ratingType;
            recordsToUpdate.add(analysis);
            final arce.Arc_Gen_RatingGlobal_data  ratingGlobal = new arce.Arc_Gen_RatingGlobal_data();
            saveRes = ratingGlobal.updateRecords(recordsToUpdate);
        } catch(Exception ex) {
            saveRes.status = 'false';
            saveRes.message = ex.getMessage();
        }
        return saveRes.status == 'true' ? jsonOK() : jsonKO(saveRes.message);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description json contructor for correct response
    *--------------------------------------------------------------------------------
    * @ Author alberto.martinez.carrero.next@bbva.com
    * @ Date   Created: 31-08-2023
    *--------------------------------------------------------------------------------
    **/
    private static String jsonOK() {
        final JSONGenerator toReturn = JSON.createGenerator(false);
        toReturn.writeStartObject();
        toReturn.writeStringField('state', 'OK');
        toReturn.writeEndObject();
        return toReturn.getAsString();
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description json contructor for bad response
    *--------------------------------------------------------------------------------
    * @ Author alberto.martinez.carrero.next@bbva.com
    * @ Date   Created: 31-08-2023
    *--------------------------------------------------------------------------------
    **/
    private static String jsonKO(String mssg) {
        final JSONGenerator toReturn = JSON.createGenerator(false);
        toReturn.writeStartObject();
        toReturn.writeStringField('state', 'KO');
        toReturn.writeStringField('errorMssg', mssg);
        toReturn.writeEndObject();
        return toReturn.getAsString();
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description json contructor to return init info
    *--------------------------------------------------------------------------------
    * @ Author alberto.martinez.carrero.next@bbva.com
    * @ Date   Created: 31-08-2023
    *--------------------------------------------------------------------------------
    **/
    private static String jsonInitInfo(arce__Account_has_Analysis__c aha, arce__Analysis__c analysis) {
        final JSONGenerator toReturn = JSON.createGenerator(false);
        toReturn.writeStartObject();
        toReturn.writeStringField('ratingTool', aha.arce__RAR_rating_tool_id__c);
        toReturn.writeStringField('ratingType', analysis.arce__rating_prerating_type__c);
        toReturn.writeStringField('stage', analysis.arce__Stage__c);
        toReturn.writeStringField('state', 'OK');
        toReturn.writeEndObject();
        return toReturn.getAsString();
    }
}