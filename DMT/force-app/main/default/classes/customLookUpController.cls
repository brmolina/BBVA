/**
* @author GlobalDesktop
*/
public with sharing class customLookUpController { //NOSONAR
    @AuraEnabled
  public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, String productFamily, Boolean custom, Boolean equals, String searchField, String ipUserFilter) { //NOSONAR
    system.debug('ObjectName-->' + ObjectName);
    final String searchKey = searchKeyWord + '%';

    final List < sObject > returnList = new List < sObject > ();
    String sQuery = '';
    // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
    
      try {
          if (custom) {
              String queryFields = 'id, ';
              queryFields +=  String.escapeSingleQuotes(searchField);
              
              if (equals) {
                  sQuery =  'SELECT '+ queryFields + ' FROM ' +String.escapeSingleQuotes(ObjectName) + ' WHERE ' + String.escapeSingleQuotes(searchField) + ' = :searchKeyWord ORDER BY createdDate DESC LIMIT 5';
              } else {
                    final String ipUserFilterQuery = ipUserFilterEmpty(ipUserFilter);
                    sQuery =  'SELECT '+ queryFields + ' FROM ' +String.escapeSingleQuotes(objectName) + ' WHERE ' + String.escapeSingleQuotes(searchField) + ' LIKE :searchKey ' + ipUserFilterQuery + ' ORDER BY createdDate DESC LIMIT 5';
              }
          } else {
              if(ObjectName == Label.ObjectName_Product2) {
                  sQuery =  'SELECT id, Name FROM ' +String.escapeSingleQuotes(ObjectName) + ' WHERE Name LIKE :searchKey AND Family LIKE :productFamily ORDER BY createdDate DESC LIMIT 5';
              } else if (ObjectName == Label.ObjectName_User) {
                  sQuery =  'SELECT id, Name FROM ' +String.escapeSingleQuotes(ObjectName) + ' WHERE isActive = true AND Name LIKE :searchKey ORDER BY createdDate DESC LIMIT 5';
              } else {
                  sQuery =  'SELECT id, Name FROM ' +String.escapeSingleQuotes(ObjectName) + ' WHERE Name = :searchKey ORDER BY createdDate DESC LIMIT 5';
              }
          }
          
          system.debug('Query -->' + sQuery);
          final List < sObject > lstOfRecords = Database.query(sQuery); //NOSONAR
          system.debug('>>>>> productFamily : ' + productFamily);
          
          returnList.addAll(lstOfRecords);
          return returnList;
      } catch (Exception e) {
          throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage()); //NOSONAR
      }
  }

    private static String ipUserFilterEmpty(String ipUserFilter) { //NOSONAR
        String ipUserFilterAux = ipUserFilter;
        if(ipUserFilterAux == null) {
            ipUserFilterAux = '';
        }
        return ipUserFilterAux;
    }
}