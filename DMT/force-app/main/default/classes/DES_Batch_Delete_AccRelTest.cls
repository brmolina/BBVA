@isTest
private class DES_Batch_Delete_AccRelTest{
    // 1. MODO ESTÁNDAR
    @isTest
    static void testStandardMode(){
        User userTest = setupTestData();

        system.runAs(userTest){
            Test.startTest();
            Database.executeBatch(new DES_Batch_Delete_AccRel(), 200);
            Test.stopTest();

            Integer remainingRecords = [SELECT count() FROM AMH_GBL_Account_Relationship__c];
            Id rtNIF = getRtNif();

            if(rtNIF != null) {
                System.assertEquals(2, remainingRecords, 'Fallo modo Estándar: Deberían sobrevivir la Contrapartida y el NIF.');
            } else {
                System.assertEquals(1, remainingRecords, 'Fallo modo Estándar: Debería sobrevivir solo la Contrapartida.');
            }
        }
    }

    // 2. MODO CONTRAPARTIDAS
    @isTest
    static void testCounterpartiesMode(){
        User userTest = setupTestData();

        system.runAs(userTest){
            Test.startTest();
            Database.executeBatch(new DES_Batch_Delete_AccRel('COUNTERPARTIES'), 200);
            Test.stopTest();

            Integer remainingRecords = [SELECT count() FROM AMH_GBL_Account_Relationship__c];
            Id rtNIF = getRtNif();

            if(rtNIF != null) {
                System.assertEquals(2, remainingRecords, 'Fallo modo Contrapartida: Deberían sobrevivir la relación Estándar y el NIF.');
            } else {
                System.assertEquals(2, remainingRecords, 'Fallo modo Contrapartida: Deberían sobrevivir las 2 relaciones estándar.');
            }
        }
    }

    // ============================================================================
    // HELPER METHODS
    // ============================================================================

    // Creación de datos
    private static User setupTestData() {
        DES_UtilTestClass testClass = new DES_UtilTestClass();

        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;

        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest){
            Id rtNIF = getRtNif();

            List<Account> listaAcc = new List<Account>();
            Account padre = testClass.createClient();
            listaAcc.add(padre);
            Account hijo = testClass.createClient();
            listaAcc.add(hijo);
            Account hijoNIF = testClass.createClient();
            if(rtNIF != null) {
                hijoNIF.RecordTypeId = rtNIF;
            }
            listaAcc.add(hijoNIF);
            insert listaAcc;

            List<AMH_GBL_Account_Relationship__c> listaAccRel = new List<AMH_GBL_Account_Relationship__c>();

            // Relación 1: Estándar
            AMH_GBL_Account_Relationship__c accRel = testClass.createAccRelationship(padre, hijo);
            listaAccRel.add(accRel);

            // Relación 2: Contrapartida
            AMH_GBL_Account_Relationship__c accRelContrapartida = testClass.createAccRelationship(padre, hijo);
            accRelContrapartida.AMH_Type__c = '04 - Contrapartida';
            listaAccRel.add(accRelContrapartida);

            // Relación 3: NIF
            AMH_GBL_Account_Relationship__c accRelNIF = testClass.createAccRelationship(padre, hijoNIF);
            listaAccRel.add(accRelNIF);

            insert listaAccRel;
        }

        return userTest;
    }

    // Devuelve el Id del RecordType NIF de forma segura
    private static Id getRtNif() {
        if(Schema.SObjectType.Account.getRecordTypeInfosByName().containsKey(System.Label.DES_STR_TYPE_NIF)){
            return Schema.SObjectType.Account.getRecordTypeInfosByName().get(System.Label.DES_STR_TYPE_NIF).getRecordTypeId();
        }
        return null;
    }

}