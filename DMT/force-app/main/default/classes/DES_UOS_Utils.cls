public with sharing class DES_UOS_Utils {

    @AuraEnabled
    public static List<DES_UOS_Utils.WRAPPER_UOSUSER> getUsersByUos( String searchedUosId ){
        List<User> usersFiltered = new List<User>();
        List<DES_UOS_Utils.WRAPPER_UOSUSER> usersWrappedFiltered= new List<DES_UOS_Utils.WRAPPER_UOSUSER>();

        Map<Id,User> userMapById = new Map<Id,User>(
        [SELECT Id, Name, lastName, userName,Profile.Name, DES_LevelUO_1__c, DES_LevelUO_2__c, DES_LevelUO_3__c, DES_LevelUO_4__c, DES_LevelUO_5__c, DES_LevelUO_6__c,
         DES_LevelUO_7__c, DES_LevelUO_8__c, DES_LevelUO_9__c, DES_LevelUO_10__c 
         FROM User 
         WHERE (DES_LevelUO_1__c= : searchedUosId OR DES_LevelUO_2__c= : searchedUosId OR  
         DES_LevelUO_3__c= : searchedUosId OR  DES_LevelUO_4__c= : searchedUosId OR  
         DES_LevelUO_5__c= : searchedUosId OR  DES_LevelUO_6__c= : searchedUosId OR  
         DES_LevelUO_7__c= : searchedUosId OR  DES_LevelUO_8__c= : searchedUosId OR  
         DES_LevelUO_9__c= : searchedUosId OR  DES_LevelUO_10__c =: searchedUosId) AND isActive=true ]);

         System.debug(' Mapa usuarios encontrados '+userMapById);
         for( User u : userMapById.values() ){
            List<String> orderedValues = new List<String>{u.DES_LevelUO_1__c,u.DES_LevelUO_2__c,
                u.DES_LevelUO_3__c,u.DES_LevelUO_4__c,u.DES_LevelUO_5__c,u.DES_LevelUO_6__c,u.DES_LevelUO_7__c,
                u.DES_LevelUO_8__c,u.DES_LevelUO_9__c,u.DES_LevelUO_10__c};

            Boolean valueFoud = false;    
            Boolean repeatsContinue = true;
            Boolean nonRepeatedButInLastPosition = false;

            for(Integer i=0; i<orderedValues.size(); i++){
                System.debug(' mi valor en la iteracion '+orderedValues[i]);
                System.debug(' Y busco '+searchedUosId);
                if( orderedValues[i] == searchedUosId ){
                    valueFoud=true;
                    //Si encuentro valor itero en otro bucle para ver que se repite, en el momento que deja de repetirse paro
                    for(Integer j=i; j<orderedValues.size(); j++){
                        if(orderedValues[j] != searchedUosId){
                            repeatsContinue=false;
                            break;
                        }
                    }
                   
                }

                if(valueFoud && !repeatsContinue &&  i == (orderedValues.size()-1) && orderedValues[i] == searchedUosId ){
                    nonRepeatedButInLastPosition=true;
                }

            }

            if((valueFoud && repeatsContinue) || nonRepeatedButInLastPosition){
                usersFiltered.add(u);
            }
        }    

        System.debug('usersFiltered a devolver  '+usersFiltered);
        for(User ietmUser : usersFiltered){
            WRAPPER_UOSUSER wrapperNewRecord = new WRAPPER_UOSUSER();
               wrapperNewRecord.Name = ietmUser.Name;
               wrapperNewRecord.LastName = ietmUser.LastName;
               wrapperNewRecord.userName = ietmUser.Username;
               wrapperNewRecord.Profile = ietmUser.Profile.Name;
               wrapperNewRecord.Id= ietmUser.Id;
            
            usersWrappedFiltered.add(wrapperNewRecord);
        }
        
        return usersWrappedFiltered;
    }

    public List<User> getUsersByUosAndUOLevel( String searchedUosId, Integer level ){
        List<User> userListReturn = new List<User>();
        Set<Id> setUsersIds = new Set<Id>();
        Map<Integer, String> mapLevelsUOsByInteger = new Map<Integer, String>{
            1 => 'DES_LevelUO_1__c',
            2 => 'DES_LevelUO_2__c',
            3 => 'DES_LevelUO_3__c',
            4 => 'DES_LevelUO_4__c',
            5 => 'DES_LevelUO_5__c',
            6 => 'DES_LevelUO_6__c',
            7 => 'DES_LevelUO_7__c',
            8 => 'DES_LevelUO_8__c',
            9 => 'DES_LevelUO_9__c',
            10 => 'DES_LevelUO_10__c'
        };

       List<DES_UOS_Utils.WRAPPER_UOSUSER> usersBySearchedUOs = new List<DES_UOS_Utils.WRAPPER_UOSUSER>();
       usersBySearchedUOs = getUsersByUos(searchedUosId);

       if( usersBySearchedUOs != null && !usersBySearchedUOs.isEmpty() ){
        for(WRAPPER_UOSUSER u: usersBySearchedUOs){
            setUsersIds.add(u.Id);
        }

        // Validar que los niveles existen en el mapa
        if (!mapLevelsUOsByInteger.containsKey(level - 1) || !mapLevelsUOsByInteger.containsKey(level)) {
            throw new IllegalArgumentException('Invalid level parameter');
        }

        String fieldPrevLevel = mapLevelsUOsByInteger.get(level - 1);
        String fieldCurrentLevel = mapLevelsUOsByInteger.get(level);

            //If we find users, get only the user in level searched
            String query ='SELECT Id, Name, DES_LevelUO_1__c, DES_LevelUO_2__c, DES_LevelUO_3__c, DES_LevelUO_4__c, DES_LevelUO_5__c, DES_LevelUO_6__c, '+
            'DES_LevelUO_7__c, DES_LevelUO_8__c, DES_LevelUO_9__c, DES_LevelUO_10__c '+
            'FROM User '+
            'WHERE '+String.escapeSingleQuotes(fieldPrevLevel)+' != \''+ String.escapeSingleQuotes(searchedUosId)+'\' AND '+
            String.escapeSingleQuotes(fieldCurrentLevel)+' = \''+ String.escapeSingleQuotes(searchedUosId)+
            +'\' AND Id IN (\''+String.join(setUsersIds, '\''+','+'\'')+'\')';
            
            System.debug(' *** My query '+String.escapeSingleQuotes(query).replaceAll('\\\\', ''));
            userListReturn=Database.query(String.escapeSingleQuotes(query).replaceAll('\\\\', ''));           
       }

       return userListReturn;
    }

    /**
    * @description identify the user uos for each user from the param user list.Returns in map user Id - uos code
    * @author BBVA DMT | 28-01-2025 
    * @param userList 
    * @return Map<Id, String> 
    **/
    public Map<Id,String> indentifyUserUos( List<User> userList ){
        Map<Id,String> mapUosByIdUser = new Map<Id,String>();

         for( User u : userList){
            if( u.DES_LevelUO_1__c != null && u.DES_LevelUO_2__c != null &&
                u.DES_LevelUO_3__c != null && u.DES_LevelUO_4__c != null &&
                u.DES_LevelUO_5__c != null && u.DES_LevelUO_6__c != null &&
                u.DES_LevelUO_7__c != null && u.DES_LevelUO_8__c != null &&
                u.DES_LevelUO_9__c != null && u.DES_LevelUO_10__c != null){

                    List<String> orderedValues = new List<String>{u.DES_LevelUO_1__c,u.DES_LevelUO_2__c,
                        u.DES_LevelUO_3__c,u.DES_LevelUO_4__c,u.DES_LevelUO_5__c,u.DES_LevelUO_6__c,u.DES_LevelUO_7__c,
                        u.DES_LevelUO_8__c,u.DES_LevelUO_9__c,u.DES_LevelUO_10__c};
          
                    String foundUOS = null;
                    Boolean nonRepeatedButInLastPosition = false;
                    String valueToCheck;

                    for(Integer i=0; i<orderedValues.size(); i++){
                        Boolean isValid = true;
                        valueToCheck=orderedValues[i];

                        for(Integer j=i; j<orderedValues.size(); j++){
                            if( valueToCheck != orderedValues[j]){
                                isValid=false;
                                break;
                            }
                        
                        }

                        if(isValid){
                            System.debug('EL uos de este usuario '+u.UserName +' es '+valueToCheck);
                            foundUOS=valueToCheck;
                            break;
                        }
        
                    }
        
                    if ( String.isNotBlank(foundUOS) ) {
                        mapUosByIdUser.put((Id) u.get('Id'), foundUOS);
                    }

            }
            
        }    
        
        return mapUosByIdUser;
    }

    public class WRAPPER_UOSUSER {
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String LastName;
        @AuraEnabled
        public String userName;
        @AuraEnabled
        public Id Id;
        @AuraEnabled
        public String Profile;
    }
}