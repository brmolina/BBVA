/**
 * @Description Batch para testear el batch DES_Batch_UpdateDesktopOpportunities
 * @author Desktop
*/
@isTest
public class DES_Batch_UpdateDesktopOpportunitiesTest {
 	/*Creacion de datos y teste del batch*/
    @isTest
    static void updateDesktopOpportunitiesTest() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();    
        final Account acc = testClass.createClient();
        insert acc;
        final Opportunity opp = testClass.createOpportunity(acc);
        insert opp;
        Test.StartTest();
        final Id batchInstanceId = Database.executeBatch(new DES_Batch_UpdateDesktopOpportunities(), 1);
        Boolean response;
        response = batchInstanceId == null ? false : true;
        System.assert(response, 'Correcto');
        Test.StopTest();
    }
}