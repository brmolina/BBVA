/*
* Web Service for Batch_deleteBBVAMembers
*/
@RestResource(urlMapping='/deleteBBVAClientMembers')
global with sharing class DES_WS_DeleteBBVAMembers {

    /*
    * SINGLETON PATTERN
    */
    private static DES_WS_DeleteBBVAMembers instance;

    /*
    * Constructor
    */
    private DES_WS_DeleteBBVAMembers() {
    }

    /*
    * getInstance
    */
    public static DES_WS_DeleteBBVAMembers gtInstance() {//NOSONAR
    if (instance == null) {
        instance = new DES_WS_DeleteBBVAMembers();
    }
    return instance;
    }

    /*
    * Method get to execute batch
    */
    @HttpGet
    global static Id runDeleteMembersBatch() {
        //final Id batchInstanceId = Database.executeBatch(new Batch_deleteBBVAMembers(), 1);
        final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_DelBBVATeam' LIMIT 1]);
        final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue()); //NOSONAR
        final Id batchInstanceId = Database.executeBatch(new DES_Batch_EliminarBBVAMember(), batchSize);//NOSONAR
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}