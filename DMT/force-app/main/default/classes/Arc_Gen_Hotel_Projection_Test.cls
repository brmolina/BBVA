/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Hotel_Projection_Test
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-10-21
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description test class for Hotel Projection Table classes
* ------------------------------------------------------------------------------------------------
* @Changes
* |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
*             Class Creation
* |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
*             Update test coverage
* |2020-11-12 mariohumberto.ramirez.contractor@bbva.com
*             update test class
* |2020-11-13 moises.martinez.dominguez.contractor@bbva.com
*             add record for Analysis Date or Period and Analysis Category
* |2020-11-13 juanmanuel.perez.ortiz.contractor@bbva.com
*             update test class
* |2020-11-30 moises.martinez.dominguez.contractor@bbva.com
*             add methods for coverage for tables date and category
*-------------------------------------------------------------------------------------------------
**/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public without sharing class Arc_Gen_Hotel_Projection_Test {
    /*
        @Description generic assert message for empty constructor
    */
    private static final String CONTRUCTOR_MESS = 'Test to empty constructor';
    /*
        @Description generic assert message for SUCCESS
    */
    private static final String SUCCESS = 'Test Success';
    /*
        @Description setup method
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newArce = arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert newArce;

        final arce__Account_has_Analysis__c acchasAn = arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        acchasAn.arce__group_asset_header_type__c = '2';
        insert acchasAn;

        final List<arce__hotel_projection__c> hotelLts = new List<arce__hotel_projection__c>();
        for (integer i = 1; i <= 6; i++) {
            arce__hotel_projection__c hotel = new arce__hotel_projection__c();
            hotel.arce__account_has_analysis_id__c = acchasAn.Id;
            hotel.arce__gf_const_proj_year_number_type__c = i == 6 ? 'YEAR > 5' : 'YEAR ' + i;
            hotel.arce__gf_hotel_avg_daily_rate_amount__c = 0;
            hotel.arce__gf_hotel_occupancy_per__c = 0;
            hotel.arce__gf_rev_per_avail_room_amount__c = 0;
            hotel.arce__gf_htl_gs_oper_profit_amount__c = 0;
            hotel.arce__gf_debt_available_funds_amount__c = 0;
            hotel.arce__gf_interest_expense_amount__c = 0;
            hotel.arce__gf_loan_funded_amount__c = 0;
            hotel.arce__gf_debt_svc_covrg_ratio_number__c = 0;
            hotel.arce__gf_hotel_breakeven_occup_per__c = 0;
            hotelLts.add(hotel);
        }
        insert hotelLts;

        arce__contracts_and_appraisals__c dummyRecordAppr = new arce__contracts_and_appraisals__c();
            dummyRecordAppr.arce__gf_hotel_name__c = 'Dummy Hotel Currency and Units';
            dummyRecordAppr.CurrencyIsoCode = 'EUR';
            dummyRecordAppr.arce__magnitude_unit_type__c = '3';
            dummyRecordAppr.arce__account_has_analysis_id__c = acchasAn.Id;
            insert dummyRecordAppr;

        final arce__hotel_analysis_date_period__c dateRecord = new arce__hotel_analysis_date_period__c();
            dateRecord.Name = 'Dummy Hotel analysisDate Hotel Currency';
            dateRecord.CurrencyIsoCode = 'EUR';
            dateRecord.arce__magnitude_unit_type__c = '3';
            dateRecord.arce__account_has_analysis_id__c = acchasAn.Id;
            insert dateRecord;

        final arce__hotel_analysis_category__c categoryRecord = new arce__hotel_analysis_category__c();
            categoryRecord.Name = 'Dummy Hotel analysisCategory Hotel Currency';
            categoryRecord.CurrencyIsoCode = 'EUR';
            categoryRecord.arce__magnitude_unit_type__c = '3';
            categoryRecord.arce__account_has_analysis_id__c = acchasAn.Id;
            insert categoryRecord;

        }
    /*
        @Description test method
    */
    @isTest static void testgetTableDataFill() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_Hotel_Projection_Helper.getUnit('1');
        Arc_Gen_Hotel_Projection_Helper.getUnit('2');
        Arc_Gen_Hotel_Projection_Helper.getUnit('3');
        final String hotelWrapper = Arc_Gen_Hotel_Projection_Controller.getTableData(accHasAnls.Id);
        delete Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(accHasAnls.Id);
        Arc_Gen_Hotel_Projection_Service.insertTableRecords(accHasAnls.Id);
        system.assertEquals(String.isEmpty(hotelWrapper), false, 'There are info to build the table');
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetTableDataEmpty() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        delete Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(accHasAnls.Id);
        try {
            Arc_Gen_Hotel_Projection_Controller.getTableData(accHasAnls.Id);
        } catch (Exception e) {
            system.assertEquals(String.isEmpty(e.getMessage()), false, 'There are not info to build the table');
        }
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorCtr() {
        Test.startTest();
        final Arc_Gen_Hotel_Projection_Controller controller = new Arc_Gen_Hotel_Projection_Controller();
        system.assertEquals(controller, controller, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorSer() {
        Test.startTest();
        final Arc_Gen_Hotel_Projection_Service service = new Arc_Gen_Hotel_Projection_Service();
        system.assertEquals(service, service, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorHelp() {
        Test.startTest();
        final Arc_Gen_Hotel_Projection_Helper helper = new Arc_Gen_Hotel_Projection_Helper();
        system.assertEquals(helper, helper, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorLoca() {
        Test.startTest();
        final Arc_Gen_Hotel_Projection_Locator locator = new Arc_Gen_Hotel_Projection_Locator();
        system.assertEquals(locator, locator, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testValEmptyKo() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        List<arce__hotel_projection__c> hotelLts = Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(accHasAnls.Id);
        hotelLts[0].arce__gf_rev_per_avail_room_amount__c = null;  // NOSONAR
        update hotelLts;
        Test.startTest();
        final String wrapperVal = Arc_Gen_ValidateHotelProjInfo_Service.beforeSaveData(hotelLts);
        system.assertEquals(wrapperVal.contains('false'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testValBadEntrieKo() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        List<arce__hotel_projection__c> hotelLts = Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(accHasAnls.Id);
        hotelLts[0].arce__gf_rev_per_avail_room_amount__c = -10;
        update hotelLts;
        Test.startTest();
        final String wrapperVal = Arc_Gen_ValidateHotelProjInfo_Service.beforeSaveData(hotelLts);
        system.assertEquals(wrapperVal.contains('false'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testValpercentKo() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        List<arce__hotel_projection__c> hotelLts = Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(accHasAnls.Id);
        hotelLts[0].arce__gf_hotel_occupancy_per__c = 200;
        update hotelLts;
        Test.startTest();
        final String wrapperVal = Arc_Gen_ValidateHotelProjInfo_Service.beforeSaveData(hotelLts);
        system.assertEquals(wrapperVal.contains('false'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateCurrency() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, 'EUR', 'currency','Arc_Gen_HotelProjSaveCombo_Service');
        final String saveResult = Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, 'EUR', 'currency','Arc_Gen_Appraisals_SaveCombo_Service');
        system.assertEquals(saveResult.contains('null'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateUnit() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, '1', 'unit','Arc_Gen_HotelProjSaveCombo_Service');
        final String saveResult = Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, '1', 'unit','Arc_Gen_Appraisals_SaveCombo_Service');
        system.assertEquals(saveResult.contains('null'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateKO() {
        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse saveResult = Arc_Gen_Hotel_Projection_Locator.updateHotelProj(new List<arce__hotel_projection__c>());
        system.assertEquals(saveResult.saveStatus, 'true', SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorRelTable() {
        Test.startTest();
        final Arc_Gen_RelatedTableManager_Ctr controller = new Arc_Gen_RelatedTableManager_Ctr();
        system.assertEquals(controller, controller, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorRelTableServ() {
        Test.startTest();
        final Arc_Gen_RelatedTableManager_Service service = new Arc_Gen_RelatedTableManager_Service();
        system.assertEquals(service, service, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorContractsAppraisals() {
        Test.startTest();
        final Arc_Gen_Contracts_Appraisals_Locator locator = new Arc_Gen_Contracts_Appraisals_Locator();
        system.assertEquals(locator, locator, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorContractsAppraisals2() {
        Test.startTest();
        final Arc_Gen_Contracts_Appraisals_Controller locator = new Arc_Gen_Contracts_Appraisals_Controller();
        system.assertEquals(locator, locator, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetTableDataContractsAppraisals() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String appraisalsWrapper = Arc_Gen_Contracts_Appraisals_Controller.getTableData(accHasAnls.Id);
        Arc_Gen_Contracts_Appraisals_Service.insertTableRecord(accHasAnls.Id);
        system.assertEquals(String.isEmpty(appraisalsWrapper), false, 'There are info to build the table');
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetCombosValues() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_RelatedTableManager_Ctr.getCombosValues(accHasAnls.Id,'Contracts_Appraisals');
        system.assertEquals(response.contains('true'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetTableDataAnalysisDate() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String dateWrapper = Arc_Gen_Analysis_Date_Controller.getTableData(accHasAnls.Id);
        Arc_Gen_Analysis_Date_Service.insertTableRecord(accHasAnls.Id);
        system.assertEquals(String.isEmpty(dateWrapper), false, 'There are info to build the table');
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateDateCurrency() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_Hotel_Projection_Helper.getUnit('1');
        Arc_Gen_Hotel_Projection_Helper.getUnit('2');
        Arc_Gen_Hotel_Projection_Helper.getUnit('3');
        final String saveResult = Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, 'EUR', 'currency','Arc_Gen_Date_SaveCombo_Service');
        system.assertEquals(saveResult.contains('null'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateDateUnit() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String saveResult = Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, '1', 'unit','Arc_Gen_Date_SaveCombo_Service');
        system.assertEquals(saveResult.contains('null'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorAnalysisDate() {
        Test.startTest();
        final Arc_Gen_Analysis_Date_Locator locatorDate = new Arc_Gen_Analysis_Date_Locator();
        system.assertEquals(locatorDate, locatorDate, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorAnalysisDate2() {
        Test.startTest();
        final Arc_Gen_Analysis_Date_Controller ctrDate = new Arc_Gen_Analysis_Date_Controller();
        system.assertEquals(ctrDate, ctrDate, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorAnalysisDate3() {
        Test.startTest();
        final Arc_Gen_Analysis_Date_Service serviceDate = new Arc_Gen_Analysis_Date_Service();
        system.assertEquals(serviceDate, serviceDate, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetDateCombosValues() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_RelatedTableManager_Ctr.getCombosValues(accHasAnls.Id,'Analysis_Date');
        system.assertEquals(response.contains('true'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateCategoryCurrency() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_Hotel_Projection_Helper.getUnit('1');
        Arc_Gen_Hotel_Projection_Helper.getUnit('2');
        Arc_Gen_Hotel_Projection_Helper.getUnit('3');
        final String saveResult = Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, 'EUR', 'currency','Arc_Gen_Category_SaveCombo_Service');
        system.assertEquals(saveResult.contains('null'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void updateCategoryUnit() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String saveResult = Arc_Gen_RelatedTableManager_Ctr.saveCombos(accHasAnls.Id, '1', 'unit','Arc_Gen_Category_SaveCombo_Service');
        system.assertEquals(saveResult.contains('null'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorAnalysisCategory() {
        Test.startTest();
        final Arc_Gen_Analysis_Category_Locator locatorCategory = new Arc_Gen_Analysis_Category_Locator();
        system.assertEquals(locatorCategory, locatorCategory, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorAnalysisCategory2() {
        Test.startTest();
        final Arc_Gen_Analysis_Category_Controller ctrCategory = new Arc_Gen_Analysis_Category_Controller();
        system.assertEquals(ctrCategory, ctrCategory, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testConstuctorAnalysisCategory3() {
        Test.startTest();
        final Arc_Gen_Analysis_Category_Service serviceCategory = new Arc_Gen_Analysis_Category_Service();
        system.assertEquals(serviceCategory, serviceCategory, CONTRUCTOR_MESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetTableDataAnalysisCategory() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String categoryWrapper = Arc_Gen_Analysis_Category_Controller.getTableData(accHasAnls.Id);
        Arc_Gen_Analysis_Category_Service.insertTableRecord(accHasAnls.Id);
        system.assertEquals(String.isEmpty(categoryWrapper), false, 'There are info to build the table');
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testgetCategoryCombosValues() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_RelatedTableManager_Ctr.getCombosValues(accHasAnls.Id,'Analysis_Category');
        system.assertEquals(response.contains('true'), true, SUCCESS);
        Test.stopTest();
    }
}