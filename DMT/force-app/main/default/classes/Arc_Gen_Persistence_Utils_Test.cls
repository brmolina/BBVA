/**
* @description Test class for Arc_Gen_Persistence_Utils.
*/
@isTest
private class Arc_Gen_Persistence_Utils_Test {
    /**
    * @description Make test data for test methods.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceAnalysis;

        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        insert accHasAn;
    }

    /**
    * @description Validates getAhaFromSobject returns correct AHA from a single-element list.
    */
    @isTest static void testGetAhaFromSobjectSingleAha() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<sObject> listObjects = new List<sObject>{aha};

        Test.startTest();
        final arce__Account_has_Analysis__c result = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObjects);
        Test.stopTest();

        Assert.areEqual(aha.Id, result.Id, 'Should return the same AHA record');
    }

    /**
    * @description Validates getAhaFromSobject throws PersistenceException when no AHA found.
    */
    @isTest static void testGetAhaFromSobjectNoAhaThrows() {
        final List<sObject> listObjects = new List<sObject>{new Account(Name = 'Test')};
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_Persistence_Utils.getAhaFromSobject(listObjects);
        } catch (Arc_Gen_Persistence_Utils.PersistenceException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw PersistenceException when no AHA found');
    }

    /**
    * @description Validates addifFilled adds key-value when map is populated.
    */
    @isTest static void testAddifFilledWithMap() {
        final Map<String, Object> finalMap = new Map<String, Object>();
        final Map<String, Object> keyValue = new Map<String, Object>{'key1' => 'value1'};

        Test.startTest();
        final Map<String, Object> result = Arc_Gen_Persistence_Utils.addifFilled(finalMap, 'testKey', keyValue);
        Test.stopTest();

        Assert.isTrue(result.containsKey('testKey'), 'Final map should contain the added key');
    }

    /**
    * @description Validates addifFilled does not add key when map is empty.
    */
    @isTest static void testAddifFilledEmptyMap() {
        final Map<String, Object> finalMap = new Map<String, Object>();
        final Map<String, Object> emptyValue = new Map<String, Object>();

        Test.startTest();
        final Map<String, Object> result = Arc_Gen_Persistence_Utils.addifFilled(finalMap, 'testKey', emptyValue);
        Test.stopTest();

        Assert.isFalse(result.containsKey('testKey'), 'Final map should not contain key for empty value');
    }

    /**
    * @description Validates addifFilledList adds key when list has elements.
    */
    @isTest static void testAddifFilledListPopulated() {
        final Map<String, Object> finalMap = new Map<String, Object>();
        final List<Map<String, Object>> listValue = new List<Map<String, Object>>{
            new Map<String, Object>{'key1' => 'value1'}
        };

        Test.startTest();
        final Map<String, Object> result = Arc_Gen_Persistence_Utils.addifFilledList(finalMap, 'listKey', listValue);
        Test.stopTest();

        Assert.isTrue(result.containsKey('listKey'), 'Final map should contain the list key');
    }

    /**
    * @description Validates getEnumFromMap returns correct enum for a valid code.
    */
    @isTest static void testGetEnumFromMapValidCode() {
        final Map<String, String> enumMap = new Map<String, String>{'01' => 'ACTIVE', '02' => 'INACTIVE'};

        Test.startTest();
        final String result = Arc_Gen_Persistence_Utils.getEnumFromMap('01', enumMap);
        Test.stopTest();

        Assert.areEqual('ACTIVE', result, 'Should return matching enum value');
    }

    /**
    * @description Validates getEnumFromMap throws PersistenceException for an invalid code.
    */
    @isTest static void testGetEnumFromMapInvalidThrows() {
        final Map<String, String> enumMap = new Map<String, String>{'01' => 'ACTIVE'};
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_Persistence_Utils.getEnumFromMap('99', enumMap);
        } catch (Arc_Gen_Persistence_Utils.PersistenceException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw PersistenceException for invalid code');
    }

    /**
    * @description Validates defaultValueList returns the provided code when not null.
    */
    @isTest static void testDefaultValueListFilledCode() {
        Test.startTest();
        final String result = Arc_Gen_Persistence_Utils.defaultValueList('ABC');
        Test.stopTest();

        Assert.areEqual('ABC', result, 'Should return the provided code');
    }

    /**
    * @description Validates defaultValueList returns default "0" for null input.
    */
    @isTest static void testDefaultValueListNullCode() {
        Test.startTest();
        final String result = Arc_Gen_Persistence_Utils.defaultValueList(null);
        Test.stopTest();

        Assert.areEqual('0', result, 'Should return default value "0" for null input');
    }

    /**
    * @description Validates booleanFromYesNo returns true for value "1".
    */
    @isTest static void testBooleanFromYesNoYes() {
        Test.startTest();
        final Boolean result = Arc_Gen_Persistence_Utils.booleanFromYesNo('1');
        Test.stopTest();

        Assert.isTrue(result, 'Should return true for value "1"');
    }

    /**
    * @description Validates booleanFromYesNo returns false for value "2".
    */
    @isTest static void testBooleanFromYesNoNo() {
        Test.startTest();
        final Boolean result = Arc_Gen_Persistence_Utils.booleanFromYesNo('2');
        Test.stopTest();

        Assert.isFalse(result, 'Should return false for value "2"');
    }

    /**
    * @description Validates booleanFromYesNo returns false for null input.
    */
    @isTest static void testBooleanFromYesNoNull() {
        Test.startTest();
        final Boolean result = Arc_Gen_Persistence_Utils.booleanFromYesNo(null);
        Test.stopTest();

        Assert.isFalse(result, 'Should return false for null input');
    }

    /**
    * @description Validates addDateToMap adds a formatted date string for a valid date.
    */
    @isTest static void testAddDateToMapValidDate() {
        final Map<String, Object> objInput = new Map<String, Object>();
        final Date testDate = Date.newInstance(2026, 3, 30);

        Test.startTest();
        Arc_Gen_Persistence_Utils.addDateToMap(objInput, 'endDate', testDate);
        Test.stopTest();

        Assert.isTrue(
            objInput.containsKey('endDate') && ((String)objInput.get('endDate')).contains('2026'),
            'Map should contain the date key with a string that includes the year'
        );
    }

    /**
    * @description Validates addDateToMap does not add key for null date input.
    */
    @isTest static void testAddDateToMapNullDate() {
        final Map<String, Object> objInput = new Map<String, Object>();

        Test.startTest();
        Arc_Gen_Persistence_Utils.addDateToMap(objInput, 'endDate', null);
        Test.stopTest();

        Assert.isFalse(objInput.containsKey('endDate'), 'Map should not contain key for null date');
    }

    /**
    * @description Validates cutString abbreviates a string longer than max length.
    */
    @isTest static void testCutStringLongInput() {
        final String longText = 'This is a very long string that should be abbreviated to a shorter version for testing purposes in the persistence layer';

        Test.startTest();
        final String result = Arc_Gen_Persistence_Utils.cutString(longText, 20);
        Test.stopTest();

        Assert.isTrue(result.length() <= 20, 'Result should be abbreviated to max length');
    }

    /**
    * @description Validates cutString returns null for null input.
    */
    @isTest static void testCutStringNullInput() {
        Test.startTest();
        final String result = Arc_Gen_Persistence_Utils.cutString(null, 20);
        Test.stopTest();

        Assert.isNull(result, 'Should return null for null input');
    }
}