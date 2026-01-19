/******************************************************************************************************************************************************************
Name:            DES_AccountRenewalDateAlertBatch
Description:     Clase Batch para lanzar semanalmente y que crear tasks de alerta en funcion del campo DES_PF_RENEWAL_DATE__c de Account
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
1.0            28/06/2018       JSS               Class creation    
2.0            20/07/2018       JSS               Se cambia la query (quitamos filtros de fecha en el where) porque la anterior daba error en PROD porque hay muchos registros: First error: [REQUEST_RUNNING_TOO_LONG] Your request was running for too long, and has been stopped.       
                                                  Ahora la comprobación para ver la fecha se realiza en el el FOR 
*******************************************************************************************************************************************************************/
public without sharing class DES_AccountRenewalDateAlertBatch implements Database.Batchable<Sobject>, Database.Stateful {
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer taskCreated = 0;
  private Date todayAdd60Days = date.today().addDays(60); //private String todayAdd60Days = String.valueOf(date.today().addDays(60));
  private Date todayAdd67Days = date.today().addDays(67); //private String todayAdd67Days = String.valueOf(date.today().addDays(67));  
  private String pQuery;  

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_AccountRenewalDateAlertBatch(){  		
  	//pQuery = 'SELECT Id,Name,DES_PF_RENEWAL_DATE__c, DES_Global_Banker_Ref__r.DES_User__c FROM Account Where DES_PF_RENEWAL_DATE__c >= ' + todayAdd60Days + ' AND DES_PF_RENEWAL_DATE__c < ' + todayAdd67Days;
    pQuery = 'SELECT Id,Name,DES_PF_RENEWAL_DATE__c, DES_Global_Banker_Ref__r.DES_User__c FROM Account Where DES_PF_RENEWAL_DATE__c != null';
	//system.debug('XXXXXX pQuery: ' + pQuery);  	
  }


  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc){
    return Database.getQueryLocator(pQuery);
  }


  public  void execute(Database.BatchableContext bc,List<Account> scope){
	List<task> taskListScope = new List<task>();
	for(Account acc : scope){
		//system.debug('XXXXXX acc.DES_Global_Banker_Ref__c: ' + acc.DES_Global_Banker_Ref__c);  			
		//system.debug('XXXXXX acc.DES_Global_Banker_Ref__r.DES_User__c: ' + acc.DES_Global_Banker_Ref__r.DES_User__c);
		//if (acc.DES_Global_Banker_Ref__c != null && acc.DES_Global_Banker_Ref__r.DES_User__c != null){
    if (acc.DES_Global_Banker_Ref__c != null && acc.DES_Global_Banker_Ref__r.DES_User__c != null &&
        acc.DES_PF_RENEWAL_DATE__c >= todayAdd60Days && acc.DES_PF_RENEWAL_DATE__c < todayAdd67Days ){
			Task taskAux = new Task();
			taskAux.WhatId = acc.id;
			taskAux.OwnerId = acc.DES_Global_Banker_Ref__r.DES_User__c;
			taskAux.IsReminderSet = true;
			taskAux.ReminderDateTime = System.now().addMinutes(15);
			taskAux.Priority = 'Normal';
			taskAux.Subject = 'PF renewal date will be ' + acc.DES_PF_RENEWAL_DATE__c.day() + '/' + acc.DES_PF_RENEWAL_DATE__c.month() + '/' + acc.DES_PF_RENEWAL_DATE__c.year() + ' on client ' + acc.Name;
			taskAux.status = 'Not Started';
			taskListScope.add(taskAux);
			//system.debug('XXXXXX taskAux: ' + taskAux);			
		}
	}
	if (!taskListScope.isEmpty()){
		//system.debug('XXXXXX taskListScope: ' + taskListScope);
		insert taskListScope;
	}
  }

  public void finish(Database.BatchableContext bc){
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('SUMMARY: ');
    System.debug('  Tasks Created: ' + taskCreated);
    System.debug('  Batches Created: ' + job.JobItemsProcessed);
    System.debug('  Number of Errors: ' + job.NumberOfErrors);
    System.debug('  Status: ' + job.Status);
  }

}