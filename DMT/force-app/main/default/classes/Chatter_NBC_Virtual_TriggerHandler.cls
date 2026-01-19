/**********************************************************************************
* @author       VASS
* @date         20/11/2019
* @description  Handler para objeto Chatter_NBC_Virtual__c.
* @Revision
                2019/11/20 Se crea la clase. Agregada funcion 'logicAfterInsert'
**********************************************************************************/
public without sharing class Chatter_NBC_Virtual_TriggerHandler {

  /*
   * SINGLETON PATTERN
   */
  private static Chatter_NBC_Virtual_TriggerHandler instance;

  /*
  * Chatter_NBC_Virtual_TriggerHelper Class
  */
  final Chatter_NBC_Virtual_TriggerHelper helperClass = Chatter_NBC_Virtual_TriggerHelper.getInstance();

  /*
   * getInstance
   */
  private Chatter_NBC_Virtual_TriggerHandler() {  }

  /*
   * getInstance
   */
  @SuppressWarnings('sf:AvoidGetSetMethods')
  public static Chatter_NBC_Virtual_TriggerHandler getInstance() {
    if (instance == null) instance = new Chatter_NBC_Virtual_TriggerHandler();//NOSONAR
    return instance;
  }

  /*
   *  @author Global Desktop
   *  @Description  Esta funcion se encarga de gestionar la logica que se ejecuta en el after insert del trigger
   *
  **/
  public static void logicAfterInsert(Map<Id, Chatter_NBC_Virtual__c> triggerNewMap) {
    Chatter_NBC_Virtual_TriggerHelper.createApexSharing(triggerNewMap);
  }

}