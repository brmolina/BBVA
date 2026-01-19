public without sharing class DMT_GroupMemberQueueableHelper implements Queueable{
    private List<GroupMember> groupMembers;
    private String operation; 
    private static final String TXT_INSERT = 'INSERT';
    private static final String TXT_DELETE = 'DELETE';

    public DMT_GroupMemberQueueableHelper(List<GroupMember> groupMembers,String operation) {
        this.groupMembers = groupMembers;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        try {
            if (operation == TXT_INSERT) {
                // Inserta los registros GroupMember
                insert groupMembers;
                System.debug('GroupMembers created.');
            } else if (operation == TXT_DELETE) {
                // Elimina los registros GroupMember
                delete groupMembers;
                System.debug('GroupMembers deleted.');
            }
        } catch (DmlException e) {
            System.debug('Error ' + operation + ': ' + e.getMessage());
        }
    }
}