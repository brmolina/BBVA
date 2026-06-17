public with sharing class DMT_LinesBulkActionController {

    private static final Pattern SAFE_IDENTIFIER_PATTERN =
        Pattern.compile('^[A-Za-z][A-Za-z0-9_]*$');

    public class OpportunityCodesRequest {
        public List<StructureCode> structureCodes;
    }

    public class StructureCode {
        public String entific;
        public String operationType;
        public String origin;
    }

    public class BulkActionResult {
        @AuraEnabled public String actionType { get; set; }
        @AuraEnabled public List<String> processedLineIds { get; set; }
        @AuraEnabled public List<String> newLineIds { get; set; }

        public BulkActionResult() {
            processedLineIds = new List<String>();
            newLineIds = new List<String>();
        }
    }

    public class ModifyPayload {
        @AuraEnabled public List<ModifyRowDTO> rows { get; set; }

        public ModifyPayload() {
            rows = new List<ModifyRowDTO>();
        }
    }

    public class ModifyPicklistOptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public ModifyPicklistOptionDTO() {}
    }

    public class ModifyFieldDTO {
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String inputType { get; set; }
        @AuraEnabled public Boolean required { get; set; }
        @AuraEnabled public Integer orderNumber { get; set; }

        public ModifyFieldDTO() {}
    }

    public class ModifyCellDTO {
        @AuraEnabled public String key { get; set; }
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String inputType { get; set; }
        @AuraEnabled public Object value { get; set; }
        @AuraEnabled public Boolean checked { get; set; }
        @AuraEnabled public Boolean required { get; set; }
        @AuraEnabled public Boolean isPicklist { get; set; }
        @AuraEnabled public List<ModifyPicklistOptionDTO> options { get; set; }

        public ModifyCellDTO() {
            isPicklist = false;
            options = new List<ModifyPicklistOptionDTO>();
        }
    }

    public class ModifyRowDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String lineId { get; set; }
        @AuraEnabled public String lineName { get; set; }
        @AuraEnabled public String lineUrl { get; set; }
        @AuraEnabled public String templateType { get; set; }
        @AuraEnabled public Object derivativesAmount { get; set; }
        @AuraEnabled public Map<String, Object> values { get; set; }
        @AuraEnabled public List<ModifyCellDTO> cells { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public List<ModifyRelatedSectionDTO> relatedSections { get; set; }

        public ModifyRowDTO() {
            values = new Map<String, Object>();
            cells = new List<ModifyCellDTO>();
            relatedSections = new List<ModifyRelatedSectionDTO>();
        }
    }

    public class ModifyRelatedSectionDTO {
        @AuraEnabled public String key { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String lookupField { get; set; }
        @AuraEnabled public Integer orderNumber { get; set; }
        @AuraEnabled public List<ModifyRelatedRecordDTO> records { get; set; }

        public ModifyRelatedSectionDTO() {
            records = new List<ModifyRelatedRecordDTO>();
        }
    }

    public class ModifyRelatedRecordDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String displayName { get; set; }
        @AuraEnabled public Map<String, Object> values { get; set; }
        @AuraEnabled public List<ModifyCellDTO> cells { get; set; }

        public ModifyRelatedRecordDTO() {
            values = new Map<String, Object>();
            cells = new List<ModifyCellDTO>();
        }
    }

    public class ModifySaveRowDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String lineId { get; set; }
        @AuraEnabled public Map<String, Object> values { get; set; }
        @AuraEnabled public List<ModifySaveRelatedSectionDTO> relatedSections { get; set; }

        public ModifySaveRowDTO() {}
    }

    public class ModifySaveRelatedSectionDTO {
        @AuraEnabled public String key { get; set; }
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String lookupField { get; set; }
        @AuraEnabled public List<ModifySaveRelatedRecordDTO> records { get; set; }

        public ModifySaveRelatedSectionDTO() {}
    }

    public class ModifySaveRelatedRecordDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Map<String, Object> values { get; set; }

        public ModifySaveRelatedRecordDTO() {}
    }

    @AuraEnabled
    public static BulkActionResult processLines(List<String> lineIds, String actionType) {

        if (lineIds == null || lineIds.isEmpty()) {
            throw new AuraHandledException('No lineIds provided');
        }

        BulkActionResult result = new BulkActionResult();
        result.actionType = actionType;
        result.processedLineIds = lineIds;

        if (actionType == 'connect') {
            processConnect(lineIds);

        } else if (actionType == 'disconnect') {
            processDisconnect(lineIds);

        } else if (actionType == 'renew') {
            result.newLineIds = processRenew(lineIds);

        } else {
            throw new AuraHandledException('Invalid actionType: ' + actionType);
        }

        return result;
    }

    public static void processConnect(List<String> lineIds) {

        List<DMT_Line__c> lines = [
            SELECT Id, Line_Id__c
            FROM DMT_Line__c
            WHERE Line_Id__c IN :lineIds
            FOR UPDATE
        ];

        if (lines.isEmpty()) {
            throw new AuraHandledException('No DMT_Line__c records found for provided Line_Id__c');
        }

        update lines;
    }

    public static void processDisconnect(List<String> lineIds) {

        List<DMT_Consolidated_Line__c> records = [
            SELECT Id, Line_Id__c, G_Multioperation_Ind_Type__c
            FROM DMT_Consolidated_Line__c
            WHERE Line_Id__c IN :lineIds
            FOR UPDATE
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException('No DMT_Consolidated_Line__c records found');
        }

        for (DMT_Consolidated_Line__c rec : records) {
            rec.G_Multioperation_Ind_Type__c = 'x';
        }

        update records;
    }

    public static List<String> processRenew(List<String> lineIds) {

        if (lineIds == null || lineIds.isEmpty()) {
            throw new AuraHandledException('No lineIds provided');
        }

        Schema.SObjectType objType = DMT_Line__c.SObjectType;

        Map<String, Schema.SObjectField> fieldsMap =
            objType.getDescribe().fields.getMap();

        List<String> fieldNames = new List<String>();

        for (String f : fieldsMap.keySet()) {
            Schema.DescribeFieldResult d = fieldsMap.get(f).getDescribe();

            if (d.isCreateable() && !d.isAutoNumber()) {
                fieldNames.add(f);
            }
        }

        String query =
            'SELECT ' + String.join(fieldNames, ',') +
            ' FROM DMT_Line__c WHERE Line_Id__c IN :lineIds';

        List<DMT_Line__c> originalLines =
            (List<DMT_Line__c>) Database.query(query);

        if (originalLines.isEmpty()) {
            throw new AuraHandledException('No lines found');
        }

        List<String> opportunityIds = getOpportunityCodesForRenew(originalLines);

        List<DMT_Line__c> newLines = new List<DMT_Line__c>();

        for (Integer i = 0; i < originalLines.size(); i++) {

            DMT_Line__c original = originalLines[i];

            DMT_Line__c cloneLine = original.clone(false, true, false, false);

            cleanFieldsForRenew(cloneLine);

            cloneLine.DMT_Parent_Line__c = original.Id;
            cloneLine.DMT_Parent_Code__c = original.Line_Id__c;

            cloneLine.Start_Date__c = original.End_Date__c != null
                ? original.End_Date__c.addDays(1)
                : Date.today();

            cloneLine.End_Date__c = cloneLine.Start_Date__c != null
                ? cloneLine.Start_Date__c.addYears(1)
                : Date.today().addYears(1);

            cloneLine.Line_Id__c = opportunityIds[i];

            newLines.add(cloneLine);
        }

        insert newLines;

        cloneRelatedRecordsDynamic(originalLines, newLines);

        List<String> newLineIds = new List<String>();

        for (DMT_Line__c newLine : newLines) {
            newLineIds.add(newLine.Line_Id__c);
        }

        return newLineIds;
    }

    public static List<String> getOpportunityCodesForRenew(List<DMT_Line__c> lines) {

        Boolean useMock = false;

        if (useMock) {
            return generateMockOpportunityIds(lines);
        }

        if (lines == null || lines.isEmpty()) {
            return new List<String>();
        }

        OpportunityCodesRequest requestBody =
            new OpportunityCodesRequest();

        requestBody.structureCodes =
            new List<StructureCode>();

        for (DMT_Line__c line : lines) {

            if (String.isBlank(line.Booking_Geography__c)) {
                throw new AuraHandledException(
                    'Booking_Geography__c is required for line ' +
                    line.Line_Id__c
                );
            }

            StructureCode sc = new StructureCode();

            sc.origin = 'ESCD';
            sc.operationType = 'LIN';
            sc.entific = line.Booking_Geography__c;

            requestBody.structureCodes.add(sc);
        }

        System.debug(
            '******* FINAL REQUEST JSON: ' +
            JSON.serializePretty(requestBody)
        );

        HttpResponse response =
            DMT_HPG_Utils.callService(
                'DMT_OpportunityCodes_Bulk',
                new Map<String,Object>{
                    'requestBody' => JSON.serialize(requestBody)
                }
            );

        System.debug(
            '******* RESPONSE STATUS: ' +
            response.getStatusCode()
        );

        System.debug(
            '******* RESPONSE BODY: ' +
            response.getBody()
        );

        if (response.getStatusCode() != 201) {
            throw new AuraHandledException(
                'Error calling opportunity service: ' +
                response.getBody()
            );
        }

        List<String> result = new List<String>();

        Map<String,Object> responseMap =
            (Map<String,Object>) JSON.deserializeUntyped(
                response.getBody()
            );

        if (
            responseMap == null ||
            !responseMap.containsKey('data')
        ) {
            throw new AuraHandledException(
                'Invalid response format'
            );
        }

        Map<String,Object> data =
            (Map<String,Object>) responseMap.get('data');

        if (
            data == null ||
            !data.containsKey('codes')
        ) {
            throw new AuraHandledException(
                'No codes returned by service'
            );
        }

        List<Object> codes =
            (List<Object>) data.get('codes');

        for (Object obj : codes) {

            Map<String,Object> codeMap =
                (Map<String,Object>) obj;

            result.add(
                (String) codeMap.get('opportunityId')
            );
        }

        if (result.size() != lines.size()) {
            throw new AuraHandledException(
                'Mismatch between request and response size'
            );
        }

        return result;
    }

    public static void cleanFieldsForRenew(DMT_Line__c line) {

        line.OwnerId = UserInfo.getUserId();

        line.DMT_LastGeneratedVersionName__c = null;
        line.DMT_Approval_Validation__c = false;
        line.DMT_Approval_Date__c = null;
        line.DMT_DateToProposal__c = null;
        line.Status__c = 'Draft';
        line.Closed__c = null;

        line.Line_Id__c = null;
    }

    public static void cloneRelatedRecordsDynamic(
        List<DMT_Line__c> originals,
        List<DMT_Line__c> clones
    ) {

        if (originals.isEmpty() || clones.isEmpty()) {
            return;
        }

        Map<Id, Id> mapOldToNew = new Map<Id, Id>();
        Map<Id, String> oldLineToNewLineId = new Map<Id, String>();
        Map<Id, Id> oldLineToOldPrincipalAssoc = new Map<Id, Id>();

        for (Integer i = 0; i < originals.size(); i++) {

            mapOldToNew.put(
                originals[i].Id,
                clones[i].Id
            );

            oldLineToNewLineId.put(
                originals[i].Id,
                clones[i].Line_Id__c
            );

            oldLineToOldPrincipalAssoc.put(
                originals[i].Id,
                originals[i].Custom_Association__c
            );
        }

        Set<Id> oldLineIds = mapOldToNew.keySet();

        Map<Id, Id> riskTermOldToNew = cloneGenericObjectWithMap(
            'DMT_Risk_Line_Term__c',
            'DMT_Line__c',
            oldLineIds,
            mapOldToNew
        );

        if (!riskTermOldToNew.isEmpty()) {

            cloneGenericObject(
                'DMT_Warranty__c',
                'DMT_Risk_Line_Term__c',
                riskTermOldToNew.keySet(),
                riskTermOldToNew
            );

            cloneGenericObject(
                'DMT_Currency_Provision__c',
                'DMT_Risk_Line_Term__c',
                riskTermOldToNew.keySet(),
                riskTermOldToNew
            );
        }

        cloneGenericObject(
            'DMT_Line_Product_Item__c',
            'Line__c',
            oldLineIds,
            mapOldToNew
        );

        List<Custom_Association__c> oldAssociations = [
            SELECT Id,
                Name,
                DMT_Line__c,
                gf_customer_group_id__c
            FROM Custom_Association__c
            WHERE DMT_Line__c IN :oldLineIds
        ];

        Map<Id, Custom_Association__c> oldAssocMap =
            new Map<Id, Custom_Association__c>();

        for (Custom_Association__c assoc : oldAssociations) {
            oldAssocMap.put(assoc.Id, assoc);
        }

        Map<Id, Id> oldAssocToNewAssoc = new Map<Id, Id>();

        List<Custom_Association__c> newAssociations =
            new List<Custom_Association__c>();

        List<Id> oldAssocIdsToInsert = new List<Id>();

        Set<String> existingLineAndGroupKeys = new Set<String>();
        Map<String, Id> existingAssocIdByKey = new Map<String, Id>();
        Map<Id, Set<String>> usedSuffixesByNewLine = new Map<Id, Set<String>>();

        Map<Id, String> newLineIdToBaseLineId = new Map<Id, String>();
        for (Id oldLineId : mapOldToNew.keySet()) {
            newLineIdToBaseLineId.put(
                mapOldToNew.get(oldLineId),
                oldLineToNewLineId.get(oldLineId)
            );
        }

        Set<String> plannedLineAndGroupKeys = new Set<String>();

        for (Custom_Association__c existingAssoc : [
            SELECT Id, DMT_Line__c, gf_customer_group_id__c
            FROM Custom_Association__c
            WHERE DMT_Line__c IN :mapOldToNew.values()
              AND gf_customer_group_id__c != null
        ]) {
            String existingKey =
                String.valueOf(existingAssoc.DMT_Line__c) +
                '|' +
                existingAssoc.gf_customer_group_id__c;

            existingLineAndGroupKeys.add(existingKey);
            existingAssocIdByKey.put(existingKey, existingAssoc.Id);

            if (!usedSuffixesByNewLine.containsKey(existingAssoc.DMT_Line__c)) {
                usedSuffixesByNewLine.put(existingAssoc.DMT_Line__c, new Set<String>());
            }

            String baseLineId = newLineIdToBaseLineId.get(existingAssoc.DMT_Line__c);
            String existingSuffix = '';

            if (
                !String.isBlank(baseLineId) &&
                existingAssoc.gf_customer_group_id__c.startsWith(baseLineId)
            ) {
                existingSuffix = existingAssoc.gf_customer_group_id__c.substring(baseLineId.length());
            }

            usedSuffixesByNewLine.get(existingAssoc.DMT_Line__c).add(existingSuffix);
        }

        for (Custom_Association__c oldAssoc : oldAssociations) {

            Id oldLineId = oldAssoc.DMT_Line__c;

            Id newLineId = mapOldToNew.get(oldLineId);

            String newBaseLineId =
                oldLineToNewLineId.get(oldLineId);

            Id oldPrincipalAssocId =
                oldLineToOldPrincipalAssoc.get(oldLineId);

            Boolean isPrincipalAssoc =
                oldAssoc.Id == oldPrincipalAssocId;

            String oldCustomerGroup =
                oldAssoc.gf_customer_group_id__c;

            String suffix = '';

            Pattern p = Pattern.compile('(_\\d+)$');
            Matcher m = p.matcher(oldCustomerGroup == null ? '' : oldCustomerGroup);

            if (m.find()) {
                suffix = m.group(1);
            }

            if (!usedSuffixesByNewLine.containsKey(newLineId)) {
                usedSuffixesByNewLine.put(newLineId, new Set<String>());
            }

            Set<String> usedSuffixes = usedSuffixesByNewLine.get(newLineId);

            if (isPrincipalAssoc) {
                suffix = '';
            } else if (String.isBlank(suffix)) {
                suffix = '_01';
            }

            String newCustomerGroupId =
                newBaseLineId + suffix;

            String existingKey =
                String.valueOf(newLineId) +
                '|' +
                newCustomerGroupId;

            if (existingLineAndGroupKeys.contains(existingKey)) {
                oldAssocToNewAssoc.put(oldAssoc.Id, existingAssocIdByKey.get(existingKey));
                usedSuffixes.add(suffix);
                continue;
            }

            if (!isPrincipalAssoc) {
                Integer counter;
                if (
                    String.isNotBlank(suffix) &&
                    suffix.startsWith('_') &&
                    suffix.length() > 1
                ) {
                    String numericPart = suffix.substring(1);
                    if (Pattern.matches('^[0-9]+$', numericPart)) {
                        counter = Integer.valueOf(numericPart);
                    } else {
                        counter = 1;
                    }
                } else {
                    counter = 1;
                }

                while (
                    usedSuffixes.contains(suffix) ||
                    plannedLineAndGroupKeys.contains(existingKey)
                ) {
                    suffix = '_' + String.valueOf(counter).leftPad(2, '0');
                    newCustomerGroupId = newBaseLineId + suffix;
                    existingKey = String.valueOf(newLineId) + '|' + newCustomerGroupId;
                    counter++;

                    if (existingLineAndGroupKeys.contains(existingKey)) {
                        oldAssocToNewAssoc.put(oldAssoc.Id, existingAssocIdByKey.get(existingKey));
                        usedSuffixes.add(suffix);
                        break;
                    }
                }

                if (oldAssocToNewAssoc.containsKey(oldAssoc.Id)) {
                    continue;
                }
            } else if (plannedLineAndGroupKeys.contains(existingKey)) {
                throw new AuraHandledException(
                    'Duplicate principal association detected for new line ' +
                    newBaseLineId + ': ' + newCustomerGroupId
                );
            }

            usedSuffixes.add(suffix);

            plannedLineAndGroupKeys.add(
                String.valueOf(newLineId) + '|' + newCustomerGroupId
            );

            Custom_Association__c newAssoc =
                oldAssoc.clone(false, false, false, false);

            newAssoc.DMT_Line__c = newLineId;

            newAssoc.gf_customer_group_id__c =
                newCustomerGroupId;

            newAssociations.add(newAssoc);
            oldAssocIdsToInsert.add(oldAssoc.Id);
        }

        if (!newAssociations.isEmpty()) {

            insert newAssociations;

            for (Integer i = 0; i < oldAssocIdsToInsert.size(); i++) {

                oldAssocToNewAssoc.put(
                    oldAssocIdsToInsert[i],
                    newAssociations[i].Id
                );
            }
        }

        List<DMT_Line__c> linesToUpdate =
            new List<DMT_Line__c>();

        for (DMT_Line__c newLine : clones) {

            Id oldLineId = newLine.DMT_Parent_Line__c;

            Id oldPrincipalAssocId =
                oldLineToOldPrincipalAssoc.get(oldLineId);

            Id newPrincipalAssocId =
                oldAssocToNewAssoc.get(oldPrincipalAssocId);

            if (newPrincipalAssocId != null) {

                linesToUpdate.add(
                    new DMT_Line__c(
                        Id = newLine.Id,
                        Custom_Association__c =
                            newPrincipalAssocId
                    )
                );
            }
        }

        if (!linesToUpdate.isEmpty()) {
            update linesToUpdate;
        }

        if (oldAssocToNewAssoc.isEmpty()) {
            return;
        }

        Set<Id> oldAssocIdsForClients = oldAssocToNewAssoc.keySet();

        Map<String, Schema.SObjectField> clientFieldsMap =
            Custom_Association_Client__c.SObjectType.getDescribe().fields.getMap();

        List<String> clientFieldNames = new List<String>();
        for (String fieldName : clientFieldsMap.keySet()) {
            clientFieldNames.add(fieldName);
        }

        String clientQuery =
            'SELECT ' + String.join(clientFieldNames, ',') +
            ' FROM Custom_Association_Client__c' +
            ' WHERE Custom_Association__c IN :oldAssocIdsForClients';

        List<Custom_Association_Client__c> oldClients =
            (List<Custom_Association_Client__c>) Database.query(clientQuery);

        List<Custom_Association_Client__c> newClients =
            new List<Custom_Association_Client__c>();

        for (Custom_Association_Client__c oldClient : oldClients) {

            Id newAssocId =
                oldAssocToNewAssoc.get(
                    oldClient.Custom_Association__c
                );

            String oldCustomerGroup =
                oldClient.gf_customer_group_id__c;

            String suffix = '';

            if (
                !String.isBlank(oldCustomerGroup) &&
                oldCustomerGroup.contains('_')
            ) {
                suffix =
                    oldCustomerGroup.substring(
                        oldCustomerGroup.lastIndexOf('_')
                    );
            }

            Id oldAssocId =
                oldClient.Custom_Association__c;

            Custom_Association__c oldAssoc =
                oldAssocMap.get(oldAssocId);

            if (oldAssoc == null) {
                continue;
            }

            String newBaseLineId =
                oldLineToNewLineId.get(oldAssoc.DMT_Line__c);

            String newCustomerGroupId =
                newBaseLineId + suffix;

            Custom_Association_Client__c newClient =
                oldClient.clone(false, false, false, false);

            newClient.Custom_Association__c = newAssocId;

            if (String.isBlank(newClient.Alpha_Code_Client__c)) {
                newClient.Alpha_Code_Client__c = oldClient.Alpha_Code_Client__c;
            }
            if (String.isBlank(newClient.Alpha_Code_Client__c)) {
                newClient.Alpha_Code_Client__c = oldClient.g_customer_id__c;
            }

            newClient.gf_customer_group_id__c =
                newCustomerGroupId;

            newClients.add(newClient);
        }

        if (!newClients.isEmpty()) {
            insert newClients;
        }
    }

    public static void cloneGenericObject(String objectName, String lookupField, Set<Id> parentIds, Map<Id, Id> parentMap) {

        Schema.SObjectType objType = getValidatedSObjectType(objectName);

        Map<String, Schema.SObjectField> fieldsMap =
            objType.getDescribe().fields.getMap();

        validateFieldForObject(lookupField, fieldsMap, objectName);

        List<String> fieldNames = new List<String>();

        for (String f : fieldsMap.keySet()) {
            fieldNames.add(f);
        }

        String query = 'SELECT ' + String.join(fieldNames, ',') +
                    ' FROM ' + objectName +
                    ' WHERE ' + lookupField + ' IN :parentIds';

        List<SObject> records = Database.query(query);

        if (records.isEmpty()) return;

        List<SObject> newRecords = new List<SObject>();

        for (SObject rec : records) {

            SObject cloneRec = rec.clone(false, false, false, false);

            cloneRec.put(lookupField, parentMap.get((Id)rec.get(lookupField)));

            if (cloneRec.getSObjectType().getDescribe().fields.getMap().containsKey('OwnerId')) {
                cloneRec.put('OwnerId', UserInfo.getUserId());
            }

            newRecords.add(cloneRec);
        }

        insert newRecords;
    }

    public static void cloneGenericObject(
        String objectName,
        String lookupField,
        Set<Id> parentIds,
        Map<Id, Id> parentMap,
        Map<Id, String> parentToNewLineId,
        String lineIdField
    ) {
        cloneGenericObjectWithMap(
            objectName,
            lookupField,
            parentIds,
            parentMap,
            parentToNewLineId,
            lineIdField
        );
    }

    public static Map<Id, Id> cloneGenericObjectWithMap(String objectName, String lookupField, Set<Id> parentIds, Map<Id, Id> parentMap) {

        Schema.SObjectType objType = getValidatedSObjectType(objectName);

        Map<String, Schema.SObjectField> fieldsMap =
            objType.getDescribe().fields.getMap();

        validateFieldForObject(lookupField, fieldsMap, objectName);

        List<String> fieldNames = new List<String>();

        for (String f : fieldsMap.keySet()) {
            fieldNames.add(f);
        }

        String query = 'SELECT ' + String.join(fieldNames, ',') +
                    ' FROM ' + objectName +
                    ' WHERE ' + lookupField + ' IN :parentIds';

        List<SObject> records = Database.query(query);

        Map<Id, Id> resultMap = new Map<Id, Id>();

        if (records.isEmpty()) return resultMap;

        List<SObject> newRecords = new List<SObject>();

        for (SObject rec : records) {

            SObject cloneRec = rec.clone(false, false, false, false);

            Id oldParentId = (Id) rec.get(lookupField);
            cloneRec.put(lookupField, parentMap.get(oldParentId));

            if (fieldsMap.containsKey('OwnerId')) {
                cloneRec.put('OwnerId', UserInfo.getUserId());
            }

            newRecords.add(cloneRec);
        }

        insert newRecords;

        for (Integer i = 0; i < records.size(); i++) {
            resultMap.put(
                (Id) records[i].get('Id'),
                (Id) newRecords[i].get('Id')
            );
        }

        return resultMap;
    }

    public static Map<Id, Id> cloneGenericObjectWithMap(
        String objectName,
        String lookupField,
        Set<Id> parentIds,
        Map<Id, Id> parentMap,
        Map<Id, String> parentToNewLineId,
        String lineIdField
    ) {
        Map<Id, Id> resultMap = new Map<Id, Id>();

        Schema.SObjectType objType = getValidatedSObjectType(objectName);

        Map<String, Schema.SObjectField> fieldsMap =
            objType.getDescribe().fields.getMap();

        validateFieldForObject(lookupField, fieldsMap, objectName);

        List<String> fieldNames = new List<String>();

        for (String f : fieldsMap.keySet()) {
            fieldNames.add(f);
        }

        String query = 'SELECT ' + String.join(fieldNames, ',') +
                    ' FROM ' + objectName +
                    ' WHERE ' + lookupField + ' IN :parentIds';

        List<SObject> records = Database.query(query);

        if (records.isEmpty()) return resultMap;

        List<SObject> newRecords = new List<SObject>();

        for (SObject rec : records) {
            SObject cloneRec = rec.clone(false, false, false, false);

            Id oldParentId = (Id) rec.get(lookupField);
            cloneRec.put(lookupField, parentMap.get(oldParentId));

            if (fieldsMap.containsKey('OwnerId')) {
                cloneRec.put('OwnerId', UserInfo.getUserId());
            }

            if (
                !String.isBlank(lineIdField) &&
                fieldsMap.containsKey(lineIdField) &&
                parentToNewLineId != null &&
                parentToNewLineId.containsKey(oldParentId)
            ) {
                cloneRec.put(lineIdField, parentToNewLineId.get(oldParentId));
            }

            newRecords.add(cloneRec);
        }

        insert newRecords;

        for (Integer i = 0; i < records.size(); i++) {
            resultMap.put(
                (Id) records[i].get('Id'),
                (Id) newRecords[i].get('Id')
            );
        }

        return resultMap;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Boolean> getAutoByLineIds(List<String> lineIds) {

        if (lineIds == null || lineIds.isEmpty()) {
            return new Map<String, Boolean>();
        }

        List<DMT_Consolidated_Line__c> records = [
            SELECT Line_Id__c, G_Multioperation_Ind_Type__c
            FROM DMT_Consolidated_Line__c
            WHERE Line_Id__c IN :lineIds
            AND GF_Group_Priority_Line_Id__c = '00'
        ];

        Map<String, Boolean> result = new Map<String, Boolean>();

        for (DMT_Consolidated_Line__c rec : records) {
            String typeVal = rec.G_Multioperation_Ind_Type__c;

            Boolean isAuto = (typeVal == 'T' || typeVal == 'F');

            result.put(rec.Line_Id__c, isAuto);
        }

        return result;
    }

    public static List<String> generateMockOpportunityIds(List<DMT_Line__c> lines) {

        List<String> result = new List<String>();

        Integer counter = 1;

        for (DMT_Line__c line : lines) {

            String original = line.Line_Id__c;

            if (String.isBlank(original) || original.length() < 10) {
                result.add('ESCD26LINTEST0000ES');
                continue;
            }

            String prefix = original.substring(0, 9);
            String suffix = original.substring(original.length() - 2);

            Integer randomNumber = Math.floor(Math.random() * 9000).intValue() + 1000;
            String numberPart = String.valueOf(randomNumber);

            String mockId =
                prefix + 'TEST' + numberPart + suffix;

            result.add(mockId);

            counter++;
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static ModifyPayload getModifyPayload(List<String> lineIds) {
        if (lineIds == null || lineIds.isEmpty()) {
            throw new AuraHandledException('No lineIds provided');
        }

        List<DMT_Line__c> baseLines = [
            SELECT Id,
                Name,
                Line_Id__c,
                Status__c,
                DMT_Line_Template_Type__c,
                Booking_Geography__c,
                DMT_DerivativesAmount__c,
                CurrencyIsoCode
            FROM DMT_Line__c
            WHERE Line_Id__c IN :lineIds
        ];

        if (baseLines.isEmpty()) {
            throw new AuraHandledException('No lines found');
        }

        for (DMT_Line__c line : baseLines) {
            if (line.Status__c != 'Draft') {
                throw new AuraHandledException(
                    'Only Draft lines can be modified. Invalid line: ' + line.Line_Id__c
                );
            }
        }

        Set<String> templates = new Set<String>();
        Set<String> geographies = new Set<String>();
        Set<Id> lineRecordIds = new Set<Id>();

        for (DMT_Line__c line : baseLines) {
            templates.add(line.DMT_Line_Template_Type__c);
            geographies.add(line.Booking_Geography__c);
            lineRecordIds.add(line.Id);
        }

        List<DMT_Line_Modify_Field_Config__mdt> configs = [
            SELECT Line_Template__c,
                Booking_Geography__c,
                Object_Api_Name__c,
                Lookup_Field__c,
                Section_Key__c,
                Section_Label__c,
                Field_Api_Name__c,
                Field_Label__c,
                Input_Type__c,
                Picklist_Options_JSON__c,
                Required__c,
                Section_Order__c,
                Order__c,
                Active__c
            FROM DMT_Line_Modify_Field_Config__mdt
            WHERE Active__c = true
            AND Line_Template__c IN :templates
            AND Booking_Geography__c IN :geographies
            ORDER BY Section_Order__c ASC, Order__c ASC
        ];

        if (configs.isEmpty()) {
            throw new AuraHandledException(
                'No editable fields configured for selected lines'
            );
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        Set<String> lineFieldNames = new Set<String>{
            'Id',
            'Name',
            'Line_Id__c',
            'Status__c',
            'DMT_Line_Template_Type__c',
            'Booking_Geography__c',
            'DMT_DerivativesAmount__c',
            'CurrencyIsoCode'
        };

        Map<String, Schema.SObjectField> lineObjectFieldsMap =
            DMT_Line__c.SObjectType.getDescribe().fields.getMap();

        Map<String, List<DMT_Line_Modify_Field_Config__mdt>> relatedConfigsByObject = new Map<String, List<DMT_Line_Modify_Field_Config__mdt>>();

        for (DMT_Line_Modify_Field_Config__mdt cfg : configs) {
            if (String.isBlank(cfg.Object_Api_Name__c)) {
                throw new AuraHandledException('Object_Api_Name__c is required in modify metadata');
            }

            if (String.isBlank(cfg.Field_Api_Name__c)) {
                throw new AuraHandledException('Field_Api_Name__c is required in modify metadata');
            }

            validateSafeIdentifier(cfg.Object_Api_Name__c, 'object api name');
            validateSafeIdentifier(cfg.Field_Api_Name__c, 'field api name');

            if (cfg.Object_Api_Name__c == 'DMT_Line__c') {
                if (!lineObjectFieldsMap.containsKey(cfg.Field_Api_Name__c)) {
                    throw new AuraHandledException(
                        'Invalid configured field ' + cfg.Field_Api_Name__c +
                        ' for object DMT_Line__c'
                    );
                }

                lineFieldNames.add(cfg.Field_Api_Name__c);
            } else {
                if (String.isBlank(cfg.Lookup_Field__c)) {
                    throw new AuraHandledException(
                        'Lookup_Field__c is required for related object: ' + cfg.Object_Api_Name__c
                    );
                }

                validateSafeIdentifier(cfg.Lookup_Field__c, 'lookup field');

                if (!relatedConfigsByObject.containsKey(cfg.Object_Api_Name__c)) {
                    relatedConfigsByObject.put(
                        cfg.Object_Api_Name__c,
                        new List<DMT_Line_Modify_Field_Config__mdt>()
                    );
                }

                relatedConfigsByObject.get(cfg.Object_Api_Name__c).add(cfg);
            }
        }

        String lineQuery =
            'SELECT ' + String.join(new List<String>(lineFieldNames), ',') +
            ' FROM DMT_Line__c WHERE Id IN :lineRecordIds';

        List<DMT_Line__c> fullLines =
            (List<DMT_Line__c>) Database.query(lineQuery);

        Map<String, List<SObject>> relatedRecordsByObject = new Map<String, List<SObject>>();

        for (String objectApiName : relatedConfigsByObject.keySet()) {
            if (!globalDescribe.containsKey(objectApiName)) {
                throw new AuraHandledException('Invalid configured object: ' + objectApiName);
            }

            List<DMT_Line_Modify_Field_Config__mdt> objectConfigs =
                relatedConfigsByObject.get(objectApiName);

            String lookupField = objectConfigs[0].Lookup_Field__c;
            validateSafeIdentifier(lookupField, 'lookup field');

            Schema.SObjectType objType = globalDescribe.get(objectApiName);
            Map<String, Schema.SObjectField> fieldsMap =
                objType.getDescribe().fields.getMap();

            if (!fieldsMap.containsKey(lookupField)) {
                throw new AuraHandledException(
                    'Invalid lookup field ' + lookupField + ' for object ' + objectApiName
                );
            }

            Set<String> fieldsToQuery = new Set<String>{
                'Id',
                lookupField
            };

            String nameFieldApi = resolveFieldApiName(fieldsMap, 'Name');
            if (String.isNotBlank(nameFieldApi)) {
                fieldsToQuery.add(nameFieldApi);
            }

            for (DMT_Line_Modify_Field_Config__mdt cfg : objectConfigs) {
                if (!fieldsMap.containsKey(cfg.Field_Api_Name__c)) {
                    throw new AuraHandledException(
                        'Invalid configured field ' + cfg.Field_Api_Name__c +
                        ' for object ' + objectApiName
                    );
                }

                fieldsToQuery.add(cfg.Field_Api_Name__c);
            }

            if (objectApiName == 'DMT_Risk_Line_Term__c') {
                if (fieldsMap.containsKey('DMT_Risk_Type__c')) {
                    fieldsToQuery.add('DMT_Risk_Type__c');
                }

                if (fieldsMap.containsKey('DMT_Init_Term__c')) {
                    fieldsToQuery.add('DMT_Init_Term__c');
                }

                if (fieldsMap.containsKey('DMT_End_Term__c')) {
                    fieldsToQuery.add('DMT_End_Term__c');
                }

                if (fieldsMap.containsKey('DMT_Amount__c')) {
                    fieldsToQuery.add('DMT_Amount__c');
                }
            }

            String relatedQuery =
                'SELECT ' + String.join(new List<String>(fieldsToQuery), ',') +
                ' FROM ' + objectApiName +
                ' WHERE ' + lookupField + ' IN :lineRecordIds';

            relatedRecordsByObject.put(
                objectApiName,
                Database.query(relatedQuery)
            );
        }

        ModifyPayload payload = new ModifyPayload();

        for (DMT_Line__c line : fullLines) {
            ModifyRowDTO row = new ModifyRowDTO();
            row.id = line.Id;
            row.lineId = line.Line_Id__c;
            row.lineName = String.isNotBlank(line.Name) ? line.Name : line.Line_Id__c;
            row.lineUrl = '/' + String.valueOf(line.Id);
            row.templateType = line.DMT_Line_Template_Type__c;
            row.derivativesAmount = line.get('DMT_DerivativesAmount__c');
            row.currencyIsoCode = line.CurrencyIsoCode;

            List<DMT_Line_Modify_Field_Config__mdt> lineConfigs =
                getConfigsForLine(configs, line, 'DMT_Line__c');

            Map<String, Schema.SObjectField> lineFieldsMap =
                DMT_Line__c.SObjectType.getDescribe().fields.getMap();

            for (DMT_Line_Modify_Field_Config__mdt cfg : lineConfigs) {
                Schema.DescribeFieldResult d =
                    lineFieldsMap.get(cfg.Field_Api_Name__c).getDescribe();

                if (!d.isUpdateable()) {
                    continue;
                }

                Object value = line.get(cfg.Field_Api_Name__c);

                row.values.put(cfg.Field_Api_Name__c, value);
                row.cells.add(
                    buildCell(
                        String.valueOf(line.Id) + '-' + cfg.Field_Api_Name__c,
                        cfg.Field_Api_Name__c,
                        cfg.Field_Label__c,
                        d,
                        value,
                        cfg.Required__c,
                        cfg.Input_Type__c,
                        cfg.Picklist_Options_JSON__c
                    )
                );
            }

            row.relatedSections =
                buildRelatedSectionsForLine(
                    line,
                    configs,
                    relatedRecordsByObject,
                    globalDescribe
                );

            payload.rows.add(row);
        }

        return payload;
    }

    public static String resolveInputType(Schema.DescribeFieldResult d) {
        Schema.DisplayType t = d.getType();

        if (t == Schema.DisplayType.Date) {
            return 'date';
        }

        if (t == Schema.DisplayType.DateTime) {
            return 'datetime';
        }

        if (
            t == Schema.DisplayType.Currency ||
            t == Schema.DisplayType.Double ||
            t == Schema.DisplayType.Integer ||
            t == Schema.DisplayType.Percent
        ) {
            return 'number';
        }

        if (t == Schema.DisplayType.Boolean) {
            return 'checkbox';
        }

        if (t == Schema.DisplayType.Email) {
            return 'email';
        }

        if (t == Schema.DisplayType.Phone) {
            return 'tel';
        }

        if (t == Schema.DisplayType.Picklist) {
            return 'picklist';
        }

        return 'text';
    }

    @AuraEnabled
    public static void saveModifiedLines(List<ModifySaveRowDTO> rows) {
        if (rows == null || rows.isEmpty()) {
            throw new AuraHandledException('No rows provided');
        }

        Set<Id> lineIds = new Set<Id>();

        for (ModifySaveRowDTO row : rows) {
            if (row == null || row.id == null) {
                throw new AuraHandledException('Invalid modify payload. Missing line record Id.');
            }

            lineIds.add(row.id);
        }

        Map<Id, DMT_Line__c> linesById = new Map<Id, DMT_Line__c>([
            SELECT Id,
                Line_Id__c,
                Status__c,
                DMT_Line_Template_Type__c,
                Booking_Geography__c
            FROM DMT_Line__c
            WHERE Id IN :lineIds
            FOR UPDATE
        ]);

        if (linesById.isEmpty()) {
            throw new AuraHandledException('No lines found');
        }

        Set<String> templates = new Set<String>();
        Set<String> geographies = new Set<String>();

        for (DMT_Line__c line : linesById.values()) {
            if (line.Status__c != 'Draft') {
                throw new AuraHandledException(
                    'Only Draft lines can be modified. Invalid line: ' + line.Line_Id__c
                );
            }

            templates.add(line.DMT_Line_Template_Type__c);
            geographies.add(line.Booking_Geography__c);
        }

        List<DMT_Line_Modify_Field_Config__mdt> configs = [
            SELECT Line_Template__c,
                Booking_Geography__c,
                Object_Api_Name__c,
                Lookup_Field__c,
                Section_Key__c,
                Section_Label__c,
                Field_Api_Name__c,
                Field_Label__c,
                Input_Type__c,
                Picklist_Options_JSON__c,
                Required__c,
                Section_Order__c,
                Order__c,
                Active__c
            FROM DMT_Line_Modify_Field_Config__mdt
            WHERE Active__c = true
            AND Line_Template__c IN :templates
            AND Booking_Geography__c IN :geographies
        ];

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        Map<String, Map<Id, SObject>> existingRelatedByObjectAndId =
            loadExistingRelatedRecordsForSave(rows, configs, lineIds, globalDescribe);

        List<SObject> updates = new List<SObject>();

        for (ModifySaveRowDTO row : rows) {
            DMT_Line__c existingLine = linesById.get(row.id);

            if (existingLine == null) {
                throw new AuraHandledException('Line not found: ' + row.lineId);
            }

            if (row.values != null && !row.values.isEmpty()) {
                DMT_Line__c lineUpdate = new DMT_Line__c(Id = row.id);

                Map<String, Schema.SObjectField> lineFieldsMap =
                    DMT_Line__c.SObjectType.getDescribe().fields.getMap();

                Set<String> allowedLineFields =
                    getAllowedFieldsForLine(configs, existingLine, 'DMT_Line__c');

                for (String fieldApi : row.values.keySet()) {
                    if (!allowedLineFields.contains(fieldApi)) {
                        throw new AuraHandledException(
                            'Field not allowed for line modify: DMT_Line__c.' + fieldApi
                        );
                    }

                    Schema.DescribeFieldResult d =
                        lineFieldsMap.get(fieldApi).getDescribe();

                    if (!d.isUpdateable()) {
                        throw new AuraHandledException('Field is not updateable: ' + fieldApi);
                    }

                    lineUpdate.put(
                        fieldApi,
                        castValueForField(row.values.get(fieldApi), d)
                    );
                }

                updates.add(lineUpdate);
            }

            if (row.relatedSections == null) {
                continue;
            }

            for (ModifySaveRelatedSectionDTO section : row.relatedSections) {
                if (
                    section == null ||
                    String.isBlank(section.objectApiName) ||
                    section.records == null
                ) {
                    continue;
                }

                if (!globalDescribe.containsKey(section.objectApiName)) {
                    throw new AuraHandledException(
                        'Invalid related object: ' + section.objectApiName
                    );
                }

                Schema.SObjectType objType =
                    globalDescribe.get(section.objectApiName);

                Map<String, Schema.SObjectField> fieldsMap =
                    objType.getDescribe().fields.getMap();

                Set<String> allowedRelatedFields =
                    getAllowedFieldsForLine(configs, existingLine, section.objectApiName);

                Map<Id, SObject> existingRecords =
                    existingRelatedByObjectAndId.get(section.objectApiName);

                for (ModifySaveRelatedRecordDTO relatedRecord : section.records) {
                    if (
                        relatedRecord == null ||
                        relatedRecord.id == null ||
                        relatedRecord.values == null ||
                        relatedRecord.values.isEmpty()
                    ) {
                        continue;
                    }

                    if (
                        existingRecords == null ||
                        !existingRecords.containsKey(relatedRecord.id)
                    ) {
                        throw new AuraHandledException(
                            'Related record not found or not related to selected lines: ' +
                            relatedRecord.id
                        );
                    }

                    SObject updateRecord =
                        objType.newSObject(relatedRecord.id);

                    for (String fieldApi : relatedRecord.values.keySet()) {
                        if (!allowedRelatedFields.contains(fieldApi)) {
                            throw new AuraHandledException(
                                'Field not allowed for related modify: ' +
                                section.objectApiName + '.' + fieldApi
                            );
                        }

                        if (!fieldsMap.containsKey(fieldApi)) {
                            throw new AuraHandledException(
                                'Invalid field ' + fieldApi +
                                ' for object ' + section.objectApiName
                            );
                        }

                        Schema.DescribeFieldResult d =
                            fieldsMap.get(fieldApi).getDescribe();

                        if (!d.isUpdateable()) {
                            throw new AuraHandledException(
                                'Field is not updateable: ' +
                                section.objectApiName + '.' + fieldApi
                            );
                        }

                        updateRecord.put(
                            fieldApi,
                            castValueForField(relatedRecord.values.get(fieldApi), d)
                        );
                    }

                    updates.add(updateRecord);
                }
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    public static List<DMT_Line_Modify_Field_Config__mdt> getConfigsForLine(
        List<DMT_Line_Modify_Field_Config__mdt> configs,
        DMT_Line__c line,
        String objectApiName
    ) {
        List<DMT_Line_Modify_Field_Config__mdt> result =
            new List<DMT_Line_Modify_Field_Config__mdt>();

        for (DMT_Line_Modify_Field_Config__mdt cfg : configs) {
            if (
                cfg.Object_Api_Name__c == objectApiName &&
                cfg.Line_Template__c == line.DMT_Line_Template_Type__c &&
                cfg.Booking_Geography__c == line.Booking_Geography__c
            ) {
                result.add(cfg);
            }
        }

        return result;
    }

    public static Set<String> getAllowedFieldsForLine(
        List<DMT_Line_Modify_Field_Config__mdt> configs,
        DMT_Line__c line,
        String objectApiName
    ) {
        Set<String> result = new Set<String>();

        for (DMT_Line_Modify_Field_Config__mdt cfg : configs) {
            if (
                cfg.Object_Api_Name__c == objectApiName &&
                cfg.Line_Template__c == line.DMT_Line_Template_Type__c &&
                cfg.Booking_Geography__c == line.Booking_Geography__c
            ) {
                result.add(cfg.Field_Api_Name__c);
            }
        }

        if (
            line.DMT_Line_Template_Type__c == 'TL' &&
            objectApiName == 'DMT_Risk_Line_Term__c'
        ) {
            result.add('DMT_Init_Term__c');
            result.add('DMT_End_Term__c');
            result.add('DMT_Amount__c');
        }

        return result;
    }

public static List<ModifyRelatedSectionDTO> buildRelatedSectionsForLine(
    DMT_Line__c line,
    List<DMT_Line_Modify_Field_Config__mdt> configs,
    Map<String, List<SObject>> relatedRecordsByObject,
    Map<String, Schema.SObjectType> globalDescribe
) {
    System.debug('MODIFY DEBUG - buildRelatedSectionsForLine START');
    System.debug('MODIFY DEBUG - line Id => ' + line.Id);
    System.debug('MODIFY DEBUG - line Line_Id__c => ' + line.Line_Id__c);
    System.debug('MODIFY DEBUG - line template => ' + line.DMT_Line_Template_Type__c);
    System.debug('MODIFY DEBUG - line geography => ' + line.Booking_Geography__c);
    System.debug('MODIFY DEBUG - configs size => ' + configs.size());
    System.debug('MODIFY DEBUG - relatedRecordsByObject keys => ' + relatedRecordsByObject.keySet());

    List<ModifyRelatedSectionDTO> sections = new List<ModifyRelatedSectionDTO>();
    Map<String, ModifyRelatedSectionDTO> sectionByKey = new Map<String, ModifyRelatedSectionDTO>();

    for (DMT_Line_Modify_Field_Config__mdt cfg : configs) {
        System.debug(
            'MODIFY DEBUG - cfg check => object=' + cfg.Object_Api_Name__c +
            ', template=' + cfg.Line_Template__c +
            ', geography=' + cfg.Booking_Geography__c +
            ', field=' + cfg.Field_Api_Name__c +
            ', lookup=' + cfg.Lookup_Field__c +
            ', sectionKey=' + cfg.Section_Key__c
        );

        if (
            cfg.Object_Api_Name__c == 'DMT_Line__c' ||
            cfg.Line_Template__c != line.DMT_Line_Template_Type__c ||
            cfg.Booking_Geography__c != line.Booking_Geography__c
        ) {
            continue;
        }

        String sectionKey =
            String.isNotBlank(cfg.Section_Key__c)
                ? cfg.Section_Key__c
                : cfg.Object_Api_Name__c;

        String compoundKey =
            cfg.Object_Api_Name__c + '|' + cfg.Lookup_Field__c + '|' + sectionKey;

        if (!sectionByKey.containsKey(compoundKey)) {
            ModifyRelatedSectionDTO section = new ModifyRelatedSectionDTO();
            section.key = sectionKey;
            section.label = String.isNotBlank(cfg.Section_Label__c)
                ? cfg.Section_Label__c
                : cfg.Object_Api_Name__c;
            section.objectApiName = cfg.Object_Api_Name__c;
            section.lookupField = cfg.Lookup_Field__c;
            section.orderNumber = cfg.Section_Order__c == null
                ? 999
                : Integer.valueOf(cfg.Section_Order__c);

            sectionByKey.put(compoundKey, section);
            sections.add(section);

            System.debug(
                'MODIFY DEBUG - section created => compoundKey=' + compoundKey +
                ', object=' + section.objectApiName +
                ', lookup=' + section.lookupField +
                ', key=' + section.key
            );
        }
    }

    System.debug('MODIFY DEBUG - sections created size => ' + sections.size());

    for (String compoundKey : sectionByKey.keySet()) {
        ModifyRelatedSectionDTO section = sectionByKey.get(compoundKey);

        System.debug(
            'MODIFY DEBUG - processing section => compoundKey=' + compoundKey +
            ', object=' + section.objectApiName +
            ', lookup=' + section.lookupField
        );

        List<DMT_Line_Modify_Field_Config__mdt> sectionConfigs =
            new List<DMT_Line_Modify_Field_Config__mdt>();

        for (DMT_Line_Modify_Field_Config__mdt cfg : configs) {
            String cfgSectionKey =
                String.isNotBlank(cfg.Section_Key__c)
                    ? cfg.Section_Key__c
                    : cfg.Object_Api_Name__c;

            String cfgCompoundKey =
                cfg.Object_Api_Name__c + '|' + cfg.Lookup_Field__c + '|' + cfgSectionKey;

            if (
                cfgCompoundKey == compoundKey &&
                cfg.Line_Template__c == line.DMT_Line_Template_Type__c &&
                cfg.Booking_Geography__c == line.Booking_Geography__c
            ) {
                sectionConfigs.add(cfg);
            }
        }

        System.debug('MODIFY DEBUG - sectionConfigs size => ' + sectionConfigs.size());

        List<SObject> relatedRecords =
            relatedRecordsByObject.get(section.objectApiName);

        if (relatedRecords == null) {
            System.debug('MODIFY DEBUG - relatedRecords NULL for object => ' + section.objectApiName);
            continue;
        }

        System.debug(
            'MODIFY DEBUG - relatedRecords size for ' + section.objectApiName +
            ' => ' + relatedRecords.size()
        );

        Schema.SObjectType objType =
            globalDescribe.get(section.objectApiName);

        Map<String, Schema.SObjectField> fieldsMap =
            objType.getDescribe().fields.getMap();

        for (SObject related : relatedRecords) {
            Id parentId = (Id) related.get(section.lookupField);

            System.debug(
                'MODIFY DEBUG - checking related => object=' + section.objectApiName +
                ', relatedId=' + related.get('Id') +
                ', parentId=' + parentId +
                ', currentLineId=' + line.Id +
                ', lookupField=' + section.lookupField
            );

            if (parentId != line.Id) {
                System.debug('MODIFY DEBUG - SKIP by parent mismatch => ' + related.get('Id'));
                continue;
            }

            Boolean isTreasuryRiskTerm =
                line.DMT_Line_Template_Type__c == 'TL' &&
                section.objectApiName == 'DMT_Risk_Line_Term__c';

            System.debug(
                'MODIFY DEBUG - isTreasuryRiskTerm => ' + isTreasuryRiskTerm +
                ', relatedId=' + related.get('Id')
            );

            if (isTreasuryRiskTerm) {
                Object riskTypeValue = related.get('DMT_Risk_Type__c');
                Object amountValue = related.get('DMT_Amount__c');

                System.debug(
                    'MODIFY DEBUG - TL candidate => relatedId=' + related.get('Id') +
                    ', riskType=' + riskTypeValue +
                    ', amount=' + amountValue +
                    ', init=' + related.get('DMT_Init_Term__c') +
                    ', end=' + related.get('DMT_End_Term__c')
                );

                if (
                    amountValue == null ||
                    String.isBlank(String.valueOf(amountValue)) ||
                    String.valueOf(amountValue) == 'null'
                ) {
                    System.debug('MODIFY DEBUG - SKIP TL by empty amount => ' + related.get('Id'));
                    continue;
                }

                if (
                    riskTypeValue == null ||
                    String.valueOf(riskTypeValue) != 'Derivatives'
                ) {
                    System.debug('MODIFY DEBUG - SKIP TL by risk type => ' + related.get('Id'));
                    continue;
                }

                System.debug('MODIFY DEBUG - TL accepted => ' + related.get('Id'));
            }

            ModifyRelatedRecordDTO recordDto = new ModifyRelatedRecordDTO();
            recordDto.id = (Id) related.get('Id');

            Integer recordCounter = section.records.size() + 1;

            if (section.objectApiName == 'DMT_Risk_Line_Term__c') {
                Object riskTypeValue = related.get('DMT_Risk_Type__c');

                if (
                    riskTypeValue != null &&
                    String.isNotBlank(String.valueOf(riskTypeValue)) &&
                    String.valueOf(riskTypeValue) != 'null'
                ) {
                    recordDto.displayName = String.valueOf(riskTypeValue);
                } else {
                    recordDto.displayName = 'Risk Line Term ' + recordCounter;
                }
            } else {
                String nameFieldApi = resolveFieldApiName(fieldsMap, 'Name');
                Object nameValue = String.isNotBlank(nameFieldApi)
                    ? related.get(nameFieldApi)
                    : null;

                if (
                    nameValue != null &&
                    String.isNotBlank(String.valueOf(nameValue)) &&
                    String.valueOf(nameValue) != 'null'
                ) {
                    recordDto.displayName = String.valueOf(nameValue);
                } else {
                    recordDto.displayName = section.label + ' ' + recordCounter;
                }
            }

            if (isTreasuryRiskTerm) {
                addRiskTermCellIfAvailable(
                    recordDto,
                    related,
                    fieldsMap,
                    'DMT_Init_Term__c',
                    'INIT TERM',
                    false
                );

                addRiskTermCellIfAvailable(
                    recordDto,
                    related,
                    fieldsMap,
                    'DMT_End_Term__c',
                    'END TERM',
                    false
                );

                addRiskTermCellIfAvailable(
                    recordDto,
                    related,
                    fieldsMap,
                    'DMT_Amount__c',
                    'AMOUNT',
                    false
                );

                System.debug(
                    'MODIFY DEBUG - TL record cells final => relatedId=' + related.get('Id') +
                    ', cells=' + JSON.serialize(recordDto.cells)
                );
            } else {
                for (DMT_Line_Modify_Field_Config__mdt cfg : sectionConfigs) {
                    Schema.DescribeFieldResult d =
                        fieldsMap.get(cfg.Field_Api_Name__c).getDescribe();

                    if (!d.isUpdateable()) {
                        System.debug(
                            'MODIFY DEBUG - SKIP non updateable related field => ' +
                            section.objectApiName + '.' + cfg.Field_Api_Name__c
                        );
                        continue;
                    }

                    Object value = related.get(cfg.Field_Api_Name__c);

                    recordDto.values.put(cfg.Field_Api_Name__c, value);
                    recordDto.cells.add(
                        buildCell(
                            String.valueOf(recordDto.id) + '-' + cfg.Field_Api_Name__c,
                            cfg.Field_Api_Name__c,
                            cfg.Field_Label__c,
                            d,
                            value,
                            cfg.Required__c,
                            cfg.Input_Type__c,
                            cfg.Picklist_Options_JSON__c
                        )
                    );
                }
            }

            section.records.add(recordDto);

            System.debug(
                'MODIFY DEBUG - record added => section=' + section.key +
                ', relatedId=' + recordDto.id +
                ', recordsSize=' + section.records.size()
            );
        }
    }

    System.debug('MODIFY DEBUG - buildRelatedSectionsForLine END sections => ' + JSON.serialize(sections));

    return sections;
}

public static void addRiskTermCellIfAvailable(
    ModifyRelatedRecordDTO recordDto,
    SObject related,
    Map<String, Schema.SObjectField> fieldsMap,
    String fieldApiName,
    String label,
    Boolean required
) {
    System.debug(
        'MODIFY DEBUG - addRiskTermCellIfAvailable START field=' + fieldApiName +
        ', relatedId=' + related.get('Id') +
        ', exists=' + fieldsMap.containsKey(fieldApiName)
    );

    if (!fieldsMap.containsKey(fieldApiName)) {
        System.debug('MODIFY DEBUG - field does not exist => ' + fieldApiName);
        return;
    }

    Schema.DescribeFieldResult d =
        fieldsMap.get(fieldApiName).getDescribe();

    System.debug(
        'MODIFY DEBUG - field describe => field=' + fieldApiName +
        ', updateable=' + d.isUpdateable() +
        ', type=' + d.getType() +
        ', rawValue=' + related.get(fieldApiName)
    );

    if (!d.isUpdateable()) {
        System.debug('MODIFY DEBUG - SKIP field not updateable => ' + fieldApiName);
        return;
    }

    Object value = related.get(fieldApiName);

    String inputTypeOverride;
    String picklistOptionsJson;

    if (
        fieldApiName == 'DMT_Init_Term__c' ||
        fieldApiName == 'DMT_End_Term__c'
    ) {
        inputTypeOverride = 'picklist';
        value = value == null ? '' : String.valueOf(value);

        picklistOptionsJson =
            '[' +
            '{"label":"Select...","value":""},' +
            '{"label":"0D","value":"0"},' +
            '{"label":"2D","value":"2"},' +
            '{"label":"3D","value":"3"},' +
            '{"label":"4D","value":"4"},' +
            '{"label":"7D","value":"7"},' +
            '{"label":"10D","value":"10"},' +
            '{"label":"15D","value":"15"},' +
            '{"label":"20D","value":"20"},' +
            '{"label":"1M","value":"30"},' +
            '{"label":"45D","value":"45"},' +
            '{"label":"2M","value":"60"},' +
            '{"label":"3M","value":"90"},' +
            '{"label":"4M","value":"120"},' +
            '{"label":"5M","value":"150"},' +
            '{"label":"6M","value":"180"},' +
            '{"label":"9M","value":"270"},' +
            '{"label":"1Y","value":"365"},' +
            '{"label":"18M","value":"548"},' +
            '{"label":"2Y","value":"730"},' +
            '{"label":"3Y","value":"1095"},' +
            '{"label":"4Y","value":"1460"},' +
            '{"label":"5Y","value":"1825"},' +
            '{"label":"6Y","value":"2190"},' +
            '{"label":"7Y","value":"2555"},' +
            '{"label":"8Y","value":"2920"},' +
            '{"label":"9Y","value":"3285"},' +
            '{"label":"10Y","value":"3650"},' +
            '{"label":"11Y","value":"4015"},' +
            '{"label":"12Y","value":"4380"},' +
            '{"label":"13Y","value":"4745"},' +
            '{"label":"14Y","value":"5110"},' +
            '{"label":"15Y","value":"5475"},' +
            '{"label":"16Y","value":"5840"},' +
            '{"label":"17Y","value":"6205"},' +
            '{"label":"18Y","value":"6570"},' +
            '{"label":"19Y","value":"6935"},' +
            '{"label":"20Y","value":"7300"},' +
            '{"label":"21Y","value":"7665"},' +
            '{"label":"22Y","value":"8030"},' +
            '{"label":"25Y","value":"9125"},' +
            '{"label":"27Y","value":"9855"},' +
            '{"label":"30Y","value":"10950"},' +
            '{"label":"32Y","value":"11680"},' +
            '{"label":"35Y","value":"12775"},' +
            '{"label":"37Y","value":"13505"},' +
            '{"label":"40Y","value":"14600"},' +
            '{"label":"42Y","value":"15330"},' +
            '{"label":"45Y","value":"16425"}' +
            ']';
    }

    System.debug(
        'MODIFY DEBUG - adding cell => field=' + fieldApiName +
        ', value=' + value +
        ', inputTypeOverride=' + inputTypeOverride
    );

    recordDto.values.put(fieldApiName, value);
    recordDto.cells.add(
        buildCell(
            String.valueOf(recordDto.id) + '-' + fieldApiName,
            fieldApiName,
            label,
            d,
            value,
            required,
            inputTypeOverride,
            picklistOptionsJson
        )
    );

    System.debug(
        'MODIFY DEBUG - addRiskTermCellIfAvailable END field=' + fieldApiName +
        ', cellsSize=' + recordDto.cells.size()
    );
}

    public static ModifyCellDTO buildCell(
        String key,
        String fieldApiName,
        String configuredLabel,
        Schema.DescribeFieldResult d,
        Object value,
        Boolean required,
        String inputTypeOverride,
        String picklistOptionsJson
    ) {
        ModifyCellDTO cell = new ModifyCellDTO();

        String resolvedInputType = String.isNotBlank(inputTypeOverride)
            ? inputTypeOverride
            : resolveInputType(d);

        cell.key = key;
        cell.fieldApiName = fieldApiName;
        cell.label = String.isNotBlank(configuredLabel)
            ? configuredLabel
            : d.getLabel();
        cell.inputType = resolvedInputType;
        cell.value = value;
        cell.checked = value instanceof Boolean ? (Boolean) value : false;
        cell.required = required == true;
        cell.isPicklist = resolvedInputType == 'picklist';

        if (cell.isPicklist) {
            cell.options = parsePicklistOptions(picklistOptionsJson);

            if (cell.options.isEmpty()) {
                cell.options = getPicklistOptionsFromDescribe(d);
            }
        }

        return cell;
    }

    public static String resolveFieldApiName(
        Map<String, Schema.SObjectField> fieldsMap,
        String requestedField
    ) {
        if (fieldsMap.containsKey(requestedField)) {
            return requestedField;
        }

        String requestedLower = requestedField.toLowerCase();

        for (String fieldName : fieldsMap.keySet()) {
            if (fieldName != null && fieldName.toLowerCase() == requestedLower) {
                return fieldName;
            }
        }

        return null;
    }

    public static List<ModifyPicklistOptionDTO> parsePicklistOptions(String jsonText) {
        List<ModifyPicklistOptionDTO> options = new List<ModifyPicklistOptionDTO>();

        if (String.isBlank(jsonText)) {
            return options;
        }

        try {
            List<Object> rawOptions =
                (List<Object>) JSON.deserializeUntyped(jsonText);

            for (Object rawOption : rawOptions) {
                Map<String, Object> optionMap =
                    (Map<String, Object>) rawOption;

                ModifyPicklistOptionDTO optionDto = new ModifyPicklistOptionDTO();
                optionDto.label = String.valueOf(optionMap.get('label'));
                optionDto.value = String.valueOf(optionMap.get('value'));

                if (
                    String.isNotBlank(optionDto.label) &&
                    String.isNotBlank(optionDto.value)
                ) {
                    options.add(optionDto);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Invalid Picklist_Options_JSON__c format. Expected JSON array with label/value.'
            );
        }

        return options;
    }

    public static List<ModifyPicklistOptionDTO> getPicklistOptionsFromDescribe(
        Schema.DescribeFieldResult d
    ) {
        List<ModifyPicklistOptionDTO> options = new List<ModifyPicklistOptionDTO>();

        if (d.getType() != Schema.DisplayType.Picklist) {
            return options;
        }

        for (Schema.PicklistEntry entry : d.getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }

            ModifyPicklistOptionDTO optionDto = new ModifyPicklistOptionDTO();
            optionDto.label = entry.getLabel();
            optionDto.value = entry.getValue();

            options.add(optionDto);
        }

        return options;
    }

    public static Object castValueForField(
        Object rawValue,
        Schema.DescribeFieldResult d
    ) {
        if (rawValue == null) {
            return null;
        }

        String stringValue = String.valueOf(rawValue);

        if (String.isBlank(stringValue)) {
            return null;
        }

        Schema.DisplayType fieldType = d.getType();

        if (fieldType == Schema.DisplayType.Date) {
            return Date.valueOf(stringValue);
        }

        if (fieldType == Schema.DisplayType.DateTime) {
            return Datetime.valueOf(stringValue.replace('T', ' '));
        }

        if (
            fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Percent
        ) {
            return Decimal.valueOf(stringValue);
        }

        if (fieldType == Schema.DisplayType.Integer) {
            return Integer.valueOf(stringValue);
        }

        if (fieldType == Schema.DisplayType.Boolean) {
            if (rawValue instanceof Boolean) {
                return rawValue;
            }

            return stringValue == 'true' || stringValue == '1';
        }

        return rawValue;
    }

    public static Map<String, Map<Id, SObject>> loadExistingRelatedRecordsForSave(
        List<ModifySaveRowDTO> rows,
        List<DMT_Line_Modify_Field_Config__mdt> configs,
        Set<Id> lineIds,
        Map<String, Schema.SObjectType> globalDescribe
    ) {
        Map<String, Map<Id, SObject>> result =
            new Map<String, Map<Id, SObject>>();

        Map<String, Set<Id>> idsByObject = new Map<String, Set<Id>>();

        for (ModifySaveRowDTO row : rows) {
            if (row.relatedSections == null) {
                continue;
            }

            for (ModifySaveRelatedSectionDTO section : row.relatedSections) {
                if (
                    section == null ||
                    String.isBlank(section.objectApiName) ||
                    section.records == null
                ) {
                    continue;
                }

                if (!idsByObject.containsKey(section.objectApiName)) {
                    idsByObject.put(section.objectApiName, new Set<Id>());
                }

                for (ModifySaveRelatedRecordDTO record : section.records) {
                    if (record != null && record.id != null) {
                        idsByObject.get(section.objectApiName).add(record.id);
                    }
                }
            }
        }

        for (String objectApiName : idsByObject.keySet()) {
            Set<Id> recordIds = idsByObject.get(objectApiName);

            if (recordIds.isEmpty()) {
                continue;
            }

            if (!globalDescribe.containsKey(objectApiName)) {
                throw new AuraHandledException('Invalid related object: ' + objectApiName);
            }

            String lookupField = resolveLookupFieldFromConfig(objectApiName, configs);
            validateSafeIdentifier(lookupField, 'lookup field');

            if (String.isBlank(lookupField)) {
                throw new AuraHandledException(
                    'Lookup field not configured for object: ' + objectApiName
                );
            }

            Schema.SObjectType objType = globalDescribe.get(objectApiName);
            Map<String, Schema.SObjectField> fieldsMap =
                objType.getDescribe().fields.getMap();

            if (!fieldsMap.containsKey(lookupField)) {
                throw new AuraHandledException(
                    'Invalid lookup field ' + lookupField +
                    ' for object ' + objectApiName
                );
            }

            String query =
                'SELECT Id, ' + lookupField +
                ' FROM ' + objectApiName +
                ' WHERE Id IN :recordIds';

            List<SObject> records = Database.query(query);

            Map<Id, SObject> recordById = new Map<Id, SObject>();

            for (SObject record : records) {
                Id parentId = (Id) record.get(lookupField);

                if (!lineIds.contains(parentId)) {
                    throw new AuraHandledException(
                        'Related record does not belong to selected lines: ' +
                        String.valueOf(record.get('Id'))
                    );
                }

                recordById.put((Id) record.get('Id'), record);
            }

            result.put(objectApiName, recordById);
        }

        return result;
    }

    public static Schema.SObjectType getValidatedSObjectType(String objectApiName) {
        validateSafeIdentifier(objectApiName, 'object api name');

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);

        if (objType == null) {
            throw new AuraHandledException('Object not found: ' + objectApiName);
        }

        return objType;
    }

    public static void validateFieldForObject(
        String fieldApiName,
        Map<String, Schema.SObjectField> fieldsMap,
        String objectApiName
    ) {
        validateSafeIdentifier(fieldApiName, 'field api name');

        if (!fieldsMap.containsKey(fieldApiName)) {
            throw new AuraHandledException(
                'Invalid field ' + fieldApiName + ' for object ' + objectApiName
            );
        }
    }

    public static String resolveLookupFieldFromConfig(
        String objectApiName,
        List<DMT_Line_Modify_Field_Config__mdt> configs
    ) {
        for (DMT_Line_Modify_Field_Config__mdt cfg : configs) {
            if (
                cfg.Object_Api_Name__c == objectApiName &&
                String.isNotBlank(cfg.Lookup_Field__c)
            ) {
                return cfg.Lookup_Field__c;
            }
        }

        return null;
    }

    public static void validateSafeIdentifier(String value, String identifierType) {
        if (String.isBlank(value) || !SAFE_IDENTIFIER_PATTERN.matcher(value).matches()) {
            throw new AuraHandledException(
                'Invalid ' + identifierType + ': ' + value
            );
        }
    }
}