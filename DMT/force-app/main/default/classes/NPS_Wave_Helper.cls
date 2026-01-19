/**
 * @author       Global Desktop
 * @date         10/10/2019
 * @description  Implementación de la lógica del handler de NPS_Wave__c
 */
public with sharing class NPS_Wave_Helper {
  /**
   * @author Global Desktop
   * @description Email 'DES_Owner_NPS_Contacts_Notification'
   */
  private static List<EmailTemplate> iEmailToOwner {
    get {
      if(iEmailToOwner == null) {
        iEmailToOwner = [SELECT Id,
                          DeveloperName,
                          Subject,
                          HtmlValue,
                          Markup
                        FROM EmailTemplate
                        WHERE DeveloperName = 'DES_Owner_NPS_Contacts_Notification'];
      }
      return iEmailToOwner;
    } set;
  }

  /**
   * @author Global Desktop
   * @description Email 'DES_Global_Banker_NPS_Notification'
   */
  private static List<EmailTemplate> iEmailToGB {
    get {
      if(iEmailToGB == null) {
        iEmailToGB = [SELECT Id,
                        DeveloperName,
                        Subject,
                        HtmlValue,
                        Markup
                      FROM EmailTemplate
                      WHERE DeveloperName = 'DES_Global_Banker_NPS_Notification'];
      }
      return iEmailToGB;
    } set;
  }

  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static NPS_Wave_Helper instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static NPS_Wave_Helper getInstance() { //NOSONAR
    if (instance == null) {
      instance = new NPS_Wave_Helper();
    }
    return instance;
  }

  private NPS_Wave_Helper() {
  }

  /**
   * @author Global Desktop
   * @method npsNotification
   */
  public static void npsNotification(List<NPS_Wave__c> listNPSWave, List<Account> listAccountNPS,Map<String,String> listContactsNPSMail,Map<String,String> listGlobalBankerEmail) {
    final Map<Id, Account> mapAccounts = new Map<Id, Account>();
    final Map<Id, Account> mapAccountsGroup = new Map<Id, Account>();
    System.debug('::::::::::npsNotification');
    for(Account iAccount : [SELECT Id,
                              DES_Country_Client__c,
                              DES_Global_banker__c,
                              RecordType.DeveloperName,
                              (SELECT Id,
                                  OwnerId,
                                  AccountId,
                                  Owner.Email
                              FROM Contacts),
                              (SELECT Id,
                                  DES_User__c,
                                  DES_Member_Role__c
                              FROM BBVA_Client_teams__r
                              WHERE (DES_Member_Role__c =: Label.DES_ROLE_GLOBAL_BANKER
                                  OR DES_Member_Role__c =: Label.DES_Role_Transactional_Banker))
                            FROM Account
                            WHERE Id IN :listAccountNPS]) {
      mapAccounts.put(iAccount.Id, iAccount);
      if(iAccount.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId()
        || iAccount.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_COMMERCIAL_CLIENT).getRecordTypeId()
        || iAccount.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_BEC_Manually_Group).getRecordTypeId()) {
        mapAccountsGroup.put(iAccount.Id, iAccount);
      }
    }
    system.debug('PROCESS1 listContactsNPSMail===='+listContactsNPSMail+'  listGlobalBankerEmail=='+listGlobalBankerEmail);
    npsNotificationAux(listNPSWave, mapAccounts, mapAccountsGroup,listContactsNPSMail,listGlobalBankerEmail);
  }

  /**
   *   @author Global Desktop
   *   @method npsNotificationAux
   */
  public static void npsNotificationAux(List<NPS_Wave__c> listNPSWave, Map<Id, Account> mapAccounts, Map<Id, Account> mapAccountsGroup,Map<String,String> listContactsNPSMail,Map<String,String> listGlobalBankerEmail) {
    final Map<Id, List<Id>> mapGroupSub = NPS_Wave_Helper_Aux.getGroupRelation(mapAccounts, mapAccountsGroup); //NOSONAR
    final Map<Id, Id> mapSubGroup = NPS_Wave_Helper_Aux.getMapClientGroup(mapAccounts.keySet()); //NOSONAR

    Map<NPS_Wave__c, List<Contact>> listContactsNPS = new Map<NPS_Wave__c, List<Contact>>();
    Map<NPS_Wave__c, List<Id>> listGlobalBanker = new Map<NPS_Wave__c, List<Id>>();
    for(NPS_Wave__c iNPSWave : listNPSWave) {
      for(Id iAccountId : mapAccounts.keySet()) {
        System.debug('::::::::::iAccountId: ' + iAccountId);
        if(iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c != null
          && iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c.containsIgnoreCase(mapAccounts.get(iAccountId).DES_Country_Client__c) == true)
        {
          System.debug('::::::::::mapAccounts.get(iAccountId).Contacts.isEmpty(): ' + mapAccounts.get(iAccountId).Contacts.isEmpty());
          System.debug('::::::::::mapAccountsGroup.containsKey(iAccountId): ' + mapAccountsGroup.containsKey(iAccountId));
          if(!mapAccounts.get(iAccountId).Contacts.isEmpty()) { //NOSONAR
            listContactsNPS = NPS_Wave_Helper_Aux.getListContactsNPS(listContactsNPS, mapAccounts, iAccountId, iNPSWave);
          } else if(mapAccounts.get(iAccountId).Contacts.isEmpty()
            && mapAccountsGroup.containsKey(iAccountId)) {
            final Boolean filialHasContact = NPS_Wave_Helper_Aux.filialHasContactFunc(mapAccounts, mapGroupSub, iAccountId);
            System.debug('::::::::::filialHasContact: ' + filialHasContact);
            if(filialHasContact == false) { //NOSONAR 
              final Id userIdAux = NPS_Wave_Helper_Aux.getUserId(mapAccountsGroup, iAccountId);
              System.debug('::::::::::userIdAux: ' + userIdAux);
              listGlobalBanker = NPS_Wave_Helper_Aux.getListGlobalBanker(listGlobalBanker, mapAccounts, userIdAux, iNPSWave);
            }
          } else if(mapAccounts.get(iAccountId).Contacts.isEmpty()
            && mapSubGroup.containsKey(iAccountId)) {
            final Boolean filialHasContact = NPS_Wave_Helper_Aux.filialHasContactFunc(mapAccounts, mapGroupSub, iAccountId);
            System.debug('::::::::::filialHasContact: ' + filialHasContact);
            if(filialHasContact == false) { //NOSONAR 
              final Id userIdAux = NPS_Wave_Helper_Aux.getUserId(mapAccountsGroup, mapSubGroup.get(iAccountId));
              System.debug('::::::::::userIdAux: ' + userIdAux);
              listGlobalBanker = NPS_Wave_Helper_Aux.getListGlobalBanker(listGlobalBanker, mapAccounts, userIdAux, iNPSWave);
            }
          }
        }
      }
    }
    system.debug('PROCESS4 listContactsNPSMail=='+listContactsNPSMail.size()+'  listGlobalBankerEmail=='+listGlobalBankerEmail.size()+'  listContactsNPS=='+listContactsNPS.size()+' listGlobalBanker='+ listGlobalBanker.size());

    sendEmail(listContactsNPS, listGlobalBanker,listContactsNPSMail,listGlobalBankerEmail);
  }

  /**
   *   @author Global Desktop
   *   @method sendEmail
   */
  public static void sendEmail(Map<NPS_Wave__c, List<Contact>> listContactsNPS, Map<NPS_Wave__c, List<Id>> listGlobalBanker,Map<String,String> listContactsNPSMail,Map<String,String> listGlobalBankerEmail) {
    if(!listContactsNPS.isEmpty()) {
      sendOwnerEmail(listContactsNPS,listContactsNPSMail);
    }

    if(!listGlobalBanker.isEmpty()) {
      sendGlobalBankerEmail(listGlobalBanker,listGlobalBankerEmail);
    }
  }

  /**
   *   @author Global Desktop
   *   @method sendOwnerEmail
   */
  public static void sendOwnerEmail(Map<NPS_Wave__c, List<Contact>> listContactsNPS,Map<String,String> listContactsNPSMail) {
    final Map<Id, Boolean> mapOwnerSendEmail = new Map<Id, Boolean>();
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();
    for(NPS_Wave__c iNPSWave : listContactsNPS.keySet()) {
      for(Contact iContact : listContactsNPS.get(iNPSWave)) {
        if(mapOwnerSendEmail.containsKey(iContact.OwnerId) == false&& listContactsNPSMail.containsKey(iContact.OwnerId) == false) {
          final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          system.debug('correo iContact.OwnerId===='+iContact.OwnerId);
          mail.setTemplateId(iEmailToOwner[0].Id);
          mail.setTargetObjectId(iContact.OwnerId);
          mail.setOrgWideEmailAddressId(Label.SER_MasterCaseInternalNotificationSender);
          mail.setSaveAsActivity(false);
          mail.setWhatId(iNPSWave.Id);

          listMails.add(mail);
          mapOwnerSendEmail.put(iContact.OwnerId, true);
		      listContactsNPSMail.put(iContact.OwnerId, iContact.OwnerId);
        }
      }
    }

    if(!listMails.isEmpty()) {
      Messaging.sendEmail(listMails);
    }
  }
  
  /**
   *   @author Global Desktop
   *   @method sendGlobalBankerEmail
   */
  public static void sendGlobalBankerEmail(Map<NPS_Wave__c, List<Id>> listGlobalBanker,Map<String,String> listGlobalBankerEmail) {
    final Map<Id, Boolean> mapOwnerSendEmail = new Map<Id, Boolean>();
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();
    for(NPS_Wave__c iNPSWave : listGlobalBanker.keySet()) {
      for(Id iUser : listGlobalBanker.get(iNPSWave)) {
        if(mapOwnerSendEmail.containsKey(iUser) == false 
          && iUser != null&&listGlobalBankerEmail.containsKey(iUser) == false) {
          final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          system.debug('correo iUser===='+iUser);
          mail.setTemplateId(iEmailToGB[0].Id);
          mail.setTargetObjectId(iUser);
          mail.setOrgWideEmailAddressId(Label.SER_MasterCaseInternalNotificationSender);
          mail.setSaveAsActivity(false);
          mail.setWhatId(iNPSWave.Id);

          listMails.add(mail);
          mapOwnerSendEmail.put(iUser, true);
		      listGlobalBankerEmail.put(iUser, iUser);
        }
      }
    }

    if(!listMails.isEmpty()) {
      Messaging.sendEmail(listMails);
    }
  }
}