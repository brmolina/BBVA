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

        User user = [SELECT Id, IsActive, UserRoleId, ID_User__c, Email, DMT_User_Role__c
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
            Boolean isAdmin = false;
            if (wrapper.data.roles != null){
                for (UserUuaaInfoExtended.Role role : wrapper.data.roles){
                     for(UserUuaaInfoExtended.Resource resource : role.resources){
                            if (resource.name == SADMIN){
                                isAdmin = true;
                                break;
                            }
                     }
                }
            }

            // Asigna el perfil y el rol del usuario.
            user.ProfileId = getProfileId(wrapper.data, isAdmin);
            user.UserRoleId = getUserRoleId(wrapper.data, user.UserRoleId);

            // Mapea los atributos personalizados, si existen.
            if (wrapper.data.attributeSet != null){
                mapCustomAttributes(user, wrapper.data.attributeSet);
            }
            if( user.Id != null){
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
     * @param           User user - Objeto usuario que será evaluado.
     * @param           UserUuaaInfoExtended.Data data - Datos del wrapper a validar.
     * @return          Boolean - Retorna true si todos los datos requeridos están presentes; de lo contrario, false.
     **********************************************************************************************************/
    public static Boolean validateWrapperData(User user, UserUuaaInfoExtended.Data data){
        Boolean hasBasicConf = false;
        if (data.roles != null){
            for (UserUuaaInfoExtended.Role role : data.roles){
                if (role.resources != null){
                    for (UserUuaaInfoExtended.Resource res : role.resources){
                        if (res.name == BASICCONF){
                            hasBasicConf = true;
                            break;
                        }
                    }
                }
                if (hasBasicConf){
                    break;
                }
            }
        }

        // Validar campos obligatorios y existencia del recurso BASICCONF.
        if (!hasBasicConf || String.isBlank(data.name) || String.isBlank(data.surname) || String.isBlank(data.workCountry) || String.isBlank(data.email)){
            return false;
        }
        return true;
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
        user.Email = data.email+'.invalid';
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
    private Id getProfileId(UserUuaaInfoExtended.Data data, Boolean isAdmin){
        String profileName = getAttributes(data).get(PFSF);
        if (String.isBlank(profileName)){
            profileName = isAdmin ? SYSADMIN : STDUSER;
        }
        return [SELECT Id
                FROM Profile
                WHERE Name = :profileName
                LIMIT 1].Id;
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
     * @name            mapCustomAttributes
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que mapea los atributos personalizados del usuario y los asigna al objeto 'User'.
     * @param           User user - El usuario al que se asignarán los atributos personalizados.
     * @param           List<UserUuaaInfoExtended.Attribute> attributes - Atributos personalizados del usuario.
     * @return          NA
     **********************************************************************************************************/
    private void mapCustomAttributes(User user, List<UserUuaaInfoExtended.Attribute> attributes){
        Map<String, String> attributeMap = getAttributes(wrapper.data);
        for (Profiling_Configuration__mdt config : Profiling_Configuration__mdt.getAll().values()){
            String value = attributeMap.get(config.DES_Key__c);
            if (String.isBlank(value)){
                continue;
            }
            switch  on config.DES_Data_Type__c{
                when 'String'{
                    user.put(config.DES_value__c, value);
                }
                when 'Boolean'{
                    user.put(config.DES_value__c, Boolean.valueOf(value));
                }
                when 'Number'{
                    user.put(config.DES_value__c, Integer.valueOf(value));
                }
                when 'Double'{
                    user.put(config.DES_value__c, Double.valueOf(value));
                }
            }
        }
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
     * @name            getAttributes
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que obtiene los atributos personalizados del usuario desde los datos proporcionados por SSO.
     * @param           UserUuaaInfoExtended.Data data - Datos del usuario obtenidos de SSO.
     * @return          Map<String, String> - Mapa de atributos personalizados del usuario.
     **********************************************************************************************************/
    private Map<String, String> getAttributes(UserUuaaInfoExtended.Data data){
        Map<String, String> attributeMap = new Map<String, String>();
        if (data.attributeSet != null){
            for (UserUuaaInfoExtended.Attribute attrSet : data.attributeSet){
                if (attrSet.attributes != null){
                    for (UserUuaaInfoExtended.Attributes attr : attrSet.attributes){
                        attributeMap.put(attr.attributeName, attr.attributeValue);
                    }
                }
            }
        }
        return attributeMap;
    }

    /*********************************************************************************************************
     * @name            setPermissionSet
     * @author          David Díaz
     * @created         02/12/2024
     * @description     Método que asigna los Permission Sets al usuario según los roles y recursos obtenidos de los datos del SSO.
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
        List<PermissionSet> permissionSets = [SELECT Id, Name
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

        for (PermissionSet ps : permissionSets){
            newPermissionSetIds.add(ps.Id);
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
        if (!metadaToFindFromPS.isEmpty()){
            list_PermissionextendMdt = queryMDTFromPSName(metadaToFindFromPS);
        }

        System.debug('list_PermissionextendMdt:::: ' + list_PermissionextendMdt);

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
            }
        }

        try{
            if (!newAssignments.isEmpty()){
                insert newAssignments;
            }
            if (!assignmentsToDelete.isEmpty()){
                delete assignmentsToDelete;
            }         
        } catch (Exception e){
            logError(e.getMessage(), e.getStackTraceString(), SETPERMISSIONSET, user.Id);
        }
        
            if (!mapToCreateORDelete.isEmpty()){
                mapObjectToManipulate(user.id, mapToCreateORDelete);
            }   
    }

    /*********************************************************************************************************
     * @name            queryMDTFromPSName
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Método que devuelve una query para obtener los metadatas tanto de los registros que hay que insertar como eliminar, en función de la lista de nombres de los Permission Set.
     * @param           List<String> psNames.
     * @return          list_PermissionextendMdt - Query generada
     **********************************************************************************************************/
    public static List<Permission_Extended__mdt> queryMDTFromPSName(List<String> psNames){
        List<Permission_Extended__mdt> list_PermissionextendMdt = [SELECT id, Api_Name__c, Filter_Fields__c, DeveloperName, Filter_Values__c, Permission_Set__c, Type__c
                                                                   FROM Permission_Extended__mdt
                                                                   WHERE Permission_Set__c IN:psNames];
        System.debug('list_PermissionextendMdt:::: ' + list_PermissionextendMdt);
        return list_PermissionextendMdt;
    }

    /*********************************************************************************************************
     * @name            mapObjectToManipulate
     * @author          Guillermo Iglesias
     * @created         08/07/2025
     * @description     Método que recibiendo como parámetro un usuario y una lista de CMDT, almacena la información en un map con los registros a eliminar o insertar
     * @param           String userId.
     * @param           Map<String, List<Permission_Extended__mdt> mapToCreateORDelete.
     * @return          NA
     **********************************************************************************************************/
    public static void mapObjectToManipulate(String userId, Map<String, List<Permission_Extended__mdt>> mapToCreateORDelete){
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
                    SObject obj = crearObjeto(userId, mdt);
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
                //cambiando nombre
                manageGroupMember(userId, groupsToFind,isInsert);
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
                manageGroupMember(userId, groupsToFind,isInsert);
            }

            if(!sObjectsOrCSToFind.isEmpty()){
                for(Permission_Extended__mdt mdtObjectOrCS : sObjectsOrCSToFind) {
                    List<SObject> objectToDelete = obtenerRegistros(userId, mdtObjectOrCS);
                    if (!objectToDelete.isEmpty()){
                        if(mapObjectsToInsert.keySet().contains(mdtObjectOrCS.Type__c)){
                            mapObjectsToDelete.get(mdtObjectOrCS.Type__c).addAll(objectToDelete);
                        } else{
                            mapObjectsToDelete.put(mdtObjectOrCS.Type__c, objectToDelete);
                        }
                    }
                }
            }
            if(!mapObjectsToInsert.isEmpty()){
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
    * @description     Método que recibiendo como parámetro un map, filtra por tipo de metadata para insertarlos de manera asíncrona o no
    * @param           Map<String, List<SObject>> mapObjects.
    * @return          NA
    **********************************************************************************************************/
    private static void insertarData(Map<String, List<SObject>> mapObjects) {
        for (String key : mapObjects.keySet()) {
            List<SObject> listaRegistroSObject = mapObjects.get(key);

            if (key == 'Object') {
                insertAsincrono(JSON.serialize(listaRegistroSObject));
            } else {
                Database.insert(listaRegistroSObject, false);
            }
        }
    }

    /*********************************************************************************************************
    * @name            insertAsincrono
    * @author          Guillermo Iglesias
    * @created         08/07/2025
    * @description     Método que recibiendo como parámetro un string, deserializa un JSON para rellenar una lista de registros e insertalos
    * @param           String jsonList.
    * @return          NA
    **********************************************************************************************************/
    @future
    public static void insertAsincrono(String jsonList) {
        List<SObject> registrosSObject = (List<SObject>) JSON.deserialize(jsonList, List<SObject>.class);
        insert registrosSObject;
    }

    /*********************************************************************************************************
    * @name            borrarData
    * @author          Guillermo Iglesias
    * @created         08/07/2025
    * @description     Método que recibiendo como parámetro un map, filtra por tipo de metadata para borrarlos de manera asíncrona o no
    * @param           Map<String, List<SObject>> mapObjectsToDelete.
    * @return          NA
    **********************************************************************************************************/
    private static void borrarData(Map<String, List<SObject>> mapObjectsToDelete) {
        for (String key : mapObjectsToDelete.keySet()) {
            List<SObject> listaRegistroSObject = mapObjectsToDelete.get(key);

            if (key == 'Object') {
                borrarAsincrono(JSON.serialize(listaRegistroSObject));
            } else {
                Database.delete(listaRegistroSObject, false);
            }
        }
    }

    /*********************************************************************************************************
    * @name            borrarAsincrono
    * @author          Guillermo Iglesias
    * @created         08/07/2025
    * @description     Método que recibiendo como parámetro un string, deserializa un JSON para rellenar una lista de registros y borrarlos
    * @param           String jsonList.
    * @return          NA
    **********************************************************************************************************/
    @future
    public static void borrarAsincrono(String jsonList) {
        List<SObject> registrosObject = (List<SObject>) JSON.deserialize(jsonList, List<SObject>.class);
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

    @future
    public static void logErrorFuture(String errorMessage, String errorTrace, String federationIdentifier, Id userId){
        logErrorSync(errorMessage, errorTrace, federationIdentifier, userId);
    }

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
    * @description     Método que recibiendo el id del usuario logueado y sus correspondientes metadata crea y devuelve los objetos para su posterior insercción
    * @param           String userId.
    * @param           Permission_Extended__mdt mdt.
    * @return          obj
    * @return          null
    **********************************************************************************************************/
    @TestVisible
    private static SObject crearObjeto(String userId, Permission_Extended__mdt mdt){
        // Obtener el nombre del objeto desde la Custom Metadata
        if (userId != null && mdt != null){
            User user = [SELECT id, id_user__c, email, firstName, lastName
                         FROM user
                         WHERE id = :userId];
            String objectName = mdt.Api_Name__c;
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
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
            if (gd.containsKey(objectName)){
                // Crear una instancia del objeto dinámicamente
                SObject obj = gd.get(objectName).newSObject();

                for (Integer i = 0; i < fields.size(); i++){
                    String field = fields[i];
                    String rawValue = values[i];
                    String realValue;
                    // Reemplazo de tokens dinámicos
                    if (rawValue == '{{userId}}'){
                        realValue = user.Id;
                    } else if (rawValue == '{{userEmail}}'){
                        realValue = user.Email;
                    } else if (rawValue == '{{userIduser}}'){
                        realValue = user.id_user__c;
                    } else if (rawValue == '{{name}}'){
                        realValue = user.FirstName + ' ' + user.LastName;
                    } else{
                        realValue = rawValue;
                    }

                    obj.put(field, realValue);
                }

                return obj;
            } 
        }
        return null;
    }

    /*********************************************************************************************************
    * @name            obtenerRegistros
    * @author          Guillermo Iglesias
    * @created         08/07/2025
    * @description     Método que recibiendo el id del usuario logueado y sus correspondientes metadata crea una query donde obtiene y almacena los objetos para su borrado
    * @param           String userId.
    * @param           Permission_Extended__mdt mdt.
    * @return          returnList
    **********************************************************************************************************/
    private static List<SObject> obtenerRegistros(String userId, Permission_Extended__mdt mdt) {
        List<SObject> returnList = new List<SObject>();
        if (userId != null && mdt != null) {
            User user = [SELECT id, id_user__c, email, firstName, lastName
                         FROM user
                         WHERE id = :userId];
            String objectName = mdt.Api_Name__c;
            
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            
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
            if (gd.containsKey(objectName)){
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
                List<String> condiciones = new List<String>();
                for (Integer i = 0; i < fields.size(); i++) {
                    String field = fields[i];
                    String rawValue = values[i];
                    String realValue;
                    if (!fieldMap.containsKey(field)) {
                        throw new AuraHandledException('Campo no permitido: ' + field);
                    }
                    if (rawValue == '{{userId}}') {
                        realValue = user.Id;
                    } else if (rawValue == '{{userEmail}}') {
                        realValue = user.Email;
                    } else if (rawValue == '{{userIduser}}') {
                        realValue = user.id_user__c;
                    } else if (rawValue == '{{name}}') {
                        realValue = user.FirstName + ' ' + user.LastName;
                    } else {
                        realValue = rawValue;
                    }
                    condiciones.add(field + ' = \'' + String.escapeSingleQuotes(realValue) + '\''); // NOSONAR
                }
                String query = 'SELECT Id FROM ' + objectName; // NOSONAR
                if (!condiciones.isEmpty()) {
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
    * @description     Método que manega la inserción y borrado de miembros de grupos
    * @param           Id userId.
    * @param           List<String> groupNames.
    * @param           boolean isInsert.
    * @return          NA
    **********************************************************************************************************/
    @TestVisible
    private static void manageGroupMember(Id userId, List<String> groupNames, boolean isInsert){
        if (groupNames == null || groupNames.isEmpty() || userId == null)
            return;
       
        List<Group> grupos = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN:groupNames];

        if (grupos.isEmpty()) return;
        if (isInsert){
            List<GroupMember> membersToInsert = new List<GroupMember>();
            for (Group grupo : grupos){
                GroupMember gm = new GroupMember();
                gm.GroupId = grupo.Id;
                gm.UserOrGroupId = userId;
                membersToInsert.add(gm);
            }
            if (!membersToInsert.isEmpty()){
                insert membersToInsert;
            }

        }else{
            List<GroupMember> membersToDelete = [SELECT Id
                                                 FROM GroupMember
                                                 WHERE GroupId IN:grupos AND UserOrGroupId = :userId];
            if (!membersToDelete.isEmpty()){
                delete membersToDelete;
            }

        }
    }

    /*********************************************************************************************************
     * @name            createRoleOrHerarchy
     * @author          David Díaz
     * @created         06/05/2025
     * @description     Método que crea roles dinamicamente.
     * @param           UserUuaaInfoExtended.OrganizationalUnit orgUnit - Unidad organizativa adel usuario.
     * @return          Id - ID del rol creado.
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
                currentParentId = newRole.Id;
                finalRoleId = newRole.Id;
                existingRoleMap.put(code, newRole);
            }
        }

        return finalRoleId;
    }

}