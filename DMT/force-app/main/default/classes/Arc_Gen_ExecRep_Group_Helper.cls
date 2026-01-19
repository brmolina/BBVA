/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Group_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-17-07
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper for Executive Summary Group visualforce
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-17-07 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-19 juanignacio.hita.contractor@bbva.com
*             Changes mapping rating value depending scale type
* |2021-01-25 juanpedro.benito.contractor@bbva.com
*             Changes format of decimal fields
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ExecRep_Group_Helper {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 27/07/2020
    * @param void
    * @return void
    * @example Arc_Gen_ExecRep_Group_Helper serviceHelper = new Arc_Gen_ExecRep_Group_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ExecRep_Group_Helper() {

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
        Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldTable = Arc_Gen_ShareholderTable_Service.getData(rid, new List<String>());
        if (shareHoldTable.hasInfo && shareHoldTable.columnsInfo.size() > 7) {
            genShareHoldTable(shareHoldTable);
        }
        return shareHoldTable;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description generate rows data of shareholder table
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2022-05-18
    * @param    Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldTable
    * @return   void
    * @example  genShareHoldTable(shareHoldTable);
    * -----------------------------------------------------------------------------------------------------
    */
    private static void genShareHoldTable(Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldTable) {
        for (integer i = 0; i <= shareHoldTable.columnsInfo.size() - 1; i++) {
            if (i > 6) {
                final List<String> val2Remove = new List<String>(shareHoldTable.columnsInfo);
                shareHoldTable.columnsInfo.remove(val2Remove[i]);
            }
        }
        final List<List<String>> newRowData = getRows2Show(shareHoldTable);
        shareHoldTable.rowData.clear();
        shareHoldTable.rowData = newRowData;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the row info to build the geographie and activitie table
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    List<Map<String,String>> rowStructure - row information
    * @param    List<String> columns -  columns information
    * @return   List<List<String>> to build the rows in the VF
    * @example  getRowDataLts(rowStructure, columns)
    * -----------------------------------------------------------------------------------------------------
    */
    public static List<List<String>> getRowDataLts(List<Map<String,String>> rowStructure, List<String> columns) {
        List<List<String>> rowDataLts = new List<List<String>>();
        integer k = 0;
        for (Map<String,String> geoActMap: rowStructure) {
            List<String> tempList = new List<String>();
            k = 0;
            for (String year: columns) {
                if (k == 0) {
                    tempList.add(geoActMap.get('geoAct'));
                    k++;
                }
                tempList.add(geoActMap.get(year));
            }
            rowDataLts.add(tempList);
        }
        return rowDataLts;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the row info to build the risk detailed table table
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    rid - Id of the account has analysis object
    * @return   Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow - Rows information
    * @example  getRows()
    * -----------------------------------------------------------------------------------------------------
    */
    public static List<Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow> getRows(Id rid) {
        List<Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow> rowDataLts = new List<Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow>();
        final Id arceId = arce.Arc_Gen_ArceAnalysis_Data.gerArce(rid).Id;
        final List<arce__Account_has_Analysis__c> allAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnforRiskDetTable(arceId);
        for (arce__Account_has_Analysis__c accHas: allAccHas) {
            Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow rowInfo = new Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow();
            if (accHas.arce__group_asset_header_type__c == '2') {
                rowInfo.name = accHas.arce__group_risk_detail_part_name__c;
                rowInfo.activity = accHas.arce__economic_activity_sector_desc__c;
                rowInfo.rating = Arc_Gen_FinInfoGroupTable_Service.getFinalRatingValue(accHas);
                rowInfo.bbvaShare = accHas.arce__bbva_financial_debt_share_per__c;
                rowInfo.lastApprove = getFormatDecField(accHas.arce__last_approved_amount__c);
                rowInfo.formalized = getFormatDecField(accHas.arce__current_formalized_amount__c);
                rowInfo.outstanding = getFormatDecField(accHas.arce__outstanding_amount__c);
                rowInfo.proposed = getFormatDecField(accHas.arce__current_proposed_local_amount__c);
                rowDataLts.add(rowInfo);
            }
        }
        for (arce__Account_has_Analysis__c accHas: allAccHas) {
            Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow rowInfo = new Arc_Gen_ExecRep_Group_Service.WrapRiskDetailRow();
            if (accHas.arce__group_asset_header_type__c == '1') {
                rowInfo.name = accHas.arce__group_risk_detail_part_name__c;
                rowInfo.activity = accHas.arce__economic_activity_sector_desc__c;
                rowInfo.rating = Arc_Gen_FinInfoGroupTable_Service.getFinalRatingValue(accHas);
                rowInfo.bbvaShare = accHas.arce__bbva_financial_debt_share_per__c;
                rowInfo.lastApprove = getFormatDecField(accHas.arce__last_approved_amount__c);
                rowInfo.formalized = getFormatDecField(accHas.arce__current_formalized_amount__c);
                rowInfo.outstanding = getFormatDecField(accHas.arce__outstanding_amount__c);
                rowInfo.proposed = getFormatDecField(accHas.arce__current_proposed_local_amount__c);
                rowDataLts.add(rowInfo);
            }
        }
        return rowDataLts;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description get the row info to build the risk detailed table table
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    rid - Id of the account has analysis object
    * @return   Arc_Gen_ExecRep_Group_Service.WrapLeverTableRow - Rows information
    * @example  getRowsLevTable(rid)
    * -----------------------------------------------------------------------------------------------------
    */
    public static List<Arc_Gen_ExecRep_Group_Service.WrapLeverTableRow> getRowsLevTable(Id rid) {
        List<Arc_Gen_ExecRep_Group_Service.WrapLeverTableRow> rowDataLts = new List<Arc_Gen_ExecRep_Group_Service.WrapLeverTableRow>();
        final Id arceId = arce.Arc_Gen_ArceAnalysis_Data.gerArce(rid).Id;
        final List<arce__Account_has_Analysis__c> allAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getInfoforLeverTable(arceId);
        for (arce__Account_has_Analysis__c accHas: allAccHas) {
            Arc_Gen_ExecRep_Group_Service.WrapLeverTableRow rowInfo = new Arc_Gen_ExecRep_Group_Service.WrapLeverTableRow();
            rowInfo.name = accHas.arce__participant_name__c;
            rowInfo.mark = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Account_has_Analysis__c', 'arce__ll_after_adj_ind_type__c', accHas.arce__ll_after_adj_ind_type__c == null ? '2' : accHas.arce__ll_after_adj_ind_type__c);
            rowInfo.type = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Account_has_Analysis__c', 'arce__ll_after_adj_clsfn_type__c', accHas.arce__ll_after_adj_clsfn_type__c);
            rowDataLts.add(rowInfo);
        }
        return rowDataLts;
    }
    /*-----------------------------------------------------------------------------------------------------
    *@Description return only 7 rows to show in the table
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-17-07
    * @param    shareHoldTable - wrapper of shareholder table for group
    * @return   return only 7 rows to show in the table
    * @example  getRows2Show(shareHoldTable)
    * -----------------------------------------------------------------------------------------------------
    */
    private Static List<List<String>> getRows2Show(Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldTable) {
        final List<List<String>> newRowDataLts = new List<List<String>>();
        for (List<String> lts: shareHoldTable.rowData) {
            List<String> auxLts = new List<String>();
            for (integer i = 0; i <= lts.size() - 1; i++) {
                if (i <= 6) {
                    auxLts.add(lts[i]);
                }
            }
            newRowDataLts.add(auxLts);
        }
        return newRowDataLts;
    }

    /*-----------------------------------------------------------------------------------------------------
    *@Description return format of Decimal fields
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanpedro.benito.contractor@bbva.com
    * @Date     2021-25-01
    * @param    getFormatDecField - change format of field
    * @return   return format of Decimal fields
    * @example  getFormatDecField(amount)
    * -----------------------------------------------------------------------------------------------------
    */
    private static String getFormatDecField (Decimal amount) {
        return amount == null ? null : amount.format();
    }
}