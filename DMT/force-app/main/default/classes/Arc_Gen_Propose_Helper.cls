/**
  * @File Name          : Arc_Gen_Propose_Helper.cls
  * @Description        :
  * @Author             : juanignacio.hita.contractor@bbva.com
  * @Group              :
  * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Last Modified On   : 03-14-2024
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    5/7/2019   12:50:32   juanignacio.hita.contractor@bbva.com      Initial Version
  * 1.1    28/02/2019 12:50:32   juanignacio.hita.contractor@bbva.com      Added traceability
  * 1.2    28/02/2019 12:50:32   juanignacio.hita.contractor@bbva.com      Changed status to PENDING_SCHE_W_DELEGATION
  * 1.3    24/03/2020            mariohumberto.ramirez.contractor@bbva.com Added new method updateProposeInPrepDate
  * 1.4    30/03/2019 12:50:32   javier.soto.carrascosar@bbva.com          Fix missing stage value in evaluateDelegationElement for sanction proposetype
  * 1.5    25/05/2020 16:05:00   juanignacio.hita.contractor@bbva.com      Added description in all methods.
  * 1.6    23/06/2020 12:50:32   javier.soto.carrascosa@bbva.com           Update workflow logic
  * 1.7    01/07/2020 12:00:00   javier.soto.carrascosa@bbva.com           Change state of sanction proposeType in evaluateDelegationElement method
  * 1.7    23/09/2020     saimassimilianno.jordana.contractor@bbva.com     Added arce. namespace to all classes that
  *                                                                        are now in the arce-dependencies package
  * 1.8    04/12/2020 10:00:00   juanignacio.hita.contractor@bbva.com      Adds aha name (analysisId) param in traceability record
  * 1.9    18/02/2021 10:00:00   joseluis.garcia4.contractor@bbva.com      Include call to action persistence service.
  * 1.10   12/02/2021 13:00:00   juanignacio.hita.contractor@bbva.com      Add traceability events funcionality in the workflow
  * 1.11   15/07/2021 12:00:00   juanignacio.hita.contractor@bbva.com      Remove call method persistArceAction
  **/
