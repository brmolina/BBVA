/**
 *  --------------------------------------------------------------------------------------------------
 * @Name       CRMX_Questionnaire_Data
 * @Author     Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date       2025-01-10
 * @Group      Expo
 * --------------------------------------------------------------------------------------------------
 * @Description This class serves as a selector to securely query regulatory questionnaires associated
 *              with a client or by ID. It uses a wrapper class to encapsulate the data and ensure 
 *              controlled access to the database, respecting user permissions. 
 * ---------------------------------------------------------------------------------------------------
 *  * @Changes
 * |2025-01-15  Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 *              Class creation. CRMX_Questionnaire_Data
 * ----------------------------------------------------------------------------------------------------
 */ 
public with sharing class CRMX_Questionnaire_Data {
    /**
    * @Description: Variable to enforce a limit of one in the query.
    * @Author:      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final Integer QUERY_LIMIT = 1;
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Private constructor to prevent the creation of class instances.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-15
     * @param       void
     * @example     CRMX_Questionnaire_Data();
     *  --------------------------------------------------------------------------------------------------
     */
    @testVisible
    private CRMX_Questionnaire_Data() {}    
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to securely retrieve questionnaires associated with a client.
     * ---------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-15
     * @param       clientId ID del cliente relacionado al cuestionario.
     * @return      Returns a list of CRMX_Regulatory_Questionnaires__c objects: questionnaireList.
     * @example     CRMX_Questionnaire_Data.getQuestionnairesByClientId(String clientId);
     * --------------------------------------------------------------------------------------------------
     */
    public static List<CRMX_Regulatory_Questionnaires__c> getQuestionnairesByClientId(String clientId) {
        return CRMX_DML_Selector.secureQuery([SELECT Id, CRMX_Client__r.Name, CRMX_Commercial_Relationship__c, CRMX_Questionnaire_Status__c, LastModifiedDate FROM CRMX_Regulatory_Questionnaires__c WHERE CRMX_Client__c = :clientId AND (NOT ID = null)]);
    }
    /**
     * --------------------------------------------------------------------------------------------------
     * @Description Method to securely retrieve a questionnaire by its ID, 
     *              validating field access permissions before executing the query.
     * ---------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-15
     * @param       questionnaireId ID del cuestionario.
     * @return      Devuelve una lista de objetos CRMX_Regulatory_Questionnaires__c
     * @example     CRMX_Questionnaire_Data.getQuestionnaireById(String questionnaireId);
     * --------------------------------------------------------------------------------------------------
     */
    public static List<CRMX_Regulatory_Questionnaires__c> getQuestionnaireById(String questionnaireId) {
        return CRMX_DML_Selector.secureQuery([SELECT Id, CRMX_Questionnaire_Status__c FROM CRMX_Regulatory_Questionnaires__c WHERE Id = :questionnaireId AND (NOT ID = null) LIMIT :QUERY_LIMIT]);
    }
    /** 
     *  -------------------------------------------------------------------------------------------------
     * @Description Method to securely query questionnaires associated with an account, 
     *              validating field access permissions before executing the query.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-10
     * @param       accountId ID of the account associated with the questionnaires.
     * @return      List<CRMX_Regulatory_Questionnaires__c> List of associated questionnaires.
     * @example     List<CRMX_Regulatory_Questionnaires__c> questionnaires =
     *              CRMX_Questionnaire_Data.getCuestionariosByAccountId(Id accountId);
     * ---------------------------------------------------------------------------------------------------
     **/
    public static List<CRMX_Regulatory_Questionnaires__c> getCuestionariosByAccountId(Id accountId) {
        return CRMX_DML_Selector.secureQuery([SELECT Id, CRMX_Client__c, Name, CRMX_Questionnaire_Status__c, CreatedDate FROM CRMX_Regulatory_Questionnaires__c WHERE CRMX_Client__c = :accountId AND CreatedDate <= TODAY]);
    }
}