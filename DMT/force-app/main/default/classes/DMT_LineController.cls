public with sharing class DMT_LineController {

    private static final String ACCESS_LEVEL_EDIT = 'accessLevel_edit';
    private static final String IS_ADMIN = 'isAdmin';

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchRecords(String objectApiName, String recordTypeApiName, String searchTerm) {
        if(searchTerm.length() < 2) {
            throw new AuraHandledException('Search term must be at least 2 characters long.');
        }
        System.debug('searchRecords called with objectApiName: ' + objectApiName + ', recordTypeApiName: ' + recordTypeApiName + ', searchTerm: ' + searchTerm);
        String lineIdField;
        if (objectApiName == 'DMT_Line__c') {
            lineIdField = 'Line_Id__c';
        } else if (objectApiName == 'Opportunity') {
            lineIdField = 'DMT_Opp_Id__c';
        } else {
            throw new AuraHandledException('Unsupported object: ' + objectApiName);
        }

        String searchPattern = '%' + searchTerm + '%';

        String soql = 'SELECT Id, CurrencyIsoCode, ' + lineIdField +
            ' FROM ' + objectApiName +
            ' WHERE ' + lineIdField + ' LIKE :searchPattern' +
            ' AND RecordType.DeveloperName = :recordTypeApiName' +
            ' LIMIT 50';

        List<SObject> records = Database.query(String.escapeSingleQuotes(soql));

        List<Map<String, String>> results = new List<Map<String, String>>();
        for (SObject rec : records) {
            Map<String, String> recMap = new Map<String, String>();
            recMap.put('id', (String)rec.get('Id'));
            recMap.put('label', (String)rec.get(lineIdField));
            recMap.put('currencyIsoCode', (String)rec.get('CurrencyIsoCode'));
            results.add(recMap);
        }
        System.debug('searchRecords results, '+ JSON.serialize(results));
        return results;
    }

    /* @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchLines(String searchTerm) {
        // Hacer la búsqueda de las líneas que coincidan con el término de búsqueda
        List<DMT_Line__c> lines = [
            SELECT Id, Line_Id__c FROM DMT_Line__c
            WHERE Line_Id__c LIKE :('%' + searchTerm + '%')
            WITH SECURITY_ENFORCED
            LIMIT 50
        ];

        // Convertir la lista de líneas en un formato adecuado para el LWC
        List<Map<String, String>> lineResults = new List<Map<String, String>>();
        for (DMT_Line__c line : lines) {
            Map<String, String> lineMap = new Map<String, String>();
            lineMap.put('id', line.Id);
            lineMap.put('label', line.Line_Id__c);
            lineResults.add(lineMap);
        }

        return lineResults;
    } */

    /* @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchOpportunies(String searchTerm) {
        // Hacer la búsqueda de las oportunidades que coincidan con el término de búsqueda
        List<Opportunity> oppList = [
            SELECT Id, DMT_Opp_Id__c FROM Opportunity
            WHERE DMT_Opp_Id__c LIKE :('%' + searchTerm + '%')
            WITH SECURITY_ENFORCED
            LIMIT 50
        ];

        // Convertir la lista de oportunidades en un formato adecuado para el LWC
        List<Map<String, String>> oppResults = new List<Map<String, String>>();
        for (Opportunity opp : oppList) {
            Map<String, String> oppMap = new Map<String, String>();
            oppMap.put('id', opp.Id);
            oppMap.put('label', opp.DMT_Opp_Id__c);
            oppResults.add(oppMap);
        }
        return oppResults;
    } */

    @AuraEnabled
    public static Map<String, Boolean> checkEditPermission(String recordId) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        result.put('accessLevel_edit', false);
        result.put('isAdmin', null);
        Boolean hasAccessOwner = false;

        Boolean userPermissionRole = DMT_Utils.hasWriteAccess();

        // If the user is an admin, no need to query further
        if(!userPermissionRole){
            result.put('accessLevel_edit', false);
            return result;
        }
        // Get the current logged-in user
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Check if the user is a System Administrator
        Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
        result.put('isAdmin', isAdmin);

        if (isAdmin) {
            result.put('accessLevel_edit', true);
            return result;
        }

        DMT_Line__c line = [SELECT Id, OwnerId FROM DMT_Line__c WHERE Id = :recordId LIMIT 1];
        if (line.OwnerId == UserInfo.getUserId()) {
            hasAccessOwner = true;
        }

        if(hasAccessOwner){
            result.put('accessLevel_edit', true);
            return result;
        }

        // Query the DMT_TeamMember__c object for the AccessLevel__c field
        List<DMT_TeamMember__c> teamMembers = [
            SELECT AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__r.Id = :recordId AND User__c = :UserInfo.getUserId()
        ];

        if (teamMembers.isEmpty()) {
            result.put('accessLevel_edit', false);
            return result;
        } else {
            result.put('accessLevel_edit', teamMembers[0].AccessLevel__c == 'Edit');
            return result;
        }
    }

        @AuraEnabled
    public static Map<String, Boolean> checkReadPermission(String recordId) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        result.put('accessLevel_read', false);
        result.put('isAdmin', null);
        Boolean hasAccessOwner = false;

        Boolean userPermissionRole = DMT_Utils.hasWriteAccess();

        // If the user is an admin, no need to query further
        if(!userPermissionRole){
            result.put('accessLevel_read', false);
            return result;
        }
        // Get the current logged-in user
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Check if the user is a System Administrator
        Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
        result.put('isAdmin', isAdmin);

        if (isAdmin) {
            result.put('accessLevel_read', true);
            return result;
        }

        DMT_Line__c line = [SELECT Id, OwnerId FROM DMT_Line__c WHERE Id = :recordId LIMIT 1];
        if (line.OwnerId == UserInfo.getUserId()) {
            hasAccessOwner = true;
        }

        if(hasAccessOwner){
            result.put('accessLevel_read', true);
            return result;
        }

        // Query the DMT_TeamMember__c object for the AccessLevel__c field
        List<DMT_TeamMember__c> teamMembers = [
            SELECT AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__r.Id = :recordId AND User__c = :UserInfo.getUserId()
        ];

        if (teamMembers.isEmpty()) {
            result.put('accessLevel_read', false);
            return result;
        } else {
            result.put('accessLevel_read', true);
            return result;
        }
    }

    @AuraEnabled
    public static Map<String, Boolean> checkEditPermissionOpp(String oppId) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        result.put(ACCESS_LEVEL_EDIT, false);
        result.put(IS_ADMIN, false);

        Boolean isAdmin = DMT_PermissionSelector.isCurrentUserAdmin();
        result.put(IS_ADMIN, isAdmin);

        if (isAdmin) {
            result.put(ACCESS_LEVEL_EDIT, true);
            return result;
        }

        Opportunity opp = DMT_PermissionSelector.getOpportunityById(oppId);

        if (opp.OwnerId == UserInfo.getUserId()) {
            result.put(ACCESS_LEVEL_EDIT, true);
            return result;
        }

        List<DMT_TeamMember__c> teamMembers = DMT_PermissionSelector.getTeamMemberAccess(oppId);
        if (!teamMembers.isEmpty()) {
            result.put(ACCESS_LEVEL_EDIT, teamMembers[0].AccessLevel__c == 'Edit');
        }

        return result;
    }
}