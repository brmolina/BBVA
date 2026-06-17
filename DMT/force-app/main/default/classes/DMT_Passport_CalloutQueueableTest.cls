/** reupload */
@IsTest
private class DMT_Passport_CalloutQueueableTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test', DES_Group_Code__c = 'GXXXXXXXXXXXXXX');
        insert acc;

        DMT_Line__c line = new DMT_Line__c(
            Name = 'Test',
            Client__c = acc.Id
        );
        insert line;
    }

    @IsTest
    static void testQueueableWorks() {
        DMT_Line__c line = [SELECT Id, Client__c FROM DMT_Line__c LIMIT 1];

        // Mock simple
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
        System.enqueueJob(new DMT_Passport_CalloutQueueable(line.Id, line.Client__c));
        Test.stopTest();

        // Test pasa si no hay excepciones
        System.assert(true);
    }

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            return new HttpResponse();
        }
    }
}