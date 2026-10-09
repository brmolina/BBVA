/**********************************************************************************
* @author       Accenture
* @date         12/01/2016
* @description  Clase útil con la lógia para la Task y Events
* @Revision
    2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
**********************************************************************************/
public with sharing class ActivitiesUtils {
  /* Constante 'SOPORTE SWIFT HOST-TO-HOST' */
  public final static String SOPORTE_SWIFT = 'SOPORTE SWIFT HOST-TO-HOST';
  /* Constante 'Call' */
  public final static String CALL = 'Call';
  /**
  * description: MAPTECHIMBYSEV for TechImpact by Severety
  * @author Victor Velandia
  */
  public final static map<Id, String> MAPTECHIMBYSEV = new map<Id, String>();

  /**
  * description: MAP_TECH_IMPACT for value TechImpact
  * @author Victor Velandia
  */
  private static final Map<string,integer> MAP_TECH_IMPACT;
  static {
    MAP_TECH_IMPACT = new Map<string,integer>{
      '1. Critical'   => 1,
      '2. High'       => 2,
      '3. Medium'     => 3,
      '4. Low'        => 4,
      '5. No Impact'  => 5
    };
  }

  /*-----------------------------------------------------------------------
     Construtor privado
  ------------------------------------------------------------------------*/
  private ActivitiesUtils() {}

  //-- PUBLIC STATIC METHODS
  /*-----------------------------------------------------------------------
    Author:         Juan Carlos Terrón
    Company:        Accenture
    Description:    Fills ContactTriggerHandler map_EmptyEmailContacts static map in order
                    to update Contact email field to match
                    the related Case supplied email.

    IN:        Trigger.newMap(Contact)
    OUT:       Void

    History:
    <Date>          <Author>              <Change Description>
    27/02/2017      Juan Carlos Terrón    Initial Version
  -------------------------------------------------------------------------*/
  public static void check_EmptyContactEmail(Map<Id,Contact> newMap) {
    System.debug('JCT - Entering ActivitiesUtils.fill_ContactEmail()');
    SER_TriggerHelper.set_MetodFired('check_EmptyContactEmail', true);
    Set<Id> set_ContactId = new Set<Id>();
    List<Contact> list_Contacts_T = new List<Contact>();
    for(Contact contacto : newMap.values()) {
      if(String.isBlank(String.valueOf(contacto.Email))) {
        ContactTriggerHandler.map_EmptyEmailContacts.put(contacto.Id, contacto);
      }
    }
    System.debug('JCT - ContactTriggerHandler.map_EmptyEmailContacts : '+ContactTriggerHandler.map_EmptyEmailContacts);
  }

  /*--------------------------------------------------------------------------
    Author:        Brian Capilla
    Company:       Accenture Cloud First
    Description:   Metodo para rellenar el campos SAL_ultima_llamada__c del Account asociado.

    IN:        List<Task> newList
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    29/09/2017      Brian Capilla      Initial Version
  ----------------------------------------------------------------------------*/
  public static void setTimeAccount(List<Task> newList) {
    final String accountPrefix = Utilities.getObjectPrefix('Account');
    final Map<String, Task> mapAccId = new Map<String, Task>();
    final Map<String, Task> mapContId = new Map<String, Task>();
    for(Task ts : newList) {
      if(ts.type == CALL) {
        System.debug(ts.whatid);
        if(ts.whatid != null && String.valueOf(ts.whatid).startsWith(accountPrefix)) {
          mapAccId.put(ts.whatid,ts);
        } else {
          mapContId.put(ts.whoId,ts);
        }
      }
    }
    if(!mapContId.isEmpty()) {
      for(Contact con : [select id, AccountId from Contact where id in :mapContId.keySet()]) {
        if(con.AccountId != null) {
          mapAccId.put(con.AccountId, mapContId.get(con.id));
        }
      }
    }
    final Set<Account> lstToUppd = new Set<Account>();
    if(!mapAccId.isEmpty()) {
      final Set<Account> lstAcc = new Set<Account>();
      lstAcc.addAll([select id, SER_Service_Client__c from Account where id in :mapAccId.keySet()]);
      final List<String> lstAccBus = new List<String>();
      for(Account ac : lstAcc) {
        if(ac.SER_Service_Client__c != null) {
          lstAccBus.add(ac.SER_Service_Client__c);
        }
        lstAccBus.add(ac.id);
      }
      lstAcc.addAll([select id, SER_Service_Client__c from Account where SER_Service_Client__c in :lstAccBus]);
      if(!lstAcc.isEmpty()) {
        for(Account co : lstAcc) {
          if(co.SER_Service_Client__c != null) {
            //Se comenta por que los usuarios Sales ya no tienen acceso a las cuentas de service
            //lstToUppd.add(new Account(id = co.SER_Service_Client__c, SAL_ultima_llamada__c = mapAccId.containsKey(co.id)?mapAccId.get(co.id).CreatedDate:mapAccId.values().get(0).CreatedDate));
            lstToUppd.add(new Account(id = co.id, SAL_ultima_llamada__c = mapAccId.containsKey(co.id)?mapAccId.get(co.id).CreatedDate:mapAccId.values().get(0).CreatedDate));
          }
        }
      }
    }
    if(!lstToUppd.isEmpty()) {
      System.debug('Actualizando Cuentas');
      update new List<Account>(lstToUppd);
    }
  }

  /*--------------------------------------------------------------------------
    Author:        Jose Luis
    Company:       Accenture
    Description:   Update AuxLastModify

    IN:        List<Task> newList
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    17/06/2020        Jose Luis      Initial Version
  ----------------------------------------------------------------------------*/
	public static void updateAuxLastModify(final List<Task> tasks) {
    final datetime myDateTime = datetime.now();
    String fechaLM;
    final Integer FORMAT = 10;
    final Integer month = myDateTime.month();
    final Integer day = myDateTime.day();
    final Integer hour = myDateTime.hour();
    final Integer minutes = myDateTime.minute();
    final Integer second = myDateTime.second();

    fechaLM = myDateTime.year()+'-';

    if (month<FORMAT) {
      fechaLM = fechaLM+'0'+month+'-';
    } else {
      fechaLM = fechaLM+month+'-';
    }
    if (day<FORMAT) {
      fechaLM = fechaLM+'0'+day+' ';
    } else {
      fechaLM = fechaLM+day+' ';
    }
    if (hour<FORMAT) {
      fechaLM = fechaLM+'0'+hour+':';
    } else {
      fechaLM = fechaLM+hour+':';
    }
    if (minutes<FORMAT) {
      fechaLM = fechaLM+'0'+minutes+':';
    } else {
      fechaLM = fechaLM+minutes+':';
    }
    if (second<FORMAT) {
      fechaLM = fechaLM+'0'+second;
    } else {
      fechaLM = fechaLM+second;
    }

    for(Task tarea : tasks) {
      tarea.AuxLastModDate__c = fechaLM;
    }
  }

  public static void updateLineFromTask(final List<Task> tasks) {
    Set<Id> idCasos = new Set<Id>();
    Set<Id> idLines = new Set<Id>();
    Set<Id> idUsers = new Set<Id>();
    Set<String> lineId = new Set<String>();
    Map<Id, Id> mapCaseUser = new Map<Id, Id>();
    Map<Id, Id> mapLineUser = new Map<Id, Id>();
    Map<Id, User> mapUser = new Map<Id, User>();
    Map<String, User> mapConsolidatedLineUser = new Map<String, User>();
    Map<Id, String> mapTaskType = new Map<Id, String>();
    // CIBGLOBALD-3690
    Map<Id, String> mapCaseScope = new Map<Id, String>();
    Map<Id, String> mapLineScope = new Map<Id, String>();
    // Consultar las tareas con su tipo de tarea
    Set<Id> taskIds = new Set<Id>();
    for (Task t : tasks) {
        taskIds.add(t.Id);
    }
    if (!taskIds.isEmpty()) {
        for (Task t : [
          //29/04/25 - Se añade cambio solicitado en CIBGLOBALD-1191 [INI]
            SELECT Id, WhatId, Status, LastModifiedById, DMT_Task_Type__c,
                   DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Scope__c
            FROM Task
            WHERE Id IN :taskIds
        ]) {
            String taskScope = t.DMT_Task_Type__r != null ? t.DMT_Task_Type__r.DMT_Scope__c : null;
            System.debug('User:' + t.WhatId + ' Status: ' + t.Status + ' Scope: ' + taskScope);

            if (t.WhatId != null && (t.Status == 'Completed' || t.Status == 'Finished') &&
                String.isNotBlank(taskScope)) {
                idCasos.add(t.WhatId);
                idUsers.add(t.LastModifiedById);
                mapCaseUser.put(t.WhatId, t.LastModifiedById);
                mapCaseScope.put(t.WhatId, taskScope);
            }
        }
    }
    // Obtener usuarios relacionados
    if (!idUsers.isEmpty()) {
        for (User u : [SELECT Id, Name FROM User WHERE Id IN :idUsers]) {
            mapUser.put(u.Id, u);
        }
    }
    // Obtener casos y sus líneas
    if (!idCasos.isEmpty()) {
        for (Case caso : [SELECT Id, DMT_Line__c FROM Case WHERE Id IN :idCasos]) {
            if (caso.DMT_Line__c != null) {
                Id lineIdVal = Id.valueOf(caso.DMT_Line__c);
                idLines.add(lineIdVal);
                mapLineUser.put(lineIdVal, mapCaseUser.get(caso.Id));
                mapLineScope.put(lineIdVal, mapCaseScope.get(caso.Id));
            }
        }
    }
    // Obtener líneas a actualizar
    List<DMT_Line__c> linesToUpdate = new List<DMT_Line__c>();
    if (!idLines.isEmpty()) {
        for (DMT_Line__c line : [
          //29/04/25 - Se añade cambio solicitado en CIBGLOBALD-1191 [INI]
            SELECT Id, DMT_Global_Risk_Analyst_User__c, DMT_Local_Risk_Analyst__c, Line_Id__c, DMT_Local_Risk_Analyst_User__c
            FROM DMT_Line__c WHERE Id IN :idLines
        ]) {
            Id userId = mapLineUser.get(line.Id);
            String lineScope = mapLineScope.get(line.Id);
            if (userId != null && mapUser.containsKey(userId)) {
                User user = mapUser.get(userId);
                if (lineScope == 'Local' || lineScope == 'Global y Local') {
                    line.DMT_Local_Risk_Analyst__c = user.Name;
                    line.DMT_Local_Risk_Analyst_User__c = user.Id;
                }
                if (lineScope == 'Global' || lineScope == 'Global y Local') {
                    line.DMT_Global_Risk_Analyst__c = user.Name;
                    line.DMT_Global_Risk_Analyst_User__c = user.Id;
                }
                //29/04/25 - Se añade cambio solicitado en CIBGLOBALD-1191 [FIN]
                mapConsolidatedLineUser.put(line.Line_Id__c, user);
                lineId.add(line.Line_Id__c);
            }
            linesToUpdate.add(line);
        }
    }

    // Obtener líneas consolidadas
    // List<DMT_Consolidated_Line__c> consolidatedLinesToUpdate = new List<DMT_Consolidated_Line__c>();
    // if (!lineId.isEmpty()) {
    //     for (DMT_Consolidated_Line__c consolidatedLine : [
    //         SELECT Id, global_risk_analyst__c, global_risk_analyst_name__c, line_id__c
    //         FROM DMT_Consolidated_Line__c WHERE line_id__c IN :lineId
    //     ]) {
    //         if (mapConsolidatedLineUser.containsKey(consolidatedLine.line_id__c)) {
    //             User user = mapConsolidatedLineUser.get(consolidatedLine.line_id__c);
    //             consolidatedLine.global_risk_analyst__c = user.Id;
    //             consolidatedLine.global_risk_analyst_name__c = user.Name;
    //         }
    //         consolidatedLinesToUpdate.add(consolidatedLine);
    //     }
    // }

    // Actualizar registros
    if (!linesToUpdate.isEmpty()) {
      DMT_WithoutSharingDAO.updateRecords(linesToUpdate);
    }
    // if (!consolidatedLinesToUpdate.isEmpty()) {
    //     update consolidatedLinesToUpdate;
    // }
  }
}