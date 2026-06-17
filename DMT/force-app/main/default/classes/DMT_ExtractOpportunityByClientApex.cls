public with sharing class DMT_ExtractOpportunityByClientApex {

    // =====================================================
    // 🔹 MÉTODO PARA LWC
    // =====================================================
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> executeFromLWC(
        String originId,
        String clientId,
        String groupCode,
        String tab,
        String productSelected
    ) {
        Map<String, Object> input = new Map<String, Object>{
            'originId' => originId,
            'ClientId' => clientId,
            'groupCode' => groupCode,
            'currentTab' => tab,
            'viewTab' => tab,
            'productSelected' => productSelected
        };
        
        Map<String, Object> full = execute(input);
        
        if (tab == 'lines') {
            full.remove('opp');
        } else if (tab == 'opps') {
            full.remove('line');
        } else if (tab == 'ProfitabilityTest') {
            full.remove('line');
            full.remove('opp');
        }
        
        return full;
    }

    // =====================================================
    // 🔹 MÉTODO PRINCIPAL (OPTIMIZADO)
    // =====================================================
    public static Map<String, Object> execute(Map<String, Object> input) {
        if (input == null) input = new Map<String, Object>();
        
        String originId         = asString(input.get('originId'));
        String inputGroupCode   = asString(input.get('groupCode'));
        String clientIdInput    = asString(input.get('ClientId'));
        String currentTab       = defaultIfBlank(asString(input.get('currentTab')), 'Opportunity');
        String viewTab          = defaultIfBlank(asString(input.get('viewTab')), 'Opportunity');
        String productSelected  = asString(input.get('productSelected'));
        String nonDisclosedCode = asString(input.get('nonDisclosedCode'));
        
        ContextData ctx = loadContext(originId, inputGroupCode, nonDisclosedCode, clientIdInput);
        
        // 🔥 Valores calculados UNA SOLA VEZ
        Id currentUserId = UserInfo.getUserId();
        Date today = Date.today();
        
        // 🔥 Obtener todos los grupos hijos (jerarquía completa)
        Set<String> allGroupCodes = new Set<String>();
        if (!String.isBlank(ctx.groupCode) && ctx.groupCode != 'null') {
            allGroupCodes = getAllDescendantGroupCodes(ctx.groupCode);
            allGroupCodes.add(ctx.groupCode);
        }
        
        // 🔥 Obtener todos los clientes locales que pertenecen a estos grupos
        Set<String> allClientIds = new Set<String>();
        if (!allGroupCodes.isEmpty()) {
            for (Account acc : [SELECT g_customer_id__c FROM Account WHERE DES_Group_Code__c IN :allGroupCodes AND g_customer_id__c != null]) {
                allClientIds.add(acc.g_customer_id__c);
            }
        }
        
        // Añadir el clientId directo si existe
        if (!String.isBlank(ctx.clientId) && ctx.clientId != 'null' && ctx.clientId != 'norecord') {
            allClientIds.add(ctx.clientId);
        }
        
        // 🔥 Queries con toda la lógica de negocio incluida
        List<Opportunity> opps = queryOpportunitiesWithAssociations(allClientIds, allGroupCodes, originId);
        List<DMT_Line__c> lines = queryLinesWithAssociations(allClientIds, allGroupCodes, originId, productSelected);
        
        // Cargar datos auxiliares
        Set<Id> oppParentIds = loadOpportunityParentIds(opps);
        Set<Id> lineParentIds = loadLineParentIds(lines);
        Set<Id> teamMemberOppIds = loadTeamMemberOpportunityIds(opps);
        Set<Id> teamMemberLineIds = loadTeamMemberLineIds(lines);
        
        // 🔥 Procesamiento masivo
        List<Object> oppOutput = new List<Object>();
        for (Opportunity opp : opps) {
            oppOutput.add(mapOpportunityOptimized(opp, oppParentIds, teamMemberOppIds, currentUserId, today));
        }
        
        List<Object> lineOutput = new List<Object>();
        for (DMT_Line__c lineRec : lines) {
            lineOutput.add(mapLineOptimized(lineRec, lineParentIds, teamMemberLineIds, currentUserId, today));
        }
        
        // Construcción de respuesta
        Map<String, Object> out = new Map<String, Object>();
        out.put('lineRecordSelected', 'norecord');
        out.put('countType', buildCountType());
        out.put('step', 'step1');
        out.put('clientPosition', 'Y');
        out.put('groupName', defaultIfBlank(ctx.groupName, ''));
        out.put('colOpp', buildColOpp());
        out.put('filter', '');
        out.put('originGroup', defaultIfBlank(ctx.groupCode, 'null'));
        out.put('opp', oppOutput);
        out.put('RecordTypeName', 'norecord');
        out.put('localClient', ctx.localClient);
        out.put('isProspect', ctx.isProspect);
        out.put('viewTab', currentTab);
        out.put('groupCode', defaultIfBlank(ctx.groupCode, 'null'));
        out.put('colLine', buildColLine());
        out.put('relationship', ctx.relationship);
        out.put('ClientId', ctx.clientId);
        out.put('clientType', 'client');
        out.put('originId', originId);
        
        Map<String, Object> userInfo = new Map<String, Object>();
        userInfo.put('groupCode', defaultIfBlank(ctx.groupCode, 'null'));
        userInfo.put('hasAccessWrite', true);
        userInfo.put('hasAccessActions', true);
        out.put('UserInfo', userInfo);
        out.put('line', lineOutput);
        
        return out;
    }

    // =====================================================
    // 🔹 RECURSIÓN PARA OBTENER TODOS LOS GRUPOS HIJOS
    // =====================================================
    private static Set<String> getAllDescendantGroupCodes(String parentGroupCode) {
        Set<String> result = new Set<String>();
        Set<String> currentLevel = new Set<String>{parentGroupCode};
        Set<String> nextLevel = new Set<String>();
        
        Map<String, Set<String>> parentToChildren = new Map<String, Set<String>>();
        
        for (amh_gbl_Account_Relationship__c rel : [
            SELECT amh_Parent_Account__r.DES_Group_Code__c,
                   amh_Child_Account__r.DES_Group_Code__c
            FROM amh_gbl_Account_Relationship__c
            WHERE amh_Parent_Account__r.DES_Group_Code__c != null
              AND amh_Child_Account__r.DES_Group_Code__c != null
              AND amh_Parent_Account__r.DES_Structure_Type__c IN ('Supragroup', 'Group', 'Subgroup')
        ]) {
            String parent = rel.amh_Parent_Account__r.DES_Group_Code__c;
            String child = rel.amh_Child_Account__r.DES_Group_Code__c;
            
            if (!parentToChildren.containsKey(parent)) {
                parentToChildren.put(parent, new Set<String>());
            }
            parentToChildren.get(parent).add(child);
        }
        
        while (!currentLevel.isEmpty()) {
            nextLevel.clear();
            for (String parent : currentLevel) {
                if (parentToChildren.containsKey(parent)) {
                    for (String child : parentToChildren.get(parent)) {
                        if (!result.contains(child)) {
                            result.add(child);
                            nextLevel.add(child);
                        }
                    }
                }
            }
            currentLevel = new Set<String>(nextLevel);
        }
        
        return result;
    }

    // =====================================================
    // 🔹 QUERY OPORTUNIDADES - CORREGIDA
    // =====================================================
    private static List<Opportunity> queryOpportunitiesWithAssociations(
        Set<String> allClientIds,
        Set<String> allGroupCodes,
        String originId
    ) {
        // Si hay originId, devolvemos solo esa oportunidad
        if (!String.isBlank(originId)) {
            String query = 'SELECT Id, Name, AccountId, OwnerId, StageName, ' +
                           'RecordType.Name, RecordType.DeveloperName, ' +
                           'Account.DES_Group_Code__c, ' +
                           'Account.DES_Main_Parent__r.DES_Group_Code__c, ' +
                           'Account.g_customer_id__c, ' +
                           'DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c, ' +
                           'DMT_Client_Type__c, DMT_Entity__c, Entific__c, ' +
                           'TCM_Garantias__c, DMT_CUR_Notional_Amount__c ' +
                           'FROM Opportunity ' +
                           'WHERE Id = :originId AND RecordType.DeveloperName = \'DMT_Opportunity\'';
            return Database.query(query);
        }
        
        // Preparamos las diferentes condiciones que se unirán con OR
        Set<Id> opportunityIds = new Set<Id>();
        
        // Condición 1: Por g_customer_id__c directo
        if (!allClientIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id FROM Opportunity 
                                   WHERE Account.g_customer_id__c IN :allClientIds 
                                   AND RecordType.DeveloperName = 'DMT_Opportunity']) {
                opportunityIds.add(opp.Id);
            }
        }
        
        // Condición 2: Por DES_Group_Code__c del Account o su Main Parent
        if (!allGroupCodes.isEmpty()) {
            for (Opportunity opp : [SELECT Id FROM Opportunity 
                                   WHERE (Account.DES_Group_Code__c IN :allGroupCodes 
                                          OR Account.DES_Main_Parent__r.DES_Group_Code__c IN :allGroupCodes)
                                   AND RecordType.DeveloperName = 'DMT_Opportunity']) {
                opportunityIds.add(opp.Id);
            }
        }
        
        // Condición 3: A través de DMT_Opportunity_Client__c
        if (!allClientIds.isEmpty()) {
            Set<Id> oppIdsFromClient = new Set<Id>();
            for (DMT_Opportunity_Client__c oppClient : [SELECT DMT_MDE_Opportunity__c 
                                                        FROM DMT_Opportunity_Client__c 
                                                        WHERE Alpha_Code_Client__c IN :allClientIds]) {
                if (oppClient.DMT_MDE_Opportunity__c != null) {
                    oppIdsFromClient.add(oppClient.DMT_MDE_Opportunity__c);
                }
            }
            if (!oppIdsFromClient.isEmpty()) {
                for (Opportunity opp : [SELECT Id FROM Opportunity 
                                       WHERE Id IN :oppIdsFromClient 
                                       AND RecordType.DeveloperName = 'DMT_Opportunity']) {
                    opportunityIds.add(opp.Id);
                }
            }
        }
        
        // Condición 4: Account Relationships
        if (!allGroupCodes.isEmpty()) {
            Set<Id> childAccountIds = new Set<Id>();
            for (amh_gbl_Account_Relationship__c rel : [SELECT amh_Child_Account__c 
                                                        FROM amh_gbl_Account_Relationship__c 
                                                        WHERE amh_Parent_Account__r.DES_Group_Code__c IN :allGroupCodes 
                                                        AND amh_Parent_Account__r.DES_Structure_Type__c IN ('Supragroup', 'Group', 'Subgroup')]) {
                if (rel.amh_Child_Account__c != null) {
                    childAccountIds.add(rel.amh_Child_Account__c);
                }
            }
            if (!childAccountIds.isEmpty()) {
                for (Opportunity opp : [SELECT Id FROM Opportunity 
                                       WHERE AccountId IN :childAccountIds 
                                       AND RecordType.DeveloperName = 'DMT_Opportunity']) {
                    opportunityIds.add(opp.Id);
                }
            }
        }
        
        // Si no hay resultados, devolver lista vacía
        if (opportunityIds.isEmpty()) {
            return new List<Opportunity>();
        }
        
        // Consulta final con todos los IDs encontrados
        String query = 'SELECT Id, Name, AccountId, OwnerId, StageName, ' +
                       'RecordType.Name, RecordType.DeveloperName, ' +
                       'Account.DES_Group_Code__c, ' +
                       'Account.DES_Main_Parent__r.DES_Group_Code__c, ' +
                       'Account.g_customer_id__c, ' +
                       'DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c, ' +
                       'DMT_Client_Type__c, DMT_Entity__c, Entific__c, ' +
                       'TCM_Garantias__c, DMT_CUR_Notional_Amount__c ' +
                       'FROM Opportunity ' +
                       'WHERE Id IN :opportunityIds ' +
                       'ORDER BY CreatedDate desc';
        
        System.debug('🔍 Opportunity Query: ' + query);
        return Database.query(query);
    }
    
    // =====================================================
    // 🔹 QUERY LÍNEAS - CORREGIDA
    // =====================================================
    private static List<DMT_Line__c> queryLinesWithAssociations(
        Set<String> allClientIds,
        Set<String> allGroupCodes,
        String originId,
        String productSelected
    ) {
        // Si hay originId, devolvemos solo esa línea
        if (!String.isBlank(originId)) {
            String query = 'SELECT Id, Name, OwnerId, Client__c, ' +
                           'Client__r.DES_Group_Code__c, ' +
                           'Client__r.DES_Main_Parent__r.DES_Group_Code__c, ' +
                           'Client__r.g_customer_id__c, ' +
                           'Product__c, Status__c, Closed__c, ' +
                           'Booking_Geography__c, Start_Date__c, End_Date__c, ' +
                           'DvP_Amount__c, DvP_Currency__c, FD_Amount__c, FD_Currency__c, ' +
                           'Client_Type__c, DMT_Origin__c, Line_Id__c, ' +
                           'Line_Details__c, DMT_Parent_Line__c, IsDeleted, DMT_Deleted__c ' +
                           'FROM DMT_Line__c ' +
                           'WHERE Id = :originId AND Product__c != \'Sanction\'';
            return Database.query(query);
        }
        
        // Preparamos las diferentes condiciones que se unirán con OR
        Set<Id> lineIds = new Set<Id>();
        
        // Condición 1: Por g_customer_id__c directo del cliente
        if (!allClientIds.isEmpty()) {
            for (DMT_Line__c line : [SELECT Id FROM DMT_Line__c 
                                     WHERE Client__r.g_customer_id__c IN :allClientIds 
                                     AND Product__c != 'Sanction']) {
                lineIds.add(line.Id);
            }
        }
        
        // Condición 2: Por DES_Group_Code__c del cliente o su Main Parent
        if (!allGroupCodes.isEmpty()) {
            for (DMT_Line__c line : [SELECT Id FROM DMT_Line__c 
                                     WHERE (Client__r.DES_Group_Code__c IN :allGroupCodes 
                                            OR Client__r.DES_Main_Parent__r.DES_Group_Code__c IN :allGroupCodes)
                                     AND Product__c != 'Sanction']) {
                lineIds.add(line.Id);
            }
        }
        
        // Condición 3: A través de Custom_Association__c y Custom_Association_Client__c
        if (!allClientIds.isEmpty()) {
            // Primero obtenemos los Custom_Association__c IDs
            Set<Id> customAssociationIds = new Set<Id>();
            for (Custom_Association_Client__c clientAssoc : [SELECT Custom_Association__c 
                                                             FROM Custom_Association_Client__c 
                                                             WHERE G_Customer_ID__c IN :allClientIds]) {
                if (clientAssoc.Custom_Association__c != null) {
                    customAssociationIds.add(clientAssoc.Custom_Association__c);
                }
            }
            
            // Luego obtenemos las líneas asociadas
            if (!customAssociationIds.isEmpty()) {
                for (Custom_Association__c assoc : [SELECT DMT_Line__c 
                                                    FROM Custom_Association__c 
                                                    WHERE Id IN :customAssociationIds 
                                                    AND DMT_Line__c != null]) {
                    lineIds.add(assoc.DMT_Line__c);
                }
            }
        }
        
        // Condición 4: Account Relationships
        if (!allGroupCodes.isEmpty()) {
            Set<Id> childAccountIds = new Set<Id>();
            for (amh_gbl_Account_Relationship__c rel : [SELECT amh_Child_Account__c 
                                                        FROM amh_gbl_Account_Relationship__c 
                                                        WHERE amh_Parent_Account__r.DES_Group_Code__c IN :allGroupCodes 
                                                        AND amh_Parent_Account__r.DES_Structure_Type__c IN ('Supragroup', 'Group', 'Subgroup')]) {
                if (rel.amh_Child_Account__c != null) {
                    childAccountIds.add(rel.amh_Child_Account__c);
                }
            }
            if (!childAccountIds.isEmpty()) {
                for (DMT_Line__c line : [SELECT Id FROM DMT_Line__c 
                                         WHERE Client__c IN :childAccountIds 
                                         AND Product__c != 'Sanction']) {
                    lineIds.add(line.Id);
                }
            }
        }
        
        // Si no hay resultados, devolver lista vacía
        if (lineIds.isEmpty()) {
            return new List<DMT_Line__c>();
        }
        
        // Consulta final con todos los IDs encontrados
        String query = 'SELECT Id, Name, OwnerId, Client__c, ' +
                       'Client__r.DES_Group_Code__c, ' +
                       'Client__r.DES_Main_Parent__r.DES_Group_Code__c, ' +
                       'Client__r.g_customer_id__c, ' +
                       'Product__c, Status__c, Closed__c, ' +
                       'Booking_Geography__c, Start_Date__c, End_Date__c, ' +
                       'DvP_Amount__c, DvP_Currency__c, FD_Amount__c, FD_Currency__c, ' +
                       'Client_Type__c, DMT_Origin__c, Line_Id__c, ' +
                       'Line_Details__c, DMT_Parent_Line__c, IsDeleted, DMT_Deleted__c ' +
                       'FROM DMT_Line__c ' +
                       'WHERE Id IN :lineIds ' +
                       'ORDER BY CreatedDate desc';
        
        System.debug('🔍 Line Query: ' + query);
        return Database.query(query);
    }

    // =====================================================
    // 🔹 CONSTRUIR LISTA DE STRINGS PARA SUBQUERIES
    // =====================================================
    private static String buildStringList(Set<String> values) {
        List<String> escapedValues = new List<String>();
        for (String val : values) {
            if (!String.isBlank(val)) {
                escapedValues.add('\'' + String.escapeSingleQuotes(val) + '\'');
            }
        }
        return String.join(escapedValues, ',');
    }

    // =====================================================
    // 🔹 CONTEXT DATA
    // =====================================================
    private class ContextData {
        String groupCode;
        String groupName;
        String clientId;
        String localClient = 'null';
        String relationship = 'null';
        Boolean isProspect = false;
    }
    
    private static ContextData loadContext(
        String originId,
        String inputGroupCode,
        String nonDisclosedCode,
        String clientIdInput
    ) {
        ContextData ctx = new ContextData();
        
        Account acc = null;
        if (!String.isBlank(originId)) {
            acc = [SELECT Id, Name, g_customer_id__c,
                          DES_Group_Code__c,
                          DES_Main_Parent__r.DES_Group_Code__c,
                          DES_Main_Parent__r.Name
                   FROM Account
                   WHERE Id = :originId
                   LIMIT 1];
        }
        
        if (!String.isBlank(clientIdInput) && clientIdInput != 'null') {
            ctx.clientId = clientIdInput;
        } else if (acc != null && !String.isBlank(acc.g_customer_id__c)) {
            ctx.clientId = acc.g_customer_id__c;
        } else {
            ctx.clientId = 'norecord';
        }
        
        ctx.groupCode = !String.isBlank(inputGroupCode)
            ? inputGroupCode
            : (acc != null ? acc.DES_Group_Code__c : null);
        
        if (!String.isBlank(nonDisclosedCode)) {
            ctx.groupCode = nonDisclosedCode;
        }
        Account accGroup = [SELECT Id, Name FROM Account WHERE DES_Group_Code__c = :inputGroupCode];
        ctx.groupName = accGroup != null ? accGroup.Name : acc.DES_Main_Parent__r.Name;
        
        return ctx;
    }

    // =====================================================
    // 🔹 MÉTODOS AUXILIARES PARA PARENTS Y TEAM MEMBERS
    // =====================================================
    private static Set<Id> loadOpportunityParentIds(List<Opportunity> opps) {
        Set<Id> parentIds = new Set<Id>();
        for (Opportunity opp : opps) {
            parentIds.add(opp.Id);
        }
        
        for (Opportunity child : [SELECT DMT_Parent_Opportunity__c FROM Opportunity WHERE DMT_Parent_Opportunity__c IN :parentIds]) {
            if (child.DMT_Parent_Opportunity__c != null) {
                parentIds.add(child.DMT_Parent_Opportunity__c);
            }
        }
        return parentIds;
    }
    
    private static Set<Id> loadLineParentIds(List<DMT_Line__c> lines) {
        Set<Id> parentIds = new Set<Id>();
        for (DMT_Line__c line : lines) {
            parentIds.add(line.Id);
        }
        
        for (DMT_Line__c child : [SELECT DMT_Parent_Line__c FROM DMT_Line__c WHERE DMT_Parent_Line__c IN :parentIds]) {
            if (child.DMT_Parent_Line__c != null) {
                parentIds.add(child.DMT_Parent_Line__c);
            }
        }
        return parentIds;
    }
    
    private static Set<Id> loadTeamMemberOpportunityIds(List<Opportunity> opps) {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }
        
        Set<Id> result = new Set<Id>();
        Id currentUserId = UserInfo.getUserId();
        
        for (DMT_TeamMember__c tm : [SELECT Opportunity__c FROM DMT_TeamMember__c WHERE User__c = :currentUserId AND Opportunity__c IN :oppIds]) {
            if (tm.Opportunity__c != null) {
                result.add(tm.Opportunity__c);
            }
        }
        return result;
    }
    
    private static Set<Id> loadTeamMemberLineIds(List<DMT_Line__c> lines) {
        Set<Id> lineIds = new Set<Id>();
        for (DMT_Line__c line : lines) {
            lineIds.add(line.Id);
        }
        
        Set<Id> result = new Set<Id>();
        Id currentUserId = UserInfo.getUserId();
        
        for (DMT_TeamMember__c tm : [SELECT Line__c FROM DMT_TeamMember__c WHERE User__c = :currentUserId AND Line__c IN :lineIds]) {
            if (tm.Line__c != null) {
                result.add(tm.Line__c);
            }
        }
        return result;
    }

    // =====================================================
    // 🔹 MAPEO OPTIMIZADO DE OPORTUNIDADES
    // =====================================================
    private static Map<String, Object> mapOpportunityOptimized(
        Opportunity opp,
        Set<Id> oppParentIds,
        Set<Id> teamMemberOppIds,
        Id currentUserId,
        Date today
    ) {
        Map<String, Object> row = new Map<String, Object>();
        
        row.put('NameURL', '/' + opp.Id);
        row.put('entity', opp.DMT_Entity__c);
        row.put('isDisabled', 'false');
        row.put('Id', opp.Id);
        row.put('buttonClass', 'clickableButton');
        row.put('accountId', opp.AccountId);
        row.put('Name', opp.Name);
        row.put('Entific__c', opp.Entific__c);
        row.put('RecordType.Name', opp.RecordType != null ? opp.RecordType.Name : null);
        row.put('StageName', opp.StageName);
        row.put('TCM_Garantias__c', opp.TCM_Garantias__c);
        row.put('DMT_Client_Type__c', opp.DMT_Client_Type__c);
        row.put('isParent', oppParentIds.contains(opp.Id));
        row.put('hasAccessOpp', opp.OwnerId == currentUserId || teamMemberOppIds.contains(opp.Id));
        
        if (opp.DMT_CUR_Notional_Amount__c != null) {
            row.put('Opportunity_Details__c', opp.DMT_CUR_Notional_Amount__c);
        }
        
        row.put('DMT_DATE_Initial_Date__c', opp.DMT_DATE_Initial_Date__c != null ? String.valueOf(opp.DMT_DATE_Initial_Date__c) : null);
        row.put('DMT_DATE_Maturity_Date__c', opp.DMT_DATE_Maturity_Date__c != null ? String.valueOf(opp.DMT_DATE_Maturity_Date__c) : null);
        
        String stage = opp.StageName;
        Date initDate = opp.DMT_DATE_Initial_Date__c;
        Date maturityDate = opp.DMT_DATE_Maturity_Date__c;
        
        if (stage == 'Closed Won') {
            if (initDate != null && today < initDate) {
                row.put('statusTooltip', 'Scheduled: the period has not started yet.');
                row.put('statusIcon', 'utility:clock');
                row.put('statusIconColor', '#4E86C6');
                row.put('statusTextColor', '#22a562');
            } else if (maturityDate != null && today > maturityDate) {
                row.put('statusTooltip', 'Historical: it was successfully closed, but it is no longer active.');
                row.put('statusIcon', 'utility:success');
                row.put('statusIconColor', '');
                row.put('statusTextColor', '#22a562');
            } else {
                row.put('statusTooltip', 'Successfully closed and currently active.');
                row.put('statusIcon', 'utility:success');
                row.put('statusIconColor', '#1F7A4D');
                row.put('statusTextColor', '#22a562');
            }
        } else if (stage == 'Closed Lost') {
            row.put('statusTooltip', 'Closed unsuccessfully.');
            row.put('statusIcon', 'utility:clear');
            row.put('statusIconColor', '#B93A3A');
            row.put('statusTextColor', '#a30b0b');
        } else if (stage == 'Ready to close') {
            row.put('statusTooltip', 'Ready to Close: only the last step remains to finalize the closure.');
            row.put('statusIcon', 'utility:clock');
            row.put('statusIconColor', '#D9A441');
            row.put('statusTextColor', '#8F5E0A');
        } else {
            row.put('statusTooltip', 'In progress: it is still open for editing, review, or approval.');
            row.put('statusIcon', 'utility:edit_form');
            row.put('statusIconColor', '');
            row.put('statusTextColor', '');
        }
        
        row.put('statusIconVariant', 'bare');
        
        return row;
    }
    
    // =====================================================
    // 🔹 MAPEO OPTIMIZADO DE LÍNEAS
    // =====================================================
    private static Map<String, Object> mapLineOptimized(
        DMT_Line__c lineRec,
        Set<Id> lineParentIds,
        Set<Id> teamMemberLineIds,
        Id currentUserId,
        Date today
    ) {
        Map<String, Object> row = new Map<String, Object>();
        
        row.put('isDisabled', false);
        row.put('Id', lineRec.Id);
        row.put('Line_Id__c', lineRec.Line_Id__c);
        row.put('NameURLLine', '/' + lineRec.Id);
        row.put('buttonClass', 'clickableButton');
        row.put('OwnerId', lineRec.OwnerId);
        row.put('DvP_Currency__c', lineRec.DvP_Currency__c);
        row.put('FD_Currency__c', lineRec.FD_Currency__c);
        row.put('DMT_Origin__c', lineRec.DMT_Origin__c);
        row.put('hasAccessLine', lineRec.OwnerId == currentUserId || teamMemberLineIds.contains(lineRec.Id));
        row.put('Name', lineRec.Name);
        row.put('Client__c', lineRec.Client__c);
        row.put('Booking_Geography__c', lineRec.Booking_Geography__c);
        row.put('isParent', lineParentIds.contains(lineRec.Id));
        row.put('multiEditable', true);
        row.put('disableRenew', false);
        row.put('buttonClass2', null);
        
        if (lineRec.DvP_Amount__c != null) row.put('DvP_Amount__c', lineRec.DvP_Amount__c);
        if (lineRec.FD_Amount__c != null) row.put('FD_Amount__c', lineRec.FD_Amount__c);
        if (lineRec.Closed__c != null) row.put('Closed__c', lineRec.Closed__c);
        
        row.put('Start_Date__c', formatDateFast(lineRec.Start_Date__c));
        row.put('End_Date__c', formatDateFast(lineRec.End_Date__c));
        
        String product = lineRec.Product__c;
        if (product == 'Sanction') product = 'Risk Approval';
        else if (product == 'Line (Other Products)') product = 'Line';
        row.put('Product__c', product);
        
        row.put('Status__c', lineRec.Status__c);
        row.put('Client_Type__c', lineRec.Client_Type__c);
        row.put('Line_Details__c', lineRec.Line_Details__c);
        
        String status = lineRec.Status__c;
        String closed = lineRec.Closed__c;
        Date startDate = lineRec.Start_Date__c;
        Date endDate = lineRec.End_Date__c;
        
        if (status == 'Closed') {
            if (String.isBlank(closed)) {
                row.put('statusTooltip', '');
                row.put('statusIcon', '');
                row.put('statusIconColor', '');
                row.put('statusTextColor', '');
            } else if (closed == 'Won') {
                if (startDate != null && today < startDate) {
                    row.put('statusTooltip', 'Scheduled: the period has not started yet.');
                    row.put('statusIcon', 'utility:clock');
                    row.put('statusIconColor', '#4E86C6');
                    row.put('statusTextColor', '#22a562');
                } else if (endDate != null && today > endDate) {
                    row.put('statusTooltip', 'Historical: it was successfully closed, but it is no longer active.');
                    row.put('statusIcon', 'utility:success');
                    row.put('statusIconColor', '');
                    row.put('statusTextColor', '#22a562');
                } else {
                    row.put('statusTooltip', 'Successfully closed and currently active.');
                    row.put('statusIcon', 'utility:success');
                    row.put('statusIconColor', '#1F7A4D');
                    row.put('statusTextColor', '#22a562');
                }
            } else {
                row.put('statusTooltip', 'Closed unsuccessfully.');
                row.put('statusIcon', 'utility:clear');
                row.put('statusIconColor', '#B93A3A');
                row.put('statusTextColor', '#a30b0b');
            }
        } else if (status == 'Ready to close') {
            row.put('statusTooltip', 'Ready to Close: only the last step remains to finalize the closure.');
            row.put('statusIcon', 'utility:clock');
            row.put('statusIconColor', '#D9A441');
            row.put('statusTextColor', '#8F5E0A');
        } else {
            row.put('statusTooltip', 'In progress: it is still open for editing, review, or approval.');
            row.put('statusIcon', 'utility:edit_form');
            row.put('statusIconColor', '');
            row.put('statusTextColor', '');
        }
        
        row.put('statusIconVariant', 'bare');
        
        return row;
    }

    // =====================================================
    // 🔹 FORMATEO RÁPIDO DE FECHAS
    // =====================================================
    private static String formatDateFast(Date d) {
        if (d == null) return null;
        Integer day = d.day();
        Integer month = d.month();
        Integer year = d.year();
        
        String monthAbbr;
        if (month == 1) monthAbbr = 'Jan';
        else if (month == 2) monthAbbr = 'Feb';
        else if (month == 3) monthAbbr = 'Mar';
        else if (month == 4) monthAbbr = 'Apr';
        else if (month == 5) monthAbbr = 'May';
        else if (month == 6) monthAbbr = 'Jun';
        else if (month == 7) monthAbbr = 'Jul';
        else if (month == 8) monthAbbr = 'Aug';
        else if (month == 9) monthAbbr = 'Sep';
        else if (month == 10) monthAbbr = 'Oct';
        else if (month == 11) monthAbbr = 'Nov';
        else monthAbbr = 'Dec';
        
        String dayStr = (day < 10) ? '0' + String.valueOf(day) : String.valueOf(day);
        return dayStr + '-' + monthAbbr + '-' + String.valueOf(year);
    }

    // =====================================================
    // 🔹 MÉTODOS AUXILIARES (MANTENIDOS)
    // =====================================================
    private static Map<String, Object> buildCountType() { return new Map<String, Object>(); }
    private static List<Object> buildColOpp() { return new List<Object>(); }
    private static List<Object> buildColLine() { return new List<Object>(); }
    
    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }
    
    private static String defaultIfBlank(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
    }
}