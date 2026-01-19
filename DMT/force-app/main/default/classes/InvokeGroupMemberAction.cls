public without sharing class InvokeGroupMemberAction {
    @InvocableMethod(callout=true label='Create Group Members')    
    public static List<String> createGroupMembers(List<List<GroupMember>> groupMembers) {
        List<String> result = new List<String>{'OK'};
        try {System.debug(groupMembers[0]+'primero');System.debug(groupMembers+'todos');
            insert groupMembers[0];
            return result;
        } catch (Exception e){
            result[0] = e.getMessage();
            return result; 
        }
      
    } 
}