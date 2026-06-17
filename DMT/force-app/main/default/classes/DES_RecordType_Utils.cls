public class DES_RecordType_Utils {
    
    private static Map<String, Id> rtIdCache = new Map<String, Id>();
    
    // VERSIÓN QUE ACEPTA STRING (nombre del objeto)
    public static Id getRecordTypeId(String objectName, String developerName) {
        if (String.isBlank(objectName) || String.isBlank(developerName)) {
            return null;
        }
        
        String cacheKey = objectName + '|' + developerName;
        if (rtIdCache.containsKey(cacheKey)) {
            return rtIdCache.get(cacheKey);
        }
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
        if (targetType == null) {
            return null;
        }
        
        DescribeSObjectResult describe = targetType.getDescribe();
        Map<String, RecordTypeInfo> rtInfos = describe.getRecordTypeInfosByDeveloperName();
        
        Id rtId = (rtInfos != null && rtInfos.containsKey(developerName)) 
            ? rtInfos.get(developerName).getRecordTypeId() 
            : null;
        
        rtIdCache.put(cacheKey, rtId);
        return rtId;
    }
    
    // FILTER con String
    public static List<SObject> filter(List<SObject> records, String objectName, String developerName) {
        List<SObject> filtered = new List<SObject>();
        if (records == null || records.isEmpty()) return filtered;
        
        Id targetRtId = getRecordTypeId(objectName, developerName);
        if (targetRtId == null) return filtered;
        
        for (SObject record : records) {
            if ((Id) record.get('RecordTypeId') == targetRtId) {
                filtered.add(record);
            }
        }
        return filtered;
    }
    
}