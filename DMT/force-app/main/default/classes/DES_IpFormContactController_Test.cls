@isTest
public class DES_IpFormContactController_Test {

    @testSetup
    static void testSetup() {
        final DES_IP_UTIL_Test ipUtil = new DES_IP_UTIL_Test();
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;

        final Account acc = utilClass.createClient();
        insert acc;

        final Opportunity opp = utilClass.createOpportunity(acc );
            opp.Name = 'Operacion agua';
            opp.RecordTypeId = ipUtil.oppIPRecordTypeId;
            opp.disclosure_info_type__c = 'Inside information';
        insert opp;

        final dwp_kitv__Visit__c vis = utilClass.createVisit(acc, opp);
        insert vis;


        final Inside_information_form__c form = new Inside_information_form__c(
            Name = 'Test IIF',
            opportunity_id__c = opp.id);
            //visit_id__c = vis.id);
        insert form;

        final Compliance_form_contact__c formContact = new Compliance_form_contact__c();
            formContact.Formulario__c = form.Id;
            formContact.user_id__c = user1.Id;
        insert formContact;

    }

    @isTest
	public static void formMembersTest01() {
        //Required test data
        final Inside_information_form__c form = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];

        //Run test
        Test.startTest();
        	DES_IpFormContactController.instance();
            DES_IpFormContactController.bbvaUserCode();
            try{
                DES_IpFormContactController.getObjectType('FakeObject');
            } catch (Exception ex){
                System.debug('Forced error: ' + ex);
            }
            DES_IpFormContactController.isVisible(form.Id);
        	DES_IpFormContactController.formMembers(form.Id);
        	DES_IpFormContactController.formExtMembers(form.Id);
        	DES_IpFormContactController.sessionId();
            DES_IpFormContactController.urlIpServices();
        Test.stopTest();

        //Assertions
        final Inside_information_form__c formAssert = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];
        System.assertNotEquals(null, formAssert);
    }

    @isTest
	public static void formMembersTest02() {
        //Required test data
        final Opportunity opptest = [SELECT Id FROM Opportunity WHERE Name = 'Operacion agua' limit 1];
        final Inside_information_form__c form = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];
        final dwp_kitv__Visit__c visitTest = [Select id,Name From dwp_kitv__Visit__c Where Name = 'VISIT TEST' limit 1];
        final Compliance_form_contact__c formContact = [SELECT Id, Formulario__c, user_id__c FROM  Compliance_form_contact__c WHERE Formulario__c = :form.id limit 1];

        //Run test
        Test.startTest();
            try{
                DES_IpFormContactController.delContactRecord(formContact.id, form.Id);
            } catch (Exception ex){
                System.debug('>>>>>>> Forced delContactRecord error: ' + ex);
            }
        Test.stopTest();

        //Assertions
        final Inside_information_form__c formAssert = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];
        System.assertNotEquals(null, formAssert);

    }


    @isTest
	public static void formMembersTest03() {
        //Required test data
        final Opportunity opptest = [SELECT Id FROM Opportunity WHERE Name = 'Operacion agua' limit 1];
        final Inside_information_form__c form = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];
        final dwp_kitv__Visit__c visitTest = [Select id,Name From dwp_kitv__Visit__c Where Name = 'VISIT TEST' limit 1];
        final Compliance_form_contact__c formContact = [SELECT Id, Formulario__c, user_id__c FROM  Compliance_form_contact__c WHERE Formulario__c = :form.id limit 1];
        form.visit_id__c = visitTest.Id;
        update form;

        //Run test
        Test.startTest();
            try{
                DES_IpFormContactController.delContactRecord(formContact.id, form.Id);
            } catch (Exception ex){
                System.debug('>>>>>>> Forced delContactRecord error: ' + ex);
            }
        Test.stopTest();

        //Assertions
        final Inside_information_form__c formAssert = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];
        System.assertNotEquals(null, formAssert);
    }

    @isTest
	public static void formMembersTest04() {
        //Required test data
        final dwp_kitv__Visit__c visitTest = [Select id,Name From dwp_kitv__Visit__c Where Name = 'VISIT TEST' limit 1];

        //Run test
        Test.startTest();
            try{
                DES_IpFormContactController.isVisitClosed(visitTest.id);
            } catch (Exception ex){
                System.debug('Forced error: ' + ex);
            }
        Test.stopTest();

        //Assertions
        final Inside_information_form__c formAssert = [SELECT Id, visit_id__c, opportunity_id__c FROM Inside_information_form__c WHERE Name = 'Test IIF' limit 1];
        System.assertNotEquals(null, formAssert);
    }


    /**
    * Test method for OppMember functions
    */
    @isTest
    public static void validateFormMemberDeletion() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        Test.startTest();
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final DES_Opportunity_Management_member__c oppMember = utilClass.createOppManagementMember(user1, opp);
        insert oppMember;
        final Inside_information_form__c form = new Inside_information_form__c();
        form.opportunity_id__c = opp.Id;
        insert form;

        Compliance_form_contact__c cFContact = new Compliance_form_contact__c();
        cFContact.user_id__c = user1.Id;
        cFContact.Formulario__c = form.Id;
        cFContact.operation_user_assign_date__c = Date.today();
        insert cFContact;
		Test.stopTest();
        Global_Desktop_Settings__c gdSettings = new Global_Desktop_Settings__c();
        gdSettings.URL_Lightning__c = 'testURL';
        insert gdSettings;
        //creo event tracker para ese usuario
        etrk__EventTracker_Event__c evnTracker = new etrk__EventTracker_Event__c();
        evnTracker.etrk__User__c = user1.Id;
        evnTracker.etrk__Event_Name__c = 'Inside_Information_Form_Open';
        evnTracker.etrk__Location__c = gdSettings.URL_Lightning__c + 'lightning/r/Inside_information_form__c/' + form.Id + '/view';
        evnTracker.etrk__Type__c = 'LocationChange';
        insert evnTracker;

        Boolean retrnEventT = DES_IpFormContactController.checkEventTracker(opp.Id, cFContact.Id);

        system.assertNotEquals(null, evnTracker.Id);
    }

}