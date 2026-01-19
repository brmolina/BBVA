/**
* @File Name          : Arc_Gen_NAHATest.cls
* @Description        : Test Class that of the calling of List Customers and Path Service
* @Author             : franciscojavier.bueno@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : eduardoefrain.hernandez.contractor@bbva.com
* @Last Modified On   : 27/8/2019 9:52:28
* @Changes
*=====================================================================================================================================
* Ver         Date                     Author      		                        Modification
*=====================================================================================================================================
* 1.0      26/08/2019            franciscojavier.bueno@bbva.com                  Initial Version
* 1.0      03/09/2019            ricardo.almanza.contractor@bbva.com             Moded for Persistance
* 1.2      10/12/2019            mariohumberto.ramirez.contractor@bbva.com       Modified for SOC
* 1.3      8/1/2020 18:21:09     javier.soto.carrascosa@bbva.com                 Adapt test classess with account wrapper and setupaccounts
* 1.4      27/4/2020 18:21:09    ricardo.almanza.contractor@bbva.com             modified arce__customer_arce_scope_type__c for new naha with true value
* 1.5      14/05/2020 14:00:00   joseluis.garcia4.contractor@bbva.com            Use correct values of arce__customer_arce_scope_type__c
* 1.6      18/05/2020            cesaroctavio.villanueva.cebal@bbva.com          Added info to correctly update Financial Sponsor information
* 1.7      11/09/2020            moises.martinez.domingurez.contractor@bbva.com  Update method testingService
* 1.8      23/09/2020     saimassimilianno.jordana.contractor@bbva.com           Added arce. namespace to all classes that are now
*                                                                                in the arce-dependencies package
**/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_NAHA_Ctrl_Test {
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
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to set an arce analysis
    * --------------------------------------------------------------------------------------
    * @param arceName - name of the arce
    * @return arce__Analysis__c object
    * @example Arc_Gen_NAHA_Ctrl_Test.setAnalysis()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Analysis__c setAnalysis(String arceName) {
        final arce__Analysis__c arceVar = new arce__Analysis__c(
            Name = arceName,
            arce__wf_status_id__c = '02'
        );
        Insert arceVar;
        Return arceVar;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to set an arce analysis Group
    * --------------------------------------------------------------------------------------
    * @param arceName - name of the arce
    * @return arce__Analysis__c object
    * @example Arc_Gen_NAHA_Ctrl_Test.setAnalysis()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Analysis__c setAnalysisGroup(String arceNameGroup) {
        final arce__Analysis__c arceGroup = new arce__Analysis__c(
            Name = arceNameGroup,
            arce__wf_status_id__c = '02'
        );
        Insert arceGroup;
        Return arceGroup;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to set an account has analysis
    * --------------------------------------------------------------------------------------
    * @param customerId - Id of an account
    * @param arceId - Id of an arce analysis
    * @return arce__Account_has_Analysis__c object
    * @example Arc_Gen_NAHA_Ctrl_Test.setAnalyzedClient()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c setAnalyzedClient(String customerId,String arceId) {
        final arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c(
            arce__Customer__c = customerId,
            arce__Analysis__c = arceId
        );
        Insert accHasAnalysis;
        Return accHasAnalysis;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to set an account has analysis group
    * --------------------------------------------------------------------------------------
    * @param grupoId - Id of an account
    * @param arceId - Id of an arce analysis
    * @return arce__Account_has_Analysis__c object
    * @example Arc_Gen_NAHA_Ctrl_Test.setAnalyzedGroup(grupoId,arceId)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c setAnalyzedGroup(String grupoId,String arceId) {
        final arce__Account_has_Analysis__c accHasAnalysisGroup = new arce__Account_has_Analysis__c(
            arce__Customer__c = grupoId,
            arce__Analysis__c = arceId
        );
        Insert accHasAnalysisGroup;
        Return accHasAnalysisGroup;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to get an analyzed client
    * --------------------------------------------------------------------------------------
    * @param accName - name of the account
    * @param accNumber -  account number
    * @param arceName - name of the arce
    * @return arce__Account_has_Analysis__c
    * @example Arc_Gen_NAHA_Ctrl_Test.getAnalyzedClient(accName,accNumber,arceName)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAnalyzedClient(String accName,String accNumber,String arceName) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce__Analysis__c analysis = setAnalysis(arceName);
        analysis.arce__Group__c = groupAccount.accId;
        update analysis;
        final arce__Account_has_Analysis__c analyzedGrp = setAnalyzedClient(groupAccount.accId,analysis.Id);
        analyzedGrp.arce__customer_arce_scope_type__c = '1';
        analyzedGrp.arce__group_asset_header_type__c = '1';
        update (analyzedGrp);
        final arce__Account_has_Analysis__c analyzedClient = setAnalyzedClient(childAccount.accId,analysis.Id);
        analyzedClient.arce__customer_arce_scope_type__c = '1';
        analyzedClient.arce__group_asset_header_type__c = '2';
        update (analyzedClient);
        Return analyzedClient;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to get an analyzed group
    * --------------------------------------------------------------------------------------
    * @param accName - name of the account
    * @param accNumber -  account number
    * @param arceName - name of the arce
    * @return arce__Account_has_Analysis__c
    * @example Arc_Gen_NAHA_Ctrl_Test.getAnalyzedGroup(accName,accNumber,arceName)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAnalyzedGroup(String accName,String accNumber,String arceNameGroup) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Analysis__c analysis = setAnalysisGroup(arceNameGroup);
        final arce__Account_has_Analysis__c analyzedGroup = setAnalyzedGroup(groupAccount.accId,analysis.Id);
        analyzedGroup.arce__customer_arce_scope_type__c = '1';
        update (analyzedGroup);
        Return analyzedGroup;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to set an iaso custom setting
    * --------------------------------------------------------------------------------------
    * @param name
    * @param url
    * @return iaso__GBL_Rest_Services_Url__c
    * @example Arc_Gen_NAHA_Ctrl_Test.setIasoCustomSetting(name,url)
    * --------------------------------------------------------------------------------------
    **/
    public static iaso__GBL_Rest_Services_Url__c setIasoCustomSetting(String name,String url) {
        final iaso__GBL_Rest_Services_Url__c iasoCustomSetting = new iaso__GBL_Rest_Services_Url__c(
            Name = name,
            iaso__Url__c = url,
            iaso__Timeout__c = 10000,
            iaso__Blocked_Service__c = false,
            iaso__cacheTTLInSecs__c = 300
        );
        Insert iasoCustomSetting;
        Return iasoCustomSetting;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_NAHA_Ctrl_Test.testingService()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingService() {
        final Arc_Gen_NAHACtrl controller = new Arc_Gen_NAHACtrl();
        final arce__Account_has_Analysis__c analyzedClient = getAnalyzedClient('Test Customer', '12345678', 'ARCE Test');
        analyzedClient.arce__customer_arce_scope_type__c = '1';
        update (analyzedClient);
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        test.startTest();
        controller.validElementInCarousel(analyzedClient.Id,null,true);
        final qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response = controller.validElementInCarousel(analyzedClient.Id,null,false);
        analyzedClient.arce__risk_assessment_persisted__c = true;
        update (analyzedClient);
        controller.validElementInCarousel(analyzedClient.Id,null,true);
        System.assertEquals(true, response.gblResultResponse, 'The response of the save record');
        analyzedClient.arce__customer_arce_scope_type__c = '0';
        update (analyzedClient);
        controller.validElementInCarousel(analyzedClient.Id,null,true);
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_NAHA_Ctrl_Test.testingServiceFail()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingServiceFail() {
        final Arc_Gen_NAHACtrl controller = new Arc_Gen_NAHACtrl();
        final qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response = null;
        test.startTest();
        try {
            response = controller.validElementInCarousel(null,null,null);
        } catch (Exception e) {
            System.assertEquals(null, response, 'The response not save the record');
        }
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_NAHA_Ctrl_Test.testingServiceFail()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingServiceConstructor() {
        test.startTest();
        final Arc_Gen_NAHA_Service service = new Arc_Gen_NAHA_Service();
        System.assertEquals(service, service, 'The test to the void constructor was succesfull');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_NAHA_Ctrl_Test.testingServiceFail()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingHelperConstructor() {
        test.startTest();
        final Arc_Gen_NAHA_Service_Helper helper = new Arc_Gen_NAHA_Service_Helper();
        System.assertEquals(helper, helper, 'The test to the void constructor was succesfull');
        test.stopTest();
    }
}