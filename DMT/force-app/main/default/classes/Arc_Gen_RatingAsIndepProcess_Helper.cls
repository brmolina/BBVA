/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_Helper
* @Author   isabel.ascaso.tech@bbva.com
* @Date     Created: 2025-07-09
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for Rating as Independent Process (RAIP) helper methods.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2025-07-09 isabel.ascaso.tech@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.EmptyStatementBlock')
public with sharing class Arc_Gen_RatingAsIndepProcess_Helper { 
    static final String FINAL_STAGE = Arc_Gen_ConfigUtils.getConfigBoolean('RAIPSelectWorkflow') == true ? '14' : '10';
    /**
    * @Description: String with value for STAGE_CLOSED in ARCE
    */
    static final String STAGE_CLOSED = '3';
    /**
    * @Description: String with value for REASON_PICK in ARCE
    */
    static final String REASON_PICK = '2';
    public Arc_Gen_RatingAsIndepProcess_Helper() {

    }
    /**
    *-------------------------------------------------------------------------------------------------------------
    * @Description method to delete the arce and related record
    *-------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @param ahaId - Id of the account_has_analysis
    * @example deleteARCE(recordId) {
    *-------------------------------------------------------------------------------------------------------------
    **/
    public static void cancelARCE(String ahaId) {
        try {
            final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
            final arce__Analysis__c arceUp = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
            arceUp.put('arce__wf_status_id__c', FINAL_STAGE);
            arceUp.put('arce__Stage__c', STAGE_CLOSED);
            arceUp.put('arce__anlys_wkfl_discard_reason_id__c', REASON_PICK);
            arceUp.put('arce__anlys_wkfl_discard_reason_desc__c', System.Label.Arc_Gen_NoSalesEngine);
            final List<arce__Analysis__c> arceList = New List<arce__Analysis__c>();
            arceList.add(arceUp);

            // Create current action traceability event record
            Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(null, ahaList[0], arceUp, 'REMOVE');
            wkflWrapper.mapReqAction.put('arce__anlys_wkfl_discard_reason_id__c', REASON_PICK);
            wkflWrapper.mapReqAction.put('arce__anlys_wkfl_discard_reason_desc__c', System.Label.Arc_Gen_NoSalesEngine);
            wkflWrapper.mapReqAction.put('arce__anlys_wkfl_discard_reason_desc__c', System.Label.Arc_Gen_NoSalesEngine);
            wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

            arce.Arc_Gen_ArceAnalysis_Data.updateArce(arceList);

            final string traceComments = Label.Cls_arce_ReturnReason + ' ' + System.Label.Arc_Gen_NoSalesEngine;
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_ArceRemoveTitle, 'deny', traceComments.abbreviate(255), ahaList[0].Name);
            final Map<String, String> auditWF = new Map<String, String>();
            final dwp_cvad__Action_Audit__c event = Arc_Gen_Traceability.saveTrace(arceUp.Id, auditAttr, auditWF);
            System.debug('cancelARCE ' + event);
            // Insert new trace record and last update
            Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);
        } catch (Exception e) {
            System.debug(loggingLevel.ERROR, e);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that finalizes a prerating.
    *-------------------------------------------------------------------------------
    * @date 2020-05-07
    * @author joseluis.garcia4.contractor@bbva.com
    * @param String arceId - ID of the ARCE record.
    */

    public static void finalizePrerating(String arceId) {
        try {
            // Finalize RAIP and set discard reason.
            final String discardReason = System.Label.Arc_Gen_FinalizePreratingDiscardReason;
            final arce__Analysis__c analysisToUpdate = new arce__Analysis__c(
                Id = arceId,
                arce__Stage__c = '3',
                arce__wf_status_id__c = '13',
                arce__anlys_wkfl_discard_reason_id__c = discardReason,
                arce__end_date__c = System.today()
            );
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { analysisToUpdate });

            // Create traceability record.
            final List<arce__Account_has_Analysis__c> lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId);
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(discardReason, 'approve', discardReason, lstAccHas[0].Name);
            final Map<String, String> auditWF = new Map<String, String>();
            Arc_Gen_Traceability.saveTrace(arceId, auditAttr, auditWF);
        } catch(DmlException ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ErrorSumPersOR);  // NOSONAR
        } catch(Exception ex) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to validatePrerating.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 30/11/2021
    * @author amunguia.contractor@bbva.com
    * @example validatePrerating(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */

    public static void validatePrerating(String arceId) {
        if(Arc_Gen_ConfigUtils.getConfigBoolean('RAIPValidatePrerating')) {
            final arce.Arc_Gen_ServiceAndSaveResponse response;
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId)[0];
            //Get local class from config.
            response = Arc_Gen_ValidateRating_service.setupValidateRating(aha.Id, aha.arce__ffss_for_rating_id__r.arce__rating_id__c, null, false);
            if(response.serviceCode != '200') {
                throw new AuraHandledException(System.Label.Arc_Gen_ValidatePrerating);  // NOSONAR
            }
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that call local service risk filter
    *-------------------------------------------------------------------------------
    * @date   2020-12-18
    * @author juanignacio.hita.contractor@bbva.com
    * @param  String customerId
    * @param  String arceId
    * @return Arc_Gen_ServiceAndSaveResponse
    * @example Arc_Gen_ServiceAndSaveResponse callRiskFilter(customerId, arceId);
    */

    public static arce.Arc_Gen_ServiceAndSaveResponse callRiskFilter(String customerId, String arceId) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            if(!Test.isRunningTest() && Arc_Gen_ConfigUtils.getConfigBoolean('RAIPRiskFilter')) {
            response = Arc_Gen_RiskFilters_Service.calloutService(new Map<String, Object> {'customerId' => customerId, 'analysisId' => arceId});
          }
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
        return response;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Verify if the new SelectModel 2012 is activated and get options from it.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 01/06/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example model2012Active();
    *---------------------------------------------------------------------------------------------------------------------
    */

    public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> model2012Active(String raipType) {
        final String mtdName = raipType == 'AnalysisCorp' ? 'IRPModelsAvailable' : 'Model2012IRP';
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(mtdName);

        if (!configs.isEmpty() && configs[0].arce__Value1__c != Arc_Gen_RatingAsIndepProcess_controller.FALSE_LITERAL) {
            final String configWf = configs[0].arce__Value1__c;
            for (String current : configWf.split(';')) {
                final List<String> keyValue = current.split(':');
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(keyValue[0], keyValue[1]));
            }
        }

        return wfValues;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Check in RatingTypeByModel arceconfig which options are available for rating type.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example checkRatingType(analysisId, modelSelec);
    *---------------------------------------------------------------------------------------------------------------------
    */

    public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> checkRatingType(String analysisId, String modelSelec, Boolean eeffButton) {
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RatingTypeByModel');
        final String modelToVerify = eeffButton ? arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)analysisId})[0].arce__RAR_rating_tool_id__c : modelSelec;

        if (!configs.isEmpty() && configs[0].arce__Value1__c != Arc_Gen_RatingAsIndepProcess_controller.FALSE_LITERAL && String.isNotBlank(modelToVerify)) {
            final String woutFlow = modelToVerify.replaceAll('[iacIAC]+rpsubsidiary|[IAC]+RPSUBSIDIARY|[iacIAC]+rpgroup|[IAC]+RPGROUP|[iacIAC]+rp|[IAC]+RP','');
            final String configWf = configs[0].arce__Value1__c;
            for (String current : configWf.split(';')) {
                final List<String> keyValue = current.split(':');
                if (woutFlow.equals(keyValue[0])) {
                    addToWfValue(wfValues, keyValue[1].split(','));
                }
            }
        } else {
            wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(Arc_Gen_RatingAsIndepProcess_controller.PRERATING_VALUE, Arc_Gen_RatingAsIndepProcess_controller.PRERATING_LABEL));
            wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL, Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL));
        }

        return wfValues;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Helper method for addToWfValue.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example addToWfValue(wfValues, ratings);
    *---------------------------------------------------------------------------------------------------------------------
    */

    public static void addToWfValue(List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues, List<String> ratings) {
        for (String current : ratings) {
            if(current.equalsIgnoreCase(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL)) {
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL, Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL));
            } else if (current.equalsIgnoreCase(Arc_Gen_RatingAsIndepProcess_controller.PRERATING_VALUE)) {
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(Arc_Gen_RatingAsIndepProcess_controller.PRERATING_VALUE, Arc_Gen_RatingAsIndepProcess_controller.PRERATING_LABEL));
            }
        }
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Return rating buttons options with step triage custom interface.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date   2/11/2021
    * @author juanignacio.hita.contractor@bbva.com
    * @param  String analysisId
    * @param  String ratingTool
    * @param  String interName
    * @return List<WfValue>
    * @example List<WfValue> wfVal = checkRatingToolId(analysisId, modelSelec, interName);
    *---------------------------------------------------------------------------------------------------------------------
    */

    public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> checkRatingToolId(String analysisId, String ratingTool, String interName) {
        final Arc_Gen_IRPFlowCustom_Interface impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow(interName);
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<String> ratings = impl.checkRatingToolId(analysisId, ratingTool);
        if(ratings.contains(Arc_Gen_RatingAsIndepProcess_controller.PRERATING_LABEL)) {
            wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(Arc_Gen_RatingAsIndepProcess_controller.PRERATING_VALUE, Arc_Gen_RatingAsIndepProcess_controller.PRERATING_LABEL));
        }
        if(ratings.contains(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL)) {
            wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL, Arc_Gen_RatingAsIndepProcess_controller.RATING_LABEL));
        }
        return wfValues;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description calls triage engine.
    *--------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-04-23
    * @param analysisId ID of the analysis
    * @param customerId ID of customer
    * @return Service results
    **/

    public static arce.Arc_Gen_ServiceAndSaveResponse callTriage(String analysisId, String customerId) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            final String param = Arc_Gen_Triage_service.setServiceParameters(analysisId, customerId, true);
            final Arc_Gen_Triage_helper.triageResponse resp = Arc_Gen_Triage_service.setupTriageService(analysisId, param, '');

            // Check if ARCE is in scope.
            final Boolean scopeArce = Boolean.valueOf(resp.groupInScope);
            if (!scopeArce) {
                // Client is not scope of ARCE, finalize raip.
                Arc_Gen_RatingAsIndepProcess_service.finalizeRaip(analysisId, resp.response);
            }

            // Build response.
            final Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('arceInScope', scopeArce);
            responseMap.put('riskSegment', resp.riskSegment);
            resp.response.serviceMessage = JSON.serialize(responseMap);

            response = resp.response;
        } catch (Exception ex) {
            response.serviceMessage = System.Label.Lc_arce_NewARCE_UnexpectedError;
            response.saveStatus = '500';
        }
        return response;
    }

}