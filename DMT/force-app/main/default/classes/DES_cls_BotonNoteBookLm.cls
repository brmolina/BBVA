public with sharing class DES_cls_BotonNoteBookLm {

    @AuraEnabled
    public static void surveyNotification(String survey, String moduleName) {
        if (String.isBlank(survey)) {
            throw new AuraHandledException('Survey name is required.');
        }

        if (String.isBlank(moduleName)) {
            throw new AuraHandledException('Module name is required.');
        }

        DES_pe_SurveyNotification__e evt = new DES_pe_SurveyNotification__e(
            DES_fld_Survey__c = survey,
            DES_fld_Modulo__c = moduleName
        );

        Database.SaveResult sr = EventBus.publish(evt);

        if (!sr.isSuccess()) {
            Database.Error err = sr.getErrors()[0];
            throw new AuraHandledException('Error publishing Platform Event: ' + err.getMessage());
        }
    }
}