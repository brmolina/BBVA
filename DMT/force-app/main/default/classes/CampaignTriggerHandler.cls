/**********************************************************************************
* @author       Accenture
* @date			01/03/2016
* @description  Manejador del trigger para el objeto Campaign. No implementar logica aquí, para ello utilizar ActivitiesUtils
* @Revision     
                2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
**********************************************************************************/
public with sharing class CampaignTriggerHandler {
	//LOGIC
    	//private final ActivitiesUtils logic;
    private Integer timesExecuted = 0;
    private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();    

    //CONSTRUCTOR
    private CampaignTriggerHandler() {
        //this.logic = new ActivitiesUtils();
    }

    //SINGLETON PATTERN
    private static CampaignTriggerHandler instance;
    public static CampaignTriggerHandler getInstance() {
        if (instance == null) instance = new CampaignTriggerHandler();
        return instance;
    }
        
    
    //EVENT HANDLER      
/*
    public void onAfterDelete(final List<Campaign> oldList) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Campaign (after delete)');
		if (userSettings.CIB_Is_Sales__c){
			system.debug(Logginglevel.INFO,'>>>>>>> Sales User. Entering custom activities...');		
    		ActivitiesUtils.deleteActivityC(oldList);
		}
        timesExecuted ++;
    }
 */
 }