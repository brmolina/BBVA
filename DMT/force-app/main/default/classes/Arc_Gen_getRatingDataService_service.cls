/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_getRatingDataService_service
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 30/4/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Contains the logic to assign the different rating variables to salesforce fields
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |30/4/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |23/7/2019  eduardoefrain.hernandez.contractor@bbva.com
*             Refactor
* |26/9/2019  javier.soto.carrascosa@bbva.com
*             Remove mock
* |22/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Refactor
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |24-01-2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             Change logic of parameters used in ASO services
* |18-02-2020 ricardo.almanza.contractor@bbva.com
*             added rating to keep null to keep the flow on calculate rating
* |27-03-2020 cesaroctavio.villanueva.cebal@bbva.com
*			  Used the correct custom label for error when a valid FS hasn't been selected
* |27-04-2020 juanignacio.hita.contractor@bbva.com
*			  Added "validationQualitativeQuestion" method
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Modify class in order to manage the call to the rating service for a previous ffss
* |2020-04-28 eduardoefrain.hernandez.contractor@bbva.com
*             Modified setupRating method to factorize the customerNumber
* |2020-06-29 mariohumberto.ramirez.contractor@bbva.com
*             Update class for HU GADRDCDE-1577 Mejora Tabla Información Financiera
*             The call to the rating service for the previous financial statement was eliminated.
* |2020-07-27 juanignacio.hita.contractor@bbva.com
*             Fix validation for finded a valid eeff to call rating engine.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Adapt implementation to use the one provided in dependencies package.
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
* 			  Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
* 			  Added annotation '@testVisible' to the empty constructor method.
* |2021-05-10 joseluis.garcia4.contractor@bbva.com
*             Add error when a valid FFSS is not selected + Parent subsidiary overlay applicability.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_getRatingDataService_service {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_getRatingDataService_service() { }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the response from the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId
    * @param String customerId
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with the result of a DML operation and service call
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupRating(String analysisId,String customerId)
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse setupRating(String analysisId, String customerId, String mockCode, String serviceMock) {
        final arce__Account_has_Analysis__c analysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{analysisId})[0];

        // Get subEventType to use from analysis.
        String subEventType = arce.Arc_Gen_RatingGlobal_Constants.RATINGCAL;
        final String subprocessType = analysis.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c;
        final String ratingPreratingType = analysis.arce__Analysis__r.arce__rating_prerating_type__c;
        if (subprocessType == '4' && ratingPreratingType == 'Prerating') {
            subEventType = arce.Arc_Gen_RatingGlobal_Constants.RATINGPRE;
        }

        // Check for valid FFSS.
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp;
        if (analysis.arce__ffss_for_rating_id__r.arce__ffss_valid_type__c == '1') {
            serviceAndSaveResp = arce.Arc_Gen_RatingGlobal_Service.setupRating(analysis, null, subEventType);
            serviceAndSaveResp = arce.Arc_Gen_RatingGlobal_helper.updateLeveragedVars(serviceAndSaveResp, analysis);

            // Calculate if parent/subsidiary overlay is applicable for this client.
            calculatePSOverlayApplicability(analysis);
        } else {
            serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
            final Map<String, Object> errWrapper = new Map<String, Object>();
            errWrapper.put('errorCode', '400');
            errWrapper.put('errorTitle', System.Label.Arc_Gen_Rrs_no_ffss);
            errWrapper.put('errorMessage', System.Label.Cls_arce_RatingNoValidFFSS);
            serviceAndSaveResp.serviceCode = '400';
            serviceAndSaveResp.serviceMessage = JSON.serialize(errWrapper);
        }
        return serviceAndSaveResp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the customer data form the data class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId
    * @return List<String>
    * @example public static List<String> getCustomerData(String analysisId)
    **/
    public static List<String> getCustomerData(String analysisId) {
        List<String> customerData = new List<String>();
        customerData = arce.Arc_Gen_RatingGlobal_data.getCustomerData(analysisId);
        Return customerData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that validates qualitative questions and returns a list with the dev name empty fields
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 27/4/2020
    * @param String accHasId
    * @param mapTabset map tabset
    * @return Map<String, List<dyfr__Field_Config__c>>
    * @example public static Map<String, List<dyfr__Field_Config__c>> map = validationQualitativeQuestion(accHasId, mapTabset);
    **/
    public static Map<String, List<dyfr__Field_Config__c>> validationQualitativeQuestion(String accHasId, Map<String, String> mapTabset) {
        Map<String, List<dyfr__Field_Config__c>> mapRet = new Map<String, List<dyfr__Field_Config__c>>();
        // Get Interface from custom metadata config
        final Arc_Gen_ValidationsRating_Interface controllerClass = Arc_Gen_GenericUtilitiesInterface.qualitativeQuestionValidation();
        if (controllerClass != null) {
            List<String> lstFcIds = new List<String>();
            Map<String, List<String>> mapTemplateFc = new Map<String, List<String>>();
            for (String nTemplate : mapTabset.keySet()) {
                // Return list devName with all the empty fields of the template
                final List<String> lstEmptyFc = controllerClass.validateQualitativeQuestion(accHasId, nTemplate);
                if (!lstEmptyFc.isEmpty()) {
                    mapTemplateFc.put(mapTabset.get(nTemplate), lstEmptyFc);
                    lstFcIds.addAll(lstEmptyFc);
                }
            }
            // Get query of all the empty fc, return a map of key dyfr__DeveloperName__c and value field config
            final Map<String, dyfr__Field_Config__c> mapSearchFc = Arc_Gen_FieldConfig_Data.getDevFieldsInfo(lstFcIds);
            mapRet = Arc_Gen_FieldConfig_Data.fillMapTabset(mapSearchFc, mapTemplateFc);
        }
        return mapRet;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calculates applicability of the Parent/Subsidiary overlay.
    * Also enables "Calculate Overlay" button depending on the presence of an overlay record
    * associated with the AHA.
    --------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 04/05/2021
    * @param arce__Account_has_Analysis__c aha
    **/
    private static void calculatePSOverlayApplicability(arce__Account_has_Analysis__c aha) {
        Boolean psApplicable = false;

        // Set "Calculate Overlay" button visibility.
        final List<arce__Overlay__c> overlays = arce.Arc_Gen_Overlays_Utils.getOverlaysByAha(new Set<String> { aha.Id });
        aha.Arc_Gen_Ent_CalculateOverlay_Enabled__c = overlays.isEmpty() ? '2' : '1';

        // Check if not group and is not holding.
        final Id customerId = aha.arce__Customer__c;
        final arce.Arc_Gen_Account_Wrapper actWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { customerId }).get(customerId);
        final Boolean isGroup = actWrapper.participantType == 'GROUP';
        final Boolean isHolding = aha.arce__main_subsidiary_ind_type__c;

        if (!isGroup && !isHolding) {
            // Check EnableParentSubsidiary config.
            final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EnableParentSubsidiary');
            if (!configMetadata.isEmpty()) {
                psApplicable = Boolean.valueOf(configMetadata[0].arce__Value1__c);
            }
        }

        // Update AHA
        aha.Arc_Gen_Ent_ParentSubsidiary_Enabled__c = psApplicable ? '1' : '2';
        arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(aha);
    }
}