/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Auto_ExpTable_Service_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-01-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for policie table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-01 joseluis.garcia4.contractor@bbva.com
*             Add check for currency.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-12 joseluis.garcia4.contractor@bbva.com
*             Setup risk table when initializing policies table (on limit service call).
* |2020-11-16 juanignacio.hita.contractor@bbva.com
*             Check if limit exposures have been created before update action
* |2020-11-27 juanignacio.hita.contractor@bbva.com
*             Create getLimitsForPersistence, updatePersLimits methods
* |2021-01-14 ivan.cons@bbva.com
*             Alligned and added namespaces
* |2021-03-17 juanignacio.hita.contractor@bbva.com
*             Refactoring fillServiceData method for return map limit response
*             Adds currency validation before call to limit service
* |2021-05-17 juanignacio.hita.contractor@bbva.com
*             Refactoring class
* |2021-05-26 juanignacio.hita.contractor@bbva.com
*             Add hasManualTablePerm method get POLICIES_PERM arce config permissions
* |2021-06-18 juanignacio.hita.contractor@bbva.com
*             Add Test.isRunningTest() condition in hasManualTablePerm method
* |2021-08-06 juanignacio.hita.contractor@bbva.com
*             Add subprocess type analysis in fillLimitsWithResp method
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Auto_ExpTable_Service_Helper {
    /**
        * @Description: param to call limits service
    */
    static final string S_GROUP = 'GROUP';
    /**
        * @Description: param to call limits service
    */
    static final string SUBSIDIARY = 'SUBSIDIARY';
    /**
    * @Description Arce config for manual permission policies table
    */
    private static final String POLICIES_PERM = 'ManualPoliciesTablePerm';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param void
    * @return void
    * @example Arc_Gen_Auto_ExpTable_Service_Helper helper = new Arc_Gen_Auto_ExpTable_Service_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Auto_ExpTable_Service_Helper() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Update policie table records with the data of the limit service
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param recordId - id of the acc has analysis object
    * @param selectedCurrency - currency selected
    * @return Map<String,Arc_Gen_Limits_Service.LimitsResponse>
    * @example Map<String,Arc_Gen_Limits_Service.LimitsResponse> map = fillServiceData(recordId, selectedCurrency)
    * --------------------------------------------------------------------------------------
    **/
    public static void fillServiceData(Id recordId, String selectedCurrency) {
        final String typoOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId) == 'Group' ? S_GROUP : SUBSIDIARY;
        final arce__Account_has_Analysis__c accHasRel = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final Map<Id,arce.Arc_Gen_Account_Wrapper> accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasRel.arce__customer__c});
        final List<arce__Account_has_Analysis__c> acchasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId});
        currencyToCheck(accHasRel);

        final Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap = Arc_Gen_Limits_Service.callLimitsService(typoOfCustomer,accWrapper.get(accHasRel.arce__customer__c).accNumber, 'limits', accHasRel.arce__currency_id__c);
        Arc_Gen_Limits_Service_Helper.validationCurrency(limitRespMap, accHasRel.arce__currency_id__c);
        // Check if limit exposures default is created
        final List<arce__limits_exposures__c> limExpDataLts = generateLimExpo(recordId);

        for (arce__limits_exposures__c limitExpData: limExpDataLts) {
            fillLimitsWithResp(limitRespMap, limitExpData, acchasAn[0]);
        }
        acchasAn[0].arce__call_limit_service__c = true;
        acchasAn[0].arce__magnitude_unit_type__c = '1';
        acchasAn[0].arce__prev_magnitude_unit_type__c = '1';
        acchasAn[0].arce__last_update_policie__c = System.now();
        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(acchasAn);
        arce.Arc_Gen_LimitsExposures_Data.updateExposureData(limExpDataLts);
        Arc_Gen_GroupRiskDetailTable_service.setupRiskTable(arce.Arc_Gen_GenericUtilities.getHighestTypLimits(acchasAn[0]), acchasAn[0]);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Fill limit exposure data with the retrieved from service
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 2020-11-27
    * @param   Map<String,Arc_Gen_Limits_Service.LimitsResponse> - limitRespMap
    * @param   String recordId
    * @return  List<arce__limits_exposures__c>
    * @example List<arce__limits_exposures__c> lst = getLimitsForPersistence(limitRespMap, recordId);
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__limits_exposures__c> getLimitsForPersistence(Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap, String recordId) {
        final List<arce__Account_has_Analysis__c> acchasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId});
        final List<arce__limits_exposures__c> limExpDataLts = arce.Arc_Gen_LimitsExposures_Data.getExposurDataMod(new List<Id>{recordId});
        for (arce__limits_exposures__c limitExpData: limExpDataLts) {
            System.debug('UnusedLocalVariable warning avoid debug: ' + limitExpData);
            limitExpData = fillLimitsWithResp(limitRespMap, limExpDataLts[0], acchasAn[0]);
        }
        return limExpDataLts;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 2021-08-06
    * @param   Map<String,Arc_Gen_Limits_Service.LimitsResponse> - limitRespMap
    * @param   arce__limits_exposures__c limitExpData
    * @param   arce__Account_has_Analysis__c accHasAn
    * @return  List<arce__limits_exposures__c>
    * @example List<arce__limits_exposures__c> lst = fillLimitsWithResponse(limitRespMap, limitExpData, accHasAn);
    * --------------------------------------------------------------------------------------
    **/
    public static arce__limits_exposures__c fillLimitsWithResp(Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap, arce__limits_exposures__c limitExpData, arce__Account_has_Analysis__c accHasAn) {
        if (limitRespMap.keySet().contains(limitExpData.arce__limits_typology_id__r.arce__risk_typo_ext_id__c)) {
            if ( acchasAn.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_NEW ) {
                limitExpData.arce__last_approved_amount__c = limitRespMap.get(limitExpData.arce__limits_typology_id__r.arce__risk_typo_ext_id__c).lastApproved;
            }
            limitExpData.arce__curr_approved_commited_amount__c = limitRespMap.get(limitExpData.arce__limits_typology_id__r.arce__risk_typo_ext_id__c).commited;
            limitExpData.arce__curr_apprv_uncommited_amount__c = limitRespMap.get(limitExpData.arce__limits_typology_id__r.arce__risk_typo_ext_id__c).uncommited;
            limitExpData.arce__current_formalized_amount__c = limitRespMap.get(limitExpData.arce__limits_typology_id__r.arce__risk_typo_ext_id__c).currentLimit;
            limitExpData.arce__outstanding_amount__c = limitRespMap.get(limitExpData.arce__limits_typology_id__r.arce__risk_typo_ext_id__c).outstanding;
        }
        return limitExpData;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Update limits exposures, aha fields related and group risk detail table fields
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 2020-11-27
    * @param   List<arce__limits_exposures__c> limExpDataLts
    * @param   String recordId
    * @return  List<arce__limits_exposures__c>
    * @example List<arce__limits_exposures__c> lst = updatePersLimits(limExpDataLts, recordId);
    * --------------------------------------------------------------------------------------
    **/
    public static void updatePersLimits(List<arce__limits_exposures__c> limExpDataLts, String recordId) {
        final List<arce__Account_has_Analysis__c> acchasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId});
        acchasAn[0].arce__call_limit_service__c = true;
        acchasAn[0].arce__magnitude_unit_type__c = '1';
        acchasAn[0].arce__prev_magnitude_unit_type__c = '1';
        acchasAn[0].arce__last_update_policie__c = System.now();
        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(acchasAn);
        arce.Arc_Gen_LimitsExposures_Data.updateExposureData(limExpDataLts);
        Arc_Gen_GroupRiskDetailTable_service.setupRiskTable(arce.Arc_Gen_GenericUtilities.getHighestTypLimits(acchasAn[0]), acchasAn[0]);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Gets the limit exposures from acc has analysis record id.
    *              Checks if there are records. If they don't exist the default typologies are created.
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-11-16
    * @param    recordId - id of the acc has analysis object
    * @return   List<arce__limits_exposures__c>
    * @example  generateLimExpo(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__limits_exposures__c> generateLimExpo(Id recordId) {
        List<arce__limits_exposures__c> limExpDataLts = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{recordId});
        if (limExpDataLts.isEmpty()) {
            Arc_Gen_ExpTable_Service_Helper.insertTypologies(recordId);
            limExpDataLts = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{recordId});
        }
        return limExpDataLts;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Check if the table is configured to work manually without the service and with assigned local custom permission.
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2021-05-21
    * @param    recordId - id of the acc has analysis object
    * @return   Boolean: return true if manually with custom permission assigned for current user
    * @example  Boolean hasManual = hasManualTablePerm(recordId);
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean hasManualTablePerm(String recordId) {
        Boolean retVal;
        try {
            final List<arce__Arce_Config__mdt> localConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(Arc_Gen_NewAnalysis_Service_Helper.LOCALUSER);
            final List<arce__Arce_Config__mdt> policiesPerm = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(POLICIES_PERM);
            final String fieldLocal = localConfig[0].arce__Value1__c;
            final String localCustomSelect = policiesPerm[0].arce__Custom_Permissions__c;
            if (Test.isRunningTest() || fieldLocal == null || localCustomSelect == '') {
                retVal = false;
            } else {
                final Map<String, Object> mapAnalysis = arce.Arc_Gen_ArceAnalysis_Data.getAnlysFldRelatedAha(recordId, new List<String>{fieldLocal});
                final String valLocalField = (String) mapAnalysis.get(fieldLocal);
                retVal = valLocalField == localCustomSelect ? true : false;
            }
        } catch(Exception ex) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(ex.getMessage());
        }
        return retVal;
    }

    /**
    * -------------------------------------------------------------------------------
    * @description: Method that check if the currency is null
    * -------------------------------------------------------------------------------
    * @date    12/04/2021
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   arce__Account_has_Analysis__c newAha
    * @return  void
    * @example currencyToCheck(newAha);
    */
    public static void currencyToCheck(arce__Account_has_Analysis__c newAha) {
        if (newAha.arce__currency_id__c == null) {
            throw new AuraHandledException(String.format(System.Label.Arc_Gen_PoliciesErrorNoCurrency, new List<String> { System.Label.Cls_arce_GRP_servError }));
        }
    }

}