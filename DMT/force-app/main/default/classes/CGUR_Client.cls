/*-------------------------------------------------------------------------------------------
* @Name     CGUR Client
* @Author   torcuato.tejada.tech@bbva.com
*           roberto.rioboo.contractor@bbva.com
* @Date     Created: 2026-02-10
* -------------------------------------------------------------------------------------------
* @Description  implementation of ClientInterface
* -------------------------------------------------------------------------------------------
*/
global with sharing class CGUR_Client implements cgur.ClientInterface {

    // List of participant roles to consider when retrieving managed clients and groups from BBVA Management Team. These roles are defined in the DES_Participant_Role__c object.
    private static final List<String> PARTICIPANT_ROLES = new List<String>{'RCREDF', 'RCREDS', 'REQUIF', 'REQUIS', 'RFORES', 'RFOREF', 'RRATEF', 'RRATES'};

    @TestVisible
    private static Boolean clientGuruAdminPermissionOverride;

    private static Boolean hasClientGuruAdminPermission() {
        if (clientGuruAdminPermissionOverride != null) {
            return clientGuruAdminPermissionOverride;
        }
        return FeatureManagement.checkPermission('cgur__ViewAllClientGuruClients');
    }

    /*
    * @description Retrieve a list of clients managed by a user
    * @param userId : Id of the user
    * @return cgur.Client.Wrapper containing a list of StarId codes for clients and groups
    */
    public cgur.Client.Wrapper getManagedClients(Id userId) {
       if (hasClientGuruAdminPermission()) {
            return getAllGroups(userId);
        } else {
            return getManagedGroupClients(userId, null);
        }
    }

    /*
    * @description Retrieve a list of clients managed by a user in a specific group
    * @param userId : Id of the user
    * @return cgur.Client.Wrapper containing a list of StarId codes for clients and groups
    */
    public cgur.Client.Wrapper getManagedGroupClients(Id userId, String groupCode) {

        final cgur.Client.Wrapper wrapper = new cgur.Client.Wrapper();
        final Map<String, cgur.Client.Item> clientsById = new Map<String, cgur.Client.Item>();
        final Map<String, cgur.Client.Item> groupsById = new Map<String, cgur.Client.Item>();
        final Map<String, Object> uo = getUO(userId);
        String uoValue = (String)uo.get('uo');
        Integer level = (Integer)uo.get('level');

        // get all users under the user uo as the user to retrieve all clients they manage
        if (hasClientGuruAdminPermission()) {
            String configuredTopUo = cgur.Utils.getConfiguration('cgur__TopUO__c');
            String configuredTopUoLevel = cgur.Utils.getConfiguration('cgur__TopUOLevel__c');
            uoValue = String.isBlank(configuredTopUo) ? '0' : configuredTopUo;
            level = Integer.valueOf(String.isBlank(configuredTopUoLevel) ? '10' : configuredTopUoLevel);
        }

        System.debug('GET GROUP FROM CLIENT - UO: ' + uoValue + ' - LEVEL: ' + level);

        List<User> users = new List<User>();

        if (uoValue == null || level == null) {
            users.add(new User(Id = userId));
        } else {
            final String uoLevel = String.valueOf(level);
            final String nextLevel = (level == 10) ? '10' : String.valueOf(level+1);
            final String escapedUoValue = String.escapeSingleQuotes(uoValue);
            String usersQuery  = 'SELECT Id FROM User WHERE (Id = \'' + String.escapeSingleQuotes(String.valueOf(userId)) + '\' OR (DES_LevelUO_' + uoLevel + '__c = \'' + escapedUoValue + '\' AND DES_LevelUO_' + nextLevel + '__c != \'' + escapedUoValue + '\')) AND IsActive = true WITH SECURITY_ENFORCED';
            users = Database.query(usersQuery);
        }

        // WORKAROUND TO GET ONLY CLIENTS MANAGED BY THE USERS TO AVOID HITTING QUERY LIMIT
        // GROUPS ARE NOT RETURNED IN THIS CASE

        // retrieve clients managed by user which are assigned in the management team object
        // filtered by group if groupCode is provided. Only clients with a (g_customer_id__c) are retrieved
        Set<Id> subsidiaryIds = new Set<Id>();
        List<DES_BBVA_Management_team__c> subsidiaries;
        if (String.isBlank(groupCode)) {
            subsidiaries = [
                SELECT DES_Client__c, DES_Client__r.Name, DES_Client__r.g_customer_id__c,
                DES_Client__r.DES_Main_Parent__r.Name, DES_Client__r.DES_Main_Parent__r.DES_Group_Code__c
                FROM DES_BBVA_Management_team__c
                WHERE DES_User__c IN :users
                AND DES_Client__r.gf_prtcpt_act_status_ind_type__c = true
                AND DES_Client__r.g_customer_id__c != ''
                AND participant_role_id__c IN :PARTICIPANT_ROLES
                WITH SECURITY_ENFORCED
            ];
        } else {
            subsidiaries = [
                SELECT DES_Client__c, DES_Client__r.Name, DES_Client__r.g_customer_id__c,
                DES_Client__r.DES_Main_Parent__r.Name, DES_Client__r.DES_Main_Parent__r.DES_Group_Code__c
                FROM DES_BBVA_Management_team__c
                WHERE DES_User__c IN :users
                AND DES_Client__r.g_customer_id__c != ''
                AND DES_Client__r.gf_prtcpt_act_status_ind_type__c = true
                AND DES_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode
                AND participant_role_id__c IN :PARTICIPANT_ROLES
                WITH SECURITY_ENFORCED
            ];
        }

        for (DES_BBVA_Management_team__c team : subsidiaries) {
            String clientId = team.DES_Client__r.g_customer_id__c;
            String groupId = team.DES_Client__r.DES_Main_Parent__r.DES_Group_Code__c;
            if (!clientsById.containsKey(String.valueOf(clientId))) {
                cgur.Client.Item clientItem = new cgur.Client.Item();
                clientItem.id = String.valueOf(clientId);
                clientItem.name = team.DES_Client__r.Name;
                clientsById.put(String.valueOf(clientId), clientItem);
            }
            if (groupId != null && !groupsById.containsKey(String.valueOf(groupId))) {
                cgur.Client.Item groupItem = new cgur.Client.Item();
                groupItem.id = String.valueOf(groupId);
                groupItem.name = team.DES_Client__r.DES_Main_Parent__r.Name;
                groupsById.put(String.valueOf(groupId), groupItem);
            }
        }
        // END OF WORKAROUND

        System.debug('Clients:' + clientsById.size());
        System.debug('Groups:' + groupsById.size());

        wrapper.clients = new List<String>(clientsById.keySet());
        wrapper.subsidiaries = new List<cgur.Client.Item>(clientsById.values());
        wrapper.groups = new List<cgur.Client.Item>(groupsById.values());

        // if clients and groups are empty, it means the user does not manage any client so we add a dummy
        // client to differentiate between users with no clients and users access to all clients
        if (wrapper.clients.isEmpty() && wrapper.groups.isEmpty() && !hasClientGuruAdminPermission()) {
            wrapper.clients = new List<String>{'001'};
        }

        return wrapper;
    }

    /**
    * @description Retrieve the organizational unit of a user
    * @param userId : Id of the user
    * @return String representing the organizational unit of the user
    */
    public static Map<String, Object> getUO(Id userId) {
        String uo;
        Integer level;
        User usr = [SELECT Id, Name,
                    DES_LevelUO_10__c, DES_LevelUO_9__c, DES_LevelUO_8__c,
                    DES_LevelUO_7__c, DES_LevelUO_6__c, DES_LevelUO_5__c,
                    DES_LevelUO_4__c, DES_LevelUO_3__c, DES_LevelUO_2__c,
                    DES_LevelUO_1__c
                    FROM User
                    WHERE Id = :userId
                    WITH SECURITY_ENFORCED];

        for (Integer i = 10; i > 1; i--) {
            if (usr.get('DES_LevelUO_' + i + '__c') != usr.get('DES_LevelUO_' + (i-1) + '__c')) {
                uo = (String)usr.get('DES_LevelUO_' + i + '__c');
                level = i;
                break;
            }
        }
        return new Map<String, Object>{ 'uo' => uo, 'level' => level };
    }

    /**
    * @description Get only groups, used when ViewAllClientGuruClients is enabled
    * @return cgur.Client.Wrapper containing a list of group IDs and names
    *
    */
    public cgur.Client.Wrapper getAllGroups(Id userId) {

        cgur.Client.Wrapper wrapper = new cgur.Client.Wrapper();
        wrapper.clients = new List<String>();
        wrapper.subsidiaries = new List<cgur.Client.Item>();
        wrapper.groups = new List<cgur.Client.Item>();

        List<String> groupCodes = new List<String>();

        // get uo and level
        //final Map<String, Object> uo = getUO(userId);
        //final String uoValue = (String)uo.get('uo');
        //final Integer level = (Integer)uo.get('level');
        //final String uoLevel = String.valueOf(level);
        //final String nextLevel = (level == 10) ? '10' : String.valueOf(level+1);

        final String configuredTopUo = cgur.Utils.getConfiguration('cgur__TopUO__c');
        final String configuredTopUoLevel = cgur.Utils.getConfiguration('cgur__TopUOLevel__c');
        final String uoValue = String.isBlank(configuredTopUo) ? '0' : configuredTopUo;
        final String uoLevel = String.isBlank(configuredTopUoLevel) ? '10' : configuredTopUoLevel;
        final String nextLevel = String.valueOf(Integer.valueOf(uoLevel) + 1);
        final String escapedUoValue = String.escapeSingleQuotes(uoValue);

        // retrieve groups from management team based on user uo and level
        String groupsQuery  = 'SELECT DES_Client__r.DES_Main_Parent__r.DES_Group_Code__c groupCode ' +
                              'FROM DES_BBVA_Management_team__c ' +
                              'WHERE DES_User__r.Id = \'' + String.valueOf(userId) + '\' OR (DES_User__r.DES_LevelUO_' + uoLevel + '__c = \'' + escapedUoValue + '\'' + (Integer.valueOf(uoLevel) < 10 ? ' AND DES_User__r.DES_LevelUO_' + nextLevel + '__c != \'' + escapedUoValue + '\'' : '') + ') ' +
                              'GROUP BY DES_Client__r.DES_Main_Parent__r.DES_Group_Code__c ';

                              //'WITH SECURITY_ENFORCED';

        System.debug('Groups Query: ' + groupsQuery);

        List<AggregateResult> groupsResults = Database.query(groupsQuery);

        for (AggregateResult ar : groupsResults) {
            String groupCode = (String)ar.get('groupCode');
            if (groupCode != null) {
                groupCodes.add(groupCode);
            }
        }

        // retrieve group details based on group codes
        Map<String, cgur.Client.Item> groupsById = new Map<String, cgur.Client.Item>();
        for (Account acc : [
            SELECT DES_Group_Code__c, Name
            FROM Account
            WHERE DES_Structure_Type__c = 'Group'
            AND DES_Group_Code__c IN :groupCodes
            WITH SECURITY_ENFORCED
        ]) {
            if (!groupsById.containsKey(acc.DES_Group_Code__c) && acc.DES_Group_Code__c != 'GRPBBVAINTERNAL') {
                cgur.Client.Item groupItem = new cgur.Client.Item();
                groupItem.id = acc.DES_Group_Code__c;
                groupItem.name = acc.Name;
                groupsById.put(groupItem.id, groupItem);
            }
        }
        wrapper.groups = new List<cgur.Client.Item>(groupsById.values());
        return wrapper;
    }

    public cgur.Client.Wrapper getAllGroups(Id userId, String groupCode) {
        cgur.Client.Wrapper wrapper = new cgur.Client.Wrapper();
        wrapper.clients = new List<String>();
        wrapper.subsidiaries = new List<cgur.Client.Item>();
        wrapper.groups = new List<cgur.Client.Item>();

        // retrieve all groups without filtering by group code since this method is only called when ClientGuruAdmin permission is enabled
        Map<String, cgur.Client.Item> groupsById = new Map<String, cgur.Client.Item>();
        for (Account acc : [
            SELECT DES_Group_Code__c, Name
            FROM Account
            WHERE DES_Structure_Type__c = 'Group'
            AND DES_Group_Code__c != 'GRPBBVAINTERNAL'
            WITH SECURITY_ENFORCED
        ]) {
            if (!groupsById.containsKey(acc.DES_Group_Code__c) && acc.DES_Group_Code__c != 'GRPBBVAINTERNAL') {
                cgur.Client.Item groupItem = new cgur.Client.Item();
                groupItem.id = acc.DES_Group_Code__c;
                groupItem.name = acc.Name;
                groupsById.put(groupItem.id, groupItem);
            }
        }
        wrapper.groups = new List<cgur.Client.Item>(groupsById.values());
        return wrapper;
    }

    /**
    * @description Get the current group of a recordId
    * @param recordId : Id of the record
    * @return String  Group code of the current group or client of the record
    */
    public String getGroup(Id accountId) {
        String groupCode;
        Account acc = [
            SELECT DES_Structure_Type__c, DES_Group_Code__c, DES_Main_Parent__r.DES_Group_Code__c
            FROM Account
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
        ];
        if (acc.DES_Structure_Type__c == 'Subsidiary' && acc.DES_Main_Parent__r.DES_Group_Code__c != null) {
            groupCode = acc.DES_Main_Parent__r.DES_Group_Code__c;
        } else if (acc.DES_Structure_Type__c == 'Group' && acc.DES_Group_Code__c != null) {
            groupCode = acc.DES_Group_Code__c;
        }
        return groupCode;
    }

}