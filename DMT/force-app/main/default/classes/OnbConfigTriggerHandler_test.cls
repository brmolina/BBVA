/*
* test
*/
@isTest
public class OnbConfigTriggerHandler_test {
    /*
    * test 1
    */
    @isTest
    public static void onbConfigTriggerHandlertest() {
        Onboarding_Configuration__c platform;
        platform = SetUpOnBoarding.createPlatformProduct(SetUpOnBoarding.getPlatformRecordtype('FX'), 'platform', 'product');
        insert platform;
        platform.Platform__c = 'platform2';
        update platform;
        System.assertEquals(platform.Platform__c,'platform2', 'Error');
    }

    /*
    * test 1
    */
    @isTest
    public static void usertest() {
        // Setup test data
        // This code runs as the system user
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        String profileTest = '';
        profileTest = utilTestClass.createProfile();
        User user;
        user = utilTestClass.createUser(profileTest);
        user.Disable_ECommerce_Margin__c=true;
        user.Disable_ECommerce_Configuration__c=true;
        user.Disable_ECommerce_Group__c=true;
        insert user;
        user.Disable_ECommerce_Margin__c=false;
        user.Disable_ECommerce_Configuration__c=false;
        user.Disable_ECommerce_Group__c=false;
        update user;
        user.Disable_ECommerce_Margin__c=true;
        user.Disable_ECommerce_Configuration__c=true;
        user.Disable_ECommerce_Group__c=true;
        update user;
        System.assert(user.Disable_ECommerce_Group__c, 'Error');
    }
}