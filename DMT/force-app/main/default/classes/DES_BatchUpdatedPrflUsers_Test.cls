/*********************************************************************************************************
 * @name        DES_BatchUpdatedPrflUsers_Test
 * @author      Capgemini
 * @created     21/05/2025
 * @description Clase de prueba unitaria para la clase batch DES_BatchUpdatedPrflUsers. 
 *              Valida la ejecución del batch para la actualización de usuarios con FederationIdentifier 
 *              a través del handler DES_SamlJitHandler.
 *********************************************************************************************************/
@isTest 
public with sharing class DES_BatchUpdatedPrflUsers_Test {
    
    /*********************************************************************************************************
     * @name        createStandardUser
     * @author      Capgemini
     * @created     21/05/2025
     * @description Método helper privado que genera un usuario activo con el perfil 'Standard User'.
     * @param       firstName - Nombre del usuario.
     * @param       lastName - Apellido del usuario.
     * @param       email - Correo y username del usuario.
     * @param       alias - Alias único para el usuario.
     * @return      User - Instancia de usuario configurada pero no insertada.
     *********************************************************************************************************/
    private static User createStandardUser(String firstName, String lastName, String email, String alias) {
        Profile testProfile = [SELECT Id
                               FROM Profile
                               WHERE Name = 'Standard User'
                               LIMIT 1];
        return new User(
            FirstName = firstName, 
            LastName = lastName, 
            Email = email, 
            Username = email, 
            Alias = alias, 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'Europe/Paris', 
            LocaleSidKey = 'es_ES', 
            EmailEncodingKey = 'ISO-8859-1', 
            LanguageLocaleKey = 'en_US', 
            IsActive = true
        );
    }
    
    /*********************************************************************************************************
     * @name        testDES_BatchUpdatedPrflUsers
     * @author      Capgemini
     * @created     21/05/2025
     * @description Prueba unitaria que valida la ejecución del batch DES_BatchUpdatedPrflUsers utilizando 
     *              una lista filtrada de usuarios con valores válidos en FederationIdentifier e ID_User__c.
     *              Se asegura de que el batch se ejecuta correctamente sin errores.
     *********************************************************************************************************/
    @isTest
    static void testDES_BatchUpdatedPrflUsers() {
        User testUser = createStandardUser('Jane', 'Doe', 'janedoetest@bbvaexample.com', 'jdoetest');
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        testUser.ID_User__c = federationIdentifier;
        testUser.FederationIdentifier = federationIdentifier;
        insert testUser;

        List<User> usersToBeProcessed = [SELECT Id, FederationIdentifier, isActive, UserRoleId FROM User WHERE Id = :testUser.Id];

        Test.startTest();
        Database.executeBatch(new DES_BatchUpdatedPrflUsers(usersToBeProcessed));
        Test.stopTest();
        List<User> usersProcessed = [SELECT Id, FederationIdentifier, isActive, UserRoleId FROM User WHERE Id = :testUser.Id];
        Assert.isNotNull(usersProcessed.get(0).UserRoleId, 'El usuario se ha actualizado');
        
    }

}