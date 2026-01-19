/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_IRPFlowCustom_Interface
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 04/10/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description IRP flow custom interface file
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2021-10-04 juanignacio.hita.contractor@bbva.com
*             Interface creation.
* |2021-10-26 juanignacio.hita.contractor@bbva.com
*             Add validateFSForRating method
* |2021-11-02 juanignacio.hita.contractor@bbva.com
*             Add checkRatingToolId method
* |2021-12-09 juanignacio.hita.contractor@bbva.com
*             Add invokeRatiosEngine method
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_IRPFlowCustom_Interface {
    /*
    * @Description: method that get rating tool for pre-triage, before ffss screen
    */
    List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> preTriageStep(String accHasId);

    /*
    * @Description: method that get rating tool for post-triage only exclusive, after ffss screen
    */
    List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> postTriageStep(String accHasId);

    /*
    * @Description: method that get rating tool for both-triage, after ffss screen
    */
    List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> bothTriageStep(String accHasId);

    /*
    * @Description: method that implements the validation of financial statements
    */
    List<arce__Financial_Statements__c> validateFSForRating(List<arce__Financial_Statements__c> ffss, String ratingTool);

    /*
    * @Description: method that implements local logic to show or hide rating and pre-rating buttons
    */
    List<String> checkRatingToolId(String analysisId, String ratingTool);

    /*
    * @Description: method that returns the decision to invoke ratios engine in IRP wizard
    */
    Boolean invokeRatiosEngine(String accHasId, String ratingTool);
}