/**********************************************************************************
* @author       Accenture
* @date         30/05/2016
* @description  Clase con la lógica del objeto User 
* @Revision     
                2018/10/04 Se crean los métodos @future para asignar/quitar usuarios al permissionSet que da acceso a los usuarios a Chatter.
                           Se ponen todos los métodos como static
*               2019/02/27 Añadida comprobación IF(!Test.isRunningTest()) para que no falle en los test la línea que se realiza "insert permissionSetList"
**********************************************************************************/
public class UserLogic {
    
    //-- CONSTRUCTORS
    //public UserLogic() {    
    //}



    //-- PUBLIC MEHOTDS
    /**
     * Método que en las cargas automatizadas de dataloader, informa a partir de los ProfileName/RoleName los campos obligatorios de User: ProfileID y UserRoleID.
     * Por defecto si no encuentra el nombre del ProfileName/RoleName inserta el ProfileID/UserRoleID definidos en el custom settings Application_Settings_Hierarchy__c.
     * Si el usuario no procede de una carga automática, no se le hace nada: Sólo los usuarios que proceden de una carga automática tienen informado los campos Dataloader_Profile_Name__c y Dataloader_Role_Name__c
     */
    public static void setUserProfileID_UserRoleID(List<User> newList) {
        map<String,ID> userProfileMap = getUserProfiles();
        map<String,ID> userRoleMap = getUserRoles();
        
        For (User newUser : newList ) {

            Boolean tieneRol = true;
            String perfil = !String.isBlank(newUser.Dataloader_Profile_Name__c)?newUser.Dataloader_Profile_Name__c.split(';').get(0):'';
            String rol = !String.isBlank(newUser.Dataloader_Role_Name__c)?newUser.Dataloader_Role_Name__c.split(';').get(0):'';

            // Asignando Perfil
            if ( !String.isBlank(perfil) ){

                if(perfil == 'Chatter External User' || perfil == 'Chatter Free User' || perfil == 'Chatter Moderator User') {

                    //newUser.UserPermissionsSupportUser = false;
                    //newUser.UserPermissionsMarketingUser = false;
                    newUser.Asset_Class__c = '';
                    tieneRol = false;

                }
                if(userProfileMap.get(perfil) != null) {

                    newUser.ProfileID = userProfileMap.get(perfil);

                } else {

                    System.debug('UserLogic.setUserProfileID_UserRoleID()'+'id: '+newUser.id+'\r\nObject: User\r\nError: El perfil '+perfil+' no existe.');
                    newUser.ProfileID = Application_Settings_Hierarchy__c.getOrgDefaults().Default_Dataloader_ProfileID__c;

                }

                system.debug(Logginglevel.INFO,'>>>>>>> Profile: "' + perfil + '" - Profile Id Asignado: "' + newUser.ProfileID + '"');
                newUser.Dataloader_Profile_Name__c = '';

            } else {

                System.debug('UserLogic.setUserProfileID_UserRoleID()' + 'id: '+newUser.id+'\r\nObject: User\r\nError: No se puede cargar un User sin perfil.');

            }
            
            // Asignando Rol
            if ( !String.isBlank(rol)){

                if(tieneRol) {

                    if(userRoleMap.get(rol) != null) {

                        newUser.UserRoleId = userRoleMap.get(rol);

                    } else {

                        System.debug('UserLogic.setUserProfileID_UserRoleID()'+ 'id: '+newUser.id+'\r\nObject: User\r\nError: El rol '+rol+' no existe.');
                        newUser.UserRoleId = Application_Settings_Hierarchy__c.getOrgDefaults().Default_Dataloader_RoleID__c;

                    }

                    system.debug(Logginglevel.INFO,'>>>>>>> Role: "' + rol + '" - Role Id Asignado: "' + newUser.UserRoleId + '"');

                }

                newUser.Dataloader_Role_Name__c = '';

            }
                        
        }
        
    }

    

    //-- PRIVATE METHODS    
    private static map<String,ID> getUserProfiles(){
        map<String,ID> userProfileMap = new map<String,ID>();
        List<Profile> userProfileList = [SELECT Id, Name FROM Profile];
        
        system.debug(Logginglevel.INFO,'>>>>>>> Lista de Profiles recuperados: ' + userProfileList);  
        for (Profile u :userProfileList ){
            userProfileMap.put(u.Name,u.Id);            
        }
                 
        return userProfileMap;
    }
    
    private static map<String,ID> getUserRoles(){
        map<String,ID> userRoleMap = new map<String,ID>();
        List<UserRole> userRoleList = [SELECT Id, Name FROM UserRole];
        
        system.debug(Logginglevel.INFO,'>>>>>>> Lista de Roles recuperados: ' + userRoleList);  
        for (UserRole u :userRoleList ){
            userRoleMap.put(u.Name,u.Id);           
        }
                 
        return userRoleMap;
    }



    @future 
    public static void assignPermissionSet(Id permSetId,Set<Id> usersId) {    
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        for (Id usId : usersId){ 
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = permSetId, AssigneeId = usId);
            permissionSetList.add(psa);
        }
         Database.SaveResult[] saveResultList = Database.insert(permissionSetList, false);

    }


    @future 
    public static void removePermissionSet(Id permSetId,Set<Id> usersId) {
        List<PermissionSetAssignment> permissionSetList = [Select Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :permSetId AND AssigneeId IN :usersId];
        if (!permissionSetList.isEmpty()){
            delete permissionSetList;
        }
    
  }    
    
    
}