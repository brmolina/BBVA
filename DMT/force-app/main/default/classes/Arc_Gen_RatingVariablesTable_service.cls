/**
* @File Name          : Arc_Gen_RatingVariablesTable_service.cls
* @Description        : Contains the logic of the rating variables table json contruction
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Group
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 07-14-2025
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 17:54:42   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    24/7/2019 10:49:00   eduardoefrain.hernandez.contractor@bbva.com     Fix incidences
* 1.2    20/5/2020 17:29:51       joseluis.garcia4.contractor@bbva.com        Show qualitative variables in table.
* 1.2    30/4/2021 17:29:51   otiliramona.veres.contractor@bbva.com           Added an empty constructor method.
* 1.3    04/5/2021 13:12:00   otiliramona.veres.contractor@bbva.com           Added annotation '@testVisible' to the empty constructor method.
* 1.4    20/4/2022 12:30:00   francisco.munoz.torres.contractor@bbva.com      Empty level one quantitative block Value
* 1.5    07/6/2022 13:12:00   otiliaramona.veres.contractor@bbva.com          Added Empty level one quantitative block value Id 101.
*                                                                             Fixed sonar issues.
**/
public without sharing class Arc_Gen_RatingVariablesTable_service {

    /**
    * @Description: String with 1100 string
    */
    static final string QUANTIT_BLOCK_ID = '1100';

    /**
    * @Description: String of Quantitative Block with 1101 string
    */
    static final string QT_BLOCK_ID_101 = '1101';

    /**
    * @Description: Map with String and a list of arce__rating_variables_detail__c
    */
    static final Map<String,List<arce__rating_variables_detail__c>> VARS_MAP = new Map<String,List<arce__rating_variables_detail__c>>();

    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_RatingVariablesTable_service() { }
    /**
    * @Class: VariablesWrapper
    * @Description: Wrapper that contain all the level one variables of the rating
    * @author BBVA
    */
    public class VariablesWrapper {
        /**
        * @Description: Description name of the variable
        */
        @AuraEnabled public String description {get;set;}
        /**
        * @Description: Number of the variable score
        */
        @AuraEnabled public String score {get;set;}
        /**
        * @Description: Value of the variable
        */
        @AuraEnabled public String value {get;set;}
        /**
        * @Description: Maximum score number of the variable
        */
        @AuraEnabled public String maxScore {get;set;}
        /**
        * @Description: List of variables level two of this variable
        */
        @AuraEnabled public List<Items> items {get;set;}
    }

    /**
    * @Class: Items
    * @Description: Wrapper that contain all the level two variables of the rating
    * @author BBVA
    */
    public class Items {
        /**
        * @Description: Description name of the variable
        */
        @AuraEnabled public String description {get;set;}
        /**
        * @Description: Number of the variable score
        */
        @AuraEnabled public String score {get;set;}
        /**
        * @Description: Value of the variable
        */
        @AuraEnabled public String value {get;set;}
        /**
        * @Description: Maximum score number of the variable
        */
        @AuraEnabled public String maxScore {get;set;}
    }

    /**
    * @Class: Items
    * @Description: Wrapper that contain all the level two qualitative variables of the rating
    * @author BBVA
    */
    public class QualitativeItems {
        /**
        * @Description: Description name of the variable
        */
        @AuraEnabled public String description {get;set;}
        /**
        * @Description: Qualitative response of this variable
        */
        @AuraEnabled public String answer {get;set;}
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the Json to construct the table
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param List<arce__rating_variables_detail__c> variablesLevelOne
    * @param List<arce__rating_variables_detail__c> variablesLevelTwo
    * @return String - The json to construct the table
    * @example public static String setTableJson(List<arce__rating_variables_detail__c> variablesLevelOne,List<arce__rating_variables_detail__c> variablesLevelTwo)
    **/
    public static String setTableJson(List<arce__rating_variables_detail__c> variablesLevelOne,List<arce__rating_variables_detail__c> variablesLevelTwo) {

        Map<String,List<arce__rating_variables_detail__c>> variablesMap = new Map<String,List<arce__rating_variables_detail__c>>();
        for(arce__rating_variables_detail__c varOne : variablesLevelOne) {
            Boolean variableWithChilds = false;
            for(arce__rating_variables_detail__c varTwo : variablesLevelTwo) {
                if(varOne.arce__rating_variable_name__c == varTwo.arce__rating_variable_name__c) {
                    variableWithChilds = true;
                    setVarsMap(varTwo,varOne);
                }
            }
            if(!variableWithChilds) {
                variablesMap.put(varOne.arce__rating_variable_name__c, new List<arce__rating_variables_detail__c>{});
            }
        }
        List<VariablesWrapper> variablesList = new List<VariablesWrapper>();

        final Map<String, arce__rating_variables_detail__c> mapLevel1LargeId =
          new Map<String, arce__rating_variables_detail__c>([
            SELECT Id, arce__rating_variable_large_id__c
            FROM arce__rating_variables_detail__c
            WHERE id =: new Map<String, arce__rating_variables_detail__c>(variablesLevelOne).keySet()]);

        for(arce__rating_variables_detail__c var : variablesLevelOne) {
            final VariablesWrapper variableLevelOne = new VariablesWrapper();
            final String loValue = mapLevel1LargeId.get(var.Id).arce__rating_variable_large_id__c;
            variableLevelOne.description = (String)var.arce__rating_variable_large_id__c;
            variableLevelOne.score = String.valueOf(var.arce__rating_var_score_number__c);
            if(loValue == QUANTIT_BLOCK_ID || loValue == QT_BLOCK_ID_101) {
                variableLevelOne.value = '';
            } else {
                variableLevelOne.value = String.valueOf(var.arce__rating_var_value_amount__c);
            }
            variableLevelOne.maxScore = String.valueOf(var.arce__rating_var_max_score_number__c);
            List<Items> itemsList = new List<Items>();
            for(arce__rating_variables_detail__c item : variablesMap.get(var.arce__rating_variable_name__c)) {
                Items variableLevelTwo = new Items();
                variableLevelTwo.description = (String)item.arce__rating_variable_large_id__c;
                variableLevelTwo.score = String.valueOf(item.arce__rating_var_score_number__c);
                variableLevelTwo.value = String.valueOf(item.arce__rating_var_value_amount__c);
                variableLevelTwo.maxScore = String.valueOf(item.arce__rating_var_max_score_number__c);
                itemsList.add(variableLevelTwo);
            }
            variableLevelOne.items = itemsList;
            variablesList.add(variableLevelOne);
        }
        Return JSON.serializePretty(variablesList);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the value of the variable VARS_MAP
    --------------------------------------------------------------------------------
    * @author otiliaramona.veres.contractor@bbva.com
    * @date 02/06/2022
    * @param arce__rating_variables_detail__c varTwo
    * @param arce__rating_variables_detail__c varOne
    **/
    @TestVisible
    private static void setVarsMap(arce__rating_variables_detail__c varTwo,arce__rating_variables_detail__c varOne) {
        if(VARS_MAP.containsKey(varOne.arce__rating_variable_name__c)) {
            VARS_MAP.get(varOne.arce__rating_variable_name__c).add(varTwo);
        } else {
            VARS_MAP.put(varOne.arce__rating_variable_name__c, new List<arce__rating_variables_detail__c>{varTwo});
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the level one variables to be shown in the table
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String ratingId
    * @return List<arce__rating_variables_detail__c>
    * @example public static List<arce__rating_variables_detail__c> getVariablesLevelOne(String ratingId)
    **/
    public static List<arce__rating_variables_detail__c> getVariablesLevelOne(String ratingId) {
        final List<arce__rating_variables_detail__c> variables = arce.Arc_Gen_Rating_Var_detail_Data.getVariablesByLevel(ratingId,'1');
        Return variables;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the level two variables to be shown in the table
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String ratingId
    * @return List<arce__rating_variables_detail__c>
    * @example public static List<arce__rating_variables_detail__c> getVariablesLevelOne(String ratingId)
    **/
    public static List<arce__rating_variables_detail__c> getVariablesLevelTwo(String ratingId) {
        final List<arce__rating_variables_detail__c> variables = arce.Arc_Gen_Rating_Var_detail_Data.getVariablesByLevel(ratingId,'2');
        Return variables;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains qualitative variable to be shown in the table
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String ratingId
    * @return String
    **/
    public static String getQualitativeVariables(String ratingId) {
        final List<arce__rating_variables_detail__c> qualitativeVariables = arce.Arc_Gen_Rating_Var_detail_Data.getQualitativeVariables(ratingId);
        final Map<String, dyfr__Field_Config__c> codeToFieldConfigMap = getRelatedFieldConfigs(qualitativeVariables);

        // Build map of codes to values.
        final Map<String, String> codeToValueMap = getValuesByQualitativeVar(qualitativeVariables);

        // Get qualitative items
        final List<QualitativeItems> items = getQualitativeItems(codeToFieldConfigMap, codeToValueMap);

        return JSON.serialize(items);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Returns a map that matches qualitative variables to their related
    * field config.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 20/05/2019
    * @param List<arce__rating_variables_detail__c> qualitativeVars - List of qualitative variables
    * to obtain mappings for.
    * @return Map<String, dyfr__Field_Config__c> A map that relates qualitative variable codes to
    * field configs.
    **/
    private static Map<String, dyfr__Field_Config__c> getRelatedFieldConfigs(List<arce__rating_variables_detail__c> qualitativeVars) {
        // Get used qualitative variable codes.
        final Set<String> codeSet = new Set<String>();
        for (arce__rating_variables_detail__c qualitativeVar : qualitativeVars) {
            codeSet.add(qualitativeVar.arce__rating_variable_large_id__c);
        }

        return Arc_Gen_FieldConfig_Data.getFieldConfigsByQualitativeCode(codeSet);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Auxiliary method that gets a map of qualitative variable codes to
    * their corresponding value.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 20/05/2020
    * @param List<arce__rating_variables_detail__c> qualitativeVariables - List of qualitative variables.
    * @return Map<String, String> Map of variable codes to values.
    **/
    private static Map<String, String> getValuesByQualitativeVar(List<arce__rating_variables_detail__c> qualitativeVariables) {
        final Map<String, String> codeToValueMap = new Map<String, String>();

        for (arce__rating_variables_detail__c var : qualitativeVariables) {
            if (var.arce__rating_var_value_amount__c == null) {
                codeToValueMap.put(var.arce__rating_variable_large_id__c, '');
            } else {
                final String stringValue = String.valueOf(var.arce__rating_var_value_amount__c.round(System.RoundingMode.DOWN));
                codeToValueMap.put(var.arce__rating_variable_large_id__c, stringValue);
            }
        }

        return codeToValueMap;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Auxiliary method that returns a list of qualitative items (rows to
    * show in the table)
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 20/05/2020
    * @param Map<String, dyfr__Field_Config__c> codeToFieldConfigMap - Maps variable codes to associated field configs.
    * @param Map<String, String> codeToValueMap - Maps variable codes to their values (retrieved from the engine)
    * @return List<QualitativeItems> list of items to display in the table.
    **/
    private static List<QualitativeItems> getQualitativeItems(Map<String, dyfr__Field_Config__c> codeToFieldConfigMap, Map<String, String> codeToValueMap) {
        final List<QualitativeItems> qualitativeItems = new List<QualitativeItems>();

        for (String code : codeToFieldConfigMap.keySet()) {
            final dyfr__Field_Config__c fieldConfig = codeToFieldConfigMap.get(code);

            final String label = String.isEmpty(fieldConfig.dyfr__Label__c) ? code : fieldConfig.dyfr__Label__c;
            final String value = codeToValueMap.get(code);
            final String answer = String.valueOf(getFieldDisplayValue(fieldConfig, value));

            final QualitativeItems item = new QualitativeItems();
            item.description = label;
            item.answer = answer;
            qualitativeItems.add(item);
        }

        return qualitativeItems;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Auxiliary method that gets the answer to display for a question.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 20/05/2020
    * @param dyfr__Field_Config__c fieldConfig - Associated field config.
    * @param String value - Value as retrieved from the rating engine.
    * @return String the answer
    **/
    private static String getFieldDisplayValue(dyfr__Field_Config__c fieldConfig, String value) {
        String displayValue;
        Boolean valueFound = true;

        // Parse list of values and list of labels and get corresponding label.
        final List<dyfr__Dependent_value__c> listsOfValues = fieldConfig.dyfr__Dependent_values__r;
        if (String.isEmpty(value)) {
            displayValue = '';
        } else if (listsOfValues.isEmpty()) {
            valueFound = false;
        } else {
            final dyfr__Dependent_value__c listOfValues = listsOfValues[0];

            // Get values.
            final String valueSeparator = listOfValues.dyfr__LoV_values__c.contains('#') ? '#' : ',';
            final List<String> values = listOfValues.dyfr__LoV_values__c.split(valueSeparator);

            // Get requested label index.
            final Integer valueIndex = values.indexOf(value);

            if (valueIndex == -1) {
                valueFound = false;
            } else {
                // Get labels.
                final String labelSeparator = listOfValues.dyfr__LoV_labels__c.contains('#') ? '#' : ',';
                final List<String> labels = listOfValues.dyfr__LoV_labels__c.split(labelSeparator);

                displayValue = labels[valueIndex];
            }
        }

        // If no label is found, show a determined label.
        if (!valueFound) {
            displayValue = String.format(System.Label.Arc_Gen_QualitativeAnswerNotFound, new List<String> { value });
        }

        return displayValue;
    }
}