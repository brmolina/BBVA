public with sharing class DMT_ApproverMemberQueueableHelper  implements Queueable {
    private List<DMT_Approver_Member__c> approverMembers;
    private String operation; 

    public DMT_ApproverMemberQueueableHelper(List<DMT_Approver_Member__c> approverMembers,String operation) {
        this.approverMembers = approverMembers;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        try {
            if (operation == 'INSERT') {
                insert approverMembers;
                System.debug('approverMembers created.');
            } else if (operation == 'DELETE') {
                delete approverMembers;
                System.debug('approverMembers deleted.');
            }
        } catch (DmlException e) {
            System.debug('Error ' + operation + ': ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_ApproverMemberQueueableHelper', 'execute', 'DMT', '');
        }
    }
}