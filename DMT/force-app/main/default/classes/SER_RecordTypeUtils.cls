/*@Description Class to manage record types ids and names for easier coding
  @Author Juan Carlos Terrón
*/
public with sharing class SER_RecordTypeUtils {
  /*Map to store all objects Record Types in the org*/
  public static Map<String,Map<String,String> > mapAllRT {get; set;}
  /*Private constructor to avoid singleton warning*/
  private SER_RecordTypeUtils() {

  }
  /*statick block to initialize all record types map*/
  static {
    if(mapAllRT == null) {
      mapAllRT = new Map<String,Map<String,String> >();
    }
    if(mapAllRT.isEmpty()) {
      loadAllRecordTypes();
    }
  }
  /*Method to retrieve and load in the static map all record types form the org*/
  public static void loadAllRecordTypes() {
    for(RecordType rtype :
        [
          SELECT Id,DeveloperName,SObjectType
          FROM RecordType
          WHERE IsActive = true
        ]) {
      if(mapAllRT.containsKey(rtype.SObjectType)) {
        mapAllRT.get(rtype.SObjectType).put(rtype.DeveloperName,rtype.Id);
        mapAllRT.get(rtype.SObjectType).put(rtype.Id,rtype.DeveloperName);
      } else {
        mapAllRT.put(rtype.SObjectType, new Map<String,String>());
        mapAllRT.get(rtype.SObjectType).put(rtype.DeveloperName,rtype.Id);
        mapAllRT.get(rtype.SObjectType).put(rtype.Id,rtype.DeveloperName);
      }
    }
  }
  /*Method to retrieve the record types id and name from the specified object*/
  public static Map<String,String> getRecordTypes(String objectType) {
    return mapAllRT.get(objectType);
  }
  /*Method to get the id of a record type with the object and recordtype name provided*/
  public static String getRecordTypeByName(String objectType,String name) {
    String rtId;
    if(mapAllRT.containsKey(objectType) && mapAllRT.get(objectType).containsKey(name)) {
      rtId = mapAllRT.get(objectType).get(name);
    } else {
      rtId = '';
    }
    return rtId;
  }
}