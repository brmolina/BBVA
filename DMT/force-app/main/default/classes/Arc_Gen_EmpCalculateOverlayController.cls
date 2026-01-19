/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EmpCalculateOverlayController
* @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
* @Date     Created: 10/05/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Contains the logic of overlays calculation.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |10/5/2021 joseluis.garcia4.contractor@bbva.com
*            Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_EmpCalculateOverlayController {
    public class NoRatingException extends Exception { }

    private static final String QUALITATIVE_SERVICE = 'qualitativeBlocks';

    private static final String PERSISTENCE_CONFIG = 'empPersistenceOverlays';

    /**
    * Empty constructor to avoid static code analysis tool warnings.
    */
    private Arc_Gen_EmpCalculateOverlayController() { } //NOPMD

    /**
    * --------------------------------------------------------------------------------------
    * @description Gets overlay support for ARCE or org.
    * @param ahaId Id of the account has analysis.
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getOverlaySupport(String ahaId) {
        // Check if ARCE has overlay record created.
        final List<arce__Overlay__c> ovlList = arce.Arc_Gen_Overlays_Utils.getOverlaysByAha(new Set<String> { ahaId });

        // Check if overlays enabled.
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EnableOverlays');
        Boolean overlaysEnabled = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
        String supportStatus;

        if (!ovlList.isEmpty()) {   //NOSONAR
            supportStatus = 'supported';
        } else if (overlaysEnabled) {
            supportStatus = 'arceDisabled';
        } else {
            supportStatus = 'orgDisabled';
        }
        return supportStatus;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description Call the persistModifiers engine
    * @param aHasAnalysId Id of the account has analysis.
    * @param methodType persistence type name.
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_Gen_PersistModifiers_Service.VariablePersistenceResult callPersistModifiers(String aHasAnalysId, String methodType) {
        arce.Arc_Gen_PersistModifiers_Service.VariablePersistenceResult response = new arce.Arc_Gen_PersistModifiers_Service.VariablePersistenceResult();
        try {
            final arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaFullObject = Arc_Gen_ArceDataModel_Locator.getFullFieldsAha(aHasAnalysId);
            final arce.Arc_Gen_PersistModifiers_Service calloutService = new arce.Arc_Gen_PersistModifiers_Service(QUALITATIVE_SERVICE, PERSISTENCE_CONFIG, true);
            response = calloutService.persistVariablesOfAnalysis(ahaFullObject);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            final Map<String, Object> errWrapper = new Map<String, Object>();
            errWrapper.put('errorCode', '403');
            errWrapper.put('errorTitle', arce.Arc_Gen_RatingGlobal_Constants.ERROR_TEXT);
            errWrapper.put('errorMessage', System.Label.Arc_Gen_RatingError_GenericError);
            response.serviceCode = '403';
            response.serviceMessage = JSON.serialize(errWrapper);
        }
        return response;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description Call the Persistence service to retrieve the answers options
    * @param aHasAnalysId Id of the account has analysis.
    * @return Returns a list of missing elements to complete
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callOverlayRating(String aHasAnalysId) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            checkRatingCalculated(aHasAnalysId);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{aHasAnalysId})[0];
            response = arce.Arc_Gen_RatingGlobal_service.setupRating(accHasAnalysis, null, arce.Arc_Gen_RatingGlobal_Constants.METHOD_OVERLAY);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            final Map<String, Object> errWrapper = new Map<String, Object>();
            errWrapper.put('errorCode', '403');
            errWrapper.put('errorTitle', arce.Arc_Gen_RatingGlobal_Constants.ERROR_TEXT);
            errWrapper.put('errorMessage', ex.getMessage());
            response.serviceCode = '403';
            response.serviceMessage = JSON.serialize(errWrapper);
        }
        return response;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description Checks that the rating is calculated; throws exception otherwise.
    * @param aHasAnalysId Id of the account has analysis.
    * --------------------------------------------------------------------------------------
    **/
    private static void checkRatingCalculated(String aHasAnalysId) {
        final arce__Account_has_Analysis__c accHasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(aHasAnalysId);
        if (accHasAn.arce__ffss_for_rating_id__r.arce__rating_id__c == null) {
            throw new NoRatingException(System.Label.Arc_Gen_NoRating_Error);
        }
    }
}