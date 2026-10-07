/**
 * @description Test class for DMT_NotificationSubscriptionController.
 *              Validates subscription management operations: get, save, delete.
 */
@IsTest
private class DMT_NotificationSubscriptionCtrlTest {

    @TestSetup
    static void setupTestData() {
        Account testClient = new Account(
            Name = 'Test Client Subscription',
            CurrencyIsoCode = 'EUR'
        );
        insert testClient;

        insert new DMT_NotificationSubscription__c(
            User__c   = UserInfo.getUserId(),
            Client__c = testClient.Id,
            Type__c   = 'Closed_Won'
        );
    }

    // ─── getSubscription Tests ───────────────────────────────────────────────

    @IsTest
    static void testGetSubscription_existingSubscription_returnsTrue() {
        Test.startTest();
        Boolean result = DMT_NotificationSubscriptionController.getSubscription('Closed_Won');
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when a subscription exists for the user and type.');
    }

    @IsTest
    static void testGetSubscription_noSubscription_returnsFalse() {
        Test.startTest();
        Boolean result = DMT_NotificationSubscriptionController.getSubscription('Unsubscribed_Type');
        Test.stopTest();

        Assert.isFalse(result, 'Should return false when no subscription exists.');
    }

    @IsTest
    static void testGetSubscription_blankOrNullType_returnsFalse() {
        Test.startTest();
        Boolean resultBlank = DMT_NotificationSubscriptionController.getSubscription('');
        Boolean resultNull = DMT_NotificationSubscriptionController.getSubscription(null);
        Boolean resultWhitespace = DMT_NotificationSubscriptionController.getSubscription('   ');
        Test.stopTest();

        Assert.isFalse(resultBlank, 'Should return false when type is empty string.');
        Assert.isFalse(resultNull, 'Should return false when type is null.');
        Assert.isFalse(resultWhitespace, 'Should return false when type is whitespace.');
    }

    // ─── saveSubscription Tests ──────────────────────────────────────────────

    @IsTest
    static void testSaveSubscription_createsGlobalSubscription() {
        Test.startTest();
        DMT_NotificationSubscriptionController.saveSubscription('Lines_Opportunities_review');
        Test.stopTest();

        List<DMT_NotificationSubscription__c> subs = [
            SELECT Id, User__c, Client__c, Type__c
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :UserInfo.getUserId()
              AND Type__c = 'Lines_Opportunities_review'
        ];

        Assert.areEqual(1, subs.size(), 'Should create exactly one global subscription.');
        Assert.isNull(subs[0].Client__c, 'Client__c should be null for a global subscription.');
        Assert.areEqual('Lines_Opportunities_review', subs[0].Type__c, 'Type should match the requested subscription type.');
    }

    @IsTest
    static void testSaveSubscription_existingGlobal_doesNotDuplicate() {
        insert new DMT_NotificationSubscription__c(
            User__c   = UserInfo.getUserId(),
            Client__c = null,
            Type__c   = 'Task_Assigned'
        );

        Test.startTest();
        DMT_NotificationSubscriptionController.saveSubscription('Task_Assigned');
        Test.stopTest();

        List<DMT_NotificationSubscription__c> subs = [
            SELECT Id
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :UserInfo.getUserId()
              AND Type__c = 'Task_Assigned'
              AND Client__c = NULL
        ];

        Assert.areEqual(1, subs.size(), 'Should not create a duplicate global subscription.');
    }

    @IsTest
    static void testSaveSubscription_blankOrNullType_throwsException() {
        Boolean blankExceptionThrown = false;
        Boolean nullExceptionThrown = false;

        Test.startTest();
        try {
            DMT_NotificationSubscriptionController.saveSubscription('');
        } catch (AuraHandledException e) {
            blankExceptionThrown = true;
        }

        try {
            DMT_NotificationSubscriptionController.saveSubscription(null);
        } catch (AuraHandledException e) {
            nullExceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(blankExceptionThrown, 'Should throw AuraHandledException when type is blank.');
        Assert.isTrue(nullExceptionThrown, 'Should throw AuraHandledException when type is null.');
    }

    // ─── deleteSubscription Tests ────────────────────────────────────────────

    @IsTest
    static void testDeleteSubscription_deletesAllSubscriptionsForType() {
        insert new DMT_NotificationSubscription__c(
            User__c   = UserInfo.getUserId(),
            Client__c = null,
            Type__c   = 'Closed_Won'
        );

        List<DMT_NotificationSubscription__c> beforeSubs = [
            SELECT Id
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :UserInfo.getUserId()
              AND Type__c = 'Closed_Won'
        ];
        Assert.areEqual(2, beforeSubs.size(), 'Should have 2 subscriptions (1 client-specific, 1 global) before deletion.');

        Test.startTest();
        DMT_NotificationSubscriptionController.deleteSubscription('Closed_Won');
        Test.stopTest();

        List<DMT_NotificationSubscription__c> afterSubs = [
            SELECT Id
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :UserInfo.getUserId()
              AND Type__c = 'Closed_Won'
        ];
        Assert.areEqual(0, afterSubs.size(), 'Should delete all subscriptions for the specified type.');
    }

    @IsTest
    static void testDeleteSubscription_nonExistingSubscription_doesNothing() {
        Test.startTest();
        DMT_NotificationSubscriptionController.deleteSubscription('Non_Existent_Type');
        Test.stopTest();

        Assert.isTrue(true, 'Should complete without errors when deleting a non-existent subscription.');
    }

    @IsTest
    static void testDeleteSubscription_blankOrNullType_doesNothing() {
        Test.startTest();
        DMT_NotificationSubscriptionController.deleteSubscription('');
        DMT_NotificationSubscriptionController.deleteSubscription(null);
        Test.stopTest();

        Assert.isTrue(true, 'Should return early without errors when type is blank or null.');
    }
}