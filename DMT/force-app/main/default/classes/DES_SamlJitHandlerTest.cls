@isTest
private class DES_SamlJitHandlerTest {
    /**
     * Método helper para crear un usuario con perfil 'Standard User'
     */
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
    
    @testSetup
    static void setupdata(){
        User testUser = createStandardUser('Jane', 'Doe', 'janedoetest@bbvaexample.com', 'jdoetest');
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        testUser.ID_User__c = federationIdentifier;
        testUser.FederationIdentifier = federationIdentifier;
        insert testUser;
        List<PermissionSet> permissionSets = [SELECT Id, Name
                                              FROM PermissionSet
                                              WHERE Name = 'GMClaims'];
        PermissionSetAssignment pATestUser = new PermissionSetAssignment(
                    AssigneeId = testUser.Id, 
                    PermissionSetId = permissionSets.get(0).Id);
        insert pATestUser;
    }

    /*********************************************************************************************************
     * @name            testCreateUser
     * @description     Prueba la funcionalidad del método 'createUser' para verificar que un usuario nuevo
     *                  se crea correctamente con los parámetros proporcionados y los valores esperados.
     **********************************************************************************************************/
    @isTest
    static void testCreateUser() {
        DES_SamlJitHandler handler = new DES_SamlJitHandler();

        Id samlSsoProviderId = UserInfo.getOrganizationId();
        Id communityId = UserInfo.getOrganizationId();
        Id portalId = UserInfo.getOrganizationId();
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        Map<String, String> attributes = new Map<String, String>{ 'key' => 'value' };
        String assertion = 'sampleAssertion';

        Test.startTest();
        User createdUser = handler.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
        Test.stopTest();

        System.assertNotEquals(null, createdUser, 'El usuario debería haber sido creado.');
        System.assertEquals('Test', createdUser.FirstName, 'El nombre del usuario no es correcto.');
    }

    /*********************************************************************************************************
     * @name            testUpdateUser
     * @description     Prueba la funcionalidad del método 'updateUser' para verificar que un usuario existente
     *                  puede ser actualizado correctamente con los valores esperados.
     **********************************************************************************************************/
    @isTest
    static void testUpdateUser() {
        User testUser =[SELECT Id, FederationIdentifier FROM User WHERE Email = 'janedoetest@bbvaexample.com' LIMIT 1];
        DES_SamlJitHandler handler = new DES_SamlJitHandler();
        Id samlSsoProviderId = UserInfo.getOrganizationId();
        Id communityId = UserInfo.getOrganizationId();
        Id portalId = UserInfo.getOrganizationId();
        Map<String, String> attributes = new Map<String, String>{ 'key' => 'value' };
        String assertion = 'sampleAssertion';

        Test.startTest();
        	handler.updateUser(testUser.Id, samlSsoProviderId, communityId, portalId, testUser.FederationIdentifier, attributes, assertion);
        Test.stopTest();

        User updatedUser = [SELECT FirstName, LastName, UserRole.RollupDescription
                            FROM User
                            WHERE Id = :testUser.Id
                            LIMIT 1];
        System.assertNotEquals(null, updatedUser, 'El usuario debería existir después de la actualización.');
        System.assertEquals('Test', updatedUser.FirstName, 'El nombre del usuario no se actualizó correctamente.');
        System.assertEquals('00080138', updatedUser.UserRole.RollupDescription, 'El role no se creó correctamente.');
    }

    /*********************************************************************************************************
     * @name            testInternalMethods
     * @description     Prueba los métodos internos como 'getUserInfo' para garantizar que devuelven
     *                  información correcta del usuario basándose en el identificador de federación.
     **********************************************************************************************************/
    @isTest
    static void testInternalMethods() {
        User testUser = createStandardUser('Test', 'User', 'testusertest@bbvaexample.com', 'tusertes');
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        testUser.ID_User__c = federationIdentifier;
        testUser.FederationIdentifier = federationIdentifier;
        insert testUser;

        DES_SamlJitHandler handler = new DES_SamlJitHandler();
        Map<String, String> attributes = new Map<String, String>{ 'key' => 'value' };
        String assertion = 'sampleAssertion';

        Test.startTest();
        User updatedUser = handler.getUserInfo(federationIdentifier, testUser);
        Test.stopTest();

        System.assertNotEquals(null, updatedUser, 'El usuario debería haber sido actualizado.');
        System.assertEquals('Test', updatedUser.FirstName, 'El campo FirstName no se actualizó correctamente.');
    }

