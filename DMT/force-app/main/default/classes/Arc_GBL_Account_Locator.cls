/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_Account_Locator
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 15/11/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class "Arc_GBL_Account_Locator"
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-11-15 juanignacio.hita.contractor@bbva.com
*             Class creation
* |2019-11-29 manuelhugo.castillo.contractor@bbva.com
*             Add methods 'getAccountByAccNumber','accountsForLookup'
* |2020-01-06 mariohumberto.ramirez.contractor@bbva.com
*             Fix method getParticipantType, added orphan validation
* |2020-01-15 javier.soto.carrascosa@bbva.com
*             Add accountUpdate, createGroup methods
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Add random values to the account wrapper
* |2020-01-29 javier.soto.carrascosa@bbva.com
*             Add docnumber, doctype remove orphan value
* |2020-01-29 juanmanuel.perez.ortiz.contractor@bbva.com
*             Remove companyEcoAct, accActivity, rtDevName from logic of account wrapper
* |2020-05-13 cesaroctavio.villanueva.cebal@bbva.com
*             Added sponsorIndicator from logic of account wrapper
* |2020-05-25 cesaroctavio.villanueva.cebal@bbva.com
*             Removed sponsorIndicator from Account Wrapper
* |2020-04-12 javier.soto.carrascosa@bbva.com
*             Add support to retrieve local field from risk assessment location
* |2020-07-15 javier.soto.carrascosa@bbva.com
*             Add branch id parameter
* |2020-07-24 joseluis.garcia4.contractor@bbva.com
*             Allow 'UNIT' text to be translated
* |2020-09-15 javier.soto.carrascosa@bbva.com
*             Remove unused method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-24 ivan.cons@bbva.com
*             Added new param country
* |2021-03-18 alexander.munguia.contractor@bbva.com
*             Method getRatingGCPByAccountNumber has been created
* |2021-05-11 alexander.munguia.contractor@bbva.com
*             The end of date, toolRating, ratingId and EEFFID fields have been added to the EEFF query
* |2021-05-13 otiliaramona.veres.contractor.capacitacion@bbva.com
*             Added final local variable 'lstUp' and 'sare'
* |2021-05-20 alexander.munguia.contractor@bbva.com new GCP rating validation.
* |2021-06-22 alexander.munguia.contractor@bbva.com the ternary for bankId is added.
* |2021-05-06 antonio.munoz.perez.contractor@bbva.com
*             Add globalId parameter initialization. (alpha code)
* |2022-05-12 alberto.martinez.carrero.contractor@bbva.com
*             Add bookingCountry parameter to getAccountInfoById method
* -----------------------------------------------------------------------------------------------
*/
global without sharing class Arc_GBL_Account_Locator implements  arce.Arc_Gen_Account_Interface {
    /**
        * @Description: String with value "Group"
    */
    static final string S_GROUP = 'GROUP';
    /**
        * @Description: String with value "Client"
    */
    static final string CLIENT = 'SUBSIDIARY';
    /**
        * @Description: String with value "Financial statement type"
    */
    private final static String TYPE = '1';
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getAccountInfoById" that retrieves full user information from a list of account Id
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 2019-11-15
    * @param List<Id> listAccountId
    * @return   Map with Account Wrappers
    * @example Map<Id,arce.Arc_Gen_Account_Wrapper> list = Arc_GBL_Account_Locator.getAccountInfoById(listAccountId);
    **/
    public Map<Id,arce.Arc_Gen_Account_Wrapper> getAccountInfoById(List<Id> listAccountId) {
        final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<Id,arce.Arc_Gen_Account_Wrapper>();
        try {
            final List<Account> lstAcc = [SELECT Id, CurrencyIsoCode, Name, AccountNumber, OwnerId, RecordTypeId,
                company_economic_activity_id__c, bank_id__c, bbva_total_debt_amount__c, CreatedById,
                NumberOfEmployees, LastModifiedById, ParentId, Rating, RecordType.DeveloperName
                FROM Account WHERE Id =:listAccountId];
            for(Account acc : lstAcc) {
                final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
                wrapper.accId = acc.Id;
                wrapper.accNumber = acc.AccountNumber;
                wrapper.name = acc.Name;
                wrapper.bankId = String.isBlank(acc.bank_id__c) ? arce.Arc_Gen_RatingGlobal_Constants.BANK_ID : acc.bank_id__c;
                wrapper.participantType = acc.ParentId == null ? S_GROUP : CLIENT;
                wrapper.docType = 'NIF';
                wrapper.docNumber = '0000000A';
                wrapper.participantOwnerId = acc.OwnerId;
                wrapper.accParentId = acc.ParentId;
                wrapper.currentLimit = math.random() * 100;
                wrapper.commited = math.random() * 100;
                wrapper.unCommited = math.random() * 100;
                wrapper.outstanding =  math.random() * 100;
                wrapper.currencyType = 'EUR';
                wrapper.unit = System.Label.Arc_Gen_PositionUnitRow;
                wrapper.branchId = '000';
                wrapper.globalId = wrapper.accNumber; // Alpha code
                wrapper.country = acc.Site;
                wrapper.bookingCountry = acc.Site;
                wrapper.isProspect = (acc.AccountNumber == '2600001cOSSCAA4') ? true : false;
                mapWrapper.put(acc.Id, wrapper);
            }
        } catch(Exception ex) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.error = ex.getMessage();
            mapWrapper.put(null, wrapper);
        }
        return mapWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getAccountByAccNumber" gets all account fields filtered by AccountNumber
    --------------------------------------------------------------------------------
    * @author manuelhugo.castillo.contractor@bbva.com
    * @date 2019-11-25
    * @param List<String> listAccountNum
    * @return   Map with Account Wrappers
    * @example Map<Id,arce.Arc_Gen_Account_Wrapper> list = Arc_GBL_Account_Locator.getAccountByAccNumber(listAccountNum);
    **/
    public Map<String,arce.Arc_Gen_Account_Wrapper> getAccountByAccNumber(List<String> listAccountNum) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<String,arce.Arc_Gen_Account_Wrapper>();
        try {
            final List<Account> lstAcc = [SELECT Id, CurrencyIsoCode, Name, AccountNumber, OwnerId, RecordTypeId,
                company_economic_activity_id__c, bank_id__c, bbva_total_debt_amount__c, CreatedById,
                NumberOfEmployees, LastModifiedById, ParentId, Rating
                FROM Account WHERE AccountNumber IN: listAccountNum];
            for(Account acc : lstAcc) {
                final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
                wrapper.accId = acc.Id;
                wrapper.name = acc.Name;
                wrapper.accNumber = acc.AccountNumber;
                wrapper.bankId = String.isBlank(acc.bank_id__c) ? arce.Arc_Gen_RatingGlobal_Constants.BANK_ID : acc.bank_id__c;
                wrapper.docType = 'NIF';
                wrapper.docNumber = '0000000A';
                wrapper.participantType = acc.ParentId == null ? S_GROUP : CLIENT;
                wrapper.participantOwnerId = acc.OwnerId;
                wrapper.accParentId = acc.ParentId;
                wrapper.globalId = wrapper.accNumber; // Alpha code
                wrapper.isProspect = (acc.AccountNumber == '2600001cOSSCAA4') ? true : false;
                mapWrapper.put(acc.AccountNumber, wrapper);
            }
        } catch(Exception ex) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.error = ex.getMessage();
            mapWrapper.put(null, wrapper);
        }
        return mapWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "accountsForLookup" gets account fields filtered by searchWord
    --------------------------------------------------------------------------------
    * @author manuelhugo.castillo.contractor@bbva.com
    * @date 2019-11-25
    * @param String searchWord
    * @return   Account Wrappers List
    * @example List<arce.Arc_Gen_Account_Wrapper> map = Arc_GBL_Account_Locator.accountsForLookup(String searchWord)
    **/
    public List<arce.Arc_Gen_Account_Wrapper> accountsForLookup(String searchWord) {
        final List<arce.Arc_Gen_Account_Wrapper> lstAccWrapper = new List<arce.Arc_Gen_Account_Wrapper>();
        final String searchQuery = 'FIND \'' + String.escapeSingleQuotes(searchWord) + '\' IN ALL FIELDS RETURNING Account (id, name, OwnerId, ParentId)';
        final List < List < Account >> accountsforshow = search.query(searchQuery);
        for(Account acc : accountsforshow[0]) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.accId = acc.Id;
            wrapper.name = acc.Name;
            wrapper.participantOwnerId = acc.OwnerId;
            wrapper.isProspect = (acc.AccountNumber == '2600001cOSSCAA4') ? true : false;
            lstAccWrapper.add(wrapper);
        }
        return lstAccWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "accountUpdate" updates a map of Account Ids and attributes
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2020-01-15
    * @param Map<Id, Map<String,String>> lstAccUp
    * @return   arce.Arc_Gen_ServiceAndSaveResponse
    * @example arce.Arc_Gen_ServiceAndSaveResponse accountUpdate(Map<Id, Map<String,String>> lstAccUp)
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse accountUpdate(Map<Id, Map<String,Object>> lstAccUp) {
        final arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
        final List<Account> lstUp = new List<Account>();
        for (Id accId : lstAccUp.keySet()) {
        Account accUp = new Account(Id=accId);
        accUp = putFieldsFromMap(accUp,lstAccUp.get(accId));
        lstUp.add(accUp);
        }
        try {
            result.saveStatus = 'true';
            final List<Database.SaveResult> sare = database.update(lstUp);
            result.saveMessage = Json.serialize(sare);
        } catch (Exception ex) {
            result.saveStatus = 'false';
            result.saveMessage = ex.getMessage();
        }
        return result;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "createGroup" create group account
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2020-01-15
    * @param Map<String,String> accAttr
    * @return  arce.Arc_Gen_ServiceAndSaveResponse
    * @example arce.Arc_Gen_ServiceAndSaveResponse createGroup(Map<String,String> accAttr)
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse createGroup(Map<String,Object> accAttr) {
        final arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
        Account grpAccount = new Account();
        grpAccount = putFieldsFromMap(grpAccount,accAttr);
        try {
            result.saveStatus = 'true';
            final Database.SaveResult sare = database.insert(grpAccount);
            result.saveMessage = Json.serialize(sare);
            result.createdRsr = new List<Id>{sare.getId()};
        } catch (Exception ex) {
            result.saveStatus = 'false';
            result.saveMessage = ex.getMessage();
        }
        return result;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "putFieldsFromMap" retrieves updated object from input fields and values
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2020-01-15
    * @param Account acc
    * @param Map<String,String> mapValues
    * @return   Account
    * @example Account putFieldsFromMap(Account acc,Map<String,String> mapValues)
    **/
    private static Account putFieldsFromMap(Account acc, Map<String,Object> mapValues) {
        for (String fieldName : mapValues.keySet()) {
            acc.put(fieldName, mapValues.get(fieldName));
        }
        return acc;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getRatingGCPByAccountNumber" retrieves Financial statement By Accnumbers
    --------------------------------------------------------------------------------
    * @author alexander.munguia.contractor@bbva.com
    * @date 2021-03-17
    * @param List<String> accountNumber
    * @return   Map<String,arce__Financial_Statements__c>
    * @example Map<String,arce__Financial_Statements__c> list =  getRatingGCPByAccountNumber(List<String> accountNumber)
    **/
    public static Map<String,arce__Financial_Statements__c> getRatingGCPByAccountNumber (List<String> accountNumber) {
        Map<String,arce__Financial_Statements__c> result = new Map<String,arce__Financial_Statements__c>();
        System.debug('UnusedPrivateField warning avoid debug: ' + TYPE);
        final List<String> conditions = new List <String>{'arce__ffss_submitted_type__c =: TYPE', 'arce__ffss_valid_type__c =: TYPE', 'arce__rating_id__c != null'};
        final Set<String> ahaByParentId = new Set<String>();
        for(arce__Account_has_Analysis__c aha : [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__r.AccountNumber IN: accountNumber
                                                    AND arce__Analysis__r.arce__Stage__c = '3' AND arce__Analysis__r.arce__wf_status_id__c = '13' AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating']) {
            ahaByParentId.add(aha.Id);
        }
        final String condition = ' AND ' + String.join(conditions, ' AND ') + ' ORDER BY CreatedDate DESC';
        result = getFinancialStatementByAha(ahaByParentId, condition);
        return result;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getFinancialStatementByAha" retrieves Financial statement By Accnumbers
    --------------------------------------------------------------------------------
    * @author alexander.munguia.contractor@bbva.com
    * @date 2021-03-17
    * @param Set<String> ahaId
    * @param String condition
    * @return   Map<String,arce__Financial_Statements__c>
    * @example Map<String,arce__Financial_Statements__c> list =  getFinancialStatementByAha(List<String> accountNumber)
    **/
    //@SuppressWarnings('sf:UnusedFormalParameter')
    private static Map<String, arce__Financial_Statements__c> getFinancialStatementByAha (Set<String> ahaId, String condition) {
        final Map<String, arce__Financial_Statements__c> result = new Map<String, arce__Financial_Statements__c>();
        System.debug('UnusedFormalParameter warning avoid debug: ' + ahaId);
        String queryString = 'SELECT Id, arce__total_rating_score_number__c, arce__rating_id__r.arce__rating_long_value_type__c, arce__rating_id__r.arce__rating_short_value_type__c, arce__financial_statement_id__c, arce__financial_statement_start_date__c,arce__financial_statement_end_date__c, arce__rating_final__c';
        queryString += ', arce__account_has_analysis_id__r.arce__Customer__r.AccountNumber, arce__account_has_analysis_id__r.arce__total_rating_score_number__c'+
            ', arce__account_has_analysis_id__r.arce__short_rating_value_type__c, arce__account_has_analysis_id__r.arce__long_rating_value_type__c, arce__rar_rating_tool_id__c, arce__rating_id__r.arce__rating_id__c, arce__account_has_analysis_id__r.arce__Analysis__r.arce__end_date__c';
        queryString += ' FROM arce__Financial_Statements__c where arce__account_has_analysis_id__c IN: ahaId ' + condition;
            for (arce__Financial_Statements__c ffee : Database.query(String.escapeSingleQuotes(queryString))) {
                if(!result.containsKey(ffee.arce__account_has_analysis_id__r.arce__Customer__r.AccountNumber)) {
                    result.put(ffee.arce__account_has_analysis_id__r.arce__Customer__r.AccountNumber, ffee);
                }
            }
        return result;
    }
}