public with sharing class UserDeactivationFailed_SendEmail implements Queueable {
    private List<User> failedUsers;
    private String errorMessage;

    public UserDeactivationFailed_SendEmail(List<User> failedUsers, String errorMessage){
        this.failedUsers=failedUsers;
        this.errorMessage=errorMessage;
        
    }

    public void execute(QueueableContext context ){
        // Create a new email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
        // Set the recipient
        mail.setToAddresses(new String[] { 'ans_clientcloud@bbva.com' });

        // Set the subject
        mail.setSubject('User Deactivation Failed');

        // Set the body
        mail.setPlainTextBody('Failed to deactivate next users' + failedUsers + '. Error message: ' + errorMessage);

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}