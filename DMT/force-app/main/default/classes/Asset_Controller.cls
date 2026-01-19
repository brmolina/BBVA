/*
* Asset_Controller
*/
@SuppressWarnings('sf:TooManyMethods,sf:NullAssignment')
public with sharing class Asset_Controller {


    /*
    * String
    */
    static final String PLATFORMADD = 'Platform Addition';

    /*
    * String
    */
    static final String REJECTUSER = 'Reject User';

    /*
    * String
    */
    static final String CLIENTREJECTED = 'Client Rejected';

    /*
    * String
    */
    static final String REJECTCLIENT = 'Reject Client';

    /*
    * String
    */
    static final String NEWFXACCSTR = 'New FX Account';

    /*
    * String
    */
    static final String NEWUSERSTR = 'New User';

    /*
    * String
    */
    static final String NEWFUNDSTR = 'Reject Fund';

    /*
    * String
    */
    static final String ASSETEQUITY = 'Equity';

    /*
    * String
    */
    static final String NEWCLIENT = 'New Client';

    /*
    * String
    */
    static final String NEWPROD = 'New Product';

    /** instance */
    private static Asset_Controller instance;

    /*
    * getInstance
    */
    public static Asset_Controller getInstance() {//NOSONAR
        if (instance == null) {
            instance = new Asset_Controller();
        }
        return instance;
    }

    /*
    * Met0d0 para pasar sonar
    */
    private Asset_Controller() {}

    /*
    * Get FieldSet for Asset Header
    */
    @AuraEnabled
    public static Boolean getStatus(String recordId) {
        Boolean estado = false;
        final Asset_Template__c fields = [SELECT Id, Status__c FROM Asset_Template__c WHERE Id =: recordId LIMIT 1];
        if(fields.Status__c == CLIENTREJECTED) {
            estado = true;
        }
        return estado;
    }

    /*
    * Get FieldSet for Asset Header
    */
    @AuraEnabled
    public static List<TemplateVF_Controller.FieldSetMemberWrapperClass> getFieldSetFromTemplate () { //NOSONAR
        return getFieldSets('NewAssetFields', false);
    }

    /*
    * Get FieldSet for Asset Header
    */
    @AuraEnabled
    public static Boolean getAssetType (String recordId) {
        Boolean show = false;
        List<TemplateVF_Controller.FieldSetMemberWrapperClass> listFields;
        listFields = getFieldsForm(recordId, false);
        for(TemplateVF_Controller.FieldSetMemberWrapperClass field : listFields) {
            if(Label.E_Commerce_Lookup.contains(field.fieldAPIName)) {
                show = true;
            }
        }
        return !show;
    }

    /*
    * Get FieldSet for Asset Header
    */
    @AuraEnabled
    public static List<TemplateVF_Controller.FieldSetMemberWrapperClass> getFieldsForm(String recordId, Boolean ocultar) {
        final Asset_Template__c fields = [SELECT Id, Onboarding_Type__c, Asset_Class__c FROM Asset_Template__c WHERE Id =: recordId LIMIT 1];
        String field = '';
        field = fields.Onboarding_Type__c+fields.Asset_Class__c;
        String fieldSet = '';
        fieldSet = field.replaceAll(' ', '');
        System.debug('fieldset ------------------------->'+fieldSet);
        return getFieldSets(fieldSet, ocultar);
    }

    /*
    * Get FieldSet for Asset Header
    */
    @AuraEnabled
    public static List<String> getPrimarySales (String recordId) {
        List<String> sales;
        sales = new List<String>();
        final Asset_Template__c assetTemplate = [SELECT Id, Primary_Sales__c, Secondary_Sales_Id__c FROM Asset_Template__c WHERE Id =: recordId];
        sales.add(assetTemplate.Primary_Sales__c);
        sales.add(assetTemplate.Secondary_Sales_Id__c);

        return sales;
    }

    /*
    * Get FieldSet for Asset Header
    */
    @AuraEnabled
    public static void updateValues (String recordId, Asset_Template__c assetHeader) {
        System.debug('assetHeader-------------------> '+assetHeader);
        Asset_Template__c oldTemplate;
        oldTemplate = [SELECT Id, Asset_Class__c, Onboarding_Type__c FROM Asset_Template__c WHERE Id =: recordId];
        Asset_Template__c assetTemplate;
        assetTemplate = assetHeader;
        assetTemplate.id = recordId;
        assetTemplate.Asset_Class__c = oldTemplate.Asset_Class__c;
        assetTemplate.Onboarding_Type__c = oldTemplate.Onboarding_Type__c;
        updateAsset(assetTemplate);
    }

    /*
    * Get FieldSet for Asset Header
    */
    public static List<TemplateVF_Controller.FieldSetMemberWrapperClass> getFieldSets(String fieldSet, Boolean ocultar) {

        List<TemplateVF_Controller.FieldSetMemberWrapperClass> wrapperList;
        wrapperList = new List<TemplateVF_Controller.FieldSetMemberWrapperClass>();

        List<String> lFields;
        lFields = new List<String>();

        Schema.SObjectType sObj;
        sObj = Schema.getGlobalDescribe().get('Asset_Template__c');

        try {

            for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldSet).getFields()) {
                TemplateVF_Controller.FieldSetMemberWrapperClass wrapper;
                wrapper = new TemplateVF_Controller.FieldSetMemberWrapperClass();
                wrapper.isDBRequired = fieldMember.getDbRequired();
                wrapper.isRequired = fieldMember.getRequired();
                wrapper.fieldType = String.valueOf(fieldMember.getType());
                wrapper.fieldLabel = fieldMember.getLabel();
                wrapper.fieldAPIName = fieldMember.getFieldPath();
                wrapper.isValidationField = false;

                if(!ocultar || (ocultar && !Label.E_Commerce_Lookup.contains(wrapper.fieldAPIName))) {
                    wrapperList.add(wrapper);
                    lFields.add(wrapper.fieldAPIName);
                    System.debug(wrapper.fieldAPIName);
                }
            }
        } catch(Exception exc) {
            system.debug('exc ' + exc);
        }
        System.debug('lFields---------->'+lFields);
        return wrapperList;
    }

    /*
    * Get FieldSet for Asset Header
    */
    public static void updateAsset (Asset_Template__c assetTemplate) { //NOSONAR
        System.debug('entro en updateAsset------------------>' + assetTemplate);
        assetTemplate.Secondary_Sales__c = null; //NOSONAR
        if(assetTemplate.Onboarding_Type__c == NEWCLIENT || assetTemplate.Onboarding_Type__c == NEWPROD || assetTemplate.Onboarding_Type__c == PLATFORMADD || (assetTemplate.Onboarding_Type__c == NEWUSERSTR && assetTemplate.Asset_Class__c == ASSETEQUITY)) {
            newClientProduct(assetTemplate);
        } else {
            newUser(assetTemplate);
        }
    }
     /*
    * Get FieldSet for Asset Header
    */
    public static void newClientProduct (Asset_Template__c assetTemplate) {
        System.debug('New client---------------------->'+assetTemplate);
        if(assetTemplate.Primary_Sales__c != null && String.valueOf(assetTemplate.Primary_Sales__c) != '') { //NOSONAR
            User usuario;
            usuario = [SELECT Id, UserRoleId, UserRole.Name  FROM User WHERE Id =: assetTemplate.Primary_Sales__c];
            assetTemplate.Secondary_Sales__c = usuario.UserRole.Name;
            assetTemplate.Secondary_Sales_Id__c = usuario.UserRoleId;
        } else if(assetTemplate.Secondary_Sales_Id__c != null && String.valueOf(assetTemplate.Secondary_Sales_Id__c) != '') { //NOSONAR
            UserRole rol;
            rol = [Select Id, Name FROM UserRole WHERE Id =: assetTemplate.Secondary_Sales_Id__c];
            assetTemplate.Secondary_Sales__c = rol.Name;
            assetTemplate.Secondary_Sales_Id__c = rol.Id;
            System.debug('rol-------------------->'+rol);
        }
        update assetTemplate;
    }

    /*
    * Get FieldSet for Asset Header
    */
    public static void newUser (Asset_Template__c assetTemplate) {
        update assetTemplate;
    }

}