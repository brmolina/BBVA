public with sharing class DES_cls_BotonNoteBookLm {

    @AuraEnabled
    public static void surveyNotification(String survey, String moduleName) {
        if (String.isBlank(survey)) {
            throw new AuraHandledException('Survey name is required.');
        }

        if (String.isBlank(moduleName)) {
            throw new AuraHandledException('Module name is required.');
        }

        DES_pe_SurveyNotification__e evt = buildSurveyEvent(survey, moduleName, UserInfo.getUserId());

        Database.SaveResult sr = EventBus.publish(evt);

        if (!sr.isSuccess()) {
            Database.Error err = sr.getErrors()[0];
            throw new AuraHandledException('Error publishing Platform Event: ' + err.getMessage());
        }
    }

    public static DES_pe_SurveyNotification__e buildSurveyEvent(String survey, String moduleName, String userIds) {
        return new DES_pe_SurveyNotification__e(
            DES_fld_Survey__c = survey,
            DES_fld_Modulo__c = moduleName,
            DES_fld_UserIds__c = userIds
        );
    }
}