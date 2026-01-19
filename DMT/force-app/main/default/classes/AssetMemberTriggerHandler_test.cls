/*
* test del trigger handler Asset Group
*/
@isTest
public with sharing class AssetMemberTriggerHandler_test {
    /*
    * test 1
    */
    @isTest
    public static void assetMemberTriggerHandlerTest() {
        Onboarding_Configuration__c platform;
        platform = SetUpOnBoarding.createPlatformProduct(SetUpOnBoarding.getPlatformRecordtype('Fixed Income'), 'platform', 'product');
        insert platform;
        Asset_Group__c groupNew;
        groupNew = [SELECT id FROM Asset_Group__c limit 1];
        Asset_Group_Member__c member;
        member = SetUpOnBoarding.createMember(groupNew.Id, UserInfo.getUserId());
        insert member;
        delete member;
        AssetGroupMemberTriggerHandler asset;
        asset = AssetGroupMemberTriggerHandler.getInstance();
        System.debug(asset);
        System.assertEquals([SELECT count() FROM Asset_Group_Member__c LIMIT 1], 0, 'Error');
    }
}