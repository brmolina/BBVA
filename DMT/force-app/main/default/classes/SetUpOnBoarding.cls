/*----------------------------------------------------------------------------------------------
    Description:    Creacion de datos dummy para los Tests de eSales OnBoarding.

    History:
    <Date>          <Author>                <Description>
    09/12/2020
-----------------------------------------------------------------------------------------------*/
public with sharing class SetUpOnBoarding {
    /** instance */
    private static SetUpOnBoarding instance;
    /*
    * getInstance
    */
    public static SetUpOnBoarding getInstance() { //NOSONAR
        if (instance == null) {
            instance = new SetUpOnBoarding();
        }
        return instance;
    }
    /*
    * Met0d0 para pasar sonar
    */
    private SetUpOnBoarding() {}


    /* Nuevo Asset_Template__c */
    public static Asset_Template__c createAssetTemplate() {
        Asset_Template__c template;
        template = new Asset_Template__c();
        template.Onboarding_Type__c = 'New User';
        template.Asset_Class__c = 'Fixed Income';
        return template;
    }

    /* Nuevo Asset_Product__c */
    public static Asset_Product__c createAssetProduct(String recordId) {
        Asset_Product__c prod;
        prod = new Asset_Product__c();
        prod.Asset_Template__c = recordId;
        prod.Trader_Group__c = 'TEST';
        return prod;
    }

    /* Nuevo Asset_Template__c */
    public static Asset_Template__c createAssetTemplateFull(String cliente, String primary, String secondary, String secondaryName) { //NOSONAR
        Asset_Template__c template;
        template = new Asset_Template__c();
        template.Onboarding_Type__c = 'New Client';
        template.Status__c = 'Review';
        template.Asset_Class__c = 'Fixed Income';
        template.Petitioner_Name__c = 'Testeo';
        template.Client__c = cliente;
        template.Star_Code__c = '11212';
        template.Murex_Code__c = '11212';
        template.Description__c = 'dasdasd';
        template.Additional_Info__c = 'adsdsa';
        template.Do_you_already_work_with_this_client__c = 'Yes';
        template.Primary_Sales__c = Primary;
        template.Secondary_Sales__c = Secondary;
        template.Secondary_Sales_Id__c = SecondaryName;
        return template;
    }

    /* Nuevo Asset Template con tdos los campos rellenos */
    public static Asset_Product__c createAssetProductFull(String recordId) {
        Asset_Product__c prod;
        prod = new Asset_Product__c();
        prod.Product__c = 'Colombian Bonds';
        prod.Platform__c = 'Bloomberg';
        prod.Client_Name_on_Platform__c = 'asdadsa';
        prod.User_Name_FI__c = 'Prueba';
        prod.View_only__c = 'YES';
        prod.Different_Tier_per_Country__c = 'Yes';
        prod.User_UUID_if_bloomberg__c = 'Teste';
        prod.Additional_info_per_Country__c = 'asdasd';
        prod.Asset_Template__c = recordId;
        prod.Trader_Group__c = 'TEST';
        prod.Tier__c = '1';
        return prod;
    }

    /* Nueva plataforma */
    public static Onboarding_Configuration__c createPlatformProduct(String rdtypeid, String platform, String product) {
        Onboarding_Configuration__c  onConfig;
        onConfig = new Onboarding_Configuration__c();
        onConfig.RecordTypeId = rdtypeid;
        onConfig.Platform__c = platform;
        onConfig.Product__c = product;

        return onConfig;
    }

    /* Nueva margin */
    public static Asset_Margin__c createMargin(String name) {
        Asset_Margin__c   margin;
        margin = new Asset_Margin__c ();
        margin.Disabled__c = false;
        margin.Forward_Margins__c = true;
        margin.Forward_trading_pricing__c = true;
        margin.Spot_Margins__c = true;
        margin.Spot_trading_pricing__c = true;
        margin.Name = name;

        return margin;
    }

    /* Nueva margin */
    public static Asset_Group_Member__c createMember(String idGroup, String idUser) {
        Asset_Group_Member__c   member;
        member = new Asset_Group_Member__c ();
        member.E_Commerce_Group__c = idGroup;
        member.User__c = idUser;

        return member;
    }

    /* Nueva margin */
    public static String getPlatformRecordtype(String recordTypeLabel) {
        return Schema.SObjectType.Onboarding_Configuration__c.getRecordTypeInfosByName().get( recordTypeLabel ).getRecordTypeId();
    }
}