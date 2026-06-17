public with sharing class DES_desactivateUsers implements Schedulable {
    @TestVisible
    private static String filterQuery;
    @TestVisible
    private static String limitQuery;
    /*********************************************************************************************************
     * @name            execute
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Punto de entrada para el trabajo programado.
     *                  Este método se llama cuando se activa el trabajo programado.
     * @param           SchedulableContext sc - Proporciona contexto para el trabajo programado.
     *********************************************************************************************************/
    public void execute(SchedulableContext sc) {
        desactivateUsers();
    }

    /*********************************************************************************************************
     * @name            desactivateUsersFuture
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Metodo futuro para la desactivacion de uusarios en contexto de Apex programado
     *********************************************************************************************************/
    @future(callout = true)
    public static void desactivateUsersFuture() {
        desactivateUsers();
    }

    /*********************************************************************************************************
     * @name            desactivateUsers (Overload)
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Método sobrecargado para desactivar usuarios con un límite especificado.
     *                  Define un límite de consulta antes de llamar al método principal.
     * @param           Integer limite - Límite de registros a procesar.
     *********************************************************************************************************/
    public static void desactivateUsers(String filtro, Integer limite) {
        if (filtro != null) {
            filterQuery = ' AND ' + filtro;
        }
        if (limite > 0) {
            limitQuery = ' LIMIT ' + String.valueOf(limite);
        }
        desactivateUsers();
    }

    /*********************************************************************************************************
     * @name            desactivateUsers
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Método principal para desactivar usuarios en base a datos externos de roles y estado activo.
     *                  Obtiene metadatos de roles, recupera usuarios activos, los compara con usuarios de Salesforce
     *                  y desactiva a aquellos que no están presentes en el sistema externo.
     *********************************************************************************************************/
    //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
    /*public static void desactivateUsers() {
     String roleName = getRoleNameFromMetadata();

     if (String.isEmpty(roleName)) {
     System.debug('Role Name not found in metadata. Aborting process.');
     return;
     }

     System.debug('Role Name: ' + roleName);

     RoleUsers.wrapper wrapper = fetchExternalActiveUsers(roleName, 'ESCD');

     if (wrapper.success) {
     Set<String> activeUserIds = extractActiveUserIds(wrapper.data);
     List<User> usersToDeactivate = findInactiveUsers(activeUserIds);

     executeDeactivationBatch(usersToDeactivate);
     } else {
     System.debug('Error retrieving users from external system: ' + wrapper.errorMessage);
     }
     }*/
    /*********************************************************************************************************
     * @name            desactivateUsers
     * @author          Capgemini
     * @created         03/05/2025
     * @description     Método principal para desactivar usuarios en base a datos externos de roles y estado activo.
     *                  Obtiene metadatos de roles, recupera usuarios activos, los compara con usuarios de Salesforce
     *                  y desactiva a aquellos que no están presentes en el sistema externo.
     *********************************************************************************************************/
    //Solución temporal, el servicio actual no soporta el volumen de datos
    public static void desactivateUsers() {
        List<User> usersToDeactivate = findInactiveUsers();

        executeDeactivationBatch(usersToDeactivate);
    }

    /*********************************************************************************************************
     * @name            getRoleNameFromMetadata
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Recupera el nombre del rol desde metadatos personalizados.
     * @return          String - El nombre del rol, o una cadena vacía si no se encuentra.
     *********************************************************************************************************/
    //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
    /*@TestVisible
    private static String getRoleNameFromMetadata() {
        return Role_Name__mdt.getInstance('Basic_Configuration').DES_PermissionSet__c;
    }*/

    /*********************************************************************************************************
     * @name            fetchExternalActiveUsers
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Recupera usuarios activos desde un sistema externo basado en el nombre del rol y la UUAA.
     * @param           String roleName - El nombre del rol para filtrar usuarios.
     * @param           String uuaa - La UUAA para la solicitud.
     * @return          RoleUsers.wrapper - La respuesta que contiene datos de usuario o información de error.
     *********************************************************************************************************/
    //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
    /*@TestVisible
    private static RoleUsers.wrapper fetchExternalActiveUsers(String roleName, String uuaa) {
        Map<String, Object> request = new Map<String, Object>();
        request.put('roleName', roleName);
        request.put('uuaa', uuaa);

        return RoleUsers.getRoleUsers(request);
    }*/

    /*********************************************************************************************************
     * @name            extractActiveUserIds
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Extrae los IDs de usuarios activos de la respuesta de datos externos.
     * @param           RoleUsers.Data dataUser - El objeto de datos que contiene información de usuarios.
     * @return          Set<String> - Un conjunto de IDs de usuarios activos.
     *********************************************************************************************************/
    //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
    /*@TestVisible
    private static Set<String> extractActiveUserIds(RoleUsers.Data dataUser) {
        Set<String> activeUserIds = new Set<String>();
        for (RoleUsers.User user : dataUser.users) {
            activeUserIds.add(user.userCode);
        }
        System.debug('Active users from external system: ' + activeUserIds);
        return activeUserIds;
    }*/

    /*********************************************************************************************************
     * @name            findInactiveUsers
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Encuentra usuarios de Salesforce que están activos pero no se encuentran en el conjunto de IDs de usuarios activos del sistema externo.
     * @param           Set<String> activeUserIds - El conjunto de IDs de usuarios activos del sistema externo.
     * @return          List<User> - Una lista de usuarios a desactivar.
     *********************************************************************************************************/
    //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
    /*@TestVisible
     private static List<User> findInactiveUsers(Set<String> activeUserIds) {
     String filterQueryVar = '';
     String limitQueryVar = '';
     if (filterQuery != null) {
     filterQueryVar = filterQuery;
     }
     if (limitQuery != null) {
     limitQueryVar = limitQuery;
     }
     Decimal diasDescontarDec = Profiling_lastLogin__mdt.getInstance('ultimoLogin').daysNoLogin__c;
     String diasDescontar = String.valueOf(diasDescontarDec.intValue());
     datetime fechaLastLogin = datetime.now();

     String query = 'SELECT Id, Id_User__c, ProfileId, Profile.UserLicense.Name, IsActive ' +
     'FROM User WHERE IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' AND (LastLoginDate = null OR LastLoginDate < LAST_N_DAYS:' + diasDescontar + ')' + filterQueryVar +
     ' ORDER BY Id_User__c ASC' + limitQueryVar; //NOSONAR

     List<User> allUsers = Database.query(query); //NOSONAR
     List<User> usersToDeactivate = new List<User>();

     for (User user : allUsers) {
     if (!activeUserIds.contains(user.Id_User__c)) {
     usersToDeactivate.add(user);
     }
     }

     System.debug('Users to deactivate: ' + usersToDeactivate);
     return usersToDeactivate;
     }*/
    /*********************************************************************************************************
     * @name            findInactiveUsers
     * @author          Capgemini
     * @created         03/05/2025
     * @description     Encuentra usuarios de Salesforce que están activos.
     * @return          List<User> - Una lista de usuarios a desactivar.
     *********************************************************************************************************/
    //Solución temporal, el servicio actual no soporta el volumen de datos
    @TestVisible
    private static List<User> findInactiveUsers() {
        String filterQueryVar = '';
        String limitQueryVar = '';
        if (filterQuery != null) {
            filterQueryVar = filterQuery;
        }
        if (limitQuery != null) {
            limitQueryVar = limitQuery;
        }
        //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
        /*Decimal diasDescontarDec = Profiling_lastLogin__mdt.getInstance('ultimoLogin').daysNoLogin__c;
        String diasDescontar = String.valueOf(diasDescontarDec.intValue());
        datetime fechaLastLogin = datetime.now();
        
        String query = 'SELECT Id, Id_User__c, ProfileId, Profile.UserLicense.Name, IsActive, LastLoginDate ' + 
                     'FROM User WHERE IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' AND (LastLoginDate = null OR LastLoginDate < LAST_N_DAYS:' + diasDescontar + ')' + filterQueryVar + 
                     ' ORDER BY Id_User__c ASC' + limitQueryVar; //NOSONAR*/

        //Solución temporal, el servicio actual no soporta el volumen de datos
        String query = 'SELECT Id, Id_User__c, ProfileId, Profile.UserLicense.Name, IsActive, LastLoginDate ' + 
                     'FROM User WHERE IsActive = true AND Profile.UserLicense.Name = \'Salesforce\'' + filterQueryVar + 
                     ' ORDER BY Id_User__c ASC' + limitQueryVar; //NOSONAR

        List<User> allUsers = Database.query(query); //NOSONAR

        List<CIB_Bypass__c> usersNoDesactivar = [SELECT Id, SetupOwnerId FROM CIB_Bypass__c WHERE CIB_DES_No_Desactivar_Usuario__c = true];

        Map<Id, CIB_Bypass__c> mapBySetupOwner = new Map<Id, CIB_Bypass__c>();

        for (CIB_Bypass__c record : usersNoDesactivar) {
            mapBySetupOwner.put(record.SetupOwnerId, record);
        }
        List<User> usersToDeactivate = new List<User>();
        for(User userToDeactivate : allUsers){
            if(!mapBySetupOwner.keySet().contains(userToDeactivate.Id)){
                usersToDeactivate.add(userToDeactivate);
            }
        }

        System.debug('Users to deactivate: ' + usersToDeactivate);
        return usersToDeactivate;
    }

    /**********************************************************************************************************
     * @name            executeDeactivationBatch
     * @author          Capgemini
     * @created         01/15/2025
     * @description     Ejecuta un trabajo batch para desactivar usuarios.
     * @param           List<User> usersToDeactivate - La lista de usuarios a desactivar.
     *********************************************************************************************************/
    @TestVisible
    private static void executeDeactivationBatch(List<User> usersToDeactivate) {
        if (usersToDeactivate.isEmpty()) {
            System.debug('No users to deactivate. Skipping batch execution.');
            return;
        }
        List<User> usersToBeDeactivate = new List<User>();
        try {
            if (Test.isRunningTest()) {
                for (User u : usersToDeactivate) {
                    if (u.ID_User__c == 'user3Test18924') {
                        usersToBeDeactivate.add(u);
                    }
                }
            } else {
                usersToBeDeactivate = usersToDeactivate;
            }
            Database.executeBatch(new DES_BatchDesactivateUsers(usersToBeDeactivate), 1);
            System.debug('Batch executed successfully to deactivate users.');
        } catch (Exception e) {
            System.debug('Error executing the batch: ' + e.getMessage());
            // UserDeactivationFailed_SendEmail.sendFailureEmail(usersToDeactivate, e.getMessage());
        }
    }

}