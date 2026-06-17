/**
* ────────────────────────────────────────────────────────────────────
* CSTK_Sustainable_Turnover_Alerts_Batch
* Batch to create alerts if the expiration date of Sustainable Turnover is approaching
* ────────────────────────────────────────────────────────────────────
* @author      Catalin Ionut Vasilache <catalin.vasilache.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-11-11
* @modified
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.EmptyStatementBlock')
global with sharing class CSTK_Sustainable_Turnover_Alerts_Batch implements Database.Batchable<sObject>, Database.Stateful {
    /** @description  Incremental Integer for alert key **/
    private Integer incrementalPK = 0;

    /** @description  Datetime NOW for alert key **/
    private Datetime dateTimeNOW = Datetime.now();

    /**
    * @description start batch.
    * @param batchableContext
    * @return Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        final Date today = Date.today();
        final Date next30days = today.addDays(30);
        return Database.getQueryLocator([
            SELECT Id, cstk__toolkit_id__c, cstk__year__c, cstk__exp_date__c, cstk__toolkit_id__r.cstk__account_id__c,
            cstk__toolkit_id__r.cstk__account_id__r.Name, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__c,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.Email, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.FederationIdentifier,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.IsActive, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__c,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__c, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.Email,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.FederationIdentifier,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.IsActive
            FROM cstk__Environmental_sales__c
            WHERE cstk__exp_date__c > :today AND cstk__exp_date__c <= :next30days AND cstk__has_processed_alert__c = false
            AND (
                cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__c != null
                OR cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__c != null
            )
            ORDER BY cstk__toolkit_id__c, cstk__year__c DESC
        ]);
    }

    /**
    * @description execute batch.
    * @param batchableContext
    * @param envDataInfo
    */
    global void execute(Database.BatchableContext batchableContext, List<cstk__Environmental_sales__c> envDataInfo) {
        final List<cstk.Alert_Wrapper> wrapperAlertList = new List<cstk.Alert_Wrapper>();
        final List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
        final List<cstk__Environmental_sales__c> envToUpdate = new List<cstk__Environmental_sales__c>();
        final cstk.Toolkit_Settings_Selector selector = new cstk.Toolkit_Settings_Selector();
        final cstk__toolkit_settings__mdt config = selector.selectActiveRecord()[0];
        final String expirationTemplate = config.cstk__susTurn_expiration_email_template__c;
        final String classNameAlert = config.cstk__Alert_itf_class_name__c;
        final cstk.Alert_Itf instance = (cstk.Alert_Itf)Type.forName(classNameAlert).newInstance();
        final EmailTemplate template = [SELECT Id, Subject, HtmlValue, Name FROM EmailTemplate WHERE Name =: expirationTemplate];

        for (cstk__Environmental_sales__c env : envDataInfo) {
            String recipientUser;
            String recipientEmail;
            String recipientFederation;

            if (String.isNotBlank(env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__c)
            && env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.IsActive) {
                recipientUser = env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__c;
                recipientEmail = env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.Email;
                recipientFederation = env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.FederationIdentifier;
            } else if (String.isNotBlank(env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__c)
            && env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.IsActive) {
                recipientUser = env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__c;
                recipientEmail = env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.Email;
                recipientFederation = env.cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.FederationIdentifier;
            } else {
                env.cstk__has_processed_alert__c = true;
                envToUpdate.add(env);
                continue;
            }

            // Create Commercial Alert
            final Map<String, String> params = new Map<String, String>();
            params.put('incremPK', String.valueOf(incrementalPK));
            params.put('startDate', String.valueOf(dateTimeNOW));
            params.put('recipientUser', recipientUser);
            params.put('recipientFederation', recipientFederation);
            wrapperAlertList.add(createSustainableTurnoverAlert(env, params));
            incrementalPK++;

            // Create Email Notification
            if (String.isNotBlank(recipientEmail) && !recipientEmail.contains('.invalid')) {
                messagesList.add(createSustainableTurnoverExpirationEmail(env, template, recipientEmail));
            }

            // Update cstk__Environmental_sales__c flag
            env.cstk__has_processed_alert__c = true;
            envToUpdate.add(env);

            if (incrementalPK > 99999) {
                incrementalPK = 0;
                dateTimeNOW = Datetime.now();
            }
        }

        if (!wrapperAlertList.isEmpty()) {
            instance.createUserAlerts(wrapperAlertList);
        }

        if (!messagesList.isEmpty()) {
            CSTK_Utils.sendEmails(messagesList);
        }

        if (!envToUpdate.isEmpty()){
            update envToUpdate;
        }
    }

    /**
    * @description finish batch.
    * @param batchableContext
    */
    global void finish(Database.BatchableContext batchableContext) {}

    /**
    * @description Create sustainable turnover alert.
    * @param envSales : environmental sales record
    * @return Alert_Wrapper
    */
    private static cstk.Alert_Wrapper createSustainableTurnoverAlert(cstk__Environmental_sales__c envSales, Map<String, String> params) {
        final cstk.Alert_Wrapper wrapperAlert = new cstk.Alert_Wrapper();
        wrapperAlert.accountId = envSales.cstk__toolkit_id__r.cstk__account_id__c;
        wrapperAlert.toolkitId = envSales.cstk__toolkit_id__c;
        wrapperAlert.userId = params.get('recipientUser');
        wrapperAlert.alertType = 'Sustainability Turnover Alert';
        wrapperAlert.description =  'Sustainability turnover is about to expire - ' + envSales.cstk__toolkit_id__r.cstk__account_id__r.Name;
        wrapperAlert.name = 'Sust. Turnover Alert: ' + envSales.cstk__toolkit_id__r.cstk__account_id__r.Name;
        wrapperAlert.priority = 'Low';
        wrapperAlert.year = envSales.cstk__year__c;
        wrapperAlert.alertId = params.get('startDate') + params.get('incremPK');
        wrapperAlert.federationId = params.get('recipientFederation');
        return wrapperAlert;
    }

    /**
    * @description Create sustainable turnover email.
    * @param envSales : environmental sales record
    * @param template : template
    * @param recipientEmail : recipient email address
    * @return Messaging.SingleEmailMessage
    */
    public static Messaging.SingleEmailMessage createSustainableTurnoverExpirationEmail(cstk__Environmental_sales__c envSales, EmailTemplate template, String recipientEmail) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setUseSignature(false);
        message.setBccSender(false);
        message.setSaveAsActivity(false);
        message.toAddresses = new List<String>{recipientEmail};

        try {
            message.setTemplateID(template.Id);
            String body = template.HtmlValue;
            body = body.replaceAll('\\{link\\}', URL.getOrgDomainURL().toExternalForm() + '/lightning/r/cstk__Toolkit__c/' + envSales.cstk__toolkit_id__c + '/view');
            body = body.replaceAll('\\{group\\}', envSales.cstk__toolkit_id__r.cstk__account_id__r.Name);
            body = body.replaceAll('\\{year\\}', envSales.cstk__year__c);
            body = body.replaceAll('\\{expirationDate\\}', String.valueOf(envSales.cstk__exp_date__c));
            message.setHtmlBody(body);
            String subject = template.Subject;
            subject = subject.replaceAll('\\{group\\}', envSales.cstk__toolkit_id__r.cstk__account_id__r.Name);
            message.subject = subject;
        } catch (Exception e) { //NOSONAR
            System.debug(e.getMessage()); //NOSONAR
            String text = 'Dear user:\n\n';
            text = text + 'Please be reminded that the sustainability turnover for the client ' + envSales.cstk__toolkit_id__r.cstk__account_id__r.Name + ' related to the Toolkit year ' + envSales.cstk__year__c +  ' is approaching its expiration date ' + envSales.cstk__exp_date__c + '.\n\n';
            text = text + 'You are receiving this notification as the designated Global Banker. Please notify the appropriate team to review the sustainability turnover date.\n\n';
            text = text + 'Kindly reach out to the client to proceed with the update.\n\n';
            text = text + URL.getOrgDomainURL().toExternalForm() + '/lightning/r/cstk__Toolkit__c/' + envSales.cstk__toolkit_id__c + '/view\n\n';
            text = text + '\nBest Regards\n\n';
            message.plainTextBody = text;
            message.subject = '[ST] URGENT Sustainability Turnover about to expire - ' + envSales.cstk__toolkit_id__r.cstk__account_id__r.Name;
        }

        return message;
    }
}