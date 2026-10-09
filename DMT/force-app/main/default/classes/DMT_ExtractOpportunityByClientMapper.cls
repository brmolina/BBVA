/**
* @description Apex replacement for Omni DataMapper ExtractOpportunityByClient.
*/
public without sharing class DMT_ExtractOpportunityByClientMapper implements Callable {
    private static final String ACTION_EXTRACT = 'extractOpportunityByClient';

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');

        if (output == null) {
            output = new Map<String, Object>();
        }

        if (action == ACTION_EXTRACT) {
            output.putAll(extract(input));
            return output;
        }

        throw new AuraHandledException('Unsupported action: ' + action);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> extract(Map<String, Object> input) {
        Map<String, Object> safeInput = (input == null) ? new Map<String, Object>() : input;

        Id originId = (Id) safeInput.get('originId');
        String clientId = (String) safeInput.get('ClientId');
        String groupCode = (String) safeInput.get('groupCode');
        String filteredLine = (String) safeInput.get('filteredLine');
        String statusLine = (String) safeInput.get('statusLine');

        Set<Id> accountIds = resolveAccountIds(originId, clientId, groupCode);

        List<DMT_Line__c> lines = fetchLines(accountIds, filteredLine, statusLine);
        List<Opportunity> opportunities = fetchOpportunities(accountIds);

        Set<Id> readableLineIds = resolveReadableIds(lines, true);
        Set<Id> readableOpportunityIds = resolveReadableIds(opportunities, false);

        List<Object> lineRows = new List<Object>();
        for (DMT_Line__c line : lines) {
            lineRows.add(toLineMap(line, readableLineIds.contains(line.Id)));
        }

        List<Object> oppRows = new List<Object>();
        for (Opportunity opp : opportunities) {
            oppRows.add(toOppMap(opp, readableOpportunityIds.contains(opp.Id)));
        }

        Map<String, Object> result = new Map<String, Object>{
            'line' => lineRows,
            'lineFil' => lineRows,
            'opp' => oppRows,
            'countType' => new Map<String, Object>{
                'line' => lineRows.size(),
                'opportunity' => oppRows.size()
            },
            'colLine' => buildLineColumns(),
            'colOpp' => buildOppColumns(),
            'localClient' => resolveLocalClientCode(accountIds),
            'filteredLine' => filteredLine,
            'statusLine' => statusLine
        };

        if (!String.isBlank(groupCode)) {
            result.put('groupCode', groupCode);
        }

        return result;
    }

    private static Set<Id> resolveAccountIds(Id originId, String clientId, String groupCode) {
        Set<Id> accountIds = new Set<Id>();

        if (originId != null && originId.getSObjectType() == Account.SObjectType) {
            accountIds.add(originId);
        }

        Id parsedClientId = tryParseId(clientId);
        if (parsedClientId != null && parsedClientId.getSObjectType() == Account.SObjectType) {
            accountIds.add(parsedClientId);
        }

        List<String> conditions = new List<String>();
        if (!String.isBlank(clientId)) {
            conditions.add('g_customer_id__c = :clientId');
        }
        if (!String.isBlank(groupCode)) {
            conditions.add('DES_Group_Code__c = :groupCode');
        }

        if (!conditions.isEmpty()) {
            String query =
                'SELECT Id FROM Account WHERE ' +
                String.join(conditions, ' OR ') +
                '  LIMIT 500';
            for (Account acc : Database.query(query,AccessLevel.SYSTEM_MODE)) {
                accountIds.add(acc.Id);
            }
        }

        return accountIds;
    }

    private static List<DMT_Line__c> fetchLines(Set<Id> accountIds, String filteredLine, String statusLine) {
        if (accountIds.isEmpty()) {
            return new List<DMT_Line__c>();
        }

        List<String> conditions = new List<String>();
        conditions.add('Client__c IN :accountIds');
        conditions.add('Product__c != \'Sanction\'');
        if (!String.isBlank(filteredLine)) {
            conditions.add('Product__c = :filteredLine');
        }
        if (!String.isBlank(statusLine)) {
            conditions.add('Status__c = :statusLine');
        }

        String query =
            'SELECT Id, Name, OwnerId, Client__c, Product__c, Status__c, Booking_Geography__c, ' +
            'Start_Date__c, End_Date__c, DvP_Amount__c, DvP_Currency__c, ' +
            'FD_Amount__c, FD_Currency__c, Client_Type__c, Line_Details__c, Line_Id__c, Closed__c ' +
            'FROM DMT_Line__c WHERE ' + String.join(conditions, ' AND ') +
            '  ORDER BY LastModifiedDate DESC LIMIT 1000';

        return Database.query(query, AccessLevel.SYSTEM_MODE);
    }

    private static List<Opportunity> fetchOpportunities(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new List<Opportunity>();
        }

        return [
            SELECT Id, Name, OwnerId, StageName, AccountId, RecordType.Name, CurrencyIsoCode,
                   DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c,
                   Entific__c, DMT_Client_Type__c, DMT_CUR_Notional_Amount__c
            FROM Opportunity
            WHERE AccountId IN :accountIds AND RecordType.developerName = 'DMT_Opportunity'
            WITH SYSTEM_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 500
        ];
    }

    private static Set<Id> resolveReadableIds(List<SObject> records, Boolean isLine) {
        Set<Id> recordIds = new Set<Id>();
        Set<Id> readableIds = new Set<Id>();
        Set<Id> teamMemberIds = new Set<Id>();
        Id currentUserId = UserInfo.getUserId();

        for (SObject record : records) {
            Id recordId = (Id) record.get('Id');
            recordIds.add(recordId);
            if ((Id) record.get('OwnerId') == currentUserId) {
                readableIds.add(recordId);
            }
        }

        if (recordIds.isEmpty()) {
            return readableIds;
        }

        if (isLine) {
            for (DMT_TeamMember__c member : [
                SELECT Line__c
                FROM DMT_TeamMember__c
                WHERE User__c = :currentUserId AND Line__c IN :recordIds
                WITH SYSTEM_MODE
            ]) {
                teamMemberIds.add(member.Line__c);
            }
        } else {
            for (DMT_TeamMember__c member : [
                SELECT Opportunity__c
                FROM DMT_TeamMember__c
                WHERE User__c = :currentUserId AND Opportunity__c IN :recordIds
                WITH SYSTEM_MODE
            ]) {
                teamMemberIds.add(member.Opportunity__c);
            }
        }
        readableIds.addAll(teamMemberIds);

        List<Id> recordIdList = new List<Id>(recordIds);
        for (Integer offset = 0; offset < recordIdList.size(); offset += 200) {
            Set<Id> chunk = new Set<Id>();
            Integer endIndex = Math.min(offset + 200, recordIdList.size());
            for (Integer index = offset; index < endIndex; index++) {
                chunk.add(recordIdList[index]);
            }

            for (UserRecordAccess access : [
                SELECT RecordId, HasReadAccess
                FROM UserRecordAccess
                WHERE UserId = :currentUserId AND RecordId IN :chunk
            ]) {
                if (access.HasReadAccess) {
                    readableIds.add(access.RecordId);
                }
            }
        }

        return readableIds;
    }

    @TestVisible
    private static Map<String, Object> toLineMap(DMT_Line__c line) {
        return toLineMap(line, false);
    }

    private static Map<String, Object> toLineMap(DMT_Line__c line, Boolean hasAccessLine) {
        return new Map<String, Object>{
            'Id' => line.Id,
            'Name' => line.Name,
            'NameURLLine' => '/' + line.Id,
            'hasAccessLine' => hasAccessLine,
            'Client__c' => line.Client__c,
            'Product__c' => line.Product__c,
            'Status__c' => line.Status__c,
            'Booking_Geography__c' => line.Booking_Geography__c,
            'Start_Date__c' => line.Start_Date__c,
            'End_Date__c' => line.End_Date__c,
            'DvP_Amount__c' => line.DvP_Amount__c,
            'DvP_Currency__c' => line.DvP_Currency__c,
            'FD_Amount__c' => line.FD_Amount__c,
            'FD_Currency__c' => line.FD_Currency__c,
            'Client_Type__c' => line.Client_Type__c,
            'Line_Details__c' => line.Line_Details__c,
            'Line_Id__c' => line.Line_Id__c,
            'Closed__c' => line.Closed__c,
            'statusIcon' => lineStatusIcon(line),
            'statusIconColor' => lineStatusIconColor(line),
            'statusIconVariant' => '',
            'statusTooltip' => lineStatusTooltip(line)
        };
    }

    /**
     * @description Ported from the (inactive) OmniStudio DataMapper ExtractOpportunityByClient_1
     * formula on DMT_Line__c:statusIcon. Drives the icon shown in the Status column.
     */
    private static String lineStatusIcon(DMT_Line__c line) {
        if (line.Status__c == 'Closed') {
            if (String.isBlank(line.Closed__c)) {
                return '';
            }
            if (line.Closed__c == 'Won') {
                return (Date.today() < line.Start_Date__c) ? 'utility:clock' : 'utility:success';
            }
            return 'utility:clear';
        }
        if (line.Status__c == 'Ready to close') {
            return 'utility:clock';
        }
        return 'utility:edit_form';
    }

    /**
     * @description Ported from the OmniStudio DataMapper formula on DMT_Line__c:statusIconColor.
     */
    private static String lineStatusIconColor(DMT_Line__c line) {
        if (line.Status__c == 'Closed') {
            if (String.isBlank(line.Closed__c)) {
                return '';
            }
            if (line.Closed__c == 'Won') {
                if (Date.today() < line.Start_Date__c) {
                    return '#4E86C6';
                }
                return (Date.today() > line.End_Date__c) ? '' : '#1F7A4D';
            }
            return '#B93A3A';
        }
        if (line.Status__c == 'Ready to close') {
            return '#D9A441';
        }
        return '';
    }

    /**
     * @description Ported from the OmniStudio DataMapper formula on DMT_Line__c:statusTooltip.
     */
    private static String lineStatusTooltip(DMT_Line__c line) {
        if (line.Status__c == 'Closed') {
            if (String.isBlank(line.Closed__c)) {
                return '';
            }
            if (line.Closed__c == 'Won') {
                if (Date.today() < line.Start_Date__c) {
                    return 'Scheduled: the period has not started yet.';
                }
                return (Date.today() > line.End_Date__c)
                    ? 'Historical: it was successfully closed, but it is no longer active.'
                    : 'Successfully closed and currently active.';
            }
            return 'Closed unsuccessfully.';
        }
        if (line.Status__c == 'Ready to close') {
            return 'Ready to Close: only the last step remains to finalize the closure.';
        }
        return 'In progress: it is still open for editing, review, or approval.';
    }

    private static Map<String, Object> toOppMap(Opportunity opp, Boolean hasAccessOpp) {
        return new Map<String, Object>{
            'Id' => opp.Id,
            'Name' => opp.Name,
            'NameURL' => '/' + opp.Id,
            'hasAccessOpp' => hasAccessOpp,
            'StageName' => opp.StageName,
            'DMT_DATE_Initial_Date__c' => opp.DMT_DATE_Initial_Date__c,
            'DMT_DATE_Maturity_Date__c' => opp.DMT_DATE_Maturity_Date__c,
            'Entific__c' => opp.Entific__c,
            'DMT_Client_Type__c' => opp.DMT_Client_Type__c,
            'RecordType' => new Map<String, Object>{ 'Name' => opp.RecordType?.Name },
            'RecordType.Name' => opp.RecordType?.Name,
            'Opportunity_Details__c' => opp.DMT_CUR_Notional_Amount__c,
            'AccountId' => opp.AccountId,
            'statusIcon' => oppStatusIcon(opp),
            'statusIconColor' => oppStatusIconColor(opp),
            'statusIconVariant' => '',
            'statusTextColor' => oppStatusTextColor(opp),
            'statusTooltip' => oppStatusTooltip(opp)
        };
    }

    /**
     * @description Ported from the OmniStudio DataMapper formula on Opportunity:statusIcon.
     */
    private static String oppStatusIcon(Opportunity opp) {
        if (opp.StageName == 'Closed Won') {
            return (Date.today() < opp.DMT_DATE_Initial_Date__c) ? 'utility:clock' : 'utility:success';
        }
        if (opp.StageName == 'Closed Lost') {
            return 'utility:clear';
        }
        if (opp.StageName == 'Ready to close') {
            return 'utility:clock';
        }
        return 'utility:edit_form';
    }

    /**
     * @description Ported from the OmniStudio DataMapper formula on Opportunity:statusIconColor.
     */
    private static String oppStatusIconColor(Opportunity opp) {
        if (opp.StageName == 'Closed Won') {
            if (Date.today() < opp.DMT_DATE_Initial_Date__c) {
                return '#4E86C6';
            }
            return (Date.today() > opp.DMT_DATE_Maturity_Date__c) ? '' : '#1F7A4D';
        }
        if (opp.StageName == 'Closed Lost') {
            return '#B93A3A';
        }
        if (opp.StageName == 'Ready to close') {
            return '#D9A441';
        }
        return '';
    }

    /**
     * @description Ported from the OmniStudio DataMapper formula on Opportunity:statusTextColor.
     */
    private static String oppStatusTextColor(Opportunity opp) {
        if (opp.StageName == 'Closed Won') {
            return '#22a562';
        }
        if (opp.StageName == 'Closed Lost') {
            return '#a30b0b';
        }
        if (opp.StageName == 'Ready to close') {
            return '#8F5E0A';
        }
        return '';
    }

    /**
     * @description Ported from the OmniStudio DataMapper formula on Opportunity:statusTooltip.
     */
    private static String oppStatusTooltip(Opportunity opp) {
        if (opp.StageName == 'Closed Won') {
            if (Date.today() < opp.DMT_DATE_Initial_Date__c) {
                return 'Scheduled: the period has not started yet.';
            }
            return (Date.today() > opp.DMT_DATE_Maturity_Date__c)
                ? 'Historical: it was successfully closed, but it is no longer active.'
                : 'Successfully closed and currently active.';
        }
        if (opp.StageName == 'Closed Lost') {
            return 'Closed unsuccessfully.';
        }
        if (opp.StageName == 'Ready to close') {
            return 'Ready to Close: only the last step remains to finalize the closure.';
        }
        return 'In progress: it is still open for editing, review, or approval.';
    }

    private static String resolveLocalClientCode(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return '';
        }

        List<Local_Client__c> localClients = [
            SELECT Alpha_code__c
            FROM Local_Client__c
            WHERE Cib_Client__c IN :accountIds
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        return localClients.isEmpty() ? '' : localClients[0].Alpha_code__c;
    }

    private static Id tryParseId(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        try {
            return (Id) value;
        } catch (Exception ex) {
            return null;
        }
    }

    private static List<Object> buildLineColumns() {
        return new List<Object>{
            new Map<String, Object>{
                'fieldName' => 'NameURLLine',
                'label' => 'Name',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'Name' },
                    'target' => '_blank'
                }
            },
            new Map<String, Object>{ 'fieldName' => 'Product__c', 'label' => 'Product' },
            new Map<String, Object>{ 'fieldName' => 'Status__c', 'label' => 'Status' },
            new Map<String, Object>{ 'fieldName' => 'Booking_Geography__c', 'label' => 'Booking Geography' },
            new Map<String, Object>{ 'fieldName' => 'Start_Date__c', 'label' => 'Start Date' },
            new Map<String, Object>{ 'fieldName' => 'End_Date__c', 'label' => 'End Date' }
        };
    }

    private static List<Object> buildOppColumns() {
        return new List<Object>{
            new Map<String, Object>{
                'fieldName' => 'NameURL',
                'label' => 'Name',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'Name' },
                    'target' => '_blank'
                }
            },
            new Map<String, Object>{ 'fieldName' => 'StageName', 'label' => 'Stage' },
            new Map<String, Object>{ 'fieldName' => 'DMT_RUP_Initial_Date__c', 'label' => 'Initial Date' },
            new Map<String, Object>{ 'fieldName' => 'DMT_RUP_Maturity_Date__c', 'label' => 'Maturity Date' }
        };
    }
}