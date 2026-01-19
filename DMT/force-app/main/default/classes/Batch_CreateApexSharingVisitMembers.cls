/**********************************************************************************
* @author  		VASS     
* @date         
* @description  Batch que genera todos los Apex Sharing para el equipo de cuenta de los objetos de oportunidad, el kit de visitas y las commercial alerts
* @Revision     
**********************************************************************************/
public without sharing class Batch_CreateApexSharingVisitMembers implements Database.Batchable<Sobject>, Database.Stateful {
    private String pQuery = 'SELECT Id, dwp_kitv__visit_id__c, dwp_kitv__user_id__c FROM dwp_kitv__Visit_Management_Team__c' + (Test.isRunningTest()?' LIMIT 1':'');
    
    public Batch_CreateApexSharingVisitMembers(){
        system.debug('>>>>> pQuery : ' + pQuery);
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(pQuery);
    }
    
    
    public void execute(Database.BatchableContext bc,List<dwp_kitv__Visit_Management_Team__c> scope){
    	system.debug('>>>>> scope : ' + scope);
    	Desktop_Utils handlerDesktopUtils = Desktop_Utils.getInstance();
		List<dwp_kitv__Visit__Share> listVisitSharing = new List<dwp_kitv__Visit__Share>();
		for(dwp_kitv__Visit_Management_Team__c visitTM : scope){
			listVisitSharing.add(handlerDesktopUtils.newManualSharingVisit(visitTM.dwp_kitv__visit_id__c, visitTM.dwp_kitv__user_id__c, 'Edit'));
		}
		system.debug('>>>>> listVisitSharing : ' + listVisitSharing);
		List<Database.SaveResult> listSR = Database.insert(listVisitSharing,false); 
		system.debug('>>>>> listSR : ' + listSR);   	
    }//FIN execute

    public void finish(Database.BatchableContext bc){    }
    
}