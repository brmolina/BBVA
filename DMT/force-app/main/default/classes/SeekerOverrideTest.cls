/*
* Test para probar el funcionamiento de la clase seekerOverride
*/
@isTest
public class SeekerOverrideTest {
	/*
    * Test que prueba el met0d0 del lookup de las oportunidades
    */
    @isTest
    public static void seekTest() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    	List < String > lstMet;
    	lstMet = new List <String> ();
        final Account acc = utilClass.createClient();
        acc.DES_Structure_Type__c = 'Subsidiary';
        insert acc;
        Id [] searchRes= new Id[1];
        searchRes[0] = acc.Id;
        Test.setFixedSearchResults(searchRes);
        final sekr__Seeker_Config_Item__mdt metadata = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, sekr__Custom_Service_Class__c, sekr__Entity_Name__c, sekr__Icon__c, sekr__Primary_Field__c, sekr__Priority__c, sekr__RecordTypeName__c, sekr__Secondary_Fields__c, sekr__Seeker_Config__c, sekr__sObject_Name__c, sekr__Name_Field__c  FROM sekr__Seeker_Config_Item__mdt where QualifiedApiName = 'Accounts'];
        final List<sekr.Seeker_Result_Wrapper_Service> lista = seekerOverride.seek(metadata, 'Test', lstMet,1);
        System.assert(!lista.isEmpty(), 'Error no se ha devuelto ningún resultado');

    }
}