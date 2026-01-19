/**
* @File Name          : Arc_Gen_CallableFromSp2_Test.cls
* @Description        : test class for Arc_Gen_CallableFromSp2.cls
* @Author             : alberto.martinez.carrero.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 05-26-2025
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0         04/06/2024    alberto.martinez.carrero.tech@bbva.com     Initial Version
**/
@isTest
public with sharing class Arc_Gen_CallableFromSp2_Test {
    /**
    * @description testSetup
    * @author alberto.martinez.carrero.tech@bbva.com
    **/
    @TestSetup
    static void testSetup() {
        final Account acc = new Account();
        acc.Name = 'TestAcc';
        acc.AccountNumber = 'CAONlXcCA_uxyJ402AA_xw';
        insert acc;
    }
    /**
    * @description test method for Arc_Gen_CallableFromSp2 class
    * @author alberto.martinez.carrero.tech@bbva.com
    **/
    @isTest
    public static void test1() {
        final Account acc = [SELECT Id,AccountNumber FROM Account WHERE name = 'TestAcc' LIMIT 1];
        Test.startTest();
        final Map<String, Object> servResp = callFinStateServ(acc.AccountNumber);
        final Map<String, Object> mapInfo = new Map<String, Object>();
        mapInfo.put('servResp', servResp);
        mapInfo.put('auditorOp', 200);
        mapInfo.put('callFrom', 'proposal');
        final Arc_Gen_CallableFromSp2 callableClass = new Arc_Gen_CallableFromSp2();
        final arce__Financial_Statements__c ffss = (arce__Financial_Statements__c) callableClass.call('buildFFSS', mapInfo);
        mapInfo.put('ffss', ffss);
        final Boolean validateFSRating = (Boolean) callableClass.call('validateFSForRating', mapInfo);
        mapInfo.put('ffssValidForRating', validateFSRating);
        final String validType = (String) callableClass.call('getFfssValidType', mapInfo);

        System.assert(String.isNotBlank(validType), 'Assert Error in buildFFSSTest');
        Test.stopTest();
    }
    /**
    * @description callFinStateServ
    * @author alberto.martinez.carrero.tech@bbva.com
    **/
    public static Map<String, Object> callFinStateServ(String accNumber) {
        final String paramsJson = '{"customerId":"' + accNumber + '"}';
        final arce.Arc_Gen_getIASOResponse.ServiceResponse response = arce.Arc_Gen_getIASOResponse.calloutIASO('financialStatements', paramsJson);
        final Map<String, Object> serviceResponse = response.serviceResponse;
        final List<Object> listServiceResp = (List<Object>) serviceResponse.get('data');
        return (Map<String, Object>) listServiceResp[0];
    }
}