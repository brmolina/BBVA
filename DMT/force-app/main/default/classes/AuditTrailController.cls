public with sharing class AuditTrailController {

    @AuraEnabled
    public static List<SetupAuditTrail> getAuditLogs(Integer limitSize, String lastId, String lastDate) {
        Integer queryLimit = (limitSize == null) ? 200 : limitSize;

        String query = 'SELECT Id, Action, Section, Display, CreatedBy.Name, CreatedDate FROM SetupAuditTrail';
        List<String> conditions = new List<String>();

        // Keyset Pagination: Find records older than the last one currently displayed
        if (String.isNotBlank(lastId) && String.isNotBlank(lastDate)) {
            // Deserializing the ISO string from JS into a proper Salesforce DateTime
            DateTime dt = (DateTime)JSON.deserialize('"' + lastDate + '"', DateTime.class);
            conditions.add('(CreatedDate < :dt OR (CreatedDate = :dt AND Id < :lastId))');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY CreatedDate DESC, Id DESC LIMIT :queryLimit';

        return Database.query(query);
    }
}