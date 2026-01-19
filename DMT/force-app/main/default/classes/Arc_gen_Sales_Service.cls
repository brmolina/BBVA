/**
* @File Name          : Arc_gen_Sales_Service.cls
* @Description        : Class to the callouts of sales
* @Author             : isabel.ascaso.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 05-26-2025
* @Changes
*========================================================================================
* Ver         Date   Author                                           Modification
*========================================================================================
* 1.0    26/03/2024  isabel.ascaso.tech@bbva.com     Initial Version
**/
public with sharing class Arc_gen_Sales_Service {
    /**
    * @description Constant storing the custom metadata service salesEnginename
    */
    private static final String SERV_NAME_ENSALES = 'servEngineSales';
    /**
    * @description Constant storing the literal 700
    */
    private static final String SEVENHUNDRED = '700';
    /**
    * @description Constant storing LARGE_ENTERPRISES for risksegment
    */
    private static final String LARGE_ENTERPRISES = 'LARGE_ENTERPRISES';
    /**
    * @description Regex to match the start of the line and the key surrounded by quotes and ending with a colon
    */
    private static final String REGEX_FORMAT = '(?m)^\\s*"{0}"\\s*:';
    /**
    * @description Replacement format of the new key surrounded by quotes and ending with a colon
    */
    private static final String REPLACEMENT_F = '"{0}" :';
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		26/03/2024
    * @author	isabel.ascaso.tech@bbva.com
    */
    private Arc_gen_Sales_Service() {

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that retrieves all the information from the database and generates the
    * json that is sent to the IASO service
    * -----------------------------------------------------------------------------------------------
    * @param List<arce__Account_has_Analysis__c> ahaObjList - List of selected account has analysis objects
    * @return String - Complete json with all service parameters required to do the request
    * @example String json = setServiceParameters(ahaObjList, toolkitObjList)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String,String> setParametersSales(arce__Account_has_Analysis__c ahaObj) {
        final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(ahaObj);
        final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{ clientId }).get(clientId);
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapper.accNumber);

        return new Map<String,String>{ 'participantId' => customerNumber};
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that retrieves all the information from the database and generates the
    * json that is sent to the IASO service
    * -----------------------------------------------------------------------------------------------
    * @param List<arce__Account_has_Analysis__c> ahaObjList - List of selected account has analysis objects
    * @return String - Complete json with all service parameters required to do the request
    * @example String json = setServiceParameters(ahaObjList, toolkitObjList)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_gen_Sales_Wrappers.DataWrapper setVariables(arce__Account_has_Analysis__c ahaObj, String raipType) {
        final arce.Arc_gen_Sales_Wrappers.DataWrapper dataRequest = new arce.Arc_gen_Sales_Wrappers.DataWrapper();
        final arce__Financial_Statements__c ffss = getFfssInformation(ahaObj.arce__ffss_for_rating_id__r.arce__financial_statement_id__c);
        final arce.Arc_Gen_AccHasAnalysis_Data ahaLocator = new arce.Arc_Gen_AccHasAnalysis_Data();
        final arce__Table_Content_per_Analysis__c tableContent = ahaLocator.getTableContentByCodeTerm(ahaObj.Id,new Set<String>{SEVENHUNDRED})[0];
        final Map<Id,arce.Arc_Gen_Account_Wrapper> prevSubsWrpMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{ahaObj.arce__Customer__c});

        dataRequest.currencyX = ffss.CurrencyIsoCode;
        dataRequest.country = prevSubsWrpMap.get(ahaObj.arce__Customer__c).country;
        dataRequest.riskSegment = LARGE_ENTERPRISES;

        final arce.Arc_gen_Sales_Wrappers.ModelWrapper model = new arce.Arc_gen_Sales_Wrappers.ModelWrapper();
        model.idLong = ahaObj.arce__RAR_rating_tool_id__c;
        dataRequest.model = model;

        final arce.Arc_gen_Sales_Wrappers.RelationParentSubsidiaryWrapper relationParent = new arce.Arc_gen_Sales_Wrappers.RelationParentSubsidiaryWrapper();
        relationParent.idLong = '1';
        relationParent.description = 'Core';
        dataRequest.parentSubsidiary = relationParent;

        dataRequest.exchangeRate = setExchange(ffss);
        if(tableContent != null) {
            dataRequest.unit = tableContent.arce__Unit_Type__c;
        }

        final arce.Arc_gen_Sales_Wrappers.RatingTypeWrapper rating = new arce.Arc_gen_Sales_Wrappers.RatingTypeWrapper();
        rating.idLong = raipType.toUpperCase();
        dataRequest.ratingType = rating;

        final arce.Arc_gen_Sales_Wrappers.EntityTypeWrapper entityType = new arce.Arc_gen_Sales_Wrappers.EntityTypeWrapper();
        entityType.idLong = prevSubsWrpMap.get(ahaObj.arce__Customer__c).isProspect ? 'PROSPECT' : 'ENTITY';
        dataRequest.entityType = entityType;

        final arce.Arc_gen_Sales_Wrappers.BranchWrapper branch = new arce.Arc_gen_Sales_Wrappers.BranchWrapper();
        branch.idLong = '';

        final arce.Arc_gen_Sales_Wrappers.BankWrapper bank = new arce.Arc_gen_Sales_Wrappers.BankWrapper();

        bank.idLong = prevSubsWrpMap.get(ahaObj.arce__Customer__c).bankId;
        bank.country = prevSubsWrpMap.get(ahaObj.arce__Customer__c).country;
        bank.branch = branch;
        dataRequest.bank = bank;

        dataRequest.sales = setSale(ahaObj, tableContent, ffss);

        System.debug('setVariables dataRequest ' + dataRequest);
        return dataRequest;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that retrieves the exchange data
    * json that is sent to the IASO service
    * -----------------------------------------------------------------------------------------------
    * @param arce__Financial_Statements__c ffss - fss record
    * @return arce.Arc_gen_Sales_Wrappers.ExchangeTypeWrapper - the wrapper with de exchangeData
    * @example arce.Arc_gen_Sales_Wrappers.ExchangeTypeWrapper json = setVariables(ffss)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_gen_Sales_Wrappers.ExchangeWrapper setExchange(arce__Financial_Statements__c ffss) {
        final arce.Arc_gen_Sales_Wrappers.BaseWrapper base = new arce.Arc_gen_Sales_Wrappers.BaseWrapper();
        base.currencyX = ffss.CurrencyIsoCode;

        final arce.Arc_gen_Sales_Wrappers.ExchangeTypeWrapper exChangeType = new arce.Arc_gen_Sales_Wrappers.ExchangeTypeWrapper();
        exChangeType.value = 1;

        final arce.Arc_gen_Sales_Wrappers.RatioWrapper ratio = new arce.Arc_gen_Sales_Wrappers.RatioWrapper();
        ratio.exchangeType = exChangeType;

        final arce.Arc_gen_Sales_Wrappers.TargetWrapper target = new arce.Arc_gen_Sales_Wrappers.TargetWrapper();
        target.currencyX = ffss.CurrencyIsoCode;
        target.ratio = ratio;

        final List<arce.Arc_gen_Sales_Wrappers.TargetWrapper> targetList = new List<arce.Arc_gen_Sales_Wrappers.TargetWrapper>();
        targetList.add(target);

        final arce.Arc_gen_Sales_Wrappers.ExchangeWrapper exChange = new arce.Arc_gen_Sales_Wrappers.ExchangeWrapper();
        exChange.targets = targetList;
        exChange.base = base;

        final DateTime endDate = DateTime.newInstance(ffss.arce__financial_statement_end_date__c.year(), ffss.arce__financial_statement_end_date__c.month(), ffss.arce__financial_statement_end_date__c.day());
        String endDateString = String.valueOf(endDate);
        endDateString = endDateString.replace(' ', 'T');

        exChange.dateX = endDateString;
        return exChange;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that retrieves all the information from the database and generates the
    * json that is sent to the IASO service
    * -----------------------------------------------------------------------------------------------
    * @param List<arce__Account_has_Analysis__c> ahaObjList - List of selected account has analysis objects
    * @return String - Complete json with all service parameters required to do the request
    * @example String json = setServiceParameters(ahaObjList, toolkitObjList)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce.Arc_gen_Sales_Wrappers.SalesWrapper> setSale(arce__Account_has_Analysis__c ahaObj, arce__Table_Content_per_Analysis__c tableContent, arce__Financial_Statements__c ffss) {
        final arce.Arc_gen_Sales_Wrappers.FinancialStatementTypeWrapper financialType = new arce.Arc_gen_Sales_Wrappers.FinancialStatementTypeWrapper();
        final String ffssType = ffss.arce__ffss_submitted_type__c.toUpperCase();
        financialType.idLong = ffssType.replace('INDIVIDUAL', 'SINGLE');

        final arce.Arc_gen_Sales_Wrappers.FinancialWrapper financial = new arce.Arc_gen_Sales_Wrappers.FinancialWrapper();
        financial.idLong = ahaObj.arce__ffss_for_rating_id__r.arce__financial_statement_id__c;
        financial.adjustedIndicator = false;
        financial.finStatType = financialType;

        final arce.Arc_gen_Sales_Wrappers.SalesWrapper sale = new arce.Arc_gen_Sales_Wrappers.SalesWrapper();
        if(tableContent != null) {
            sale.sales = tableContent.arce__base_amount__c;
            sale.unit = tableContent.arce__Unit_Type__c;
        }
        sale.year = String.valueOf(ffss.arce__financial_statement_end_date__c.year());
        sale.currencyX = ffss.CurrencyIsoCode;
        sale.finStatement = financial;
        sale.isAnchor = true;

        sale.exchangeRate = setExchange(ffss);
        final List<arce.Arc_gen_Sales_Wrappers.SalesWrapper> saleList = new List<arce.Arc_gen_Sales_Wrappers.SalesWrapper>();
        saleList.add(sale);

        return saleList;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that generates the json and executes the call to the service and returns service response
    * -----------------------------------------------------------------------------------------------
    * @param String ahaId - Selected account has analysis id
    * @param List<arce__Account_has_Analysis__c> ahaObjList - List of selected account has analysis objects
    * @param List<SObject> toolkitSObjList - List of all selected toolkit objects
    * @return ResponseWrapper - Service response
    * @example ResponseWrapper dataResponse = processData(ahaId, response)
    * -----------------------------------------------------------------------------------------------
    **/
    public static ResponseWrapper callIASOServiceEngineSales(arce__Account_has_Analysis__c ahaObj, String raipType) {
        final ResponseWrapper response;
        try {
            final arce.Arc_gen_Sales_Wrappers.DataWrapper request = setVariables(ahaObj, raipType);
            String salesRequestJson = JSON.serialize(request, true);

            final Map<String, String> replacementKeys = new Map<String, String>{ 'currencyX' => 'currency', 'dateX' => 'date', 'parentSubsidiary' => 'relationParentSubsidiary', 'finStatement' => 'financialStatement', 'idLong' => 'id', 'finStatType' => 'financialStatementType' };
            salesRequestJson = replaceJsonKeys(salesRequestJson, replacementKeys);
            final Map<String, String> parametersJson = setParametersSales(ahaObj);
            parametersJson.put('jsonInput', salesRequestJson);

            final arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERV_NAME_ENSALES, JSON.serialize(parametersJson));
            String responseJson = JSON.serialize(iasoResponse.serviceResponse);
            final Map<String, String> replacementKeysS = new Map<String, String>{ 'currency' => 'currencyX', 'date' => 'dateX', 'relationParentSubsidiary' => 'parentSubsidiary', 'financialStatement' => 'finStatement', 'id' => 'idLong', 'financialStatementType' => 'finStatType' };
            responseJson = replaceJsonKeys(responseJson, replacementKeysS);

            final arce.Arc_gen_Sales_Wrappers.EngineSalesResponseWrapper salesResponse = (arce.Arc_gen_Sales_Wrappers.EngineSalesResponseWrapper) JSON.deserializeStrict(responseJson, arce.Arc_gen_Sales_Wrappers.EngineSalesResponseWrapper.class);

            if (iasoResponse.serviceCode.contains('20')) {
                response = new ResponseWrapper(salesResponse.data.calculationResult, null, ahaObj.Id, iasoResponse.serviceCode);
            } else {
                response = new ResponseWrapper(false, salesResponse.messages[0].message, ahaObj.Id, iasoResponse.serviceCode);
            }
            updateAhaExtSalesEngine(request, ahaObj);
        } catch (CalloutException exc) {
            response = new ResponseWrapper(false, exc.getMessage(), ahaObj.Id, System.Label.Arc_Gen_ApexCallError);
            System.debug(response);
            throw new AuraHandledException(exc.getMessage());
        }
        return response;
    }

    /**
    * @Description: Iterates over a map of old keys (reserved apex words, unusable as wrapper params) to new keys
    * (usually we append "_x" to the original key) and does a find and replace on all of them.
    * This method is “safer” than String.replace() because we first reformat the JSON into a known good format so that we only replace the initial key.
    * This prevents us from accidentally replacing a match for the key in the middle of the data.
    * @param String data: inputJson string.
    * @param Map<String,String> replacements: map of existing key to replacement key.
    * Example: Map<String, String> replacements = new Map<String, String> {'currency' => 'currencyX', 'number' => 'numberX'};
    * @return String formattedJSON
    */
    public static String replaceJsonKeys(String data, Map<String, String> replacements) {
        // Since our JSON can come in formatted however the endpoint wants, we need to format it to a standard we know and can handle
        String formattedJSON = JSON.serializePretty(JSON.deserializeUntyped(data));
        // Iterate over all the keys we want to replace
        for (String key : replacements.keySet()) {
            // Generate our regex based on the key
            final String regex = String.format(REGEX_FORMAT, new List<String>{ key });
            // Generate our replacement
            final String replacement = String.format(REPLACEMENT_F, new List<String>{ replacements.get(key) });
            // Find all and replace
            formattedJSON = formattedJSON.replaceAll(regex, replacement);
        }
        return formattedJSON;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that get ffssInformation
    * -----------------------------------------------------------------------------------------------
    * @param String ffssId - Selected account has analysis id
    * @return arce__Financial_Statements__c
    * @example ResponseWrapper getFfssInformation = getFfssInformation(ffssId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce__Financial_Statements__c getFfssInformation(String ffssId) {
        arce__Financial_Statements__c financialState = new arce__Financial_Statements__c();
        if (Schema.sObjectType.arce__Financial_Statements__c.isAccessible()) {
            financialState = [SELECT tolabel(arce__ffss_submitted_type__c), arce__financial_statement_end_date__c, CurrencyIsoCode
                            FROM arce__Financial_Statements__c
                            WHERE arce__financial_statement_id__c =: ffssId LIMIT 1];
        }
        return financialState;
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method to delete the arce and related record
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @param ahaId - Id of the account_has_analysis
    * @example deleteARCE(recordId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void updateAhaExtSalesEngine(arce.Arc_gen_Sales_Wrappers.DataWrapper request, arce__Account_has_Analysis__c aha) {
        final arce__AHA_Extension__c ahaExtension = new arce__AHA_Extension__c();

        try {
            ahaExtension.id = aha.arce__AHA_Extension__c;
            ahaExtension.arce__sales_engine_amount__c = request.sales[0].sales;
            ahaExtension.arce__sales_engine_amount_unit__c = request.sales[0].unit;
            ahaExtension.arce__sales_engine_sales_amount_ffss_year__c = request.sales[0].year;
            ahaExtension.arce__sales_engine_amount_ffss_id__c = request.sales[0].finStatement.idLong;
            ahaExtension.arce__sales_engine_client_type__c = request.entityType.idLong;
            ahaExtension.arce__sales_engine_country__c = request.country;
            arce.Arc_Gen_AccHasAnalysis_Data.updateObjects(new List<sObject> { ahaExtension });
        } catch (Exception e) {
            System.debug(loggingLevel.ERROR, e);
        }

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example arce.Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new arce.Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapper {
        /**
        * @description Storing the success response
        */
        @AuraEnabled
        public Boolean success { get;set; }
        /**
        * @description Storing the success response
        */
        @AuraEnabled
        public Boolean calculationResult { get;set; }
        /**
        * @description Storing the message response
        */
        @AuraEnabled
        public String message { get;set; }
        /**
        * @description Storing the id response
        */
        @AuraEnabled
        public String idAha { get;set; }
        /**
        * @description Storing the code response
        */
        @AuraEnabled
        public String code { get;set; }
        /**
        * ----------------------------------------------------------------------------------------------------
        * @description Empty constructor to avoid sonar warnings
        * ----------------------------------------------------------------------------------------------------
        * @param Boolean blSuccess
        * @param String strMessage 
        * @param String strId
        * @param String strCode
        * @example ResponseWrapper wrapper = new arce.Arc_gen_Sales_Wrappers.ResponseWrapper()
        * ----------------------------------------------------------------------------------------------------
        **/
        public ResponseWrapper(Boolean calResult, String strMessage, String strId, String strCode) {
            if(strCode != null && strCode.contains('20')) {
                success = true;
            } else {
                success = false;
            }
            message = strMessage;
            idAha = strId;
            code = strCode;
            calculationResult = calResult;
        }
    }

}