/**************************************************************************************************************
Name:            DES_Batch_firstUpdateRevenues
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            28/05/2019      Global Desktop    Schedulable que lanza el Batch DES_Batch_firstUpdateRevenues
**************************************************************************************************************/
global without sharing class DES_Schedulable_firstUpdateRevenues implements Schedulable{
	
	/*
    * @author Global Desktop
    * @description Methos que lanza el batch
    */
	global void execute(SchedulableContext scMain){
            Id batchInstanceId = Database.executeBatch(new DES_Batch_firstUpdateRevenues(), 2000);
            system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
	}
	
}