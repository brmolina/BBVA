@isTest
private class DES_desactivateUsersTest {
    // Constantes reutilizables
    private static final String STANDARD_USER_PROFILE = 'Standard User';
    private static final String TIME_ZONE = 'America/Los_Angeles';
    private static final String LOCALE = 'en_US';
    private static final String EMAIL_ENCODING = 'UTF-8';
    private static Id standardUserProfileId;

    /*********************************************************************************************************
     * @name            setupTestData
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Configura los datos iniciales de prueba incluyendo la creación de usuarios.
     *********************************************************************************************************/
    @testSetup
    static void setupTestData() {

        standardUserProfileId = [SELECT Id
                                 FROM Profile
                                 WHERE Name = :STANDARD_USER_PROFILE
                                 LIMIT 1].Id;

        List<User> usersToInsert = new List<User>{ createTestUser('Mario', 'User1', 'mariouser1@example.com', 'user1Test18924'), createTestUser('Lucas', 'User2', 'lucasuser2@example.com', 'user2Test18924'), createTestUser('Maria', 'User3', 'mariauser3@example.com', 'user3Test18924') };

        insert usersToInsert;
    }

    /*********************************************************************************************************
     * @name            createTestUser
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Crea un usuario de prueba con los parámetros proporcionados.
     * @param           String firstName - Nombre del usuario.
     * @param           String lastName - Apellido del usuario.
     * @param           String email - Correo electrónico del usuario.
     * @param           String userId - Identificador único del usuario.
     * @return          User - El usuario creado.
     *********************************************************************************************************/
    private static User createTestUser(String firstName, String lastName, String email, String userId) {
        return new User(
            FirstName = firstName, 
            LastName = lastName, 
            Email = email, 
            Username = email, 
            Alias = firstName.substring(0, 1) + lastName, 
            TimeZoneSidKey = TIME_ZONE, 
            LocaleSidKey = LOCALE, 
            EmailEncodingKey = EMAIL_ENCODING, 
            ProfileId = standardUserProfileId, 
            ID_User__c = userId, 
            LanguageLocaleKey = LOCALE, 
            Dataloader_Profile_Name__c = 'BBVA Desktop Compliance', 
            Dataloader_Role_Name__c = 'ARCE'
        );
    }
    
    /*********************************************************************************************************
     * @name            testExecuteWithFilter
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Prueba la ejecución del método execute con un filtro específico para desactivar usuarios.
     *********************************************************************************************************/
    @isTest
    static void testExecuteWithFilter() {
        Test.startTest();
        DES_desactivateUsers.desactivateUsers('id_user__c = \'user3Test18924\'', 0);
        Test.stopTest();

        Assert.isTrue(validateUserStates(new Set<String>{ 'user2Test18924', 'user1Test18924' }, 'user3Test18924'));
    }

    /*********************************************************************************************************
     * @name            testExecuteWithFilterAndLimit
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Prueba la ejecución del método execute con un filtro y un límite para desactivar usuarios.
     *********************************************************************************************************/
    @isTest
    static void testExecuteWithFilterAndLimit() {
        Test.startTest();
        DES_desactivateUsers.desactivateUsers('id_user__c = \'user3Test18924\'', 3);
        Test.stopTest();

        Assert.isTrue(validateUserStates(new Set<String>{ 'user2Test18924', 'user1Test18924' }, 'user3Test18924'));
    }

    /*********************************************************************************************************
     * @name            validateUserStates
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Valida los estados de los usuarios tras la ejecución del método de desactivación.
     * @param           Set<String> activeUserIds - Conjunto de IDs de usuarios que deben permanecer activos.
     * @param           String deactivatedUserId - ID del usuario que debe estar desactivado.
     *********************************************************************************************************/
    private static Boolean validateUserStates(Set<String> activeUserIds, String deactivatedUserId) {
        List<User> activeUsers = [SELECT Id, ID_User__c, ProfileId, IsActive
                                  FROM User
                                  WHERE IsActive = true AND ID_User__c IN:activeUserIds];

        User deactivatedUser = [SELECT Id, ID_User__c, ProfileId, IsActive
                                FROM User
                                WHERE IsActive = false AND ID_User__c = :deactivatedUserId
                                LIMIT 1];
        Assert.isFalse(activeUsers.isEmpty(), 'Active users should not be empty.');
        Assert.isNotNull(deactivatedUser.Id, 'Deactivated user should not be null.');
        return true;
    }

}