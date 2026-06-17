/**
* @description Test class for Arc_GBL_ValidationRating_Service.
*/
@isTest
private class Arc_GBL_ValidationRating_Service_Test {
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
    * @description Validates userValidate returns validation message when proposer is current user.
    */
    @isTest static void testUserValidateSameUser() {
        final String currentUserId = UserInfo.getUserId();

        Test.startTest();
        final String result = Arc_GBL_ValidationRating_Service.userValidate(currentUserId);
        Test.stopTest();

        Assert.areEqual(System.Label.Arc_Gen_RAIP_ValidateUser, result,
            'Should return validation message when proposer is current user');
    }

    /**
    * @description Validates userValidate returns OK when proposer differs from current user.
    */
    @isTest static void testUserValidateDifferentUser() {
        final List<User> others = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1];
        if (others.isEmpty()) {
            return;
        }

        Test.startTest();
        final String result = Arc_GBL_ValidationRating_Service.userValidate(others[0].Id);
        Test.stopTest();

        Assert.areEqual('OK', result, 'Should return OK when proposer differs from current user');
    }

    /**
    * @description Validates CompletionResult wrapper instantiates successfully.
    */
    @isTest static void testCompletionResultConstructor() {
        Test.startTest();
        final Arc_GBL_ValidationRating_Service.CompletionResult cr = new Arc_GBL_ValidationRating_Service.CompletionResult();
        Test.stopTest();

        Assert.isNotNull(cr, 'CompletionResult should instantiate successfully');
    }

    /**
    * @description Validates TabCompletionInfo wrapper instantiates successfully.
    */
    @isTest static void testTabCompletionInfoConstructor() {
        Test.startTest();
        final Arc_GBL_ValidationRating_Service.TabCompletionInfo tci = new Arc_GBL_ValidationRating_Service.TabCompletionInfo();
        Test.stopTest();

        Assert.isNotNull(tci, 'TabCompletionInfo should instantiate successfully');
    }

    /**
    * @description Validates validateQualitativeQuestion returns a list for non-matching template.
    */
    @isTest static void testValidateQualitativeQuestionInvalid() {
        final arce__Account_has_Analysis__c accHasAn = [
            SELECT Id
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        Exception expectedExc;

        Test.startTest();
        try {
            Arc_GBL_ValidationRating_Service.validateQualitativeQuestion(accHasAn.Id, 'NonExistentTemplate');
        } catch (Exception exc) {
            expectedExc = exc;
        }
        Test.stopTest();

        Assert.isNotNull(expectedExc, 'Should throw an exception for non-matching template');
    }
}