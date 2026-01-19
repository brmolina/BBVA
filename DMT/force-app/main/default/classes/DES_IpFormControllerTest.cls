/**
*
* @author Global Desktop
*/
@isTest
private class DES_IpFormControllerTest { //NOSONAR
    @testSetup
    static void testSetup() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        user1.FederationIdentifier = 'test1234';
        insert user1;

        system.runAs(user1) {
            final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
            visit.visit_prvlg_participant_id__c = acc.Id;
            visit.visit_privileged_user_name__c = user1.Id;
            insert visit;
            final dwp_kitv__Visit_Management_Team__c visitMember = utilClass.createVisitManagementTeam(visit, user1);
            insert visitMember;
        }
    }

    @isTest
    static void testInstance() {
        final DES_IpFormController instance = DES_IpFormController.instance();
        system.assertNotEquals(null, instance);
    }

    @isTest
    static void testBBVAUserCode() {
        final User user1 = [SELECT Id,FederationIdentifier, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        String fedId;
        system.runAs(user1) {
            fedId = DES_IpFormController.bbvaUserCode();
        }

        system.assertEquals('test1234', fedId, 'fedId does not equal test1234');
    }

    @isTest
    static void getObjectType() {
        String fields = '';
        fields = DES_IpFormController.getObjectType('dwp_kitv__Visit__c');
        system.assertNotEquals('', fields,'fields');
    }

    @isTest
    static void testUrlIpServices() {
        final User user1 = [SELECT Id,Name, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        String url;
        system.runAs(user1) {
            url = DES_IpFormController.urlIpServices();
        }

        System.assertNotEquals(null, user1);
    }

    @isTest
    static void testComplianceQuestions() {
        final Map<String,String> mapComQues = DES_IpFormController.complianceQuestions();

        System.assertNotEquals(null, mapComQues);
    }

    @isTest
    static void testSaveFormulario() {
        Inside_information_form__c form = new Inside_information_form__c();
        insert form;
        form = DES_IpFormController.saveFormulario(form);

        System.assertNotEquals(null, form);
    }

    @isTest
    static void testGetOppId() {
        final Inside_information_form__c form = new Inside_information_form__c();
        insert form;
        final Id oppId = DES_IpFormController.getOppId(form.Id);

        System.assertEquals(null, oppId, 'oppId does not equal null');
    }

    @isTest
    static void testGetRecordTypeId() {
        final String rtId = DES_IpFormController.getRecordTypeId('Desktop_Form_Visit');

        System.assertNotEquals(null, rtId);
    }

    @isTest
    static void testGetIpSalesforceData() {
        final User user1 = [SELECT Id,Name, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        DES_IpFormController.IpSFData data;
        system.runAs(user1) {
            final Inside_information_form__c form = new Inside_information_form__c();
            insert form;
            final List<Compliance_form_contact__c> insiders = new List<Compliance_form_contact__c>();
            final Compliance_form_contact__c insiderBBVA = new Compliance_form_contact__c(Formulario__c = form.Id);
            insiderBBVA.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Form).getRecordTypeId();
            insiders.add(insiderBBVA);
            final Compliance_form_contact__c insiderExternal1 = new Compliance_form_contact__c(Formulario__c = form.Id);
            insiderExternal1.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
            insiders.add(insiderExternal1);
            final Compliance_form_contact__c insiderExternal2 = new Compliance_form_contact__c(Formulario__c = form.Id);
            insiderExternal2.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
            insiders.add(insiderExternal2);
            final Compliance_form_contact__c insiderExternal3 = new Compliance_form_contact__c(Formulario__c = form.Id);
            insiderExternal3.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
            insiders.add(insiderExternal3);
            final Compliance_form_contact__c insiderExternal4 = new Compliance_form_contact__c(Formulario__c = form.Id);
            insiderExternal4.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
            insiders.add(insiderExternal4);
            final Compliance_form_contact__c insiderExternal5 = new Compliance_form_contact__c(Formulario__c = form.Id);
            insiderExternal5.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
            insiders.add(insiderExternal5);
            insert insiders;

            data = DES_IpFormController.getIpSalesforceData(form.Id);
        }

        System.assertNotEquals(null, data);
    }

    @isTest
    static void testGetInsideFormData() {
        final Inside_information_form__c form = new Inside_information_form__c();
        insert form;
        final DES_IpFormController.InsideFormData formData = DES_IpFormController.getInsideFormData(form.Id);

        System.assertNotEquals(null, formData);
    }

    @isTest
    static void testIsCompliance() {
        final User user1 = [SELECT Id,Name, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        Boolean isCompliance;
        system.runAs(user1) {
            isCompliance = DES_IpFormController.isCompliance();
        }

        System.assert((false == isCompliance), 'isCompliance does not equal false');
    }

}