/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRepCtrl
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-10
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class to obtain info in order to print exec Rep
* ------------------------------------------------------------------------------------------------
* @Changes
* |2020-01-24 luisruben.quinto.munoz@bbva.com
*             Added space end line
* |2020-01-24 mariohumberto.ramirez.contractor@bbva.com
*             Added new params to the wrapper pdf
* |2020-07-27 mariohumberto.ramirez.contractor@bbva.com
*             Update class for HU Executive summary Group
* |2020-08-07 juanigancio.hita.contractor@bbva.com
*             Added analysisType param to WrapPdf object
* |2020-11-18 juanigancio.hita.contractor@bbva.com
*             Added ratingVal param to WrapPdf object
* |2020-12-01 moises.martinez.dominguez.contractor@bbva.com
*             Added fields Template Hoteles
* |2020-12-15 joseluis.garcia4.contractor@bbva.com
*             Include "isOrphan" field to PDF wrapper.
* |2021-01-14 mariohumberto.ramirez.contractor@bbva.com
*             Include "levMark" field to PDF wrapper.
* |2021-04-21 brauliobaruchs.sanpedro.contractor@bbva.com
*             Added fields Agro table
* |2022-01-11 jose.hijar.contractor@bbva.com
*             Added arce__analysis__c obj to wrapper and remove analysis Id from it
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyFields')
public without sharing class Arc_Gen_ExecRepCtrl {
    /**
    *   wrapper Financial Statements
    * @author Ricardo Almanza
    */
    public WrapPDF wrapIns {get;set;}

    /**
    * ------------------------------------------------------------------------------------------------
    * @Name     WrapPDF
    * @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
    * @Date     Created: 2019-06-10
    * @Group    ARCE
    * ------------------------------------------------------------------------------------------------
    * @Description Class to Wrap results between SOC
    * ------------------------------------------------------------------------------------------------
    * @Changes
    * -----------------------------------------------------------------------------------------------
    */
    @SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields')
    public class WrapPDF {
        /**
        * Orphan indicator.
        * @author José Luis García
        */
        public Boolean isOrphan {get;set;}
        /**
        *   record Id
        * @author Ricardo Almanza
        */
        Public Id rid {get;set;}
        /**
        *   analysis type
        * @author Juan Ignacio Hita
        */
        Public String analysisType {get;set;}
        /**
        *   analysis id
        * @author Jose Hijar
        */
        public arce__analysis__c analysisObj {get;set;}
        /**
        *   Third Participant details
        * @author Ricardo Almanza
        */
        Public arce__Third_Participant_Details__c[] thrdPrtDtl {get;set;}
        /**
        *   main banks data
        * @author Ricardo Almanza
        */
        Public arce__main_banks__c[] mnBnks {get;set;}
        /**
        *   proposed amount
        * @author Ricardo Almanza
        */
        Public String crrentPropAmmt {get;set;}
        /**
        *   approved amount
        * @author Ricardo Almanza
        */
        Public String crrentApprvAmmt {get;set;}
        /**
        *   header table typologies
        * @author Ricardo Almanza
        */
        Public String[] headTipology {get;set;}
        /**
        *   header table modalities
        * @author Ricardo Almanza
        */
        Public String[] headMod {get;set;}
        /**
        *   header table financial highlights
        * @author Ricardo Almanza
        */
        Public String[] yearsFnHighlight {get;set;}
        /**
        *   data table typologies
        * @author Ricardo Almanza
        */
        Public List<List<String>> dataTipology {get;set;}
        /**
        *   data table Financial Highlights
        * @author Ricardo Almanza
        */
        Public List<List<String>> fnHighlights {get;set;}
        /**
        *   data table Modalities
        * @author Ricardo Almanza
        */
        Public List<List<String>> dataMod {get;set;}
        /**
        *   Object Financial Statements
        * @author Ricardo Almanza
        */
        Public WrappFFSS ffssObj {get;set;}
        /**
        *   @Description Shareholder table wrapper
        */
        Public Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldTableGp {get;set;}
        /**
        *   @Description Financial Information Group table wrapper
        */
        Public Arc_Gen_FinInfoGroupTable_Ctrl.FinInfoTableGp finInfoWrap {get;set;}
        /**
        *   @Description Financial Information Group table wrapper
        */
        Public Arc_Gen_ExecRep_Group_Service.WrapRiskDetail wrapRisDetTable {get;set;}
        /**
        *   @Description Leveraged Group table wrapper
        */
        Public Arc_Gen_ExecRep_Group_Service.WrapLeverTable wrapLeverTable {get;set;}
        /**
        * Rating value
        * @author Juan Ignacio Hita
        */
        Public String ratingVal {get;set;}
        /**
        *   Contracts Appraisals data
        * @author Moises Martinez
        */
        Public arce__contracts_and_appraisals__c[] contractsAppraisals {get;set;}
        /**
        *   Currency and Unit of Contracts Appraisals
        * @author Moises Martinez
        */
        Public arce__contracts_and_appraisals__c[] curUnitContract {get;set;}
        /**
        *   Analysis Date data
        * @author Moises Martinez
        */
        Public arce__hotel_analysis_date_period__c[] analysisDate {get;set;}
        /**
        *   Currency and Unit of Date
        * @author Moises Martinez
        */
        Public arce__hotel_analysis_date_period__c[] curUnitDate {get;set;}
        /**
        *   indicator template hoteles
        * @author Moises Martinez
        */
        Public arce__Account_has_Analysis__c template {get;set;}
        /**
        *   Analysis Category data
        * @author Moises Martinez
        */
        Public arce__hotel_analysis_category__c[] analysisCategory {get;set;}
        /**
        *   Currency and Unit of Category
        * @author Moises Martinez
        */
        Public arce__hotel_analysis_category__c[] curUnitCategory {get;set;}
        /**
        *   Analysis Projection data
        * @author Moises Martinez
        */
        Public arce__hotel_projection__c[] projection {get;set;}
        /**
        *   Currency and Unit of Projection
        * @author Moises Martinez
        */
        Public arce__hotel_projection__c[] curUnitProjection {get;set;}
        /**
        * ------------------------------------------------------------------------------------------------
        * @Description Constructor of WrapPDF to set recordId of Account has analysis
        * ------------------------------------------------------------------------------------------------
        * @param Id recordId of Account has analysis
        * @return Constructed Obj WrapPDF
        * @example new WrapPDF(ApexPages.currentPage().getParameters().get('Id'))
        * ------------------------------------------------------------------------------------------------
        **/
        public WrapPDF(Id accHasId) {
            rid = accHasId;
        }
        /**
        * Date of the maximum limit of the last Analysis
        */
        Public String maximumLimDate {get;set;}
        /**
        * Rating value of the last account has analysis
        */
        Public String currentBBVARating {get;set;}
        /**
        * value of the cr and office
        */
        Public String officeVal {get;set;}
        /**
        *   @Description wrapper for geographies and activities table
        */
        Public Arc_Gen_ExecRep_Group_Service.WrapGeoAct wrapGeoAct {get;set;}
        /**
        * @Description leveraged mark indicator
        */
        public String levMark {get;set;}
        /**
        *   @Description wrapper for new colums agro table
        */
        Public List<String> columsAgro {get;set;}
        /**
        *   @Description wrapper for new data agro table
        */
        Public List<List<String>> newData {get;set;}
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Name     WrappFFSS
    * @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
    * @Date     Created: 2019-07-15
    * @Group    ARCE
    * ------------------------------------------------------------------------------------------------
    * @Description Class to Wrap results for Financial Statements between SOC
    * ------------------------------------------------------------------------------------------------
    * @Changes
    * -----------------------------------------------------------------------------------------------
    */
    public class WrappFFSS {
        /**
        *   header table Balance 1
        * @author Ricardo Almanza
        */
        Public String[] yearsBalSh1 {get;set;}
        /**
        *   data table Balance 1
        * @author Ricardo Almanza
        */
        Public List<List<String>> balSh1 {get;set;}
        /**
        *   header table Balance 2
        * @author Ricardo Almanza
        */
        Public String[] yearsBalSh2 {get;set;}
        /**
        *   data table Balance 2
        * @author Ricardo Almanza
        */
        Public List<List<String>> balSh2 {get;set;}
        /**
        *   header table Income statement
        * @author Ricardo Almanza
        */
        Public String[] yearsIncmSt {get;set;}
        /**
        *   data table Income statement
        * @author Ricardo Almanza
        */
        Public List<List<String>> incmSt {get;set;}
        /**
        *   header table cash analysis
        * @author Ricardo Almanza
        */
        Public String[] yearsCshAn {get;set;}
        /**
        *   data table cash analysis
        * @author Ricardo Almanza
        */
        Public List<List<String>> cshAn {get;set;}
        /**
        *   header table ratios
        * @author Ricardo Almanza
        */
        Public String[] yearsRtios {get;set;}
        /**
        *   data table ratios
        * @author Ricardo Almanza
        */
        Public List<List<String>> rtios {get;set;}
        /**
        *   header table maturity
        * @author Ricardo Almanza
        */
        Public String[] yearsMatur {get;set;}
        /**
        *   data table maturity
        * @author Ricardo Almanza
        */
        Public List<List<String>> matur {get;set;}
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Constructor of Arc_Gen_ExecRepCtrl to obtain data in order to print PDF
    * ------------------------------------------------------------------------------------------------
    * @param ApexPages.StandardController controller Control of Apex page to print VF
    * @return Constructed Obj Arc_Gen_ExecRepCtrl
    * @example Arc_Gen_ExecRepCtrl(ApexPages.StandardController controller)
    * ------------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_ExecRepCtrl(ApexPages.StandardController controller) {
        if (!Test.isRunningTest()) {
            controller.addFields(new List<String>{'arce__cust_economic_position_desc__c', 'arce__gf_cmnt_fin_re_solv_co_desc__c'});
        }
        WrapPDF wrappObj = new WrapPDF(Id.valueOf(controller.getRecord().Id));
        wrappObj = Arc_Gen_ExecRep_Service.genPDF(wrappObj);
        relateWrapperVars(wrappObj);
    }
    private void relateWrapperVars(WrapPDF wrappObj) {
        wrapIns = wrappObj;
    }
}