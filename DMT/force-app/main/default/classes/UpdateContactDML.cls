/***
*   @author: GlobalDesktop
*   @Class: UpdateContactDML
*   @Description: Revisa los permisos del usuario sobre el registro
*   @Versions:
        v1 - 2019/03/XX - Initial version
**/
public with sharing class UpdateContactDML {

	/* pattern */
    private static UpdateContactDML instance;

    /**
    * @author Global Desktop
    * @description Constructor de la clase
    */
    private UpdateContactDML() {
    	system.debug('Constructor UpdateContactDML');
    }

    /**
	* @author Global Desktop
	* @description pattern
	*/
    public static UpdateContactDML getInstance() { //NOSONAR
        if(instance == null) {
            instance = new UpdateContactDML();
        }
        return instance;
    }

    /**
	* @author Global Desktop
	* @description updateContact
	*/
    public static Database.SaveResult updateContact(Contact contacto, String oldOwner) {
        System.debug('::::updateContact init :: ');
        System.debug('::::contacto:: ' + contacto);
        System.debug('::::oldOwner:: ' + oldOwner);
        System.debug('::::contacto.OwnerId:: ' + contacto.OwnerId);
        System.debug('::::UserInfo.getUserId():: ' + UserInfo.getUserId());
        //1) ar permisos share
        Database.SaveResult result;

        //2) update
        final Id userId = UserInfo.getUserId();
        List<GroupMember> lstGMembers;
        lstGMembers = getUserOrGroupIdSelector('Edit_Permissions_Desktop_ContactsGroup');
        System.debug('::::lstGMembers:: ' + lstGMembers);
        final List<String> lstUsers = new List<String>();
        if(!lstGMembers.isEmpty()) {
            for(GroupMember gMember : lstGMembers) {
                lstUsers.add(gMember.UserOrGroupId);
            }
        }
        final Boolean canModify = checkUserHasPermission(contacto, userId, oldOwner, lstUsers);
        System.debug('::::checkUserHasPermission == :: ' + canModify);
        if(canModify) {
            result = Database.update(contacto);
            System.debug('::::::updateContact:: ' + result);
        } else {
            result =  (Database.SaveResult)JSON.deserialize('{"success":false,"errors":[{"message":"You do not have permissions to edit the current contact","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
        }
        return result;
    }

    /**
	* @author Global Desktop
	* @description checkUserHasPermission
	*/
    private static Boolean checkUserHasPermission(Contact contacto, Id userId, Id oldOwner, List<String> lstUsers) {
        Boolean isValid;
        System.debug('::::checkUserHasPermission INIT == :: ' );
        System.debug('::::contacto == :: ' + contacto);
        System.debug('::::userId == :: ' + userId);
        System.debug('::::lstUsers == :: ' + lstUsers);
        isValid = false;
        if(contacto.OwnerId == userId || oldOwner == userId) {
            System.debug('::::contacto.OwnerId == userId:: ' );
            isValid = true;
        } else if(!lstUsers.isEmpty()) {
            System.debug('::::!lstUsers.isEmpty():: ' );
            if(lstUsers.contains(userId)) {
                System.debug('::::lstUsers.contains(userId):: ' );
                isValid = true;
            }
        }
        return isValid;
    }

    /**
	* @author Global Desktop
	* @description getUserOrGroupIdSelector
	*/
    private static List<GroupMember> getUserOrGroupIdSelector(String lstUsers) {
        List<GroupMember> lstGMembers;
        if(Schema.sObjectType.GroupMember.fields.UserOrGroupId.isAccessible()) {
            lstGMembers = [SELECT UserOrGroupId
                                        FROM GroupMember
                                        WHERE Group.DeveloperName = :lstUsers];
        } else {
            lstGMembers = new List<GroupMember>();
        }
        return lstGMembers;
    }
}