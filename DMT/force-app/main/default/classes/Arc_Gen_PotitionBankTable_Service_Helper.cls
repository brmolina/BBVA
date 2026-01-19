/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionBankTable_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_PotitionBankTable_Ctlr.
* --------------------------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-11-14 mariohumberto.ramirez.contractor@bbva.com
*             Added new param typoOfCustomer in getRowsGroup and getRowsFilial methods.
* |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
*             Change the object limits exposure to risk position summary
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Added logic to manage automatic position
* |2020-06-16 javier.soto.carrascosa@bbva.com
*             Change currency and unit to custom labels
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Add typology information in table rows in order to be able to construct tree data.
*             Split logic of getColumns() method into different methods.
* |2020-08-27 antonio.munoz.perez.contractor@bbva.com
*             Added cnsldColumns() method for an extra table in the TOP DOWN analisis.
*             Added getCommonColumns() method and modified getColumns() to avoid code duplication.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* --------------------------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Arc_Gen_PotitionBankTable_Service_Helper {
    /**
    * @Description: 'text' literal
    */
    static final string TEXT_LIT = 'text';
    /**
    * @Description: 'number' literal
    */
    static final string NUMBER_LIT = 'number';

    /**
    * ----------------------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_PotitionBankTable_Service_Helper servicehelper = new Arc_Gen_PotitionBankTable_Service_Helper()
    * ----------------------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_PotitionBankTable_Service_Helper() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description insert TOTAL if is missing
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId - id of the acc has analysis object
    * @return void
    * @example insertTotal(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean insertTotal(Id recordId) {
        final arce__risk_position_summary__c riskPosSummary = new arce__risk_position_summary__c();
        final arce__Account_has_Analysis__c accHasAnData = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        riskPosSummary.arce__account_has_analysis_id__c = recordId;
        riskPosSummary.recordTypeId = Arc_Gen_Risk_Position_summary_Data.getRecordTypeRiskPositionSum('Comments');
        riskPosSummary.arce__account_Id__c = accHasAnData.arce__Customer__c;
        riskPosSummary.arce__banrel_current_limit_name__c = 0;
        riskPosSummary.arce__banrel_commitment_name__c = 0;
        riskPosSummary.arce__banrel_uncommitment_name__c = 0;
        riskPosSummary.arce__banrel_outstanding_name__c = 0;
        riskPosSummary.arce__banrel_comments_desc__c = '';
        insert riskPosSummary;
        return true;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId - id of the acc has analysis object
    * @return columns information of the potition bank table
    * @example getColumns(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableColumns> getColumns(Id recordId) {
        final String firstColLabel = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId) == 'Group' ? System.Label.Arc_Gen_Subsidiate : System.Label.Arc_Gen_Product;
        final List<Arc_Gen_TableColumns> columns = new List<Arc_Gen_TableColumns>();
        columns.add(getFirstColumn(TEXT_LIT, 'product', firstColLabel));
        return getCommonColumns(columns);
    }
        /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information of the table
    * --------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     Created: 2020-08-27
    * @return columns information of the consolidated group potition bank table
    * @example cnsldColumns()
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableColumns> cnsldColumns () {
        final List<Arc_Gen_TableColumns> columns = new List<Arc_Gen_TableColumns>();
        columns.add(getFirstColumn(TEXT_LIT, 'product', System.Label.Arc_Gen_Product));
        return getCommonColumns(columns);
    }
        /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information of the table
    * --------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     Created: 2020-08-27
    * @param columns - List<Arc_Gen_TableColumns>
    * @return common columns information of the potition bank table
    * @example getCommonColumns(columns)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableColumns> getCommonColumns(List<Arc_Gen_TableColumns> columns) {
        columns.add(getColumn(NUMBER_LIT, 'currentLimit', System.Label.Arc_Gen_Current_limit));
        columns.add(getColumn(NUMBER_LIT, 'commited', System.Label.Arc_Gen_Committed));
        columns.add(getColumn(NUMBER_LIT, 'uncommited', System.Label.Arc_Gen_Non_committed));
        columns.add(getColumn(NUMBER_LIT, 'outstanding', System.Label.Arc_Gen_Outstanding));
        columns.add(getColumn(TEXT_LIT, 'currencyType', System.Label.Arc_Gen_PositionCurrency));
        columns.add(getColumn(TEXT_LIT, 'unit', System.Label.Arc_Gen_PositionUnit));
        columns.add(getColumn(TEXT_LIT, 'comments', System.Label.Arc_Gen_CommentsGuaranties, 350));
        return columns;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the first column of the table
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * @param type - column type
    * @param fieldName - column name
    * @param label - column label
    * @return column information of the column
    * --------------------------------------------------------------------------------------
    **/
    private static Arc_Gen_TableColumns getFirstColumn(String type, String fieldName, String label) {
        final Map<String,String> leftAlignAttrs = new Map<String,String>();
        leftAlignAttrs.put('alignment','left');

        final Arc_Gen_TableColumns column = new Arc_Gen_TableColumns();
        column.type = type;
        column.fieldName = fieldName;
        column.label = label;
        column.initialWidth = 250;
        column.cellAttributes = leftAlignAttrs;
        return column;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * @param type - column type
    * @param fieldName - column name
    * @param label - column label
    * @return column information of the column
    * --------------------------------------------------------------------------------------
    **/
    private static Arc_Gen_TableColumns getColumn(String type, String fieldName, String label) {
        final Map<String,String> centerAlignAttrs = new Map<String,String>();
        centerAlignAttrs.put('alignment','center');

        final Arc_Gen_TableColumns column = new Arc_Gen_TableColumns();
        column.type = type;
        column.fieldName = fieldName;
        column.label = label;
        column.cellAttributes = centerAlignAttrs;
        return column;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * @param type - column type
    * @param fieldName - column name
    * @param label - column label
    * @param initialWidth - pixel width of the column
    * @return column information of the column
    * --------------------------------------------------------------------------------------
    **/
    private static Arc_Gen_TableColumns getColumn(String type, String fieldName, String label, Integer initialWidth) {
        final Arc_Gen_TableColumns column = getColumn(type, fieldName, label);
        column.initialWidth = initialWidth;
        return column;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId -  Id of the account has analysis object
    * @return row information of the table
    * @example getColumns()
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> getRowsHelper(Id recordId) {
        final String typoOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId);
        return typoOfCustomer == 'Group' ? getRowsGroup(recordId, typoOfCustomer) : getRowsFilial(recordId, typoOfCustomer);
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
    public static List<Arc_Gen_TableRow> getRowsFilial(Id recordId, String typoOfCustomer) {
        final List<Arc_Gen_TableRow> rowList = new List<Arc_Gen_TableRow>();
        double currentLimit = 0, commited = 0, uncommited = 0, outstanding = 0;
        final List<arce__risk_position_summary__c> riskPosSumDatLts = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{recordId});
        for (arce__risk_position_summary__c summaryData: riskPosSumDatLts) {
            if (summaryData.arce__Product_id__c != null) {
                final Arc_Gen_TableRow row = getRowFromRiskSumData(summaryData, typoOfCustomer);
                currentLimit += summaryData.arce__banrel_current_limit_name__c;
                commited += summaryData.arce__banrel_commitment_name__c;
                uncommited += summaryData.arce__banrel_uncommitment_name__c;
                outstanding += summaryData.arce__banrel_outstanding_name__c;
                rowList.add(row);
            }
        }
        for (arce__risk_position_summary__c summaryData: riskPosSumDatLts) {
            if (summaryData.arce__Product_id__c == null) {
                final Arc_Gen_TableRow row = new Arc_Gen_TableRow();
                final Map<String,String> info = new Map<String,String>();
                info.put('clientType', typoOfCustomer);
                info.put('typology', '');
                info.put('automatic', 'false');
                row.name = summaryData.Id;
                row.recordTypeId = summaryData.recordTypeId;
                row.product = 'TOTAL';
                row.currentLimit = currentLimit;
                row.commited = commited;
                row.uncommited = uncommited;
                row.outstanding = outstanding;
                row.comments = summaryData.arce__banrel_comments_desc__c;
                row.info = info;
                rowList.add(row);
                summaryData.arce__banrel_current_limit_name__c = currentLimit;
                summaryData.arce__banrel_commitment_name__c = commited;
                summaryData.arce__banrel_uncommitment_name__c = uncommited;
                summaryData.arce__banrel_outstanding_name__c = outstanding;
            }
        }
        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(riskPosSumDatLts);
        return rowList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId -  Id of the account has analysis object
    * @return row information of the table
    * @example getRowsGroup(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableRow> getRowsGroup(Id recordId, String typoOfCustomer) {
        final List<Arc_Gen_TableRow> rowList = new List<Arc_Gen_TableRow>();
        final List<arce__risk_position_summary__c> riskPosSumDatGrp = Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{recordId});
        final List<arce__risk_position_summary__c> allCliPosSumDatGp = getAllClientRiskSummData(recordId);
        for (arce__risk_position_summary__c summaryData: allCliPosSumDatGp) {
            if (summaryData.arce__account_Id__c != null) {
                rowList.add(getRowFromRiskSumData(summaryData, typoOfCustomer));
            }
        }
        for (arce__risk_position_summary__c summaryData: riskPosSumDatGrp) {
            final Arc_Gen_TableRow row = getRowFromRiskSumData(summaryData, typoOfCustomer);
            row.product = 'TOTAL';
            rowList.add(row);
        }
        return rowList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a list of arce__limits_exposures__c
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-25
    * @param recordId -  Id of the account has analysis object
    * @return List<arce__limits_exposures__c>
    * @example getAllClientExposureData(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__risk_position_summary__c> getAllClientRiskSummData(Id recordId) {
        final Id arceAnalysisId = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId})[0].arce__Analysis__c;
        final List<Id> arceAnalysisIdLts = arce.Arc_Gen_GenericUtilities.getIdsOfSubsidiaries(arceAnalysisId);
        return Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(arceAnalysisIdLts);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Gets row information from arce__risk_position_summary__c record.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * @param summaryData - Position summary record
    * @param typoOfCustomer - Customer type
    * @return the row
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_TableRow getRowFromRiskSumData(arce__risk_position_summary__c summaryData, String typoOfCustomer) {
        final Arc_Gen_TableRow row = new Arc_Gen_TableRow();
        final Map<String,String> info = new Map<String,String>();
        info.put('clientType', typoOfCustomer);
        info.put('typology', summaryData.arce__Product_id__c == null ? '' : summaryData.arce__Product_id__r.ProductCode);
        info.put('automatic', 'false');
        row.name = summaryData.Id;
        row.product = summaryData.arce__Product_id__c == null ? '' : summaryData.arce__Product_id__r.Name;
        row.recordTypeId = summaryData.recordTypeId;
        row.currentLimit = summaryData.arce__banrel_current_limit_name__c;
        row.commited = summaryData.arce__banrel_commitment_name__c;
        row.uncommited = summaryData.arce__banrel_uncommitment_name__c;
        row.outstanding = summaryData.arce__banrel_outstanding_name__c;
        row.comments = summaryData.arce__banrel_comments_desc__c;
        row.info = info;

        return row;
    }
}