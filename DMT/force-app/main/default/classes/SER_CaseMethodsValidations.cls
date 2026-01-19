/*-----------------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Class to handle methods called when the triggers over Case object are fired

*  Author:    Javier Touchard
*  Description:  Class to handle methods called when the triggers over Case object are fired
*
*  History:
*  <Date>        <Author>            <Description>
*  01/02/2020    Javier Touchard            GTB
-------------------------------------------------------------------------------------------------*/
public without sharing class SER_CaseMethodsValidations {
  /*Constante 'SER_Classification__c'*/
  public static final String CLASSIFICATION = 'SER_Classification__c';
  /*Constante 'Origin'*/
  public static final String ORIGIN = 'Origin';
  /*Constante 'status'*/
  public static final String STATUS = 'status';
  

  private SER_CaseMethodsValidations() {
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate case picklist values.

      IN:            List<Case> newList.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validatePickList(List<Case> newList, Map<Id, Case> oldMap) {
    System.debug('---->>>>  Entramos a validatePickList');
    for(Case caso : newList) {
      System.debug('Skip validations: ' + caso.SER_Skip_validations__c);
      Boolean validate;
      validate = caso.SER_Skip_validations__c == false;
      if(validate) {
        //GM
        Boolean isGM;
        isGM = caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_Closed_Case_GM_User') ||
              caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_GM_User');

        Boolean isGMInsert;
        isGMInsert = isGM && oldMap == null;
        if(isGMInsert) {
          validateGMCaseInsert(caso);
        }

        Boolean isGMUpdate;
        isGMUpdate = isGM && oldMap != null;
        if(isGMUpdate) {
          validateGMCaseUpdate(caso, oldMap);
        }

        //STE
        Boolean isSTE;
        isSTE = caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_Closed_Case_STE_User') ||
                caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_STE_User') ||
                caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_Transferred_STE_User');

        Boolean isSTEInsert;
        isSTEInsert = isSTE && oldMap == null;
        if(isSTEInsert) {
          validateSTECaseInsert(caso);
        }

        Boolean isSTEUpdate;
        isSTEUpdate = isSTE && oldMap != null;
        if(isSTEUpdate) {
          validateSTECaseUpdate(caso, oldMap);
          validateSTEParentCase(caso, oldMap);
        }

        //GNC
        Boolean isGNC;
        isGNC = caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_Closed_Case_GNC_User') ||
                caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_GNC_User');

        Boolean isGNCInsert;
        isGNCInsert = isGNC && oldMap == null;
        if(isGNCInsert) {
          validateGNCCaseInsert(caso);
        }

        Boolean isGNCUpdate;
        isGNCUpdate = isGNC && oldMap != null;
        if(isGNCUpdate) {
          validateGNCCaseUpdate(caso, oldMap);
        }

        validatePickList2(caso, oldMap);
      }
      caso.SER_Skip_validations__c = false;
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate case picklist values. GTB.

      IN:            Case caso.
      IN:            Map<Id, Case> oldMap.
      OUT:           Boolean.
  ------------------------------------------------------------------------*/
  public static Boolean validatePickList2(Case caso, Map<Id, Case> oldMap) {
    //GTB
    Boolean isGTB;
    isGTB = caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_Closed_Case_GTB_User') ||
            caso.RecordTypeId == SER_RecordTypeUtils.getRecordTypeByName(SER_Constant.CASECTN, 'SER_GTB_User');

    Boolean isGTBInsert;
    isGTBInsert = isGTB && oldMap == null;
    //Status
    if(isGTBInsert && caso.status == SER_Constant.REOPEN) {
      caso.addError(STATUS, Label.SER_Error_ReopenCheckbox);
    }

    Boolean isGTBUpdate;
    isGTBUpdate = isGTB && oldMap != null;
    if(isGTBUpdate) {
      validateGTBCaseUpdate(caso, oldMap);
    }

    return true;
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate GM Cases on Insert.

      IN:            Case caso.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateGMCaseInsert(Case caso) {
    System.debug('---->>>>  Entramos a validateGMCaseUpdate');
    //Valido campos
    //Status
    if(caso.status == SER_Constant.TRANSFERRED) {
      caso.addError(STATUS, Label.SER_Error_Transfered);
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate GM Cases on Update.

      IN:            Case caso.
      IN:            Map<Id, Case> oldMap.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateGMCaseUpdate(Case caso, Map<Id, Case> oldMap) {
    System.debug('---->>>>  Entramos a validateGMCaseUpdate');
    //Valido campos
    //Status
    if(caso.status != oldMap.get(caso.Id).status && caso.status == SER_Constant.TRANSFERRED) {
      caso.addError(STATUS, Label.SER_Error_Transfered);
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate STE Cases on Insert.

      IN:            Case caso.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateSTECaseInsert(Case caso) {
    System.debug('---->>>>  Entramos a validateSTECaseInsert');
    //Valido campos
    //Status
    Boolean remedyStatus;
    remedyStatus = caso.status == SER_Constant.REMEDYSCALATED
                    || caso.status == SER_Constant.PENDINGINF
                    || caso.status == SER_Constant.PENDINGTOCLOSE
                    || caso.status == SER_Constant.REJECTED;
    if (remedyStatus) {
      caso.addError(STATUS, Label.SER_Error_RemedyStatus);
    } else if(caso.status == SER_Constant.REOPEN) {
      caso.addError(STATUS, Label.SER_Error_ReopenCheckbox);
    } else if(caso.status == SER_Constant.TRANSFERRED) {
      caso.addError(STATUS, Label.SER_Error_Transfered);
    } else if(caso.status == SER_Constant.LINKMASTER) {
      caso.addError(STATUS, Label.SER_Error_LinkedToMasterCase);
    }
    //Origin
    Boolean originBl;
    originBl = caso.Origin == 'Email BBVA Customer Service' ||
              caso.Origin == 'Email PATRIMONIOS' ||
              caso.Origin == 'Email Oneview' ||
              caso.Origin == 'Email Social Network' ||
              caso.Origin == 'Email STE-PLUS' ||
              caso.Origin == 'Email Validations' ||
              caso.Origin == 'Email OPINATOR';
    Boolean webOrigin;
    webOrigin = caso.Origin == 'WEB_FORM' ||
                caso.Origin == 'MAX_MISTRAL' ||
                caso.Origin == 'BOSS';
    if(originBl) {
      caso.addError(ORIGIN, ' "' + caso.Origin + '" ' + Label.SER_Error_Origin_IncomingEmail);
    } else if(webOrigin) {
      caso.addError(ORIGIN, ' "' + caso.Origin + '" ' + Label.SER_Error_Origin);
    }
    //Product
    Boolean product;
    product = caso.SER_Product__c == 'NET CASH' ||
              caso.SER_Product__c == 'DISKETTE 3 1/2' ||
              caso.SER_Product__c == 'EDIFACT';
    if(product) {
      caso.addError('SER_Product__c', ' "' + caso.SER_Product__c + '" ' + Label.SER_Error_Product);
    }
    //Remedy Department
    Boolean department;
    department = caso.SER_Remedy_Department__c == SER_Constant.EQRESOLUTOR;
    if(department) {
      caso.addError('SER_Remedy_Department__c', ' "' + caso.SER_Remedy_Department__c + '" ' + Label.SER_Error_RemedyDepartment);
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate STE Cases on Update.

      IN:            Case caso.
      IN:            Map<Id, Case> oldMap.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateSTECaseUpdate(Case caso, Map<Id, Case> oldMap) {
    System.debug('---->>>>  Entramos a validateSTECaseUpdate');
    //Valido campos
    //Status
    Boolean reopen;
    reopen = caso.status != oldMap.get(caso.Id).status && caso.status == SER_Constant.REOPEN;
    Boolean remedy;
    remedy = caso.status != oldMap.get(caso.Id).status &&
              (caso.status == SER_Constant.REMEDYSCALATED
              || caso.status == SER_Constant.PENDINGINF
              || caso.status == SER_Constant.PENDINGTOCLOSE
              || caso.status == SER_Constant.REJECTED);
    Boolean transfered;
    transfered = caso.status != oldMap.get(caso.Id).status && caso.status == SER_Constant.TRANSFERRED;
    Boolean linked;
    linked = caso.status != oldMap.get(caso.Id).status && caso.status == SER_Constant.LINKMASTER;
    if(reopen) {
      caso.addError(STATUS, Label.SER_Error_ReopenCheckbox);
    } else if (remedy) {
      caso.addError(STATUS, Label.SER_Error_RemedyStatus);
    } else if(transfered) {
      caso.addError(STATUS, Label.SER_Error_Transfered);
    } else if(linked) {
      caso.addError(STATUS, Label.SER_Error_LinkedToMasterCase);
    }

    //Origin
    Boolean incoming;
    incoming = caso.Origin != oldMap.get(caso.Id).Origin &&
                (caso.Origin == 'Email BBVA Customer Service' ||
                caso.Origin == 'Email PATRIMONIOS' ||
                caso.Origin == 'Email Oneview' ||
                caso.Origin == 'Email Social Network' ||
                caso.Origin == 'Email STE-PLUS' ||
                caso.Origin == 'Email Validations' ||
                caso.Origin == 'Email OPINATOR');
    Boolean web;
    web = caso.Origin != oldMap.get(caso.Id).Origin &&
            (caso.Origin == 'WEB_FORM' ||
            caso.Origin == 'MAX_MISTRAL' ||
            caso.Origin == 'BOSS');
    if(incoming) {
      caso.addError(ORIGIN, ' "' + caso.Origin + '" ' + Label.SER_Error_Origin_IncomingEmail);
    } else if(web) {
      caso.addError(ORIGIN, ' "' + caso.Origin + '" ' + Label.SER_Error_Origin);
    }

    //Product
    Boolean product;
    product = caso.SER_Product__c != oldMap.get(caso.Id).SER_Product__c &&
                (caso.SER_Product__c == 'NET CASH' ||
                caso.SER_Product__c == 'DISKETTE 3 1/2' ||
                caso.SER_Product__c == 'EDIFACT');
    if(product) {
      caso.addError('SER_Product__c', ' "' + caso.SER_Product__c + '" ' + Label.SER_Error_Product);
    }

    //Remedy Department
    Boolean department;
    department = caso.SER_Remedy_Department__c != oldMap.get(caso.Id).SER_Remedy_Department__c &&
                  caso.SER_Remedy_Department__c == SER_Constant.EQRESOLUTOR;
    if(department) {
      caso.addError('SER_Remedy_Department__c', ' "' + caso.SER_Remedy_Department__c + '" ' + Label.SER_Error_RemedyDepartment);
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate STE Parent Case on Update.

      IN:            Case caso.
      IN:            Map<Id, Case> oldMap.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateSTEParentCase(Case caso, Map<Id, Case> oldMap) {
    System.debug('---->>>>  Entramos a validateSTEParentCase');
    //Parent Case
    Boolean parentCase;
    parentCase = caso.ParentId != oldMap.get(caso.Id).ParentId &&
                  caso.ParentId != null;

    if(parentCase) {
      Case casoParent;
      casoParent = new Case();
      casoParent = [SELECT SER_Is_Master_Case__c FROM Case WHERE Id = :caso.ParentId];

      Boolean parentMaster;
      parentMaster = casoParent.SER_Is_Master_Case__c != TRUE  || 
                  caso.SER_RemedyId__c == null;
      
      if(parentMaster) {            
        caso.addError('ParentId', system.label.SER_STE_parentCase_validation);
      }
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate GNC Cases on Insert.

      IN:            Case caso.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateGNCCaseInsert(Case caso) {
    System.debug('---->>>>  Entramos a validateGNCCaseInsert');
    //Valido campos
    //Status
    if(caso.status == SER_Constant.REOPEN) {
      caso.addError(STATUS, Label.SER_Error_ReopenCheckbox);
    } else if (caso.status == SER_Constant.REMEDYSCALATED
                || caso.status == SER_Constant.PENDINGINF
                || caso.status == SER_Constant.PENDINGTOCLOSE
                || caso.status == SER_Constant.REJECTED) {
      caso.addError(STATUS, Label.SER_Error_RemedyStatus);
    }

    //Classification
    if(caso.SER_Classification__c == SER_Constant.DESCARTADO) {
      caso.addError(CLASSIFICATION, Label.SER_Error_DiscardWithCheckbox);
    }

    //Origin
    if(caso.Origin == SER_Constant.EMAIL_GNC) {
      caso.addError(ORIGIN, Label.SER_Error_GNC_Email);
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate GNC Cases on Update.

      IN:            Case caso.
      IN:            Map<Id, Case> oldMap.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateGNCCaseUpdate(Case caso, Map<Id, Case> oldMap) {
    System.debug('---->>>>  Entramos a validateGNCCaseUpdate');
    //Valido campos
    //Status
    Boolean remedy;
    remedy = caso.status != oldMap.get(caso.Id).status &&
              (caso.status == SER_Constant.REMEDYSCALATED
              || caso.status == SER_Constant.PENDINGINF
              || caso.status == SER_Constant.PENDINGTOCLOSE
              || caso.status == SER_Constant.REJECTED);
    if (remedy) {
      caso.addError(STATUS, Label.SER_Error_RemedyStatus);
    } else if(caso.status != oldMap.get(caso.Id).status && caso.status == SER_Constant.REOPEN) {
      caso.addError(STATUS, Label.SER_Error_ReopenCheckbox);
    }

    //Classification
    if(caso.SER_Classification__c != oldMap.get(caso.Id).SER_Classification__c
        && caso.SER_Classification__c == SER_Constant.DESCARTADO) {
      caso.addError(CLASSIFICATION, Label.SER_Error_DiscardWithCheckbox);
    }

    //Origin
    if(caso.Origin != oldMap.get(caso.Id).Origin && caso.Origin == SER_Constant.EMAIL_GNC) {
      caso.addError(ORIGIN, Label.SER_Error_GNC_Email);
    }
  }

  /*----------------------------------------------------------------------
      Company:       BBVA
      Description:   Method to validate GTB Cases on Update.

      IN:            Case caso.
      IN:            Map<Id, Case> oldMap.
      OUT:           void
  ------------------------------------------------------------------------*/
  public static void validateGTBCaseUpdate(Case caso, Map<Id, Case> oldMap) {
    System.debug('---->>>>  Entramos a validateGTBCaseUpdate');
    //Valido campos
    //Status
    if(caso.status != oldMap.get(caso.Id).status && caso.status == SER_Constant.REOPEN) {
      caso.addError(STATUS, Label.SER_Error_ReopenCheckbox);
    }
  }
}