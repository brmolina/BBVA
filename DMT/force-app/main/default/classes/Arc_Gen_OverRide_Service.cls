/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistanceBR_Service
* @Author   Ricardo Almanza Angeles
* @Date     Created: 21/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that get data and create json to persist.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-21 Ricardo Almanza Angeles
*             Class creation.
* |2020-04-22 César Octavio Villanueva Ceballos
*             Added self control of modifications for rating override instead
*             of calling Arc_Gen_getRatingDataService_helper
* |2020-01-21 Ricardo Almanza Angeles
*             change user for overide service.
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Modify call to the class Arc_Gen_getRatingDataService_helper.setServiceParameters
* |2020-06-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added error management to show appropiate error messages to the user
* |2020-06-25 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to avoid create duplicate override variables
* |2020-07-07 juanmanuel.perez.ortiz.contractor@bbva.com
*             Create methods called setConditionalResult and evaluateCodeResponse
* |2020-07-23 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to add eventType parameter in service parameters
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* |2021-03-12 eduardoefrain.hernandez.contractor@bbva.com
*             Add error management
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes and remove methods already present in dependencies.
* |2021-06-02 joseluis.garcia4.contractor@bbva.com
*             Add persistence of override reason combobox (arce__rating_override_comment__c) + Fix persistence.
* |2021-06-04 juanignacio.hita.contractor@bbva.com
*             Changed bankId param fill from account wrapper
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD, sf:TooManyMethods')
public without sharing class Arc_Gen_OverRide_Service {
    /**
        * @Description: string with api of field value to override
    */
        Static Final String OVRVAL = 'arce__adj_long_rating_value_type__c';
    /**
        * @Description: string with api of field Comment to override
    */
        Static Final String OVRDSC = 'arce__rating_override_reason_desc__c';
    /**
        * @Description: string with api of field Comment to override
    */
        Static Final String OVRREASON = 'arce__rating_override_comment__c';
    /**
        * @Description: string with the service name
    */
        Static Final String SERVICE_NAME = 'overRating';
    /**
        * @Description: string with the success answer1
    */
        Static Final String SUCC1 = '200';
    /**
        * @Description: string with the success answer2
    */
        Static Final String SUCC2 = '204';
    /**
        * @Description: string with the success answer3
    */
    Static Final String SUCC3 = '201';
    /**
    * @Description: Service response identificator
    */
    public final static String ID_TEXT = 'Id';
    /**
    * @Description: Service response identificator
    */
    public final static String ID_TEXT_MAP = 'id';
    /**
    * @Description: Service response path group
    */
    public final static String PATHGR = 'GROUP';
    /**
    * @Description: Service responsepath subsidiary
    */
    public final static String PATHSUB = 'SUBSIDIARY';
    /**
    * @Description: Name of the bankId custom setting
    */
    private final static String BANK_ID = '0001';
    /**
    * @Description: Service response rating method type override
    */
    public final static String RATINGOVER = 'OVERRIDE';
    /**
    * @Description: Service response rating method type overlay
    */
    public final static String OVERLAY = 'OVERLAY';
    /**
    * @Description: Service response identificator
    */
    public final static String DATA_TEXT = 'data';
    /**
    * @Description: Service response identificator
    */
    public final static String RATING_TEXT = 'ratings';
    /**
    * @Description: Service response identificator
    */
    public final static String FINAL_RATING = 'FINAL';
    /**
    * @Description: Service response identificator
    */
    public final static String LONG_VALUE = 'longScaleValue';
    /**
    * @Description: Service response rating type
    */
    public final static String RATINGTYPE = 'ratingType';
    /**
    * @Description: Service response identificator
    */
    public final static String ADJUSTMENTS = 'adjustments';
    /**
    * @Description: Service response identificator
    */
    public final static String DEFAULT_PROBABILITY = 'defaultProbability';
    /**
    * @Description: Service response identificator
    */
    public final static String MODIFIER = 'modifier';
    /**
    * @Description: Service response identificator
    */
    public final static String SHORT_VALUE = 'shortScaleValue';
    /**
    * @Description: Service response identificator
    */
    public final static String LEVEL = 'level';
    /**
    * @Description: Service response identificator
    */
    public final static String DESCRIPTION = 'description';
    /**
    * @Description: If the variable does not have any value
    */
    public final static String NOT_APPLY = 'NA';
    /**
    * @Description: Service response identificator
    */
    public final static String SCORE = 'score';
    /**
    * @Description: Instance of the data access class
    */
    private static arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();
    /**
    * @Description: String with the participant number
    */
    private static Boolean showErrorLog;
    /**
    * @Description: static logic that sets participantNumber
    */
    static {
        final List<arce__Arce_Config__mdt> showErrorsConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ShowTraceErrorLogs');
        showErrorLog = Boolean.valueOf(showErrorsConfig.get(0).arce__Value1__c);
    }
    /**
    * @Class: OverRideParameters
    * @Description: Wrapper that contain all the rating override parameters
    * @author BBVA
    */
    public class OverRideParameters {
        /**
        * @Description: eventType identifier.
        */
        public String eventType {get;set;}
        /**
        * @Description: Business agent identifier that starts the rating study.
        */
        public String businessAgentId {get;set;}
        /**
        * @Description: Unique bank identifier.
        */
        public String bankId {get;set;}
        /**
        * @Description: Unique branch identifier when the assessment is created.
        */
        public String branchId {get;set;}
        /**
        * @Description: Unique level of branch identifier.
        */
        public String branchLevel {get;set;}
        /**
        * @Description: Indicates the participation type that the participant of the analysis
        * has within the Economic Group to which it belongs.
        */
        public String participationType {get;set;}
        /**
        * @Description: Identificator of the Financial Statement
        */
        public String ffssId {get;set;}
        /**
        * @Description: DateTime to call service
        */
        public String evaluationDate {get;set;}
        /**
        * @Description: Adjustment Description
        */
        public String adjDesc {get;set;}
        /**
        * @Description: Adjustment Value
        */
        public String adjValue {get;set;}
        /**
        * @Description: Identificator of the analyzed client (Not the standard Salesforce Id)
        */
        public String riskAssessmentId {get;set;}
        /**
        * @Description: Account Number of the Customer
        */
        public String participantId {get;set;}
        /**
        * @Description: Identificator of the rating in Salesforce
        */
        public String ratingid {get;set;}
        /**
        * @Description: override reason.
        */
        public String reason {get;set;}
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_OverRide_Service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    null
    * @return   Arc_Gen_OverRide_Service
    * @example  new Arc_Gen_OverRide_Service()
    * */
    @TestVisible
    private Arc_Gen_OverRide_Service() {}
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to persist persistOverRide
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    List<String> accIds Id's of account
    * @param    List<sObject> listAccsPend Accounts to persist
    * @return   boolean to confirm persistance
    * @example  succes = Arc_Gen_OverRide_Service.persistOR(new List<String>(arcAcc),listAccs,listrvar)
    * */
    public static arce.Arc_Gen_wrpSave persistOR(List<String> accIds,List<sObject> listAccsPend,List<sObject> listRVar) {
        Final List<sObject> accsToPersist = new List<sObject>();
        Final String errMsg;
        sObject aha = listAccsPend[0];
        Boolean result = true;
        Final Map<String,sObject> mAccDB = toMap(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(accIds));
        for (sObject accPend : listRVar) {
            final String ovrValCurr = String.valueOf(accPend.get(OVRVAL));
            final String ovrValDb = String.valueOf(mAccDB.get(String.valueOf(aha.get(ID_TEXT))).get(OVRVAL));
            final String ovrCommCurr = String.valueOf(accPend.get(OVRDSC));
            final String ovrCommDb = String.valueOf(mAccDB.get(String.valueOf(aha.get(ID_TEXT))).get(OVRDSC));
            final String ovrReasonCurr = String.valueOf(accPend.get(OVRREASON));
            final String ovrReasonDb = String.valueOf(mAccDB.get(String.valueOf(aha.get(ID_TEXT))).get(OVRREASON));

            final boolean resultConditional = ovrValCurr != ovrValDb || ovrCommCurr != ovrCommDb || ovrReasonCurr != ovrReasonDb;
            if(resultConditional) {
                accsToPersist.add(accPend);
            }
        }
        for (sObject accToPers : accsToPersist) {
            Arc_Gen_ValidateRating_data locator = new Arc_Gen_ValidateRating_data();
            arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient = locator.getAccountHasAnalysis((Id)aha.get(ID_TEXT));
            String customerNumber = analyzedClient.accWrapperObj.accNumber;
            customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(customerNumber);
            String parametersJson = setServiceParameters(analyzedClient.ahaObj, customerNumber, BANK_ID,accToPers);
            arce.Arc_Gen_getIASOResponse.serviceResponse response;
            arce.Arc_Gen_ServiceAndSaveResponse response2;
            try {
                response = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, parametersJson);
                final Boolean responseCode = evaluateCodeResponse(String.valueOf(response.serviceCode));
                if(responseCode) {
                    response2 = setupRating(String.valueOf(analyzedClient.ahaObj.Id), String.valueOf(customerNumber), String.valueOf(accToPers.get(ID_TEXT)), null, null, analyzedClient.accWrapperObj.bankId);
                    if (!(SUCC1.equals(String.valueOf(response2.serviceCode)) || SUCC2.equals(String.valueOf(response2.serviceCode)))) {
                        Map<String, Object> errorMap = (Map<String, Object>)JSON.deserializeUntyped(response2.serviceMessage);
                        result = false;
                        errMsg = (String)errorMap.get('errorTitle') + (String)errorMap.get('errorMessage') + ' ' + (String)errorMap.get('errorCode');
                    }
                    savePersistedOverride(analyzedClient, accToPers, response2.serviceCode);
                } else {
                    result = false;
                    errMsg = Label.Arc_Gen_Generic_ErrorSumPersOR;
                }
            } catch(Exception e) {
                result = false;
                errMsg = showErrorLog ? e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString() : Label.Arc_Gen_RatingError_OverrideError;
            }
        }
        return new arce.Arc_Gen_wrpSave(result,errMsg,null);
    }
    /*------------------------------------------------------------------------------------------------------
    * @Description Saves persisted override data into the Account has Analysis object.
    * -----------------------------------------------------------------------------------------------------
    * @Author   José Luis García
    * @Date     2021-06-01
    * @param    arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient - AHA Wrapper
    * @param    sObject accToPers - Override variable data
    * @param    String serviceCode - Service code
    * */
    private static void savePersistedOverride(arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient, sObject accToPers, String serviceCode) {
        final Boolean success = SUCC1.equals(String.valueOf(serviceCode)) || SUCC2.equals(String.valueOf(serviceCode));
        if (success) {
            final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
                Id = analyzedClient.ahaObj.Id,
                arce__adj_long_rating_value_type__c = String.valueOf(accToPers.get(OVRVAL)),
                arce__rating_override_reason_desc__c = String.valueOf(accToPers.get(OVRDSC)),
                arce__rating_override_comment__c = String.valueOf(accToPers.get(OVRREASON))
            );

            arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(aha);
        }
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform list to map with key as ID
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-05
    * @param    List<sObject> listAcc Accounts to add to map
    * @return   Map<String,sObject> map of id,sObject
    * @example  toMap(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(accIds));
    * */
    private static Map<String,sObject> toMap(List<sObject> listAcc) {
        Final Map<String,sObject> toRet = new Map<String,sObject>();
        for (sObject acc : listAcc) {
            toRet.put(String.valueOf(acc.get(ID_TEXT)), acc);
        }
        return toRet;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service response and assign the rating fields
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 19/2/2020
    * @param arce__Account_has_Analysis__c analyzedClient Account has analisis to call the WS
    * @param String customerId Account id to call WS
    * @param String methodType type of operation the service expects
    * @return String parameters for WS
    * @example setServiceParameters(arce__Account_has_Analysis__c analyzedClient,String customerId, String methodType) {
    **/
    private static String setServiceParameters(arce__Account_has_Analysis__c analyzedClient,String customerId, String bankId,sObject dyn) {
        final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(UserInfo.getUserId());
        final OverRideParameters parameters = new OverRideParameters();
        final String subprocessType = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{analyzedClient.Id})[0].arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c;
        final String eventType = arce.Arc_Gen_GenericUtilities.getEventTypeValue(subprocessType);
        parameters.eventType = eventType;
        parameters.businessAgentId = uInfo.businessAgentId;
        parameters.bankId = bankId;
        parameters.branchId = uInfo.branchId;
        parameters.branchLevel = uInfo.branchlevel;
        parameters.participationType = analyzedClient.arce__group_asset_header_type__c == '1' ? PATHGR : PATHSUB;
        parameters.ffssId = analyzedClient.arce__ffss_for_rating_id__r.arce__financial_statement_id__c;
        parameters.evaluationDate = String.valueOf(DateTime.now());
        parameters.adjValue = String.valueOf(dyn.get(OVRVAL));
        parameters.adjDesc = String.valueOf(dyn.get(OVRDSC));
        parameters.reason = String.valueOf(dyn.get(OVRREASON));
        parameters.riskAssessmentId = analyzedClient.Name;
        parameters.participantId = customerId;
        parameters.ratingid = arce.Arc_Gen_Rating_data.generalRatingData(new List<String>{analyzedClient.arce__ffss_for_rating_id__r.arce__rating_id__c})[0].arce__rating_id__c;
        Return JSON.serialize(parameters,true);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the response from the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId
    * @param String customerId
    * @param String ratingId
    * @param String mockCode
    * @param String serviceMock
    * @param String bankId
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with the result of a DML operation and service call
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupRating(analysisId, customerId, ratingId, mockCode, serviceMock, bankId)
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse setupRating(String analysisId, String customerId, String ratingId, String mockCode, String serviceMock, String bankId) {
        Final arce.Arc_Gen_RatingGlobal_data locatorRatDat = new arce.Arc_Gen_RatingGlobal_data();
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{analysisId})[0];
        arce.Arc_Gen_RatingGlobal_helper.HelperParameters helperWrapper = new arce.Arc_Gen_RatingGlobal_helper.HelperParameters(accHasAnalysis, ratingId, arce.Arc_Gen_RatingGlobal_Constants.METHOD_OVERRIDE);
        helperWrapper.setBankId(bankId);
        String customerNumber = customerId;
        customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(customerNumber);
        List<arce__Financial_Statements__c> validFinancialSt = locatorRatDat.getValidFFSS(analysisId);
        helperWrapper.accHasAnalysis = accHasAnalysis;
        helperWrapper.serviceMock = serviceMock;
        helperWrapper.mockCode = mockCode;
        helperWrapper.rating2Keep = ratingId;
        serviceAndSaveResp = processOverride(helperWrapper);
        Return serviceAndSaveResp;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service error responses
    --------------------------------------------------------------------------------
    * @author cesaroctavio.villanueva.cebal@bbva.com
    * @date  22/04/2020
    * @param HelperParameters helpWrapper - Wrapper with the data to save
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the result of the process
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse processOverride(String analysisId, String customerNumber,List<arce__Financial_Statements__c> validFinancialSt)
    **/
    private static arce.Arc_Gen_ServiceAndSaveResponse processOverride(arce.Arc_Gen_RatingGlobal_helper.HelperParameters helpWrapper) {
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_getIASOResponse.serviceResponse response = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final arce__Account_has_Analysis__c analysis = helpWrapper.accHasAnalysis;
        String parameters = arce.Arc_Gen_RatingGlobal_helper.setServiceParameters(helpWrapper);
        String serviceName = String.isBlank(helpWrapper.serviceMock) ? 'ratingEngine' : helpWrapper.serviceMock;
        if(String.isNotBlank(helpWrapper.mockCode)) {
            serviceName = helpWrapper.mockCode;
            parameters = '{"messages":[{"code":"connectionError","message":"Unable to call Passive Products service","parameters": []}]}';
        }
        response = locator.callRatingService(parameters, serviceName);
        try {
            serviceAndSaveResp = arce.Arc_Gen_RatingGlobal_helper.processResponse(response, helpWrapper);
        } catch(Exception ex) {
            serviceAndSaveResp.saveStatus = 'false';
            serviceAndSaveResp.saveMessage = ex.getMessage();
        }
        serviceAndSaveResp = arce.Arc_Gen_RatingGlobal_helper.updateLeveragedVars(serviceAndSaveResp, analysis);
        Return serviceAndSaveResp;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service response and assign the rating fields
    --------------------------------------------------------------------------------
    * @author cesaroctavio.villanueva.cebal@bbva.com
    * @date  22/04/2020
    * @param Map<String, Object> responseMap process response of the WS
    * @param arce__Account_has_Analysis__c analysis current analisis for rating
    * @return arce__rating__c current rating object
    * @example public static arce__rating__c processRatingData(Map<String, Object> responseMap,arce__Account_has_Analysis__c analysis)
    **/
    private static arce__rating__c processOverrideData(Map<String, Object> responseMap,arce__Account_has_Analysis__c analysis) {
        final arce__rating__c rating = locator.getCurrentRating(analysis.id);
        final Object listServiceResp = (Object)responseMap.get(DATA_TEXT);
        final Map<String, Object> data = (Map<String, Object>)listServiceResp;
        final List<Object> ratingMap = (List<Object>)data.get(RATING_TEXT);
        final Map<String, Object> finalRatingMap = arce.Arc_Gen_RatingGlobal_helper.getMapFromList(ratingMap,FINAL_RATING);
        rating.arce__rating_id__c = (String)data.get(System.Label.Cls_arce_RatingId);
        rating.arce__total_rating_score_number__c = Decimal.valueOf(String.valueOf(finalRatingMap.get(System.Label.Cls_arce_RatingRespScore)));
        rating.arce__rating_short_value_type__c = (String)finalRatingMap.get(System.Label.Cls_arce_RatingRespShortScale);
        rating.arce__rating_long_value_type__c = (String)finalRatingMap.get(System.Label.Cls_arce_RatingRespLongScale);
        rating.arce__pd_per__c = (Decimal)finalRatingMap.get(System.Label.Cls_arce_RatingRespDefProbability);
        rating.arce__status_type__c = '2';
        arce.Arc_Gen_User_Wrapper userWrapper = arce.Arc_Gen_User_Locator.getUserInfo(UserInfo.getUserId());
        rating.arce__rating_user_id__c =  userWrapper.businessAgentId;
        analysis.arce__long_rating_value_id__c = (String)finalRatingMap.get(LONG_VALUE);
        analysis.arce__newFFSS_ind__c = 'NO';
        locator.updateRecord(analysis);
        Return rating;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that evaluate service code response
    --------------------------------------------------------------------------------
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @date  09/07/2020
    * @return Boolean
    * @example public static Boolean evaluateCodeResponse(String responseCode)
    **/
    public static boolean evaluateCodeResponse(String responseCode) {
        return SUCC1.equals(responseCode) || SUCC2.equals(responseCode) || SUCC3.equals(responseCode);
    }
}