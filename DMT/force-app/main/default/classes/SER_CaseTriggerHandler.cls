/*---------------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   SER_Case_TRIGGER Handler.

    History:
    <Date>          <Author>                <Description>
    16/09/2020      Javier Touchard         Initial Version.
    13/01/2021      Irene Calvo             Mergeo con trigger de paquete AP 3.2

----------------------------------------------------------------------------------------------*/
public with sharing class SER_CaseTriggerHandler {
  /** GM */
  public final static String GM_BS = 'GM';
  /** GTB */
  public final static String GTB = 'GTB';
  /** System */
  public final static String SYSTEM_USER = 'System';
  /** instance */
  private static SER_CaseTriggerHandler instance;
  /** CUSTOM SETTING CIB_User_Org__c */
  private final CIB_User_Org__c userSettings;
  /** USER_NAME */
  public final static String USER_NAME;
  /** Mapa que relaciona el Id de un recordtype con su nombre */
  public final static Map<String, String> RECORDTYPEMP;
  static {
    USER_NAME = [SELECT Name FROM User WHERE id = : UserInfo.getUserId()].Name;
    RECORDTYPEMP = SER_RecordTypeUtils.getRecordTypes('Case');
  }


  //CONSTRUCTOR PRIVADO
  private SER_CaseTriggerHandler() {
    userSettings = CIB_User_Org__c.getInstance();
  }

  //SINGLETON PATTERN
  public static SER_CaseTriggerHandler getInstance() {
    if (instance == null) {
      instance = new SER_CaseTriggerHandler();
    }
    return instance;
  }


  /*----------------------------------------------------------------------------------------------------------------------------------
    ON BEFORE INSERT
  ----------------------------------------------------------------------------------------------------------------------------------*/

  public void onBeforeInsert(final List<Case> newList) {
    System.debug('Entering Cases Trigger on Case - EVENT : BEFORE INSERT');
    System.debug('New List: ' + newList);

    //----------------------------------------------- Email-To-Case BEFORE INSERT ------------------------------------------------//
    Boolean isSystem;
    isSystem = SYSTEM_USER.equals(USER_NAME);
    if(isSystem) {
      System.debug('--- E2C BEFORE INSERT ---');
      SER_CaseMethodsEmail.generateSEREmailToCaseCode(newList);
    }

    if(userSettings.CIB_Is_Service__c) {
      //----------------------------------------------------- GM BEFORE INSERT -----------------------------------------------------//
      Boolean isGM;
      isGM = RECORDTYPEMP.get(newList[0].RecordTypeId).contains(GM_BS);
      if(isGM) {
        System.debug('--- GM BEFORE INSERT ---');
        SER_CaseMethods.fillCaseResponsible(newList, null, null, null);
        SER_CaseMethodsCurrency.manageCurrencyRate(newList, null, null, null);
      }

      //----------------------------------------------------- GTB BEFORE INSERT ----------------------------------------------------//
      Boolean isGTB;
      isGTB = RECORDTYPEMP.get(newList[0].RecordTypeId).contains(GTB);
      if(isGTB) {
        System.debug('--- GTB BEFORE INSERT ---');
        SER_CaseMethodsCurrency.manageCurrencyRate(newList, null, null, null);
      }

      //------------------------------------------------- All bussines BEFORE INSERT -----------------------------------------------//
      SER_CaseMethodsValidations.validatePickList(newList, null);
    }
  }


  /*----------------------------------------------------------------------------------------------------------------------------------
    ON BEFORE UPDATE
  ----------------------------------------------------------------------------------------------------------------------------------*/

  public void onBeforeUpdate(List<Case> newList, Map<Id, Case> newMap, Map<Id, Case> oldMap) {
    System.debug('Entering Cases Trigger on Case - EVENT : BEFORE UPDATE');
    System.debug('New Map: ' + newMap);
    System.debug('Old Map: ' + oldMap);

    //------------------------------------------------- Email-To-Case AFTER INSERT -----------------------------------------------//

    if(userSettings.CIB_Is_Service__c) {
      //----------------------------------------------------- GM BEFORE UPDATE -----------------------------------------------------//
      Boolean isGM;
      isGM = RECORDTYPEMP.get(newList[0].RecordTypeId).contains(GM_BS);
      if(isGM) {
        System.debug('--- GM BEFORE UPDATE ---');
        SER_CaseMethods.assignerCaseStatusOnUpdate(newMap, oldMap);
        SER_CaseMethods.fillCaseResponsible(null, null, newMap, oldMap);
        SER_CaseMethodsContact.validateContactEmail(newList, null, newMap, oldMap);
        SER_CaseMethodsCurrency.manageCurrencyRate(null, null, newMap, oldMap);
      }

      //----------------------------------------------------- GTB BEFORE UPDATE ----------------------------------------------------//
      Boolean isGTB;
      isGTB = RECORDTYPEMP.get(newList[0].RecordTypeId).contains(GTB);
      if(isGTB) {
        System.debug('--- GTB BEFORE UPDATE ---');
        SER_CaseMethodsCurrency.manageCurrencyRate(null, null, newMap, oldMap);
        SER_CaseMethodsGTB.assigGTBApprovers(newList);
      }

      //-------------------------------------------------- All bussines BEFORE UPDATE ----------------------------------------------//
      SER_CaseMethodsEmail.assignerMailingGroup(newMap, oldMap);
      SER_CaseMethods_Aux.updateAuxLastModify(newList);
      SER_CaseMethodsValidations.validatePickList(newList, oldMap);
    }
  }


  /*----------------------------------------------------------------------------------------------------------------------------------
    ON AFTER INSERT
  ----------------------------------------------------------------------------------------------------------------------------------*/

  public void onAfterInsert(List<Case> newList, Map<Id, Case> newMap) {
    System.debug('Entering Cases Trigger on Case - EVENT : AFTER INSERT');
    System.debug('New Map: ' + newMap);

    //------------------------------------------------- Email-To-Case AFTER INSERT -----------------------------------------------//
    Boolean isSystem;
    isSystem = SYSTEM_USER.equals(USER_NAME);
    if(isSystem) {
      SER_CaseMethodsEmail.checkerDuplicatedEmail2Case(newMap);
    }

    if(userSettings.CIB_Is_Service__c) {
      //------------------------------------------------------ GM AFTER INSERT -----------------------------------------------------//
      Boolean isGM;
      isGM = RECORDTYPEMP.get(newList[0].RecordTypeId).contains(GM_BS);
      if(isGM) {
        System.debug('--- GM AFTER INSERT ---');
        SER_CaseMethodsParent.copyParentCaseFieldsToChildrenCaseFields(Label.SER_INSERT_DMLOP, newList, null, newMap, null);
      }
    }
  }


  /*----------------------------------------------------------------------------------------------------------------------------------
    ON AFTER UPDATE
  ----------------------------------------------------------------------------------------------------------------------------------*/

  public void onAfterUpdate(List<Case> newList, List<Case> oldList, Map<Id, Case> newMap, Map<Id, Case> oldMap) {
    System.debug('Entering Cases Trigger on Case - EVENT : AFTER UPDATE');
    System.debug('New Map: ' + newMap);
    System.debug('Old Map: ' + oldMap);
    if(userSettings.CIB_Is_Service__c) {
      //------------------------------------------------------ GM AFTER UPDATE -----------------------------------------------------//
      Boolean isGM;
      isGM = RECORDTYPEMP.get(newList[0].RecordTypeId).contains(GM_BS);
      if(isGM) {
        System.debug('--- GM AFTER UPDATE ---');
        SER_CaseMethodsParent.copyParentCaseFieldsToChildrenCaseFields(Label.SER_UPDATE_DMLOP, null, null, newMap, oldMap);
      }
    } else if (!userSettings.CIB_Is_Service__c) {
      //------------------------------------------------------ Account planning AFTER UPDATE -----------------------------------------------------//
      Boolean isAP;
      isAP = RECORDTYPEMP.get(newList[0].RecordTypeId).contains('Account Plan');
      if(isAP) {
        System.debug('--- GDT Account Planning AFTER UPDATE ---');
        final acpl.CasePlanningHandler caseHandler = acpl.CasePlanningHandler.getInstance();
        caseHandler.sendChatterChangeStatus(newList, oldMap);
      }

    }

    SER_CaseMethods.createLineVersionSnapshot(newList, oldMap);
    
  }

  /*---------------------------------------------------------------------------------------
      Company:       BBVA
      Description:   Reset SkipValidation field.

      IN:            List<Case> newList.
      OUT:           Void.
  ---------------------------------------------------------------------------------------*/
  public void resetSkipValidations(List<Case> newList) {
    if(userSettings.CIB_Is_Service__c) {
      for(Case caso : newList) {
        if(caso.SER_Skip_validations__c == true) {
            caso.SER_Skip_validations__c = false;
        }
      }
    }
  }

}