/**
*
* @author Global Desktop
*/
@isTest
public class InsideFormTriggerHandler_Test {
    /**
     * Test que crea un formulario, inserta los datos obtenidos por parámetro
     * @param UpdateCountry: lista con los datos a actualizar
     *
     */
	@isTest
    public static void inserOwner() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        // String ids= userTest.Id;
    	final inside_information_form__c inside = new Inside_information_form__c( Name = 'Test IIF',OwnerId=userTest.Id);
        Test.startTest();
        final Database.SaveResult result= Database.insert(inside,false);
        Test.stopTest();
        system.assertNotEquals(false,result.isSuccess(), 'Shouldn\'t be deleted :( ' );
    }
    /**
     *
     * @author Global Desktop
     */
    @isTest
    public static void changeContactsRT() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        // String ids= userTest.Id;
    	final inside_information_form__c inside = new Inside_information_form__c( Name = 'Test IIF',OwnerId=userTest.Id);
        system.debug(inside.Id);
        insert inside;
        Test.startTest();
        //Updates para los casos de Pending
        inside.status_type__c='Pending';
        update inside;
        final List<Compliance_form_contact__c> lstCntctRdOnlyQry = [Select Id, RecordTypeId from Compliance_form_contact__c where Formulario__c  =:inside.Id];
        Compliance_form_contact__c contactRead = lstCntctRdOnlyQry[0];
        contactRead.RecordTypeId=Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
        update contactRead;
        update inside;
        contactRead.RecordTypeId=Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Form).getRecordTypeId();
        update contactRead;
        update inside;
        //Updates para los casos de Rejected
        inside.status_type__c='Rejected';
        update inside;
        Compliance_form_contact__c contactRead2 = lstCntctRdOnlyQry[0];
        contactRead2.RecordTypeId=Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Read_Form).getRecordTypeId();
        update contactRead2;
        update inside;
        contactRead2.RecordTypeId=Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Read_Form).getRecordTypeId();
        update contactRead2;
        update inside;
        
        Test.stopTest();
        system.assertNotEquals(Null,inside.Id, 'Pass');
    }
}