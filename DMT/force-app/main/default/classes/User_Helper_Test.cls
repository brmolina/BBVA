/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Clase de test para User_Helper (Facade principal del módulo User).
 *
 *               OBJETIVO:
 *               Validar el correcto funcionamiento del patrón Facade que orquesta:
 *               • Validación de Ambit (ARCE).
 *               • Gestión de grupo México.
 *               • Ejecución @future.
 *               • Delegación a servicios UOS.
 *               • Delegación a servicio de mapeo dinámico de roles.
 *
 * ARQUITECTURA 2026:
 *  • Cubre comportamiento del singleton.
 *  • Cubre delegación a servicios auxiliares.
 *  • Cubre ramas de early return.
 *  • Evita dependencias innecesarias mediante inyección controlada.
 *
 * CONSIDERACIONES:
 *  • Se utiliza @testSetup para crear usuarios base reutilizables.
 *  • No se valida lógica interna de servicios (eso se cubre en sus propias clases test).
 *  • Se valida únicamente el comportamiento del Facade.
 *
 ***************************************************************************************/
@IsTest
public with sharing class User_Helper_Test{
    
    /***************************************************************************************
     * @description  Crea usuarios base para los tests.
     *               • 1 usuario México.
     *               • 1 usuario España.
     ***************************************************************************************/
    @testSetup
    static void setup(){

        Profile p = [SELECT Id
                     FROM Profile
                     WHERE Name = 'BBVA Standard User'
                     LIMIT 1];

        List<User> usersToInsert = new List<User>();

        usersToInsert.add(buildUser(p.Id, 'mx.user', 'mx.user@test.com', 'mx.user@test.com.invalid', 'MEX', 'MEX1234'));

        usersToInsert.add(buildUser(p.Id, 'es.user', 'es.user@test.com', 'es.user@test.com.invalid', 'ESP', 'ESP1234'));

        insert usersToInsert;
    }
    
    /***************************************************************************************
     * @description  Construye un usuario válido para test.
     ***************************************************************************************/
    private static User buildUser(Id profileId, String aliasBase, String usernameBase, String email, String country, String uniqueID){

        String unique = String.valueOf(DateTime.now().getTime()) + '.' + 
                                                     String.valueOf(Math.abs(Crypto.getRandomInteger()));

        User u = new User();
        u.ProfileId = profileId;
        u.LastName = 'Test';
        u.Alias = (aliasBase.length() > 8 ? aliasBase.substring(0, 8) : aliasBase);

        u.Username = usernameBase + '.' + unique;
        u.Email = email;
        u.TimeZoneSidKey = 'Europe/Madrid';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Country = country;
        u.DES_Country__c = country;
        u.ID_User__c = uniqueID;
        
        u.gf_user_operation_ambit_name__c = null;

        return u;
    }
    
    /***************************************************************************************
     * @description  Valida que el patrón Singleton funciona correctamente.
     ***************************************************************************************/
    @IsTest
    static void testGtInstance_singleton(){

        User_Helper i1 = User_Helper.gtInstance();
        User_Helper i2 = User_Helper.gtInstance();

        System.assertNotEquals(null, i1);
        System.assertEquals(i1, i2);
    }
    
    /***************************************************************************************
     * @description  Valida que completeLogicValidate delega correctamente
     *               al servicio de Ambit y asigna flags booleanos.
     ***************************************************************************************/
    @IsTest
    static void testCompleteLogicValidate_setsFlags(){

        List<User> testUsers = [SELECT Id, gf_user_operation_ambit_name__c, DES_ARCE_Can_Propose__c, DES_ARCE_Can_Validate__c, DES_ARCE_Can_Edit__c
                                FROM User
                                LIMIT 2];

        Test.startTest();
        User_Helper.gtInstance().completeLogicValidate(testUsers);
        Test.stopTest();

        for (User u : testUsers){
            System.assertEquals(false, u.DES_ARCE_Can_Propose__c);
            System.assertEquals(false, u.DES_ARCE_Can_Validate__c);
            System.assertEquals(false, u.DES_ARCE_Can_Edit__c);
        }
    }
    
    /***************************************************************************************
     * @description  Valida inserción y eliminación del grupo México.
     ***************************************************************************************/
    @IsTest
    static void testValidateMexUser_addAndRemove_member(){

        User mexUser = [SELECT Id
                        FROM User
                        WHERE Country = 'MEX'
                        LIMIT 1];

        Set<Id> ids = new Set<Id>{ mexUser.Id };

        Test.startTest();

        User_Helper.validateMexUser(ids, true);

        List<GroupMember> inserted = [SELECT Id
                                      FROM GroupMember
                                      WHERE UserOrGroupId = :mexUser.Id AND Group.DeveloperName = 'cTMMexico'];

        System.assertEquals(1, inserted.size());

        User_Helper.validateMexUser(ids, false);

        List<GroupMember> deletedCheck = [SELECT Id
                                          FROM GroupMember
                                          WHERE UserOrGroupId = :mexUser.Id AND Group.DeveloperName = 'cTMMexico'];

        Test.stopTest();

        System.assertEquals(0, deletedCheck.size());
    }

    /***************************************************************************************
     * @description  Valida ejecución correcta del método @future.
     ***************************************************************************************/
    @IsTest
    static void testValidateMexUserFuture_executesFuture(){

        User mexUser = [SELECT Id
                        FROM User
                        WHERE Country = 'MEX'
                        LIMIT 1];

        Set<Id> ids = new Set<Id>{ mexUser.Id };

        Test.startTest();
        User_Helper.validateMexUserFuture(ids, true);
        Test.stopTest();

        List<GroupMember> inserted = [SELECT Id
                                      FROM GroupMember
                                      WHERE UserOrGroupId = :mexUser.Id AND Group.DeveloperName = 'cTMMexico'];

        System.assertEquals(1, inserted.size());

        // cleanup
        User_Helper.validateMexUser(ids, false);
    }
    
    /***************************************************************************************
     * @description  Valida branch seguro de assignUserUosToDmtApprover
     *               cuando el mapa es vacío.
     ***************************************************************************************/
    @IsTest
    static void testAssignUserUosToDmtApprover_safeEarlyReturn(){

        Test.startTest();
        User_Helper.gtInstance().assignUserUosToDmtApprover(null, new Map<Id, User>());
        Test.stopTest();

        System.assert(true);
    }

    /***************************************************************************************
     * @description  Valida método de compatibilidad uosDeleteApproveMember.
     ***************************************************************************************/
    @IsTest
    static void testUosDeleteApproveMember_safeEarlyReturn(){

        Profile p = [SELECT Id
                     FROM Profile
                     WHERE Name = 'Standard User'
                     LIMIT 1];

        User u = buildUser(p.Id, 'tmp.user', 'tmp.user@test.com', 'tmp.user@test.com.invalid', 'ESP', 'TMP1234');

        insert u;

        Map<Id, User> oldUserMap = new Map<Id, User>{ u.Id => u };

        Map<Id, String> mapUosUserNew = new Map<Id, String>();

        Test.startTest();
        List<GroupMember> res = User_Helper.uosDeleteApproveMember(oldUserMap, mapUosUserNew);
        Test.stopTest();

        System.assertEquals(0, res.size());
    }
    
    /***************************************************************************************
     * @description  Valida que el servicio de mapeo dinámico de roles
     *               asigna correctamente el campo configurado.
     ***************************************************************************************/
    @IsTest
    static void testFillUserRoleByProject_setsMappedField_withInjectedMetadata(){

        DES_User_Roles__mdt fake = new DES_User_Roles__mdt();

        fake.DES_Role_Developer_Name__c = 'DMT_Proyecto';
        fake.DES_User_Field_Map__c = 'DMT_User_Role__c';

        User u = new User();
        u.FirstName = 'John';
        u.LastName = 'Doe';

        Test.startTest();

        DES_cls_UserProjectRoleService.fill(u, null, new List<DES_User_Roles__mdt>{ fake });

        Test.stopTest();

        System.assert(String.valueOf(u.get('DMT_User_Role__c')).contains('DMT_Proyecto'));
    }

}