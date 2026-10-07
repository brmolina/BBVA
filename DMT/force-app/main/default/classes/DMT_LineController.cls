public without sharing class DMT_LineController {

    private static final String ACCESS_LEVEL_EDIT = 'accessLevel_edit';
    private static final String IS_ADMIN = 'isAdmin';
    // CIBGLOBALD-3779: catalog Id the old cfSummaryTreasury_Flexcard used for its "Type of risk"
    // combobox (DmSummaryTreasuryFlexCard_1 DataRaptor, filter DMT_Catalog__c = 'B444') — matched
    // exactly so dmt_lineInfo's Type of risk field offers the same options.
    private static final String TYPE_OF_RISK_CATALOG = 'B444';
    // CIBGLOBALD-3779: catalog Id backing the old cfSummaryTreasury_Flexcard's "Entific" display
    // value (Booking_Geography__c's country code expanded to "code - country name", e.g. "ES -
    // Spain"). Sourced from LINE_SummaryTreasury_Procedure_6, which maps Booking_Geography__c as
    // the DataRaptor's input and concatenates its DMT_Value__c/DMT_Name_EN__c output.
    private static final String COUNTRY_CATALOG = 'C245';
    // CIBGLOBALD-3779: catalog Id backing the old cfSummaryTreasury_Flexcard's "Committed /
    // Uncommitted" combobox (DmSummaryTreasuryFlexCard_1 DataRaptor, filter DMT_Catalog__c =
    // 'H405') — matched exactly so dmt_lineInfo's Committed/Uncommitted field offers the same
    // options.
    private static final String COMMITMENT_CATALOG = 'H405';

    public class TypeOfRiskOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    public class CommitmentOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    public class CurrencyOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    @AuraEnabled(cacheable=true)
    public static List<TypeOfRiskOption> getTypeOfRiskOptions() {
        // Deduped by DMT_Value__c: this catalog has duplicate value/label rows (same underlying
        // taxonomy-catalog data-quality issue as the Products catalog elsewhere in DMT), which
        // would otherwise show the same option twice in the combobox.
        Map<String, TypeOfRiskOption> optionsByValue = new Map<String, TypeOfRiskOption>();
        for (DMT_Taxonomy_Values__c taxonomyValue : [
            SELECT DMT_Value__c, DMT_Name_EN__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :TYPE_OF_RISK_CATALOG
            WITH SYSTEM_MODE
            ORDER BY DMT_Name_EN__c ASC
        ]) {
            if (optionsByValue.containsKey(taxonomyValue.DMT_Value__c)) {
                continue;
            }
            TypeOfRiskOption option = new TypeOfRiskOption();
            option.value = taxonomyValue.DMT_Value__c;
            option.label = taxonomyValue.DMT_Name_EN__c;
            optionsByValue.put(taxonomyValue.DMT_Value__c, option);
        }
        return optionsByValue.values();
    }

    @AuraEnabled(cacheable=true)
    public static List<CommitmentOption> getCommitmentOptions() {
        // Deduped by DMT_Value__c — same taxonomy-catalog data-quality issue as
        // getTypeOfRiskOptions above.
        Map<String, CommitmentOption> optionsByValue = new Map<String, CommitmentOption>();
        for (DMT_Taxonomy_Values__c taxonomyValue : [
            SELECT DMT_Value__c, DMT_Name_EN__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :COMMITMENT_CATALOG
            WITH SYSTEM_MODE
            ORDER BY DMT_Name_EN__c ASC
        ]) {
            if (optionsByValue.containsKey(taxonomyValue.DMT_Value__c)) {
                continue;
            }
            CommitmentOption option = new CommitmentOption();
            option.value = taxonomyValue.DMT_Value__c;
            option.label = taxonomyValue.DMT_Name_EN__c;
            optionsByValue.put(taxonomyValue.DMT_Value__c, option);
        }
        return optionsByValue.values();
    }

    @AuraEnabled(cacheable=true)
    public static List<CurrencyOption> getCurrencyOptions() {
        List<CurrencyOption> options = new List<CurrencyOption>();
        for (CurrencyType currencyType : [
            SELECT IsoCode
            FROM CurrencyType
            WHERE IsActive = true
            WITH SYSTEM_MODE
            ORDER BY IsoCode ASC
        ]) {
            CurrencyOption option = new CurrencyOption();
            option.value = currencyType.IsoCode;
            option.label = currencyType.IsoCode;
            options.add(option);
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static String getEntificDisplayValue(String geographyCode) {
        if (String.isBlank(geographyCode)) {
            return null;
        }
        List<DMT_Taxonomy_Values__c> matches = [
            SELECT DMT_Name_EN__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :COUNTRY_CATALOG AND DMT_Value__c = :geographyCode
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        if (matches.isEmpty() || String.isBlank(matches[0].DMT_Name_EN__c)) {
            return geographyCode;
        }
        return geographyCode + ' - ' + matches[0].DMT_Name_EN__c;
    }

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

        List<SObject> records = Database.query(String.escapeSingleQuotes(soql), AccessLevel.SYSTEM_MODE);

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
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1];

        // Check if the user is a System Administrator
        Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
        result.put('isAdmin', isAdmin);

        if (isAdmin) {
            result.put('accessLevel_edit', true);
            return result;
        }

        List<DMT_Line__c> lineRecords = [SELECT Id, OwnerId FROM DMT_Line__c WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
        if (!lineRecords.isEmpty() && lineRecords[0].OwnerId == UserInfo.getUserId()) {
            hasAccessOwner = true;
        }

        if (!hasAccessOwner) {
            List<Opportunity> oppRecords = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
            if (!oppRecords.isEmpty() && oppRecords[0].OwnerId == UserInfo.getUserId()) {
                hasAccessOwner = true;
            }
        }

        if (hasAccessOwner) {
            result.put('accessLevel_edit', true);
            return result;
        }

        // Query the DMT_TeamMember__c object for the AccessLevel__c field
        List<DMT_TeamMember__c> teamMembers = [
            SELECT AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__r.Id = :recordId AND User__c = :UserInfo.getUserId()
            WITH SYSTEM_MODE
        ];

        if (teamMembers.isEmpty()) {
            teamMembers = [
                SELECT AccessLevel__c
                FROM DMT_TeamMember__c
                WHERE Opportunity__c = :recordId AND User__c = :UserInfo.getUserId()
                WITH SYSTEM_MODE
                LIMIT 1
            ];
        }

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

        // Boolean userPermissionRole = DMT_Utils.hasWriteAccess();

        // // If the user is an admin, no need to query further
        // if(!userPermissionRole){
        //     result.put('accessLevel_read', false);
        //     return result;
        // }
        // Get the current logged-in user
        User currentUser = [SELECT Profile.Name, DMT_User_Role__c FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1];

        // Check if the user is a System Administrator
        Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
        result.put('isAdmin', isAdmin);

        if (isAdmin) {
            result.put('accessLevel_read', true);
            return result;
        }

        List<DMT_Line__c> lineRecords = [SELECT Id, OwnerId FROM DMT_Line__c WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
        if (!lineRecords.isEmpty() && lineRecords[0].OwnerId == UserInfo.getUserId()) {
            hasAccessOwner = true;
        }

        if (!hasAccessOwner) {
            List<Opportunity> oppRecords = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
            if (!oppRecords.isEmpty() && oppRecords[0].OwnerId == UserInfo.getUserId()) {
                hasAccessOwner = true;
            }
        }

        if (hasAccessOwner) {
            result.put('accessLevel_read', true);
            return result;
        }

        // Query the DMT_TeamMember__c object for the AccessLevel__c field
        List<DMT_TeamMember__c> teamMembers = [
            SELECT AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__r.Id = :recordId AND User__c = :UserInfo.getUserId()
            WITH SYSTEM_MODE
        ];

        if (teamMembers.isEmpty()) {
            teamMembers = [
                SELECT AccessLevel__c
                FROM DMT_TeamMember__c
                WHERE Opportunity__c = :recordId AND User__c = :UserInfo.getUserId()
                WITH SYSTEM_MODE
                LIMIT 1
            ];
        }

        String userRole = currentUser.DMT_User_Role__c == null ? '' : currentUser.DMT_User_Role__c;
        if (teamMembers.isEmpty() && !userRole.contains('DMT_Read Only')) {
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
        result.put('accessLevel_read', false);
        result.put(IS_ADMIN, false);
        result.put('isGod', false);
        result.put('isOwner', false);
        result.put('isTeamMemberEmpty', false);
        result.put('isTeamMemberRead', false);
        result.put('isTeamMemberEdit', false);
        result.put('isTeamMemberApprovalEdit', false);

        Boolean userPermissionRole = DMT_Utils.hasWriteAccess();
        result.put('isReadOnlyRole', !userPermissionRole);


        // 1. Admin
        Boolean isAdmin = DMT_PermissionSelector.isCurrentUserAdmin();
        result.put(IS_ADMIN, isAdmin);

        // 2. God permission (evaluated for all users, including admins)
        Boolean isGod = FeatureManagement.checkPermission('DMT_Line_God');
        result.put('isGod', isGod);

        if (isAdmin) {
            result.put('accessLevel_read', true);
        }

        if (isGod) {
            result.put('accessLevel_read', true);
            result.put(ACCESS_LEVEL_EDIT, userPermissionRole);
        }

        // 3. Owner
        Opportunity opp = DMT_PermissionSelector.getOpportunityById(oppId);
        if (opp != null && opp.OwnerId == UserInfo.getUserId()) {
            result.put(ACCESS_LEVEL_EDIT, userPermissionRole);
            result.put('accessLevel_read', true);
            result.put('isOwner', true);
        }

        // 4. Team member
        List<DMT_TeamMember__c> teamMembers = [
            SELECT AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE Opportunity__c = :oppId AND User__c = :UserInfo.getUserId()
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        if (teamMembers.isEmpty()) {
            result.put('isTeamMemberEmpty', true);
            return result;
        }

        result.put('accessLevel_read', true);
        result.put('isTeamMemberRead', true);
        if (teamMembers[0].AccessLevel__c == 'Edit' && userPermissionRole) {
            result.put(ACCESS_LEVEL_EDIT, true);
            result.put('isTeamMemberEdit', true);
            result.put('isTeamMemberApprovalEdit', teamMembers[0].DMT_ApprovalEdit__c);
        }

        return result;
    }
}