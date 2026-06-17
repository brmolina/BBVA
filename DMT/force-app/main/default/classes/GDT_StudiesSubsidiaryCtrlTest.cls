@IsTest
private class GDT_StudiesSubsidiaryCtrlTest {

    @IsTest
    static void testGetLocalClientId_Success() {

        // Client = Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Único Local Client relacionado
        Local_Client__c lc = new Local_Client__c(
            Name = 'Local Client 1',
            Cib_Client__c = acc.Id
            // Agrega aquí cualquier campo obligatorio si aplica
        );
        insert lc;

        Test.startTest();
        Id result = GDT_StudiesSubsidiaryCtrl.getLocalClientId(acc.Id);
        Test.stopTest();

        System.assertEquals(lc.Id, result,
            'Debe devolver el único Local Client relacionado');
    }

    @IsTest
    static void testGetLocalClientId_NoLocalClient() {

        Account acc = new Account(Name = 'Account Without Local Client');
        insert acc;

        Test.startTest();
        Id result = GDT_StudiesSubsidiaryCtrl.getLocalClientId(acc.Id);
        Test.stopTest();

        System.assertEquals(null, result,
            'Debe devolver null si no existe Local Client');
    }

    @IsTest
    static void testGetLocalClientId_NullParam() {

        Test.startTest();
        Id result = GDT_StudiesSubsidiaryCtrl.getLocalClientId(null);
        Test.stopTest();

        System.assertEquals(null, result,
            'Debe devolver null si el parámetro es null');
    }
}