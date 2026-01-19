/*
*Name:            Wrapper_ctrl
*Description:     Controlador del componente Wrapper del Kit de visitas v4   -
*/
public with sharing class Wrapper_ctrl {

   /*
   * Variable int uno
   */
  private static final Integer ONE = 1;

    /**
    * SINGLETON PATTERN
    */
    private static Wrapper_ctrl instance;

    /**
    * getInstance
    */
    public static Wrapper_ctrl gtInstance() {//NOSONAR
        if (instance == null) {
        instance = new Wrapper_ctrl();
        }
        return instance;
    }

    /*
    * Met0d0 para pasar sonar
    */
    private Wrapper_ctrl() {}

    /*
    *Met0d0 que envia la notificacion a Google del kit de visitas
     */
    @AuraEnabled
    public static void sendToGoogle(Id visitId, boolean notifications) {
        final List<event> eventList = [SELECT Id FROM Event WHERE dwp_kitv__visit_id__c = :visitId AND isChild = False];
        System.debug('sendToGoogle event List '+ eventList);
        if(eventList.size() == ONE) {
            gcal.GBL_Configuration_wrp googleConfig;
            googleConfig = new gcal.GBL_Configuration_wrp();
            googleConfig.synchronizeAll = true;
            googleConfig.notifications = notifications;
            //gcal.GBL_EventHandler.synchronizeEvent (new List<Id>{eventList[0].Id},googleConfig);
        }
    }
}