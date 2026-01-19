public without sharing class InvokeGroupMemberDeletion {
    @InvocableMethod(callout=true label='Create Group Members')    
    public static List<String> deleteGroupMembers(List<List<GroupMember>> groupMembers) {
        List<String> result = new List<String>{'OK'};
        try {System.debug(groupMembers[0]+'primero');System.debug(groupMembers+'todos');
            delete groupMembers[0];
            return result;
        } catch (Exception e){
            result[0] = e.getMessage();
            return result; 
        }
      
    } 
}