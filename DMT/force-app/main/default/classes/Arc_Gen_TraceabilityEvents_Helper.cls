/**
* @File Name          : Arc_Gen_TraceabilityEvents_Helper.cls
* @Description        : Helper class for auxiliary methods of the traceability events functionality
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |04/02/2021 juanignacio.hita.contractor@bbva.com
*             Class creation
* -----------------------------------------------------------------------------------------------
**/
public without sharing class Arc_Gen_TraceabilityEvents_Helper {

    /**
    *-------------------------------------------------------------------------------
    * @description Void constructor
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  void
    * @return void
    * @example Arc_Gen_TraceabilityEvents_Helper()
    **/
    @TestVisible
    private Arc_Gen_TraceabilityEvents_Helper () {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets the last trace record and updates the current event flag and the current event start time
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return void
    * @example updateCurrentEvent(wkflWrapper);
    **/
    public static void updateCurrentEvent(Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper) {
        // Update Stop time workflow event
        final List<arce__Traceability_Event__c> lastWkflEvt = Arc_Gen_TraceabilityEvents_Data.getEvtActiveAnalysis(wkflWrapper.analysis.Id, Arc_Gen_TraceabilityEvents_Data.ALL_FIELDS);
        if (lastWkflEvt.isEmpty()) {
            wkflWrapper.wkflEvtCurrent.arce__start_time__c = wkflWrapper.analysis.CreatedDate;
        } else {
            wkflWrapper.wkflEvtLast = lastWkflEvt[0];
            wkflWrapper.wkflEvtLast.arce__current_event__c = false;
            wkflWrapper.wkflEvtCurrent.arce__start_time__c = wkflWrapper.wkflEvtLast.arce__stop_time__c;
        }
        wkflWrapper.wkflEvtCurrent.arce__stop_time__c = DateTime.now();
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Return next traceability code unique from last trace record
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return Integer
    * @example Integer codeInteger = getAutoNumCode(wkflWrapper);
    **/
    public static Integer getAutoNumCode(Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper) {
        Integer autoNum;
        if (wkflWrapper.wkflEvtLast == null) {
            autoNum = 0;
        } else {
            final List<String> lstCode = wkflWrapper.wkflEvtLast.arce__gc_trcblty_internal_code_id__c.split('-');
            final Integer autoNumLast = Integer.valueOf(lstCode[2]);
            autoNum = autoNumLast + 1;
        }
        return autoNum;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Returns text string concatenated with the following code traceability record
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   08/02/2021
    * @param  Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper
    * @return String
    * @example String code = getWkflCode(wkflWrapper);
    **/
    public static String getWkflCode(Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper) {
        return 'T-' + wkflWrapper.analysis.arce__parent_analysis_id__c + '-' + getAutoNumCode(wkflWrapper);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that control the number user sanction counter
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   15/02/2021
    * @param  arce__Analysis__c arce
    * @param  String userId
    * @return String
    * @example Integer ret = controlNumUserSanction(accHas);
    **/
    public static Integer controlNumUserSanction(arce__Analysis__c arceObj, String userId) {
        Integer retNumUser = Integer.valueOf(arceObj.arce__num_users_sanction__c);
        final List<arce__Traceability_Event__c> lstTrace = Arc_Gen_TraceabilityEvents_Data.getEvtByAnlysisUserAction(arceObj.Id, userId, '1');
        if (lstTrace.isEmpty()) {
            if (retNumUser == null) {
                retNumUser = userId == System.UserInfo.getUserId() ? 1 : 2;
            } else {
                retNumUser++;
            }
        }
        return retNumUser;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that control the number user committe counter
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    16/02/2021
    * @param   arce__Analysis__c arce
    * @param   String userId
    * @return  Integer
    * @example Integer ret = controlNumUserCommittes(arce, userId);
    **/
    public static Integer controlNumUserCommittes(arce__Analysis__c arceObj, String userId) {
        Integer retNumUser = Integer.valueOf(arceObj.arce__num_committes_sanction__c);
        final List<arce__Traceability_Event__c> lstTrace = Arc_Gen_TraceabilityEvents_Data.getEvtByAnlysisUserAction(arceObj.Id, userId, '2');
        if (lstTrace.isEmpty()) {
            retNumUser = retNumUser == null ? 1 : retNumUser + 1;
        }
        return retNumUser;
    }
}