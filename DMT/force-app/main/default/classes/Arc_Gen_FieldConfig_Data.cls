/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FieldConfig_Data
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 28/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Data class for dyfr__field_confic__c object
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-04-27 juanignacio.hita.contractor@bbva.com
*             Added getDevFieldsInfo and fillMapTabset methods
* |2020-05-22 joseluis.garcia4.contractor@bbva.com
*             Add getFieldConfigsByQualitativeCode() method.
* |2020-07-27 juanignacio.hita.contractor@bbva.com
*             Add getDependValByQualitativeCode() method.
* |2020-11-17 juanignacio.hita.contractor@bbva.com
*             Add hasFieldSections method
* |2022-06-06 juanignacio.hita.contractor@bbva.com
*             Create getQualQuestionByTabs and checkChangesQualQuestion methods.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_FieldConfig_Data {

    /** @Description: rating value for recalculate_rating field */
    private static final String RATING = '2';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-28
    * @param void
    * @return void
    * @example Arc_Gen_FieldConfig_Data data = new Arc_Gen_FieldConfig_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_FieldConfig_Data() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Return a Map<String,dyfr__Field_Config__c>
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-28
    * @param mapFields -  List with the api name of the field to query
    * @return Map<String,dyfr__Field_Config__c>
    * @example getMapFieldsInfo(mapFields)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Map<String,dyfr__Field_Config__c> getMapFieldsInfo(List<String> mapFields) {
        Map<String,dyfr__Field_Config__c> mapReturn = new Map<String,dyfr__Field_Config__c>();
        List<dyfr__Field_Config__c> fieldConfigData = [SELECT Id, dyfr__Map_field__c, dyfr__Type__c, dyfr__Read_only__c FROM dyfr__Field_Config__c WHERE dyfr__Map_field__c = :mapFields];
        for (dyfr__Field_Config__c fieldConfig: fieldConfigData) {
            mapReturn.put((String)fieldConfig.dyfr__Map_field__c, fieldConfig);
        }
        return mapReturn;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Return a Map<String,dyfr__Field_Config__c> from a list of developer names
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-04-27
    * @param mapFields -  List with the dev name of the field to query
    * @return Map<String,dyfr__Field_Config__c>
    * @example getDevFieldsInfo(devFields)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Map<String,dyfr__Field_Config__c> getDevFieldsInfo(List<String> devFields) {
        Map<String,dyfr__Field_Config__c> mapReturn = new Map<String,dyfr__Field_Config__c>();
        List<dyfr__Field_Config__c> fieldConfigData = [SELECT Id, Name, dyfr__Tab__r.Name, dyfr__DeveloperName__c, dyfr__Section_name__c,
                                                        dyfr__Section_order__c, dyfr__Subsection_name__c, dyfr__Subsection_order__c, dyfr__Label__c FROM dyfr__Field_Config__c
                                                        WHERE dyfr__DeveloperName__c = :devFields];

        for (dyfr__Field_Config__c fieldConfig: fieldConfigData) {
            mapReturn.put((String)fieldConfig.dyfr__DeveloperName__c, fieldConfig);
        }
        return mapReturn;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fill map with tabset completitud data
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 05/05/2020
    * @param Map<String, dyfr__Field_Config__c> mapSearchFc : Map with the developer name as key and the field config object
    * @param Map<String, List<String>> mapTemplateFc : Map with name of the section and the empty field list
    * @return Map<String, List<dyfr__Field_Config__c>> : return a map with name of the section and a list of field config object
    * @example Map<String, List<dyfr__Field_Config__c>> map = fillMapTabset(mapSearchFc, mapTemplateFc);
    **/
    public static Map<String, List<dyfr__Field_Config__c>> fillMapTabset(Map<String, dyfr__Field_Config__c> mapSearchFc, Map<String, List<String>> mapTemplateFc) {
        Map<String, List<dyfr__Field_Config__c>> mapRet = new Map<String, List<dyfr__Field_Config__c>>();
        for(String nTemplate : mapTemplateFc.keySet()) {
            List<dyfr__Field_Config__c> lstTemp = new List<dyfr__Field_Config__c>();
            for (String fc : mapTemplateFc.get(nTemplate)) {
                lstTemp.add(mapSearchFc.get(fc));
            }
            mapRet.put(nTemplate, lstTemp);
        }
        return mapRet;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Returns a map that matches qualitative variable codes to their related
    * field config.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 20/05/2019
    * @param Set<String> codes - List of codes to obtain field configs for.
    * @return Map<String, dyfr__Field_Config__c> A map that relates qualitative variable codes to
    * field configs.
    **/
    public static Map<String,dyfr__Field_Config__c> getFieldConfigsByQualitativeCode(Set<String> codes) {
        // Fetch field config mapped by the qualitative variables.
        final List<dyfr__Field_Config__c> fieldConfigs =
            [SELECT dyfr__Label__c, dyfr__Map_field__c, qualitative_question_code__c, (SELECT dyfr__LoV_labels__c, dyfr__LoV_values__c FROM dyfr__Dependent_values__r)
            FROM dyfr__Field_Config__c
            WHERE qualitative_question_code__c IN :codes];

        // Build map that relates each variable to its field config.
        final Map<String, dyfr__Field_Config__c> fieldConfigToVarMap = new Map<String, dyfr__Field_Config__c>();
        for (dyfr__Field_Config__c fieldConfig : fieldConfigs) {
            final String code = fieldConfig.qualitative_question_code__c;
            if (!fieldConfigToVarMap.containsKey(code)) {
                fieldConfigToVarMap.put(code, fieldConfig);
            }
        }

        return fieldConfigToVarMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that receives qualitative code field config object and
    * return a map with the dependent values and labels of the field finded in the template
    * associated to AHA
    *-------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 27/07/2020
    * @param String qualitativeCode : qualitative code field on field config object
    * @return Map<String, String> returns a map with the dependent values and labels of the field finded.
    * @example Map<String, String> map = getDependValByQualitativeCode(qualitativeCode);
    **/
    public static Map<String, String> getDependValByQualitativeCode(String qualitativeCode) {
        final Map<String, dyfr__Field_Config__c> fcData = Arc_Gen_FieldConfig_Data.getFieldConfigsByQualitativeCode(new Set<String>{qualitativeCode});
        Map<String, String> mapDependentVal = new Map<String, String>();
        if (!fcData.isEmpty()) {
            final dyfr__Field_Config__c fieldConfig = fcData.get(qualitativeCode);
            final List<dyfr__Dependent_value__c> dependtValues = fieldConfig.dyfr__Dependent_values__r;
            List<String> lstLabel = new List<String>();
            List<String> lstVal = new List<String>();

            if (!dependtValues.isEmpty()) {
                lstLabel = dependtValues[0].dyfr__LoV_labels__c.split(',');
                lstVal = dependtValues[0].dyfr__LoV_values__c.split(',');
            }

            for (Integer i = 0; i < lstVal.size(); i++) {
                mapDependentVal.put(lstVal[i], lstLabel[i]);
            }
        }
        return mapDependentVal;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Check if the field configuration list has fields with some name from the list of section names.
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 16/11/2020
    * @param    List<dyfr__Field_Config__c> lstFc
    * @param    List<String> lstSections
    * @return   Boolean
    * @example  Boolean retStatus = hasFieldSections(lstFc, lstSections);
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean hasFieldSections(List<dyfr__Field_Config__c> lstFc, List<String> lstSections) {
        Boolean retStatus = true;
        final List<String> nameSect = new List<String>();
        for (dyfr__Field_Config__c fc : lstFc) {
            if (!nameSect.contains(fc.dyfr__Section_name__c)) {
                nameSect.add(fc.dyfr__Section_name__c);
            }
        }
        for(String key: lstSections) {
            if(!nameSect.contains(key)) {
                retStatus = false;
            }
        }
        return retStatus;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that returns configured qualitative question of some specific tabs.
    *-------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @date     03/06/2022
    * @param    Set<String> tabCodes
    * @return   Map<String, dyfr__Field_Config__c> : map with mapfield as key and fieldconfig object
    * @example  Map<String, dyfr__Field_Config__c> mapa = getQualQuestionByTabs(tabCodes);
    **/
    public static Map<String, dyfr__Field_Config__c> getQualQuestionByTabs(Set<String> tabCodes) {
        // Fetch field configs qualitative question filtered by tab codes
        final List<dyfr__Field_Config__c> fieldConfigs = [SELECT Id, Name, dyfr__Tab__c, dyfr__DeveloperName__c, dyfr__Label__c, dyfr__Map_field__c,
                                                        dyfr__Subsection_name__c, dyfr__Section_name__c, Arc_Gen_QualitativeQuestions__c
                                                        FROM dyfr__Field_Config__c
                                                        WHERE dyfr__Tab__r.dyfr__Tab_Code__c IN :tabCodes
                                                        AND Arc_Gen_QualitativeQuestions__c = true];
        final Map<String, dyfr__Field_Config__c> fcToVarMap = new Map<String, dyfr__Field_Config__c>();
        for (dyfr__Field_Config__c fieldConfig : fieldConfigs) {
            fcToVarMap.put(fieldConfig.dyfr__Map_field__c, fieldConfig);
        }
        return fcToVarMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that check changes in the qualitative questions configured in the template of the customer.
    *-------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @date     03/06/2022
    * @param    sObject oldAha
    * @param    sObject newAha
    * @param    String nameClass
    * @return   checkChangesQualQuestion(oldAha, newAha, nameClass);
    * @example  checkChangesQualQuestion(oldAha, newAha, nameClass);
    **/
    public static void checkChangesQualQuestion(sObject oldAha, sObject newAha, String nameClass) {
        final arce__Account_has_Analysis__c ahaObj = (arce__Account_has_Analysis__c) newAha;
        final arce__Sector__c sector = Arc_Gen_Sector_Data.getSectorAccHasAn(ahaObj, ahaObj.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
        if (sector != null && sector.arce__anlys_wkfl_cnsld_ffss_type__c != arce.Arc_Gen_Constants.FAMILY_CONSGROUP) {
            final List<String> lstSection = sector.arce__analysis_section_list__c.split(';');
            final List<dyfr__Tab__c> lstTabs = [SELECT Id, dyfr__Tab_Code__c, Name
                                                FROM dyfr__Tab__c
                                                WHERE dyfr__Template__r.Name IN :lstSection
                                                AND dyfr__Save_APEX_Class__c = :nameClass];
            final Map<String,dyfr__Field_Config__c> mapFc = getQualQuestionByTabs(new Set<String>{lstTabs[0].dyfr__Tab_Code__c});
            if (arce.Arc_Gen_GenericUtilities.checkChanges(oldAha, newAha, new List<String>(mapFc.keySet()))) {
                ahaObj.arce__recalculate_rating__c = RATING;
                arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(new List<arce__Account_has_Analysis__c>{ahaObj});
            }
        }
    }
}