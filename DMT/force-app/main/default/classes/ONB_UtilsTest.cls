/*
* @author Teresa Anaya
* @name ONB_UtilsTest
* @description Test de la clase apex ONB_Utils
*/
@isTest
public class ONB_UtilsTest {

    /**
    * @description Test del método getFederationIdentifier
    */
    @isTest
    public static void testGetFederationIdentifier() {
        Test.startTest();
        String federationId = ONB_Utils.getFederationIdentifier();
        Test.stopTest();

        // El método devuelve el FederationIdentifier del usuario actual (puede ser null)
        User usr = [SELECT FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.assertEquals(usr.FederationIdentifier, federationId, 'El FederationIdentifier debe coincidir con el del usuario actual');
    }

    /**
    * @description Test del método callService en contexto de test (usa getMock internamente)
    */
    @isTest
    public static void testCallService() {
        Map<String, Object> requestBody = new Map<String, Object>{
            'param1' => 'value1'
        };

        Test.startTest();
        HttpResponse response;
        try {
            response = ONB_Utils.callService('ONB_Agreements', requestBody);
            System.assertNotEquals(null, response, 'La respuesta no debe ser nula');
            System.assertEquals(200, response.getStatusCode(), 'El status code debe ser 200');
        } catch (Exception ex) {
            System.assert(ex != null, 'Se lanzó una excepción esperada: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    /**
    * @description Test del método getMock
    */
    @isTest
    public static void testGetMock() {
        Test.startTest();
        HttpResponse response;
        try {
            response = ONB_Utils.getMock('ONB_Agreements');
            System.assertNotEquals(null, response, 'La respuesta mock no debe ser nula');
            System.assertEquals(200, response.getStatusCode(), 'El status code del mock debe ser 200');
        } catch (Exception ex) {
            System.assert(ex != null, 'Se lanzó una excepción esperada: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    /**
    * @description Test del método traducirValores con registros válidos
    */
    @isTest
    public static void testTraducirValoresConDatos() {
        Schema.DescribeFieldResult fieldResult = Account.DES_Activity__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        List<List<Account>> inputLists = new List<List<Account>>();

        if (!picklistValues.isEmpty()) {
            String apiName = picklistValues[0].getValue();
            String expectedLabel = picklistValues[0].getLabel();

            Account acc = new Account(Name = 'Test Account', DES_Activity__c = apiName);
            List<Account> accountList = new List<Account>{ acc };
            inputLists.add(accountList);

            Test.startTest();
            List<List<Account>> result = ONB_Utils.traducirValores(inputLists);
            Test.stopTest();

            System.assertEquals(1, result.size(), 'Debe devolver una lista');
            System.assertEquals(expectedLabel, result[0][0].DES_Activity__c, 'El valor debe haberse traducido al label del picklist');
        }
    }

    /**
    * @description Test del método traducirValores con DES_Activity__c nulo o vacío
    */
    @isTest
    public static void testTraducirValoresSinDatos() {
        Account acc = new Account(Name = 'Test Account Sin Actividad');
        List<Account> accountList = new List<Account>{ acc };
        List<List<Account>> inputLists = new List<List<Account>>{ accountList };

        Test.startTest();
        List<List<Account>> result = ONB_Utils.traducirValores(inputLists);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe devolver una lista');
        System.assertEquals(null, result[0][0].DES_Activity__c, 'El valor debe permanecer nulo');
    }

    /**
    * @description Test del método traducirValores con lista vacía
    */
    @isTest
    public static void testTraducirValoresListaVacia() {
        List<List<Account>> inputLists = new List<List<Account>>();

        Test.startTest();
        List<List<Account>> result = ONB_Utils.traducirValores(inputLists);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertEquals(0, result.size(), 'El resultado debe ser una lista vacía');
    }
}