/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveGroupFinancialRisk_Test
* @Author   José Luis García Díaz
* @Date     Created: 02/10/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class test for Arc_Gen_SaveGroupFinancialRisk.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-02 José Luis García Díaz
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@IsTest
public with sharing class Arc_Gen_SaveGroupFinancialRisk_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup. Creates test data.
    * --------------------------------------------------------------------------------------
    **/
    @TestSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','C000001'});
        final arce.Arc_Gen_Account_Wrapper grp = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper sub = groupAccWrapper.get('C000001');
        final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, grp.accId);
        insert analysis;
        final arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        insert sect;
        final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, sub.accId, 's-01');
        insert accHasAnalysis;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Tests SME calculation when any of inputs are null.
    * --------------------------------------------------------------------------------------
    **/
    @IsTest static void testSmeCalculationNull() {
        // Prepare AHA info.
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)aha.Id})[0];
        ahaTestFinal.arce__employees_number__c = null;
        ahaTestFinal.arce__total_asset_local_amount__c = 400000;
        ahaTestFinal.arce__total_revenues_local_amount__c = 50000000;
        fillWithDynFields(ahaTestFinal);

        Test.startTest();
        final Arc_Gen_SaveGroupFinancialRisk saveImpl = new Arc_Gen_SaveGroupFinancialRisk();
        saveImpl.save(new List<SObject> { ahaTestFinal });
        Test.stopTest();

        // Assert.
        System.assertEquals(null, ahaTestFinal.arce__smes_eur_comuty_defn_type__c, 'Calculated SME must be null as some fields are null');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Tests SME calculation when employee count is above the limit.
    * --------------------------------------------------------------------------------------
    **/
    @IsTest static void testSmeCalculationNoBcEmployees() {
        // Prepare AHA info.
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)aha.Id})[0];
        ahaTestFinal.arce__employees_number__c = 500;
        ahaTestFinal.arce__total_asset_local_amount__c = 400000;
        ahaTestFinal.arce__total_revenues_local_amount__c = 50000;
        fillWithDynFields(ahaTestFinal);

        Test.startTest();
        final Arc_Gen_SaveGroupFinancialRisk saveImpl = new Arc_Gen_SaveGroupFinancialRisk();
        saveImpl.save(new List<SObject> { ahaTestFinal });
        Test.stopTest();

        // Assert.
        System.assertEquals('2', ahaTestFinal.arce__smes_eur_comuty_defn_type__c, 'Calculated SME must be "No" because of employee count');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Tests SME calculation when balance and sales are above the limit.
    * --------------------------------------------------------------------------------------
    **/
    @IsTest static void testSmeCalculationNoBcAmounts() {
        // Prepare AHA info.
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)aha.Id})[0];
        ahaTestFinal.arce__employees_number__c = 100;
        ahaTestFinal.arce__total_asset_local_amount__c = 44000000;
        ahaTestFinal.arce__total_revenues_local_amount__c = 51000000;
        fillWithDynFields(ahaTestFinal);


        Test.startTest();
        final Arc_Gen_SaveGroupFinancialRisk saveImpl = new Arc_Gen_SaveGroupFinancialRisk();
        saveImpl.save(new List<SObject> { ahaTestFinal });
        Test.stopTest();

        // Assert.
        System.assertEquals('2', ahaTestFinal.arce__smes_eur_comuty_defn_type__c, 'Calculated SME must be "No" because of sales and balance');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Tests SME calculation when balance and sales are under the limit.
    * --------------------------------------------------------------------------------------
    **/
    @IsTest static void testSmeCalculationYesBcAmounts() {
        // Prepare AHA info.
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)aha.Id})[0];
        ahaTestFinal.arce__employees_number__c = 100;
        ahaTestFinal.arce__total_asset_local_amount__c = 42;
        ahaTestFinal.arce__total_revenues_local_amount__c = 51;
        fillWithDynFields(ahaTestFinal);

        Test.startTest();
        final Arc_Gen_SaveGroupFinancialRisk saveImpl = new Arc_Gen_SaveGroupFinancialRisk();
        saveImpl.save(new List<SObject> { ahaTestFinal });
        Test.stopTest();

        // Assert.
        System.assertEquals('1', ahaTestFinal.arce__smes_eur_comuty_defn_type__c, 'Calculated SME must be "No" because of sales and balance');
    }

    private static void fillWithDynFields(arce__Account_has_Analysis__c ahaTestFinal){
      ahaTestFinal.put('arce__ffss_auditor_fullname_name__c','test');
      ahaTestFinal.put('arce__ffss_cnsld_perimeter_desc__c','test');
      ahaTestFinal.put('arce__ffss_auditor_fullname_name__c','test');
      ahaTestFinal.put('arce__debt_maturity_desc__c','test');
      ahaTestFinal.put('arce__number_entity_type__c','test');
      ahaTestFinal.put('arce__debt_maturity_available_type__c','test');
      ahaTestFinal.put('arce__cust_budget_cyr_ind_type__c','test');
      ahaTestFinal.put('arce__cust_budget_incl_ffss_ind_type__c','test');
      ahaTestFinal.put('arce__cust_proj_2yr_3yr_ind_type__c','test');
      ahaTestFinal.put('arce__cust_proj_2yr_3yr_desc__c','test');
      ahaTestFinal.put('arce__property_ownership_type__c','test');
      ahaTestFinal.put('arce__property_ownership_desc__c','test');
      ahaTestFinal.put('arce__var_over_20_balance_desc__c','test');
      ahaTestFinal.put('arce__equity_total_asset_20_type__c','test');
    }
}