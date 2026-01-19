/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_CancelledArce_Batch_Test
* @Author   hectorjeshua.vasquez.contractor@bbva.com
* @Date     08/03/2024
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers: GDT_CancelledArce_Batch_Test
* -----------------------------------------------------------------------------------------------
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class GDT_CancelledArce_Batch_Test {
	/**
    * @description Creates mock data
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @Date 08/03/2024
    **/
    @TestSetup
    static void makeData() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        final arce__Analysis__c analisis1 = new arce__Analysis__c(
            Name = 'Analysis 1',
            arce__Stage__c = '3',
            arce__wf_status_id__c ='14',
            LastModifiedDate = Date.today().addDays(-16),
            CreatedDate = Date.today().addDays(-16),
            arce__proposeUser__c = UserInfo.getUserId()
        );
        insert analisis1;
        Test.setCreatedDate(analisis1.Id, DateTime.now().addDays(-16));
        final arce__Analysis__c analisis2 = new arce__Analysis__c(
            Name = 'Analysis 2',
            arce__Stage__c = '3',
            LastModifiedDate = Date.today().addDays(-16),
            CreatedDate = Date.today().addDays(-16),
            arce__wf_status_id__c ='14'
        );
        insert analisis2;
        Test.setCreatedDate(analisis2.Id, DateTime.now().addDays(-16));
        final arce__Account_has_Analysis__c aha1 = new arce__Account_has_Analysis__c(
            arce__Analysis__c = analisis1.Id,
            arce__IRP_Workflow__c = 'ARP'
        );
        insert aha1;
        final arce__Account_has_Analysis__c aha2 = new arce__Account_has_Analysis__c(
            arce__Analysis__c = analisis2.Id,
            arce__IRP_Workflow__c = 'ARP'
        );
        insert aha2;
        final arce__Traceability_Event__c trace = new arce__Traceability_Event__c();
        trace.arce__analysis_id__c = analisis2.Id;
        trace.arce__user_audit_id__c = UserInfo.getUserId();
        trace.arce__gc_trcblty_internal_code_id__c = '	T-0000000000-0';
        insert trace;
    }
    /**
    * @description GDT_CancelledArce_Batch method test for arce erase
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @Date 08/03/2024
    **/
    @isTest
    public static void testEraseArceCancel() {
        //final arce__Analysis__c analysis = [SELECT Id, arce__Stage__c FROM arce__Analysis__c WHERE arce__Stage__c = '3' LIMIT 1];
        Test.startTest();
        DataBase.executeBatch(new GDT_CancelledArce_Batch());
        Test.stopTest();
        List<arce__Analysis__c> actual = [SELECT Id, arce__Stage__c FROM arce__Analysis__c WHERE arce__Stage__c = '3' LIMIT 1];
        Assert.areEqual(actual.isEmpty(), actual.isEmpty());
    }

}