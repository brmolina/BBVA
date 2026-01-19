/**
 * --------------------------------------------------------------------------------------------------
 * @Name     CRMX_InvocableEmailTemplate_Service
 * @Author   Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date     2025-01-08
 * @Group    Expo
 * --------------------------------------------------------------------------------------------------
 * @Description  Service class for processing and sending emails using classic Salesforce templates.
 * --------------------------------------------------------------------------------------------------
 * @Changes
 * |2025-01-08 Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 *             Class creation.
 * --------------------------------------------------------------------------------------------------
 */
public with sharing class CRMX_InvocableEmailTemplate_Service {
    /**
     * @Description Slash for concatenating URLs.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String SLASH = '/';
    /**
     * @Description Key to replace the executive owner's name.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String EXECUTIVE = '{Ejecutivo}';
    /**
     * @Description Key to replace the client's name.
     * @Author      Alejandro Rodriguez Contreras alejandro.rodriguez.contreras.contractor@bbva.com
     */
    private static final String CLIENT = '{Cliente}';
    /**
     * @Description Key to replace the client's record page URL.
     * @Author      Alejandro Rodriguez Contreras alejandro.rodriguez.contreras.contractor@bbva.com
     */
    private static final String EXPO_URL = '{Url}';
    /* 
     *  --------------------------------------------------------------------------------------------------
     * @Description Private constructor of the class, SonarQube rule.
     *  --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     *  --------------------------------------------------------------------------------------------------
     */
    @testVisible
    private CRMX_InvocableEmailTemplate_Service() {}
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Static method to send emails using a classic template.
     *              This method builds and sends email messages based on the received requests.
     *  --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @param       requests List of email requests, each containing information 
     *                       about the template, recipients, and executive to personalize the message.
     * @return      void
     * @example     CRMX_InvocableEmailTemplate_Service.sendEmailTemp(List<CRMX_InvocableEmailTemplate_Cls.EmailRequest> requests);
     *  --------------------------------------------------------------------------------------------------
     */
    public static void sendEmailTemp(List<CRMX_InvocableEmailTemplate_Cls.EmailRequest> requests) {
        final List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        for (CRMX_InvocableEmailTemplate_Cls.EmailRequest rowRequest : requests) {
            final String strUrl = System.URL.getOrgDomainUrl().toExternalForm();
            final String urlAccount = strUrl+SLASH+rowRequest.objCuenta.id;
            final String htmlBody = rowRequest.emailTemplate.HtmlValue.replace(EXECUTIVE, rowRequest.strExecutive).replace(CLIENT, rowRequest.objCuenta.name).replace(EXPO_URL,urlAccount);
            final Messaging.SingleEmailMessage emailInfo = new Messaging.SingleEmailMessage();
            emailInfo.setHtmlBody(htmlBody);
            emailInfo.setUseSignature(false);
            emailInfo.setTargetObjectId(rowRequest.recipientId);
            emailInfo.setSubject(rowRequest.emailSubject);
            emailInfo.setOrgWideEmailAddressId(rowRequest.strSender);
            emailInfo.setSaveAsActivity(false);
            emailMessages.add(emailInfo);
        }
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    }
}