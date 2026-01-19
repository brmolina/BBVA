@isTest
public with sharing class User_Helper_Test {
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    private static User runningUser = new User();
    private static User userTest1 = new User();
    @testSetup
    static void setup() {
        Test.startTest();
        List<User> usersToInsert = new List<User>();
        String profileTest = utilTestClass.createProfile();

        runningUser = utilTestClass.createUser(profileTest);
        runningUser.ProfileId = [SELECT Id, Name
                                 FROM Profile
                                 WHERE Name = 'Desktop Integration'
                                 LIMIT 1].Id;
        usersToInsert.add(runningUser);

        userTest1 = utilTestClass.createUser(profileTest);
        userTest1.ID_User__c = 'userTest12';
        userTest1.Country = 'MEX';
        usersToInsert.add(userTest1);

        insert usersToInsert;

        Test.stopTest();
    }

    @isTest
    static void testGtInstance() {
        Test.startTest();
        User_Helper instance1 = User_Helper.gtInstance();
        User_Helper instance2 = User_Helper.gtInstance();
        Test.stopTest();

        System.assertNotEquals(null, instance1, 'Instance should not be null');
        System.assertEquals(instance1, instance2, 'Instances should be the same');
    }

    @isTest
    static void testCompleteLogicValidate() {
        List<User> testUsers = [SELECT Id, gf_user_operation_ambit_name__c
                                FROM User
                                LIMIT 3];

        Test.startTest();
        User_Helper helper = User_Helper.gtInstance();
        helper.completeLogicValidate(testUsers);
        Test.stopTest();

        for (User usr : testUsers) {
            System.assertNotEquals(null, usr.DES_ARCE_Can_Propose__c, 'Should have a boolean value');
            System.assertNotEquals(null, usr.DES_ARCE_Can_Validate__c, 'Should have a boolean value');
            System.assertNotEquals(null, usr.DES_ARCE_Can_Edit__c, 'Should have a boolean value');
        }
    }

    @isTest
    static void testValidateMexUser() {
        Set<Id> userIds = new Set<Id>();
        User usr = [SELECT Id
                    FROM User
                    WHERE Country = 'MEX'
                    LIMIT 1];
        userIds.add(usr.Id);

        Test.startTest();
        User_Helper.validateMexUser(userIds, true);
        List<GroupMember> groupMembers = [SELECT Id, UserOrGroupId
                                          FROM GroupMember
                                          WHERE UserOrGroupId = :usr.Id];
        User_Helper.validateMexUser(userIds, false);
        List<GroupMember> NOgroupMembers = [SELECT Id, UserOrGroupId
                                            FROM GroupMember
                                            WHERE UserOrGroupId = :usr.Id];
        Test.stopTest();
        System.assertEquals(groupMembers[0].UserOrGroupId, usr.Id, 'All users should be created from the group');
        System.assertNotEquals(NOgroupMembers.size(), groupMembers.size(), 'All users should be deleted from the group');
    }

}