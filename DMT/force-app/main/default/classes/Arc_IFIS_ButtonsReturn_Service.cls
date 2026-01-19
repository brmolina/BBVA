/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsReturn_Service
* @Author         marcos.gimeno.next@bbva.com
* @Date           30-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for Arc_IFIS_ButtonsReturn.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 30-08-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_IFIS_ButtonsReturn_Service {
    /** @description Variable status schedule action workflow delegation**/
    static final String STAGE_FIELD = 'arce__Stage__c';
    /** @description Variable status schedule action workflow delegation**/
    static final String STATUS_FIELD = 'arce__wf_status_id__c';
    /** @description Variable schedule action**/
    static final String ACTION_SCHEDULE = 'Arc_Gen_Schedule';
    /** @description Variable ownerId**/
    static final String OWNER_ID = 'OwnerId';
    /**
    *-------------------------------------------------------------------------------
    * @description Method that evaluate identification funcionality
    * --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-01-20
    * @param   String accHasAnalysisId
    * @param   Object wrapper
    * @param   String userId
    * @param   String reason
    * @return  Arc_Gen_Delegation_Wrapper
    * @example public Arc_Gen_Delegation_Wrapper evaluateIdentification(accHasAnalysisId, wrapper, userId, reason);
    **/
    public static Arc_IFIS_Buttons_Wrp.DelegationWrapper evaluateIdentification(
        Id ahaId,
        Object wrapper,
        String reason
    ) {
        final String userId = UserInfo.getUserId();
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);

        Arc_IFIS_Buttons_Wrp.DelegationWrapper delegationWrp = (Arc_IFIS_Buttons_Wrp.DelegationWrapper) JSON.deserialize(
            JSON.serialize(wrapper),
            Arc_IFIS_Buttons_Wrp.DelegationWrapper.class
        );
        final Map<String, Object> fieldValueMap = new Map<String, Object>{
            'arce__anlys_wkfl_return_reason_desc__c' => reason,
            'arce__anlys_wkfl_edit_br_level_type__c' => delegationWrp.lstAmbits[0].get('value'),
            STATUS_FIELD => arce.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING,
            OWNER_ID => userId
        };
        fieldValueMap.put(STAGE_FIELD, arce.Arc_Gen_Constants.STAGE_IN_PREPARATION);
        fieldValueMap.put(STATUS_FIELD, arce.Arc_Gen_Constants.RAIP_STATUS_PREPARING);

        arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(analysis.Id, fieldValueMap);

        if (delegationWrp.codStatus == new arce.Arc_Gen_CustomServiceMessages().CODE_200) {
            Arc_IFIS_Buttons_Helper.sendNotifications(analysis.Id, System.Label.arce.Arc_IFIS_BtnReturn_Notification);
            setTraceability(analysis, delegationWrp.ambit, reason, userId);
            delegationWrp.msgInfo = System.Label.arce.Arc_IFIS_BtnReturn_Success;
        }

        return delegationWrp;
    }
    /**
    * -------------------------------------------------------------------------------
    * @description setTraceability
    * --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-01-20
    * @param   arce__Analysis__c arceAnalysis
    * @param   String reason
    * @param   String userId
    * @return  void
    * @example setTraceability(arceAnalysis, reason, userId);
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void setTraceability(
        arce__Analysis__c analysis, 
        String selectedAmbit,
        String reason,
        String assignedUser
    ) {
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(assignedUser);
        final string traceComments =
            System.Label.arce.Arc_IFIS_ReturnToTrace +
            ': ' +
            wrpUser.userBasicInfo.Name.abbreviate(60) +
            ' | ' +
            System.Label.arce.Arc_IFIS_ReturnReasonTrace +
            ' ' +
            reason;

        final arce.Arc_IFIS_Traceability.AuditWF auditWFWrap = new arce.Arc_IFIS_Traceability.AuditWF();
        auditWFWrap.ambit = selectedAmbit;
        auditWFWrap.stage = arce.Arc_Gen_Constants.STAGE_IN_SANCTION;
        auditWFWrap.status = arce.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING;
        auditWFWrap.action = '';

        arce.Arc_IFIS_Traceability.saveStatusEvent(
            analysis.Id,
            'Returned',
            traceComments.abbreviate(255),
            arce.Arc_IFIS_Traceability.genAuditWF(auditWFWrap)
        );
    }
}