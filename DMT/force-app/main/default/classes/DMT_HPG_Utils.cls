/**
* ────────────────────────────────────────────────────────────────────
* Client Position Utils class.
* ────────────────────────────────────────────────────────────────────
* @author     torcuato.tejada.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2023-04-14
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class DMT_HPG_Utils {

    static final String SUPRAGROUP_NAME = 'Supragroup';
    static final String GROUP_NAME = 'Group';
    static final String SHARED_GROUP_NAME = 'Shared Management Group';
    static final String TOTAL_CLIENTS = 'TOTAL CLIENTS';
    static final List<String> ADMIN_PROFILES = new List<String>{'System Administrator', 'BBVA Standard User'};
    private static String cachedFederationId;
    static final String HPGR_ACCESS_CUSTOM_PERMISSION = 'hpgr__Access';
    static final String HPGR_ACCESSRISK_CUSTOM_PERMISSION = 'hpgr__AccessRisk';
    static final String HPGR_ADMIN_CUSTOM_PERMISSION = 'hpgr__Admin';
    static final String DMT_ACCESS_CUSTOM_PERMISSION = 'DMT_Access';

    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        request.put('userId', getFederationIdentifier());
        final String requestStr = JSON.serialize(request);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = getMock(serviceName);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }
        return response;
    }


    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();
        final iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c , iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final String responseBody = (String)serviceDetails.get('iaso__Mock_LTA__c');
        final String requestMethod = (String)serviceDetails.get('iaso__Http_Method__c');
        response.setStatus('OK');
        if (serviceName == 'DMT_consumptionsReassign') {
            response.setStatusCode(204);
        }
        else if (serviceName == 'DMT_OpportunityCodes') {
            response.setStatusCode(201);
        }
        else {
            response.setStatusCode(requestMethod == 'GET' ? 200 : 201);
        }
        response.setBody(responseBody);
        return response;
    }

    public static String getFederationIdentifier() {
        if (cachedFederationId != null) {
            return cachedFederationId;
        }
        final Id userId = UserInfo.getUserId();
        final User usr = [SELECT FederationIdentifier FROM User WHERE Id = :userId LIMIT 1];
        cachedFederationId = usr.FederationIdentifier;
        return cachedFederationId;
    }

    //DEPRECATED
    /*public static Map<String,Object> handleServiceError(Map<String,Object> responseBodyErrorMap){
        Map<String,Object> returnMap = new Map<String,Object>();
        String responseSerialize = JSON.serialize(responseBodyErrorMap.get('messages'));
        final Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseSerialize.substring(1, responseSerialize.length() -1));
        final String response = (String)responseMap1.get('message');
        returnMap.put('success', false);
        returnMap.put('errorMessage', 'An error ocurred meanwhile calling the service, please try again later.' + ' ' + response);
        return returnMap;
    }*/

    public static String getGroupId(Id clientId) {
        final Map<String,Object> groups = getGroupFromClient(clientId);
        final String res = (String)groups.get('groupCode');
        return res;
    }

    public static String getGroupName(Id clientId) {
        DMT_HPG_GlobalPosition.Wrapper res = new DMT_HPG_GlobalPosition.Wrapper();
        final String groupName;

        String searchDate = DMT_HPG_Utils.lastDate();        
        res = DMT_HPG_MainTableCustomController.fetchClientDataFromService(clientId, '1', '5000', new List<String>{}, Date.valueOf(searchDate), 'N', null);
        if(res.data != null && res.data.size() > 0) {
            groupName = res.data[0].groupName;
        }
        return groupName;
    }
    
    public static String getAlphaCode(Id clientId) {
        List<Account> accList = [SELECT g_customer_id__c FROM Account WHERE Id =:clientId];

        if(accList.isEmpty())
        {
            return null;
        }
        return accList[0].g_customer_id__c;
    }

    /**
     * @description Resolves the Main Holder's display name for each Opportunity's current client
     * structure (Grupo y Main Holder en Opportunity tras migración Multiholder). Mirrors the
     * classification already proven in DMT_OpportunityClientController.resolveMainHolderClientId():
     * Subsidiary / Prospect_Subsidiary Accounts always resolve to the Opportunity's own Account
     * (Custom_Association_Opportunity__c is not even considered for those); every other Account
     * (standard Group / Prospect_Group) resolves the Main Holder via the client flagged through
     * Custom_Association_Opportunity__c.g_customer_id__c, falling back to the Opportunity's own
     * Account when no such association exists. Bulk-safe, SOQL only (no callouts) - safe to call
     * from trigger context.
     * @param opportunityIds Ids of the Opportunities to resolve
     * @param fallbackAccountNameByOppId Opportunity Id -> Account.Name to use when the Opportunity
     * is Subsidiary-like, or when no Multiholder Custom Association is mapped
     * @return Map of Opportunity Id -> Main Holder display name
     */
    public static Map<Id, String> getMainHolderNames(Set<Id> opportunityIds, Map<Id, String> fallbackAccountNameByOppId) {
        Map<Id, String> result = new Map<Id, String>();
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return result;
        }

        Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Prospect_Subsidiary')?.getRecordTypeId();

        // Subsidiary-like Opportunities (real Subsidiary or Prospect_Subsidiary Account) always use
        // their own Account as the Main Holder, regardless of any Custom_Association_Opportunity__c
        // record that may exist - mirrors DMT_OpportunityClientController.resolveMainHolderClientId().
        Set<Id> subsidiaryLikeOppIds = new Set<Id>();
        for (Opportunity opp : [
            SELECT Id, Account.DES_Client_Type__c, Account.RecordTypeId
            FROM Opportunity
            WHERE Id IN :opportunityIds
            WITH USER_MODE
        ]) {
            Boolean isSubsidiary = opp.Account != null && opp.Account.DES_Client_Type__c == 'Subsidiary';
            Boolean isProspectSubsidiary = opp.Account != null && opp.Account.RecordTypeId == prospectSubsidiaryRtId;
            if (isSubsidiary || isProspectSubsidiary) {
                subsidiaryLikeOppIds.add(opp.Id);
            }
        }

        Set<Id> associationLookupOppIds = new Set<Id>(opportunityIds);
        associationLookupOppIds.removeAll(subsidiaryLikeOppIds);

        Map<Id, String> mainHolderCodeByOpp = new Map<Id, String>();
        if (!associationLookupOppIds.isEmpty()) {
            for (Custom_Association_Opportunity__c assoc : [
                SELECT Opportunity__c, g_customer_id__c
                FROM Custom_Association_Opportunity__c
                WHERE Opportunity__c IN :associationLookupOppIds AND g_customer_id__c != null
                WITH USER_MODE
                ORDER BY CreatedDate
            ]) {
                if (!mainHolderCodeByOpp.containsKey(assoc.Opportunity__c)) {
                    mainHolderCodeByOpp.put(assoc.Opportunity__c, assoc.g_customer_id__c);
                }
            }
        }

        Set<String> mainHolderCodes = new Set<String>(mainHolderCodeByOpp.values());
        Map<String, String> accountNameByCustomerId = new Map<String, String>();
        if (!mainHolderCodes.isEmpty()) {
            for (Account acc : [
                SELECT g_customer_id__c, Name
                FROM Account
                WHERE g_customer_id__c IN :mainHolderCodes
                WITH USER_MODE
            ]) {
                accountNameByCustomerId.put(acc.g_customer_id__c, acc.Name);
            }
        }

        for (Id oppId : opportunityIds) {
            String fallback = fallbackAccountNameByOppId != null ? fallbackAccountNameByOppId.get(oppId) : null;
            if (subsidiaryLikeOppIds.contains(oppId)) {
                result.put(oppId, fallback);
                continue;
            }
            String mainHolderCode = mainHolderCodeByOpp.get(oppId);
            String mainHolderName = (String.isNotBlank(mainHolderCode) && accountNameByCustomerId.containsKey(mainHolderCode))
                ? accountNameByCustomerId.get(mainHolderCode)
                : fallback;
            result.put(oppId, mainHolderName);
        }
        return result;
    }

    /**
     * @description Single-Opportunity convenience overload of getMainHolderNames(), for real-time
     * NBC view rendering (DMT_ViewController).
     * @param opportunityId Id of the Opportunity
     * @param fallbackAccountName Account.Name of the Opportunity's own AccountId, used when no
     * Multiholder Custom Association is mapped
     * @return the Main Holder's display name
     */
    public static String getMainHolderName(Id opportunityId, String fallbackAccountName) {
        if (opportunityId == null) {
            return fallbackAccountName;
        }
        Map<Id, String> resolved = getMainHolderNames(
            new Set<Id>{ opportunityId },
            new Map<Id, String>{ opportunityId => fallbackAccountName }
        );
        return resolved.get(opportunityId);
    }

    /**
    * @description get client code used to call 'group-positions' service
    * @param recordId : Id of the client
    * @return client code
    */
    Public static String getRecordCode(Id recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        final String objectName = recordId.getSObjectType().getDescribe().getName();
        switch on objectName {
            when 'Account' {
                retMap = getRecordCodeFromAccount(recordId);
            }
            when else {
                retMap.put('errorMessage', 'Cannot obtain group/client record code from ' + objectName);
                retMap.put('success', false);
            }
        }
        return (String)retMap.get('recordCode');
    }

    /**
    * @description: get groupcode from recordId
    * @param recordId - : Account Id
    * @return retMap account data
    */
    @AuraEnabled
    public static Map<String,Object> getGroupFromClient(Id recordId) {

        final Map<String,Object> res = new Map<String,Object>();
        final String objectName = recordId.getSObjectType().getDescribe().getName();
        final String recordCode = getRecordCode(recordId);
        final Map<String,Object> groupObj = getGroupFromRecordCode(recordCode);
        final String groupCode = (String)groupObj.get('groupCode');
        // final String groupName = (String)groupObj.get('groupName');
        // final String subgroupId = (String)groupObj.get('subgroupId');
        // final String supragroupId = (String)groupObj.get('supragroupId');

        res.put('recordCode', recordCode);
        res.put('groupCode', groupCode);
        // res.put('groupName', groupName);
        // res.put('supragroupId', supragroupId);
        // res.put('subgroupId', subgroupId);

        //Map<String,Object> hierarchy = buildClientGroupStructure(recordId);
        //res.putAll(hierarchy);
        return res;
    }

    public static Map<String,Object> getGroupFromClientAccount(String recordId) { // CIBGLOBALD-2027

        final Map<String,Object> res = new Map<String,Object>();
        final String recordCode = getRecordCode(recordId);
        final Map<String,Object> groupObj = getGroupFromRecordCode(recordCode);
        System.debug('groupObj--> ' + groupObj);
        final String groupCode = (String)groupObj.get('groupCode');

        res.put('recordCode', recordCode);
        // res.put('groupCode', groupCode);
        // res.put('supragroupId', null);
        // res.put('subgroupId', null);

        Map<String,Object> hierarchy = buildClientGroupStructure(recordId);
        res.putAll(hierarchy);
        return res;
    }

    public static Map<String, Object> buildClientGroupStructure(String accountId) {
        final Map<String, Object> res = new Map<String, Object>();
    Id prospectGroupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
    Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();

    // 1. Buscar la cuenta por su ID de Salesforce
    List<Account> accounts = [SELECT Id, Name, DES_Structure_Type__c, DES_Group_Code__c, G_customer_ID__c, RecordTypeId, participant_id__c, participant_id__r.Name, participant_id__r.DES_Group_Code__c, participant_id__r.RecordTypeId
                              FROM Account
                              WHERE Id = :accountId
                              WITH USER_MODE
                              LIMIT 1];
    
    if (accounts.isEmpty()) {
        return res;
    }
    Account currentAcc = accounts[0];

    //Prospects
    if(currentAcc.RecordTypeId == prospectGroupRtId) {
        res.put('groupCode', currentAcc.DES_Group_Code__c);
        res.put('groupName', currentAcc.Name);
    } else if(currentAcc.RecordTypeId == prospectSubsidiaryRtId) {
        if(currentAcc.participant_id__r != null && currentAcc.participant_id__r.RecordTypeId == prospectGroupRtId) { // Parent is a Prospect Group
            res.put('groupCode', currentAcc.participant_id__r.DES_Group_Code__c);
            res.put('groupName', currentAcc.participant_id__r.Name);
        } else if (currentAcc.participant_id__c != null && (currentAcc.participant_id__r.RecordTypeId != prospectGroupRtId && currentAcc.participant_id__r.RecordTypeId != prospectSubsidiaryRtId)) { // Parent is not a Prospect
            Map<String, Object> parentRes = buildClientGroupStructure(currentAcc.participant_id__c);
            res.putAll(parentRes);
        }
    //No Prospects
    } else {
        //res.put('groupName', currentAcc.Name);
        //res.put('groupId', currentAcc.Id);
        res.put('structureType', currentAcc.DES_Structure_Type__c);
        
        // Guardar el código del nivel actual si corresponde (usando DES_Group_Code__c)
        if (currentAcc.DES_Structure_Type__c == 'Supragroup') {
            res.put('supragroupId', currentAcc.DES_Group_Code__c);
            res.put('supragroupName', currentAcc.Name);
        } else if (currentAcc.DES_Structure_Type__c == 'Group') {
            res.put('groupCode', currentAcc.DES_Group_Code__c);
            res.put('groupName', currentAcc.Name);
        } else if (currentAcc.DES_Structure_Type__c == 'Subgroup') {
            res.put('subgroupId', currentAcc.DES_Group_Code__c);
            res.put('subgroupName', currentAcc.Name);
        }
        // Si es cliente, no guardamos código de grupo (solo su nombre ya está en groupName)
        
        // 2. Construir jerarquía hacia arriba (ancestros)
        buildAncestorsHierarchy(currentAcc.Id, res);
        
        // 3. Construir jerarquía hacia abajo (descendientes directos e indirectos)
        //buildDescendantsHierarchy(currentAcc.Id, res);
        
        // 4. Mantener compatibilidad con el campo level3
        if (res.get('supragroupId') != null) {
            res.put('level3Id', res.get('subgroupId'));
            res.put('level3Name', res.get('subgroupName'));
        }
    }
    return res;
}

