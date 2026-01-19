public class EmailQueueable implements Queueable, Database.AllowsCallouts {
    private String templateId;
    private List<String> userIds;
    private Boolean isLastBatch;
    private Boolean isSuccess;
    private String batchId; // Identificador del lote

    public EmailQueueable(String templateId, List<String> userIds, Boolean isLastBatch, String batchId) {
        this.templateId = templateId;
        this.userIds = userIds;
        this.isLastBatch = isLastBatch;
        this.batchId = batchId;
    }

    public void execute(QueueableContext context) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SendEmailResult> sendResults= new List<Messaging.SendEmailResult>();
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'globaldesktop@bbva.com' LIMIT 1];

        for (String uId : userIds) {
            Messaging.SingleEmailMessage mailToSend = new Messaging.SingleEmailMessage();
            if (owea != null) {
                mailToSend.setOrgWideEmailAddressId(owea.Id);
            }
            mailToSend.setTemplateId(templateId);
            mailToSend.setTargetObjectId(uId);
            mailToSend.setSaveAsActivity(false);
            mails.add(mailToSend);
        }
        sendResults = Messaging.sendEmail(mails);
        String errorDetails;
        for (Messaging.SendEmailResult sR : sendResults) {
            if (!sR.isSuccess()) {
                for (Messaging.SendEmailError error : sR.getErrors()) {
                    errorDetails += 'Error al enviar a usuario: ' + error.getStatusCode() + ' - ' + error.getMessage() + '\n';
                }
            }

        }
         // Encolar el siguiente lote solo si no es el último
         if (isLastBatch) {
            System.debug('errors: '+errorDetails);
            if (errorDetails != null) {
                iaso__GBL_Application_Log__c appLog = new iaso__GBL_Application_Log__c();
                appLog.iaso__Transaction_Id__c = batchId;
                appLog.iaso__Message_LTA__c = errorDetails;
                insert appLog;
                System.debug(appLog);
            }else {
                System.debug('Todos los correos se han enviado correctamente.');
            }   
        }
    }
}