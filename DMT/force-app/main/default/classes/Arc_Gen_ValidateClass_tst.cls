/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateClass_tst
* @Author   juan.ignacion.hit.contractor@bbva.com
* @Date     Created: 2019-11-04
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for validation classes
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 juan.ignacion.hit.contractor@bbva.com
*             Class creation.
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-06 juanmanuel.perez.ortiz.contractor@bbva.com
*             Create methods for Contracts and Appraisals class
* |2020-11-16 joseluis.garcia4.contractor@bbva.com
*             Fix test.
* |2020-11-13 moises.martinez.dominguez.contractor@bbva.com
*             Create methods for Analysis Date or Period and Analysis Category class
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods,sf:ExcessiveClassLength')
@isTest
public class Arc_Gen_ValidateClass_tst {
    /**
    * --------------------------------------------------------------------------------------
    * @Description load data method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void loadData
    * --------------------------------------------------------------------------------------
    **/
    @testSetup Static void loadData() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis MB', null, groupAccount.accId);
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        insert newAnalysis;

        final arce__contracts_and_appraisals__c contractsAppraisals = new arce__contracts_and_appraisals__c(
            arce__gf_hotel_name__c = 'Hotel 1', arce__account_has_analysis_id__c = newAnalysis.Id,
            arce__appraisal_amount__c = 100, arce__last_assessed_date__c = System.today(), arce__gf_htl_ownshp_ctrct_dur_number__c = 'Six Months',
            arce__gf_current_expiration_date__c = System.today(), arce__gf_hotel_contract_type_name__c = '1'

        );

        insert contractsAppraisals;

        final arce__hotel_analysis_date_period__c analysisDate = new arce__hotel_analysis_date_period__c(
            arce__gf_period_start_date__c = System.today(),arce__gf_period_end_date__c = System.today(),
            arce__account_has_analysis_id__c = newAnalysis.Id,arce__gf_hotel_occupancy_per__c = 100,
            arce__gf_hotel_avg_daily_rate_amount__c = 250000,arce__gf_rev_per_avail_room_amount__c = 500000
        );
        insert analysisDate;

