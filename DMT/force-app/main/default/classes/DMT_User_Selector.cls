/*
Autor: vido
Fecha: 2024-02-27
*/
public without sharing class DMT_User_Selector {

    // Método para obtener el user contry
    public static User getLoginUser() {
        return [SELECT Id, DES_Country__c, Profile.Name, FederationIdentifier
                FROM User
                WHERE Id = :UserInfo.getUserId()
                /*WITH USER_MODE*/
                LIMIT 1];
    }

    //method used to take the id of a certain Custom permission
    public static CustomPermission getCustomPermission(String permissionName){
        return [SELECT Id FROM CustomPermission WHERE DeveloperName =: permissionName LIMIT 1];
    }

    //Method used to get the SetupEntityAccess of a certain custom permission
    public static List<SetupEntityAccess> getSetupEntityAccess(CustomPermission customPermissionId){
        return [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityType = 'CustomPermission' AND SetupEntityId =: customPermissionId.Id];
    }

}