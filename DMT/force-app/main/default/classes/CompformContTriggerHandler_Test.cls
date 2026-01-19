/**
*
* @author Global Desktop
*/
@isTest
public class CompformContTriggerHandler_Test {
  /**
     * Test que crea una oportunidad, visita y formulario y actualiza esos registros por los datos obtenidos por parámetro
     * @param UpdateCountry: lista con los datos a actualizar
     *
     */
	@isTest
    public static void testNotDeleteOwner() {
		final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //Se introducen datos para inside_information_form__c y Compliance_form_contact__c para probar el borrado
        final inside_information_form__c inside = new Inside_information_form__c( Name = 'Test IIF',OwnerId=userTest.Id);
      	insert inside;
      	final Compliance_form_contact__c con = new Compliance_form_contact__c( Formulario__c= inside.Id,user_id__c=userTest.Id);
      	insert con;
        final List<Compliance_form_contact__c> linform = new List<Compliance_form_contact__c>([SELECT Id FROM Compliance_form_contact__c WHERE Formulario__c = :inside.Id]);
        Test.startTest();
        final Database.DeleteResult[] deleteResults = Database.delete(linform, false);
        Test.stopTest();
        for(Database.DeleteResult dr : deleteResults) {
            if (!dr.isSuccess()) {
                system.assert(!dr.isSuccess(), 'Shouldn\'t be deleted :( ' );
            }
        }
    }
}