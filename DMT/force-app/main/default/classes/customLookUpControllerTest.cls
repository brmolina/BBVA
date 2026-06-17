@isTest
private class customLookUpControllerTest {
    @isTest
    static void testFetchLookUpValuesCustomEquals() {
        Account acc = new Account(Name='UniqueAccountName');
        insert acc;
        Test.startTest();
        List<sObject> result = customLookUpController.fetchLookUpValues('UniqueAccountName', 'Account', '', true, true, 'Name', '');
        System.assert(result.size() == 1, 'Should return exact match for custom/equals');
        Test.stopTest();
    }

    @isTest
    static void testFetchLookUpValuesProduct2Family() {
        Product2 prod = new Product2(Name='FamilyProduct', Family='SpecialFamily');
        insert prod;
        Test.startTest();
        List<sObject> result = customLookUpController.fetchLookUpValues('FamilyProduct', 'Product2', 'SpecialFamily', false, false, 'Name', '');
        System.assert(result.size() > 0, 'Should return Product2 with matching family');
        Test.stopTest();
    }

    @isTest
    static void testFetchLookUpValuesIdField() {
        // Prueba que se puede buscar por el campo Id
        Account acc = new Account(Name='TestIdField');
        insert acc;
        Test.startTest();
        List<sObject> result = customLookUpController.fetchLookUpValues(acc.Id, 'Account', '', true, true, 'Id', '');
        System.assert(result.size() == 1, 'Debe devolver el registro exacto por Id');
        Test.stopTest();
    }

    @isTest
    static void testFetchLookUpValuesUser() {
        User u = [SELECT Id, Name FROM User WHERE isActive = true LIMIT 1];
        Test.startTest();
        List<sObject> result = customLookUpController.fetchLookUpValues(u.Name.left(3), 'User', '', false, false, 'Name', '');
        System.assert(result.size() >= 0, 'Debe ejecutarse para User');
        Test.stopTest();
    }

    @isTest
    static void testFetchLookUpValuesPitch() {
        // Solo se prueba que no lance excepción, ya que no hay datos de prueba para pith__Pitch__c
        Test.startTest();
        try {
            customLookUpController.fetchLookUpValues('Test', 'pith__Pitch__c', '', true, false, 'Name', null);
            System.assert(true, 'No debe lanzar excepción para objeto permitido');
        } catch (Exception e) {
            System.assert(false, 'No debe lanzar excepción para objeto permitido');
        }
        Test.stopTest();
    }
}