/**
* @File Name          : Arc_Gen_TriageService_data.cls
* @Description        : Class that process the data of salesforce to the triage service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : eduardoefrain.hernandez.contractor@bbva.com
* @Last Modified On   : 09-11-2020
* @Changes
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    12/8/2019 18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    24/4/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Implement triage call for RAIP
* 1.2    27/4/2020 18:00:36   ricardo.almanza.contractor@bbva.com             Better manage responses for setupTriageService and  variable updates on insertTriageData
* 1.3    29/4/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Fix different TriageResponse objects being used in transaction.
* 1.4    06/5/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Persists primary analysis type into AHA.
* 1.5    13/5/2020 18:00:00   ricardo.almanza.contractor@bbva.com             Account Wrapper.
* 1.6    14/5/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Fixes ARCE always being out of scope and arce__customer_arce_scope_type__c values.
* 1.7    19/5/2020 18:00:00   joseluis.garcia4.contractor@bbva.com            Includes riskSegment in response.
* 1.8    19/5/2020 10:00:00   ricardo.almanza.contractor@bbva.com             TopDown Templates.
* 1.8    25/5/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Fix TopDown Templates.
* 1.9    10/7/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Fix Triage testing and debugs.
* 1.10   23/7/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Messages triage
* 1.11   03/8/2020 10:00:00   ricardo.almanza.contractor@bbva.com             Orphans
* 1.12   11/8/2020 15:00:00   javier.soto.carrascosa@bbva.com                 Update sector field
* 1.13   8/24/2020 10:00:00   eduardoefrain.hernandez.contractor@bbva.com     Adding RAIP rating tool Id managwement
* 1.14   8/25/2020 10:00:00   eduardoefrain.hernandez.contractor@bbva.com     Refactor insertTriageData method
* 1.15   27/8/2020 10:00:00   juanmanuel.perez.ortiz.contractor@bbva.com      Refactorize method setupTriageService
* 1.16   28/8/2020 10:00:00   juanmanuel.perez.ortiz.contractor@bbva.com      Modified getPortfolioValue access level
* 1.17   04/9/2020 10:00:00   ricardo.almanza.contractor@bbva.com             double call Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp); because first one is for control errors and second is for group in scope
* 1.18   11/25/2020 10:00:00  eduardoefrain.hernandez.contractor@bbva.com     Update conditions to suscribe the bus
* 1.19   19/1/2021 15:00:00   brauliobaruchs.sanpedro.contractor@bbva.com     Call method to publish a new event "Close Arce" with a unique characteristics
* 1.20   21/01/2021           saimassimilianno.jordana.contractor@bbva.com    Modified getAccountInfoById calls in insertTriageData and getCustWrps meth0ds to return the correct accountWrapper if customAccount exists.
* 1.21   23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.22   11/25/2020 10:00:00  joseluis.garcia4.contractor@bbva.com            Remove triage validations from optional response parameters.
**/
@SuppressWarnings('PMD.ExcessivePublicCount,sf:TooManyMethods')
public class Arc_Gen_Triage_helper {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/04/2020
    * @param void
    * @return void
    * @example Arc_Gen_Triage_helper()
    **/
    @TestVisible
    private Arc_Gen_Triage_helper() {}
    /**
    * @Description: Service response identificator
    */
    public final static String FINANCIAL_STATEMENT = 'financialStatement';
    /**
    * @Description: Service response identificator
    */
    public final static String ECONOMIC_PART = 'economicGroupParticipants';
    /**
    * @Description: Service response identificator
    */
    public final static String CONSOLIDATED = 'CONSOLIDATED';
    /**
    * @Description: Service response identificator
    */
    public final static String TRUE_TEXT = 'true';
    /**
    * @Description: Service response identificator
    */
    public final static String FALSE_TEXT = 'false';
    /**
    * @Description: Picklist value of the "Bottom-up" primary analysis type.
    */
    public final static String PRIMARY_ANLYS_TYPE_BOTTOM_UP_VALUE = '1';
    /**
    * @Description: Picklist value of the "Top-down" primary analysis type.
    */
    public final static String PRIMARY_ANLYS_TYPE_TOP_DOWN_VALUE = '2';
    /**
    * @Description: Service response of the "Bottom-up" primary analysis type.
    */
    public final static String PRIMARY_ANLYS_TYPE_BOTTOM_UP_TEXT = 'BOTTOM_UP';
    /**
    * @Description: Service response of the "Top-down" primary analysis type.
    */
    public final static String PRIMARY_ANLYS_TYPE_TOP_DOWN_TEXT = 'TOP_DOWN';
    /**
    * @Class: TriageParameters
    * @Description: Wrapper that contain all the rating service parameters
    * @author BBVA
    */
    public class TriageParameters {
        /**
        * @Description: Indicates if the service method is NEW
        */
        public String eventType {get;set;}
        /**
        * @Description: Identificator of the analyzed client (Not the standard Salesforce Id)
        */
        public String riskAssessmentId {get;set;}
        /**
        * @Description: Account Number of the Customer
        */
        public String participantId {get;set;}
        /**
        * @Description: Indicates the participation type that the participant of the analysis
        * has within the Economic Group to which it belongs.
        */
        public String participationType {get;set;}
        /**
        * @Description: Business agent identifier that starts the rating study.
        */
        public String businessAgentId {get;set;}
        /**
        * @Description: Unique bank identifier.
        */
        public String bankId {get;set;}
        /**
        * @Description: Unique branch identifier when the assessment is created.
        */
        public String branchId {get;set;}
        /**
        * @Description: Unique level of branch identifier.
        */
        public String branchLevel {get;set;}
        /**
        * @Description: Financial statement ID (only used for RAIP).
        */
        public String financialStatementId {get;set;}
    }
    /**
    * @Class: TriageResponse
    * @Description: Wrapper that contain all the rating service parameters
    * @author BBVA
    */
    public class TriageResponse {
        /**
        * @Description: Contains the response of the service and the save result of the update process
        */
        @auraEnabled public arce.Arc_Gen_ServiceAndSaveResponse response {get;set;}
        /**
        * @Description: Contains the list of all ARCE not scope clients
        */
        @auraEnabled public List<String> clientsNotInScope {get;set;}
        /**
        * @Description: Indicates if the group is ARCE scope
        */
        @auraEnabled public String groupInScope {get;set;}
        /**
        * @Description: Risk segment of the group
        */
        @auraEnabled public String riskSegment {get;set;}
    }
    @SuppressWarnings('PMD.TooManyFields')
    public class TriageRetrievedData {
        /**
        * @Description: Participant Group or subsidiary number
        */
        public String participantId {get;set;}
        /**
        * @Description: Indicates if the participant is GROUP or SUBSIDIARY
        */
        public String participantType {get;set;}
        /**
        * @Description: Indicates if the participant is ARCE Scope
        */
        public Boolean isInScope {get;set;}
        /**
        * @Description: Indicates the segment of the participant
        */
        public String riskSegment {get;set;}
        /**
        * @Description: Grouping of portfolios into larger segments.
        */
        public String analysisModelType {get;set;}
        /**
        * @Description: Rating tool identifier
        */
        public String ratingToolId {get;set;}
        /**
        * @Description: Sector cyclicity used in the rating process that allows the use of different scales due to the cyclicity of the sector.
        */
        public String cyclicitySectorAxis {get;set;}
        /**
        * @Description: Rating model tool identification (Companies, SMEs and Others) RD1 Ouput. Code that will identify the rating to
        */
        public String ratingModelType {get;set;}
        /**
        * @Description: Unique bank identifier
        */
        public String bankId {get;set;}
        /**
        * @Description: Office of the bank associated with the customer
        */
        public String branchId {get;set;}
        /**
        * @Description: This field is used to determined the template to be displayed in each analysis
        */
        public String template {get;set;}
        /**
        * @Description: Unique identifier for a financial statement of a client
        */
        public String ffssId {get;set;}
        /**
        * @Description: String based on ISO-4217 for specifying the currency of the financial statements
        */
        public String ffssCurrency {get;set;}
        /**
        * @Description: String based on ISO-4217 for specifying the currency of the financial statements
        */
        public String ffssUnits {get;set;}
        /**
        * @Description: Unit in which the time is expressed
        */
        public String periodUnit {get;set;}
        /**
        * @Description: Number of units representing the full period of time between the beginning and the end of a situation
        */
        public Integer periodNumber {get;set;}
        /**
        * @Description: Number of units representing the full period of time between the beginning and the end of a situation
        */
        public String periodType {get;set;}
        /**
        * @Description: String based on ISO-8601 date format for providing the last day of the economic period covered by the financial Statement
        */
        public Date ffssEndDate {get;set;}
        /**
        * @Description: Financial statement type identifier
        */
        public String ffssType {get;set;}
        /**
        * @Description: Sales figure from last valid Financial Statements
        */
        public Decimal salesAmount {get;set;}
        /**
        * @Description: String based on ISO-4217 for specifying the currency
        */
        public String salesCurrency {get;set;}
        /**
        * @Description: dentification of the group/client Analysis for the primary Analysis. This identification will be based on Top down/Bottom Up
        */
        public String primaryAnalysisType {get;set;}
    }
    /**
    * @Description: global triage response variable
    */
    private static TriageResponse triageResp = new TriageResponse();
    /**
*-------------------------------------------------------------------------------
* @description Method that calls the triage service and returns the processed response
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String parameters - JSON with the input parameters
* @param String analysisId - Id of the parent ARCE
* @param String callType - If "callout" -> the process is for synchronous callout. If "callback" ->
* the process is for asynchronous callout and the data will be retrieved by another service
* @return triageResponse - Wrapper with all required responses of the service
* @example public static triageResponse setupTriageService(String analysisId, String parameters)
**/
    public static TriageResponse setupTriageService(arce__Analysis__c arceAnalysis, Map<String, Object> data, String callType) {
        Final Map<String, Map<String, String>> contMap = Arc_Gen_Triage_helper.genCtrlMap((List<Object>)data.get('controls'));
        triageResp = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        if(triageResp.response.saveStatus == 'errAsync') {
            Arc_Gen_Triage_helper.closeArce(arceAnalysis, triageResp.response.saveStatus, callType);
        } else {
            final List<Object> economicGroupPart = (List<Object>)data.get('economicGroupParticipants');
            final arce.Arc_Gen_GenericUtilities.SaveResult saveRes = processEconomicPart(economicGroupPart, arceAnalysis, callType, triageResp);
            triageResp.response.saveStatus = saveRes.status;
            triageResp.response.saveMessage = saveRes.message;
            arceAnalysis.arce__triageStatus__c = '2';
            arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{arceAnalysis});
            triageResp.groupInScope = triageResp.groupInScope == null ? FALSE_TEXT : triageResp.groupInScope;
            triageResp = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
            if(arceAnalysis.arce__anlys_wkfl_sub_process_type__c != '4' && triageResp.groupInScope == 'false') {
                Arc_Gen_Triage_helper.closeArce(arceAnalysis, triageResp.response.saveStatus, callType);
            }
        }
        Return triageResp;
    }
    public static Map<String, Map<String, String>> genCtrlMap(List<Object> controls) {
        Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>();
        if(controls != null) {
            for(Object obj : controls) {
                Map<String, String> contrlsCont = new Map<String, String>();
                Map<String, Object> control = (Map<String, Object>)obj;
                contrlsCont.put(arce.Arc_Gen_GenericUtilities.DESCRIPTION,(String)control.get(arce.Arc_Gen_GenericUtilities.DESCRIPTION));
                contrlsCont.put('isValid',String.valueOf((Boolean)control.get('isValid')));
                contMap.put((String)control.get(arce.Arc_Gen_GenericUtilities.ID_TEXT),contrlsCont);
            }
        }
        return contMap;
    }
    public static Arc_Gen_Triage_helper.TriageResponse cntrlErr(Map<String, Map<String, String>> contMap, Arc_Gen_Triage_helper.TriageResponse triageResp) {
        if (triageResp.response == null ) {
            triageResp.response = new arce.Arc_Gen_ServiceAndSaveResponse();
        }
        Final String errTriag = 'CT016';
        Final String errAsync = 'ERROR';
        if (contMap.containsKey(errTriag) || triageResp.groupInScope == 'false') {
            Map<String, String> contrlsCont = contMap.get(errTriag);
            String valArc;
            try {
                valArc = contrlsCont.get('isValid');
                triageResp.response.saveMessage = contrlsCont.get(arce.Arc_Gen_GenericUtilities.DESCRIPTION);
            } catch(Exception e) {
                valArc = 'true';
                triageResp.response.saveMessage = e.getStackTraceString();
            }
            triageResp.response.saveStatus = valArc.equalsIgnoreCase('true') ? errTriag : 'NotArce';
        }
        if (contMap.containsKey(errAsync)) {
            Map<String, String> contrlsCont = contMap.get(errAsync);
            String valArc = contrlsCont.get('isValid');
            triageResp.response.saveStatus = valArc.equalsIgnoreCase('true') ? errAsync : 'errAsync';
            triageResp.response.saveMessage = contrlsCont.get(arce.Arc_Gen_GenericUtilities.DESCRIPTION);
        }
        System.debug('ss '+triageResp.response.saveStatus);
        return triageResp;
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that process the service response and assign the triage fields
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param List<Object> economicGroupPart - List of participations retrieved by the service
* @param arce__Analysis__c analysis - Parent ARCE previously created
* @param String callType - If "callout" -> the process is for synchronous callout. If "callback" ->
* the process is for asynchronous callout and the data will be retrieved by another service
* @return Arc_Gen_DMLOperations_data.saveResult - Wrapper with the result of the Mini Arce's update
* @example public static Arc_Gen_DMLOperations_data.saveResult processEconomicPart(List<Object> economicGroupPart, arce__Analysis__c analysis)
**/
    public static arce.Arc_Gen_GenericUtilities.SaveResult processEconomicPart(List<Object> economicGroupPart, arce__Analysis__c analysis, String callType, TriageResponse triageResp) {

        List<TriageRetrievedData> triageWrapperList = new List<TriageRetrievedData>();
        Map<String, TriageRetrievedData> triageDataMap = new Map<String, TriageRetrievedData>();
        for(Object obj : economicGroupPart) {
            Map<String, Object> participant = (Map<String, Object>)obj;
            TriageRetrievedData triageObject = setTriageData(participant);
            if(callType == 'callback') {
                validateRequiredData(triageObject);
            }
            triageDataMap.put(triageObject.participantId, triageObject);
            triageWrapperList.add(triageObject);
        }

        List<arce__Account_has_Analysis__c> accHas = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{analysis.Id});
        String clientId = analysis.arce__Group__c;
        if(accHas[0].arce__Analysis__r?.arce__anlys_wkfl_sub_process_type__c == '4') {
            clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHas[0]);
        }
        // Check if group is in scope.
        arce.Arc_Gen_Account_Wrapper groupInfo = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { clientId }).get(clientId);
        String encAccNum = arce.Arc_Gen_CallEncryptService.getEncryptedClient(groupInfo.accNumber);
        List<String> encryptedIds = new List<String>();
        encryptedIds.addAll(triageDataMap.keyset());
        List<String> decryptedIds = arce.Arc_Gen_CallEncryptService.getDecryptedClients(encryptedIds);
        List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaw = arce.Arc_Gen_AccHasAnalysis_Data.getByARCEandClient(String.valueOf(analysis.Id), decryptedIds);
        List<arce__Account_has_Analysis__c> analyzedClients = getFromWrp(ahaw);//accHasAnlysisByAccNumber
        Boolean isOrph = analyzedClients.size() == 1 && encryptedIds.size() == 1;
        if (triageDataMap.containsKey(encAccNum)|| isOrph) {
            TriageRetrievedData groupRetrievedData = isOrph ? triageDataMap.get(encryptedIds[0]) : triageDataMap.get(encAccNum);
            triageResp.groupInScope = String.valueOf(groupRetrievedData.isInScope);
            triageResp.riskSegment = groupRetrievedData.riskSegment;
        }
        Map<String,String> participantsMap = new Map<String,String>();

        for(Integer i = 0; i < encryptedIds.size(); i ++) {
            participantsMap.put(encryptedIds[i],decryptedIds[i]);
        }

        if(callType == 'callout') {
          assignTriageStatus(analysis,accHas,analyzedClients);
        }

        return insertTriageData(triageWrapperList, participantsMap, analyzedClients, triageResp);
    }


