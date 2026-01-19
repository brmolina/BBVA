/**
* @File Name          : Arc_Gen_TraceabilityEvents.cls
* @Description        : Funcionality class for the traceability events
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |04/02/2021 juanignacio.hita.contractor@bbva.com
*             Class creation
* |20/07/2021 juanignacio.hita.contractor@bbva.com
*             Change mapping stop_time__c field in the creation event for the sanction action.
*             Adds change stage/status when sanction action, actionWkflTraceEvt method
* -----------------------------------------------------------------------------------------------
**/
public without sharing class Arc_Gen_TraceabilityEvents {
    /**
    * @Description: Propose in preparation action label
    */
    public static final String PROPOSE_PREP = 'PROPOSE_PREP';
    /**
    * @Description: Propose in sanction action label
    */
    public static final String PROPOSE_SANCTION = 'PROPOSE_SANCTION';
    /**
    * @Description: Schedule action label
    */
    public static final String SCHEDULE = 'SCHEDULE';
    /**
    * @Description: Remove action label
    */
    public static final String REMOVE = 'REMOVE';
    /**
    * @Description: Return action label
    */
    public static final String RETURNACT = 'RETURN';
    /**
    * @Description: Sanction action label
    */
    public static final String SANCTION = 'SANCTION';
    /**
    * @Description: Propose action for IRP
    */
    public static final String PROPOSEIRP = 'PROPOSE-IRP';
    /**
    * @Description: Validate action
    */
    public static final String VALIDATE = 'VALIDATE';
    /**
    * @Description: Propose action for IRP
    */
    public static final String VALIDATEIRP = 'VALIDATE-IRP';
    /**
    * @Description: Actions with api values of applied_action field of traceability object
    */
    public static final Map<String, String> ACTIONS = new Map<String, String> {
        VALIDATE => '0',
        PROPOSE_PREP => '1',
        PROPOSE_SANCTION => '1',
        SCHEDULE => '2',
        REMOVE => '3',
        RETURNACT => '4',
        SANCTION => '5',
        PROPOSEIRP => '1',
        VALIDATEIRP => '6'
    };
    /**
        * @Description: Ambit arce analysis field
    */
    private static final String FLD_AMBIT = 'arce__anlys_wkfl_edit_br_level_type__c';

    /**
    * @Description: Stage arce analysis field
    */
    private static final String FLD_STAGE = 'arce__wkfl_stage_type__c';

    /**
    * @Description: Status arce analysis field
    */
    private static final String FLD_STATUS = 'arce__wkfl_status_stage_type__c';

    /**
        * @Description: Traceability wrapper
    */
    public class Arc_Gen_Traceability_Wrapper {
        /**
        * @Description: Delegation wrapper
        */
        Arc_Gen_Delegation_Wrapper delegationWrapper {get; set;}
        /**
        * @Description: Account has analysis object
        */
        public arce__Account_has_Analysis__c accHasAnlysis {get; set;}
        /**
        * @Description: Analysis object
        */
        public arce__Analysis__c analysis {get; set;}
        /**
        * @Description: New current workflow traceability event
        */
        public arce__Traceability_Event__c wkflEvtCurrent {get; set;}
        /**
        * @Description: Last workflow traceability event record
        */
        public arce__Traceability_Event__c wkflEvtLast {get; set;}
        /**
        * @Description: Action name
        */
        public String action {get; set;}
        /**
        * @Description: Custom map with paremeters for each action
        */
        public Map<String, Object> mapReqAction {get;set;}
        /**
        *-------------------------------------------------------------------------------
        * @description Constructor traceability wrapper
        --------------------------------------------------------------------------------
        * @author juanignacio.hita.contractor@bbva.com
        * @date   08/02/2021
        * @param  Arc_Gen_Delegation_Wrapper delWrap
        * @param  arce__Account_has_Analysis__c accHas
        * @param  arce__Analysis__c anlysis, String actionName
        * @param  String actionName
        * @return void
        * @example Arc_Gen_Traceability_Wrapper wrapper = new Arc_Gen_Traceability_Wrapper(delWrap, accHas, analysis, action);
        **/
        public Arc_Gen_Traceability_Wrapper(Arc_Gen_Delegation_Wrapper delWrap, arce__Account_has_Analysis__c accHas, arce__Analysis__c anlysis, String actionName) {
            delegationWrapper = delWrap;
            accHasAnlysis = accHas;
            analysis = anlysis;
            action = actionName;
            wkflEvtCurrent = new arce__Traceability_Event__c();
            mapReqAction = new Map<String, Object>();
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Void constructor
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  void
    * @return void
    * @example Arc_Gen_TraceabilityEvents()
    **/
    @TestVisible
    private Arc_Gen_TraceabilityEvents () {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that save common fields of traceability event record
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return Arc_Gen_Traceability_Wrapper wkflWrapper
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = saveTraceEvent(wkflWrapper);
    **/
    public static Arc_Gen_Traceability_Wrapper saveTraceEvent(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        // Get current traceability event active in analysis, update stop date and current event flag
        Arc_Gen_TraceabilityEvents_Helper.updateCurrentEvent(wkflWrapper);
        // Fill common fields new traceability event record Required fields
        wkflWrapper.wkflEvtCurrent.arce__current_event__c = true;
        wkflWrapper.wkflEvtCurrent.arce__gc_trcblty_internal_code_id__c = Arc_Gen_TraceabilityEvents_Helper.getWkflCode(wkflWrapper);
        wkflWrapper.wkflEvtCurrent.arce__account_has_analysis_id__c = wkflWrapper.accHasAnlysis.Id;
        wkflWrapper.wkflEvtCurrent.arce__analysis_id__c = wkflWrapper.analysis.Id;
        wkflWrapper.wkflEvtCurrent.arce__wkfl_stage_type__c = wkflWrapper.analysis.arce__Stage__c;
        wkflWrapper.wkflEvtCurrent.arce__wkfl_status_stage_type__c = wkflWrapper.analysis.arce__wf_status_id__c;
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_sub_process_type__c = wkflWrapper.analysis.arce__anlys_wkfl_sub_process_type__c;
        wkflWrapper.wkflEvtCurrent.arce__audit_date__c = System.today();
        wkflWrapper.wkflEvtCurrent.arce__user_audit_id__c = System.UserInfo.getUserId();
        wkflWrapper.wkflEvtCurrent.arce__gf_applied_action_type__c = ACTIONS.get(wkflWrapper.action);
        wkflWrapper.wkflEvtCurrent.arce__riskAssessmentId__c = wkflWrapper.accHasAnlysis.Name;
        return actionWkflTraceEvt(wkflWrapper);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that save common fields of traceability event record
    --------------------------------------------------------------------------------
    * @author noelia.ruiz.lopez.contractor@bbva.com
    * @date   20/11/2023
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return Arc_Gen_Traceability_Wrapper wkflWrapper
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = saveTraceEvent(wkflWrapper);
    **/
    public static Arc_Gen_Traceability_Wrapper saveTraceEvent(Arc_Gen_Traceability_Wrapper wkflWrapper, List <arce__Traceability_Event__c> lastWkflEvt) {
        // Get current traceability event active in analysis, update stop date and current event flag
        // Update Stop time workflow event
        if (lastWkflEvt == null || lastWkflEvt.isEmpty()) {
            wkflWrapper.wkflEvtCurrent.arce__start_time__c = wkflWrapper.analysis.CreatedDate;
        } else {
            wkflWrapper.wkflEvtLast = lastWkflEvt[0];
            wkflWrapper.wkflEvtLast.arce__current_event__c = false;
            wkflWrapper.wkflEvtCurrent.arce__start_time__c = wkflWrapper.wkflEvtLast.arce__stop_time__c;
        }
        wkflWrapper.wkflEvtCurrent.arce__stop_time__c = DateTime.now();
        // Fill common fields new traceability event record Required fields
        wkflWrapper.wkflEvtCurrent.arce__current_event__c = true;
        wkflWrapper.wkflEvtCurrent.arce__gc_trcblty_internal_code_id__c = Arc_Gen_TraceabilityEvents_Helper.getWkflCode(wkflWrapper);
        wkflWrapper.wkflEvtCurrent.arce__account_has_analysis_id__c = wkflWrapper.accHasAnlysis?.Id;
        wkflWrapper.wkflEvtCurrent.arce__analysis_id__c = wkflWrapper.analysis.Id;
        wkflWrapper.wkflEvtCurrent.arce__wkfl_stage_type__c = wkflWrapper.analysis.arce__Stage__c;
        wkflWrapper.wkflEvtCurrent.arce__wkfl_status_stage_type__c = wkflWrapper.analysis.arce__wf_status_id__c;
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_sub_process_type__c = wkflWrapper.analysis.arce__anlys_wkfl_sub_process_type__c;
        wkflWrapper.wkflEvtCurrent.arce__audit_date__c = System.today();
        wkflWrapper.wkflEvtCurrent.arce__user_audit_id__c = System.UserInfo.getUserId();
        wkflWrapper.wkflEvtCurrent.arce__gf_applied_action_type__c = ACTIONS.get(wkflWrapper.action);
        wkflWrapper.wkflEvtCurrent.arce__riskAssessmentId__c = wkflWrapper.accHasAnlysis.Name;
        return actionWkflTraceEvt(wkflWrapper);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Public method that generate traceability event for Analysis ARCE type
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   12/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return Arc_Gen_Traceability_Wrapper wkflWrapper
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflTraceEvt(wkflWrapper);
    **/
    private static Arc_Gen_Traceability_Wrapper actionWkflTraceEvt(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        if (wkflWrapper.action == PROPOSE_PREP || wkflWrapper.action == PROPOSE_SANCTION) {
            actionWkflPropose(wkflWrapper);
        } else if (wkflWrapper.action == SCHEDULE) {
            actionWkflSchedule(wkflWrapper);
        } else if (wkflWrapper.action == REMOVE) {
            actionWkflRemove(wkflWrapper);
        } else if (wkflWrapper.action == RETURNACT) {
            actionWkflReturn(wkflWrapper);
        } else if (wkflWrapper.action == SANCTION) {
            actionWkflSanction(wkflWrapper);
        } else if (wkflWrapper.action == PROPOSEIRP) {
            actionWkflTraceEvtIRP(wkflWrapper);
        } else if (wkflWrapper.action == VALIDATEIRP) {
          actionWkflValidateEvtIRP(wkflWrapper);
        }
        return wkflWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Public method that generate traceability event for IRP analysis
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   03/03/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflTraceEvt(wkflWrapper);
    **/
    private static void actionWkflTraceEvtIRP(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_edit_br_level_type__c = (String) wkflWrapper.mapReqAction.get(FLD_AMBIT);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Public method that generate validate traceability event for IRP analysis
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   19/10/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflValidateEvtIRP(wkflWrapper);
    **/
    private static void actionWkflValidateEvtIRP(Arc_Gen_Traceability_Wrapper wkflWrapper) {
      wkflWrapper.wkflEvtCurrent.arce__wkfl_status_stage_type__c = (String) wkflWrapper.mapReqAction.get(FLD_STATUS);
      wkflWrapper.wkflEvtCurrent.arce__wkfl_stage_type__c = (String) wkflWrapper.mapReqAction.get(FLD_STAGE);
      if(wkflWrapper.wkflEvtCurrent.arce__wkfl_stage_type__c == arce.Arc_Gen_Constants.STAGE_FINALIZED) {
        wkflWrapper.wkflEvtCurrent.arce__stop_time__c = wkflWrapper.wkflEvtCurrent.arce__start_time__c;
      }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fill specific fields for the propose action
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflPropose(wkflWrapper);
    **/
    private static void actionWkflPropose(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        // KPI start event time
        final String ambit = (String) wkflWrapper.mapReqAction.get(FLD_AMBIT);
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_edit_br_level_type__c = ambit;
        final String ownerIdCurrent = (String) wkflWrapper.mapReqAction.get('OwnerId');
        wkflWrapper.wkflEvtCurrent.arce__user_audit_id__c = ownerIdCurrent == null ? System.UserInfo.getUserId() : ownerIdCurrent;
        if (wkflWrapper.action == PROPOSE_SANCTION) {
            wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_snctn_br_level_type__c = wkflWrapper.delegationWrapper.sanctionAmbit;
        } else if (wkflWrapper.action == PROPOSE_PREP) {
            wkflWrapper.wkflEvtCurrent.arce__wkfl_stage_type__c = arce.Arc_Gen_Constants.STAGE_IN_PREPARATION;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fill specific fields for the return action
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflReturn(wkflWrapper);
    **/
    private static void actionWkflReturn(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        // Specific fields for return action
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_edit_br_level_type__c = (String) wkflWrapper.mapReqAction.get(FLD_AMBIT);
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_return_reason_desc__c = (String) wkflWrapper.mapReqAction.get('arce__anlys_wkfl_return_reason_desc__c');
        final String ownerIdCurrent = (String) wkflWrapper.mapReqAction.get('OwnerId');
        wkflWrapper.wkflEvtCurrent.arce__user_audit_id__c = ownerIdCurrent == null ?  System.UserInfo.getUserId() : ownerIdCurrent;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fill specific fields for the schedule action
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflSchedule(wkflWrapper);
    **/
    private static void actionWkflSchedule(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        wkflWrapper.wkflEvtCurrent.arce__gf_anlys_wkfl_committee_type__c = (String) wkflWrapper.mapReqAction.get('committeeValue');
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fill specific fields for the remove action
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflRemove(wkflWrapper);
    **/
    private static void actionWkflRemove(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_discard_reason_id__c = (String) wkflWrapper.mapReqAction.get('arce__anlys_wkfl_discard_reason_id__c');
        wkflWrapper.wkflEvtCurrent.arce__gf_anlys_wkfl_discard_reason_desc__c = (String) wkflWrapper.mapReqAction.get('arce__anlys_wkfl_discard_reason_desc__c');
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fill specific fields for the sanction action
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example Arc_Gen_Traceability_Wrapper wkflWrapper = actionWkflSanction(wkflWrapper);
    **/
    private static void actionWkflSanction(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        wkflWrapper.wkflEvtCurrent.arce__wkfl_risk_expiry_date__c = (Date) wkflWrapper.mapReqAction.get('arce__analysis_risk_expiry_date__c');
        wkflWrapper.wkflEvtCurrent.arce__wkfl_risk_sanction_date__c = (Date) wkflWrapper.mapReqAction.get('arce__analysis_risk_sanction_date__c');
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_edit_br_level_type__c = (String) wkflWrapper.mapReqAction.get(FLD_AMBIT);
        wkflWrapper.wkflEvtCurrent.arce__wkfl_sanction_rsn_desc__c = (String) wkflWrapper.mapReqAction.get('arce__anlys_wkfl_sanction_rsn_desc__c');
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_sanction_rslt_type__c = (String) wkflWrapper.mapReqAction.get('arce__anlys_wkfl_sanction_rslt_type__c');
        wkflWrapper.wkflEvtCurrent.arce__gf_risk_cmtee_sntcn_user_id__c = (String) wkflWrapper.mapReqAction.get('arce__gf_committee_user_id__c');
        wkflWrapper.wkflEvtCurrent.arce__anlys_wkfl_snctn_br_level_type__c = wkflWrapper.analysis.arce__anlys_wkfl_snctn_br_level_type__c;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Update traceability events from wkflWrapper
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   15/02/2021
    * @param  Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example updateTraceEvents(wkflWrapper);
    **/
    public static void updateTraceEvents(Arc_Gen_Traceability_Wrapper wkflWrapper) {
        Arc_Gen_TraceabilityEvents_Data.updateTraceEvents(wkflWrapper);
    }


}