        final arce__hotel_analysis_category__c analysisCategory = new arce__hotel_analysis_category__c(
            arce__gf_hotel_category_type__c = '2', arce__account_has_analysis_id__c = newAnalysis.Id,
            arce__gf_hotel_occupancy_per__c = 100, arce__gf_hotel_avg_daily_rate_amount__c = 250000,
            arce__gf_rev_per_avail_room_amount__c = 500000

        );
        insert analysisCategory;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMainBanksOk
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void validateMainBanksOk() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__main_banks__c> lstMainBanks = new List<arce__main_banks__c>();
        final arce__main_banks__c mainBank1 = Arc_UtilitysDataTest_tst.crearMainBanks(newAnalysis.Id, null);
        mainBank1.arce__entity_quota_share_per__c = 10;
        mainBank1.arce__entity_name__c = 'BBVA';
        lstMainBanks.add(mainBank1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateMainBanks_service.beforeSaveData(lstMainBanks);
        System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMainBanksEmptyFieldKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void validateMainBanksEmptyFieldKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__main_banks__c> lstMainBanks = new List<arce__main_banks__c>();
        final arce__main_banks__c mainBank1 = Arc_UtilitysDataTest_tst.crearMainBanks(newAnalysis.Id, null);
        mainBank1.arce__entity_quota_share_per__c = 10;
        mainBank1.arce__entity_name__c = '';
        lstMainBanks.add(mainBank1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateMainBanks_service.beforeSaveData(lstMainBanks);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Name for record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMainBanksEmptyFieldShareKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void validateMainBanksEmptyFieldShareKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__main_banks__c> lstMainBanks = new List<arce__main_banks__c>();
        final arce__main_banks__c mainBank1 = Arc_UtilitysDataTest_tst.crearMainBanks(newAnalysis.Id, null);
        mainBank1.arce__entity_name__c = 'Test';
        lstMainBanks.add(mainBank1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateMainBanks_service.beforeSaveData(lstMainBanks);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Percentage for record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMainBanksEmptyRecordsOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateMainBanksEmptyRecordsOK() {
        final List<arce__main_banks__c> lstMainBanks = new List<arce__main_banks__c>();

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateMainBanks_service.beforeSaveData(lstMainBanks);
        System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMainBanksPercentGreaterKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateMainBanksPercentGreaterKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__main_banks__c> lstMainBanks = new List<arce__main_banks__c>();
        final arce__main_banks__c mainBank1 = Arc_UtilitysDataTest_tst.crearMainBanks(newAnalysis.Id, null);
        mainBank1.arce__entity_quota_share_per__c = 120;
        mainBank1.arce__entity_name__c = 'BBVA';
        lstMainBanks.add(mainBank1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateMainBanks_service.beforeSaveData(lstMainBanks);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, the sum of percentages can\'t be greater than 100%."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateContentOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContentOK() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('NameCollection 1', null, '05');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        tableContent1.arce__table_content_percentage__c = 100;
        lstTableContent.add(tableContent1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContent_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateContentEmptyOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContentEmptyOK() {
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContent_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateContentEmptyFieldKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContentEmptyFieldKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('NameCollection 1', null, '05');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        lstTableContent.add(tableContent1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContent_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Percentage for record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateContentPercentFailKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContentPercentFailKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('NameCollection 1', null, '05');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        tableContent1.arce__table_content_percentage__c = 120;
        lstTableContent.add(tableContent1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContent_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, the sum of percentages for year 2000 must be equal to 100%."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateContentYearFailKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContentYearFailKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('NameCollection 1', null, '05');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        final arce__Table_Content_per_Analysis__c tableContent2 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2001');
        final arce__Table_Content_per_Analysis__c tableContent3 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2002');
        tableContent1.arce__table_content_percentage__c = 5;
        tableContent2.arce__table_content_percentage__c = 5;
        tableContent3.arce__table_content_percentage__c = 5;
        lstTableContent.add(tableContent1);
        lstTableContent.add(tableContent2);
        lstTableContent.add(tableContent3);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContent_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, you can only introduce up to two years of information."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateContentEmptyYearKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContentEmptyYearKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('NameCollection 1', null, '05');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        tableContent1.arce__table_content_percentage__c = 5;
        tableContent1.arce__table_content_year__c = '';
        lstTableContent.add(tableContent1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContent_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, the year column has an incorrect format. Please make sure to introduce only 4 numbers.Error, please complete field Year for record 1.Error, the sum of percentages for year  must be equal to 100%."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateThirdParticipantEmptyOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateThirdParticipantEmptyOK() {
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;

        Test.startTest();
            String resBeforeSaveData = '';
            resBeforeSaveData = Arc_Gen_ValidateThirdParticipant_service.beforeSaveData(lstTableThird);
            System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateThirdParticipantPercentKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateThirdParticipantPercentKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;

        final arce__Third_Participant_Details__c thirdParticipant1 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(newAnalysis.Id, thirdParticipant.Id, null);
        thirdParticipant1.arce__third_participant_per__c = null;
        lstTableThird.add(thirdParticipant1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateThirdParticipant_service.beforeSaveData(lstTableThird);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Percentage for record 1.The first column is mandatory, please review record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateThirdParticipantSumPercentKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateThirdParticipantSumPercentKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;

        final arce__Third_Participant_Details__c thirdParticipant1 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(newAnalysis.Id, thirdParticipant.Id, null);
        thirdParticipant1.arce__third_participant_per__c = 105;
        lstTableThird.add(thirdParticipant1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateThirdParticipant_service.beforeSaveData(lstTableThird);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"The first column is mandatory, please review record 1.Error, the sum of percentages can\'t be greater than 100%."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateShareholdersEmptyOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateShareholdersEmptyOK() {
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;
        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateShareholders_service.beforeSaveData(lstTableThird);
        System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateShareholdersTypeOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateShareholdersTypeOK() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;
        final arce__Third_Participant__c thirdParticipantTR1 = [SELECT Id FROM arce__Third_Participant__c LIMIT 1];

        final arce__Third_Participant_Details__c thirdParticipant1 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(newAnalysis.Id, thirdParticipant.Id, null);
        thirdParticipant1.arce__third_participant_per__c = 20;
        thirdParticipant1.arce__shareholder_sponsor_year_id__c = '2000';
        thirdParticipant1.arce__shrhldr_financial_sponsor_type__c = '02';
        thirdParticipant1.arce__Third_Participant_id__c = thirdParticipantTR1.Id;
        lstTableThird.add(thirdParticipant1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateShareholders_service.beforeSaveData(lstTableThird);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Year should be completed only for financial sponsors, please review record 1.The first column is mandatory, please review record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateShareholdersFSSumPerKOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateShareholdersFSSumPerKOK() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;

        final arce__Third_Participant_Details__c thirdParticipant1 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(newAnalysis.Id, thirdParticipant.Id, null);
        thirdParticipant1.arce__third_participant_per__c = 120;
        thirdParticipant1.arce__shareholder_sponsor_year_id__c = '';
        thirdParticipant1.arce__shrhldr_financial_sponsor_type__c = '02';
        lstTableThird.add(thirdParticipant1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateShareholders_service.beforeSaveData(lstTableThird);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateShareholdersFieldEmptyOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateShareholdersFieldEmptyOK() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Third_Participant_Details__c> lstTableThird = new List<arce__Third_Participant_Details__c>();
        final arce__Third_Participant__c thirdParticipant =  Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdParticipant.arce__third_participant_role_type__c = '03';
        insert thirdParticipant;

        final arce__Third_Participant_Details__c thirdParticipant1 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(newAnalysis.Id, thirdParticipant.Id, null);
        thirdParticipant1.arce__third_participant_per__c = null;
        thirdParticipant1.arce__shareholder_sponsor_year_id__c = null;
        thirdParticipant1.arce__shrhldr_financial_sponsor_type__c = '01';
        lstTableThird.add(thirdParticipant1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateShareholders_service.beforeSaveData(lstTableThird);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Percentage for record 1.Year should be completed only for financial sponsors, please review record 1.The first column is mandatory, please review record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMaturityContentAmountKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateMaturityContentAmountKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('Bonds', null, '01');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        tableContent1.arce__table_content_value__c = null;
        lstTableContent.add(tableContent1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContentMaturity_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Amount for record 1.The first column is mandatory, please review record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validation test method
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hit.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param void
    * @return void
    * @example Static void validateMaturityContentYearKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateMaturityContentYearKO() {
        final arce__Account_has_Analysis__c newAnalysis = [SELECT Id, arce__analysis_template_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Table_Content_per_Analysis__c> lstTableContent = new List<arce__Table_Content_per_Analysis__c>();
        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('Bonds', null, '01');
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableContent1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataCollection.Id, null, '2000');
        tableContent1.arce__table_content_value__c = 100;
        tableContent1.arce__table_content_year__c = '';
        lstTableContent.add(tableContent1);

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateContentMaturity_service.beforeSaveData(lstTableContent);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Year for record 1.The first column is mandatory, please review record 1."}', 'Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateMaturityContentYearKO
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableOK() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":true,"msgInfo":""}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service KO Hotel Name
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateContractsAppraisalsTableKOHotelName
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableKOHotelName() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];

        contractAppraisal[0].arce__gf_hotel_name__c = '';
        update contractAppraisal;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Hotel Name for record 1."}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service KO Appraisal Value
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateContractsAppraisalsTableKOAppraisalAmount
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableKOAppraisalAmount() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];

        contractAppraisal[0].arce__appraisal_amount__c = null;
        update contractAppraisal;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Appraisal Value for record 1."}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service KO Last Appraisal Date
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateContractsAppraisalsTableKOLastAppraisal
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableKOLastAppraisal() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];

        contractAppraisal[0].arce__last_assessed_date__c = null;
        update contractAppraisal;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Last Appraisal Date for record 1."}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service KO Contract Period
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateContractsAppraisalsTableKOContractPeriod
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableKOContractPeriod() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];

        contractAppraisal[0].arce__gf_htl_ownshp_ctrct_dur_number__c = '';
        update contractAppraisal;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Contract Period for record 1."}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service KO Contract Expiration
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateContractsAppraisalsTableKOContractExpiration
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableKOContractExpiration() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];

        contractAppraisal[0].arce__gf_current_expiration_date__c = null;
        update contractAppraisal;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Contract Expiration for record 1."}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidContractAppraisals_service KO Type of Contract
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param void
    * @return void
    * @example Static void validateContractsAppraisalsTableKOTypeContract
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateContractsAppraisalsTableKOTypeContract() {
        final List<arce__contracts_and_appraisals__c> contractAppraisal = [SELECT arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,arce__gf_hotel_contract_type_name__c
        FROM arce__contracts_and_appraisals__c limit 1];

        contractAppraisal[0].arce__gf_hotel_contract_type_name__c = '';
        update contractAppraisal;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidContractAppraisals_service.beforeSaveData(contractAppraisal);
        System.assertEquals(resBeforeSaveData, '{"validation":false,"msgInfo":"Error, please complete field Type of Contract for record 1."}', 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisDateOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateOK() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_period_start_date__c = System.today();
        analysisDate[0].arce__gf_period_end_date__c = System.today() + 1;
        update analysisDate;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('true'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO Start Date
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-19
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOStartDate
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOStartDate() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_period_start_date__c = null;
        update analysisDate;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO End Date
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-19
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOEndDate
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOEndDate() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_period_end_date__c = null;
        update analysisDate;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO Previous Date
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-19
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOPreviousDate
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOPreviousDate() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_period_end_date__c = system.today()-1;
        update analysisDate;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO Percent
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOPercent
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOPercent() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_hotel_occupancy_per__c = null;
        update analysisDate;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO Max Percent
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOMaxPercent
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOMaxPercent() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_hotel_occupancy_per__c = 101;
        update analysisDate;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO ADR
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOOAdr
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOAdr() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_hotel_avg_daily_rate_amount__c = null;
        update analysisDate;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisPerDate_Service KO REVPAR
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKORevpar
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKORevpar() {
        final List<arce__hotel_analysis_date_period__c> analysisDate = [SELECT arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_date_period__c limit 1];

        analysisDate[0].arce__gf_rev_per_avail_room_amount__c = null;
        update analysisDate;


        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(analysisDate);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO Max Records
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-19
    * @param void
    * @return void
    * @example Static void validateAnalysisDateKOMaxRecord
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisDateKOMaxRecord() {
        List<arce__Account_has_Analysis__c> maxRecord = new List<arce__Account_has_Analysis__c>();
        arce__Analysis__c analysis = [SELECT id FROM arce__Analysis__c LIMIT 1];

        for (Integer count = 0;count <= 100;count++){
            final arce__Account_has_Analysis__c newAha = new arce__Account_has_Analysis__c (arce__gf_company_economic_actvy_id__c = String.valueOf((Math.random()*10000000).round()), arce__Analysis__c= analysis.id);
            maxRecord.add(newAha);
        }
        insert maxRecord;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisPerDate_Service.beforeSaveData(maxRecord);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service OK
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisCategoryOK
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisCategoryOK() {
        final List<arce__hotel_analysis_category__c> analysisCategory = [SELECT arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_category__c limit 1];

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(analysisCategory);
        System.assertEquals(true, resBeforeSaveData.contains('true'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO Category
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisKOCategory
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisKOCategory() {
        final List<arce__hotel_analysis_category__c> analysisCategory = [SELECT arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_category__c limit 1];

        analysisCategory[0].arce__gf_hotel_category_type__c = '';
        update analysisCategory;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(analysisCategory);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO Percent
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisKOPercent
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisKOPercent() {
        final List<arce__hotel_analysis_category__c> analysisCategory = [SELECT arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_category__c limit 1];

        analysisCategory[0].arce__gf_hotel_occupancy_per__c = null;
        update analysisCategory;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(analysisCategory);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO Max Percent
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisKOMaxPercent
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisKOMaxPercent() {
        final List<arce__hotel_analysis_category__c> analysisCategory = [SELECT arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_category__c limit 1];

        analysisCategory[0].arce__gf_hotel_occupancy_per__c = 101;
        update analysisCategory;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(analysisCategory);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO ADR
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisKOAdr
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisKOAdr() {
        final List<arce__hotel_analysis_category__c> analysisCategory = [SELECT arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_category__c limit 1];

        analysisCategory[0].arce__gf_hotel_avg_daily_rate_amount__c = null;
        update analysisCategory;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(analysisCategory);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO REVPAR
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-13
    * @param void
    * @return void
    * @example Static void validateAnalysisKORevpar
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisKORevpar() {
        final List<arce__hotel_analysis_category__c> analysisCategory = [SELECT arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
        FROM arce__hotel_analysis_category__c limit 1];

        analysisCategory[0].arce__gf_rev_per_avail_room_amount__c = null;
        update analysisCategory;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(analysisCategory);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Tets method for Arc_Gen_ValidateAnalysisCategory_Service KO Max Records
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-19
    * @param void
    * @return void
    * @example Static void validateAnalysisKOMaxRecord
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Static void validateAnalysisKOMaxRecord() {
        List<arce__Account_has_Analysis__c> maxRecord = new List<arce__Account_has_Analysis__c>();
        arce__Analysis__c analysis = [SELECT id FROM arce__Analysis__c LIMIT 1];

        for (Integer count = 0;count <= 100;count++) {
            arce__Account_has_Analysis__c newAha = new arce__Account_has_Analysis__c (arce__gf_company_economic_actvy_id__c = String.valueOf((Math.random()*10000000).round()), arce__Analysis__c= analysis.id);
            maxRecord.add(newAha);
        }
        insert maxRecord;

        Test.startTest();
        String resBeforeSaveData = '';
        resBeforeSaveData = Arc_Gen_ValidateAnalysisCategory_Service.beforeSaveData(maxRecord);
        System.assertEquals(true, resBeforeSaveData.contains('false'), 'Success');
    }
}