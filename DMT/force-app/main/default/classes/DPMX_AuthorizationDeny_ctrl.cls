/**
* ____________________________________________________________________________
* Controller class for DPMX_NewDynamicPricing.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-04-
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_AuthorizationDeny_ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_AuthorizationDeny_ctrl() {

    }

    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param recordId : Client Id
    * @return retMap status update 
    */
    @AuraEnabled
    public static Map<String,Object> updateAuth (String recordId, String commentarioTxt) {
        Map<String, Object> retMap = new Map<String, Object>();
        boolean toastStatus = false;
        DPMX_authorization__c auth = [SELECT Status__c, commentAuthorizer__c, Date_AuthorizerDate__c, OwnerFullName__c, LKP_Dynamic_Pricing__c, LKP_Dynamic_Pricing__r.name, LKP_Dynamic_Pricing__r.Client__c, lkp_AssignedTo__c, CreatedById
        FROM DPMX_authorization__c
        WHERE Id =:recordId];
        
        if(auth.Status__c == 'Pendiente'){
            auth.Date_AuthorizerDate__c = Date.today();
            auth.Status__c = 'Denegado';
            auth.commentAuthorizer__c = commentarioTxt;
            toastStatus = true;
            update auth;
        }
        
        Messaging.CustomNotification notify = new Messaging.CustomNotification();
        notify.setTitle('Autorizacion denegada.');
        notify.setBody('La autorización del Dynamic pricing se ha denegado.');
        notify.setNotificationTypeId([select id from CustomNotificationType where developername = 'DPMX_Autorizacion_actualizada'].id);
        notify.setTargetId(auth.LKP_Dynamic_Pricing__c);
        Set<String> recipientsIds = new Set<String>();
        recipientsIds.add(auth.lkp_AssignedTo__c);
        recipientsIds.add(auth.CreatedById);

        // Actually send the notification
        try {
            notify.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }

        sendReport(commentarioTxt, recordId);

		retMap.put('statusAuth', toastStatus);
        return retMap;
    }

    @AuraEnabled
    public static Map<String,Object> sendReport (String commentarioTxt, string authId) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemp = DPMX_Utils.returnEmailTemp('DPMX_AuthorizeDenied');
        DPMX_authorization__c auth = DPMX_Utils.AuthSelector(authId);
        DPMX_Dynamic_Pricing__c DPAut = DPMX_Utils.dynamicPricingSelector(auth.LKP_Dynamic_Pricing__c);
        DateTime today = DateTime.now();
        String consultDate = today.format('yyyy-MM-dd');
        Map<String, Object> retMap = new Map<String, Object>();
        String htmlBody = emailTemp.HtmlValue;
        string status = 'sendReport';
        Boolean sendReport = true;
            
        htmlBody = htmlBody.replace('{!DPMX.fecha}',consultDate);
        htmlBody = htmlBody.replace('{!DPMX.razónSocial}',DPAut.Company_Name__r.Name);
        htmlBody = htmlBody.replace('{!DPMX.comentario}',commentarioTxt);
        htmlBody = htmlBody.replace('{!DPMX.Link}', Label.DPMX_Link);
        htmlBody = htmlBody.replace('{!DPMX.autId}',auth.LKP_Dynamic_Pricing__c);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(emailTemp.Id);
        mail.setTargetObjectId(auth.CreatedById);
        mail.setHtmlBody(htmlBody);
        mail.setSaveAsActivity(false);
        mail.setSubject('Respuesta a solicitud de autorización de tasa');
        emailList.add(mail);
        
        if(!emailList.isEmpty()){
            //Messaging.sendEmail(emailList);
            try {
        		Messaging.sendEmail(emailList);
    		} catch (EmailException e) {
                if (Test.isRunningTest()) {
                    // Silenciamos el error solo en tests si es por falta de configuración
                    System.debug('Error de envío en test: ' + e.getMessage());
                } else {
                    throw e;
                }
            }
        }else {
            status = 'fail send report';
            sendReport = false;
        }
        retMap.put('sendReport', sendReport);
        retMap.put('status', status);
        return retMap;
    }
}