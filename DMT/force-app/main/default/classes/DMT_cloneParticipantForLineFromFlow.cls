public with sharing class DMT_cloneParticipantForLineFromFlow {

    public class WrapperClone {
        @InvocableVariable
        public String  accounId;
        @InvocableVariable
        public String  localClient;
        @InvocableVariable
        public String  oldLineId;
        @InvocableVariable
        public String  newLineId;
        @InvocableVariable
        public Boolean isDeleteOrUpdate;
        @InvocableVariable
        public String accauntGroup;
        @InvocableVariable
        public String localClientGroup;
    }
    @InvocableMethod(label='CloneParticipanFromLine' description='Process to clone participant')
    public static void cloneProcess(List<WrapperClone> inputList){

        try{
            String oldLineId = '';
            String newLineId = '';
            Boolean isDeleteOrUpdate;
            String accauntGroup = '';
            String localClientGroup = '';
            String accounId = '';
            String localClient = '';
            String accauntGroupLine = '';
            String localClientGroupLine = '';

            for(WrapperClone wrapper : inputList){
                oldLineId = wrapper.oldLineId;
                newLineId = wrapper.newLineId;
                isDeleteOrUpdate = wrapper.isDeleteOrUpdate;
                accauntGroup = wrapper.accauntGroup;
                localClientGroup = wrapper.localClientGroup;
                accounId = wrapper.accounId;
                localClient = wrapper.localClient;
            }
            List<DMT_TeamMember__c> teamMemberList = DMT_cloneParticipantForLine_Selector.getTeamMember(oldLineId);
            List<DMT_TeamMember__c> existingMembers = DMT_cloneParticipantForLine_Selector.getTeamMember(newLineId);
            if(!String.isBlank(accounId) && !teamMemberList.isEmpty()){
                    accauntGroupLine = teamMemberList[0].Line__r.Client__r.DES_Group_Code__c != null ? teamMemberList[0].Line__r.Client__r.DES_Group_Code__c : teamMemberList[0].Line__r.Client__r.DES_Subsidiary_Group_Code__c;  
            }
            if(!String.isBlank(localClient) && !teamMemberList.isEmpty()){
                    localClientGroupLine = teamMemberList[0].Line__r.Client__r.DES_Subsidiary_Group_Code__c != null ? teamMemberList[0].Line__r.Client__r.DES_Subsidiary_Group_Code__c : teamMemberList[0].Line__r.Client__r.DES_Group_Code__c;  
            }
            //Si es el mismo Grupo
            if((!String.isBlank(accauntGroup) && accauntGroup != null && accauntGroup == accauntGroupLine) || 
            (!String.isBlank(localClientGroup) && localClientGroup != null && localClientGroup == localClientGroupLine )){
                if (isDeleteOrUpdate) {
                    if(!existingMembers.isEmpty()){ delete existingMembers;}
                    if(!String.isBlank(newLineId) && !teamMemberList.isEmpty()){
                        createTeamMbembers(teamMemberList, newLineId);
                    }                      
                }else{
                    if(!existingMembers.isEmpty()){ delete existingMembers;}                    
                    existingMembers = new List<DMT_TeamMember__c>();
                }
            }// El cliente a clonar tiene el grupo distinto que el Origen
            else {
                hasADifferentGroup( accauntGroup, accounId, localClientGroup, localClient, newLineId, existingMembers);
            }
        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_cloneParticipantForLineFromFlow','cloneProcess','DMT',''));
            System.debug('Error clone Participan cloneProcess: ' + e.getMessage());
            System.debug('Error clone Participan cloneProcess line number: ' + e.getLineNumber());
        }
    }
    public static void hasADifferentGroup( String accauntGroup, String accounId, String localClientGroup, String localClient, String newLineId, List<DMT_TeamMember__c> existingMembers){

        try{
            Set<Id> clientIds = new Set<Id>();               
                    if (!String.isBlank(accauntGroup)) {
                        clientIds.add(accounId);
                    } 
                    else if (!String.isBlank(localClientGroup)) {
                        List<Local_Client__c> mainAccounts = DMT_cloneParticipantForLine_Selector.getLocalClient(localClient);                      
                        if (!mainAccounts.isEmpty()) {
                            if (mainAccounts[0].Cib_Client__c != null) { clientIds.add(mainAccounts[0].Cib_Client__c);}
                            if (mainAccounts[0].Cib_Client__r.DES_Main_Parent__c != null) {clientIds.add(mainAccounts[0].Cib_Client__r.DES_Main_Parent__c);}
                        }
                    }
                    List<DES_BBVA_Management_team__c> managementTeam = new List<DES_BBVA_Management_team__c>();
                    if (!clientIds.isEmpty()) {
                        managementTeam = DMT_cloneParticipantForLine_Selector.getManagementTeam(clientIds);
                    }
                    if (!existingMembers.isEmpty()) { delete existingMembers;}
                    createCoverageTeamToTeamMbembers(managementTeam, newLineId);


        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_cloneParticipantForLineFromFlow','hasADifferentGroup','DMT',''));
            System.debug('Error creating Team Mbember hasADifferentGroup: ' + e.getMessage());
            System.debug('Error creating Team Mbember hasADifferentGroup line number: ' + e.getLineNumber());
        }

    }
    public static void createTeamMbembers(List<DMT_TeamMember__c> teamList, String newLineId ){

        try{
            List<DMT_TeamMember__c> uniqueManagementTeam = new List<DMT_TeamMember__c>();
        
            if(teamList.size() > 0){
                // Si existe Duplicados en el grupo, se eliminan
                Set<Id> uniqueIds = new Set<Id>(); 
                for (DMT_TeamMember__c member : teamList){
                    if(!uniqueIds.contains(member.User__c)){
                        uniqueIds.add(member.User__c);
                        uniqueManagementTeam.add(member);
                    }
                }
            }
            if(!uniqueManagementTeam.isEmpty()){

                List<DMT_TeamMember__c> newTeamMembers = new List<DMT_TeamMember__c>();

                // Crear nuevos TeamMembers relacionados con newLineId
                for(DMT_TeamMember__c member : uniqueManagementTeam) {
                    DMT_TeamMember__c newMember = new DMT_TeamMember__c();
                    newMember.User__c = member.User__c;
                    newMember.Line__c = newLineId; 
                    newMember.AccessLevel__c = member.AccessLevel__c;
                    newMember.DMT_ApprovalEdit__c = member.DMT_ApprovalEdit__c;
                    newMember.Team_Role__c = member.Team_Role__c;
                    newTeamMembers.add(newMember);
                }
                // Insertar todos los nuevos TeamMembers
                if (!newTeamMembers.isEmpty()) {
                    insert newTeamMembers;
                }
            }
        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_cloneParticipantForLineFromFlow','createTeamMbembers','DMT',''));
            System.debug('Error creating Team Mbember createTeamMbembers: ' + e.getMessage());
            System.debug('Error creating Team Mbember createTeamMbembers line number: ' + e.getLineNumber());
        }
    }
    public static void createCoverageTeamToTeamMbembers(List<DES_BBVA_Management_team__c> managementTeam, String newLineId ){

        try{
            List<DES_BBVA_Management_team__c> uniqueManagementTeam = new List<DES_BBVA_Management_team__c>(); 
            if(managementTeam.size() > 0){
                // Si existe Duplicados en el grupo, se eliminan                                                        
                Set<Id> uniqueIds = new Set<Id>();
                for (DES_BBVA_Management_team__c member : managementTeam){
                    if(!uniqueIds.contains(member.DES_User__c)){
                        uniqueIds.add(member.DES_User__c);
                        uniqueManagementTeam.add(member);
                    }
                }
            }

            if(!uniqueManagementTeam.isEmpty()){   
                List<DMT_TeamMember__c> newTeamMembers = new List<DMT_TeamMember__c>();
                for(DES_BBVA_Management_team__c teamMember : uniqueManagementTeam){
                    DMT_TeamMember__c newMember = new DMT_TeamMember__c();
                    newMember.User__c = teamMember.DES_User__c; 
                    newMember.Line__c = newLineId; 
                    newMember.AccessLevel__c = 'Read';
                    newMember.DMT_ApprovalEdit__c = false;
                    newTeamMembers.add(newMember);
                }                 
                if (!newTeamMembers.isEmpty()) {
                    insert newTeamMembers;
                }
            }
        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_cloneParticipantForLineFromFlow','createCoverageTeamToTeamMbembers','DMT',''));
            System.debug('Error creating Team Mbember createCoverageTeamToTeamMbembers: ' + e.getMessage());
            System.debug('Error creating Team Mbember createCoverageTeamToTeamMbembers line number: ' + e.getLineNumber());
        }           
    }
}