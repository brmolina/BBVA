/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateRating_service
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 23/07/2019
* @Group    ARCE Team
* ----------------------------------------------------------------------------------------------
* @Description Class that contain the logic of the rating validation
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |13/5/2019  eduardoefrain.hernandez.contractor@bbva.com
*             Initial Version
* |26/9/2019  javier.soto.carrascosa@bbva.com
*             Remove mock
* |19/12/2019 manuelhugo.castillo.contractor@bbva.com
*             Modify methods 'getRatingData,changeRatingStatus,setupValidateRating' replace
*             arce__Account_has_Analysis__c to arce.Arc_Gen_Account_Has_Analysis_Wrapper
* |24/01/2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             Remove logic static parameters to ASO services
* |30/01/2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add missing custom labels
* |18/02/2020 ricardo.almanza.contractor@bbva.com
*             Modified service to use validate rating
* |01/03/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Add logic to finalize the RAIP when validate rating
* |02/04/2020 juanignacio.hita.contractor@bbva.com
*             Added in array return of "getRatingData" and raipValidations
* |22/05/2020 juanignacio.hita.contractor@bbva.com
*             Added logic for short and long scale field of rating
* |26/05/2020 cesaroctavio.villanueva.cebal@bbva.com
*             Removed unused validate persistance service call
* |28/05/2020 juanignacio.hita.contractor@bbva.com
*             Added traceability for RAIP analysis
* |14-04-2020 mariohumberto.ramirez.contractor@bbva.com
*             Modified call to the class Arc_Gen_getRatingDataService_helper.setServiceParameters
* |2020-06-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added error management to show appropiate error messages to the user
* |2020-07-13 javier.soto.carrascosa@bbva.com
*             Enforce 2 decimales for rating score in validate rating modal
* |17/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Update getRatingData method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |04/12/2020 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* |23/02/2021 carlos.pisador.contractor@bbva.com
*             Added method that changes rating value to 'validate'
* |24/02/2021 joseluis.garcia4.contractor@bbva.com
*             Calls actions service to persist IRP rating validation.
* |03/03/2021 juanignacio.hita.contractor@bbva.com
*             Adds traceability funcionality for sets the stop time of the current event
* |07/04/2021 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes.
* |24/04/2021 jose.hijar.contractor@bbva.com
*             Overloading of setupValidateRatingByUser method allowing specify userId in service parameters
* |30/04/2021 otiliaramona.veres.contractor@bbva.com
* 			  Added an empty constructor method.
* |04/05/2021 otiliaramona.veres.contractor@bbva.com
* 			  Added annotation '@testVisible' to the empty constructor method.
* |02/06/2021 juanignacio.hita.contractor@bbva.com
*             Call setBankId(bankId) method for fill bankId param
* |2021-01-03 saimassimilianno.jordana.contractor@bbva.com
*             setTraceability meth0d modified, setupValidateRating meth0d modified to use ValidationWrapper.

