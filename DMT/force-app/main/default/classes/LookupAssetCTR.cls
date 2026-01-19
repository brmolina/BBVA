/*
* LookupAssetCTR
*/
@SuppressWarnings('sf:SOQLInjection, sf:CyclomaticComplexity')
public with sharing class LookupAssetCTR {

    private LookupAssetCTR() {}

    /*
    * fetchRecords
    */
    @AuraEnabled
    public static List<RecordsData> fetchRecords(String objectName, String filterField, String custom, String searchString, String value) { //NOSONAR
        //Si al componente le meto el value = 'Yes' se precarga un valor
        try {
            List<RecordsData> recordsDataList;
            recordsDataList = new List<RecordsData>();
            if(String.isNotBlank(value)) {  //CAMBIADO IF
                String query;
                query = 'SELECT Id, '+ String.escapeSingleQuotes(filterField)+ ' FROM '+String.escapeSingleQuotes(objectName)+ ' WHERE Id = \''+ String.escapeSingleQuotes(value)+ '\' LIMIT 49999';
                system.debug('query------------------->'+query);
                for(SObject s : Database.query(query)) {
                    recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('id')) );
                }
            } else {
                List<String> profileName;
                profileName = new List<String>{'BBVA Desktop GM Standard','BBVA Desktop GM Click To Dial'};
                List<String> roleName;
                roleName = new List<String>{'GLOBAL MARKETS ECOMMERCE SALES','GLOBAL MARKETS E-COMMERCE', ' '};
                System.debug(profileName+''+roleName);
                System.debug('filterfield---------------->'+filterField);
                String second;
                second = 'secondary';
                String primer;
                primer = 'primary';
                String estand;
                estand = 'estandar';
                System.debug(primer);
                System.debug(estand);
                if(custom == second) {
                    List<User> lstUsu;
                    lstUsu = [SELECT Id, UserRole.Id, Name, Profile.Name, UserRole.Name FROM User WHERE Profile.Name =: profileName AND UserRole.Name !=: roleName AND UserRoleId != null]; //NOSONAR
                    system.debug('lstUsu------------>'+lstUsu);
                    Set<Id> lstId;
                    lstId = new Set<Id>();
                    for (User usu : lstUsu) {
                        if(usu.UserRole.Id != null) {
                            lstId.add(usu.UserRole.Id);
                        }
                    }
                    system.debug('lstId------------>'+lstId);

                    String query;
                    query = 'SELECT Id, ' + String.escapeSingleQuotes(filterField)+ ' FROM  '+ String.escapeSingleQuotes(objectName)+' WHERE Id =:  lstId AND ' + String.escapeSingleQuotes(filterField)+' LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim())+'%\'LIMIT 49999';
                    system.debug('query------------>'+query);
                    for(SObject s : Database.query(query)) {
                        system.debug('bucle------------>'+s);
                        recordsDataList.add( new RecordsData((String)s.get('Name'), (String)s.get('id')) );
                    }
                } else if (custom == primer) {
                    String query;
                    query = 'SELECT Id, UserRole.Id, Profile.Name, UserRole.Name, ' + String.escapeSingleQuotes(filterField) + '  FROM ' + String.escapeSingleQuotes(objectName) +' WHERE Profile.Name =: profileName AND UserRole.Name !=: roleName AND UserRoleId != null AND ' + String.escapeSingleQuotes(filterField)+
                                ' LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
                    for(SObject s : Database.query(query)) {
                        recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('id')) );
                    }
                } else if (custom == estand) {
                    String query = 'SELECT Id, ' + String.escapeSingleQuotes(filterField)+ '  FROM  '+ String.escapeSingleQuotes(objectName);
                    if(String.isNotBlank(value)) {
                        query += ' WHERE Id = \''+ '\'' + String.escapeSingleQuotes(value)+ '\''  + '\' LIMIT 49999';
                    } else {
                        query += ' WHERE ' + String.escapeSingleQuotes(filterField)+
                                ' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
                    }
                    for(SObject s : Database.query(query)) {
                        recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('id')) );
                    }
                }
            }
            return recordsDataList;
	    } catch (Exception err) {
	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(Label.DES_Error + err);
            } else {
                throw new AuraHandledException(Label.DES_Error + err);
            }
	    }
    }

    /*
    * metdoRole
    */
    @AuraEnabled
    public static List<RecordsData> metodoRole(String recordId) {
        System.debug('recordId--------------------->'+recordId);
        List<RecordsData> recordsDataList;
        recordsDataList = new List<RecordsData>();
        UserRole rol = new UserRole();
        System.debug(rol);
        String userS;
        userS = 'User';
        System.debug(userS);
        if(recordId != null && recordId != '') {
            String objeto;
            objeto = findObjectNameFromRecordIdPrefix(recordId);
            if(objeto == userS) {
                User usuario;
                usuario = [SELECT Id, UserRoleId  FROM User WHERE Id =: recordId];
                System.debug('UserRoleId--------------------->'+usuario.UserRoleId);
                rol = [Select Id, Name FROM UserRole WHERE Id =: usuario.UserRoleId];
            } else {
                rol = [Select Id, Name FROM UserRole WHERE Id =: recordId];
            }
            recordsDataList.add( new RecordsData(rol.Name, rol.Id));
        }
        return recordsDataList;
    }

    /*
    * Returns the object of the ID
    */
    private static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix) {
        String objectName = '';
        try {
            String myIdPrefix;
            myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            Map<String, Schema.SObjectType> gdd;
            gdd =  Schema.getGlobalDescribe();
            for(Schema.SObjectType stype : gdd.values()) {
                Schema.DescribeSObjectResult rsult;
                rsult = stype.getDescribe();
                String prefix;
                prefix = rsult.getKeyPrefix();
                if(prefix!=null && prefix.equals(myIdPrefix)) {
                    objectName = rsult.getName();
                    break;
                }
            }
        } catch(Exception e) {
            System.debug(e);
        }
        return objectName;
    }

    /*
    *RecordsData
    */
    public class RecordsData {
        @AuraEnabled public String label;//NOSONAR
        @AuraEnabled public String value;//NOSONAR
        /*
        *RecordsData
        */
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}