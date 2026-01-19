@RestResource(urlMapping='/updateSanctionAMIWEB')
global with sharing class DMT_LaunchSanctionAMIWEB {
    
    @HttpGet
    global static Id runSanctionBatch(){
        Id batchInstanceId = Database.executeBatch(new DMT_BatchSanctionAMIWEB(), 200);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}