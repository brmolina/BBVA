/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistance_Bureau_MB_Test
* @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
* @Date     Created: 01/11/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers:  Arc_Gen_Bureau_Main_Banks_Per_service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-11 manuelhugo.castillo.contractor@bbva.com
*             Class creation
* |2020-11-12 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_Persistance_Bureau_MB_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method, create data for dinamic form
    * --------------------------------------------------------------------------------------
    * @Author   manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param void
    * @return void
    * @example setupTest()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setupTest() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;
        final arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Banking', '200', 'Bank', null);
        insert sect;
        final arce__Account_has_Analysis__c accHasAnaClient = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, newArce.Id, childAccount.accId, '1');
        accHasAnaClient.arce__group_asset_header_type__c = '2';
        accHasAnaClient.arce__InReview__c = true;
        accHasAnaClient.arce__risk_position_summary_desc__c = 'Comments risk position';
        accHasAnaClient.arce__cust_delay_payment_desc__c = 'Cust delay';
        accHasAnaClient.arce__bureau_warning_prevention_desc__c = 'Bureau warning prevention';
        accHasAnaClient.arce__bureau_warn_prvnt_owner_desc__c = 'Prevention owner';
        accHasAnaClient.arce__bureau_warn_prvnt_action_desc__c = 'Prevention action';
        accHasAnaClient.arce__other_contracted_product_desc__c = 'Contracted product';
        accHasAnaClient.arce__number_entity_type__c = '3';
        accHasAnaClient.arce__other_operation_desc__c = 'Other operation';
        accHasAnaClient.arce__rar_profitability_per__c = 123;
        accHasAnaClient.arce__rar_profitability_desc__c = 'RAR Profitability';
        accHasAnaClient.arce__hats_risk_qualification_number__c = 321;
        accHasAnaClient.arce__stage_collective_desc__c = 'Stage collective';
        accHasAnaClient.arce__customer_product_usage_desc__c = 'customer product usage';
        accHasAnaClient.arce__banking_pool_desc__c = 'Banking pool';
        accHasAnaClient.arce__capital_provision_per__c = 1234;
        accHasAnaClient.arce__capital_provision_desc__c = 'Capital provision';
        accHasAnaClient.arce__fin_covenants_breach_type__c = '1';
        accHasAnaClient.arce__fin_covenants_breach_desc__c = 'Covenant breach';
        insert accHasAnaClient;

        arce__Account_has_Analysis__c ahaGroup = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, newArce.Id, groupAccount.accId, '1');
        ahaGroup.arce__group_asset_header_type__c = '1';
        ahaGroup.arce__InReview__c = true;
        insert ahaGroup;

        Arc_UtilitysDataTest_tst.setupProducts();
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('familyTest');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);

        // Set product typology.
        final Product2 updatedProd = new Product2(Id = prodWrapper.productId, ProductCode = 'TP_0010');
        update updatedProd;

        setupTypologies();
        setupChildRiskPositionRecords(accHasAnaClient, childAccount, prodWrapper);
        setupParentRiskPositionRecords(ahaGroup, childAccount);
        setupMainBanks(accHasAnaClient);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Creates test typologies
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param void
    * @return void
    * @example setupTypologies()
    * --------------------------------------------------------------------------------------
    **/
    private static void setupTypologies() {
        // Create Lv1 topology.
        final arce__limits_typology__c totalCredRisk = new arce__limits_typology__c();
        totalCredRisk.arce__risk_typo_ext_id__c = '999999999999';
        totalCredRisk.arce__risk_typology_level_id__c = 'TP_0006';
        totalCredRisk.arce__risk_typology_active__c = true;
        insert totalCredRisk;

        // Create Lv2 topologies
        final arce__limits_typology__c typo1 = new arce__limits_typology__c();
        typo1.arce__risk_typo_ext_id__c = '999999999999A';
        typo1.arce__risk_typology_level_id__c = 'TP_0010';
        typo1.arce__risk_typology_parent_id__c = totalCredRisk.Id;
        typo1.arce__risk_typology_active__c = true;
        insert typo1;

        final arce__limits_typology__c typo2 = new arce__limits_typology__c();
        typo2.arce__risk_typo_ext_id__c = '999999999999B';
        typo2.arce__risk_typology_level_id__c = 'TP_0008';
        typo2.arce__risk_typology_parent_id__c = totalCredRisk.Id;
        typo2.arce__risk_typology_active__c = true;
        insert typo2;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Creates risk position records for child account
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param arce__Account_has_Analysis__c accHasAnaClient - account has analysis
    * @param arce.Arc_Gen_Account_Wrapper childAccount - related account
    * @param Arc_Gen_Product_Wrapper prodWrapper- product wrapper related
    * @return void
    * @example setupChildRiskPositionRecords(accHasAnaClient,childAccount, prodWrapper)
    * --------------------------------------------------------------------------------------
    **/
    private static void setupChildRiskPositionRecords(arce__Account_has_Analysis__c accHasAnaClient, arce.Arc_Gen_Account_Wrapper childAccount, Arc_Gen_Product_Wrapper prodWrapper) {
        final arce__risk_position_summary__c riskPositionSumm = new arce__risk_position_summary__c();
        riskPositionSumm.arce__account_has_analysis_id__c = accHasAnaClient.Id;
        riskPositionSumm.arce__account_Id__c = childAccount.accId;
        riskPositionSumm.arce__banrel_current_limit_name__c = 0;
        riskPositionSumm.arce__banrel_commitment_name__c = 0;
        riskPositionSumm.arce__banrel_uncommitment_name__c = 0;
        riskPositionSumm.arce__banrel_outstanding_name__c = 0;
        riskPositionSumm.arce__banrel_comments_desc__c = 'test comments';
        riskPositionSumm.arce__Product_id__c = prodWrapper.productId;
        insert riskPositionSumm;

        final arce__risk_position_summary__c rPositionSummary = new arce__risk_position_summary__c();
        rPositionSummary.arce__account_has_analysis_id__c = accHasAnaClient.Id;
        rPositionSummary.arce__account_Id__c = childAccount.accId;
        rPositionSummary.arce__banrel_current_limit_name__c = 0;
        rPositionSummary.arce__banrel_commitment_name__c = 0;
        rPositionSummary.arce__banrel_uncommitment_name__c = 0;
        rPositionSummary.arce__banrel_outstanding_name__c = 0;
        rPositionSummary.arce__banrel_comments_desc__c = '';
        rPositionSummary.arce__Product_id__c = null;
        insert rPositionSummary;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Creates main banks records for account has analysis
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param arce__Account_has_Analysis__c accHasAnaClient - account has analysis
    * @return void
    * @example setupMainBanks(accHasAnaClient)
    * --------------------------------------------------------------------------------------
    **/
    private static void setupMainBanks(arce__Account_has_Analysis__c accHasAnaClient) {
        arce__main_banks__c[] mnBnksLst = new List<arce__main_banks__c> ();
        arce__main_banks__c mnBnks2 = Arc_UtilitysDataTest_tst.crearMainBanks(accHasAnaClient.Id, null);
        mnBnksLst.add(mnBnks2);
        Arc_Gen_MainBanks_Data.insertTableContent(mnBnksLst);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Creates risk position records for parent account
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param arce__Account_has_Analysis__c ahaGroup - account has analysis
    * @param arce.Arc_Gen_Account_Wrapper childAccount - child account
    * @return void
    * @example setupParentRiskPositionRecords(ahaGroup, childAccount)
    * --------------------------------------------------------------------------------------
    **/
    private static void setupParentRiskPositionRecords(arce__Account_has_Analysis__c ahaGroup, arce.Arc_Gen_Account_Wrapper childAccount) {
        final arce__risk_position_summary__c riskPSGroup = new arce__risk_position_summary__c();
        riskPSGroup.arce__account_has_analysis_id__c = ahaGroup.Id;
        riskPSGroup.arce__account_Id__c = childAccount.accId;
        riskPSGroup.arce__banrel_current_limit_name__c = 0;
        riskPSGroup.arce__banrel_commitment_name__c = 0;
        riskPSGroup.arce__banrel_uncommitment_name__c = 0;
        riskPSGroup.arce__banrel_outstanding_name__c = 0;
        riskPSGroup.arce__banrel_comments_desc__c = 'Test comments banrel';
        riskPSGroup.arce__Product_id__c = null;
        insert riskPSGroup;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that test group account has analysis
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param void
    * @return void
    * @example persistanceGroupTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void persistanceGroupTest() {
        final Map<String, arce.Arc_Gen_Account_Wrapper> mapAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = mapAccWrapper.get(GROUP_ID);
        final arce__account_has_analysis__c ahaTest = arce.Arc_Gen_AccHasAnalysis_Data.getAccForResume(new Set<Id>{groupAccount.accId})[0];
        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaTest.Id})[0];
        Test.startTest();
        final String test1 =  Arc_Gen_Bureau_Main_Banks_Per_service.save(new List<arce__account_has_analysis__c>{ahaTestFinal});
        system.assert(test1.contains('"validated":true'), 'Test save persistance');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that persist a client
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2019-01-11
    * @param void
    * @return void
    * @example persistanceClientTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void persistanceClientTest() {
        final Map<String, arce.Arc_Gen_Account_Wrapper> mapAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper childAccount = mapAccWrapper.get(SUBSIDIARY_ID);
        final arce__account_has_analysis__c ahaTest = arce.Arc_Gen_AccHasAnalysis_Data.getAccForResume(new Set<Id>{childAccount.accId})[0];
        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaTest.Id})[0];
        Test.startTest();
        final String test1 =  Arc_Gen_Bureau_Main_Banks_Per_service.save(new List<arce__account_has_analysis__c>{ahaTestFinal});
        system.assert(test1.contains('"validated":true'), 'Test save persistance');
        Test.stopTest();
    }
}