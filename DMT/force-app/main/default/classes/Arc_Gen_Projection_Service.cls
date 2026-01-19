/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Projection_Service
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 21/05/2023
* @Group    ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 03-05-2025
* @Description Arc_Gen_Projection_Service
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
*/
@SuppressWarnings('PMD.ExcessiveParameterList, sf:CyclomaticComplexity, sf:AvoidUsingTestIsRunningTest')
public with sharing class Arc_Gen_Projection_Service {
    /**
    * @Description: Map<String, String> SCENARIO_MAPPING
    */
    private final static Map<String, String> SCENARIO_MAPPING = new Map<String, String>{ 'BASE' => 'Base Case', 'BASE_MODIFICATION' => 'Base Case', 'UPSIDE_MODIFICATION' => 'Up', 'DOWNSIDE_MODIFICATION' => 'Down', 'DOWNSIDE' => 'Down', 'UPSIDE' => 'Up', 'CLONE' => 'CLONE'};
    /**
    * @Description: List<arce__Projection__c> oldProjList
    */
    static List<arce__Projection__c> oldProjList = new List<arce__Projection__c>();
    /**
    * @Description: List<SObject> projListToInsert
    */
    static List<SObject> projListToInsert = new List<SObject>();
    /**
    * @Description: List<arce__Projection__c> projListToClone
    */
    static List<arce__Projection__c> projListToClone = new List<arce__Projection__c>();
    /**
    * @description Literal value: Projection
    **/
    final static String PROJECTION_VALUE = 'Projection';
    /**
    * @description Literal value: Up
    **/
    final static String UP_VALUE = 'Up';
    /**
    * @description Literal value: Down
    **/
    final static String DOWN_VALUE = 'Down';
    /**
    * @description Literal value: BASE
    **/
    final static String BASE_VALUE = 'BASE';
    /**
    * @description Literal value: Anchor
    **/
    final static String ANCHOR_VALUE = 'Anchor';
    /**
    * @description Literal value: PROJECTION_STATEMENT
    **/
    final static String PROJ_STM_VALUE = 'PROJECTION_STATEMENT';
    /**
    * @description Literal value: PROJECTION TYPE FIELD
    **/
    final static String PROJ_TYPE = 'arce__Projection_Type__c';
    /**
    * @description Literal value: PROJECTION SCENA TYPE FIELD
    **/
    final static String PROJ_SC_TYPE = 'arce__Scenario_Type__c';
    /**
    * @description Literal value: PROJECTION HEADER FIELD
    **/
    final static String PROJ_HEADER = 'arce__Projection_Header__c';
    /**
    * @description Literal value: BASE_MODIFICATION
    **/
    final static String BASE_MOD_VALUE = 'BASE_MODIFICATION';
    /**
    * @description Literal value: MODIFICATION
    **/
    final static String MOD_VALUE = 'MODIFICATION';
    /**
    * @description Literal value: Base Case
    **/
    final static String BASE_CASE_VALUE = 'Base Case';
    /**
    * @description Literal value: Clone Value
    **/
    final static String SCEN_CLONE = 'CLONE';
    /**
    * @description Empty constructor to avoid SonarQube warning.
    **/
    @TestVisible
    private Arc_Gen_Projection_Service() {
    }

    /**
    * @description call projection service
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param String scenarioType
    * @param List<arce__Projection__c> projectionsList
    * @param Set<String> financialStatemIds
    * @return Arc_Gen_Projection_ServiceWrapper
    **/
    public static arce.Arc_Gen_Projection_ServiceWrapper callProjection(String scenarioType, String ahaId, Set<String> ffssIds, String proposalId) {
        final String serviceName = Test.isRunningTest() ? scenarioType == BASE_CASE_VALUE && !ffssIds.isEmpty() ? 'projectionsBaseMock' : 'projectionsModMock' : 'projections';
        arce.Arc_Gen_Projection_ServiceWrapper srvWrapper = new arce.Arc_Gen_Projection_ServiceWrapper(scenarioType, ahaId, ffssIds, proposalId);
        final Map<String, String> params = new Map<String, String>();
        params.put('riskAssessmentId', srvWrapper.request.riskAssessmentId);
        params.put('participantId', srvWrapper.request.participantId);
        params.put('jsonInput', srvWrapper.request.jsonInput);
        arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse = new arce.Arc_Gen_getIASOResponse.ServiceResponse();
        sResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(serviceName, JSON.serialize(params));
        if ('200' == sResponse.serviceCode || (Test.isRunningTest() && '201' == sResponse.serviceCode)) {
            srvWrapper = processProjectionResp(ahaId, sResponse, srvWrapper, scenarioType, proposalId);
        } else {
            srvWrapper.addMessage(sResponse.serviceCode, sResponse.serviceCode, sResponse.serviceMessage);
        }
        return srvWrapper;
    }

    /**
    * @description Process projections service response
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param arce.Arc_Gen_getIASOResponse.ServiceResponse sResp
    * @param arce.Arc_Gen_Projection_ServiceWrapper srvWrap
    * @return Arc_Gen_Projection_ServiceWrapper
    **/
    private static arce.Arc_Gen_Projection_ServiceWrapper processProjectionResp(String ahaId, arce.Arc_Gen_getIASOResponse.ServiceResponse sResp, arce.Arc_Gen_Projection_ServiceWrapper srvWrapper, String internalScenType, String proposalId) {
        arce.Arc_Gen_Projection_ServiceWrapper srvWrap = srvWrapper;
        final Map<String, String> mappingFieldsMap = new Map<String, String>();
        final Map<String, String> baseFieldsMap = new Map<String, String>();
        final Map<String, String> calcFieldsMap = new Map<String, String>();
        final Map<String, String> pctFieldsMap = new Map<String, String>();
        final List<arce__Projections__mdt> mdtList = arce.Arc_Gen_Projection_Data.getAllProjectionsMdt();
        for (arce__Projections__mdt mdt : mdtList) {
            mappingFieldsMap.put(mdt.arce__id__c, mdt.arce__Map_field__c);
            baseFieldsMap.put(mdt.arce__id__c, mdt.arce__Base_field__c);
            calcFieldsMap.put(mdt.arce__id__c, mdt.arce__Calc_field__c);
            pctFieldsMap.put(mdt.arce__id__c, mdt.arce__Percentage_Map__c);
        }

        final Map<String, Object> data = (Map<String, Object>)sResp.serviceResponse;
        final Map<String, String> replacementKeys = new Map<String, String>{ 'currency' => 'currencyX', 'number' => 'numberX' };
        final String parsedKeysJson = arce.Arc_Gen_Projection_ServiceWrapper.replaceJsonKeys(JSON.serialize(data.get('data')), replacementKeys);
        final ProjectionJsonWrapper respJsonWrapper = (ProjectionJsonWrapper)JSON.deserialize(parsedKeysJson, ProjectionJsonWrapper.class);

        oldProjList.addAll(proposalId == null ? arce.Arc_Gen_Projection_Data.getProjByAhaScenProjType(ahaId, new Set<String>{ SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id) }, PROJECTION_VALUE) : arce.Arc_Gen_Projection_Data.getProjByAhaScenProjTypeProposal(proposalId, new Set<String>{ SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id) }, PROJECTION_VALUE));

        for (Integer index = 0; index < respJsonWrapper.statements.size(); index++) {
            generateNewProjection(respJsonWrapper, index, mappingFieldsMap, pctFieldsMap, baseFieldsMap, ahaId, calcFieldsMap, proposalId);
        }

        cloneBaseScenProjections(respJsonWrapper, ahaId, proposalId);
        srvWrap = cloneModScenProjections(srvWrap, ahaId, internalScenType, respJsonWrapper, proposalId);

        srvWrap = arce.Arc_Gen_Projection_Data.insertRecords(projListToInsert, srvWrap);
        if (srvWrap == null || srvWrap.messageList == null || srvWrap.messageList.isEmpty()) { 
            srvWrap = arce.Arc_Gen_Projection_Data.deleteRecords(oldProjList, srvWrap);
        }
        return srvWrap;
    }

    /**
    * @description generateNewProjection
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param arce.Arc_Gen_Projection_ServiceWrapper.ProjectionJsonWrapper respJsonWrapper
    * @param Integer i
    * @param Map<String, String> amountFieldsMapping
    * @param Map<String, String> pctFieldsMapping
    **/
    @SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
    private static void generateNewProjection(ProjectionJsonWrapper respJsonWrapper, Integer index, Map<String, String> mappingFieldsMap, Map<String, String> pctFieldsMap, Map<String, String> baseFieldsMap, String ahaId, Map<String, String> calcFieldsMap, String proposalId) {
        if (PROJ_STM_VALUE == respJsonWrapper.statements[index].statementType.id) {
            final SObject projObj = new arce__Projection__c();
            if (BASE_VALUE == respJsonWrapper.scenarioType.id && index == 0) {
                projObj.put(PROJ_TYPE, ANCHOR_VALUE);
                projObj.put(PROJ_SC_TYPE, SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id));
                projObj.put(PROJ_HEADER, ANCHOR_VALUE + ': ' +respJsonWrapper.statements[index].period.endDate);
            } else if (BASE_VALUE == respJsonWrapper.scenarioType.id) {
                projObj.put(PROJ_TYPE, PROJECTION_VALUE);
                projObj.put(PROJ_SC_TYPE, SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id));
                projObj.put(PROJ_HEADER, respJsonWrapper.statements[index].period.endDate);

            } else if (SCEN_CLONE == respJsonWrapper.scenarioType.id){
                cloneProcessResponse(index, respJsonWrapper, projObj);
            } else {
                projObj.put(PROJ_TYPE, PROJECTION_VALUE);
                projObj.put(PROJ_HEADER, respJsonWrapper.statements[index].period.endDate);
                projObj.put(PROJ_SC_TYPE, SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id));
            }
            if (proposalId == null) {
                projObj.put('arce__Account_has_Analysis__c', ahaId);
            } else {
                projObj.put('arce__Proposal_Folder_Id__c', proposalId);
            }
            projObj.put('arce__Projection_Id__c', respJsonWrapper.statements[index].id); 

            final arce__Account_has_Analysis__c aha = (arce__Account_has_Analysis__c) arce.Arc_Gen_ParentSubsidiary_utils.getSObjectInfo( 'arce__Account_has_Analysis__c',  ahaId, new List<String>{'arce__AHA_Extension__r.arce__Undrawn_debt_Currency__c'});
            projObj.put('arce__SelectedCurrency__c', aha.arce__AHA_Extension__r.arce__Undrawn_debt_Currency__c);
            projObj.put('arce__Statement_Currency__c', respJsonWrapper.statements[index].currencyX);
            projObj.put('arce__SelectedCurrency__c', respJsonWrapper.statements[index].currencyX);
            projObj.put('arce__FinancialStatement_Type__c', respJsonWrapper.statements[index].financialStatementType.id);
            projObj.put('arce__Period_StartDate__c', respJsonWrapper.statements[index].period.startDate);
            projObj.put('arce__Period_EndDate__c', respJsonWrapper.statements[index].period.endDate);

            for (SpecificRatiosMagnitudes srm : respJsonWrapper.statements[index].calculations.specificRatiosMagnitudes) {
                if (String.isNotBlank(mappingFieldsMap.get(srm.id))) {
                    projObj.put(mappingFieldsMap.get(srm.id), String.valueOf(Decimal.valueOf(srm.totalAmount.amount)));
                }
                if (String.isNotBlank(baseFieldsMap.get(srm.id))) {
                    projObj.put(baseFieldsMap.get(srm.id), String.valueOf(Decimal.valueOf(srm.totalAmount.amount)));
                }
                if (String.isNotBlank(calcFieldsMap.get(srm.id))) {
                    projObj.put(calcFieldsMap.get(srm.id), String.valueOf(Decimal.valueOf(srm.totalAmount.amount)));
                }
                if (String.isNotBlank(pctFieldsMap.get(srm.id))) {
                    projObj.put(pctFieldsMap.get(srm.id), srm.percentage);
                }
            }
            if (!oldProjList.isEmpty() && respJsonWrapper.scenarioType.id.contains(MOD_VALUE)) {
                projObj.put('arce__Edit_Base_Case__c', oldProjList[0].arce__Edit_Base_Case__c);
                projObj.put('arce__Projection_Criteria__c', oldProjList[0].arce__Projection_Criteria__c);
                projObj.put('arce__Scenario_Comment__c', oldProjList[0].arce__Scenario_Comment__c);
                projObj.put('arce__SelectedCurrency__c', oldProjList[0].arce__SelectedCurrency__c);
            }
            projListToInsert.add(projObj);
            if (PROJECTION_VALUE == projObj.get(PROJ_TYPE) && SCEN_CLONE != respJsonWrapper.scenarioType.id) {
                projListToClone.add((arce__Projection__c)projObj);
            }
        }
    }

    /**
    * @description cloneBaseScenProjections
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param arce.Arc_Gen_Projection_ServiceWrapper.ProjectionJsonWrapper respJsonWrapper
    * @param String ahaId
    **/
    private static void cloneBaseScenProjections(ProjectionJsonWrapper respJsonWrapper, String ahaId, String proposalId) {
        if (BASE_VALUE == respJsonWrapper.scenarioType.id || SCEN_CLONE == respJsonWrapper.scenarioType.id) {
            for (arce__Projection__c upProj : projListToClone.deepClone(false, true, false)) {
                upProj.arce__Scenario_Type__c = UP_VALUE;
                upProj.arce__Confirmed_Projection__c = false;
                upProj.arce__Scenario_Comment__c = '';
                projListToInsert.add(upProj);
            }
            for (arce__Projection__c downProj : projListToClone.deepClone(false, true, false)) {
                downProj.arce__Scenario_Type__c = DOWN_VALUE;
                downProj.arce__Confirmed_Projection__c = false;
                downProj.arce__Scenario_Comment__c = '';
                projListToInsert.add(downProj);
            }
            oldProjList.clear();
            oldProjList.addAll(proposalId == null ? arce.Arc_Gen_Projection_Data.getProjByAhaScenProjType(ahaId, new Set<String>{ SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id) }, ANCHOR_VALUE) : arce.Arc_Gen_Projection_Data.getProjByAhaScenProjTypeProposal(proposalId, new Set<String>{ SCENARIO_MAPPING.get(respJsonWrapper.scenarioType.id) }, ANCHOR_VALUE));
            oldProjList.addAll(proposalId == null ? arce.Arc_Gen_Projection_Data.getProjByAhaScenProjType(ahaId, new Set<String>{ UP_VALUE, DOWN_VALUE, BASE_CASE_VALUE }, PROJECTION_VALUE) : arce.Arc_Gen_Projection_Data.getProjByAhaScenProjTypeProposal(proposalId, new Set<String>{ UP_VALUE, DOWN_VALUE, BASE_CASE_VALUE }, PROJECTION_VALUE));
        }
    }

    /**
    * @description cloneModScenProjections
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param arce.Arc_Gen_Projection_ServiceWrapper srvWrap
    * @param String ahaId
    * @param String internalScenarioType
    * @return Arc_Gen_Projection_ServiceWrapper
    **/
    public static arce.Arc_Gen_Projection_ServiceWrapper cloneModScenProjections(arce.Arc_Gen_Projection_ServiceWrapper srvWrapper, String ahaId, String internalScenType, ProjectionJsonWrapper respJsonWrapper, String proposalId) {
        arce.Arc_Gen_Projection_ServiceWrapper srvWrap = srvWrapper;
        final Arc_Gen_Projection_Helper.ControlrAnalysisWrapper checkWrapper = Arc_Gen_Projection_Helper.checkControlValues(ahaId, internalScenType, false, proposalId);
        if (BASE_MOD_VALUE == respJsonWrapper.scenarioType.id && (!checkWrapper.controlValues.get(UP_VALUE) || !checkWrapper.controlValues.get(DOWN_VALUE))) {
            final List<arce__Projection__c> actualUpDownList = new List<arce__Projection__c>();
            if (!checkWrapper.controlValues.get(UP_VALUE)) {
                actualUpDownList.addAll(proposalId == null ? arce.Arc_Gen_Projection_Data.getProjByAhaScenProjType(ahaId, new Set<String>{ UP_VALUE }, PROJECTION_VALUE) : arce.Arc_Gen_Projection_Data.getProjByAhaScenProjTypeProposal(proposalId, new Set<String>{ UP_VALUE }, PROJECTION_VALUE));
                for (arce__Projection__c upProj : projListToClone.deepClone(false, true, false)) {
                    upProj.arce__Scenario_Type__c = UP_VALUE;
                    upProj.arce__Confirmed_Projection__c = false;
                    upProj.arce__Scenario_Comment__c = '';
                    projListToInsert.add(upProj);
                }
            }
            if (!checkWrapper.controlValues.get(DOWN_VALUE)) {
                actualUpDownList.addAll(proposalId == null ? arce.Arc_Gen_Projection_Data.getProjByAhaScenProjType(ahaId, new Set<String>{ DOWN_VALUE }, PROJECTION_VALUE) : arce.Arc_Gen_Projection_Data.getProjByAhaScenProjTypeProposal(proposalId, new Set<String>{ DOWN_VALUE }, PROJECTION_VALUE));
                for (arce__Projection__c downProj : projListToClone.deepClone(false, true, false)) {
                    downProj.arce__Scenario_Type__c = DOWN_VALUE;
                    downProj.arce__Confirmed_Projection__c = false;
                    downProj.arce__Scenario_Comment__c = '';
                    projListToInsert.add(downProj);
                }
            }
            srvWrap = arce.Arc_Gen_Projection_Data.deleteRecords(actualUpDownList, srvWrap);
        }
        return srvWrap;
    }

    /**
    * @description call IASO
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param String ahaId
    * @return Arc_Gen_Projection_ServiceWrapper
    **/
    @SuppressWarnings('sf:EmptyIfStmt, sf:DUDataflowAnomalyAnalysis')
    public static arce.Arc_Gen_Projection_ServiceWrapper callProjectionRating(String ahaId, String projectionId) {
        final arce.Arc_Gen_Projection_ServiceWrapper srvWrapper = new arce.Arc_Gen_Projection_ServiceWrapper();
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ ahaId })[0];
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final arce.Arc_Gen_RatingGlobal_helper.HelperParameters helperWrapper = new arce.Arc_Gen_RatingGlobal_helper.HelperParameters(accHasAnalysis, null, arce.Arc_Gen_RatingGlobal_Constants.PROJECTION_STANDALONE);
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper analyzedClient = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String>{ accHasAnalysis.Id })[0];
        helperWrapper.setBankId(analyzedClient.accWrapperObj.bankId);
        helperWrapper.setProjectionId(projectionId);
        if (Test.isRunningTest()) {
            helperWrapper.mockCode = 'projectionStandaloneMock';
        }

        final String fstValidType = accHasAnalysis.arce__ffss_for_rating_id__r.arce__ffss_valid_type__c;
        final String subprocessType = accHasAnalysis.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c;

        if ((fstValidType == '1' && helperWrapper.participantId != System.Label.Cls_arce_GRP_glbError) || subprocessType == '4') {
            response = arce.Arc_Gen_RatingGlobal_helper.calcRating(helperWrapper);
            if (checkResponseCode(response.serviceCode)) {
                // Its ok, nothing to do here...
            } else {
                srvWrapper.addMessage(response.serviceCode, 'Projection Rating error', response.serviceMessage);
            }
        } else {
            final String message = helperWrapper.participantId == System.Label.Cls_arce_GRP_glbError ? System.Label.Cls_arce_EncryptClientError : System.Label.Lc_arce_NoValidFFSS;
            srvWrapper.addMessage('500', arce.Arc_Gen_RatingGlobal_Constants.ERROR_TEXT, message);
        }
        return srvWrapper;
    }

    /**  
    * @description checkForValidState
    * @author aleksandar.dinkov.contractor@bbva.com 
    * @param String statusCode
    * @return Boolean
    **/
    private static Boolean checkResponseCode(String statusCode) {
        return statusCode == arce.Arc_Gen_RatingGlobal_Constants.SUCC1 || statusCode == arce.Arc_Gen_RatingGlobal_Constants.SUCC2 || statusCode == arce.Arc_Gen_RatingGlobal_Constants.SUCC3;
    }

    /**
    * @description call clone projection service
    * @author joseluis.miralles.techr@bbva.com
    * @param String scenarioType
    * @param Set<String> financialStatemIds
    * @return Arc_Gen_Projection_ServiceWrapper
    **/
    public static arce.Arc_Gen_Projection_ServiceWrapper callCloneProjection(String scenarioType, String ahaId, String proposalId) {
        arce.Arc_Gen_Projection_ServiceWrapper srvWrapper = new arce.Arc_Gen_Projection_ServiceWrapper(scenarioType, ahaId, null, proposalId);
        final Map<String, String> params = new Map<String, String>();
        params.put('riskAssessmentId', srvWrapper.request.riskAssessmentId);
        params.put('participantId', srvWrapper.request.participantId);
        params.put('jsonInput', srvWrapper.request.jsonInput);
        arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse = new arce.Arc_Gen_getIASOResponse.ServiceResponse();
        sResponse = arce.Arc_Gen_getIASOResponse.calloutIASO('projections_persistence', JSON.serialize(params));
        if ('200' == sResponse.serviceCode || (Test.isRunningTest() && '201' == sResponse.serviceCode)) {
            srvWrapper = processProjectionResp(ahaId, sResponse, srvWrapper, scenarioType, proposalId);
        } else {
            srvWrapper.addMessage(sResponse.serviceCode, sResponse.serviceCode, sResponse.serviceMessage);
        }
        return srvWrapper;
    }
    /**
    * @description call clone projection service
    * @author joseluis.miralles.techr@bbva.com
    * @param String scenarioType
    * @param Set<String> financialStatemIds
    * @return Arc_Gen_Projection_ServiceWrapper
    **/
    public static void cloneProcessResponse(Integer index, ProjectionJsonWrapper respJsonWrapper, SObject projObj) {
        final arce__Projection__c projObjClone = (arce__Projection__c) projObj;
        if (index == 0) {
            projObjClone.put(PROJ_TYPE, ANCHOR_VALUE);
            projObjClone.put(PROJ_HEADER, ANCHOR_VALUE + ': ' +respJsonWrapper.statements[index].period.endDate);
        } else {
            projObj.put(PROJ_TYPE, PROJECTION_VALUE);
            projObj.put(PROJ_HEADER, respJsonWrapper.statements[index].period.endDate);
        }
        projObjClone.put(PROJ_SC_TYPE, SCENARIO_MAPPING.get(respJsonWrapper.statements[index].scenarioType.id));
    }
    /**
    * @Description: wrapper class ProjectionJsonWrapper
    */
    public class ProjectionJsonWrapper {
        /**
        * @Description: wrapper field scenarioType
        */
        public ScenarioType scenarioType;
        /**
        * @Description: wrapper field statements
        */
        public List<Statement> statements = new List<Statement>();
        /**
        * @Description: wrapper field analysisType
        */
        public AnalysisType analysisType = new AnalysisType();
    }
    /**
    * @Description: wrapper class AnalysisType
    */
    public class AnalysisType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }
    /**
    * @Description: wrapper class ScenarioType
    */
    public class ScenarioType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class Statement
    */
    public class Statement {
        /**
        * @Description: wrapper field id
        */
        public String id;
        /**
        * @Description: wrapper field currency
        */
        public String currencyX;
        /**
        * @Description: wrapper field statementType
        */
        public StatementType statementType;
        /**
        * @Description: wrapper field financialStatementType
        */
        public FinancialStatementType financialStatementType;
        /**
        * @Description: wrapper field period
        */
        public Period period;
        /**
        * @Description: wrapper field calculations
        */
        public Calculations calculations;
        /**
        * @Description: wrapper field calculations
        */
        public ScenarioType scenarioType;
    }

    /**
    * @Description: wrapper class FinancialStatementType
    */
    public class FinancialStatementType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class StatementType
    */
    public class StatementType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class Period
    */
    public class Period {
        /**
        * @Description: wrapper field unit
        */
        public String unit;
        /**
        * @Description: wrapper field number
        */
        public Integer numberX;
        /**
        * @Description: wrapper field periodType
        */
        public PeriodType periodType;
        /**
        * @Description: wrapper field startDate
        */
        public String startDate;
        /**
        * @Description: wrapper field endDate
        */
        public String endDate;
    }

    /**
    * @Description: wrapper class Period
    */
    public class Calculations {
        /**
        * @Description: wrapper field specificRatiosMagnitudes
        */
        public List<SpecificRatiosMagnitudes> specificRatiosMagnitudes = new List<SpecificRatiosMagnitudes>();
        /**
        * @Description: wrapper field accountingAccounts
        */
        public List<AccountingAccounts> accountingAccounts = new List<AccountingAccounts>();
    }

    /**
    * @Description: wrapper class SpecificRatiosMagnitudes
    */
    public class SpecificRatiosMagnitudes {
        /**
        * @Description: wrapper field id
        */
        public String id;
        /**
        * @Description: wrapper field description
        */
        public String description;
        /**
        * @Description: wrapper field calculationType
        */
        public CalculationType calculationType;
        /**
        * @Description: wrapper field totalAmount
        */
        public TotalAmount totalAmount;
        /**
        * @Description: wrapper field percentage
        */
        public Double percentage;
    }

    /**
    * @Description: wrapper class AccountingAccounts
    */
    public class AccountingAccounts {
        /**
        * @Description: wrapper field id
        */
        public String id;
        /**
        * @Description: wrapper field calculationType
        */
        public CalculationType calculationType;
        /**
        * @Description: wrapper field amount
        */
        public Amount amount;
    }

    /**
    * @Description: wrapper class TotalAmount
    */
    public class TotalAmount {
        /**
        * @Description: wrapper field amount
        */
        public Double amount;
        /**
        * @Description: wrapper field currency
        */
        public String currencyX;
        /**
        * @Description: wrapper field unit
        */
        public String unit;
    }

    /**
    * @Description: wrapper class Amount
    */
    public class Amount {
        /**
        * @Description: wrapper field amount
        */
        public Double amount;
        /**
        * @Description: wrapper field currency
        */
        public String currencyX;
    }

    /**
    * @Description: wrapper class PeriodType
    */
    public class PeriodType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class CalculationType
    */
    public class CalculationType {
        /**
        * @Description: wrapper field id
        */
        public String id;

    }

}