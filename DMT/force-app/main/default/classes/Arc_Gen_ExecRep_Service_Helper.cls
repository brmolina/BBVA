/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Service_Helper
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service helper for Executive Summary visualforce
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2019-07-23 ricardo.almanza.contractor@bbva.com
*             modification for modalities.
* |2019-10-10 ricardo.almanza.contractor@bbva.com
*             modification for null values.
* |2019-10-21 ricardo.almanza.contractor@bbva.com
*             modification for alignment.
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |2019-12-02 ricardo.almanza.contractor@bbva.com
*             modification for tipology level id, added tipologyTCrR,tipologyTCoR and tipologyPrFn.
* |2020-01-17 jhovanny.delacruz.cruz@bbva.com
*             Format is added to the amounts
* |2020-01-24 luisruben.quinto.munoz@bbva.com
*             delete percentage in balace tables of cash flows
* |2020-01-30 javier.soto.carrascosa@bbva.com
*             Add HU 787 missing functionality
* |2020-03-04 cesaroctavio.villanueva.cebal@bbva.com
*             Added formatting to proposed and approved ammounts
* |2020-03-30 mariohumberto.ramirez.contractor@bbva.com
*             Update class for HU Executive summary 4.0 - 1.3
* |2020-08-09 mariohumberto.ramirez.contractor@bbva.com
*             Updated getDataOfPastAnalysis method
* |2020-08-07 juanigancio.hita.contractor@bbva.com
*             Created infoAnalysis method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-18 juanigancio.hita.contractor@bbva.com
*             Created getRatingValue method
* |2020-12-03 moises.martinez.dominguez.contractor@bbva.com
*             Add methods query for tables record HU Hotels
* |2020-12-15 joseluis.garcia4.contractor@bbva.com
*             Include "isOrphan" field to PDF wrapper.
* |2021-01-14 mariohumberto.ramirez.contractor@bbva.com
*             Include "levMark" field to PDF wrapper.
* |2021-04-21 brauliobaruchs.sanpedro.contractor@bbva.com
*             Added methods consult to add columns and data in agro table about Arc_Gen_evol_main_prod_agro_Locator
* |2022-01-11 jose.hijar.contractor@bbva.com
*             Add arce__Analysis__c obj to wrapper and remove analysis Id from wrapper in method infoAnalysis
*             Adjust createDataTipology method for new object arce__Analysis__c in wrapper
*             Add logic based on analysis state for populating crrentApprvAmmt wrapper field @setDataTipology method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods')
global with sharing class Arc_Gen_ExecRep_Service_Helper implements pdfp.GBL_PDFviewer_Interface {
    /**
    *   tipology TOTAL CREDIT RISK
    * @author Ricardo Almanza
    */
    Static String tipologyTCrR= 'TP_0006';
    /**
    *   tipology TOTAL CORPORATE RISK
    * @author Ricardo Almanza
    */
    Static String tipologyTCoR= 'TP_0003';
    /**
    *   tipology Project Finance
    * @author Ricardo Almanza
    */
    Static String tipologyPrFn= 'TP_0013';
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Page that pass parameters and encode pdf in 64 base
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    recordId account_has_analysis related with Executive Summary
    * @return   String base 64 encode of apex page of Executive Summary
    * @example  getPDFinBase64(recordId);
    * */
    global String getPDFinBase64(Id recordId) {
        Blob docBlob;
        PageReference templateVF = Page.Arc_Gen_ExecRepVF;
        templateVF.getParameters().put('Id', recordId);
        templateVF.setRedirect(true);
        try {
            docBlob = templateVF.getContentAsPDF();
        } catch(VisualforceException e) {
            docBlob = Blob.valueOf(Label.Arc_Gen_ExecRepErrPDF + e);
        }
        return EncodingUtil.base64Encode(docBlob);
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain information of the analysis related with the AHA
    * -----------------------------------------------------------------------------------------------------
    * @Author   Juan Ignacio Hita Manso
    * @Date     2020-08-07
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRepCtrl.wrapPDF wrap = Arc_Gen_ExecRep_Service_Helper.infoAnalysis(rid,wrappObj);
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF infoAnalysis(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(rid);
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id> { aha.arce__Analysis__c })[0];
        wrappObj.analysisType = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__anlys_wkfl_sub_process_type__c', analysis.arce__anlys_wkfl_sub_process_type__c);
        wrappObj.isOrphan = analysis.arce__analysis_customer_relation_type__c == arce.Arc_Gen_Constants.CUSTOMER_RELATION_ORPHAN;
        wrappObj.analysisObj = analysis;
        wrappObj.levMark = aha.arce__ll_after_adj_ind_type__c == '1' ? Label.Arc_Gen_Yes : Label.Arc_Gen_No;
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain simple query of related objects to the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.simpleQrys(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF simpleQrys(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        wrappObj.thrdPrtDtl = Arc_Gen_ThirdParticipantDetails_Data.getThirdParticipantDetails(rid);
        wrappObj.mnBnks = Arc_Gen_MainBanks_Data.getMainBanks(rid);
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Financial Highlights of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.createFnHighlights(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF createFnHighlights(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        final WrappFFSS fnHighlights = processFFSS(new WrappFFSS(Label.Arc_Gen_ExecRepTechnicalFinancialGrouping,false),Arc_Gen_TableContentPerAnalysis_Data.execRepGetFnHighlights(rid));
        wrappObj.yearsFnHighlight = fnHighlights.years;
        wrappObj.fnHighlights = fnHighlights.data;
        return wrappObj;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Name     WrappFFSS
    * @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
    * @Date     Created: 2019-07-16
    * @Group    ARCE
    * ------------------------------------------------------------------------------------------------
    * @Description Class to Wrap results for FFSS
    * ------------------------------------------------------------------------------------------------
    * @Changes
    * -----------------------------------------------------------------------------------------------
    */
    private class WrappFFSS {
        /**
        *   array of years to group
        * @author Ricardo Almanza
        */
        public String[] years {get;set;}
        /**
        *   data of tables
        * @author Ricardo Almanza
        */
        public List<List<String>> data {get;set;}
        /**
        *   grouping on the query
        * @author Ricardo Almanza
        */
        public String grping {get;set;}
        /**
        *   boolean for percentage
        * @author Ricardo Almanza
        */
        public Boolean perc {get;set;}
        /**
        * ------------------------------------------------------------------------------------------------
        * @Description Constructor of WrappFFSS
        * ------------------------------------------------------------------------------------------------
        * @return Constructed Obj wrapPDF
        * @example new WrappFFSS()
        * ------------------------------------------------------------------------------------------------
        **/
        public WrappFFSS(String grp, Boolean percent) {
            grping = grp;
            perc = percent;
        }
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to add rows to Financial Statements
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-16
    * @param    dtColl Map of Data to add
    * @param    wrappObj object with related objects to get FFSS
    * @param    mpFnHighlights Map of Financial Highlights
    * @return   WrappFFSS Object with related data to get FFSS
    * @example  addrows(dtColl,wrappObj,mpFnHighlights)
    * */
    private static WrappFFSS addrows(Map<String,String> dtColl, WrappFFSS wrappObj,Map<String,Map<String,List<String>>> mpFnHighlights) {
        String rwNm;
        wrappObj.data = new List<List<String>>();
        List<String> rowToAdd;
        Boolean firstData,percData;
        for(String rw : dtColl.keySet()) {
            rowToAdd = new List<String>();
            for(String data : wrappObj.years) {
                firstData = data == Label.Arc_Gen_ExecRepHighScale;
                percData = data.contains('%');
                rwNm = firstData ? dtColl.get(rw) : rwNm;
                String val;
                try {
                    val = percData ? mpFnHighlights.get(data).get(rwNm)[0] : mpFnHighlights.get(data).get(rwNm)[1];
                } catch (NullPointerException nlex) {//NOSONAR
                    val = '-';
                }
                rowToAdd.add(firstData ? rwNm : val);
            }
            wrappObj.data.add(rowToAdd);
        }
        return fixPercYears(wrappObj);
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to process Financial Statements
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-16
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to get FFSS
    * @param    data2Process Aggregate result list of FFSS
    * @return   WrappFFSS Object with related data to get FFSS
    * @example  processFFSS(rid,new WrappFFSS(),Arc_Gen_TableContentPerAnalysis_Data.execRepGetFnHighlights(rid))
    * */
    private static WrappFFSS processFFSS(WrappFFSS wrappObj,AggregateResult[] data2Process) {
        Map<String,Map<String,List<String>>> mpFnHighlights = new Map<String,Map<String,List<String>>>();
        Map<String,String> dtColl = new Map<String,String>();
        Map<String,List<String>> datVal;
        List<String> vals;
        String year,dat,val1,val2,perval;
        perval='%';
        for(AggregateResult cntPrAn : data2Process) {
            year = String.valueOf(cntPrAn.get('arce__table_content_year__c'));
            dat = String.valueOf(cntPrAn.get('data'));
            val1 = notNull(cntPrAn,'val1');
            val2 = notNull(cntPrAn,'val2');
            datVal = mpFnHighlights.containsKey(year) ? mpFnHighlights.get(year) : new Map<String,List<String>>();
            vals = new List<String>();
            vals.add(val1);
            vals.add(val2);
            datVal.put(dat,vals);
            mpFnHighlights.put(year, datVal);
            if(wrappObj.perc) {
                mpFnHighlights.put(year+perval, datVal);
            }
            dtColl.put(String.valueOf(cntPrAn.get(wrappObj.grping)),dat);
        }
        wrappObj.years = new List<String>();
        wrappObj.years.add(Label.Arc_Gen_ExecRepHighScale);
        wrappObj.years.addAll(mpFnHighlights.keySet());
        return addrows(dtColl,wrappObj,mpFnHighlights);
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
    private static String notNull(AggregateResult cntPrAn,String varName) {
        return 'nm'+Decimal.valueOf(String.valueOf(cntPrAn.get(varName) == null ? 0 : cntPrAn.get(varName))).format();
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to fix percentage years to only show percentage symbol
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-22
    * @param    wrappObj WrappFFSS wrapper class to process FFSS
    * @return   wrappObj WrappFFSS wrapper class to process FFSS with percentage symbol if percentage selected
    * @example  fixPercYears(wrappObj)
    * */
    private static WrappFFSS fixPercYears(WrappFFSS wrappObj) {
        List<String> yrsFixPerc;
        final String perval = '%';
        String year = '';
        if(wrappObj.perc) {
            yrsFixPerc = new List<String>();
            for(String data : wrappObj.years) {
                year = data.contains('%') ? perval : data;
                yrsFixPerc.add(year);
            }
            wrappObj.years = yrsFixPerc;
        }
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Financial Statements
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-16
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.createFFSS(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF createFFSS(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        //arce__collection_table__c = '07' AND arce__arce_collection_order_number__c  < 71550
        final WrappFFSS balanceSheet1MA = processFFSS(new WrappFFSS(Label.Arc_Gen_ExecRepTechnicalFinancialGrouping,true),Arc_Gen_TableContentPerAnalysis_Data.execRepGetTblsRelatedArce(rid, 'ltt', '07', 71550));
        wrappObj.ffssObj = new Arc_Gen_ExecRepCtrl.wrappFFSS();
        wrappObj.ffssObj.yearsBalSh1 = balanceSheet1MA.years;
        wrappObj.ffssObj.balSh1 = balanceSheet1MA.data;
        //arce__collection_table__c = '07' AND arce__arce_collection_order_number__c  > 71550
        final WrappFFSS balanceSheet2MA = processFFSS(new WrappFFSS(Label.Arc_Gen_ExecRepTechnicalFinancialGrouping,true),Arc_Gen_TableContentPerAnalysis_Data.execRepGetTblsRelatedArce(rid, 'gtt', '07', 71550));
        wrappObj.ffssObj.yearsBalSh2 = balanceSheet2MA.years;
        wrappObj.ffssObj.balSh2 = balanceSheet2MA.data;
        //arce__collection_table__c = '03'
        final WrappFFSS incomeStatementMA = processFFSS(new WrappFFSS(Label.Arc_Gen_ExecRepTechnicalFinancialGrouping,true),Arc_Gen_TableContentPerAnalysis_Data.execRepGetTblsRelatedArce(rid, 'non', '03', 0));
        wrappObj.ffssObj.yearsIncmSt = incomeStatementMA.years;
        wrappObj.ffssObj.incmSt = incomeStatementMA.data;
        //arce__collection_table__c = '04'
        final WrappFFSS cashFlowMA = processFFSS(new WrappFFSS(Label.Arc_Gen_ExecRepTechnicalFinancialGrouping,false),Arc_Gen_TableContentPerAnalysis_Data.execRepGetTblsRelatedArce(rid, 'non', '04', 0));
        wrappObj.ffssObj.yearsCshAn = cashFlowMA.years;
        wrappObj.ffssObj.cshAn = cashFlowMA.data;
        //arce__collection_table__c = '02'
        final WrappFFSS rtiosMagnMA = processFFSS(new WrappFFSS(Label.Arc_Gen_ExecRepTechnicalFinancialGrouping,false),Arc_Gen_TableContentPerAnalysis_Data.execRepGetTblsRelatedArce(rid, 'non', '02', 0));
        wrappObj.ffssObj.yearsRtios = rtiosMagnMA.years;
        wrappObj.ffssObj.rtios = rtiosMagnMA.data;
        //arce__collection_table__c ='01'
        final WrappFFSS maturityMA = processFFSS(new WrappFFSS('Name',false),Arc_Gen_TableContentPerAnalysis_Data.execRepGetTblsRelatedArce(rid, 'mat', '01', 0));
        wrappObj.ffssObj.yearsMatur = maturityMA.years;
        wrappObj.ffssObj.matur = maturityMA.data;
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Tipology of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.createDataTipology(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF createDataTipology(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        final string arceStage = wrappObj.analysisObj.arce__anlys_wkfl_sanction_rslt_type__c;
        Arc_Gen_ExecRepCtrl.wrapPDF wrappObj2 = wrappObj;
        wrappObj2.headTipology = createHeadTipo(arceStage);
        final arce__limits_exposures__c[] lmtsExp = arce.Arc_Gen_LimitsExposures_Data.tipologyL1(rid);
        Map<Id,arce__limits_exposures__c> lmtsExpFathMap = new Map<Id,arce__limits_exposures__c>();
        for(arce__limits_exposures__c tipo : lmtsExp) {
            lmtsExpFathMap.put(tipo.Id,tipo);
        }
        TipologyL2Cl tipo2 = createTipologyL2(rid);
        Map<Id,arce__limits_exposures__c[]> lmtsExpChldMap = tipo2.lmtsExpChldMap;
        final List<arce__limits_exposures__c> auxListL3 = getLevel3(rid);
        for (arce__limits_exposures__c chld : auxListL3) {
            final List<arce__limits_exposures__c> chldLst = lmtsExpChldMap.get(chld.arce__limits_exposures_parent_id__c) == null ? new List<arce__limits_exposures__c>() : lmtsExpChldMap.get(chld.arce__limits_exposures_parent_id__c);
            chldLst.add(chld);
            lmtsExpChldMap.put(chld.arce__limits_exposures_parent_id__c,chldLst);
        }
        lmtsExp.addAll(auxListL3);
        wrappObj2 = setDataTipology(wrappObj2,lmtsExp,lmtsExpChldMap,arceStage);
        final TipologyL2Cl modal = createModal(rid);
        wrappObj2.headMod = createHeadMod(arceStage);
        final List<Map<Id,arce__limits_exposures__c[]>> lstMapsRelated = new List<Map<Id,arce__limits_exposures__c[]>>();
        lstMapsRelated.add(lmtsExpChldMap);
        lstMapsRelated.add(modal.lmtsExpChldMap);
        wrappObj2 = setDataModal(wrappObj2,lmtsExp,lstMapsRelated,arceStage);
        return wrappObj2;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to set Data tipologies for Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    wrappObj object with related objects to build PDF
    * @param    lmtsExp Limit exposure base to get tipology
    * @param    lmtsExpChldMap Map of related tipologies
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  setDataTipology(wrappObj,lmtsExp,lmtsExpChldMap)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF setDataTipology(Arc_Gen_ExecRepCtrl.wrapPDF wrappObj,arce__limits_exposures__c[] lmtsExp,Map<Id,arce__limits_exposures__c[]> lmtsExpChldMap,String arceStage) {
        wrappObj.dataTipology = new List<List<String>>();
        List<String> rowTyp;
        Map<String, String> addAttr = new Map<String, String>();
        final String toProposeAssign = arce.Arc_Gen_LimitsExposures_Data.getExposureByDevName(new List<Id>{wrappObj.rid}, new List<String>{tipologyPrFn})[0].arce__current_proposed_amount__c == 0 ? tipologyTCoR : tipologyTCrR;
        for(arce__limits_exposures__c tipo : lmtsExp) {
            rowTyp = createRowLim(tipo,'L1',false,arceStage);
            wrappObj.dataTipology.add(rowTyp);
            final String tipoId = tipo.arce__limits_typology_id__r.arce__risk_typology_level_id__c;
            final String porpAmmt = tipo.arce__current_proposed_amount__c == null ? '0': String.valueOf(tipo.arce__current_proposed_amount__c.format());
            if(tipoId == toProposeAssign) {
                wrappObj.crrentPropAmmt = porpAmmt;
                if (wrappObj.analysisObj.arce__Stage__c == '3' && wrappObj.analysisObj.arce__wf_status_id__c == '10'){
                    wrappObj.crrentApprvAmmt = porpAmmt;
                }
            }
            addAttr.put('level', 'L1');
            addAttr.put('arceStage', arceStage);
            wrappObj.dataTipology = addRelatedChld(wrappObj.dataTipology,lmtsExpChldMap,tipo.Id,addAttr);
        }
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to set Data modalities for Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    wrappObj object with related objects to build PDF
    * @param    lmtsExp Limit exposure base to get tipology
    * @param    lmtsExpChldMap List of Maps of related tipologies and modalities
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  setDataModal(wrappObj,lmtsExp,lstMapsRelated)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF setDataModal(Arc_Gen_ExecRepCtrl.wrapPDF wrappObj,arce__limits_exposures__c[] lmtsExp,List<Map<Id,arce__limits_exposures__c[]>> lmtsExpChldMap,String arceStage) {
        wrappObj.dataMod = new List<List<String>>();
        List<String> rowTyp;
        for(arce__limits_exposures__c tipo : lmtsExp) {
            Map<String, String> addAttr = new Map<String, String>();
            rowTyp = createRowLim(tipo,'L1',true,arceStage);
            wrappObj.dataMod.add(rowTyp);
            addAttr.put('level', 'L1');
            addAttr.put('arceStage', arceStage);
            wrappObj.dataMod = addRelatedChldMod(wrappObj.dataMod,lmtsExpChldMap,tipo.Id,addAttr);
        }
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Tipology Level 2
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    recordId account_has_analysis related with Executive Summary
    * @return   TipologyL2Cl Object to Wrap List of tipologys
    * @example  createTipologyL2(rid)
    * */
    private static TipologyL2Cl createTipologyL2(Id rid) {
        final Map<Id,arce__limits_exposures__c> lmtsMapParKid = new Map<Id,arce__limits_exposures__c>();
        final Map<Id,arce__limits_exposures__c[]> lmtsExpChldMap = new Map<Id,arce__limits_exposures__c[]>();
        arce__limits_exposures__c[] chldLst;
        for(arce__limits_exposures__c chld : arce.Arc_Gen_LimitsExposures_Data.tipologyL2(rid)) {
            chldLst = lmtsExpChldMap.get(chld.arce__limits_exposures_parent_id__c) == null ? new List<arce__limits_exposures__c>() : lmtsExpChldMap.get(chld.arce__limits_exposures_parent_id__c);
            chldLst.add(chld);
            lmtsExpChldMap.put(chld.arce__limits_exposures_parent_id__c,chldLst);
            lmtsMapParKid.put(chld.Id,chld);
        }
        return new TipologyL2Cl(lmtsMapParKid,lmtsExpChldMap);
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Modal and related to parent
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    recordId account_has_analysis related with Executive Summary
    * @return   TipologyL2Cl Object to Wrap List of modalities
    * @example  createModal(rid)
    * */
    private static TipologyL2Cl createModal(Id rid) {
        final Map<Id,arce__limits_exposures__c> lmtsFatChldhMap = new Map<Id,arce__limits_exposures__c>();
        final Map<Id,arce__limits_exposures__c[]> lmtsExpChldMap = new Map<Id,arce__limits_exposures__c[]>();
        arce__limits_exposures__c[] chldLst;
        for(arce__limits_exposures__c chld : arce.Arc_Gen_LimitsExposures_Data.modalityFull(rid)) {
            chldLst = lmtsExpChldMap.get(chld.arce__limits_exposures_parent_id__c) == null ? new List<arce__limits_exposures__c>() : lmtsExpChldMap.get(chld.arce__limits_exposures_parent_id__c);
            chldLst.add(chld);
            lmtsExpChldMap.put(chld.arce__limits_exposures_parent_id__c,chldLst);
            lmtsFatChldhMap.put(chld.Id,chld);
        }
        return new TipologyL2Cl(lmtsFatChldhMap,lmtsExpChldMap);
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Name     TipologyL2Cl
    * @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
    * @Date     Created: 2019-06-10
    * @Group    ARCE
    * ------------------------------------------------------------------------------------------------
    * @Description Class to Wrap List of tipologys
    * ------------------------------------------------------------------------------------------------
    * @Changes
    * -----------------------------------------------------------------------------------------------
    */
    private class TipologyL2Cl {
        Map<Id,arce__limits_exposures__c> lmtsExpFatChldhMap;
        Map<Id,arce__limits_exposures__c[]> lmtsExpChldMap;
        /**
        * ------------------------------------------------------------------------------------------------
        * @Description Constructor of TipologyL2Cl to set Lists of tipologys
        * ------------------------------------------------------------------------------------------------
        * @param Map<Id,arce__limits_exposures__c> fatChldhMap Map to relate father and child tipologys
        * @param Map<Id,arce__limits_exposures__c[]> chldMap Map of L2 tipologys
        * @return Constructed Obj TipologyL2Cl
        * @example new TipologyL2Cl(lmtsExpFatChldhMap,lmtsExpChldMap)
        * ------------------------------------------------------------------------------------------------
        **/
        private TipologyL2Cl(Map<Id,arce__limits_exposures__c> fatChldhMap, Map<Id,arce__limits_exposures__c[]> chldMap) {
            lmtsExpFatChldhMap = fatChldhMap;
            lmtsExpChldMap = chldMap;
        }
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Header Tipology of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    null
    * @return   List<String> header of tipology object
    * @example  createHeadTipo()
    * */
    private static List<String> createHeadTipo(String arceStage) {
        final List<String> head = new List<String>();
        head.add(System.Label.Arc_Gen_Last_Approved);
        head.add(System.Label.Arc_Gen_Current_limit);
        head.add(System.Label.Arc_Gen_Outstanding);
        head.add(arceStage == '1' || arceStage == '2' ? System.Label.Arc_Gen_Proposed_Approved : System.Label.Arc_Gen_Proposed);
        return head;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Header Modalities of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    null
    * @return   List<String> header of Modalities object
    * @example  createHeadMod()
    * */
    private static Set<String> clnHeadersMod(String arceStage) {
        final Set<String> headers = new Set<String>();
        headers.add('arce__last_approved_amount__c');
        headers.add('arce__outstanding_amount__c');
        headers.add(arceStage == '1' || arceStage == '2' ? 'arce__current_proposed_amount__c' : 'arce__current_proposed_amount__c');
        headers.add('arce__curr_apprv_deleg_dchan_amount__c');
        headers.add('arce__curr_apprv_deleg_rm_amount__c');
        headers.removeAll(Label.Arc_Gen_ExecRepModalityExclApis.split(','));
        return headers;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain Header Modalities of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    null
    * @return   List<String> header of Modalities object
    * @example  createHeadMod()
    * */
    private static List<String> createHeadMod(String arceStage) {
        // final List<String> headMod = new List<String>();
        // headMod.addAll(arce.Arc_Gen_LimitsExposures_Data.getLabels(new List<String>(clnHeadersMod(arceStage))));
        // return headmod;

        final List<String> head = new List<String>();
        head.add(System.Label.Arc_Gen_Last_Approved);
        head.add(System.Label.Arc_Gen_Outstanding);
        head.add(arceStage == '1' || arceStage == '2' ? System.Label.Arc_Gen_Proposed_Approved : System.Label.Arc_Gen_Proposed);

        return head;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to add related Tipology of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    dataTipology to modify and add childs
    * @param    relList list of childs to add
    * @param    llave key of the map of childs
    * @param    level Order of tipology
    * @return   List<List<String>> dataTipology to display on Executive Summary
    * @example  addRelatedChld(wrappObj.dataTipology,lmtsExpChldMap,tipo.Id,'L1')
    * */
    private static List<List<String>> addRelatedChld(List<List<String>> dataTipology, Map<Id,arce__limits_exposures__c[]> relList, Id llave, Map<String,String> addAttr) {
        List<String> rowTyp;
        String newLevel = addAttr.get('level');
        final string arceStage = addAttr.get('arceStage');
        if(relList.containsKey(llave)) {
            for(arce__limits_exposures__c chld : relList.get(llave)) {
                if (chld.arce__limits_exposures_parent_id__c == null){
                    newLevel = 'L1';
                } else if (chld.arce__Product_id__c == null) {
                    newLevel = 'L2';
                } else {
                    newLevel = 'L3';
                }
                rowTyp = createRowLim(chld,newLevel,false,arceStage);
                dataTipology.add(rowTyp);
            }
        }
        return dataTipology;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to add related Tipology of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    dataMod to modify and add childs
    * @param    relList list of childs to add
    * @param    llave key of the map of childs
    * @param    level Order of tipology
    * @return   List<List<String>> dataTipology to display on Executive Summary
    * @example  addRelatedChldMod(wrappObj.dataTipology,lmtsExpChldMap,tipo.Id,'L1')
    * */
    private static List<List<String>> addRelatedChldMod(List<List<String>> dataMod, List<Map<Id,arce__limits_exposures__c[]>> relList, Id llave, Map<String,String> addAttr) {
        List<String> rowTyp;
        List<List<String>> dataMod2 = dataMod;
        String newLevel = addAttr.get('level');
        final string arceStage = addAttr.get('arceStage');
        if(relList[0].containsKey(llave)) {
            for(arce__limits_exposures__c chld : relList[0].get(llave)) {
                if (chld.arce__limits_exposures_parent_id__c == null){
                    newLevel = 'L1';
                } else if (chld.arce__Product_id__c == null) {
                    newLevel = 'L2';
                } else {
                    newLevel = 'L3';
                }
                Map<String, String> newAddAttr = new Map<String, String>();
                rowTyp = createRowLim(chld,newLevel,true,arceStage);
                dataMod2.add(rowTyp);
                newAddAttr.put('level', 'L2');
                newAddAttr.put('arceStage', arceStage);
                dataMod2 = addRelatedChldMod(dataMod2,relList,chld.Id,newAddAttr);
            }
        }
        if(relList[1].containsKey(llave)) {
            newLevel = 'L3';
            for(arce__limits_exposures__c chld : relList[1].get(llave)) {
                rowTyp = createRowLim(chld,newLevel,true,arceStage);
                dataMod2.add(rowTyp);
            }
        }
        return dataMod2;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to add row Tipology of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-06-20
    * @param    lmtExp Tipology to add
    * @param    level Level to add
    * @param    isModalRecord boolean to identify wich columns to add
    * @return   List<String> row to display on Executive Summary
    * @example  createRowLim(chld,level)
    * */
    private static List<String> createRowLim(arce__limits_exposures__c lmtExp,String level,Boolean isModalRecord,String arceStage) {
        final List<String> rowTyp = new List<String>();
        final SObject lmt = lmtExp;
        Decimal tempDec = 0;
        rowTyp.add(rowTypeByLevel(level, lmtExp));
        if(isModalRecord) {
            for(String var : clnHeadersMod(arceStage)) {
                tempDec = (Decimal)lmt.get(var);
                rowTyp.add('nm'+String.valueOf(tempDec == null ? '-' : tempDec.format()));
            }
            rowTyp.add(concatValues(lmt));
        } else {
            rowTyp.add(fieldFormated(lmtExp.arce__last_approved_amount__c));
            rowTyp.add(fieldFormated(lmtExp.arce__current_formalized_amount__c));
            rowTyp.add(fieldFormated(lmtExp.arce__outstanding_amount__c));
            rowTyp.add(fieldFormated(lmtExp.arce__current_proposed_amount__c));
        }
        return rowTyp;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to field formated
    * -----------------------------------------------------------------------------------------------------
    * @Author   amunguia
    * @Date     2021-05-18
    * @param    currentAmount Double
    * @return   String fieldFormated
    * @example  concatValues(lmt)
    * */
    private static String fieldFormated(Decimal currentAmount) {
        return currentAmount == null ?  'nm-' : 'nm'+currentAmount.format();
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to rowTypeByLevel
    * -----------------------------------------------------------------------------------------------------
    * @author amunguia.contractor@bbva.com | 05-18-2021
    * @param String level
    * @param arce__limits_exposures__c lmtExp
    * @return String
    **/
    private static String rowTypeByLevel(String level, arce__limits_exposures__c lmtExp) {
        String result;
        if (level == 'L2') {
            result = lmtExp.arce__limits_typology_id__r.Name;
        } else if (level == 'L1') {
            result = level + lmtExp.arce__limits_typology_id__r.Name;
        } else if (level == 'L3') {
            result = level + lmtExp.arce__Product_id__r.Name;
        }
        return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to concat values for modalities of the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2019-07-20
    * @param    lmt SObject to add fields
    * @return   String row of concatenated values for modalities
    * @example  concatValues(lmt)
    * */
    private static String concatValues(SObject lmt) {
        String concatCol = '';
        Set<String> columns2Concat = new Set<String>();
        columns2Concat.add('arce__cust_amortized_oblg_type__c');
        columns2Concat.add('arce__break_clause_frequency_id__c');
        columns2Concat.add('arce__treasury_break_clause_date__c');
        columns2Concat.add('arce__project_finc_calification_type__c');
        columns2Concat.add('arce__undly_hedge_treasury_type__c');
        columns2Concat.add('arce__currency_id__c');
        columns2Concat.add('arce__notary_certification_type__c');
        columns2Concat.add('arce__grace_months_number__c');
        columns2Concat.add('arce__project_finance_rating_id__c');
        columns2Concat.add('arce__collection_payment_period_id__c');
        columns2Concat.add('arce__days_period_number__c');
        columns2Concat.add('arce__ltv_per__c');
        columns2Concat.add('arce__netting_type__c');
        columns2Concat.add('arce__no_real_guarantee_type__c');
        columns2Concat.add('arce__project_finance_lgd_range_id__c');
        columns2Concat.add('arce__treasury_prehedge_id__c');
        columns2Concat.add('arce__real_guarantee_type__c');
        columns2Concat.add('arce__shareholder_gntee_limit_type__c');
        columns2Concat.add('arce__amortization_type_desc__c');
        Integer index = 0;
        final String[] lbls = arce.Arc_Gen_LimitsExposures_Data.getLabels(new List<String>(columns2Concat));
        for(String col : columns2Concat) {
            if(lmt.get(col) != null) {
                concatCol += lbls[index] + ':' + lmt.get(col) + ' / ';
            }
            index++;
        }
        concatCol += ' ';
        return concatCol.removeEndIgnoreCase(' /  ');
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that fill with '-' the rows in maturity table in order to show the table of the same
    * rows that the ratios table
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-26-03
    * @param    Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj - pdf wrapper
    * @return   Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj
    * @example  fitMaturityData(newWrappObj)
    * */
    public static List<List<String>> fitMaturityData(List<List<String>> ratiosLts, List<List<String>> maturityLts) {
        List<List<String>> retMaturity = maturityLts;
        if (!maturityLts.isEmpty() && ratiosLts.size() > maturityLts.size() && !maturityLts[0].isEmpty()) {
            integer resta = ratiosLts.size() - maturityLts.size();
            for (integer i = 0; i < resta; i++) {
                List<String> auxLts = new List<String>();
                for (integer k = 0; k < maturityLts[0].size(); k++) {
                    if (k == 0) {
                        auxLts.add(' ');
                    } else {
                        auxLts.add('nm-');
                    }
                }
                retMaturity.add(auxLts);
            }
        }
        return retMaturity;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that get some data of the past analysis
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-26-03
    * @param    Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj - pdf wrapper
    * @param    rid - Id of the account has analysis object
    * @return   Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj
    * @example  getDataOfPastAnalysis(newWrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.WrapPDF getDataOfPastAnalysis(Id rid, Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj) {
        Arc_Gen_ExecRepCtrl.WrapPDF wrapObj = newWrappObj;
        Set<Id> arceIds = new Set<Id>();
        final Id accountId = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{rid})[0].arce__Customer__c;
        final List<arce__Account_has_Analysis__c> accHasAnRelatedLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnById(accountId);
        for (arce__Account_has_Analysis__c accHas: accHasAnRelatedLts) {
            if (accHas.Id != rid) {
                arceIds.add(accHas.arce__Analysis__c);
            }
        }
        final List<arce__Analysis__c> lastArceActive = arce.Arc_Gen_ArceAnalysis_Data.getLastSancArce(arceIds);
        if (!lastArceActive.isEmpty()) {
            wrapObj.maximumLimDate = String.valueOf(lastArceActive[0].arce__analysis_risk_sanction_date__c);
            final List<arce__Account_has_Analysis__c> lastAccHasActiveLts = arce.Arc_Gen_AccHasAnalysis_Data.getAllAccFromArce(lastArceActive[0].Id);
            for (arce__Account_has_Analysis__c accHas: lastAccHasActiveLts) {
                if (accHas.arce__Customer__c == accountId) {
                    wrapObj.currentBBVARating = Arc_Gen_FinInfoGroupTable_Service.getFinalRatingValue(accHas);
                }
            }
        }
        return wrapObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that get the office value
    * -----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-26-03
    * @param    Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj - pdf wrapper
    * @param    rid - Id of the account has analysis object
    * @return   Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj
    * @example  getOfficeValue(newWrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.WrapPDF getOfficeValue(Id rid, Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj) {
        Arc_Gen_ExecRepCtrl.WrapPDF wrapObj = newWrappObj;
        final arce.Arc_Gen_User_Wrapper wrapUser = arce.Arc_Gen_User_Locator.getUserInfo(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(rid).arce__Customer__r.OwnerId);
        wrapObj.officeVal = wrapUser.officeName;
        return wrapObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that get the rating value depending rating scale type
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-11-18
    * @param    Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj - pdf wrapper
    * @param    rid - Id of the account has analysis object
    * @return   Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj
    * @example  getOfficeValue(newWrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.WrapPDF getRatingValues(Id rid, Arc_Gen_ExecRepCtrl.WrapPDF newWrappObj) {
        final Arc_Gen_ExecRepCtrl.WrapPDF wrapObj = newWrappObj;
        final List<arce__Account_has_Analysis__c> lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnforRiskDetTable(wrapObj.analysisObj.Id);
        arce__Account_has_Analysis__c accHasActual = new arce__Account_has_Analysis__c();
        for (arce__Account_has_Analysis__c acc : lstAccHas) {
            if (acc.Id == rid) {
                accHasActual = acc;
            }
        }
        if (!lstAccHas.isEmpty()) {
            wrapObj.ratingVal = Arc_Gen_FinInfoGroupTable_Service.getRatingValue(accHasActual);
            wrapObj.currentBBVARating = Arc_Gen_FinInfoGroupTable_Service.getFinalRatingValue(accHasActual);
        }
        return wrapObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain query of related object Table Contracts Appraisals hotels to the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez
    * @Date     2020-12-03
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.tableContractQrys(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF tableContractQrys(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        wrappObj.curUnitContract = Arc_Gen_Contracts_Appraisals_Locator.getContractsAppraisalsRecords(rid);
        wrappObj.ContractsAppraisals = Arc_Gen_Contracts_Appraisals_Locator.getAllContractsAppraisals(rid);
        wrappObj.template = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(rid);
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain query of related object Table Analysis Date hotels to the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez
    * @Date     2020-12-03
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.tableDateQrys(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF tableDateQrys(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        wrappObj.curUnitDate = Arc_Gen_Analysis_Date_Locator.getAnalysisDateRecords(rid);
        wrappObj.analysisDate = Arc_Gen_Analysis_Date_Locator.getAllAnalysisDate(rid);
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain query of related object Analysis Category hotels to the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez
    * @Date     2020-12-03
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.tableCategoryQrys(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF tableCategoryQrys(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        wrappObj.curUnitCategory = Arc_Gen_Analysis_Category_Locator.getCategoryRecords(rid);
        wrappObj.analysisCategory = Arc_Gen_Analysis_Category_Locator.getAllAnalysisCategory(rid);
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain query of related object Hotel Projection hotels to the Executive Summary
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez
    * @Date     2020-12-03
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.tableProjectionQrys(rid,wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF tableProjectionQrys(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        wrappObj.projection = Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(rid);
        wrappObj.curUnitProjection = Arc_Gen_Hotel_Projection_Locator.getCurUnitprojection(rid);
        return wrappObj;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtain columns and data about agro table
    * ------------------------------------------------------------------------------------------------------
    * @Author   brauliobaruchs.sanpedro.contractor@bbva.com
    * @Date     2021-04-21
    * @param    Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj
    * @return   Arc_Gen_ExecRepCtrl.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRepCtrl.wrapPDF tableAgro(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj)
    * */
    public static Arc_Gen_ExecRepCtrl.wrapPDF tableAgro(Id rid, Arc_Gen_ExecRepCtrl.wrapPDF wrappObj) {
        final List<String> columns = Arc_Gen_evol_main_prod_agro_Locator.getColumnsOfEvolPricesTb(rid);
        wrappObj.newData = Arc_Gen_evol_main_prod_agro_Locator.getRowStructure(rid, columns);
        final List<String> columnInfo = new List<String>{Label.Arc_Gen_ProductName};
        columnInfo.addAll(columns);
        wrappObj.columsAgro = columnInfo;
        return wrappObj;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that obtain tipology Levl 3 arce__limits_exposures__c data
    * -----------------------------------------------------------------------------------------------
    * @param rid - id of the arce__account_has_analysis_id__c to obtain
    * @return arce__limits_exposures__c[] tipology L3
    * @example getLevel3(rid)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__limits_exposures__c> getLevel3 (Id rid) {
        final List<arce__limits_exposures__c> listL3 = new List<arce__limits_exposures__c>();
        for(arce__limits_exposures__c chld : arce.Arc_Gen_LimitsExposures_Data.modalityFull(rid)) {
            if (chld.arce__limits_exposures_parent_id__c != null && chld.arce__Product_id__c != null) {
                listL3.add(chld);
            }
        }
        return listL3;
    }
}