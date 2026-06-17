/*------------------------------------------------------------------
* @File Name: Arc_Gen_ModalFinanStatemController.cls
* @Author:        ARCE Team
* @Group:      	ARCE - BBVA Bancomer
* @Description:   Controller to modal Arc_Gen_ModalFinanStatem.
* @Changes :
* Methods to get and process FinancialStatemnt from ASO

Service class: Arc_Gen_Balance_Tables_Service
Data class: Arc_Gen_Balance_Tables_data
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        11/04/2019     ARCE TEAM   							Creación.
*1.1		24/04/2019	   diego.miguel.contractor@bbva.com		        Modified ratios function to parse Json response properly
*1.2		25/04/2019	   diego.miguel.contractor@bbva.com	            Modified ratios and eeff functions to handle error messages and display to users
*1.3		20/12/2019	   mariohumberto.ramirez.contractor@bbva.com    Added new wrapper FinancialDetailsWrapper and new method consultFSdetails
*1.4		30/01/2020	   juanmanuel.perez.ortiz.contractor@bbva.com	Add missing custom labels
*1.5        09/03/2020     eduardoefrain.hernandez.contractor@bbva.com  adedd methods because of Indepentent Rating (RAIP)
*1.6        26/03/2020     juanignacio.hita.contractor@bbva.com         Refactoring
*1.7        15/04/2020     joseluis.garcia4.contractor@bbva.com         Implement FinancialStatementsFetchWrapper to provide label to frontend
*1.8        26/05/2020     joseluis.garcia4.contractor@bbva.com         Error messages when no FFSS are found.
*1.9        16/06/2020     joseluis.garcia4.contractor@bbva.com         Prevent call to ratios engine if user has no edit permission on analysis.
*1.10       07/07/2020     juanignacio.hita.contractor@bbva.com         Add translatePicklistValues list for save ffss list with labels translated from service.
*1.11       10/01/2021     ivan.cons@bbva.com                           Added isPreselected feature for retrieve the preselected FFSS.
*1.12       15/03/2021     ivan.cons@bbva.com                           Added isFinancialRAIP param to callEngineFinancialState
                                                                        for differenciate flows.
+1.13       22/06/2021     ivan.cons@bbva.com                           Added empty constructor
*1.14       26/10/2021     juanignacio.hita.contractor@bbva.com         Adds ratingTool param that is used in irp wizard with pre step triage configured, supresses ExcessiveParameterList pmd rule
*1.15       09/12/2021     juanignacio.hita.contractor@bbva.com         Add step custom irp logic to call ratios engine in callEngineFinancialState method
*1.16       05/01/2021     amunguia.contractor@bbva.com                 Create methods to save the inline edition and activate an extra configurable column
*1.17       14/03/2022     francisco.munoz.torres.contractor@bbva.com   Get audit data from FFSS details and set into FFSS object
*1.18       27/02/2023     joseluis.miralles.contractor@bbva.com        Update overlay record with ratingEngine value
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.ExcessivePublicCount, PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public with sharing class Arc_Gen_ModalFinanStatemController {
    /**
    * @Description Value of the "Valid" picklist entry of the ffss_valid_type field.
    */
    private static final String FFSS_VALID_TYPE_VALUE = '1';
    /**
    * @Description Literal string value "text" used to describe field type.
    */
    private static final String STRING_VALUE_TEXT = 'text';
    /**
    * @Description Value of the default exception message
    */
    private static final String DEFAULT_EXCEPTION_MESSAGE = 'Script-thrown exception';
    /**
    * @Description: Double with value "7300"
    */
    private static final Double RATIO_ID = 7300;
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the component
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return all the information to create the component
    * @example TabsWrapper tabswrapper = new TabsWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class FinancialDetailsWrapper {
        /**
        * @Description: Contain a message of error
        */
        @AuraEnabled public String gblResulError {get;set;}
        /**
        * @Description: Boolean to manage the result of an operation
        */
        @AuraEnabled public Boolean gblSuccessOperation {get;set;}
        /**
        * @Description: String to manage the servicecode of a service
        */
        @AuraEnabled public Integer gblRespServiceCode {get;set;}
        /**
        * @Description: Integer that contains the employess number
        */
        @AuraEnabled public Integer employeesNumber {get;set;}
        /**
        * @Description: Object that contains the audit data
        */
        @AuraEnabled public Audit audit {get;set;}
    }
    /**
    * @Description: Structure of the Audit
    */
    public class Audit {
      public Auditor auditor {get; set;}
      public String auditDate {get;set;}
      public String quality {get;set;}

      public Audit(Object auditObject) {
        if(auditObject != null) {
          Map<String, Object> auditData = (Map<String, Object>)auditObject;
          auditDate = auditData.containsKey('auditDate')? (String)auditData.get('auditDate'): '';
          quality = auditData.containsKey('quality')? (String)auditData.get('quality'): '';
          auditor = auditData.containsKey('auditor')? new Arc_Gen_ModalFinanStatemController.Auditor(auditData.get('auditor')): new Arc_Gen_ModalFinanStatemController.Auditor();
        }
      }
    public Audit() {
        auditor = new Arc_Gen_ModalFinanStatemController.Auditor();
      }
    }
    /**
    * @Description: Structure of the Auditor
    */
    public class Auditor {
      public String opinion {get; set;}
      public String name {get; set;}
      public String origin {get; set;}
      public String hasQualification {get; set;}

      public Auditor(Object auditorObject){
        if(auditorObject != null) {
          Map<String, Object> auditorData = (Map<String, Object>) auditorObject;
          opinion = auditorData.containsKey('opinion')? (String)auditorData.get('opinion'): '';
          name = auditorData.containsKey('name')? (String)auditorData.get('name'): '';
          origin = auditorData.containsKey('origin')? (String)auditorData.get('origin'): '';
          hasQualification = auditorData.containsKey('hasQualification')? ((Boolean)auditorData.get('hasQualification')?'S':'N'): 'N';
        }
      }
    /**
    * @Description: Structure of the Auditor
    */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public Auditor() {}
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contains a list of FFSS, as well as the label of the valid picklist type
    * for comparison
    * -----------------------------------------------------------------------------------------------
    **/
    public class FinancialStatementsFetchWrapper {
        /**
        * @Description: List of financial statements.
        */
        @AuraEnabled public List<arce__Financial_Statements__c> ffssList { get; set; }

        /**
        * @Description: List of financial statements with labels translated.
        */
        @AuraEnabled public List<arce__Financial_Statements__c> ffssListLabel { get; set; }

        /**
        * @Description: Label of the valid picklist value of the ffss_valid_type field.
        */
        @AuraEnabled public String validLabel { get; set; }

        /**
        * @Description: Label of the valid picklist value of the ffss_valid_type field.
        */
        @AuraEnabled public Set<String> preselected { get; set; }
        /**
        * @Description: Pagination object to be returned from service.
        */
        @AuraEnabled public Arc_Gen_Balance_Tables_service.Pagination pagination { get; set; }
    }

    /**
    * Empty constructor to avoid static code analysis tool warnings.
    */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private Arc_Gen_ModalFinanStatemController() {

    }

    /**
    *-------------------------------------------------------------------------------
    * @description method that draw the table of financial statements.
    *--------------------------------------------------------------------------------
    * @author diego.miguel.contractor@bbva.com
    * @date 2019-04-11
    * @param varRecord recordId of the account_has_analysis.
    * @param isFinancialRAIP
    * @param isRAIP
    * @param ratingToolSelect
    * @param requestedPage Page number to be requested from service, if null web service fetch all FFSS at once, without pagination.
    * @return FinancialStatementsFetchWrapper class object containing financial statements list and pagination info, when requestedPage param is populated.
    * @example FinancialStatementsFetchWrapper wrapper = fetchFinancialStatements(varRecord, isFinancialRAIP, isRAIP, ratingToolSelect, requestedPage);
    **/
    @AuraEnabled
    public static FinancialStatementsFetchWrapper fetchFinancialStatements(String varRecord, Boolean isFinancialRAIP, Boolean isRAIP, String ratingToolSelect, Integer requestedPage) {
        try {
            final FinancialStatementsFetchWrapper wrapper = new FinancialStatementsFetchWrapper();
            String ratingTool = ratingToolSelect == null ? Arc_Gen_RatingAsIndepProcess_service.getRatingIdSelIrp(varRecord) : ratingToolSelect;
            if(isFinancialRAIP) {
                final Set<String> preselectedFFSS = new Set<String>();
                for(arce__Account_has_Analysis__c aHa : arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{varRecord})) {
                    preselectedFFSS.add(aHa.arce__ffss_for_rating_id__r.arce__financial_statement_id__c);
                }
                wrapper.preselected = preselectedFFSS;
            }
            final Arc_Gen_Balance_Tables_service.SetupFFSSHeadersWrapper setupWrapper = Arc_Gen_Balance_Tables_service.setupFFSSHeaders(varRecord, false, ratingTool, requestedPage);
            wrapper.pagination = setupWrapper.pagination;
            wrapper.ffssList = setupWrapper.ffssList;
            wrapper.ffssListLabel = Arc_Gen_Balance_Tables_Service.translatePicklistValues(wrapper.ffssList);
            // Get label for "Valid" value of ffss_valid_type field
            final List<Schema.PicklistEntry> picklistEntries = arce__Financial_Statements__c.arce__ffss_valid_type__c.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.getValue() == FFSS_VALID_TYPE_VALUE) {
                    wrapper.validLabel = entry.getLabel();
                }
            }
            setUsedInAnalysisFFSS(wrapper.ffssListLabel, varRecord);
            return wrapper;
        } catch (Exception ex) {
            System.debug('e '+ex.getStackTraceString());
            AuraHandledException auraEx = financialStatementExceptionHandling(ex);
            throw auraEx; // NOSONAR
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method that set the used in analysis field to true or false.
    *--------------------------------------------------------------------------------
    * @author aleksandar.dinkov.contractor@bbva.com
    * @date 2025-03-28
    * @param ffssListLabel - List of financial statements with labels translated.
    * @param varRecord - recordId of the account_has_analysis.
    **/
    private static void setUsedInAnalysisFFSS(List<arce__Financial_Statements__c> ffssListLabel, String varRecord) {
        final Set<String> usedFfssIds = new Set<String>();

        final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{varRecord})[0]);
        final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{clientId}).get(clientId);

        for (arce__Account_has_Analysis__c actualAha : [SELECT Id, arce__ffss_for_rating_id__r.arce__financial_statement_id__c, arce__Analysis__r.arce__wf_status_id__c FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__wf_status_id__c = '13' AND arce__Customer__c = :accWrapper.accId WITH SYSTEM_MODE ORDER BY arce__ffss_for_rating_id__r.arce__financial_statement_id__c DESC]) {
            if (String.isNotBlank(actualAha.arce__ffss_for_rating_id__r.arce__financial_statement_id__c)) {
                usedFfssIds.add(actualAha.arce__ffss_for_rating_id__r.arce__financial_statement_id__c);
            }
        }
        for (arce__Financial_Statements__c ffss : ffssListLabel) {
            ffss.arce__Is_used_in_analisys__c = usedFfssIds.contains(ffss.arce__financial_statement_id__c) ? true : false;
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method that call callEngineFinancialState and return the status of engine.
    *--------------------------------------------------------------------------------
    * @author diego.miguel.contractor@bbva.com
    * @date 2019-04-11
    * @param recordId - recordId of the account_has_analysis and the list of elements selected from the table.
    * @param financialIdList - List<String> data for the tables
    * @param isRAIP - Boolean - check if it comes from a RAIP.
    * @param isFinancialRAIP - Boolean - check if it comes from a Financial RAIP.
    * @return Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse
    * @example public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callEngineFinancialState(String recordId,String lista) {
    **/
    @AuraEnabled
    public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callEngineFinancialState(
        String recordId,
        List<arce__Financial_Statements__c> updatedEEFF,
        List<String> financialIdList,
        Boolean isRAIP,
        Boolean isFinancialRAIP,
        String ratingToolSelect,
        String pFolderArceId
    ) {
        final Boolean hasPermissions = Arc_Gen_TabSet_service.getPermissionToEdit(recordId) == 'true';
        Map<String, String> updatedOrder = new Map<String, String>();
        for(arce__Financial_Statements__c aux :updatedEEFF) {
            updatedOrder.put(aux.arce__financial_statement_id__c, aux.arce__Order__c);
            updatedOrder.put('arce__Selected_Adjustment_Type__c', aux.arce__Selected_Adjustment_Type__c);
        }
        if (!hasPermissions && pFolderArceId == null) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_NotAllowed);
        }
        Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
        try {
            final List<arce__Financial_Statements__c> financialStat = Arc_Gen_Balance_Tables_service.setupFFSSHeadersProp(recordId, false, ratingToolSelect, pFolderArceId);
            for(arce__Financial_Statements__c aux :financialStat) {
                aux.arce__Order__c = updatedOrder.get(aux.arce__financial_statement_id__c);
                aux.arce__Selected_Adjustment_Type__c = updatedOrder.get('arce__Selected_Adjustment_Type__c');
            }
            final List<arce__Financial_Statements__c> selectedFinancialStatements = Arc_Gen_Balance_Tables_service.filterFFSSByServiceId(financialStat, financialIdList);
            Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse resp = new Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse();
            final Boolean invokeRatios = isRAIP ? Arc_Gen_RatingAsIndepProcess_service.invokeRatiosEngine(recordId, ratingToolSelect) : true;
            if (invokeRatios) {
                resp = Arc_Gen_Balance_Tables_service.buildTables(recordId, selectedFinancialStatements, isRAIP, isFinancialRAIP, pFolderArceId);
            } else {
                resp = Arc_Gen_Balance_Tables_service.createRatiosAndRespWrapper(selectedFinancialStatements[0].arce__financial_statement_id__c);
                List<arce__Account_has_Analysis__c> analyzedClient = dataAccess.getAccountHasAnalysis(recordId);
                Arc_Gen_Balance_Tables_data.insertNewRecord(selectedFinancialStatements[0]);
                Arc_Gen_Balance_Tables_helper.saveRatingFfss(analyzedClient[0], selectedFinancialStatements, resp, selectedFinancialStatements[0]);
            }

            if(pFolderArceId == null) {
                dataValueUpdate(recordId);
            }

            return resp;
        } catch (Exception ex) {
            System.debug('e '+ex.getStackTraceString());
            //AuraHandledException auraEx = financialStatementExceptionHandling(ex);
            throw ex;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Auxiliary method to help with the exception handling in order to avoid complexity issues
    *--------------------------------------------------------------------------------
    * @author andres.rodriguez.contractor@bbva.com
    * @date 2022-04-28
    * @param ex - the exception that has been caught
    **/
    public static AuraHandledException financialStatementExceptionHandling(Exception ex) {
        AuraHandledException res = null;
        if (ex instanceOf Arc_Gen_Balance_Tables_service.NoFinancialStatementDataException) {
            Arc_Gen_Balance_Tables_service.NoFinancialStatementDataException exc = (Arc_Gen_Balance_Tables_service.NoFinancialStatementDataException) ex;
            if (exc.reason == Arc_Gen_Balance_Tables_service.NoFinancialStatementReason.NO_FFSS_EMPTY_LIST) {
                res = new AuraHandledException(System.Label.Arc_Gen_NoReturnedFFSS);
            } else if (exc.reason == Arc_Gen_Balance_Tables_service.NoFinancialStatementReason.NO_FFSS_NO_SERVICE) {
                res = new AuraHandledException(System.Label.Lc_arce_RAIP_CannotExecuteGroup);
            } else {
                res = new AuraHandledException(System.Label.Arc_Gen_ErrorService);
            }
        } else {
            if (ex.getMessage() == DEFAULT_EXCEPTION_MESSAGE) {
                res = new AuraHandledException(System.Label.Arc_Gen_ErrorService);
            } else {
                res = new AuraHandledException(ex.getMessage());
                res.setMessage(ex.getMessage());
            }
        }
        return res;
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the financial statement details service and set the number of employess of the subsidiary
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-12-19
    * @param recordId - Id of the account_has_analysis
    * @param fsServiceId - Id of the financial statement
    * @return FinancialDetailsWrapper - wrapper with the result of the operation
    * @example consultFSdetails(recordId, fsServiceId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static FinancialDetailsWrapper consultFSdetails(String recordId, String fsServiceId, Boolean isProposal) {
        FinancialDetailsWrapper response =  new FinancialDetailsWrapper();
        try {
            response = Arc_Gen_FinStatDetails_Service.getFFSSDetail(recordId, fsServiceId);
            if(response.gblSuccessOperation) {
                if(!isProposal) {
                    Arc_Gen_FinStatDetails_Service.setNumberOfEmployees(recordId, response.employeesNumber);
                }
                String ffssId = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId})[0].arce__ffss_for_rating_id__c;
                List<arce__Financial_Statements__c> ffssList = arce.Arc_Gen_FinancialStatements_Locator.getFSInfo(new List<String>{ffssId});
                if(!ffssList.isEmpty()) {
                    Arc_Gen_FinStatDetails_Service.setFFSSAuditData(ffssList[0], response.audit);
                }
            }
        } catch (Exception e) {
            response.gblSuccessOperation = false;
            response.gblResulError = e.getMessage() + ' : ' + e.getLineNumber();
            System.debug('Error consultFSdetails: ' + e.getStackTraceString());
        }
        return response;
    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the financial statement details service and set the number of employess of the subsidiary
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-12-19
    * @param recordId - Id of the account_has_analysis
    * @param fsServiceId - Id of the financial statement
    * @return FinancialDetailsWrapper - wrapper with the result of the operation
    * @example consultFSdetails(recordId, fsServiceId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void updateEEFF(List<arce__Financial_Statements__c> eeffList) {
        if (Schema.sObjectType.arce__Financial_Statements__c.isUpdateable()) {
            update eeffList;
        }
    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description get Dynamic Columns
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   amunguia.contractor@bbva.com
    * @Date     Created: 2022-01-05
    * @param isRaip - Boolean
    * @return String - wrapper with the result of the operation
    * @example getDynamicColumns(isRaip) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getDynamicColumns(Boolean isRaip) {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_SortableEEFF');

        final Boolean sortable = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();
        if(sortable && !isRaip) {
            writeNewCol(gen, null, 25, 'arce__Order__c', 'phone', true, true);
        }
        writeNewCol(gen, System.Label.Lc_arce_Date, 110, 'arce__financial_statement_end_date__c', STRING_VALUE_TEXT, null, null);
        writeNewCol(gen, System.Label.Lc_arce_Period, 82, 'arce__economic_month_info_number__c', STRING_VALUE_TEXT, null, null);
        writeNewCol(gen, System.Label.Lc_arce_Certification, null, 'arce__ffss_certification_type__c', STRING_VALUE_TEXT, null, null);
        writeNewCol(gen, System.Label.Lc_arce_Type, null, 'arce__ffss_submitted_type__c', STRING_VALUE_TEXT, null, null);
        final Boolean isRaipCorp = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c);
        if(!isRaipCorp) {
            writeNewCol(gen, System.Label.Lc_arce_ValidForRating, null, 'arce__ffss_valid_type__c', STRING_VALUE_TEXT, null, null);
        }
        writeNewCol(gen, System.Label.Lc_arce_ValidForRating, null, 'arce__ffss_valid_type__c', STRING_VALUE_TEXT, null, null);
        writeNewCol(gen, System.Label.Lc_arce_AdjustedType, null, 'arce__ffss_adjusted_type__c', STRING_VALUE_TEXT, null, null);
        writeNewCol(gen, 'Id', 75, 'shortId', STRING_VALUE_TEXT, null, null);
        gen.writeEndArray();

        return gen.getAsString();
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description save EEFF
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   amunguia.contractor@bbva.com
    * @Date     Created: 2022-01-05
    * @param List<arce__Financial_Statements__c> fflist
    * @param List<arce__Financial_Statements__c> draft
    * @param String selectedRows
    * @return List<arce__Financial_Statements__c>
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<arce__Financial_Statements__c> saveEEFF(List<arce__Financial_Statements__c> fflist, List<arce__Financial_Statements__c> draft, String selectedRows) {
        Set<String> selectedSet = (Set<String>) JSON.deserialize(selectedRows, Set<String>.class);
        Map<String, arce__Financial_Statements__c> eeffMap = new Map<String, arce__Financial_Statements__c>();
        Map<String, String> orderMap = new Map<String, String>();
        for(arce__Financial_Statements__c aux : fflist) {
            eeffMap.put(aux.arce__financial_statement_id__c, aux);
            orderMap.put(aux.arce__Order__c, aux.arce__financial_statement_id__c);

        }
        for(arce__Financial_Statements__c aux : draft) {
            if(selectedSet.contains(aux.arce__financial_statement_id__c)) {
                if(orderMap.containsKey(aux.arce__Order__c)) {
                    eeffMap.get(orderMap.get(aux.arce__Order__c)).arce__Order__c = eeffMap.get(aux.arce__financial_statement_id__c).arce__Order__c;
                }
                eeffMap.get(aux.arce__financial_statement_id__c).arce__Order__c = aux.arce__Order__c;
            }
        }
        return eeffMap.values();
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description Update datavalue from ratiosEngine response
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     Created: 2023-02-28
    * @param String recordId
    * @return void
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static void dataValueUpdate(String recordId) {
        Arc_Gen_Balance_Tables_data balanceClass = new Arc_Gen_Balance_Tables_data();
        final List<Double> ratiosToGet = new List<Double>{RATIO_ID};
        final List<arce__Account_has_Analysis__c> listFFSS = balanceClass.getAccountHasAnalysis(recordId);
        final String idFFSS = listFFSS.isEmpty() ?  '' : listFFSS.get(0).arce__ffss_for_rating_id__r.arce__financial_statement_id__c;
        final List<arce__Table_Content_per_Analysis__c> ratiosValues = Arc_Gen_Balance_Tables_data.getRatiosRecords(recordId,idFFSS,ratiosToGet);
        if(!ratiosValues.isEmpty() && String.isNotBlank(idFFSS)) {
            Arc_Gen_Balance_Tables_data.updateDataValueOverlay(recordId,String.valueOf(ratiosValues.get(0).arce__table_content_value__c));
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method that update field isRTC
    *--------------------------------------------------------------------------------
    * @Author isabel.ascaso.contractor@bbva.com
    * @Date 2023/09/19
    * @param analysisId - id of analysis
    * @return ok
    * @example Arc_Gen_ModalFinanStatemController.getSplittedMdtValue(arceConfigName)
    *--------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void updateIsRTC(String ahaId) {
        if (Schema.sObjectType.arce__Account_has_Analysis__c.isAccessible()) {
            final arce__Account_has_Analysis__c aha = [SELECT arce__Analysis__c FROM	arce__Account_has_Analysis__c WHERE Id =: ahaId];
            final arce__Analysis__c analysis = new arce__Analysis__c(Id = aha.arce__Analysis__c);
            analysis.arce__is_RTC__c = true;
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c>{analysis});
        }
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description Write new JSON node that represents a column.
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   francisco.munoz.torres.next@bbva.com
    * @Date     26/02/2024
    * @param JSONGenerator gen      - JSONGenerator instance must be started and ended, see example below.
    * @param String label           - set null to avoid creating this parameter.
    * @param Integer initialWidth   - set null to avoid creating this parameter.
    * @param String fieldName       - set null to avoid creating this parameter.
    * @param String type            - set null to avoid creating this parameter.
    * @param Boolean editable       - set null to avoid creating this parameter.
    * @param Boolean sortable       - set null to avoid creating this parameter.
    * @example
    * JSONGenerator gen = JSON.createGenerator(false);
    * gen.writeStartArray();
    * writeNewCol(gen, 'RandomLabel', 25, 'arce__Order__c', 'phone', true, true);
    * gen.writeEndArray();
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void writeNewCol(
        JSONGenerator gen,
        String label,
        Integer initialWidth,
        String fieldName,
        String type,
        Boolean editable,
        Boolean sortable
    ) {
        gen.writeStartObject();
        if (label != null) {
            gen.writeStringField('label', label);
        }
        if (initialWidth != null) {
            gen.writeNumberField('initialWidth', initialWidth);
        }
        if (fieldName != null) {
            gen.writeStringField('fieldName', fieldName);
        }
        if (type != null) {
            gen.writeStringField('type', type);
        }
        if (editable != null) {
            gen.writeBooleanField('editable', editable);
        }
        if (sortable != null) {
            gen.writeBooleanField('sortable', sortable);
        }
        gen.writeEndObject();
    }
}