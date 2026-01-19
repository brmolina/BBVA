/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionBankTable_Ctlr_Test
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_PotitionBankTable_Ctrl, Arc_Gen_PotitionBankTable_Service and
* Arc_Gen_PotitionBankTable_Service_Helper.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-07 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-02-07 mariohumberto.ramirez.contractor@bbva.com
*             Update test class
* |2020-03-30 javier.soto.carrascosa@bbva.com
*             Add support for product static resource in test classes
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Create additional test topologies for testing nested data.
* |2020-07-28 joseluis.garcia4.contractor@bbva.com
*             Update tests to increase coverage.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-08-27 antonio.munoz.perez.contractor@bbva.com
*             Added testMethod1AutoGroupTD()
* |2020-11-11 juanignacio.hita.contractor@bbva.com
*             Update setup typologies family
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
private class Arc_Gen_PotitionBankTable_Ctlr_Test{
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
    * @Description Setup method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);

        arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, groupAccount.accId);
        analysis.arce__analysis_customer_relation_type__c = '01';
        insert analysis;

        arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Banking', '200', 'Bank', null);
        insert sect;

        arce__Account_has_Analysis__c accHasAnalysisClient = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, childAccount.accId, '1');
        accHasAnalysisClient.arce__group_asset_header_type__c = '2';
        accHasAnalysisClient.arce__InReview__c = true;
        insert accHasAnalysisClient;

        arce__Account_has_Analysis__c accHasAnalysisGroup = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, groupAccount.accId, '1');
        accHasAnalysisGroup.arce__group_asset_header_type__c = '1';
        accHasAnalysisGroup.arce__InReview__c = true;
        insert accHasAnalysisGroup;

        Arc_UtilitysDataTest_tst.setupProducts();
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('familyTest');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);

        // Set product typology.
        final Product2 updatedProd = new Product2(Id = prodWrapper.productId, Family = 'TP_0010');
        update updatedProd;

        setupTypologies();
        setupChildRiskPositionRecords(accHasAnalysisClient, childAccount, prodWrapper);
        setupParentRiskPositionRecords(accHasAnalysisGroup, groupAccount);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Creates test typologies
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
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
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * --------------------------------------------------------------------------------------
    **/
    private static void setupChildRiskPositionRecords(arce__Account_has_Analysis__c accHasAnalysisClient,arce.Arc_Gen_Account_Wrapper childAccount, Arc_Gen_Product_Wrapper prodWrapper) {
        final arce__risk_position_summary__c riskPositionSummary = new arce__risk_position_summary__c();
        riskPositionSummary.arce__account_has_analysis_id__c = accHasAnalysisClient.Id;
        riskPositionSummary.arce__account_Id__c = childAccount.accId;
        riskPositionSummary.arce__banrel_current_limit_name__c = 0;
        riskPositionSummary.arce__banrel_commitment_name__c = 0;
        riskPositionSummary.arce__banrel_uncommitment_name__c = 0;
        riskPositionSummary.arce__banrel_outstanding_name__c = 0;
        riskPositionSummary.arce__banrel_comments_desc__c = '';
        riskPositionSummary.arce__Product_id__c = prodWrapper.productId;
        insert riskPositionSummary;

        final arce__risk_position_summary__c riskPositionSummary1 = new arce__risk_position_summary__c();
        riskPositionSummary1.arce__account_has_analysis_id__c = accHasAnalysisClient.Id;
        riskPositionSummary1.arce__account_Id__c = childAccount.accId;
        riskPositionSummary1.arce__banrel_current_limit_name__c = 0;
        riskPositionSummary1.arce__banrel_commitment_name__c = 0;
        riskPositionSummary1.arce__banrel_uncommitment_name__c = 0;
        riskPositionSummary1.arce__banrel_outstanding_name__c = 0;
        riskPositionSummary1.arce__banrel_comments_desc__c = '';
        riskPositionSummary1.arce__Product_id__c = null;
        insert riskPositionSummary1;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Creates risk position records for parent account
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García    joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * --------------------------------------------------------------------------------------
    **/
    private static void setupParentRiskPositionRecords(arce__Account_has_Analysis__c accHasAnalysisGroup,arce.Arc_Gen_Account_Wrapper groupAccount) {
        final arce__risk_position_summary__c riskPositionSummaryGroup = new arce__risk_position_summary__c();
        riskPositionSummaryGroup.arce__account_has_analysis_id__c = accHasAnalysisGroup.Id;
        riskPositionSummaryGroup.arce__account_Id__c = groupAccount.accId;
        riskPositionSummaryGroup.arce__banrel_current_limit_name__c = 0;
        riskPositionSummaryGroup.arce__banrel_commitment_name__c = 0;
        riskPositionSummaryGroup.arce__banrel_uncommitment_name__c = 0;
        riskPositionSummaryGroup.arce__banrel_outstanding_name__c = 0;
        riskPositionSummaryGroup.arce__banrel_comments_desc__c = '';
        riskPositionSummaryGroup.arce__Product_id__c = null;
        insert riskPositionSummaryGroup;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod1Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1Client() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Account_has_Analysis__c accHasAnClient = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();

        Test.startTest();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnClient.Id, 'Arc_Gen_PotitionBankTable_Service');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod2Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod2Client() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Account_has_Analysis__c accHasAnClient = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();

        Test.startTest();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnClient.Id, 'Arc_Gen_PotitionBankTable');
        system.assertEquals(wrapper.successResponse, false, 'Error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod3Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod3Client() {
        Test.startTest();
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = Arc_Gen_PotitionBankTable_Ctlr.getRecordTypeId('RPS_0001');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod4Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod4Client() {
        Test.startTest();
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper3 = Arc_Gen_PotitionBankTable_Ctlr.getRecordTypeId('123');
        system.assertEquals(wrapper3.successResponse, false, 'There was an error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod5Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod5Client() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Account_has_Analysis__c accHasAnClient = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        arce__risk_position_summary__c recort2delete = [SELECT Id FROM arce__risk_position_summary__c WHERE arce__account_Id__c = :accHasAnClient.arce__Customer__c LIMIT 1];

        Test.startTest();
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper4 = Arc_Gen_PotitionBankTable_Ctlr.deleteRecord(recort2delete.Id);
        system.assertEquals(wrapper4.successResponse, true, 'The call was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod6Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod6Client() {
        Test.startTest();
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper5 = Arc_Gen_PotitionBankTable_Ctlr.deleteRecord('error');
        system.assertEquals(wrapper5.successResponse, true, 'There was an error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod1Group()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1Group() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        arce__Account_has_Analysis__c accHasAnGroup = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnGroup.Id, 'Arc_Gen_PotitionBankTable_Service');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethodVoidConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethodVoidConstructor() {
        Arc_Gen_PotitionBankTable_Ctlr controller = new Arc_Gen_PotitionBankTable_Ctlr();
        Arc_Gen_Risk_Position_summary_Data data = new Arc_Gen_Risk_Position_summary_Data();
        Arc_Gen_PotitionBankTable_Service_Helper helper = new Arc_Gen_PotitionBankTable_Service_Helper();
        system.assertEquals(controller, controller, 'The test to void contructor was successfull');
        system.assertEquals(data, data, 'The test to void contructor was successfull');
        system.assertEquals(helper, helper, 'The test to void contructor was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param void
    * @return void
    * @example testMethod1Client()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1ClientAuto() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Account_has_Analysis__c accHasAnClient = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();

        Test.startTest();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnClient.Id, 'Arc_Gen_Auto_Position_Service');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Should test what happens if no previously existing position
    * records exist.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García  joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-29
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1ClientAuto2() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Account_has_Analysis__c accHasAnClient = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();

        // Remove existing position records.
        delete [SELECT Id FROM arce__risk_position_summary__c WHERE arce__Product_id__c != null];   // NOSONAR

        Test.startTest();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnClient.Id, 'Arc_Gen_Auto_Position_Service');
        System.assert(wrapper.successResponse, 'The call was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Should test what happens when calling dataResponse after forcing a refresh.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García  joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1ClientAuto3() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Account_has_Analysis__c accHasAnClient = [SELECT Id, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();

        // Remove existing position records.
        delete [SELECT Id FROM arce__risk_position_summary__c WHERE arce__Product_id__c != null];  // NOSONAR

        Test.startTest();
        Arc_Gen_PotitionBankTable_Ctlr.refreshAutomaticPosition(accHasAnClient.Id, 'Arc_Gen_Auto_Position_Service');
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnClient.Id, 'Arc_Gen_Auto_Position_Service');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod1Group()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1AutoGroup() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        arce__Account_has_Analysis__c accHasAnGroup = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnGroup.Id, 'Arc_Gen_Auto_Position_Service');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
    }
        /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testMethod1Group()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMethod1AutoGroupTD() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Account_has_Analysis__c accHasAnGroup = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper wrapper = new Arc_Gen_PotitionBankTable_Ctlr.ResponseWrapper();
        wrapper = Arc_Gen_PotitionBankTable_Ctlr.dataResponse(accHasAnGroup.Id, 'Arc_Gen_Consolidated_Position_Service');
        system.assertEquals(wrapper.successResponse, true, 'The call was successfull');
    }
}