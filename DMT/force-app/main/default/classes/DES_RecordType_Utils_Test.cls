@IsTest
private class DES_RecordType_Utils_Test {

    @IsTest
    static void testGetRecordTypeId_InvalidInputs() {
        Test.startTest();
        System.assertEquals(null, DES_RecordType_Utils.getRecordTypeId(null, 'Business'));
        System.assertEquals(null, DES_RecordType_Utils.getRecordTypeId('', 'Business'));
        System.assertEquals(null, DES_RecordType_Utils.getRecordTypeId('Account', null));
        System.assertEquals(null, DES_RecordType_Utils.getRecordTypeId('Account', ''));
        System.assertEquals(null, DES_RecordType_Utils.getRecordTypeId('ObjetoInventado__c', 'Business'));
        Test.stopTest();
    }

    @IsTest
    static void testGetRecordTypeId_ValidAndCache() {
        // Usamos Account porque siempre existe en el org
        Map<String, Schema.RecordTypeInfo> rtInfos =
            Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        if (rtInfos == null || rtInfos.isEmpty()) {
            System.assert(true, 'No hay record types disponibles para Account en este org.');
            return;
        }

        String developerName = rtInfos.keySet().iterator().next();
        Id expectedRtId = rtInfos.get(developerName).getRecordTypeId();

        Test.startTest();
        Id result1 = DES_RecordType_Utils.getRecordTypeId('Account', developerName);
        Id result2 = DES_RecordType_Utils.getRecordTypeId('Account', developerName); // segunda llamada para caché
        Test.stopTest();

        System.assertEquals(expectedRtId, result1);
        System.assertEquals(expectedRtId, result2);
    }

    @IsTest
    static void testGetRecordTypeId_DeveloperNameNotFound() {
        Test.startTest();
        Id result = DES_RecordType_Utils.getRecordTypeId('Account', 'DeveloperName_Que_No_Existe');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @IsTest
    static void testFilter_NullAndEmptyList() {
        Test.startTest();
        List<SObject> resultNull = DES_RecordType_Utils.filter(null, 'Account', 'Business');
        List<SObject> resultEmpty = DES_RecordType_Utils.filter(new List<SObject>(), 'Account', 'Business');
        Test.stopTest();

        System.assertNotEquals(null, resultNull);
        System.assertEquals(0, resultNull.size());

        System.assertNotEquals(null, resultEmpty);
        System.assertEquals(0, resultEmpty.size());
    }

    @IsTest
    static void testFilter_RecordTypeNotFound() {
        List<SObject> records = new List<SObject>{
            new Account(Name = 'Cuenta 1'),
            new Account(Name = 'Cuenta 2')
        };

        Test.startTest();
        List<SObject> filtered = DES_RecordType_Utils.filter(records, 'Account', 'DeveloperName_Que_No_Existe');
        Test.stopTest();

        System.assertNotEquals(null, filtered);
        System.assertEquals(0, filtered.size());
    }

    @IsTest
    static void testFilter_ValidCase() {
        Map<String, Schema.RecordTypeInfo> rtInfos =
            Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        if (rtInfos == null || rtInfos.isEmpty()) {
            System.assert(true, 'No hay record types disponibles para Account en este org.');
            return;
        }

        String developerName = rtInfos.keySet().iterator().next();
        Id targetRtId = rtInfos.get(developerName).getRecordTypeId();

        Account acc1 = new Account(Name = 'Cuenta RT OK');
        acc1.put('RecordTypeId', targetRtId);

        Account acc2 = new Account(Name = 'Cuenta RT OK 2');
        acc2.put('RecordTypeId', targetRtId);

        Account acc3 = new Account(Name = 'Cuenta sin RT objetivo');

        List<SObject> records = new List<SObject>{ acc1, acc2, acc3 };

        Test.startTest();
        List<SObject> filtered = DES_RecordType_Utils.filter(records, 'Account', developerName);
        Test.stopTest();

        System.assertEquals(2, filtered.size());
        System.assertEquals(targetRtId, (Id)filtered[0].get('RecordTypeId'));
        System.assertEquals(targetRtId, (Id)filtered[1].get('RecordTypeId'));
    }
}