/**
*
* @author: Global Desktop
*/
@SuppressWarnings('sf:CyclomaticComplexity')
global with sharing class EsalesDynamicButtonsHandler implements dwp_dbpn.DynamicButtonsStatusInterface {   //NOSONAR

    /*
    * String
    */
    static final String ASSETEMP = 'Asset_Template__c';
    /*
    * String
    */
    static final String NEWSTR = 'New';
    /*
    * String
    */
    static final String IMPLEMENT = 'Implement';
    /*
    * String
    */
    static final String NEWCLIENT = 'New Client';
    /*
    * String
    */
    static final String NEWPROD = 'New Product';
    /*
    * String
    */
    static final String GLOBALMSALES = 'GLOBAL MARKETS ECOMMERCE SALES';
    /*
    * String
    */
    static final String REVIEW = 'Review';
    /*
    * String
    */
    static final String EQUITY = 'Equity';

    /*
    * getDynamicButtonStatus
    */
    global Set<String> getDynamicButtonStatus(String recordId, String sObjectName) {
        Set<String> buttonsStatusSet = new Set<String>();
        System.debug('recordId----------------->'+recordId);
        System.debug('sObjectName----------------->'+sObjectName);
        if(sObjectName == ASSETEMP) {
            final Asset_Template__c form = getForm(recordId);
            System.debug('Es eSales ------------> ');
            System.debug('form ------------> ' + form);
            if(!getConsultation()) {
                buttonsStatusSet = reviewButtons(form, buttonsStatusSet);
                buttonsStatusSet = approveButtons(form, buttonsStatusSet);
                buttonsStatusSet = submitButtons(form, buttonsStatusSet);
                buttonsStatusSet = implementButtons(form, buttonsStatusSet);
                buttonsStatusSet = editButtons(form, buttonsStatusSet);
                buttonsStatusSet = addProductButtons(form, buttonsStatusSet);
                buttonsStatusSet = approveReject(form, buttonsStatusSet);
                buttonsStatusSet = completedButtons(form, buttonsStatusSet);
                buttonsStatusSet = rejectClient(form, buttonsStatusSet);
            }
        }
        return buttonsStatusSet;
    }

    private Asset_Template__c getForm(String recordId) {
        return [SELECT Id, Name, Status__c, OwnerId, Murex_Code__c, eSales_check__c, Reject_Reason__c, Rejection_Reason__c, User_Rejection_Reason__c, Onboarding_Type__c, Asset_Class__c, Secondary_Sales_Id__c,(SELECT Id, Does_the_client_confirm_via_Markitwire__c FROM Asset_Products__r WHERE Does_the_client_confirm_via_Markitwire__c = 'No') FROM Asset_Template__c WHERE Id = :recordId LIMIT 1];
    }

    private List<String> getTraders(String recordId) {
        final List<Asset_Product__c> products = [SELECT Id, Asset_Template__c, Trader_Group__c FROM Asset_Product__c WHERE Asset_Template__c =: recordId];
        List<String> traderGroup;
        traderGroup = new List<String>();
        for(Asset_Product__c prod : products) {
            traderGroup.add(prod.Trader_Group__c);
        }
        final List<GroupMember> memberGroups = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: traderGroup];
        List<String> idUsuarios;
        idUsuarios = new List<String>();
        for(GroupMember miembro : memberGroups) {
            idUsuarios.add(miembro.UserOrGroupId);
        }
        return idUsuarios;
    }

    private Set<String> reviewButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        System.debug('form----------------->'+form);
        if(form.Status__c == NEWSTR && form.Onboarding_Type__c != 'New FX Account') {
            if(form.Asset_Class__c == EQUITY && !getRoleButtons('GLOBAL EQUITIES DERIV. SALES') && (form.Onboarding_Type__c == NEWCLIENT || form.Onboarding_Type__c == NEWPROD)) {
                buttonsDefined.add(REVIEW);
            } else if(form.Asset_Class__c != EQUITY && (form.Onboarding_Type__c == NEWCLIENT || form.Onboarding_Type__c == NEWPROD)) {
                buttonsDefined.add(REVIEW);
            }
        }
        System.debug('buttonsDefined 1----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    private Set<String> submitButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        Boolean rol;
        rol = getRol(form);
        if(form.Status__c == REVIEW && rol && (form.Onboarding_Type__c == NEWCLIENT || form.Onboarding_Type__c == NEWPROD) && (form.Asset_Class__c == 'Fixed Income' || form.Asset_Class__c == 'FX')) {
            buttonsDefined.add('Submit');
        } else if(form.Status__c == 'New' && rolImplement(GLOBALMSALES) && (form.Onboarding_Type__c == NEWCLIENT || form.Onboarding_Type__c == NEWPROD) && (form.Asset_Class__c == 'Fixed Income' || form.Asset_Class__c == 'FX')) {
            buttonsDefined.add('Submit');
        }
        System.debug('buttonsDefined 2----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    private Set<String> approveButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        if(form.Status__c == 'Approve' && (form.Onboarding_Type__c == NEWCLIENT || form.Onboarding_Type__c == NEWPROD)) {
            buttonsDefined.add('Submit');
        }
        System.debug('buttonsDefined 3----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    private Set<String> implementButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        if(form.Status__c == NEWSTR && (form.Onboarding_Type__c == 'Platform Addition' || form.Onboarding_Type__c == 'New FX Account' || form.Onboarding_Type__c == 'New User' || form.Onboarding_Type__c == 'Reject User' || form.Onboarding_Type__c == 'Reject Client' || form.Onboarding_Type__c == 'Reject Fund')) {
            buttonsDefined.add(IMPLEMENT);
        } else if(form.Status__c == 'Wrong Data' && (rolImplement(GLOBALMSALES) || (getRol(form) && form.eSales_check__c == true))) {
            buttonsDefined.add(IMPLEMENT);
            if(rolImplement(GLOBALMSALES) && form.Secondary_Sales_Id__c != null) {
                buttonsDefined.add('SalesReview');
            }
        } else if(form.Status__c == REVIEW && form.Asset_Class__c == EQUITY && getRol(form)) {
            buttonsDefined.add(IMPLEMENT);
        } else if(form.Status__c == NEWSTR && form.Asset_Class__c == EQUITY && (getRoleButtons('GLOBAL EQUITIES DERIV. SALES') || rolImplement(GLOBALMSALES))) {
            buttonsDefined.add(IMPLEMENT);
        } else if(form.Status__c == REVIEW && form.Asset_Class__c == 'IRS' && getRol(form) && (form.Onboarding_Type__c == 'New Client' || form.Onboarding_Type__c == 'New Product')) {
            buttonsDefined.add(IMPLEMENT);
        } else if(form.Status__c == REVIEW && form.Asset_Class__c == 'IRS' && rolImplement(GLOBALMSALES) && form.Asset_Products__r != null &&!form.Asset_Products__r.isEmpty()) {
            buttonsDefined.add(IMPLEMENT);
        } else if(form.Status__c == 'New' && form.Asset_Class__c == 'IRS' && rolImplement(GLOBALMSALES) &&(form.Onboarding_Type__c == 'New Client' || form.Onboarding_Type__c == 'New Product')) {
            buttonsDefined.add(IMPLEMENT);
        }
        System.debug('buttonsDefined 4----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    /**
     *
     * editButtons recoge las condiciones para que aparezca el boton edit
     */
    private Set<String> editButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        Boolean rol;
        rol = getRol(form);
        Boolean user;
        user = getUserId(form);
        Boolean trader;
        trader = getIfTrader(form.Id);
        String editS;
        editS = 'Edit';
        System.debug(trader+ ' editS ' + editS);
        if(getProfile()) {
            buttonsDefined.add(editS);
        } else if(form.Status__c != 'Completed' && form.Status__c != 'Client Rejected' && form.Status__c != 'Implement') {
            if(form.Status__c == NEWSTR && (user || rolImplement(GLOBALMSALES))) {
                buttonsDefined.add(editS);
            } else if(form.Status__c == REVIEW && (rol || rolImplement(GLOBALMSALES))) {
                buttonsDefined.add(editS);
            } else if(form.Status__c == 'Validate' && trader && comprobarAprove(form.Id)) {
                buttonsDefined.add('Edit_Trader');
            } else if(form.Status__c == 'Wrong Data' && (rolImplement(GLOBALMSALES) || (getRol(form) && form.eSales_check__c == true))) {
                buttonsDefined.add(editS);
            }
        }
        System.debug('user----------------->'+user);
        System.debug('rol----------------->'+rol);
        System.debug('buttonsDefined 5----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    /**
     *
     * addProductButtons recoge las condiciones para que aparezca el boton edit
     */
    private Set<String> addProductButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        Boolean user;
        user = getUserId(form);
        if(form.Status__c == NEWSTR && (user || rolImplement(GLOBALMSALES))) {
            buttonsDefined.add('AddProduct');
        }
        System.debug('buttonsDefined 6----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    private Set<String> approveReject(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        Boolean trader;
        trader = getIfTrader(form.Id);
        if(form.Status__c == 'Validate' && trader && comprobarAprove(form.Id)) {
            buttonsDefined.add('ApproveTrader');
            buttonsDefined.add('Reject');
        }
        System.debug('buttonsDefined 7----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    private Set<String> completedButtons(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        if(form.Status__c == IMPLEMENT && (rolImplement('GLOBAL MARKETS E-COMMERCE') || Test.isRunningTest())) {   //NOSONAR
            buttonsDefined.add('Complete');
            buttonsDefined.add('WrongData');
        } else if(form.Status__c == IMPLEMENT && form.Asset_Class__c == EQUITY && (getRoleButtons('GLOBAL EQUITIES DERIV. SALES') || Test.isRunningTest())) {   //NOSONAR
            buttonsDefined.add('Complete');
        }
        System.debug('buttonsDefined 8----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    private Set<String> rejectClient(Asset_Template__c form, Set<String> buttonsStatusSet) {
        final Set<String> buttonsDefined = buttonsStatusSet;
        System.debug('form----------------->'+form);
        if(form.Status__c == REVIEW && getRol(form)) {
            buttonsDefined.add('RejectClient');
        }
        System.debug('buttonsDefined 9----------------->'+buttonsDefined);
        return buttonsDefined;
    }

    /**
    * comprobarAprove
     */
    public static Boolean comprobarAprove(String recordId) {
        Boolean faltaAprobar = false;
        Id userId;
        userId = UserInfo.getUserId();
        System.debug('userId---->'+userId);
        final List<Asset_Product__c> prods = [SELECT Id, Asset_Template__c, Trader_Group__c, Approval_date__c, Trader_Approver__c FROM Asset_Product__c WHERE Asset_Template__c =: recordId];
        Set<String> groupId;
        groupId = Buttons_Onboarding_Controller.getGroupsId(recordId, prods);
        final List<GroupMember> members = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: groupId];
        List<Asset_Product__c> auxProd;
        auxProd = new List<Asset_Product__c>();
        for(Asset_Product__c prod : prods) {
            for(GroupMember mem : members) {
                if(prod.Trader_Group__c  == mem.GroupId && mem.UserOrGroupId == userId) {
                    auxProd.add(prod);
                }
            }
        }
        system.debug('auxProd------------------------>'+auxProd);
        for(Asset_Product__c prod : auxProd) {
            if(prod.Trader_Approver__c == null) {
                system.debug('Prod dentro del bucle--------------->'+prod);
                faltaAprobar = true;
            }
        }
        return faltaAprobar;
    }


    /**
    * getProfile
    */
    public static Boolean getProfile() {   //NOSONAR
        final List<String> lProfName = new List<String> {'System Administrator', 'Administrator Business'};
        final Map<Id, Profile> mProfiles = new Map<Id, Profile> ([SELECT id, Name FROM Profile WHERE Name IN :lProfName]);
        final Id profileID = userinfo.getProfileId();
        Boolean perfil = false;
        if(mProfiles.containsKey(profileID)) {
            perfil = true;
        }
        return perfil;
    }


    /**
    * getEconnectivity
    */
    public Boolean getRoleButtons(String roleName) {
        Boolean rol = false;
        final String rolId = UserInfo.getUserRoleId();
        final String rolEquities = [SELECT Id, Name FROM UserRole WHERE Name =: roleName LIMIT 1].Id;
        if(rolEquities == rolId) {
            rol = true;
        }
        return rol;
    }


    /**
    * getProfile
    */
    public static Boolean getConsultation() {   //NOSONAR
        final List<String> lProfName = new List<String> {'Consultation IT'};
        final Map<Id, Profile> mProfiles = new Map<Id, Profile> ([SELECT id, Name FROM Profile WHERE Name IN :lProfName]);
        final Id profileID = userinfo.getProfileId();
        Boolean perfil = false;
        if(mProfiles.containsKey(profileID)) {
            perfil = true;
        }
        return perfil;
    }

    private Boolean getRol(Asset_Template__c form) {
        Boolean rol = false;
        final String rolId = UserInfo.getUserRoleId();
        if(form.Secondary_Sales_Id__c == rolId) {
            rol = true;
        }
        return rol;
    }

    /**
    *getUserId
    */
    public Boolean getUserId(Asset_Template__c form) {
        Boolean user = false;
        String userId;
        userId = UserInfo.getUserId();
        if(form.OwnerId == userId) {
            user = true;
        }
        return user;
    }

    /**
    *getIfTrader
    */
    public Boolean getIfTrader(Id recordId) {
        Boolean trader = false;
        String userId;
        userId = UserInfo.getUserId();
        List<String> traders;
        traders = getTraders(recordId);
        if(traders.contains(userId)) {
            trader = true;
        }
        return trader;
    }

    /**
    *rolImplement
    */
    public Boolean rolImplement(String roleName) {
        String rolId;
        rolId = UserInfo.getUserRoleId();
        Set<Id> roleIds;
        roleIds = new Set<Id>();
        Set<Id> rolsCompare;
        rolsCompare = new Set<Id>();
        Boolean editar = false;
        final userRole rol = [SELECT Id, Name FROM UserRole WHERE Name =: roleName LIMIT 1];
        roleIds.add(rol.Id);
        rolsCompare = getAllSubRoleIds(roleIds);
        rolsCompare.add(rol.Id);
        for(Id idRol : rolsCompare) {
            if(rolId == idRol) {
                editar = true;
            }
        }
        return editar;
    }

    private static Set<Id> getAllSubRoleIds(Set<ID> roleIds) {
        Set<Id> currentRoleIds;
        currentRoleIds = new Set<Id>();
        for(UserRole userRole : [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleID != null]) {   //NOSONAR
            currentRoleIds.add(userRole.Id);
        }
        if(!currentRoleIds.isEmpty()) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
            return currentRoleIds;
    }
}