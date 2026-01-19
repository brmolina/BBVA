/**
 * @description       : Class that handles the queries of exception object
 * @author            : Javier Portilla
 * @group             : 
 * @last modified on  : 03-14-2025
 * @last modified by  : Javier Portilla
**/
public with sharing class DMT_Des_ExceptionViewerController {
    
    @AuraEnabled(cacheable=true)
    public static List<DES_Exceptions__b> getRecords(Date timestampFrom, Date timestampTo, Integer limitSize, Datetime lastTimestamp) {
        List<DES_Exceptions__b> records = new List<DES_Exceptions__b>();
        try {

            String query = 'SELECT  Id, Timestamp__c, Project__c, Type__c, Class_Name__c, MethodName__c, Message__c, StackTrace__c, Object__c, LineNumber__c, DML_Fields__c, DML_StatusCode__c FROM DES_Exceptions__b';
            String whereClause = ' WHERE Timestamp__c != null';
            
            if (timestampFrom != null && timestampTo != null) {
                whereClause += ' AND Timestamp__c >= :timestampFrom AND Timestamp__c <= :timestampTo';
            }

            if (lastTimestamp != null) {
                whereClause += ' AND Timestamp__c < :lastTimestamp';
            }
             
            query += whereClause + ' ORDER BY Timestamp__c DESC LIMIT ' + limitSize;
            
            System.debug('Query:'+query);
            records = Database.query(query);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_Des_ExceptionViewerController', 'getRecords', 'DMT', 'DES_Exceptions__b');
            throw new AuraHandledException('Error: ' + e);
        }
        return records;
    }
       
}