/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Service
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service for Executive Summary visualforce
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2020-03-30 mariohumberto.ramirez.contractor@bbva.com
*             Update method genPDF for HU Executive summary 4.0 - 1.3
* |2020-07-27 mariohumberto.ramirez.contractor@bbva.com
*             Update method genPDF for HU Executive summary Group
* |2020-08-07 juanigancio.hita.contractor@bbva.com
*             Added call infoAnalysis helper to genPDF method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-18 juanigancio.hita.contractor@bbva.com
*             Added call getRatingValue helper method
* |2020-12-03 moises.martinez.dominguez.contractor@bbva.com
*             Add methods querys for HU Executive summary Hotels
* |2021-04-21 brauliobaruchs.sanpedro.contractor@bbva.com
*             Added methods consult to add columns and data in agro table
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ExecRep_Service {
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_ExecRep_Service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-03
    * @param    null
    * @return   Arc_Gen_ExecRep_Service
    * @example  new Arc_Gen_ExecRep_Service()
    * */
    @TestVisible
    private Arc_Gen_ExecRep_Service() {}
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Page that control to build Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    Arc_Gen_ExecRepCtrl.WrapPDF wrappObj Objeto wrapper para generar pdf
    * @return    Arc_Gen_ExecRepCtrl.WrapPDF wrappObj Objeto wrapper para generar pdf
    * @example  Arc_Gen_ExecRepCtrl.WrapPDF GenPDF(Arc_Gen_ExecRepCtrl.WrapPDF wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.WrapPDF genPDF(Arc_Gen_ExecRepCtrl.WrapPDF wrappObj) {
        final Id rid= wrappObj.rid;
        Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj = wrappObj;
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.infoAnalysis(rid,newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.simpleQrys(rid,newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.createDataTipology(rid,newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.createFnHighlights(rid,newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.createFFSS(rid,newWrappObj);
        newWrappObj.ffssObj.matur = Arc_Gen_ExecRep_Service_Helper.fitMaturityData(newWrappObj.ffssObj.rtios, newWrappObj.ffssObj.matur);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.getDataOfPastAnalysis(rid, newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.getOfficeValue(rid, newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.tableContractQrys(rid, newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.tableDateQrys(rid, newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.tableCategoryQrys(rid, newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.tableProjectionQrys(rid, newWrappObj);
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.tableAgro(rid, newWrappObj);
        if (arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(rid) == 'Group') {
            newWrappObj.shareHoldTableGp = Arc_Gen_ExecRep_Group_Service.getShareHoldGpInfo(rid);
            newWrappObj.wrapGeoAct = Arc_Gen_ExecRep_Group_Service.getGeoActInfo(rid);
            newWrappObj.finInfoWrap = Arc_Gen_FinInfoGroupTable_Ctrl.getTableData(rid);
            newWrappObj.wrapRisDetTable = Arc_Gen_ExecRep_Group_Service.getGpRiskDetailInfo(rid);
            newWrappObj.wrapLeverTable = Arc_Gen_ExecRep_Group_Service.getLeveragedTableInfo(rid);
        }
        newWrappObj = Arc_Gen_ExecRep_Service_Helper.getRatingValues(rid, newWrappObj);
        return newWrappObj;
    }
}