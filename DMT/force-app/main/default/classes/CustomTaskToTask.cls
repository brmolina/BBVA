/*-------------------------------------------------------------------------------------------------------------------------------------------------------
	    Author:        Brian Capilla
	    Company:       Accenture Cloud First
	    Description:   Batch para actualizar los Task normales y que dejen de apuntar a los custom (Activity__c).
	    				Este batch solo se debe lanzar para actualizar los WhatID de las Task/Event y luego no se va a volver a utilizar, podría comentarse todo el código.

	    
	    History: 
	    
	    <Date>				<Author>				<Change Description>
 	    20/10/2017			Brian Capilla			Initial Version
 	   14/11/2017			Javier SS				Se comenta el código porque ya no hace falta esta clase, para que no reste el coverage.
	    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
global class CustomTaskToTask {
}
/*	    
global class CustomTaskToTask implements Database.Batchable<sObject> {
	
	boolean isTest;
	String query;
	String leadIndex;
	String accountIndex;
	String campaignIndex;
	String contactIndex;
	String opportunityIndex;
	Map<String, Task> taskMap;
	Map<String, Event> eventMap;
	List<Activity__c> activList;
	Map<String, String> taskList;
	Map<String, String> eventList;
	Integer contacts;
	Integer leads;
	Integer opportunities;
	Integer campaigns;
	Integer accounts;
	
	global CustomTaskToTask(boolean isTest) {
		this.isTest = isTest;
		contacts = 0;
		leads = 0;
		opportunities = 0;
		campaigns = 0;
		accounts = 0;
		leadIndex = Utilities.getObjectPrefix('Lead');
		accountIndex = Utilities.getObjectPrefix('Account');
		campaignIndex = Utilities.getObjectPrefix('Campaign');
		contactIndex = Utilities.getObjectPrefix('Contact');
		opportunityIndex = Utilities.getObjectPrefix('Opportunity');
		System.debug('leadIndes: '+leadIndex+', accountIndex: '+accountIndex+', campaignIndex: '+campaignIndex+', contactIndex: '+contactIndex+', opportunityIndex: '+opportunityIndex);
		query = 'select Id, (select id from Tasks), (select id from Events), Name, Account__c, Campaign__c, Contact__c, Lead__c, Opportunity__c from Activity__c';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.debug('la query es: '+query);
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		try {
	   		System.debug(scope);
	   		System.debug('llegan '+scope.size()+' registros');

			activList = scope;
			taskMap = new Map<String, Task>();
			eventMap = new Map<String, Event>();
			taskList = new Map<String, String>();
			eventList = new Map<String, String>();
			for(Activity__c act : activList) {
				System.debug(act+' Events: '+act.Events.size()+', Tasks: '+act.Tasks.size());
			if(!act.Tasks.isEmpty() && act.Tasks[0].id != null) {
					Task tempTask;
					if(act.Account__c != null) {
						tempTask = new Task(id = act.Tasks[0].id, whatId = act.Account__c, whoId = null);
						taskMap.put(act.id, tempTask);
						accounts++;
					} else if(act.Campaign__c != null) {
						tempTask = new Task(id = act.Tasks[0].id, whatId = act.Campaign__c, whoId = null);
						taskMap.put(act.id, tempTask);
						campaigns++;
					} else if(act.Contact__c != null) {
						tempTask = new Task(id = act.Tasks[0].id, whoId = act.Contact__c, whatId = null);
						taskMap.put(act.id, tempTask);
						taskList.put(act.Contact__c, act.id);
						contacts++;
					} else if(act.Lead__c != null) {
						tempTask = new Task(id = act.Tasks[0].id, whoId = act.Lead__c, whatId = null);
						taskMap.put(act.id, tempTask);
						leads++;
					} else if(act.Opportunity__c != null) {
						tempTask = new Task(id = act.Tasks[0].id, whatId = act.Opportunity__c, whoId = null);
						taskMap.put(act.id, tempTask);
						opportunities++;
					}
				} else if (!act.Events.isEmpty() && act.Events[0].id != null) {
					Event tempEvent;
					if(act.Account__c != null) {
						tempEvent = new Event(id = act.Events[0].id, whatId = act.Account__c, whoId = null);
						eventMap.put(act.id, tempEvent);
						accounts++;
					} else if(act.Campaign__c != null) {
						tempEvent = new Event(id = act.Events[0].id, whatId = act.Campaign__c, whoId = null);
						eventMap.put(act.id, tempEvent);
						campaigns++;
					} else if(act.Contact__c != null) {
						tempEvent = new Event(id = act.Events[0].id, whoId = act.Contact__c, whatId = null);
						eventMap.put(act.id, tempEvent);
						eventList.put(act.Contact__c, act.id);
						contacts++;
					} else if(act.Lead__c != null) {
						tempEvent = new Event(id = act.Events[0].id, whoId = act.Lead__c, whatId = null);
						eventMap.put(act.id, tempEvent);
						leads++;
					} else if(act.Opportunity__c != null) {
						tempEvent = new Event(id = act.Events[0].id, whatId = act.Opportunity__c, whoId = null);
						eventMap.put(act.id, tempEvent);
						opportunities++;
					}
				}
			}

			if(taskList.size() != 0)
				for(Contact cont : [select id, AccountId from Contact where id in :taskList.keySet() and AccountId != null])
					taskMap.get(taskList.get(cont.id)).whatId = cont.AccountId;
			

			if(eventList.size() != 0)
				for(Contact cont : [select id, AccountId from Contact where id in :eventList.keySet() and AccountId != null])
					eventMap.get(eventList.get(cont.id)).whatId = cont.AccountId;
			
			System.debug('taskMap: '+taskMap.size()+' registros a actualizar');
			System.debug('eventMap: '+eventMap.size()+' registros a actualizar');

			System.debug(opportunities+' opportunities encontradas');
			System.debug(leads+' leads encontradas');
			System.debug(contacts+' contacts encontradas');
			System.debug(campaigns+' campaigns encontradas');
			System.debug(accounts+' accounts encontradas');
		
			if(!isTest) {
				update taskMap.values();
				update eventMap.values();
			}
		} catch (Exception ex) {
			System.debug(ex.getStackTraceString());
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		System.debug('terminado');
	}

}	
*/