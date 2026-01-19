/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GroupRiskDetailTable_service
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 26/03/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Contains the logic to update the Group Risk Detail Table
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |26/03/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |15/05/2020 cesaroctavio.villanueva.cebal@bbva.com
*             Modified the divition factor for the Proposed Amount
* |29/05/2020 cesaroctavio.villanueva.cebal@bbva.com
*             Added validation for group or orphan info to set proposed amount
* |01/06/2020 cesaroctavio.villanueva.cebal@bbva.com
*			  Added functionality to set limits to subsidiary if group is being edited
* |17-06-2020 cesaroctavio.villanueva.cebal@bbva.com
*             Reverted to previous version
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |18/11/2020 juanignacio.hita.contractor@bbva.com
*             Adds createConfigTable method
* |17/03/2021 juanignacio.hita.contractor@bbva.com
*             Changes reference class of getMultiplicationFactor method in setupRiskTable
* |07/04/2021 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_GroupRiskDetailTable_service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/03/2020
    * @param void
    * @return void
    * @example Arc_Gen_GroupRiskDetailTable_service service = new Arc_Gen_GroupRiskDetailTable_service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_GroupRiskDetailTable_service() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that update the Account Has Analysis with the Limit amounts
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 26/03/2020
    * @param arce__limits_exposures__c limits - Limit exposures Record
    * @param arce__Account_has_Analysis__c accHasAnalysis - Account Has Analysis Record
    * @return String - A json with the status and the message of the update
    * @example public String setupRiskTable(arce__limits_exposures__c limits, arce__Account_has_Analysis__c accHasAnalysis) {
    **/
    public static String setupRiskTable(arce__limits_exposures__c limits, arce__Account_has_Analysis__c accHasAnalysis) {
        final arce.Arc_Gen_RatingGlobal_data res = new arce.Arc_Gen_RatingGlobal_data();
        arce__Account_has_Analysis__c ahaGroup = accHasAnalysis.arce__group_asset_header_type__c == '1' ? accHasAnalysis : getAhaGroup(accHasAnalysis);
        final Decimal multipFactor = Arc_Gen_Validate_Customer_Helper.getMultiplicationFactor(accHasAnalysis.arce__magnitude_unit_type__c);
        final Decimal divFactor = Arc_Gen_Validate_Customer_Helper.getMultiplicationFactor(ahaGroup.arce__magnitude_unit_type__c);

        accHasAnalysis.arce__last_approved_amount__c = (limits.arce__last_approved_amount__c * multipFactor) / divFactor;
        accHasAnalysis.arce__outstanding_amount__c = (limits.arce__outstanding_amount__c * multipFactor) / divFactor;
        accHasAnalysis.arce__current_formalized_amount__c = (limits.arce__current_formalized_amount__c * multipFactor) / divFactor;
        accHasAnalysis.arce__current_proposed_local_amount__c = (limits.arce__current_proposed_amount__c * multipFactor) / divFactor;

        Return JSON.serialize(res.updateRecords(new List<sObject>{accHasAnalysis}));
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that update the group Account Has Analysis with the Limit amounts
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 26/03/2020
    * @param arce__Account_has_Analysis__c accHasAnalysis - Account Has Analysis Record
    * @return arce__Account_has_Analysis__c - Account Has Analysis Record
    * @example public arce__Account_has_Analysis__c getAhaGroup(arce__Account_has_Analysis__c accHasAnalysis)
    **/
    private static arce__Account_has_Analysis__c getAhaGroup(arce__Account_has_Analysis__c accHasAnalysis) {
        arce__Account_has_Analysis__c ahaGroup = new arce__Account_has_Analysis__c();
        final List<arce__Account_has_Analysis__c> ahaByArce = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{accHasAnalysis.arce__Analysis__c});
        for(arce__Account_has_Analysis__c aha : ahaByArce) {
            if(aha.arce__group_asset_header_type__c == '1') {
                ahaGroup = aha;
            }
        }
        Return ahaGroup;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Build configuration group risk detail table
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    18/11/2020
    * @param   Id accHasId - Account Has Analysis Record id
    * @return  Arc_Gen_DwpTableWrapper_Controller.Configuration_Table
    * @example Arc_Gen_DwpTableWrapper_Controller.Configuration_Table config = configGroupRiskDetail(accHasId);
    **/
    public static Arc_Gen_DwpTableWrapper_Controller.Configuration_Table configGroupRiskDetail(Id accHasId) {
        final Arc_Gen_DwpTableWrapper_Controller.Configuration_Table configTable = new Arc_Gen_DwpTableWrapper_Controller.Configuration_Table();
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasId);
        final List<arce__Account_has_Analysis__c> lstAccAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnforRiskDetTable(analysis.Id);

        final Map<String, Object> mapHeader = new Map<String, Object> {
            'partName' => System.Label.Arc_Gen_ParticipantName,
            'activity' => System.Label.Arc_Gen_ColumnHeader_Activity,
            'rating' => System.Label.Lc_Arc_Rating,
            'finanDebt' => System.Label.Arc_Gen_FinancialDebtShare,
            'lastApprov' => System.Label.Arc_Gen_Last_Approved,
            'formalized' => System.Label.Arc_Gen_Formalized,
            'outStanding' => System.Label.Arc_Gen_Outstanding,
            'proposed' => System.Label.Arc_Gen_Proposed
        };

        final Map<Id, Map<String, Object>> mapRows = new Map<Id, Map<String, Object>>();
        for (arce__Account_has_Analysis__c accAha : lstAccAha) {
            final Map<String, Object> mapRow = new Map<String, Object> {
            'partName'    => accAha.arce__group_risk_detail_part_name__c,
            'activity'    => accAha.arce__economic_activity_sector_desc__c,
            'rating'      => Arc_Gen_FinInfoGroupTable_Service.getFinalRatingValue(accAha),
            'finanDebt'   => accAha.arce__bbva_financial_debt_share_per__c,
            'lastApprov'  => formatAmount(accAha.arce__last_approved_amount__c),
            'formalized'  => formatAmount(accAha.arce__current_formalized_amount__c),
            'outStanding' => formatAmount(accAha.arce__outstanding_amount__c),
            'proposed'    => formatAmount(accAha.arce__current_proposed_local_amount__c)
            };
            mapRows.put(accAha.Id, mapRow);
        }
        configTable.mapHeader = mapHeader;
        configTable.mapRows = mapRows;
        configTable.editable = false;
        configTable.lblEmptyTable = System.Label.Arc_Gen_empty_table;

        return configTable;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Build configuration leveraged group table
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    18/11/2020
    * @param   Id accHasId - Account Has Analysis Record id
    * @return  Arc_Gen_DwpTableWrapper_Controller.Configuration_Table
    * @example Arc_Gen_DwpTableWrapper_Controller.Configuration_Table config = configLeveragedGpTable(accHasId);
    **/
    public static Arc_Gen_DwpTableWrapper_Controller.Configuration_Table configLeveragedGpTable(Id accHasId) {
        final Arc_Gen_DwpTableWrapper_Controller.Configuration_Table configTable = new Arc_Gen_DwpTableWrapper_Controller.Configuration_Table();
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasId);
        final List<arce__Account_has_Analysis__c> lstAccAha = arce.Arc_Gen_AccHasAnalysis_Data.getInfoforLeverTable(analysis.Id);

        final Map<String, Object> mapHeader = new Map<String, Object> {
            'name' => System.Label.Arc_Gen_ParticipantName,
            'afterAdj' => System.Label.Arc_Gen_LeveragedFlag,
            'leveragedType' => System.Label.Arc_Gen_LeveragedType
        };

        final Map<Id, Map<String, Object>> mapRows = new Map<Id, Map<String, Object>>();
        for (arce__Account_has_Analysis__c accAha : lstAccAha) {
            final Map<String, Object> mapRow = new Map<String, Object> {
            'name' => accAha.arce__participant_name__c,
            'afterAdj' => arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Account_has_analysis__c', 'arce__ll_after_adj_ind_type__c', accAha.arce__ll_after_adj_ind_type__c),
            'leveragedType' => arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Account_has_analysis__c', 'arce__ll_after_adj_clsfn_type__c', accAha.arce__ll_after_adj_clsfn_type__c)
            };
            mapRows.put(accAha.Id, mapRow);
        }
        configTable.mapHeader = mapHeader;
        configTable.mapRows = mapRows;
        configTable.editable = false;
        configTable.lblEmptyTable = System.Label.Arc_Gen_NoLeveragedSubsidiaries;

        return configTable;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Formats a decimal value
    --------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    23/11/2020
    * @param   amountToFormat - The amount to format
    * @return  the formatted value
    **/
    private static String formatAmount(Decimal amountToFormat) {
        return amountToFormat == null ? '' : amountToFormat.format();
    }
}