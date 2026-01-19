public with sharing class DES_BatchDesactivateUsers implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private List<String> userIdsToDeactivate;
    
    /*********************************************************************************************************
     * @name            DES_BatchDesactivateUsers
     * @author          Capgemini
     * @created         15/01/2025
     * @description     Constructor de la clase batch que inicializa los IDs de los usuarios a desactivar.
     * @param           List<User> usersToDeactivate - Lista de usuarios a desactivar.
     *********************************************************************************************************/
    public DES_BatchDesactivateUsers(List<User> usersToDeactivate) {
        if (usersToDeactivate == null || usersToDeactivate.isEmpty()) {
            throw new IllegalArgumentException('La lista de usuarios a desactivar no puede estar vacía.');
        }
        this.userIdsToDeactivate = new List<String>();
        for (User u : usersToDeactivate) {
            this.userIdsToDeactivate.add(u.Id);
        }
    }

    /**********************************************************************************************************
     * @name            start
     * @author          Capgemini
     * @created         15/01/2025
     * @description     Método inicial del batch que devuelve el conjunto de datos a procesar.
     * @param           Database.BatchableContext bc - Contexto del batch.
     * @return          Database.QueryLocator - Query que localiza los registros a procesar.
     *********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
        /*String query = 'SELECT Id, Id_User__c, ProfileId, IsActive ' + 
                     'FROM User WHERE IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ' + 
                     'AND Id IN :userIdsToDeactivate ' + 
                     'ORDER BY Id_User__c ASC';*/


        String query = 'SELECT Id, Id_User__c, ProfileId, IsActive, LastLoginDate '+
                     'FROM User WHERE IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ' + 
                     'AND Id IN :userIdsToDeactivate ' + 
                     'ORDER BY Id_User__c ASC';
        return Database.getQueryLocator(query);
    }

    /*********************************************************************************************************
     * @name            execute
     * @author          Capgemini
     * @created         15/01/2025
     * @description     Procesa un subconjunto de registros para desactivarlos.
     * @param           Database.BatchableContext bc - Contexto del batch.
     * @param           List<User> scope - Lista de usuarios a procesar en el lote actual.
     *********************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<User> scope) {

        List<User> usersToUpdate = new List<User>();
        String errorMessage;
        //Se comenta para aplicar solución temporal, el servicio actual no soporta el volumen de datos
        /*for (User user : scope) {
            user.IsActive = false;
            usersToUpdate.add(user);
        }
        if (!usersToUpdate.isEmpty()) {
            updateUsers(usersToUpdate);
        }*/

        List<User> usersToInactive = verifyInactiveUser(scope);

        if (!usersToInactive.isEmpty()) {
            for (User user : usersToInactive) {
                user.IsActive = false;
                usersToUpdate.add(user);
            }
            if (!usersToUpdate.isEmpty()) {
                updateUsers(usersToUpdate);
            }
        }
    }

    /*********************************************************************************************************
     * @name            verifyInactiveUser
     * @author          Capgemini
     * @created         03/05/2025
     * @description     Verifica usuarios de Salesforce que se deben deasctivar.
     * @return          List<User> - Una lista de usuarios a desactivar.
     *********************************************************************************************************/
    //Solución temporal, el servicio actual no soporta el volumen de datos
    @TestVisible
    private static List<User> verifyInactiveUser(List<User> usersToVerify) {
        Map<String, User> usersToUpdate = new Map<String, User> ();
        List<UserUuaaInfoExtended.Data> dataToValidate = new List<UserUuaaInfoExtended.Data>();
        Map<String, User> mapUsersToValidate = new Map<String, User>();
        Decimal diasDescontarDec = Profiling_lastLogin__mdt.getInstance('ultimoLogin').daysNoLogin__c;
        datetime fechaLastLogin = datetime.now()-diasDescontarDec;
        for (User user : usersToVerify) {
            Boolean userToDeactivate = true;
            if(user.LastLoginDate < fechaLastLogin){
                usersToUpdate.put(user.Id, user);
            }
            else{
                mapUsersToValidate.put(user.Id_User__c, user);
                Map<String, Object> request = new Map<String, Object>{ 'federationIdentifier' => user.Id_User__c };
                UserUuaaInfoExtended.wrapper wrapper = UserUuaaInfoExtended.getUserUuaaInfoExtended(request);
                
                if (wrapper.success) {
                    dataToValidate.add(wrapper.data);
                    UserUuaaInfoExtended.Data dataUser = wrapper.data;
                    if(dataUser.userCode == user.Id_User__c){
                        userToDeactivate = false;
                    }
                }
            } 
            if (userToDeactivate) {
                usersToUpdate.put(user.Id, user);
            }
        }

        for (UserUuaaInfoExtended.Data data : dataToValidate) {
            Boolean hasBasicConf = false;
            if(mapUsersToValidate.keySet().contains(data.userCode)){
                if (data.roles != null) {
                    for (UserUuaaInfoExtended.Role role : data.roles) {
                        if (role.resources != null) {
                            for (UserUuaaInfoExtended.Resource res : role.resources) {
                                if (res.name == 'Basic_Configuration') {
                                    hasBasicConf = true;
                                    break;
                                }
                            }
                        }
                    }
                }
                if (hasBasicConf) {
                    break;
                } else {
                    User userToDesActivate = mapUsersToValidate.get(data.userCode);
                    usersToUpdate.put(userToDesActivate.Id,userToDesActivate);
                }
            }
        }

        return usersToUpdate.values();
    }

    /*********************************************************************************************************
     * @name            finish
     * @author          Capgemini
     * @created         15/01/2025
     * @description     Método final del batch que ejecuta tareas post-procesamiento.
     * @param           Database.BatchableContext bc - Contexto del batch.
     *********************************************************************************************************/
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Batch finalizado.');
    }

    /*********************************************************************************************************
     * @name            updateUsers
     * @author          Capgemini
     * @created         15/01/2025
     * @description     Actualiza el estado de los usuarios a desactivado en Salesforce.
     * @param           List<User> usersToUpdate - Lista de usuarios a actualizar.
     *********************************************************************************************************/
    @TestVisible
    private void updateUsers(List<User> usersToUpdate) {
        try {
            if (!usersToUpdate.isEmpty()) {
                Database.update (usersToUpdate, false);
                System.debug(LoggingLevel.INFO, 'Usuarios desactivados correctamente: ' + usersToUpdate.size());
            }
            System.debug(usersToUpdate.size());
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Error al desactivar usuarios: ' + e.getMessage());
        }
    }

    /*********************************************************************************************************
     * @name            enqueueEmailForFailedUsers
     * @author          Capgemini
     * @created         15/01/2025
     * @description     Encola un trabajo para enviar correos a los administradores con los usuarios que no
     *                  pudieron desactivarse.
     * @param           List<User> failedUsers - Lista de usuarios que fallaron en el proceso de desactivación.
     * @param           String errorMessage - Mensaje de error asociado al fallo.
     *********************************************************************************************************/
    @TestVisible
    private void enqueueEmailForFailedUsers(List<User> failedUsers, String errorMessage) {
        if (failedUsers.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'No hay usuarios fallidos para procesar.');
            return;
        }

        System.debug(LoggingLevel.WARN, 'Encolando el envío de correos para usuarios fallidos.');
        UserDeactivationFailed_SendEmail queueableEmail = new UserDeactivationFailed_SendEmail(failedUsers, errorMessage);
        System.enqueueJob(queueableEmail);
    }

}