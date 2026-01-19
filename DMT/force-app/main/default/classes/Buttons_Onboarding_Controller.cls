/**
* Buttons_Onboarding_Controller
*/
@SuppressWarnings('sf:TooManyMethods, sf:CyclomaticComplexity, sf:ConfusingTernary')
public with sharing class Buttons_Onboarding_Controller {

    /*
    * String
    */
    static final String NEWSTR = 'New';
    /*
    * String
    */
    static final String IMPLMENT = 'Implement';
    /*
    * String
    */
    static final String YES = 'Yes';
    /*
    * String
    */
    static final String WRONGDATA = 'Wrong Data';
    /*
    * String
    */
    static final String FIXEDINCOME = 'Fixed Income';
    /*
    * String
    */
    static final String IRS = 'IRS';
    /*
    * String
    */
    static final String PLATADD = 'Platform Addition';
    /*
    * String
    */
    static final String NEWCLIENT = 'New Client';
    /*
    * String
    */
    static final String PRODAPI = 'Product__c';
    /*
    * String
    */
    static final String PLATFORMAPI = 'Platform__c';
    /*
    * String
    */
    static final String NEWPROD = 'New Product';
    /*
    * String
    */
    static final String TIERAPI = 'Tier__c';
    /*
    * String
    */
    static final String NEWUSER = 'New User';

    /** instance */
    private static Buttons_Onboarding_Controller instance;
    /*
    * getInstance
    */
    public static Buttons_Onboarding_Controller getInstance() {   //NOSONAR
        if (instance == null) {
            instance = new Buttons_Onboarding_Controller();
        }
        return instance;
    }
    /*
    * Met0d0 para pasar sonar
    */
    private Buttons_Onboarding_Controller() {}

    /**
    *review
    */
    @AuraEnabled
    public static String review(String recordId) {
        try {
            System.debug('recordId----------------------->'+recordId);
            String valido = 'error';
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            System.debug('Status----------------------->'+assetTemp.Status__c);
            if(comprobarProducto(assetTemp)) {
                if (assetTemp.Secondary_Sales_Id__c != null) {
                    if(comprobarUserName(assetTemp)) {
                        assetTemp.Status__c = 'Review';
                        valido = 'correcto';
                        update assetTemp;
                    } else {
                        valido = 'ErrorUserName';
                    }
                }
                system.debug('valido---------------------->'+valido);
            } else {
                valido = 'producto';
            }
            return valido;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    *implement
    */
    @AuraEnabled
    public static String implement(String recordId) {
        try {
            System.debug('recordId --------------------> '+recordId);
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            String sFields = '';
            System.debug('Status---------------------------->'+assetTemp.Status__c);
            if(comprobarProducto(assetTemp)) {
                Set<String> excluir;
                excluir = commonPlatUser(assetTemp);
                excluir.addAll(uniqueFields(assetTemp, recordId));
                if (excluir.isEmpty()) {
                    final String errMarkit = comprobarMarkitWire(assetTemp);
                    final String erreMarket = comprobarContratoeMarket(assetTemp);
                    if(comprobarUserName(assetTemp) && errMarkit == '' && !comprobarSSIs(assetTemp) && erreMarket == '') {
                        assetTemp.Status__c = IMPLMENT;
                        update assetTemp;
                        if(assetTemp.Status__c == WRONGDATA) {
                            sFields = 'flow';
                        }
                    } else if (comprobarSSIs(assetTemp)) {
                        sFields = 'ssis';
                    } else if(!comprobarUserName(assetTemp)) {
                        sFields = 'ErrorUserName';
                    } else if(errMarkit.contains('permission::')) {
                        sFields = 'ErrorMarkitPermission';
                    } else if(errMarkit.contains('murex::')) {
                        sFields = 'ErrorMarkitMurex';
                    } else if(errMarkit.contains('markit::')) {
                        sFields = 'ErrorMarkitWire';
                    } else if(erreMarket.contains('signature::')) {
                        sFields = 'ErroreMarketSignature';
                    } else if(erreMarket.contains('agreement::')) {
                        sFields = 'ErroreMarketAgreement';
                    }
                } else {
                    sFields = String.join(new List<String>(excluir), ', ');
                }
            System.debug('sFields---------------------------->'+sFields);
            } else {
                sFields = 'producto';
            }
            return sFields;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    * validate
    */
    @AuraEnabled
    public static String validate(String recordId) {
        try {
            System.debug('recordId----------------->'+recordId);
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            String sFields = '';
            System.debug('Status--------------------->'+assetTemp.Status__c);
            if(comprobarProducto(assetTemp)) {
                if (assetTemp.Secondary_Sales_Id__c == null) {
                    sFields = 'error';
                } else {
                    Set<String> excluir;
                    excluir = commonFields(assetTemp);
                    excluir.addAll(uniqueFields(assetTemp, recordId));
                    final String erreMarket = comprobarContratoeMarket(assetTemp);
                    System.debug('erreMarket------>'+erreMarket);
                    if (excluir.isEmpty()) {
                        if(comprobarSSIs(assetTemp)) {
                            sFields = 'ssis';
                        } else if(!comprobarUserName(assetTemp)) {
                            sFields = 'ErrorUserName';
                        } else if(erreMarket.contains('signature::')) {
                            sFields = 'ErroreMarketSignature';
                        } else if(erreMarket.contains('agreement::')) {
                            sFields = 'ErroreMarketAgreement';
                        } else {
                            assetTemp.Status__c = 'Validate';
                            update assetTemp;
                        }
                    } else {
                        sFields = String.join(new List<String>(excluir), ', ');
                    }
                }
            } else {
                sFields = 'producto';
            }
            return sFields;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    * approve
    */
    @AuraEnabled
    public static void approve(String recordId) {
        try {
            System.debug('recordId------------------->'+recordId);
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            System.debug('Status ---------------------------->'+assetTemp.Status__c);
            if (assetTemp.Status__c == 'Validate' && (assetTemp.Onboarding_Type__c == NEWCLIENT || assetTemp.Onboarding_Type__c == NEWPROD)) {
                assetTemp.Status__c = IMPLMENT;
                update assetTemp;
            }
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    * approveTrader
    */
    @AuraEnabled
    public static String approveTrader(String recordId) {
        try {
            String traders = '';
            Boolean allProd = false;
            Set<String> lstTraders;
            lstTraders = new Set<String>();
            System.debug('recordId----->'+recordId);
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            System.debug('Status------------> '+assetTemp.Status__c);
            traderProducts(recordId);
            for(Asset_Product__c prod : [SELECT Id, Asset_Template__c, Trader_Group__c, Trader_Approver__r.Name, Approval_date__c, Trader_Approver__c FROM Asset_Product__c WHERE Asset_Template__c =: recordId AND Trader_Group__c != null]) {   //NOSONAR
                System.debug('prod.Trader_Approver__c---------------------------->'+prod.Trader_Approver__c);
                if(prod.Trader_Approver__c == null) {
                    allProd = true;
                } else {
                    lstTraders.add(prod.Trader_Approver__r.Name);
                }
            }
            System.debug('lstTraders---------------------------->'+lstTraders);
            if(lstTraders.isEmpty() || allProd) {
                traders = 'falta';
            } else {
                List<String> lstTrad;
                lstTrad = new List<String>();
                lstTrad.addAll(lstTraders);
                traders = String.join(lstTrad, ', ');
                System.debug('traders---------------------------->'+traders);
                assetTemp.Status__c = IMPLMENT;
                update assetTemp;
            }
            return traders;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    * rejectTrader
    */
    @AuraEnabled
    public static void rejectTrader(String recordId) {
        try {
            System.debug('recordId---------------------------->'+recordId);
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            System.debug('Status---------------------------------------->'+assetTemp.Status__c);
                assetTemp.Status__c = 'Review';
                assetTemp.Trader_Resolution_Date__c = Date.today();
                update assetTemp;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    * complete
    */
    @AuraEnabled
    public static Boolean complete(String recordId) {
        try {
            System.debug('recordId---------------------------->'+recordId);
            Boolean complete = false;
            Asset_Template__c assetTemp;
            assetTemp = getForm(recordId);
            EsalesDynamicButtonsHandler dynamicButtons;
            dynamicButtons = new EsalesDynamicButtonsHandler();
            Map<Asset_Template__c, Boolean> mapAsset;
            mapAsset = completeAux(assetTemp, dynamicButtons.rolImplement('GLOBAL MARKETS E-COMMERCE'),  dynamicButtons.getRoleButtons('GLOBAL EQUITIES DERIV. SALES'));
            if(mapAsset.get(assetTemp)) {
                assetTemp.Status__c = 'Completed';
                assetTemp.Completed_Date__c = Datetime.now();
                update assetTemp;
                complete = true;
            }
            return complete;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
     * Reject Client
     *
     */
    @AuraEnabled
    public static void rejectClient(String recordId, Asset_Template__c temp) {
        try {
            System.debug('temp----------------------->'+temp);
            System.debug('temp----------------------->'+temp.Rejection_Reason__c);
            Asset_Template__c form;
            form = [SELECT Id, Status__c, Rejection_Reason__c FROM Asset_Template__c WHERE Id =:recordId LIMIT 1];
            form.Status__c = 'Client Rejected';
            form.Rejection_Reason__c = temp.Rejection_Reason__c;
            update form;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /**
    * getForm
    */
    private static Asset_Template__c getForm(String recordId) {
        List<TemplateVF_Controller.FieldSetMemberWrapperClass> fieldset;
        fieldset = Asset_Controller.getFieldsForm(recordId, false);
        Set<String> campos;
        campos = new Set<String>();
        List<String> camposUnicos;
        camposUnicos = new List<String>{'Id', 'Asset_Class__c', 'Name', 'Murex_Code__c', 'Do_you_already_work_with_this_client__c', 'Trader_Resolution_Date__c', 'Reject_Reason__c', 'Rejection_Reason__c', 'User_Rejection_Reason__c', 'Status__c', 'Star_Code__c', 'Onboarding_Type__c', 'Petitioner_Name__c', 'Client__c', 'Client_Type__c', 'Description__c', 'Additional_Info__c', 'Primary_Sales__c', 'Secondary_Sales__c', 'Secondary_Sales_Id__c'};
        campos.addAll(camposUnicos);
        for(TemplateVF_Controller.FieldSetMemberWrapperClass field : fieldSet) {
            campos.add(field.fieldAPIName);
        }
        List<String> camposFinal;
        camposFinal = new List<String>(campos);
        final String query = 'SELECT '+ String.join(camposFinal,', ')+' FROM Asset_Template__c WHERE Id = :recordId LIMIT 1';
        return Database.query(String.escapeSingleQuotes(query));
    }

    /**
    * allApprove
    */
    public static void allApprove(List<String> lIDs) {
        List<String> lIDsUse;
        lIDsUse = new List<String>();
        lIDsUse.addAll(lIDs);
        for(Asset_Template__c assetTemp : [SELECT id, Name, (SELECT id, Trader_Group__c FROM Asset_Products__r WHERE Trader_Group__c != null) FROM Asset_Template__c WHERE id IN :lIDsUse]) {   //NOSONAR
            for(Asset_Product__c assetProd : assetTemp.Asset_Products__r) {
                System.debug(assetProd);
                if(lIDsUse.contains(assetTemp.id)) {
                    lIDsUse.remove(lIDsUse.indexOf(assetTemp.id));
                }
            }
        }

        List<Asset_Template__c> lUpdate;
        lUpdate = new List<Asset_Template__c> ();
        for(String idTemp : lIDsUse) {
            lUpdate.add(new Asset_Template__c (ID=idTemp, Status__c=IMPLMENT));
        }
        update lUpdate;
    }

    /**
    * traderProducts
    */
    private static void traderProducts(String recordId) {
        final List<Asset_Product__c> prods = [SELECT Id, Asset_Template__c, Trader_Group__c, Approval_date__c, Trader_Approver__c FROM Asset_Product__c WHERE Asset_Template__c =: recordId];
        Set<String> groupId;
        groupId = getGroupsId(recordId, prods);
        Map<Id,List<String>> mapTrader;
        mapTrader = createMap(prods, groupId);
        String userId;
        userId = UserInfo.getUserId();
        List<Asset_Product__c> prodUpdate;
        prodUpdate = new List<Asset_Product__c>();
        for(Asset_Product__c prod : prods) {
            if(mapTrader.containsKey(prod.Id) && mapTrader.get(prod.Id).contains(userId)) {
                prod.Trader_Approver__c = userId;
                prod.Approval_date__c = Datetime.now();
                prodUpdate.add(prod);
            }
        }
        update prodUpdate;
    }

    /**
    * getGroupsId
    */
    public static Set<String> getGroupsId(String recordId, List<Asset_Product__c> prods) {
        Set<String> groupId;
        groupId = new Set<String>();
        for(Asset_Product__c prod : prods) {
            if(prod.Trader_Group__c != null) {
                groupId.add(prod.Trader_Group__c);
            }
        }
        return groupId;
    }

    /**
    * createMap
    */
    private static Map<Id,List<String>> createMap(List<Asset_Product__c> prods, Set<String> groupId) {
        final List<GroupMember> members = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: groupId];
        Map<Id,List<String>> mapTrader;
        mapTrader = new Map<Id,List<String>>();
        List<String> traderId;
        traderId = new List<String>();
        for(GroupMember mem : members) {
            for(Asset_Product__c prod : prods) {
                if(prod.Trader_Group__c  == mem.GroupId) {
                    if(mapTrader.containsKey(prod.Id)) {
                        system.debug('traderId------------------------------>'+traderId);
                        traderId = mapTrader.get(prod.Id);
                        system.debug('traderId 2------------------------------>'+traderId);
                        traderId.add(mem.UserOrGroupId);
                        mapTrader.put(prod.Id,traderId);
                    } else {
                        mapTrader.put(prod.Id,new List<String>{mem.UserOrGroupId});
                    }
                }
            }
        }
        System.debug('traderId---->'+traderId);
        return mapTrader;
    }

    /**
    * commonPlatUser
    */
    private static Set<String> commonPlatUser(Asset_Template__c assetTemp) {
        Set<String> excluir;
        excluir = new Set<String>();

        String objectName = '';
        objectName = 'Asset_Template__c';

        String fieldset = '';
        fieldset = assetTemp.Onboarding_Type__c + assetTemp.Asset_Class__c;

        Schema.SObjectType sObj;
        sObj = Schema.getGlobalDescribe().get(objectName);
        for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldset.replace(' ', '')).getFields()) {
            if(assetTemp.get(fieldMember.getFieldPath())== null) {
                excluir.add(fieldMember.getLabel());
            }
        }
        return excluir;
    }

    /**
    * commonFields
    */
    private static Set<String> commonFields(Asset_Template__c assetTemp) {
        Set<String> excluir;
        excluir = new Set<String>();

        String objectName = '';
        objectName = 'Asset_Template__c';

        String fieldset = '';
        fieldset = assetTemp.Onboarding_Type__c + assetTemp.Asset_Class__c;

        Schema.SObjectType sObj;
        sObj = Schema.getGlobalDescribe().get(objectName);

        for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldset.replace(' ', '')).getFields()) {
            if(assetTemp.get(fieldMember.getFieldPath())== null) {
                excluir.add(fieldMember.getLabel());
            }
        }
        if (assetTemp.Primary_Sales__c == null) {
            excluir.add('Primary Sales');
        }
        if (assetTemp.Secondary_Sales__c == null) {
            excluir.add('Secondary Sales');
        }
        if (assetTemp.Secondary_Sales_Id__c == null) {
            excluir.add('Secondary Sales Id');
        }
        return excluir;
    }

    /**
    * uniqueFields
    */
    private static Set<String> uniqueFields(Asset_Template__c assetTemp, String recordId) {
        System.debug('recordId---> '+recordId);
        System.debug('assetTemp---------------------->'+assetTemp);
        List<String> campos;
        campos = new List<String>();
        Set<String> faltan;
        faltan = new Set<String>();
        String getQuery;
        getQuery = getSOQLFields();
        System.debug('query------------->'+getQuery);
        List<Asset_Product__c> listProd;
        listProd = Database.query(String.escapeSingleQuotes(getQuery));
        for(Asset_Product__c prod : listProd) {
            campos = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(assetTemp.Asset_Class__c, assetTemp.Onboarding_Type__c, prod.Platform__c, prod.Product__c, 'ALL', null);
            //campos.addAll(getFieldsProdPlatform(assetTemp));
            for (String aux : campos) {
                if(prod.get(aux) == null && checkDepenFields(prod, aux)) {
                    faltan.add(getLabelApiName(aux));
                }
            }
        }
        return faltan;
    }

    /**
    * getLabelApiName
    */
    private static String getLabelApiName (String aux) {
        Map<String, Schema.SObjectField> fieldMap;
        fieldMap = Asset_Product__c.sObjectType.getDescribe().fields.getMap();
        return fieldMap.get(aux).getDescribe().getLabel();
    }
    /*
    * Get soql with all fields
    */
    private static String getSOQLFields () {    //NOSONAR
        Map<String, Schema.SObjectField> fieldMap;
        fieldMap = Asset_Product__c.sObjectType.getDescribe().fields.getMap();
        Set<String> fieldNames;
        fieldNames = fieldMap.keySet();
        String sFields = '';
        sFields = String.join(new List<String>(fieldNames), ',');
        return 'select ' + sFields + ' from Asset_Product__c where Asset_Template__c =: recordId';
    }

    /**
    * checkDepenFields
    */
    private static Boolean checkDepenFields(Asset_Product__c prod, String aux) {
        Boolean addField = false;
        if(aux == 'Rating__c' && prod.CVA_List__c == YES) {
            addField = true;
        } else if(aux == 'Prime_Broker_Name__c' && prod.Is_client_using_a_Prime_Broker_PB__c == YES) {
            addField = true;
        } else if(aux == 'Additional_info_per_Country__c' && prod.Different_Tier_per_Country__c == YES) {
            addField = true;
        } else if(aux == 'Settlement_Limit_allowed_by_the_DN__c' && prod.Is_client_using_a_Prime_Broker_PB__c == YES) {
            addField = true;
        } else if(aux == 'Net_open_position_allowed_by_the_DN__c' && prod.Is_client_using_a_Prime_Broker_PB__c == YES) {
            addField = true;
        } else if(aux == 'The_DN_allows_products_ccys_requested__c' && prod.Is_client_using_a_Prime_Broker_PB__c == YES) {
            addField = true;
        } else if(aux == 'MIFID_Category__c' && prod.MIFID_Client__c == YES) {
            addField = true;
        } else if(aux != 'MIFID_Category__c' && aux != 'Rating__c' && aux != 'Prime_Broker_Name__c' && aux != 'Additional_info_per_Country__c' && aux != 'Settlement_Limit_allowed_by_the_DN__c' && aux != 'Net_open_position_allowed_by_the_DN__c' && aux != 'The_DN_allows_products_ccys_requested__c') {
            addField = true;
        }
        return addField;
    }
    /**
    * comprobarMarkitWire los 3 diferentes errores de IRS
    */
    private static String comprobarMarkitWire(Asset_Template__c temp) {
        String cambiarFase = '';
        if(temp.Asset_Class__c == IRS && temp.Onboarding_Type__c == NEWCLIENT) {
            for(Asset_Product__c prod : [SELECT Id, Does_the_client_confirm_via_Markitwire__c, Set_up_of_Drop_Copy__c, Do_we_have_Markitwire_permissions__c, Is_the_STP_Markitwire_Murex_in_place__c FROM Asset_Product__c WHERE Asset_Template__c =: temp.Id]) {
                if(prod.Do_we_have_Markitwire_permissions__c == 'No' || prod.Do_we_have_Markitwire_permissions__c == 'Not sure') {
                    cambiarFase += 'permission::';
                } else if(prod.Is_the_STP_Markitwire_Murex_in_place__c == 'No' || prod.Is_the_STP_Markitwire_Murex_in_place__c == 'Not sure') {
                    cambiarFase += 'murex::';
                } else if(prod.Does_the_client_confirm_via_Markitwire__c == 'No' && (prod.Set_up_of_Drop_Copy__c == 'Not needed' || prod.Set_up_of_Drop_Copy__c == 'Pending')) {
                    cambiarFase += 'markit::';
                }
            }
        }
        return cambiarFase;
    }

    /**
    * comprobarContratoeMarket los 2 diferentes errores de eMarket
    */
    private static String comprobarContratoeMarket(Asset_Template__c temp) {
        String cambiarFase = '';
        if(temp.Asset_Class__c == 'FX' && (temp.Onboarding_Type__c == NEWCLIENT || temp.Onboarding_Type__c == 'Platform Addition' || temp.Onboarding_Type__c == 'New User')) {
            for(Asset_Product__c prod : [SELECT Id, Client_signed_BBVA_eMarkets_agreement__c, Signature_sheet_for_new_users__c,Asset_Template__r.Onboarding_Type__c FROM Asset_Product__c WHERE Asset_Template__c =: temp.Id AND ((Signature_sheet_for_new_users__c = 'No' AND Asset_Template__r.Onboarding_Type__c = 'New User') OR (Client_signed_BBVA_eMarkets_agreement__c = 'No' AND (Asset_Template__r.Onboarding_Type__c = 'New Client' OR Asset_Template__r.Onboarding_Type__c = 'Platform Addition')))]) {
                if(prod.Signature_sheet_for_new_users__c == 'No' && prod.Asset_Template__r.Onboarding_Type__c == 'New User') {
                    cambiarFase += 'signature::';
                } else {
                    cambiarFase += 'agreement::';
                }
            }
        }
        return cambiarFase;
    }

    /**
    * comprobarUserName
    */
    private static Boolean comprobarUserName(Asset_Template__c assetTemp) {
        Boolean cambiarFase = true;
        if(assetTemp.Asset_Class__c == FIXEDINCOME || assetTemp.Asset_Class__c == IRS) {
            final List<Asset_Product__c> lProd = [SELECT Id, Platform__c, Product__c, Asset_Template__c, User_Name_FI__c FROM Asset_Product__c WHERE Asset_Template__c =: assetTemp.Id AND Platform__c = 'Bloomberg' AND User_Name_FI__c LIKE '%All pending users%'];
            List<String> campos;
            campos = new List<String>();
            for(Asset_Product__c prod : lProd) {
                campos = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(assetTemp.Asset_Class__c, assetTemp.Onboarding_Type__c, prod.Platform__c, prod.Product__c, 'ALL', null);
                if(campos.contains('User_Name_FI__c')) {
                    cambiarFase = false;
                }
            }
        }
        return cambiarFase;
    }

    /**
    * comprobarProducto
    */
    private static Boolean comprobarProducto(Asset_Template__c assetTemp) {
        Boolean producto = false;
        final List<Asset_Product__c> lProd = [SELECT Id FROM Asset_Product__c WHERE Asset_Template__c =: assetTemp.Id];
        if(!lProd.isEmpty()) {
            producto = true;
        }
        return producto;
    }

    /**
    * Comprobación de si tiene el producto USTs y el campo ssis marcado
    */
    private static Boolean comprobarSSIs(Asset_Template__c assetTemp) {
        Boolean ssis = false;
        String fixedSt;
        fixedSt = 'Fixed Income';
        if(assetTemp.Asset_Class__c == fixedSt) {
            final List<Asset_Product__c> lstProd = [SELECT Id, Platform__c, Product__c, SSIs_for_USTs__c FROM Asset_Product__c WHERE Asset_Template__c =: assetTemp.Id AND Product__c = 'USTs' AND SSIs_for_USTs__c = false];
            List<String> campos;
            campos = new List<String>();
            for(Asset_Product__c prod : lstProd) {
                campos = OnboardingPlatformProduct_ctrl.getFieldSetFromAsset(assetTemp.Asset_Class__c, assetTemp.Onboarding_Type__c, prod.Platform__c, prod.Product__c, 'ALL', null);
                if(campos.contains('SSIs_for_USTs__c')) {
                    ssis = true;
                }
            }
        }
        return ssis;
    }

    /**
    * completeAux se usa tanto para completar un formulario como para el completeAll
    */
    private static Map<Asset_Template__c, Boolean> completeAux(Asset_Template__c assetTemp, Boolean roleUser, Boolean roleConnectivity) {
        Map<Asset_Template__c, Boolean> mapAsset;
        mapAsset = new Map<Asset_Template__c, Boolean>();
        if((roleUser || roleConnectivity) && assetTemp.Status__c == IMPLMENT ) {
            mapAsset.put(assetTemp, true);
        } else {
            mapAsset.put(assetTemp, false);
        }
        return mapAsset;
    }

}