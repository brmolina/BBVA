/**
* @File Name          : Arc_Gen_PDF_Projection_Helper.cls
* @Description        : Helper class for Arc_Gen_PDF_Projection_Controller.cls
* @Author             : joseluis.miralles.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 11-26-2024
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0    15/05/2023  joseluis.miralles.contractor@bbva.com     Initial Version
**/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyFields, sf:LongVariable')
public with sharing class Arc_Gen_PDF_Projection_Helper {
    /**
    * @description: Simulation label to show when scenario is equal to Base Case
    */
    public static final String SIMULATION_BASE = 'Base Case';
    /**
    * @description: Simulation label to show when scenario is equal to Downside
    */
    public static final String SIMULATION_DOWN = 'Downside';
    /**
    * @description: Simulation label to show when scenario is equal to Upside
    */
    public static final String SIMULATION_UP = 'Upside';
    /**
    * @description: Scenario type equal to Up
    */
    public static final String TYPE_UP = 'Up';
    /**
    * @description: Scenario type equal to Down
    */
    public static final String TYPE_DOWN = 'Down';
    /**
    * @description: Value 0
    */
    public static final Integer VALUE_0 = 0;
    /**
    * @description: Last order number to get all active magnitudes data
    */
    public static final Integer LAST_MAGNITUDE_ACT = 200;
    /**
    * @description: Size to fill comment section
    */
    public static final Integer SECTION_FILL = 115;
    /**
    * @description: Map with values required to make units conversion
    */
    public static final Map<String, Double> MAPDIV = new Map<String, Double>{ '1' => 1000000, '2' => 1000, '3' => 1, '4' => 0.001 };
    /**
    * @description: Last order number to get all active magnitudes data
    */
    public static final String PROJEC_NAME = 'Projections_Summary_';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor to avoid SonarQube warning.
    *-------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_PDF_Projection_Helper() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection Data
    *--------------------------------------------------------------------------------
    * @date     01/05/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    ahaId
    * @param    scenario
    * @return   TableProjectionWrapper
    * @example  Arc_Gen_PDF_Projection_Helper.getProjectionData(ahaId, scenario);
    */
    public static TableProjectionWrapper getProjectionData(id ahaId, String scenario) {
        final Map<String, String> columnsHeader = new Map<String, String>();
        final Map<String, arce__Projection__c> magnitudeProjectionData = new Map<String, arce__Projection__c>();
        final List<String> columnsId = new List<String>();
        List<String> scenarioComment = new List<String>();
        String createdDate;
        TableProjectionWrapper tablesStructure = new TableProjectionWrapper();
            tablesStructure = getMagnitudes();
            final List<arce__Projection__c> projectionDataList = Arc_Gen_Projection_Data.getProjScenarioData(String.valueOf(ahaId), scenario);
            for (arce__Projection__c projectionData : projectionDataList) {
                columnsId.add(projectionData.Id);
                columnsHeader.put(projectionData.Id, projectionData.arce__Projection_Header__c);
                magnitudeProjectionData.put(projectionData.Id, formatProjectionData(projectionData, tablesStructure.listToFormat, ahaId));
                scenarioComment = projectionData.arce__Scenario_Comment__c == null ? null : getListFromComment(projectionData.arce__Scenario_Comment__c);
                createdDate = String.valueOf(projectionData.CreatedDate);
            }
            tablesStructure.columsHeader = columnsHeader;
            tablesStructure.columnsId = columnsId;
            tablesStructure.labelProjection = magnitudeProjectionData;
            tablesStructure.scenarioComment = scenarioComment;
            tablesStructure.createdDate = createdDate;

        return tablesStructure;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection simulation data
    *--------------------------------------------------------------------------------
    * @date     01/05/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    ahaId
    * @return   TableProjectionWrapper
    * @example  Arc_Gen_PDF_Projection_Helper.getProjectionSimulationData(ahaId);
    */
    public static TableProjectionWrapper getProjectionSimulationData(id ahaId) {
        final Map<String, arce__Projection__c> baseProjectionData = new Map<String, arce__Projection__c>();
        final Map<String, arce__Projection__c> upProjectionData = new Map<String, arce__Projection__c>();
        final Map<String, arce__Projection__c> downProjectionData = new Map<String, arce__Projection__c>();
        final Map<String, String> magnitudesList = new Map<String, String>{ 'Base Case' => 'arce__Simulation_Short_Scale_Value__c', 'Downside' => 'arce__Simulation_Short_Scale_Value__c', 'Upside' => 'arce__Simulation_Short_Scale_Value__c' };

        final Map<String, String> columnsHeader = new Map<String, String>();
        final List<String> columnsId = new List<String>();
        final TableProjectionWrapper tablesStructure = new TableProjectionWrapper();

        final List<String> simulationValues = new List<String>{ SIMULATION_BASE, SIMULATION_UP, SIMULATION_DOWN };
        tablesStructure.simulationValues = simulationValues;


            final List<arce__Projection__c> projectionDataList = Arc_Gen_Projection_Data.getProjectionData(String.valueOf(ahaId));

            for (arce__Projection__c projectionData : projectionDataList) {
                if (projectionData.arce__Scenario_Type__c == SIMULATION_BASE) {
                    baseProjectionData.put(projectionData.arce__Projection_Header__c, projectionData);
                    columnsId.add(projectionData.arce__Projection_Header__c);
                    columnsHeader.put(projectionData.arce__Projection_Header__c, projectionData.arce__Projection_Header__c);
                } else if (projectionData.arce__Scenario_Type__c == TYPE_UP) {
                    upProjectionData.put(projectionData.arce__Projection_Header__c, projectionData);
                } else if (projectionData.arce__Scenario_Type__c == TYPE_DOWN) {
                    downProjectionData.put(projectionData.arce__Projection_Header__c, projectionData);
                }

            }
            tablesStructure.magnitudesListMap = magnitudesList;
            tablesStructure.columsHeader = columnsHeader;
            tablesStructure.columnsId = columnsId;
            tablesStructure.labelProjection = baseProjectionData;
            tablesStructure.labelProjectionUp = upProjectionData;
            tablesStructure.labelProjectionDown = downProjectionData;
        return tablesStructure;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get magnitudes data
    *--------------------------------------------------------------------------------
    * @date     01/05/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @return   TableProjectionWrapper
    * @example  Arc_Gen_PDF_Projection_Helper.getMagnitudes();
    */
    @SuppressWarnings('sf:AvoidGetSetMethods')
    public static TableProjectionWrapper getMagnitudes() {
        final TableProjectionWrapper labelMap = new TableProjectionWrapper();
        final Map<String, String> magnitudesListMap = new Map<String, String>();
        final Map<String, String> magnitudesPercentageListMap = new Map<String, String>();

        final List<String> magnitudesBalanceActiveSheet = new List<String>();
        final List<String> magnitudesBalancePassiveSheet = new List<String>();
        final List<String> magnitudesPL = new List<String>();
        final List<String> magnitudesCASHFLOW = new List<String>();
        final List<String> magnitudesKEYRATIOS = new List<String>();
        final List<String> magnitudesKeyassumptions = new List<String>();
        final List<String> listAPI = new List<String>{ 'arce__Capex_Key__c' };
        List<arce__Projections__mdt> projectionMetadata = new List<arce__Projections__mdt>();

            projectionMetadata = [Select Label, arce__id__c, arce__Map_field__c, arce__Order__c, arce__Table_ID__c, arce__Percentage_Map__c
                                  from arce__Projections__mdt
                                  order by arce__Order__c asc LIMIT 100];
            for (arce__Projections__mdt labelMagnitudeData : projectionMetadata) {

                switch  on labelMagnitudeData.arce__Table_ID__c{
                    when '1'{
                        if (labelMagnitudeData.arce__Order__c >= VALUE_0 && labelMagnitudeData.arce__Order__c <= LAST_MAGNITUDE_ACT) {
                            magnitudesBalanceActiveSheet.add(labelMagnitudeData.Label);

                        } else {
                            magnitudesBalancePassiveSheet.add(labelMagnitudeData.Label);
                        }
                        listAPI.add(labelMagnitudeData.arce__Map_field__c);
                    }
                    when '2'{
                        magnitudesPL.add(labelMagnitudeData.Label);
                        listAPI.add(labelMagnitudeData.arce__Map_field__c);
                    }
                    when '3'{
                        magnitudesCASHFLOW.add(labelMagnitudeData.Label);
                        listAPI.add(labelMagnitudeData.arce__Map_field__c);
                    }
                    when '4'{
                        magnitudesKEYRATIOS.add(labelMagnitudeData.Label);
                    }
                    when '5'{
                        magnitudesKeyassumptions.add(labelMagnitudeData.Label);
                    }
                }

                magnitudesListMap.put(labelMagnitudeData.Label, labelMagnitudeData.arce__Map_field__c);
                magnitudesPercentageListMap.put(labelMagnitudeData.Label, labelMagnitudeData.arce__Percentage_Map__c);
            }
            labelMap.labelMapPerValue = magnitudesPercentageListMap;
            labelMap.magnitudesListMap = magnitudesListMap;
            labelMap.magnitudesKeyassumptions = magnitudesKeyassumptions;
            labelMap.magnitudesKEYRATIOS = magnitudesKEYRATIOS;
            labelMap.magnitudesCASHFLOW = magnitudesCASHFLOW;
            labelMap.magnitudesPL = magnitudesPL;
            labelMap.magnitudesBalanceActiveSheet = magnitudesBalanceActiveSheet;
            labelMap.magnitudesBalancePassiveSheet = magnitudesBalancePassiveSheet;
            labelMap.listToFormat = listAPI;
        return labelMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get client data
    *--------------------------------------------------------------------------------
    * @date     01/05/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    ahaId
    * @return   List<String>
    * @example  Arc_Gen_PDF_Projection_Helper.getClientData(ahaId);
    */
    public static TableProjectionClient getClientData(id ahaId) {
        final TableProjectionClient clientData = new TableProjectionClient();
        final List<arce__Account_has_Analysis__c> aha = [select id,arce__FR_Unit_Type__c, arce__AHA_Extension__r.arce__Undrawn_debt_Currency__c,arce__Customer__r.Name,arce__Analysis__r.arce__parent_analysis_id__c, arce__group_asset_header_type__c
                                                    from arce__Account_has_Analysis__c
                                                    where id = :ahaId
                                                    limit 1];
        if (!aha.isEmpty()) {
            clientData.name = aha.get(0).arce__Customer__r.Name;
            clientData.currencyFFSS = aha.get(0).arce__AHA_Extension__r.arce__Undrawn_debt_Currency__c;
            clientData.fileName = PROJEC_NAME + aha.get(0).arce__Analysis__r.arce__parent_analysis_id__c+'_' + date.today().format().replace('/', '_');
            final List<Schema.PicklistEntry> values = arce__Account_has_Analysis__c.arce__group_asset_header_type__c.getDescribe().getPicklistValues();
            final Map<String, String> clientGroup = new Map<String, String>();
            for (Schema.PicklistEntry sp : values) {
                clientGroup.put(sp.getValue(), sp.getLabel());
            }
            final List<Schema.PicklistEntry> valuesunits = arce__Financial_Statements__c.arce__magnitude_unit_type__c.getDescribe().getPicklistValues();
            final Map<String, String> clientunits = new Map<String, String>();
            for (Schema.PicklistEntry sp : valuesunits) {
                clientunits.put(sp.getValue(), sp.getLabel());
            }
            clientData.clientUnitsApi = aha.get(0).arce__FR_Unit_Type__c;
            clientData.clientGroup = clientGroup.get(aha.get(0).arce__group_asset_header_type__c);
        }
        return clientData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to format comment to show in visualforce
    *--------------------------------------------------------------------------------
    * @date     01/05/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    comment
    * @return   List<String>
    * @example  Arc_Gen_PDF_Projection_Helper.getListFromComment(comment);
    */
    @SuppressWarnings('sf:DUDataflowAnomalyAnalysis')
    public static List<String> getListFromComment(String comment) {
        final List<String> lstring = new List<String>();

        if (comment.length() > SECTION_FILL) {
            Integer multiplo = 0;
            for (Integer i = 1; i < comment.length(); i++) {
                if (math.mod(i, SECTION_FILL) == 0 && comment.length() > SECTION_FILL) {
                    lstring.add(comment.substring(i - SECTION_FILL, i).toLowercase());
                    multiplo += SECTION_FILL;
                } else if (i == comment.length() - 1) {
                    lstring.add(comment.substring(multiplo, i + 1).toLowercase());
                }
            }
        } else {
            lstring.add(comment.toLowercase());
        }
        return lstring;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to format Projection data to show in PDF
    *--------------------------------------------------------------------------------
    * @date     01/05/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    prRecord
    * @param    List<String> wrapper
    * @param    ahaId
    * @return   arce__Projection__c
    * @example  Arc_Gen_PDF_Projection_Helper.formatProjectionData(prRecord,wrapper,ahaId);
    */
    public static arce__Projection__c formatProjectionData(arce__Projection__c prRecord, List <String> wrapper, String ahaId) {
        TableProjectionClient clientData = new TableProjectionClient();
        final List<arce__Projections__mdt> projectionMetadata = [Select Label,	arce__Format_Percentage__c, arce__id__c, arce__Map_field__c, arce__Order__c, arce__Table_ID__c, arce__Percentage_Map__c
        from arce__Projections__mdt
        order by arce__Order__c asc LIMIT 100];
        clientData = getClientData(ahaId);
        for (arce__Projections__mdt pjmdt : projectionMetadata) {
            if (wrapper.contains(pjmdt.arce__Map_field__c) && prRecord.get(pjmdt.arce__Map_field__c) != null) {
                final Double valueDouble = Double.valueOf(prRecord.get(pjmdt.arce__Map_field__c));
                final Decimal decimalvalue = Decimal.valueOf(valueDouble);
                final String valueFront = pjmdt.arce__Format_Percentage__c ? String.valueOf((decimalvalue * 100).format()) : String.valueOf(decimalvalue.format());
                prRecord.put(pjmdt.arce__Map_field__c, formatNoRounding(valueFront));
            } else if(prRecord.get(pjmdt.arce__Map_field__c) != null) {
                final Double valueDouble2 = Double.valueOf(prRecord.get(pjmdt.arce__Map_field__c));
                final Decimal decimalvalue2 = Decimal.valueOf(valueDouble2);
                final String valueFront2 = pjmdt.arce__Format_Percentage__c ? String.valueOf((decimalvalue2 * 100).format()) : String.valueOf(decimalvalue2.format());
                prRecord.put(pjmdt.arce__Map_field__c, formatNoRounding(valueFront2));
            }
        }
        return prRecord;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to setScale no rounding
    *--------------------------------------------------------------------------------
    * @date     10/07/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    value
    * @return   String
    * @example  Arc_Gen_PDF_Projection_Helper.formatNoRounding(value);
    */
    public static String formatNoRounding(String value) {
        String result;
        String afterDecimal = value.substringAfter(',');
        if (afterDecimal.length()>2) {
            result = value.subString(0,value.indexOf(',')+3);
        } else {
            result = value;
        }
        return result;
    }
    /**
    * @Description: Wrapper to store table Projection data
    */
    public class TableProjectionWrapper {
        /**
        * @Description: Map to store for each magnitude label the mapfield to show
        */
        public Map<String, String> magnitudesListMap { get; set; }

        /**
        *
        * @Description: Map with columns label to show and the columnId
        */
        public Map<String, String> columsHeader { get; set; }

        /**
        * @Description: Labels active Sheet magnitudes
        */
        public List<String> magnitudesBalanceActiveSheet { get; set; }

        /**
        * @Description: Labels Passive Sheet magnitudes
        */
        public List<String> magnitudesBalancePassiveSheet { get; set; }

        /**
        * @Description: Labels key assumptions magnitudes
        */
        public List<String> magnitudesKeyassumptions { get; set; }

        /**
        * @Description: Labels key ratios magnitudes
        */
        public List<String> magnitudesKEYRATIOS { get; set; }

        /**
        * @Description: Labels Cash Flow magnitudes
        */
        public List<String> magnitudesCASHFLOW { get; set; }

        /**
        * @Description: Labels P&L magnitudes
        */
        public List<String> magnitudesPL { get; set; }

        /**
        * @Description:Columns Id stored
        */
        public List<String> columnsId { get; set; }

        /**
        * @Description: Map with header and projectionRecord, to get the data needed in Down scenario
        */
        public Map<String, arce__Projection__c> labelProjectionDown { get; set; }

        /**
        * @Description: Map with header and projectionRecord, to get the data needed in Up scenario
        */
        public Map<String, arce__Projection__c> labelProjectionUp { get; set; }

        /**
        * @Description: Map with header and projectionRecord, to get the data needed in BasCase scenario
        */
        public Map<String, arce__Projection__c> labelProjection { get; set; }

        /**
        * @Description: Map to store label and percentage value
        */
        public Map<String, String> labelMapPerValue { get; set; }

        /**
        * @Description:Scenario comment to show
        */
        public List<String> scenarioComment { get; set; }

        /**
        * @Description: Projection created date
        */
        public String createdDate { get; set; }

        /**
        * @Description: Label to show in simulation Table
        */
        public List<String> simulationValues { get; set; }

        /**
        * @Description: List to be formated
        */
        public List<String> listToFormat { get; set; }
    }
    /**
    * @Description: Wrapper to store client Data
    */
    public class TableProjectionClient {
        /**
        * @Description: Client name
        */
        public String name { get; set; }

        /**
        * @Description: Group from aha
        */
        public String clientGroup { get; set; }

        /**
        * @Description: Currency
        */
        public String currencyFFSS { get; set; }

        /**
        * @Description: Units
        */
        public String unitsFFSS { get; set; }

        /**
        * @Description: API from units
        */
        public String clientUnitsApi { get; set; }
        /**
        * @Description: File name to download in front
        */
        public String fileName { get; set; }

    }
}