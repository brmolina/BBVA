public with sharing class DMT_UserDataApexService {
    public static Map<String, Object> getUserData() {
        Map<String, Object> out = new Map<String, Object>();

        User u = [
            SELECT Id, DMT_User_Role__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        List<String> roles = new List<String>();
        if (!String.isBlank(u.DMT_User_Role__c)) {
            roles = u.DMT_User_Role__c.split(';');
        }

        out.put('roles', roles);
        out.put('hasWriteAccessUser', true);
        out.put('hasLineGodAccess', true);

        return out;
    }
}