/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Auto_Position_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-01-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_PotitionBankTable_Ctlr and Arc_Gen_Auto_Position_Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-03-31 mariohumberto.ramirez.contractor@bbva.com
*             fix dml operation call before limit service call
* |2020-07-24 joseluis.garcia4.contractor@bbva.com
*             Allow UNIT text to be translated
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Add typology information in table rows in order to be able to construct tree data.
* |2020-07-28 joseluis.garcia4.contractor@bbva.com
*             Refactor + Call limits service only the first time and on refresh.
* |2020-08-28 antonio.munoz.perez.contractor@bbva.com
*             As there is a new table in a TOP DOWN analysis, always call limits service in getRowsFilial() for group type.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-11 juanignacio.hita.contractor@bbva.com
*             Change typology mapping of getRowsFromData method
*|2020-11-17  juanignacio.hita.contractor@bbva.com
*             Checks if exist the default risk positions data in getRowsFilial method
* |2021-01-15 joseluis.garcia4.contractor@bbva.com
*             Ensure that the same 'UNIT' label is used in all cases.
* |2021-05-13 otiliaramona.veres.contractor@bbva.com
*             Added static final Id with name 'R_TYPE_ID'
*             Declared some local variables as final
*             Fixed excesively some long variables.
*             Fixed potentially unused variables.
* |2021-05-20 otiliaramona.veres.contractor@bbva.com
*             Added header comment from the public class 'WrapperAux'.
*             Added static final string to avoid duplicated string 'ERROR'.
*             Relocated the declaration of a variable.
* |2021-03-24  antonio.munoz.perez.contractor@bbva.com
*             Changes logic for invoking limit service in getRows method
* |2021-04-28 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add "itsTotal" value
* |2021-05-19  antonio.munoz.perez.contractor@bbva.com
*             Bugfix.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public without sharing class Arc_Gen_Auto_Position_Service_Helper {
    /**
        * @Description: External Id of TOTAL CREDIT RISK
    */
    static final String TCR_EXT_ID = Arc_Gen_LimitsTypologies_Data.getTypologiesByDevName('TP_0006').arce__risk_typo_ext_id__c;
    /**
        * @Description: Api Name for Client
    */
    static final String CLIENT = '2';
    /**
        * @Description: Name of the table last row
    */
    static final String TOTAL = 'TOTAL';
    /**
        * @Description: Name of the table last row
    */
    static final String UNIT = System.Label.Arc_Gen_PositionUnitRow;
    /**
        * @Description: param to call limits service
    */
    static final string S_GROUP = 'GROUP';
    /**
        * @Description: param to call limits service
    */
    static final string SUBSIDIARY = 'SUBSIDIARY';
    /**
        * @Description: Variable that get record type Id
    */
    static final Id R_TYPE_ID = Arc_Gen_Risk_Position_summary_Data.getRecordTypeRiskPositionSum('Comments');
    /**
        * @Description: Name of the error case
    */
    static final string ERROR = 'ERROR';
    /**
        * @Description: Name of the clientType
    */
    static final string CLIENT_TYPE = 'clientType';
    /**
        * @Description: Name of the automatic
    */
    static final string AUTOMATIC = 'automatic';
    /**
        * @Description: Name of the 'true'
    */
    static final string S_TRUE = 'true';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param void
    * @return void
    * @example Arc_Gen_Auto_Position_Service_Helper helper = new Arc_Gen_Auto_Position_Service_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Auto_Position_Service_Helper() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Public class for WrapperAux
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param void
    * @return void
    * @example WrapperAux wrapperAux = new WrapperAux();
    * ----------------------------------------------------------------------------------------------------
    **/
    public class WrapperAux {
        /**
        * @Description: List of Arc_Gen_TableRow wrapper
        */
        List<Arc_Gen_TableRow> tableRowLts {get;set;}
        /**
        * @Description: List of arce__risk_position_summary__c object
        */
        List<arce__risk_position_summary__c> summaryDataGroup {get;set;}
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param recordId -  Id of the account has analysis object
    * @return row information of the table
    * @example getColumns()
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> getRows(Id recordId) {
        final String typoOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId) == 'Group' ? S_GROUP : SUBSIDIARY;
        final Boolean isTD = arce.Arc_Gen_GenericUtilities.getConsolidatedType(recordId) == '2';
        List<Arc_Gen_TableRow> rows = new List<Arc_Gen_TableRow>();
        if (typoOfCustomer == S_GROUP && isTD) {
            rows = getRowsFilial(recordId, typoOfCustomer, 'limits');
            rows = getRowsGroup(recordId, typoOfCustomer, '');
        } else {
            rows = typoOfCustomer == S_GROUP ? getRowsGroup(recordId, typoOfCustomer, 'limits') : getRowsFilial(recordId, typoOfCustomer, 'limits');
        }
        return rows;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId -  Id of the account has analysis object
    * @return row information of the table
    * @example getRowsFilial()
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> getRowsFilial(Id recordId, String typoOfCustomer, String serviceName) {
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        List<Arc_Gen_TableRow> rowList = new List<Arc_Gen_TableRow>();
        Boolean callLimitsService = false;
        if (typoOfCustomer <> S_GROUP && aha.arce__last_update_position__c == null) {
            callLimitsService = true;
        }

        Arc_Gen_PotitionBankTable_Service.verifyDataInserted(recordId);
        final List<arce__risk_position_summary__c> riskPosSumAllDLts = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{recordId});

        if (callLimitsService && String.isNotBlank(serviceName)) {
            // If last update position (flag) is null, call limits service
            final Id accId = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId).arce__customer__c;
            final Map<Id,arce.Arc_Gen_Account_Wrapper> accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accId});
            final Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap = Arc_Gen_Limits_Service.callLimitsService(typoOfCustomer,accWrapper.get(accId).accNumber, serviceName);
            if (limitRespMap.containsKey(ERROR)) {
                throw new QueryException(Label.serviceFailure + ' ' + limitRespMap.get(ERROR).gblCodeResponse);
            }
            final List<String> extProdIdLts = new List<String>(limitRespMap.keySet());
            if (Arc_Gen_Risk_Position_summary_Data.getPositionSummaryByProd(new List<Id>{recordId}, extProdIdLts).isEmpty()) {
                final Map<Id, Arc_Gen_Product_Wrapper> prodWrapper = Arc_Gen_Product_Locator.getProductsActive();
                rowList = insertRecordsFilial(prodWrapper, limitRespMap, recordId, typoOfCustomer);
            } else {
                updateRiskPositionRecords(riskPosSumAllDLts, limitRespMap);
                rowList = getRowsFromData(typoOfCustomer, riskPosSumAllDLts);
            }
        } else {
            // If last update position (flag) is not null, retrieve rows directly from the database.
            rowList = getRowsFromData(typoOfCustomer, riskPosSumAllDLts);
        }
        return rowList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description converts arce__risk_position_summary__c records to table rows.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-06-18
    * @param typoOfCustomer - Whether the account is group or subsidiary
    * @param riskPosSumAllDLts - List of risk position summary from database.
    * @return list of table rows
    * --------------------------------------------------------------------------------------
    **/
    private static List<Arc_Gen_TableRow> getRowsFromData(String typoOfCustomer, List<arce__risk_position_summary__c> riskPosSumAllDataLts) {
        List<Arc_Gen_TableRow> rowList = new List<Arc_Gen_TableRow>();
        Arc_Gen_TableRow rowGroup = new Arc_Gen_TableRow();
        Boolean hasGroupRow = false;
        for (arce__risk_position_summary__c riskPosSumData: riskPosSumAllDataLts) {
            if (isTotalRow(typoOfCustomer,riskPosSumData)) {
                // Row of totals.
                Map<String,String> info = new Map<String,String>();
                info.put(CLIENT_TYPE, typoOfCustomer);
                info.put('typology', '');
                info.put(AUTOMATIC, S_TRUE);
                rowGroup.name = riskPosSumData.Id;
                rowGroup.recordTypeId = riskPosSumData.RecordTypeId;
                rowGroup.product = TOTAL;
                rowGroup.itsTotal = true;
                rowGroup.currentLimit = riskPosSumData.arce__banrel_current_limit_name__c;
                rowGroup.commited = riskPosSumData.arce__banrel_commitment_name__c;
                rowGroup.uncommited = riskPosSumData.arce__banrel_uncommitment_name__c;
                rowGroup.outstanding = riskPosSumData.arce__banrel_outstanding_name__c;
                rowGroup.comments = riskPosSumData.arce__banrel_comments_desc__c;
                rowGroup.currencyType = riskPosSumData.CurrencyIsoCode;
                rowGroup.unit = UNIT;
                rowGroup.info = info;
                hasGroupRow = true;
            } else if (riskPosSumData.arce__Product_id__c != null) {
                final Arc_Gen_TableRow row = new Arc_Gen_TableRow();
                final Map<String,String> info = new Map<String,String>();
                info.put(CLIENT_TYPE, typoOfCustomer);
                info.put('typology', riskPosSumData.arce__Product_id__r.Family);
                info.put(AUTOMATIC, S_TRUE);
                row.name = riskPosSumData.Id;
                row.recordTypeId = riskPosSumData.RecordTypeId;
                row.product = riskPosSumData.arce__Product_id__r.Name;
                row.currentLimit = riskPosSumData.arce__banrel_current_limit_name__c;
                row.commited = riskPosSumData.arce__banrel_commitment_name__c;
                row.uncommited = riskPosSumData.arce__banrel_uncommitment_name__c;
                row.outstanding = riskPosSumData.arce__banrel_outstanding_name__c;
                row.comments = riskPosSumData.arce__banrel_comments_desc__c;
                row.currencyType = riskPosSumData.CurrencyIsoCode;
                row.unit = UNIT;
                row.info = info;

                // Get only rows with any field filled or not equal to zero.
                Final List<Boolean> limitsList = getLimitsValue(row);
                rowList = addRowsLimits(rowList,row,limitsList);
            }
        }
        rowList = addRowGroup(rowList,rowGroup,hasGroupRow);
        return rowList;
    }
        /**
    * --------------------------------------------------------------------------------------
    * @Description returns a boolean whether a total row logic or a filiarl row to table rows.
    * --------------------------------------------------------------------------------------
    * @Author  Antonio Muñoz Pérez    antonio.munoz.perez.contractor@bbva.com
    * @Date    Created: 2021-05-24
    * @param   typoOfCustomer - Whether the account is group or subsidiary
    * @param   riskPosSumData - Risk position summary from database.
    * @return  Boolean
    * --------------------------------------------------------------------------------------
    **/
    private static Boolean isTotalRow(String typoOfCustomer, arce__risk_position_summary__c riskPosSumData) {
        return typoOfCustomer == S_GROUP ? riskPosSumData.arce__Product_id__c == null && riskPosSumData.arce__account_Id__r.ParentId == null: riskPosSumData.arce__Product_id__c == null;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Updates existing risk position records with the information retrieved by
    * the service.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García Díaz    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-28
    * @param riskPosSumAllDLts -  List of existing records.
    * @param limitRespMap - Response from the service
    * --------------------------------------------------------------------------------------
    **/
    public static void updateRiskPositionRecords(List<arce__risk_position_summary__c> riskPosSumAllDLts, Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap) {
        for (arce__risk_position_summary__c riskPosSumData: riskPosSumAllDLts) {
            if (riskPosSumData.arce__Product_id__c == null) {
                riskPosSumData.arce__banrel_current_limit_name__c = limitRespMap.get(TCR_EXT_ID).currentLimit;
                riskPosSumData.arce__banrel_commitment_name__c = limitRespMap.get(TCR_EXT_ID).commited;
                riskPosSumData.arce__banrel_uncommitment_name__c = limitRespMap.get(TCR_EXT_ID).uncommited;
                riskPosSumData.arce__banrel_outstanding_name__c = limitRespMap.get(TCR_EXT_ID).outstanding;
            } else {
                riskPosSumData.arce__banrel_current_limit_name__c = limitRespMap.get(riskPosSumData.arce__Product_id__r.ExternalId).currentLimit;
                riskPosSumData.arce__banrel_commitment_name__c = limitRespMap.get(riskPosSumData.arce__Product_id__r.ExternalId).commited;
                riskPosSumData.arce__banrel_uncommitment_name__c = limitRespMap.get(riskPosSumData.arce__Product_id__r.ExternalId).uncommited;
                riskPosSumData.arce__banrel_outstanding_name__c = limitRespMap.get(riskPosSumData.arce__Product_id__r.ExternalId).outstanding;
            }
        }
        Arc_Gen_Risk_Position_summary_Data.updateRecords(riskPosSumAllDLts);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param recordId -  Id of the account has analysis object
    * @param typoOfCustomer -  group/subsidiary
    * @param serviceName -  name of the service to consult
    * @return row information of the table
    * @example getRowsGroup(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> getRowsGroup(Id recordId, String typoOfCustomer, String serviceName) {
        // Should we call limits service? (check flag/date on AHA)
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final Boolean callLimitsService = aha.arce__last_update_position__c == null;

        WrapperAux wrapperAux = new WrapperAux();
        final List<Id> accIds = new List<Id>();
        final Id groupId;
        List<Arc_Gen_TableRow> rowLts =  new List<Arc_Gen_TableRow>();
        boolean flag = false;
        final arce__Account_has_Analysis__c accHasRel = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final List<arce__Account_has_Analysis__c> accHasLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(accHasRel.arce__Analysis__c);
        for (arce__Account_has_Analysis__c accHas: accHasLts) {
            if (accHas.arce__group_asset_header_type__c == CLIENT) {
                accIds.add(accHas.arce__customer__c);
            } else {
                groupId = accHas.arce__customer__c;
            }
        }
        final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(accIds);
        final Map<Id,arce.Arc_Gen_Account_Wrapper> mapGroupWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{groupId});
        final List<arce__risk_position_summary__c> riskPosDataLts = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryByAccount(new List<Id>{recordId}, accIds);
        final List<arce__risk_position_summary__c> riskPositionGroup = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryByAccount(new List<Id>{recordId}, new List<Id>{groupId});
        final List<arce__risk_position_summary__c> riskPosSumDtG = new List<arce__risk_position_summary__c>();
        if (riskPosDataLts.isEmpty()) {
            wrapperAux = insertNewRecords(mapWrapper, R_TYPE_ID, recordId, typoOfCustomer);
            rowLts = wrapperAux.tableRowLts;
        } else {
            flag = true;
            for (arce__risk_position_summary__c riskSumData: riskPosDataLts) {
                riskSumData.arce__banrel_current_limit_name__c = mapWrapper.get(riskSumData.arce__account_Id__c).currentLimit;
                riskSumData.arce__banrel_commitment_name__c = mapWrapper.get(riskSumData.arce__account_Id__c).commited;
                riskSumData.arce__banrel_uncommitment_name__c = mapWrapper.get(riskSumData.arce__account_Id__c).unCommited;
                riskSumData.arce__banrel_outstanding_name__c = mapWrapper.get(riskSumData.arce__account_Id__c).outstanding;
                riskPosSumDtG.add(riskSumData);
                rowLts.add(fillRowData(riskSumData, mapWrapper, typoOfCustomer));
            }
        }
        if (callLimitsService && String.isNotBlank(serviceName)) {
            rowLts.add(getRowTotalInfo(new List<String>{typoOfCustomer, serviceName}, mapGroupWrapper, groupId, riskPositionGroup));
        } else {
            rowLts.add(getRowTotalFromDatabase(typoOfCustomer, riskPositionGroup[0]));
        }
        if (flag) {
            arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(riskPosSumDtG);
        } else {
            arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(wrapperAux.summaryDataGroup);
        }
        return rowLts;
    }
    /**
    *----------------------------------------------------------------------------------
    * @description Fills Arc_Gen_TableRow object.
    *----------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    21/04/2022
    * @param arce__risk_position_summary__c riskSumData
    * @param Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper
    * @param String typoOfCustomer
    * @return Arc_Gen_TableRow row
    * @example Arc_Gen_TableRow row = fillRowData(riskSumData, mapWrapper, typoOfCustomer);
    **/
    public static Arc_Gen_TableRow fillRowData(arce__risk_position_summary__c riskSumData, Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper, String typoOfCustomer) {
        final Map<String,String> info = new Map<String,String>();
        info.put(CLIENT_TYPE, typoOfCustomer);
        info.put(AUTOMATIC, S_TRUE);
        final Arc_Gen_TableRow row = new Arc_Gen_TableRow();
        row.name = riskSumData.Id;
        row.recordTypeId = riskSumData.recordTypeId;
        row.product = riskSumData.arce__account_Id__r.Name;
        row.currentLimit = mapWrapper.get(riskSumData.arce__account_Id__c).currentLimit;
        row.commited = mapWrapper.get(riskSumData.arce__account_Id__c).commited;
        row.uncommited = mapWrapper.get(riskSumData.arce__account_Id__c).unCommited;
        row.outstanding = mapWrapper.get(riskSumData.arce__account_Id__c).outstanding;
        row.comments = riskSumData.arce__banrel_comments_desc__c;
        row.currencyType = mapWrapper.get(riskSumData.arce__account_Id__c).currencyType;
        row.unit = UNIT;
        row.info = info;
        return row;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information for position table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param params -  service name and typeOfCustomer values
    * @param mapGroupWrapper -  Account wrapper
    * @param groupId -  Id group
    * @param riskPositionGroup -  position summary data related to group
    * @return row information of the table
    * @example getRowTotalInfo(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_TableRow getRowTotalInfo(List<String> params, Map<Id,arce.Arc_Gen_Account_Wrapper> mapGroupWrapper, Id groupId, List<arce__risk_position_summary__c> riskPositionGroup) {
        final Arc_Gen_TableRow row = new Arc_Gen_TableRow();
        final Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap = Arc_Gen_Limits_Service.callLimitsService(params[0],mapGroupWrapper.get(groupId).accNumber, params[1]);
        if (limitRespMap.containsKey(ERROR)) {
            throw new QueryException(Label.serviceFailure + ' ' + limitRespMap.get(ERROR).gblCodeResponse);
        }
        for (String limitId: limitRespMap.keySet()) {
            if (limitId == TCR_EXT_ID) {
                final Map<String,String> info = new Map<String,String>();
                info.put(CLIENT_TYPE, params[0]);
                info.put(AUTOMATIC, S_TRUE);
                riskPositionGroup[0].arce__banrel_current_limit_name__c = limitRespMap.get(limitId).currentLimit;
                riskPositionGroup[0].arce__banrel_commitment_name__c = limitRespMap.get(limitId).commited;
                riskPositionGroup[0].arce__banrel_uncommitment_name__c = limitRespMap.get(limitId).uncommited;
                riskPositionGroup[0].arce__banrel_outstanding_name__c = limitRespMap.get(limitId).outstanding;
                row.name = riskPositionGroup[0].Id;
                row.recordTypeId = riskPositionGroup[0].recordTypeId;
                row.product = TOTAL;
                row.currentLimit = limitRespMap.get(limitId).currentLimit;
                row.commited = limitRespMap.get(limitId).commited;
                row.uncommited = limitRespMap.get(limitId).uncommited;
                row.outstanding = limitRespMap.get(limitId).outstanding;
                row.comments = riskPositionGroup[0].arce__banrel_comments_desc__c;
                row.currencyType = limitRespMap.get(limitId).currencyType;
                row.unit = UNIT;
                row.info = info;
            }
        }
        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(riskPositionGroup);
        return row;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information for position table from the database
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García Díaz joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-29
    * @param customerType - Customer type
    * @param riskPosSumData - Record with the totals
    * @return row information of the table
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_TableRow getRowTotalFromDatabase(String customerType, arce__risk_position_summary__c riskPosSumData) {
        final Arc_Gen_TableRow row = new Arc_Gen_TableRow();

        // Retrieve data directly from database.
        final Map<String,String> info = new Map<String,String>();
        info.put(CLIENT_TYPE, customerType);
        info.put('typology', '');
        info.put(AUTOMATIC, S_TRUE);
        row.name = riskPosSumData.Id;
        row.recordTypeId = riskPosSumData.RecordTypeId;
        row.product = TOTAL;
        row.currentLimit = riskPosSumData.arce__banrel_current_limit_name__c;
        row.commited = riskPosSumData.arce__banrel_commitment_name__c;
        row.uncommited = riskPosSumData.arce__banrel_uncommitment_name__c;
        row.outstanding = riskPosSumData.arce__banrel_outstanding_name__c;
        row.comments = riskPosSumData.arce__banrel_comments_desc__c;
        row.currencyType = riskPosSumData.CurrencyIsoCode;
        row.unit = UNIT;
        row.info = info;

        return row;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param mapWrapper -  map of account wrapper
    * @param recordTypeId -  Id of the record type to associate
    * @param recordId -  Id of the account has analysis object
    * @param typoOfCustomer - Group/Client
    * @return WrapperAux - wrapper with the info to update and show in the position table
    * @example insertNewRecords(mapWrapper, recordTypeId, recordId, typoOfCustomer);
    * --------------------------------------------------------------------------------------
    **/
    private static WrapperAux insertNewRecords(Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper, Id recordTypeId, Id recordId, String typoOfCustomer) {
        final WrapperAux wrapperRet = new WrapperAux();
        final List<arce__risk_position_summary__c> riskPosSumDtG = new List<arce__risk_position_summary__c>();
        final List<Arc_Gen_TableRow> rowLts =  new List<Arc_Gen_TableRow>();
        for (Id accountId: mapWrapper.keySet()) {
            final arce__risk_position_summary__c summaryData = new arce__risk_position_summary__c();
            summaryData.recordTypeId = recordTypeId;
            summaryData.arce__account_Id__c = accountId;
            summaryData.arce__banrel_current_limit_name__c = mapWrapper.get(accountId).currentLimit;
            summaryData.arce__banrel_commitment_name__c = mapWrapper.get(accountId).commited;
            summaryData.arce__banrel_uncommitment_name__c = mapWrapper.get(accountId).unCommited;
            summaryData.arce__banrel_outstanding_name__c = mapWrapper.get(accountId).outstanding;
            summaryData.arce__account_has_analysis_id__c = recordId;
            riskPosSumDtG.add(summaryData);
        }
        wrapperRet.summaryDataGroup = riskPosSumDtG;
        for (arce__risk_position_summary__c summaryData: riskPosSumDtG) {
            final Map<String,String> info = new Map<String,String>();
            info.put(CLIENT_TYPE, typoOfCustomer);
            info.put(AUTOMATIC, S_TRUE);
            final Arc_Gen_TableRow row = new Arc_Gen_TableRow();
            row.name = summaryData.Id;
            row.recordTypeId = summaryData.recordTypeId;
            row.product = mapWrapper.get(summaryData.arce__account_Id__c).name;
            row.currentLimit = summaryData.arce__banrel_current_limit_name__c;
            row.commited = summaryData.arce__banrel_commitment_name__c;
            row.uncommited = summaryData.arce__banrel_uncommitment_name__c;
            row.outstanding = summaryData.arce__banrel_outstanding_name__c;
            row.comments = summaryData.arce__banrel_comments_desc__c;
            row.info = info;
            row.unit = UNIT;
            rowLts.add(row);
        }
        wrapperRet.tableRowLts = rowLts;
        return wrapperRet;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param mapWrapper -  map of account wrapper
    * @param limitRespMap -  Service response
    * @param recordId -  Id of the account has analysis object
    * @param typoOfCustomer - Group/Client
    * @return List<Arc_Gen_TableRow> - row information of the table
    * @example insertNewRecords(mapWrapper, recordTypeId, recordId, typoOfCustomer);
    * --------------------------------------------------------------------------------------
    **/
    private static List<Arc_Gen_TableRow> insertRecordsFilial(Map<Id, Arc_Gen_Product_Wrapper> prodWrapper, Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap, Id recordId, String typoOfCustomer) {
        final List<arce__risk_position_summary__c> riskPosSumAuxLts = new List<arce__risk_position_summary__c>();
        for (id prodId: prodWrapper.keySet()) {
            if (limitRespMap.keySet().contains(prodWrapper.get(prodId).externalId)) {
                final arce__risk_position_summary__c summaryProduct = new arce__risk_position_summary__c();
                summaryProduct.recordTypeId = R_TYPE_ID;
                summaryProduct.arce__account_Id__c = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId).arce__customer__c;
                summaryProduct.arce__banrel_current_limit_name__c = limitRespMap.get(prodWrapper.get(prodId).externalId).currentLimit;
                summaryProduct.arce__banrel_commitment_name__c = limitRespMap.get(prodWrapper.get(prodId).externalId).commited;
                summaryProduct.arce__banrel_uncommitment_name__c = limitRespMap.get(prodWrapper.get(prodId).externalId).uncommited;
                summaryProduct.arce__banrel_outstanding_name__c = limitRespMap.get(prodWrapper.get(prodId).externalId).outstanding;
                summaryProduct.arce__account_has_analysis_id__c = recordId;
                summaryProduct.arce__Product_id__c = prodId;

                // Insert only rows with any field filled or not equal to zero.
                final Boolean anyCurrentLimit = summaryProduct.arce__banrel_current_limit_name__c != null && summaryProduct.arce__banrel_current_limit_name__c != 0;
                final Boolean anyCommited = summaryProduct.arce__banrel_commitment_name__c != null && summaryProduct.arce__banrel_commitment_name__c != 0;
                final Boolean anyUncommited = summaryProduct.arce__banrel_uncommitment_name__c != null && summaryProduct.arce__banrel_uncommitment_name__c != 0;
                final Boolean anyOutstanding = summaryProduct.arce__banrel_outstanding_name__c != null && summaryProduct.arce__banrel_outstanding_name__c != 0;
                if (anyCurrentLimit || anyCommited || anyUncommited || anyOutstanding) {
                    riskPosSumAuxLts.add(summaryProduct);
                }
            }
        }
        Arc_Gen_Risk_Position_summary_Data.insertRecords(riskPosSumAuxLts);

        final List<arce__risk_position_summary__c> riskPosSumAllDLts = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{recordId});
        updateRiskPositionRecords(riskPosSumAllDLts, limitRespMap);
        return getRowsFromData(typoOfCustomer, riskPosSumAllDLts);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description returned boolean values if a row of the table has null values or zero values
    * --------------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz  juanmanuel.perez.ortiz.contractor.contractor@bbva.com
    * @Date     Created: 2021-04-28
    * @param row - Record of the table
    * @return List<Boolean> - List of boolean values
    * @example getLimitsValue(Arc_Gen_TableRow row);
    * --------------------------------------------------------------------------------------
    **/
    private static List<Boolean> getLimitsValue(Arc_Gen_TableRow row) {
        final Boolean anyCurrentLimit = row.currentLimit != null && row.currentLimit != 0;
        final Boolean anyCommited = row.commited != null && row.commited != 0;
        final Boolean anyUncommited = row.uncommited != null && row.uncommited != 0;
        final Boolean anyOutstanding = row.outstanding != null && row.outstanding != 0;
        return new List<Boolean>{anyCurrentLimit, anyCommited, anyUncommited, anyOutstanding};
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description adds a group row if it exists
    * --------------------------------------------------------------------------------------
    * @Author   carlos.pisador.contractor@bbva.com
    * @Date     Created: 2021-05-18
    * @param rowList - Records of the table
    * @param rowGroup - Group record of the table
    * @param hasRowGroup - There is a row for group?
    * @return List<Arc_Gen_TableRow> - List of table rows
    * @example addRowGroup (rowList, rowGroup, hasRowGroup);
    * --------------------------------------------------------------------------------------
    **/
    private static List<Arc_Gen_TableRow> addRowGroup (List<Arc_Gen_TableRow> rowList, Arc_Gen_TableRow rowGroup, Boolean hasRowGroup) {
        if (hasRowGroup) {
            rowList.add(rowGroup);
        }
        return rowList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description adds a row to a row list
    * --------------------------------------------------------------------------------------
    * @Author   carlos.pisador.contractor@bbva.com
    * @Date     Created: 2021-05-18
    * @param rowList - Records of the table
    * @param row - Record of the table
    * @param listLimits - Boolean list
    * @return List<Arc_Gen_TableRow> - List of table rows
    * @example addRowsLimits (rowList, row, listLimits);
    * --------------------------------------------------------------------------------------
    **/
    private static List<Arc_Gen_TableRow> addRowsLimits (List<Arc_Gen_TableRow> rowList, Arc_Gen_TableRow row, List<Boolean> listLimits) {
        if (listLimits[0] || listLimits[1]  || listLimits[2] || listLimits[3]) {
            rowList.add(row);
        }
        return rowList;
    }
}