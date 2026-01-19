/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_OraclePers_service
* @Author   Javier Soto Carrascosa
* @Date     Created: 04/042020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages webservice callouts for basic data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-04 Javier Soto Carrascosa
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-01 Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
*             Add bankingRelationshipWS method.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_OraclePers_service {
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_OraclePers_service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Javier Soto
    * @Date     2020-04-06
    * @param    null
    * @return   Arc_Gen_OraclePers_service
    * @example  new Arc_Gen_OraclePers_service()
    * */
    @TestVisible
    private Arc_Gen_OraclePers_service() {}
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for basic info callout
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param String - participantId
    * @param String - riskassessmentId
    * @param Map<String, Object> - wsJson
    * @return boolean - callout executed OK / KO
    * @example addIndicators(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean basicInfoWS(String participantId, String riskassessmentId, Map<String, Object> wsJson) {
      Boolean calloutOK = true;
      if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(wsJson)) {
        final String templateIASO = '{"risk-assessment-id" : "' + riskassessmentId +'","participant-id" : "' + participantId +'","JSONIN" : ' + JSON.serialize(JSON.serialize(wsJson)) +'}';
        calloutOK =Arc_Gen_Persistence_Utils.executePersistence('bassicData', templateIASO);
      }
      return calloutOK;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for business risk info callout
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param String - participantId
    * @param String - riskassessmentId
    * @param String - wsJson
    * @return boolean - callout executed OK / KO
    * @example addIndicators(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean businessRiskWS(String participantId, String riskassessmentId, Map<String, Object> wsJson) {
        Boolean calloutOK = true;
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(wsJson)) {
            final String templateIASO = '{"risk-assessment-id" : "' + riskassessmentId +'","participant-id" : "' + participantId +'","JSONIN" : ' + JSON.serialize(JSON.serialize(wsJson)) +'}';
            calloutOK = Arc_Gen_Persistence_Utils.executePersistence('businessrisk', templateIASO);
        }
        return calloutOK;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for financial statements info callout
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 08/04/2020
    * @param String - participantId
    * @param String - riskassessmentId
    * @param String - wsJson
    * @return boolean - callout executed OK / KO
    * @example addIndicators(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean financialRiskWS(String participantId, String riskassessmentId, Map<String, Object> wsJson) {
        Boolean calloutOK = true;
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(wsJson)) {
            final String templateIASO = '{"risk-assessment-id" : "' + riskassessmentId +'","participant-id" : "' + participantId +'","JSONIN" : ' + JSON.serialize(JSON.serialize(wsJson)) +'}';
            calloutOK = Arc_Gen_Persistence_Utils.executePersistence('financialStatementsPersist', templateIASO);
        }
        return calloutOK;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for financial statements info callout
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param String - participantId
    * @param String - riskassessmentId
    * @param String - wsJson
    * @return boolean - callout executed OK / KO
    * @example bankingRelationshipWS(participantId, riskassessmentId, wsJson)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean bankingRelationshipWS(String participantId, String riskassessmentId, Map<String, Object> wsJson) {
      Boolean calloutOK = true;
      if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(wsJson)) {
          final String templateIASO = '{"risk-assessment-id" : "' + riskassessmentId +'","participant-id" : "' + participantId +'","JSONIN" : ' + JSON.serialize(JSON.serialize(wsJson)) +'}';
          calloutOK = Arc_Gen_Persistence_Utils.executePersistence('mainBureauPersist', templateIASO);
      }
      return calloutOK;
  }
}