/**********************************************************************************
* @author  		VASS     
* @date         
* @description  Batch que genera todos los Apex Sharing para el equipo de cuenta de los objetos de oportunidad, el kit de visitas y las commercial alerts
* @Revision     
**********************************************************************************/
public without sharing class Batch_DeleteOppApexSharing implements Database.Batchable<Sobject>, Database.Stateful {
    private String pQuery = 'SELECT Id FROM OpportunityShare WHERE RowCause = \'Manual\'' + (Test.isRunningTest()?' LIMIT 1':'');
    
    public Batch_DeleteOppApexSharing(){
        system.debug('>>>>> pQuery : ' + pQuery);
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(pQuery);
    }
    
    
    public void execute(Database.BatchableContext bc,List<OpportunityShare> scope){
    	system.debug('>>>>> scope : ' + scope);
		delete scope;    	
    }//FIN execute

    public void finish(Database.BatchableContext bc){    }
    
}