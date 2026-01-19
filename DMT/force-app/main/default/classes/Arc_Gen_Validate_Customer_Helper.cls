/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Customer_Helper
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 2019-05-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper service class for Arc_Gen_Validate_Customer_Controller.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 juanignacio.hita.contractor@bbva.com
*             Class creation. Reduce number of methods in Validate_Customer_Service class
* |2021-06-07 mariohumberto.ramirez.contractor@@bbva.com
*             fix validateField logic
* |2022-02-22 juanignacio.hita.contractor@bbva.com
*             Refactoring validateTypoSum method and created validateTypoChild
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Arc_Gen_Validate_Customer_Helper {
    /**
        * @Description: List of string with the name of some fields in arce__limits_exposure__c object
    */
    public static final List<string> FIELD_LIST = new List<string>{'arce__current_proposed_amount__c'};
    /**
        * @Description: List of string with the label of some fields in arce__limits_exposure__c object
    */
    public static final List<string> FIELD_LABEL = new List<string>{System.Label.Arc_Gen_Proposed};
    /**
        * @Description: string with the name of a key of the map that return the method validateTable
    */
    public static final string FIELD_NAME = 'FieldName';
    /**
        * @Description: string with the name of a key of the map that return the method validateTable
    */
    public static final string FIELD_MISSING = 'FieldsMissing';
    /**
        * @Description: string with the name of a key of the map that return the method validateTable
    */
    public static final string TYPOLOGY = 'Typology';
    /**
        * @Description: String with value "TP_0005"
    */
    static final string TOTAL_FIN_RISK_ST = 'TP_0005';
    /**
        * @Description: List String with value 'TP_0010','TP_0012'
    */
    static final List<string> TOTAL_FIN_ST_CHILD = new List<string>{'TP_0010','TP_0012'};
    /**
        * @Description: String with value "TP_0007"
    */
    static final string TOTAL_FIN_RISK_LT = 'TP_0007';
    /**
        * @Description: String with value 'TP_0011','TP_0014'
    */
    static final List<string> TOTAL_FIN_LT_CHILD = new List<string>{'TP_0011','TP_0014'};
    /**
        * @Description: String with the dev name of Total Corporate Risk tipology
    */
    static final string TOTAL_CORP_RISK = 'TP_0003';
    /**
        * @Description: List of string with the childs dev name of Total Corporate Risk tipology
    */
    static final List<string> TOTAL_CORPR_CHILD = new List<string>{'TP_0002', 'TP_0005', 'TP_0007', 'TP_0008'};

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Helper service = new Arc_Gen_Validate_Customer_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Validate_Customer_Helper() {
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Gets value to use for TDBU indicator.
    * --------------------------------------------------------------------------------------
    * @param accHas arce__Account_has_Analysis__c record
    * --------------------------------------------------------------------------------------
    **/
    public static String getConsolidatedType(arce__Account_has_Analysis__c accHas) {
        return String.isEmpty(accHas.arce__anlys_wkfl_cnsld_ffss_type__c) ? '1' : accHas.arce__anlys_wkfl_cnsld_ffss_type__c;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns a string with the name of the client no validated or a validation
    * flag
    * --------------------------------------------------------------------------------------
    * @param List<arce__Account_has_Analysis__c> childsId
    * @return a string with the name of the client no validated or a validation flag
    * @example checkValidateCustomer(childsId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<String> checkValidateCustomer(List<String> ids, String typeCustomer) {
        final List<String> resultFalse = new List<String>();
        List<String> result = new List<String>();
        final List<arce__Account_has_Analysis__c> accHasObjLts = Arc_Gen_Validate_Customer_Data.checkCustomerFlag(ids);
        for (arce__Account_has_Analysis__c acchas: accHasObjLts) {
            if (typeCustomer == Arc_Gen_Validate_Customer_Service.S_GROUP && accHas.arce__status_limit_pers_service__c == false) {
                resultFalse.add((String)acchas.arce__Customer__r.Name);
            } else if (typeCustomer == Arc_Gen_Validate_Customer_Service.CLIENT && (acchas.arce__arce_ctmr_flag__c == false || acchas.arce__status_limit_pers_service__c == false)) {
                resultFalse.add((String)acchas.arce__Customer__r.Name);
            }
        }
        if (resultFalse.isEmpty()) {
            result.add(Arc_Gen_Validate_Customer_Service.ACTIVE);
        } else {
            result = resultFalse;
        }
        return result;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns the ids of account has analysis related to group
    * --------------------------------------------------------------------------------------
    * @param List<arce__Analysis__c> childsId
    * @return a string with the name of the client no validated or a validation flag
    * @example getIdsOfFilials(childsId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<String> getIdsOfFilials(List<arce__Analysis__c> childsId) {
        final List<String> idOfChilds = new List<String>();
        for (arce__Analysis__c childId: childsId) {
            for (arce__Account_has_Analysis__c accId: childId.arce__Account_has_Analysis__r) {
                idOfChilds.add(accId.Id);
            }
        }
        return idOfChilds;
    }

    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description Returns a List<Map<string,string>> that contain the final error message of the
    * Policies table validations
    * ---------------------------------------------------------------------------------------------------
    * @param validateTypo List<Map<string,string>> with the fields missing in typologies
    * @param fields List<Map<string,string>> with the fields missing in proposal and risk request section
    * @param groupResults List<Map<string,string>> with the fields missing if the client is a group
    * @return a List<Map<string,string>> with all the fields missing in policies table
    * @example createFinalMap(validateTypo, fields, groupResults)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> createFinalMap(List<Map<string,string>> validateTypo, List<Map<string,string>> fields, List<Map<string,string>> groupResults) {
        final List<Map<string,string>> finalMapResult = new List<Map<string,string>>();
        finalMapResult.addAll(validateTypo);
        finalMapResult.addAll(fields);
        if (!groupResults.isEmpty()) {
            finalMapResult.addAll(groupResults);
        }
        return finalMapResult;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Returns a List<Map<string,string>> with the fields missing in typologies
    * validations
    * --------------------------------------------------------------------------------------
    * @param accHasAId Id of the arce__Account_has_Analysis__c
    * @return a List<Map<string,string>> with the fields missing in typologies
    * validations
    * @example validateTypology(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> validateTypology(string accHasAId, List<arce__limits_exposures__c> exposureData) {
        final List<Map<string,string>> mapResult = new List<Map<string,string>>();
        for (arce__limits_exposures__c expData: exposureData) {
            if (expData.arce__limits_typology_id__c != null && expData.arce__limits_typology_id__r.arce__risk_typology_parent_id__c != null) {
                final List<Map<string,string>> auxTypo = compareTypology(expData, expData.arce__limits_exposures_parent_id__c, exposureData);
                mapResult.addAll(auxTypo);
            }
            if (expData.arce__limits_typology_id__r.arce__risk_typology_level_id__c == TOTAL_FIN_RISK_ST) {
                final List<Map<string,string>> auxTypo3 = validateTypoSum(expData, exposureData, TOTAL_FIN_ST_CHILD);
                mapResult.addAll(auxTypo3);
            }
            if (expData.arce__limits_typology_id__r.arce__risk_typology_level_id__c == TOTAL_FIN_RISK_LT) {
                final List<Map<string,string>> auxTypo4 = validateTypoSum(expData, exposureData, TOTAL_FIN_LT_CHILD);
                mapResult.addAll(auxTypo4);
            }
            if (expData.arce__limits_typology_id__r.arce__risk_typology_level_id__c == TOTAL_CORP_RISK) {
                final List<Map<string,string>> auxTypo2 = validateTotals(expData, exposureData, TOTAL_CORPR_CHILD);
                mapResult.addAll(auxTypo2);
            }
        }
        return mapResult;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that compare the amount of the parent typologies and the child
    * typologies
    * --------------------------------------------------------------------------------------
    * @param expData - Data of the child typology
    * @param typoParentId - Id of the parent typology
    * @param exposureData - Data of the arce__limits_exposures__c object
    * @return a List<Map<string,string>> with the information of the typologies that exeed
    * in amount to its parents
    * @example compareTypology(expData, typoParentId, exposureData)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> compareTypology(arce__limits_exposures__c expData, Id typoParentId, List<arce__limits_exposures__c> exposureData) {
        final List<Map<string,string>> mapRes = new List<Map<string,string>>();
        for (arce__limits_exposures__c exposureParent: exposureData) {
            if (exposureParent.Id == typoParentId) {
                for (integer i = 0; i < FIELD_LIST.size(); i++) {
                    if (Double.valueOf((Double)exposureParent.get(FIELD_LIST.get(i))) < Double.valueOf((Double)expData.get(FIELD_LIST.get(i)))) {
                        mapRes.add(new Map<String,String>{Arc_Gen_Validate_Customer_Service.CLIENT => String.valueOf((String)expData.arce__account_has_analysis_id__r.arce__Customer__r.Name), TYPOLOGY => (String)expData.arce__limits_typology_id__r.Name, FIELD_NAME => FIELD_LABEL.get(i)});
                    }
                }
            }
        }
        return mapRes;
    }
    /*
    * --------------------------------------------------------------------------------------
    * @Description - Method that compare the amount of some Totals typologies and its childs
    * typologies
    * --------------------------------------------------------------------------------------
    * @param expData - Data of the Parent typology
    * @param exposureData - Data of the arce__limits_exposures__c object
    * @param iteraChilds - List string with the dev name of the childs
    * @return a List<Map<string,string>> with an error message
    * @example validateTypoSum(expData, exposureData, iteraChilds)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> validateTypoSum(arce__limits_exposures__c expData, List<arce__limits_exposures__c> exposureData, List<string> iteraChilds) {
        final List<Map<string,string>> mapRes = new List<Map<string,string>>();
        final Map<string,double> fieldsValuesMap = new Map<string,double>();
        double flag = 0;
        for (integer i = 0; i < FIELD_LIST.size(); i++) {
            fieldsValuesMap.put(FIELD_LIST[i], 0);
        }
        for (arce__limits_exposures__c exposure: exposureData) {
            for (String child: iteraChilds) {
                if (exposure.arce__limits_typology_id__r.arce__risk_typology_level_id__c == child && exposure.arce__Product_id__c == null) {
                    flag++;
                    final Map<String, arce__limits_exposures__c> mapLimits = new Map<String, arce__limits_exposures__c> {
                        'exposure' => exposure,
                        'expData' => expData
                    };
                    mapRes.addAll(validateTypoChild(flag, fieldsValuesMap, mapLimits));
                }
            }
        }
        return mapRes;
    }
    /*
    * --------------------------------------------------------------------------------------
    * @Description - Method that validate amount and typologies of limits childs
    * --------------------------------------------------------------------------------------
    * @param double flag
    * @param Map<string,double> fieldsValuesMap
    * @param Map<String, arce__limits_exposures__c> mapLimits
    * @return a List<Map<string,string>> with the validation messages
    * @example List<Map<string,string>> lst = validateTypoChild(flag, fieldsValuesMap, mapLimits);
    * --------------------------------------------------------------------------------------
    **/
    private static List<Map<string,string>> validateTypoChild(double flag, Map<string,double> fieldsValuesMap, Map<String, arce__limits_exposures__c> mapLimits) {
        final List<Map<string,string>> mapRes = new List<Map<string,string>>();
        final arce__limits_exposures__c exposure = mapLimits.get('exposure');
        final arce__limits_exposures__c expData = mapLimits.get('expData');
        double aux;
        for (integer i = 0; i < FIELD_LIST.size(); i++) {
            if (flag == 1) {
                fieldsValuesMap.put(FIELD_LIST[i], (Double)exposure.get(FIELD_LIST.get(i)));
            } else if (flag == 2) {
                aux = fieldsValuesMap.get(FIELD_LIST[i]) + (Double)exposure.get(FIELD_LIST.get(i));
                fieldsValuesMap.put(FIELD_LIST[i], aux);
                aux = 0;
                if (Double.valueOf((Double)expData.get(FIELD_LIST.get(i))) > fieldsValuesMap.get(FIELD_LIST[i])) {
                    mapRes.add(new Map<String,String>{Arc_Gen_Validate_Customer_Service.CLIENT => String.valueOf((String)expData.arce__account_has_analysis_id__r.arce__Customer__r.Name),
                                                    FIELD_MISSING => System.Label.Arc_Gen_SumOfChilds,
                                                    TYPOLOGY => (String)expData.arce__limits_typology_id__r.Name,
                                                    FIELD_NAME => FIELD_LABEL.get(i)});
                }
            }
        }
        return mapRes;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that compare the amount of some Totals typologies and its childs
    * typologies
    * --------------------------------------------------------------------------------------
    * @param expData - Data of the child typology
    * @param exposureData - Data of the arce__limits_exposures__c object
    * @param iteraChilds - List string with the dev name of the childs
    * @return a List<Map<string,string>> with the information of the typologies that exeed
    * in amount to its parents
    * @example validateTotals(expData, exposureData, iteraChilds)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> validateTotals(arce__limits_exposures__c expData, List<arce__limits_exposures__c> exposureData, List<string> iteraChilds) {
        final List<Map<string,string>> mapRes = new List<Map<string,string>>();
        for (arce__limits_exposures__c exposure: exposureData) {
            for (String child: iteraChilds) {
                if (exposure.arce__limits_typology_id__r.arce__risk_typology_level_id__c == child) {
                    for (integer i = 0; i < FIELD_LIST.size(); i++) {
                        if (Double.valueOf((Double)exposure.get(FIELD_LIST.get(i))) > Double.valueOf((Double)expData.get(FIELD_LIST.get(i)))) {
                            mapRes.add(new Map<String,String>{Arc_Gen_Validate_Customer_Service.CLIENT => String.valueOf((String)expData.arce__account_has_analysis_id__r.arce__Customer__r.Name), FIELD_MISSING => 'Parent: ' + (String)expData.arce__limits_typology_id__r.Name, TYPOLOGY => (String)exposure.arce__limits_typology_id__r.Name, FIELD_NAME => FIELD_LABEL.get(i)});
                        }
                    }
                }
            }
        }
        return mapRes;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return true/false
    * --------------------------------------------------------------------------------------
    * @param field - dyfr__Field_Config__c object
    * @param devFieldsConfMap - Map<String,SObject>
    * @param fieldValues - arce__Account_has_Analysis__c object list
    * @return boolean - true/false
    * @example validateField(field,devFieldsConfMap,devFieldsValueMap)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean validateField(dyfr__Field_Config__c field, Map<String,SObject> devFieldsConfMap, Map<String,String> devFieldsValueMap) {
        Boolean filledField;
        if (String.isEmpty(field.dyfr__Visibility_control_field__c)) {
            filledField = devFieldsValueMap.get(field.dyfr__DeveloperName__c) == null || devFieldsValueMap.get(field.dyfr__DeveloperName__c) == 'false' ? false : true;
        } else {
            filledField = field.dyfr__Visibility_control_field__c.contains(';') ? validateMultiDepField(field, devFieldsConfMap, devFieldsValueMap) : validateDepField(field, devFieldsConfMap, devFieldsValueMap);
        }
        return filledField;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description return true/false
    * --------------------------------------------------------------------------------------
    * @param field - dyfr__Field_Config__c object
    * @param devFieldsConfMap - Map<String,SObject>
    * @param fieldValues - arce__Account_has_Analysis__c object list
    * @return boolean - true/false
    * @example validateDepField(field,devFieldsConfMap,devFieldsValueMap)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean validateDepField(dyfr__Field_Config__c field, Map<String,SObject> devFieldsConfMap, Map<String,String> devFieldsValueMap) {
        Boolean fieldFilled;
        List<String> contValueLts = new List<String>();
        contValueLts = field.dyfr__Visibility_control_value__c.contains(',') ? field.dyfr__Visibility_control_value__c.split(',') : new List<String>{field.dyfr__Visibility_control_value__c == null ? '' : field.dyfr__Visibility_control_value__c};
        final String valueControlField = devFieldsValueMap.get(field.dyfr__Visibility_control_field__c);
        for (String valLts : contValueLts) {
            if (valLts == valueControlField) {
                fieldFilled = devFieldsValueMap.get(field.dyfr__DeveloperName__c) == null || devFieldsValueMap.get(field.dyfr__DeveloperName__c) == 'false' ? false : true;
                break;
            }
        }
        return fieldFilled;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description return true/false
    * --------------------------------------------------------------------------------------
    * @param field - dyfr__Field_Config__c object
    * @param devFieldsConfMap - Map<String,SObject>
    * @param fieldValues - arce__Account_has_Analysis__c object list
    * @return boolean - true/false
    * @example validateMultiDepField(field,devFieldsConfMap,devFieldsValueMap)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean validateMultiDepField(dyfr__Field_Config__c field, Map<String,SObject> devFieldsConfMap, Map<String,String> devFieldsValueMap) {
        final List<Boolean> filledLts =  new List<Boolean>();
        Boolean isActive = false;
        Boolean filledField;
        integer k = 0;
        final List<String> fieldControlLts = String.valueOf(field.dyfr__Visibility_control_field__c).split(';');
        final List<String> fieldValuesLts = String.valueOf(field.dyfr__Visibility_control_value__c).split(';');
        for (integer i = 0; i < fieldControlLts.size(); i++) {
            if (devFieldsValueMap.get(fieldControlLts[i]) == null) {
                filledLts.add(false);
            } else {
                filledLts.add(fieldValuesLts[i].contains(devFieldsValueMap.get(fieldControlLts[i])));
            }
        }
        for (integer i = 0; i < filledLts.size(); i++) {
            if (filledLts[i] == true) {
                k++;
            }
        }
        if (k == filledLts.size()) {
            isActive = true;
        }
        filledField = devFieldsValueMap.get(field.dyfr__DeveloperName__c) == null && isActive == true ? false : true;
        return filledField;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description manage the validation when there are some products in the policies table
    * --------------------------------------------------------------------------------------
    * @param accHasAId Id of the arce__Account_has_Analysis__c
    * @return List<Map<string,string>> with the name and the amount higher than the parent
    * typology
    * @example validateProduct(accHasAId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<String,String>> validateProduct(List<arce__limits_exposures__c> dataProducts) {
        final List<Map<string,string>> mapProduct = new List<Map<string,string>>();
        for (arce__limits_exposures__c dataProduct: dataProducts) {
            if (dataProduct.arce__Product_id__c != null) {
                final List<Map<string,string>> auxProduct = compareProduct(dataProduct, dataProduct.arce__limits_exposures_parent_id__c, dataProducts);
                if (!auxProduct.isEmpty()) {
                    for (Map<string,string> auxMap: auxProduct) {
                        mapProduct.add(auxMap);
                    }
                }
            }
        }
        return mapProduct;
    }

        /**
    * --------------------------------------------------------------------------------------
    * @Description manage the validation when there are some products in the policies table
    * --------------------------------------------------------------------------------------
    * @param dataProducts arce__limits_exposures__c data of the product to validate
    * @param groupProducts arce__limits_exposures__c data of the product to compare
    * @return List<Map<string,string>> with the name and the amount higher than the group
    * typology
    * @example validateGroupProduct(dataProducts, groupProducts)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<String,String>> validateGroupProduct(List<arce__limits_exposures__c> dataProducts, List<arce__limits_exposures__c> groupProducts) {
        final List<Map<string,string>> mapProduct = new List<Map<string,string>>();
        for (arce__limits_exposures__c dataProduct: dataProducts) {
            if (dataProduct.arce__Product_id__c != null) {
                final List<Map<string,string>> auxProduct = compareProduct(dataProduct, dataProduct.Id, groupProducts);
                if (!auxProduct.isEmpty()) {
                    for (Map<string,string> auxMap: auxProduct) {
                        mapProduct.add(auxMap);
                    }
                }
            }
        }
        return mapProduct;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description method that compare a product with its typology parent
    * --------------------------------------------------------------------------------------
    * @param product - arce__limits_exposures__c data of the product to compare
    * @param typoParentId - Id of the typology parent
    * @param dataProducts - all the data of the object arce__limits_exposures__c
    * @return List<Map<string,string>> with the name and the amount higher than the parent
    * typology
    * @example validateProduct(product, typoParentId, dataProducts)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> compareProduct(arce__limits_exposures__c product, Id typoParentId, List<arce__limits_exposures__c> dataProducts) {
        final List<Map<string,string>> mapRes = new List<Map<string,string>>();
        for (arce__limits_exposures__c dataP: dataProducts) {
            if (dataP.Id == typoParentId) {
                for (integer i = 0; i < FIELD_LIST.size(); i++) {
                    if (Double.valueOf((Double)dataP.get(FIELD_LIST.get(i))) < Double.valueOf((Double)product.get(FIELD_LIST.get(i)))) {
                        mapRes.add(new Map<String,String>{Arc_Gen_Validate_Customer_Service.CLIENT => String.valueOf((String)product.arce__account_has_analysis_id__r.arce__Customer__r.Name), TYPOLOGY => (String)product.arce__Product_id__r.Name, FIELD_NAME => FIELD_LABEL.get(i)});
                    }
                }
            }
        }
        return mapRes;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return the multiplication factor to convert the unit selected in units
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 29/10/2019
    * @param unitSelected - unit selected in combo box
    * @return multiFactor - factor of multiplication to convert the unit selected in units
    * @example getMultiplicationFactor(unitSelected)
    * --------------------------------------------------------------------------------------
    **/
    public static Double getMultiplicationFactor(String unitSelected) {
        Double multiFactor = 1;
        switch on unitSelected {
            when '1' {
                multiFactor = 1;
            }
            when '2' {
                multiFactor = 1000;
            }
            when '3' {
                multiFactor = 1000000;
            }
            when '4' {
                multiFactor = 1000000000000L;
            }
        }
        return multiFactor;
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
        for (String flag : flagType) {
            if (flagType[0] != Arc_Gen_Validate_Customer_Service.ACTIVE) {
                mapResult = new Map<String, String>{Arc_Gen_Validate_Customer_Service.ID_CLIENTE => flag,
                                                    FIELD_MISSING => lblError};
            }
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
    public static Map<String, String> checkCustomersAndServices(List<String> idAhaGroup, List<String> idOfClients) {
        final Map<String, String> mapAhaGroup = utilErrorCheckVal(checkValidateCustomer(idAhaGroup, Arc_Gen_Validate_Customer_Service.S_GROUP), System.Label.Arc_Gen_StatusPersServiceCheckCustomer);
        final Map<String, String> mapAhaSubsi = utilErrorCheckVal(checkValidateCustomer(idAhaGroup, Arc_Gen_Validate_Customer_Service.S_GROUP), System.Label.Arc_Gen_ClientNoValidated);
        Map<String, String> mapReturn = new Map<String, String>();
        if (mapAhaGroup.isEmpty()) {
            mapReturn = mapAhaSubsi.isEmpty() ? mapAhaSubsi : new Map<String, String>();
        } else {
            mapReturn = mapAhaGroup;
        }
        return mapReturn;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Check that all the customers have the same currency
    * --------------------------------------------------------------------------------------
    * @param List<String> ids : list of ids of the subsidiaries added to the analysis.
    * @return Returns a true value if all the customers have the same currency
    * @example Bollean valCheck = checkValidateCurrency(ids)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean checkValidateCurrency(List<String> ids) {
        final List<arce__Account_has_Analysis__c> accHasObjLts = Arc_Gen_Validate_Customer_Data.checkCurrencyAHA(ids);
        Boolean valCurrency = true;
        String currencyStr = '';

        if (!accHasObjLts.isEmpty()) {
            currencyStr = accHasObjLts[0].arce__currency_id__c;
            for (arce__Account_has_Analysis__c acchas: accHasObjLts) {
                if (currencyStr != acchas.arce__currency_id__c) {
                    valCurrency = false;
                }
            }
        }
        return valCurrency;
    }
}