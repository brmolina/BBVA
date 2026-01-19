/*
* @author Global Desktop
* @Description: batch que lanza las notificaciones de las alertas insertadas/modificadas con la configuración del usuario
*/
public without sharing class DES_Batch_NewAlert_Notify implements Database.Batchable<Sobject>, Database.Stateful {
  /**
  *  @Description Variable Global
  */
  private static List<ConnectApi.BatchInput> bItemInput = new List<ConnectApi.BatchInput>();

  /**
  *  @Description Private attributes
  */
  private String query = '';       //NOSONAR

  /**
  *  @Description Private attributes
  */
  private String TYPEALERT;       //NOSONAR

  /**
  *  @Description Private attributes
  */
  private static final String TASKGTB = 'Commercial Task GTB';

  /**
  * @author Global Desktop
  * @description Variable mapOwnerSendEmail
  */
  private final Map<Id, Boolean> mapOwnerSendEmail = new Map<Id, Boolean>();

  /**
  * @author Global Desktop
  * @description Variable mapOwnerSendEmail
  */
  private final Set<Id> usersNotified = new Set<Id>();

  /**
  * @author Global Desktop
  * @description Email template of notification
  */
  private static List<EmailTemplate> iEmailToOwner {
    get {
      if(iEmailToOwner == null) {
        final List<altm__Commercial_Alert_Setting__mdt> iSettings = [SELECT altm__Email_template__c FROM altm__Commercial_Alert_Setting__mdt LIMIT 1];

        iEmailToOwner = [SELECT Id,
                          DeveloperName,
                          Subject,
                          HtmlValue,
                          Markup
                        FROM EmailTemplate
                        WHERE DeveloperName = :iSettings[0].altm__Email_template__c];
      }
      return iEmailToOwner;
    } set;
  }

  /**
  * @author Global Desktop
  * @description Email template of notification
  */
  private static List<OrgWideEmailAddress> iOrgEmailAddress {
    get {
      if(iOrgEmailAddress == null) {
        final List<altm__Commercial_Alert_Setting__mdt> iSettings = [SELECT altm__Email_sender_address__c FROM altm__Commercial_Alert_Setting__mdt LIMIT 1];

        iOrgEmailAddress = [SELECT Id,
                              Address
                            FROM OrgWideEmailAddress
                            WHERE Address = :iSettings[0].altm__Email_sender_address__c
                            LIMIT 1];
      }
      return iOrgEmailAddress;
    } set;
  }

  private static Map<Id, List<Id>> userToKpiGroups = new Map<Id, List<Id>>();
  private static Map<Id, List<Id>> kpiGroupToUsersToBeNotifiedByEmail = new Map<Id, List<Id>>();
  private static Map<Id, List<Id>> kpiGroupToUsersToBeNotifiedByChatter = new Map<Id, List<Id>>();

  /**
  * @author Global Desktop
  * @Description constructor
  */
  public DES_Batch_NewAlert_Notify(String type) {
    this.query = 'SELECT Id, Name, altm__User_id__c, altm__participant_id__c, OwnerId, RecordTypeId, altm__commercial_alert_task_type__c, altm__commercial_subalert_name__c FROM altm__Commercial_Alert__c where CreatedDate = TODAY AND altm__commercial_alert_record_type__c = \'' + type + '\'' + (Test.isRunningTest() ? ' LIMIT 1000' : '');
    this.TYPEALERT = type;
    System.debug('>>>>> Query: ' + query);
  }

  /**
  * @author Global Desktop
  * @Description batchable method
  */
  public Database.QueryLocator start(Database.BatchableContext iBatchableContext) {
    return Database.getQueryLocator(query);
  }

  /**
  * @author Global Desktop
  * @Description batch que lanza las notificaciones de las alertas insertadas/modificadas con la configuración del usuario
  */
  public void execute(Database.BatchableContext iBatchableContext, List<altm__Commercial_Alert__c> listCommAlert) {
    final List<altm__Commercial_Alert__c> kpiAlerts = new List<altm__Commercial_Alert__c>();
    final List<altm__Commercial_Alert__c> otherAlerts = new List<altm__Commercial_Alert__c>();
    for (altm__Commercial_Alert__c alert : listCommAlert) {
      if (alert.altm__commercial_subalert_name__c == 'OPERATION WITHOUT KPI' || alert.altm__commercial_subalert_name__c == 'OPERATION WITH UPCOMING KPI REVIEW') {
        kpiAlerts.add(alert);
      } else {
        otherAlerts.add(alert);
      }
    }

    alertNotification(otherAlerts);
    generarNotificaciones(otherAlerts);

    initializeKpiVariables();
    alertNotificationForKpiAlerts(kpiAlerts);
    generarNotificacionesForKpiAlerts(kpiAlerts);

    if(bItemInput.size() > 0 && !Test.isRunningTest()) { //NOSONAR
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), bItemInput);
    }
  }

	/**
	* @author Global Desktop
	* @Description: finish batch method
	*/
	public void finish(Database.BatchableContext iBatchableContext) {
    if(TYPEALERT == TASKGTB) {
      final DES_Batch_NewAlert_Notify batchNotification = new DES_Batch_NewAlert_Notify('Commercial Task GCC');
      final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
      system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    } else {
      final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :iBatchableContext.getJobId()];
	    System.debug('>>>>> SUMMARY: ');
	    System.debug('>>>>>   Batches Created: '    + job.JobItemsProcessed);
	    System.debug('>>>>>   Number of Errors: '   + job.NumberOfErrors);
	    System.debug('>>>>>   Status: '             + job.Status);
      
    }
    //Se llama al batch de Commercial_Alert_UpdateToMatured_BATCH
      final Date fechaHoy = System.today();
      final Datetime fechaHoydt = (DateTime)fechaHoy;
      final String dayOfWeek = fechaHoydt.format('E');
      final String diaAevitar='Sat';
      if (dayOfWeek!=diaAevitar) {
          final Commercial_Alert_UpdateToMatured_BATCH batchUpdateToMatured = new Commercial_Alert_UpdateToMatured_BATCH();
          final Id batchInstanceId = Database.executeBatch(batchUpdateToMatured, 2000);
          system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
      }
      
      
    


  }

  /**
  * @author Global Desktop
  * @Description Funcion que genera notificaciones por carga en función de prioridad y/o tipo de notificacion que elige el usuario
  */
  public void generarNotificaciones(List<altm__Commercial_Alert__c> lstAlert) {
    final Set<Id> usersIds = new Set<Id>();

    for(altm__Commercial_Alert__c alert : lstAlert) {
      if(!usersNotified.contains(alert.OwnerId)) {
        usersIds.add(alert.OwnerId);
        usersNotified.add(alert.OwnerId);
      }
    }

    final List<User> users = new List<User>([
      SELECT Id FROM User WHERE Id IN :usersIds AND DES_Disable_Chatter__c = false AND isActive = true
    ]);

    for(User user : users) {
      generarPostChatter(user.Id);
    }

    System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());
    for(ConnectApi.BatchInput batch : Desktop_Utils.batchFeedItemInputs) {
      System.debug('batch: ' + batch);
    }

    if(!Desktop_Utils.batchFeedItemInputs.isEmpty() && !test.isRunningTest()) {             //NOSONAR
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
    }
  }  //FIN generarNotificaciones

  /**
  * @author Global Desktop
  * @Description Funcion que genera el post de chatter para las notificaciones de alertas
  */
  public static void generarPostChatter(Id idUser) {
    System.debug('idUser: ' + idUser);

    final ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    final ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = idUser;     // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    final ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ' ' + system.label.New_Alert_Notify;
    messageInput.messageSegments.add(textSegment);
    final ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;

    if(idUser != null) {
      input.subjectId = idUser;
    }

    final ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
    Desktop_Utils.batchFeedItemInputs.add(batchInput);
    System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());

    if(Desktop_Utils.batchFeedItemInputs.size() == 500 && !test.isRunningTest()) {     //NOSONAR
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
      Desktop_Utils.batchFeedItemInputs = new List<ConnectApi.BatchInput>();
      System.debug('>>>>> Desktop_Utils.batchFeedItemInputs FORMATEADO : ' + Desktop_Utils.batchFeedItemInputs);
    }
  }

  /**
  * @author Global Desktop
  * @description alertNotification
  */
  private void alertNotification(final List<altm__Commercial_Alert__c> newList) {
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();
    listMails.addAll(alertNotificationMail(newList));
    if(!listMails.isEmpty()) {
      Messaging.sendEmail(listMails);
    }
  }

  /**
  * @author Global Desktop
  * @description alertNotificationMail
  */
  private List<Messaging.SingleEmailMessage> alertNotificationMail(final List<altm__Commercial_Alert__c> listCommAlert) {
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();
    final Map<Id, Boolean> mapUserNotif = getOwnerNotification(listCommAlert);
    system.debug('** mapOwnerSendEmail -> ' + JSON.serialize(mapOwnerSendEmail));
    for(altm__Commercial_Alert__c iCommercialAlert : listCommAlert) {
      if(mapUserNotif.get(iCommercialAlert.OwnerId) == true
        && mapOwnerSendEmail.containsKey(iCommercialAlert.OwnerId) == false) {
        final Messaging.SingleEmailMessage mail = getEmailToSend(iCommercialAlert);
        listMails.add(mail);
        mapOwnerSendEmail.put(iCommercialAlert.OwnerId, true);
      }
    }
    return listMails;
  }

  /**
  * @author Global Desktop
  * @description getOwnerNotification
  */
  public static Map<Id, Boolean> getOwnerNotification(final List<altm__Commercial_Alert__c> listCommAlert) {
    final Set<Id> listOwnerId = new Set<Id>();
    for(altm__Commercial_Alert__c iCommercialAlert : listCommAlert) {
      listOwnerId.add(iCommercialAlert.OwnerId);
    }

    final Map<Id, Boolean> mapUserNotif = new Map<Id, Boolean>();
    for(User iUser : [SELECT Id,
                      altm__notification_mail_type__c
                      FROM User
                      WHERE Id IN :listOwnerId]) {
      mapUserNotif.put(iUser.Id, iUser.altm__notification_mail_type__c);
    }

    return mapUserNotif;
  }

  /**
  * @author Global Desktop
  * @description getEmailToSend
  */
  public static Messaging.SingleEmailMessage getEmailToSend(altm__Commercial_Alert__c iCommercialAlert) {
    final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    if(Test.isRunningTest()) { //NOSONAR
      mail.setHtmlBody('Test');
    } else {
      mail.setTemplateId(iEmailToOwner[0].Id);
      mail.setOrgWideEmailAddressId(iOrgEmailAddress[0].Id);
    }
    mail.setTargetObjectId(iCommercialAlert.OwnerId);
    mail.setSaveAsActivity(false);
    mail.setWhatId(iCommercialAlert.Id);

    return mail;
  }

  private static void initializeKpiVariables() {
    final List<GroupMember> groupMembers = [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.DeveloperName IN ('ESG_KPI_Alerts_Originacion', 'ESG_KPI_Alerts_Monitoring') WITH USER_MODE];
    final Set<Id> userIds = new Set<Id>();
    for (GroupMember m : groupMembers) {
      userIds.add(m.UserOrGroupId);
    }
    // Sí, es necesaria una query por separado a User
    final Map<Id, User> users = new Map<Id, User>([SELECT altm__notification_mail_type__c, DES_Disable_Chatter__c, IsActive FROM User WHERE Id IN :userIds]);

    for (GroupMember m : groupMembers) {
      initializeKpiVariable1(m);
      initializeKpiVariable2(m, users);
      initializeKpiVariable3(m, users);
    }
  }

  private static void initializeKpiVariable1(GroupMember m) {
    if (!userToKpiGroups.containsKey(m.UserOrGroupId)) {
      userToKpiGroups.put(m.UserOrGroupId, new List<Id>{m.GroupId});
    } else {
      userToKpiGroups.get(m.UserOrGroupId).add(m.GroupId);
    }
  }

  private static void initializeKpiVariable2(GroupMember m, Map<Id, User> users) {
    if (users.get(m.UserOrGroupId).altm__notification_mail_type__c == true) {
      if (!kpiGroupToUsersToBeNotifiedByEmail.containsKey(m.GroupId)) {
        kpiGroupToUsersToBeNotifiedByEmail.put(m.GroupId, new List<Id>{m.UserOrGroupId});
      } else {
        kpiGroupToUsersToBeNotifiedByEmail.get(m.GroupId).add(m.UserOrGroupId);
      }
    }
  }

  private static void initializeKpiVariable3(GroupMember m, Map<Id, User> users) {
    if (users.get(m.UserOrGroupId).DES_Disable_Chatter__c == false && users.get(m.UserOrGroupId).IsActive == true) {
      if (!kpiGroupToUsersToBeNotifiedByChatter.containsKey(m.GroupId)) {
        kpiGroupToUsersToBeNotifiedByChatter.put(m.GroupId, new List<Id>{m.UserOrGroupId});
      } else {
        kpiGroupToUsersToBeNotifiedByChatter.get(m.GroupId).add(m.UserOrGroupId);
      }
    }
  }

  private void alertNotificationForKpiAlerts(final List<altm__Commercial_Alert__c> kpiAlerts) {
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();
    listMails.addAll(alertNotificationMailForKpiAlerts(kpiAlerts));
    if(!listMails.isEmpty()) {
      Messaging.sendEmail(listMails);
    }
  }

  private List<Messaging.SingleEmailMessage> alertNotificationMailForKpiAlerts(final List<altm__Commercial_Alert__c> listCommAlert) {
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();

    for (altm__Commercial_Alert__c alert : listCommAlert) { // Por cada alerta de KPI
      if (userToKpiGroups.get(alert.OwnerId) != null) { // Si el Owner está en un grupo de KPI
        for (Id kpiGroup : userToKpiGroups.get(alert.OwnerId)) { // Por cada grupo
          if (kpiGroupToUsersToBeNotifiedByEmail.get(kpiGroup) != null) { // Si hay usuarios que quieren ser notificados por correo
            for (Id userId : kpiGroupToUsersToBeNotifiedByEmail.get(kpiGroup)) { // Por cada usuario
              if (!mapOwnerSendEmail.containsKey(userId) || !mapOwnerSendEmail.get(userId)) { // Si el usuario aún no ha sido notificado por correo
                final Messaging.SingleEmailMessage mail = getEmailToSend(userId, alert.Id);
                listMails.add(mail);
                mapOwnerSendEmail.put(userId, true);
              }
            }
          }
        }
      }
    }

    return listMails;
  }

  /** Muy parecido a otro método de esta clase con el mismo nombre */
  private static Messaging.SingleEmailMessage getEmailToSend(Id recipient, Id alert) {
    final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    if(Test.isRunningTest()) { //NOSONAR
      mail.setHtmlBody('Test');
    } else {
      mail.setTemplateId(iEmailToOwner[0].Id);
      mail.setOrgWideEmailAddressId(iOrgEmailAddress[0].Id);
    }
    mail.setTargetObjectId(recipient);
    mail.setSaveAsActivity(false);
    mail.setWhatId(alert);

    return mail;
  }

  private void generarNotificacionesForKpiAlerts(List<altm__Commercial_Alert__c> lstAlert) {
    for (altm__Commercial_Alert__c alert : lstAlert) { // Por cada alerta de KPI
      if (userToKpiGroups.get(alert.OwnerId) != null) { // Si el Owner está en un grupo de KPI
        for (Id kpiGroup : userToKpiGroups.get(alert.OwnerId)) { // Por cada grupo
          if (kpiGroupToUsersToBeNotifiedByChatter.get(kpiGroup) != null) { // Si hay usuarios que quieren ser notificados por Chatter
            for (Id userId : kpiGroupToUsersToBeNotifiedByChatter.get(kpiGroup)) { // Por cada usuario
              if (!usersNotified.contains(userId)) { // Si el usuario aún no ha sido notificado por Chatter
                generarPostChatter(userId);
                usersNotified.add(userId);
              }
            }
          }
        }
      }
    }

    if(!Desktop_Utils.batchFeedItemInputs.isEmpty() && !test.isRunningTest()) {             //NOSONAR
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
    }
  }

}