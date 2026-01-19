/**
* @File Name          : Arc_Gen_TraceabilityEvents_Data.cls
* @Description        : Traceability event data class
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |12/02/2021 juanignacio.hita.contractor@bbva.com
*             Class creation
* -----------------------------------------------------------------------------------------------
**/
public without sharing class Arc_Gen_TraceabilityEvents_Data {
    /**
    * @Description: All available fields traceability events
    */
    public static final List<String> ALL_FIELDS = new List<String> {'arce__account_has_analysis_id__c', 'arce__analysis_id__c', 'arce__anlys_wkfl_discard_reason_id__c', 'arce__anlys_wkfl_edit_br_level_type__c',
                                                                    'arce__anlys_wkfl_return_reason_desc__c', 'arce__anlys_wkfl_sanction_rslt_type__c', 'arce__anlys_wkfl_snctn_br_level_type__c',
                                                                    'arce__anlys_wkfl_sub_process_type__c', 'arce__audit_date__c', 'arce__current_event__c', 'arce__gc_trcblty_internal_code_id__c',
                                                                    'arce__gf_anlys_wkfl_committee_type__c', 'arce__gf_anlys_wkfl_discard_reason_desc__c', 'arce__gf_applied_action_type__c', 'arce__gf_risk_cmtee_sntcn_user_id__c',
                                                                    'arce__start_time__c', 'arce__stop_time__c', 'arce__total_time__c', 'arce__user_audit_id__c', 'arce__wkfl_risk_expiry_date__c', 'arce__wkfl_risk_sanction_date__c',
                                                                    'arce__wkfl_sanction_rsn_desc__c', 'arce__wkfl_stage_type__c', 'arce__wkfl_status_stage_type__c', 'Name', 'Id'};

    /**
    *-------------------------------------------------------------------------------
    * @description Void constructor
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   15/02/2021
    * @param  void
    * @return void
    * @example Arc_Gen_TraceabilityEvents_Helper()
    **/
    @TestVisible
    private Arc_Gen_TraceabilityEvents_Data () {
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Returns a list of traceability events with all available fields
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   15/02/2021
    * @param  String analysisId
    * @param  List<String> lstFields
    * @return List<arce__Traceability_Event__c>
    * @example List<arce__Traceability_Event__c> lstObj = getEvtActiveAnalysis(analysisId, lstFields);
    **/
    public static List<arce__Traceability_Event__c> getEvtActiveAnalysis(String analysisId, List<String> lstFields) {
        List<arce__Traceability_Event__c> result = null;   //NOSONAR
        final String fieldListStr = String.escapeSingleQuotes(String.join(lstFields, ','));
        final String query = 'SELECT ' + fieldListStr + ' FROM arce__Traceability_Event__c WHERE arce__analysis_id__c = :analysisId AND arce__current_event__c = true';
        final List<arce__Traceability_Event__c> resultList = Database.query(query);
        return resultList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Returns a Map of  arce Id and traceability events
    --------------------------------------------------------------------------------
    * @author noelia.ruiz.lopez.contractor@bbva.com
    * @date   16/11/2023
    * @param  List<Id> analysisIds
    * @return Map <Id, arce__Traceability_Event__c>
    * @example List<Id> lstObj = getEvtActiveAnalysis(analysisIds);
    **/
    public static Map<Id,  List<arce__Traceability_Event__c>> getEvtActiveAnalysis(List<Id> analysisIds) {
        Map <Id, List<arce__Traceability_Event__c>> traceabilityEventMap = new Map<Id, List<arce__Traceability_Event__c>>();
        final String fieldListStr = String.escapeSingleQuotes(String.join(ALL_FIELDS, ','));
        final String query = 'SELECT ' + fieldListStr + ' FROM arce__Traceability_Event__c WHERE arce__analysis_id__c IN :analysisIds AND arce__current_event__c = true';
        final List<arce__Traceability_Event__c> resultList = Database.query(query);
        for(arce__Traceability_Event__c traceability : resultList){
            if(!traceabilityEventMap.containsKey(traceability.arce__analysis_id__c)){
                traceabilityEventMap.put(traceability.arce__analysis_id__c, new List <arce__Traceability_Event__c>{traceability});
            }else{
                List <arce__Traceability_Event__c> aux = traceabilityEventMap.get(traceability.arce__analysis_id__c);
                aux.add(traceability);
                traceabilityEventMap.put(traceability.arce__analysis_id__c, aux);
            }
        }
        return  traceabilityEventMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Returns a list of traceability events related with analysis and an action doing by a user
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   15/02/2021
    * @param  String analysisId
    * @param  List<String> lstFields
    * @param  String action
    * @return List<arce__Traceability_Event__c>
    * @example List<arce__Traceability_Event__c> lstObj = getEvtByAnlysisUserAction(analysisId, userId, action);
    **/
    public static List<arce__Traceability_Event__c> getEvtByAnlysisUserAction(String analysisId, String userId, String action) {
        return [SELECT Id, arce__gc_trcblty_internal_code_id__c FROM arce__Traceability_Event__c
                WHERE arce__analysis_id__c = :analysisId AND arce__user_audit_id__c = :userId AND
                arce__gf_applied_action_type__c = :action];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Update current and last traceability events
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   15/02/2021
    * @param  Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example updateTraceEvents(wkflWrapper);
    **/
    public static void updateTraceEvents(Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper) {
        insert wkflWrapper.wkflEvtCurrent;
        if (wkflWrapper.wkflEvtLast != null) {
            update wkflWrapper.wkflEvtLast;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Update traceability event records
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   03/03/2021
    * @param  List<arce__Traceability_Event__c> lstTraceability
    * @return void
    * @example updateRecordTraceability(lstTraceability);
    **/
    public static void updateRecordTraceability(List<arce__Traceability_Event__c> lstTraceability) {
        update lstTraceability;
    }

}