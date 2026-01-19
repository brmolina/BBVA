/**********************************************************************************
* @author       Accenture
* @date			12/01/2016
* @description  Manejador del trigger para el objeto Event. No implementar logica aquí, para ello utilizar ActivitiesUtils
* @Revision     
                2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
**********************************************************************************/
public with sharing class EventTriggerHandler {
	//LOGIC
    	//private final ActivitiesUtils logic;
    private Integer timesExecuted = 0;
    private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();     

    //CONSTRUCTOR
    private EventTriggerHandler() {
        //this.logic = new ActivitiesUtils();
    }

    //SINGLETON PATTERN
    private static EventTriggerHandler instance;
    public static EventTriggerHandler getInstance() {
        if (instance == null) instance = new EventTriggerHandler();
        return instance;
    }
        
    
    //EVENT HANDLER    

  /*     
       
    public void onAfterInsert(final List<Event> newList) {
    	system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Event (after insert)');
		if (userSettings.CIB_Is_Sales__c){
			system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...');    		     	      	
    		ActivitiesUtils.newEvents(newList);  //this.logic.newEvents(newList);
		} else {
            ActivitiesUtils.setProcessedAtTrue(newList);
        }
        timesExecuted ++;
    }
    
  
    public void onBeforeUpdate(final Map<Id,Event> oldMap, final Map<Id,Event> newMap) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Event (before update)');
		if (userSettings.CIB_Is_Sales__c){
			system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...'); 		
	    	//ActivitiesUtils.checkConversionChangeWhoIdEvent(oldMap,newMap);
	    	ActivitiesUtils.checkChangeRelatedToEvent(oldMap,newMap);    	
	    	ActivitiesUtils.checkChangeEventVisibility (oldMap,newMap);
		} 
        timesExecuted ++;
    }
    
    
    
    public void onAfterDelete(final List<Event> oldList) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Event (after delete)');
		if (userSettings.CIB_Is_Sales__c){
			system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...'); 		
    		ActivitiesUtils.deleteEmptyActivityC(oldList);
		}    
        timesExecuted ++;
    }    
 */   
     	
    
    //Se comenta esta parte porque no se dispara el 'trigger before insert' ni para Task ni para Events. Se traslada la lógica al evento del trigger 'after insert'
    //public void onBeforeInsert(final List<Event> newList) {
    //    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Event (before insert)'); 
    //    ActivitiesUtils.chekEQPublic(newList,'Event');
    //    timesExecuted ++;
    //}           
    
    
 
}