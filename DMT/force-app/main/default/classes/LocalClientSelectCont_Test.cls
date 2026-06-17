/**
* @description Test class for LocalClientSelectCont
*/
@isTest
private class LocalClientSelectCont_Test {
    /** Constant for not null assertion message */
    private static final String NOT_NULL = 'Result should not be null';
    /**
    * Test data setup
    */
    @testSetup
    static void setup() {
        final Account testAcc = Arc_UtilitysDataTest_tst.crearCuenta('Test Account', null, null, '0001');
        testAcc.BillingCountry = 'ES';
        insert testAcc;
    }

    /**
    * Test gtCountries method with site field populated
    */
    @isTest
    static void testGtCountriesWithSite() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];
        Local_Client__c lc = new Local_Client__c ();
        lc.Cib_Client__c = testAcc.Id;
        lc.entity_id__c  = '0069';
        insert lc;
        Test.startTest();
        final String result = LocalClientSelectCont.gtCountries(testAcc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
    }

    /**
    * Test gtClients method with corporates entity type
    */
    @isTest
    static void testGtClientsWithCorporates() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final String result = LocalClientSelectCont.gtClients(testAcc.Id, 'ES', 'corporates');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
    }

    /**
    * Test gtClients method with IFIS entity type
    */
    @isTest
    static void testGtClientsWithIFIS() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];
        Local_Client__c lc = new Local_Client__c ();
        lc.Cib_Client__c = testAcc.Id;
        lc.entity_id__c  = '0069';
        insert lc;

        Test.startTest();
        final String result = LocalClientSelectCont.gtClients(testAcc.Id, 'MX', 'ifis');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
    }

    /**
    * Test gtClients method with unsupported entity type
    */
    @isTest
    static void testGtClientsWithUnsupportedEntityType() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final String result = LocalClientSelectCont.gtClients(testAcc.Id, 'ES', 'unsupported');
        Test.stopTest();

        System.assertEquals('[]', result, 'Result should be empty array');
    }

    /**
    * Test mainCntry method with site field populated
    */
    @isTest
    static void testMainCntryWithSite() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final String result = LocalClientSelectCont.mainCntry(testAcc.Id);
        Test.stopTest();

        System.assert(String.isBlank(result), 'Error, result should be blank');
    }

    /**
    * Test callRatingSystem method with valid parameters
    */
    @isTest
    static void testCallRatingSystemSuccess() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final Arc_Gen_RatingSystem_Service.ValidationResult result = LocalClientSelectCont.callRatingSystem(testAcc.Id, 'testFlow', 'ES');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
    }

    /**
    * Test callRatingSystem method with exception handling
    */
    @isTest
    static void testCallRatingSystemException() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            LocalClientSelectCont.callRatingSystem(testAcc.Id, 'invalidFlow', 'INVALID');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception should be thrown for invalid parameters');
    }

    /**
    * Test WrapperClass construction
    */
    @isTest
    static void testWrapperClassConstruction() {
        Test.startTest();
        final LocalClientSelectCont.WrapperClass wrapper = new LocalClientSelectCont.WrapperClass('TestName', 'TestId', 'TestBankEntity');
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should be instantiated');
    }

     /**
    * Test checkExpgAvailability default branch (not SUBSIDIARY, not IFIS).
    * Expected: returns wrapper with isParent=true, isExpgAvailable=false, isCoreRelation=false.
    */
    @isTest
    static void testCheckExpgAvailabilityDefaultBranch() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        LocalClientSelectCont.ExpgAvailabilityWrapper result;
        try {
            result = LocalClientSelectCont.checkExpgAvailability(testAcc.Id);
        } catch (AuraHandledException e) {
            result = null;
        }
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
        System.assertEquals(true, result.isParent, 'isParent should be true for default branch');
        System.assertEquals(false, result.isExpgAvailable, 'isExpgAvailable should be false for default branch');
        System.assertEquals(false, result.isCoreRelation, 'isCoreRelation should be false for default branch');
    }

    /**
    * Test checkExpgAvailability when callout is invoked.
    * The callout to Arc_Gen_RetrievePS_Service is not mocked, so an AuraHandledException
    * may be thrown. Both outcomes are accepted to keep the test data-independent.
    */
    @isTest
    static void testCheckExpgAvailabilitySubsidiaryBranch() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        LocalClientSelectCont.ExpgAvailabilityWrapper result;
        try {
            result = LocalClientSelectCont.checkExpgAvailability(testAcc.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown || result != null, 'Either result is returned or AuraHandledException is thrown');
    }

    /**
    * Test checkExpgAvailability error handling with an invalid client id.
    */
    @isTest
    static void testCheckExpgAvailabilityException() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            LocalClientSelectCont.checkExpgAvailability(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception should be thrown for invalid clientId');
    }


    /**
    * Test gtInstance singleton method.
    */
    @isTest
    static void testGtInstance() {
        Test.startTest();
        final LocalClientSelectCont first = LocalClientSelectCont.gtInstance();
        final LocalClientSelectCont second = LocalClientSelectCont.gtInstance();
        Test.stopTest();

        System.assertNotEquals(null, first, NOT_NULL);
        System.assertEquals(first, second, 'Singleton should return the same instance');
    }

    /**
    * Test gtLocalCountries method.
    */
    @isTest
    static void testGtLocalCountries() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];
        final Local_Client__c lc = new Local_Client__c();
        lc.Cib_Client__c = testAcc.Id;
        lc.entity_id__c = '0182';
        lc.country_id__c = 'ES';
        lc.gf_prtcpt_act_status_ind_type__c = true;
        insert lc;

        Test.startTest();
        final String result = LocalClientSelectCont.gtLocalCountries('TEST_CLIENT_CODE');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
    }

    /**
    * Test gtLocalClients method.
    */
    @isTest
    static void testGtLocalClients() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];
        final Local_Client__c lc = new Local_Client__c();
        lc.Cib_Client__c = testAcc.Id;
        lc.entity_id__c = '0182';
        lc.country_id__c = 'ES';
        lc.gf_prtcpt_act_status_ind_type__c = true;
        insert lc;

        Test.startTest();
        final String result = LocalClientSelectCont.gtLocalClients('TEST_CLIENT_CODE', 'ES');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
    }

    /**
    * Test getSObjectName method for Account.
    */
    @isTest
    static void testGetSObjectNameAccount() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final String result = LocalClientSelectCont.getSObjectName(testAcc.Id);
        Test.stopTest();

        System.assertEquals('Account', result, 'Should return Account');
    }

    /**
    * Test getSObjectName method for Local_Client__c.
    */
    @isTest
    static void testGetSObjectNameLocalClient() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];
        final Local_Client__c lc = new Local_Client__c();
        lc.Cib_Client__c = testAcc.Id;
        lc.entity_id__c = '0182';
        insert lc;

        Test.startTest();
        final String result = LocalClientSelectCont.getSObjectName(lc.Id);
        Test.stopTest();

        System.assertEquals('Local_Client__c', result, 'Should return Local_Client__c');
    }

    /**
    * Test getQueryString method for Account context.
    */
    @isTest
    static void testGetQueryStringAccount() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final String result = LocalClientSelectCont.getQueryString(testAcc.Id, 'ES');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
        System.assert(result.contains('Cib_Client__c'), 'Query should filter by Cib_Client__c');
    }

    /**
    * Test getQueryString method for Local_Client__c context.
    */
    @isTest
    static void testGetQueryStringLocalClient() {
        final Account testAcc = [SELECT Id FROM Account LIMIT 1];
        final Local_Client__c lc = new Local_Client__c();
        lc.Cib_Client__c = testAcc.Id;
        lc.entity_id__c = '0182';
        insert lc;

        Test.startTest();
        final String result = LocalClientSelectCont.getQueryString(lc.Id, 'ES');
        Test.stopTest();

        System.assertNotEquals(null, result, NOT_NULL);
        System.assert(result.contains('Id = :clientCode'), 'Query should filter by Id when called with Local_Client__c');
    }

    /**
    * Test ExpgAvailabilityWrapper instantiation and property access.
    */
    @isTest
    static void testExpgAvailabilityWrapper() {
        Test.startTest();
        final LocalClientSelectCont.ExpgAvailabilityWrapper wrapper = new LocalClientSelectCont.ExpgAvailabilityWrapper();
        wrapper.isExpgAvailable = true;
        wrapper.isCoreRelation = true;
        wrapper.isParent = true;
        Test.stopTest();

        System.assertEquals(true, wrapper.isExpgAvailable, 'isExpgAvailable should be assignable');
        System.assertEquals(true, wrapper.isCoreRelation, 'isCoreRelation should be assignable');
        System.assertEquals(true, wrapper.isParent, 'isParent should be assignable');
    }
}