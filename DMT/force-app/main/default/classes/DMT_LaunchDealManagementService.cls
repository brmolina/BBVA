/**
* @description Apex replacement for the OmniStudio IP DealManagement_launchDealManagement.
*              It keeps the same orchestration contract for workspace bootstrap.
*/
public with sharing class DMT_LaunchDealManagementService implements Callable {
    private static final String ACTION_NAME = 'launchDealManagement';
    private static final String DMT_OPPORTUNITY_RT_NAME = 'DMT Opportunity';
    private static final String NON_DISCLOSED_GROUP_CODE = 'GXXXXXXXXXXXXXX';

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');

        if (output == null) {
            output = new Map<String, Object>();
        }

        if (action == ACTION_NAME) {
            output.putAll(execute(input));
            return output;
        }

        throw new AuraHandledException('Unsupported action: ' + action);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> launchDealManagement(
        Id originId,
        String currentTab,
        String viewTab,
        String oppSelected,
        String productSelected,
        String originGroup,
        Boolean scopeToClient
    ) {
        Map<String, Object> input = new Map<String, Object>{
            'originId' => originId,
            'currentTab' => currentTab,
            'viewTab' => viewTab,
            'oppSelected' => oppSelected,
            'productSelected' => productSelected,
            'originGroup' => originGroup,
            'scopeToClient' => scopeToClient
        };

        return execute(input);
    }

    /**
     * Resolves the Salesforce Account that represents a group node selected in the
     * HPG tree. Subsidiaries can share DES_Group_Code__c with their parent, so they
     * must be explicitly excluded from this lookup.
     */
    @AuraEnabled(cacheable=true)
    public static Id resolveGroupAccountId(String groupCode) {
        if (String.isBlank(groupCode)) {
            return null;
        }

        List<Account> groupAccounts = [
            SELECT Id, DES_Structure_Type__c
            FROM Account
            WHERE DES_Group_Code__c = :groupCode
            AND DES_Structure_Type__c IN ('Supragroup', 'Group', 'Subgroup', 'Shared Management Group')
            WITH USER_MODE
            LIMIT 1
        ];
        return groupAccounts.isEmpty() ? null : groupAccounts[0].Id;
    }

    private static Map<String, Object> execute(Map<String, Object> input) {
        try {
            Id originId = (Id) input.get('originId');
            if (originId == null) {
                throw new AuraHandledException('originId is required');
            }

            String currentTab = String.isBlank((String) input.get('currentTab'))
                ? 'Lines'
                : (String) input.get('currentTab');

            String viewTab = String.isBlank((String) input.get('viewTab'))
                ? currentTab
                : (String) input.get('viewTab');

            String returnedDate = DMT_HPG_Utils.lastDate();
            String groupCode = DMT_HPG_Utils.getGroupId(originId);
            Boolean scopeToClient = input.get('scopeToClient') == true;

            Map<String, Object> response = buildWorkspaceResponse(
                originId,
                returnedDate,
                groupCode,
                currentTab,
                viewTab,
                (String) input.get('oppSelected'),
                (String) input.get('productSelected'),
                (String) input.get('originGroup'),
                scopeToClient
            );

            Map<String, Object> userInfo = buildUserInfo(response);
            response.put('UserInfo', userInfo);

            Boolean hasWriteAccessUser = (Boolean) userInfo.get('hasAccessWrite');
            Boolean hasLineGodAccess = (Boolean) userInfo.get('hasLineGodAccess');
            response.put('hasWriteAccessUser', hasWriteAccessUser);
            response.put('hasLineGodAccess', hasLineGodAccess);

            Boolean oppAccess = resolveOppAccess(
                (List<String>) userInfo.get('roles'),
                (String) response.get('groupCode'),
                (String) response.get('ClientId')
            );
            response.put('OppAccess', oppAccess);

            return response;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_LaunchDealManagementService', 'execute', 'DMT', '');
            throw new AuraHandledException('Error launching Deal Management: ' + e.getMessage());
        }
    }

    private static Map<String, Object> buildWorkspaceResponse(
        Id originId,
        String returnedDate,
        String groupCode,
        String currentTab,
        String viewTab,
        String oppSelected,
        String productSelected,
        String originGroupInput,
        Boolean scopeToClient
    ) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('originId', String.valueOf(originId));
        response.put('returnedDate', returnedDate);
        response.put('currentTab', currentTab);
        response.put('viewTab', viewTab);
        response.put('oppSelected', oppSelected);
        response.put('productSelected', productSelected);
        response.put('groupCode', groupCode);
        response.put('hasOpportunityListAccess', true);

        String originGroup = String.isBlank(originGroupInput) ? groupCode : originGroupInput;
        response.put('originGroup', originGroup);

        if (originGroup == NON_DISCLOSED_GROUP_CODE) {
            response.put('nonDisclosedCode', NON_DISCLOSED_GROUP_CODE);
        }

        // When the user explicitly selects a single client in the tree, the
        // Lines/Opportunities extraction must be scoped to that account only,
        // instead of always broadening to every account under the same group.
        Map<String, Object> extractInput = new Map<String, Object>{
            'originId' => originId,
            'currentTab' => currentTab,
            'viewTab' => viewTab,
            'groupCode' => (scopeToClient == true) ? null : groupCode,
            'ClientId' => String.valueOf(originId)
        };
        Map<String, Object> extractResult = DMT_ExtractOpportunityByClientMapper.extract(extractInput);
        response.putAll(extractResult);

        Account accountInfo = getAccountInfo(originId);

        // The first HPG row for a subsidiary also contains its parent groupId, so
        // inferring the selected node type from first.groupId incorrectly marks a
        // subsidiary launch as a group launch. The Salesforce Account is the source
        // of truth for the current selection context.
        if (accountInfo != null) {
            response.put(
                'clientType',
                accountInfo.DES_Structure_Type__c == 'Subsidiary' ? 'client' : 'group'
            );
        }

        // HPG's clientPositionsType='Y' means "With Exposure" — clients that actually have a
        // risk position. Prospects (Prospect_Group / Prospect_Subsidiary) never have a position
        // in HPG by definition, so requesting 'Y' for them always comes back with data=[] and
        // leaves the client/group tree empty. For Prospects we request '' (all positions,
        // unfiltered) instead, matching the fallback strategy already used elsewhere
        // (dmt_MainClientSelectionTable.fetchClientsForCountryMapping / DMT_CreateOpportunityService).
        Boolean isProspect = accountInfo != null && accountInfo.RecordType != null
            && String.isNotBlank(accountInfo.RecordType.DeveloperName)
            && accountInfo.RecordType.DeveloperName.startsWith('Prospect');

        DMT_HPG_GlobalPosition.Wrapper hpgData = (DMT_HPG_GlobalPosition.Wrapper)
            DMT_HPG_MainTableCustomController.fetchInitialData(
                'tcmopportunity',
                originId,
                new List<String>(),
                returnedDate,
                isProspect ? 'N' : 'Y',
                '1',
                '100',
                null
            );

        DMT_HPG_GlobalPosition.Data first = (hpgData != null && hpgData.data != null && !hpgData.data.isEmpty())
            ? hpgData.data[0]
            : null;

        // HPG only guarantees a trustworthy, non-anonymized name in groupName (for groups).
        // customerName can come back anonymized/tokenized by the source system for privacy
        // reasons, so for individual clients (and when HPG returns no data at all, e.g.
        // Prospects) we fall back to the Salesforce Account Name instead.
        response.put('groupName', String.isNotBlank(first?.groupName) ? first.groupName : (accountInfo != null ? accountInfo.Name : null));

        if (first != null) {
            if (!response.containsKey('ClientId') || String.isBlank((String) response.get('ClientId'))) {
                response.put('ClientId', String.isBlank(first.customerId) ? 'norecord' : first.customerId);
            }
            if (!response.containsKey('clientType')) {
                response.put('clientType', String.isBlank(first.groupId) ? 'client' : 'group');
            }
            if (!response.containsKey('taxpayerId')) {
                response.put('taxpayerId',first.taxpayerId);
            }
        }

        if (!response.containsKey('ClientId')) {
            response.put('ClientId', 'norecord');
        }
        if (!response.containsKey('clientType')) {
            response.put('clientType', 'client');
        }

        return response;
    }

    /**
     * @description Resolves the Account's Name and RecordType in a single query, used both to
     *              detect Prospect accounts (Prospect_Group / Prospect_Subsidiary) and to
     *              provide a trustworthy display name for the workspace header, independent of
     *              HPG (whose customerName can be anonymized/tokenized by the source system).
     */
    private static Account getAccountInfo(Id originId) {
        List<Account> acc = [
            SELECT Name, RecordType.DeveloperName, DES_Structure_Type__c
            FROM Account
            WHERE Id = :originId
            WITH USER_MODE
            LIMIT 1
        ];
        return acc.isEmpty() ? null : acc[0];
    }

    private static Map<String, Object> buildUserInfo(Map<String, Object> response) {
        User currentUser = [
            SELECT DMT_User_Role__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        List<String> roles = new List<String>();
        if (!String.isBlank(currentUser.DMT_User_Role__c)) {
            roles.addAll(DMT_Utils.splitString(currentUser.DMT_User_Role__c, ';'));
        }

        Boolean hasWriteAccess = DMT_Utils.hasWriteAccess();
        Boolean hasLineGodAccess = DMT_Utils.checkLineGodUser();

        String clientId = (String) response.get('ClientId');
        String groupCode = (String) response.get('groupCode');

        Boolean hasClient = !String.isBlank(clientId) && clientId != 'norecord';
        Boolean hasGroup = !String.isBlank(groupCode) && groupCode != 'null';
        Boolean hasAccessActions = hasWriteAccess && (hasClient || hasGroup);

        return new Map<String, Object>{
            'roles' => roles,
            'DMT_User_Role__c' => currentUser.DMT_User_Role__c,
            'hasAccessWrite' => hasWriteAccess,
            'hasLineGodAccess' => hasLineGodAccess,
            'hasAccessActions' => hasAccessActions
        };
    }

    private static Boolean resolveOppAccess(List<String> roles, String groupCode, String clientId) {
        if (roles == null || roles.isEmpty()) {
            return false;
        }

        String creationParams = new DMT_GetCreationParameters().getCreationParametersList(
            roles,
            DMT_OPPORTUNITY_RT_NAME,
            null,
            groupCode,
            clientId
        );

        return !String.isBlank(creationParams) && creationParams != '[]';
    }
}