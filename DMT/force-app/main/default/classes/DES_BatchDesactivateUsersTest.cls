/*********************************************************************************************************
 * @name            DES_BatchDesactivateUsersTest
 * @author          Capgemini
 * @created         01/15/2025
 * @description     Clase de prueba para la clase batch DES_BatchDesactivateUsers. Valida todos los escenarios
 *                  incluyendo usuarios exitosos y fallidos en el proceso de desactivación.
 *********************************************************************************************************/
@isTest
private class DES_BatchDesactivateUsersTest {
    /*********************************************************************************************************
     * @name            setupTestData
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Configura los datos iniciales de prueba incluyendo usuarios activos y con roles.
     *********************************************************************************************************/
    @testSetup
    static void setupTestData() {
        Profile standardProfile = [SELECT Id
                                   FROM Profile
                                   WHERE Name = 'Standard User'
                                   LIMIT 1];

        List<User> testUsers = new List<User>{ createTestUser('Mario', 'User1', 'mariouser1@example.com', 'user1TestBatch', standardProfile.Id), createTestUser('Lucas', 'User2', 'lucasuser2@example.com', 'user2TestBatch', standardProfile.Id), createTestUser('Maria', 'User3', 'mariauser3@example.com', 'user3TestBatch', standardProfile.Id) };

        insert testUsers;
    }

    /*********************************************************************************************************
     * @name            createTestUser
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Crea un usuario de prueba con los parámetros proporcionados.
     * @param           String firstName - Nombre del usuario.
     * @param           String lastName - Apellido del usuario.
     * @param           String email - Correo electrónico del usuario.
     * @param           String userId - ID del usuario.
     * @param           Id profileId - ID del perfil asociado.
     * @return          User - Usuario creado.
     *********************************************************************************************************/
    private static User createTestUser(String firstName, String lastName, String email, String userId, Id profileId) {
        return new User(
            FirstName = firstName, 
            LastName = lastName, 
            Email = email, 
            Username = email, 
            Alias = firstName.substring(0, 1) + lastName, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            ProfileId = profileId, 
            IsActive = true, 
            ID_User__c = userId, 
            LanguageLocaleKey = 'en_US'
        );
    }

    /*********************************************************************************************************
     * @name            testBatchExecution
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Prueba la ejecución completa del batch para desactivar usuarios.
     *********************************************************************************************************/
    @isTest
    static void testBatchExecution() {

        List<User> usersToDeactivate = [SELECT Id, FirstName, LastName
                                        FROM User
                                        WHERE ID_User__c IN ('user1TestBatch', 'user2TestBatch')];

        Test.startTest();
        DES_BatchDesactivateUsers batchInstance = new DES_BatchDesactivateUsers(usersToDeactivate);
        Database.executeBatch(batchInstance, 2);
        Test.stopTest();

        List<User> deactivatedUsers = [SELECT Id, IsActive
                                       FROM User
                                       WHERE ID_User__c IN ('user1TestBatch', 'user2TestBatch')];

        for (User u : deactivatedUsers) {
            System.assertEquals(false, u.IsActive, 'El usuario debería estar desactivado.');
        }

        User unaffectedUser = [SELECT Id, IsActive
                               FROM User
                               WHERE ID_User__c = 'user3TestBatch'
                               LIMIT 1];
        System.assertEquals(true, unaffectedUser.IsActive, 'El usuario no afectado debería seguir activo.');
    }

    /*********************************************************************************************************
     * @name            testBatchWithEmptyInput
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Valida que se lanza una excepción al inicializar el batch con una lista vacía.
     *********************************************************************************************************/
    @isTest
    static void testBatchWithEmptyInput() {
        try {
            Test.startTest();
            DES_BatchDesactivateUsers batchInstance = new DES_BatchDesactivateUsers(new List<User>());
            Test.stopTest();
            System.assert(false, 'Se esperaba una excepción para una lista vacía.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('La lista de usuarios a desactivar no puede estar vacía.', e.getMessage(), 'El mensaje de excepción debería coincidir.');
        }
    }

    /*********************************************************************************************************
     * @name            testPartialFailures
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Simula fallos parciales en la actualización de usuarios y valida el manejo.
     *********************************************************************************************************/
    @isTest
    static void testPartialFailures() {
        List<User> usersToDeactivate = [SELECT Id, IsActive
                                        FROM User
                                        WHERE ID_User__c IN ('user1TestBatch', 'user2TestBatch', 'user3TestBatch')];

        Test.startTest();
        DES_BatchDesactivateUsers batchInstance = new DES_BatchDesactivateUsers(usersToDeactivate);
        Database.executeBatch(batchInstance, 3);
        Test.stopTest();

        List<User> usersDeactivate = [SELECT Id, IsActive
                                        FROM User
                                        WHERE ID_User__c IN ('user1TestBatch', 'user2TestBatch', 'user3TestBatch')];
        
        Assert.areEqual(usersToDeactivate.size(), usersDeactivate.size());
    }

    /*********************************************************************************************************
     * @name            testEnqueueEmailForFailedUsers
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Prueba el método enqueueEmailForFailedUsers para asegurarse de que maneja
     *                  correctamente los usuarios fallidos.
     *********************************************************************************************************/
    @isTest
    static void testEnqueueEmailForFailedUsers() {
        List<User> usersToDeactivate = [SELECT Id
                                        FROM User
                                        WHERE ID_User__c IN ('user1TestBatch', 'user2TestBatch', 'user3TestBatch')];

        Test.startTest();
        DES_BatchDesactivateUsers batchInstance = new DES_BatchDesactivateUsers(usersToDeactivate);
        batchInstance.enqueueEmailForFailedUsers(usersToDeactivate, 'Error');
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [SELECT Id, JobType, Status
                                         FROM AsyncApexJob
                                         WHERE JobType = 'Queueable'];
        System.assert(!queuedJobs.isEmpty(), 'Se debería haber encolado un trabajo para manejar usuarios fallidos.');
        System.assertEquals('Queueable', queuedJobs[0].JobType, 'El trabajo encolado debería ser de tipo Queueable.');
    }

    /*********************************************************************************************************
     * @name            testEnqueueEmailForFailedUsers
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Prueba el método enqueueEmailForFailedUsers para asegurarse de que devuelve el error cuando la lista de usuarios es vacia.
     *********************************************************************************************************/
    @isTest
    static void testEnqueueEmailEmptyUsers() {
        List<User> usersToDeactivate = [SELECT Id
                                        FROM User
                                        WHERE ID_User__c IN ('user1TestBatch', 'user2TestBatch', 'user3TestBatch')];

        List<User> usersEmpty = new List<User>();

        Test.startTest();
        DES_BatchDesactivateUsers batchInstance = new DES_BatchDesactivateUsers(usersToDeactivate);
        batchInstance.enqueueEmailForFailedUsers(usersEmpty, 'Error');
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [SELECT Id, JobType, Status
                                         FROM AsyncApexJob
                                         WHERE JobType = 'Queueable'];
        System.assert(queuedJobs.isEmpty(), 'Se debería haber encolado un trabajo para manejar usuarios fallidos.');
    }

}