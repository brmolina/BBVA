/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsFinalize_Service
* @Author         marcos.gimeno.next@bbva.com
* @Date           04-09-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for finalize rating process.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 04-09-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_IFIS_ButtonsFinalize_Service {
    /** @description Service message class**/
    static final arce.Arc_Gen_CustomServiceMessages SERVICE_MESSAGES = new arce.Arc_Gen_CustomServiceMessages();
    /** @description True reponse string.**/
    static final String RESPONSE_TRUE = 'true';
    /** @description False reponse string.**/
    static final String RESPONSE_FALSE = 'false';
    /** @description Status for a validated rating.**/
    static final String STATUS_VALIDATE = '3';
    /** @description Name of the rating validation service.**/
    static final String SERVICE_PERSISTENCE = 'IFIS_ValidationPersistence';
    /** @description Name of the rating validation service.**/
    static final String SERVICE_ENGINE = 'IFIS_RatingEngineValidation';
    /** @description Default message string.**/
    static final String DEFAULT_MESSAGE = 'Show';
    /** @description Title of the service error message string.**/
    static final String ERROR_TITLE = 'errorTitle';
    /** @description Message of the service error message string.**/
    static final String ERROR_MESSAGE = 'errorMessage';

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Empty constructor to avoid sonar warnings.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_IFIS_ButtonsFinalize_Service() {
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description This method gets the rating data for a given Aha record and returns it as a
    *              arce.Arc_IFIS_Buttons_Wrp.ValidateResponse object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaId       arce__Account_has_Analysis__c record
    * @return   The modified response object for validated operations.
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = getRatingData(aha)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse getRatingData(
        arce__Account_has_Analysis__c aha,
        String buttonType
    ) {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse response;
        final Map<String, String> labelByType = new Map<String, String>{
            'PROPOSAL' => System.Label.arce.Arc_Gen_RecalcRatWarning,
            arce.Arc_Gen_RatingGlobal_Constants.FINALIZATION => System.Label.arce.Arc_Gen_RecalcRatWarningPre,
            arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL => System.Label.arce.Arc_Gen_RecalcRatWarningVal
        };

        try {
            if (
                arce.Arc_IFIS_Buttons_Helper.isRating(aha.arce__Analysis__r.arce__rating_prerating_type__c) ||
                aha.arce__Analysis__r.arce__is_RTC__c
            ) {
                final Map<String, Object> data = new Map<String, Object>();
                arce.Arc_IFIS_Buttons_Wrp.DelegationWrapper wrapper;
                arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();
                final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(aha.Id);

                String message = DEFAULT_MESSAGE;
                final arce__Account_has_Analysis__c ahaRating = locator.getAccountHasAnalysis(aha.Id)[0];
                final Decimal ratingAfterProp = ahaRating.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__final_rating_after_propose__c;
                final Decimal ratingToValidate = ahaRating.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c;
                final Decimal ratingStandAfterProp = ahaRating.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_standalone_after_prop__c;
                final Decimal ratingStandToValidate = ahaRating.arce__total_rating_score_number__c;
                data.put('wfType', ahaRating.arce__IRP_Workflow__c);
                data.put('subProcessType', ahaRating.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
                data.put('ratingId', ahaRating.arce__ffss_for_rating_id__r.arce__rating_id__c);
                // data.put('financialType', ahaRating.arce__AHA_Extension__r.arce__Financial_Type__c);
                final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(
                    System.UserInfo.getUserId()
                );
                final Arc_Gen_Delegation_Wrapper wrapperDeleg = Arc_Gen_Propose_Helper.initDelegation(
                    wrpUser.ambitUser,
                    arceVar.Id,
                    'RAIP-PROPOSE',
                    false
                );
                System.debug('Revisar Delegacion ' + wrapperDeleg.lstRegion);
                data.put('lstRegion', wrapperDeleg.lstRegion);
                if (ahaRating.arce__recalculate_rating__c != null && ahaRating.arce__recalculate_rating__c != '4') {
                    final Map<String, String> mapa = arce.Arc_Gen_GenericUtilities.getMapLabelFromValue(
                        'arce__Account_has_Analysis__c',
                        'arce__recalculate_rating__c'
                    );
                    if (!mapa.isEmpty() && mapa.get(ahaRating.arce__recalculate_rating__c) != null) {
                        String recalc = mapa.get(ahaRating.arce__recalculate_rating__c).toLowerCase();
                        message = labelByType.get(buttonType) + ' ' + recalc;
                    }
                }
                data.put('recalculateRating', message);
                data.put(
                    'showValidatedBy',
                    ratingAfterProp != ratingToValidate || ratingStandAfterProp != ratingStandToValidate
                );
                data.put('proposeUser', ahaRating.arce__Analysis__r.arce__proposeUser__c);

                wrapper = arce.Arc_IFIS_Buttons_Helper.initDelegation(null, null, 'PROPOSE');
                data.put('ambitList', wrapper.lstAmbits);

                response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(data, true, null);
            } else {
                // Initialize variables and collections
                final Map<String, Object> data = new Map<String, Object>();
                final String message = DEFAULT_MESSAGE;

                // Add key-value pairs to the data map
                data.put('subProcessType', aha.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
                data.put('ratingId', aha.arce__ffss_for_rating_id__r.arce__rating_id__c);
                data.put('recalculateRating', message);

                response = arce.Arc_IFIS_Buttons_Helper.isRatingValid(aha, data);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Sets up and validates a rating by user.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    validationWrap    The validation wrapper object.
    * @return   Response object for rating operations.
    * @example  arce.Arc_Gen_ServiceAndSaveResponse e = setupValidateRatingByUser(validationWrap)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse setupValidateRatingByUser(
        arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validationWrap,
        arce__Analysis__c analysis
    ) {
        // Create a new service and save response object
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();

        // Get the analyzed client associated with the validation wrapper
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(
            new List<String>{ validationWrap.analyzedClientId }
        )[0];

        // Set helper parameters for the rating validation
        final String subevent = getSubEventType(analyzedClient.ahaObj);
        final arce.Arc_Gen_RatingGlobal_helper.HelperParameters helperWrap = new arce.Arc_Gen_RatingGlobal_helper.HelperParameters(
            analyzedClient.ahaObj,
            validationWrap.ratingId,
            validationWrap.userId,
            subevent
        );
        helperWrap.setBankId(analyzedClient.accWrapperObj.bankId);
        final String parametersJson = arce.Arc_IFIS_Buttons_Helper.isRating(analysis.arce__rating_prerating_type__c)
            ? setServParamsPersistence(helperWrap)
            : arce.Arc_Gen_RatingGlobal_helper.setServiceParameters(helperWrap);

        try {
            // Call the rating service
            final arce.Arc_Gen_getIASOResponse.serviceResponse serviceResp = new arce.Arc_Gen_RatingGlobal_data()
                .callRatingService(
                    parametersJson,
                    arce.Arc_IFIS_Buttons_Helper.isRating(analysis.arce__rating_prerating_type__c)
                        ? SERVICE_PERSISTENCE
                        : SERVICE_ENGINE
                );

            // Process the response
            response = processRatingResponse(serviceResp, analyzedClient.ahaObj);

            // Set traceability if save was successful
            if (response.saveStatus == RESPONSE_TRUE) {
                setTraceability(validationWrap, helperWrap, analysis);
            }
        } catch (CalloutException e) {
            response.saveStatus = RESPONSE_FALSE;
            response.serviceMessage = e.getMessage();
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Handle success service response.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     01-08-2023
    * @param    valDataWrap    Wrapper with validation parameters
    * @param    saveStatus            Service status response
    * @param    saveMessage           Save message response
    * @return   Wrapper with success response
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = handleValidationSuccess(valDataWrap, saveStatus, saveMessage)
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:UnusedLocalVariable, sf:DUDataflowAnomalyAnalysis')
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse handleValidationSuccess(
        Arc_IFIS_Buttons_Wrp.ValidationData valDataWrap,
        Boolean saveStatus,
        String saveMessage,
        arce__Analysis__c analysis
    ) {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse response;

        arce.Arc_Gen_GenericUtilities.SaveResult saveRes = updateData(
            valDataWrap.ratingId,
            valDataWrap.description,
            analysis.Id
        );
        if (saveRes.status == RESPONSE_FALSE) {
            response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(null, false, System.Label.arce.Arc_IFIS_Error_Update);
        } else {
            if (arce.Arc_IFIS_Buttons_Helper.isRating(analysis.arce__rating_prerating_type__c)) {
                List<arce__Rating_Copy__c> ratingCopies = arce.Arc_IFIS_RatingCopy_Data.getRecords(
                    new List<String>{ valDataWrap.ahaId }
                );

                if (!ratingCopies.isEmpty()) {
                    ratingCopies = arce.Arc_IFIS_RatingCopy_Data.removeDeletedRecords(ratingCopies);

                    final Integer syncLimit = Integer.valueOf(
                        arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('IFIS_SyncCloneLimit')[0].arce__Value1__c
                    );

                    if (ratingCopies.size() <= syncLimit) {
                        // Synchronous operation
                        arce.Arc_IFIS_CloneRating.cloneRatingProcess(valDataWrap.ahaId, ratingCopies);
                    } else {
                        // Asynchronous operation
                        Id jobID = System.enqueueJob(new arce.Arc_IFIS_CloneRating(valDataWrap.ahaId, ratingCopies));
                    }
                }
            }
            response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(null, saveStatus, saveMessage);
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Handle failure service response.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     01-08-2023
    * @param    serviceMessage    Service message response in json format
    * @return   Wrapper with success response
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = handleValidationFailure(serviceMessage)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse handleValidationFailure(String serviceMessage) {
        final Map<String, Object> servMessageDes = (Map<String, Object>) JSON.deserializeUntyped(serviceMessage);
        final String errorMessage = servMessageDes.get(ERROR_TITLE) + ': ' + servMessageDes.get(ERROR_MESSAGE);

        return arce.Arc_IFIS_Buttons_Helper.createResponseObj(null, false, errorMessage);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Fetch uses by ambit.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    selectedAmbit    Selected ambit
    * @return   Wrapper with the information to be returned to the component
    * @example  arce.Arc_IFIS_Buttons_Wrp.DelegationWrapper e = fetchUsersByAmbit(selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_IFIS_Buttons_Wrp.DelegationWrapper fetchUsersByAmbit(String selectedAmbit) {
        final arce.Arc_IFIS_Buttons_Wrp.DelegationWrapper wrapper = new arce.Arc_IFIS_Buttons_Wrp.DelegationWrapper();
        try {
            wrapper.lstUsers = getUsersAmbit(selectedAmbit);
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error in proposing action : ' + e.getMessage();
        }
        return wrapper;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Returns the subevent type based on the given aha object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaObj    Aha object record
    * @return   Subevent type based on the given aha object.
    * @example  Strin e = getSubEventType(ahaObj)
    * -----------------------------------------------------------------------------------------------
    **/
    private static String getSubEventType(arce__Account_has_Analysis__c ahaObj) {
        return arce.Arc_IFIS_Buttons_Helper.isRating(ahaObj.arce__Analysis__r.arce__rating_prerating_type__c) ||
            String.isBlank(ahaObj.arce__Analysis__r.arce__rating_prerating_type__c)
            ? arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL
            : arce.Arc_Gen_RatingGlobal_Constants.FINALIZATION;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Processes the response from service request.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    response          The response object for validated operations.
    * @param    analyzedClient    The analyzed client associated with the service response.
    * @return   Response object for rating operations.
    * @example  arce.Arc_Gen_ServiceAndSaveResponse e = processRatingResponse(response,analyzedClient )
    * -----------------------------------------------------------------------------------------------
    **/
    private static arce.Arc_Gen_ServiceAndSaveResponse processRatingResponse(
        arce.Arc_Gen_getIASOResponse.serviceResponse response,
        arce__Account_has_Analysis__c analyzedClient
    ) {
        final arce.Arc_Gen_ServiceAndSaveResponse servAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final arce.Arc_Gen_CustomServiceMessages servMessagesWrap = new arce.Arc_Gen_CustomServiceMessages();

        // Set the service code and message
        servAndSaveResp.serviceCode = response.serviceCode;
        servAndSaveResp.serviceMessage = response.serviceMessage;

        if (servAndSaveResp.serviceCode.contains('20')) {
            // If the service code is success, change the rating status for the analyzed client
            final List<String> changeStatus = changeRatingStatus(analyzedClient);
            servAndSaveResp.saveStatus = changeStatus[0];
            servAndSaveResp.saveMessage = changeStatus[1];

            setDestinationRatingId(response, analyzedClient);
        } else {
            servAndSaveResp.serviceMessage = response.serviceCode == String.valueOf(servMessagesWrap.CODE_400) ||
                response.serviceCode == String.valueOf(servMessagesWrap.CODE_500)
                ? JSON.serialize(
                      arce.Arc_Gen_RatingErrorManagement.processErrorData(
                          response,
                          arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL
                      )
                  )
                : response.serviceMessage;
        }

        return servAndSaveResp;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Changes the rating status for an analyzed client and returns a list containing the
    *              status and message of the save result.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    analyzedClient    The analyzed client associated with the service response.
    * @return   A list containing the status and message of the save result.
    * @example  List<String> e = changeRatingStatus(analyzedClient)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<String> changeRatingStatus(arce__Account_has_Analysis__c analyzedClient) {
        final arce.Arc_Gen_RatingGlobal_data dataAccess = new arce.Arc_Gen_RatingGlobal_data();

        // Get the analysis data and rating data objects for the analyzed client
        final List<arce__Analysis__c> arceAnalysisData = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(
            new List<Id>{ analyzedClient.arce__Analysis__c }
        );
        final List<arce__rating__c> ratingData = arce.Arc_Gen_Rating_data.generalRatingData(
            new List<String>{ analyzedClient.arce__ffss_for_rating_id__r.arce__rating_id__c }
        );

        // Update the rating status
        ratingData[0].arce__status_type__c = STATUS_VALIDATE;

        // Update the rating and ArceAnalysisData objects
        final arce.Arc_Gen_RatingGlobal_data.SaveResult result = dataAccess.updateRecords(
            new List<sObject>{ ratingData[0], arceAnalysisData[0] }
        );

        // Return the status and message of the save result in a list
        return new List<String>{ result.status, result.message };
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Map the IASO service response and update arce__Rating_Copy__c records.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     11-07-2023
    * @param    response          IASO service response
    * @param    analyzedClient    Current arce__Account_has_Analysis__c record
    * @return   void
    * @example  setDestinationRatingId(response, analyzedClient)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void setDestinationRatingId(
        arce.Arc_Gen_getIASOResponse.ServiceResponse response,
        arce__Account_has_Analysis__c analyzedClient
    ) {
        final Map<String, Map<String, String>> transformedMap = transformResponseMap(response);
        if (!transformedMap.isEmpty()) {
            final List<arce__Rating_Copy__c> ratingCopies = arce.Arc_IFIS_RatingCopy_Data.getRecords(
                new List<String>{ analyzedClient.Id }
            );
            updateRatingCopies(ratingCopies, transformedMap);
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Helper method to transform response map.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     21-08-2023
    * @param    response    IASO service response
    * @return   Transformed response map
    * @example  Map<String, Map<String, String>> e = transformResponseMap(response)
    * -----------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private static Map<String, Map<String, String>> transformResponseMap(
        arce.Arc_Gen_getIASOResponse.ServiceResponse response
    ) {
        Map<String, Map<String, String>> transformedMap = new Map<String, Map<String, String>>();

        final Map<String, Object> dataMap = (Map<String, Object>) response.serviceResponse.get('data');
        if (dataMap != null) {
            final Map<String, Object> rtgCalcMap = (Map<String, Object>) dataMap.get('ratingCalculation');
            if (rtgCalcMap != null) {
                final List<Object> countriesList = (List<Object>) rtgCalcMap.get('countries');

                if (countriesList != null && !countriesList.isEmpty()) {
                    transformedMap = processCountriesList(countriesList);
                }
            }
        }

        return transformedMap;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Helper method to transform country map.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     05-09-2023
    * @param    countriesList    List of countries
    * @return   List of participants by country
    * @example  Map<String, Map<String, String>> e = processCountriesList(countriesList)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Map<String, String>> processCountriesList(List<Object> countriesList) {
        final Map<String, Map<String, String>> transformedMap = new Map<String, Map<String, String>>();

        for (Object countryObj : countriesList) {
            final Map<String, Object> countryMap = (Map<String, Object>) countryObj;
            final String countryId = (String) countryMap.get('id');

            final List<Object> participantsList = (List<Object>) countryMap.get('participants');
            final Map<String, String> partRtgMap = new Map<String, String>();

            if (participantsList != null && !participantsList.isEmpty()) {
                for (Object participantObj : participantsList) {
                    final Map<String, Object> participantMap = (Map<String, Object>) participantObj;
                    final String participantId = (String) participantMap.get('id');
                    final Map<String, Object> ratingMap = (Map<String, Object>) participantMap.get('rating');

                    if (ratingMap != null) {
                        final String ratingId = String.valueOf(ratingMap.get('id'));
                        partRtgMap.put(participantId, ratingId);
                    }
                }
            }

            transformedMap.put(countryId, partRtgMap);
        }

        return transformedMap;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Helper method to update rating copies.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     21-08-2023
    * @param    ratingCopies      List of arce__Rating_Copy__c records
    * @param    transformedMap    Transformed response map
    * @return   void
    * @example  updateRatingCopies(ratingCopies, transformedMap)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void updateRatingCopies(
        List<arce__Rating_Copy__c> ratingCopies,
        Map<String, Map<String, String>> transformedMap
    ) {
        for (arce__Rating_Copy__c ratingCopy : ratingCopies) {
            final String country = ratingCopy.arce__Country_Ceiling__r.arce__g_country_subdivision_id__c;
            if (transformedMap.containsKey(country)) {
                final Map<String, String> mapData = transformedMap.get(country);
                final String alphaCode = ratingCopy.arce__Alpha_Code__c;
                if (
                    mapData.containsKey(alphaCode) &&
                    ratingCopy.arce__Destination_Rating_Id__c != mapData.get(alphaCode)
                ) {
                    ratingCopy.arce__Destination_Rating_Id__c = mapData.get(alphaCode);
                } else {
                    ratingCopy.arce__Destination_Rating_Id__c = ratingCopy.arce__Source_Rating_Id__c;
                }
            } else {
                ratingCopy.arce__Destination_Rating_Id__c = ratingCopy.arce__Source_Rating_Id__c;
            }
        }

        arce.Arc_IFIS_RatingCopy_Data.updateRecords(ratingCopies);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Set persistence service parameters.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    helperWrap    Rating helper wrapper
    * @return   Serialize persistence service parameters
    * @example  String e = setServParamsPersistence(helperWrap)
    * -----------------------------------------------------------------------------------------------
    **/
    private static String setServParamsPersistence(arce.Arc_Gen_RatingGlobal_helper.HelperParameters helperWrap) {
        final Arc_IFIS_Buttons_Wrp.ServPersisenceParams parameters = new Arc_IFIS_Buttons_Wrp.ServPersisenceParams();

        parameters.eventType = helperWrap.event;
        parameters.subEventType = helperWrap.subEvent;
        parameters.businessAgentId = helperWrap.userInfo?.businessAgentId;
        parameters.bankId = helperWrap.bankId;
        parameters.branchId = helperWrap.userInfo?.branchId;
        parameters.branchLevel = helperWrap.userInfo?.branchlevel;
        parameters.participantId = helperWrap.participantId;
        parameters.participantType = helperWrap.participationType;
        parameters.evaluationDate = String.valueOf(DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        parameters.ratingId = helperWrap.calcRatingId;
        parameters.riskAssessmentId = helperWrap.accHasAnalysis.Name;
        parameters.clientType = helperWrap.clientTypeIFIS;

        return JSON.serialize(parameters, true);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Set traceability for the finalize process.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    validationWrap    Validation wrapper
    * @param    helperWrap        Rating helper wrapper
    * @param    analysis          arce__Analysis__c record
    * @return   void
    * @example  setTraceability(validationWrap, helperWrap, analysis)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void setTraceability(
        arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validationWrap,
        arce.Arc_Gen_RatingGlobal_helper.HelperParameters helperWrap,
        arce__Analysis__c analysis
    ) {
        //Choosing ambit
        final String ambit = String.isBlank(validationWrap.ambitSelected)
            ? analysis.arce__anlys_wkfl_edit_br_level_type__c
            : validationWrap.ambitSelected;
        final String strAmbit = arce.Arc_Gen_GenericUtilities.getLabelFromValue(
            'arce__Analysis__c',
            'arce__anlys_wkfl_edit_br_level_type__c',
            ambit
        );
        //User or Committee
        final String ifComite = helperWrap.userInfo?.businessAgentId == 'COMITE' ? 'Committee' : '';
        final String userName = helperWrap.userInfo?.userBasicInfo == null
            ? ifComite
            : helperWrap.userInfo?.userBasicInfo.name;

        String traceComments = setTraceComments(userName, strAmbit, validationWrap);
        arce.Arc_IFIS_Traceability.saveStatusEvent(analysis.Id, 'Validated', traceComments.abbreviate(255));
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Set trace comments for traceability.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    userName          User who validated the process
    * @param    strAmbit          Selected ambit
    * @param    validationWrap    Rating validation wrapper
    * @return   Trace comments
    * @example  setTraceComments(userName, strAmbit, validationWrap)
    * -----------------------------------------------------------------------------------------------
    **/
    private static String setTraceComments(
        String userName,
        String strAmbit,
        arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validationWrap
    ) {
        String traceComments = '';

        traceComments = System.Label.arce.Arc_IFIS_Traceability_Validate + ' ' + userName;

        if (!String.isEmpty(strAmbit)) {
            traceComments += ' | ' + System.Label.arce.Arc_IFIS_Traceability_Ambit + ': ' + strAmbit;
        }

        if (!String.isEmpty(validationWrap.commentary)) {
            traceComments += ' | ' + System.Label.arce.Arc_IFIS_Traceability_Comment + ': ' + validationWrap.commentary;
        }

        return traceComments;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Fetch users by ambit.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    selectedAmbit    Selected ambit
    * @return   List of users by ambit
    * @example  List<Map<String, String>> e = getUsersAmbit(selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String, String>> getUsersAmbit(String selectedAmbit) {
        final String ambitString = getStringAmbit(selectedAmbit);
        final List<User> userByAmbitList = getUserByAmbit(ambitString);

        final List<Map<String, String>> userMapList = new List<Map<String, String>>();
        for (User usr : userByAmbitList) {
            userMapList.add(new Map<String, String>{ 'label' => usr.Name, 'value' => usr.Id });
        }
        return userMapList;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Implementation to convert possible values of selected ambit to the specified value
    *              for ambit field in User object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    selectedAmbit    Selected ambit
    * @return   Transformed selected ambit
    * @example  String e = getStringAmbit(String selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    private static String getStringAmbit(String selectedAmbit) {
        return null;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Returns a list of user filtered by ambit parameter.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     05-09-2023
    * @param    ambitString    Ambit in string format
    * @return   List of user filtered by ambit parameter
    * @example  List<User> e = getUserByAmbit(ambitString)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<User> getUserByAmbit(String ambitString) {
        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = TRUE
            ORDER BY Name ASC
        ];
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Updates the description of a rating record.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ratingId       The ID of the rating record to update
    * @param    description    The new description for the rating record
    * @param    description    The ID of the analysis record to update
    * @return   DML result
    * @example  arce.Arc_Gen_GenericUtilities.SaveResult e = updateData(ratingId, description, analysis)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_GenericUtilities.SaveResult updateData(
        String ratingId,
        String description,
        String analysisId
    ) {
        final List<SObject> toUpdate = new List<SObject>();

        if (String.isNotBlank(ratingId)) {
            final arce__Rating__c ratingToUpd = new arce__Rating__c(
                Id = ratingId,
                arce__Arc_Gen_ValidationCommentary__c = description
            );
            toUpdate.add(ratingToUpd);
        }
        if (String.isNotBlank(analysisId)) {
            final arce__Analysis__c analysisToUpd = new arce__Analysis__c(
                Id = analysisId,
                arce__end_date__c = System.today(),
                arce__Stage__c = arce.Arc_Gen_Constants.STAGE_FINALIZED,
                arce__wf_status_id__c = arce.Arc_Gen_Constants.RAIP_STATUS_FINALIZED
            );
            toUpdate.add(analysisToUpd);
        }

        return arce.Arc_Gen_GenericUtilities.updateRecords(toUpdate);
    }
}