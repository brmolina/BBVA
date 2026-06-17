public class EmailQueueable implements Queueable, Database.AllowsCallouts {
    private String templateId;
    private List<String> userIds;
    private Boolean isLastBatch;
    private Boolean isSuccess;
    private String batchId; // Identificador del lote
    private String historyId;
    private String oweaId;

    public EmailQueueable(String templateId, List<String> userIds, Boolean isLastBatch, String batchId, String historyId, String oweaId) {
        this.templateId = templateId;
        this.userIds = userIds;
        this.isLastBatch = isLastBatch;
        this.batchId = batchId;
        this.historyId = historyId;
        this.oweaId =oweaId;
    }

    public void execute(QueueableContext context) {
        try{
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SendEmailResult> sendResults= new List<Messaging.SendEmailResult>();
        List<User> users = [SELECT Id, Email FROM User WHERE Id IN :userIds ];
        for (String uId : userIds) {
            Messaging.SingleEmailMessage mailToSend = new Messaging.SingleEmailMessage();
            mailToSend.setTemplateId(templateId);
            mailToSend.setTargetObjectId(uId);
            mailToSend.setSaveAsActivity(false);
            mailToSend.setOrgWideEmailAddressId(oweaId);
            mails.add(mailToSend);
        }
        sendResults = Messaging.sendEmail(mails);
         List<DES_obj_MassEmailUser__c> userRecords = [ SELECT Id, DES_fld_User__c  FROM DES_obj_MassEmailUser__c WHERE DES_fld_Email__c = :historyId AND DES_fld_User__c IN :userIds];
         Map<Id, DES_obj_MassEmailUser__c> recordMap = new Map<Id, DES_obj_MassEmailUser__c>();

        for (DES_obj_MassEmailUser__c rec : userRecords) {
            recordMap.put(rec.DES_fld_User__c, rec);
        }

        Integer successCount = 0;
        Integer errorCount = 0;
        String errorDetails = '';

        for (Integer i = 0; i < sendResults.size(); i++) {

            Messaging.SendEmailResult res = sendResults[i];
            User currentUser = users[i];

            DES_obj_MassEmailUser__c record = recordMap.get(currentUser.Id);

            if (res.isSuccess()) {
                record.DES_fld_Status__c = 'Sent';
                successCount++;

            } else {
                record.DES_fld_Status__c = 'Error';
                String userError = '';
                for (Messaging.SendEmailError error : res.getErrors()) {
                    userError += error.getStatusCode() + ' - ' + error.getMessage() + ' ';
                }
                record.DES_fld_ErrorMessage__c = userError;
                errorDetails += currentUser.Email + ': ' + userError + '\n';
                errorCount++;
            }
        }

        update userRecords;

        if (isLastBatch) {
            DES_obj_MassEmailHistory__c historyUpdate = new DES_obj_MassEmailHistory__c(
                Id = historyId,
                DES_fld_Status__c = errorCount > 0 ? 'Completed with Errors' : 'Completed',
                DES_fld_ErrorLog__c = errorDetails
            );
            update historyUpdate;
        }
    }catch (Exception e) {

            // 🔥 ERROR GLOBAL (Template, OWEA, limit, etc.)
            DES_obj_MassEmailHistory__c historyUpdate =
                new DES_obj_MassEmailHistory__c(
                    Id = historyId,
                    DES_fld_Status__c = 'Failed',
                    DES_fld_ErrorLog__c =
                        e.getMessage() +
                        '\n\n' +
                        e.getStackTraceString()
                );

            update historyUpdate;
        }
    }
}