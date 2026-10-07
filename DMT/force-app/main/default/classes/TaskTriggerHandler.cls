/**********************************************************************************
* @author       Accenture
* @date         12/01/2016
* @description  Manejador del trigger para el objeto Task. No implementar logica aquí, para ello utilizar ActivitiesUtils
* @Revision
                2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
                22/06/2018 Update -> se añade modificación en metodo onAfterInsert para que no afecte a los usuarios Desktop
**********************************************************************************/
public with sharing class TaskTriggerHandler {
  //LOGIC
  //private final ActivitiesUtils logic;
  private Integer timesExecuted = 0;
  private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();

  //CONSTRUCTOR
  private TaskTriggerHandler() {
    //this.logic = new ActivitiesUtils();
  }

  //SINGLETON PATTERN
  private static TaskTriggerHandler instance;
  public static TaskTriggerHandler getInstance() {
    if (instance == null) instance = new TaskTriggerHandler();
    return instance;
  }

  /*---------------------------------------------------------------------------------------
    ON AFTER INSERT
  ---------------------------------------------------------------------------------------*/
  public void onAfterInsert(final List<Task> newList) {
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Task (after insert)');
    if(!userSettings.CIB_Is_Desktop__c) {
      ActivitiesUtils.setTimeAccount(newList);
      /*if (userSettings.CIB_Is_Sales__c){
          system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...');
          ActivitiesUtils.newTasks(newList);  //this.logic.newTasks(newList);
          //ActivitiesUtils.relateNewActivities(); //this.logic.relateNewActivities();
          //ActivitiesUtils.chekEQPublic(newList, 'Task');
        } else {
          ActivitiesUtils.setProcessedAtTrue(newList);
        }*/
    }
    timesExecuted ++;
    List<Task> dmtTasks = DES_RecordType_Utils.filter((List<SObject>) Trigger.new, 'Task', 'DMT_Step_Approval');
    if (!dmtTasks.isEmpty()) {
      // Send Task Assigned notifications for DMT tasks
      DMT_CloseWonNotificationService.sendTaskAssignedLineNotifications(dmtTasks);
      DMT_CloseWonNotificationService.sendTaskAssignedOppNotifications(dmtTasks);
    } else {
      Task_Helper_Comm_Alert.changeCommAlertStatusInsert(newList);
    }
  }

  /*---------------------------------------------------------------------------------------
    ON AFTER UPDATE
  ---------------------------------------------------------------------------------------*/
  public void onAfterUpdate(final List<Task> newList, Map<Id, Task> newMap, Map<Id, Task> oldMap) {
    
    List<Task> dmtTasks = DES_RecordType_Utils.filter((List<SObject>) Trigger.new, 'Task', 'DMT_Step_Approval');
    if (!dmtTasks.isEmpty()) {
      ActivitiesUtils.updateLineFromTask(dmtTasks);
    } else {
    Task_Helper_Comm_Alert.changeCommAlertStatusUpdate(newMap, oldMap);
  }
  }

  /*---------------------------------------------------------------------------------------
    ON BEFORE UPDATE
  ---------------------------------------------------------------------------------------*/
  public void onBeforeUpdate(final List<Task> newList, Map<Id, Task> oldMap) {
    if(userSettings.CIB_Is_Service__c) {
      ActivitiesUtils.updateAuxLastModify(newList);
    }
  }
/*
  public void onBeforeUpdate(final Map<Id,Task> oldMap, final Map<Id,Task> newMap) {
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Task (before update)');
    if (userSettings.CIB_Is_Sales__c){
      system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...');
      //ActivitiesUtils.checkConversionChangeWhoIdTask(oldMap,newMap);
      ActivitiesUtils.checkChangeRelatedToTask(oldMap,newMap);
      ActivitiesUtils.checkChangeTaskVisibility (oldMap,newMap);
    }
    timesExecuted ++;
  }

  public void onAfterDelete(final List<Task> oldList) {
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Task (after delete)');
    if (userSettings.CIB_Is_Sales__c){
      system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...');
      ActivitiesUtils.deleteEmptyActivityC(oldList);
    }
    timesExecuted ++;
  }

  Se comenta esta parte porque no se dispara el 'trigger before insert' ni para Task ni para Events. Se traslada la lógica al evento del trigger 'after insert'
  public void onBeforeInsert(final List<Task> newList) {
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Task (before insert)');
    ActivitiesUtils.chekEQPublic(newList, 'Task');
    timesExecuted ++;
  }
*/
}