public with sharing class DMT_AttachmentController {
    @AuraEnabled(cacheable=true)
    public static List<AttachmentWrapper> getAttachments(Id parentId) {
        List<AttachmentWrapper> results = new List<AttachmentWrapper>();

        for (Attachment att : [
            SELECT Id, Name, ContentType, BodyLength, CreatedDate, CreatedBy.Name
            FROM Attachment
            WHERE ParentId = :parentId
            ORDER BY CreatedDate DESC
        ]) {
            results.add(new AttachmentWrapper(att));
        }
        return results;
    }

    @AuraEnabled
    public static void uploadAttachment(Id parentId, String fileName, String base64Data) {
        if (String.isBlank(parentId) || String.isBlank(fileName) || String.isBlank(base64Data)) {
            throw new AuraHandledException('Incomplete data to upload the file.');
        }

        Attachment attach = new Attachment();
        attach.ParentId = parentId;
        attach.Name = fileName;
        attach.Body = EncodingUtil.base64Decode(base64Data);
        insert attach;
    }

    @AuraEnabled
    public static void deleteAttachment(Id attachmentId) {
        if (attachmentId != null) {
            delete [SELECT Id FROM Attachment WHERE Id = :attachmentId LIMIT 1];
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasEditAccess(Id recordId) {
        Boolean hasAccessOwner = false;
        Boolean hasAccessMember = false;
        Boolean hasPermissionRole = false;
        Boolean userPermissionRole = false;
        Boolean hasGodLineAccess = false;

        Id userId = UserInfo.getUserId();

        if(DMT_Passport_Helper.objectNameById(recordId) == DMT_Line__c.getSObjectType().getDescribe().getName())
        {
            // Comprobar si es el propietario de la línea
            DMT_Line__c line = [SELECT Id, OwnerId FROM DMT_Line__c WHERE Id = :recordId LIMIT 1];
            if (line.OwnerId == userId) {
                hasAccessOwner = true;
            }
        
            // Verificar si el usuario es miembro del equipo con acceso 'Edit'
            List<DMT_TeamMember__c> members = [
                SELECT Id FROM DMT_TeamMember__c
                WHERE Line__c = :recordId AND User__c = :userId AND AccessLevel__c = 'Edit'
                LIMIT 1
            ];
            
            userPermissionRole = DMT_Utils.hasWriteAccess();
            hasGodLineAccess = DMT_Utils.checkLineGodUser();
           
            hasAccessMember = userPermissionRole;

            if(!hasGodLineAccess){
                if(userPermissionRole){
                    hasAccessMember = !members.isEmpty() || hasAccessOwner;
                }
            }else{
                hasAccessMember = true;
            }
        }
        else if (DMT_Passport_Helper.objectNameById(recordId) == Case.getSObjectType().getDescribe().getName())
        {
            Case caseRecord = [SELECT Id, OwnerId FROM Case WHERE Id = :recordId LIMIT 1];
            hasGodLineAccess = DMT_Utils.checkLineGodUser();
            List<Group> listGr = [SELECT Id, Name, DeveloperName  FROM Group WHERE Id = :caseRecord.OwnerId AND Type = 'Queue' LIMIT 1];
            List<DMT_Approver_Member__c> members = new List<DMT_Approver_Member__c>();
            if(!listGr.isEmpty()){
                members = [SELECT Id FROM DMT_Approver_Member__c
                WHERE DMT_Approver__r.DMT_Group__c = :listGr.get(0).DeveloperName AND DMT_User__c = :userId AND DMT_Access_Level__c = 'Edit'
                LIMIT 1
                ];
            }
            
            User usr = [SELECT  id, Name,  DMT_User_Role__c  FROM User WHERE Id = :userId LIMIT 1];

            if(hasGodLineAccess){
                hasAccessMember = true;
            }
            else if(usr.DMT_User_Role__c != null && usr.DMT_User_Role__c != ''){
                hasAccessMember = !members.isEmpty() && hasEditCaseRole(usr.DMT_User_Role__c);
            }else{
                hasAccessMember = !members.isEmpty() || hasAccessOwner;
            }
            
        }else if(DMT_Passport_Helper.objectNameById(recordId) == Opportunity.getSObjectType().getDescribe().getName()){
            Opportunity oppRecord = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :recordId LIMIT 1];
            if (oppRecord.OwnerId == userId) {
                hasAccessOwner = true;
            }
            List<Group> listGr = [SELECT Id, Name  FROM Group WHERE Id = :oppRecord.OwnerId AND Type = 'Queue' LIMIT 1];
            List<DMT_TeamMember__c> members = new List<DMT_TeamMember__c>();
            if(!listGr.isEmpty()){
                members = [
                SELECT Id FROM DMT_TeamMember__c
                WHERE Opportunity__c = :recordId AND User__c = :userId AND AccessLevel__c = 'Edit'
                LIMIT 1
            ];
            }
            

            User usr = [SELECT  id, Name,  DMT_User_Role__c  FROM User WHERE Id = :userId LIMIT 1];

            if(usr.DMT_User_Role__c != null && usr.DMT_User_Role__c != ''){
                hasAccessMember = !members.isEmpty() || hasAccessOwner;
            }else{
                hasAccessMember = !members.isEmpty() || hasAccessOwner;
            }
        }
        return hasAccessMember;
    }

    //method created to check if the role of the user is not in the readOnly 
    public static Boolean hasEditCaseRole(String role){
        //This are the roles that have permission to edit caseTask
        List<String> validRoles = new List<String>();

        for (DES_User_Roles__mdt  rolVal : [SELECT DES_Role_Developer_Name__c  FROM DES_User_Roles__mdt where DES_Access_Level__c = 'Read/Write' ]){
            validRoles.add(rolVal.DES_Role_Developer_Name__c);
        }

        List<String> userRoles = role.split(';');

        for(String roleUser : userRoles) {

            if(validRoles.contains(roleUser)){
                return true;
            }

        }
        return false;
    }
    @AuraEnabled
    public static String getAttachmentBase64(String attachmentId) {
        try {
            
            Attachment att = [SELECT Body FROM Attachment WHERE Id = :attachmentId LIMIT 1];
            return EncodingUtil.base64Encode(att.Body);
        } catch (Exception e) {
            throw new AuraHandledException('No se pudo obtener el archivo: ' + e.getMessage());
        }
    }
    
    

    public class AttachmentWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String contentType;
        @AuraEnabled public Integer sizeKb;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String createdBy;

        public AttachmentWrapper(Attachment att) {
            id = att.Id;
            name = att.Name;
            contentType = att.ContentType;
            sizeKb = (Integer)Math.ceil(att.BodyLength / 1024.0);
            createdDate = att.CreatedDate;
            createdBy = att.CreatedBy.Name;
        }
    }
}