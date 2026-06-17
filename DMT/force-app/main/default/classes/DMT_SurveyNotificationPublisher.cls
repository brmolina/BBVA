public with sharing class DMT_SurveyNotificationPublisher {
    @TestVisible
    private static Boolean forcePublishErrorForTest = false;

    @AuraEnabled
    public static void publishSupportWutSurvey(String moduleName) {
        if (String.isBlank(moduleName)) {
            throw new AuraHandledException('Module name is required.');
        }

        DES_pe_SurveyNotification__e surveyEvt = new DES_pe_SurveyNotification__e(
            DES_fld_Survey__c = 'SupportWUT',
            DES_fld_Modulo__c = moduleName
        );

        Database.SaveResult sr = EventBus.publish(surveyEvt);

        if (forcePublishErrorForTest || !sr.isSuccess()) {
            String errorMessage = 'Error publishing survey notification event';

            if (!sr.getErrors().isEmpty()) {
                errorMessage += ': ' + sr.getErrors()[0].getMessage();
            }

            throw new AuraHandledException(errorMessage);
        }
    }
}