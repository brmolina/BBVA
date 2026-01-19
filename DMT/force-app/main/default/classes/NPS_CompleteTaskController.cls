/**
 * @author Global Desktop
 * @description Clase del componente lightning NPS_CompleteTask del botón de
 *              la listview de contacto.
 */
public with sharing class NPS_CompleteTaskController {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static NPS_CompleteTaskController instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static NPS_CompleteTaskController getInstance() { //NOSONAR
    if (instance == null) {
      instance = new NPS_CompleteTaskController();
    }
    return instance;
  }

  private NPS_CompleteTaskController() {
  }

  /**
   * @author Global Desktop
   * @method haveNPSContacts
   */
  @auraEnabled
  public static String haveNPSContacts() {
    final Id iUserId = UserInfo.getUserId();
    final List<Task> listTask = [SELECT Id,
                                  Status
                                FROM Task
                                WHERE Subject LIKE 'NPS Wave%'
                                  AND Status = 'In Progress'
                                  AND OwnerId = :iUserId];

    final WrapperClass iWrapperClass = new WrapperClass(listTask.isEmpty());
    final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
    listWrapperClass.add(iWrapperClass);
    return JSON.serialize(listWrapperClass);
  }

  /**
   * @author Global Desktop
   * @method completeTask
   */
  @auraEnabled
  public static void completeTask() {
    final Id iUserId = UserInfo.getUserId();
    final List<Task> listTask = new List<Task>();
    for(Task iTask : [SELECT Id,
                        Status
                      FROM Task
                      WHERE Subject LIKE 'NPS Wave%'
                        AND Status = 'In Progress'
                        AND OwnerId = :iUserId]) {
      iTask.Status = 'Completed';
      listTask.add(iTask);
    }

    if(!listTask.isEmpty()) {
      update listTask;
    }
  }

  /**
   * @author Global Desktop
   * @description clase para construir lista wrapper
   */
  public class WrapperClass {
    /**
     * @author Global Desktop
     * @description Variables de la clase wrapper
     */
    private Boolean isEmpty; //NOSONAR

    /**
     * @author Global Desktop
     * @description Construye lista wrapper
     */
    public WrapperClass(Boolean isEmpty) {
      this.isEmpty = isEmpty;
      System.debug('::::::::::::::::::::this:::: ' + this);
    }
  }
}