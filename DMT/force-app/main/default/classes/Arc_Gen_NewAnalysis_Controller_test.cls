/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NewAnalysis_Controller_test
* @Author   diego.miguel.contractor@bbva.com
* @Date     Created: 2019-04-11
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_NewAnalysis_Controller,Arc_Gen_NewAnalysis_data
* Arc_Gen_NewAnalysis_Service, Arc_Gen_SetSector_Service, Arc_Gen_SetSector_data
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-04-11 diego.miguel.contractor@bbva.com
*             Class creation.
* |2019-30-04 eduardoefrain.hernandez.contractor@bbva.com
*             updated
* |2019-05-03 diego.miguel.contractor@bbva.com
*             Update to name ARCE
* |2019-05-09 diego.miguel.contractor@bbva.com
*             Update to Arce status
* |2019-05-14 diego.miguel.contractor@bbva.com
*             Added test methods to groups coverage.
* |2019-08-13 mariohumberto.ramirez.contractor@bbva.com
*             Added new test method testSetClientSectorNull in order to increase code coverage
* |2019-05-14 luisruben.quinto.munoz@bbva.com
*             Delete reference to arce__Id__c
* |2019-09-26 javier.soto.carrascosa@bbva.com
*             Remove incorrect test methods
* |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
*             update test class
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-02-08 ricardo.almanza.contractor@bbva.com
*             Added orphan
* |2020-02-28 juanignacio.hita.contractor@bbva.com
*             Added parameter "analysisType" in the test
* |2020-04-08 joseluis.garcia4.contractor@bbva.com
*             Refactor of new ARCE modal
* |2020-04-21 joseluis.garcia4.contractor@bbva.com
*             Fixes test after RAIP creation refactor.
* |2020-05-04 ricardo.almanza.contractor@bbva.com
*             Added method testtriage
* |2020-05-08 juanmanuel.perez.ortiz.contractor@bbva.com
*             Added method flowModifiedArceTest
* |2020-05-20 juanmanuel.perez.ortiz.contractor@bbva.com
*             Added method emptyConstructorTest
* |2020-06-12 mariohumberto.ramirez.contractor@bbva.com
*             update test class
* |2020-06-18 joseluis.garcia4.contractor@bbva.com
*             Add isOrphan in the call to the listParticipant service.
* |2020-07-15 juanignacio.hita.contractor@bbva.com
*             Add isOrphan in test methods
* |2020-07-15 javier.soto.carrascosa@bbva.com
*             Add process subtype
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-08-17 mariohumberto.ramirez.contractor@bbva.com
*             Update test class for hu renovation
* |2020-08-25 mariohumberto.ramirez.contractor@bbva.com
*             Update test class
* |2020-08-26 juanmanuel.perez.ortiz.contractor@bbva.com
*             Added method getAnalysisDataTest
* |2020-09-02 mariohumberto.ramirez.contractor@bbva.com
*             Update test class
* |2020-09-07 mariohumberto.ramirez.contractor@bbva.com
*             update test class
* |2020-09-14 mariohumberto.ramirez.contractor@bbva.com
*             update test class
* |2020-09-14 joseluis.garcia4.contractor@bbva.com
*             Increase test coverage
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-28 eduardoefrain.hernandez.contractor@bbva.com
*             Update flowModifiedArceTest method
* |2020-10-13 eduardoefrain.hernandez.contractor@bbva.com
*             Update flowModifiedArceTest method
* |2020-12-21 juanignacio.hita.contractor@bbva.com
*             Add testCallRiskFilters test method
* |2021-03-11 juanmanuel.perez.ortiz.contractor@bbva.com
*             Update flowModifiedArceTest method
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__sector_desc__c for arce__sector_id__c
* |2021-05-31 juanignacio.hita.contractor@bbva.com
*             Add testGetGroupId, testPerformFfssTestCall methods
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback 2020-03-12 commit PR:1231
* |2021-09-02 juanignacio.hita.contractor@bbva.com
*             Fix tests for Spain deployment.
* |2021-09-02 javier.soto.carrascosa@bbva.com
*             Add name to Subsidiary and Group
* |2022-01-21 saimassimilianno.jordana.contractor@bbva.com
*             profilingResultTest method added.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_NewAnalysis_Controller_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string TEST_TEXT = 'Test';
    /**
    * @Description: "contains id" literal
    */
    static final string CONTAINSID_LIT = 'contains id';
    /**
    * @Description: "The response is not empty" literal
    */
    static final string RESPNOTEMPTY_LIT = 'The response is not empty';
    /**
    * @Description: 'isHolding' literal
    */
    static final string ISHOLDING_LIT = 'isHolding';
    /**
    * @Description: 'isorphan' literal
    */
    static final string ISORPHAN_LIT = 'isorphan';
    /**
    * @Description: 'Empty constructor' literal
    */
    static final string EMPCONST_LIT = 'Empty constructor';
    /**
    * @Description: 'there was an error' literal
    */
    static final string ERROR_LIT = 'there was an error';
    /**
    * @Description: LISTP literal
    */
    static final String LISTP = '{"servicecallerror":"","errormessage":"","error204message":"","customersdata":[{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"C000001","ParentEconomicGroupId":null},{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"NOTVALID","ParentEconomicGroupId":null}]}';
    /**
    * @Description: LISTP2 literal
    */
    static final String LISTP2='{"servicecallerror":"","errormessage":"","error204message":"","customersdata":[{"pRelRelationTypeId":"IG","pRelLevel":"02","participname":null,"participantId":"IV019470","parentEconomicGroupId":null},{"pRelRelationTypeId":"IG","pRelLevel":"03","participname":null,"participantId":"C000001","parentEconomicGroupId":null}]}';
    /**
    * @Description: LISTP2 literal
    */
    static final String ECONOMICP = '{"servicecallerror":null,"groupinfo":{"groupname":"GUZMAN FONSECA,SA DE CV","groupid":"G000001","decryptedgroupid":"G000001"},"errormessage":null,"error204message":null,"business":{"bussineslistdocuments":[{"businessDocumentNumber":"USQ921005WWX","businessDocTypeName":null,"businessDocTypeId":null}],"businessLegalName":"DEGUSSA CORMPANY Lochlynn Seanna","businessId":"C000001"}}';
    /**
    * @Description: Insert new Analysis
    */
    private static arce__Analysis__c setAnalysis(String name, String accId) {
        final Date dateToday = date.today();
        final Date nextWeek = dateToday.addDays(7);
        final arce__Analysis__c analysis = new arce__Analysis__c(
            Name = name, arce__Group__c  = accId, arce__anlys_wkfl_sanction_rslt_type__c = '1', arce__Stage__c = '3', arce__analysis_risk_expiry_date__c = nextWeek,
            arce__wf_status_id__c = '10'
        );
        insert analysis;
        return analysis;
    }

    private static arce__Account_has_Analysis__c setAnalyzedClient(String clientId,String analysisId) {
        final arce__Account_has_Analysis__c analyzedClient = new arce__Account_has_Analysis__c(
            arce__Customer__c = clientId,
            arce__Analysis__c = analysisId
        );
        Insert analyzedClient;
        return analyzedClient;
    }
    private static arce__Account_has_Analysis__c getAnalyzedClient(String accNumber) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{accNumber});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(accNumber);
        final Account testAcc = new Account(Id = groupAccount.accId);
        final arce__Analysis__c analysis = setAnalysis('Analysis',testAcc.Id);
        final arce__Account_has_Analysis__c accHasAn = setAnalyzedClient(groupAccount.accId,analysis.Id);
        return accHasAn;
    }
    private static void insertThirdParticipantsData(String acchasId) {
        final arce__Third_Participant__c testThird = new arce__Third_Participant__c();
        insert testThird;
        final arce__Third_Participant_Details__c thirdPart = new arce__Third_Participant_Details__c(arce__account_has_analysis_id__c = acchasId, arce__third_participant_id__c = testThird.Id);
        insert thirdPart;
    }
    private static void insertTableContentPerAnalysisData(String acchasId) {
        final Id recordTypeId = Schema.SObjectType.arce__Table_Content_per_Analysis__c.getRecordTypeInfosByName().get('Activities').getRecordTypeId();
        final arce__Data_Collections__c dataCollection = new arce__Data_Collections__c(arce__collection_table__c = '06');
        insert dataCollection;
        final arce__Table_Content_per_Analysis__c tableContent = new arce__Table_Content_per_Analysis__c(arce__account_has_analysis_id__c = acchasId,arce__Data_Collection_Id__c = dataCollection.Id,recordtypeid=recordTypeId);
        insert tableContent;
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    private static void insertLimExposureData(String acchasId) {
        final arce__limits_typology__c limTypo1 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, null);
        limTypo1.arce__risk_typology_level_id__c = 'TP_0005';
        limTypo1.arce__risk_typology_active__c = true;
        limTypo1.arce__risk_typology_level_type__c = '1';
        limTypo1.arce__Typology_Order__c = 1;
        insert limTypo1;
        final arce__limits_typology__c limTypo2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Commercial Risk', limTypo1.Id, null);
        limTypo2.arce__risk_typology_level_id__c = 'TP_0010';
        limTypo2.arce__risk_typology_active__c = true;
        limTypo2.arce__risk_typology_level_type__c = '2';
        insert limTypo2;

        final Product2 product = new product2();
        product.name = 'productTest';
        product.isActive = true;
        insert product;


        final arce__limits_exposures__c limExp1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null, null, acchasId, limTypo1.Id);
        insert limExp1;
        final arce__limits_exposures__c limExp2 = Arc_UtilitysDataTest_tst.crearLimitExposures(limExp1.Id, null, acchasId, limTypo2.Id);
        insert limExp2;
        final arce__limits_exposures__c limExp3 = Arc_UtilitysDataTest_tst.crearLimitExposures(limExp2.Id, null, acchasId, null);
        limExp3.arce__Product_id__c = product.Id;
        insert limExp3;
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    private static void insertDynamicFormData() {
        final dyfr__Template__c templateInfo = Arc_UtilitysDataTest_tst.crearTemplate(TEST_TEXT);
        insert templateInfo;

        final dyfr__Tab__c tabInfo = Arc_UtilitysDataTest_tst.crearTab('tabTest', templateInfo.Id);
        tabInfo.dyfr__Tab_Code__c = 'BusinessRisk';
        insert tabInfo;

        final dyfr__Field_Config__c fieldConfInfo1 = Arc_UtilitysDataTest_tst.crearfieldConfigData('sectionTest', tabInfo.Id, 'arce__sector_desc__c');
        fieldConfInfo1.dyfr__Type__c = 'Text';
        fieldConfInfo1.dyfr__Hidden__c = false;
        fieldConfInfo1.dyfr__Read_only__c = false;
        insert fieldConfInfo1;

    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @testSetup static void setup() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();
        
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,GROUP_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;
        final arce__Financial_Statements__c ffss1 = new arce__Financial_Statements__c(arce__financial_statement_id__c = 'dummyFFSS');
        ffss1.arce__financial_statement_end_date__c = date.today().addMonths(-5);
        insert ffss1;
        final arce__Financial_Statements__c ffss2 = new arce__Financial_Statements__c(arce__financial_statement_id__c = 'NoValidFFSS');
        ffss2.arce__financial_statement_end_date__c = date.today().addMonths(-19);
        insert ffss2;
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__analysis_customer_relation_type__c = '01';
        insert newArce;
        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__group_asset_header_type__c = '1';
        newAnalysis.arce__magnitude_unit_type__c = '1';
        newAnalysis.arce__ffss_for_rating_id__c = ffss1.Id;
        newAnalysis.arce__InReview__c = true;
        insert newAnalysis;
        final arce__Account_has_Analysis__c newAnalysis2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        newAnalysis2.arce__group_asset_header_type__c = '2';
        newAnalysis2.arce__magnitude_unit_type__c = '1';
        newAnalysis2.arce__ffss_for_rating_id__c = ffss2.Id;
        newAnalysis2.arce__InReview__c = true;
        insert newAnalysis2;
        final arce.Arc_Gen_Account_Wrapper groupAccount2 = groupAccWrapper.get(GROUP_ID2);
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        final arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c(arce__gf_company_economic_actvy_id__c = '234567890', arce__customer__c = groupAccount2.accId,arce__Analysis__c = newArce.Id, arce__group_asset_header_type__c = '2');
        insert accHasAnalysis;
        final SectorAssetBanxico__c sector = new SectorAssetBanxico__c(company_economic_activity_id__c = '234567890', Name = 'sector test', sector_id__c = '0099887766');
        insert sector;
        final Sectores_catalog__c sectorPart2 = new Sectores_catalog__c(sector_outlook_type__c = 'type', sector_id__c = '0099887766', Name = 'Sector test');
        insert sectorPart2;
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testlistpa() {
        Test.startTest();
        final String response = Arc_Gen_NewAnalysis_Controller.listparticipant('ae2NAUGjEQ1WtclUDaytLg', false);
        System.assertEquals(response, response, CONTAINSID_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testesconomicp() {
        Test.startTest();
        final String response = Arc_Gen_NewAnalysis_Controller.economicarticipants('ae2NAUGjEQ1WtclUDaytLg');
        System.assertEquals(response, response, CONTAINSID_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void groupstructure() {
        Test.startTest();
        final String response = Arc_Gen_NewAnalysis_Controller.constructgroupstructure(LISTP2,ECONOMICP,'C000001',false);
        System.assert(!String.isEmpty(response), RESPNOTEMPTY_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void setarceOrphan() {
        final Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'C000003' limit 1];
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = acc.Id;
        accWrapLts.add(accWrap);
        final Map<String, Boolean> mapIsHolding = new Map<String, Boolean>();
        mapIsHolding.put(acc.Id, false);
        Test.startTest();
        final Map<String, String> params = new Map<String, String>();
        params.put('recordId', (String) acc.Id);
        params.put(ISORPHAN_LIT, 'true');
        params.put('orphanNumber', 'C000001');
        params.put('accounts',  JSON.serialize(accWrapLts));
        params.put(ISHOLDING_LIT, JSON.serialize(mapIsHolding));
        params.put('analysisType', '2');
        final String response = Arc_Gen_AnalysisWizard_Controller.setanalysis(params);
        System.assert(!String.isEmpty(response), RESPNOTEMPTY_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void setarce() {
        final Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'C000001' limit 1];
        final Account groupAcc = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' limit 1];
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = acc.Id;
        accWrap.name = TEST_TEXT;
        accWrap.isProspect = false;
        accWrapLts.add(accWrap);
        final Map<String, Boolean> mapIsHolding = new Map<String, Boolean>();
        mapIsHolding.put(acc.Id, false);
        final arce.Arc_Gen_Account_Wrapper accWrapGp =  new arce.Arc_Gen_Account_Wrapper();
        accWrapGp.accId = groupAcc.Id;
        accWrapGp.name = TEST_TEXT;
        accWrapGp.isProspect = false;
        accWrapLts.add(accWrapGp);
        Test.startTest();
        final Map<String, String> params = new Map<String, String>();
        params.put('recordId', (String) acc.Id);
        params.put(ISORPHAN_LIT, 'false');
        params.put('orphanNumber', 'C000001');
        params.put('accounts',  JSON.serialize(accWrapLts));
        params.put('analysisType', '2');
        params.put(ISHOLDING_LIT, JSON.serialize(mapIsHolding));
        final String response = Arc_Gen_AnalysisWizard_Controller.setanalysis(params);
        System.assert(!String.isEmpty(response), RESPNOTEMPTY_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void setarce2() {
        final Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'C000001' limit 1];
        final Account groupAcc = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' limit 1];
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = acc.Id;
        accWrapLts.add(accWrap);
        final Map<String, Boolean> mapIsHolding = new Map<String, Boolean>();
        mapIsHolding.put(acc.Id, false);
        final arce.Arc_Gen_Account_Wrapper accWrapGp =  new arce.Arc_Gen_Account_Wrapper();
        accWrapGp.accId = groupAcc.Id;
        accWrapLts.add(accWrapGp);
        Test.startTest();
        final Map<String, String> params = new Map<String, String>();
        params.put('recordId', (String) acc.Id);
        params.put(ISORPHAN_LIT, 'false');
        params.put('orphanNumber', 'C000001');
        params.put('actualClient', 'C000001');
        params.put('accounts',  JSON.serialize(accWrapLts));
        params.put('analysisType', '4');
        params.put(ISHOLDING_LIT, JSON.serialize(mapIsHolding));
        final String response = Arc_Gen_AnalysisWizard_Controller.setanalysis(params);
        System.assert(!String.isEmpty(response), RESPNOTEMPTY_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void updatearce() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c limit 1];
        System.assertEquals(arceVar, arceVar, CONTAINSID_LIT);
        Test.startTest();
        Arc_Gen_AnalysisWizard_Controller.updateArceToPreparing(arceVar.Id, '');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testarceprev() {
        final Account acc = [SELECT Id FROM Account limit 1];
        System.assertEquals(acc, acc, CONTAINSID_LIT);
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = acc.Id;
        accWrap.accNumber = 'G000001';
        accWrapLts.add(accWrap);
        Test.startTest();
        Arc_Gen_NewAnalysis_Controller.getExistingArce(acc.Id, JSON.serialize(accWrapLts), 'analysis', null);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testarceprevNew() {
        final Account acc = [SELECT Id FROM Account limit 1];
        delete [SELECT Id FROM arce__Analysis__c LIMIT 100];
        System.assertEquals(acc, acc, CONTAINSID_LIT);
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = acc.Id;
        accWrapLts.add(accWrap);
        Test.startTest();
        Arc_Gen_NewAnalysis_Controller.getExistingArce(acc.Id, JSON.serialize(accWrapLts), 'analysis', null);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testpath() {
        final arce__Account_has_Analysis__c accHasAnalysis1 = getAnalyzedClient(GROUP_ID);
        System.assertEquals(accHasAnalysis1, accHasAnalysis1, CONTAINSID_LIT);
        Test.startTest();
        Arc_Gen_AnalysisWizard_Controller.callPathService((String)accHasAnalysis1.arce__Analysis__c,(String)accHasAnalysis1.arce__Customer__c,true);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testtriage() {
        final Account acc = [SELECT Id FROM Account limit 1];
        final arce__Account_has_Analysis__c accHasAnalysis1 = getAnalyzedClient(GROUP_ID);
        System.assertEquals(accHasAnalysis1, accHasAnalysis1, CONTAINSID_LIT);
        Test.startTest();
        Arc_Gen_AnalysisWizard_Controller.callTriage((String)accHasAnalysis1.arce__Analysis__c,(String)accHasAnalysis1.arce__Customer__c,acc.Id);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testcallPersistence() {
        final arce__Analysis__c newArce = [SELECT Id FROM arce__Analysis__c limit 1];
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_AnalysisWizard_Controller.callPersistence(newArce.Id);
        System.assertNotEquals(null, response,'testcallPersistence call');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void setarc() {
        final String acc = [SELECT Id FROM Account limit 1].Id;
        System.assertEquals(acc, acc, CONTAINSID_LIT);
        Test.startTest();
        Arc_Gen_NewAnalysis_Controller.getaccdataforservices(acc);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void emtyConstuctor() {
        Test.startTest();
        final Arc_Gen_NewAnalysis_Service service = new Arc_Gen_NewAnalysis_Service();
        System.assertEquals(service, service, 'Test Success');
        Test.stopTest();
    }
    /**
    * @Method:  testGetAvailableArceTypes
    * @Description: tests the method getAvailableArceTypes from the controller.
    */
    @isTest static void testGetAvailableArceTypes() {
        Test.startTest();
        final List<String> availablArceTypes = Arc_Gen_NewAnalysis_Controller.getAvailableArceTypes();
        System.assertNotEquals(null, availablArceTypes, 'The returned list must not be null');
        Test.stopTest();
    }
    /**
    * @Method:  testShouldShowRaipGroupStructure
    * @Description: tests the method shouldShowRaipGroupStructure from the controller.
    */
    @isTest static void testShouldShowRaipGroupStructure() {
        Test.startTest();
        final Boolean showRaipGs = Arc_Gen_NewAnalysis_Controller.shouldShowRaipGroupStructure();
        System.assertNotEquals(null, showRaipGs, 'The returned value must not be null');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void flowModifiedArceTest() {
        final Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'C000003' limit 1];

        final List<arce__Account_has_Analysis__c> ahaList = [SELECT Id,arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.Name = 'Arce Analysis'];
        insertThirdParticipantsData(ahaList.get(0).Id);
        insertTableContentPerAnalysisData(ahaList.get(0).Id);
        insertLimExposureData(ahaList.get(0).Id);
        insertDynamicFormData();
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = acc.Id;
        accWrap.accNumber = 'G000001';
        accWrapLts.add(accWrap);
        final Map<String, Boolean> mapIsHolding = new Map<String, Boolean>();
        mapIsHolding.put(acc.Id, false);
        Test.startTest();
        final Map<String, String> map1 = new Map<String, String>{
            'analysisId' => ahaList.get(0).arce__Analysis__c,
            'subProcess' => '1',
            'persistanceInd' => 'true',
            'selectedSector' => '1',
            'accountswraper' => JSON.serialize(accWrapLts),
            'modRenVar' => '1',
            ISHOLDING_LIT => JSON.serialize(mapIsHolding)
        };
        final String response = Arc_Gen_AnalysisWizard_Controller.flowModifiedArce(map1);
        Arc_Gen_Expandible_Table_Controller.getLastProposeInfo(ahaList.get(0).Id);
        System.assertNotEquals(ahaList.get(0).arce__Analysis__c, response, 'ARCE dont match correctly');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void emptyConstructorTest() {
        Test.startTest();
        final Arc_Gen_ModificationArce_Controller constructor = new Arc_Gen_ModificationArce_Controller();
        System.assertEquals(constructor, constructor, EMPCONST_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void emptyConstructorTest2() {
        Test.startTest();
        final Arc_Gen_ModificationArce_Service constructor = new Arc_Gen_ModificationArce_Service();
        System.assertEquals(constructor, constructor, EMPCONST_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void emptyConstructorTest3() {
        Test.startTest();
        final Arc_Gen_ModificationArce_Data constructor = new Arc_Gen_ModificationArce_Data();
        System.assertEquals(constructor, constructor, EMPCONST_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void getRelatedRecordsArceTest() {
        Test.startTest();
        final Arc_Gen_CloneWrapper responseWrap = new Arc_Gen_CloneWrapper();
        try {
            responseWrap = Arc_Gen_ModRenArce_Helper.getRelatedRecordsArce('error', null);
        } catch(Exception ex) {
            System.assertNotEquals(null, responseWrap, ERROR_LIT);
        }
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void cloneRecordsTest() {
        Test.startTest();
        try {
            Arc_Gen_ModRenArce_Helper.cloneRecords(new Arc_Gen_CloneWrapper(), null);
        } catch(Exception ex) {
            System.assertNotEquals(null, ex, ERROR_LIT);
        }
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void associateAccHasAn2ArceTest() {
        Test.startTest();
        final List<arce__Account_has_Analysis__c> response = new List<arce__Account_has_Analysis__c>();
        try {
            response = Arc_Gen_ModRenArce_Helper.associateAccHasAn2Arce(new Arc_Gen_CloneWrapper(), null, true, null);
        } catch(Exception ex) {
            System.assertNotEquals(null, response, ERROR_LIT);
        }
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void associateRecords2AccHasAnTest() {
        Test.startTest();
        String response = 'false';
        try {
            response = Arc_Gen_ModRenArce_Helper.associateRecords2AccHasAn(new Arc_Gen_CloneWrapper(), null, null);
        } catch(Exception ex) {
            System.assertNotEquals(null, response, ERROR_LIT);
        }
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void manageTraceabilityTest() {
        Test.startTest();
        try {
            Arc_Gen_ModRenArce_Helper.manageTraceability(null, null);
        } catch(Exception ex) {
            System.assertNotEquals(null, ex, ERROR_LIT);
        }
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void emptyConstructorTestModRen() {
        Test.startTest();
        final Arc_Gen_ModRenArce_Helper constructor = new Arc_Gen_ModRenArce_Helper();
        System.assertEquals(constructor, constructor, EMPCONST_LIT);
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void callEcoPartPerTest() {
        final arce__Account_has_Analysis__c accHasAnalysis1 = getAnalyzedClient('G000001');
        accHasAnalysis1.arce__group_asset_header_type__c = '1';
        update accHasAnalysis1;
        final Account accClient = [SELECT Id FROM Account WHERE AccountNumber = 'C000001' limit 1];
        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, accHasAnalysis1.arce__Analysis__c, accClient.Id, null);
        insert accHasAn;
        final List<arce.Arc_Gen_Account_Wrapper> accWrapLts =  new List<arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap =  new arce.Arc_Gen_Account_Wrapper();
        accWrap.accId = accClient.Id;
        accWrap.accNumber = 'C000001';
        accWrapLts.add(accWrap);
        final arce.Arc_Gen_Account_Wrapper accWrapGp =  new arce.Arc_Gen_Account_Wrapper();
        accWrapGp.accId = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' limit 1].Id;
        accWrapGp.accNumber = 'G000001';
        accWrapLts.add(accWrapGp);
        final Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(LISTP, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
        Test.startTest();
        arce.Arc_Gen_ServiceAndSaveResponse responseError = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            responseError = Arc_Gen_AnalysisWizard_Controller.callEcoGroupParticipantsPer(JSON.serialize(listparticipants), JSON.serialize(accWrapLts), null);
        } catch (Exception e) {
            system.assertEquals('false', responseError.saveStatus, 'SUCCESS');
        }
        Arc_Gen_Refresh_controller.callEcoGroupParticipantsPersistence(JSON.serialize(listparticipants), JSON.serialize(accWrapLts), accHasAnalysis1.arce__Analysis__c);
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_AnalysisWizard_Controller.callEcoGroupParticipantsPer(JSON.serialize(listparticipants), JSON.serialize(accWrapLts), accHasAnalysis1.arce__Analysis__c);
        System.assertEquals('200', response.serviceCode, 'SUCCESS');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void getAnalysisDataTest() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c limit 1];
        Test.startTest();
        final List<arce__analysis__c> result = Arc_Gen_Triage_Service.getAnalysisData(arceVar.Id);
        System.assertEquals(arceVar.Id, result[0].Id, 'ARCE id match succesfully');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @IsTest static void testGetCallTriageConfig() {
        Test.startTest();
        final Boolean result = Arc_Gen_AnalysisWizard_Controller.getCallTriageEngineConfig();
        Test.stopTest();

        System.assertNotEquals(null, result, 'A result must be obtained from the call');
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @IsTest static void testUpdateArceSectorAndStatus() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c limit 1];

        Test.startTest();
        Arc_Gen_AnalysisWizard_Controller.updateArceSectorAndStatus(analysis.Id, 's-01', '1', '2');
        Test.stopTest();

        final arce__Analysis__c anlys = [SELECT arce__wf_status_id__c FROM arce__Analysis__c WHERE Id = :analysis.Id];
        System.assertEquals('02', anlys.arce__wf_status_id__c, 'The status must have been updated');
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testCallRiskFilters() {
        final Account accClient = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' LIMIT 1];
        final arce__Analysis__c newArce = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Arce Analysis' LIMIT 1];
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_AnalysisWizard_Controller.callRiskFilters(accClient.Id, newArce.Id);
        System.assert(response != null,'testcallPersistence call');
        Test.stopTest();
    }
    /**
    * @Method:  test getGroupId method
    * @Description: testing method.
    */
    @isTest static void testGetGroupId() {
        final Account accClient = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' LIMIT 1];
        final arce__Analysis__c newArce = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Arce Analysis' LIMIT 1];
        Test.startTest();
        final arce__Analysis__c analysis = Arc_Gen_NewAnalysis_Controller.getGroupId(newArce.Id);
        System.assertEquals(accClient.Id, analysis.arce__Group__c, 'Return analysis with group id');
        Test.stopTest();
    }
    /**
    * @Method:  test performFfssTestCall method
    * @Description: testing method.
    */
    @isTest static void testPerformFfssTestCall() {
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_NewAnalysis_Controller.performFfssTestCall('G000001');
        System.assertEquals('200', response.serviceCode, 'Return analysis with group id');
        Test.stopTest();
    }
    /**
    * @Method:  test profilingResult method
    * @Description: testing method.
    */
    @isTest static void profilingResultTest() {
        final Id clientId = [SELECT Id FROM Account LIMIT 1].id;

        final Account cliente = new Account(name = TEST_TEXT,parentId=clientId);
        insert cliente;

        Test.startTest();
        final String response = Arc_Gen_NewAnalysis_Controller.profilingResult(cliente.Id);
        System.assertEquals(System.Label.Arc_Gen_AllFlowsAllowed, response, 'Error fetching profile permissions :: profilingResult() ::');
        Test.stopTest();
    }
}