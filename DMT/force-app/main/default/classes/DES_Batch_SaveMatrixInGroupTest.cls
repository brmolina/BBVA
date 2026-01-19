@isTest
private class DES_Batch_SaveMatrixInGroupTest{

    @isTest
    static void DES_Batch_SaveMatrixInGroupTest(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();  
        Id idGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Id idSubsidiaryRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        
        Account accGroup = testClass.createClient();
        accGroup.RecordTypeId = idGroupRT;
        accGroup.DES_Structure_Type__c = 'Group';
        accGroup.DES_BBVA_Segmentation__c = 'C';
        insert accGroup;
         
        Account accFilial = testClass.createClient();    
        accFilial.DES_Entity_Hierarchy__c = 'S';
        accFilial.DES_Main_Parent__c = accGroup.Id;
        accFilial.RecordTypeId = idSubsidiaryRT;
        insert accFilial;
        
         
    Test.startTest();
    String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_ParentField());
    System.assertNotEquals(jobId, null,'msg');
    Test.stopTest();  }

}