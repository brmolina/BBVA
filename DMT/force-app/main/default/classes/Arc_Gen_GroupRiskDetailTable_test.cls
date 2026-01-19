/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GroupRiskDetailTable_test
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 19/11/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Tests the classes getRatingDataService and RatingVariablesTable
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |19/11/2020 juanignacio.hita.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_GroupRiskDetailTable_test {
    /**
    * @Description: Configuration name group risk detail table
    */
    static final String CONF_GROUPRISK = 'Arc_Gen_GroupRiskDetail_SI';
    /**
    * @Description: Configuration name group leveraged risk table
    */
    static final String CONF_LEVGDRISK = 'Arc_Gen_LeveragedGpTable_SI';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000003';
    /**
    * --------------------------------------------------------------------------------------
    * @Description setup test
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 19/11/2020
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();

        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c arce = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        arce.arce__analysis_customer_relation_type__c = '01';
        arce.arce__Stage__c = '2';
        arce.arce__anlys_wkfl_sub_process_type__c = '2';
        insert arce;

        final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;200;300;400;500', '1', null);
        newSector.arce__sector_analisis_type__c = '2';
        newSector.arce__active_type__c = true;
        insert newSector;

        final arce__rating__c rating = new arce__rating__c();
        insert rating;

        final arce__Account_has_Analysis__c accHasAnGp = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arce.Id, groupAccount.accId, '1');
        accHasAnGp.arce__risk_request_desc__c = 'xxx';
        accHasAnGp.arce__arce_ctmr_flag__c = true;
        accHasAnGp.arce__InReview__c = true;
        accHasAnGp.arce__group_asset_header_type__c = '1';
        accHasAnGp.arce__magnitude_unit_type__c = '2';
        accHasAnGp.arce__group_risk_detail_part_name__c = 'ACC1';
        accHasAnGp.arce__economic_activity_sector_desc__c = 'test';
        accHasAnGp.arce__bbva_financial_debt_share_per__c = 15;
        accHasAnGp.arce__last_approved_amount__c = 0.0;
        accHasAnGp.arce__current_formalized_amount__c = 0.0;
        accHasAnGp.arce__outstanding_amount__c = 0.0;
        accHasAnGp.arce__current_proposed_local_amount__c = 0.0;
        accHasAnGp.arce__rating_scale_type__c = '1';
        accHasAnGp.arce__participant_name__c = 'TOTAL';
        accHasAnGp.arce__ll_after_adj_ind_type__c = '1';
        accHasAnGp.arce__ll_after_adj_clsfn_type__c = 'FS';
        insert accHasAnGp;

        final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, accHasAnGp.id, rating.id, null);
        finStatement.arce__ffss_valid_type__c = '1';
        finStatement.CurrencyIsoCode = 'EUR';
        insert finStatement;

    }
    /**
    * @Method:  test for constructor method
    * @Description: testing method.
    */
    @isTest
    static void testConstructor() {
        Test.startTest();
        final Arc_Gen_GroupRiskDetailTable_controller genCons = new Arc_Gen_GroupRiskDetailTable_controller();
        System.assertEquals(genCons, genCons, 'Constructor method');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test createGroupRiskTable method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingFiancialAlertRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCreateGroupRisk() {
        final arce__Account_has_Analysis__c analyzedClient = [SELECT Id, Name FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Financial_Statements__c ffss = [SELECT Id, Name FROM arce__Financial_Statements__c LIMIT 1];
        analyzedClient.arce__ffss_for_rating_id__c = ffss.Id;
        Test.startTest();
            final String retVal = Arc_Gen_GroupRiskDetailTable_controller.createGroupRiskTable(analyzedClient.Id, CONF_GROUPRISK);
            System.assert(retVal != '', 'Create group risk table test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test createGroupRiskTable method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingFiancialAlertRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCreateLeveraged() {
        final arce__Account_has_Analysis__c analyzedClient = [SELECT Id, Name FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
            final String retVal = Arc_Gen_GroupRiskDetailTable_controller.createGroupRiskTable(analyzedClient.Id, CONF_GROUPRISK);
            System.assert(retVal != '', 'Create leveraged group table test');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test createGroupRiskTable method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingFiancialAlertRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCreateGroupRiskKO() {
        final Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        try {
            Arc_Gen_GroupRiskDetailTable_controller.createGroupRiskTable(acc.Id, CONF_LEVGDRISK);
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'CreateGroupRiskTable test method');
        }
        Test.stopTest();
    }
}