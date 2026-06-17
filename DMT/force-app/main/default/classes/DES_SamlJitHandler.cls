global with sharing class DES_SamlJitHandler implements Auth.SamlJitHandler{
    public DES_SamlJitHandler(){
    }

    private class JitException extends Exception{
    }

    private UserUuaaInfoExtended.wrapper wrapper = new UserUuaaInfoExtended.wrapper();
    public static final String SADMIN = 'sAdmin';
    public static final String DESLEVEL = 'DES_LevelUO_';
    public static final String APENDC = '__c';
    public static final String REGIONEU = 'Europe/Paris';
    public static final String LOCALES = 'es_ES';
    public static final String ISOCOD = 'ISO-8859-1';
    public static final String LANGUAGE = 'en_US';
    public static final String APENDCIB = '.cib';
    public static final String PFSF = 'Perfil_SF';
    public static final String SYSADMIN = 'System Administrator';
    public static final String STDUSER = 'BBVA Standard User';
    public static final String ROLESF = 'Role_SF';
    public static final String GLOBMANAG1 = 'Global Management';
    public static final String ARCE = 'ARCE';
    public static final String SETPERMISSIONSET = 'setPermissionSet';
    public static final String ERRORMSG = 'Error al crear usuario: ';
    public static final String ERRORNAME = 'getUserUuaaInfoExtended ';
    public static final String ERRORTYPE = 'Integration';
    public static final String BASICCONF = 'Basic_Configuration';
    public static final String SPGROUP = 'CIB_gr_S_P_TEAM';
    public static final String CIBUOCODE = '00003906';
    public static final String EVENTLICENSE = 'Event Monitoring Analytics Apps';
    private static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
    /**********************************************************************************************************
     * @name            createUser
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que crea un nuevo usuario a partir de los datos proporcionados por SSO, asignando perfil y permisos.
     * @param           Id samlSsoProviderId - ID del proveedor SSO.
     * @param           Id communityId - ID de la comunidad.
     * @param           Id portalId - ID del portal.
     * @param           String federationIdentifier - Identificador de la federación.
     * @param           Map<String, String> attributes - Atributos adicionales del usuario.
     * @param           String assertion - Aserción SAML para validación.
     * @return          User - El usuario creado.
     **********************************************************************************************************/
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion){

        User user = getUserInfo(federationIdentifier, new User());
        user.FederationIdentifier = federationIdentifier;
        user.ID_User__c = federationIdentifier;

        try{
            insert user;
        } catch (Exception e){
            logError(e.getMessage(), e.getStackTraceString(), federationIdentifier, null);
        }
        setPermissionSet(user);
        return user;
    }

    /*********************************************************************************************************
     * @name            updateUser
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que actualiza un usuario existente con los datos del SSO, asignando permisos y perfil.
     * @param           Id userId - ID del usuario a actualizar.
     * @param           Id samlSsoProviderId - ID del proveedor SSO.
     * @param           Id communityId - ID de la comunidad.
     * @param           Id portalId - ID del portal.
     * @param           String federationIdentifier - Identificador de la federación.
     * @param           Map<String, String> attributes - Atributos adicionales del usuario.
     * @param           String assertion - Aserción SAML para validación.
     * @return          NA
     **********************************************************************************************************/
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion){

        User user = [SELECT Id, IsActive, UserRoleId, ID_User__c, Email, DMT_User_Role__c, FederationIdentifier, firstName, lastName
                     FROM User
                     WHERE Id = :userId
                     LIMIT 1];

        if (!user.IsActive){
            user.IsActive = true;
        }

        user = getUserInfo(federationIdentifier, user);
        try{
            update user;
        } catch (Exception e){
            deactivateUser(user.Id);
            logError(e.getMessage(), e.getStackTraceString(), federationIdentifier, user.Id);
        }
        if (user.IsActive){
            setPermissionSet(user);
        }
    }

    /*********************************************************************************************************
     * @name            deactivateUser
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que desactiva un usuario en la plataforma.
     * @param           Id userId - ID del usuario a desactivar.
     * @return          NA
     **********************************************************************************************************/
    public static void deactivateUser(Id userId){
        if (System.isFuture() || System.isBatch()){
            deactivateUserSync(userId);
        } else{
            deactivateUserFuture(userId);
        }
    }

    /**********************************************************************************************************
     * @name            deactivateUserFuture
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que desactiva un usuario en la plataforma de manera asíncrona.
     * @param           Id userId - ID del usuario a desactivar.
     * @return          NA
     **********************************************************************************************************/
    @future
    public static void deactivateUserFuture(Id userId){
        deactivateUserSync(userId);
    }

    /**********************************************************************************************************
     * @name            deactivateUserSync
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que desactiva un usuario en la plataforma de manera síncrona.
     * @param           Id userId - ID del usuario a desactivar.
     * @return          NA
     **********************************************************************************************************/
    public static void deactivateUserSync(Id userId){
        User user = [SELECT Id, IsActive, UserRoleId
                     FROM User
                     WHERE Id = :userId
                     LIMIT 1];
        user.IsActive = false;
        update user;
    }

    /*********************************************************************************************************
     * @name            getUserInfo
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que obtiene la información de un usuario desde el sistema SSO y la mapea al objeto 'User'.
     * @param           String federationIdentifier - Identificador de la federación.
     * @param           User user - Usuario al que se asignarán los datos obtenidos.
     * @return          User - Usuario con los datos actualizados.
     **********************************************************************************************************/
    public User getUserInfo(String federationIdentifier, User user){
        Map<String, Object> request = new Map<String, Object>{ 'federationIdentifier' => federationIdentifier };
        wrapper = UserUuaaInfoExtended.getUserUuaaInfoExtended(request);

        if (!wrapper.success){
            user.IsActive = false;
        } else if (validateWrapperData(user, wrapper.data)){
            // Mapea los datos básicos del usuario.
            mapUserData(user, wrapper.data);

            // Determina si el usuario es administrador.
            Boolean isAdmin = hasResource(wrapper.data, SADMIN);


            // Asigna el perfil y el rol del usuario.
            user.ProfileId = getProfileId(wrapper.data, isAdmin);
            user.UserRoleId = getUserRoleId(wrapper.data, user.UserRoleId);

            if (user.Id != null){
                User_Helper.fillUserRoleByProject(user, wrapper);
            }
        } else{
            user.IsActive = false;
        }

        return user;
    }

    /*********************************************************************************************************
     * @name            validateWrapperData
     * @author          David Díaz
     * @created         22/01/2025
     * @description     Método que valida los datos del wrapper asegurándose de que los campos obligatorios no
     *                  están vacíos o nulos.
     * @param           User user - Usuario evaluado (reservado para validaciones futuras).
     * @param           UserUuaaInfoExtended.Data data - Datos del wrapper a validar.
     * @return          Boolean - Retorna true si todos los datos requeridos están presentes; de lo contrario, false.
     **********************************************************************************************************/
    public static Boolean validateWrapperData(User user, UserUuaaInfoExtended.Data data){
        if (!hasResource(data, BASICCONF) || String.isBlank(data.name) || String.isBlank(data.surname) || String.isBlank(data.workCountry) || String.isBlank(data.email)){
            return false;
        }
        return true;
    }

    /*********************************************************************************************************
     * @name            hasResource
     * @author          David Díaz
     * @created         24/12/2025
     * @description     Verifica si en los roles del usuario existe un recurso concreto.
     * @param           UserUuaaInfoExtended.Data data - Datos del usuario obtenidos desde SSO.
     * @param           String resourceName - Nombre del recurso a buscar.
     * @return          Boolean - true si el recurso existe; false en caso contrario.
     **********************************************************************************************************/
    private static Boolean hasResource(UserUuaaInfoExtended.Data data, String resourceName){
        if (data == null || data.roles == null){
            return false;
        }

        for (UserUuaaInfoExtended.Role role : data.roles){
            if (role.resources == null){
                continue;
            }
            for (UserUuaaInfoExtended.Resource res : role.resources){
                if (res.name == resourceName){
                    return true;
                }
            }
        }
        return false;
    }

    /*********************************************************************************************************
     * @name            mapUserData
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que mapea los datos obtenidos de SSO al objeto 'User' (nombre, apellido, país de trabajo, etc.).
     * @param           User user - El usuario al que se le asignarán los datos mapeados.
     * @param           UserUuaaInfoExtended.Data data - Datos obtenidos de SSO.
     * @return          NA
     **********************************************************************************************************/
    private void mapUserData(User user, UserUuaaInfoExtended.Data data){
        user.FirstName = data.name;
        user.LastName = String.join(new List<String>{ data.surname, data.secondSurname }, ' ');
        user.DES_Country__c = data.workCountry;

        if (data.organizationalUnit != null){
            mapOrganizationalUnitsToUser(user, data.organizationalUnit);
        }

        if (user.Id == null){
            setUserDefaults(user, data);
        }
    }

    /*********************************************************************************************************
     * @name            mapOrganizationalUnitsToUser
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que mapea las unidades organizativas al objeto 'User', asignando niveles de organización.
     * @param           User user - El usuario al que se asignarán las unidades organizativas.
     * @param           UserUuaaInfoExtended.OrganizationalUnit orgUnit - Unidad organizativa a mapear.
     * @return          NA
     **********************************************************************************************************/
    private void mapOrganizationalUnitsToUser(User user, UserUuaaInfoExtended.OrganizationalUnit orgUnit){
        List<String> levels = new List<String>{ orgUnit.parentCode1, orgUnit.parentCode2, orgUnit.parentCode3, orgUnit.parentCode4, orgUnit.parentCode5, orgUnit.parentCode6, orgUnit.parentCode7, orgUnit.parentCode8, orgUnit.parentCode9, orgUnit.parentCode10 };
        for (Integer i = 0; i < levels.size(); i++){
            user.put(DESLEVEL + (i + 1) + APENDC, levels[i]);
        }
    }

    /*********************************************************************************************************
     * @name            setUserDefaults
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que establece los valores predeterminados del usuario (alias, zona horaria, idioma, etc.).
     * @param           User user - El usuario al que se le asignarán los valores predeterminados.
     * @param           UserUuaaInfoExtended.Data data - Datos obtenidos de SSO.
     * @return          NA
     **********************************************************************************************************/
    private void setUserDefaults(User user, UserUuaaInfoExtended.Data data){
        Integer indexName = data.name.length() >= 1 ? 1 : data.name.length();
        Integer indexSurName = data.surname.length() >= 3 ? 3 : data.surname.length();
        String alias = data.name.substring(0, indexName) + data.surname.substring(0, indexSurName);
        String userNameSTR = data.email + APENDCIB;
        List<User> existingUsers = [SELECT Id
                                    FROM User
                                    WHERE Username = :userNameSTR];
        if (!existingUsers.isEmpty()){
            alias += String.valueOf(existingUsers.size());
            userNameSTR += String.valueOf(existingUsers.size());
        }
        user.Alias = alias;
        user.TimeZoneSidKey = REGIONEU;
        user.LocaleSidKey = LOCALES;
        user.EmailEncodingKey = ISOCOD;
        user.LanguageLocaleKey = LANGUAGE;
        user.Email = data.email;
        user.Username = userNameSTR;
        user.UserPermissionsSFContentUser = true;
    }

    /*********************************************************************************************************
     * @name            getProfileId
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que obtiene el ID del perfil del usuario, asignando un perfil según los roles y atributos personalizados.
     * @param           UserUuaaInfoExtended.Data data - Datos obtenidos de SSO.
     * @param           Boolean isAdmin - Indica si el usuario es un administrador.
     * @return          Id - ID del perfil.
     **********************************************************************************************************/
    public Id getProfileId(UserUuaaInfoExtended.Data data, Boolean isAdmin){
        String profileName;
        profileName = isAdmin ? SYSADMIN : STDUSER;
        Profile userProfile = [SELECT Id, Name
                               FROM Profile
                               WHERE Name = :profileName
                               LIMIT 1];
        return userProfile.Id;
    }

    /*********************************************************************************************************
     * @name            getUserRoleId
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que obtiene el ID del rol del usuario según sus atributos personalizados.
     * @param           UserUuaaInfoExtended.Data data - Datos obtenidos de SSO.
     * @param           String oldUserRole - Role del usuario, si es un usaurio a crear el valor sera null.
     * @return          Id - ID del rol del usuario.
     **********************************************************************************************************/
    private Id getUserRoleId(UserUuaaInfoExtended.Data data, String oldUserRole){
        String roleName = ARCE;
        if (data.organizationalUnit != null){
            roleName = data.organizationalUnit.parentCode10;
        }

        List<UserRole> listUserRole = [SELECT Id
                                       FROM UserRole
                                       WHERE RollupDescription = :roleName
                                       LIMIT 1];

        Id roleUserId;
        if (!listUserRole.isEmpty()){
            roleUserId = listUserRole.get(0).Id;
        } else{
            roleUserId = createRoleOrHerarchy(data.organizationalUnit);
        }
        return roleUserId;
    }

    /*********************************************************************************************************
     * @name            getPermissionSet
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que obtiene la lista de Permission Sets para el usuario según los roles proporcionados por SSO.
     * @param           UserUuaaInfoExtended.Data data - Datos obtenidos de SSO.
     * @return          List<String> - Lista de Permission Sets.
     **********************************************************************************************************/
    private List<String> getPermissionSet(UserUuaaInfoExtended.Data data){
        List<String> permissionSets = new List<String>();
        if (data.roles != null){
            for (UserUuaaInfoExtended.Role role : data.roles){
                if (role.resources != null){
                    for (UserUuaaInfoExtended.Resource res : role.resources){
                        permissionSets.add(res.value);
                    }
                }
            }
        }
        return permissionSets;
    }

    /*********************************************************************************************************
     * @name            setPermissionSet
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Gestiona la asignación y eliminación de Permission Sets del usuario
     *                  según los recursos recibidos por SSO, controlando licencias,
     *                  conflictos y operaciones extendidas vía Custom Metadata.
     * @param           User user - El usuario al que se asignarán los Permission Sets.
     * @return          NA
     **********************************************************************************************************/
    public void setPermissionSet(User user){
        // Obtener los nombres de los Permission Sets a asignar.
        List<String> permissionSetNames = getPermissionSet(wrapper.data);
        if (permissionSetNames.isEmpty()){
            return;
        }

        // Consultar los Permission Sets correspondientes a los nombres obtenidos.
        List<PermissionSet> permissionSets = [SELECT Id, Name, LicenseId, License.Name
                                              FROM PermissionSet
                                              WHERE Name IN:permissionSetNames];

        // Consultar las asignaciones existentes del usuario.
        List<PermissionSetAssignment> existingAssignments = [SELECT PermissionSetId, PermissionSet.Name
                                                             FROM PermissionSetAssignment
                                                             WHERE AssigneeId = :user.Id AND PermissionSet.ProfileId = ''];

        Set<Id> assignedPermissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : existingAssignments){
            assignedPermissionSetIds.add(psa.PermissionSetId);
        }

        Set<Id> newPermissionSetIds = new Set<Id>();
        List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> assignmentsToDelete = new List<PermissionSetAssignment>();

        List<String> psNamesToInsert = new List<String>();
        List<String> psNamesDelete = new List<String>();

        String licenseId;
        String psId;
        for (PermissionSet ps : permissionSets){
            newPermissionSetIds.add(ps.Id);
            if (ps.LicenseId != null && ps.License.Name == EVENTLICENSE){
                licenseId = ps.LicenseId;
                psId = ps.Id;
            }
            if (!assignedPermissionSetIds.contains(ps.Id)){
                psNamesToInsert.add(ps.Name);
                newAssignments.add(new PermissionSetAssignment(
                    AssigneeId = user.Id, 
                    PermissionSetId = ps.Id
                ));
            }
        }

        // Determinar las asignaciones obsoletas a eliminar.
        for (PermissionSetAssignment existing : existingAssignments){
            if (!newPermissionSetIds.contains(existing.PermissionSetId)){
                assignmentsToDelete.add(existing);
                psNamesDelete.add(existing.PermissionSet.Name);
            }
        }

        List<String> metadaToFindFromPS = new List<String>();
        if (!psNamesToInsert.isEmpty()){
            metadaToFindFromPS.addAll(psNamesToInsert);
        }
        if (!psNamesDelete.isEmpty()){
            metadaToFindFromPS.addAll(psNamesDelete);
        }

        List<Permission_Extended__mdt> list_PermissionextendMdt = new List<Permission_Extended__mdt>();
        list_PermissionextendMdt = queryMDTFromPSName(metadaToFindFromPS);

        Map<String, List<Permission_Extended__mdt>> mapToCreateORDelete = new Map<String, List<Permission_Extended__mdt>>();

        if (!list_PermissionextendMdt.isEmpty()){
            mapToCreateORDelete.put('Create', new List<Permission_Extended__mdt>());
            mapToCreateORDelete.put('Delete', new List<Permission_Extended__mdt>());
            for (Permission_Extended__mdt mdt : list_PermissionextendMdt){
                if (psNamesToInsert.contains(mdt.Permission_Set__c)){
                    mapToCreateORDelete.get('Create').add(mdt);
                }
                if (psNamesDelete.contains(mdt.Permission_Set__c)){
                    mapToCreateORDelete.get('Delete').add(mdt);
                }
                if (mdt.Profile__c != null){
                    if (mdt.Profile__c == user.ProfileId){
                        mapToCreateORDelete.get('Create').add(mdt);
                    }
                    if (mdt.Profile__c != user.ProfileId){
                        mapToCreateORDelete.get('Delete').add(mdt);
                    }
                }
            }
        }
        try{
            if (!newAssignments.isEmpty()){
                Database.insert (newAssignments);
            }
            if (!assignmentsToDelete.isEmpty()){
                delete assignmentsToDelete;
            }

        } catch (Exception e){
            if (psId != null && licenseId != null){
                List<PermissionSetAssignment> newAssigWithOutEventM = new List<PermissionSetAssignment>();
                for (PermissionSetAssignment pSA : newAssignments){
                    if (pSA.PermissionSetId != psId){
                        newAssigWithOutEventM.add(pSA);
                    }
                }
                Database.insert (newAssigWithOutEventM);
                Boolean licenseFree = freeUpLicense(licenseId, psId, newAssignments);
                if (licenseFree){
                    Map<String, String> dataForReUpdated = new Map<String, String>{ 'userId' => user.Id, 'psId' => psId };
                    futureUpdatePSUser(JSON.serialize(dataForReUpdated));
                }
            }
        }


        if (!mapToCreateORDelete.isEmpty()){
            mapObjectToManipulate(user, mapToCreateORDelete);
        }
    }

    /*********************************************************************************************************
     * @name            freeUpLicense
     * @author          María Martínez
     * @created         24/12/2025
     * @description     Intenta liberar una licencia asociada a un Permission Set eliminando
     *                  la asignación del usuario activo menos reciente.
     * @param           String licensedId       - Id de la licencia limitada.
     * @param           String permissionSetID  - Id del Permission Set asociado.
     * @param           List<PermissionSetAssignment> newAssignment - Asignaciones pendientes.
     * @return          Boolean - true si la licencia se libera correctamente; false en caso contrario.
     * @notes           Excluye usuarios marcados como no desactivables mediante CIB_Bypass__c.
     **********************************************************************************************************/
    @future
    public static void futureUpdatePSUser(String dataForReUpdated){
        Map<String, String> data = (Map<String, String>)JSON.deserialize(dataForReUpdated, Map<String, String>.class);
        PermissionSetAssignment pSA = new PermissionSetAssignment(
            AssigneeId = data.get('userId'), 
            PermissionSetId = data.get('psId')
        );
        insert PSA;
    }

    /*********************************************************************************************************
     * @name            freeUpLicense
     * @author          María Martínez
     * @created         24/12/2025
     * @description     Intenta liberar una licencia de Permission Set eliminando la asignación del usuario
     *                  activo con el LastLoginDate más antiguo.
     * @param           String licensedId       - Id de la licencia limitada.
     * @param           String permissionSetID  - Id del Permission Set asociado a la licencia.
     * @param           List<PermissionSetAssignment> newAssignment - Asignaciones pendientes.
     * @return          Boolean - true si se libera la licencia correctamente; false en caso contrario.
     * @notes           Excluye usuarios marcados como no desactivables mediante CIB_Bypass__c.
     **********************************************************************************************************/
    private Boolean freeUpLicense(String licensedId, String permissionSetID, List<PermissionSetAssignment> newAssignment){
        Boolean respuesta = false;
        if (licensedId == null || permissionSetID == null){
            System.debug('ERROR: El conjunto de licencias para liberar está vacío.');
            return false;
        }
        List<CIB_Bypass__c> usersNoDesactivar = [SELECT Id, SetupOwnerId
                                                 FROM CIB_Bypass__c
                                                 WHERE CIB_DES_No_Desactivar_Usuario__c = true];
        List<Id> usersIDNoDesactivar = new List<Id>();
        for (CIB_Bypass__c record : usersNoDesactivar){
            usersIDNoDesactivar.add(record.SetupOwnerId);
        }
        // 1. Consulta: Encontrar la asignación del Permission Set limitado
        // cuyo usuario (Assignee) tiene el LastLoginDate más antiguo (o nulo, si nunca se logueó).
        // ORDER BY Assignee.LastLoginDate ASC NULLS FIRST asegura que el menos activo sea el primero.
        System.debug('LicensedId::: ' + licensedId + ' PermissionId:: ' + permissionSetID + ' UserNoDesactivar:: ' + usersIDNoDesactivar);
        List<PermissionSetAssignment> assignmentPSAToFree = [SELECT Id, AssigneeId, PermissionSetId, Assignee.LastLoginDate
                                                             FROM PermissionSetAssignment
                                                             WHERE PermissionSet.LicenseId = :licensedId // Filtrar solo los PS que consumen la licencia
         AND PermissionSetId = :permissionSetID AND Assignee.IsActive = TRUE AND AssigneeId NOT IN:usersIDNoDesactivar// Solo considerar usuarios activos
                                                             ORDER BY Assignee.LastLoginDate ASC
                                                             NULLS FIRST // El más antiguo (NULLS FIRST = nunca logueado)
                                                             LIMIT 1];

        Id userId = assignmentPSAToFree[0].AssigneeId;
        List<PermissionSetAssignment> assigmentPSA = new List<PermissionSetAssignment>();
        assigmentPSA.addAll(assignmentPSAToFree);
        assigmentPSA.addAll(newAssignment);

        if (!assignmentPSAToFree.isEmpty()){
            PermissionSetAssignment psa = assignmentPSAToFree[0];
            System.debug('Eliminar la asignación: ' + psa.Id + ' Del usuario menos activo: ' + psa.AssigneeId + ' (LastLoginDate: ' + psa.Assignee.LastLoginDate + ')');
            try{
                System.debug('Eliminada la asignación: ' + psa.Id);
                // 2. Eliminar la asignación de permissio para liberar la licencia
                delete assignmentPSAToFree;

                respuesta = true;
            } catch (DmlException e){
                // Manejar error si la eliminación falla (p. ej., problemas de permisos o bloqueos)
                System.debug('ERROR al intentar eliminar la asignación para liberar la licencia: ' + e.getMessage());
                // logError(e.getMessage(), e.getStackTraceString(), 'freeUpLicense', psa.AssigneeId);
                respuesta = false;
            }
        }

        return respuesta;
    }

    /*********************************************************************************************************
     * @name            queryMDTFromPSName
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Obtiene los registros de Custom Metadata Permission_Extended__mdt
     *                  asociados a una lista de Permission Sets o a un Profile.
     * @param           List<String> psNames - Lista de nombres de Permission Sets.
     * @return          List<Permission_Extended__mdt> - Lista de metadatos encontrados.
     **********************************************************************************************************/
    public static List<Permission_Extended__mdt> queryMDTFromPSName(List<String> psNames){
        List<Permission_Extended__mdt> list_PermissionextendMdt = new List<Permission_Extended__mdt>();
        for (Permission_Extended__mdt meta : [SELECT id, Api_Name__c, Filter_Fields__c, DeveloperName, Filter_Values__c, Permission_Set__c, Type__c, Profile__c
                                              FROM Permission_Extended__mdt]){
            if (psNames.contains(meta.Permission_Set__c) || meta.Profile__c != null){
                list_PermissionextendMdt.add(meta);
            }

        }
        return list_PermissionextendMdt;
    }

    /*********************************************************************************************************
     * @name            mapObjectToManipulate
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Analiza la configuración de Custom Metadata asociada a Permission Sets
     *                  y determina qué registros deben insertarse o eliminarse para el usuario.
     * @param           User user - Usuario sobre el que se aplican las operaciones.
     * @param           Map<String, List<Permission_Extended__mdt>> mapToCreateORDelete -
     *                  Mapa con metadata a crear ('Create') o eliminar ('Delete').
     * @return          NA
     **********************************************************************************************************/
    public static void mapObjectToManipulate(User user, Map<String, List<Permission_Extended__mdt>> mapToCreateORDelete){
        List<Permission_Extended__mdt> listToInsert = mapToCreateORDelete.get('Create');
        List<Permission_Extended__mdt> listToDelete = mapToCreateORDelete.get('Delete');
        Map<String, List<SObject>> mapObjectsToInsert = new Map<String, List<SObject>>();
        Map<String, List<SObject>> mapObjectsToDelete = new Map<String, List<SObject>>();
        List<String> groupsToFind = new List<String>();
        boolean isInsert = false;
        if (!listToInsert.isEmpty()){
            isInsert = true;
            groupsToFind = new List<String>();
            for (Permission_Extended__mdt mdt : listToInsert){
                if (mdt.Type__c == 'Public Group'){
                    groupsToFind.add(mdt.Api_Name__c);
                } else{
                    SObject obj = crearObjeto(user, mdt);
                    if (obj != null){
                        if (mapObjectsToInsert.keySet().contains(mdt.Type__c)){
                            mapObjectsToInsert.get(mdt.Type__c).add(obj);
                        } else{
                            List<SObject> sObjectsToInsert = new List<SObject>();
                            sObjectsToInsert.add(obj);
                            mapObjectsToInsert.put(mdt.Type__c, sObjectsToInsert);
                        }
                    }
                }
            }
            if (!groupsToFind.isEmpty()){
                manageGroupMember(user, groupsToFind, isInsert);
            }
        }
        if (!listToDelete.isEmpty()){
            isInsert = false;
            groupsToFind = new List<String>();
            List<Permission_Extended__mdt> sObjectsOrCSToFind = new List<Permission_Extended__mdt>();
            for (Permission_Extended__mdt mdt : listToDelete){
                if (mdt.Type__c == 'Public Group'){
                    groupsToFind.add(mdt.Api_Name__c);
                } else{
                    sObjectsOrCSToFind.add(mdt);
                }
            }
            if (!groupsToFind.isEmpty()){
                //Buscar y eliminar miembros de grupos
                manageGroupMember(user, groupsToFind, isInsert);
            }

            if (!sObjectsOrCSToFind.isEmpty()){
                for (Permission_Extended__mdt mdtObjectOrCS : sObjectsOrCSToFind){
                    List<SObject> objectToDelete = obtenerRegistros(user, mdtObjectOrCS);
                    if (!objectToDelete.isEmpty()){
                        if (mapObjectsToInsert.keySet().contains(mdtObjectOrCS.Type__c)){
                            mapObjectsToDelete.get(mdtObjectOrCS.Type__c).addAll(objectToDelete);
                        } else{
                            mapObjectsToDelete.put(mdtObjectOrCS.Type__c, objectToDelete);
                        }
                    }
                }
            }
            if (!mapObjectsToInsert.isEmpty()){
                insertarData(mapObjectsToInsert);
            }
            if (!mapObjectsToDelete.isEmpty()){
                borrarData(mapObjectsToDelete);
            }
        }
    }

    /*********************************************************************************************************
     * @name            insertarData
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Inserta registros agrupados por tipo, ejecutando inserción asíncrona
     *                  cuando el tipo corresponde a objetos dinámicos.
     * @param           Map<String, List<SObject>> mapObjects - Registros a insertar agrupados por tipo.
     * @return          NA
     **********************************************************************************************************/
    private static void insertarData(Map<String, List<SObject>> mapObjects){
        for (String key : mapObjects.keySet()){
            List<SObject> listaRegistroSObject = mapObjects.get(key);

            if (key == 'Object'){
                insertAsincrono(JSON.serialize(listaRegistroSObject));
            } else{
                Database.insert (listaRegistroSObject, false);
            }
        }
    }

    /*********************************************************************************************************
     * @name            insertAsincrono
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Inserta registros de forma asíncrona a partir de una lista serializada en JSON.
     * @param           String jsonList - Lista de SObjects serializada en formato JSON.
     * @return          NA
     * @notes           Usado para evitar límites DML en operaciones dinámicas.
     **********************************************************************************************************/
    @future
    public static void insertAsincrono(String jsonList){
        List<SObject> registrosSObject = (List<SObject>)JSON.deserialize(jsonList, List<SObject>.class);
        insert registrosSObject;
    }

    /*********************************************************************************************************
     * @name            borrarData
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Elimina registros agrupados por tipo, ejecutando borrado asíncrono
     *                  cuando corresponde a objetos dinámicos.
     * @param           Map<String, List<SObject>> mapObjectsToDelete - Registros a eliminar.
     * @return          NA
     **********************************************************************************************************/
    private static void borrarData(Map<String, List<SObject>> mapObjectsToDelete){
        for (String key : mapObjectsToDelete.keySet()){
            List<SObject> listaRegistroSObject = mapObjectsToDelete.get(key);

            if (key == 'Object'){
                borrarAsincrono(JSON.serialize(listaRegistroSObject));
            } else{
                Database.delete (listaRegistroSObject, false);
            }
        }
    }

    /*********************************************************************************************************
     * @name            borrarAsincrono
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Elimina registros de forma asíncrona a partir de una lista serializada en JSON.
     * @param           String jsonList - Lista de SObjects serializada.
     * @return          NA
     **********************************************************************************************************/
    @future
    public static void borrarAsincrono(String jsonList){
        List<SObject> registrosObject = (List<SObject>)JSON.deserialize(jsonList, List<SObject>.class);
        delete registrosObject;
    }

    /*********************************************************************************************************
     * @name            logError
     * @description     Registra los errores ocurridos durante la creación o actualización de un usuario en el
     *                  registro de logs del sistema, con detalles del error, identificador de federación y usuario.
     * @author          David Díaz
     * @created         02/12/2024
     *
     * @param           String errorMessage        - Mensaje de error descriptivo.
     * @param           String errorTrace          - Trazabilidad del error o identificador de transacción.
     * @param           String federationIdentifier - Identificador único de la federación afectada.
     * @param           Id userId                  - ID del usuario relacionado con el error (opcional).
     *
     * @return          void
     *
     * @notes           Este método es invocado de manera asíncrona usando la anotación @future. Se recomienda
     *                  limitar su uso cuando existan restricciones críticas de tiempo o DML.
     **********************************************************************************************************/
    public static void logError(String errorMessage, String errorTrace, String federationIdentifier, Id userId){
        if (System.isFuture() || System.isBatch()){
            logErrorSync(errorMessage, errorTrace, federationIdentifier, userId);
        } else{
            logErrorFuture(errorMessage, errorTrace, federationIdentifier, userId);
        }
    }

    /*********************************************************************************************************
     * @name            logErrorFuture
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Ejecuta de forma asíncrona el registro de errores de integración SSO.
     * @param           String errorMessage - Mensaje de error.
     * @param           String errorTrace - Trazabilidad o stack trace.
     * @param           String federationIdentifier - Identificador de federación.
     * @param           Id userId - Usuario asociado al error.
     * @return          NA
     **********************************************************************************************************/
    @future
    public static void logErrorFuture(String errorMessage, String errorTrace, String federationIdentifier, Id userId){
        logErrorSync(errorMessage, errorTrace, federationIdentifier, userId);
    }

    /*********************************************************************************************************
     * @name            logErrorSync
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Registra de forma síncrona un error de integración en el objeto
     *                  iaso__GBL_Application_Log__c.
     * @param           String errorMessage - Mensaje de error.
     * @param           String errorTrace - Trazabilidad o stack trace.
     * @param           String federationIdentifier - Identificador de federación.
     * @param           Id userId - Usuario asociado al error.
     * @return          NA
     **********************************************************************************************************/
    public static void logErrorSync(String errorMessage, String errorTrace, String federationIdentifier, Id userId){
        iaso__GBL_Application_Log__c log = new iaso__GBL_Application_Log__c(
            iaso__Message_LTA__c = ERRORMSG + errorMessage, 
            Name = ERRORNAME + federationIdentifier, 
            iaso__Type__c = ERRORTYPE, 
            iaso__Transaction_Id__c = errorTrace, 
            iaso__Start_Time__c = System.now(), 
            iaso__End_Time__c = System.now()
        );
        if (userId != null){
            log.iaso__User__c = userId;
        }
        insert log;
    }

    /*********************************************************************************************************
     * @name            crearObjeto
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Crea dinámicamente un SObject a partir de la definición almacenada
     *                  en Custom Metadata, resolviendo tokens con datos del usuario.
     * @param           User user - Usuario actual.
     * @param           Permission_Extended__mdt mdt - Metadata con definición del objeto.
     * @return          SObject - Objeto listo para inserción o null si no es válido.
     **********************************************************************************************************/
    @TestVisible
    private static SObject crearObjeto(User user, Permission_Extended__mdt mdt){
        // Obtener el nombre del objeto desde la Custom Metadata
        if (user.Id != null && mdt != null){
            String objectName = mdt.Api_Name__c;
            List<String> fields = new List<String>();
            List<String> values = new List<String>();
            if (mdt.Filter_Fields__c != null){
                if (mdt.Filter_Fields__c.contains(';')){
                    fields = mdt.Filter_Fields__c.split(';');
                } else{
                    fields.add(mdt.Filter_Fields__c);
                }

            }
            if (mdt.Filter_Values__c != null){
                if (mdt.Filter_Values__c.contains(';')){
                    values = mdt.Filter_Values__c.split(';');
                } else{
                    values.add(mdt.Filter_Values__c);
                }

            }
            if (GLOBAL_DESCRIBE.containsKey(objectName)){
                // Crear una instancia del objeto dinámicamente
                SObject obj = GLOBAL_DESCRIBE.get(objectName).newSObject();

                for (Integer i = 0; i < fields.size(); i++){
                    String field = fields[i];
                    String rawValue = values[i];
                    String realValue = resolveToken(rawValue, user);

                    obj.put(field, realValue);
                }

                return obj;
            }
        }
        return null;
    }

    /*********************************************************************************************************
     * @name            resolveToken
     * @author          David Díaz
     * @created         24/12/2025
     * @description     Resuelve valores dinámicos definidos en Custom Metadata,
     *                  sustituyendo tokens por valores reales del usuario.
     * @param           String rawValue - Valor original del metadata (token o literal).
     * @param           User user - Usuario actual.
     * @return          String - Valor final resuelto.
     * @notes           Tokens soportados: {{userId}}, {{userEmail}}, {{userIduser}}, {{name}}.
     **********************************************************************************************************/
    private static String resolveToken(String rawValue, User user){
        switch  on rawValue{
            when '{{userId}}'{
                return user.Id;
            }
            when '{{userEmail}}'{
                return user.Email;
            }
            when '{{userIduser}}'{
                return user.Id_User__c;
            }
            when '{{name}}'{
                return user.FirstName + ' ' + user.LastName;
            }
            when else{
                return rawValue;
            }
        }
    }

    /*********************************************************************************************************
     * @name            obtenerRegistros
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Construye dinámicamente una query SOQL basada en Custom Metadata
     *                  y obtiene los registros asociados a un usuario para su eliminación.
     * @param           User user - Usuario actual.
     * @param           Permission_Extended__mdt mdt - Metadata con definición de filtros.
     * @return          List<SObject> - Lista de registros encontrados.
     * @notes           Valida campos dinámicos mediante Schema Describe.
     **********************************************************************************************************/
    private static List<SObject> obtenerRegistros(User user, Permission_Extended__mdt mdt){
        List<SObject> returnList = new List<SObject>();
        if (user.Id != null && mdt != null){
            String objectName = mdt.Api_Name__c;

            List<String> fields = new List<String>();
            List<String> values = new List<String>();
            if (mdt.Filter_Fields__c != null){
                if (mdt.Filter_Fields__c.contains(';')){
                    fields = mdt.Filter_Fields__c.split(';');
                } else{
                    fields.add(mdt.Filter_Fields__c);
                }
            }
            if (mdt.Filter_Values__c != null){
                if (mdt.Filter_Values__c.contains(';')){
                    values = mdt.Filter_Values__c.split(';');
                } else{
                    values.add(mdt.Filter_Values__c);
                }
            }
            if (GLOBAL_DESCRIBE.containsKey(objectName)){
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
                List<String> condiciones = new List<String>();
                for (Integer i = 0; i < fields.size(); i++){
                    String field = fields[i];
                    String rawValue = values[i];
                    String realValue = resolveToken(rawValue, user);
                    if (!fieldMap.containsKey(field)){
                        throw new AuraHandledException('Campo no permitido: ' + field);
                    }
                    condiciones.add(field + ' = \'' + String.escapeSingleQuotes(realValue) + '\''); // NOSONAR
                }
                String query = 'SELECT Id FROM ' + objectName; // NOSONAR
                if (!condiciones.isEmpty()){
                    query += ' WHERE ' + String.join(condiciones, ' AND '); // NOSONAR
                }

                returnList = Database.query(query); // NOSONAR

            }
        }
        return returnList;
    }

    /*********************************************************************************************************
     * @name            manageGroupMember
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Gestiona la inserción o eliminación de un usuario como miembro
     *                  de uno o varios Public Groups.
     * @param           User user - Usuario a insertar o eliminar del grupo.
     * @param           List<String> groupNames - DeveloperName de los grupos.
     * @param           Boolean isInsert - true para insertar; false para eliminar.
     * @return          NA
     **********************************************************************************************************/
    @TestVisible
    private static void manageGroupMember(User user, List<String> groupNames, boolean isInsert){
        if (groupNames == null || groupNames.isEmpty() || user.Id == null)
            return;
        List<Group> grupos = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN:groupNames];

        if (grupos.isEmpty())
            return;
        if (isInsert){
            List<GroupMember> membersToInsert = new List<GroupMember>();
            for (Group grupo : grupos){
                GroupMember gm = new GroupMember();
                gm.GroupId = grupo.Id;
                gm.UserOrGroupId = user.Id;
                membersToInsert.add(gm);
            }
            if (!membersToInsert.isEmpty()){
                insert membersToInsert;
            }

        } else{
            List<GroupMember> membersToDelete = [SELECT Id
                                                 FROM GroupMember
                                                 WHERE GroupId IN:grupos AND UserOrGroupId = :user.Id];
            if (!membersToDelete.isEmpty()){
                delete membersToDelete;
            }

        }
    }

    /*********************************************************************************************************
     * @name            createRoleOrHerarchy
     * @author          David Díaz
     * @created         06/05/2025
     * @description     Crea dinámicamente la jerarquía de User Roles a partir de la
     *                  unidad organizativa recibida desde SSO.
     * @param           UserUuaaInfoExtended.OrganizationalUnit orgUnit - Unidad organizativa del usuario.
     * @return          Id - Id del rol final asignado al usuario.
     * @notes           Reutiliza roles existentes y crea únicamente los inexistentes.
     **********************************************************************************************************/
    private Id createRoleOrHerarchy(UserUuaaInfoExtended.OrganizationalUnit orgUnit){
        List<String> uoCodes = new List<String>{ orgUnit.parentCode1, orgUnit.parentCode2, orgUnit.parentCode3, orgUnit.parentCode4, orgUnit.parentCode5, orgUnit.parentCode6, orgUnit.parentCode7, orgUnit.parentCode8, orgUnit.parentCode9, orgUnit.parentCode10 };
        List<String> uoNames = new List<String>{ orgUnit.parentName1, orgUnit.parentName2, orgUnit.parentName3, orgUnit.parentName4, orgUnit.parentName5, orgUnit.parentName6, orgUnit.parentName7, orgUnit.parentName8, orgUnit.parentName9, orgUnit.parentName10 };

        Map<String, String> uoCodeToName = new Map<String, String>();
        for (String code : uoCodes){
            if (!String.isBlank(code) && !uoCodeToName.containsKey(code)){
                uoCodeToName.put(code, uoNames.get(uoCodes.indexOf(code)));
            }
        }

        if (!uoCodeToName.containsKey(CIBUOCODE)){
            UserRole arceRole = [SELECT Id
                                 FROM UserRole
                                 WHERE Name = :ARCE
                                 LIMIT 1];
            return arceRole.Id;
        }

        List<UserRole> existingRoles = [SELECT Id, Name, RollupDescription, ParentRoleId
                                        FROM UserRole
                                        WHERE RollupDescription IN:uoCodeToName.keySet()];

        Map<String, UserRole> existingRoleMap = new Map<String, UserRole>();
        for (UserRole r : existingRoles){
            existingRoleMap.put(r.RollupDescription, r);
        }

        Id currentParentId = existingRoleMap.get(CIBUOCODE).Id;
        Id finalRoleId = currentParentId;

        for (String code : uoCodes){
            if (String.isBlank(code) || code == CIBUOCODE)
                continue;
            if (existingRoleMap.containsKey(code)){
                currentParentId = existingRoleMap.get(code).Id;
                finalRoleId = currentParentId;
            } else if (uoCodeToName.containsKey(code)){
                UserRole newRole = new UserRole(
                    Name = uoCodeToName.get(code), 
                    RollupDescription = code, 
                    ParentRoleId = currentParentId
                );
                insert newRole;
                Map<String, String> roleData = new Map<String, String>{ 'Name' => newRole.Name, 'ParentRoleId' => newRole.ParentRoleId, 'RollupDescription' => newRole.RollupDescription };
                if (!System.isFuture() && !System.isBatch()){
                    notifyANS(JSON.serialize(roleData));
                }
                currentParentId = newRole.Id;
                finalRoleId = newRole.Id;
                existingRoleMap.put(code, newRole);
            }
        }

        return finalRoleId;
    }

    /*********************************************************************************************************
     * @name            notifyANS
     * @author          Adrián Salinas
     * @created         13/01/2026
     * @description     Método que envia una notificación a ANS cuando se crea un nuevo rol dinámico.
     * @param           String roleJson - JSON con datos del nuevo rol creado.
     * @return          NA
     **********************************************************************************************************/
    @future
    private static void notifyANS(String roleJson){
        try{
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            Id orgWideId = [SELECT Id
                            FROM OrgWideEmailAddress
                            WHERE Address = 'ans_clientcloud@bbva.com'
                            LIMIT 1].Id;
            email.setOrgWideEmailAddressId(orgWideId);
            email.setToAddresses(new String[]{ 'ans_clientcloud@bbva.com' });
            email.setSubject('Nuevo Role dinámico creado en a través del proceso SAML');

            Map<String, String> roleData = (Map<String, String>)JSON.deserialize(roleJson, Map<String, String>.class);
            String body = 'Se ha creado un nuevo Role dinámico en Producción vía SAML.\n' + 
                       '\nRole Name: ' + roleData.get('Name') + 
                       '\nParent Role: ' + roleData.get('ParentRoleId') + 
                       '\nRollup Description: ' + roleData.get('RollupDescription') + 
                       '\n\nPor favor, sincronizar en Pre-Producción y repositorio.';

            email.setPlainTextBody(body);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e){
            System.debug('No se pudo enviar notificación ANS: ' + e.getMessage());
        }
    }

}