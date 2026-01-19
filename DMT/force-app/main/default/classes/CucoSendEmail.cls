/**
* ────────────────────────────────────────────────────────────────────
* CucoSendEmail
* Class to send email information and notifications in Salesforce.
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoSendEmail {

    /**
	* SINGLETON PATTERN
	*/
    private static CucoSendEmail instance;

    /**
	* Constructor
	*/
    private CucoSendEmail() {
    }

    /**
	* getInstance
	*/
    public static CucoSendEmail gtInstance() {
        if(instance == null) {
            instance = new CucoSendEmail();
        }
        return instance;
    }

    /**
    * @description method: Prepare data for SendEmailClass and notifications on cuco__profitability_sheet__c
    * @param books : List<cuco__profitability_sheet__c>
    * @param idProfSheetSet : Set<Id> Id of cuco__profitability_sheet__c
    * @param setProfSheetCode : Set<String> cuco__gf_profitability_sheet_id__c of cuco__profitability_sheet__c
    */
    public static void notifications (List<cuco__profitability_sheet__c> books, Set<Id> idProfSheetSet, Set<String> setProfSheetCode) {
        final List<cuco__profitability_analysis__c> lstPA = CucoSendEmailHelper.getPA(idProfSheetSet,setProfSheetCode);
        final List<cuco__profitability_analysis__c> newLstPA = CucoSendEmailHelper.getBookRelated(lstPA,books);
        final Map<Id,List<String>> mapCurrentPP = CucoSendEmailHelper.getCurrentProfParticipants(idProfSheetSet);
        Map<String,Set<Id>> mapAnalysis = new Map<String,Set<Id>> ();
        Map<Id,User> userMap = new Map<Id,User> ();
        if (!lstPA.isEmpty() && !newLstPA.isEmpty()) {
            final Set<Id> resultIds = (new Map<Id,SObject>(newLstPA)).keySet();
            final Map<String,String> auditMap = CucoSendEmailHelper.getAudits(resultIds);
            mapAnalysis = CucoSendEmailHelper.getMapAnalysis(newLstPA,auditMap);
            userMap = CucoSendEmailHelper.getUsers(CucoSendEmailHelper.getIdUsersToFind(newLstPA,auditMap));
        }
        final Map<Id,CucoConstructor.DataBooks> mapToSend = CucoSendEmailHelper.getMapToSend(books,mapAnalysis,mapCurrentPP);
        if(!mapToSend.isEmpty()) {
            final EmailTemplate template = getEmailTemplate('ErrorPricing');
            final CustomNotificationType typeId = getcustomNType();
            sendNotifications(mapToSend,userMap,template);
            setupNotifications(mapToSend,userMap,typeId);
        }
    }

    /**
    * @description method: Manage data for SendEmailClass
    * @param mapToSend : Map<Id,CucoConstructor.DataBooks> Id cuco__profitability_sheet__c,
    * {OwnerId of cuco__profitability_sheet__c/ActionAudit userId, List cuco__profitability_sheet_participant__c,cuco__profitability_sheet__c}
    * @param userMap : Map<Id,User>
    * @param template : template ErrorPricing
    */
    public static void sendNotifications (Map<Id,CucoConstructor.DataBooks> mapToSend, Map<Id,User> userMap, EmailTemplate template) {
        final List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
        for(Id idKey:mapToSend.keySet()) {
            final CucoConstructor.DataBooks dataBooks2 = mapToSend.get(idKey);
            final Set<Id> idUser2 = dataBooks2.idUser;
            if (!idUser2.isEmpty()) {
                for (Id idUser : idUser2) {
                    final Messaging.SingleEmailMessage mail = getEmail(template);
                    mail.setHtmlBody(createEmailBody(dataBooks2.book,template,dataBooks2.lstCurrentPP));
                    final String[] toAddresses = new String[] {userMap.get(idUser).Email};
                    mail.setToAddresses(toAddresses);
                    lstMails.add(mail);
                }
            }
        }
        Messaging.sendEmail(lstMails);
    }

    /**
    * @description method: Manage data for Send Notification class
    * @param mapToSend : Map<Id,CucoConstructor.DataBooks> Id cuco__profitability_sheet__c,
    * {OwnerId of cuco__profitability_sheet__c/ActionAudit userId, List cuco__profitability_sheet_participant__c,cuco__profitability_sheet__c}
    * @param userMap : Map<Id,User>
    * @param typeId : CustomNotificationType 'Cuaderno_de_Condiciones'
    */
    public static void setupNotifications (Map<Id,CucoConstructor.DataBooks> mapToSend, Map<Id,User> userMap, CustomNotificationType typeId) {
        final Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(typeId.Id);
        for(Id idKey:mapToSend.keySet()) {
            final CucoConstructor.DataBooks dataBooks2 = mapToSend.get(idKey);
            notification.setTargetId(dataBooks2.book.Id);
            String numberBook= '';
            if (dataBooks2.book.getSObjectType().getDescribe().getName() == System.Label.profitability_analysis) {
                notification.setBody(System.Label.Notificacion_Comentarios);
                numberBook = String.isBlank((String)dataBooks2.book.get('cuco__gf_auto_formalization_req_id__c')) ? ' ' :(String)dataBooks2.book.get('cuco__gf_auto_formalization_req_id__c');
                notification.setTitle(System.Label.Numero_de_Cuaderno + numberBook + ' ' + System.Label.Comentarios_Cuaderno);

            } else {
                notification.setBody(System.Label.Notificacion_Error);
                numberBook = (String)dataBooks2.book.get('cuco__gf_profitability_sheet_id__c');
                notification.setTitle(System.Label.Numero_de_Cuaderno + numberBook + ' ' + System.Label.Errores_cuaderno);
            }
            final Set<Id> idUser2 = dataBooks2.idUser;
            if (!idUser2.isEmpty()) {
                for (Id idUser : idUser2) {
                    notification.setSenderId(userMap.get(idUser).Id);
                    notification.send(new Set<String> { userMap.get(idUser).Id });
                }
            }
        }
    }

    /**
    * @description method: create Email Body
    * @param book : cuco__profitability_sheet__c/cuco__profitability_analysis__c
    * @param template : template ErrorPricing
    * @param names : names of clientes related (cuco__profitability_sheet_participant__c/cuco__profitability_analysis_participant__c)
    */
    public static String createEmailBody(sObject book, EmailTemplate template, List<String> names) {
        final String recordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+book.Id;
        String body= '';
        String numberBook= '';
        String plainText = template.HTMLValue;
        String labelText = System.Label.Listado_con_errores;
        if (book.getSObjectType().getDescribe().getName() == System.Label.profitability_analysis) {
            numberBook = String.isBlank((String)book.get('cuco__gf_auto_formalization_req_id__c')) ? ' ' :(String)book.get('cuco__gf_auto_formalization_req_id__c');
        } else {
            numberBook = (String)book.get('cuco__gf_profitability_sheet_id__c');
        }
        plainText = plainText.replace('{!book.Number}',numberBook);
        plainText = plainText.replace('{!book.Name}', (String)book.get('Name'));
        plainText = plainText.replace('{!book.Link}','<a href="'+ recordlink + '">');
        if (template.DeveloperName == 'CommentsPricing') {
            labelText = System.Label.Listado_con_notificaciones;
        } else if (template.DeveloperName == 'RestudyPricing') {
            labelText = System.Label.Listado_reestudio;
        }
        if (names != NULL) { // NOSONAR
            body += '<p>' + labelText + '</p>';
            Integer inte =1;
            for (String name : names) {
                body += inte + ' ' + name + '<br />';
                inte++;
            }
            plainText = plainText.replace('#Participants#', body);
        } else {
            plainText = plainText.replace('#Participants#', '');
        }
        return plainText;
    }

    /**
    * @description Prepare SingleEmailMessage
    * @param template : template (ErrorPricing/CommentsPricing)
    * @return mail Messaging.SingleEmailMessage
    */
    public static Messaging.SingleEmailMessage getEmail(EmailTemplate template) {
        final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName(System.Label.Notificacion_Error_Cuaderno);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setSubject(template.Subject);
        return mail;
    }

    /**
    * @description Select EmailTemplate
    * @param nameTemplate : name of defined template (ErrorPricing/CommentsPricing)
    * @return EmailTemplate template
    */
    public static EmailTemplate getEmailTemplate (String nameTemplate) {
        return [SELECT Id,HTMLValue,Body,Subject,DeveloperName FROM EmailTemplate WHERE Name =: nameTemplate WITH SECURITY_ENFORCED LIMIT 1];
    }

    /**
    * @description Select CustomNotificationType
    * @return CustomNotificationType typeId
    */
    public static CustomNotificationType getcustomNType () {
        return [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Cuaderno_de_Condiciones'];
    }

}