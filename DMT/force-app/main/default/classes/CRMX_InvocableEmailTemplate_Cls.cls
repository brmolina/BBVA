/**
 *  --------------------------------------------------------------------------------------------------
 * @Name     CRMX_InvocableEmailTemplate_Cls
 * @Author   Jose Eduardo Murillo Garcia joseeduardo.murillo.garcia.contractor@bbva.com
 * @Date     2024-10-10
 * @Group    Expo
 * --------------------------------------------------------------------------------------------------
 * @Description Class for handling email sending using classic Salesforce templates. 
 *              Implements the Singleton pattern to ensure a single instance.
 * --------------------------------------------------------------------------------------------------
 * @Changes
 * |2024-10-10 Jose Eduardo Murillo Garcia joseeduardo.murillo.garcia.contractor@bbva.com
 *             Class creation.
 *  --------------------------------------------------------------------------------------------------
 */
public with sharing class CRMX_InvocableEmailTemplate_Cls {
	/* 
     *  --------------------------------------------------------------------------------------------------
     * @Description Private constructor of the class.
     *  --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     *  --------------------------------------------------------------------------------------------------
     */
    @testVisible
    private CRMX_InvocableEmailTemplate_Cls() {}
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Invocable method to send emails using a classic template. 
     *              Calls the email sending service with the provided list of requests.
     *  --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @param       requests List of email requests.
     * @return      void
     * @example     CRMX_InvocableEmailTemplate_Cls.getInstance().sendEmailTemp(requests);
     *  --------------------------------------------------------------------------------------------------
     */
    @invocableMethod(label='Send Email with Classic Template')
    public static void sendEmailTemp(List<EmailRequest> requests) {
        CRMX_InvocableEmailTemplate_Service.sendEmailTemp(requests);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Inner class to represent the email sending request.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     *  --------------------------------------------------------------------------------------------------
     */
    public class EmailRequest {
        /**
         * @Description Classic email template to be used.
         * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
         */
        @InvocableVariable(label='Classic Email Template' required=true)
        public EmailTemplate emailTemplate;
        /**
         * @Description Executive's name to be used for personalizing the email.
         * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
         */
        @InvocableVariable(label='Executive' required=true)
        public String strExecutive;
        /**
         * @Description Fields of the SObject Account.
         * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
         */
        @InvocableVariable(label='account' required=false)
        public Account objCuenta;
        /**
         * @Description Sender of the Org.
         * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
         */
        @InvocableVariable(label='Sender' required=false)
        public Id strSender;
        /**
         * @Description Email subject to be sent.
         * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
         */
        @InvocableVariable(label='Subject' required=false)
        public String emailSubject;
        /**
         * @Description Recipient email to be sent.
         * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
         */
        @InvocableVariable(label='recipientId' required=true)
        public String recipientId;
    }
}