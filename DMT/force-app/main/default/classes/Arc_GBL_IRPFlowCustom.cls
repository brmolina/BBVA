/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_IRPFlowCustom
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 04/10/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Example local implementation of Arc_Gen_IRPFlowCustom_interface
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2021-10-04 juanignacio.hita.contractor@bbva.com
*             Class creation
* |2021-10-26 juanignacio.hita.contractor@bbva.com
*             Add new validateFSForRating method
* |2021-11-02 juanignacio.hita.contractor@bbva.com
*             Adds checkRatingToolId method
* |2021-12-09 juanignacio.hita.contractor@bbva.com
*             Adds checkRatingToolId method
* -----------------------------------------------------------------------------------------------
*/
global without sharing class Arc_GBL_IRPFlowCustom implements Arc_Gen_IRPFlowCustom_Interface { //NOSONAR

    /**
    *-------------------------------------------------------------------------------
    * @description Return rating tool list values for pre triage action
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2021-10-04
    * @param  String accHasId : account has analysis id
    * @return List<Arc_Gen_RatingAsIndepProcess_service.RatingTool>
    * @example List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTool = preTriageStep();
    **/
    public static List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> preTriageStep(String accHasId) {
        final List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTools = Arc_Gen_RatingAsIndepProcess_service.getUserSelectableRatingTools();
        ratingTools.addAll(Arc_Gen_RatingAsIndepProcess_service.getUserRatingToolsType());
        return ratingTools;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Return rating tool list values for post triage action exclusive
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2021-10-04
    * @param  String accHasId : account has analysis id
    * @return List<Arc_Gen_RatingAsIndepProcess_service.RatingTool>
    * @example List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTool = postTriageStep();
    **/
    public static List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> postTriageStep(String accHasId) {
        final List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTools = new List<Arc_Gen_RatingAsIndepProcess_service.RatingTool>();
        /*
        * LOCAL LOGIC EXAMPLE
        */
        for (Arc_Gen_RatingAsIndepProcess_service.RatingTool tool : Arc_Gen_RatingAsIndepProcess_service.getUserSelectableRatingTools()) {
            //final Integer valueTool = Integer.valueOf(tool.value);
            //if (valueTool > 0000000000000000) {
            ratingTools.add(tool);
            //}
        }
        return ratingTools;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Return rating tool list values for post triage action after ffss when both config
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2021-10-04
    * @param  String accHasId : account has analysis id
    * @return List<Arc_Gen_RatingAsIndepProcess_service.RatingTool>
    * @example List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTool = bothTriageStep();
    **/
    public static List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> bothTriageStep(String accHasId) {
        List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTools = new List<Arc_Gen_RatingAsIndepProcess_service.RatingTool>();
        // Logic depends financial statement selected
        ratingTools = Arc_Gen_RatingAsIndepProcess_service.getUserSelectableRatingTools();
        return ratingTools;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that implements the validation of financial statements for the rating engine
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    25/10/2021
    * @param   List<arce__Financial_Statements__c> ffss
    * @return  String ratingTool
    * @example List<arce__Financial_Statements__c>
    **/
    public static List<arce__Financial_Statements__c> validateFSForRating(List<arce__Financial_Statements__c> ffss, String ratingTool) {
        final List<arce__Financial_Statements__c> listFfss = new List<arce__Financial_Statements__c>();
        for (arce__Financial_Statements__c unit : ffss) {
            final Boolean ffssValForRat = unit.arce__ffss_certification_type__c == 'AUDITED' ? true : false;
            unit.arce__ffss_valid_type__c = Arc_Gen_Balance_Tables_helper.getFfssValidType(ffssValForRat);
            listFfss.add(unit);
        }
        return listFfss;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Implements local logic to show or hide rating and pre-rating buttons
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    02/11/2021
    * @param   String analysisId
    * @param   String ratingTool
    * @return  List<String> values : RATING_LABEL or PRERATING_LABEL
    * @example List<String>
    **/
    public static List<String> checkRatingToolId(String analysisId, String ratingTool) {
        final List<String> options = new List<String>();
        if (ratingTool == '0000000000000000') {
            options.add(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL);
        }
        if (ratingTool != '0000000000000000') {
            options.add(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL);
            options.add(Arc_Gen_RatingAsIndepProcess_controller.PRERATING_LABEL);
        }
        return options;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Implements local logic to invoke ratios engine
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    09/12/2021
    * @param   String accHasId : account has analysis id
    * @param   String ratingTool : rating tool string selected
    * @return  Boolean
    * @example Boolean return if to call ratios engine
    **/
    public static Boolean invokeRatiosEngine(String accHasId, String ratingTool) {
        Boolean retVal = true;
        if (ratingTool == '0000000000000000') {
            retVal = false;
        }
        return retVal;
    }

}