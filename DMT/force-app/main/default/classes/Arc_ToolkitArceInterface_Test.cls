/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_ToolkitArceInterface_Test
* @Author   Santiago Vidal Carretero
* @Date     Created: 10/09/2020
* @Group    GDT
* -----------------------------------------------------------------------------------------------
* @Description Test class for the apex class Arc_ToolkitArceInterface
* -----------------------------------------------------------------------------------------------
* @Changes
*
* -----------------------------------------------------------------------------------------------
*/
@IsTest
private class Arc_ToolkitArceInterface_Test {
    /**
    * @Description: String with name of callable class
    */
    private static String callableClass = 'Arc_ToolkitArceInterface';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
    /**

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void testSetup() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();

        
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,GROUP_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Financial_Statements__c ffss1 = new arce__Financial_Statements__c(arce__financial_statement_id__c = 'dummyFFSS1');
        ffss1.arce__financial_statement_end_date__c = date.today();
        ffss1.arce__ffss_submitted_type__c = '1';
        insert ffss1;
        final arce__Financial_Statements__c ffss2 = new arce__Financial_Statements__c(arce__financial_statement_id__c = 'dummyFFSS2');
        ffss2.arce__financial_statement_end_date__c = date.today();
        ffss2.arce__ffss_submitted_type__c = '1';
        insert ffss2;
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__analysis_customer_relation_type__c = '01';
        newArce.arce__Stage__c = '3';
        newArce.arce__rating_prerating_type__c = 'Rating';
        newArce.arce__wf_status_id__c = '13';
        insert newArce;

        
        // Main Client
        final Account mainClient = new Account();
        mainClient.Name = 'Test Client';
        mainClient.Phone = '646171717';
        mainClient.DES_Revenue_Update_Engloba__c = '20180912';
		mainClient.DES_Country_Client__c = 'ES';
        mainClient.account_client__c = 'N';
        mainClient.DES_Group_Code__c = 'A000000001';
        insert mainClient;
        // Client
        final Account client = new Account();
        client.Name = 'Test Client';
        client.Phone = '646171717';
        client.DES_Revenue_Update_Engloba__c = '20180912';
		client.DES_Country_Client__c = 'ES';
        client.account_client__c = 'N';
        client.DES_Main_Parent__c = mainClient.Id;
        client.DES_Entity_Hierarchy__c = 'S'; // Value 'S' so field formula checkbox business_group_header_type__c equals true 
        insert client;
        // Local Client
        final Local_Client__c localClient =new Local_Client__c(Name = 'TestAcct',Cib_Client__c = client.Id, Alpha_code__c = 'ES' + Integer.valueof((Math.random() * 100000)));
        insert localClient;

        // Main Client
        final Account mainClient2 = new Account();
        mainClient2.Name = 'Test Client';
        mainClient2.Phone = '646171718';
        mainClient2.DES_Revenue_Update_Engloba__c = '20180913';
		mainClient2.DES_Country_Client__c = 'ES';
        mainClient2.account_client__c = 'N';
        mainClient2.DES_Group_Code__c = 'A000000002';
        insert mainClient2;
        // Client
        final Account client2 = new Account();
        client2.Name = 'Test Client';
        client2.Phone = '646171718';
        client2.DES_Revenue_Update_Engloba__c = '20180913';
		client2.DES_Country_Client__c = 'ES';
        client2.account_client__c = 'N';
        client2.DES_Main_Parent__c = mainClient2.Id;
        client2.DES_Entity_Hierarchy__c = 'S'; // Value 'S' so field formula checkbox business_group_header_type__c equals true 
        insert client2;
        // Local Client
        final Local_Client__c localClient2 =new Local_Client__c(Name = 'TestAcct2',Cib_Client__c = client2.Id, Alpha_code__c = 'ES' + Integer.valueof((Math.random() * 100000)));
        insert localClient2;

        // Account Has Analysis 
        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__group_asset_header_type__c = '1';
        newAnalysis.arce__magnitude_unit_type__c = '1';
        newAnalysis.arce__ffss_for_rating_id__c = ffss1.Id;
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__RAR_rating_tool_id__c = '2012P1IRP';
        newAnalysis.DES_Local_Client__c = localClient.Id;
        insert newAnalysis;
        final arce__Account_has_Analysis__c newAnalysis2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        newAnalysis2.arce__group_asset_header_type__c = '2';
        newAnalysis2.arce__magnitude_unit_type__c = '1';
        newAnalysis2.arce__ffss_for_rating_id__c = ffss2.Id;
        newAnalysis2.arce__InReview__c = true;
        newAnalysis2.arce__RAR_rating_tool_id__c = '2021RTC_GEN';
        newAnalysis2.DES_Local_Client__c = localClient2.Id;
        insert newAnalysis2;

        final arce__Activity_Split__c activitySplit = new arce__Activity_Split__c();
        activitySplit.arce__sector_id__c = 'D';
        activitySplit.arce__Subsector_id__c = 'DF';
        activitySplit.arce__gf_company_economic_actvy_id__c = 'DBB';
        activitySplit.arce__gf_subactivity_id__c = '842';
        activitySplit.arce__Template_type__c = '10';
        activitySplit.arce__gf_subindustry_weight_per__c = 25;
        activitySplit.arce__gf_activity_split_per_type__c = '1';
        activitySplit.arce__Account_has_Analysis__c = newAnalysis.Id;
        activitySplit.arce__gf_company_economic_actvy_id_2012__c = 'DAA';
        activitySplit.arce__Subsector_id_2012__c = 'DA';
        insert activitySplit;

        final arce__Activity_Split_2012__c activitySplit2012 = new arce__Activity_Split_2012__c();
        activitySplit2012.arce__sector_id__c = 'A';
        activitySplit2012.arce__Subsector_id__c = 'AD';
        activitySplit2012.arce__gf_company_economic_actvy_id__c = 'AAB';
        activitySplit2012.arce__gf_subactivity_id__c = 'AAB2';
        activitySplit2012.arce__Template_type__c = '102';
        activitySplit2012.arce__gf_subindustry_weight_per__c = 97;
        activitySplit2012.arce__gf_activity_split_per_type__c = '1';
        activitySplit2012.arce__Country_2012__c = 'ES';
        activitySplit2012.arce__Account_has_Analysis__c = newAnalysis2.Id;
        insert activitySplit2012;

        // Data Collection
        final arce__Data_Collections__c dataCol = new arce__Data_Collections__c();
        dataCol.Name = 'dummyColeccion';
        dataCol.arce__collection_table__c = '02';
        dataCol.arce__collection_code_term__c = '700';
        insert dataCol;

        // Table Content Analysis
        final arce__Table_Content_per_Analysis__c tableContAnalysis = new arce__Table_Content_per_Analysis__c();
        tableContAnalysis.arce__account_has_analysis_id__c = newAnalysis.Id;
        tableContAnalysis.arce__Data_Collection_Id__c = dataCol.Id;
        tableContAnalysis.arce__table_content_year__c = 'year';
        tableContAnalysis.arce__Unit_Type__c = 'UNITS';
        tableContAnalysis.arce__table_content_value__c = Double.valueOf('14000000');
        tableContAnalysis.arce__base_amount__c = Double.valueOf('14000000');
        tableContAnalysis.arce__original_amount__c = Double.valueOf('14000000');
        tableContAnalysis.arce__original_currency__c = 'EUR';
        tableContAnalysis.arce__collection_table__c = '02';
        tableContAnalysis.CurrencyIsoCode = 'EUR';
        tableContAnalysis.arce__table_content_parent_code_id__c = 'dummyFFSS1';
        insert tableContAnalysis;

        // Geographic Split
        final arce__Geographic_Split__c geographicSplit = new arce__Geographic_Split__c();
        geographicSplit.arce__Country__c = 'ES';
        geographicSplit.arce__gf_geography_weight_per__c = 40;
        geographicSplit.arce__Activity_Split__c = activitySplit.Id;
        geographicSplit.arce__gf_geography_split_per_type__c = '1';
        insert geographicSplit;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getClientArceRatingId 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetClientArceRatingId() {
        String result = '';
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'].Id;
        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => 'A000000001',
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        result = (String) callable.call('getClientArceRatingId', parameters);				

        System.assertEquals(ahaId, result, 'The ahaId returned is not the expected value');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getProspectArceRatingId 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetProspectArceRatingId() {
        String result = '';
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'].Id;
        final String mainParentId= [SELECT Id FROM Account WHERE DES_Group_Code__c = 'A000000001'].Id;
        final arce__Analysis__c arce = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arce.arce__rating_prerating_type__c = 'Prerating';
        update arce;

        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'prospectId' => mainParentId,
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        result = (String) callable.call('getProspectArceRatingId', parameters);
       
        System.assertEquals(ahaId, result, 'The ahaId returned is not the expected value');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getSectorization 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetSectorization2021() {
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'].Id;

        final Map<String, Object> parameters = new Map<String, Object>{
            'ratingId' => ahaId
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> sectorizationResults = (List<Map<String, Object>>) callable.call('getSectorization', parameters);
				
        System.assertNotEquals(null, sectorizationResults, 'Result should not be null');
        System.assert(sectorizationResults.size() > 0, 'Results should not be empty');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getSectorization 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetSectorization2012() {
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'].Id;

        final Map<String, Object> parameters = new Map<String, Object>{
            'ratingId' => ahaId
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> sectorizationResults = (List<Map<String, Object>>) callable.call('getSectorization', parameters);
				
        System.assertNotEquals(null, sectorizationResults, 'Result should not be null');
        System.assert(sectorizationResults.size() > 0, 'Results should not be empty');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getSubsector 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetSubsector2021() {
        String result = '';
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'].Id;

        final Map<String, Object> parameters = new Map<String, Object>{
            'ratingId' => ahaId
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        result = (String) callable.call('getSubsector', parameters);
				
        System.assertNotEquals('', result, 'Result should not be empty string');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getSubsector 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetSubsector2012() {
        String result = '';
        String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'].Id;

        Map<String, Object> parameters = new Map<String, Object>{
            'ratingId' => ahaId
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        result = (String) callable.call('getSubsector', parameters);
				
        System.assertNotEquals('', result, 'Result should not be empty string');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getCapex
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetCapex() {
        final String dateStr = String.valueOf(Date.today().year());
        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => 'A000000001',
            'year' => dateStr,
            'codeTerm' => new List<String>{'700', '712'}
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> capexResults = (List<Map<String, Object>>) callable.call('getCapex', parameters);
				
        System.assertNotEquals(null, capexResults, 'Result should not be null');
        System.assert(capexResults.size() > 0, 'Results should not be empty');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getClientGeographies
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetClientGeographies() {
        final String dateStr = String.valueOf(Date.today().year());
        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => 'A000000001',
            'year' => dateStr
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> clientGeoResult = (List<Map<String, Object>>) callable.call('getClientGeographies', parameters);
		
        System.assertNotEquals(null, clientGeoResult, 'Result should not be null');
        System.assert(clientGeoResult.size() > 0, 'Results should not be empty');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getProspectGeographies
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetProspectGeographies() {
        final String mainParentId= [SELECT Id FROM Account WHERE DES_Group_Code__c = 'A000000001'].Id;
        final arce__Analysis__c arce = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arce.arce__rating_prerating_type__c = 'Prerating';
        update arce;
        final String dateStr = String.valueOf(Date.today().year());
        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'prospectId' => mainParentId,
            'year' => dateStr
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> prspctGeoResult = (List<Map<String, Object>>) callable.call('getProspectGeographies', parameters);
		
        System.assertNotEquals(null, prspctGeoResult, 'Result should not be null');
        System.assert(prspctGeoResult.size() > 0, 'Results should not be empty');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getTop5Activities
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetTop5Activities() {
        final String dateStr = String.valueOf(Date.today().year());
        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => 'A000000001',
            'year' => dateStr,
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> top5ActResult = (List<Map<String, Object>>) callable.call('getTop5Activities', parameters);
        
        System.assertNotEquals(null, top5ActResult, 'Result should not be null');
        System.assert(top5ActResult.size() > 0, 'Results should not be empty');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test method for Arc_ToolkitArceInterface.getTop5Activities
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     11-09-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    private static void testGetTop5Activities2012() {
        final String dateStr = String.valueOf(Date.today().year());
        final Map<String, Object> parameters = new Map<String, Object>{
            'statusId' => '13',
            'stage' => '3',
            'submittedType' => new List<String>{'1', '2'},
            'groupCode' => 'A000000002',
            'year' => dateStr,
            'ratingToolId' => new List<String>{'2012P1IRP', '2021RTC_GEN'}
        };

        Callable callable = (Callable) Type.forName(callableClass).newInstance();
        List<Map<String, Object>> top5ActResult = (List<Map<String, Object>>) callable.call('getTop5Activities', parameters);
		
        System.assertNotEquals(null, top5ActResult, 'Result should not be null');
        System.assert(top5ActResult.size() > 0, 'Results should not be empty');
    }
}