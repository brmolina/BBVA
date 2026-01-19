public class DPMX_revisionFormalize {
	
    public void DPMX_revisionFormalize() {
        DateTime today = DateTime.now();
        String consultDate = today.format('yyyy-MM-dd');
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemp = DPMX_Utils.returnEmailTemp('DPMX_FormalizeRevision');
        String htmlBody = emailTemp.HtmlValue;

        try{
            List<DPMX_Dynamic_Pricing__c> dynamicPricingLst = DPMX_Utils.dynamicPricingDateSelector(consultDate);
            if(dynamicPricingLst != null){
                for(DPMX_Dynamic_Pricing__c dynamicPricing : dynamicPricingLst)
                {
                    DPMX_Formalize__c formalize = DPMX_Utils.formalizeDPMXSelector(dynamicPricing.Id);
                    if(formalize != null){
                        htmlBody = htmlBody.replace('{!DPMX.Name}', formalize.Name);
                        htmlBody = htmlBody.replace('{!DPMX.Dynamic_Pricing__r.Name}', dynamicPricing.Name);
                        htmlBody = htmlBody.replace('{!DPMX.Link}', Label.DPMX_Link);
                        htmlBody = htmlBody.replace('{!DPMX.autId}', dynamicPricing.Id);
    
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTemp.Id);
                        mail.setTargetObjectId(dynamicPricing.CreatedById);
                        //mail.setCcAddresses(sendCC);
                        mail.setHtmlBody(htmlBody);
                        mail.setSaveAsActivity(false);
                        mail.setSubject('Formalización revisión');
                        emailList.add(mail);
                    }
                }
                if(!emailList.isEmpty()){
                    Messaging.sendEmail(emailList);
                }
            }
        }catch(Exception ex){
            System.debug('Error to send email.');
        }
    }
}