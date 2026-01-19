global class DES_Schedulable_SaveMatrixInGroup implements Schedulable{

    global void execute(SchedulableContext scMain){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_deleteGBMatrix(), 50000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);    
    }

}