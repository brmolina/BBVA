/**
*
* @author Global Desktop
*/
@isTest
public class Batch_InvolvedAreas_Test {

    @isTest
    public static void involvedAreas(){
        //Datos necesarios
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        final String profileTest = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileTest);
        final User userTest2 = utilTestClass.createUser(profileTest);
        userTest2.username += 'M';
        userTest2.ID_User__c = userTest2.ID_User__c + 'T';
        userTest2.CommunityNickname = 'Test22';
        List <User> usersToInsert;
        usersToInsert = new List <User>();
        usersToInsert.add(userTest1);
        usersToInsert.add(userTest2);
        insert usersToInsert;

        final Account acc = utilTestClass.createClient();
        insert acc;

        final dwp_kitv__Visit__c visit = utilTestClass.createVisit(acc, null);
        insert visit;

        List <dwp_kitv__Visit_Management_Team__c> visitsMTToInsert;
        visitsMTToInsert = new List <dwp_kitv__Visit_Management_Team__c>();
        final dwp_kitv__Visit_Management_Team__c visitMT = utilTestClass.createVisitTM(userTest1, visit);
        final dwp_kitv__Visit_Management_Team__c visitMT2 = utilTestClass.createVisitTM(userTest2, visit);
        visitsMTToInsert.add(visitMT);
        visitsMTToInsert.add(visitMT2);
        insert visitsMTToInsert;

        system.runAs(userTest1){
            Test.startTest();
            Id batchInstanceId2 = Database.executeBatch(new Batch_InvolvedAreas(), 2000);
            system.debug('>>>>> id BATCH JO: ' + batchInstanceId2);
            system.assertNotEquals(batchInstanceId2, null, 'not null');
            Test.stopTest();
        }
    }
}