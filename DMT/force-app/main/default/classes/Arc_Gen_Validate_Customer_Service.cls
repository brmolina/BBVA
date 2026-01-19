/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Customer_Controller
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-05-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_Validate_Customer_Controller.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-09-24 mariohumberto.ramirez.contractor@bbva.com
*             Added new call to arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(accHasAId) class
*             Added new constant S_GROUP
* |2019-09-30 mariohumberto.ramirez.contractor@bbva.com
*             Deleted lines that validate TOTAL CREDIT RISK
* |2019-09-30 mariohumberto.ramirez.contractor@bbva.com
*             Added new methods validateTypoSum and getIdsOfFilials
* |2019-10-03 mariohumberto.ramirez.contractor@bbva.com
*             Added new method validateRatingInSanction
* |2019-10-16 mariohumberto.ramirez.contractor@bbva.com
*             Added new method createSetapiFields
* |2019-10-29 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getMultiplicationFactor
* |2019-12-30 mariohumberto.ramirez.contractor@bbva.com
*             Modify method validateFields
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Update class to manage automatic position validations
* |2020-02-08 ricardo.almanza.contractor@bbva.com
*             Modify to validate orphan
* |2020-04-27 joseluis.garcia4.contractor@bbva.com
*             Modifications to adapt to new signature of method "getSectorHasAn".
* |2020-04-15 berthaelena.tellez.contractor@bbva.com
*             Added call persistance leverage service
* |2020-06-03 javier.soto.carrascosa@bbva.com
*             Reduce logic complexity in validateRatingInSanction method
* |2020-06-09 mariohumberto.ramirez.contractor@bbva.com
*             The validateTable method was modified to know the type of analysis to validate
* |2020-08-12 antonio.munoz.perez.contractor@bbva.com
*             TOP DOW completion validations. Added new validateGroupProduct method.
* |2020-06-30 joseluis.garcia4.contractor@bbva.com
*             Change reference to PoliciesWrapper.
* |2020-08-11 juanignacio.hita.contractor@bbva.com
*             Add checkValidateCurrency method and in the call for the group customer
* |2020-08-27 joseluis.garcia4.contractor@bbva.com
*             Add Leveraged validations (check either excluded or unexcluded, must be calculated if not excluded).
* |2020-09-02 joseluis.garcia4.contractor@bbva.com
*             Fixes clients with no leveraged test not being validated. Only validate and persist leveraged in bottom-up clients.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-26 joseluis.garcia4.contractor@bbva.com
*              Handle empty TDBU indicator for historical ARCEs.
* |2020-11-16 juanignacio.hita.contractor@bbva.com
*             Integrate the custom metadata "DynForm_ValidateSections" to get the sections that will be used in the client validation.
* |2020-11-18 joseluis.garcia4.contractor@bbva.com
*             Fix double call to leverage persistence + Incorrect validation mark
* |2020-11-20 joseluis.garcia4.contractor@bbva.com
*             Fix validation in orphan customers (not advancing ARCE status).
* |2020-12-10 antonio.munoz.perez.contractor@bbva.com
*              Fix TD Group validation error.
* |2021-01-20 joseluis.garcia4.contractor@bbva.com
*             Add validation to check that at least one subsidiary has been added to the ARCE analysis (fixed: only applies for BU).
* |2021-03-15 juanignacio.hita.contractor@bbva.com
*             Add updateStatusLimitPers method and translate helper methods to a helper class for reduce TooManyMethods
* |2021-05-14 juanignacio.hita.contractor@bbva.com
*             Refactoring class and add arce__status_limit_pers_service__c
* |2021-06-01 juanignacio.hita.contractor@bbva.com
*             Revert changes remove validate rating
* |2021-06-15 mairohumberto.ramirez.contractor@bbva.com
*             Update validate fields logic
* |2022-01-11 juanignacio.hita.contractor@bbva.com
*             Add covenant validation to leveragedValidations method
* |2022-02-22 juanignacio.hita.contractor@bbva.com
*             Refactoring leveragedValidations method, created handleExcludedIndicator
* |2022-06-03 juanignacio.hita.contractor@bbva.com
*             Creates validateRecalcRating method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Arc_Gen_Validate_Customer_Service {
    /**
        * @Description: string with the name of a key of the map that return the method validateTable
    */
    public static final string ID_CLIENTE = 'IdCliente';
    /**
        * @Description: string with the name of a key of the map that return the method validateTable
    */
    public static final string ACTIVE = 'Active';
    /**
        * @Description: string with the name of a key of the map that return the method validateTable
    */
    public static final string REMOVE = 'Remove';
    /**
        * @Description: String with value "Group"
    */
    public static final string S_GROUP = 'Group';
    /**
        * @Description: String with value "Orphan"
    */
    public static final string ORPHAN = 'Orphan';
    /**
        * @Description: String with value "Client"
    */
    public static final string CLIENT = 'Client';
    /**
        * @Description: String with value "Bottom-up" for Top-down/Bottom-up indicator.
    */
    public static final string TDBU_BOTTOMUP = '1';
    /**
        * @Description: String with value "Top-down" for Top-down/Bottom-up indicator.
    */
    public static final string TDBU_TOPDOWN = '2';
    /**
        * @Description: String with value "3"
    */
    public static final string VALIDATE = '3';
    /**
        * @Description: String with value "2"
    */
    public static final string IN_SANCTION = '2';
    /**
        * @Description: String with value "2"
    */
    public static final string TEST_NOT_EXCLUDED = '2';
    /**
        * @Description: String with value "1" (Bottom-up)
    */
    public static final string S_BU = '1';
    /**
        * @Description: String with value "2" (Top-down)
    */
    public static final string S_TD = '2';
    /**
        * @Description: YES value
    */
    public static final string YES = '1';
    /**
        * @Description: No recalculate needed value arce__recalculate_rating__c field
    */
    public static final string NORECALCULATE = '4';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Service service = new Arc_Gen_Validate_Customer_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Validate_Customer_Service() {

    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns a List<Map<string,string>> that contain the error message of the
    * Policies table validations
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @return a List<Map<string,string>> that contain the error message of the
    * Policies table validations
    * @example validateTable(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_Validate_Customer_Controller.ResponseWrapper validateTable(string accHasAId) {
        Arc_Gen_Validate_Customer_Controller.ResponseWrapper result = new Arc_Gen_Validate_Customer_Controller.ResponseWrapper();
        List<Map<string,string>> mapResult = new List<Map<string,string>>();
        final List<String> accHasA = new List<String>{accHasAId};
        final List<arce__limits_exposures__c> exposureData = Arc_Gen_Validate_Customer_Data.getExposures(accHasA);
        final arce__Account_has_Analysis__c acc = Arc_Gen_Validate_Customer_Data.checkGroup(accHasAId);
        final String typeOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(accHasAId);
        final String consolidatedType = Arc_Gen_Validate_Customer_Helper.getConsolidatedType(acc);
        final List<Map<string,string>> validateTypo = Arc_Gen_Validate_Customer_Helper.validateTypology(accHasAId, exposureData);
        final List<Map<string,string>> fields = validateFields(accHasAId);

        // Initialize result.
        result.ratingStatus = new List<String>();
        result.analysisType = typeOfCustomer;

        if (consolidatedType == S_TD || typeOfCustomer != S_GROUP) {
            final List<arce__Account_has_Analysis__c> accHasObjLts = Arc_Gen_Validate_Customer_Data.checkCustomerFlag(new List<String>{accHasAId});
            final Map<String, String> mapResultStatus = utilErrorCheckVal(checkValidateCustomer(accHasObjLts, 'arce__status_limit_pers_service__c'), System.Label.Arc_Gen_StatusPersServiceCheckCustomer);
            if (mapResultStatus.isEmpty()) {
                final List<Map<string,string>> productResult = Arc_Gen_Validate_Customer_Helper.validateProduct(exposureData);
                mapResult = Arc_Gen_Validate_Customer_Helper.createFinalMap(validateTypo, fields, productResult);
            } else {
                result.ratingStatus = new List<String>();
                result.responseError = mapResultStatus.get(Arc_Gen_Validate_Customer_Helper.FIELD_MISSING);
            }
        }

        if (typeOfCustomer == S_GROUP) {
            final List<arce__Analysis__c> childsId = Arc_Gen_Validate_Customer_Data.getIdsOfChildAccount(acc.arce__Analysis__r.arce__Group__c, acc.arce__Analysis__c);
            final List<String> idOfClients = Arc_Gen_Validate_Customer_Helper.getIdsOfFilials(childsId);
            final List<String> idOfAllAcc = new List<String>{accHasAId};
            idOfAllAcc.addAll(idOfClients);
            if (idOfClients.isEmpty() && consolidatedType == S_BU) {
                result.ratingStatus = new List<String>();
                result.responseError = System.Label.Arc_Gen_ErrorNoSubsidiaries;
            } else if (Arc_Gen_Validate_Customer_Helper.checkValidateCurrency(idOfAllAcc)) {
                final Map<String, String> mapValStatus = checkCustomersAndServices(new List<String>{acc.arce__Analysis__r.arce__Group__c}, idOfClients);
                if (mapValStatus.isEmpty()) {
                    final Double multiplicationFactorGP = Arc_Gen_Validate_Customer_Helper.getMultiplicationFactor((String)arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(accHasA)[0].arce__magnitude_unit_type__c);
                    final List<Map<string,string>> groupResult = getGroup(exposureData, idOfClients, multiplicationFactorGP);
                    mapResult = Arc_Gen_Validate_Customer_Helper.createFinalMap(validateTypo, fields, groupResult);
                } else {
                    result.responseError = mapValStatus.get(Arc_Gen_Validate_Customer_Helper.FIELD_MISSING) + ' - ' + System.Label.Arc_Gen_ValidatePleaseReview + ' ' + mapValStatus.get(Arc_Gen_Validate_Customer_Service.ID_CLIENTE);
                    mapResult.add(mapValStatus);
                }
            } else {
                result.ratingStatus = new List<String>();
                result.responseError = System.Label.Arc_Gen_Validate_PoliciesCurrency;
            }
        }

        result.gblResponse = mapResult;
        return result;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Performs leveraged validations and calls persistence service if no error
    * has been found during validation.
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @param wrapper the wrapper that contains previous validation results.
    * --------------------------------------------------------------------------------------
    **/
    public static void validateLeveraged(String accHasAId, Arc_Gen_Validate_Customer_Controller.ResponseWrapper wrapper) {
        final Boolean noPreviousErrors = wrapper.gblResponse != null && wrapper.gblResponse.isEmpty() && wrapper.ratingStatus.isEmpty() && String.isBlank(wrapper.responseError);
        final arce__Account_has_Analysis__c aha = Arc_Gen_Validate_Customer_Data.getAhaWithLeveragedInfo(accHasAId);
        final String typeOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(accHasAId);
        final String tdbuIndicator = aha.arce__anlys_wkfl_cnsld_ffss_type__c;
        final Boolean validateLev = typeOfCustomer == ORPHAN || (typeOfCustomer == CLIENT && tdbuIndicator == TDBU_BOTTOMUP) || (typeOfCustomer == S_GROUP && tdbuIndicator == TDBU_TOPDOWN);
        if (noPreviousErrors && validateLev) {
            leveragedValidations(aha, wrapper);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Performs leveraged validations and calls persistence service if no error
    * has been found during validation.
    * --------------------------------------------------------------------------------------
    * @param aha arce__Account_has_Analysis__c record
    * @param wrapper the wrapper that contains previous validation results.
    * --------------------------------------------------------------------------------------
    **/
    public static void leveragedValidations(arce__Account_has_Analysis__c aha, Arc_Gen_Validate_Customer_Controller.ResponseWrapper wrapper) {
        // If participant can have Leveraged Test, validate the following.
        final String excludedIndicator = aha.arce__ll_test_scope_ind_type__c;
        final Boolean notCalculated = aha.arce__ll_before_adj_ind_type__c == null || aha.arce__ll_after_adj_ind_type__c == null;

        if (excludedIndicator == null) {
            // Leveraged test has neither been excluded nor not excluded.
            wrapper.responseError = System.Label.Arc_Gen_ErrorLeveragedExclusion;
        } else if (excludedIndicator == TEST_NOT_EXCLUDED && notCalculated) {
            // Leveraged test has not been excluded, but has not been calculated.
            wrapper.responseError = System.Label.Arc_Gen_ErrorLeveragedNotCalculated;
        } else {
            handleExcludedIndicator(aha, wrapper);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Handles excluded conditions that fill wrapper response error and gblResponse
    * --------------------------------------------------------------------------------------
    * @param aha arce__Account_has_Analysis__c record
    * @param wrapper the wrapper that contains previous validation results.
    * --------------------------------------------------------------------------------------
    **/
    private static void handleExcludedIndicator(arce__Account_has_Analysis__c aha, Arc_Gen_Validate_Customer_Controller.ResponseWrapper wrapper) {
        final String excludedIndicator = aha.arce__ll_test_scope_ind_type__c;
        final Boolean covenantBreach = aha.arce__fin_covenants_breach_type__c == YES && aha.arce__fin_covenants_breach_desc__c == null;
        final Boolean covenantValidation = aha.arce__entity_covenants_type__c == null || aha.arce__fin_covenants_breach_type__c == null || covenantBreach;
        if (excludedIndicator == TEST_NOT_EXCLUDED && covenantValidation && aha.arce__ll_before_adj_ind_type__c == YES) {
            // Leveraged test has not been excluded, but has covenant fields null.
            wrapper.responseError = System.Label.Arc_Gen_ErrorLeveragedCovenant;
        } else if ((wrapper.responseError == '' || wrapper.responseError == null) &&
            wrapper.gblResponse != null && wrapper.gblResponse.isEmpty() && wrapper.ratingStatus.isEmpty()) {
            // If no error, persist leveraged test data.
            wrapper.gblResponse = validatePersistanceTL(aha.Id);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Changes the status of the ARCE analysis if no errors have been found during
    * validation and the AHA is from an orphan or group customer.
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @param wrapper the wrapper that contains previous validation results.
    * --------------------------------------------------------------------------------------
    **/
    public static void changeStatusArce(String accHasAId, Arc_Gen_Validate_Customer_Controller.ResponseWrapper wrapper) {
        final Boolean canTriggerChange = wrapper.analysisType == ORPHAN || wrapper.analysisType == S_GROUP;
        final Boolean noErrors = wrapper.responseError == '' || wrapper.responseError == null;
        final Boolean noIncomplete = wrapper.gblResponse.isEmpty() && wrapper.ratingStatus.isEmpty();
        if (canTriggerChange && noErrors && noIncomplete) {
            Arc_Gen_Validate_Customer_Data.changeStatusArce(accHasAId);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns a string with the name of the client no validated or a validation
    * flag
    * --------------------------------------------------------------------------------------
    * @param List<arce__Account_has_Analysis__c> accHasObjLts
    * @param String fieldName
    * @return a string with the name of the client no validated or a validation flag
    * @example List<String> lstStr = checkValidateCustomer(accHasObjLts, fieldName)
    * --------------------------------------------------------------------------------------
    **/
    public static List<String> checkValidateCustomer(List<arce__Account_has_Analysis__c> accHasObjLts, String fieldName) {
        final List<String> resultFalse = new List<String>();
        List<String> result = new List<String>();
        for (arce__Account_has_Analysis__c acchas: accHasObjLts) {
            if (fieldName == 'arce__arce_ctmr_flag__c' && acchas.arce__arce_ctmr_flag__c == false) {
                resultFalse.add((String)acchas.arce__Customer__r.Name);
            } else if (fieldName == 'arce__status_limit_pers_service__c' && accHas.arce__status_limit_pers_service__c == false) {
                resultFalse.add((String)acchas.arce__Customer__r.Name);
            }
        }
        if (resultFalse.isEmpty()) {
            result.add(ACTIVE);
        } else {
            result = resultFalse;
        }
        return result;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description manage the validation of some fields in the policy tab
    * --------------------------------------------------------------------------------------
    * @param accHasAId Id of the arce__Account_has_Analysis__c
    * @return List<Map<string, string>> with the name of the missing fields
    * @example validateFields(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> validateFields(string accHasAId) {
        List<Map<string,string>> mapResult = new List<Map<string,string>>();
        final Set<String> mapFieldLts = new Set<String>();
        final Map<String,SObject> devFieldsConfigMap = new Map<String,SObject>();
        final Map<String,String> devFieldsValueMap = new Map<String,String>();
        final List<arce__Account_has_Analysis__c> accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<Id>{accHasAId});
        final arce__Sector__c sector = Arc_Gen_Sector_Data.getSectorAccHasAn(accHasAnalysis[0], accHasAnalysis[0].arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
        final String clientName = Arc_Gen_Validate_Customer_Data.getNameClient(accHasAId);
        final String templateDevName = Arc_Gen_Sector_Data.getTemplateFromSector(sector,'500');
        final List<String> lstSections = Arc_Gen_Validate_Customer_Data.getConfSectionName(templateDevName);
        final List<dyfr__Field_Config__c> fieldConfigData = Arc_Gen_Validate_Customer_Data.getFieldsBySection(lstSections, templateDevName);
        final Boolean verifyFields = Arc_Gen_FieldConfig_Data.hasFieldSections(fieldConfigData, lstSections);

        if (!fieldConfigData.isEmpty() && verifyFields) {
            final dyfr__Field_Config__c stageControl = Arc_Gen_Validate_Customer_Data.getFieldStageControl('arce__Analysis__r.arce__Stage__c', templateDevName);
            final dyfr__Field_Config__c groupControl = Arc_Gen_Validate_Customer_Data.getGroupControl('arce__group_asset_header_type__c', templateDevName, lstSections[2]);
            final arce__Account_has_Analysis__c valControlFld = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation((Id)accHasAId);
            final String valueStageControl = valControlFld.arce__Analysis__r.arce__Stage__c;
            final String valueGroupControl = valControlFld.arce__group_asset_header_type__c;
            for (dyfr__Field_Config__c field: fieldConfigData) {
                mapFieldLts.add((String)field.dyfr__Map_field__c);
                devFieldsConfigMap.put((String)field.dyfr__DeveloperName__c, field);
            }

            devFieldsConfigMap.put((String)stageControl.dyfr__DeveloperName__c, stageControl);
            devFieldsConfigMap.put((String)groupControl.dyfr__DeveloperName__c, groupControl);
            String mapFieldString = String.join(new List<String>(mapFieldLts), ',');
            final List<arce__Account_has_Analysis__c> fieldValues = Arc_Gen_Validate_Customer_Data.getValues(accHasAId, mapFieldString);
            for (dyfr__Field_Config__c field: fieldConfigData) {
                devFieldsValueMap.put((String)field.dyfr__DeveloperName__c, String.valueOf(fieldValues[0].get(field.dyfr__Map_field__c)));
            }
            devFieldsValueMap.put((String)stageControl.dyfr__DeveloperName__c,valueStageControl);
            devFieldsValueMap.put((String)groupControl.dyfr__DeveloperName__c,valueGroupControl);
            for (dyfr__Field_Config__c field: fieldConfigData) {
                final Boolean fieldFilled = Arc_Gen_Validate_Customer_Helper.validateField(field, devFieldsConfigMap, devFieldsValueMap);
                if (fieldFilled == false) {
                    mapResult.add(new Map<string,string>{ID_CLIENTE => clientName, Arc_Gen_Validate_Customer_Helper.FIELD_MISSING => field.dyfr__Label__c});
                }
            }
        } else {
            throw new AuraHandledException(System.Label.Arc_Gen_NotElements);
        }

        return mapResult;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description manage the validation when a client is a group
    * --------------------------------------------------------------------------------------
    * @param exposureParentData - arce__limits_exposures__c data of the group
    * @param childsId - object that contains the the account has analysis Ids of the clients
    * @return List<Map<string,string>> with the error message
    * @example getGroup(exposureParentData, childsId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> getGroup(List<arce__limits_exposures__c> exposureParentData, List<String> accHasIdList, Double multiplicationFactorGP) {
        final List<Map<String,String>> mapResult = new List<Map<String,String>>();
        Map<String,Double> multiplicationFactorChilds = new Map<String,Double>();
        final List<arce__Account_has_Analysis__c> accHasAnData = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(accHasIdList);
        for (arce__Account_has_Analysis__c accHasAn: accHasAnData) {
            multiplicationFactorChilds.put(accHasAn.Id, Arc_Gen_Validate_Customer_Helper.getMultiplicationFactor((String)acchasAn.arce__magnitude_unit_type__c));
        }
        final List<arce__limits_exposures__c> exposureChildData = Arc_Gen_Validate_Customer_Data.getExposures(accHasIdList);
        for (arce__limits_exposures__c exposureParentD: exposureParentData) {
            for (arce__limits_exposures__c exposureChildD: exposureChildData) {
                if (exposureParentD.arce__limits_typology_id__r.Name == exposureChildD.arce__limits_typology_id__r.Name) {
                    for (integer i = 0; i < Arc_Gen_Validate_Customer_Helper.FIELD_LIST.size(); i++) {
                        if (Double.valueOf((Double)exposureParentD.get(Arc_Gen_Validate_Customer_Helper.FIELD_LIST.get(i))) * multiplicationFactorGP < Double.valueOf((Double)exposureChildD.get(Arc_Gen_Validate_Customer_Helper.FIELD_LIST.get(i))) * multiplicationFactorChilds.get(exposureChildD.arce__account_has_analysis_id__c)) {
                            mapResult.add(new Map<String,String>{ID_CLIENTE => String.valueOf((String)exposureChildD.arce__account_has_analysis_id__r.arce__Customer__r.Name), Arc_Gen_Validate_Customer_Helper.TYPOLOGY => (String)exposureChildD.arce__limits_typology_id__r.Name, Arc_Gen_Validate_Customer_Helper.FIELD_NAME => Arc_Gen_Validate_Customer_Helper.FIELD_LABEL.get(i)});
                        }
                    }
                }
            }
        }
        return mapResult;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Valid rating in Sanction
    * --------------------------------------------------------------------------------------
    * @param recordId - id of the account has analysis object
    * @param typeOfCustomer - type of customer
    * @param idOfClients - List<Id> of account has analysis object
    * @return List<string> with name of the clients that do not has a valid rating
    * @example validateRatingInSanction(recordId, typeOfCustomer, idOfClients)
    * --------------------------------------------------------------------------------------
    **/
    public static List<String> validateRatingInSanction(String recordId, String typeOfCustomer, List<String> idOfClients) {
        final List<String> result = new List<String>();
        final List<Id> idLts = new List<Id>();
        final Id idAccHas = Id.valueOf(recordId);
        final arce__Account_has_Analysis__c stageOfArce = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(idAccHas);
        if (typeOfCustomer == S_GROUP && stageOfArce.arce__Analysis__r.arce__Stage__c == IN_SANCTION) {
            for (String idClient: idOfClients) {
                idLts.add(Id.valueOf(idClient));
            }
            final List<arce__Account_has_Analysis__c> ratingStatus = arce.Arc_Gen_AccHasAnalysis_Data.getRatingStatus(idLts);
            for (arce__Account_has_Analysis__c ratingStat: ratingStatus) {
                if (ratingStat.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c != VALIDATE) {
                    result.add(ratingStat.arce__Customer__r.Name);
                }
            }
        } else if (typeOfCustomer != S_GROUP && stageOfArce.arce__Analysis__r.arce__Stage__c == IN_SANCTION) {
            final List<arce__Account_has_Analysis__c> ratingStatus = arce.Arc_Gen_AccHasAnalysis_Data.getRatingStatus(new List<Id>{recordId});
            if (ratingStatus[0].arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c != VALIDATE) {
                result.add(ratingStatus[0].arce__Customer__r.Name);
            }
        }
        return result;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validates if leverage test persistence will run
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @return a List<Map<string,string>> that contain the error message of the persistance service
    * @example validatePersistanceTL(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> validatePersistanceTL(string accHasAId) {
        List<Map<string,string>> mapResult = new List<Map<string,string>>();
        Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper wrapper = new Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper();
        wrapper = Arc_Gen_TestLeverage_service.leveragePersistence(accHasAId);
        if(!wrapper.success) {
            mapResult.add(new map<String,String>{ID_CLIENTE => Label.Arc_Gen_ErrPersistLev});
        }
        return mapResult;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Sets validated customer flag to true if no error has been detected.
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @param wrapper the wrapper that contains previous validation results.
    * --------------------------------------------------------------------------------------
    **/
    public static void activeCustomerFlag(String accHasAId, Arc_Gen_Validate_Customer_Controller.ResponseWrapper wrapper) {
        final Boolean success = (wrapper.responseError == '' || wrapper.responseError == null) && wrapper.gblResponse.isEmpty() && wrapper.ratingStatus.isEmpty();
        if (success) {
            Arc_Gen_Validate_Customer_Data.activeCustomerFlag(accHasAId, ACTIVE);
        } else {
            Arc_Gen_Validate_Customer_Data.activeCustomerFlag(accHasAId, REMOVE);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Util method that returns map with flag and error label
    * --------------------------------------------------------------------------------------
    * @param List<String> flagType
    * @param String lblError
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String, String> utilErrorCheckVal(List<String> flagType, String lblError) {
        Map<String, String> mapResult = new Map<string,string>();
        if (!flagType.isEmpty() && flagType[0] != Arc_Gen_Validate_Customer_Service.ACTIVE) {
            mapResult = new Map<String, String>{Arc_Gen_Validate_Customer_Service.ID_CLIENTE => string.join(flagType,', '),
                                                Arc_Gen_Validate_Customer_Helper.FIELD_MISSING => lblError};
        }
        return mapResult;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Checks the status of group and customers
    * --------------------------------------------------------------------------------------
    * @param List<String> idAhaGroup : list of account has analysis id
    * @param List<String> idOfClients : list of account has analysis id
    * --------------------------------------------------------------------------------------
    **/
    private static Map<String, String> checkCustomersAndServices(List<String> idAhaGroup, List<String> idOfClients) {
        final List<arce__Account_has_Analysis__c> accHasObjLts = Arc_Gen_Validate_Customer_Data.checkCustomerFlag(idAhaGroup);
        final List<arce__Account_has_Analysis__c> accHasClients = Arc_Gen_Validate_Customer_Data.checkCustomerFlag(idOfClients);
        final Map<String, String> mapResultStatus = utilErrorCheckVal(checkValidateCustomer(accHasClients, 'arce__arce_ctmr_flag__c'), System.Label.Arc_Gen_ClientNoValidated);
        final Map<String, String> mapAhaGroup = utilErrorCheckVal(checkValidateCustomer(accHasObjLts, 'status_limit_pers_service__c'), System.Label.Arc_Gen_StatusPersServiceCheckCustomer);
        final Map<String, String> mapAhaClients = mapAhaGroup.isEmpty() ? utilErrorCheckVal(checkValidateCustomer(accHasClients, 'status_limit_pers_service__c'), System.Label.Arc_Gen_StatusPersServiceCheckCustomer) : mapAhaGroup;
        return mapResultStatus.isEmpty() ? mapAhaClients : mapResultStatus;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description method that validates if its necessary to recalculate the rating because changed qualitative questions.
    * --------------------------------------------------------------------------------------
    * @param accHasAId of the object arce__Account_has_Analysis__c
    * @param wrapper   the wrapper that contains previous validation results.
    * --------------------------------------------------------------------------------------
    **/
    public static void validateRecalcRating(String accHasAId, Arc_Gen_Validate_Customer_Controller.ResponseWrapper wrapper) {
        final List<arce__Account_has_Analysis__c> lstAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAId});
        if (lstAha[0].arce__recalculate_rating__c != NORECALCULATE) {
            wrapper.responseError = System.Label.Arc_Gen_ErrorChangesQualitativeQuest;
        }
    }
}