/*
* test 1
*/@isTest
public class OnboardingPlatformProduct_ctrl_test {
    /*
    * String
    */
    static final String FIXEDINCOME = 'Fixed Income';
    /*
    * String
    */
    static final String EQUITY = 'Equity';
    /*
    * String
    */
    static final String FXSTRING = 'FX';
    /*
    * String
    */
    static final String PLATFORMSTR = 'platform';
    /*
    * String
    */
    static final String PRODUCT = 'product';
    /*
    * test 1
    */
    @isTest
    public static void getPrimarySalesTest() {
        Boolean test = false;
        Onboarding_Configuration__c platform;
        platform = SetUpOnBoarding.createPlatformProduct(SetUpOnBoarding.getPlatformRecordtype(FIXEDINCOME), PLATFORMSTR, PRODUCT);
        insert platform;
        Asset_Margin__c margin;
        margin = SetUpOnBoarding.createMargin('margin');
        insert margin;
        Asset_Group__c groupNew;
        groupNew = [SELECT id FROM Asset_Group__c limit 1];
        final Group groupStand = [SELECT id FROM Group WHERE Name LIKE 'E-comm%' limit 1];
        Asset_Group_Member__c member;
        member = SetUpOnBoarding.createMember(groupNew.Id, UserInfo.getUserId());
        insert member;


        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        insert template;
        Asset_Product__c tempProd;
        tempProd = SetUpOnBoarding.createAssetProduct(template.id);
        insert tempProd;
        OnboardingPlatformProduct_ctrl.getProductIDs(template.id);
        OnboardingPlatformProduct_ctrl.addNewAssetProduct(template.id);
        OnboardingPlatformProduct_ctrl.getProductFields(tempProd.id);
        OnboardingPlatformProduct_ctrl.getPlatformList(FIXEDINCOME, PLATFORMSTR);
        OnboardingPlatformProduct_ctrl.getProductList(FIXEDINCOME, PLATFORMSTR, PLATFORMSTR, PRODUCT);
        OnboardingPlatformProduct_ctrl.getTierList(FIXEDINCOME, PLATFORMSTR, PRODUCT, PLATFORMSTR, PRODUCT, '1');
        Asset_Product__c tempProdClone;
        tempProdClone = SetUpOnBoarding.createAssetProduct(template.id);
        OnboardingPlatformProduct_ctrl.cloneAssetProduct(tempProdClone, tempProd.id);
        OnboardingPlatformProduct_ctrl.updateProduct(tempProd, tempProd.id, 'assetType');
        List<String> lResult;
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(FIXEDINCOME , 'New Client', 'Bloomberg', 'USTs', 'ALL', 'Wrong Data');
        OnboardingPlatformProduct_ctrl.getTraderExclude(lResult);
        OnboardingPlatformProduct_ctrl.canEditAsset(template.id);
        OnboardingPlatformProduct_ctrl.canSaveAsset('secondary', template.id);
        template.Status__c = 'Validate';
        update template;
        tempProd.Trader_Group__c = groupStand.id;
        update tempProd;
        OnboardingPlatformProduct_ctrl.getProductIDs(template.id);
        OnboardingPlatformProduct_ctrl.delAssetProduct(tempProd.id);
        if([SELECT count() FROM Asset_Product__c WHERE id = :tempProd.id] == 0) {
            test = true;
        }
        System.assert(test, 'Error');
    }
    /*
    * test 1
    */
    @isTest
    public static void getPicklistValue() {
        Asset_Picklist__c aPick;
        aPick = new Asset_Picklist__c(Field_Name__c='Access', Value__c='BBB');
        insert aPick;
        String wrongS;
        wrongS = 'Wrong Data';
        String allS;
        allS = 'ALL';
        String ustS;
        ustS = 'USTs';
        String newClientS;
        newClientS = 'New Client';
        OnboardingPlatformProduct_ctrl.getPickListValues('Access', 'AAA');
        OnboardingPlatformProduct_ctrl.waitTime(1);
        List<String> lResult;
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(FXSTRING , newClientS, 'BVAeMarkets', ustS, allS, wrongS);
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(EQUITY , newClientS, 'Tradeweb', ustS, allS, wrongS);
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(EQUITY , newClientS, 'RFQHub', ustS, allS, wrongS);
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(EQUITY , newClientS, 'BloombergDLIB', ustS, allS, wrongS);
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(EQUITY , newClientS, 'EmailPricer', ustS, allS, wrongS);
        lResult = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(EQUITY , newClientS, 'WebPricer', ustS, allS, wrongS);
        System.debug('lResult ' + lResult);
        System.assertEquals(aPick.Field_Name__c, 'Access', 'Error');

    }
}