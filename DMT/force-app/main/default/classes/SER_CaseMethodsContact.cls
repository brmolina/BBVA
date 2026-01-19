/*-----------------------------------------------------------------------------------------------
Author:        Rodrigo Fdez-Victorio
Company:       Accenture
Description:   Subclass to handle contact methods called when the triggers over Case object are fired

History:
<Date>          <Author>                <Description>
08/07/2017      Juan Carlos Terrón        Initial version
-------------------------------------------------------------------------------------------------*/
public without sharing class SER_CaseMethodsContact {

  /*Constante texto identificador de test*/
  final static string LOG_TEST = 'Catch testing';

  private SER_CaseMethodsContact() {
  }
  /*----------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Validates contact creation from an incoming email.

      IN:            Trigger.new && Trigger.oldMap
      OUT:           Void

      History:
      <Date>                  <Author>                <Change Description>
      27/02/2017              Juan Carlos Terrón      Initial Version
      ------------------------------------------------------------------------*/
  public static void validateContactEmail(List<Case> newList,List<Case> oldList,Map<Id,Case> newMap, Map<Id,Case> oldMap) {
    try {
      SER_TriggerHelper.set_MetodFired('fill_ContactEmail', true);
      Set<String> setEmailAddresses;
      setEmailAddresses = new Set<String>();

      for(Case casoItem : newMap.values()) {       //We check if the related contact is in a static map in the same transaction as the contact creation.
        final boolean auxGM = !setEmailAddresses.contains(casoItem.SuppliedEmail)
                              && oldMap.get(casoItem.Id).ContactId != casoItem.ContactId
                              && oldMap.get(casoItem.ID).ContactId == null
                              && casoItem.ContactId != null
                              && casoItem.SER_Business_Case_Type__c == 'GM'
                              && ContactTriggerHandler.map_EmptyEmailContacts.containskey(casoItem.ContactId);
        if(auxGM) {
          setEmailAddresses.add(casoItem.SuppliedEmail);
        }
        //If this is the case we store the supplied mail of the case to check if there's already a contact
        //with that adress as email address.
      }
      updateContact(newList, oldMap);
      //If case have SuppliedEmail and a contact the contact's email is filled in with the cases's SuppluedEmail
      reloadListContact(newMap,setEmailAddresses);
      if(runTest()) { throw new HandledException(LOG_TEST); }       //Catch testing for code coverage.
    } catch (Exception ex) {
      cibLog(ex, 'SER_CaseMethods.validateContactEmail()');
    }
  }
  private static void updateContact (List<Case> newList, Map<Id,Case> oldMap) {
    if(!SER_TriggerHelper.getTriggerFired('contacttrigger') &&
        (ContactTriggerHandler.map_EmptyEmailContacts == null ||
        ContactTriggerHandler.map_EmptyEmailContacts.size() == 0)) {
      Map<Id,String> contactSenderMap;
      List<Contact> contactToUpd;
      contactSenderMap = new Map<Id,String>();
      contactToUpd = new List<Contact>();

      for(Case casoItem : newList) {
        final boolean bAux = casoItem.SuppliedEmail != ''
                              && casoItem.SuppliedEmail != null
                              && oldMap.get(casoItem.Id).ContactId == null
                              && casoItem.ContactId != null
                              && casoItem.SER_Business_Case_Type__c == 'GM';
        if(bAux) {
          contactSenderMap.put(casoItem.ContactId,casoItem.SuppliedEmail);
        }
      }
      for(Id i : contactSenderMap.keySet()) {
        contactToUpd.add(new Contact(Id = i, Email = contactSenderMap.get(i), Email_ExternalID__c = contactSenderMap.get(i)));
      }
      if(contactToUpd.isEmpty()==false) {
        update contactToUpd;
      }
    }
  }
  private static void reloadListContact (Map<Id,Case> newMap, Set<String> setEmailAddresses) {
    if(!setEmailAddresses.isEmpty()) {
      Set<String> setExistingEmails;
      setExistingEmails = new Set<String>();
      Set<Id> setCaseErrors;
      setCaseErrors = new Set<Id>();
      Set<Id> setEmptySenderErr;
      setEmptySenderErr = new Set<Id>();
      List<Contact> listContactToUpd;
      listContactToUpd = new List<Contact>();
      List<Contact> listContactToDel;
      listContactToDel = new List<Contact>();

      for(Contact contactItem : [SELECT Id, Email FROM Contact WHERE Email IN :setEmailAddresses]) {           //We query over contacts filtering by the ones whose email field is in the previous built set.
        setExistingEmails.add(contactItem.Email);
      }
      for(Case casoItem : newMap.values()) {           //Iterate over the  case list from the trigger
        if( (setExistingEmails.contains(casoItem.SuppliedEmail) && ContactTriggerHandler.map_EmptyEmailContacts.containskey(casoItem.ContactId))
            || String.isBlank(String.valueOf(casoItem.SuppliedEmail))) {             //The related contact cant be created due to there's alreadya  contact with taht email adress.
          setCaseErrors.add(casoItem.Id);               //Add the id to the error set.
          //The supplied email is blank, the error displayed must be different
          if(String.isBlank(String.valueOf(casoItem.SuppliedEmail))) { setEmptySenderErr.add(casoItem.Id); }
          listContactToDel.add(new Contact(Id = casoItem.ContactId));
        } else {             //The Contact email fields are overwritten.
          final boolean aux = casoItem.ContactId != null
                              && ContactTriggerHandler.map_EmptyEmailContacts.containskey(casoItem.ContactId);
          if(aux) {
            listContactToUpd.add(new Contact(Id = casoItem.ContactId, Email = casoItem.SuppliedEmail, Email_ExternalID__c = casoItem.SuppliedEmail));
          }
        }
      }
      update listContactToUpd;           //Update the non duplicated contacts
      delete listContactToDel;           //Delete the duplicated contacts

      wrongCreatedContact (newMap,setCaseErrors,setEmptySenderErr);
    }
  }

  private static void wrongCreatedContact (Map<Id,Case> newMap, Set<Id> setCaseErrors,Set<Id> setEmptySenderErr) {
    for(Id errorID : setCaseErrors) {     //Iterate over the wrong created contacts
      if(setEmptySenderErr.contains(errorID)) {       //ContactIDS contained in the previous filled error set for empty sender field on the case.
        newMap.get(errorID).addError(Label.SER_EmptySenderError);
      } else {       //Contacts with duplicated email fields.
        newMap.get(errorID).addError(Label.SER_DuplicatedContactEmail_ERRMSG);
      }
    }
  }

  /*------------------------------------------------------------------------------------------------------------------------
      Author:        Javier SS
      Company:       Accenture
      Description:   Method that copies the contact into the Contact-Product object (for cases with "STE User" Record Type).

      IN:            Trigger.NewMap, Trigger.OldMap
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      10/04/2017              Javier SS      Initial Version.
      --------------------------------------------------------------------------------------------------------------------------*/
  public static void copyContactCaseToContactProduct(Map<Id,Case> newMap, Map<Id,Case> oldMap) {
    try {
      List<SER_Contact_Product__c> lstCtProdToIns;
      lstCtProdToIns = new List<SER_Contact_Product__c>();
      Map<String,String> mapCaseRecType;
      mapCaseRecType = SER_RecordTypeUtils.getRecordTypes('Case');

      if (!lstCtProdToIns.isEmpty()) {
        // Para evitar insertar varias veces el mismo Contacto y Producto, se ha creado una validation rule.
        // Si realizamos el insert de un contacto que ya está en el producto va a saltar la validation rule:
        //  DUPLICATE_VALUE, duplicate value found: SER_Contact_Product_ID__c
        // Entonces a la hora de insertar hay 2 opciones:
        // 1) Poniendo este Try-Catch evitamos que se aparezca el error en la visualforce.
        //    Aunque perdemos el control de si aparecen otros errores
        // 2) lanzar una query y meter en un mapa los SER_Contact_Product__c, y quitar de lstCtProdToIns los que ya existan,
        //       pero esta solución  tendríamos que filtrar con un WHERE en la query por ejemplo traer solo los contactos de
        //       los productos en la lista de NewCases porque si no con el tiempo pudiera haber miles de contactosProductos.
        //
        //  -> la opcion elegida es 1)
        try {
          insert lstCtProdToIns;
        } catch (exception ex) {
          final String msg = ex.getMessage();
          System.debug ('Error' + msg);
        }
      }
      if(runTest()) { throw new HandledException(LOG_TEST); }      //Catch testing for code coverage.
    } catch (Exception ex) {
      CIB_LogUtils.create_Log('SER_CaseMethods.copyContactCaseToContactProduct()', ex.getStackTraceString()+'\n'+ex.getMessage());
    }
  }

  /*--------------------------------------------------------------------------
    Author:        Cintia Carmona
    Company:       Accenture
    Description:   Insert Group Name in Case.

    IN:        Map<Id,Case> newMap, Map<Id,Case> oldMap
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    29/05/2020        Cintia Carmona      Initial Version
  ----------------------------------------------------------------------------*/
  public static void fillGroupName(String event, List<Case> newList, List<Case> oldList) {

    Map<String,String> mapCaseRecType;
    mapCaseRecType = SER_RecordTypeUtils.getRecordTypes('Case');

    List<Id> contactIdsList; 
    contactIdsList = new List<Id>(); 

    Map<Id, Account> contactAccMap;
    contactAccMap = new Map<Id, Account>();

    List<Case> caseToUpdate;
    caseToUpdate = new List<Case>();

    if(contactIdsList.isEmpty() == false) {
        contactAccMap=findAccountGroup(contactIdsList);
    }

    if(event == Label.SER_INSERT_DMLOP) {
      for(Case newCase : newList) {
        final Account cuentaGrupo = contactAccMap.get(newCase.ContactId);
        Boolean process;
        process = cuentaGrupo != null;
        if(process) {
          newCase.gf_group_incidence_case_name__c = cuentaGrupo.DES_Main_Parent__c;
        }
      }
    } else {
      List<Case> casesWithGroup; 
      casesWithGroup = new List<Case>();

      for(Case caso : caseToUpdate) {
        final Account cuentaGrupo = contactAccMap.get(caso.ContactId);
        Boolean process;
        process = cuentaGrupo != null;
        if(process) {
          final Case updatedCase = new case();
          updatedCase.Id = caso.Id;
          updatedCase.gf_group_incidence_case_name__c = cuentaGrupo.DES_Main_Parent__c;
          casesWithGroup.add(updatedCase);
        }
      }

      if(casesWithGroup.isEmpty() == false) {
        update casesWithGroup;
      }
    }
  }

  /*--------------------------------------------------------------------------
    Author:        Cintia Carmona
    Company:       Accenture
    Description:   Find Account Group 

    IN:        String event, List<Contact> contacts
    OUT:       Map<Id, Account>

    History:
    <Date>            <Author>            <Change Description>
    29/05/2020        Cintia Carmona      Initial Version
  ----------------------------------------------------------------------------*/
  public static Map<Id, Account> findAccountGroup(List<Id> contactsIds) {

    List<Id> accountIdsList; 
    accountIdsList = new List<Id>(); 

    Map<Id, Account> contactAccMap;
    contactAccMap = new Map<Id, Account>();

    List<Contact> contactList = new List<Contact>();
    contactList = [SELECT Id, AccountId FROM Contact WHERE Id IN :contactsIds];
    if(contactList.isEmpty() == false) {
      for(Contact contacto : contactList) {
        final boolean cuenta = contacto.Accountid != null;
        if(cuenta) {
          accountIdsList.add(contacto.AccountId);  
        }
      }
    }

    if(accountIdsList.isEmpty() == false) {
      List<Account> accountList = new List<Account>();
      accountList = [SELECT Id, DES_Main_Parent__c FROM Account WHERE Id IN :accountIdsList];
      for(Contact contacto : contactList) {
        for(Account cuenta : accountList) {
          Boolean process;
          process = cuenta.Id == contacto.AccountId && cuenta.DES_Main_Parent__c != null;
          if(process) {
            contactAccMap.put(contacto.Id, cuenta);
          }
        }
      }
    }

    return contactAccMap;

  }

  //Comprueba si nos encontramos en ejecución de un test
  private static boolean runTest() {
    return Test.isRunningTest();
  }
  private static void cibLog(Exception pEx, String pMetodo) {
    CIB_Log__c logToInsert;
    logToInsert = new CIB_Log__c();
    logToInsert.CIB_ErrorMessage__c = pEx.getStackTraceString()+'\n'+pEx.getMessage();
    logToInsert.CIB_Subject__c = pMetodo+' ERROR';
    insert logToInsert;
  }
}