    /*********************************************************************************************************
     * @name            testCreateUserError
     * @description     Prueba la funcionalidad del método 'createUser' para validar que los errores durante
     *                  la creación de un usuario son manejados correctamente y que no se crea el usuario.
     **********************************************************************************************************/
    @isTest
    static void testCreateUserError() {
        User testUser = createStandardUser('Test', 'User', 'Test.user@bbvatest.com', 'janedoe');
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        testUser.ID_User__c = federationIdentifier;
        testUser.FederationIdentifier = federationIdentifier;
        insert testUser;

        DES_SamlJitHandler handler = new DES_SamlJitHandler();
        Id samlSsoProviderId = UserInfo.getOrganizationId();
        Id communityId = UserInfo.getOrganizationId();
        Id portalId = UserInfo.getOrganizationId();
        Map<String, String> attributes = new Map<String, String>{ 'key' => 'value' };
        String assertion = 'sampleAssertion';

        Test.startTest();
        User createdUser = handler.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
        Test.stopTest();

        // Se asume que si ocurre error, no se asigna Id al usuario.
        System.assertEquals(null, createdUser.Id, 'El usuario NO debería haberse creado tras ocurrir un error.');
    }

    /*********************************************************************************************************
     * @name            testActiveUser
     * @description     Prueba la funcionalidad del método 'updateUser' para validar que un usuario inactivo se reactiva.
     **********************************************************************************************************/
    @isTest
    static void testActiveUser() {
        User testUser = createStandardUser('Test', 'User', 'Test.user@bbvatest.com', 'janedoe');
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        testUser.ID_User__c = federationIdentifier;
        testUser.FederationIdentifier = federationIdentifier;
        insert testUser;
        // Desactivar usuario manualmente.
        testUser.IsActive = false;
        update testUser;

        DES_SamlJitHandler handler = new DES_SamlJitHandler();
        Id samlSsoProviderId = UserInfo.getOrganizationId();
        Id communityId = UserInfo.getOrganizationId();
        Id portalId = UserInfo.getOrganizationId();
        Map<String, String> attributes = new Map<String, String>{ 'key' => 'value' };
        String assertion = 'sampleAssertion';

        Test.startTest();
        handler.updateUser(testUser.Id, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
        Test.stopTest();

        User updatedUser = [SELECT FirstName, LastName, IsActive
                            FROM User
                            WHERE Id = :testUser.Id
                            LIMIT 1];
        System.assertNotEquals(null, updatedUser, 'El usuario debería existir después de la actualización.');
        System.assertEquals('Test', updatedUser.FirstName, 'El campo FirstName no se actualizó correctamente.');
        System.assertEquals(true, updatedUser.IsActive, 'El usuario no se reactivó correctamente.');
    }

    /*********************************************************************************************************
     * @name            testDeActiveUser
     * @description     Prueba la funcionalidad del método 'deactivateUser' para validar que un usuario activo se desactiva correctamente.
     **********************************************************************************************************/
    @isTest
    static void testDeActiveUser() {
        User testUser = createStandardUser('Test', 'User', 'Test.user@bbvatest.com', 'janedoe');
        String federationIdentifier = String.valueOf(Math.round(Math.random() * 100000));
        testUser.ID_User__c = federationIdentifier;
        testUser.FederationIdentifier = federationIdentifier;
        insert testUser;

        Test.startTest();
        DES_SamlJitHandler.deactivateUser(testUser.Id);
        Test.stopTest();

        User updatedUser = [SELECT IsActive
                            FROM User
                            WHERE Id = :testUser.Id
                            LIMIT 1];
        System.assertEquals(false, updatedUser.IsActive, 'El usuario no se desactivó correctamente.');
    }

    /**********************************************************************************************************
     * @name            testValidateWrapperData
     * @description     Prueba la funcionalidad del método 'validateWrapperData' para validar que los datos del wrapper
     *                  cumplen con los criterios requeridos.
     **********************************************************************************************************/
    @isTest
    static void testValidateWrapperData() {
        // Crear un usuario de prueba para contexto.
        User testUser = createStandardUser('Test', 'User', 'Test.user@bbvatest.com', 'janedoe');

        // Crear datos inválidos (campo name en blanco)
        UserUuaaInfoExtended.Data invalidData = new UserUuaaInfoExtended.Data();
        invalidData.name = '';
        invalidData.surname = 'Doe';
        invalidData.workCountry = 'US';
        invalidData.email = 'john.doe@example.com';

        Test.startTest();
        Boolean isValid = DES_SamlJitHandler.validateWrapperData(testUser, invalidData);
        Test.stopTest();

        System.assertEquals(false, isValid, 'El método debe retornar false para datos inválidos.');
    }

}