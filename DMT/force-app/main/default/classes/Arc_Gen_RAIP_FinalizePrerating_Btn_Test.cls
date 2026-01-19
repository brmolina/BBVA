/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_test
* @Author   alberto.martinez.carrero.tech@bbva.com
* @Date     Created: 2020-01-13
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_RatingAsIndepProcess_controller, Arc_Gen_RatingAsIndepProcess_service, Arc_Gen_RAIPButtons
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-13 alberto.martinez.carrero.tech@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_RAIP_FinalizePrerating_Btn_Test {
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

        final arce__Table_Content_per_Analysis__c table = new arce__Table_Content_per_Analysis__c(arce__account_has_analysis_id__c = accHasAnalysisG.Id, arce__Data_Collection_Id__c = collection.Id, arce__collection_table__c = '01');
        insert table;

        arce.Arc_Gen_FinancialStatements_locator.setFFSS();
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
            Arc_Gen_RAIP_FinalizePrerating_Btn_Ctrl.finalizePrerating(arceVar.Id);
        } catch (Exception ex) {
            response = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals('', response, 'Status should have been updated to Finalized Rating');
    }
}