/**
* ButtonEsalesValidationMessage_Test
*/
@isTest
@SuppressWarnings('sf:TooManyMethods')
public with sharing class ButtonEsalesValidationMessage_Test {

    /*
    * String
    */
    static final String REVIEW = 'Review';
    /*
    * String
    */
    static final String MESSAGE = 'El estado está mal.';

    /*
     * Testsetup method
     */
    @testSetup
    static void setupTestData() {
        UserRole rolUser;
        rolUser = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		insert rolUser;
    }

    /**
     * validateReviewTest
     */
    @isTest
    public static void validateReviewTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', REVIEW);
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateApproveTest
     */
    @isTest
    public static void validateApproveTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Approve');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateApproveTest
     */
    @isTest
    public static void validateSubmitTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = 'New';
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Submit');
        system.assert(lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateImplementTest
     */
    @isTest
    public static void validateImplementTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Implement');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateEditTest
     */
    @isTest
    public static void validateEditTest() {
        final String idRol = [SELECT Id FROM UserRole LIMIT 1].Id;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        assTemp.Secondary_Sales_Id__c = idRol;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Edit');
        system.assert(lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateApproveTraderTest
     */
    @isTest
    public static void validateApproveTraderTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'ApproveTrader');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateAddProductTest
     */
    @isTest
    public static void validateAddProductTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'AddProduct');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateRejectTest
     */
    @isTest
    public static void validateRejectTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Reject');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }

    /**
     * validateEditTierTest
     */
    @isTest
    public static void validateEditTierTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Edit_Tier');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }


    /**
     * validateCompletTest
     */
    @isTest
    public static void validateCompletTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = REVIEW;
        insert assTemp;
        List<String> lstStr;
        lstStr = ButtonEsalesValidationMessage.getErrorMessagesList(assTemp.Id, '', 'Complete');
        system.assert(!lstStr.isEmpty(), MESSAGE);
    }
}