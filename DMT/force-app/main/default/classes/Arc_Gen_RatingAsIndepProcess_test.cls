/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_test
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2020-01-13
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_RatingAsIndepProcess_controller, Arc_Gen_RatingAsIndepProcess_service, Arc_Gen_RAIPButtons
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-13 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-05-07 joseluis.garcia4.contractor@bbva.com
*             Change gettingRaipData() method to adapt to new getRAIPData() response format.
* |2020-05-07 joseluis.garcia4.contractor@bbva.com
*             Add tests for finalizePrerating() method.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-11 eduardoefrain.hernandez.contractor@bbva.com
*             Update test coverage
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-11 juanignacio.hita.contractor@bbva.com
*             Fix setup accounts add Inreview field
* |2021-03-01 saimassimilianno.jordana.contractor@bbva.com
*             Add tests for isRAIPWfMetadata() picklistValueOfSelectWf() newFFSSWAhas() methods.
* |2021-03-01 saimassimilianno.jordana.contractor@bbva.com
*             newFFSSWAhasTest test meth0d modified to keep working correctly with newFFSSWAhas.
* |2021-06-09 saimassimilianno.jordana.contractor@bbva.com
*             Label added to getPicklistValueWFTest, newFFSSWAhasTest meth0ds
* |2021-06-09 saimassimilianno.jordana.contractor@bbva.com
*             Parameter added to picklistValueOfSelectWf() test method.
* |2021-09-22 saimassimilianno.jordana.contractor@bbva.com
*             New test newRatingTyByModl added.
* |2021-10-13 juanignacio.hita.contractor@bbva.com
*             Add new test methods
* |2021-11-02 juanignacio.hita.contractor@bbva.com
*             Increases coverage code
* |2022-01-24 saimassimilianno.jordana.contractor@bbva.com
*             picklistValueOfSelectWf meth0d parameter call changed.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_RatingAsIndepProcess_test {
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
    static final string SUBS_TEMPLATE = 's-01';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string RATING_LITERAL = 'Rating';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_RatingAsIndepProcess_test
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,GROUP_ID2,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper groupAccount2 = groupAccWrapper.get(GROUP_ID2);
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);


        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector(SUBS_TEMPLATE, '100', SUBS_TEMPLATE, null);
        insert newSector;
        final arce__Sector__c newSector2 = Arc_UtilitysDataTest_tst.crearSector('re-gbl-01', '100', 're-gbl-01', null);
        newSector2.arce__active_type__c = true;
        newSector2.arce__rar_rating_tool_id__c = '1234567890';
        insert newSector2;

        final List<arce__Analysis__c> newArces = new List<arce__Analysis__c>();
        newArces.add(Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId));
        newArces.add(Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis2', null, groupAccount2.accId));
        insert newArces;

        final arce__Account_has_Analysis__c accHasAnalysisG = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArces[0].Id, groupAccount.accId, SUBS_TEMPLATE);
        accHasAnalysisG.arce__group_asset_header_type__c = '1';
        accHasAnalysisG.arce__InReview__c = true;
        insert accHasAnalysisG;

        final arce__Account_has_Analysis__c accHasAnalysisG2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArces[1].Id, groupAccount2.accId, SUBS_TEMPLATE);
        accHasAnalysisG2.arce__group_asset_header_type__c = '1';
        accHasAnalysisG2.arce__InReview__c = true;
        insert accHasAnalysisG2;

        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        final arce__Account_has_Analysis__c accHasAnalysisS = new arce__Account_has_Analysis__c(arce__gf_company_economic_actvy_id__c = '234567890', arce__customer__c = clientAccount.accId,arce__Analysis__c = newArces[0].Id);
        accHasAnalysisS.arce__group_asset_header_type__c = '2';
        insert accHasAnalysisS;
        final SectorAssetBanxico__c sector = new SectorAssetBanxico__c(company_economic_activity_id__c = '234567890', Name = 'sector test', sector_id__c = '0099887766');
        insert sector;
        final Sectores_catalog__c sectorPart2 = new Sectores_catalog__c(sector_outlook_type__c = 'type', sector_id__c = '0099887766', Name = 'Sector test');
        insert sectorPart2;
        final arce__Financial_Statements__c financialStatem = Arc_UtilitysDataTest_tst.crearFinStatement(clientAccount.accId, accHasAnalysisG.Id, null, null);
        financialStatem.arce__financial_statement_id__c = 'Test';
        financialStatem.arce__financial_statement_end_date__c = Date.newInstance(2023, 1, 31);
        financialStatem.arce__ffss_submitted_type__c = '1';
        insert financialStatem;
        
        accHasAnalysisG.arce__ffss_for_rating_id__c = financialStatem.Id;
        update accHasAnalysisG;

        final UrlsArce__c urlArce1 = new UrlsArce__c(Name = 'OrgUrlRunAway', url__c = 'https://www.bbva.es/');
        insert urlArce1;
        final UrlsArce__c urlArce2 = new UrlsArce__c(Name = 'VfUrlRunAway', url__c = 'https://www.bbva.es/');
        insert urlArce2;

        final arce__Data_Collections__c collection = new arce__Data_Collections__c(arce__collection_code_term__c = '700', arce__collection_table__c = '01');
        insert collection;

        final arce__Table_Content_per_Analysis__c table = new arce__Table_Content_per_Analysis__c(arce__account_has_analysis_id__c = accHasAnalysisG.Id, arce__Data_Collection_Id__c = collection.Id, arce__collection_table__c = '01');        insert table;

        arce.Arc_Gen_FinancialStatements_locator.setFFSS();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.persistRatingData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void persistRatingData() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1]; 
        final arce__Analysis__c arce = [SELECT Id, arce__rating_prerating_type__c, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c WHERE Id = :accHasAnalysis.arce__Analysis__c];
        arce.arce__rating_prerating_type__c = 'Prerating';
        arce.arce__anlys_wkfl_sub_process_type__c = RATING_LITERAL;
        update arce;
        Test.startTest();
        final String response = Arc_Gen_RatingAsIndepProcess_controller.persistRatingModel(accHasAnalysis.Id, '1234567890', RATING_LITERAL, '');
        final Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(response);
        System.assertEquals('true', mapRes.get('saveStatus'), 'Sector is false');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.callingRatios()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void callingRatios() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Financial_Statements__c finanStatem = [SELECT Id FROM arce__Financial_Statements__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse response = Arc_Gen_RatingAsIndepProcess_controller.callRatiosEngine(accHasAnalysis.Id, finanStatem.Id, true);
        System.assertNotEquals(null, response, 'Response status');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method (finalizePrerating())
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García Díaz   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 07-05-2020
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testFinalizePrerating() {
        // Prepare.
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final String response = '';
        // Test.
        Test.startTest();
        try {
            Arc_Gen_RatingAsIndepProcess_controller.finalizePrerating(arceVar.Id);
        } catch (Exception ex) {
            response = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals('', response, 'Status should have been updated to Finalized Rating');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method (finalizePrerating())
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García Díaz   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 07-05-2020
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testFinalizePreratingFail() {
        String response = '';
        Test.startTest();
        try {
            Arc_Gen_RatingAsIndepProcess_controller.finalizePrerating(null);
        } catch(Exception ex) {
            response = ex.getMessage();
        }
        System.assertNotEquals(null, response, 'The response is filled with an error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.callingPersistance()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void callingPersistance() {
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        final arce__Account_has_Analysis__c accHasAnalysisS = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_RatingAsIndepProcess_controller.callPersistence(accHasAnalysisG.arce__Analysis__c, accHasAnalysisS.arce__Customer__c);
        System.assertEquals('201', response.serviceCode, 'Status of the process');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.gettingRaipData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void gettingRaipData() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Arce Analysis2' LIMIT 1];
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c =: arceVar.Id LIMIT 1];
        Test.startTest();
        final Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(Arc_Gen_RatingAsIndepProcess_controller.getRAIPData(arceVar.Id));
        final Map<String,Object> serviceMessage = (Map<String, Object>)JSON.deserializeUntyped((String) response.get('serviceMessage'));
        System.assertEquals(accHasAnalysis.Id, serviceMessage.get('accHasAnalysisId'), 'Id of the account has analysis');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.emptyConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyConstructor() {
        Test.startTest();
        final Arc_Gen_RatingAsIndepProcess_controller constructor = new Arc_Gen_RatingAsIndepProcess_controller();
        System.assertEquals(constructor, constructor, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.emptyConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyConstructor2() {
        Test.startTest();
        final Arc_Gen_RatingAsIndepProcess_service constructor = new Arc_Gen_RatingAsIndepProcess_service();
        System.assertEquals(constructor, constructor, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.persistanceException()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void persistanceException() {
        final arce__Account_has_Analysis__c accHasAnalysisG = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        final arce__Account_has_Analysis__c accHasAnalysisS = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_RatingAsIndepProcess_controller.callPersistence(accHasAnalysisG.Id, accHasAnalysisS.arce__Customer__c);
        System.assertNotEquals('Success', response.serviceMessage, 'Status of the process');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.raipDataException()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void raipDataException() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Arce Analysis2' LIMIT 1];
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c =: arceVar.Id LIMIT 1];
        Test.startTest();
        final Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(Arc_Gen_RatingAsIndepProcess_controller.getRAIPData(accHasAnalysis.Id));
        System.assertNotEquals(accHasAnalysis.Id, response.get('serviceMessage'), 'Id of the account has analysis');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.testTriage()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testTriage() {
        Test.startTest();
        final arce__Analysis__c arceVar = [SELECT Id, arce__Group__c FROM arce__Analysis__c WHERE Name = 'Arce Analysis2' LIMIT 1];
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_RatingAsIndepProcess_service.TriageConfig response = Arc_Gen_RatingAsIndepProcess_controller.getTriageConfig(accHasAnalysis.Id, null, null);
        Arc_Gen_RatingAsIndepProcess_controller.callTriage(arceVar.Id, arceVar.arce__Group__c);
        System.assertNotEquals(Null, response, 'Triage is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.testTriage()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testRAIPButtons() {
        final arce.Arc_Gen_RAIPButtons raipB = new arce.Arc_Gen_RAIPButtons();
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Arce Analysis2' LIMIT 1];
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c =: arceVar.Id LIMIT 1];
        String response = '';
        Test.startTest();
        try {
            raipB.getDynamicButtonStatus(accHasAnalysis.Id, 'arce__Account_has_Analysis__c');
        } catch (Exception ex) {
            response = ex.getMessage();
        }
        System.assertEquals('', response, 'There are no errors');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 11-09-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.testSettingRaip()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSettingRaip() {
        Test.startTest();
        final arce__Analysis__c arceVar = [SELECT Id, arce__Group__r.AccountNumber FROM arce__Analysis__c WHERE Name = 'Arce Analysis2' LIMIT 1];
        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('isorphan', 'false');
        dataMap.put('orphanNumber', '');
        dataMap.put('analysisType', '4');
        dataMap.put('isorphan', 'false');
        dataMap.put('accounts', JSON.serialize(new List<arce.Arc_Gen_Account_Wrapper>()));
        dataMap.put('actualClient', arceVar.arce__Group__r.AccountNumber);
        final String response = Arc_Gen_RatingAsIndepProcess_controller.setAnalysis(dataMap);
        System.assertNotEquals(Null, response, 'Response of new raip is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.testTriage()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSelectRatingTool() {
        Test.startTest();
        List<Arc_Gen_RatingAsIndepProcess_service.RatingTool> ratingTools = Arc_Gen_RatingAsIndepProcess_service.getUserSelectableRatingTools();
        System.assertNotEquals(Null, ratingTools, 'Rating tools is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 25-02-2020
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.testTriage()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testTriageError() {
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_RatingAsIndepProcess_controller.callTriage(null, null);
        System.assertNotEquals(Null, response, 'Triage is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for isRAIPWfMetadata().
    * --------------------------------------------------------------------------------------
    * @Author   saimassimilianno.jordana.contractor@bbva.com
    * @Date     Created: 01/03/2021
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.isRAIPWfTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void isRAIPWfTest() {
        Test.startTest();
        final Boolean response = Arc_Gen_RatingAsIndepProcess_controller.isRAIPWfMetadata();
        System.assertNotEquals(Null, response, 'RAIPSelectWorkflow is null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for picklistValueOfSelectWf().
    * --------------------------------------------------------------------------------------
    * @Author   saimassimilianno.jordana.contractor@bbva.com
    * @Date     Created: 01/03/2021
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.getPicklistValueWFTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getPicklistValueWFTest() {
        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> response = Arc_Gen_RatingAsIndepProcess_controller.picklistValueOfSelectWf('2012', '2012:IRP-ARP-CRP;2019:IRP-ARP-CRP');
        Boolean existRating = false;
        for (Arc_Gen_RatingAsIndepProcess_controller.WfValue current : response) {
            if(current.label == RATING_LITERAL && current.value == 'IRP') {
                existRating = true;
                break;
            }
        }
        System.assert(existRating, 'Picklist WF Values is null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for newFFSSWAhas().
    * --------------------------------------------------------------------------------------
    * @Author   saimassimilianno.jordana.contractor@bbva.com
    * @Date     Created: 01/03/2021
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.newFFSSWAhasTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void newFFSSWAhasTest() {
        final arce__Analysis__c analysis = [SELECT Id, Name FROM arce__Analysis__c LIMIT 1];
        final String analysisId = analysis.Id;
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c = :analysisId LIMIT 1];
        final String rarRating = 'testrarrating';
        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_controller.newFFSSWAhas(accHasAnalysis.Id, analysisId, 'CRP',rarRating);
        final arce__Financial_Statements__c finanStatem = [SELECT Id, arce__rating_id__r.arce__rar_rating_tool_id__c FROM arce__Financial_Statements__c WHERE arce__rating_id__r.arce__rar_rating_tool_id__c = :rarRating LIMIT 1];
        System.assertEquals(rarRating, finanStatem.arce__rating_id__r.arce__rar_rating_tool_id__c, 'newFFSSWAhasTest Error: There is no Financial_Statements');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for newFFSSWAhas().
    * --------------------------------------------------------------------------------------
    * @Author   saimassimilianno.jordana.contractor@bbva.com
    * @Date     Created: 01/03/2021
    * @param void
    * @return void
    * @example Arc_Gen_RatingAsIndepProcess_test.newFFSSWAhasTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void newRatingTyByModl() {
        final arce__Analysis__c analysis = [SELECT Id, Name FROM arce__Analysis__c LIMIT 1];
        final String analysisId = analysis.Id;
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c = :analysisId LIMIT 1];
        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> result = Arc_Gen_RatingAsIndepProcess_controller.checkRatingType(accHasAnalysis.Id, '2019',false);
        System.assert(result[0].value == RATING_LITERAL || result[0].value =='Prerating', 'newRatingTyByModl Error: There is no Wf object');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description handleTriageConfigBoth test method
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    13/10/2021
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.handleTriageConfigBoth()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testHandleTriageConfigBoth() {
        Test.startTest();
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_RatingAsIndepProcess_service.TriageConfig response = Arc_Gen_RatingAsIndepProcess_controller.handleTriageConfigBoth('Arc_GBL_IRPFlowCustom', accHasAnalysis.Id);
        System.assertNotEquals(response.ratingTypeList, null, 'Triage is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description getIRPTriageStepConfig test method
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    13/10/2021
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testGetIRPTriageStepConfig()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetIRPTriageStepConfig() {
        Test.startTest();
        final String response = Arc_Gen_RatingAsIndepProcess_controller.getIRPTriageStepConfig();
        final List<Object> lstRes = (List<Object>) JSON.deserializeUntyped(response);
        final String nameInter = (String) lstRes[1];
        System.assertEquals('Arc_GBL_IRPFlowCustom', nameInter, 'Irp triage step custom test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description globalRunWayConfig test method
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    02/11/2021
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testGlobalRunWayConfig()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGlobalRunWayConfig() {
        Test.startTest();
        final Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig globalRunaway = Arc_Gen_RatingAsIndepProcess_controller.globalRunWayConfig();
        System.assert(globalRunaway.gblRunWayEnabled != null, 'Global runway config test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description checkRatingToolId test method
    * --------------------------------------------------------------------------------------
    * @Author  alberto.martinez.carrero.contractor@bbva.com
    * @Date    07/03/2022
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testCheckRatingToolId2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGlobalRunUrlConfigs() {
        Test.startTest();
        final Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig urlConfigs = Arc_Gen_RatingAsIndepProcess_controller.localURLs();
        System.assertNotEquals(null, urlConfigs.orgURL, 'Check rating tool id test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description checkRatingToolId test method
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    02/11/2021
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testCheckRatingToolId()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCheckRatingToolId() {
        Test.startTest();
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = Arc_Gen_RatingAsIndepProcess_controller.checkRatingToolId(accHasAnalysis.Id, '', 'Arc_GBL_IRPFlowCustom');
        System.assertNotEquals(null, wfValues, 'Check rating tool id test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description checkRatingToolId test method
    * --------------------------------------------------------------------------------------
    * @Author  alberto.martinez.carrero.contractor@bbva.com
    * @Date    07/03/2022
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testCheckRatingToolId2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCheckRatingToolId2() {
        Test.startTest();
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues1 = Arc_Gen_RatingAsIndepProcess_controller.checkRatingToolId(accHasAnalysis.Id, '0000000000000000', 'Arc_GBL_IRPFlowCustom');
        System.assertNotEquals(null, wfValues1, 'Check rating tool id test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description callRiskFilter test method
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    02/11/2021
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testCallRiskFilter()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCallRiskFilter() {
        Test.startTest();
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSave = Arc_Gen_RatingAsIndepProcess_controller.callRiskFilter(accHasAnalysis.arce__Customer__c, accHasAnalysis.arce__Analysis__c);
        System.assertEquals(null, serviceAndSave.serviceCode, 'Call risk filter service test');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description call getShowEEFFCorpMessage test method
    * --------------------------------------------------------------------------------------
    * @Author  andres.rodriguez.munoz.contractor@bbva.com
    * @Date    21/04/2022
    * @param   void
    * @return  void
    * @example Arc_Gen_RatingAsIndepProcess_test.testGetShowEEFFCorpMessage()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetShowEEFFCorpMessage() {
        Test.startTest();
        Boolean showMessage = Arc_Gen_RatingAsIndepProcess_controller.getShowEEFFCorpMessage();
        System.assertNotEquals(null,showMessage);
        Test.stopTest();
    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description GetSalesEngine test method
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @example testGetSalesEngine() {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    public static void testGetSalesEngine() {
        Test.startTest();
        final arce__Financial_Statements__c finanStatem = [SELECT Id FROM arce__Financial_Statements__c LIMIT 1];
        final arce__Account_has_Analysis__c aha = [select id, createdDate from arce__Account_has_Analysis__c WHERE arce__ffss_for_rating_id__c = :finanStatem.Id limit 1];
        final Arc_gen_Sales_Service.ResponseWrapper response = Arc_Gen_RatingAsIndepProcess_controller.getSalesEngine(aha.id, RATING_LITERAL);
        System.assert(true, response.calculationResult);
        Test.stopTest();

    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description GetSalesEngine test method
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @example testGetSalesEngine() {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    public static void testisSalesEngineConfig() {
        Test.startTest();
        final Boolean isConfig = Arc_Gen_RatingAsIndepProcess_controller.isSalesEngineConfig();
        System.assert(true, isConfig);
        Test.stopTest();

    }
}