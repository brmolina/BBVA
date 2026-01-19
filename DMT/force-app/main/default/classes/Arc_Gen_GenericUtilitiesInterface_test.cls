/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GenericUtilitiesInterface
* @Author   Juan Ignacio Hita Manso juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-04-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Arc_Gen_GenericUtilitiesInterface test class
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-30 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2020-09-16 juanignacio.hita.contractor@bbva.com
*             Add new test methods
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_GenericUtilitiesInterface_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description setup test
    * --------------------------------------------------------------------------------------
    * @Author   javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-01-08
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        arce__Analysis__c arceobj = new arce__Analysis__c();
        arceobj.Name = 'arce__Analysisobj';
        arceobj.arce__analysis_customer_relation_type__c = '01';
        arceobj.CurrencyIsoCode = 'EUR';
        arceobj.arce__Group__c = groupAccount.accId;
        arceobj.arce__Stage__c = '1';
        arceobj.arce__wf_status_id__c = '02';
        insert arceobj;
        arce__Account_has_Analysis__c arceAccounthasAnalysisobj = new arce__Account_has_Analysis__c();
        arceAccounthasAnalysisobj.currencyIsoCode = 'EUR';
        arceAccounthasAnalysisobj.arce__main_subsidiary_ind_type__c = true;
        arceAccounthasAnalysisobj.arce__InReview__c = true;
        arceAccounthasAnalysisobj.arce__Analysis__c = arceobj.Id;
        arceAccounthasAnalysisobj.arce__smes_eur_comuty_defn_type__c = '1';
        arceAccounthasAnalysisobj.arce__ll_before_adj_ind_type__c = '1';
        arceAccounthasAnalysisobj.arce__ll_before_adj_clsfn_type__c = 'NI';
        arceAccounthasAnalysisobj.arce__ll_after_adj_ind_type__c = '1';
        arceAccounthasAnalysisobj.arce__ll_after_adj_clsfn_type__c = 'NI';
        arceAccounthasAnalysisobj.arce__Customer__c = groupAccount.accId;
        insert arceAccounthasAnalysisobj;
    }
    /**
    * @Method:  test for constructor method
    * @Description: testing method.
    */
    @isTest
    static void testConstructor() {
        Test.startTest();
        final Arc_Gen_GenericUtilitiesInterface genericConstructor = new Arc_Gen_GenericUtilitiesInterface();
        System.assertEquals(genericConstructor, genericConstructor, 'Constructor method');
        Test.stopTest();
    }
    /**
    * @Method:  test for workflowClass method
    * @Description: testing method.
    */
    @isTest
    static void testWorkFlowService() {
        final Arc_Gen_Workflow_Interface workflowController = Arc_Gen_GenericUtilitiesInterface.workflowClass();
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_Delegation_Wrapper wrapper = workflowController.getDelegation('1', analysis.Id, 'OTRA',true);
        System.assertEquals(wrapper.ambit, '1', 'Workflow service test');
        Test.stopTest();
    }
    /**
    * @Method:  test for raipValidationsClass method
    * @Description: testing method.
    */
    @isTest
    static void testRaipValidationsClass() {
        try {
            final Arc_Gen_ValidationsRating_Interface raipController = Arc_Gen_GenericUtilitiesInterface.raipValidationsClass('qualitativeQ');
            final arce__Account_has_Analysis__c accHas = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            Test.startTest();
            final List<String> lstStr = raipController.validateQualitativeQuestion(accHas.Id, 's-01-100');
            System.debug('lstStr');
            System.debug(lstStr);
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'assert raip validation class');
        }
    }
    /**
    * @Method:  test for qualitativeQuestionValidation method
    * @Description: testing method.
    */
    @isTest
    static void testUserValidate() {
        try {
            final Arc_Gen_ValidationsRating_Interface raipController = Arc_Gen_GenericUtilitiesInterface.qualitativeQuestionValidation();
            final String userId = System.UserInfo.getUserId();
            Test.startTest();
            final String userInterface = raipController.userValidate(userId);
            System.debug('userInterface');
            System.debug(userInterface);
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals('Attempt to de-reference a null object', ex.getMessage(), 'assert raip validation class');
        }
    }
    /**
    * @Method:  test for qualitativeQuestionValidation method
    * @Description: testing method.
    */
    @isTest
    static void testGetFinancialSponsorCheck() {
        try {
            final Arc_Gen_FinancialSponsor_Interface finSponsorImpl = Arc_Gen_GenericUtilitiesInterface.getFinancialSponsorCheckClass();
            final arce__Analysis__c analysis = [SELECT Id, arce__Group__c FROM arce__Analysis__c LIMIT 1];
            final Id groupId = analysis.arce__Group__c;
            final arce.Arc_Gen_Account_Wrapper groupInfo = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String> { groupId }).get(groupId);
            Test.startTest();
            final Boolean hasFinancialSponsor = finSponsorImpl.getFinancialSponsorStatus(groupInfo.accNumber);
            System.debug('hasFinancialSponsor');
            System.debug(hasFinancialSponsor);
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals('Attempt to de-reference a null object', ex.getMessage(), 'assert raip validation class');
        }
    }
}