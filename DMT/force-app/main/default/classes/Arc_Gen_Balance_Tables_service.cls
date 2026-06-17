/*------------------------------------------------------------------
*Author:        ARCE Team
*Project:      	ARCE - BBVA Bancomer
*Description:   Service class to get and process FinancialStatemnt FROM ASO
Controller class: Arc_Gen_ModalFinanStatem
Data class: Arc_Gen_Balance_Tables_data
*_______________________________________________________________________________________
* @Changes
*Version    Date           Author                                       Description
*1.0        11/04/2019     ARCE TEAM   							        Creación.
*1.1		24/04/2019	   diego.miguel.contractor@bbva.com		        Modified ratios function to parse Json response properly
*1.2		25/04/2019	   diego.miguel.contractor@bbva.com 	        Modified ratios and eeff functions to handle error messages and display to users
*1.3		17/05/2019	   diego.miguel.contractor@bbva.com 	        Modify function to handle 3 calls to WS
*1.4		29/05/2019	   eduardoefrain.hernandez.contractor@bbva.com 	Modify function buildTables to fix the errors managing
*1.5		17/07/2019	   ricardo.almanza.contractor@bbva.com      	Modify method listToInsertMethod to set arce__table_content_year__c adding full
*                                                                       date and arce__ffss_certification_type__c
*1.6		20/09/2019	   eduardoefrain.hernandez.contractor@bbva.com 	Fix managing error incidence
*1.7		26/09/2019	   javier.soto.carrascosa@bbva.com 	            Remove mock
*1.8        23/10/2019     mariohumberto.ramirez.contractor@bbva.com    Added new method updateEEFFtoShow
*1.8.1      02/12/2019     german.sanchez.perez.contractor@bbva.com
*                          franciscojavier.bueno@bbva.com               Api names modified with the correct name on business glossary
*1.8.2      06/12/2019     jhovanny.delacruz.cruz@bbva.com              Encryption funcionality enabled
*1.9        19/12/2019     mariohumberto.ramirez.contractor@bbva.com    Modified funcionality for HU "Aprovisionamiento numero de empleados en Front"
*1.10       30/01/2020     juanmanuel.perez.ortiz.contractor@bbva.com   Add missing custom labels
*1.11       20/02/2020     juanmanuel.perez.ortiz.contractor@bbva.com   Fix incidence, geography data was deleted
*                                                                       when loading another financial statement
*1.12       09/03/2020     eduardoefrain.hernandez.contractor@bbva.com  adedd methods because of Indepentent Rating (RAIP)
*1.13       23/03/2020     eduardoefrain.hernandez.contractor@bbva.com  Reorder validate actions in buildTables method
*1.14       01/04/2020     juanmanuel.perez.ortiz.contractor@bbva.com   Modify method 'buildTables' to convert eventType in dynamic value
*1.15       26/03/2020     juanignacio.hita.contractor@bbva.com         Refactoring
*1.16       17/04/2020     mariohumberto.ramirez.contractor@bbva.com    Add new logic in order to mark the ratios of the valid FS and previous year
*                                                                       FS inside the methods callProcessData and listToInsertMethod
*1.16       26/03/2020     joseluis.garcia4.contractor@bbva.com         Shows the correct error when ratios engine call fails.
*1.17       26/05/2020     joseluis.garcia4.contractor@bbva.com         FFSS test call + Service distinction for group and client.
*1.18       08/06/2020     mariohumberto.ramirez.contractor@bbva.com    Corrected error message in the modal when valid
*                                                                       financial statements are not selected
*1.19       15/06/2020     juanignacio.hita.contractor@bbva.com         Add non mandatory percentage and unexisting balances getPercentFromMap method
*1.20       25/06/2020     mariohumberto.ramirez.contractor@bbva.com    Fix cpu limit apex error
*1.21       25/06/2020     joseluis.garcia4.contractor@bbva.com         Clear Leveraged Test results when financial statements change.
*1.22       07/07/2020     juanignacio.hita.contractor@bbva.com         Added validation before call to rating engine and
*                                                                       translatePicklistValues method
*1.23       08/07/2020     juanignacio.hita.contractor@bbva.com         Add submit_type field in the ffss table header and abbreviate the types
*1.24       24/07/2020     joseluis.garcia4.contractor@bbva.com         Use field label for certification type of FFSS.
*1.25       15/09/2020     joseluis.garcia4.contractor@bbva.com         Performance improvement on listToInsertMethod method.
*1.26       23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in
*                                                                       the arce-dependencies package
*1.27       29/10/2020     joseluis.garcia4.contractor@bbva.com         If a data collection element is not found in the ratios response,
*                                                                       don't log the exception.
*1.28       04/11/2020     joseluis.garcia4.contractor@bbva.com         Include new parameter participantType in ratios request.
*1.29       23/12/2020     juanignacio.hita.contractor@bbva.com         Changes the mapping of the risk AssessmentId parameter of the service
*1.30       05/01/2021     joseluis.garcia4.contractor@bbva.com         Performance improvement on listToInsertMethod
*                                                                        method (include improvements from R3).
*1.31       29/01/2021     joseluis.garcia4.contractor@bbva.com         Force re-validation when financial statements change.
*1.32       03/03/2021     ivan.cons@bbva.com                           Overloaded processRatioDataValues to accept API update with
                                                                        specificRatiosMagnitudes param. If this param comes, it will ignore others
*1.33       15/03/2021     ivan.cons@bbva.com                           When method is called from IPR flow in financial risk tab, EEFF is not updated.
*1.33       21/04/2021     ivan.cons@bbva.com                           Gets column field from arceConfig to improve tables flexibility
*1.34       30/04/2021     otiliaramona.veres.contractor@bbva.com       Added an empty constructor method.
*1.35       04/05/2021     otiliaramona.veres.contractor@bbva.com       Added annotation '@testVIsible' to the empty constructor method.
*1.36       06/05/2021     otiliaramona.veres.contractor@bbva.com       Cleared unsued variable 'messageReturn'  of the method 'callProcessData'.
*1.37       23/08/2021     amunguia.contractor@bbva.com                 Multiple ratios can be created in different positions
*1.38       26/10/2021     juanignacio.hita.contractor@bbva.com         Adds ratingTool param that is used in irp wizard with
*                                                                       pre step triage configured
*1.39       09/12/2021     juanignacio.hita.contractor@bbva.com         Adds createRatiosAndRespWrapper method that return success wrapper.
*1.40       14/12/2021     otiliaramona.veres.contractor@bbva.com       Added condition for amount when unit is a percentage
*1.41       05/01/2022     amunguia.contractor@bbva.com                 The header of the key figure table is modified.
*1.42       17/02/2022     juanignacio.hita.contractor@bbva.com         Adds exception when service call failed with the valid eeff
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('PMD.ExcessivePublicCount,sf:TooManyMethods,sf:ExcessiveClassLength,PMD.ExcessiveClassLength, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.NcssMethodCount')
public with sharing class Arc_Gen_Balance_Tables_service {
    /*
    * @Description map with the picklist values and labels of arce__collection_table__c
    */
    static final Map<String,String> COLLECTION_MAP = arce.Arc_Gen_GenericUtilities.getMapLabelFromValue('arce__Table_Content_per_Analysis__c','arce__collection_table__c');
    /*
    * @Description Group participant type.
    */
    private static final String PART_TYPE_GROUP = 'GROUP';
    /*
    * @Description Name of the financial statements service for clients.
    */
    private static final String FFSS_SRVNAMECLI = 'financialStatements';
    /*
    * @Description Name of the financial statements service for groups.
    */
    private static final String FFSS_SRVNAMEGROUP = 'financialStatementsGroup';
    /*
    * @Description Name of Percentage
    */
    private static final String FFSS_SERVPERC = 'PERCENTAGE';
    /*
    * @Description currency Literal
    */
    private static final String CURRENCY_LIT = 'currency';
    /*
    * @Description unit Literal
    */
    private static final String UNIT_LIT = 'unit';
    /*
    * @Description amount Literal
    */
    private static final String AMOUNT_LIT = 'amount';
    /*
    * @Description amount Literal
    */
    private static final String TRUE_VALUE = 'true';
    /**
    * @Description: Double with value "7300"
    */
    private static final Double RATIO_ID = 7300;

    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_Gen_Balance_Tables_service() { }
    /**
    *-------------------------------------------------------------------------------
    * @description Enum that lists the possible reasons there are no FFSS for a
    * given participant.
    *-------------------------------------------------------------------------------
    */
    public enum NoFinancialStatementReason { NO_FFSS_EMPTY_LIST, NO_FFSS_NO_SERVICE }

    /**
    *-------------------------------------------------------------------------------
    * @description Exception used to signal the lack of financial statement data, either because
    * there is no available service for the group or because the service did not return
    * any financial statements.
    *-------------------------------------------------------------------------------
    * @author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @date     25/05/2020
    */
    public class NoFinancialStatementDataException extends Exception {
        /**
        * @Description The reason for the exception.
        */
        public NoFinancialStatementReason reason { get; set; }

        /**
        * @description Constructor.
        */
        public NoFinancialStatementDataException(NoFinancialStatementReason reason) {
            this.reason = reason;
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description class used to handle aso responses in this wrapper
    *--------------------------------------------------------------------------------
    * @author   ARCE TEAM
    * @date     11/04/2019
    * @param null
    * @return null
    * @example public class RatiosAndRatingResponse {
    **/
    public class RatiosAndRatingResponse {
        /*
        * @Description String with the ratiosStatus
        */
        @AuraEnabled public String ratiosStatus {get;set;}
        /*
        * @Description String with the ratingValidFFSS
        */
        @AuraEnabled public String ratingValidFFSS {get;set;}
        /*
        * @Description String with the ratingValidatedFS
        */
        @AuraEnabled public String ratingValidatedFS {get;set;}
        /*
        * @Description String with the ratiosErrorMsg
        */
        @AuraEnabled public String ratiosErrorMsg {get;set;}
        /*
        * @Description String with the Id of the Financial Statement
        */
        @AuraEnabled public String fsServiceId {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description class used to provide callRatiosEngine method the needed arguments
    * to call the ratios engine
    *--------------------------------------------------------------------------------
    * @author   ARCE TEAM
    * @date     09/03/2020
    **/
    class RatiosServiceParameters {
        /*
        * @Description Federation Id.
        */
        public String federationId { get; set; }
        /*
        * @Description Customer Id.
        */
        public String customerId { get; set; }
        /*
        * @Description Customer number.
        */
        public String customerNumber { get; set; }
        /*
        * @Description Id of the analysis in the service.
        */
        public String analysisIdToSend { get; set; }
        /*
        * @Description Event type.
        */
        public String eventType { get; set; }
        /*
        * @Description Participant type (group or subsidiary).
        */
        public String participantType { get; set; }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description class used to retrieve information generated by the
    * callRatiosEngine method.
    *--------------------------------------------------------------------------------
    * @author   ARCE TEAM
    * @date     09/03/2020
    **/
    public class RatiosResponse {
        /*
        * @Description Status code returned by the service.
        */
        public Integer serviceStatusCode { get; set; }
        /*
        * @Description FFSS that have been persisted successfully.
        */
        public List<arce__Financial_Statements__c> ffssToProcess { get; set; }
        /*
        * @Description HTTP responses from the service.
        */
        public List<String> validHttpRespBody { get; set; }
        /*
        * @Description Processed FFSS that are valid for rating.
        */
        public List<arce__Financial_Statements__c> validFFSS { get; set; }
        /*
        * @Description Error messages from the service.
        */
        public String globalResponseErrorMessage { get; set; }
        /*
        * @Description Indicates whether there is a valid FFSS for rating.
        */
        public Boolean atLeastOneValid { get { return !validFFSS.isEmpty(); } set; }
        /*
        * @Description RatiosResponse
        */
        public RatiosResponse() {
            this.ffssToProcess = new List<arce__Financial_Statements__c>();
            this.validHttpRespBody = new List<String>();
            this.validFFSS = new List<arce__Financial_Statements__c>();
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Performs a test call to the correct financial statements service to check
    * that (1) the service to call is available and (2) the service returns any financial
    * statement. This method is to be called before the RAIP is created so the creation process
    * is prevented if no financial statements can be retrieved.
    *--------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date     25/05/2020
    * @param accountNumber account number of the account to perform the test for.
    * @return arce.Arc_Gen_ServiceAndSaveResponse
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse financialStatementsTestCall(String accountNumber) {
        final arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();

        try {
            final arce.Arc_Gen_Account_Wrapper accountInfo = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> { accountNumber }).get(accountNumber);
            final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accountNumber);

            // Get financial statements service name depending on whether the account is a group or a client.
            final String ffssServiceName = getServiceNameByParticipantType(accountInfo.participantType);

            // Call service
            final arce.Arc_Gen_getIASOResponse.serviceResponse iasoResp = arce.Arc_Gen_getIASOResponse.calloutIASO(ffssServiceName,'{"customerId":"'+customerNumber+'"}');
            response.serviceCode = iasoResp.serviceCode;
            response.serviceMessage = iasoResp.serviceMessage;

            // Check if there is any FFSS in the response.
            final List<Object> listServiceResp = (List<Object>)iasoResp.serviceResponse.get('data');
            if (listServiceResp.isEmpty()) {
                throw new NoFinancialStatementDataException(NoFinancialStatementReason.NO_FFSS_EMPTY_LIST);
            }
        }catch (NoFinancialStatementDataException ex){
            String message = System.Label.Arc_Gen_ErrorService;
            if (ex.reason == NoFinancialStatementReason.NO_FFSS_EMPTY_LIST) {
                message = System.Label.Arc_Gen_NoReturnedFFSS;
            } else if (ex.reason == NoFinancialStatementReason.NO_FFSS_NO_SERVICE) {
                message = System.Label.Lc_arce_RAIP_CannotExecuteGroup;
            }
            response.serviceCode = '404';
            response.serviceMessage = message;
        }catch(Exception ex){
            response.serviceCode = response.serviceCode == null || response.serviceCode == '200' ? '500' : response.serviceCode;
        }

        return response;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contains a list of FFSS and pagination info.
    * -----------------------------------------------------------------------------------------------
    **/
    public class SetupFFSSHeadersWrapper {
        /**
        * @Description: Pagination object.
        */
        public Pagination pagination {get; set;}
        /**
        * @Description: FFSS list.
        */
        public List<arce__Financial_Statements__c> ffssList {get; set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Object representing Pagination node retrieved from FFSS web service.
    * -----------------------------------------------------------------------------------------------
    **/
    public class Pagination {
        /**
        * @Description: Actual page to be returned from service.
        */
        @AuraEnabled public Integer page { get; set; }
        /**
        * @Description: Actual pageSize to be returned from service.
        */
        @AuraEnabled public Integer totalPages { get; set; }
        /**
        * @Description: Total number of elements to be returned from service.
        */
        @AuraEnabled public Integer totalElements { get; set; }
        /**
        * @Description: Total number of pages to be returned from service.
        */
        @AuraEnabled public Integer pageSize { get; set; }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call financialStatement aso service and insert into salesforce.
    * 		This method will only get the new FFSS, old FFSS will not be updated
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param analysisId recordId of the account_has_analysis.
    * @param translatePicklistValues modifies values of picklist fields on returned records
    *   so they contain picklist value labels instead of picklist values.
    * @return SetupFFSSHeadersWrapper
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId, Boolean translatePicklistValues) {
    **/
    public static SetupFFSSHeadersWrapper setupFFSSHeaders(String analysisId, Boolean transPLValues, String ratingToolSelect, Integer requestedPage) {
        return setupFFSSHeaders(analysisId, transPLValues, ratingToolSelect, requestedPage, null);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call financialStatement aso service and insert into salesforce.
    * 		This method will only get the new FFSS, old FFSS will not be updated
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param analysisId recordId of the account_has_analysis.
    * @param translatePicklistValues modifies values of picklist fields on returned records
    *   so they contain picklist value labels instead of picklist values.
    * @return SetupFFSSHeadersWrapper
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId, Boolean translatePicklistValues) {
    **/
    public static SetupFFSSHeadersWrapper setupFFSSHeaders(String analysisId, Boolean transPLValues, String ratingToolSelect, Integer requestedPage, String proposalFolderArceId) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();

        final arce.Arc_Gen_Account_Wrapper accountInfo = locator.getCustomerData(analysisId);
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accountInfo.accNumber);
        // Get financial statements service name depending on whether the account is a group or a client.
        final String ffssServiceName = getServiceNameByParticipantType(accountInfo.participantType);

        // Call Financial Statements service to get FS data.
        String paramsJson;
        Boolean isServPaginated = false;
        if (Arc_Gen_Balance_Tables_data.retrieveFFSSPaginationConfig().arce__Value1__c == TRUE_VALUE && requestedPage != null) {
            paramsJson = '{"customerId":"'+customerNumber+'", "pageSize":"25", "paginationKey":"'+ requestedPage +'"}';
            isServPaginated = true;
        } else {
            paramsJson = '{"customerId":"'+customerNumber+'"}';
        }
        final arce.Arc_Gen_getIASOResponse.ServiceResponse response = arce.Arc_Gen_getIASOResponse.calloutIASO(ffssServiceName, paramsJson);
        if (response.serviceCode != String.valueOf(serviceMessage.CODE_200)) {
            throw new HandledException(String.format('{0} - {1}', new List<String> { response.serviceCode, response.serviceMessage })); // NOSONAR
        }

        SetupFFSSHeadersWrapper toBeReturned = new SetupFFSSHeadersWrapper();
        toBeReturned.ffssList = Arc_Gen_Balance_Tables_helper.processFinancialStatements(analysisId, response, transPLValues, accountInfo, ratingToolSelect, proposalFolderArceId);

        final Set<String> servRespKeys = response.serviceResponse.keySet();
        if (servRespKeys.contains('pagination') && isServPaginated) {
            toBeReturned.pagination = (Pagination) System.JSON.deserialize(JSON.serialize(response.serviceResponse.get('pagination')), Pagination.class);
        }

        return toBeReturned;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description call financialStatement aso service and insert into salesforce.
    * 		This method will only get the new FFSS, old FFSS will not be updated
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param analysisId recordId of the account_has_analysis.
    * @param translatePicklistValues modifies values of picklist fields on returned records
    *   so they contain picklist value labels instead of picklist values.
    * @return SetupFFSSHeadersWrapper
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId, Boolean translatePicklistValues) {
    **/
    public static SetupFFSSHeadersWrapper setupFFSSHeadersRTC(String analysisId, Boolean transPLValues, String ratingToolSelect, Integer requestedPage) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        final Arc_Gen_Balance_Tables_data locatorrtc = new Arc_Gen_Balance_Tables_data();
        final arce.Arc_Gen_Account_Wrapper accountInfo = locatorrtc.getCustomerData(analysisId);
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accountInfo.accNumber);

        // Get rtc financial statements service name depending on whether the account is a group or a client.
        final String groupClient = arce.Arc_gen_Util.getFilialSubsidiaryByAha(new List<String>{(String) analysisId});
        final String ffssServiceName = getServiceNameByParticipantType(groupClient);

        // Call RTC Financial Statements service to get FS data.
        String paramsJsonRTC;
        Boolean isServPaginated = false;
        if (Arc_Gen_Balance_Tables_data.retrieveFFSSPaginationConfig().arce__Value1__c == TRUE_VALUE && requestedPage != null) {
            paramsJsonRTC = '{"customerId":"'+customerNumber+'", "pageSize":"25", "paginationKey":"'+ requestedPage +'"}';
            isServPaginated = true;
        } else {
            paramsJsonRTC = '{"customerId":"'+customerNumber+'"}';
        }
        final arce.Arc_Gen_getIASOResponse.ServiceResponse response = arce.Arc_Gen_getIASOResponse.calloutIASO(ffssServiceName, paramsJsonRTC);
        if (response.serviceCode != String.valueOf(serviceMessage.CODE_200)) {
            throw new HandledException(String.format('{0} - {1}', new List<String> { response.serviceCode, response.serviceMessage })); // NOSONAR
        }

        SetupFFSSHeadersWrapper toBeReturned = new SetupFFSSHeadersWrapper();
        toBeReturned.ffssList = Arc_Gen_Balance_Tables_helper.processFinancialStatementsRTC(analysisId, response, transPLValues, accountInfo, ratingToolSelect);


        System.debug('setupFFSSHeaders ffssList ' + toBeReturned.ffssList.size());

        final Set<String> servRespKeys = response.serviceResponse.keySet();
        if (servRespKeys.contains('pagination') && isServPaginated) {
            toBeReturned.pagination = (Pagination) System.JSON.deserialize(JSON.serialize(response.serviceResponse.get('pagination')), Pagination.class);
        }

        return toBeReturned;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call financialStatement aso service and insert into salesforce.
    * 		This method will only get the new FFSS, old FFSS will not be updated
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param analysisId recordId of the account_has_analysis.
    * @param translatePicklistValues modifies values of picklist fields on returned records
    *   so they contain picklist value labels instead of picklist values.
    * @return List<arce__Financial_Statements__c>
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId, Boolean translatePicklistValues) {
    **/
    public static List<arce__Financial_Statements__c> setupFFSSHeaders(String analysisId, Boolean transPLValues, String ratingToolSelect) {
        return setupFFSSHeaders(analysisId, transPLValues, ratingToolSelect, null).ffssList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call financialStatement aso service and insert into salesforce.
    * 		This method will only get the new FFSS, old FFSS will not be updated
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     08/01/2025
    * @param analysisId recordId of the account_has_analysis.
    * @param translatePicklistValues modifies values of picklist fields on returned records
    * @param proposalFolderArceId recordId of proposal folder
    *   so they contain picklist value labels instead of picklist values.
    * @return List<arce__Financial_Statements__c>
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId, Boolean translatePicklistValues) {
    **/
    public static List<arce__Financial_Statements__c> setupFFSSHeadersProp(String analysisId, Boolean transPLValues, String ratingToolSelect, String proposalFolderArceId) {
        return setupFFSSHeaders(analysisId, transPLValues, ratingToolSelect, null, proposalFolderArceId).ffssList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description This method filters the list of provided FFSS by returning only
    * the ones whose Financial Statement ID matches any from the list of IDs provided as
    * argument.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    04/03/2019
    * @param ffssList list to filter
    * @param ffssServiceIds IDs of the FFSS that need to be filtered.
    * @return List<arce__Financial_Statements__c> the list of FFSS whose service IDs match any of
    **/
    public static List<arce__Financial_Statements__c> filterFFSSByServiceId(List<arce__Financial_Statements__c> ffssList, List<String> ffssServiceIds) {
        final List<arce__Financial_Statements__c> filteredFfssList = new List<arce__Financial_Statements__c>();
        for (arce__Financial_Statements__c ffss : ffssList) {
            if (ffssServiceIds.contains(ffss.arce__financial_statement_id__c)) {
                filteredFfssList.add(ffss);
            }
        }

        return filteredFfssList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call ratiosEngine aso service and insert into salesforce.
    *       Previous ratios will be deleted FROM system
    *       Only the most recent FFSS will be sent (this may change in the future)
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param recordId recordId of the account_has_analysis
    * @param selectedFfssList list of financial statements
    * @param isRAIP boolean if is RAIP
    * @return RatiosAndRatingResponse
    *       if OK serviceCode = 200,
    *           ratiosErrorMsg will cointain error messages formated to be displayed
    *       if not OK serviceCode = 'Error - MessageError' to be displayed to user
    *       Exceptions calling WS will return 'Error calling service'
    * @example public static RatiosAndRatingResponse buildTables(String recordId, List<arce__Financial_Statements__c> selectedFfssList, Boolean isRAIP) {
    **/
    public static RatiosAndRatingResponse buildTables(String recordId, List<arce__Financial_Statements__c> selectedFfssList, Boolean isRAIP, Boolean isFinancialRAIP) {
        return buildTables(recordId, selectedFfssList, isRAIP, isFinancialRAIP, null);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call ratiosEngine aso service and insert into salesforce.
    *       Previous ratios will be deleted FROM system
    *       Only the most recent FFSS will be sent (this may change in the future)
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param recordId recordId of the account_has_analysis
    * @param selectedFfssList list of financial statements
    * @param isRAIP boolean if is RAIP
    * @param propFolArceId proposal folder arce id for proposal
    * @return RatiosAndRatingResponse
    *       if OK serviceCode = 200,
    *           ratiosErrorMsg will cointain error messages formated to be displayed
    *       if not OK serviceCode = 'Error - MessageError' to be displayed to user
    *       Exceptions calling WS will return 'Error calling service'
    * @example public static RatiosAndRatingResponse buildTables(String recordId,
    *              List<arce__Financial_Statements__c> selectedFfssList, Boolean isRAIP, propFolArceId) {
    **/
    public static RatiosAndRatingResponse buildTables(String ahaId, List<arce__Financial_Statements__c> selectedFfssList, Boolean isRAIP, Boolean isFinancialRAIP, String propFolArceId) {

        final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
        final arce__Account_has_Analysis__c aha = dataAccess.getAccountHasAnalysis(ahaId)[0];

        final RatiosResponse response = getRatiosResponse(aha, selectedFfssList, isRAIP);

        return processRatiosResponse(aha, isFinancialRAIP, propFolArceId, response);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Return the ratios service response
    *--------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    02/09/2025
    * @param ahaId ahaId
    * @param selectedFfssList list of FFSS
    * @param isRAIP is RAIP
    * @return RatiosResponse
    **/
    public static RatiosResponse getRatiosResponse(arce__Account_has_Analysis__c aha, List<arce__Financial_Statements__c> selectedFfssList, Boolean isRAIP) {
        final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();

        // Get parameters to be sent to the service.
        final arce.Arc_Gen_User_Wrapper wrapperUser = arce.Arc_Gen_User_Locator.getUserInfo(UserInfo.getUserId());

        final RatiosServiceParameters ratiosParams = new RatiosServiceParameters();
        ratiosParams.federationId = wrapperUser.businessAgentId;
        ratiosParams.customerId = dataAccess.getCustomerData(aha.Id).accNumber;
        ratiosParams.customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(ratiosParams.customerId);

        final String groupClient = arce.Arc_gen_Util.getFilialSubsidiaryByAha(new List<String>{(String) aha.Id});
        if(groupClient == null) {
            ratiosParams.participantType = getParticipantType(aha.arce__group_asset_header_type__c);
        } else {
            ratiosParams.participantType = groupClient;
        }
        ratiosParams.analysisIdToSend = aha.name;
        ratiosParams.eventType = arce.Arc_Gen_GenericUtilities.getEventTypeValue(aha.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);

        // Call ratios engine for each selected financial statement.
        return callRatiosEngine(selectedFfssList, ratiosParams, isRAIP);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Process the ratios response
    *--------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    02/09/2025
    * @param aha aha object
    * @param isFinancialRAIP financial RAIP
    * @param proposalFolderId proposal folder id
    * @param response Ratios service response
    * @return RatiosAndRatingResponse
    **/
    public static RatiosAndRatingResponse processRatiosResponse(arce__Account_has_Analysis__c aha, Boolean isFinancialRAIP, String propFolArceId, RatiosResponse response) {
        return processRatiosResponse(aha, isFinancialRAIP, propFolArceId, response, null);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Process the ratios response
    *--------------------------------------------------------------------------------
    * @author  francisco.munoz.torres.tech@bbva.com
    * @date    02/09/2025
    * @param aha aha object
    * @param isFinancialRAIP financial RAIP
    * @param proposalFolderId proposal folder id
    * @param response Ratios service response
    * @return RatiosAndRatingResponse
    **/
    @SuppressWarnings('sf:NPathComplexity, sf:DUDataflowAnomalyAnalysis')
    public static RatiosAndRatingResponse processRatiosResponse(arce__Account_has_Analysis__c aha, Boolean isFinancialRAIP, String propFolArceId, RatiosResponse response, String ratingType) {
        final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();

        List<SObject> listToClean = new List<SObject>();
        final List<String> filterValues = new List<String>{'02','03','04','07'};
        if(propFolArceId == null) {
            listToClean = dataAccess.getRecordsToClean(aha.Id, filterValues);
        } else {
            listToClean = Arc_Gen_Balance_Tables_data.getRecordsToCleanByProposal(propFolArceId , filterValues);
        }

        // Sync financial statements:
        // - Delete existing FFSS that were not selected
        // - Update existing FFSS that were selected
        // - Insert new FFSS
        Boolean ffssChanged = false;
        if(propFolArceId == null) {
            ffssChanged = dataAccess.persistProcessedFfss(aha.Id, response.ffssToProcess);
        }
        // Logical validation of the valid financial statements to save rating
        final arce__Financial_Statements__c finStateValidObj = response.validFFSS.isEmpty() ? new arce__Financial_Statements__c() : Arc_Gen_Balance_Tables_helper.validationFFSSRating(aha, response.validFFSS);
        // Generates arce__Table_Content_per_Analysis__c records from engine response.
        final Arc_Gen_Balance_Tables_data.SaveResult saveRes = callProcessData(response.ffssToProcess, response.validHttpRespBody, aha.Id, finStateValidObj, propFolArceId);
        final RatiosAndRatingResponse resp = setResults(saveRes, response.atLeastOneValid, response.globalResponseErrorMessage, response.serviceStatusCode);

        // Set "new FFSS" indicator on Account_has_analysis__c record. This indicator
        // means the rating engine has not been called yet with this subset of FFSS.
        if(isFinancialRAIP || propFolArceId != null) {
            resp.fsServiceId = finStateValidObj.arce__financial_statement_id__c;
        } else {
            aha.arce__newFFSS_ind__c = 'YES';
            aha.arce__ffss_for_rating_id__c = null;     // NOSONAR
            dataAccess.updateRecords(new List<sObject>{ aha });

            // Reinitialize Leveraged Test fields.
            Arc_Gen_TestLeverage_service.clearTestLeveragedResults(aha.Id);

            // Choose a valid financial statement to use for rating (if any).
            Arc_Gen_Balance_Tables_helper.saveRatingFfss(aha, response.validFFSS, resp, finStateValidObj);
        }

        // [DMT] We are deleting previosList even if the WS fail (if there were any info, user will lose it until WS problem get solved)
        if (!listToClean.isEmpty()) {
            dataAccess.deletePrevious(listToClean);
        }

        arce__Analysis__c updatedArce = null;

        // If FFSS have changed, force the user to validate the AHAs again.
        if (ffssChanged) {
            updatedArce = new arce__Analysis__c(Id = aha.arce__Analysis__c, arce__Temporal_status__c = false);
        }

        // If rating type is defined and is different from the current one, update it
        if (ratingType != null && aha.arce__Analysis__r.arce__rating_prerating_type__c != ratingType) {
            if (updatedArce == null) {
                updatedArce = new arce__Analysis__c(Id = aha.arce__Analysis__c, arce__Temporal_status__c = false);
            }
            updatedArce.arce__rating_prerating_type__c = ratingType;
        }

        // Update analysis if needed
        if (updatedArce != null) {
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { updatedArce });
        }

        if(propFolArceId == null) {
            dataValueUpdate(aha);
        }

        return resp;
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
    public static void dataValueUpdate(arce__Account_has_Analysis__c aha) {
        final List<Double> ratiosToGet = new List<Double>{RATIO_ID};
        final String idFFSS = aha.arce__ffss_for_rating_id__r.arce__financial_statement_id__c;
        final List<arce__Table_Content_per_Analysis__c> ratiosValues = Arc_Gen_Balance_Tables_data.getRatiosRecords(aha.Id,idFFSS,ratiosToGet);
        if(!ratiosValues.isEmpty() && String.isNotBlank(idFFSS)) {
            Arc_Gen_Balance_Tables_data.updateDataValueOverlay(aha.Id,String.valueOf(ratiosValues.get(0).arce__table_content_value__c));
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Gets value for participant type field.
    *--------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    29/01/2021
    * @param String partiTypeVal Participant type of the account
    * @return 'GROUP' or 'SUBSIDIARY'
    **/
    private static String getParticipantType(String partiTypeVal) {
        return partiTypeVal == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER ? 'GROUP' : 'SUBSIDIARY';
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets the name of the financial statements service to call for a
    * given participant type.
    *--------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    25/05/2020
    * @param String participantType Participant type of the account
    * @return String Name of the service to call.
    **/
    private static String getServiceNameByParticipantType(String participantType) {
        if (participantType == PART_TYPE_GROUP) {
            // Check availability of financial statements service for groups.
            final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('GroupFFSSServicesAvailable');

            if (configs.isEmpty() || configs[0].arce__Value1__c == null || !Boolean.valueOf(configs[0].arce__Value1__c)) {
                throw new NoFinancialStatementDataException(NoFinancialStatementReason.NO_FFSS_NO_SERVICE);
            }
        }
        return participantType == PART_TYPE_GROUP ? FFSS_SRVNAMEGROUP : FFSS_SRVNAMECLI;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls ratiosEngine aso service and returns the result (correctly
    * processed FFSS, HTTP responses and valid FFSS).
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     09/03/2020
    * @param List selectedFfssList List of selected financial statements
    * @param ratiosParams object that contains parameters to provide to FFSS.
    * @return RatiosResponse aggregated response obtained from ratios service calls
    **/
    private static RatiosResponse callRatiosEngine(List<arce__Financial_Statements__c> selectedFfssList, RatiosServiceParameters ratiosParams, Boolean isRAIP) {
        RatiosResponse ratiosResponse = new RatiosResponse();
        Boolean callRatios = true;
        for (arce__Financial_Statements__c financialItem : selectedFfssList) {
            try {
                if (callRatios) {
                    // Call ratios engine.
                    final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
                    final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
                    final String fncialStatementId = financialItem.arce__financial_statement_id__c;
                    final String params =
                        '{"riskAssessmentId":"' + ratiosParams.analysisIdToSend +
                        '","customerId":"' + ratiosParams.customerNumber +
                        '","federationId":"'+ ratiosParams.federationId +
                        '","financialStatementId":"' + fncialStatementId +
                        '","participantType":"' + ratiosParams.participantType +
                        '","evenType":"' + ratiosParams.eventType + '"}';
                    final HttpResponse response = dataAccess.callEngine(params);
                    // Process response.
                    if (response.getStatusCode() == serviceMessage.CODE_200) {
                        // check if response contains error (data->controls)
                        ratiosResponse.globalResponseErrorMessage += processError(response);

                        // Add to correctly processed FFSS. If valid, record it.
                        ratiosResponse.ffssToProcess.add(financialItem);
                        ratiosResponse.validHttpRespBody.add(response.getBody());
                        //ratiosResponse.atLeastOneValid = false;

                        if (financialItem.arce__ffss_valid_type__c == '1' || isRAIP) {
                            ratiosResponse.atLeastOneValid = true;
                            ratiosResponse.validFFSS.add(financialItem);
                        }
                        ratiosResponse.serviceStatusCode = response.getStatusCode();
                    } else {
                        if (financialItem.arce__ffss_valid_type__c == '1') {
                            ratiosResponse.globalResponseErrorMessage += '<br/>' + fncialStatementId + ': ' + System.Label.Arc_Gen_ErrorRatios + ': ' + response.getStatusCode() + ' - ' + response.getBody();
                            ratiosResponse.serviceStatusCode = response.getStatusCode();
                            callRatios = false;
                        } else { // For an not valid eeff not blocked the calling
                            ratiosResponse.serviceStatusCode = serviceMessage.CODE_200;
                        }
                    }
                }
            } catch(Exception e) {
                ratiosResponse.globalResponseErrorMessage += '<br/>' + System.Label.Arc_Gen_ErrorParsingEngine + ': ' + e;
                ratiosResponse.serviceStatusCode = 500;
            }
        }
        return ratiosResponse;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Sets the results of the ratios engine and save records
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     20/09/2019
    * @param Arc_Gen_Balance_Tables_data.SaveResult saveRes - Result of the database insert
    * @param Arc_Gen_Balance_Tables_data.SaveResult saveRes
    * @param String atLeastOneValid - Indicate if there is at least one valid FFSS for rating
    * @param String gblRespErrorMsg - Error string
    * @return RatiosAndRatingResponse - Wrapper
    * @example public static RatiosAndRatingResponse setResults(Arc_Gen_Balance_Tables_data.SaveResult
    *  saveRes, Boolean atLeastOneValid, String gblRespErrorMsg)
    **/
    private static RatiosAndRatingResponse setResults(Arc_Gen_Balance_Tables_data.SaveResult saveRes, Boolean atLeastOneValid, String gblRespErrorMsg, Integer ratiosStatusCode) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        final RatiosAndRatingResponse resp = new RatiosAndRatingResponse();
        resp.ratiosStatus = saveRes.status == 'true' && ratiosStatusCode == serviceMessage.CODE_200 ? System.Label.Cls_arce_Success200 : System.Label.Cls_arce_GRP_glbError;
        resp.ratingValidFFSS = atLeastOneValid == true ? 'yes' : 'no';
        resp.ratiosErrorMsg = saveRes.status == 'true' ? gblRespErrorMsg : saveRes.message;
        return resp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call function to process data
    *--------------------------------------------------------------------------------
    * @author ARCE TEAM
    * @date   11/04/2019
    * @param  List<arce__Financial_Statements__c> ffssToProcess
    * @param  List<HttpResponse> validHttpResp
    * @param  String recordId
    * @param  FinancialStatement valid ffss chosen
    * @return Arc_Gen_Balance_Tables_data.SaveResult
    * @example public static void callProcessData(ffssToProcess, validHttpResp, recordId) {
    **/
    @SuppressWarnings('sf:DUDataflowAnomalyAnalysis')
    public static Arc_Gen_Balance_Tables_data.SaveResult callProcessData(List<arce__Financial_Statements__c> ffssToProcess, List<String> validHttpRespBody, String recordId, arce__Financial_Statements__c validFs, String propFoldArceId) {
        final List<Map<String,String>> eeffData2Update = new List<Map<String,String>>();
        final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
        Arc_Gen_Balance_Tables_data.SaveResult saveRes = new Arc_Gen_Balance_Tables_data.SaveResult();
        final List<sObject> listToInsert = new List<sObject>();

        final List<arce__Financial_Statements__c> finStaPrevYearLts = Arc_Gen_Balance_Tables_helper.checkEeffPreviousValid(ffssToProcess, validFs);
        final Map<String,arce__Financial_Statements__c> ffssImportantMap = new Map<String,arce__Financial_Statements__c>();
        ffssImportantMap.put('valFS', validFs);
        ffssImportantMap.put('prevFS', finStaPrevYearLts.isEmpty() ? new arce__Financial_Statements__c() : finStaPrevYearLts[0]);

        final List<arce__Data_Collections__c> dataCollectList = dataAccess.getRecordsToInsert(new List<String>{'07','02','03','04'});
        final arce__Arce_Config__mdt orderTableField = Arc_Gen_Balance_Tables_data.orderTableField();
        for (Integer i=0; i<ffssToProcess.size(); i++) {
            final arce__Financial_Statements__c financialItem = ffssToProcess[i];
            final String responseBody = validHttpRespBody[i];
            try {
                final Map<String, arce__Table_Content_per_Analysis__c> completeResptMap = new Map<String, arce__Table_Content_per_Analysis__c>();
                eeffData2Update.add(processData(responseBody,completeResptMap));
                if (financialItem.arce__financial_statement_id__c != Arc_Gen_ArceCore_Constants.DUMMY_FFSS) {
                    listToInsert.addAll(listToInsertMethod(ffssImportantMap, financialItem, recordId, completeResptMap, propFoldArceId, dataCollectList, orderTableField));
                }
            } catch(Exception e) {
                saveRes.status = System.Label.Cls_arce_GRP_glbError;
                saveRes.message = e.getMessage();
                break;
            }
        }
        updateEEFFtoShow(eeffData2Update,recordId);
        dataAccess.updateRecords(finStaPrevYearLts);
        saveRes = dataAccess.insertRecords(listToInsert);
        return saveRes;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Update the all the eeff
    *-------------------------------------------------------------------------------
    * @author  mariohumberto.ramirez.contractor@bbva.com
    * @date     23/10/2019
    * @param eeffData2Update List of map with the data to update
    * @param recordId - id of the account has analysis object
    * @return void
    * @example updateEEFFtoShow(eeffData2Update)
    *-------------------------------------------------------------------------------
    **/
    public static void updateEEFFtoShow(List<Map<String,String>> eeffData2Update, String recordId) {
        final List<String> eeffIdsLts = new List<String>();
        final List<String> unitLts = new List<String>();
        final List<String> currencyEeff = new List<String>();
        for (Map<String,String> eeffData: eeffData2Update) {
            eeffIdsLts.add(eeffData.get('Id'));
            currencyEeff.add(eeffData.get(CURRENCY_LIT));
            switch on eeffData.get(UNIT_LIT) {
                when 'UNITS' {
                    unitLts.add('1');
                }
                when 'THOUSANDS' {
                    unitLts.add('2');
                }
                when 'MILLIONS' {
                    unitLts.add('3');
                }
                when 'BILLION' {
                    unitLts.add('4');
                }
            }
        }
        final List<arce__Financial_Statements__c> financialSLts = Arc_Gen_Balance_Tables_data.getFinancialState2Show(eeffIdsLts,recordId);
        for (arce__Financial_Statements__c finaStat: financialSLts) {
            for (integer i = 0; i < eeffIdsLts.size(); i++) {
                if (finaStat.arce__financial_statement_id__c == eeffIdsLts[i]) {
                    finaStat.arce__magnitude_unit_type__c = unitLts[i];
                    finaStat.CurrencyIsoCode = currencyEeff[i];
                }
            }
        }
        Arc_Gen_Balance_Tables_data.updateRecordLts(financialSLts);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description retrieve error FROM Ratios WS response
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param HttpResponse retrieved FROM Ratios WS
    * @return String
    *       Blank string if no error
    *       Parsed error string if some error
    * @example public static String processError(HttpResponse response) {
    **/
    public static String processError(HttpResponse response) {
        final Map<String, Object> mapResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        final Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(mapResponse.get('data')));
        final List<Object> controls = ( List<Object>)data.get('controls');
        String respErrorMsg = '';
        for(Object controlDataL : controls) {
            final Map<String, Object> controlData = (Map<String, Object>)controlDataL;
            final Boolean isValid = (Boolean)controlData.get('isValid');
            if (!isValid) {
                if (respErrorMsg == '' ) {
                    respErrorMsg += (String)controlData.get('description');
                } else {
                    respErrorMsg +='<br/>' + (String)controlData.get('description');
                }
            }
        }
        return respErrorMsg;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description process WS response to format data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param HttpResponse retrieved FROM Ratios WS
    * @param Map<String, arce__Table_Content_per_Analysis__c> fullRespMap
    * @return Map<String,String>
    * @example public static void processData(HttpResponse response, Map<String, arce__Table_Content_per_Analysis__c> fullRespMap) {
    **/
    public static Map<String,String> processData(String responseBody, Map<String, arce__Table_Content_per_Analysis__c> fullRespMap) {
        final Map<String,String> eeffData = new Map<String,String>();
        final Map<String, Object> mapResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        final Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(mapResponse.get('data')));
        final Map<String, Object> calculations = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(data.get('calculations')));
        final Map<String, Object> balanceFs = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(data.get('financialStatement')));
        List<Object> specificMag;

        //List<String> ratioMetricsSpecialKeys = new List<String>{'netPayback', 'averageCollectionPeriod', 'stockTurnover', 'averagePayingPeriod'}; // this keys of ratioMetrics have 'number' instead of 'ammount / ammount'
        //List<String> globalSynthesisOnlyPercentKeys = new List<String>{'variationOnSales'};
        final String parentId = (String)balanceFs.get('id');
        eeffData.put('Id',parentId);
        eeffData.put(CURRENCY_LIT,(String)balanceFs.get(CURRENCY_LIT));
        eeffData.put(UNIT_LIT,(String)balanceFs.get(UNIT_LIT));
        if(calculations.containsKey('specificRatiosMagnitudes')) {
            specificMag = (List<Object>)JSON.deserializeUntyped(JSON.serialize(calculations.get('specificRatiosMagnitudes')));
            for(Object element: specificMag) {
                final Map<String,Object> data1 = (Map<String,Object>) element;
                final arce__Table_Content_per_Analysis__c recordToInsert = processRatioDataValues(data1, parentId);
                fullRespMap.put(String.valueOf(data1.get('id')), recordToInsert);
            }
        }
        final Map<String, Object> globalSynthesis = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(calculations.get('globalSynthesis')));
        final Map<String, Object> cashFlow = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(calculations.get('cashFlow')));
        final Map<String, Object> ratiosMetrics = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(calculations.get('ratiosMetrics')));
        for(Object element: globalSynthesis.keyset()) {
            final arce__Table_Content_per_Analysis__c recordToInsert = processRatioDataValues(element, globalSynthesis, 'globalSynthesis', parentId);
            fullRespMap.put(String.valueOf(element), recordToInsert);
        }
        for(Object element: cashFlow.keyset()) {
            final arce__Table_Content_per_Analysis__c recordToInsert = processRatioDataValues(element, cashFlow, 'cashFlow', parentId);
            fullRespMap.put(String.valueOf(element), recordToInsert);
        }
        for(Object element: ratiosMetrics.keyset()) {
            final arce__Table_Content_per_Analysis__c recordToInsert = processRatioDataValues(element, ratiosMetrics, 'ratiosMetrics', parentId);
            fullRespMap.put(String.valueOf(element), recordToInsert);
        }
        return eeffData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description process WS Data for each section
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Object "Element" to be proccessed
    * @param Map<String,Object> of the section
    * @param String "dataType" ratiosMetrics / cashFlow / globalSynthesis
    * @return record arce__Table_Content_per_Analysis__c with data
    * @example private static arce__Table_Content_per_Analysis__c processRatioDataValues(Object element,
    * Map<String, Object> dataMap, string dataType, String parentId) {
    **/
    private static arce__Table_Content_per_Analysis__c processRatioDataValues(Object element, Map<String, Object> dataMap, string dataType, String parentId) {
        final arce__Table_Content_per_Analysis__c recordToInsert = new arce__Table_Content_per_Analysis__c();
        try {
            switch on dataType {
                when 'ratiosMetrics' {
                    final List<String> ratioMetDrctKeys = new List<String>{'financialDebtOverEquity', 'interestCoverageWithEbitda', 'grossFinancialDebtOverEbitda', 'netFinancialDebtOverEbitda', 'returnOnAssets'}; // this keys are mapped directly to decimal
                    if(ratioMetDrctKeys.contains(String.valueOf(element))) {
                        // element contains decimal value
                        recordToInsert.arce__table_content_value__c = Decimal.valueOf(String.valueOf(dataMap.get(String.valueOf(element))));
                    } else {
                        final Map<String, Object> elemntMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataMap.get(String.valueOf(element))));
                        final List<String> ratioMetSpecKeys = new List<String>{'netPayback', 'averageCollectionPeriod', 'stockTurnover', 'averagePayingPeriod'}; // this keys of ratioMetrics have 'number' instead of 'ammount / ammount'
                        if(ratioMetSpecKeys.contains(String.valueOf(element))) {
                            // element / number
                            recordToInsert.arce__table_content_value__c = Decimal.valueOf(String.valueOf(elemntMap.get('number')));
                        } else {
                            // element / ammount / ammount
                            final Map<String, Object> amountMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(elemntMap.get(AMOUNT_LIT)));
                            recordToInsert.arce__table_content_value__c = getAmount(amountMap);
                            recordToInsert.CurrencyIsoCode = getCurrency(amountMap);
                        }
                    }
                }
                when 'cashFlow' {
                    final Map<String, Object> elemntMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataMap.get(String.valueOf(element))));//NOSONAR
                    final Map<String, Object> amountMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(elemntMap.get(AMOUNT_LIT)));
                    recordToInsert.arce__table_content_value__c = getAmount(amountMap);
                    recordToInsert.CurrencyIsoCode = getCurrency(amountMap);
                }
                when 'globalSynthesis' {
                    final Map<String, Object> elemntMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(dataMap.get(String.valueOf(element))));//NOSONAR
                    recordToInsert.arce__table_content_percentage__c = Arc_Gen_Balance_Tables_helper.getPercentFromMap(elemntMap);
                    final List<String> gblSynOnlyPrcntK = new List<String>{'variationOnSales'};
                    if(! gblSynOnlyPrcntK.contains(String.valueOf(element))) {
                        // if element is in list means that only contains percentage, so we cant map ammount
                        final Map<String, Object> amountMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(elemntMap.get(AMOUNT_LIT)));
                        recordToInsert.arce__table_content_value__c = getAmount(amountMap);
                        recordToInsert.CurrencyIsoCode = getCurrency(amountMap);
                    }
                }
            }
            recordToInsert.arce__table_content_parent_code_id__c = parentId;
        } catch(Exception e) {
            /*This error should not be presented to the user, but it is important to determinate if the errors came FROM WS */
            System.debug('Excpetion while parsing json response (' + dataType + ' element: ' + String.valueOf(element) + ' ) Exception: ' + e );
        }
        return recordToInsert;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description process WS Data for each section
    *--------------------------------------------------------------------------------
    * @Author  ARCE TEAM
    * @Date     03/03/2021
    * @param Map<String,Object> element - Data for Balante Table Helper.
    * @param String parentId - Parent Id of currect client.
    * @return record arce__Table_Content_per_Analysis__c with data
    * @example private static arce__Table_Content_per_Analysis__c processRatioDataValues(Map<String, Object> dataMap, String parentId) {
    * -------------------------------------------------------------------------------
    **/
    private static arce__Table_Content_per_Analysis__c processRatioDataValues(Map<String, Object> element, String parentId) {
        final arce__Table_Content_per_Analysis__c recordToInsert = new arce__Table_Content_per_Analysis__c();
        try {
            recordToInsert.arce__table_content_percentage__c = Arc_Gen_Balance_Tables_helper.getPercentFromMap(element);
            if(element.containsKey('totalAmount')) {
                final Map<String, Object> amountMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(element.get('totalAmount')));
                final Decimal finalAmount = getAmount(amountMap);
                recordToInsert.arce__table_content_value__c = finalAmount;
                recordToInsert.CurrencyIsoCode = getCurrency(amountMap);
                recordToInsert.arce__Unit_Type__c = getUnit(amountMap);
                recordToInsert.arce__base_amount__c = finalAmount;
                recordToInsert.arce__original_amount__c = finalAmount;
                recordToInsert.arce__original_currency__c = getCurrency(amountMap);
            }
            recordToInsert.arce__table_content_parent_code_id__c = parentId;
        } catch(Exception e) {
            /*This error should not be presented to the user, but it is important to determinate if the errors came FROM WS */
            System.debug('Excpetion while parsing json response (specificRatiosMagnitudes element: ' + String.valueOf(element.get('description')) + ' ) Exception: ' + e );
        }
        return recordToInsert;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description get currency FROM map
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Map<String, Object> amountMap map of ammounts
    * @return String currency for map
    * @example private static String getCurrency(Map<String, Object> amountMap) {
    **/
    private static String getCurrency(Map<String, Object> amountMap) {
        return String.valueOf(String.valueOf(amountMap.get(CURRENCY_LIT)));
    }

    /**
    *-------------------------------------------------------------------------------
    * @description get currency FROM map
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Map<String, Object> amountMap map of ammounts
    * @return String currency for map
    * @example private static String getCurrency(Map<String, Object> amountMap) {
    **/
    private static String getUnit(Map<String, Object> amountMap) {
        return String.valueOf(String.valueOf(amountMap.get('unit')));
    }

    /**
    *-------------------------------------------------------------------------------
    * @description get amount FROM map
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Map<String, Object> amountMap to reviw
    * @return String amount to validate
    * @example private static Decimal getAmount(Map<String, Object> amountMap) {
    **/
    private static Decimal getAmount(Map<String, Object> amountMap) {
        Decimal amount;
        if (String.valueOf(amountMap.get(UNIT_LIT)) == FFSS_SERVPERC) {
            amount = (100 * Decimal.valueOf(String.valueOf(amountMap.get(AMOUNT_LIT)))).setScale(0);
        } else {
            amount = Decimal.valueOf(String.valueOf(amountMap.get(AMOUNT_LIT)));
        }
        return amount;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description insert WS response into Salesforce
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Arc_Gen_Balance_Tables_data dataAccess
    * @param arce__Financial_Statements__c ffss financial statement
    * @param String recordId  id of analysis
    * @param Map<String, arce__Table_Content_per_Analysis__c> cmpltRespMap (records to be inserted)
    * @return void (insert data)
    * @example public static void listToInsertMethod(Arc_Gen_Balance_Tables_data dataAccess, Date year, String recordId, Map<String, arce__Table_Content_per_Analysis__c> completeResponsetMap ) {
    **/
    public static List<sObject> listToInsertMethod(Map<String,arce__Financial_Statements__c> ffssImportantMap, arce__Financial_Statements__c ffss, String recordId, Map<String, arce__Table_Content_per_Analysis__c> cmpltRespMap, String propFolArceId, List<arce__Data_Collections__c> dataCollectList, arce__Arce_Config__mdt orderTableField) {
        final List<arce__Table_Content_per_Analysis__c> listToInsert = new List<arce__Table_Content_per_Analysis__c>();

        // Label maps.
        final Map<String, Map<String, String>> mapLabels = new Map<String, Map<String, String>> {
            'adjustedTypeMap' => arce.Arc_Gen_GenericUtilities.getMapLabelFromValue('arce__Financial_Statements__c', 'arce__ffss_adjusted_type__c'),
            'certTypeMap' => arce.Arc_Gen_GenericUtilities.getMapLabelFromValue('arce__Financial_Statements__c', 'arce__ffss_certification_type__c'),
            'submTypeMap' => arce.Arc_Gen_GenericUtilities.getMapLabelFromValue('arce__Financial_Statements__c', 'arce__ffss_submitted_type__c')
        };
        final Map<String, String> mapRecordTypeIds = getRecordTypeIdByDataCollection(dataCollectList);
        for(arce__Data_Collections__c dataCollectElemnt : dataCollectList) {
            // If element is not found in ratios response, skip it.
            if (!cmpltRespMap.containsKey(dataCollectElemnt.arce__collection_code_term__c)) {
                continue;
            }
            final arce__Table_Content_per_Analysis__c codeTerm = cmpltRespMap.get(dataCollectElemnt.arce__collection_code_term__c);
            final arce__Table_Content_per_Analysis__c recordToInsert = new arce__Table_Content_per_Analysis__c();
            try {
                recordToInsert.CurrencyIsoCode = codeTerm.CurrencyIsoCode;
                recordToInsert.arce__table_content_value__c = codeTerm.arce__table_content_value__c;
                recordToInsert.arce__table_content_percentage__c = codeTerm.arce__table_content_percentage__c;
                recordToInsert.arce__table_content_parent_code_id__c = codeTerm.arce__table_content_parent_code_id__c;
                recordToInsert.RecordTypeId = mapRecordTypeIds.get(dataCollectElemnt.arce__collection_table__c);
                recordToInsert.arce__collection_table__c = dataCollectElemnt.arce__collection_table__c;
                recordToInsert.arce__table_content_year__c = getTableHeaderByFinancialStatement(ffss, mapLabels);

                if(propFolArceId == null) {
                    recordToInsert.arce__account_has_analysis_id__c = recordId;
                } else {
                    recordToInsert.arce__SP2_Proposal_Folder__c = propFolArceId;
                }

                recordToInsert.arce__Data_Collection_Id__c = dataCollectElemnt.id;
                recordToInsert.put(orderTableField.arce__Value1__c, String.valueof(dataCollectElemnt.arce__collection_order_number__c)); // PARCE
                recordToInsert.arce__valid_fin_statement__c = false;
                if (ffssImportantMap.get('valFS').Id == ffss.Id) {
                    recordToInsert.arce__valid_fin_statement__c = true;
                }
                recordToInsert.arce__previous_valid__c = false;
                if (ffssImportantMap.get('prevFS').Id == ffss.Id) {
                    recordToInsert.arce__previous_valid__c = true;
                }
                recordToInsert.arce__table_dynamic_header_field__c = ffss.arce__economic_month_info_number__c + 'M ' +ffss.arce__economic_period_type_id__c;
                recordToInsert.arce__Unit_Type__c = codeTerm.arce__Unit_Type__c;
                recordToInsert.arce__base_amount__c = codeTerm.arce__base_amount__c;
                recordToInsert.arce__original_amount__c = codeTerm.arce__original_amount__c;
                recordToInsert.arce__original_currency__c = codeTerm.arce__original_currency__c;
                recordToInsert.arce__collection_order_type__c = '2300';
            } catch(Exception e) {
                // This error should not be presented to the user, but it is important to determinate if the errors came FROM WS
                system.debug('Exception: ' + e.getMessage() + ' | Stack trace: ' + e.getStackTraceString());
            }
            listToInsert.add(recordToInsert);
        }
        return listToInsert;
    }

    /**
    *----------------------------------------------------------------------------------
    * @description Get record type id for "arce__Table_Content_per_Analysis__c" record.
    *----------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     19/04/2022
    * @param arce__Data_Collections__c dataCollElm
    * @return String rtId
    * @example String rtId = getRecordTypeIdByDataCollection(dataCollectElemnt);
    **/
    public static String getRecordTypeIdByDataCollection(arce__Data_Collections__c dataCollElm) {
        // Build record type table.
        final Schema.DescribeFieldResult fieldResult = arce__Table_Content_per_Analysis__c.arce__collection_table__c.getDescribe();
        final List<Schema.PicklistEntry> picklisValue = fieldResult.getPicklistValues();
        final Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.arce__Table_Content_per_Analysis__c.getRecordTypeInfosByName();
        final Map<String, String> rtIdsByLabel = buildRecordTypeIdsByLabel(recordTypeInfos, picklisValue);

        return rtIdsByLabel.get(dataCollElm.arce__collection_table__c);
    }

    /**
    *----------------------------------------------------------------------------------
    * @description Get map record Type labels
    *----------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     19/04/2022
    * @param List<arce__Data_Collections__c> dataCollElm
    * @return Map<String,String> rtIdMap
    * @example String rtId = getRecordTypeIdByDataCollection(dataCollectElemnt);
    **/
    public static Map<String, String> getRecordTypeIdByDataCollection(List<arce__Data_Collections__c> dataCollElm) {
        // Build record type table.
        final Schema.DescribeFieldResult fieldResult = arce__Table_Content_per_Analysis__c.arce__collection_table__c.getDescribe();
        final List<Schema.PicklistEntry> picklisValue = fieldResult.getPicklistValues();
        final Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.arce__Table_Content_per_Analysis__c.getRecordTypeInfosByName();

        return buildRecordTypeIdsByLabel(recordTypeInfos, picklisValue);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @description Get header for "arce__table_content_year__c" field of "arce__Table_Content_per_Analysis__c" record.
    *---------------------------------------------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     19/04/2022
    * @param arce__Financial_Statements__c ffss
    * @param Map<String, Map<String, String>> mapLabels
    * @return String tableHeader
    * @example String header = getTableHeaderByFinancialStatement(ffss, mapLabels);
    **/
    public static String getTableHeaderByFinancialStatement(arce__Financial_Statements__c ffss, Map<String, Map<String, String>> mapLabels) {
        final List<arce__Arce_Config__mdt> sortableConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_SortableEEFF');

        // Get table header maximum text size for truncation.
        final Schema.DescribeFieldResult describe = arce__Table_Content_per_Analysis__c.arce__table_content_year__c.getDescribe();
        final Integer headerMaxLength = describe.getLength();

        // Labels.
        final Map<String, String> adjustedTypeMap = mapLabels.get('adjustedTypeMap');
        final Map<String, String> certTypeMap = mapLabels.get('certTypeMap');
        final Map<String, String> submTypeMap = mapLabels.get('submTypeMap');
        final String adjustedLabel = adjustedTypeMap.get(ffss.arce__ffss_adjusted_type__c);
        final String certLabel = certTypeMap.get(ffss.arce__ffss_certification_type__c);
        final String submLabel = submTypeMap.get(ffss.arce__ffss_submitted_type__c);
        Boolean sortable = false;
        if (!sortableConfig.isEmpty()) {
            sortable = Boolean.valueOf(sortableConfig[0].arce__Value1__c);
        }
        final String order = sortable ? ffss.arce__Order__c + 'º ' : '';

        String tableHeader = order + Datetime.newInstance(ffss.arce__financial_statement_end_date__c, Time.newInstance(0,0,0,0)).format('yyyy-MM-dd') + ' ' + certLabel + ' ' + submLabel + ' ' + adjustedLabel + ' (' + ffss.arce__financial_statement_id__c.replaceFirst('^0+(?!$)', '') + ')';
        tableHeader = tableHeader.abbreviate(headerMaxLength);

        return tableHeader;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Return the list of financial statements with the translated labels.
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    26/06/2020
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  List<arce__Financial_Statements__c> list of financial statements with the labels translated
    * @example List<arce__Financial_Statements__c> list = Arc_Gen_Balance_Tables_service.translatePicklistValues(ffssList);
    **/
    public static List<arce__Financial_Statements__c> translatePicklistValues(List<arce__Financial_Statements__c> ffssList) {
        final List<arce__Financial_Statements__c> ffssListRet = ffssList.deepClone();
        Arc_Gen_Balance_Tables_helper.translatePicklistValues(ffssListRet);
        return ffssListRet;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Builds a map of record type IDs for data collections.
    *--------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    05/01/2021
    * @param   recordTypeInfos - Record type metadata
    * @param   picklisValue - Picklist value metadata
    * @return  the map matching labels (from picklist) to record type IDs.
    **/
    private static Map<String, String> buildRecordTypeIdsByLabel(Map<String, Schema.RecordTypeInfo> recordTypeInfos, List<Schema.PicklistEntry> picklisValue) {
        final Map<String, String> rtIdsByLabel = new Map<String, String>();
        for( Schema.PicklistEntry element : picklisValue) {
            rtIdsByLabel.put(element.getValue(), recordTypeInfos.get(element.getLabel()).getRecordTypeId());
        }
        return rtIdsByLabel;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Build success RatiosAndRatingResponse wrapper
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    09/12/2021
    * @param   ffssId - String
    * @return  wrapper RatiosAndRatingResponse
    **/
    public static RatiosAndRatingResponse createRatiosAndRespWrapper(String ffssId) {
        final Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse resp = new Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse();
        resp.ratiosStatus = System.Label.Cls_arce_Success200;
        resp.ratingValidFFSS = 'yes';
        resp.ratiosErrorMsg = System.Label.Cls_arce_Success200;
        resp.fsServiceId = ffssId;
        return resp;
    }

}