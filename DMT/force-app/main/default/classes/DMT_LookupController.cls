public with sharing class DMT_LookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> searchRecords(String objectName, String searchTerm, 
                                              List<Filter> filters, List<String> additionalFields) {
        
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return new List<SObject>();
        }
        
        String query = buildQuery(objectName, searchTerm, filters, additionalFields);
        
        try {
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error searching records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRelatedRecords(Id parentId, String relationshipField, 
                                                  List<String> fields) {
        
        if (String.isBlank(relationshipField)) {
            throw new AuraHandledException('Relationship field is required');
        }
        
        String objectName = parentId.getSobjectType().getDescribe().getName();
        String childObjectName = getChildObjectName(objectName, relationshipField);
        
        if (String.isBlank(childObjectName)) {
            throw new AuraHandledException('Invalid relationship field');
        }
        
        String fieldList = 'Id, Name';
        if (fields != null && !fields.isEmpty()) {
            for (String field : fields) {
                if (field != 'Id' && field != 'Name') {
                    fieldList += ', ' + field;
                }
            }
        }
        
        String query = 'SELECT ' + fieldList + 
                      ' FROM ' + childObjectName + 
                      ' WHERE ' + relationshipField + ' = :parentId' +
                      ' ORDER BY CreatedDate DESC' +
                      ' LIMIT 50';
        
        try {
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error getting related records: ' + e.getMessage());
        }
    }
    
    private static String buildQuery(String objectName, String searchTerm, 
                                     List<Filter> filters, List<String> additionalFields) {
        
        String searchPattern = '%' + searchTerm + '%';
        String fieldList = 'Id, Name';
        
        if (additionalFields != null) {
            for (String field : additionalFields) {
                if (field != 'Id' && field != 'Name') {
                    fieldList += ', ' + field;
                }
            }
        }
        
        String whereClause = 'WHERE Name LIKE :searchPattern';
        
        if (filters != null && !filters.isEmpty()) {
            for (Filter filter : filters) {
                whereClause += ' AND ' + filter.field + ' ' + filter.operator + ' ';
                
                if (filter.operator == 'LIKE') {
                    whereClause += '\'%' + String.escapeSingleQuotes((String)filter.value) + '%\'';
                } else if (filter.value instanceof String) {
                    whereClause += '\'' + String.escapeSingleQuotes((String)filter.value) + '\'';
                } else if (filter.value instanceof Id) {
                    whereClause += '\'' + (Id)filter.value + '\'';
                } else if (filter.value instanceof Boolean) {
                    whereClause += (Boolean)filter.value;
                } else {
                    whereClause += filter.value;
                }
            }
        }
        
        return 'SELECT ' + fieldList + 
               ' FROM ' + objectName + 
               ' ' + whereClause + 
               ' ORDER BY Name' +
               ' LIMIT 50';
    }
    
    private static String getChildObjectName(String parentObject, String relationshipField) {
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(parentObject);
        Schema.DescribeSObjectResult parentDescribe = parentType.getDescribe();
        
        for (Schema.ChildRelationship childRel : parentDescribe.getChildRelationships()) {
            if (childRel.getRelationshipName() == relationshipField) {
                return childRel.getChildSObject().getDescribe().getName();
            }
        }
        
        return null;
    }
    
    public class Filter {
        @AuraEnabled public String field { get; set; }
        @AuraEnabled public String operator { get; set; }
        @AuraEnabled public Object value { get; set; }
    }
}