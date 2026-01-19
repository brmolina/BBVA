global class DES_Schedulable_AllWeeksAccAlert implements Schedulable{

     global void execute(SchedulableContext scMain){
        //Account Renewal Date
        system.debug('>>>>> Inicio Batch Account Renewal Date');
        Id batchInstanceId_2 = Database.executeBatch(new DES_AccountRenewalDateAlertBatch(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId_2);       
     }


}