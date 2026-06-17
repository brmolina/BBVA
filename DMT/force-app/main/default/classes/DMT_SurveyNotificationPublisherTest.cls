@IsTest
private class DMT_SurveyNotificationPublisherTest {
    @IsTest
    static void publishSupportWutSurvey_ok() {
        Test.startTest();
        DMT_SurveyNotificationPublisher.publishSupportWutSurvey('Deal Management');
        Test.stopTest();

        System.assert(true, 'Platform Event published without exception');
    }

    @IsTest
    static void publishSupportWutSurvey_blankModule_throwsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            DMT_SurveyNotificationPublisher.publishSupportWutSurvey('');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Expected exception for blank module name');
    }

    @IsTest
    static void publishSupportWutSurvey_publishError_throwsException() {
        Boolean exceptionThrown = false;
        DMT_SurveyNotificationPublisher.forcePublishErrorForTest = true;

        Test.startTest();
        try {
            DMT_SurveyNotificationPublisher.publishSupportWutSurvey('Deal Management');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        DMT_SurveyNotificationPublisher.forcePublishErrorForTest = false;

        System.assertEquals(true, exceptionThrown, 'Expected exception when publish fails');
    }
}