* -----------------------------------------------------------------------------------------------
**/
public without sharing class Arc_Gen_ValidateRating_service {
    /**
    * @Description: Name of the EncryptionFlag custom metadata
    */
    private final static String ENCRYPTION_FLAG = 'EncryptionFlag';
    /**
    * @Description: Status OK
    */
    private final static String STATUS_OK = 'OK';

    /**
    * @Description: MSG VALIDATOR
    */
    private final static String MSG_VALIDATOR = 'Validator - You have participated in the process of calculating a rating as a validator';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created: 2021-04-30
    */
    @TestVisible
    private Arc_Gen_ValidateRating_service() { }
    /**
    *-------------------------------------------------------------------------------
    * @description Custom Exception that extends exception
    *--------------------------------------------------------------------------------
    * @date		30/03/2020
    */
    public virtual class CustomException extends Exception {}
    /**
    * @Class: Adjustments
    * @Description: Wrapper that contain all the rating adjustments
    * @author BBVA
    */
    public class Adjustments {
        /**
        * @Description: Rating score
        */
        Decimal score{get;set;}
        /**
        * @Description: Rating expressed in short scale
        */
        String shortScaleValue{get;set;}
        /**
        * @Description: Rating expressed in long scale
        */
        String longScaleValue{get;set;}
        /**
        * @Description: Rating default probability perentage
        */
        String defaultProbability{get;set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets the rating data
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param String analyzedClientId id of account for the analisis
* @return List<String> - A list of client rating data. Position[0] = ratingId, Position[1] = rating final, Position[2] = rating score
* @example public static List<String> getRatingData(String analyzedClientId)
**/
    public static Map<String, Object> getRatingData(String analyzedClientId) {
        Map<String, Object> ratingData = new Map<String, Object>();
        Arc_Gen_ValidateRating_data locator = new Arc_Gen_ValidateRating_data();
        arce.Arc_Gen_Account_Has_Analysis_Wrapper analysis = locator.getAccountHasAnalysis(analyzedClientId);
        arce__rating__c rating = locator.getRatingData(analysis.ahaObj.arce__ffss_for_rating_id__r.arce__rating_id__c);

        ratingData.put('ratingId', rating.Id);
        // Depending on the scale for the rating assigned in the AHA, the short or long value field is returned
        if (analysis.ahaObj.arce__rating_scale_type__c == arce.Arc_Gen_Constants.LONG_SCALE_RATING) {
            ratingData.put('ratingValue', rating.arce__rating_long_value_type__c);
        } else if (analysis.ahaObj.arce__rating_scale_type__c == arce.Arc_Gen_Constants.SHORT_SCALE_RATING) {
            ratingData.put('ratingValue', rating.arce__rating_short_value_type__c);
        }
        ratingData.put('ratingScore', String.valueOf(rating.arce__total_rating_score_number__c.setScale(2)));
        ratingData.put('subprocessType', analysis.ahaObj.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
        ratingData.put('proposeUser', analysis.ahaObj.arce__Analysis__r.arce__proposeUser__c);
        return ratingData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that inicializes the response of the validate rating
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-05-13
    * @param String analyzedClientId id of account for the analisis
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with the DML save results and the response of the service
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse getRatingData(String analyzedClientId)
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static arce.Arc_Gen_ServiceAndSaveResponse setupValidateRating(String analyzedClientId, String ratingId, String mockCode, Boolean isRaip) {
      //return setupValidateRatingByUser(analyzedClientId, UserInfo.getUserId(), ratingId, mockCode, isRaip);
      final arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validtionWrapper = new arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper(analyzedClientId,UserInfo.getUserId(),ratingId);
      return setupValidateRatingByUser(validtionWrapper, mockCode, isRaip);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that inicializes the response of the validate rating specifying a user to validate for
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 2021-04-08
    * @param ValidationWrapper validWrapper validation process data.
    * @param String mockCode predefined response
    * @param String isRaip indicates if the process is for a IRP
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with the DML save results and the response of the service
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupValidateRatingByUser(String analyzedClientId, String userId, String ratingId, String mockCode, Boolean isRaip)
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static arce.Arc_Gen_ServiceAndSaveResponse setupValidateRatingByUser(arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validWrapper, String mockCode, Boolean isRaip) {
        Arc_Gen_ValidateRating_data locator = new Arc_Gen_ValidateRating_data();
        final arce.Arc_Gen_RatingGlobal_data locatorRating = new arce.Arc_Gen_RatingGlobal_data();
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient = locator.getAccountHasAnalysis(validWrapper.analyzedClientId);
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final String subevent = validateSubeventType(analyzedClient.ahaObj) ? arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL : arce.Arc_Gen_RatingGlobal_Constants.FINALIZATION;
        final arce.Arc_Gen_RatingGlobal_helper.HelperParameters helperWrapper = new arce.Arc_Gen_RatingGlobal_helper.HelperParameters(analyzedClient.ahaObj, validWrapper.ratingId, validWrapper.userId, subevent);
        helperWrapper.setBankId(analyzedClient.accWrapperObj.bankId);
        String customerNumber = analyzedClient.accWrapperObj.accNumber;
        if(Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(ENCRYPTION_FLAG)[0].arce__Value1__c)) {
            customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(customerNumber);
        }
        String parametersJson = arce.Arc_Gen_RatingGlobal_helper.setServiceParameters(helperWrapper);
        String serviceName = 'validateRating';
        if(String.isNotBlank(mockCode)) {
            serviceName = mockCode;
            parametersJson = '{"messages":[{"code":"connectionError","message":"Unable to call Passive Products service","parameters": []}]}';
        }
        try {
            // Persist action into Oracle (only in IRP).
            if (isRaip) {
                arce.Arc_Gen_ActionsPersistence_Service.persistArceAction(analyzedClient.ahaObj.arce__Analysis__c, arce.Arc_Gen_ActionsPersistence_Service.ACTION_SANCTION);
            }
            arce.Arc_Gen_getIASOResponse.serviceResponse serviceResp = locatorRating.callRatingService(parametersJson, serviceName);
            response = processResponse(serviceResp, analyzedClient.ahaObj, validWrapper.commentary);
            if (response.saveStatus == 'true') {
                final arce.Arc_Gen_User_Wrapper uInfo = helperWrapper.userInfo;
                setTraceability(validWrapper, analyzedClient, uInfo);
                try {
                    List<arce__Account_has_Analysis__c> lAnaly = [Select arce__Analysis__c, arce__Analysis__r.OwnerId, arce__Analysis__r.CreatedById, arce__Analysis__r.arce__proposeUser__c, arce__Analysis__r.arce__anlys_wkfl_prev_user_name__c from arce__Account_has_Analysis__c where Id = :validWrapper.analyzedClientId];
                    System.debug('>>>>>>>>> lista lAnaly ' + lAnaly);
                    System.debug('>>>>>>>>> lista analysisId ' + validWrapper.analyzedClientId);
                    Set<Id> idsUsers = new Set<Id>();
                    if(uInfo.userBasicInfo != null)
                        idsUsers.add(uInfo.userBasicInfo.Id);
                    idsUsers.add(lAnaly.get(0).arce__Analysis__r.OwnerId);
                    idsUsers.add(lAnaly.get(0).arce__Analysis__r.CreatedById);
                    idsUsers.add(lAnaly.get(0).arce__Analysis__r.arce__proposeUser__c);
                    final List<User> userPropuesto = new List<User>();
                    for (Id userA : idsUsers) {
                        User newUser = new User();
                        newUser.id = userA;
                        userPropuesto.add(newUser);
                    }
                    sendNotifications(lAnaly.get(0).arce__Analysis__c,userPropuesto,System.Label.Arc_Gen_Traceability_13);

                    final Set<Id> idsUsersValid = new Set<Id>();
                    idsUsersValid.add(lAnaly.get(0).arce__Analysis__r.OwnerId);
                    final List<User> userValid = new List<User>();
                    for (Id userA : idsUsersValid) {
                        User newUser = new User();
                        newUser.id = userA;
                        userValid.add(newUser);
                    }
                    sendNotifications(lAnaly.get(0).arce__Analysis__c,userValid,MSG_VALIDATOR);
                } catch (Exception e) {
                    System.debug('Error notificactions');
                }
                if (isRaip) {
                    final Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapperPre = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(null, analyzedClient.ahaObj, analyzedClient.ahaObj.arce__Analysis__r, 'VALIDATE-IRP');
                    wkflWrapperPre.mapReqAction =  new Map<String, Object> {
                        'arce__wkfl_status_stage_type__c' => ARCE.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING,
                        'arce__wkfl_stage_type__c' => arce.Arc_Gen_Constants.STAGE_IN_SANCTION
                    };
                    final Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wrapperPre = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapperPre);
                    Arc_Gen_TraceabilityEvents.updateTraceEvents(wrapperPre);

                    final Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(null, analyzedClient.ahaObj, analyzedClient.ahaObj.arce__Analysis__r, 'VALIDATE-IRP');
                    wkflWrapper.mapReqAction =  new Map<String, Object> {
                        'arce__wkfl_status_stage_type__c' => ARCE.Arc_Gen_Constants.RAIP_STATUS_FINALIZED,
                        'arce__wkfl_stage_type__c' => arce.Arc_Gen_Constants.STAGE_FINALIZED
                    };
                    final Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);
                    Arc_Gen_TraceabilityEvents.updateTraceEvents(wrapper);
                }
            }
        } catch(CalloutException e) {
            response.saveStatus = 'false';
            response.serviceMessage = e.getMessage();
        }
        return response;
    }

    /**
    * --------------------------------------------------------------------------------
    * @description Method that process the service response codes
    * --------------------------------------------------------------------------------
    * @date 30/4/2019
    * @param arce.Arc_Gen_getIASOResponse.serviceResponse response - Wrapper that contains the service response info
    * @param arce__Account_has_Analysis__c analyzedClient - Analized Client record
    * @param String comment - Commentary for the validation
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the process information
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse processResponse(arce.Arc_Gen_getIASOResponse.serviceResponse response, arce__Account_has_Analysis__c analyzedClient, String comment) {
        final arce.Arc_Gen_ServiceAndSaveResponse servSaveResponse = new arce.Arc_Gen_ServiceAndSaveResponse();
        final arce.Arc_Gen_CustomServiceMessages custServMessage = new arce.Arc_Gen_CustomServiceMessages();
        servSaveResponse.serviceCode = response.serviceCode;
        servSaveResponse.serviceMessage = response.serviceMessage;
        if(response.serviceCode == String.valueOf(custServMessage.CODE_200)) {
            final List<String> changeStatus = changeRatingStatus(analyzedClient, comment);
            servSaveResponse.saveStatus = changeStatus[0];
            servSaveResponse.saveMessage = changeStatus[1];
        } else if(response.serviceCode == String.valueOf(custServMessage.CODE_400)) {
            servSaveResponse.serviceMessage = response.serviceCode == String.valueOf(custServMessage.CODE_400) ||
                response.serviceCode == String.valueOf(custServMessage.CODE_500) ?
                    JSON.serialize(arce.Arc_Gen_RatingErrorManagement.processErrorData(response, 'VALIDATION')) :
                    response.serviceMessage;
        }
        return servSaveResponse;
    }
/**
    * --------------------------------------------------------------------------------
    * @description Method that changes the status of a Rating from Calculated to Validated
    * --------------------------------------------------------------------------------
    * @date 2019-05-13
    * @param String analyzedClientId id of account for the analisis
    * @param String comment - Commentary for the validation
    * @return List<String> A list of update results. Position[0] = status(true/false), Position[1] = message
    * @example public static List<String> changeRatingStatus(String analyzedClientId)
    **/
    public static List<String> changeRatingStatus(arce__Account_has_Analysis__c analyzedClient, String comment) {
        final List<String> changeStatusData = new List<String>();
        final arce.Arc_Gen_RatingGlobal_data dataAccess = new arce.Arc_Gen_RatingGlobal_data();
        final Arc_Gen_ValidateRating_data locator = new Arc_Gen_ValidateRating_data();

        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{analyzedClient.arce__Analysis__c})[0];
        final arce__rating__c rating = locator.getRatingData(analyzedClient.arce__ffss_for_rating_id__r.arce__rating_id__c);
        rating.arce__status_type__c = '3';
        if (arce__rating__c.SObjectType.getDescribe().fields.getMap().containsKey('arce__Arc_Gen_ValidationCommentary__c')) {
            rating.put('arce__Arc_Gen_ValidationCommentary__c', comment); // This field is not in package dependencies
        }
        arceVar.arce__raip_wkfl_stage_type__c = '2';
        arceVar.arce__raip_wkfl_status_stage_type__c = '03';
        arceVar.arce__Stage__c = arce.Arc_Gen_Constants.STAGE_IN_SANCTION;
        if (arceVar.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {
            arceVar.arce__Stage__c = arce.Arc_Gen_Constants.STAGE_FINALIZED;
            arceVar.arce__wf_status_id__c = arce.Arc_Gen_Constants.RAIP_STATUS_FINALIZED;
            arceVar.arce__end_date__c = System.today();
        }

        final arce.Arc_Gen_RatingGlobal_data.SaveResult result = dataAccess.updateRecords(new List<SObject>{rating, arceVar});
        changeStatusData.add(result.status);
        changeStatusData.add(result.message);
        
        return changeStatusData;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that changes sets the final rating data
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 2019-05-13
* @param arce__rating__c rating - record
* @return List<Adjustments> - A wrapper that contains a rating data
* @example public static List<Adjustments> setFinalRating(arce__rating__c rating)
**/
    public static List<Adjustments> setFinalRating(arce__rating__c rating) {
        List<Adjustments> finalList = new List<Adjustments>();
        Adjustments adj = new Adjustments();
        adj.score = rating.arce__total_rating_score_number__c;
        adj.shortScaleValue = rating.arce__rating_short_value_type__c;
        adj.longScaleValue = rating.arce__rating_long_value_type__c;
        adj.defaultProbability = String.valueOf(rating.arce__PD_per__c);
        finalList.add(adj);
        Return finalList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get the config metadata RAIP_Validations and validate raip
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 2020-04-03
    * @param rDataString - List<String>
    * @return void
    * @example Arc_Gen_ValidateRating_controller.validations(rDataString)
    **/
    public static void raipValidations(Map<String, Object> rDataString) {
        final Arc_Gen_ValidationsRating_Interface controllerClass = Arc_Gen_GenericUtilitiesInterface.raipValidationsClass('userValidate');
        if (controllerClass != null) {
            final String statusVal = controllerClass.userValidate((String)rDataString.get('proposeUser'));
            if (statusVal != STATUS_OK) {
                throw new CustomException(statusVal);
            }
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Sets a traceability message for validation rating action in a RAIP analysis
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 2020-05-28
    * @param arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validWrppr
    * @param arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient
    * @param Arc_Gen_User_Wrapper userInfo
    * @return void
    * @example setTraceability(validWrppr, analyzedClient, userInfo);
    **/
    public static void setTraceability(arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validWrppr, arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient, arce.Arc_Gen_User_Wrapper userInfo) {
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(validWrppr.analyzedClientId);
        if (analysis.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {

            //Choosing ambit
            final String ambit = string.isBlank(validWrppr.ambitSelected) ? UserInfo.ambitUser : getStringAmbit(validWrppr.ambitSelected);
            //final String strAmbit = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__anlys_wkfl_edit_br_level_type__c', ambit);

            //User or Committee
            final String ifComite = userInfo.businessAgentId == 'COMITE' ? 'Committee' : '';
            final String userName = userInfo.userBasicInfo == null ? ifComite : userInfo.userBasicInfo.name;

            String traceComments = '';
            final String actionAuditType = analyzedClient.ahaObj.arce__RAR_rating_tool_id__c == '2021RTC_NBF' ? 'Arc_IFIS_Traceability' : 'Arc_Gen_Traceability' ;
            traceComments = System.Label.Arc_Gen_Traceability_validated_by + ' ' + userName + ' | ' + System.Label.Arc_Gen_TraceabilityAmbit + ': ' + ambit + ' | Commentary: ' + validWrppr.commentary;
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_Traceability_Finalized_RAIP, 'approve', traceComments.abbreviate(255), analyzedClient.ahaObj.Name, actionAuditType);
            final Map<String, String> auditWF = new Map<String, String>();
            dwp_cvad__Action_Audit__c audit = Arc_Gen_Traceability.saveTrace(analysis.Id, auditAttr, auditWF);
            final Map<String, String> auditDetailAttr = Arc_Gen_Traceability.genAuditDetailAttr(validWrppr.commentary, '1', '', 'Embedded');
            Arc_Gen_Traceability.saveTraceDetail(audit.Id, auditDetailAttr);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that changes rating status to 'validate'
    --------------------------------------------------------------------------------
    * @author carlos.pisador.contractor@bbva.com
    * @date 2021-02-23
    * @param List<arce__Account_has_Analysis__c> ahaClientLst
    * @return List<arce__rating__c>
    * @example changeRatingsData(List<arce__Account_has_Analysis__c> ahaClientLst)
    **/
    public static List<arce__rating__c> changeRatingsData(List<arce__Account_has_Analysis__c> ahaClientLst) {
        final List<String> ratingsIds = new List<String>();
        for (arce__Account_has_Analysis__c auxAha : ahaClientLst) {
            ratingsIds.add(String.valueOf(auxAha.arce__ffss_for_rating_id__r.arce__rating_id__c));
        }
        final List<arce__rating__c> ratings = arce.Arc_Gen_Rating_data.generalRatingData(new List<String>(ratingsIds));
        for (arce__rating__c indvRating : ratings) {
            indvRating.arce__status_type__c = '3';
        }
        return ratings;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description validateSubeventType
    --------------------------------------------------------------------------------
    * @author amunguia.contractor@bbva.com
    * @date 2021-12-23
    * @param arce__Account_has_Analysis__c ahaObj
    * @return Boolean
    * @example validateSubeventType(arce__Account_has_Analysis__c ahaObj)
    **/
    private static Boolean validateSubeventType(arce__Account_has_Analysis__c ahaObj) {
        return ahaObj.arce__Analysis__r.arce__rating_prerating_type__c == arce.Arc_Gen_RatingGlobal_Constants.RATING || String.isBlank(ahaObj.arce__Analysis__r.arce__rating_prerating_type__c);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method that sets the arce__Analysis__c with the new values of the propose
    --------------------------------------------------------------------------------
    * @param String arceId - Standard Id of the arce__Analysis__c
    * @param List<User> usuarios - List of User
    * @return arce__Analysis__c - ARCE record ready to update
    * @example arce__Analysis__c arce = Arc_GBL_RAIP_Propose_Locator.sendNotifications(Id arceId)
    **/
    private static void sendNotifications(Id arceId, List<User> usuarios, String mensaje) {
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{arceId})[0];
        arce.Arc_Gen_GenericUtilities.createNotifications(usuarios, arceId, mensaje + ': ' + arceVar.Name);
    }

        /*
    * @author Global Desktop
    */
    public static String getStringAmbit(String selectedAmbit) {
        final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
        SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
        FROM Arce_ambit_hierarchy__mdt
        WHERE Ambit__c = :selectedAmbit
        LIMIT 40000
        ]);

        String ambitString = '';
        if(!ambitMetadatas.isEmpty()) {
        ambitString = ambitMetadatas.get(0).Region__c + ' - ' + ambitMetadatas.get(0).Level__c + (ambitMetadatas.get(0).Description__c == null || ambitMetadatas.get(0).Description__c == '' ? ' -' : ' - ' + ambitMetadatas.get(0).Description__c);
        }
        return ambitString;
    }
}