public static void buildAncestorsHierarchy(Id accountId, Map<String, Object> res) {
    Set<Id> visited = new Set<Id>();
    Id currentId = accountId;

    while (currentId != null && !visited.contains(currentId)) {
        visited.add(currentId);

        // 🔹 Traer TODAS las relaciones (sin LIMIT 1)
        List<AMH_GBL_Account_Relationship__c> parentRels = [
            SELECT AMH_Parent_Account__c,
                   AMH_Parent_Account__r.Name,
                   AMH_Parent_Account__r.DES_Structure_Type__c,
                   AMH_Parent_Account__r.DES_Group_Code__c
            FROM AMH_GBL_Account_Relationship__c
            WHERE AMH_Child_Account__c = :currentId
            WITH SECURITY_ENFORCED
        ];

        if (parentRels.isEmpty()) {
            break;
        }

        // 🔹 Elegir el mejor padre según prioridad
        AMH_GBL_Account_Relationship__c selectedRel;
        AMH_GBL_Account_Relationship__c subgroupRel;
        AMH_GBL_Account_Relationship__c groupRel;
        AMH_GBL_Account_Relationship__c supragroupRel;

        for (AMH_GBL_Account_Relationship__c rel : parentRels) {
            String type = rel.AMH_Parent_Account__r.DES_Structure_Type__c;

            if (type == 'Subgroup' && subgroupRel == null) {
                subgroupRel = rel;
            } else if (type == 'Group' && groupRel == null) {
                groupRel = rel;
            } else if (type == 'Supragroup' && supragroupRel == null) {
                supragroupRel = rel;
            }
        }

        // 🔹 prioridad: Subgroup > Group > Supragroup
        if (subgroupRel != null) {
            selectedRel = subgroupRel;
        } else if (groupRel != null) {
            selectedRel = groupRel;
        } else {
            selectedRel = supragroupRel;
        }

        if (selectedRel == null) {
            break;
        }

        Account parent = selectedRel.AMH_Parent_Account__r;
        String parentType = parent.DES_Structure_Type__c;
        String parentGroupCode = parent.DES_Group_Code__c;

        // 🔹 Guardar valores (igual que lógica original)
        if (parentType == 'Supragroup' && !res.containsKey('supragroupId')) {
            res.put('supragroupId', parentGroupCode);
            res.put('supragroupName', parent.Name);
        } else if (parentType == 'Group' && !res.containsKey('groupCode')) {
            res.put('groupCode', parentGroupCode);
            res.put('groupName', parent.Name);
        } else if (parentType == 'Subgroup' && !res.containsKey('subgroupId')) {
            res.put('subgroupId', parentGroupCode);
            res.put('subgroupName', parent.Name);
        }

        // 🔹 Subir al siguiente nivel
        currentId = selectedRel.AMH_Parent_Account__c;
    }
}


    @AuraEnabled
    public static String getSerializedGroupFromRecordCode(String recordCode) {
        // Call the original method
        Map<String, Object> result = getGroupFromRecordCode(recordCode);

        // Serialize the result to a JSON string
        return JSON.serialize(result);
    }

    /**
     * @description: get groupcode from recordCode
     * @param recordCode - : recordCode (GXXXXXXX or ES1082XXXX)
     * @return retMap account data
     */
    public static Map<String, Object> getGroupFromRecordCode(String recordCode) {
        final Map<String,Object> res = new Map<String,Object>();
        final Map<String, Object> request = new Map<String, Object>();
        request.put('queryString', 'clientIdentifier=' + recordCode);
        final HttpResponse response = callService('DMT_HPG_GetHierarchyPositions', request);
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            final Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            final List<Object> dataList = (List<Object>) parsed.get('data');
            for (Object item : dataList) {
                final Map<String, Object> entry = (Map<String, Object>) item;
                if (entry.get('hierarchyType') == 'R') {
                    res.put('groupCode', (String) entry.get('hierarchyLevel1Id'));
                    break;
                }
            }
            if (!res.containsKey('groupCode')) {
                if (recordCode != null && isProspectGroup(recordCode)) {
                    res.put('errorCode', 'PROSPECT_GROUP_NO_SUBSIDIARY');
                    res.put('errorMessage', 'Please generate a subsidiary for this prospect group before accessing Deal Management.');
                    return res;
                }
                throw new HandledException('Could not find hierarchyType R for record code ' + recordCode);
            }
        } else {
            throw new HandledException('Could not obtain group for record code ' + recordCode + ' from hierarchy-positions service: ' + response.getBody());
        }
        return res;
    }

    public static Boolean isProspectGroup(String recordCode) {
        Id prospectGroupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        List<Account> accs = [SELECT RecordTypeId FROM Account WHERE DES_Group_Code__c = :recordCode LIMIT 1];
        return !accs.isEmpty() && accs[0].RecordTypeId == prospectGroupRtId;
    }

    /*private static boolean getChildrenVisionRisk(Id accountId) {
        final List<dwp_acmh__GBL_Account_Relationship__c> acmh = [SELECT Id from dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND  dwp_acmh__Parent_Account__c =:accountId LIMIT 1];
        return acmh.size() > 0;
    }*/

    public static List<String> getCountries2Anonymize() {
        final Id userId = UserInfo.getUserId();
        List<String> res = new List<String>();
        final User userInfo = [Select DES_Country__c, Profile.Name FROM User WHERE Id=:userId LIMIT 1];

        // following previous logic of hpgr__Geography_Visibility_Configuration__c records, if user has no country all are anonymized; if its MX, none; else only MX is anonymized
        if (String.isBlank(userInfo.DES_Country__c)) {
            res = DMT_Constants.ANON_ALL_COUNTRIES;
        } else  if (userInfo.DES_Country__c == DMT_Constants.MEX) {
            res = DMT_Constants.ANON_ANY;
        } else {
            res = DMT_Constants.ANON_MX;
        }

        return res;
    }

    public static Boolean userCanEdit() {
        final Id userId = UserInfo.getUserId();
        final User usr = [SELECT FederationIdentifier, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        final Map<String, DMT_VisibilityUsers__mdt> users = DMT_VisibilityUsers__mdt.getAll();
        return users.keyset().contains(usr.FederationIdentifier) || ADMIN_PROFILES.contains(usr.Profile.Name);
    }


    public static DMT_HPG_GlobalPosition.Wrapper anonymize(DMT_HPG_GlobalPosition.Wrapper wrap) {
        List<String> countries2Anonymize = getCountries2Anonymize();
        for (DMT_HPG_GlobalPosition.Data item : wrap.data) {
            item.customerName = unNullValue(item.customerName, '');
            if (countries2Anonymize.contains(item.countryId) && !item.customerName.contains(TOTAL_CLIENTS)) {
                item.customerName = obfuscate(item.customerName);
                item.lei = obfuscate(item.lei);
                item.taxpayerId = obfuscate(item.taxpayerId);
            }
        }
        return wrap;
    }

    public static String obfuscate(String input) {
        String res;
        if (!String.isBlank(input)) {
            if (input.startsWith(DMT_Constants.DMT_PROSPECT_PREFIX)) {
                res = DMT_Constants.DMT_PROSPECT_PREFIX + input.substring(DMT_Constants.DMT_PROSPECT_PREFIX.length()).replaceAll('[^\\s]', 'X');
            } else {
                res = input.replaceAll('[^\\s]', 'X');
            }
        }
        return res;
    }

    public static String unNullValue(String value, String ko) {
        String res = value;
        if (String.isBlank(value)) {
            res = ko;
        }
        return res;
    }
    @AuraEnabled(cacheable=true)
    public static String lastDate() {
        Date currentDate = Date.newInstance(1975, 5, 5);
        Map<String, Object> request = new Map<String, Object>();
        request.put('tblMeEngineNameConcatenationDesc', 'GCE');
        DMT_HPG_UsedTables.Wrapper usedTables = DMT_HPG_UsedTables.getUsedTables(request);
        for (DMT_HPG_UsedTables.DateRangeTable dateRange : usedTables.data[0].dateRangeTables)  {
            Date compareTo = Date.valueOf(dateRange.tableDate);
            if (compareTo > currentDate) {
                currentDate = compareTo;
            }
        }
        return String.ValueOf(currentDate);
    }

    /**
    * @description Wrapper for picklist values
    */
    /*public class PicklistValue_Wrapper implements Comparable {

        @AuraEnabled
        public String label {get; set;}

        @AuraEnabled
        public String value {get; set;}

        public PicklistValue_Wrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo) {
            PicklistValue_Wrapper compareToPicklist = (PicklistValue_Wrapper)compareTo;
            return -value.compareTo(compareToPicklist.value);
        }
    }*/

    /**
    * @description get groupcode or alphacode from account recordId.
    * @param clientId: Account Id
    * @return String groupcode
    */
    public static Map<String, Object> getRecordCodeFromAccount(Id recordId) {
        final Map<String,Object> res = new Map<String, Object>{'recordCode' => '', 'errorMessage' => 'Could not obtain recordCode from Account Id ' + recordId, 'success' => false};
        final List<Account> accountList = [SELECT Id, DES_Group_Code__c, RecordType.DeveloperName, g_customer_id__c FROM Account WHERE Id =:recordId];
        if (accountList.size() > 0 && accountList[0].DES_Group_Code__c != '' && accountList[0].DES_Group_Code__c != null) {
            res.put('recordCode', accountList[0].DES_Group_Code__c);
            res.put('errorMessage', '');
            res.put('success', true);
        } else if (accountList.size() > 0 && accountList[0].g_customer_id__c != '' && accountList[0].g_customer_id__c != null) {
            res.put('recordCode', accountList[0].g_customer_id__c);
            res.put('errorMessage', '');
            res.put('success', true);
        }
        return res;
    }

    public static Map<String, Object> getCustomerHPGS(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {

        final List<String> requiredFields = new List<String>{ 'clientId', 'lastDate', 'customerId' };
        List<String> missingFields = new List<String>();


        // Validación de campos requeridos (null o vacíos)
        for (String field : requiredFields) {
            if (!inputMap.containsKey(field) || inputMap.get(field) == null || String.valueOf(inputMap.get(field)).trim() == '') {
                missingFields.add(field);
            }
        }

        if (!missingFields.isEmpty()) {
            outMap.put('serviceError', 'HPG Service Error - Missing or null required fields: ' + String.join(missingFields, ', '));
            return outMap;
        }

        // Parámetros de entrada válidos
        List<String> countries = new List<String>{ 'ALL' };
        String objectType = 'tcmopportunity';

        DMT_HPG_GlobalPosition.Wrapper wrapperHPG = (DMT_HPG_GlobalPosition.Wrapper)
        DMT_HPG_MainTableCustomController.fetchInitialData(
            objectType,
            (Id) inputMap.get('clientId'),
            countries,
            (String) inputMap.get('lastDate'),
            'N',
            '1',
            '4000',
            null
        );

        String inputCustomerId = (String) inputMap.get('customerId');

        for (DMT_HPG_GlobalPosition.Data item : wrapperHPG.data) {
            if (item.customerId == inputCustomerId) {
                outMap.put('CustomerHPG', item);
                outMap.put('LastUpdate', Datetime.now().format('HH:mm:ss'));
                return outMap;
            }
        }

        outMap.put('serviceError', 'HPG Service Error - Customer not found in HPG Service');
        return outMap;
    }

    public static void updateLastModifiedByHuman(List<SObject> records) {
        if (records.isEmpty()) return;

        // Cache profile ID only once
        Id integrationProfileId = [SELECT Id FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1].Id;

        if (UserInfo.getProfileId() == integrationProfileId) {
            return; // Skip integration user
        }

        String userStamp = UserInfo.getName() + ' - ' + Datetime.now().format('dd/MM/yyyy HH:mm:ss');

        for (SObject record : records) {
            // Safe put using dynamic DML
            record.put('Last_Modified_By_Human__c', userStamp);
        }
    }

    // invoked from both DMT_Line_Helper and record-triggered flow Sync_Custom_Association_Name_with_DMT_Line_Name
    @InvocableMethod(label='Sync Custom Association Name With Line Name')
    public static void syncCustomAssociationName(List<String> lineIds) {
        System.debug('syncCustomAssociationName called with lineIds: ' + lineIds);
        List<Custom_Association__c> associations = [SELECT Id, DMT_Line__c, DMT_Line__r.Name, Name, Group__r.Name, gf_customer_group_id__c FROM Custom_Association__c WHERE DMT_Line__c IN :lineIds];
        System.debug('Found associations size: ' + associations.size());
        Boolean updateList = false;
        String customName;
        if (associations != null && !associations.isEmpty()) {
            for (Custom_Association__c association : associations) {
                customName =  association.gf_customer_group_id__c?.replaceAll('[^0-9]', '')?.substring(2)  + '_' + association.Group__r.Name?.replaceAll('[^A-Za-z0-9 ]', '')?.left(68)?.trim();
                if(association.Name != customName){
                    association.Name =  customName; // Update the Name field with the Line Name
                    updateList = true; // Set flag to true if any association is updated
                }
            }
        }
        if(updateList) {
            update associations; // Perform the update only if there are changes
        }
    }

    /*
    public static Map<String, Object> getCustomerHPGS(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        String all = 'ALL';
        List<String> countries = new List<String>();
        countries.add(all);
        boolean customerFound = false;

        Object res = DMT_HPG_MainTableCustomController.fetchInitialData((String)'tcmopportunity', (Id) inputMap.get('clientId'), countries, (String) inputMap.get('lastDate'), 'Y', '1', '100');
        System.debug('Response:'+res);
        DMT_HPG_GlobalPosition.Wrapper wrapperHPG = (DMT_HPG_GlobalPosition.Wrapper) res;
        System.debug('wrapperHPG'+wrapperHPG);

        for(DMT_HPG_GlobalPosition.Data dataItem: wrapperHPG.data){
            if((inputMap.get('customerId')).equals(dataItem.customerId)){
                outMap.put('CustomerHPG', dataItem);
                outMap.put('LastUpdate',Datetime.now().format('HH:mm:ss'));
                customerFound = true;
                break;
            }
        }

        if(!customerFound){
            outMap.put('serviceError', 'Customer not found in HPG Service');
        }

        return outMap;
    }*/

        public static Map<String, Object> getClientDataHPGS(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        System.debug('log::EN getCustomerHPGS ');
        System.debug('log::clientId: ' + inputMap.get('clientId'));
        System.debug('log::lastDate: ' + inputMap.get('lastDate'));
        System.debug('log::customerId: ' + inputMap.get('customerId'));
        final List<String> requiredFields = new List<String>{ 'clientId', 'lastDate', 'customerId' };
        List<String> missingFields = new List<String>();


        // Validación de campos requeridos (null o vacíos)
        for (String field : requiredFields) {
            if (!inputMap.containsKey(field) || inputMap.get(field) == null || String.valueOf(inputMap.get(field)).trim() == '') {
                missingFields.add(field);
            }
        }

        if (!missingFields.isEmpty()) {
            outMap.put('serviceError', 'HPG Service Error - Missing or null required fields: ' + String.join(missingFields, ', '));
            return outMap;
        }

        // Parámetros de entrada válidos
        List<String> countries = new List<String>{ 'ALL' };
        String objectType = 'tcmopportunity';

        DMT_HPG_GlobalPosition.Wrapper wrapperHPG = (DMT_HPG_GlobalPosition.Wrapper)
        DMT_HPG_MainTableCustomController.fetchClientInitialData(
            objectType,
            (Id) inputMap.get('clientId'),
            countries,
            (String) inputMap.get('lastDate'),
            'N',
            '1',
            '4000',
            null
        );

        String inputCustomerId = (String) inputMap.get('customerId');

        for (DMT_HPG_GlobalPosition.Data item : wrapperHPG.data) {
            if (item.customerId == inputCustomerId) {
                System.debug('log::Customer found in HPG Service: ' + item);
                outMap.put('CustomerHPG', item);
                outMap.put('LastUpdate', Datetime.now().format('HH:mm:ss'));
                return outMap;
            }
        }

        outMap.put('serviceError', 'HPG Service Error - Customer not found in HPG Service');
        return outMap;
    }
}