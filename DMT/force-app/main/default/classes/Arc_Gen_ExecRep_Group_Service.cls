/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Group_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-17-07
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service for Executive Summary Group visualforce
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-17 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-11-20 juanignacio.hita.contractor@bbva.com
*             Change label rating column of getGpRiskDetailInfo method
* |2020-11-20 joseluis.garcia4.contractor@bbva.com
*             Changes rating column label.
* |2021-01-25 juanpedro.benito.contractor@bbva.com
*             Changes type of Decimal fields
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class Arc_Gen_ExecRep_Group_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 27/07/2020
    * @param void
    * @return void
    * @example Arc_Gen_ExecRep_Group_Service serviceHelper = new Arc_Gen_ExecRep_Group_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ExecRep_Group_Service() {

    }
    /*
    * @Description wrapper for geographies and activities table
    */
    public class WrapGeoAct {
        /*
        * @Description columns info for geographies and activities table
        */
        public List<String> columnsGeo {get;set;}
        /*
        * @Description columns info for geographies and activities table
        */
        public List<String> columnsAct {get;set;}
        /*
        * @Description row info for geographies and activities table
        */
        public List<List<String>> rowDataGeo {get;set;}
        /*
        * @Description row info for geographies and activities table
        */
        public List<List<String>> rowDataAct {get;set;}
        /*
        * @Description boolean to know if there are info for geographie table
        */
        public Boolean geoTableHasInfo {get;set;}
        /*
        * @Description boolean to know if there are info for activity table
        */
        public Boolean actTableHasInfo {get;set;}
    }
    /*
    * @Description wrapper for risk detail table group
    */
    public class WrapRiskDetailRow {
    /**
    * @Description: String with the participant name in the table
    */
    @AuraEnabled public String name {get;set;}
    /**
    * @Description: String with the activity in the table
    */
    @AuraEnabled public String activity {get;set;}
    /**
    * @Description: String with the rating in the table
    */
    @AuraEnabled public String rating {get;set;}
    /**
    * @Description: value of the bbvaShare
    */
    @AuraEnabled public Decimal bbvaShare {get;set;}
    /**
    * @Description: value of last approve amount
    */
    @AuraEnabled public String lastApprove {get;set;}
    /**
    * @Description: value of formalized amount
    */
    @AuraEnabled public String formalized {get;set;}
    /**
    * @Description: value of outstanding amount
    */
    @AuraEnabled public String outstanding {get;set;}
    /**
    * @Description: value of proposed amount
    */
    @AuraEnabled public String proposed {get;set;}
    }
    /*
    * @Description wrapper for leveraged table group
    */
    public class WrapLeverTableRow {
        /**
        * @Description: String with the participant name in the table
        */
        @AuraEnabled public String name {get;set;}
        /**
        * @Description: String with the leveraged mark in the table
        */
        @AuraEnabled public String mark {get;set;}
        /**
        * @Description: String with the leveraged type in the table
        */
        @AuraEnabled public String type {get;set;}
        }
    /*
    * @Description wrapper for risk detail table group
    */
    public class WrapRiskDetail {
        /*
        * @Description columns info for risk detail table
        */
        public List<String> columns {get;set;}
        /*
        * @Description columns info for risk detail table
        */
        public List<WrapRiskDetailRow> rows {get;set;}
    }
    /*
    * @Description wrapper for leveraged table group
    */
    public class WrapLeverTable {
        /*
        * @Description columns info for leveraged table
        */
        public List<String> columns {get;set;}
        /*
        * @Description columns info for leveraged table
        */
        public List<WrapLeverTableRow> rows {get;set;}
        /*
        * @Description show table variable
        */
        public Boolean showInfo {get;set;}
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the info to build the share holder table for group
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    rid - Id of the account has analysis object
    * @return   Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp newWrappObj
    * @example  getShareHoldGpInfo(rid)
    * -----------------------------------------------------------------------------------------------------
    */
    public static Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp getShareHoldGpInfo(Id rid) {
        return Arc_Gen_ExecRep_Group_Helper.getShareHoldGpInfo(rid);
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the info to build the geographie and activitie table
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    rid - Id of the account has analysis object
    * @return   WrapGeoAct wrapGeoActTb
    * @example  getGeoActInfo(rid)
    * -----------------------------------------------------------------------------------------------------
    */
    public static WrapGeoAct getGeoActInfo(Id rid) {
        WrapGeoAct wrapGeoActTb = new WrapGeoAct();
        wrapGeoActTb.columnsGeo = Arc_Gen_TableContentPerAnalysis_Data.getColumnsOfGeoActTb(rid, '05');
        wrapGeoActTb.columnsAct = Arc_Gen_TableContentPerAnalysis_Data.getColumnsOfGeoActTb(rid, '06');
        final List<Map<String,String>> rowStructureGeo = Arc_Gen_TableContentPerAnalysis_Data.getGeoActRowStructure(rid, '05', wrapGeoActTb.columnsGeo);
        final List<Map<String,String>> rowStructureAct = Arc_Gen_TableContentPerAnalysis_Data.getGeoActRowStructure(rid, '06', wrapGeoActTb.columnsAct);
        final List<List<String>> rowDataGeo = Arc_Gen_ExecRep_Group_Helper.getRowDataLts(rowStructureGeo, wrapGeoActTb.columnsGeo);
        final List<List<String>> rowDataAct = Arc_Gen_ExecRep_Group_Helper.getRowDataLts(rowStructureAct, wrapGeoActTb.columnsAct);
        List<String> columnInfoGeo = new List<String>{''};
        List<String> columnInfoAct = new List<String>{''};
        columnInfoGeo.addAll(wrapGeoActTb.columnsGeo);
        columnInfoAct.addAll(wrapGeoActTb.columnsAct);
        wrapGeoActTb.columnsGeo = columnInfoGeo;
        wrapGeoActTb.rowDataGeo = rowDataGeo;
        wrapGeoActTb.columnsAct = columnInfoAct;
        wrapGeoActTb.rowDataAct = rowDataAct;
        return wrapGeoActTb;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the info to build the risk detail table for group
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    rid - Id of the account has analysis object
    * @return   WrapGeoAct wrapGeoActTb
    * @example  getGpRiskDetailInfo(rid)
    * -----------------------------------------------------------------------------------------------------
    */
    public static WrapRiskDetail getGpRiskDetailInfo(Id rid) {
        WrapRiskDetail wrapperTable = new WrapRiskDetail();
        wrapperTable.columns = new List<String>{Label.Arc_Gen_ParticipantName, Label.Arc_Gen_ColumnHeader_Activity, Label.Arc_Gen_RatingGroupRisk,
                                Label.Arc_Gen_FinancialDebtShare, Label.Arc_Gen_Last_Approved, Label.Arc_Gen_Formalized, Label.Arc_Gen_Outstanding,
                                Label.Arc_Gen_Proposed};
        wrapperTable.rows = Arc_Gen_ExecRep_Group_Helper.getRows(rid);
        return wrapperTable;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the info to build the leveraged table for group
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    rid - Id of the account has analysis object
    * @return   WrapRiskDetail wrapGeoActTb
    * @example  getGpRiskDetailInfo(rid)
    * -----------------------------------------------------------------------------------------------------
    */
    public static WrapLeverTable getLeveragedTableInfo(Id rid) {
        WrapLeverTable wrapperLeveraged = new WrapLeverTable();
        wrapperLeveraged.showInfo = false;
        wrapperLeveraged.columns = new List<String>{Label.Arc_Gen_ParticipantName, Label.Arc_Gen_LeveragedFlag, Label.Arc_Gen_LeveragedType};
        wrapperLeveraged.rows = Arc_Gen_ExecRep_Group_Helper.getRowsLevTable(rid);
        if (wrapperLeveraged.rows.size() > 0) {
            wrapperLeveraged.showInfo = true;
        }
        return wrapperLeveraged;
    }
}