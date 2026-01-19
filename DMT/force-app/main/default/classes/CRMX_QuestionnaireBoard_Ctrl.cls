/**
 * --------------------------------------------------------------------------------------------------
 * @Name     CRMX_QuestionnaireBoard_Ctrl
 * @Author   Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date     2025-01-08
 * @Group    Expo
 * --------------------------------------------------------------------------------------------------
 * @Description Class to handle the COMPLETED questionnaire receipt and its download as a PDF file.
 * --------------------------------------------------------------------------------------------------
 * @Changes
 * |2025-01-08 Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 *             Class creation.
 *  --------------------------------------------------------------------------------------------------
 */
public with sharing class CRMX_QuestionnaireBoard_Ctrl {
    /**
    * @Description: Constant to define the "COMPLETED" status of the questionnaire.
    * @Author: monzerrath.roque.contractor@bbva.com
    */
    private static final String COMPLETED = 'COMPLETED';
    /* 
     *  --------------------------------------------------------------------------------------------------
     * @Description Private constructor to prevent the creation of multiple instances of the class.
     *  --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     *  --------------------------------------------------------------------------------------------------
     */
    @testVisible
    private CRMX_QuestionnaireBoard_Ctrl() {}
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve the list of questionnaires associated with a specific client.
     *              Returns a list of wrapped objects (`QuestionnaireWrapper`) containing the relevant 
     *              information for the LWC.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-08
     * @param       clientId ID of the client to search for associated questionnaires.
     * @return      List<CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper> List of wrapped questionnaires with the required details.
     * @example     CRMX_QuestionnaireBoard_Ctrl.getQuestionnaires('001XXXXXXXXXXXXXXX');
     *  --------------------------------------------------------------------------------------------------
     */
    @AuraEnabled(cacheable=true)
    public static List<CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper> getQuestionnaires(String clientId) {
        return CRMX_Questionnaire_Service.getQuestionnairesByClient(clientId);
    }
	/**
     *  --------------------------------------------------------------------------------------------------
     * @Description Method to update the status of a specific questionnaire.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-16
     * @param       questionnaireId ID of the questionnaire to be updated.
     * @param       strStatus New status to be assigned to the questionnaire.
     * @return      void
     * @example     CRMX_QuestionnaireBoard_Ctrl.updateQuestionnaireStatus('a0BXXXXXXXXXXXXXX', 'COMPLETED');
     *  --------------------------------------------------------------------------------------------------
     */
    @AuraEnabled
    public static void updateQuestionnaireStatus(Id questionnaireId, String strStatus) {
        CRMX_Questionnaire_Service.updateQuestionnaireStatus(questionnaireId, strStatus);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Method to obtain the full URL of the PDF file associated with a questionnaire.
     *              The URL points to a Visualforce page that generates the receipt.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-08
     * @param       recordId ID of the questionnaire record to be downloaded as a PDF.
     * @return      String Full URL of the generated PDF file.
     * @example     String pdfUrl = CRMX_QuestionnaireBoard_Ctrl.getPDFUrl(Id recordId);
     *  --------------------------------------------------------------------------------------------------
     */
    @AuraEnabled
    public static String getPDFUrl(Id recordId) {
        return URL.getOrgDomainUrl().toExternalForm() + CRMX_Questionnaire_Service.getPDFUrl(recordId);
    }
	/**
     *  --------------------------------------------------------------------------------------------------
     * @Description Internal class to encapsulate questionnaire information. Provides the necessary data for display in the LWC.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-08
     * --------------------------------------------------------------------------------------------------
     */
    public class QuestionnaireWrapper {
        /**
         * @Description Unique identifier of the questionnaire.
         */
        @AuraEnabled public String questionnaireId { get; set; }
        /**
         * @Description Name of the client associated with the questionnaire.
         */
        @AuraEnabled public String clientName { get; set; }
        /**
         * @Description Business group linked to the questionnaire.
         */
        @AuraEnabled public String linkedGroup { get; set; }
        /**
         * @Description Current status of the questionnaire.
         */
        @AuraEnabled public String strStatus { get; set; }
        /**
         * @Description Indicates whether the questionnaire can be downloaded.
         */
        @AuraEnabled public Boolean canDownload { get; set; }
        /**
         * @Description Last modified date of the questionnaire.
         */
        @AuraEnabled public Datetime lastModifiedDate { get; set; }
        /**
         * --------------------------------------------------------------------------------------------------
         * @Description Constructor that takes a questionnaire record and converts it into a `QuestionnaireWrapper` object.
         * --------------------------------------------------------------------------------------------------
         * @Author      Monzerrath Roque Ramos
         * @Date        2025-01-08
         * @param       questionNaire Questionnaire record (`CRMX_Regulatory_Questionnaires__c`).
         * @return      QuestionnaireWrapper Wrapped object with the relevant information.
         * @example     new QuestionnaireWrapper(questionNaire);
         * --------------------------------------------------------------------------------------------------
         */

    public QuestionnaireWrapper(CRMX_Regulatory_Questionnaires__c questionNaire) {
        this.questionnaireId = questionNaire.Id;
        this.clientName = questionNaire.CRMX_Client__r.Name;
        this.linkedGroup = questionNaire.CRMX_Commercial_Relationship__c;
        this.strStatus = questionNaire.CRMX_Questionnaire_Status__c;
        this.canDownload = questionNaire.CRMX_Questionnaire_Status__c == COMPLETED;
        this.lastModifiedDate = questionNaire.LastModifiedDate;
        }
    }
}