/**
* @File Name          : Arc_Gen_TriageService_service.cls
* @Description        : Contains the logic to call the triage engine
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : eduardoefrain.hernandez.contractor@bbva.com
* @Last Modified On   : 09-11-2020
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    24/7/2019 18:16:47   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    24/4/2020 18:16:47   ricardo.almanza.contractor@bbva.com             Service Name and bank id variables
* 1.2    24/4/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Implement triage call for RAIP
* 1.3    29/4/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Check ARCE not in scope for RAIP.
* 1.4    30/5/2020 12:22:21   juanmanuel.perez.ortiz.contractor@bbva.com      Assign eventType's dinamic value in getTriageParameters method
* 1.5    10/7/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Fix Triage testing and debugs.
* 1.6    23/7/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Fix Triage messages.
* 1.6    03/8/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Orphans.
* 1.7    26/08/2020 13:32:00  juanmanuel.perez.ortiz.contractor@bbva.com      Add method called getAnalysisData
* 1.8    11/25/2020 10:00:00  eduardoefrain.hernandez.contractor@bbva.com     Update conditions to suscribe the bus
* 1.9    21/01/2021        saimassimilianno.jordana.contractor@bbva.com       Modified all getAccountInfoById calls to return the correct accountWrapper if customAccount exists.
* 1.10   22/03/2021 10:00:00  joseluis.garcia4.contractor@bbva.com            Triage response code management (2xx success, else error).
* 1.11   23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.12   10/08/2021           juanignacio.hita.contractor@bbva.com            Changes owner user to current user logged in the request of service
**/
public class Arc_Gen_Triage_service {
    /**
    * @Description: Service response identificator
    */
    public final static String ECONOMIC_PART = 'economicGroupParticipants';
    /**
    * @Description: Service response identificator
    */
    public final static String CALCULATION_REQUEST = 'calculationRequest';
    /**
    * @Description: Service name identificator
    */
    public final static String SERVICENAME = 'triageEngine';
    /**
    * @Description: Bank Id
    */
    public final static String BANKID = '0001';

    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service response and assign the triage fields for an analysis.
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId - Id of the parent ARCE
    * @param String customerId - Group number to call triage
    * @return String - JSON with the service parameters
    * @example public String setServiceParameters(String analysisId, String customerId)
    **/
    public static String setServiceParameters(String analysisId, String customerId) {
        return setServiceParameters(analysisId, customerId, false);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service response and assign the triage fields for a RAIP.
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId - Id of the parent ARCE
    * @param String customerId - Group number to call triage
    * @param Boolean isRaip - true if triage is being called for RAIP, false if analysis
    * @return String - JSON with the service parameters
    * @example public String setServiceParameters(String analysisId, String customerId)
    **/
    public static String setServiceParameters(String analysisId, String customerId, Boolean isRaip) {
        arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_data.getArceAnalysisData(new List<Id>{analysisId})[0];
        List<arce__Account_has_Analysis__c> accHas = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{analysis.Id});
        String clientId = analysis.arce__Group__c;
        if(accHas[0].arce__Analysis__r?.arce__anlys_wkfl_sub_process_type__c == '4') {
            clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHas[0]);
        }
        arce.Arc_Gen_Account_Wrapper analysisGroup = arce.Arc_Gen_Account_Locator.getAccountInfoById(New Id[] {clientId}).get(clientId);
        List<String> laccId = new List<String>();
        laccId.add(analysisGroup.accNumber);
        List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaw = arce.Arc_Gen_AccHasAnalysis_Data.getByARCEandClient(analysisId, laccId);
        arce__Account_has_Analysis__c analyzedClient = Arc_Gen_Triage_helper.getFromWrp(ahaw)[0];//accHasAnlysisByAccNumber
        string customerNumber = String.isBlank(analysisGroup.accNumber) ? analysisGroup.participantParentaccNumber : analysisGroup.accNumber ;
        customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(customerNumber); //todo agregar jhio

