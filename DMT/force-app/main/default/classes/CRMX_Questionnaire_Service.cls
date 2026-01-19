/**
 * --------------------------------------------------------------------------------------------------
 * @Name       CRMX_Questionnaire_Service
 * @Author     Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date       2025-02-11
 * @Group      Expo
 * --------------------------------------------------------------------------------------------------
 * @Description Service class for managing questionnaires associated with clients.
 * --------------------------------------------------------------------------------------------------
 *  @Changes
 * |2025-02-11  Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 *              Class creation. CRMX_Questionnaire_Data
 * --------------------------------------------------------------------------------------
 */
public with sharing class CRMX_Questionnaire_Service {
    /**
    * @Description: Constant to reference a Visualforce page.
    * @Author: monzerrath.roque.contractor@bbva.com
    */
    private static final String APEX_PAGE_REF ='/apex/CRMX_QuestionnaireReceipt';
    /**
    * @Description: Key para el Id del record actual de cliente.
    * @Author: monzerrath.roque.contractor@bbva.com
    */
    private static final String RECORD_ID ='Id';
    /**
    * @Description: Constant to define the "TRUE" state.
    * @Author: monzerrath.roque.contractor@bbva.com
    */
    private static final Boolean FAIL_ON_ERROR = TRUE;
    /* 
     *  --------------------------------------------------------------------------------------------------
     * @Description Private constructor to prevent the creation of multiple instances of the class.
     *  --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     *  --------------------------------------------------------------------------------------------------
     */
    @testVisible
    private CRMX_Questionnaire_Service() {}
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve or create a questionnaire associated with an account.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-02-11
     * @param       accountId ID of the account.
     * @return      List of CRMX_Regulatory_Questionnaires__c objects.
     * @example     CRMX_Questionnaire_Service.getOrCreateCuestionario(Id account);
     * --------------------------------------------------------------------------------------------------
     */
    public static List<CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper> getQuestionnairesByClient(Id clientId) {
        Final List<CRMX_Regulatory_Questionnaires__c> questionnaireList = CRMX_Questionnaire_Data.getQuestionnairesByClientId(clientId);
        Final List<CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper> questWrapList = new List<CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper>();
        for (CRMX_Regulatory_Questionnaires__c rowQuestion : questionnaireList) {
            questWrapList.add(new CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper(rowQuestion));
        }
        return questWrapList;
    }
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve a questionnaire associated with an account.
     * --------------------------------------------------------------------------------------------------
     *  @Author      Monzerrath Roque Ramos
     * @Date        2025-02-11
     * @param       accountId ID de la cuenta.
     * @return      Record ID of CRMX_Regulatory_Questionnaires__c.
     * @example     CRMX_Questionnaire_Service.getCuestionarioByAccountId(Id account);
     * --------------------------------------------------------------------------------------------------
     */
    public static Id getCuestionarioByAccountId(Id accountId) {
        Final List<CRMX_Regulatory_Questionnaires__c> listCuestionarios = CRMX_Questionnaire_Data.getCuestionariosByAccountId(accountId);
        Id idCuestionario;
        if (!listCuestionarios.isEmpty()) {
            idCuestionario =  listCuestionarios[0].Id;
        }
        return idCuestionario;
    }
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to create a questionnaire associated with an account.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-02-11
     * @param       accountId ID de la cuenta.
     * @return      Record ID of CRMX_Regulatory_Questionnaires__c.
     * @example     CRMX_Questionnaire_Service.createCuestionario(Id account);
     * --------------------------------------------------------------------------------------------------
     */
    public static Id createCuestionario(Id accountId) {
        Final CRMX_Regulatory_Questionnaires__c nuevoCuestionario = new CRMX_Regulatory_Questionnaires__c(CRMX_Client__c = accountId);
        CRMX_DML_Selector.insertRecords(new List<SObject>{nuevoCuestionario}, FAIL_ON_ERROR);
        return getCuestionarioByAccountId(accountId);
    }
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve or create a questionnaire associated with an account.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-02-11
     * @param       accountId ID de la cuenta.
     * @return      Record ID of CRMX_Regulatory_Questionnaires__c.
     * @example     CRMX_Questionnaire_Service.getOrCreateCuestionario(Id account);
     * --------------------------------------------------------------------------------------------------
     */
    public static Id getOrCreateCuestionario(Id accountId) {
        Final Id cuestionarioId = getCuestionarioByAccountId(accountId);
        return (cuestionarioId == null) ? createCuestionario(accountId) : cuestionarioId;
    }
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve or create a questionnaire associated with an account.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-02-11
     * @param       accountId ID of the account.
     * @return      none
     * @example     CRMX_Questionnaire_Service.updateQuestionnaireStatus(Id account);
     * --------------------------------------------------------------------------------------------------
     */
    public static void updateQuestionnaireStatus(Id questionnaireId, String strStatus) {
        Final List<CRMX_Regulatory_Questionnaires__c> questionNaire = CRMX_Questionnaire_Data.getQuestionnaireById(questionnaireId);
        if (!questionNaire.isEmpty()) { 
            questionNaire[0].CRMX_Questionnaire_Status__c = strStatus;
            CRMX_DML_Selector.updateRecords(questionNaire, FAIL_ON_ERROR);
        }
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve the full URL of the PDF file associated with a questionnaire.
     *              The URL points to a Visualforce page that generates the document.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-08
     * @param       recordId ID of the questionnaire record to be downloaded as a PDF.
     * @return      String Full URL of the generated PDF file.
     * @example     String pdfUrl = CRMX_Questionnaire_Service.getPDFUrl(Id recordId);
     * --------------------------------------------------------------------------------------------------
     */
    @AuraEnabled
    public static String getPDFUrl(Id recordId) {
        Final PageReference pdfPage = new PageReference(APEX_PAGE_REF);
        pdfPage.getParameters().put(RECORD_ID, recordId);
        return pdfPage.getUrl();
    }
}