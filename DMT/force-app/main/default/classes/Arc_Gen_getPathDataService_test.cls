/**
* @File Name          : Arc_Gen_getPathDataService_test.cls
* @Description        : Test class for Rating Service
* @Author             : luisruben.quinto.munoz@bbva.com
* @Group              : ARCE
* @Last Modified By   : javier.soto.carrascosa@bbva.com
* @Last Modified On   : 12/04/2020 00:00:00
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                      Modification
*==============================================================================
* 1.0    12/7/2019  18:18:07  luisruben.quinto.munoz@bbva.com                 Initial Version
* 1.1    23/7/2019  18:04:16  eduardoefrain.hernandez.contractor@bbva.com     Added comments and upgrades test coverage
* 1.2    8/1/2020   18:21:09  javier.soto.carrascosa@bbva.com                 Adapt test classess with account wrapper and setupaccounts
* 1.3    29/1/2020  18:21:09  javier.soto.carrascosa@bbva.com                 Recover boolean saveobject
* 1.4    04/02/2020 12:53:11  juanmanuel.perez.ortiz.contractor@bbva.com      Add two new parameters in setupPath() and created
*                                                                             SetupPathWrapper to avoid 'long parameter lists'
* 1.5    12/04/2020 00:00:00  javier.soto.carrascosa@bbva.com                 Add support to retrieve local field from risk assessment location
* 1.5    23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now
*                                                                             in the arce-dependencies package
**/
@isTest
public class Arc_Gen_getPathDataService_test {
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
    * @Description setAnalysis method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @param String name
    * @example setAnalysis(String name)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Analysis__c setAnalysis(String name) {
        final arce__Analysis__c analysis = new arce__Analysis__c(
            Name = name
        );
        insert analysis;
        return analysis;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description setAnalyzedClient method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @param String clientId,String analysisId
    * @example setAnalyzedClient(String clientId,String analysisId)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c setAnalyzedClient(String clientId,String analysisId) {
        final arce__Account_has_Analysis__c analyzedClient = new arce__Account_has_Analysis__c(
            arce__Customer__c = clientId,
            arce__Analysis__c = analysisId
        );
        insert analyzedClient;
        return analyzedClient;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description getAnalyzedClient method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @param String accNumber,String analysisName,String accParentId
    * @example getAnalyzedClient(String accNumber,String analysisName,String accParentId)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAnalyzedClient(String accNumber,String analysisName,String accParentId) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{accNumber});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(accNumber);
        final arce__Analysis__c analysis = setAnalysis(analysisName);
        return setAnalyzedClient(groupAccount.accId,analysis.Id);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description setIasoCustomSetting method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @param String name,String url
    * @example setIasoCustomSetting(String name,String url)
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
        insert iasoCustomSetting;
        return iasoCustomSetting;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description getIasoAuthMtd method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @param String name
    * @example getIasoAuthMtd(String name)
    * --------------------------------------------------------------------------------------
    **/
    public static iaso__GBL_Authentication_Service__mdt getIasoAuthMtd(String name) {
        return [SELECT DeveloperName,iaso__Apex_Class__c,iaso__Cache_Key__c,iaso__Cache_Partition__c,iaso__CryptoKey__c,iaso__Custom_Setting__c,iaso__Header_Token__c,iaso__isOrgCache__c,iaso__Password__c,iaso__Service_Parameters__c,iaso__User__c FROM iaso__GBL_Authentication_Service__mdt WHERE DeveloperName =: name];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description getIasoIntegrationMtd method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @param String name
    * @example getIasoIntegrationMtd(String name)
    * --------------------------------------------------------------------------------------
    **/
    public static iaso__GBL_integration_service__mdt getIasoIntegrationMtd(String name) {
        return [SELECT DeveloperName,iaso__Authentication_Service__c,iaso__Blocked_Service__c,iaso__Custom_Setting__c,iaso__Headers_Class__c,iaso__Http_Headers_LTA_TEMP__c,iaso__Http_Headers_LTA__c,iaso__Http_Method__c,iaso__Json_Input_Template_LTA_TEMP__c,iaso__Json_Input_Template_LTA__c,iaso__Mock_LTA_TEMP__c,iaso__Mock_LTA__c,iaso__Querystring_Input_Template_LTA_TEMP__c,iaso__Querystring_Input_Template_LTA__c,iaso__Retrieve_Mock_LTA_TEMP__c,iaso__Retrieve_Mock_LTA__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =: name];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description testingDML method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingDML() {
        final Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
        arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
        final Arc_Gen_getPathDataService_data.saveResult saveRes = new Arc_Gen_getPathDataService_data.saveResult();
        final Arc_Gen_getPathDataService_service service = new Arc_Gen_getPathDataService_service();
        insert(Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings());
        final arce__Account_has_Analysis__c accHasAnalysis1 = getAnalyzedClient(GROUP_ID,null,null);
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final account accToUpd1 = new Account(Id=groupAccount.accId);
        final Arc_Gen_getPathDataService_service.SetupPathWrapper pathParamGroup = new Arc_Gen_getPathDataService_service.SetupPathWrapper();
        pathParamGroup.analysisId = (String)accHasAnalysis1.arce__Analysis__c;
        pathParamGroup.customerId = (String)accHasAnalysis1.arce__Customer__c;
        pathParamGroup.clientNumber = GROUP_ID;
        pathParamGroup.subsidiary = System.Label.Cls_arce_PathGroup;
        pathParamGroup.saveobject = true;
        service.setupPath(pathParamGroup);
        final arce__Account_has_Analysis__c accHasAnalysis2 = getAnalyzedClient(SUBSIDIARY_ID,null,groupAccount.accId);
        final Arc_Gen_getPathDataService_service.SetupPathWrapper pathParamSub = new Arc_Gen_getPathDataService_service.SetupPathWrapper();
        pathParamSub.analysisId = (String)accHasAnalysis2.arce__Analysis__c;
        pathParamSub.customerId = (String)accHasAnalysis2.arce__Customer__c;
        pathParamSub.clientNumber = SUBSIDIARY_ID;
        pathParamSub.subsidiary = System.Label.Cls_arce_PathSubsidiary;
        pathParamSub.saveobject = true;
        service.setupPath(pathParamSub);
        final List<Account> accsToUpdate = new List<Account>();
        accsToUpdate.add(accToUpd1);
        saveRes.status = 'true';
        saveRes.message = 'true';
        final Map<String, Object> mps = new Map<String, Object>();
        saveRes.updatefields = mps ;
        test.startTest();
        result = locator.updateRecords(accsToUpdate);
        System.assertEquals('true', result.saveStatus, 'The DML status is wrong because of null parameter, the response is false');
        test.stopTest();
    }
    @isTest
    static void testingDMLError() {
        arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
        final Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
        final arce__analysis__c arceIns = new arce__analysis__c(Name = 'Test1');
        insert arceIns;
        arceIns.Name = '12345678901234567890121234567890123456789012123456789012345678901212345678901234567890121234567890123456789012';
        final List<arce__analysis__c> arceUp = new List<arce__analysis__c>();
        arceUp.add(arceIns);
        test.startTest();
        result = locator.updateRecords(arceUp);
        System.assertEquals('false', result.saveStatus, 'The DML status is wrong because of null parameter, the response is false');
        test.stopTest();
    }
    @isTest
    static void testingGetCustomerData() {
        insert(Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings());
        final arce__Account_has_Analysis__c accHasAnalysis1 = getAnalyzedClient(GROUP_ID,null,null);
        final arce__Account_has_Analysis__c accHasAnalysis2 = getAnalyzedClient(SUBSIDIARY_ID,null,null);
        test.startTest();
        final list<String> data1 = Arc_Gen_getPathDataService_service.getCustomerData(accHasAnalysis1.Id);
        final String data3 = Arc_Gen_getPathDataService_service.getCustomerNumber(accHasAnalysis2.arce__Analysis__c, accHasAnalysis2.arce__Customer__c);
        System.assertEquals(data1[0], data1[0], 'Obtains the externalid from an AccountHasAnalysis');
        System.assertEquals(SUBSIDIARY_ID, data3, 'Obtains the externalid from an ARCE');
        test.stopTest();
    }
}