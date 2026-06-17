/*------------------------------------------------------------------
* @Author:        ARCE Team
* @Project:       ARCE - BBVA Bancomer
* @Description:   Service class to get and process FinancialStatemnt FROM ASO
* @Controller class: Arc_Gen_ModalFinanStatem
* Service class: Arc_Gen_Balance_Tables_service
*_______________________________________________________________________________________
* @Changes
*Version    Date           Author                               Description
*1.0        11/04/2019     ARCE TEAM   							Creación.
*1.1		24/04/2019	   diego.miguel.contractor@bbva.com     Modified ratios function to parse Json response properly
*1.2		25/04/2019	   diego.miguel.contractor@bbva.com 	Modified ratios and eeff functions to handle error messages and display to users
*1.3		01/07/2019	   ricardo.almanza.contractor@bbva.com 	Modified List to eliminate duplicate records on method insertRecords
*1.3		25/09/2019	   ismael.obregon.contractor@bbva.com 	Add new methods for validate ratings.
*1.4        26/09/2019     javier.soto.carrascosa@bbva.com      Remove Mock
*1.5        23/10/2019     mariohumberto.ramirez.contractor@bbva.com    Added new method getFinancialState2Show and updateRecordLts
*1.6        24/10/2019     mariohumberto.ramirez.contractor@bbva.com    Delete method getEEFFValidForRatingList() and getEEFFValidForRating()
*                                                                       and added new fields 'arce__magnitude_unit_type__c,CurrencyIsoCode' in
*                                                                       the method getFinancialStatements
*1.6.1      02/12/2019     german.sanchez.perez.contractor@bbva.com
*                          franciscojavier.bueno@bbva.com               Api names modified with the correct name on business glossary
*1.7        24/10/2019     mariohumberto.ramirez.contractor@bbva.com    Added new fields in the method getEmptyFinancialStatements
*1.8        20/02/2020     juanmanuel.perez.ortiz.contractor@bbva.com   Fix incidence, geography data was deleted when loading
*                                                                       another financial statement
*1.9        26/03/2020     juanignacio.hita.contractor@bbva.com         Refactoring
*1.9        26/03/2020     mariohumberto.ramirez.contractor@bbva.com    update method updateRecords
*1.10       26/05/2020     joseluis.garcia4.contractor@bbva.com         Makes getCustomerData() return a arce.Arc_Gen_Account_Wrapper.
*1.11       10/06/2020     cesaroctavio.villanueva.cebal@bbva.com       Added new fields to getAccountHasAnalysis return value
*1.12       24/06/2020     juanmanuel.perez.ortiz.contractor@bbva.com   Added two methods called deleteRatingRecords and getRatingVariables
*1.12       24/06/2020     juanignacio.hita.contractor@bbva.com         Added main_subsidiary_ind_type, group_asset_header_type fields to
*                                                                       getAccountHasAnalysis method
*1.13       25/06/2020     joseluis.garcia4.contractor@bbva.com         Modified persistProcessedFfss() method so it returns true when FFSS change.
*1.14       23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now
*                                                                       in the arce-dependencies package.
*1.15       12/11/2020     joseluis.garcia4.contractor@bbva.com         Add getDataCollectionsById() method.
*1.16       23/12/2020     juanignacio.hita.contractor@bbva.com         Add Name in getAccountHasAnalysis method
*1.17       18/01/2021     luisdavid.rivera.ortiz@bbva.com              Revome field references for usused fields (namings nivelation)
*1.18       21/01/2021     saimassimilianno.jordana.contractor@bbva.com Modified all getAccountInfoById calls to return the correct
*                                                                       accountWrapper if customAccount exists.
*1.19       02/02/2021     luisdavid.rivera.ortiz@bbva.com              Revomed unused fields
*1.20       16/04/2021     ronald.pisco.contractor@bbva.com             Modified getAccountHasAnalysis add subquery to arce__Financial_Statements__r
*1.21       21/04/2021     ivan.cons@bbva.com                           Added orderTableField method to query arceConfig
*1.22       23/12/2021     francisco.munoz.torres.contractor@bbva.com   Add getRecords method
*1.24       27/02/2023     joseluis.miralles.contractor@bbva.com        Update overlay record with ratingEngine value
*-----------------------------------------------------------------------------------------*/
@SuppressWarnings('PMD.ExcessivePublicCount,sf:TooManyMethods, PMD.CyclomaticComplexity, PMD.ApexCRUDViolation')
public without sharing class Arc_Gen_Balance_Tables_data {
    /**
    *-------------------------------------------------------------------------------
    * @description Sets Variables to use in this wrapper
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param null
    * @return null
    * @example public class SaveResult {
    **/
    public class SaveResult {
        /**
        * @author alberto.martinez.carrero.contractor@bbva.com
        */
        public String status {get;set;}
        /**
        * @author alberto.martinez.carrero.contractor@bbva.com
        */
        public String message {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description This is the constructor of the object Financial Statement.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param financial A financialStatement class instance that contains the object data
    * @return arce__Financial_Statements__c A structurated financial statement object
    * @example public static arce__Financial_Statements__c setFinancialStatements() {
    **/
    public static arce__Financial_Statements__c setFinancialStatements() {
        return new arce__Financial_Statements__c();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description inicialize arce__rating__c
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param void
    * @return arce__rating__c. object of rating
    * @example public static arce__rating__c setRating() {
    **/
    public static arce__rating__c setRating() {
        return new arce__rating__c();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description This method inserts a list of sObjects to Salesforce.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param recordsToInsert A list of sObjects to insert
    * @return SaveResult A SaveResult class instance that will contain the result of the insertion
    * @example public SaveResult insertRecords(List<sObject> recordsToInsert) {
    **/
    public SaveResult insertRecords(List<sObject> recordsToInsert) {
        final SaveResult insertResults = new SaveResult();
        if(recordsToInsert == null) {
            final NullPointerException excep = new NullPointerException();
            insertResults.status = 'false';
            insertResults.message = excep.getMessage();
        } else {
            final List<sObject> newRec = new List<sObject>(new Set<sObject>(recordsToInsert));
            try {
                insertResults.status = 'true';
                insert(newRec);
            } catch(Exception ex) {
                insertResults.status = 'false';
                insertResults.message = ex.getMessage();
            }
        }
        return insertResults;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description This method gets the Customer Data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param analysisId Id of the analysis
    * @return SaveResult A SaveResult class instance that will contain the result of the insertion
    * @example public List<String> getCustomerData(String analysisId) {
    **/
    public arce.Arc_Gen_Account_Wrapper getCustomerData(String analysisId) {
        arce.Arc_Gen_Account_Wrapper retData = null;
        if (Schema.sObjectType.arce__Account_has_Analysis__c.isAccessible()) {
            final arce__Account_has_Analysis__c analysis = [SELECT arce__Customer__c, arce__CustomAccountID__c FROM arce__Account_has_Analysis__c WHERE id =: analysisId LIMIT 1];
            final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(analysis);
            final Map<Id, arce.Arc_Gen_Account_Wrapper> mapWrap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{clientId});
            retData = mapWrap.get(clientId);
        }
        return retData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description get ffss List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param List<String> ids (ffss id's)
    * @return List<arce__Financial_Statements__c>.
    * @example public List<arce__Financial_Statements__c> getFinancialStatements(List<String> ids) {
    **/
    public List<arce__Financial_Statements__c> getFinancialStatements(List<String> ids) {
        List<arce__Financial_Statements__c> ffss = new List<arce__Financial_Statements__c>();
        if (Schema.sObjectType.arce__Financial_Statements__c.isAccessible()) {
            ffss = [SELECT id,arce__Selected_Adjustment_Type__c, arce__magnitude_unit_type__c,arce__Order__c,CurrencyIsoCode,arce__financial_statement_id__c,arce__ffss_auditor_qlfn_type__c,arce__ffss_auditor_opinion_type__c,arce__account_has_analysis_id__c,arce__rating_id__c,arce__financial_statement_start_date__c,arce__ffss_submitted_type__c,arce__financial_statement_end_date__c,arce__ffss_certification_type__c,tolabel(arce__ffss_adjusted_type__c) adjusted,arce__ffss_adjusted_type__c,arce__economic_month_info_number__c,arce__ffss_valid_type__c, arce__pd_per__c, arce__rating_long_value_type__c FROM arce__Financial_Statements__c WHERE Id in : ids];
        }
        return ffss;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description get ffss List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param List<String> ids (ffss id's)
    * @return List<arce__Financial_Statements__c>.
    * @example public arce__Financial_Statements__c getEmptyFinancialStatements() {
    **/
    public arce__Financial_Statements__c getEmptyFinancialStatements() {
        arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        if (Schema.sObjectType.arce__Financial_Statements__c.isAccessible()) {
            ffss = [SELECT id, arce__magnitude_unit_type__c, arce__ffss_submitted_type__c, CurrencyIsoCode, arce__financial_statement_id__c FROM arce__Financial_Statements__c WHERE arce__financial_statement_id__c = 'dummyFFSS'][0];
        }
        return ffss;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description get ffss List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String analysisId id of analysis
    * @return List<arce__Financial_Statements__c>.
    * @example public List<arce__Financial_Statements__c> getExistentFinancialStatements(String analysisId) {
    **/
    public List<arce__Financial_Statements__c> getExistentFinancialStatements(String analysisId) {
        List<arce__Financial_Statements__c> ffss = new List<arce__Financial_Statements__c>();
        if (Schema.sObjectType.arce__Financial_Statements__c.isAccessible()) {
            ffss = [SELECT id,arce__rating_id__c,arce__financial_statement_id__c,arce__account_has_analysis_id__c,arce__financial_statement_start_date__c,arce__ffss_submitted_type__c,arce__financial_statement_end_date__c,arce__ffss_certification_type__c,arce__ffss_adjusted_type__c,arce__economic_month_info_number__c,arce__ffss_valid_type__c FROM arce__Financial_Statements__c WHERE arce__account_has_analysis_id__c =: analysisId];
        }
        return ffss;
    }

    /**
    *--------------------------------------------------------------------------------
    * @description get arce__Account_has_Analysis__c List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String analysisId id of analysis
    * @return List<arce__Account_has_Analysis__c>. list of analysis
    * @example public List<arce__Account_has_Analysis__c> getAccountHasAnalysis(String analysisId) {
    **/
    public List<arce__Account_has_Analysis__c> getAccountHasAnalysis(String analysisId) {
        return [SELECT id,Name,arce__ffss_for_rating_id__c, arce__CustomAccountID__c, arce__Analysis__r.arce__parent_analysis_id__c,arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c,arce__Analysis__r.arce__analysis_risk_expiry_date__c,arce__ffss_for_rating_id__r.arce__magnitude_unit_type__c,arce__ffss_for_rating_id__r.currencyIsoCode,arce__main_subsidiary_ind_type__c, arce__group_asset_header_type__c, arce__ffss_for_rating_id__r.arce__financial_statement_id__c,
                (SELECT id,arce__financial_statement_end_date__c  FROM arce__Financial_Statements__r) FROM arce__Account_has_Analysis__c WHERE Id =: analysisId];
    }

    /**
    *-------------------------------------------------------------------------------
    * @description call ASO Ratios Service
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String params to call ASO
    * @return HttpResponse. response FROM service
    * @example public HttpResponse callEngine(String params) {
    **/
    public HttpResponse callEngine(String params) {
        // ratios service name (CMT). Mock must be set to 'retrieve mock = true' in order to pass test clases
        return arce.Arc_Gen_getIASOResponse.getServiceResponse('ratiosEngine', params);
    }

    /**
    *--------------------------------------------------------------------------------
    * @description get arce__Table_Content_per_Analysis__c List with data
    *--------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.contractor@bbva.com
    * @date     23/12/2021
    * @param String ahaId id of analysis
    * @param List<String> filterValues collection table to filter
    * @return List<arce__Table_Content_per_Analysis__c>. list of records
    * @example public List<arce__Table_Content_per_Analysis__c> getRecords(String recordId, List<String> filterValues) {
    **/
    public List<arce__Table_Content_per_Analysis__c> getRecords(String recordId, List<String> filterValues) {
        List<arce__Table_Content_per_Analysis__c> tcpa = new List<arce__Table_Content_per_Analysis__c>();
        if (Schema.sObjectType.arce__Table_Content_per_Analysis__c.isAccessible()) {
            tcpa = [
                SELECT Id, RecordTypeId, arce__Data_Collection_Id__c, arce__Data_collection_name__c, arce__account_has_analysis_id__c, arce__arce_collection_order_number__c, arce__collection_order_type__c,
                    arce__collection_table__c, arce__economic_month_info_number__c, arce__previous_valid__c, arce__table_content_parent_code_id__c, arce__table_content_percentage__c,
                    arce__table_content_value__c, arce__table_content_year__c, arce__valid_fin_statement__c
                FROM arce__Table_Content_per_Analysis__c
                WHERE arce__account_has_analysis_id__c = :recordId
                AND arce__collection_table__c IN :filterValues];
        }
        return tcpa;
    }

    /**
    *--------------------------------------------------------------------------------
    * @description get arce__Table_Content_per_Analysis__c List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String recordId id of analysis
    * @return List<arce__Table_Content_per_Analysis__c>. list of records
    * @example public List<arce__Table_Content_per_Analysis__c> getRecordsToClean(String recordId) {
    **/
    public List<arce__Table_Content_per_Analysis__c> getRecordsToClean(String recordId, List<String> filterValues) {
        List<arce__Table_Content_per_Analysis__c> tcpa = new List<arce__Table_Content_per_Analysis__c>();
        if (Schema.sObjectType.arce__Table_Content_per_Analysis__c.isAccessible()) {
            tcpa = [SELECT Id FROM arce__Table_Content_per_Analysis__c WHERE arce__account_has_analysis_id__c = :recordId AND arce__collection_table__c IN :filterValues];
        }
        return tcpa;
    }

    /**
    *--------------------------------------------------------------------------------
    * @description get arce__Table_Content_per_Analysis__c List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     16/12/2024
    * @param String recordId id of proposal
    * @return List<arce__Table_Content_per_Analysis__c>. list of records
    * @example public List<arce__Table_Content_per_Analysis__c> getRecordsToClean(String recordId) {
    **/
    public static List<arce__Table_Content_per_Analysis__c> getRecordsToCleanByProposal(String recordId, List<String> filterValues) {
        List<arce__Table_Content_per_Analysis__c> tcpa = new List<arce__Table_Content_per_Analysis__c>();
        if (Schema.sObjectType.arce__Table_Content_per_Analysis__c.isAccessible()) {
            tcpa = [SELECT Id FROM arce__Table_Content_per_Analysis__c WHERE arce__SP2_Proposal_Folder__c = :recordId AND arce__collection_table__c IN :filterValues];
        }
        return tcpa;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description get arce__Data_Collections__c List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Set<String> ids list of ids to retrieve
    * @return List<arce__Data_Collections__c>. list of data collections
    **/
    public static List<arce__Data_Collections__c> getDataCollectionsById(Set<String> ids) {
        List<arce__Data_Collections__c> datCol = new List<arce__Data_Collections__c>();
        if (Schema.sObjectType.arce__Data_Collections__c.isAccessible()) {
            datCol = [SELECT Name, arce__collection_table__c FROM arce__Data_Collections__c WHERE Id IN :ids ];
        }
        return datCol;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description get arce__Data_Collections__c List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param List<String> tablesList list of records to insert
    * @return List<arce__Data_Collections__c>. list of data collections
    * @example public List<arce__Data_Collections__c> getRecordsToInsert(List<String> tablesList) {
    **/
    public List<arce__Data_Collections__c> getRecordsToInsert(List<String> tablesList) {
        List<arce__Data_Collections__c> datCol = new List<arce__Data_Collections__c>();
        if (Schema.sObjectType.arce__Data_Collections__c.isAccessible()) {
            datCol = [SELECT Id, arce__collection_code_term__c, arce__collection_table__c,arce__collection_order_number__c FROM arce__Data_Collections__c WHERE arce__collection_table__c in : tablesList ];
        }
        return datCol;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description get arce__Table_Content_per_Analysis__c List with data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String analysisId
    * @param String finanStatemId
    * @return List<arce__Table_Content_per_Analysis__c>.
    * @example public List<arce__Table_Content_per_Analysis__c> getLeverageVariables(String analysisId,String finanStatemId) {
    **/
    public List<arce__Table_Content_per_Analysis__c> getLeverageVariables(String analysisId,String finanStatemId) {
        return [SELECT arce__Data_Collection_Id__r.arce__collection_code_term__c,arce__table_content_value__c FROM arce__Table_Content_per_Analysis__c WHERE arce__account_has_analysis_id__c =: analysisId AND arce__table_content_parent_code_id__c =: finanStatemId AND (arce__Data_Collection_Id__r.arce__collection_code_term__c = 'ebitda' OR arce__Data_Collection_Id__r.arce__collection_code_term__c = 'totalRevenues' OR arce__Data_Collection_Id__r.arce__collection_code_term__c = 'grossFinancialDebt' OR arce__Data_Collection_Id__r.arce__collection_code_term__c = 'netFinancialDebt' OR arce__Data_Collection_Id__r.arce__collection_code_term__c = 'totalAssets')];
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Msets Variables to use in this wrapper
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param List<sObject> recordsToDelete records to delete ffss
    * @return void.
    * @example public void deletePrevious(List<sObject> recordsToDelete) {
    **/
    public void deletePrevious(List<sObject> recordsToDelete) {
        Database.delete(recordsToDelete, true, AccessLevel.SYSTEM_MODE);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description update records
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param List<sObject> recordsToUpdate records to undate ffss
    * @return void.
    * @example public void updateRecords(List<sObject> recordsToUpdate) {
    **/
    public void updateRecords(List<sObject> recordsToUpdate) {
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description update record
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param sObject recordToUpdate records to update any
    * @return void.
    * @example public void updateRecord(sObject recordToUpdate) {
    **/
    public void updateRecord(sObject recordToUpdate) {
        update recordToUpdate;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description insert record
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param sObject recordToInsert new fsss
    * @return String record id.  id of analysis
    * @example public String insertNewRecord(sObject recordToInsert) {
    **/
    public static String insertNewRecord(sObject recordToInsert) {
        insert recordToInsert;
        Return recordToInsert.Id;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description return the data of the financial statement to update
    *--------------------------------------------------------------------------------
    * @author  mariohumberto.ramirez.contractor@bbva.com
    * @date     23/10/2019
    * @param eeffIdsLts - List of ids of financial statements
    * @param recordId - id of the account has analysis object
    * @return List<arce__Financial_Statements__c>
    * @example getFinancialState2Show(eeffIdsLts,recordId)
    **/
    public static List<arce__Financial_Statements__c> getFinancialState2Show (List<String> eeffIdsLts, String recordId) {
        return [SELECT Id, arce__magnitude_unit_type__c, arce__financial_statement_id__c FROM arce__Financial_Statements__c WHERE arce__financial_statement_id__c = :eeffIdsLts AND arce__account_has_analysis_id__c = :recordId];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description update record
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param sObject recordToUpdate records to update any
    * @return void.
    * @example public void updateRecord(sObject recordToUpdate) {
    **/
    public static void updateRecordLts(List<arce__Financial_Statements__c> recordToUpdate) {
        if (Schema.sObjectType.arce__Financial_Statements__c.isUpdateable()) {
            update recordToUpdate;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Synchronizes into the database the financial statements that were
    * selected for the analysis, deleting those that were not selected (but were before)
    * and upserting those that were selected.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    04/03/2020
    * @param analysisId Id of the Account_has_Analysis__c record
    * @param processedFfssList Selected FFSS list
    * @return Boolean - true if financial statements have changed from the ones that were
    * selected previously, false otherwise.
    **/
    public Boolean persistProcessedFfss(Id analysisId, List<arce__Financial_Statements__c> processedFfssList) {
        final List<String> ffssServiceIds = new List<String>();
        for (arce__Financial_Statements__c ffss : processedFfssList) {
            ffssServiceIds.add(ffss.arce__financial_statement_id__c);
        }

        // Delete existing FFSS that were not selected
        final List<arce__Financial_Statements__c> toDeleteFfssList = [
            SELECT Id FROM arce__Financial_Statements__c
            WHERE arce__account_has_analysis_id__c = :analysisId AND
                arce__financial_statement_id__c NOT IN :ffssServiceIds];

        // Update existing FFSS that were selected
        final List<arce__Financial_Statements__c> toUpsertFfssList = new List<arce__Financial_Statements__c>();
        final List<arce__Financial_Statements__c> existingFfssList = [
            SELECT Id, arce__financial_statement_id__c FROM arce__Financial_Statements__c
            WHERE arce__account_has_analysis_id__c = :analysisId AND
                arce__financial_statement_id__c IN :ffssServiceIds];

        final Map<String, arce__Financial_Statements__c> existFfssByServId = new Map<String, arce__Financial_Statements__c>();
        for (arce__Financial_Statements__c existingFfss : existingFfssList) {
            existFfssByServId.put(existingFfss.arce__financial_statement_id__c, existingFfss);
        }

        for (arce__Financial_Statements__c ffss : processedFfssList) {
            if (existFfssByServId.containsKey(ffss.arce__financial_statement_id__c)) {
                // Update.
                ffss.Id = existFfssByServId.get(ffss.arce__financial_statement_id__c).Id;
            } else {
                // Insert
                ffss.arce__account_has_analysis_id__c = analysisId;
            }

            toUpsertFfssList.add(ffss);
        }

        // Perform DMLs.
        Database.delete(toDeleteFfssList, true, AccessLevel.SYSTEM_MODE);
        Database.upsert(toUpsertFfssList, true, AccessLevel.SYSTEM_MODE);

        return !toDeleteFfssList.isEmpty() || existingFfssList.size() != processedFfssList.size();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description retrieve financial statemnts formated to table
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param varRecord recordId of the account_has_analysis.
    * @return list FROM financial statements.
    * @example public static List <arce__Financial_Statements__c> getPreviousFinancialStatements(String varRecord) {
    **/
    public static List <arce__Financial_Statements__c> getPreviousFinancialStatements(String varRecord) {
        List<arce__Financial_Statements__c> ffssList;
        ffssList = [SELECT Id,Name,toLabel(arce__ffss_valid_type__c),arce__financial_statement_end_date__c,arce__economic_month_info_number__c,toLabel(arce__ffss_certification_type__c),toLabel(arce__ffss_submitted_type__c),toLabel(arce__ffss_adjusted_type__c)
                    FROM arce__Financial_Statements__c WHERE arce__account_has_analysis_id__c=:varRecord];
        return ffssList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Delete rating records from Set ids
    *--------------------------------------------------------------------------------
    * @author  Juan Manuel Perez Ortiz
    * @date    24/06/2020
    * @param Set<Id> ratingRecordsToDelete
    * @return void
    * @example public void deleteRatingRecords(Set<Id> ratingRecordsToDelete) {
    **/
    public void deleteRatingRecords(Set<Id> ratingRecordsToDelete) {
        delete([SELECT id from arce__rating__c where id IN :ratingRecordsToDelete]);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Get all rating variables from account has analysis
    *--------------------------------------------------------------------------------
    * @author  Juan Manuel Perez Ortiz
    * @date     24/06/2020
    * @param ahaId recordId of the account_has_analysis.
    * @return List<arce__rating_variables_detail__c>
    * @example public List <arce__rating_variables_detail__c> getRatingVariables(String ahaId) {
    **/
    public List<arce__rating_variables_detail__c> getRatingVariables(String ahaId) {
        List<arce__rating_variables_detail__c> rvd = new List<arce__rating_variables_detail__c>();
        if (Schema.sObjectType.arce__rating_variables_detail__c.isAccessible()) {
            rvd = [SELECT id,name,arce__account_has_analysis_id__r.Name,arce__rating_var_score_number__c,arce__rating_id__r.arce__rating_long_value_type__c,arce__rating_override_reason_desc__c,arce__rating_id__c,arce__rating_variable_type_name__c FROM arce__rating_variables_detail__c WHERE arce__account_has_analysis_id__c =:ahaId];
        }
        return rvd;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Get RatiosOrderTableField from the custom metadata arceConfig.
    *--------------------------------------------------------------------------------
    * @author  Iván Cons Álvarez
    * @date     09/04/2021
    * @return arce__Arce_Config__mdt Arce Config Metadata that contains de orderTableField
    * @example public arce__Arce_Config__mdt orderTableField() {
    **/
    public static arce__Arce_Config__mdt orderTableField() {
        arce__Arce_Config__mdt conf = new arce__Arce_Config__mdt();
        if (Schema.sObjectType.arce__Arce_Config__mdt.isAccessible()) {
            conf = [SELECT Id, arce__Config_Name__c, arce__Value1__c FROM arce__Arce_Config__mdt WHERE arce__Config_Name__c = 'RatiosOrderTableField' limit 1];
        }
        return conf;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Get FFSSPaginatedCallout from the custom metadata arceConfig.
    *--------------------------------------------------------------------------------
    * @author  Aleksandar Ivanov
    * @date     30/05/2022
    * @return arce__Arce_Config__mdt Arce Config Metadata that contains FFSSPaginationField
    * @example arce__Arce_Config__mdt mdt = getFFSSPaginationField()
    **/
    public static arce__Arce_Config__mdt retrieveFFSSPaginationConfig() {
        return [SELECT Id, arce__Config_Name__c, arce__Value1__c FROM arce__Arce_Config__mdt WHERE arce__Config_Name__c = 'FFSSPaginatedCallout' limit 1];
    }

    /**
    *--------------------------------------------------------------------------------
    * @description get arce__Table_Content_per_Analysis__c List with data
    *--------------------------------------------------------------------------------
    * @author  joseluis.miralles.contractor@bbva.com
    * @date     27/02/2023
    * @param String ahaId id of analysis, related FFSS
    * @param List<String> ratiosCollection to get values
    * @return List<arce__Table_Content_per_Analysis__c>. list of records
    * @example public List<arce__Table_Content_per_Analysis__c> getRatiosRecords(String recordId,String relatedFFSS, List<String> ratiosCollection) {
    **/
    public static List<arce__Table_Content_per_Analysis__c> getRatiosRecords(String recordId,String relatedFFSS, List<Double> ratiosCollection) {
        return [SELECT Id, RecordTypeId, arce__Data_Collection_Id__c, arce__Data_collection_name__c, arce__account_has_analysis_id__c, arce__arce_collection_order_number__c,
            arce__collection_order_type__c,arce__collection_table__c, arce__economic_month_info_number__c, arce__previous_valid__c, arce__table_content_parent_code_id__c,
            arce__table_content_percentage__c, arce__table_content_value__c, arce__table_content_year__c, arce__valid_fin_statement__c
            FROM arce__Table_Content_per_Analysis__c
            WHERE arce__account_has_analysis_id__c = :recordId AND arce__table_content_parent_code_id__c=:relatedFFSS AND arce__arce_collection_order_number__c IN :ratiosCollection];
      }
    /**
    *-------------------------------------------------------------------------------
    * @description Update overlay with ratingEngine value
    *--------------------------------------------------------------------------------
    * @author joseluis.miralles.contractor@bbva.com
    * @date     27/02/2023
    * @example updateDataValueOverlay(ahaid,dataValue)
    **/
    public static void updateDataValueOverlay(String ahaid, String dataValue) {
        if (Schema.sObjectType.arce__Overlay__c.isUpdateable() && Schema.sObjectType.arce__Overlay__c.isAccessible()) {
            final arce__Overlay__c overlayRecord = [Select id from arce__Overlay__c where arce__Account_has_AnalysisId__c =:ahaid limit 1];
            overlayRecord.arce__Arc_Gen_Engine_Data_Value__c = dataValue;
            update(overlayRecord);
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return current FFSS data
    * -----------------------------------------------------------------------------------------------
    * @param - String recordId
    * @return - A List of arce__Financial_Statements__c data
    * @example getCurrentFFSS()
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__Financial_Statements__c> getCurrentFFSS(String recordId) {
        return [SELECT ID, arce__financial_statement_id__c, arce__rating_id__c FROM arce__Financial_Statements__c WHERE arce__account_has_analysis_id__c =: recordId];
    }
}