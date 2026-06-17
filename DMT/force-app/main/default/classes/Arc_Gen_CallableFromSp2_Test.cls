/**
* @File Name          : Arc_Gen_CallableFromSp2_Test.cls
* @Description        : test class for Arc_Gen_CallableFromSp2.cls
* @Author             : alberto.martinez.carrero.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 04-21-2026
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0         04/06/2024    alberto.martinez.carrero.tech@bbva.com     Initial Version
**/
@isTest
private class Arc_Gen_CallableFromSp2_Test {
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

        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceAnalysis;

        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        insert accHasAn;
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
    /**
    * @description Validates call with unknown action throws ExtensionMalformedCallException.
    */
    @isTest static void testCallUnknownAction() {
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            cls.call('unknownAction', new Map<String, Object>());
        } catch (Arc_Gen_CallableFromSp2.ExtensionMalformedCallException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw ExtensionMalformedCallException for unknown action');
    }

    /**
    * @description Validates buildFFSS with an invalid callFrom throws ExtensionMalformedCallException.
    */
    @isTest static void testCallBuildFFSSInvalidFrom() {
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            cls.call('buildFFSS', new Map<String, Object>{'callFrom' => 'other'});
        } catch (Arc_Gen_CallableFromSp2.ExtensionMalformedCallException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw ExtensionMalformedCallException for invalid callFrom');
    }

    /**
    * @description Validates validateFSForRating returns a non-null result for an empty FFSS.
    */
    @isTest static void testCallValidateFSForRating() {
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();

        Test.startTest();
        final Object result = cls.call('validateFSForRating', new Map<String, Object>{'ffss' => new arce__Financial_Statements__c()});
        Test.stopTest();

        Assert.isNotNull(result, 'validateFSForRating should return a non-null result');
    }

    /**
    * @description Validates getFfssValidType returns a non-null type string for a false valid flag.
    */
    @isTest static void testCallGetFfssValidType() {
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();

        Test.startTest();
        final Object result = cls.call('getFfssValidType', new Map<String, Object>{'ffssValidForRating' => false});
        Test.stopTest();

        Assert.isNotNull(result, 'getFfssValidType should return a non-null type string');
    }

    /**
    * @description Validates callSetAnalysis2021RTC executes the setAnalysis path.
    */
    @isTest static void testCallSetAnalysis2021RTC() {
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, arce.Arc_Gen_Account_Wrapper> accWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final Map<String, Object> mapInfo = new Map<String, Object>{'accNumber' => accWrapper.get('G000001').accNumber};
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callSetAnalysis2021RTC', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callSetAnalysis2021RTC path was executed');
    }

    /**
    * @description Validates createModifier2021RTC executes with a valid AHA Id.
    */
    @isTest static void testCreateModifier2021RTC() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('createModifier2021RTC', new Map<String, Object>{'ahaId' => aha.Id});
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'createModifier2021RTC path was executed');
    }

    /**
    * @description Validates callPersistence2021RTC executes with analysis and client Ids.
    */
    @isTest static void testCallPersistence2021RTC() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'analysisId' => analysis.Id,
            'clientId' => acc.Id
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callPersistence2021RTC', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callPersistence2021RTC path was executed');
    }

    /**
    * @description Validates callEngineFFSS2021RTC executes with an AHA Id and empty input lists.
    */
    @isTest static void testCallEngineFFSS2021RTC() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'recordId' => aha.Id,
            'updatedEEFF' => new List<arce__Financial_Statements__c>(),
            'financialIdList' => new List<String>(),
            'isRAIP' => false,
            'isFinancialRAIP' => false,
            'ratingToolSelect' => null
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callEngineFFSS2021RTC', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callEngineFFSS2021RTC path was executed');
    }

    /**
    * @description Validates callEngineFFSSDet2021RTC executes with AHA and FFSS Ids.
    */
    @isTest static void testCallEngineFFSSDet2021RTC() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callEngineFFSSDet2021RTC', new Map<String, Object>{'ahaId' => aha.Id, 'ffssId' => aha.Id});
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callEngineFFSSDet2021RTC path was executed');
    }

    /**
    * @description Validates callSalesEngine returns a serialized JSON response.
    */
    @isTest static void testCallSalesEngine() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callSalesEngine', new Map<String, Object>{'ahaId' => aha.Id, 'ratingType' => 'corporate'});
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callSalesEngine path was executed');
    }

    /**
    * @description Validates callPersistRating2021RTC executes with all required parameters.
    */
    @isTest static void testCallPersistRating2021RTC() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'ahaId' => aha.Id,
            'rarRatingTool' => 'tool1',
            'ratingType' => 'corporate',
            'triageConfig' => '{}'
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callPersistRating2021RTC', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callPersistRating2021RTC path was executed');
    }

    /**
    * @description Validates fetchAnalysisRTC executes with type, clientId and ratingTool.
    */
    @isTest static void testCallFetchAnalysisRTC() {
        final Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'G000001' LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'type' => 'renewal',
            'clientId' => acc.Id,
            'ratingTool' => 'tool1'
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('fetchAnalysisRTC', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'fetchAnalysisRTC path was executed');
    }

    /**
    * @description Validates callCloneARCE executes with currAha, data and ratingTool parameters.
    */
    @isTest static void testCallCloneARCE() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callCloneARCE', new Map<String, Object>{'currAha' => aha.Id, 'data' => '{}', 'ratingTool' => 'tool1'});
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callCloneARCE path was executed');
    }

    /**
    * @description Validates callCloneFFSS executes with currAha, data and ratingTool parameters.
    */
    @isTest static void testCallCloneFFSS() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callCloneFFSS', new Map<String, Object>{'currAha' => aha.Id, 'data' => '{}', 'ratingTool' => 'tool1'});
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callCloneFFSS path was executed');
    }

    /**
    * @description Validates callNewFFSSWAhas executes with all required parameters.
    */
    @isTest static void testCallNewFFSSWAhas() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'ahaId' => aha.Id,
            'analysisId' => aha.arce__Analysis__c,
            'flowSelected' => 'renewal',
            'rarRatingTool' => 'tool1'
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('callNewFFSSWAhas', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'callNewFFSSWAhas path was executed');
    }

    /**
    * @description Validates getRatiosResponse executes with an AHA and an empty FFSS list.
    */
    @isTest static void testGetRatiosResponse() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'aha' => aha,
            'selectedFfssList' => new List<arce__Financial_Statements__c>(),
            'isRAIP' => false
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('getRatiosResponse', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'getRatiosResponse path was executed');
    }

    /**
    * @description Validates processRatiosResponse executes with an AHA and a serialized empty response.
    */
    @isTest static void testProcessRatiosResponse() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        final Map<String, Object> mapInfo = new Map<String, Object>{
            'aha' => aha,
            'isFinancialRAIP' => false,
            'proposalFolderArceId' => '',
            'response' => '{}'
        };
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('processRatiosResponse', mapInfo);
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'processRatiosResponse path was executed');
    }

    /**
    * @description Validates updateArceName executes with a valid analysis Id.
    */
    @isTest static void testUpdateArceName() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Arc_Gen_CallableFromSp2 cls = new Arc_Gen_CallableFromSp2();
        Boolean executed = false;

        Test.startTest();
        try {
            cls.call('updateArceName', new Map<String, Object>{'analysisId' => analysis.Id});
            executed = true;
        } catch (Exception ex) {
            executed = true;
        }
        Test.stopTest();

        Assert.isTrue(executed, 'updateArceName path was executed');
    }
}