public with sharing class Arc_Gen_Propose_Helper {
  /*
    @Description: Status analysis : Arce Prepared
  */
  static final String ARCE_PREPARED = '03';
  /*
    @Description: Status analysis : Constrasting Analysis
  */
  static final String CONSTRA_ANALYSIS = '04';
  /*
    @Description: Status analysis : PENDING_SCHE_W_DELEGATION
  */
  static final String PENDING_SCHE_W_DELEGATION = '05';
  /*
    @Description: Status analysis : PENDING_DECI_W_DELEGATION
  */
  static final String PENDING_DECI_W_DELEGATION = '06';
  /*
    @Description: Status analysis : Pending Schedule in Committee
  */
  static final String PENDING_SCHE_COMMITEE = '07';
  /*
    @Description: Status analysis : Pending Sanction in Committee
  */
  static final String PENDING_SANC_COMMITEE = '08';
  /*
    @Description: Status analysis : Pending Sanction in Committee
  */
  static final String AMBIT_FLD = 'arce__anlys_wkfl_edit_br_level_type__c';
  /**
  *-------------------------------------------------------------------------------
  * @description Constructor method for sonnar
  *--------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date 15/01/2020
  * @return void
  * @example  private Arc_Gen_Propose_Helper()
  **/
  @TestVisible
  private Arc_Gen_Propose_Helper() {
  }
  /**
  *-------------------------------------------------------------------------------
  * @description    Method that runs the local delegation process of workflow analysis configurated.
  *                 Receives the name of the ambit, an analysis id and a action name as parameters.
  *                 Returns a delegation wrapper object
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  String : ambit to propose
  * @param  Id : recordId id of analysis object
  * @param  String : action
  * @return Arc_Gen_Delegation_Wrapper
  * @example Arc_Gen_Delegation_Wrapper = initDelegation(ambit, analysisId, action);
  **/
  public static Arc_Gen_Delegation_Wrapper initDelegation(String ambit, Id analysisId, String action, Boolean validate) {
    final Arc_Gen_Workflow_Interface workflowController = Arc_Gen_GenericUtilitiesInterface.workflowClass();
    final Arc_Gen_Delegation_Wrapper wrapper = workflowController.getDelegation(ambit, analysisId, action,validate);
    return wrapper;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description    Method that runs the local identification process of workflow analysis configurated.
  *                 Receives the name of the ambit and an analysis. Returns the user identifier calculated.
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  String : ambit to propose
  * @param  Id : recordId id of analysis object
  * @return String with the user id calculated
  * @example String userId = initIdentification(ambit, analysisId);
  **/
  public static String initIdentification(String ambit, Id analysisId) {
    final Arc_Gen_Workflow_Interface workflowController = Arc_Gen_GenericUtilitiesInterface.workflowClass();
    return workflowController.getIdentification(ambit, analysisId);
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  Update the snctn level type field with the sanction ambit
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  Arc_Gen_Delegation_Wrapper : delegation wrapper
  * @return void
  * @example updateSnctnType(wrapper);
  **/
  public static void updateSnctnType(Arc_Gen_Delegation_Wrapper wrapper) {
    Map<String, Object> fieldValueMap = new Map<String, Object>();
    fieldValueMap.put('arce__anlys_wkfl_snctn_br_level_type__c', wrapper.sanctionAmbit);
    arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(wrapper.analysisId, fieldValueMap);
  }
  /**
  *-------------------------------------------------------------------------------
  * @description    Auxiliary method used in the delegation evaluation. Evaluating the different ways: with delegation,
  *                 without delegation or not calculated. Receives the delegation wrapper, acc has analysis id and propose type.
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  Arc_Gen_Delegation_Wrapper : wrapper
  * @param  Id : record id of the account has analysis object
  * @param  String : propose type
  * @return Arc_Gen_Delegation_Wrapper
  * @example Arc_Gen_Delegation_Wrapper wrapper = evaluateDelegation(wrapper, accHasAnalysisId);
  **/
  public static Arc_Gen_Delegation_Wrapper evaluateDelegation(Arc_Gen_Delegation_Wrapper wrapper, Id accHasAnalysisId, String proposeType) {
    Arc_Gen_Delegation_Wrapper newWrapper = new Arc_Gen_Delegation_Wrapper();
    if (wrapper.hasDelegation == 'YES') {
      newWrapper = evaluateDelegationA(wrapper, proposeType, accHasAnalysisId);
    } else if (wrapper.hasDelegation == 'NO' || wrapper.hasDelegation == 'NOTCALCULATED') {
      newWrapper = evaluateDelegationB(wrapper, accHasAnalysisId, proposeType);
    } else {
      newWrapper.codStatus = 500;
      newWrapper.msgInfo = 'Configuration local proposeAction, hasDelegation value not found';
    }
    return newWrapper;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  Auxiliary method used in the delegation evaluation process with delegation.
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  Arc_Gen_Delegation_Wrapper : wrapper
  * @param  String : propose type
  * @return Arc_Gen_Delegation_Wrapper
  * @example Arc_Gen_Delegation_Wrapper wrapper = evaluateDelegationA(wrapper, accHasAnalysisId);
  **/
  public static Arc_Gen_Delegation_Wrapper evaluateDelegationA(Arc_Gen_Delegation_Wrapper wrapper, String proposeType, Id accHasAnalysisId) {
    Map<String, Object> fieldValueMap = new Map<String, Object>();
    String targetStatus = '';
    String targetStage = '';
    String action = '';
    final arce.Arc_Gen_User_Wrapper currentUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
    try {
      if (proposeType == 'SANCTION') {
        targetStatus = PENDING_SCHE_COMMITEE;
        targetStage = '2';
        action = 'Arc_Gen_ProposeInSanction';
      } else if (proposeType == 'PREPARATION') {
        targetStatus = PENDING_SCHE_COMMITEE;
        targetStage = '2';
        action = 'Arc_Gen_ProposeInPreparation';
      }
      fieldValueMap.put('arce__wf_status_id__c', targetStatus);
      fieldValueMap.put('arce__Stage__c', targetStage);
      fieldValueMap.put('arce__proposeUser__c',System.UserInfo.getUserId());
      fieldValueMap.put(AMBIT_FLD, currentUser.ambitUser);

      // Control of the number of different users involved in the Sanction stage
      final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
      fieldValueMap.put('arce__num_users_sanction__c', Arc_Gen_TraceabilityEvents_Helper.controlNumUserSanction(arceVar, System.UserInfo.getUserId()));
      final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(accHasAnalysisId, new List<String>{ 'Id', 'Name', 'arce__anlys_wkfl_cnsld_ffss_type__c' });

      // Save new changes Analysis
      arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(wrapper.analysisId, fieldValueMap);

      final string traceComments = System.Label.Arc_Gen_ProposeToTraceability.abbreviate(60) + ' ' + currentUser.userBasicInfo.Name.abbreviate(60) + ' | ' + System.Label.Arc_Gen_TraceabilityAmbit + ': ' +  arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', 'arce__anlys_wkfl_edit_br_level_type__c', wrapper.lstAmbits[0].get('value'));
      final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_BtnPropose + ' - ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', 'arce__wf_status_id__c', targetStatus).abbreviate(60), 'sendBack', traceComments.abbreviate(255), accHasAnalysis.Name);
      final Map<String, String> auditWF = Arc_Gen_Traceability.genAuditWF(currentUser.ambitUser, '2', targetStatus, action);
      Arc_Gen_Traceability.saveTrace(wrapper.analysisId, auditAttr, auditWF);

      // Create current action traceability event record
      final String wkflProposeType = proposeType == 'SANCTION' ? 'PROPOSE_SANCTION' : 'PROPOSE_PREP';
      Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(wrapper, accHasAnalysis, arceVar, wkflProposeType);
      wkflWrapper.mapReqAction = fieldValueMap;
      wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

      // Insert new trace record and last update
      Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);
      wrapper.codStatus = 201;
      wrapper.msgInfo = System.Label.Arc_Gen_SchedulePropose;
    } catch (Exception e) {
      wrapper.codStatus = 500;
      wrapper.msgInfo = e.getMessage();
    }
    return wrapper;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  Auxiliary method used in the delegation evaluation process without delegation or not calculated
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  Arc_Gen_Delegation_Wrapper : delegation wrapper
  * @param  Id : record id of the account has analysis object
  * @param  String : propose type
  * @return Arc_Gen_Delegation_Wrapper
  * @example Arc_Gen_Delegation_Wrapper wrapper = evaluateDelegationB(wrapper, accHasAnalysisId);
  **/
  public static Arc_Gen_Delegation_Wrapper evaluateDelegationB(Arc_Gen_Delegation_Wrapper wrapper, Id accHasId, String proposeType) {
    Arc_Gen_Delegation_Wrapper wrapperRet = wrapper;
    try {
      if (wrapper.lstAmbits.size() == 1) {
        wrapperRet = evaluateDelegationElement(wrapper, accHasId, proposeType);
      } else if (wrapper.lstAmbits.size() >= 1) {
        wrapperRet.codStatus = 200;
      }
    } catch (Exception e) {
      wrapperRet.codStatus = 500;
      wrapperRet.msgInfo = e.getMessage();
    }
    return wrapperRet;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  Auxiliary method used in the delegation evaluation process without delegation or not calculated. And the ambit list has a single element.
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  Arc_Gen_Delegation_Wrapper : wrapper
  * @param  Id : record id of the account has analysis object
  * @param  String : propose type
  * @return Arc_Gen_Delegation_Wrapper
  * @example evaluateDelegationElement(wrapper, accHasAnalysisId);
  **/
  public static Arc_Gen_Delegation_Wrapper evaluateDelegationElement(Arc_Gen_Delegation_Wrapper wrapper, Id accHasAnalysisId, String proposeType) {
      final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
      final arce.Arc_Gen_User_Wrapper currentUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
      Map<String, Object> fieldValueMap = new Map<String, Object>();
      String identification = initIdentification(wrapper.lstAmbits[0].get('value'), wrapper.analysisId);
      final arce.Arc_Gen_User_Wrapper nextUser = arce.Arc_Gen_User_Locator.getUserInfo(identification);
      String targetStatus = '';
      String targetStage = '';
      String action = '';

      if (proposeType == 'SANCTION') {
        targetStatus = wrapper.lstAmbits[0].get('value') == currentUser.ambitUser ? PENDING_SCHE_COMMITEE : CONSTRA_ANALYSIS;
        targetStage = '2';
        action = 'Arc_Gen_ProposeInSanction';
      } else if (proposeType == 'PREPARATION') {
        targetStatus = CONSTRA_ANALYSIS;
        targetStage = '2';
        action = 'Arc_Gen_ProposeInPreparation';
      }
      fieldValueMap.put('arce__wf_status_id__c', targetStatus);
      fieldValueMap.put('arce__Stage__c', targetStage);
      fieldValueMap.put(AMBIT_FLD, wrapper.lstAmbits[0].get('value'));
      fieldValueMap.put('OwnerId', identification);
      fieldValueMap.put('arce__proposeUser__c',System.UserInfo.getUserId());
      // Control of the number of different users involved in the Sanction stage
      fieldValueMap.put('arce__num_users_sanction__c', Arc_Gen_TraceabilityEvents_Helper.controlNumUserSanction(arceVar, identification));
      final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(accHasAnalysisId, new List<String>{ 'Id', 'Name', 'arce__anlys_wkfl_cnsld_ffss_type__c' });

      // Update status and create traceability record.
      arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(arceVar.Id, fieldValueMap);

      final string traceComments = System.Label.Arc_Gen_ProposeToTraceability.abbreviate(60) + ' ' + nextUser.userBasicInfo.Name + ' | ' + System.Label.Arc_Gen_TraceabilityAmbit + ': ' +  arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', AMBIT_FLD, wrapper.lstAmbits[0].get('value'));
      final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_BtnPropose + ' - ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', 'arce__wf_status_id__c', targetStatus).abbreviate(60), 'sendBack', traceComments, accHasAnalysis.Name);
      final Map<String, String> auditWF = Arc_Gen_Traceability.genAuditWF(currentUser.ambitUser, '2', targetStatus, action);
      Arc_Gen_Traceability.saveTrace(arceVar.Id, auditAttr, auditWF);

      // Create current action traceability event record
      final String wkflProposeType = proposeType == 'SANCTION' ? 'PROPOSE_SANCTION' : 'PROPOSE_PREP';
      Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(wrapper, accHasAnalysis, arceVar, wkflProposeType);
      wkflWrapper.mapReqAction = fieldValueMap;
      wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

      // Insert new trace record and last update
      Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);

      arce.Arc_Gen_GenericUtilities.createNotifications(Arc_Gen_Notifications_Service.getUsersIds(wrapper.analysisId), wrapper.analysisId, System.Label.Arc_Gen_ArcePropose + ': ' + arceVar.Name);

      wrapper.codStatus = 201;
      wrapper.msgInfo = System.Label.Arc_Gen_Record_Update_Success;
      return wrapper;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description set the date of propose in preparation button action
  --------------------------------------------------------------------------------
  * @author mariohumberto.ramirez.contractor@bbva.com
  * @date   24/04/2020
  * @param  Arc_Gen_Delegation_Wrapper : wrapper
  * @return void
  * @example updateProposeInPrepDate(wrapper);
  **/
  public static void updateProposeInPrepDate(Arc_Gen_Delegation_Wrapper wrapper) {
    final List<arce__Analysis__c> arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{wrapper.analysisId});
    arceVar[0].arce__proposal_in_prep_action_date__c =  System.today();
    arce.Arc_Gen_ArceAnalysis_Data.updateArce(arceVar);
  }
  /**
  *-------------------------------------------------------------------------------
  * @description set arce__recalculate_rating__c field value
  --------------------------------------------------------------------------------
  * @author aleksandar.dinkov.contractor@bbva.com
  * @date   08/02/2024
  * @param  String value
  * @return arce.Arc_Gen_GenericUtilities.SaveResult saveResult
  **/
  public static arce.Arc_Gen_GenericUtilities.SaveResult setRecalculateRatingValue(Id ahaId, String value) {
    final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {ahaId})[0];
    aha.arce__recalculate_rating__c = value;
    return arce.Arc_Gen_GenericUtilities.updateRecords(new List<arce__Account_has_Analysis__c>{aha});
  }
}