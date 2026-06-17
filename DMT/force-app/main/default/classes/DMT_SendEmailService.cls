/**
 * @description Service class to centralize  email generation and delivery.
 */
public with sharing class DMT_SendEmailService {
    private static final String LINE_TEMPLATE = 'DMT_Line_Approver';
    private static final String OPPORTUNITY_TEMPLATE = 'DMT_Opportunity_Approver';
    private static final String SITE_NAME = 'DMT_Public_Site_Template_Email';

    private class ResourceUrls {
        public String bbva;
        public String wut;
        public String file;
    }

    private class EmailContext {
        public Id recordId;
        public Schema.SObjectType recordType;
        public String selectedTemplateName;
        public String safeName;
        public Messaging.EmailFileAttachment attachment;
        public EmailTemplate template;
        public ResourceUrls resourceUrls;
    }

    /**
     * @description Builds PDF from HTML map payload and sends the email if business criteria are met.
     * @param dataMap payload containing HTML, status and record fields.
     */
    public static void processMapAndSendEmail(Map<String, Object> dataMap) {
        try {
            System.debug('Received dataMap: ' + dataMap);
            String htmlContent = getMapValue(dataMap, 'HTML');
            String recordId = resolveRecordId(dataMap);
            String recordName = resolveRecordName(dataMap);
            String pdfBase64 = buildPdfBase64(htmlContent);
            System.debug('HTML content length: ' + htmlContent.length());
            System.debug('RecordId: ' + recordId);
            System.debug('RecordName: ' + recordName);
            System.debug('Generated PDF Base64 length: ' + pdfBase64.length());


            if (String.isBlank(pdfBase64) || String.isBlank(recordId)) {
                System.debug('Error: Failed to generate PDF or missing recordId.');
                return;
            }
            System.debug('Checking eligibility to send email for recordId: ' + recordId + ', eligible: ' + isEligibleToSend(dataMap));
            if (isEligibleToSend(dataMap)) {
                sendEmailAsync(pdfBase64, recordId, recordName);
            }
        } catch (Exception ex) {
            System.debug('Error in processMapAndSendEmail: ' + ex.getMessage());
        }
    }

    /**
     * @description Validates payload and triggers snapshot approval email send.
     * @param pdfBase64 PDF in base64 format.
     * @param lineId line or opportunity id.
     * @param lineName line or opportunity name.
     */
    public static void sendEmailToApprovers(String pdfBase64, String lineId, String lineName) {
        try {
            if (String.isBlank(pdfBase64) || String.isBlank(lineId)) {
                throw new AuraHandledException('Missing required data (PDF or Line).');
            }
            sendEmailAsync(pdfBase64, lineId, lineName);
        } catch (Exception ex) {
            throw new AuraHandledException('Error starting email send: ' + ex.getMessage());
        }
    }

    /**
     * @description Sends snapshot approval emails to approvers.
     * @param pdfBase64 PDF in base64 format.
     * @param lineId line or opportunity id.
     * @param lineName line or opportunity name.
     */
    public static void sendEmailAsync(String pdfBase64, String lineId, String lineName) {
        if (String.isBlank(lineId)) {
            System.debug('Error: LineId is null');
            return;
        }

        Id recordId = parseRecordId(lineId);
        if (recordId == null) {
            return;
        }

        EmailContext context = buildEmailContext(pdfBase64, lineId, lineName, recordId);
        if (context == null) {
            return;
        }

        Map<Id, String> recipientEmails = DMT_SendEmailSelectTeamMember.getRecipientEmails(context.recordId, context.recordType);
        if (recipientEmails.isEmpty()) {
            System.debug('No recipients found to send emails.');
            return;
        }

        Id sanctionLineId = getSanctionLineId(context.recordId, context.recordType);
        List<Messaging.SingleEmailMessage> emailsToSend = buildEmails(recipientEmails, context, sanctionLineId, lineId);
        Boolean emailSent = sendEmails(emailsToSend);

        if (emailSent) {
            try {
                DMT_CoreDocumentsUploadFile.enqueueUploadAfterEmail(context.recordId, context.safeName, pdfBase64);
            } catch (Exception ex) {
                System.debug('Error queueing CoreDocuments upload: ' + ex.getMessage());
            }
        }
    }

    private static String buildPdfBase64(String htmlContent) {
        Blob pdfBlob = DMT_BlobBuilderForPDF.buildPdfBlob(htmlContent);
        return EncodingUtil.base64Encode(pdfBlob);
    }

    private static Boolean isEligibleToSend(Map<String, Object> dataMap) {
        String statusLine = getMapValue(dataMap, 'StatusLine');
        String closeLine = getMapValue(dataMap, 'CloseLine');
        String categoryId = getMapValue(dataMap, 'categoryId');
        String recTypeName = getMapValue(dataMap, 'RecordTypeName');

        Boolean isClosedWonStatus = statusLine == 'Closed Won'|| statusLine == 'Closed-Won'|| (statusLine == 'Closed' && closeLine == 'Won')|| closeLine == 'Won';
        Boolean isValidCategory = categoryId == 'Ready to close-Closed'|| categoryId == 'Ready to close-Closed Won' || categoryId == 'User Defined';
        Boolean isValidRecType = recTypeName == 'TreasurySettlement'|| recTypeName == 'OtherProducts'|| recTypeName == 'Sanction'|| recTypeName == 'DMT_Opportunity';

        return isClosedWonStatus && isValidCategory && isValidRecType;
    }

    private static String getMapValue(Map<String, Object> dataMap, String keyName) {
        return dataMap != null && dataMap.containsKey(keyName) ? String.valueOf(dataMap.get(keyName)) : '';
    }

    private static String resolveRecordId(Map<String, Object> dataMap) {

        List<String> candidateKeys = new List<String>{'recordLineId','lineId','recordId','opportunityId'};
        for (String keyName : candidateKeys) {
            String value = getMapValue(dataMap, keyName);
            if (String.isNotBlank(value)) {
                return value;
            }
        }
        return '';
    }

    private static String resolveRecordName(Map<String, Object> dataMap) {

        List<String> candidateKeys = new List<String>{'lineName','recordName','opportunityName','Name'};
        for (String keyName : candidateKeys) {
            String value = getMapValue(dataMap, keyName);
            if (String.isNotBlank(value)) {
                return value;
            }
        }
        return '';
    }

    private static Id parseRecordId(String lineId) {
        try {
            return (Id)lineId.trim();
        } catch (Exception ex) {
            System.debug('Error: invalid lineId format. ' + ex.getMessage());
            return null;
        }
    }

    private static EmailContext buildEmailContext(String pdfBase64, String lineId, String lineName, Id recordId) {
        EmailContext context = new EmailContext();
        context.recordId = recordId;
        context.recordType = recordId.getSObjectType();
        context.safeName = buildSafeFileName(lineId, lineName, context.recordType);
        context.attachment = buildAttachment(pdfBase64, context.safeName);
        if (context.attachment == null) {
            return null;
        }

        context.template = resolveTemplate(context.recordType);
        if (context.template == null) {
            System.debug('Error: No compatible email template found (DMT_Line_Approver / DMT_Opportunity_Approver).');
            return null;
        }

        context.selectedTemplateName = context.recordType == Opportunity.SObjectType ? OPPORTUNITY_TEMPLATE : LINE_TEMPLATE;
        if (context.recordType == Opportunity.SObjectType && context.template.DeveloperName == LINE_TEMPLATE) {
            context.selectedTemplateName = LINE_TEMPLATE;
        }

        context.resourceUrls = getResourceUrls();
        if (context.resourceUrls == null) {
            return null;
        }

        return context;
    }

    private static String buildSafeFileName(String lineId, String lineName, Schema.SObjectType recordType) {
        String recordPrefix = recordType == Opportunity.SObjectType ? 'Opportunity_' : 'Line_';
        String resolvedName = String.isBlank(lineName) ? recordPrefix + lineId : lineName.trim();
        if (resolvedName.toLowerCase().endsWith('.pdf')) {
            resolvedName = resolvedName.substring(0, resolvedName.length() - 4);
        }
        return resolvedName.replaceAll('[\\/:*?"<>|]', '_');
    }

    private static Messaging.EmailFileAttachment buildAttachment(String pdfBase64, String safeName) {
        try {
            Blob fileBody = EncodingUtil.base64Decode(pdfBase64);
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(safeName + '.pdf');
            attachment.setBody(fileBody);
            attachment.setContentType('application/pdf');
            return attachment;
        } catch (Exception ex) {
            System.debug('Error decoding base64 PDF: ' + ex.getMessage());
            return null;
        }
    }

    private static EmailTemplate resolveTemplate(Schema.SObjectType recordType) {
        Map<String, EmailTemplate> templatesByName = new Map<String, EmailTemplate>();
        for (EmailTemplate templateItem : DMT_SendEmailService_Selector.getEmailTemplatesByDeveloperNames(
            new List<String>{ LINE_TEMPLATE, OPPORTUNITY_TEMPLATE }
        )) {
            templatesByName.put(templateItem.DeveloperName, templateItem);
        }

        String preferred = recordType == Opportunity.SObjectType ? OPPORTUNITY_TEMPLATE : LINE_TEMPLATE;
        if (templatesByName.containsKey(preferred)) {
            return templatesByName.get(preferred);
        }
        return templatesByName.containsKey(LINE_TEMPLATE) ? templatesByName.get(LINE_TEMPLATE) : null;
    }

    private static ResourceUrls getResourceUrls() {
        List<Site> sites = DMT_SendEmailService_Selector.getSiteByName(SITE_NAME);
        if (sites.isEmpty()) {
            System.debug('Error: Site DMT_Public_Site_Template_Email not found in this org.');
            return null;
        }

        List<SiteDetail> details = DMT_SendEmailService_Selector.getSiteDetailByDurableId(sites[0].Id);
        if (details.isEmpty()) {
            System.debug('Error: SiteDetail not found for Site Id: ' + sites[0].Id);
            return null;
        }

        String baseUrl = details[0].SecureUrl;
        ResourceUrls urls = new ResourceUrls();
        urls.bbva = baseUrl + 'resource/DMT_ET_BBVA';
        urls.wut = baseUrl + 'resource/DMT_ET_WUT';
        urls.file = baseUrl + 'resource/DMT_ET_FILE';
        return urls;
    }

    private static Id getSanctionLineId(Id recordId, Schema.SObjectType recordType) {
        if (recordType != Opportunity.SObjectType) {
            return null;
        }

        List<Opportunity> opportunities = DMT_SendEmailService_Selector.getOpportunitySanctionById(recordId);
        return opportunities.isEmpty() ? null : opportunities[0].DMT_Sanction__c;
    }

    private static List<Messaging.SingleEmailMessage> buildEmails(Map<Id, String> recipientEmails, EmailContext context, Id sanctionLineId, String lineId) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Id userId : recipientEmails.keySet()) {
            Messaging.SingleEmailMessage renderedMail = renderMailForMember(context, userId, sanctionLineId);
            String bodyHtml = renderedMail != null ? renderedMail.getHtmlBody() : null;
            String subject = renderedMail != null ? renderedMail.getSubject() : null;

            if (String.isBlank(bodyHtml)) {
                bodyHtml = buildFallbackEmailHtml(context.safeName, lineId, context.resourceUrls);
            } else {
                bodyHtml = replaceTemplateUrls(bodyHtml, context.resourceUrls);
            }
            if (String.isBlank(subject)) {
                subject = 'Snapshot PDF - ' + context.safeName;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject(subject);
            mail.setHtmlBody(bodyHtml);
            mail.setBccSender(false);
            mail.setToAddresses(new List<String>{ recipientEmails.get(userId) });
            mail.setSaveAsActivity(false);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { context.attachment });
            emailsToSend.add(mail);
        }
        return emailsToSend;
    }

    private static Messaging.SingleEmailMessage renderMailForMember(EmailContext context, Id userId, Id sanctionLineId) {
        if (context.recordType == Opportunity.SObjectType
            && context.selectedTemplateName == LINE_TEMPLATE
            && sanctionLineId != null) {
            Messaging.SingleEmailMessage sanctionMail = renderTemplateSafe(context.template.Id, userId, sanctionLineId);
            if (sanctionMail != null) {
                return sanctionMail;
            }
        }
        return renderTemplateSafe(context.template.Id, userId, context.recordId);
    }

    private static String replaceTemplateUrls(String bodyHtml, ResourceUrls resourceUrls) {
        return bodyHtml
            .replace('{URL_BBVA}', resourceUrls.bbva)
            .replace('{URL_WUT}', resourceUrls.wut)
            .replace('{URL_File}', resourceUrls.file);
    }

    private static Boolean sendEmails(List<Messaging.SingleEmailMessage> emailsToSend) {
        System.debug('Prepared ' + emailsToSend.size() + ' email(s) to send.');
        if (emailsToSend.isEmpty()) {
            return false;
        }

        try {
            Boolean hasSuccess = false;
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
            for (Integer idx = 0; idx < results.size(); idx++) {
                if (results[idx].isSuccess()) {
                    hasSuccess = true;
                } else {
                    for (Messaging.SendEmailError sendError : results[idx].getErrors()) {
                        System.debug('Email idx ' + idx + ' ERROR: ' + sendError.getMessage());
                    }
                }
            }
            return hasSuccess;
        } catch (Exception ex) {
            if (Test.isRunningTest()) {
                System.debug('Send error in test: ' + ex.getMessage());
                return false;
            }
            throw ex;
        }
    }

    private static Messaging.SingleEmailMessage renderTemplateSafe(Id templateId, Id userId, Id whatId) {
        try {
            return Messaging.renderStoredEmailTemplate(templateId, userId, whatId);
        } catch (Exception ex) {
            return null;
        }
    }

    private static String buildFallbackEmailHtml(String recordName, String recordId, ResourceUrls resourceUrls) {
        return '<div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#1f1f1f;">'
            + '<p>Se ha generado una nueva versión del documento para aprobación.</p>'
            + '<p><strong>Registro:</strong> ' + escapeHtml(recordName) + '</p>'
            + '<p><strong>ID:</strong> ' + escapeHtml(recordId) + '</p>'
            + '<p>Se adjunta el PDF en este correo.</p>'
            + '<hr style="border:none;border-top:1px solid #d9d9d9;"/>'
            + '<p style="font-size:12px;color:#6b6b6b;">'
            + '<img src="' + resourceUrls.bbva + '" alt="BBVA" style="height:20px;vertical-align:middle;margin-right:8px;"/>'
            + '<img src="' + resourceUrls.wut + '" alt="WUT" style="height:20px;vertical-align:middle;margin-right:8px;"/>'
            + '<img src="' + resourceUrls.file + '" alt="File" style="height:20px;vertical-align:middle;"/>'
            + '</p>'
            + '</div>';
    }

    @TestVisible
    private static String buildFallbackEmailHtmlForTest(String recordName, String recordId, String bbvaUrl, String wutUrl, String fileUrl) {
        ResourceUrls resourceUrls = new ResourceUrls();
        resourceUrls.bbva = bbvaUrl;
        resourceUrls.wut = wutUrl;
        resourceUrls.file = fileUrl;
        return buildFallbackEmailHtml(recordName, recordId, resourceUrls);
    }

    private static String escapeHtml(String inputValue) {
        if (inputValue == null) {
            return '';
        }
        return inputValue
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }

    @TestVisible
    private static String escapeHtmlForTest(String inputValue) {
        return escapeHtml(inputValue);
    }
}