/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PDF_Projection_ctrlr_Test
* @Author   joseluis.miralles.contractor@bbva.com
* @Date     Created: 21/05/2023
* @Group    ARCE
* @Last Modified By   : joseluis.miralles.contractor@bbva.com
* @Last Modified On   : 21/05/2023
* @Description Test Class of Arc_Gen_PDF_Projection_ctrlr_Test
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
*/
@isTest
public class Arc_Gen_PDF_Projection_ctrlr_Test {
    /**
    * @Description: Parameter literal to be passed to visualforce
    */
    final static String ID_PARAM = 'ahaId';
    /**
    * @Description: Setup data for running test
    */
    @TestSetup
    static void setupData() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{ 'G000001' });

        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, groupAccount.accId);
        analysis.arce__analysis_customer_relation_type__c = '01';
        insert analysis;

        final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analysis.Id, groupAccount.accId, 's-01');
        accHasAnalysis.arce__group_asset_header_type__c = '1';
        insert accHasAnalysis;

        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        final arce__Financial_Statements__c fsWithRating = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, accHasAnalysis.Id, rating.Id, null);
        fsWithRating.arce__financial_statement_id__c = '70202017129';
        fsWithRating.arce__Order__c = '1';
        fsWithRating.arce__magnitude_unit_type__c = '1';
        fsWithRating.currencyIsoCode = 'EUR';
        insert fsWithRating;

        accHasAnalysis.arce__ffss_for_rating_id__c = fsWithRating.Id;
        update accHasAnalysis;

        final arce__Financial_Statements__c fsWithRating2 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, accHasAnalysis.Id, rating.Id, null);
        fsWithRating2.arce__financial_statement_id__c = '70202017129';
        insert fsWithRating2;

        final List<arce__Projection__c> proList = Arc_UtilitysDataTest_tst.getprojectionList(accHasAnalysis.Id);
        insert proList;
    }

    /**
    * @Description: Method to check if client data is correct
    */
    @isTest
    public static void testClientDataProjectionPage() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        final PageReference projPage_pdf = Page.Arc_Gen_PDF_Projection_DataTable_Summary;
        projPage_pdf.getParameters().put(ID_PARAM, accHasAnalysis.Id);
        Test.setCurrentPage(projPage_pdf);
        final List<Schema.PicklistEntry> values = arce__Account_has_Analysis__c.arce__group_asset_header_type__c.getDescribe().getPicklistValues();
        final Map<String, String> clientGroup = new Map<String, String>();
        for (Schema.PicklistEntry sp : values) {
            clientGroup.put(sp.getValue(), sp.getLabel());
        }
        Test.startTest();
        final Arc_Gen_PDF_Projection_Controller pageController = new Arc_Gen_PDF_Projection_Controller();
        System.assertEquals(accHasAnalysis.arce__Customer__r.Name, pageController.tableDataWrapperHeaderData.Name, 'Error getting data from aHA');
        Test.stopTest();
    }

    /**
    * @Description: Method to get Projection Data
    */
    @isTest
    public static void testGetProjectionData() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1];
        final List<arce__Projection__c> proRecord = [SELECT Id
                                                      FROM arce__Projection__c
                                                      where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c = 'Base Case'];
        final Set<String> setIds = new Set<String>();
        setIds.add(String.valueOf(accHasAnalysis.Id));
        Test.startTest();
        final List<arce__Projection__c> proList = Arc_Gen_Projection_Data.getProjectionData(accHasAnalysis.Id);
        proList.get(0).arce__Projection_Header__c = '31/12/2023';
        final List<arce__Projection__c> proListScenario = Arc_Gen_Projection_Data.getProjScenarioData(accHasAnalysis.Id, 'Base Case');
        Arc_Gen_Projection_Data.updateProjectionData(proList);
        Arc_Gen_Projection_Data.updateBaseCase(accHasAnalysis.Id, '2', 'Standard projection');
        System.assertEquals(proRecord.get(0).Id, proListScenario.get(0).Id, 'Error getting projection data');
        Test.stopTest();
    }

}