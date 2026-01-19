/**
 * --------------------------------------------------------------------------------------------------
 * @Name       CRMX_Questionnaire_Ctrl
 * @Author     Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date       2025-01-08
 * @Group      Expo
 * --------------------------------------------------------------------------------------------------
 * @Description Class for handling the creation and retrieval of questionnaires associated with clients.
 * --------------------------------------------------------------------------------------------------
 * @Changes
 * |2025-01-08 Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 *             Class creation.
 * --------------------------------------------------------------------------------------------------
 */
public with sharing class CRMX_Questionnaire_Ctrl {
    /**
    * @Description: Variable used to manage DML operations with error handling.
    * @Author: Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final Boolean FAIL_ON_ERROR = true;
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Private constructor to prevent multiple instances of the class.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-15
     * @param       void
     * @param       void
     * @example     CRMX_Questionnaire_Ctrl();
     *  --------------------------------------------------------------------------------------------------
     */
    @testVisible
    private CRMX_Questionnaire_Ctrl() {}
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Method to retrieve or create a questionnaire associated with a specific account. 
     *              If a questionnaire already exists for the account, it returns its ID. 
     *              If not, it creates a new one and returns the ID of the newly created questionnaire.
     * --------------------------------------------------------------------------------------------------
     * @Author      Monzerrath Roque Ramos
     * @Date        2025-01-08
     * @param       accountId Account ID for which the questionnaire is retrieved or created.
     * @return      ID of the questionnaire found or created.
     * @example     CRMX_Questionnaire_Ctrl.getOrCreateCuestionario(Id accountId);
     *  --------------------------------------------------------------------------------------------------
     */
    @AuraEnabled
    public static Id getOrCreateCuestionario(Id accountId) {
        return CRMX_Questionnaire_Service.getOrCreateCuestionario(accountId);
    }
}