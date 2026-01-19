global with sharing class DES_SamlJitHandler_copy implements Auth.SamlJitHandler{
    
    public DES_SamlJitHandler_copy(){}
    
    private class JitException extends Exception{}
    private UserUuaaInfoExtended.Data data = new UserUuaaInfoExtended.Data();
    private UserUuaaInfoExtended.wrapper wrapper = new UserUuaaInfoExtended.wrapper();
    
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
    String federationIdentifier, Map<String, String> attributes, String assertion) {
        
        User user = getUserInfo(federationIdentifier,new User());
        
        Boolean cantinsert = false;
        try {
            insert user;
            
        } catch (Exception e) {
            cantinsert = true;
            logError(e, federationIdentifier,user);  
        }
        
        if(!cantinsert){setPermissionSet(user);}
        
        return user;
    }
    
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
    String federationIdentifier, Map<String, String> attributes, String assertion) {
        
        User user = [SELECT Id FROM User WHERE Id=:userId LIMIT 1];
        
        user = getUserInfo(federationIdentifier,user);
        setPermissionSet(user);
        
        try {
            update user; 
        } catch (Exception e) {
            logError(e, federationIdentifier,user);
            
        }
        
    }
    private User getUserInfo(String federationIdentifier, User user){
        
        Map <String, Object> request = new Map <String, Object>();
        wrapper =  UserUuaaInfoExtended.getUserUuaaInfoExtended(request);
        system.debug('Wrapper ' +wrapper);
        
        if (!wrapper.success) {
            user.IsActive = false;
            return user;
        }
        
        Boolean isAdm = false;
        
        UserUuaaInfoExtended.Data dataRole = wrapper.data;
        if (dataRole.roles != null && !dataRole.roles.isEmpty()){
            for(UserUuaaInfoExtended.Role role : dataRole.roles){
                if(role.name == 'sAdmin'){
                    isAdm = true;
                }
            }
        }
        
        //mapeo de la información del servicio al usuario
        String alias='';
        List<String> permisionSets= new  List<String>();
        Map<String, String> attributesMap = new Map<String, String>();
        data = wrapper.data;
        user.FirstName = data.name ;
        user.LastName = data.surname +' '+ data.secondSurname;
        user.DES_Country__c = data.workCountry;
        user.DES_LevelUO_1__c = data.organizationalUnit.parentCode1;
        user.DES_LevelUO_2__c = data.organizationalUnit.parentCode2;
        user.DES_LevelUO_3__c = data.organizationalUnit.parentCode3;
        user.DES_LevelUO_4__c = data.organizationalUnit.parentCode4;
        user.DES_LevelUO_5__c = data.organizationalUnit.parentCode5;
        user.DES_LevelUO_6__c = data.organizationalUnit.parentCode6;
        user.DES_LevelUO_7__c = data.organizationalUnit.parentCode7;
        user.DES_LevelUO_8__c = data.organizationalUnit.parentCode8;
        user.DES_LevelUO_9__c = data.organizationalUnit.parentCode9;
        user.DES_LevelUO_10__c = data.organizationalUnit.parentCode10;
        if(user.id==null){
            String random = '';
            List<User> liUser = [SELECT Alias from User WHERE Alias like:alias+'%'];
            
            if(liUser.size()>0){
                alias= alias + string.valueof(liUser.size());
            }
            
            user.Alias = alias;
            user.TimeZoneSidKey = 'Europe/Paris';
            user.LocaleSidKey = 'es_ES';
            user.EmailEncodingKey ='ISO-8859-1';
            user.LanguageLocaleKey = 'en_US';
        }
        
        
        
        Boolean hasAttributes = false;
        
        if (data.attributeSet != null) {
            for (UserUuaaInfoExtended.Attribute attribute : data.attributeSet) {
                if (attribute.attributes == null) {
                    hasAttributes = true;
                    break;
                }
            }
        } 
        
        if (hasAttributes) {
            attributesMap=getAttributes(data);
        } else {
            attributesMap.clear();
        }
        
        //Obtenemos Perfil
        Profile prof = new Profile();
        String perfil = attributesMap.get('Perfil_SF');
        if (perfil == null || perfil == '') {
            prof = isAdm ? [SELECT Id FROM Profile WHERE Name ='System Administrator' LIMIT 1] :[SELECT Id FROM Profile WHERE Name ='Standard User' LIMIT 1];
        } else{
            prof = [SELECT Id FROM Profile WHERE Name =: perfil LIMIT 1];
        }
        user.ProfileId = prof.Id;

        //Obtenemos Rol
        String rol = attributesMap.get('Role_SF');
        if(!Test.isRunningTest()){
            if (rol != null && rol != '') {
                user.UserRoleId = [SELECT Id FROM UserRole WHERE Name =: rol LIMIT 1].Id;
            }
        } else {
            user.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Global_Management1' LIMIT 1].Id;
        }
        
        
        //Devolver nombre campos
        List<Profiling_Configuration__mdt> lmeta = Profiling_Configuration__mdt.getAll().values();
        
        for(Profiling_Configuration__mdt key : lmeta){
            
            String attr = attributesMap.get(key.DES_Key__c);
            
            switch  on (key.DES_Data_Type__c) {
                when 'String' {
                    if (String.isBlank(attr) && attr == 'Role_SF'){ continue;}
                    user.put(key.DES_value__c,attr);
                }
                when 'Boolean' {
                    Boolean booleanValue = false;
                    if (!String.isBlank(attr)){
                        booleanValue = Boolean.valueOf(attr);
                    }
                    user.put(key.DES_value__c, booleanValue);
                    
                }
                
                when 'Number' {
                    Integer intValue = Integer.valueOf(attr);
                    user.put(key.DES_value__c, intValue);
                }
                when 'Double' {
                    Double doubleValue = Double.valueOf(attr);
                    user.put(key.DES_value__c, doubleValue);
                }
                
            }
        }
        
        if(attributesMap.get('LicenciaSalesforce') == null){
            user.IsActive = false;
        }
        return user;
        
    }
    private List<string> getPermissionSet(UserUuaaInfoExtended.Data info){
        List<string> lpermissionset = new List<string>();
        
        for(UserUuaaInfoExtended.Role item:info.roles){
            for(UserUuaaInfoExtended.Resource ps: item.resources){
                lpermissionset.add(ps.value);
            }
        }
        return lpermissionset;
    }
    
    private Map<string, string> getAttributes(UserUuaaInfoExtended.Data info){
        Map<string, string> attributesmap = new Map<string, string>();
        
        for(UserUuaaInfoExtended.Attribute item: info.attributeSet){
            for(UserUuaaInfoExtended.Attributes at: item.attributes){
                attributesmap.put(at.attributeName, at.attributeValue);
                
            }
            
        }
        return attributesmap;   
    }
    
    
    
    private void setPermissionSet(User user){
        
        // Borrar Permission Sets
        /*
        if(user.id!=null){
            List<PermissionSetAssignment> lpsdelete = [SELECT Id  FROM PermissionSetAssignment WHERE AssigneeId = :user.id and PermissionSet.ProfileId=''];
            system.debug(lpsdelete);
            delete lpsdelete;
        }*/
        Boolean hasResources = false;
        
        if (data.roles != null) {
            for (UserUuaaInfoExtended.Role roleItem : data.roles) {
                if (roleItem.resources != null) {
                    hasResources = true;
                    break;
                }
            }
        }
        if (hasResources) {
            //Buscar Permission Sets
            
            List<PermissionSet> lps = [SELECT Id  FROM PermissionSet WHERE Name in : getPermissionSet(data)];
            //Solución tactica quitar cuando activemos el borrado Permission Set - restablecerlo en el futuro
            List<PermissionSetAssignment> lpsaB=[SELECT Id,PermissionSetId  FROM PermissionSetAssignment WHERE PermissionSetId in :lps and AssigneeId = :user.id];
            Set<Id> sps= new Set<Id>();
            for(PermissionSetAssignment item: lpsaB){
                sps.add(item.PermissionSetId);
            }
            
            // Asignar Permission Sets
            List<PermissionSetAssignment> lpsa = new List<PermissionSetAssignment>();
            for (PermissionSet ps : lps) {
                if(!sps.contains(ps.Id)){
                    PermissionSetAssignment psa = new PermissionSetAssignment();
                    psa.AssigneeId = user.Id;
                    psa.PermissionSetId = ps.Id;
                    lpsa.add(psa);
            }
            
        }
        } 
        
        
    }   
    
    private void logError(Exception e, String federationIdentifier,User user) {
        String nameLog = 'getUserUuaaInfoExtended ' + federationIdentifier;
        String type = 'Integration';
        User usererror = [SELECT Id FROM User WHERE Name = 'Globals'];
        String errorMessage = 'Error al crear usuario: ' + e.getMessage() + '\n' + wrapper;
        
        iaso__GBL_Application_Log__c log = new iaso__GBL_Application_Log__c();
        log.iaso__Message_LTA__c = errorMessage;
        log.Name = nameLog;
        log.iaso__Type__c = type;
        log.iaso__User__c = usererror.Id;
        log.iaso__Transaction_Id__c = e.getStackTraceString();
        log.iaso__Start_Time__c = System.now();
        log.iaso__End_Time__c = System.now(); 
        database.insert(log);
    }
}