/**
*    -   Batch   -   ScheduleDeleteProspectsTest
*/
@isTest
public without sharing class ScheduleDeleteProspectsTest {
    /*
    * Test method
    */
    @isTest
    public static void deleteProspect() {
        String cib;
        String x1234;

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        cib = 'C';
        x1234 = '1234';

        final Account accProspectGrupo = utilClass.createClient();
        accProspectGrupo.CIB_Commercial_Prospect__c = 'CIB';
        accProspectGrupo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        insert accProspectGrupo;

        final Account accSub = utilClass.createClient();
        accSub.DES_BBVA_Segmentation__c = cib;
        accSub.DES_Structure_Type__c = 'Subsidiary';
        accSub.DES_Entity_Type__c = 'Subsidiary';
        accSub.Merge_Insert__c = true;
        accSub.DES_ID_Fiscal__c = x1234;
        accSub.old_participant_id__c = accProspectGrupo.id;
        insert accSub;

        Test.startTest();
        //final Id batchInstanceId2 = Database.executeBatch(new Batch_MergeProspects(), 1);
        String batchInstanceId2 = system.schedule('Test Check', '0 0 2 * * ?', new ScheduleDeleteProspects());
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId2);
        system.assertNotEquals(batchInstanceId2, null, 'not null');
        Test.stopTest();
        system.debug('accs -> ' + [SELECT Id, Name, RecordType.DeveloperName, DES_ID_Fiscal__c, DES_Main_Parent__r.Name from Account LIMIT 5]);
    }

}