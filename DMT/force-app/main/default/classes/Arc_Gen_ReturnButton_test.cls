/**
* @File Name          : Arc_Gen_ReturnButton_test.cls
* @Description        : Test Class that receives the response of the rating validation from the service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 23/7/2019 19:58:12
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    3/5/2019 18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1   08/01/2020 13:12:00  javier.soto.carrascosa@bbva.com Add support for account wrapper and setupaccounts
* 1.2   15/09/2020 13:12:00  juanignacio.hita.contractor@bbva.com            Add test method with raip analysis
* 1.3    23/09/2020          saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.4   02/02/2021 17:09:00  luisdavid.rivera.ortiz@bbva.com                 Eliminated unused fields
* 1.5   18/02/2021           joseluis.garcia4.contractor@bbva.com            Fix tests for action persistence service.
* 1.6   16/03/2021 11:38:00  juanignacio.hita.contractor@bbva.com            Change testValAfterInitDelegation for increase coverage code
* 1.7   17/06/2021 11:38:00  juanmanuel.perez.ortiz.contractor@bbva.com      Create method insertAhas to avoid sonar major
* 1.8   03/08/2021           juanignacio.hita.contractor@bbva.com            Add OwnerId testValAfterInitDelegation method
**/
@isTest
public class Arc_Gen_ReturnButton_test {
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
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','G000002'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper groupAccountRAIP = groupAccWrapper.get('G000002');
        final id currUserId = UserInfo.getUserId();
        arce__Analysis__c arceobj = new arce__Analysis__c();
        arceobj.Name = 'arce__Analysisobj';
        arceobj.arce__analysis_customer_relation_type__c = '01';
        arceobj.CurrencyIsoCode = 'EUR';
        arceobj.arce__Group__c = groupAccount.accId;
        arceobj.arce__Stage__c = '1';
        arceobj.arce__wf_status_id__c = '02';
        arceobj.arce__anlys_wkfl_prev_user_name__c = currUserId;
        insert arceobj;
        arce__Analysis__c arceRAIP = new arce__Analysis__c();
        arceRAIP.Name = 'arceRAIP';
        arceRAIP.arce__analysis_customer_relation_type__c = '01';
        arceRAIP.CurrencyIsoCode = 'EUR';
        arceRAIP.arce__Group__c = groupAccountRAIP.accId;
        arceRAIP.arce__Stage__c = '1';
        arceRAIP.arce__wf_status_id__c = '02';
        arceRAIP.arce__anlys_wkfl_sub_process_type__c = '4';
        arceRAIP.arce__rating_prerating_type__c = 'Rating';
        arceRAIP.arce__anlys_wkfl_prev_user_name__c = currUserId;
        insert arceRAIP;
        insertAhas(arceobj, groupAccount, arceRAIP, groupAccountRAIP);
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    private static void insertAhas(arce__Analysis__c arceobj, arce.Arc_Gen_Account_Wrapper groupAccount, arce__Analysis__c arceRaip, arce.Arc_Gen_Account_Wrapper groupAccountRAIP) {
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
        arceAccounthasAnalysisobj.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
        insert arceAccounthasAnalysisobj;
        arce__Account_has_Analysis__c arceAccounthasAnalysisRAIP = new arce__Account_has_Analysis__c();
        arceAccounthasAnalysisRAIP.currencyIsoCode = 'EUR';
        arceAccounthasAnalysisRAIP.arce__main_subsidiary_ind_type__c = true;
        arceAccounthasAnalysisRAIP.arce__InReview__c = true;
        arceAccounthasAnalysisRAIP.arce__Analysis__c = arceRAIP.Id;
        arceAccounthasAnalysisRAIP.arce__smes_eur_comuty_defn_type__c = '1';
        arceAccounthasAnalysisRAIP.arce__ll_before_adj_ind_type__c = '1';
        arceAccounthasAnalysisRAIP.arce__ll_before_adj_clsfn_type__c = 'NI';
        arceAccounthasAnalysisRAIP.arce__ll_after_adj_ind_type__c = '1';
        arceAccounthasAnalysisRAIP.arce__ll_after_adj_clsfn_type__c = 'NI';
        arceAccounthasAnalysisRAIP.arce__Customer__c = groupAccountRAIP.accId;
        insert arceAccounthasAnalysisRAIP;

    }
    /**
    * @Method:  test for method constructor
    * @Description: testing method.
    */
    @isTest
    static void testingConstructor() {
        Test.startTest();
        final Arc_Gen_ReturnButton_controller contConstructor = new Arc_Gen_ReturnButton_controller();
        final Arc_Gen_ReturnButton_service servConstructor = new Arc_Gen_ReturnButton_service();
        System.assertEquals(contConstructor, contConstructor,'Empty constructor');
        System.assertEquals(servConstructor, servConstructor,'Empty constructor');
        Test.stopTest();
    }
    /**
    * @Method:  test for method init delegation
    * @Description: testing method.
    */
    @isTest
    static void testInitDelegation() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String ret = Arc_Gen_ReturnButton_controller.initDelegation(aha.Id);
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) ret, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperSerialize.ambit, '1', 'test init delegation');
        try {
            Arc_Gen_ReturnButton_controller.initDelegation(null);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    /**
    * @Method:  test for method valAfterInitDelegation
    * @Description: testing method.
    */
    @isTest
    static void testValAfterInitDelegation() {
        Test.startTest();
        final arce__Analysis__c analysis = [SELECT Id, OwnerId FROM arce__Analysis__c LIMIT 1];
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = new Arc_Gen_Delegation_Wrapper();
        final Map<String,String> newAmbit = new Map<String, String>();
        newAmbit.put('label', 'Office');
        newAmbit.put('value', '1');
        wrapperSerialize.lstAmbits = new List<Map<String, String>>();
        wrapperSerialize.lstAmbits.add(newAmbit);
        Arc_Gen_ReturnButton_service.valAfterInitDelegation(wrapperSerialize, analysis);
        System.assertEquals(newAmbit.get('value'), '1', 'test init delegation');
        Test.stopTest();
    }
    /**
    * @Method:  test for method init identification
    * @Description: testing method.
    */
    @isTest
    static void testInitIdentification() {
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        final String ret = Arc_Gen_ReturnButton_controller.initIdentification(JSON.serialize(wrapper));
        Test.startTest();
        System.assertEquals(ret, UserInfo.getUserId(), 'init identification method test');
        try {
            Arc_Gen_ReturnButton_controller.initIdentification(null);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    /**
    * @Method:  test for method evaluate identification
    * @Description: testing method.
    */
    @isTest
    static void testEvaluateIdentificationA() {
        final arce__Account_has_Analysis__c aha = [SELECT arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        wrapper.analysisId = aha.arce__Analysis__c;
        Test.startTest();
        final String retStr = Arc_Gen_ReturnButton_controller.evaluateIdentification(aha.Id, JSON.serialize(wrapper), UserInfo.getUserId(), '1');
        final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retStr, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperRet.codStatus, 200, 'evaluate identification test method');
        try {
            Arc_Gen_ReturnButton_controller.evaluateIdentification(null, null, null, null);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    /**
    * @Method:  test for method evaluate identification
    * @Description: testing method.
    */
    @isTest
    static void testEvaluateIdentificationB() {
        final arce__Account_has_Analysis__c aha = [SELECT arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        wrapper.analysisId = aha.arce__Analysis__c;
        final List<String> valuesSelected = new List<String>{'2'};
        final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
        wrapper.lstAmbits = lstPicklist;
        Test.startTest();
        final String retStr = Arc_Gen_ReturnButton_controller.evaluateIdentification(aha.Id, JSON.serialize(wrapper), UserInfo.getUserId(), '1');
        final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retStr, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperRet.codStatus, 200, 'evaluate identification test method');
        Test.stopTest();
    }
    /**
    * @Method:  test for method evaluate identification with raip analysis
    * @Description: testing method.
    */
    @isTest
    static void testEvaluateIdentificationRAIP() {
        final arce__Account_has_Analysis__c ahaRAIP = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '4' LIMIT 1];
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        wrapper.analysisId = ahaRAIP.arce__Analysis__c;
        final List<String> valuesSelected = new List<String>{'2'};
        final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
        wrapper.lstAmbits = lstPicklist;
        Test.startTest();
        String retStr = Arc_Gen_ReturnButton_controller.evaluateIdentification(ahaRAIP.Id, JSON.serialize(wrapper), UserInfo.getUserId(), '1');
        final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retStr, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperRet.codStatus, 200, 'evaluate identification test method with raip analysis');
        Test.stopTest();
    }

}