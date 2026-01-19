/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveGroupFinancialRisk
* @Author   José Híjar <jose.hijar.contractor@bbva.com>
* @Date     Created: 5/08/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that contains some common methods to financial risk persitance
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2021-08-05 José Híjar <jose.hijar.contractor@bbva.com>
*             Class creation.
*             Moves financialInfoJSON method and its dependencies from Arc_Gen_FinRisk_Pers_service class to this
* -----------------------------------------------------------------------------------------------
*/

public with sharing class Arc_Gen_FinRisk_Pers_Helper {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author alberto.martinez.carrero.contractor@bbva.com
    *@Date   Created:2022-02-23
    */
    @TestVisible
    private Arc_Gen_FinRisk_Pers_Helper() { }
    /*
    * @Description 'comments' Literal
    */
    public final static String COMMENTS_LIT = 'comments';
    /*
    * @Description 'arce__cust_proj_2yr_3yr_desc__c' Literal
    */
    public final static String CUST_PROJ_LIT = 'arce__cust_proj_2yr_3yr_desc__c';

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON for financial risk WS
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 08/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param arce__Account_has_Analysis__c - prevaha Object
    * @return Map<String, Object> with WS structure for Financial Risk WS
    * @example financialInfoJSON(ahaData, prevAha)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> financialInfoJSON (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha) {
        final Map<String, arce__Service_persistence__mdt> configsMap = Arc_Gen_Persistence_Utils.getConfigurationInfo(new List<String>{'finRiskIndicatorsConfig', 'finRiskVariablesConfig', 'finRiskVariationsConfig'});
        Map<String, Object> finalWSMap = new Map<String, Object>();
        final List<Map<String, Object>> indicators = addIndicators(ahaData, prevAha, configsMap);
        final List<Map<String, Object>> variables = addVariables(ahaData, prevAha, configsMap);
        final List<Map<String, Object>> variations = addVariations(ahaData, prevAha, configsMap);
        final Map<String, Object> audit = addAudit(ahaData);
        final String consolidation = addConsolidation(ahaData);
        final Map<String, Object> maturityTable = addMaturity(ahaData, prevAha);
        final Map<String, Object> budget = generateBudget(ahaData, prevAha);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilledList(finalWsMap,'variables',variables);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilledList(finalWsMap,'variations',variations);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilledList(finalWsMap,'indicators',indicators);
        finalWsMap = Arc_Gen_Persistence_Utils.addifFilled(finalWsMap,'budget',budget);
        finalWsMap.put('maturityTable', maturityTable);
        finalWsMap.put('perimeter', (Object)consolidation);
        finalWsMap.put('audit', audit);
        return finalWSMap;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating audit Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for sector, subsector and activity
    * @example addSector(ahaData, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> addAudit (arce__Account_has_Analysis__c ahaData) {
        final Map<String, Object> audit =  new Map<String, Object>();
        final Map<String, Object> auditor =  new Map<String, Object>();
        final String opinion = Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get('arce__ffss_auditor_opinion_type__c'));
        final String auditorName = arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__ffss_auditor_fullname_name__c')) ? (String)ahaData.get('arce__ffss_auditor_fullname_name__c') : 'null';
        auditor.put('fullName', (Object)auditorName);
        auditor.put('opinion', (Object)opinion);
        audit.put('businessAgentComments', ahaData.get('arce__ffss_auditor_opinion_desc__c'));
        audit.put('auditor', auditor);
        return audit;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating audit Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for sector, subsector and activity
    * @example addSector(ahaData, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static String addConsolidation (arce__Account_has_Analysis__c ahaData) {
        return arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__ffss_cnsld_perimeter_desc__c')) ? (String)ahaData.get('arce__ffss_cnsld_perimeter_desc__c') : 'null';
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating audit Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param arce__Account_has_Analysis__c - prevAha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for sector, subsector and activity
    * @example addSector(ahaData, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> addMaturity (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha) {
        final Map<String, Object> maturityMap =  new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__debt_maturity_desc__c')) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get('arce__debt_maturity_desc__c'))) {
            maturityMap.put(COMMENTS_LIT, ahaData.get('arce__debt_maturity_desc__c'));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__number_entity_type__c')) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get('arce__number_entity_type__c'))) {
            maturityMap.put('banksNumberRange', Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get('arce__number_entity_type__c')));
        }
        maturityMap.put('hasMaturityTable', Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__debt_maturity_available_type__c')));
        return maturityMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating budget Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 9/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param arce__Account_has_Analysis__c - prevAha Object
    * @param string - key
    * @return Map<String, Object> with WS structure for budget
    * @example generateBudget(ahaData, prevAha)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> generateBudget (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha) {
        final Map<String, Object> budgetMap =  new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__cust_budget_cyr_ind_type__c')) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get('arce__cust_budget_cyr_ind_type__c'))) {
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__cust_budget_incl_ffss_ind_type__c'))) {
                budgetMap.put(COMMENTS_LIT,ahaData.get('arce__cust_budget_incl_ffss_desc__c'));
                budgetMap.put('isIncluded', Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__cust_budget_incl_ffss_ind_type__c')));
            }
            budgetMap.put('hasBudget', Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__cust_budget_cyr_ind_type__c')));

        }
        return budgetMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info indicators Object
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param arce__Account_has_Analysis__c - prevAha Object
    * @return List<Map<String, Object>> with WS structure
    * @example addIndicators(ahaData, prevAha)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String, Object>> addIndicators(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, Map<String, arce__Service_persistence__mdt> configsMap) {
        final List<Map<String, Object>> listMapIndicators = new List<Map<String, Object>>();
        final Map<String, String> mapIndicators = (Map<String, String>)JSON.deserialize(configsMap.get('finRiskIndicatorsConfig').arce__api_field_Name__c, Map<String, String>.class);
        final Map<String, String> indicatorsCom = (Map<String, String>)JSON.deserialize(configsMap.get('finRiskIndicatorsConfig').arce__iasoVariables__c, Map<String, String>.class);
        for (string element : mapIndicators.keyset()) {
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(element)) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get(element))) {
                final Map<String, Object> indicatorMap = new Map<String, Object>();
                if (arce.Arc_Gen_ValidateInfo_utils.isFilled(indicatorsCom.get(element))) {
                    //indicatorMap.put(COMMENTS_LIT,ahaData.get(indicatorsCom.get(element)));
                    insertIndicatorProvisional(ahaData, indicatorsCom, indicatorMap, element);
                }
                indicatorMap.put('isActive',Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get(element)));
                indicatorMap.put('id',mapIndicators.get(element));
                listMapIndicators.add(indicatorMap);
            }
        }
        return listMapIndicators;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Provisional method that trims "arce__cust_proj_2yr_3yr_desc__c" indicator comments
    * -----------------------------------------------------------------------------------------------
    * @Author  Juan Ignacio Hita Manso
    * @Date    26/01/2022
    * @param   arce__Account_has_Analysis__c - ahaData
    * @param   Map<String, String> indicatorsCom
    * @param   Map<String, Object> indicatorMap
    * @param   String element
    * @return  void
    * @example insertIndicatorProvisional(ahaData, indicatorComments, indicatorMap, element);
    * -----------------------------------------------------------------------------------------------
    **/
    private static void insertIndicatorProvisional(arce__Account_has_Analysis__c ahaData, Map<String, String> indicatorsCom, Map<String, Object> indicatorMap, String element) {
        String valueStr = (String) ahaData.get(indicatorsCom.get(element));
        if (indicatorsCom.get(element) == CUST_PROJ_LIT) {
            valueStr = valueStr.length() > 1000 ? valueStr.substring(0,999) : valueStr;
            indicatorMap.put(COMMENTS_LIT,valueStr);
        } else {
            indicatorMap.put(COMMENTS_LIT,valueStr);
        }
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info variables Object
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 09/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param arce__Account_has_Analysis__c - prevAha Object
    * @return List<Map<String, Object>> with WS structure
    * @example addIndicators(ahaData, prevAha)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String, Object>> addVariables (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, Map<String, arce__Service_persistence__mdt> configsMap) {
        final List<Map<String, Object>> listMapVariables = new List<Map<String, Object>>();
        final Map<String, String> mapVariables = (Map<String, String>)JSON.deserialize(configsMap.get('finRiskVariablesConfig').arce__api_field_Name__c, Map<String, String>.class);
        final Map<String, String> variablesComments = (Map<String, String>)JSON.deserialize(configsMap.get('finRiskVariablesConfig').arce__iasoVariables__c, Map<String, String>.class);
        for (string element : mapVariables.keyset()) {
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(element)) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get(element))) {
                final Map<String, Object> indicatorMap = new Map<String, Object>();
                if (arce.Arc_Gen_ValidateInfo_utils.isFilled(variablesComments.get(element))) {
                    indicatorMap.put(COMMENTS_LIT,ahaData.get(variablesComments.get(element)));
                }
                indicatorMap.put('variableType',Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get(element)));
                indicatorMap.put('id',mapVariables.get(element));
                listMapVariables.add(indicatorMap);
            }
        }
        return listMapVariables;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating the basic info variations Object
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 09/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param arce__Account_has_Analysis__c - prevAha Object
    * @return List<Map<String, Object>> with WS structure
    * @example addIndicators(ahaData, prevAha)
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String, Object>> addVariations (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, Map<String, arce__Service_persistence__mdt> configsMap) {
        final List<Map<String, Object>> listMapVariations = new List<Map<String, Object>>();
        final Map<String, String> mapVariations = (Map<String, String>)JSON.deserialize(configsMap.get('finRiskVariationsConfig').arce__iasoVariables__c, Map<String, String>.class);
        for (string element : mapVariations.keyset()) {
            if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(element)) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get(element))) {
                final Map<String, Object> indicatorMap = new Map<String, Object>();
                indicatorMap.put(COMMENTS_LIT, ahaData.get(element));
                indicatorMap.put('id',mapVariations.get(element));
                listMapVariations.add(indicatorMap);
            }
        }
        return listMapVariations;
    }
}