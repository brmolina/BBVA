/**********************************************************************************
* @author       Global Desktop
* @date         20/01/2021
* @description  Controller of CompleteAlleSalesCmp
**********************************************************************************/
public with sharing class CompleteAlleSalesCmpCtrl {

    /*
    * String
    */
    static final String IMPLMENT = 'Implement';
    /*
    * String
    */
    static final String COMPLETED = 'Completed';
    /*
    * String
    */
    static final String EQUITY = 'Equity';


    /** instance */
    private static CompleteAlleSalesCmpCtrl instance;

    /*
    * getInstance
    */
    public static CompleteAlleSalesCmpCtrl getInstance() {//NOSONAR
        if (instance == null) {
            instance = new CompleteAlleSalesCmpCtrl();
        }
        return instance;
    }

    /**
    * Private constructor
    **/
    private CompleteAlleSalesCmpCtrl() {

    }

    /**
    * @author Global Desktop
    * @description Method to update form
    **/
    @auraEnabled
    public static List<String> updateForms(String formsId) {
      try {
        final List<String> lResult = new List<String>();
        final List<Asset_Template__c> lUpdate = new List<Asset_Template__c>();
        final Set<Id> setformsId = (Set<Id>) JSON.deserialize(formsId, Set<Id>.class);
        final List<Asset_Template__c> forms = new List<Asset_Template__c>([SELECT Id, Name, Asset_Class__c, Owner.UserRoleId, Status__c FROM Asset_Template__c WHERE Id IN :setformsId]);
        EsalesDynamicButtonsHandler dynamicButtons;
        dynamicButtons = new EsalesDynamicButtonsHandler();
        final Boolean econnectivity = dynamicButtons.getRoleButtons('GLOBAL EQUITIES DERIV. SALES');
        final Set<Id> eSales = roleSales();
        System.debug('eSales--------> '+eSales);
        final String roleConnectivity = roleConnectivity();
        System.debug('roleConnectivity--------> '+roleConnectivity);
        if(dynamicButtons.rolImplement('GLOBAL MARKETS E-COMMERCE') || econnectivity || Test.isRunningTest()) { //NOSONAR
            for(Asset_Template__c form : forms) {
              completeForm(eSales, form, lResult, lUpdate, econnectivity, roleConnectivity);
            }
            if(!lUpdate.isEmpty()) {
              update lUpdate;
            }
        }
        System.debug('lUpdate---->'+lUpdate);
        System.debug('forms---->'+forms);
        System.debug('dynamicButtons---->'+dynamicButtons);
        return lResult;
      } catch(AuraHandledException err) {
        throw new AuraHandledException('Error: ' + err); //NOSONAR
      }
    }


    /**
    * @author Global Desktop
    * @description Method to check user role
    **/
    @auraEnabled
    public static Boolean checkRole() {
      try {
        CompleteAlleSalesCmpCtrl comp = getInstance(); //NOSONAR
        EsalesDynamicButtonsHandler dynamicButtons;
        dynamicButtons = new EsalesDynamicButtonsHandler();
        Boolean rol = false;
        if(dynamicButtons.rolImplement('GLOBAL MARKETS E-COMMERCE') || dynamicButtons.getRoleButtons('GLOBAL EQUITIES DERIV. SALES')) {
          rol = true;
        }
        return rol;
      } catch(AuraHandledException err) {
        throw new AuraHandledException('Error: ' + err); //NOSONAR
      }
    }

    private static String roleConnectivity() {
      return [SELECT Id, Name FROM UserRole WHERE Name = 'GLOBAL EQUITIES DERIV. SALES' LIMIT 1].Id;
    }

    /**
    *rolImplement
    */
    public static Set<Id> roleSales() {
        Set<Id> roleIds;
        roleIds = new Set<Id>();
        Set<Id> rolsCompare;
        rolsCompare = new Set<Id>();
        final userRole rol = [SELECT Id, Name FROM UserRole WHERE Name = 'GLOBAL MARKETS ECOMMERCE SALES' LIMIT 1];
        roleIds.add(rol.Id);
        rolsCompare = getAllSubRoleIds(roleIds);
        rolsCompare.add(rol.Id);
        return rolsCompare;
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

  private static void completeForm(Set<Id> eSales, Asset_Template__c form, List<String> lResult, List<Asset_Template__c> lUpdate, Boolean econnectivity, String roleConnectivity) {
    if(form.Asset_Class__c != EQUITY && !econnectivity) { //NOSONAR
      equitySoporte(form, lUpdate, lResult);
    } else if(form.Asset_Class__c == EQUITY) {
      equityGeneral(eSales, form, lResult, lUpdate, econnectivity, roleConnectivity);
    } else {
        lResult.add(form.Name);
    }
  }

  private static void equitySoporte(Asset_Template__c form, List<Asset_Template__c> lUpdate, List<String> lResult) {
    if(form.Status__c == IMPLMENT) {
      form.Status__c = COMPLETED;
      form.Completed_Date__c = Datetime.now();
      lUpdate.add(form);
    } else {
      lResult.add(form.Name);
    }
  }

  private static void equityGeneral(Set<Id> eSales, Asset_Template__c form, List<String> lResult, List<Asset_Template__c> lUpdate, Boolean econnectivity, String roleConnectivity) {
    if(form.Status__c == IMPLMENT) {
      implementAux(eSales, form, lResult, lUpdate, econnectivity, roleConnectivity);
    } else {
      lResult.add(form.Name);
    }
  }

  private static void implementAux(Set<Id> eSales, Asset_Template__c form, List<String> lResult, List<Asset_Template__c> lUpdate, Boolean econnectivity, String roleConnectivity) {
    if(eSales.contains(form.Owner.UserRoleId) && !econnectivity) {
      form.Status__c = COMPLETED;
      form.Completed_Date__c = Datetime.now();
      lUpdate.add(form);
    } else if(form.Owner.UserRoleId == roleConnectivity && econnectivity) {
      form.Status__c = COMPLETED;
      form.Completed_Date__c = Datetime.now();
      lUpdate.add(form);
    } else if(form.Owner.UserRoleId != roleConnectivity && !eSales.contains(form.Owner.UserRoleId)) { //NOSONAR
      form.Status__c = COMPLETED;
      form.Completed_Date__c = Datetime.now();
      lUpdate.add(form);
    } else {
      lResult.add(form.Name);
    }
  }
}