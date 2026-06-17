@IsTest
private class DES_cls_BotonNoteBookLmTest {

    private static final String SURVEY_NAME = 'SupportWUT';
    private static final String MODULE_NAME = 'Deal Management';

    @IsTest
    static void surveyNotification_ok() {
        Test.startTest();
        DES_cls_BotonNoteBookLm.surveyNotification(SURVEY_NAME, MODULE_NAME);
        Test.stopTest();

        System.assert(true, 'The Platform Event should be published without exception.');
    }

    @IsTest
    static void surveyNotification_blankSurvey_throwsException() {
        Test.startTest();
        try {
            DES_cls_BotonNoteBookLm.surveyNotification('', MODULE_NAME);
            System.assert(false, 'An AuraHandledException was expected when survey is blank.');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void surveyNotification_blankModule_throwsException() {
        Test.startTest();
        try {
            DES_cls_BotonNoteBookLm.surveyNotification(SURVEY_NAME, '');
            System.assert(false, 'An AuraHandledException was expected when moduleName is blank.');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void surveyNotification_error_publicando_evento() {
        Schema.DescribeSObjectResult objDesc = DES_pe_SurveyNotification__e.SObjectType.getDescribe();
        Schema.SObjectField fld = objDesc.fields.getMap().get('DES_fld_Survey__c');

        System.assertNotEquals(null, fld, 'The field DES_fld_Survey__c was not found in the Platform Event.');

        Schema.DescribeFieldResult fldDesc = fld.getDescribe();
        Integer maxLen = fldDesc.getLength();

        String tooLong = 'A';
        while (tooLong.length() <= maxLen) {
            tooLong += tooLong; 
        }
        tooLong = tooLong.substring(0, maxLen + 1);

        Test.startTest();
        try {
            DES_cls_BotonNoteBookLm.surveyNotification(tooLong, MODULE_NAME);
            System.assert(false, 'An AuraHandledException was expected when the Platform Event publication failed.');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}