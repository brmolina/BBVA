/***********************************************************************************************************************************
 * @author       Accenture
 * @date			01/03/2016
 * @description  Manejador del trigger para el objeto Contact. No implementar logica aquí, para ello utilizar ActivitiesUtils
 * @Revision    2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
 * @Revision    2018/11/08 Se añade la funcionalida para relacionar los contactos con los clientes superiores en la jerarquía
 * @Revision     2019/01/30 denormContact added new field y chatterPostFeed method
 * @Revision     2019/02/27 Añadida comprobación IF(!Test.isRunningTest()) para que no falle en los test la línea
                que se realiza "ConnectApi.ChatterFeeds"
 * @Revision     2019/03/20 Comprobación añadida para que en un Update no volver a insertar relaciones
                Account-Contact que ya existieran
 ************************************************************************************************************************************/
public with sharing class ContactTriggerHandler {
  /*Declarando variable*/
  private Integer timesExecuted = 0;
  /*Declarando variable*/
  private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
  /*Declarando variable*/
  public static Map<Id,Contact> map_EmptyEmailContacts = new Map<Id,Contact>();
  /*Declarando variable*/
  final private Set<String> setAccIdHierarchy = new Set<String>();   //Set used to avoid duplicate id's

  /**
   *	@author GlobalDesktop
   */
  private static ContactTriggerHandler instance;
  /**
   *	@author GlobalDesktop
   */
  public static ContactTriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new ContactTriggerHandler();
    }
    return instance;
  }

  //CONSTRUCTOR
  private ContactTriggerHandler() {
  }

  /*
  *   Description: onBeforeInsert
  */
  public void onBeforeInsert(final Map<Id,Contact> newMap) {
    System.debug(':::Entering ContactTriggerHandler.onBeforeInsert()');
    if(newMap != null) {
      buildPhoneNumbers(newMap);
      Utilities.checkIsMexico(newMap);
    }
  }
  /*
  *   Description: onBeforeUpdate
  */
  public void onBeforeUpdate(final Map<Id,Contact> newMap, final Map<Id,Contact> oldMap) {
    System.debug(':::Entering ContactTriggerHandler.onBeforeUpdate()');
    if(newMap != null) {
      buildPhoneNumbers(newMap);
      Utilities.checkIsMexico(newMap);
    }

    final List<Contact> listContactNPS = new List<Contact>();
    final List<Contact> listContactNoNPS = new List<Contact>();
    for(Contact iContact : newMap.values()) {
      if(addContactNPS(newMap, oldMap, iContact)) {
        listContactNPS.add(iContact);
      } else if(addContactNoNPS(newMap, oldMap, iContact)) {
        listContactNoNPS.add(iContact);
      }
    }

    if(!listContactNPS.isEmpty()) {
      checkContactNPS(listContactNPS);
    }
    if(!listContactNoNPS.isEmpty()) {
      checkContactNoNPS(listContactNoNPS);
    }
  }
 /*
   *   NPS uncheck validation
   */
  public void uncheckValidationNPS(List<Contact> newMap, List<Contact> oldMap) {

      List<PermissionSetAssignment> objPermUncheckNPS=[SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment where    PermissionSet.Name in :system.Label.lbl_PermsetUncheckNPS.split(',')    and AssigneeId=:UserInfo.getUserId() ];
      List<User> objUserPermUncheckNPS=[Select id from User where profile.name in :system.Label.lbl_ProfileUncheckNPS.split(',') and Id=:UserInfo.getUserId()];
      system.debug('validacion NPS');
      for(Integer i=0;i<newMap.size();i++) {
          Contact conOld =oldMap[i];
          Contact conNew =newMap[i];

          if(System.isBatch()==false&&objUserPermUncheckNPS.size()==0&&objPermUncheckNPS.size()==0&& conOld.survey_nps_contact_type__c != conNew.survey_nps_contact_type__c&&conNew.survey_nps_contact_type__c==false) {
              newMap[i].AddError(system.Label.lbl_MsgUncheckNPS);
          }
      }

  }
  /*
   *   Description: onAfterInsert
   */
  public void onAfterInsert(final Map<Id,Contact> newMap) {
    System.debug('JCT - Entering ContactTriggerHandler.onAfterInsert()');
    System.debug('JCT - NEWMAP : '+ Trigger.newMap);
    ActivitiesUtils.check_EmptyContactEmail(newMap);
    SER_TriggerHelper.setTriggerFired('contacttrigger', true);
    System.debug('Before llamada denormContact...');
    denormContact(newMap);
    System.debug('After llamada denormContact...');
    managePostChatter(newMap, null);
    DES_HandlerTerritory.shareWithTerritoryListTrigger(newMap.values(),null);
  }

  /*
   *   Description: onAfterUpdate
   */
  public void onAfterUpdate(final Map<Id,Contact> newMap, final Map<Id,Contact> oldMap) {
    System.debug('>>>>>>>> Entering ContactTriggerHandler.onAfterUpdate() \r\n NEWMAP: '+ Trigger.newMap + '\r\nNEWMAP: ' + Trigger.oldMap);

    final Map<Id,Contact> contactsToUpdate =  new Map<Id,Contact>();
    for(Id contactId : newMap.keyset()) {
      if(newMap.get(contactId).AccountId != oldMap.get(contactId).AccountId) {
        contactsToUpdate.put(contactId,newMap.get(contactId) );
      }

    }

    if (!contactsToUpdate.isEmpty()) {
      denormContact(contactsToUpdate);
    }
    managePostChatter(newMap, oldMap);
  }

  /* PRIVADOS
   * ----------------------------------------------------------------------------------------------
   */

  /*
   *   Diseñado sólo para inserciones de Contacts de uno en uno,
   *   no cargas masivas, para que se traiga la jerarquía del Account cuando se da de alta un Contacto
   */
  private void denormContact (Map<Id,Contact> newMap) {
    Map<String,AccountContactRelation> acrToInsert;
    acrToInsert = new  Map<String,AccountContactRelation>();
    for (Contact contact: newMap.values()) {
      setAccIdHierarchy.clear();
      recursiveFxn(contact.AccountId, contact.AccountId);

      if (!setAccIdHierarchy.isEmpty()) {
        for( String accId:setAccIdHierarchy) {
          final AccountContactRelation acRelation = new AccountContactRelation(AccountId=accId, ContactId=contact.Id, CurrencyIsoCode=contact.CurrencyIsoCode, record_created_hierarchy_type__c = true);
          acrToInsert.put(accId + '_' + contact.Id,acRelation);
        }
      }
    }

    //Comprobación añadida para que en un Update no volver a insertar relaciones Account-Contact que ya existieran
    if (Trigger.isUpdate) {
      final Set<Id> listCon = new Set<Id>();
      final Set<Id> listAcc = new Set<Id>();
      For (String acrti: acrToInsert.keySet()) {
        listAcc.add(acrti.split('_')[0]);
        listCon.add(acrti.split('_')[1]);
      }
      final List<AccountContactRelation> ACRinserted = [Select AccountId, ContactId From AccountContactRelation where ContactId in :listCon AND AccountId in :listAcc];

      // No hace falta preguntar en un IF, directamente borramos todas (las que existan en el mapa se borran, las que no existan no hace nada)
      for (AccountContactRelation acr : ACRinserted) {
        acrToInsert.remove(acr.AccountId + '_' + acr.ContactId);
      }
    }


    if (!acrToInsert.isEmpty()) {
      System.debug('>>>>>>>>>> Lista de registros a insertar en AccountContactRelation: ' + acrToInsert);
      insert acrToInsert.values();
    }

  }
  //Recursive function to add the AccTeamMembers of the Account hierarchy for a given opportunity
  //starting from Opportunity.AccountId
  private void recursiveFxn(string accId, string accInicial) {
    if (accId != null && accId != accInicial) {
      setAccIdHierarchy.add(accId);
    }

    //Retrieve the parents for the account passed
    final List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT Id, dwp_acmh__Parent_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c = :accId];

    //iterate to recursively add the opportunity to each parent in the hierarchy
    for (dwp_acmh__GBL_Account_Relationship__c accRel : listAccRel) {
      recursiveFxn(accRel.dwp_acmh__Parent_Account__c, accInicial);
    }
  }
  /*
   *   Creating manage chatter notification module checking the user has enabled chatter
   */
  private void managePostChatter (Map<Id,Contact> newMap, Map<Id,Contact> oldMap) {   //NOSONAR static
    Final Id USERID = UserInfo.getUserId();
    final List<User> lstUser = [SELECT Id, DES_Disable_Chatter__c FROM USER WHERE Id = :USERID];

    if(!lstUser.isEmpty() && lstUser[0].DES_Disable_Chatter__c == false) {
      Final Set<Id> setUsers = new Set<Id>();
      List<User> lstUserEnabled = new List<User>();
      System.debug('lstUserEnabled: ' + lstUserEnabled);
      Final Id rtDesktopContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.DES_Desktop_Contact_Active).getRecordTypeId();
      for(Contact con : newMap.values()) {
        if(con.RecordTypeId == rtDesktopContact) {
          setUsers.add(con.OwnerId);
        }
      }
      if(!setUsers.isEmpty()) {
        lstUserEnabled = [SELECT Id FROM USER
                          WHERE DES_Disable_Chatter__c = false
                                                         AND isActive = true
                                                                        AND Id IN :setUsers
                                                                        AND profile.Name like 'BBVA Desktop%'];
      }
      if(!lstUserEnabled.isEmpty()) {
        Final Map<Id,Contact> mapNew = popUsersWithoutChatter(lstUserEnabled, newMap);
        chatterPostFeed(mapNew, oldMap);
      }
    }
  }
  /*
   *   Creating popUsersWithoutChatter
   */
  private static Map<Id,Contact> popUsersWithoutChatter (List<User> lstUserEnabled, Map<Id,Contact> mapVanilla) {
    final Map<Id,Contact> mapContact = new Map<Id,Contact>();

    for(User user : lstUserEnabled) {
      for(Contact con : mapVanilla.values()) {
        if(user.Id == con.OwnerId) {
          mapContact.put(con.Id, con);
        }
      }
    }
    return mapContact;
  }
  /*
   *   Creating chatterPostFeed
   */
  private static void chatterPostFeed (Map<Id,Contact> newMap, Map<Id,Contact> oldMap) {
    System.debug('::::chatterPostFeed init');
    final List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    final Map<Id, Account> mapConAcc = parseMapConAcc(newMap);
    final Id rtDesktopContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.DES_Desktop_Contact_Active).getRecordTypeId();
    System.debug('mapConAcc: ' + mapConAcc);
    if(oldMap == null) {
      System.System.debug('::::insert');
      for(Contact con : newMap.values()) {
        if(con.OwnerId != con.CreatedById && con.RecordTypeId == rtDesktopContact) {
          final ConnectApi.BatchInput batchInput = createBatchInput(mapConAcc.get(con.AccountId), con);
          batchInputs.add(batchInput);
        }
      }
    } else {
      System.System.debug('::::update');
      for(Contact conNew : newMap.values()) {
        for(Contact conOld : oldMap.values()) {
          if(conOld.Id == conNew.Id && conOld.OwnerId != conNew.OwnerId && conNew.RecordTypeId == rtDesktopContact) {
            final ConnectApi.BatchInput batchInput = createBatchInput(mapConAcc.get(conNew.AccountId), conNew);
            batchInputs.add(batchInput);
          }
        }
      }
    }
    System.debug('::::batchInputs:::' + batchInputs);
    if (!Test.isRunningTest()  && !batchInputs.isEmpty()) { ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs); }     //NOSONAR Test
  }

  /*
   *   Creating parseMapConAcc
   */
  private static Map<Id, Account> parseMapConAcc (Map<Id,Contact> newMap) {
    final Set<Id> setContactIds = new Set<Id>();
    for(Contact con : newMap.values()) {
      System.debug('::::con:::' + JSON.serialize(con));
      setContactIds.add(con.AccountId);
    }
    System.debug('::::setContactIds:::' + JSON.serialize(setContactIds));
    final Map<Id, Account> mapConAcc = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN: setContactIds]);
    System.debug('::::mapConAcc:::' + JSON.serialize(mapConAcc));
    return mapConAcc;
  }

  /*
   *   Creating createBatchInput
   */
  private static ConnectApi.BatchInput createBatchInput (Account acc, Contact con) {
    final List<String> lstBody = new List<String>();
    lstBody.add(' You have been assigned as owner of the following contact of ' + acc.Name + ': ');
    lstBody.add(' (' + con.Email_ExternalID__c + '),');
    final ConnectApi.FeedItemInput feedItemInput = postFeedElementWithMention(lstBody, con.OwnerId, con.Id);
    return new ConnectApi.BatchInput(feedItemInput);
  }

  /*
   *   Creating postFeedElementWithMention
   */
  private static ConnectApi.FeedItemInput  postFeedElementWithMention(List<String> lstBody, Id subjectId, Id rowCreatedId) {
    final ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
    final ConnectApi.MentionSegmentInput segmentInput = new ConnectApi.MentionSegmentInput();
    final ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();

    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    segmentInput.id = subjectId;
    messageBodyInput.messageSegments.add(segmentInput);

    final ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
    textSegmentInput1.text = lstBody[0];
    messageBodyInput.messageSegments.add(textSegmentInput1);
    final ConnectApi.EntityLinkSegmentInput segmentInput2 = new ConnectApi.EntityLinkSegmentInput();
    segmentInput2.entityId = rowCreatedId;
    messageBodyInput.messageSegments.add(segmentInput2);
    final ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
    textSegmentInput3.text = lstBody[1];
    messageBodyInput.messageSegments.add(textSegmentInput3);

    feedItemInput.body = messageBodyInput;
    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
    feedItemInput.subjectId = subjectId;

    return feedItemInput;
  }
  /*
  *   @author Global Desktop - APC
  *   @description Concat prefix + phoneNumber
              :MOBILE:::: cell_phone_lada_id__c + MobilePhone IN  cell_phone_number_id__c,
              :PHONE::::: ladaline_phone_id__c +  Phone = phone_id__c
  */
  private static void  buildPhoneNumbers( Map<Id,Contact> newMap) {
    for(Contact con : newMap.values()) {
      fillCellPhone(con);
      fillPhone(con);
    }
  }
   /*
  *   @author Global Desktop - APC
  *   @description helper of buildPhoneNumbers
  */
  private static void  fillCellPhone(Contact con) {
    if(con.cell_phone_lada_id__c == null || con.cell_phone_lada_id__c == '') {
      con.cell_phone_number_id__c = con.MobilePhone;
    } else if(con.MobilePhone == null || con.MobilePhone == '') {
      con.cell_phone_number_id__c = '';
    } else {
      Final List<String> lstPrefix = con.cell_phone_lada_id__c.split('\\|');
      con.cell_phone_number_id__c = '+' + lstPrefix[1].trim() + ' ' + con.MobilePhone;
    }
  }
  /*
    *   @author Global Desktop - APC
    *   @description helper of buildPhoneNumbers
    */
  private static void  fillPhone(Contact con) {
    if(con.ladaline_phone_id__c == null || con.ladaline_phone_id__c == '') {
      con.phone_id__c = con.Phone;
    } else if(con.Phone == null || con.Phone == '') {
      con.phone_id__c = '';
    } else {
      Final List<String> lstPrefix = con.ladaline_phone_id__c.split('\\|');
      con.phone_id__c = '+' + lstPrefix[1].trim() + ' ' + con.Phone;
    }
  }

  /*
   *   @author Global Desktop
   *   @method addContactNPS
   */
  private static Boolean addContactNPS(final Map<Id,Contact> newMap, final Map<Id,Contact> oldMap, Contact iContact) {
    return (newMap.get(iContact.Id).survey_nps_contact_type__c != oldMap.get(iContact.Id).survey_nps_contact_type__c
              || newMap.get(iContact.Id).last_send_nps_user_id__c != oldMap.get(iContact.Id).last_send_nps_user_id__c)
            && newMap.get(iContact.Id).survey_nps_contact_type__c == true
            && (newMap.get(iContact.Id).RecordTypeId == Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Label.RT_Desktop_Contact).getRecordTypeId()
              || newMap.get(iContact.Id).RecordTypeId == Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Label.RT_Desktop_Inactive_Contact).getRecordTypeId());
  }

  /*
   *   @author Global Desktop
   *   @method addContactNoNPS
   */
  private static Boolean addContactNoNPS(final Map<Id,Contact> newMap, final Map<Id,Contact> oldMap, Contact iContact) {
    return newMap.get(iContact.Id).survey_nps_contact_type__c != oldMap.get(iContact.Id).survey_nps_contact_type__c
            && newMap.get(iContact.Id).survey_nps_contact_type__c == false
            && (newMap.get(iContact.Id).RecordTypeId == Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Label.RT_Desktop_Contact).getRecordTypeId()
              || newMap.get(iContact.Id).RecordTypeId == Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Label.RT_Desktop_Inactive_Contact).getRecordTypeId());
  }

  /*
   *   @author Global Desktop
   *   @method checkContactNPS
   */
  private static void checkContactNPS(List<Contact> listContactNPS) {
    final Map<Id, Contact> mapContact = new Map<Id, Contact>([SELECT Id,
                                                          Name,
                                                          Account.survey_nps_contact_type__c,
                                                          Account.DES_Country_Client__c
                                                        FROM Contact
                                                        WHERE Id IN :listContactNPS
                                                          AND (RecordTypeId = :Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Label.RT_Desktop_Contact).getRecordTypeId()
                                                            OR RecordTypeId = :Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Label.RT_Desktop_Inactive_Contact).getRecordTypeId())]);

    if(!mapContact.isEmpty()) {
      checkContactNPSError(listContactNPS, mapContact);
    }
  }

  /*
   *   @author Global Desktop
   *   @method checkContactNPSError
   */
  private static void checkContactNPSError(List<Contact> listContactNPS, Map<Id, Contact> mapContact) {
    final List<NPS_Wave__c> listWave = [SELECT Id, //NOSONAR
                                          gf_nps_sv_cust_oper_cntry_desc__c,
                                          nps_start_date__c,
                                          nps_end_date__c
                                        FROM NPS_Wave__c
                                        WHERE nps_start_date__c = THIS_YEAR
                                          AND gf_nps_sv_cust_oper_cntry_desc__c != null
                                        ORDER BY CreatedDate DESC];

    for(Contact iContact : listContactNPS) {
      if(iContact.last_send_nps_user_id__c == null) {
        iContact.last_send_nps_user_id__c = iContact.OwnerId;
      }

      if(mapContact.get(iContact.Id).Account.survey_nps_contact_type__c == true) {
        Boolean waveExists = false;
        waveExists = checkActiveWaveError(listWave, mapContact, iContact);
        if(waveExists == false) {
          iContact.addError(Label.DES_ERR_ACTIVE_WAVE_COUNTRY);
        }
      }

      iContact.nps_unavailable_date__c = null; //NOSONAR
      iContact.nps_discard_reason_type__c = null; //NOSONAR
      iContact.gf_nps_contact_mark_date__c = Date.today();
    }
  }

  /**
   *   @author Global Desktop
   *   @method checkActiveWaveError
   */
  private static Boolean checkActiveWaveError(List<NPS_Wave__c> listWave, Map<Id, Contact> mapContact, Contact iContact) {
    final List<NPS_Wave__c> listWaveCountry = new List<NPS_Wave__c>(); //NOSONAR
    Boolean waveExists = false;
    for(NPS_Wave__c iNPSWave : listWave) {
      if(iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c.containsIgnoreCase(mapContact.get(iContact.Id).Account.DES_Country_Client__c) == true) {
        waveExists = true;
        listWaveCountry.add(iNPSWave);
      }
    }

    Boolean waveExistsDate = false;
    if(waveExists == true) {
      for(NPS_Wave__c iNPSWave : listWaveCountry) {
        if(Date.today() >= iNPSWave.nps_start_date__c
          || Date.today() <= iNPSWave.nps_end_date__c) {
          waveExistsDate = true;
        }
      }
    }

    if(waveExistsDate == false) {
      iContact.addError(Label.DES_ERR_ACTIVE_WAVE);
    }

    return waveExists;
  }

  /**
   *   @author Global Desktop
   *   @method checkContactNoNPS
   */
  private static void checkContactNoNPS(List<Contact> listContactNoNPS) {
    checkLastNPS(listContactNoNPS);

    for(Contact iContact : listContactNoNPS) {
      if(iContact.last_send_nps_user_id__c == null) {
        iContact.last_send_nps_user_id__c = iContact.OwnerId;
      }
      if(iContact.nps_unavailable_date__c == null) {
        iContact.nps_unavailable_date__c = Datetime.now();
      }
    }
  }

  /**
   *   @author Global Desktop
   *   @method checkContactNoNPS
   */
  private static void checkLastNPS(List<Contact> listContactNoNPS) {
    final Set<Id> setAccId = new Set<Id>();
    for(Contact iContact : listContactNoNPS) {
      if(iContact.DES_Client_NPS__c == true) {
        setAccId.add(iContact.AccountId);
      }
    }

    final Map<Id, Account> mapAccount = new Map<Id, Account>();
    for(Account iAccount : [SELECT Id,
                              Name,
                              (SELECT Id
                              FROM Contacts
                              WHERE survey_nps_contact_type__c = true)
                            FROM Account
                            WHERE Id IN :setAccId]) {
      if(iAccount.Contacts.size() <= 1) {
        mapAccount.put(iAccount.Id, iAccount);
      }
    }
    final List<AsyncApexJob> listAsyncJob = [SELECT Id,
                                              Status,
                                              ApexClass.Name
                                            FROM AsyncApexJob
                                            WHERE ApexClass.Name = 'Batch_Update_NPS'
                                              AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
                                            LIMIT 1];
    for(Contact iContact : listContactNoNPS) {
      if(mapAccount.containsKey(iContact.AccountId) && listAsyncJob.isEmpty()) {
        iContact.addError('Unfortunately this contact is the last contact for ' + mapAccount.get(iContact.AccountId).Name + ', which is under the NPS perimeter, therefore you must select another contact for NPS before unmark this one. Thank you very much.');
      }
    }
  }

}