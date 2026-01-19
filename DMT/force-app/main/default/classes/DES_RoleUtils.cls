/**********************************************************************************
* @author       VASS - DSL
* @date         03/07/2018
* @description  Clase de utilidad con las funciones necesarias para obtener la jerarquía de roles y los usuarios con dichos roles 
* @Revision                     
**********************************************************************************/
public with sharing class DES_RoleUtils {
    
    public static Map<Id, User> getAllUserWithRoles(Set<Id> setRolesIds){
    	Map<Id, User> mapUsers = new Map<Id, User>([
    		SELECT Id, UserRoleId, Name
    		FROM User
    		WHERE UserRoleId IN :setRolesIds
    	]);
    	system.debug('>>>>> mapUsers : ' + mapUsers);
    	return mapUsers;
    }
    
    public static Set<Id> getAllSubRoleIds(Set<ID> roleIds) {
        Set<ID> currentRoleIds = new Set<ID>();
        for(UserRole userRole :[SELECT Id 
        						FROM UserRole 
        						WHERE ParentRoleId IN :roleIds AND ParentRoleID != null]) {
            currentRoleIds.add(userRole.Id);
        }
        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
    
        return currentRoleIds;
    }
    // To get all Parent Roles.
    /*public static Set<Id> getParentRoleId(Set<ID> roleIds) {

        Set<ID> currentRoleIds = new Set<ID>();
    
        
        // get all of the parent roles.
        for(UserRole ur :[select Id, ParentRoleId from UserRole where Id IN: roleIds]) {
            currentRoleIds.add(ur.ParentRoleId);
        }
    
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getParentRoleId(currentRoleIds));
        }
    
        return currentRoleIds;
    }*/

}