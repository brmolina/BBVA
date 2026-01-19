/**
  * @File Name : Arc_Gen_ScheduleInSanction_Service.cls
  * @Description : Principal logic of schedule button
  * @Author : luisarturo.parra.externo@bbva.com
  * @Group : ARCE - BBVA Bancomer
  * @Last Modified By : juanignacio.hita.contractor@bbva.com
  * @Last Modified On : 30/07/2021
  * @Modification Log :
  *==============================================================================
  * Ver Date Author          Modification
  *==============================================================================
  * 1.0 5/10/2019 ARCE TEAM Creación.
  * 1.1 26/12/2019 juanmanuel.perez.ortiz.contractor@bbva.com   Add logic to send notifications.
  * 1.2 03/03/2020 juanignacio.hita.contractor@bbva.com         Fix updateCoommitteService
  * 1.2 23/09/2020 saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.3 04/12/2020 juanignacio.hita.contractor@bbva.com         Adds aha name (analysisId) param in traceability record
  * 1.4 29/12/2020 joseluis.garcia4.contractor@bbva.com         Force validation in orphan before sanctioning.
  * 1.5 12/02/2021 juanignacio.hita.contractor@bbva.com         Add traceability events funcionality in the workflow
  * 1.6 18/02/2021 joseluis.garcia4.contractor@bbva.com         Include call to action persistence service.
  * 1.7 30/07/2021 juanignacio.hita.contractor@bbva.com         Modifies updateCommitteeService method, on invocation of trace events
  * 1.8 03/12/2021 francisco.munoz.torres.contractor@bbva.com   Remove obligation of validate in HU after Schedule
  **/
public class Arc_Gen_ScheduleInSanction_Service {
    static final String PENDING_SCHE_W_DELEGATION = '05';
    static final String PENDING_DECI_W_DELEGATION = '06';
    static final String PENDING_SCHE_COMMITEE = '07';
    static final String PENDING_SANC_COMMITEE = '08';
    /**
    *-------------------------------------------------------------------------------
    * @description private method to avoid intances
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.externo@bbva.com
    * @date 5/10/2019
    * @param none
    * @return  List < String >
    **/
    @TestVisible
    private Arc_Gen_ScheduleInSanction_Service() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to change values and send arce to be updated
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 5/10/2019
    * @param String committeeValue
    * @param Id recordId
    * @param String committeeDesc
    * @return none
    **/
  public static void updateCommitteeService(String committeeValue, Id recordId, String committeeDesc) {
    final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(recordId, new List<String>{ 'Id', 'Name', 'arce__anlys_wkfl_cnsld_ffss_type__c' });
    arce__Analysis__c arceUp = arce.Arc_Gen_ArceAnalysis_Data.gerArce(recordId);
    final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
    final List<arce__Analysis__c> arceList = New List<arce__Analysis__c>();
    String targetStatus = '';

    if (arceUp.arce__wf_status_id__c == PENDING_SCHE_W_DELEGATION) {
      targetStatus = PENDING_DECI_W_DELEGATION;
    } else if (arceUp.arce__wf_status_id__c == PENDING_SCHE_COMMITEE) {
      targetStatus = PENDING_SANC_COMMITEE;
    }

    // Persist action into Oracle.
    arce.Arc_Gen_ActionsPersistence_Service.persistArceAction(arceUp.Id, arce.Arc_Gen_ActionsPersistence_Service.ACTION_SCHEDULE);

    // Update status and create traceability record.
    arceUp.put('arce__wf_status_id__c', targetStatus);
    arceUp.put('arce__bbva_committees_type__c', committeeValue);
    arceUp.put('arce__num_committes_sanction__c', Arc_Gen_TraceabilityEvents_Helper.controlNumUserCommittes(arceUp, wrpUser.userBasicInfo.Id));

    // Save new changes Analysis
    arceList.add(arceUp);
    arce.Arc_Gen_ArceAnalysis_Data.updateArce(arceList);

    // Action audit record
    String title = System.Label.Arc_Gen_TraceabilityScheduled + ' - ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', 'arce__wf_status_id__c', targetStatus).abbreviate(60);
    String comments = System.Label.Arc_Gen_TraceabilityCommittee.abbreviate(60) + ' : ' + committeeDesc.abbreviate(60);
    final Map<String, String> auditWF = Arc_Gen_Traceability.genAuditWF(wrpUser.ambitUser, '2', targetStatus, 'Arc_Gen_Schedule');
    final Map<String, String> mapAuditAttr = Arc_Gen_Traceability.genAuditAttr(title, 'sendBack', comments, accHasAnalysis.Name);
    Arc_Gen_Traceability.saveTrace(arceUp.Id, mapAuditAttr, auditWF);

    // Create current action traceability event record
    final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
    Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(wrapper, accHasAnalysis, arceUp, 'SCHEDULE');
    wkflWrapper.mapReqAction.put('committeeValue', committeeValue);
    wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

    arce.Arc_Gen_GenericUtilities.createNotifications(Arc_Gen_Notifications_Service.getUsersIds(arceUp.Id), arceUp.Id, System.Label.Arc_Gen_ArceSchedule + ': ' +  arceUp.Name);

    // Insert new trace record and last update
    Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);
  }
}