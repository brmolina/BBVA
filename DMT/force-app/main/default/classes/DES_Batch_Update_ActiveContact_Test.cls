/*
* Test Class
*/
@isTest
public class DES_Batch_Update_ActiveContact_Test {

    /*
    * Test method for DES_Batch_Update_ActiveContact
    */
    @isTest
    public static void testBatch() {
        final RecordType rtype = [SELECT Id, DeveloperName from RecordType Where DeveloperName = 'Desktop_Contact' LIMIT 1];
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final Account acc = testClass.createClient();
        acc.DES_Country_Client__c = 'AR';
        insert acc;
        final Contact con = testClass.createContact(acc);
        con.role_status_contact_prtcpt_type__c = false;
        con.DES_Scope__c = 'AR';
        con.RecordTypeId = rtype.Id;
        insert con;
        final Id batchInstanceId = Database.executeBatch(new DES_Batch_Update_ActiveContact(), 1);
        final Contact con1 = [SELECT Id, role_status_contact_prtcpt_type__c, RecordType.developername from Contact Where id = :con.id limit 1];
        system.debug('con1.role_status_contact_prtcpt_type__c ' + con1.role_status_contact_prtcpt_type__c + ' ' + con.Recordtype.DeveloperName);
        system.assertNotEquals(batchInstanceId, null, 'msg');
    }
}