        // Get parameters for analysis.
        final Arc_Gen_Triage_helper.TriageParameters parameters = getTriageParameters(analysisGroup, analyzedClient, customerNumber, isRaip);
        return JSON.serialize(parameters,true);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Gets an object with the parameters that should be provided to the triage
    * engine.
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com, joseluis.garcia4.contractor@bbva.com
    * @date 23/04/2019
    * @param arce.Arc_Gen_Account_Wrapper analysisGroup - Id of the group ARCE or account associated with the RAIP.
    * @param arce__Account_has_Analysis__c analyzedClient - Account has analysis object
    * @param String customerNumber - Customer number of the analyzed client.
    * @param Boolean isRaip - Whether is RAIP or not.
    * @return Parameters to provide to the triage engine.
    **/
    private static Arc_Gen_Triage_helper.TriageParameters getTriageParameters(arce.Arc_Gen_Account_Wrapper analysisGroup,arce__Account_has_Analysis__c analyzedClient, String customerNumber, Boolean isRaip) {
        Arc_Gen_Triage_helper.TriageParameters parameters = new Arc_Gen_Triage_helper.TriageParameters();
        final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final String subprocessType = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{analyzedClient.arce__Analysis__c})[0].arce__anlys_wkfl_sub_process_type__c;
        parameters.eventType = arce.Arc_Gen_GenericUtilities.getEventTypeValue(subprocessType);
        parameters.riskAssessmentId = analyzedClient.Name;
        parameters.participantId = customerNumber;
        parameters.businessAgentId = uInfo.userBasicInfo.FederationIdentifier == null ? '' : uInfo.userBasicInfo.FederationIdentifier;
        parameters.participationType = analysisGroup.participantType;
        parameters.bankId = BANKID;
        parameters.branchId = uInfo.branchId;
        parameters.branchLevel = uInfo.branchLevel;
        parameters.financialStatementId = isRaip ? '&financialStatement.id='+analyzedClient.arce__ffss_for_rating_id__r.arce__financial_statement_id__c : '';
        return parameters;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service error responses
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param Map<String, Object> responseMap
    * @return String - The error string
    * @example private static String setParams(String mockCode, String param)
    **/
    private static String setParams(String mockCode, String param) {
        String retParam;
        retParam = String.isNotBlank(mockCode) ? '{"messages":[{"code":"conflict","message":"No fue posible tranformar JSON de respuesta a objeto JAVA","parameters": []}]}' : param;
        return retParam;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service error responses
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param Map<String, Object> responseMap
    * @return String - The error string
    * @example public static String processErrorData(Map<String, Object> responseMap)
    **/
    public static Arc_Gen_Triage_helper.TriageResponse setupTriageService(String analysisId, String parameters, String mockCode) {
        String serviceParameters = setParams(mockCode, parameters);
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<String>{analysisId}).get(0);
        final arce.Arc_Gen_getIASOResponse.serviceResponse response = Arc_Gen_Triage_data.callTriageService(serviceParameters, SERVICENAME);
        Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();
        Boolean serviceError = false;

        triageResp.response = new arce.Arc_Gen_ServiceAndSaveResponse();
        triageResp.response.serviceCode = response.serviceCode;
        triageResp.response.serviceMessage = response.serviceMessage;

        if(response.serviceCode != null && response.serviceCode.startsWith('2')) {
            Map<String, Object> responseMap = response.serviceResponse;
            final Object listServiceResp = (Object)responseMap.get(System.Label.Cls_arce_ServiceRespData);
            final Map<String, Object> data = (Map<String, Object>)listServiceResp;
            final List<Object> economicGroupPart = (List<Object>)data.get('economicGroupParticipants');
            System.debug('economicGroupPart '+economicGroupPart);
            final arce.Arc_Gen_GenericUtilities.SaveResult saveRes = Arc_Gen_Triage_helper.processEconomicPart(economicGroupPart, analysis,'callout', triageResp);
            triageResp.response.saveStatus = saveRes.status;
            triageResp.response.saveMessage = saveRes.message;
            if (triageResp.response.saveMessage == 'noscope') {
                triageResp.groupInScope = 'false';
            }

            arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{analysis});
            Final Map<String, Map<String, String>> contMap = Arc_Gen_Triage_helper.genCtrlMap((List<Object>)data.get('controls'));
            triageResp = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        } else {
            triageResp.response.serviceMessage = JSON.serialize(arce.Arc_Gen_RatingErrorManagement.processErrorData(response, 'TRIAGE'));
            serviceError = true;
        }

        if (!serviceError) {
            triageResp.groupInScope = triageResp.groupInScope == null ? 'false' : triageResp.groupInScope;
            if(triageResp.response.saveStatus == 'errAsync'||(analysis.arce__anlys_wkfl_sub_process_type__c != '4' && triageResp.groupInScope == 'false')) {
                Arc_Gen_Triage_helper.closeArce(analysis, triageResp.response.saveStatus, 'callout');
            }
        }
        Return triageResp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get ARCE data
    --------------------------------------------------------------------------------
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @date 26/08/2020
    * @param String arceId - Id from ARCE
    * @return List<arce__analysis__c>
    * @example public static List<arce__analysis__c> getAnalysisData(String arceId)
    **/
    @AuraEnabled
    public static List<arce__analysis__c> getAnalysisData(String arceId) {
        return arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{arceId});
    }
}