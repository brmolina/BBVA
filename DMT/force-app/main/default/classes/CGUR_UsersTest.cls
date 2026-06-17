@IsTest
private class CGUR_UsersTest {

    private static User createTestUser(String country) {
        User currentUser = [
            SELECT ProfileId, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        String uniqueKey = String.valueOf(DateTime.now().getTime()).right(6);
        User usr = new User(
            Alias = 'cgurt',
            Email = 'cgur.users.test+' + uniqueKey + '@example.com',
            EmailEncodingKey = currentUser.EmailEncodingKey,
            ID_User__c = 'O' + uniqueKey,
            LastName = 'UsersTest',
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            ProfileId = currentUser.ProfileId,
            TimeZoneSidKey = currentUser.TimeZoneSidKey,
            Username = 'cgur.users.test+' + uniqueKey + '@example.com',
            DES_Country__c = country
        );
        insert usr;
        return usr;
    }

    @IsTest
    static void testGetUserCountry() {
        User usr = createTestUser('ESP');
        String country;

        Test.startTest();
        System.runAs(usr) {
            country = (new CGUR_Users()).getUserCountry();
        }
        Test.stopTest();

        System.assertEquals('ESP', country, 'The country should be ESP. GOT:' + country);
    }
}