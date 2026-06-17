@IsTest
public class ONB_createGestorasControllerTest {

    static final String ONB_ACTIVITY_FUND = System.Label.ONB_ACTIVITY_FUND;
    static final String ONB_ACTIVITY_ASSET_MANAGER = System.Label.ONB_ACTIVITY_ASSET_MANAGER;
    static final String ONB_NEW_CLIENT_ONB_RTNAME = System.Label.ONB_NEW_CLIENT_ONB_RTNAME;

    @testSetup
    static void setupData() {

        Id rtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = :ONB_NEW_CLIENT_ONB_RTNAME
            LIMIT 1
        ].Id;

        // Contrato Marco
        Contrato_Marco__c contrato = new Contrato_Marco__c(
            Name = 'Contrato Test'
        );
        insert contrato;

        Account parent = new Account(Name = 'Parent AM');
        insert parent;
        
        Account a = new Account(Name = 'Gestora 1', SER_CNAE__c  = '', DES_Activity__c = ONB_ACTIVITY_ASSET_MANAGER);
        insert a;
        
        Account a1 = new Account(Name = 'Gestora 2', SER_CNAE__c  = ONB_ACTIVITY_ASSET_MANAGER, DES_Activity__c = ONB_ACTIVITY_ASSET_MANAGER);
        insert a1;

        Account gestora2 = new Account(
            Name = 'Gestora 2',
            RecordTypeId = rtId,
            ParentId = parent.Id,
            DES_Activity__c = ONB_ACTIVITY_ASSET_MANAGER
        );

        insert gestora2;

        // Relaciones Gestora–Contrato
        insert new List<ONB_Master_Agreement__c>{
            new ONB_Master_Agreement__c(
                ONB_Contrato__c = contrato.Id,
                ONB_Client__c   = a.Id
            ),
            new ONB_Master_Agreement__c(
                ONB_Contrato__c = contrato.Id,
                ONB_Client__c   = gestora2.Id
            )
        };

        // Fondos
        Account fondo1 = new Account(
            Name = 'Fondo 1',
            RecordTypeId = rtId,
            ParentId = a.Id,
            DES_Activity__c = ONB_ACTIVITY_FUND
        );

        Account fondo2 = new Account(
            Name = 'Fondo 2',
            RecordTypeId = rtId,
            ParentId = a.Id,
            DES_Activity__c = ONB_ACTIVITY_FUND
        );

        insert new List<Account>{ fondo1, fondo2 };

        // Fondo 1 ya vinculado al contrato
        insert new ONB_Master_Agreement__c(
            ONB_Contrato__c = contrato.Id,
            ONB_Client__c   = fondo1.Id
        );
    }

    @IsTest
    static void test_getGestorasByContrato() {
        Id contratoId = [SELECT Id FROM Contrato_Marco__c LIMIT 1].Id;

        Test.startTest();
        List<Account> gestoras =
            ONB_createGestorasController.getGestorasByContrato(contratoId);
        Test.stopTest();

        System.assertEquals(2, gestoras.size());
    }

    @IsTest
    static void test_createAccount_createsRel_whenAssetManager() {
        Id contratoId = [SELECT Id FROM Contrato_Marco__c LIMIT 1].Id;

        Account parent = new Account(Name = 'Parent Create');
        insert parent;

        Test.startTest();
        Account acc = ONB_createGestorasController.createAccount(
            contratoId,
            'Gestora Create',
            ONB_ACTIVITY_ASSET_MANAGER,
            parent.Id,
            '12345678901234567890',
            'STAR',
            'CC'
        );
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT()
             FROM ONB_Master_Agreement__c
             WHERE ONB_Contrato__c = :contratoId
             AND ONB_Client__c = :acc.Id]
        );
    }

    @IsTest
    static void test_asociarFondoGestoras_insertsRels() {
        Id contratoId = [SELECT Id FROM Contrato_Marco__c LIMIT 1].Id;
        Id gestoraId  = [
            SELECT Id
            FROM Account
            WHERE DES_Activity__c = :ONB_ACTIVITY_ASSET_MANAGER
            LIMIT 1
        ].Id;

        Account f1 = new Account(
            Name = 'Fondo A',
            ParentId = gestoraId,
            DES_Activity__c = ONB_ACTIVITY_FUND
        );
        Account f2 = new Account(
            Name = 'Fondo B',
            ParentId = gestoraId,
            DES_Activity__c = ONB_ACTIVITY_FUND
        );
        insert new List<Account>{ f1, f2 };

        Test.startTest();
        ONB_createGestorasController.asociarFondoGestoras(
            contratoId,
            new List<Id>{ f1.Id, f2.Id }
        );
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT()
             FROM ONB_Master_Agreement__c
             WHERE ONB_Contrato__c = :contratoId
             AND ONB_Client__c IN :new List<Id>{ f1.Id, f2.Id }]
        );
    }

    @IsTest
    static void test_getFondosByGestoras_excludesAlreadyLinked() {
        Id contratoId = [SELECT Id FROM Contrato_Marco__c LIMIT 1].Id;
        Id gestoraId  = [
            SELECT Id
            FROM Account
            WHERE DES_Activity__c = :ONB_ACTIVITY_ASSET_MANAGER
            LIMIT 1
        ].Id;

        Test.startTest();
        List<Account> fondos =
            ONB_createGestorasController.getFondosByGestoras(
                new List<Id>{ gestoraId },
                contratoId
            );
        Test.stopTest();

        System.assertEquals(1, fondos.size());
    }
}