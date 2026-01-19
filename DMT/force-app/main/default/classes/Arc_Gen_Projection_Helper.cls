/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Projection_Helper
* @Author   joseluis.miralles.contractor@bbva.com
* @Date     Created: 22-05-2023
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_ProjectionController
* ------------------------------------------------------------------------------------------------
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.ExcessiveParameterList, sf:LongVariable, sf:UseObjectForClearerAPI')
public with sharing class Arc_Gen_Projection_Helper {
    /**
    * @Description : String with Base Case scenario 
    */
    static final String BASE_CASE = 'Base Case';
    /**
    * @Description : String with Upscenario
    */
    static final String UP_SCE = 'Up';
    /**
    * @Description : String with Down scenario
    */
    static final String DOWN = 'Down';
    /**
    * @Description : String with  Projection API -> arce__Projection__c
    */
    static final String PROJECTION_OBJECT = 'arce__Projection__c';
    /**
    * @Description : String Anchor type
    */
    static final String ANCHOR = 'Anchor';
    /**
    * @Description : String Anchor type
    */
    static final String API_CHANGE = 'arce__Capex_Key__c';
    /**
    * @Description : Map with the corresponding number to divide by
    */
    static final Map<String, String> UNITS_VALUES = new Map<String, String>{ 'UNITS' => '1', 'THOUS' => '1000','MILLI' => '1000000', 'BILLI' => '1000000000'};
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     Created: 22-05-2023
    * @param void
    * @return void
    * ----------------------------------------------------------------------------------------------------
    **/
    private Arc_Gen_Projection_Helper() {
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get maps data from custommetadata and use maps to fill projectionTables
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    isRating
    * @return   TableContentPerAnalysisWrapper
    * @example    Arc_Gen_Projection_Helper.getTableData(true);
    */
    public static TableContentPerAnalysisWrapper getTableData(Boolean isRating) {
        final TableContentPerAnalysisWrapper wrapper = new TableContentPerAnalysisWrapper();
        List<arce__Projections__mdt> cmProjection = new List<arce__Projections__mdt>();

        if (isRating) {
            final List<String> baseCaseMetricsIds = new List<String>{ '97', '92', '701', '58', '59', '700' };
            cmProjection = [Select arce__id__c, arce__Map_field__c, arce__Format_Percentage__c, arce__Order__c, arce__Table_ID__c, arce__Percentage_Map__c
                            from arce__Projections__mdt
                            where arce__id__c IN:baseCaseMetricsIds
                            order by arce__Order__c asc LIMIT 100];
        } else {
            cmProjection = [Select arce__id__c, arce__Map_field__c, arce__Format_Percentage__c, arce__Order__c, arce__Table_ID__c, arce__Percentage_Map__c
                            from arce__Projections__mdt
                            order by arce__Order__c asc LIMIT 100];
        }

        final Map<String, Double> valuesMappingOrder = new Map<String, Double>();
        final Map<Double, String> valuesMappingTableOrder = new Map<Double, String>();
        final Map<String, String> valuesMapping = new Map<String, String>();
        final Map<String, String> valuesMappingPercentage = new Map<String, String>();
        final Map<String, Boolean> valuesMappingFormatPer = new Map<String, Boolean>();
        for (arce__Projections__mdt values : cmProjection) {
            valuesMapping.put(values.arce__id__c, values.arce__Map_field__c);
            valuesMappingOrder.put(values.arce__id__c, values.arce__Order__c);
            valuesMappingPercentage.put(values.arce__Map_field__c, values.arce__Percentage_Map__c);
            valuesMappingTableOrder.put(values.arce__Order__c, values.arce__Table_ID__c);
            valuesMappingFormatPer.put(values.arce__Map_field__c, values.arce__Format_Percentage__c);
        }
        final Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        final Schema.SObjectType leadSchema = schemaMap.get(PROJECTION_OBJECT);
        final Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        final Map<Double, Map<String, String>> mapidMap = new Map<Double, Map<String, String>>();


        for (String fieldName : fieldMap.keySet()) {
            if (valuesMapping.values().contains(String.valueOf(fieldMap.get(fieldName)))) {
                final Map<String, String> mapLabelAPI = new Map<String, String>();
                mapLabelAPI.put(String.valueOf(fieldMap.get(fieldName)), fieldMap.get(fieldName).getDescribe().getLabel());
                for (String key : valuesMapping.keySet()) {
                    if (valuesMapping.get(key) == fieldname) {
                        final double order = valuesMappingOrder.get(key);
                        mapidMap.put(order, mapLabelAPI);
                    }
                }
            }
        }
        final Map<Double, Map<String, String>> orderMappping = orderMap(mapidMap);

        wrapper.valuesMappingTableOrder = valuesMappingTableOrder;
        wrapper.mapIdFieldPercentage = valuesMappingPercentage;
        wrapper.mapIdFieldValue = valuesMapping;
        wrapper.mapLabelAPI = orderMappping;
        wrapper.mapAPIFormatPer = valuesMappingFormatPer;

        return wrapper;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to order data to show in projections tables
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    mapValue : Map<Double, Map<String,String>>
    * @return   Map<Double, Map<String,String>>
    * @example    Arc_Gen_Projection_Helper.orderMap(mapValue);
    */
    public static Map<Double, Map<String, String>> orderMap(Map<Double, Map<String, String>> mapValue) {
        final Map<Double, Map<String, String>> newMap = new Map<Double, Map<String, String>>();
        Set<Double> mapValueList = new Set<Double>();
        mapValueList = mapValue.keySet();
        final List<Double> listDouble = new List<Double>(mapValueList);
        listDouble.sort ();
        for (Double listIteration : listDouble) {
            newMap.put(listIteration, mapValue.get(listIteration));
        }

        return newMap;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to check if scenario has been edited or if simulation has been calculated
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId : String
    * @param    scenario : String
    * @param    isSimulation : Boolean
    * @return   ControlrAnalysisWrapper
    * @example    Arc_Gen_Projection_Helper.orderMap(mapValue);
    */
    public static ControlrAnalysisWrapper checkControlValues(String recordId, String scenario, Boolean isSimulation, String proposalId) {
            final ControlrAnalysisWrapper controlContent = new ControlrAnalysisWrapper();
            final List<arce__Projection__c> dataTable = proposalId == null ? arce.Arc_Gen_Projection_Data.getProjectionData(recordId) : arce.Arc_Gen_Projection_Data.getProjectionDataProposal(proposalId);
            if (!dataTable.isEmpty()) {
                final Map<String, Boolean> controlButtons = new Map<String, Boolean>();
                final  List<String> scenarioNoCalculated = new List<String>();
                for (arce__Projection__c pro : dataTable) {
                    if (pro.arce__Confirmed_Projection__c == false && pro.arce__Projection_Type__c != ANCHOR) {
                        scenarioNoCalculated.add(pro.arce__Scenario_Type__c);
                        controlContent.scenarioNoCalculated = scenarioNoCalculated;
                    } else {
                        scenarioNoCalculated.add('');
                    }
                    controlButtons.put(pro.arce__Scenario_Type__c, pro.arce__Confirmed_Projection__c);
                    controlContent.controlValues = controlButtons;
                    if (scenario == BASE_CASE && pro.arce__Scenario_Type__c == BASE_CASE && !isSimulation) {
                        controlContent.editBaseCase = pro.arce__Edit_Base_Case__c;
                        controlContent.projectionCriteria = pro.arce__Projection_Criteria__c;
                    }
                }
                controlContent.simulation = simulationCalculatedMapped(scenario, dataTable);

                controlContent.projectionPerspective = calculateProjectionPerspective(dataTable, recordId);
            }
            return controlContent;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to calculate Projection Perspective
    *--------------------------------------------------------------------------------
    * @date        05/08/2024
    * @author    aleksandar.dinkov.contractor@bbva.com
    * @param    List<arce__Projection__c> dataTable
    * @return   String projectionPerspective
    * @example    Arc_Gen_Projection_Helper.calculateProjectionPerspective(dataTable);
    */
    public static String calculateProjectionPerspective(List<arce__Projection__c> dataTable, String recordId) {
        String projectionPerspective = 'Not calculated';
        final arce__Account_has_Analysis__c ahaObj = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId})[0];
        // AAA:26, AA+:25, AA:24, AA-:23, A+:22, A:21, A-:20, BBB+:19, BBB:18, BBB-:17, BB+:16, BB:15, BB-:14,
        // CCC+:13, CCC:12, CCC-:11, CC+:10, CC:9, CC-:8, B+:7, B:6, B-:5, D:4, C+:3, C:2, C-:1, NA:0
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ShortRatingValuesOrder');
        if (!configs.isEmpty()) {
            final Map<String, String> valuesOrderMap = new Map<String, String>();
            List<String> configValuesList = configs[0].arce__Value1__c.split(',');
            for (String var : configValuesList) {
                valuesOrderMap.put(var.substringBefore(':'), var.substringAfter(':'));
            }
            // Determinar el mejor rating de todas las proyecciones
            String bestProjRating = 'NA';
            for (arce__Projection__c proj : dataTable) {
                if (valuesOrderMap.get(proj.arce__Simulation_Short_Scale_Value__c) > valuesOrderMap.get(bestProjRating)) {
                    bestProjRating = proj.arce__Simulation_Short_Scale_Value__c;
                }
            }
            // Determinar la perspectiva final
            if (valuesOrderMap.get(bestProjRating) > valuesOrderMap.get(ahaObj.arce__short_rating_value_type__c)) {
                projectionPerspective = 'Positive';
            } else if (valuesOrderMap.get(bestProjRating) < valuesOrderMap.get(ahaObj.arce__short_rating_value_type__c)) {
                projectionPerspective = 'Negative';
            } else {
                projectionPerspective = 'Neutral';
            }
        }
        return projectionPerspective;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get data from projections simulations
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId : String
    * @return   TableContentPerAnalysisWrapper
    * @example    Arc_Gen_Projection_Helper.getSimulationDataHelper(recordId);
    */
    public static TableContentPerAnalysisWrapper getSimulationDataHelper(String recordId, String proposalId) {
        TableContentPerAnalysisWrapper tcontent = new TableContentPerAnalysisWrapper();

        tcontent = getTableData(true);
        final List<arce__Projection__c> dataTable = proposalId == null ? arce.Arc_Gen_Projection_Data.getProjectionData(recordId) : arce.Arc_Gen_Projection_Data.getProjectionDataProposal(proposalId);
        tcontent.dataTable = dataTable;

        return tcontent;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to update control values from projections
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId : String
    * @param    scenario : String
    * @param    controlValue : Boolean
    * @return   void
    * @example    Arc_Gen_Projection_Helper.updateControlValues(recordId, scenario, controlValue);
    */
    public static void updateControlValues(String recordId, String scenario, Boolean controlValue, String proposalId) {
        final List<arce__Projection__c> dataTable = proposalId == null ?  arce.Arc_Gen_Projection_Data.getProjectionData(recordId) : arce.Arc_Gen_Projection_Data.getProjectionDataProposal(proposalId);
            for (arce__Projection__c pro : dataTable) {
                if ((pro.arce__Scenario_Type__c == BASE_CASE && controlValue == true) || pro.arce__Scenario_Type__c == scenario) {
                    pro.arce__Confirmed_Projection__c = controlValue;
                }
            }
            upsert dataTable;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to update scenarios comment
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId : String
    * @param    scenario : String
    * @param    scenarioComment : String
    * @return   void
    * @example    Arc_Gen_Projection_Helper.updateScenarioComment(recordId, scenario, scenarioComment);
    */
    public static void updateScenarioComment(String recordId, String scenario, String scenarioComment, String proposalId) {
        final List<arce__Projection__c> dataTable = proposalId == null ? arce.Arc_Gen_Projection_Data.getProjScenarioData(recordId, scenario) : arce.Arc_Gen_Projection_Data.getProjProposalScenarioData(proposalId, scenario);
            if (!datatable.isEmpty()) {
                for (arce__Projection__c pro : dataTable) {
                    if (pro.arce__Scenario_Type__c == scenario) {
                        pro.arce__Scenario_Comment__c = scenarioComment;
                    }
                }
                arce.Arc_Gen_Projection_Data.updateProjectionData(dataTable);
            }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get table data from projections for a specific scenario
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId : String
    * @param    scenario : String
    * @param    isSimulation : Boolean
    * @return   void
    * @example    Arc_Gen_Projection_Helper.getScenarioDataHelper(recordId, scenario, isSimulation);
    */
    public static TableContentPerAnalysisWrapper getScenarioDataHelper(String recordId, string scenario, Boolean isSimulation, String proposalId) {
            final String sceFront = scenario == null ? BASE_CASE : scenario;
            TableContentPerAnalysisWrapper tcontent = new TableContentPerAnalysisWrapper();
            tcontent = getTableData(isSimulation);
            tcontent.financialStatementRecord = arce.Arc_Gen_Projection_Data.getDataFFSS(recordId);
            tcontent.controlChecking = checkControlValues(recordId, sceFront, isSimulation, proposalId);
            tcontent.dataTable = proposalId == null ? arce.Arc_Gen_Projection_Data.getProjScenarioData(recordId, sceFront) : arce.Arc_Gen_Projection_Data.getProjProposalScenarioData(proposalId, sceFront);
            tcontent.controlClone = checkAnchorControlClone(tcontent.dataTable);
            tcontent.scenarioComment = tcontent.dataTable.isEmpty() ? '' : tcontent.dataTable.get(tcontent.dataTable.size() - 1).arce__Scenario_Comment__c;
            tcontent.ahaData = arce.Arc_Gen_Projection_Data.getRiskAssByAhaId(recordId).arce__Analysis__r.arce__Stage__c;
            return tcontent;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get update KeyAssumptions gotten in front
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    editedValues : Map<String,Map<String,Double>>
    * @param    scenario : String
    * @param    editCase : String
    * @param    projectionCriteria : String
    * @param    ahaId : String
    * @return   void
    * @example    Arc_Gen_Projection_Helper.updateKeyAssumptionsHelper(editedValues, scenario, editCase,projectionCriteria);
    */
    public static Map<String, List<String>> updateKeyAssumptionsHelper(Map<String, Map<String, Double>> editedValues, string scenario, string editCase, string projectionCriteria, string ahaId, String unitsReal, String proposalId) {
            final Map<String,List<String>> listValidationErrors = new Map<String,List<String>> ();
            Set<String> idsToEdit = new Set<String>();
            idsToEdit = editedValues.keySet();
            List<String> listStrings = new List<String>(idsToEdit);
            final arce__Account_has_Analysis__c ahaObj = arce.Arc_Gen_Projection_Data.getRiskAssByAhaId(ahaId);
            final List<arce__Projection__c> projectionToEdit = arce.Arc_Gen_Projection_Data.getProjectionDataSet(idsToEdit);
            if (!projectionToEdit.isEmpty()) {
                final List<arce__Projection__c> projectionCapex = new List<arce__Projection__c> ();
                for (arce__Projection__c projectionElement : projectionToEdit) {
                    Map<String, Double> valuesAndAPI = new Map<String, Double>();
                    final String idProjection = projectionElement.id;
                    valuesAndAPI = editedValues.get(idProjection);
                    Set<String> listToChange = new Set<String>();
                    listToChange = valuesAndAPI.keySet();
                    for (String apiChange : listToChange) {
                        if (apiChange == API_CHANGE) {
                            projectionCapex.add(projectionElement);
                        }
                        projectionElement.put(apiChange, String.valueOf(Decimal.valueOf(valuesAndAPI.get(apiChange))));
                    }
                }
                if (!projectionCapex.isEmpty()) {
                    final Double ratio = baseCurrencyFormat(ahaObj, projectionCapex[0]);
                    for (arce__Projection__c projectionElementCapex : projectionCapex) {
                        projectionElementCapex.put('arce__Capex_Key_base__c', String.valueOf(Decimal.valueOf( Double.valueOf(projectionElementCapex.arce__Capex_Key__c) * Double.valueOf(UNITS_VALUES.get(ahaObj.arce__FR_Unit_Type__c)) * ratio)));
                    }
                }
            }
            Savepoint sp = Database.setSavepoint();
            arce.Arc_Gen_Projection_Data.updateProjectionData(projectionToEdit);
            Map<String,Set<String>> actionsPerOppIdMap = dwp_dace.DynamicActionsEngine_helper.getAvailableActions(listStrings,'arce__Projection__c','Arc_Gen_Projection_Keys');
            if (scenario == BASE_CASE) {
                arce.Arc_Gen_Projection_Data.updateBaseCase(ahaId, editCase, projectionCriteria, proposalId);
            }
            Boolean roolBack = false;
            for (Id key : actionsPerOppIdMap.keySet()) {
                List<String> listString = new List <String> (actionsPerOppIdMap.get(key));
                listValidationErrors.put(key, listString);
                if (!listString.isEmpty()) {
                    roolBack = true;
                }
            }
            if (roolBack) {
                Database.rollback(sp);
            }
        return listValidationErrors;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to check if scenario has been edited or if simulation has been calculated
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    projecRecord : List<arce__Projection__c>
    * @param    scenario : String
    * @return   ControlSimulation
    * @example    Arc_Gen_Projection_Helper.simulationCalculatedMapped(scenario, projecRecord);
    */
    public static ControlSimulation simulationCalculatedMapped(String scenario, List<arce__Projection__c> projecRecord) {
        final ControlSimulation controlSimulation = new ControlSimulation();
        if (!projecRecord.isEmpty()) {
            final List<arce__Projection__c> projectionNoCalculated = new List<arce__Projection__c>();
            final Map<String, Boolean> mapControlSimulation = new Map<String, Boolean>{ 'Base Case' => true, 'Down' => true, 'Up' => true };
            for (arce__Projection__c pro : projecRecord) {
                if (pro.arce__Scenario_Type__c == BASE_CASE && pro.arce__Simulation_Calculated__c == false) {
                    mapControlSimulation.put(pro.arce__Scenario_Type__c, pro.arce__Simulation_Calculated__c);
                    projectionNoCalculated.add(pro);
                } else if (pro.arce__Scenario_Type__c == UP_SCE && pro.arce__Simulation_Calculated__c == false) {
                    mapControlSimulation.put(pro.arce__Scenario_Type__c, pro.arce__Simulation_Calculated__c);
                    projectionNoCalculated.add(pro);
                } else if (pro.arce__Scenario_Type__c == DOWN && pro.arce__Simulation_Calculated__c == false) {
                    mapControlSimulation.put(pro.arce__Scenario_Type__c, pro.arce__Simulation_Calculated__c);
                    projectionNoCalculated.add(pro);
                }
            }
            controlSimulation.recordsNoCalculated = projectionNoCalculated; 
            controlSimulation.simulationCalculated = mapControlSimulation;
        }

        return controlSimulation;
    }
    /**
     *-------------------------------------------------------------------------------
    * @description Format value to the original currency
    *--------------------------------------------------------------------------------
    * @date      12/07/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    ahaObj : arce__Account_has_Analysis__c
    * @param    projectionRecord : arce__Projection__c
    * @return   Double
    * @example    Arc_Gen_Projection_Helper.baseCurrencyFormat(ahaObj, projectionRecord);
    */
    public static Double baseCurrencyFormat(arce__Account_has_Analysis__c ahaObj, arce__Projection__c projectionRecord) {
        //Call currencies service
        if (projectionRecord.arce__SelectedCurrency__c == projectionRecord.arce__Statement_Currency__c) {
            return 1;
        } else {
        final List<arce__Projection__c> listProjections = arce.Arc_Gen_Projection_Data.getProjectionByAhaId(ahaObj.id);
        final String dateFFSS = String.valueOf(listProjections.get(0).arce__Period_EndDate__c);
        final Arc_Gen_Ratios_Calc_Core_Service.CurrencySrvcParameters servParams = new Arc_Gen_Ratios_Calc_Core_Service.CurrencySrvcParameters(projectionRecord.arce__SelectedCurrency__c, projectionRecord.arce__Statement_Currency__c,'IRISK', dateFFSS);
        final Map<String,Double> response =  Arc_Gen_Ratios_Calc_Core_Service.targtCurrncy(servParams).get(projectionRecord.arce__Statement_Currency__c);
        final Double ratio = Double.valueOf(response.get('MONTH_END_EXCHANGE_RATE'));
        return ratio;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Check control field to know if cloned is needed
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.tech@bbva.com
    * @param    List<arce__Projection__c> dataTable
    * @return   Boolean
    * @example    Arc_Gen_Projection_Helper.checkAnchorControlClone(dataTable);
    */
    public static Boolean checkAnchorControlClone(List<arce__Projection__c> dataTable) {
        Boolean controlClone = false;
        if (!dataTable.isEmpty()) {
            controlClone = dataTable[0].arce__Prop_Need_Cloned__c;
        }
    return controlClone;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Wrapper class to return
    * ----------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     Created: 22-05-2023
    * ----------------------------------------------------------------------------------------------------
    **/
    public class TableContentPerAnalysisWrapper {
        /**
        * @Description: Object that contains projection Data
        */
        @AuraEnabled
        public String ahaData { get; set; }
        /**
        * @Description: control If clone is needed
        */
        @AuraEnabled
        public Boolean controlClone { get; set; }
        /**
        * @Description: Object that contains projection Data
        */
        @AuraEnabled
        public List<arce__Projection__c> dataTable { get; set; }

        /**
        * @Description: Map to stored label and api from fields
        */
        @AuraEnabled
        public Map<Double, Map<String, String>> mapLabelAPI { get; set; }

        /**  
        * @Description: Map to stored api and format percentage  from custom metadata
        */
        @AuraEnabled
        public Map<String, Boolean> mapAPIFormatPer { get; set; }
        /**
        * @Description: Map to stored field and value
        */
        @AuraEnabled
        public Map<String, String> mapIdFieldValue { get; set; }

        /**
        * @Description: Map to stored field and percentage
        */
        @AuraEnabled
        public Map<String, String> mapIdFieldPercentage { get; set; }

        /**
        * @Description: Order Map with label values
        */
        @AuraEnabled
        public Map<Double, String> valuesMappingTableOrder { get; set; }

        /**
        * @Description: Scenario comment saved
        */
        @AuraEnabled
        public String scenarioComment { get; set; }

        /**
        * @Description: Wrapper control Values
        */
        @AuraEnabled
        public ControlrAnalysisWrapper controlChecking { get; set; }

        /**
        * @Description: arce__Financial_Statements__c anchor selected
        */
        @AuraEnabled
        public arce__Financial_Statements__c financialStatementRecord { get; set; }

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Class to store ControlAnalysis data
    * ----------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     Created: 22-05-2023
    * ----------------------------------------------------------------------------------------------------
    **/
    public class ControlrAnalysisWrapper {
        /**
        * @Description: If
        */
        @AuraEnabled
        public Map<String, Boolean> controlValues { get; set; }

        /**
        * @Description: Variable to stored projection creiteria from BBDD
        */
        @AuraEnabled
        public String projectionCriteria { get; set; }

        /**
        * @Description: Variable to stored Edit base case from BBDD
        */
        @AuraEnabled
        public String editBaseCase { get; set; }

        /**
        * @Description: List to stored no edited scenarios
        */
        @AuraEnabled
        public List<String> scenarioNoCalculated { get; set; }

        /**
        * @Description: Map to stored if simulation is calculated for each scenario
        */
        @AuraEnabled
        public ControlSimulation simulation { get; set; }

        /**
        * @Description: Projection perspective
        */
        @AuraEnabled
        public String projectionPerspective { get; set; }
        
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Class to store ControlSimulation data
    * ----------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     Created: 22-05-2023
    * ----------------------------------------------------------------------------------------------------
    **/
    public class ControlSimulation {
        /**
        * @Description: Map to stored if simulation is calculated for each scenario
        */
        @AuraEnabled
        public Map<String, Boolean> simulationCalculated { get; set; }

        /**
        * @Description: Map to stored if simulation is calculated for each scenario
        */
        @AuraEnabled
        public List<arce__Projection__c> recordsNoCalculated { get; set; }
    }
}