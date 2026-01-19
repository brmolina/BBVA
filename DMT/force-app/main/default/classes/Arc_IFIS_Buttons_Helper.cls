/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_Buttons_Helper
* @Author         francisco.munoz.torres.contractor@bbva.com
* @Date           31-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Utility class with common button methods.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            francisco.munoz.torres.contractor@bbva.com
* 31-08-2023      Class creation.
*
* v1.1            marcos.gimeno.next@bbva.com
* 31-08-2023      Added multiple methods of the different buttons.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
public class Arc_IFIS_Buttons_Helper {
    /** @description Constant with picklist value not to recalculate*/
    static final String RECALC_NO = '4';
    /** @description Default message string.**/
    public static final String DEFAULT_MESSAGE = 'Show';
    /** @description Service message class**/
    static final arce.Arc_Gen_CustomServiceMessages SERVICE_MESSAGES = new arce.Arc_Gen_CustomServiceMessages();

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper class to store the data quality result locally.
    * -----------------------------------------------------------------------------------------------
    * @autor       ARCE
    * @date        10-06-2024
    * -----------------------------------------------------------------------------------------------
    **/
    public class DQLocalResult {
        public String status { get; set; }
        public String message { get; set; }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Private constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     31-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_IFIS_Buttons_Helper() {
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks whether a specified button is available for a record.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    recordId      ID of the Account_has_Analysis__c record
    * @param    buttonName    Name of the button to check
    * @return   Whether the button is available
    * @example  Boolean e = isButtonAvailable(recordId, buttonName)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean isButtonAvailable(String recordId, String buttonName) {
        Boolean isAvailable;
        if (Test.isRunningTest()) {
            isAvailable = true;
        } else {
            final Set<String> availableButtons = Arc_IFIS_ButtonsStatus.getDynamicButtonStatus(
                recordId,
                'arce__Account_has_Analysis__c'
            );
            isAvailable = availableButtons.contains(buttonName);
        }
        return isAvailable;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that runs the local delegation process of workflow analysis configurated.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    ambit         Ambit to propose
    * @param    analysisId    ID of the Analysis__c record
    * @param    action        Current action
    * @return   TYPE    DESCRIPTION (MENTION LIKELY VALUES IN DESCRIPTION)
    * @example  A delegation wrapper object
    * -----------------------------------------------------------------------------------------------
    **/
    public static Arc_IFIS_Buttons_Wrp.DelegationWrapper initDelegation(
        String selectedAmbit,
        Id analysisId,
        String action
    ) {
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper wrapper = new Arc_IFIS_Buttons_Wrp.DelegationWrapper();
        wrapper.analysisId = analysisId;
        wrapper.ambit = selectedAmbit;

        try {
            switch on action {
                when 'RETURN' {
                    returnAction(wrapper);
                }
                when 'PROPOSE' {
                    proposeAction(wrapper);
                }
            }
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error Propose Action : ' + e.getMessage();
        }

        return wrapper;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Notifies the user about the proposal process.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysisId    ID of the Analysis__c record
    * @return   void
    * @example  sendNotifications(analysisId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static void sendNotifications(Id analysisId, String message) {
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(
            new List<Id>{ analysisId }
        )[0];
        arce.Arc_Gen_GenericUtilities.createNotifications(
            arce.Arc_IFIS_Notification.getUsersIds(analysisId),
            analysisId,
            message + ': ' + analysis.Name
        );
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Create wrapper response object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    data       Response validated data
    * @param    isValid    Response check
    * @param    message    Response message
    * @return   TYPE    DESCRIPTION (MENTION LIKELY VALUES IN DESCRIPTION)
    * @example  Arc_IFIS_Buttons_Wrp.ValidateResponse e = createResponseObj(data, isValid, message)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse createResponseObj(
        Map<String, Object> data,
        Boolean isValid,
        String message
    ) {
        return new Arc_IFIS_Buttons_Wrp.ValidateResponse(data, isValid, message);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks if the current Analysis is rating type.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     07-09-2023
    * @param    type       Analysis rating type
    * @return   True if analysis is rating, false otherwise
    * @example  Boolean e = isRating(String type)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean isRating(String type) {
        return type == arce.Arc_Gen_Constants.RATING_TYPE;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Verifies if the rating calculation has been performed and ensures that no
    *              changes have been made to the ARCE subsequently that could potentially impact
    *              the calculated rating.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     10-07-2023
    * @param    aha     arce__Account_has_Analysis__c record
    * @param    data    Map with data to validate
    * @return   Validation response
    * @example  Arc_IFIS_Buttons_Wrp.ValidateResponse e = isRatingValid(aha, data)
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:DUDataflowAnomalyAnalysis')
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse isRatingValid(
        arce__Account_has_Analysis__c aha,
        Map<String, Object> data
    ) {
        Arc_IFIS_Buttons_Wrp.ValidateResponse response;

        final String finalRating = aha.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_short_value_type__c;
        final Boolean isChanged = aha.arce__recalculate_rating__c == RECALC_NO ? false : true;

        if (String.isEmpty(finalRating)) {
            response = createResponseObj(data, false, System.Label.arce.Arc_IFIS_Error_Invalid_Rating);
        } else if (isChanged) {
            response = createResponseObj(data, false, System.Label.arce.Arc_IFIS_Error_Invalid_Rating_Recalculate);
        } else {
            response = createResponseObj(data, true, null);
        }

        return response;
    }

     /**
    * -----------------------------------------------------------------------------------------------
    * @description This method checks the data quality of a record and returns it as a JSON string.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        29-05-2024
    * @param       recordId ID of the record to check
    * @return      JSON string with the data quality result
    * -----------------------------------------------------------------------------------------------
    **/
    public static String checkDataQuality(String recordId) { 
        String result;

        final arce.Arc_IFIS_DataQuality dataQuality = new arce.Arc_IFIS_DataQuality(recordId);
        dataQuality.getModel();

        if (dataQuality.model != null && dataQuality.model != 'IFIS-AGE-IRP') {
            dataQuality
                .getDataQualityFields()
                .buildQueryString()
                .getAhaData()
                .getAccountData()
                .getRelatedData()
                .checkDataQuality();

            final arce.Arc_IFIS_DataQuality.DataQualityResult dataQualityResult = dataQuality.getResult();

            final DQLocalResult localResult = new DQLocalResult();
            localResult.status = dataQualityResult.status;
            localResult.message = dataQualityResult.message;

            result = JSON.serialize(localResult);
        } else {
            result = JSON.serialize(new DQLocalResult());
        }

        return result;
    }
    
    /**
    * -----------------------------------------------------------------------------------------------
    * @description This method gets the rating data for a given Aha record and returns it as a
    *              Arc_IFIS_Buttons_Wrp.ValidateResponse object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaId arce__Account_has_Analysis__c record
    * @param    buttonType Type of button that triggers the action
    * @return   The modified response object for validated operations.
    * @example  Arc_IFIS_Buttons_Wrp.ValidateResponse e = getRatingData(aha)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse getRatingData(
        arce__Account_has_Analysis__c aha,
        String buttonType
    ) {
        Arc_IFIS_Buttons_Wrp.ValidateResponse response;
        final Map<String, Object> data = new Map<String, Object>();
        String message = DEFAULT_MESSAGE;

        try {
            arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();
            final arce__Account_has_Analysis__c ahaRating = locator.getAccountHasAnalysis(aha.Id)[0];

            message = checkRatingValid(ahaRating, message, buttonType);
            data.putAll(getRatingDataMap(ahaRating, message));
            response = Arc_IFIS_Buttons_Helper.createResponseObj(data, true, null);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Gets the rating data for a given Aha record and returns it as a Map.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        26-02-2024
    * @param       ahaRating arce__Account_has_Analysis__c record
    * @param       message Message to show
    * @return      Map with rating data
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> getRatingDataMap(arce__Account_has_Analysis__c ahaRating, String message) {
        final Map<String, Object> data = new Map<String, Object>();
        data.put('subProcessType', ahaRating.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
        data.put('ratingId', ahaRating.arce__ffss_for_rating_id__r.arce__rating_id__c);
        data.put('recalculateRating', message);
        return data;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks if the recalculate rating value is valid and returns a message.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        26-02-2024
    * @param       ahaRating arce__Account_has_Analysis__c record
    * @param       message Message to show
    * @param       buttonType Type of button that triggers the action
    * @return      Message to show
    * -----------------------------------------------------------------------------------------------
    **/
    private static String checkRatingValid(arce__Account_has_Analysis__c ahaRating, String message, String buttonType) {
        final Map<String, String> labelByType = new Map<String, String>{
            'PROPOSAL' => System.Label.arce.Arc_Gen_RecalcRatWarning,
            arce.Arc_Gen_RatingGlobal_Constants.FINALIZATION => System.Label.arce.Arc_Gen_RecalcRatWarningPre,
            arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL => System.Label.arce.Arc_Gen_RecalcRatWarningVal
        };

        if (ahaRating.arce__recalculate_rating__c != null && ahaRating.arce__recalculate_rating__c != '4') {
            Map<String, String> mapa = arce.Arc_Gen_GenericUtilities.getMapLabelFromValue(
                'arce__Account_has_Analysis__c',
                'arce__recalculate_rating__c'
            );
            if (!mapa.isEmpty() && mapa.get(ahaRating.arce__recalculate_rating__c) != null) {
                String recalc = mapa.get(ahaRating.arce__recalculate_rating__c).toLowerCase();
                message = labelByType.get(buttonType) + ' ' + recalc;
            }
        }

        return message;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Sets specific delegation info for "Propose".
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * @param    wrapper    Delegation info wrapper
    * @return   void
    * @example  proposeAction(wrapper)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void proposeAction(Arc_IFIS_Buttons_Wrp.DelegationWrapper wrapper) {
        final List<String> valuesSelected = new List<String>{ '1', '2', '3' };
        final List<Map<String, String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels(
            'arce__Analysis__c',
            'arce__anlys_wkfl_edit_br_level_type__c',
            valuesSelected
        );
        wrapper.lstAmbits = lstPicklist;
        wrapper.sanctionAmbit = lstPicklist.size() > 1 ? '1' : lstPicklist[0].get('value');
        wrapper.hasDelegation = 'NO';
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Sets specific delegation info for "Return".
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * @param    wrapper    Delegation info wrapper
    * @return   void
    * @example  proposeAction(wrapper)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void returnAction(Arc_IFIS_Buttons_Wrp.DelegationWrapper wrapper) {
        final List<String> valuesSelected = new List<String>{ '2' };
        final List<Map<String, String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels(
            'arce__Analysis__c',
            'arce__anlys_wkfl_edit_br_level_type__c',
            valuesSelected
        );
        wrapper.lstAmbits = lstPicklist;
    }
}