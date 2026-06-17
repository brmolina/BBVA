/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Utils
* @Author   cosme.alcazar.tech@bbva.com
* @Date     Created: 2025-04-29
* -------------------------------------------------------------------------------------------
* @Description Utils_Itf implementation class
* -------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class HPGR_Utils implements hpgr.Utils_Itf {

    static final String LWC_CONSUMPTION_DETAIL = 'consumption_detail';
    static final String CONTRACT_GUARANTEES = 'contract_guarantees';
    static final String SUPPORT_WUT = 'SupportWUT';
    static final String DMT_SOPORTE_FUNCIONAL = 'DMT_Soporte funcional';
    static final String DMT_CONFIGURADOR_SF = 'DMT_Configurador SF';
    static final String DMT_LINE_URL_TEMPLATE = '/lightning/r/DMT_Line__c/SALESFORCE_ID/view';

    /**
    * @description get 'consumptionLastLevelId' field hierarchy
    * @param - : no param
    * @return List with 'consumptionLastLevelId' field hierarchy
    */
    public static Map<String, Object> getConsumptionLastLevelIdHierarchyData(String catalogId) {
        Map<String, Object> consumptionLastLevelIdHierarchyLocal = new Map<String, Object>();
        Date cuttoffDate = [SELECT gf_cutoff_date__c FROM DMT_Taxonomy_Hierarchy__c ORDER BY gf_cutoff_date__c DESC LIMIT 1].gf_cutoff_date__c;
        DateTime lastModifiedDate = [SELECT LastModifiedDate FROM DMT_Taxonomy_Hierarchy__c ORDER BY LastModifiedDate DESC LIMIT 1].LastModifiedDate;
        Date fecha = lastModifiedDate.date();
        DateTime fechaTime = DateTime.newInstance(fecha.year(), fecha.month(), fecha.day(), 0, 0, 0);
        DateTime lastModifiedDateMin = fechaTime.addSeconds(UserInfo.getTimezone().getOffset(fechaTime) / 1000);
        List<DMT_Taxonomy_Hierarchy__c> taxonomyHierarchyList = [SELECT gf_cutoff_date__c,
                                                                        g_hierarchy_id__c,
                                                                        g_hierarchy_node_catalog_id__c,
                                                                        g_hierarchy_node_level_id__c,
                                                                        gf_hierarchy_node_value_id__c,
                                                                        gf_lvl_1_hier_catalog_val_id__c,
                                                                        gf_lvl_2_hier_catalog_val_id__c,
                                                                        gf_lvl_3_hier_catalog_val_id__c,
                                                                        gf_lvl_4_hier_catalog_val_id__c,
                                                                        gf_lvl_5_hier_catalog_val_id__c,
                                                                        gf_lvl_6_hier_catalog_val_id__c,
                                                                        gf_lvl_7_hier_catalog_val_id__c,
                                                                        gf_lvl_8_hier_catalog_val_id__c,
                                                                        gf_lvl_9_hier_catalog_val_id__c,
                                                                        gf_lvl_10_hier_catalog_val_id__c,
                                                                        gf_lvl_11_hier_catalog_val_id__c,
                                                                        gf_lvl_12_hier_catalog_val_id__c,
                                                                        gf_lvl_13_hier_catalog_val_id__c,
                                                                        gf_lvl_14_hier_catalog_val_id__c,
                                                                        gf_lvl_15_hier_catalog_val_id__c
                                                                    FROM DMT_Taxonomy_Hierarchy__c
                                                                    WHERE g_hierarchy_node_catalog_id__c = :catalogId AND gf_cutoff_date__c =:cuttoffDate AND LastModifiedDate >=:lastModifiedDateMin
                                                                    ORDER BY gf_cutoff_date__c DESC,
                                                                            gf_lvl_1_hier_catalog_val_id__c DESC,
                                                                            g_hierarchy_node_level_id__c DESC,
                                                                            gf_lvl_2_hier_catalog_val_id__c,
                                                                            gf_lvl_3_hier_catalog_val_id__c,
                                                                            gf_lvl_4_hier_catalog_val_id__c,
                                                                            gf_lvl_5_hier_catalog_val_id__c,
                                                                            gf_lvl_6_hier_catalog_val_id__c,
                                                                            gf_lvl_7_hier_catalog_val_id__c,
                                                                            gf_lvl_8_hier_catalog_val_id__c,
                                                                            gf_lvl_9_hier_catalog_val_id__c,
                                                                            gf_lvl_10_hier_catalog_val_id__c,
                                                                            gf_lvl_11_hier_catalog_val_id__c,
                                                                            gf_lvl_12_hier_catalog_val_id__c,
                                                                            gf_lvl_13_hier_catalog_val_id__c,
                                                                            gf_lvl_14_hier_catalog_val_id__c,
                                                                            gf_lvl_15_hier_catalog_val_id__c];
        Set<String> consumptionLastLevelIdSet = new Set<String>();
        List<List<String>> taxonomyValueListArray = new List<List<String>>();
        Set<String> uniqueRecords = new Set<String>();
        Set<String> invalidValues = new Set<String>{'', '-', null, '0'};
        for (DMT_Taxonomy_Hierarchy__c record : taxonomyHierarchyList) {
            List<String> innerList = new List<String>();
            innerList.add(record.g_hierarchy_node_level_id__c);
            if (!invalidValues.contains(record.gf_lvl_1_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_1_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_1_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_2_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_2_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_2_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_3_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_3_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_3_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_4_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_4_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_4_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_5_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_5_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_5_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_6_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_6_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_6_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_7_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_7_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_7_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_8_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_8_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_8_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_9_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_9_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_9_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_10_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_10_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_10_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_11_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_11_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_11_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_12_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_12_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_12_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_13_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_13_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_13_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_14_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_14_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_14_hier_catalog_val_id__c);
            }
            if (!invalidValues.contains(record.gf_lvl_15_hier_catalog_val_id__c)) {
                innerList.add(record.gf_lvl_15_hier_catalog_val_id__c);
                consumptionLastLevelIdSet.add(record.gf_lvl_15_hier_catalog_val_id__c);
            }
            String uniqueKey = String.join(innerList, ',');
            if (!uniqueRecords.contains(uniqueKey)) {
                uniqueRecords.add(uniqueKey);
                taxonomyValueListArray.add(innerList);
            }
        }
        if (taxonomyValueListArray.size() == 0) {
            // Save error in DES_Exceptions__b
            hpgr.Utils.Error_Wrapper errorWrapper = new hpgr.Utils.Error_Wrapper();
            errorWrapper.type = 'DMT_Taxonomy_Hierarchy__c Error';
            errorWrapper.errorData = 'No valid taxonomyValueListArray values found for Taxonomy catalog: ' + catalogId;
            errorWrapper.className = 'HPGR_Utils';
            errorWrapper.methodName = 'getConsumptionLastLevelIdHierarchyData';
            HPGR_Utils.manageError(errorWrapper);
        }
        List<hpgr.Utils.ConsumptionLastLevelIdHierarchy> consumptionLastLevelIdHierarchy = hpgr.Utils.getConsumptionLastLevelIdHierarchy(taxonomyValueListArray);
        // Get Labels
        Set<String> uniqueValues = new Set<String>();
        Map<String, String> taxonomyValuesMap = new Map<String, String>();
        List<DMT_Taxonomy_Values__c> taxonomyValueList = [SELECT DMT_Value__c, DMT_Name_EN__c
                                                            FROM DMT_Taxonomy_Values__c
                                                            WHERE DMT_Catalog__c = :catalogId
                                                            ORDER BY DMT_Cutoff_Date__c DESC];
        for (DMT_Taxonomy_Values__c taxonomyValue : taxonomyValueList) {
            if (!uniqueValues.contains(taxonomyValue.DMT_Value__c)) {
                uniqueValues.add(taxonomyValue.DMT_Value__c);
                taxonomyValuesMap.put(taxonomyValue.DMT_Value__c, taxonomyValue.DMT_Name_EN__c);
            }
        }
        Map<String, String> consumptionLastLevelIdLabels = hpgr.Utils.getConsumptionLastLevelIdHierarchyLabels(consumptionLastLevelIdSet, taxonomyValuesMap);
        if (consumptionLastLevelIdHierarchy.size() == 0 || consumptionLastLevelIdLabels.isEmpty()) {
            // Save error in DES_Exceptions__b
            hpgr.Utils.Error_Wrapper errorWrapper = new hpgr.Utils.Error_Wrapper();
            errorWrapper.type = 'Data Retrieval Error';
            if (consumptionLastLevelIdHierarchy.size() == 0) {
                errorWrapper.errorData = 'No hpgr.Utils.getConsumptionLastLevelIdHierarchy values found for Taxonomy catalog: ' + catalogId;
            } else {
                errorWrapper.errorData = 'No DMT_Taxonomy_Values__c values found for Taxonomy catalog: ' + catalogId;
            }
            errorWrapper.className = 'HPGR_Utils';
            errorWrapper.methodName = 'getConsumptionLastLevelIdHierarchyData';
            HPGR_Utils.manageError(errorWrapper);
            consumptionLastLevelIdHierarchyLocal.put('success', false);
        } else {
            consumptionLastLevelIdHierarchyLocal.put('consumptionLastLevelIdHierarchy', consumptionLastLevelIdHierarchy);
            consumptionLastLevelIdHierarchyLocal.put('consumptionLastLevelIdLabels', consumptionLastLevelIdLabels);
            consumptionLastLevelIdHierarchyLocal.put('success', true);
        }
        return consumptionLastLevelIdHierarchyLocal;
    }

    /**
    * @description get 'consumptionLastLevelId' field values
    * @param - : no param
    * @return List with 'consumptionLastLevelId' field values
    */
    public static Map<String, Object> getConsumptionLastLevelIdData(String catalogId) {
        Map<String, Object> consumptionLastLevelIdLocal = new Map<String, Object>();
        List<hpgr.Utils.ConsumptionLastLevelIdValues> consumptionLastLevelIdValues = new List<hpgr.Utils.ConsumptionLastLevelIdValues>();
        Date cuttoffDate = [SELECT gf_cutoff_date__c FROM DMT_Taxonomy_Hierarchy__c ORDER BY gf_cutoff_date__c DESC LIMIT 1].gf_cutoff_date__c;
        DateTime lastModifiedDate = [SELECT LastModifiedDate FROM DMT_Taxonomy_Hierarchy__c ORDER BY LastModifiedDate DESC LIMIT 1].LastModifiedDate;
        Date fecha = lastModifiedDate.date();
        DateTime fechaTime = DateTime.newInstance(fecha.year(), fecha.month(), fecha.day(), 0, 0, 0);
        DateTime lastModifiedDateMin = fechaTime.addSeconds(UserInfo.getTimezone().getOffset(fechaTime) / 1000);
        Set<String> consumptionLastLevelIdSet = new Set<String>();
        for (DMT_Taxonomy_Hierarchy__c taxonomyValue : [SELECT gf_hierarchy_node_value_id__c
                                                        FROM DMT_Taxonomy_Hierarchy__c
                                                        WHERE g_hierarchy_node_catalog_id__c = :catalogId AND gf_cutoff_date__c =:cuttoffDate AND LastModifiedDate >=:lastModifiedDateMin
                                                        ORDER BY gf_cutoff_date__c DESC]) {
            consumptionLastLevelIdSet.add(taxonomyValue.gf_hierarchy_node_value_id__c);
        }
        // Get Labels
        // Backup values from Custom Metadata Type
        List<hpgr.Utils.ConsumptionLastLevelIdValues> taxonomyValuesListBackup = new List<hpgr.Utils.ConsumptionLastLevelIdValues>();
        Map<String, Object> retMap = hpgr.Utils.getConsumptionLastLevelIdBackup(catalogId);
        taxonomyValuesListBackup = (List<hpgr.Utils.ConsumptionLastLevelIdValues>)retMap.get('consumptionLastLevelIdValues');
        // Values from local Taxonomy
        Set<String> uniqueValues = new Set<String>();
        Map<String, String> taxonomyValuesMap = new Map<String, String>();
        List<hpgr.Utils.ConsumptionLastLevelIdValues> taxonomyValuesList = new List<hpgr.Utils.ConsumptionLastLevelIdValues>();
        for (DMT_Taxonomy_Values__c taxonomyValue : [SELECT DMT_Value__c, DMT_Name_EN__c
                                                        FROM DMT_Taxonomy_Values__c
                                                        WHERE DMT_Catalog__c = :catalogId
                                                        ORDER BY DMT_Cutoff_Date__c DESC]) {
            if (!uniqueValues.contains(taxonomyValue.DMT_Value__c)) {
                uniqueValues.add(taxonomyValue.DMT_Value__c);
                taxonomyValuesList.add(new hpgr.Utils.ConsumptionLastLevelIdValues(taxonomyValue.DMT_Value__c, taxonomyValue.DMT_Name_EN__c, '', ''));
            }
        }
        // Use visualization order and set 'onClickComponent' and 'onClickRow' from Backup values
        Map<String, hpgr.Utils.ConsumptionLastLevelIdValues> uniqueValuesMap = new Map<String, hpgr.Utils.ConsumptionLastLevelIdValues>();
        for (hpgr.Utils.ConsumptionLastLevelIdValues backupValue : taxonomyValuesListBackup) {
            uniqueValuesMap.put(backupValue.consumptionLastLevelId, backupValue);
        }
        for (hpgr.Utils.ConsumptionLastLevelIdValues localValue : taxonomyValuesList) {
            if (uniqueValuesMap.containsKey(localValue.consumptionLastLevelId)) {
                hpgr.Utils.ConsumptionLastLevelIdValues existingValue = uniqueValuesMap.get(localValue.consumptionLastLevelId);
                existingValue.consumptionLastLevelName = localValue.consumptionLastLevelName;
            } else {
                localValue.onClickComponent = LWC_CONSUMPTION_DETAIL;
                localValue.onClickRow = CONTRACT_GUARANTEES;
                uniqueValuesMap.put(localValue.consumptionLastLevelId, localValue);
            }
        }
        List<hpgr.Utils.ConsumptionLastLevelIdValues> combinedList = new List<hpgr.Utils.ConsumptionLastLevelIdValues>(uniqueValuesMap.values());
        consumptionLastLevelIdValues = hpgr.Utils.getConsumptionLastLevelIdChildValues(consumptionLastLevelIdSet, combinedList);
        if(consumptionLastLevelIdValues.size() == 0) {
            // Save error in DES_Exceptions__b
            hpgr.Utils.Error_Wrapper errorWrapper = new hpgr.Utils.Error_Wrapper();
            errorWrapper.type = 'hpgr.Utils.getConsumptionLastLevelIdChildValues Error';
            errorWrapper.errorData = 'No consumptionLastLevelId values found for Taxonomy catalog: ' + catalogId;
            errorWrapper.className = 'HPGR_Utils';
            errorWrapper.methodName = 'getConsumptionLastLevelIdData';
            HPGR_Utils.manageError(errorWrapper);
            consumptionLastLevelIdLocal.put('success', false);
        } else {
            consumptionLastLevelIdLocal.put('consumptionLastLevelIdValues', consumptionLastLevelIdValues);
            consumptionLastLevelIdLocal.put('success', true);
        }
        return consumptionLastLevelIdLocal;
    }

    /**
    * @description manage error handling
    * @param errorWrapper : dynamic structure containing error information
    * @return void
    */
    public static void manageError(hpgr.Utils.Error_Wrapper errorWrapper) {
        DES_Exceptions__b exceptionRecord = new DES_Exceptions__b();
        // Class_Name__c
        String namespace = String.isNotBlank(errorWrapper.namespace) ? errorWrapper.namespace + '.' : '';
        exceptionRecord.Class_Name__c = errorWrapper.className != null ? namespace + errorWrapper.className :namespace + 'Unknown Class';
        // DML_Fields__c
        // exceptionRecord.DML_Fields__c =
        // DML_StatusCode__c
        // exceptionRecord.DML_StatusCode__c =
        // LineNumber__c
        // exceptionRecord.LineNumber__c =
        // Message__c
        String errorMessage = 'See debug logs for more details';
        if (errorWrapper.errorData != null) {
            if (errorWrapper.errorData instanceof String) {
                errorMessage = (String)errorWrapper.errorData;
            } else if (errorWrapper.errorData instanceof Exception) {
                errorMessage = ((Exception)errorWrapper.errorData).getMessage();
            }
        }
        exceptionRecord.Message__c = errorMessage;
        // MethodName__c
        exceptionRecord.MethodName__c = errorWrapper.methodName != null ? errorWrapper.methodName : 'Unknown Method';
        // Object__c
        // exceptionRecord.Object__c =
        // Project__c
        exceptionRecord.Project__c = ' Global Clients Exposure - hpgr Package';
        // RecordId__c
        // exceptionRecord.RecordId__c =
        // Reported_By__c
        if (errorWrapper.userId != null) {
            exceptionRecord.Reported_By__c = errorWrapper.userId;
        } else {
            exceptionRecord.Reported_By__c = UserInfo.getUserId();
        }
        // StackTrace__c
        // exceptionRecord.StackTrace__c =
        // Timestamp__c
        if (errorWrapper.timestamp != null) {
            exceptionRecord.Timestamp__c = errorWrapper.timestamp;
        } else {
            exceptionRecord.Timestamp__c = System.now();
        }
        // Type__c
        exceptionRecord.Type__c = errorWrapper.type;
        if (!Test.isRunningTest()) {
            Database.insertImmediate(exceptionRecord);
        }
        System.debug('manageError - errorWrapper.type: ' + errorWrapper.type);
        System.debug('manageError - errorWrapper.namespace: ' + errorWrapper.namespace);
        System.debug('manageError - errorWrapper.className: ' + errorWrapper.className);
        System.debug('manageError - errorWrapper.methodName: ' + errorWrapper.methodName);
        System.debug('manageError - errorWrapper.userId: ' + errorWrapper.userId);
        System.debug('manageError - errorWrapper.timestamp: ' + errorWrapper.timestamp);
        System.debug('manageError - errorWrapper.errorData: ' + errorWrapper.errorData);
        // Handle different types of error data
        //if (errorWrapper.errorData == null) {
        //    System.debug(LoggingLevel.ERROR, 'manageError - Error data is null');
        //    return;
        //}
        // Check if it's a String
        //if (errorWrapper.errorData instanceof String) {
        //    System.debug(LoggingLevel.ERROR, 'manageError - Error message: ' + (String)errorWrapper.errorData);
        //}
        // Check if it's an Exception
        //else if (errorWrapper.errorData instanceof Exception) {
        //    Exception ex = (Exception)errorWrapper.errorData;
        //    System.debug(LoggingLevel.ERROR, 'manageError - Exception occurred: ' + ex.getMessage());
        //    System.debug(LoggingLevel.ERROR, 'manageError - Stack trace: ' + ex.getStackTraceString());
        //}
        // Check if it's a Map (structured error data)
        //else if (errorWrapper.errorData instanceof Map<String, Object>) {
        //    Map<String, Object> errorMap = (Map<String, Object>)errorWrapper.errorData;
        //    System.debug(LoggingLevel.ERROR, 'manageError - Structured error data: ' + JSON.serialize(errorMap));
        //}
        // Handle other types
        //else {
        //    System.debug(LoggingLevel.ERROR, 'manageError - Error data type: ' + String.valueOf(errorWrapper.errorData));
        //}
    }

    /**
    * @description manage open help
    * @param - : no param
    * @return no return
    */
    @AuraEnabled
    public static void manageOpenHelp() {
        DES_pe_SurveyNotification__e surveyEvt = new DES_pe_SurveyNotification__e(DES_fld_Survey__c = SUPPORT_WUT);
        Database.SaveResult savedResult = EventBus.publish(surveyEvt);
        if (!savedResult.isSuccess()) {
            for (Database.Error err : savedResult.getErrors()) {
                System.debug('Error al solicitar encuesta NotebookLM: ' + err.getMessage());
            }
            // Save error in DES_Exceptions__b
            hpgr.Utils.Error_Wrapper errorWrapper = new hpgr.Utils.Error_Wrapper();
            errorWrapper.type = 'DES_pe_SurveyNotification__e Error';
            errorWrapper.errorData = savedResult.getErrors();
            errorWrapper.className = 'HPGR_Utils';
            errorWrapper.methodName = 'manageOpenHelp';
            HPGR_Utils.manageError(errorWrapper);
        }
    }

    /**
    * @description get opportunity ids with DMT line and their url
    * @param opportunityIdSet : set of opportunity ids
    * @return opportunity ids with DMT line and their url
    */
    public static Map<String, String> getDMTLinesData(Set<String> opportunityIdSet) {
        Map<String,String> linesData = new Map<String, String>();
        Set<String> validDMTRoles = new Set<String>{DMT_SOPORTE_FUNCIONAL, DMT_CONFIGURADOR_SF};
        Set<String> linesValidDMTRoles = new Set<String>();
        // The user has certain DMT role or is the Owner of the line or is participant of the line
        List<User> user = [SELECT Id, DMT_User_Role__c FROM User WHERE Id = :UserInfo.getUserId() AND (DMT_User_Role__c LIKE :DMT_SOPORTE_FUNCIONAL OR DMT_User_Role__c LIKE :DMT_CONFIGURADOR_SF) LIMIT 1];
        if (user.size() > 0) {
            for (DMT_Line__c line : [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c IN :opportunityIdSet]) {
                linesData.put(line.Line_Id__c, DMT_LINE_URL_TEMPLATE.replace('SALESFORCE_ID', line.Id));
            }
        } else {
            Map<String, Id> dmtOwnerLinesMap = new Map<String, Id>();
            for (DMT_Line__c dmtOwnerLine : [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c IN :opportunityIdSet AND OwnerId = :UserInfo.getUserId()]) {
                dmtOwnerLinesMap.put(dmtOwnerLine.Line_Id__c, dmtOwnerLine.Id);
            }
            Set<Id> lineIds = new Set<Id>();
            for (DMT_Line__c line : [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c IN :opportunityIdSet]) {
                lineIds.add(line.Id);
            }
            Map<String, Id> dmtTeamMemberLinesMap = new Map<String, Id>();
            for (DMT_TeamMember__c dmtTeamMember :[SELECT Id, Line__c, Line__r.Line_Id__c FROM DMT_TeamMember__c WHERE Line__c IN :lineIds AND User__c = :UserInfo.getUserId()]) {
                dmtTeamMemberLinesMap.put(dmtTeamMember.Line__r.Line_Id__c, dmtTeamMember.Line__c);
            }
            for (String opportunityId : opportunityIdSet) {
                if (dmtOwnerLinesMap.containsKey(opportunityId)) {
                    Id lineId = dmtOwnerLinesMap.get(opportunityId);
                    if (lineId != null) {
                        linesData.put(opportunityId, DMT_LINE_URL_TEMPLATE.replace('SALESFORCE_ID', lineId));
                    }
                } else if (dmtTeamMemberLinesMap.containsKey(opportunityId)) {
                    Id lineId = dmtTeamMemberLinesMap.get(opportunityId);
                    if (lineId != null) {
                        linesData.put(opportunityId, DMT_LINE_URL_TEMPLATE.replace('SALESFORCE_ID', lineId));
                    }
                }
            }
        }
        return linesData;
    }
}