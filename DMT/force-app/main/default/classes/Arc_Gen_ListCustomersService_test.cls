/**
* @File Name          : arce.Arc_Gen_getRatingDataService_data.cls
* @Description        : Test class that of the calling of List Customers Service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 23/7/2019 22:38:11
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 17:59:32   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.0    30/4/2019 17:59:32   eduardoefrain.hernandez.contractor@bbva.com     modification to add list customer logic
* 1.2    07/01/2020 13:12:00  javier.soto.carrascosa@bbva.com                 Add support for account wrapper and setupaccounts
* 1.3    27/04/2020 13:12:00  ricardo.almanza.contractor@bbva.com             modified for naha arce__customer_arce_scope_type__c
* 1.4    14/05/2020 14:00:00  joseluis.garcia4.contractor@bbva.com            Use correct values of arce__customer_arce_scope_type__c
* 1.4    23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
**/
@isTest
public class Arc_Gen_ListCustomersService_test {
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
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        Arc_UtilitysDataTest_tst.setupAcccounts();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description setAnalysis
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param String arceName
    * @return arce__Analysis__c
    * @example setAnalysis()
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
    * @Description setAnalyzedClient
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param String customerId
    * @param String arceId
    * @param String assetHeader
    * @return arce__Account_has_Analysis__c
    * @example setAnalyzedClient()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c setAnalyzedClient(String customerId,String arceId,String assetHeader) {
        arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c(
            arce__Customer__c = customerId,
            arce__Analysis__c = arceId,
            arce__group_asset_header_type__c = assetHeader
        );
        Insert accHasAnalysis;
        Return accHasAnalysis;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description setAnalyzedClient
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param String customerId
    * @param String arceId
    * @param String assetHeader
    * @return arce__Account_has_Analysis__c
    * @example setAnalyzedClient()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAnalyzedClient(String accNumber,String arceId,String assetHeader) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{accNumber});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(accNumber);
        arce__Account_has_Analysis__c analyzedClient = setAnalyzedClient(groupAccount.accId,arceId,assetHeader);
        Return analyzedClient;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description setIasoCustomSetting
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param String name
    * @param String url
    * @return iaso__GBL_Rest_Services_Url__c
    * @example setIasoCustomSetting()
    * --------------------------------------------------------------------------------------
    **/
    public static iaso__GBL_Rest_Services_Url__c setIasoCustomSetting(String name,String url) {
        iaso__GBL_Rest_Services_Url__c iasoCustomSetting = new iaso__GBL_Rest_Services_Url__c(
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
    * @Description testingListCustomers
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param void
    * @return void
    * @example testingListCustomers()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingListCustomers() {
        Arc_Gen_NAHACtrl controller = new Arc_Gen_NAHACtrl();
        final arce__Analysis__c arceVar = setAnalysis('ARCE 1');
        final arce__Account_has_Analysis__c analyzedClient = getAnalyzedClient(SUBSIDIARY_ID, arceVar.Id, '2');
        analyzedClient.arce__customer_arce_scope_type__c = '1';
        update (analyzedClient);
        List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        test.startTest();
        qvcd.GBL_CardDetails_Ctrl.CardPagerWrapper response = controller.validElementInCarousel(analyzedClient.Id,null,false);
        System.assertEquals(true, response.gblResultResponse, 'The response of the save record');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description testingDML
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2019-07-23
    * @param void
    * @return void
    * @return arce__Account_has_Analysis__c
    * @example testingDML()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingDML() {
        Arc_Gen_ListCustomersService_data locator = new Arc_Gen_ListCustomersService_data();
        Arc_Gen_ListCustomersService_data.saveResult sr = new Arc_Gen_ListCustomersService_data.saveResult();
        arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
        Arc_Gen_ListCustomersService_service service = new Arc_Gen_ListCustomersService_service();
        arce__analysis__c arceIns = new arce__analysis__c(Name = 'Test1');
        insert arceIns;
        arceIns.Name = '12345678901234567890121234567890123456789012123456789012345678901212345678901234567890121234567890123456789012';
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        sr.status = 'true';
        sr.message = 'true';
        Test.startTest();
        result = locator.updateRecord(arceIns);
        Insert(Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings());
        service.setupListCustomers(groupAccount.accNumber, true);
        System.assertEquals('false', result.saveStatus, 'The update send a false because there is an error in the DML operation');
        Test.stopTest();
    }
}