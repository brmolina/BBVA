/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SavePolicies
* @Author   José Luis García Díaz
* @Date     Created: 30/06/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages the save event on the "Policies" tab. The save implementation
* checks permissions on the analysis and clears Leveraged Test results if key fields change.
* -----------------------------------------------------------------------------------------------
* @Changes
* |2020-06-30 José Luis García Díaz
*             Class creation.
* |2020-08-20 José Luis García Díaz
*             Clear Leveraged Test fields when it is excluded manually after not being excluded.
* |2020-09-02 José Luis García Díaz
*             Add missing fields to be cleared when excluded manually after not being excluded.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-26 Juan Ignacio Hita
*             Add call persistence for save policies
* |2021-01-21 Juan Ignacio Hita
*             Fix the logic to assign a default value in risk policy type field for BU analysis
* |2021-01-26 José Luis García Díaz
*             When policies table is extended, recalculate Total Credit Risk after saving.
* |2021-03-17 Juan Ignacio Hita
*             Refactoring of validations and add status_limits_persistence in the logic
* |2021-04-09 José Luis García Díaz
*             Do not clear covenant field data as they can also be populated in Banking Relationship.
* |2021-03-17 Juan Ignacio Hita
*             Refactoring of validations and add status_limits_persistence in the logic
* |2022-05-24 Juan Ignacio Hita
*             Add to call hasManualTablePerm method in save method class
* |2022-06-06 Juan Ignacio Hita
*             Add checkChangesQualQuestion validation and FIELDS_COMMON list
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SavePolicies implements dyfr.Save_Interface {
    /*
    * @description: Fields to check in the Account_has_Analysis__c (group) object. If any of these fields
    * change, leveraged test results FOR THE ANALYSIS AND ALL AHAs will be cleared.
    */
    private static final List<String> FIELDS_TO_CHECK_GROUP = new List<String> {
        'arce__currency_id__c', 'arce__magnitude_unit_type__c'
    };
    /*
    * @description: Fields to check in the Account_has_Analysis__c object. If any of these fields
    * change, leveraged test results will be cleared FOR ONLY THE AHA.
    */
    private static final List<String> FIELDS_TO_CHECK_AHA = new List<String> {
        'arce__currency_id__c', 'arce__magnitude_unit_type__c',
        'arce__debt_comt_not_disb_local_amount__c',
        'arce__ll_adj_debt_auditor_amount__c', 'arce__ll_adj_ebitda_auditor_amount__c',
        'arce__ll_adj_deb_excl_amount__c', 'arce__ll_adj_ebitda_excl_amount__c',
        'arce__ll_other_adj_debt_amount__c', 'arce__ll_other_adj_ebitda_amount__c'
    };

    /**
    * @description: List of fields present on the Leveraged section of the policies screen. These fields
    * are to be cleared when the test is excluded after not being excluded.
    */
    private static final List<String> LL_FIELDS_TO_CLEAR = new List<String> {
        'arce__ll_adj_debt_auditor_amount__c', 'arce__ll_adj_deb_excl_amount__c',
        'arce__ll_other_adj_debt_amount__c', 'arce__ll_adj_ebitda_auditor_amount__c',
        'arce__ll_adj_ebitda_excl_amount__c', 'arce__ll_other_adj_ebitda_amount__c',
        'arce__ll_before_adj_ind_type__c', 'arce__ll_after_adj_ind_type__c',
        'arce__ll_before_adj_clsfn_type__c', 'arce__ll_after_adj_clsfn_type__c',
        'arce__ll_previous_anlys_ind_type__c', 'arce__ll_anlys_clsfn_var_rsn_id__c'
    };

    /**
    * @description: List of fields persistence service
    */
    private static final List<String> FD_SERV_PERSIST = new List<String> {
        'arce__Analysis__r.arce__analysis_risk_sanction_date__c',
        'arce__gf_anlys_risk_prps_expiry_date__c', 'arce__risk_policy_type__c',
        'arce__risk_request_desc__c, arce__Customer__c, Name','arce__anlys_wkfl_cnsld_ffss_type__c',
        'arce__status_limit_pers_service__c', 'arce__call_limit_service__c', 'arce__limit_exposure_ext_ind_type__c'
    };

    /**
    * @description: List of common fields
    */
    private static final List<String> FIELDS_COMMON = new List<String> {
        'Analysis__c', 'arce__group_asset_header_type__c', 'arce__ll_test_scope_ind_type__c',      // To check if leveraged test has been excluded/unexcluded
        'arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c', 'arce__analysis_template_id__c', 'arce__anlys_wkfl_cnsld_ffss_type__c',
        'arce__limit_exposure_ext_ind_type__c', 'arce__g_rtg_tool_typ_id__c', 'arce__RAR_rating_tool_id__c',
        'arce__Analysis__r.arce__analysis_customer_relation_type__c'
    };

    /**
    * @description: Default value with no data for risk policy type field
    */
    private static final String RISKPOL_TYPE = '3';

    /**
    * @description: Constant to indicate the option 'Yes' in 'Enable extended risk policy' field.
    */
    private static final String ENABLEEXTENDED_YES = '1';

    /**
    * -------------------------------------------------------------------------------
    * @description: Method called when the Policies Tab is saved.
    * -------------------------------------------------------------------------------
    * @date   30/06/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param listObject the saved object list, provided by dynamic form.
    * @return the stringified wrapper with the save results.
    */
    public String save(List<sObject> listObject) {
        for(sObject obj : listObject) {
            final String recordId = String.valueOf(obj.get('Id'));

            // Only validate if what is being saved is an Account_has_analysis__c
            // record.
            if (Id.valueOf(recordId).getSobjectType() != arce__Account_has_Analysis__c.SObjectType) {
                continue;
            }
            // Validate that the user has permission to edit the record
            // before saving.
            if (Arc_Gen_TabSet_service.getPermissionToEdit(recordId) != 'true') {
                throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
            }

            // Check changes in the observed fields. If any changes, clear Leveraged Test results.
            final arce__Account_has_Analysis__c newAha = (arce__Account_has_Analysis__c) obj;
            final Set<String> fieldsToRetrieve = new Set<String>();
            fieldsToRetrieve.addAll(FIELDS_TO_CHECK_GROUP);
            fieldsToRetrieve.addAll(FIELDS_TO_CHECK_AHA);
            fieldsToRetrieve.addAll(FD_SERV_PERSIST);
            fieldsToRetrieve.addAll(FIELDS_COMMON);

            final String currencyToCheck = currencyToCheck(newAha);
            final arce__Account_has_Analysis__c oldAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(newAha.Id, new List<String>(fieldsToRetrieve));

            // Adds exception for bottom up analysis with default value in policy risk type field
            polRiskFldbottomUp(oldAha, newAha);

            // Return true if change the currency or unit fields
            final Boolean clearAnlysResults = checkChangesInFields(oldAha, newAha, FIELDS_TO_CHECK_GROUP);
            final Boolean enableExtendedPol = getExtendPolicies(newAha, oldAha);
            final Boolean logicUpdateLimit = clearAnlysResults || !oldAha.arce__status_limit_pers_service__c || !oldAha.arce__call_limit_service__c || enableExtendedPol;

            Map<String,Arc_Gen_Limits_Service.LimitsResponse> mapLimits = new Map<String,Arc_Gen_Limits_Service.LimitsResponse>();
            if (!Arc_Gen_Auto_ExpTable_Service_Helper.hasManualTablePerm(recordId)) {
                // Call limit service
                mapLimits = Arc_Gen_Limits_Service.callLimitById(recordId, currencyToCheck);
                Arc_Gen_Limits_Service_Helper.validationCurrency(mapLimits, currencyToCheck);
            }

            // Call to policies persistence service
            Arc_Gen_PersistencePolicies_service.callPoliciesPersService(newAha, oldAha);

            if (logicUpdateLimit) {
                List<arce__limits_exposures__c> limExpDataLts = new List<arce__limits_exposures__c>();
                if (Arc_Gen_Auto_ExpTable_Service_Helper.hasManualTablePerm(recordId)) {
                    limExpDataLts = arce.Arc_Gen_LimitsExposures_Data.getExposurDataMod(new List<Id>{recordId});
                } else {
                    // Gets the data exposure limits populated with the data retrieved from the service.
                    limExpDataLts = Arc_Gen_Auto_ExpTable_Service_Helper.getLimitsForPersistence(mapLimits, recordId);
                }
                Arc_Gen_PersistenceLimits_service.callLimitsPersService(oldAha.Id, newAha, limExpDataLts);
                // Update limit exposures, AHA fields related and group risk detail fields.
                Arc_Gen_Auto_ExpTable_Service_Helper.updatePersLimits(limExpDataLts, recordId);
            }

            leveragedValidations(clearAnlysResults, oldAha, newAha);
            // Recalculate Total Credit Risk.
            recalculateCreditRisk(newAha);
            Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(newAha, oldAha, String.valueOf(Arc_Gen_SavePolicies.class.getName()));
        }
        return JSON.serialize(
            new arce.Arc_Gen_wrpSave(true, Label.Arc_Gen_Generic_ErrorSumPersBR, listObject));
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Recalculate Total Credit Risk when it is enabled.
    * -------------------------------------------------------------------------------
    * @date   26/01/2021
    * @author joseluis.garcia4.contractor@bbva.com
    * @param newAha the AHA as provided by the dynamic form.
    */
    private void recalculateCreditRisk(arce__Account_has_Analysis__c newAha) {
        if (newAha.arce__limit_exposure_ext_ind_type__c == ENABLEEXTENDED_YES) {
            Arc_Gen_Expandible_Table_Service.sumTypologies(newAha.Id);
        }
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Checks if any of the key fields have changed.
    * -------------------------------------------------------------------------------
    * @date   30/06/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param newAha the AHA as provided by the dynamic form.
    * @return true if any field has changed, false otherwise.
    */
    private Boolean checkChangesInFields(arce__Account_has_Analysis__c oldAha, arce__Account_has_Analysis__c newAha, List<String> fieldsToCheck) {
        Boolean anyFieldDifferent = false;
        for (String fieldName : fieldsToCheck) {
            if (newAha.isSet(fieldName) && oldAha.get(fieldName) != newAha.get(fieldName)) {
                anyFieldDifferent = true;
                break;
            }
        }

        return anyFieldDifferent;
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: If test exclusion state changes, clears unused fields.
    * -------------------------------------------------------------------------------
    * @date   25/08/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param newAha the AHA as provided by the dynamic form.
    */
    private void handleTestExclusionChange(arce__Account_has_Analysis__c newAha) {
        if (newAha.arce__ll_test_scope_ind_type__c == '1') {
            // If leveraged excluded, clear leveraged fields.
            final arce__Account_has_Analysis__c updatedAha = new arce__Account_has_Analysis__c(Id = newAha.Id);
            for (String fieldName : LL_FIELDS_TO_CLEAR) {
                updatedAha.put(fieldName, null);
            }
            arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(updatedAha);
        } else if (newAha.arce__ll_test_scope_ind_type__c == '2') {
            // If not excluded, clear exclusion reason.
            final arce__Account_has_Analysis__c updatedAha = new arce__Account_has_Analysis__c(
                Id = newAha.Id, arce__ll_test_manl_excl_rsn_type__c = ''
            );
            arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(updatedAha);
        }
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Method that execute leveraged test validations
    * -------------------------------------------------------------------------------
    * @date   30/03/2021
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Boolean clearAnalysisResults
    * @param  arce__Account_has_Analysis__c oldAha
    * @param  arce__Account_has_Analysis__c newAha
    * @return void
    * @example leveragedValidations(clearAnalysisResults, newAha, oldAha);
    */
    private void leveragedValidations(Boolean clearAnalysisResults, arce__Account_has_Analysis__c oldAha, arce__Account_has_Analysis__c newAha) {
        // Check if test has just been excluded/unexcluded.
        if (oldAha.arce__ll_test_scope_ind_type__c != newAha.arce__ll_test_scope_ind_type__c) {
            handleTestExclusionChange(newAha);
        }

        if (clearAnalysisResults) {
            Arc_Gen_TestLeverage_service.clearTestLeveragedResultsAnalysis(oldAha.arce__Analysis__c);
        } else {
            final Boolean clearAhaResults = checkChangesInFields(oldAha, newAha, FIELDS_TO_CHECK_AHA);
            // Clear results.
            if (clearAhaResults) {
                Arc_Gen_TestLeverage_service.clearTestLeveragedResults(oldAha.Id);
            }
        }
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Method that adss exception for fill risk policy type field in a bottom up type analysis
    * -------------------------------------------------------------------------------
    * @date    02/12/2020
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   arce__Account_has_Analysis__c newAha
    * @return  void
    * @example polRiskFldbottomUp(newAha);
    */
    private void polRiskFldbottomUp(arce__Account_has_Analysis__c oldAha, arce__Account_has_Analysis__c newAha) {
        // Fill risk policy type with value 3 for BOTTOM UP analysis
        final Boolean isBottomUp = oldAha.arce__anlys_wkfl_cnsld_ffss_type__c == arce.Arc_Gen_Constants.TDBU_BOTTOM_UP && String.isEmpty(newAha.arce__risk_policy_type__c);
        if (isBottomUp) {
            newAha.arce__risk_policy_type__c = RISKPOL_TYPE;
        }
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Method that check if the currency is null
    * -------------------------------------------------------------------------------
    * @date    12/04/2021
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   arce__Account_has_Analysis__c newAha
    * @return  String
    * @example currencyToCheck(newAha);
    */
    private String currencyToCheck(arce__Account_has_Analysis__c newAha) {
        final String currValue = newAha.arce__currency_id__c == null ? '' : newAha.arce__currency_id__c;
        if (currValue == '') {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_PoliciesErrorNoCurrency);
        }
        return currValue;
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Method that return true if the enable extended field changed 1 (YES)
    * -------------------------------------------------------------------------------
    * @date    29/04/2021
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   arce__Account_has_Analysis__c newAha
    * @param   arce__Account_has_Analysis__c oldAha
    * @return  Boolean
    * @example Boolean retVal = getExtendPolicies(newAha, oldAha);
    */
    private Boolean getExtendPolicies(arce__Account_has_Analysis__c newAha, arce__Account_has_Analysis__c oldAha) {
        return oldAha.arce__limit_exposure_ext_ind_type__c == newAha.arce__limit_exposure_ext_ind_type__c || oldAha.arce__limit_exposure_ext_ind_type__c == null ? false : true;
    }
}