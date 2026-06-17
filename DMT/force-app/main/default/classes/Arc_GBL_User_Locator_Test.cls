/**
* @description Test class for Arc_GBL_User_Locator.
*/
@isTest
private class Arc_GBL_User_Locator_Test {
    /**
    * @description Creates a user with gf_user_operation_ambit_name__c set so getUserByAmbit has records to return.
    */
    @testSetup
    static void setup() {
        final User currentUser = [
            SELECT ProfileId, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        final User ambitUser = new User(
            Alias = 'ambusr',
            Email = 'ambit.user.test@example.com',
            EmailEncodingKey = currentUser.EmailEncodingKey,
            LastName = 'AmbitUserTest',
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            ProfileId = currentUser.ProfileId,
            TimeZoneSidKey = currentUser.TimeZoneSidKey,
            Username = 'ambit.user.test.' + DateTime.now().getTime() + '@example.com',
            gf_user_operation_ambit_name__c = '1',
            IsActive = true,
            ID_User__c = String.valueOf((Math.random()*100000))
        );
        insert ambitUser;
    }
    /**
    * @description Validates getUserInfo returns a populated wrapper for the current user.
    */
    @isTest static void testGetUserInfoCurrentUser() {
        final Id currentUserId = UserInfo.getUserId();

        Test.startTest();
        final arce.Arc_Gen_User_Wrapper result = Arc_GBL_User_Locator.getUserInfo(currentUserId);
        Test.stopTest();

        Assert.isTrue(result != null && result.userBasicInfo != null && result.userBasicInfo.Id == currentUserId
            && result.branchId != null && result.profileName != null, 'Should return populated wrapper for current user');
    }

    /**
    * @description Validates getUsers returns results for a valid search term.
    */
    @isTest static void testGetUsersValidSearch() {
        final String currentUserName = UserInfo.getLastName();

        Test.startTest();
        final List<arce.Arc_Gen_User_Wrapper> results = Arc_GBL_User_Locator.getUsers(currentUserName);
        Test.stopTest();

        Assert.isFalse(results.isEmpty() && results[0].userBasicInfo != null, 'Should find at least current user and populate user info');
    }

    /**
    * @description Validates getUsers returns empty list for a non-existent search term.
    */
    @isTest static void testGetUsersNonExistentTerm() {
        Test.startTest();
        final List<arce.Arc_Gen_User_Wrapper> results = Arc_GBL_User_Locator.getUsers('ZZZZNONEXISTENT99999');
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Should return empty list for non-existent search term');
    }

    /**
    * @description Validates getUserByAmbit returns active users for a given ambit string.
    */
    @isTest static void testGetUserByAmbitReturnsActive() {
        Test.startTest();
        final List<User> results = Arc_GBL_User_Locator.getUserByAmbit('1', null);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return at least one active user');
    }
}