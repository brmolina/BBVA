@isTest
public class MassiveBlockUnblockAPBatchTest {

@isTest
    public static void Method1() {
        Test.startTest();
        AP_notif__c obj=new AP_notif__c();
        obj.gf_admin_notif_lock_mgr_desc__c='An Account Planning where you are member has been locked!';
        obj.gf_admin_notif_unlock_mgr_desc__c='An Account Planning where you are member has been locked!';
        insert obj;
        List<User> lstU=[select id from User where isActive=true limit 10];
        Set<Id> userIdSet_blockUnblock=new Set<Id>();
        for(Integer i=0;i<lstU.size();i++) {
             userIdSet_blockUnblock.add(lstU[i].id);   
        }
        List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'MassiveBlockUnblockAPBatch' LIMIT 1]);
        MassiveBlockUnblockAPBatch massiveAPBatch = new MassiveBlockUnblockAPBatch();
         massiveAPBatch.BatchParameters(userIdSet_blockUnblock,true);
                    
        String idbatch=database.executebatch(massiveAPBatch,(Integer)batchParams[0].Batch_Size__c );

        System.assertNotEquals(idbatch, null);

        Test.stopTest();    
        
    }
    
}