/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Expandible_Table_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_Policies_Controller
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Add new attribute to the JSON response in getColumns method.
* |2019-08-09 mariohumberto.ramirez.contractor@bbva.com
*             Add new line that call the method "deleteDuplicatesValues" the method evals if the
*             typology is duplicated and delete the duplicated record
* |2019-08-14 mariohumberto.ramirez.contractor@bbva.com
*             Deleted call to the method deleteDuplicatesValues
* |2019-09-30 mariohumberto.ramirez.contractor@bbva.com
*             Added new method sumTypologies
* |2019-10-11 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getHeaderDate
* |2020-01-21 juanmanuel.perez,ortiz.contractor@bbva.com
*             Remove column in expandible table
* |2020-01-06 mariohumberto.ramirez.contractor@bbva.com
*             modify method getproductService
* |2020-01-30 javier.soto.carrascosa@bbva.com
*             Add HU 787 missing functionality
* |2020-07-16 joseluis.garcia4.contractor@bbva.com
*             Add clearTestLeveraged() method.
* |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
*             Add getTypeOfAnalysis and getLastProposeInfo methods
* |2020-08-18 mariohumberto.ramirez.contractor@bbva.com
*             Fix copy proposal amount for products
* |2020-09-07 mariohumberto.ramirez.contractor@bbva.com
*             Add unit converter logic when "Propose the same risk limits of the previous year" button is pressed
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-18 joseluis.garcia4.contractor@bbva.com
*             Clear leveraged results when policies change in an orphan.
* |2020-12-15 joseluis.garcia4.contractor@bbva.com
*             Clear leveraged test when policies are modified in orphan customer.
* |2021-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* |2021-03-01 luisdavid.rivera.ortiz@bbva.com
*             Revert current_apprv_limit_term_type fields
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__current_apprv_limit_term_type__c  for arce__current_apprv_limit_term_id__c
* |2021-03-15 juanignacio.hita.contractor@bbva.com
*             Refactoring of getTypeOfAnalysis method for return more fields of AHA object
* |2021-03-15 juanignacio.hita.contractor@bbva.com
*             Refactoring of getTypeOfAnalysis method for return more fields of AHA object
* |2021-03-18 juanignacio.hita.contractor@bbva.com
*             Change return sumTypologies method
* |2021-10-27 francisco.munoz.torres.contractor@bbva.com
*             When recovering the last sanctioned ARCE, the expired and unexpired are included in the same step
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods')
public with sharing class Arc_Gen_Expandible_Table_Service {

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Service service = new Arc_Gen_Expandible_Table_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Expandible_Table_Service() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that verify if there are arce__limits_exposures__c records inserted and insert
    * records if there are not records inserted
    * ----------------------------------------------------------------------------------------------------
    * @param recordId - Id of the account has analysis object
    * @return void
    * @example verifyTypologiesInserted()
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void verifyTypologiesInserted(Id recordId) {
        final List<arce__limits_exposures__c> exposureData = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{recordId});
        if (exposureData.isEmpty()) {
            Arc_Gen_ExpTable_Service_Helper.insertTypologies(recordId);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get date of sanction to show in politics header table
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-10-11
    * @param recordId - id of the account_has_analysis.
    * @return String  date of sanction
    * @example getHeaderDate(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static String getHeaderDate(Id recordId) {
        return String.valueOf(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId})[0].arce__Analysis__r.arce__analysis_risk_sanction_date__c);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information of the policy table
    * --------------------------------------------------------------------------------------
    * @param void
    * @return columns information of the policy table
    * @example getColumns()
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableColumns> getColumns(String arceStage) {
        Map<String,String> attributes = new Map<String,String>();
        attributes.put('alignment','center');
        Arc_Gen_TableColumns tipology = new Arc_Gen_TableColumns();
        tipology.type = 'text';
        tipology.fieldName = 'tipology';
        tipology.label = System.Label.Arc_Gen_Tipology;
        tipology.initialWidth = 400;
        tipology.cellAttributes = attributes;
        Arc_Gen_TableColumns lastApproved = new Arc_Gen_TableColumns();
        lastApproved.type = 'number';
        lastApproved.fieldName = 'lastApproved';
        lastApproved.label = System.Label.Arc_Gen_Last_Approved;
        lastApproved.cellAttributes = attributes;
        Arc_Gen_TableColumns commited = new Arc_Gen_TableColumns();
        commited.type = 'number';
        commited.fieldName = 'commited';
        commited.label = System.Label.Arc_Gen_Committed;
        commited.cellAttributes = attributes;
        Arc_Gen_TableColumns uncommited = new Arc_Gen_TableColumns();
        uncommited.type = 'number';
        uncommited.fieldName = 'uncommited';
        uncommited.label = System.Label.Arc_Gen_Non_committed;
        uncommited.cellAttributes = attributes;
        Arc_Gen_TableColumns currentLimit = new Arc_Gen_TableColumns();
        currentLimit.type = 'number';
        currentLimit.fieldName = 'currentLimit';
        currentLimit.label = System.Label.Arc_Gen_Current_limit;
        currentLimit.cellAttributes = attributes;
        Arc_Gen_TableColumns outstanding = new Arc_Gen_TableColumns();
        outstanding.type = 'number';
        outstanding.fieldName = 'outstanding';
        outstanding.label = System.Label.Arc_Gen_Outstanding;
        outstanding.cellAttributes = attributes;
        Arc_Gen_TableColumns limitProposed = new Arc_Gen_TableColumns();
        limitProposed.type = 'number';
        limitProposed.fieldName = 'limitProposed';
        limitProposed.label =  arceStage == '1' || arceStage == '2'  ?  System.Label.Arc_Gen_Proposed_Approved : System.Label.Arc_Gen_Proposed;
        limitProposed.cellAttributes = attributes;
        List<Arc_Gen_TableColumns> columns = new List<Arc_Gen_TableColumns>{tipology,lastApproved,commited,uncommited,currentLimit,outstanding,limitProposed};
        return columns;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the data needed to create the policy table
    * --------------------------------------------------------------------------------------
    * @param recordId - id of the account_has_analysis.
    * @return ordenatedList a  List<Arc_Gen_TableRow> that contain the data to create the
    * policy table.
    * @example buildNestedData(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> buildNestedData (Id recordId) {
        return Arc_Gen_ExpTable_Service_Helper.getNestedData(recordId);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Delete records
    * --------------------------------------------------------------------------------------
    * @param recordId - id of the account_has_analysis.
    * @return response.
    * @example deleteRecord(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,String> deleteRecord(Id recordId) {
        return Arc_Gen_ExpTable_Service_Helper.deleteRecordTable(recordId);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return's the record Id of a record type
    * --------------------------------------------------------------------------------------
    * @param recordTypeName - name of the record type
    * @return recordIdResp - String with the Id of the record type
    * @example getRecordTypeId(recordTypeName)
    * --------------------------------------------------------------------------------------
    **/
    public static String getRecordTypeId(String recordTypeName) {
        String recordIdResp = '';
        for(RecordType recordId : arce.Arc_Gen_GenericUtilities.getRecordTypeData(recordTypeName)) {
            recordIdResp = recordId.Id;
        }
        return recordIdResp;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get a list of products
    * --------------------------------------------------------------------------------------
    * @param tipologia - name of the typology
    * @return lista.
    * @example getProductsService(tipologia)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Map<string,string>> getProductsService(String tipologia) {
        final List<Map<string,string>> listaProd = new List<Map<string,string>>();
        Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology(tipologia);
        if (pWrap.isEmpty()) {
            throw new QueryException(Label.Arc_Gen_VoidList);
        }
        Arc_Gen_Product_Wrapper prod = new Arc_Gen_Product_Wrapper();
        for (id prodId: pWrap.keySet()) {
            prod = pWrap.get(prodId);
            listaProd.add(new map<String,String>{'value' => prodId , 'label' => prod.productName});
        }
        return listaProd;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that sum typologies
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2019-09-30
    * @param recordId - Id of the account has analysis object
    * @return String
    * @example String ret = sumTypologies(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String sumTypologies(Id recordId) {
        return Arc_Gen_ExpTable_Service_Helper.sumTypologies(recordId);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - If the AHA is from the group, clears all leveraged test results from the analysis.
    * ----------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 2020-07-16
    * @param recordId - Id of the account has analysis object
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void clearTestLeveraged(String recordId) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> { recordId });
        final arce__Account_has_Analysis__c aha = ahaList[0];

        if (aha.arce__group_asset_header_type__c == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER || aha.arce__Analysis__r.arce__analysis_customer_relation_type__c == arce.Arc_Gen_Constants.CUSTOMER_RELATION_ORPHAN) {
            // If group, clear all leveraged test results from AHAs.
            Arc_Gen_TestLeverage_service.clearTestLeveragedResultsAnalysis(aha.arce__Analysis__c);
        } else if (aha.arce__Analysis__r.arce__analysis_customer_relation_type__c == arce.Arc_Gen_Constants.CUSTOMER_RELATION_ORPHAN) {
            // If orphan, clear own leveraged test results.
            Arc_Gen_TestLeverage_service.clearTestLeveragedResults(aha.Id);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get type of analysis and status limit pers fields
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-08-04
    * @param recordId - id of the account_has_analysis.
    * @return String - type of analysis
    * @example String retJson = getTypeOfAnalysis(recordId);
    * --------------------------------------------------------------------------------------
    **/
    public static String getTypeOfAnalysis(String recordId) {
        final List<arce__Account_has_Analysis__c> lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
        return JSON.serialize(
            new List<Object> {
                lstAccHas[0].arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c,
                lstAccHas[0].arce__status_limit_pers_service__c,
                lstAccHas[0].arce__call_limit_service__c }
        );
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get propose info of the previous arce
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-08-04
    * @param recordId - id of the account_has_analysis.
    * @return String - TRUE/FALSE
    * @example getLastProposeInfo(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static String getLastProposeInfo(Id recordId) {
        String ret = 'TRUE';
        try {
            final arce__Account_has_Analysis__c currAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId})[0];
            final Id groupId = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{currAccHas.arce__Analysis__c})[0].arce__Group__c;
            final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getLastSancArceByGroup(new Set<Id>{groupId})[0];
            final List<arce__Account_has_Analysis__c> allPrevAcchasAn = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{(String)arceVar.Id});
            final Id prevAccHasId;
            for (arce__Account_has_Analysis__c accHasAn :allPrevAcchasAn) {
                if (currAccHas.arce__Customer__c == accHasAn.arce__Customer__c) {
                    prevAccHasId = accHasAn.Id;
                    break;
                }
            }
            final List<arce__limits_exposures__c> prevLimExpLts = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{prevAccHasId});
            final List<arce__limits_exposures__c> currLimExpInf = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{recordId});
            final Double multFactor = Arc_Gen_ExpTable_Service_Helper.getMultiFactor(prevLimExpLts, currLimExpInf);
            for(arce__limits_exposures__c limExpPrev: prevLimExpLts) {
                for (arce__limits_exposures__c limExpCur: currLimExpInf) {
                    if (limExpPrev.arce__limits_typology_id__c == limExpCur.arce__limits_typology_id__c && limExpPrev.arce__Product_id__c == limExpCur.arce__Product_id__c) {
                        limExpCur.arce__current_proposed_amount__c = limExpPrev.arce__current_proposed_amount__c * multFactor;
                        limExpCur.arce__cust_amortized_oblg_type__c = limExpPrev.arce__cust_amortized_oblg_type__c;
                        limExpCur.arce__current_apprv_limit_term_id__c = limExpPrev.arce__current_apprv_limit_term_id__c;
                        limExpCur.arce__grace_months_number__c = limExpPrev.arce__grace_months_number__c;
                        limExpCur.arce__amortization_type_desc__c = limExpPrev.arce__amortization_type_desc__c;
                        limExpCur.arce__ltv_per__c = limExpPrev.arce__ltv_per__c;
                        limExpCur.arce__currency_id__c = limExpPrev.arce__currency_id__c;
                        limExpCur.arce__real_guarantee_type__c = limExpPrev.arce__real_guarantee_type__c;
                        limExpCur.arce__shareholder_gntee_limit_type__c = limExpPrev.arce__shareholder_gntee_limit_type__c;
                        limExpCur.arce__notary_certification_type__c = limExpPrev.arce__notary_certification_type__c;
                        limExpCur.arce__no_real_guarantee_type__c = limExpPrev.arce__no_real_guarantee_type__c;
                        limExpCur.arce__curr_apprv_deleg_dchan_amount__c = limExpPrev.arce__curr_apprv_deleg_dchan_amount__c;
                        limExpCur.arce__curr_apprv_deleg_rm_amount__c = limExpPrev.arce__curr_apprv_deleg_rm_amount__c;
                    }
                }
            }
            arce.Arc_Gen_LimitsExposures_Data.updateExposureData(currLimExpInf);
        } catch (Exception exep) {
            ret = exep.getTypeName() + ' : ' + exep.getMessage() + ' : ' + exep.getStackTraceString();
        }
        return ret;
    }
}