/**
*-------------------------------------------------------------------------------
* @description Method that assings value to triage status field based on GADRDCDE-2289 logic
--------------------------------------------------------------------------------
* @author jose.hijar.contractor@bbva.com
* @date 05/09/2021
* @param arce__Analysis__c analysis - Parent ARCE previously created
* @param List<arce__Account_has_Analysis__c> list of all aHas related to analysis
* @param arce__Analysis__c analysis - List of ahas related to analysis corresponding with clientes provided by service
* @return void
* @example private static void assignTriageStatus(arce__Analysis__c analysis, List<arce__Account_has_Analysis__c> accHas, List<arce__Account_has_Analysis__c> analyzedClients)
**/
    private static void assignTriageStatus(arce__Analysis__c analysis, List<arce__Account_has_Analysis__c> accHas, List<arce__Account_has_Analysis__c> analyzedClients){

    //if (Boolean.valueOf(triageResp.groupInScope)) {
      Boolean allClientsInResponse = true;
      Integer c=0;
      if(!accHas.isEmpty()){
        while (allClientsInResponse && c < accHas.size()) {
          if (!clientInAhas(accHas[c].Id, analyzedClients)) {
            allClientsInResponse = false;
          }
          c++;
        }
      }
      if (allClientsInResponse) {
        analysis.arce__triageStatus__c = '2';
      } else {
        analysis.arce__triageStatus__c = '1';
      }
      // }else {
        //   analysis.arce__triageStatus__c = '1';
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Search for an aHa inside a list of aHas and returns true if is found
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 05/09/2021
    * @param Id - Id of searched aHa
    * @param List<arce__Account_has_Analysis__c> list of all aHas related to analysis
    * @return Boolean True if provided aHa is inside the list
    * @example private static void assignTriageStatus(arce__Analysis__c analysis, List<arce__Account_has_Analysis__c> accHas, List<arce__Account_has_Analysis__c> analyzedClients)
    **/
    private static Boolean clientInAhas(Id clientAhaId, List<arce__Account_has_Analysis__c> aHas){
      Boolean found=false;
      Integer c = 0;
      do {
        if (aHas[c].Id == clientAhaId) {
          found=true;
        }
        c++;
      } while (!found && c < aHas.size());

      return found;
    }

    /**
*-------------------------------------------------------------------------------
* @description Method that obtains the service response and sets the response wrapper
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param Map<String, Object> participant - Object of participant retrieved  by JSON response
* @param arce__Analysis__c analysis - Parent ARCE object
* @return Arc_Gen_TriageService_helper - Wrapper with all fields of the service response
* @example public static Arc_Gen_TriageService_helper setTriageData(Map<String, Object> participant, arce__Analysis__c analysis)
**/
    public static List<arce__Account_has_Analysis__c> getFromWrp (List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> wrapper) {
        List<arce__Account_has_Analysis__c> ret = new List<arce__Account_has_Analysis__c>();
        for (arce.Arc_Gen_Account_Has_Analysis_Wrapper current: wrapper){
            ret.add(current.ahaObj);
        }
        return ret;
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that obtains the service response and sets the response wrapper
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param Map<String, Object> participant - Object of participant retrieved  by JSON response
* @param arce__Analysis__c analysis - Parent ARCE object
* @return Arc_Gen_TriageService_helper - Wrapper with all fields of the service response
* @example public static Arc_Gen_TriageService_helper setTriageData(Map<String, Object> participant, arce__Analysis__c analysis)
**/
    private static void validateRequiredData(TriageRetrievedData triageObject) {
        List<Map<String,String>> nullDataList = new List<Map<String,String>>();
        nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('participant-id',triageObject.participantId,nullDataList);
        nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('isInScope',triageObject.isInScope,nullDataList);
        if (triageObject.ffssId != null) {
            nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('period-unit-id',triageObject.periodUnit,nullDataList);
            nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('period-number-id',triageObject.periodNumber,nullDataList);
            nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('totalRevenues-amount',triageObject.salesAmount,nullDataList);
            nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('totalRevenues-currency',triageObject.salesCurrency,nullDataList);
            nullDataList = Arc_Gen_AsyncTriage_helper.checkForNulls('financialStatement-currency',triageObject.ffssCurrency,nullDataList);
        }
        if(!nullDataList.isEmpty()) {
            throw new Arc_Gen_AsyncTriage_helper.InvalidParametersException(Json.serializePretty(Arc_Gen_AsyncTriage_helper.setErrorResponse(Arc_Gen_AsyncTriage_helper.MISSING_PARAMS_CODE,Arc_Gen_AsyncTriage_helper.URL_MISSING_PARAMS, nullDataList), true));
        }
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to return string 0 when null
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-22
    * @param    cntPrAn AggregateResult where to get variable
    * @param    varName String Name of the variable
    * @return   String Decimal with format on string or 0
    * @example  notNull(cntPrAn,'val1')
    * */
    private static String notNullStr(Object comp,String val) {
        Boolean nullobj = comp == null;
        String val2 = nullobj ? '' : (String)getMapFromObject(comp).get(val);
        return nullobj ? '' : val2;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to return string 0 when null
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-22
    * @param    cntPrAn AggregateResult where to get variable
    * @param    varName String Name of the variable
    * @return   String Decimal with format on string or 0
    * @example  notNull(cntPrAn,'val1')
    * */
    private static Object notNullMapObj(Object comp) {
        return comp == null ? null : getMapFromObject(comp);
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to return string 0 when null
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-22
    * @param    cntPrAn AggregateResult where to get variable
    * @param    varName String Name of the variable
    * @return   String Decimal with format on string or 0
    * @example  notNull(cntPrAn,'val1')
    * */
    private static Object notNullObj(Map<String, Object> comp,String val) {
        return comp == null ? null : getObjectFromJson(comp,val);
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains the service response and sets the response wrapper
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param Map<String, Object> participant - Object of participant retrieved  by JSON response
* @param arce__Analysis__c analysis - Parent ARCE object
* @return Arc_Gen_TriageService_helper - Wrapper with all fields of the service response
* @example public static Arc_Gen_TriageService_helper setTriageData(Map<String, Object> participant, arce__Analysis__c analysis)
**/
    private static TriageRetrievedData setTriageData(Map<String, Object> participant) {
        TriageRetrievedData triageWrapper = new TriageRetrievedData();
        triageWrapper.participantId = (String)participant.get(arce.Arc_Gen_GenericUtilities.ID_TEXT);
        triageWrapper.isInScope = (Boolean)participant.get('isInScope');
        triageWrapper.riskSegment = (String)participant.get('riskSegment');
        triageWrapper.participantType = (String)getMapFromObject(getObjectFromJson(participant,'participantType')).get(arce.Arc_Gen_GenericUtilities.ID_TEXT);
        Object objAMT = getObjectFromJson(participant,'analysisModelType');
        triageWrapper.analysisModelType = notNullStr(objAMT, arce.Arc_Gen_GenericUtilities.ID_TEXT);
        Object objRTI = getObjectFromJson(participant,arce.Arc_Gen_GenericUtilities.RATING_TEXT);
        Map<String, Object> mapRTI = (Map<String, Object>) notNullMapObj(objRTI);
        Object objRTI1 = notNullObj(mapRTI, 'tool');
        triageWrapper.ratingToolId = notNullStr(objRTI1, arce.Arc_Gen_GenericUtilities.ID_TEXT);
        Object objCyc = getObjectFromJson(participant,arce.Arc_Gen_GenericUtilities.RATING_TEXT);
        triageWrapper.cyclicitySectorAxis = notNullStr(objCyc, 'cyclicitySectorAxis');
        Object objRMT = getObjectFromJson(participant,arce.Arc_Gen_GenericUtilities.RATING_TEXT);
        Map<String, Object> mapRMT = (Map<String, Object>) notNullMapObj(objRMT);
        Object objRMT1 = notNullObj(mapRMT, 'modelType');
        triageWrapper.ratingModelType = notNullStr(objRMT1, arce.Arc_Gen_GenericUtilities.ID_TEXT);
        final Map<String, Object> bankObject = getMapFromObject(getObjectFromJson(participant,'bank'));
        setBankData(triageWrapper, bankObject);
        triageWrapper.template = (String)participant.get('template');
        final Map<String, Object> ffssObject = getMapFromObject(getObjectFromJson(participant,FINANCIAL_STATEMENT));
        setFfssData(triageWrapper, ffssObject);
        triageWrapper.primaryAnalysisType = getPrimaryAnalysisTypeValue((String)participant.get('primaryAnalysisType'));
        Return triageWrapper;
    }
/**
*-------------------------------------------------------------------------------
* @description Fills the triageWrapper with bank data.
--------------------------------------------------------------------------------
* @author joseluis.garcia4.contractor@bbva.com
* @date 06/05/2020
* @param TriageRetrievedData triageWrapper - Triage wrapper
* @param Map<String, Object> bankObject - Service response JSON
**/
    private static void setBankData(TriageRetrievedData triageWrapper, Map<String, Object> bankObject) {
        if (bankObject != null) {
            triageWrapper.bankId = (String)bankObject.get(arce.Arc_Gen_GenericUtilities.ID_TEXT);
            triageWrapper.branchId = bankObject.containsKey('branch') ? (String)getMapFromObject(getObjectFromJson(bankObject,'branch')).get(arce.Arc_Gen_GenericUtilities.ID_TEXT) : '';
        }
    }
/**
*-------------------------------------------------------------------------------
* @description Fills the triageWrapper with FFSS data.
--------------------------------------------------------------------------------
* @author joseluis.garcia4.contractor@bbva.com
* @date 06/05/2020
* @param TriageRetrievedData triageWrapper - Triage wrapper
* @param Map<String, Object> bankObject - Service response JSON
**/
    private static void setFfssData(TriageRetrievedData triageWrapper, Map<String, Object> ffssObject) {
        if (ffssObject != null) {
            triageWrapper.ffssId = (String)ffssObject.get(arce.Arc_Gen_GenericUtilities.ID_TEXT);
            triageWrapper.ffssCurrency = (String)ffssObject.get(arce.Arc_Gen_GenericUtilities.CURRENCY_TEXT);
            triageWrapper.ffssUnits = (String)ffssObject.get('unit');

            final Map<String, Object> periodObject = getMapFromObject(getObjectFromJson(ffssObject,'period'));
            setPeriodData(triageWrapper, periodObject);

            triageWrapper.ffssType = ffssObject.containsKey('financialStatementType') ? (String)getMapFromObject(getObjectFromJson(ffssObject,'financialStatementType')).get(arce.Arc_Gen_GenericUtilities.ID_TEXT) : '';
            triageWrapper.salesAmount = (Decimal)getMapFromObject(getObjectFromJson(ffssObject,'totalRevenues')).get('amount');
            triageWrapper.salesCurrency = (String)getMapFromObject(getObjectFromJson(ffssObject,'totalRevenues')).get(arce.Arc_Gen_GenericUtilities.CURRENCY_TEXT);
        }
    }
/**
*-------------------------------------------------------------------------------
* @description Fills the triageWrapper with period data.
--------------------------------------------------------------------------------
* @author joseluis.garcia4.contractor@bbva.com
* @param TriageRetrievedData triageWrapper - Triage wrapper
* @param Map<String, Object> bankObject - Service response JSON
**/
    private static void setPeriodData(TriageRetrievedData triageWrapper, Map<String, Object> periodObject) {
        triageWrapper.periodUnit = (String)periodObject.get('unit');
        triageWrapper.periodNumber = Integer.valueOf(periodObject.get('number'));
        triageWrapper.periodType = periodObject.containsKey('periodType') ? (String)getMapFromObject(getObjectFromJson(periodObject,'periodType')).get(arce.Arc_Gen_GenericUtilities.ID_TEXT) : '';
        if (periodObject.containsKey('endDate')) {
            triageWrapper.ffssEndDate = Date.valueOf((String)periodObject.get('endDate'));
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the value to set in the picklist ANLYS_WKFL_CNSLD_FFSS_TYPE field
    * given the value provided by the service (either "BOTTOM_UP" or "TOP_DOWN").
    --------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 06/05/2020
    * @param String serviceValue - The value retrieved from the triage engine.
    * @return The picklist value (1 or 2).
    **/
    private static String getPrimaryAnalysisTypeValue(String serviceValue) {
        String value = '';
        if (serviceValue == PRIMARY_ANLYS_TYPE_BOTTOM_UP_TEXT) {
            value = PRIMARY_ANLYS_TYPE_BOTTOM_UP_VALUE;
        } else if (serviceValue == PRIMARY_ANLYS_TYPE_TOP_DOWN_TEXT) {
            value = PRIMARY_ANLYS_TYPE_TOP_DOWN_VALUE;
        }

        return value;
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that gets an object from a JSON and convert it in a salesforce object
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param Map<String, Object> jsonArray - Array of the JSON
* @param String key - Keyword map
* @return Object - Salesforce object
* @example public static Object getObjectFromJson(Map<String, Object> jsonArray, String key)
**/
    public static Object getObjectFromJson(Map<String, Object> jsonArray, String key) {
        Return (Object)jsonArray.get(key);
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets an object from a JSON and convert it in a salesforce object
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param Object jsonObject - Generated Object by the getObjectFromJson method
* @return Map<String, Object> - map of the json array
* @example public static Map<String, Object> getMapFromObject(Object jsonObject)
**/
    public static Map<String, Object> getMapFromObject(Object jsonObject) {
        Return (Map<String, Object>)jsonObject;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains the portfolio value
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String riskSegment - Value obtained from the service
* @return String - Translated key to the salesforce field value
* @example public static String getPortfolioValue(String riskSegment)
**/
    public static String getPortfolioValue(String riskSegment) {
        String portfolioValue;
        Switch on riskSegment {
            when 'SOVEREIGNS' {
                portfolioValue = '1';
            }
            when 'FINANCIAL_INSTITUTIONS' {
                portfolioValue = '2';
            }
            when 'SPECIALIZED_LENDING' {
                portfolioValue = '4';
            }
            when 'REAL_ESTATE_DEVELOPERS' {
                portfolioValue = '6';
            }
            when 'SMALL_OR_MEDIUM_SIZE_COMPANIES' {
                portfolioValue = '8';
            }
            when 'ENTERPRISES' {
                portfolioValue = '9';
            }
            when 'WITHOUT_SALES' {
                portfolioValue = '11';
            }
        }
        Return portfolioValue;
    }

/**
*-------------------------------------------------------------------------------
* @description Method that gets the sector key based on the template retrieved by the service
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String template - number of template
* @return String - Sector key
* @example public static String getPortfolioValue(String riskSegment)
**/
    public static String getTemplateSector(String template) {
        String templateSector;
        Switch on template {
            when '1' {
                templateSector = 's-01';
            }
            when '2' {
                templateSector = 's-02';
            }
            when else {
                templateSector = '';
            }
        }
        Return templateSector;
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that change the stage of the Parent ARCE to Finished and the status to Finished
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param arce__Analysis__c analysis - Parent ARCE object
* @return Void
* @example public static void closeArce(arce__Analysis__c analysis)
**/
    public static void closeArce(arce__Analysis__c analysis, String reason, String callType) {
        analysis.arce__Stage__c = '3';
        analysis.arce__wf_status_id__c = '10';
        analysis.arce__triageStatus__c = reason == 'errAsync' ? '3' : '4';
        arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{analysis});
        if(callType == 'callback') {
            List<arceMessage__e> triageEvent = new List<arceMessage__e>();
            String arceScopeString = reason;
            triageEvent.add(new arceMessage__e (AnalysisId__c=analysis.Id, Status__c =arceScopeString));
            // Call method to publish events
            EventBus.publish(triageEvent);

            // Call method to publish a new event "Close Arce" with a unique characteristics
            final List<arce__Analysis__c> arceList = New List<arce__Analysis__c>();
            arceList.add(analysis);
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(arceList);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(analysis.Id, new List<String>{ 'Id', 'Name' });
            final string traceComments = Label.Arc_Gen_ErrTriage;
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_ArceRemoveTitle, 'sanction', traceComments.abbreviate(255), accHasAnalysis.Name);
            final Map<String, String> auditWF = new Map<String, String>();
            Arc_Gen_Traceability.saveTrace(analysis.Id, auditAttr, auditWF);
            arce.Arc_Gen_GenericUtilities.createNotifications(Arc_Gen_Notifications_Service.getUsersIds(analysis.Id), analysis.Id, System.Label.Arc_Gen_ArceRemove + ': ' + analysis.Name);
        }
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that change the stage of the Parent ARCE to Finished and the status to Finished
--------------------------------------------------------------------------------
* @author ricardo.almanza.contractor@bbva.com
* @date 12/5/2020
* @param List<arce__Account_has_Analysis__c> analyzedClients - List of Mini Arce's previously created
* @return Map<Id,arce.Arc_Gen_Account_Wrapper> wrapper
* @example final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrap = getCustWrps(analyzedClients);
**/
    private static Map<Id,arce.Arc_Gen_Account_Wrapper> getCustWrps(List<arce__Account_has_Analysis__c> analyzedClients) {
        final List<Id> clientsIds = new List<Id>();
        for(arce__Account_has_Analysis__c acc : analyzedClients) {
            clientsIds.add(arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(acc));
        }
        return arce.Arc_Gen_Account_Locator.getAccountInfoById(clientsIds);
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that process the service response and assign the triage fields
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param List<Arc_Gen_TriageService_helper> triageWrapperList - A list of response wrapper
* @param Map<String,String> participantsMap - Map with the encrypted client number corresponding with the no encrypted client number
* @param List<arce__Account_has_Analysis__c> analyzedClients - List of Mini Arce's previously created
* @return Arc_Gen_DMLOperations_data.saveResult - Wrapper with the result of the Mini Arce's update
* @example public static Arc_Gen_DMLOperations_data.saveResult insertTriageData(List<Arc_Gen_TriageService_helper> triageWrapperList,  Map<String,String> participantsMap, List<arce__Account_has_Analysis__c> analyzedClients)
**/
    private static arce.Arc_Gen_GenericUtilities.SaveResult insertTriageData(List<TriageRetrievedData> triageWrapperList, Map<String,String> participantsMap, List<arce__Account_has_Analysis__c> analyzedClients, TriageResponse triageResp) {

        final Map<String, arce__Account_has_Analysis__c> analysisMap = new Map<String, arce__Account_has_Analysis__c>();
        final List<arce__Account_has_Analysis__c> recordsToUpdate = new List<arce__Account_has_Analysis__c>();
        final List<String> noScopeList = new List<String>();
        final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrap = getCustWrps(analyzedClients);
        for(arce__Account_has_Analysis__c acc : analyzedClients) {
            analysisMap.put(mapWrap.get(arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(acc)).accNumber, acc);
        }
        for(TriageRetrievedData obj : triageWrapperList) {
            arce__Account_has_Analysis__c analysis = analysisMap.get(participantsMap.get(obj.participantId));
            if(analysis != null) {
                final arce__Account_has_Analysis__c accHasAnToUp = new arce__Account_has_Analysis__c(Id = analysis.Id);
                if(setTriageResult(obj, triageResp)) {
                    noScopeList.add(participantsMap.get(obj.participantId));
                }
                accHasAnToUp.arce__Portfolio_class_type__c = getPortfolioValue(obj.riskSegment);
                accHasAnToUp.arce__customer_arce_scope_type__c = getCustomerArceScopeType(obj.isInScope);
                accHasAnToUp.arce__analysis_model_entity_type__c = obj.analysisModelType;
                accHasAnToUp.arce__analysis_template_id__c = obj.template;
                accHasAnToUp.arce__anlys_wkfl_cnsld_ffss_type__c = obj.primaryAnalysisType;
                Boolean raipInfo = setRatingToolTemplate(analysis, obj.ratingToolId);
                if(!raipInfo) {
                    accHasAnToUp.arce__RAR_rating_tool_id__c = obj.ratingToolId;
                }
                recordsToUpdate.add(accHasAnToUp);
            }
        }
        triageResp.clientsNotInScope = noScopeList;
        arce.Arc_Gen_GenericUtilities.SaveResult ins = arce.Arc_Gen_GenericUtilities.updateRecords(recordsToUpdate);
        setResponse(ins, triageResp);
        return ins;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the value to set in the arce__customer_arce_scope_type__c field.
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 24/08/2020
    * @param arce.Arc_Gen_GenericUtilities.SaveResult ins - Analyzed client record
    * @param TriageResponse triageResp - Service Response wrapper
    * @return void
    * @example setResponse(arce__Account_has_Analysis__c aha)
    **/
    private static void setResponse(arce.Arc_Gen_GenericUtilities.SaveResult ins, TriageResponse triageResp) {
        if(ins != null) {
            arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
            if(ins.status == TRUE_TEXT) {
                response.saveMessage = 'exito';
            } else if (triageResp.groupInScope == 'false') {
                response.saveMessage = 'noscope';
            } else {
                response.saveMessage = ins.message;
            }
            triageResp.response = new arce.Arc_Gen_ServiceAndSaveResponse();
            triageResp.response = response;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the value to set in the arce__customer_arce_scope_type__c field.
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 24/08/2020
    * @param arce__Account_has_Analysis__c aha - Analyzed client record
    * @return void
    * @example setRatingToolTemplate(arce__Account_has_Analysis__c aha)
    **/
    private static Boolean setRatingToolTemplate(arce__Account_has_Analysis__c aha, String ratingTool) {
        Boolean resp = false;
        if(aha.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c == '4') {
            Arc_Gen_RatingAsIndepProcess_service.persistRatingModel(aha.id, ratingTool, aha.arce__Analysis__r.arce__rating_prerating_type__c, '');
            resp = true;
        }
        return resp;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the value to set in the arce__customer_arce_scope_type__c field.
    --------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 14/05/2020
    * @param Boolean isInScope - Whether or not the customer is ARCE scope.
    * @return String - The value to set to the arce__customer_arce_scope_type__c field.
    **/
    private static String getCustomerArceScopeType(Boolean isInScope) {
        return isInScope ? '1' : '2';
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that process the service response and assign the triage fields
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param Arc_Gen_TriageService_helper obj - A wrapper item
* @return Boolean - Indicates if the selected object is not arce scope
* @example private static Boolean setTriageResult(Arc_Gen_TriageService_helper obj)
**/
    private static Boolean setTriageResult(TriageRetrievedData obj, TriageResponse triageResp) {
        Boolean ret;
        if(obj.participantType == Label.Cls_arce_PathGroup) {
            triageResp.groupInScope = String.valueOf(obj.isInScope);
            ret = false;
        } else {
            ret = !obj.isInScope;
        }
        return ret;
    }
}