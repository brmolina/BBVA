/*
 * @author GlobalDesktop
 * @description Clase batch para enviar notificaciones a los usuarios que participan
 *              en iniciativas que finalizan en 15 días o 24h.
 */
global class InitiativeNotificationBatch implements Database.Batchable<sObject> {   //NOSONAR

  private Date expiration1, expiration2;    //NOSONAR
  private String query;                     //NOSONAR
  /*
  * String para el sonar
  */
  private static final String NAMEVAR = '[Name]';

  /*
   * Constructor
   */
  global InitiativeNotificationBatch(String query) {
    this.expiration1 = Date.today().addDays(15);
    this.expiration2 = Date.today().addDays(1);
    this.query = query;
  }

  /*
   * Met0d0 de implementar Database.Batchable<sObject>.
   */
  global Database.QueryLocator start(Database.BatchableContext batchContxt) {
    return Database.getQueryLocator(query);
  }

  /*
   * Met0d0 de implementar Database.Batchable<sObject>.
   */
  global void execute(Database.BatchableContext batchContxt, List<intt__Team_initiative__c> scope) {
    List<Task> tareas = new List<Task>();
    tareas = createNotifications(scope);
    insert tareas;
    sendMail(scope);
  }

  /*
   * Met0d0 de implementar Database.Batchable<sObject>.
   */
  global void finish(Database.BatchableContext batchContxt) {
    List<Campaign> endIntts = [SELECT Id, EndDate, RecordType.DeveloperName, Status FROM Campaign WHERE RecordType.DeveloperName = 'Initiative' AND EndDate <= TODAY AND Status != 'Ended'];    //NOSONAR
    System.debug('***' + endIntts.size() + '***');
    for(Campaign intt : endIntts) {
      System.debug('Intt Status ' + intt.Status + ' / RecordType ' + intt.RecordType.DeveloperName);
      intt.Status = 'Ended';
    }
    update endIntts;
    if(endIntts != null && endIntts.size() != 0 && endIntts[0] != null) {
      System.debug(endIntts[0].Status);
    }
  }

  /*
   * Met0d0 que crea tareas a los participantes.
   */
  private List<Task> createNotifications(List<intt__Team_initiative__c> teamList) {
    List<Task> tareas = new List<Task>();     //NOSONAR
    for(intt__Team_initiative__c member : teamList) {
      String mensaje = createMessage(member); //NOSONAR
      Task tarea = new Task();                //NOSONAR
      tarea.OwnerId = member.intt__manager_team_id__c;
      if(member.intt__campaign_id__c == null) {
        tarea.WhatId = member.intt__gf_group_campaign_id__r.cond__campaign_id__c;
      } else {
        tarea.WhatId = member.intt__campaign_id__c;
      }
      tarea.Subject = mensaje;
      tarea.IsReminderSet = true;
      tarea.ReminderDateTime = System.now().addMinutes(5);
      tareas.add(tarea);
    }
    return tareas;
  }

  /*
  * Met0d0 que crea el mensaje de la notificación.
  */
  private String createMessage(intt__Team_initiative__c member) {
    String mensaje = '';
    if(member.intt__campaign_id__c == null) {
      if(member.intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate == expiration1) {
        mensaje = Label.Initiative_15_days_notification.replace(NAMEVAR, member.intt__gf_group_campaign_id__r.cond__campaign_id__r.Name);
      } else {
        mensaje = Label.Initiative_24_h_notification.replace(NAMEVAR, member.intt__gf_group_campaign_id__r.cond__campaign_id__r.Name);
      }
    } else {
      if(member.intt__campaign_id__r.EndDate == expiration1) {
        mensaje = Label.Initiative_15_days_notification.replace(NAMEVAR, member.intt__campaign_id__r.Name);
      } else {
        mensaje = Label.Initiative_24_h_notification.replace(NAMEVAR, member.intt__campaign_id__r.Name);
      }
    }
    return mensaje;
  }

  /*
   * Met0d0 que envia mail a los participantes.
   */
  private void sendMail(List<intt__Team_initiative__c> recipients) {
    Map<Id,List<intt__Team_initiative__c> > teamInitiativeMap = new Map<Id,List<intt__Team_initiative__c> >();          //NOSONAR

    for(intt__Team_initiative__c participante : recipients) {
      if(participante.intt__campaign_id__c == null) {
        if(teamInitiativeMap.containsKey(participante.intt__gf_group_campaign_id__r.cond__campaign_id__c)) {
          List<intt__Team_initiative__c> teamInttList = teamInitiativeMap.remove(participante.intt__gf_group_campaign_id__r.cond__campaign_id__c);  //NOSONAR
          teamInttList.add(participante);
          teamInitiativeMap.put(participante.intt__gf_group_campaign_id__r.cond__campaign_id__c, teamInttList);
        } else {
          List<intt__Team_initiative__c> teamInttList = new List<intt__Team_initiative__c> {participante};              //NOSONAR
        teamInitiativeMap.put(participante.intt__gf_group_campaign_id__r.cond__campaign_id__c, teamInttList);
        }
      } else {
        if(teamInitiativeMap.containsKey(participante.intt__campaign_id__c)) {
          List<intt__Team_initiative__c> teamInttList = teamInitiativeMap.remove(participante.intt__campaign_id__c);    //NOSONAR
          teamInttList.add(participante);
          teamInitiativeMap.put(participante.intt__campaign_id__c, teamInttList);
        } else {
          List<intt__Team_initiative__c> teamInttList = new List<intt__Team_initiative__c> {participante};              //NOSONAR
          teamInitiativeMap.put(participante.intt__campaign_id__c, teamInttList);
        }
      }
    }
    mailToParticipants(teamInitiativeMap);
  }

  /*
   * Met0d0 que envia mail a los participantes.
   */
  private void mailToParticipants(Map<Id,List<intt__Team_initiative__c> > teamInitiativeMap) {
    List<intt__Team_initiative__c> teamInttList = new List<intt__Team_initiative__c>();
    intt__Team_initiative__c participante;
    String nombre, body, link, subject;

    for(Id iniciativa : teamInitiativeMap.keySet()) {
      teamInttList = teamInitiativeMap.get(iniciativa);
      participante = teamInttList[0];

      if(participante.intt__campaign_id__c == null) {
        nombre = participante.intt__gf_group_campaign_id__r.cond__campaign_id__r.Name;
        link = Url.getOrgDomainURL().toExternalForm() + '/' + participante.intt__gf_group_campaign_id__r.cond__campaign_id__c;
        if(participante.intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate == expiration1) {
          body = Label.Initiative_15_days_notification.replace(NAMEVAR, nombre);
        } else {
          body = Label.Initiative_24_h_notification.replace(NAMEVAR, nombre);
        }
      } else {
        nombre = participante.intt__campaign_id__r.Name;
        link = Url.getOrgDomainURL().toExternalForm() + '/' + participante.intt__campaign_id__c;
        if(participante.intt__campaign_id__r.EndDate == expiration1) {
          body = Label.Initiative_15_days_notification.replace(NAMEVAR, nombre);
        } else {
          body = Label.Initiative_24_h_notification.replace(NAMEVAR, nombre);
        }
      }

      subject = Label.Initiative_15_days_notification.remove(' in 15 days, you can check it here.').replace('[Name]', nombre);
      body = body.replace('here', '<a href="' + link + '">here</a>');
      UtilInitiatives.sendMail(subject, body, teamInttList);
    }
  }
}