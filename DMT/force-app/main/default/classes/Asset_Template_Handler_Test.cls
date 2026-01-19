/*
* Asset_Template_Handler_Test
*/
@isTest
public with sharing class Asset_Template_Handler_Test {

    /*
    * Test method for checkDelete
    */
    @isTest
    public static void checkDeleteTest() {
        Asset_Template__c temp;
        String prueba = '';
        prueba = 'Cannot delete if status is not New';
        temp = SetUpOnBoarding.createAssetTemplate();
        temp.Status__c = 'Review';
        Boolean test = false;
        insert temp;
        List<Asset_Template__c> oldList;
        oldList = New List<Asset_Template__c>();
        oldList.add(temp);
        Asset_Template_Handler assetTemp;
        assetTemp = new Asset_Template_Handler();
        Asset_Template_Handler_out.getInstance();
        try {
            assetTemp.checkDelete(oldList);
        } catch (Exception e) {
            if(e.getMessage() == prueba) {
                test = true;
            }
            system.assert(test, 'La lista está vacía');
        }
    }

    /*
    * Test method for checkDelete
    */
    @isTest
    public static void compareStageChangeTest() {
        Asset_Template__c temp;
        temp = SetUpOnBoarding.createAssetTemplate();
        temp.Status__c = 'Review';
        insert temp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(temp.Id);
        prod.Currency_Traded__c = 'All';
        Asset_Product__c prod1;
        prod1 = SetUpOnBoarding.createAssetProduct(temp.Id);
        prod1.Product__c = 'EM (Hard & Local Currency)';
        List<Asset_Product__c> lstOld;
        lstOld = new List<Asset_Product__c>{prod,prod1};
        insert lstOld;
        temp.Status__c = 'Validate';
        update temp;
        List<Asset_Product__c> prodRec;
        prodRec = [SELECT Id, Trader_Group__c, Asset_Template__c FROM Asset_Product__c WHERE Asset_Template__c =: temp.Id LIMIT 2];
        system.assert(prodRec[0].Trader_Group__c != null && prodRec[1].Trader_Group__c != null, 'No se ha asignado trader');
    }

    /*
    * Test method for checkDelete
    */
    @isTest
    public static void compareStageChangeTestFX() {
        Onboarding_Configuration__c platform;
        platform = SetUpOnBoarding.createPlatformProduct(SetUpOnBoarding.getPlatformRecordtype('FX'), 'platform', 'product');
        insert platform;
        Asset_Margin__c margin;
        margin = SetUpOnBoarding.createMargin('margin');
        insert margin;
        Asset_Group__c groupNew;
        groupNew = [SELECT id, Name FROM Asset_Group__c ORDER BY CreatedDate DESC LIMIT 1];
        Group grp;
        grp = new Group(Name='E-Commerce-'+groupNew.Name,DoesIncludeBosses=false);
        insert grp;
        Asset_Group_Member__c member;
        member = SetUpOnBoarding.createMember(groupNew.Id, UserInfo.getUserId());
        insert member;

        Asset_Template__c temp;
        temp = SetUpOnBoarding.createAssetTemplate();
        temp.Status__c = 'Review';
        temp.Asset_Class__c = 'FX';
        insert temp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(temp.Id);
        prod.Currency_Traded__c = 'All';
        insert prod;
        temp.Status__c = 'Validate';
        update temp;
        Asset_Product__c prodRec;
        prodRec = [SELECT Id, Trader_Group__c, Asset_Template__c FROM Asset_Product__c WHERE Asset_Template__c =: temp.Id LIMIT 1];
        system.assert(prodRec.Trader_Group__c != null, 'No se ha asignado trader');
    }
}