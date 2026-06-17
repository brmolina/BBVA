/**
 *  --------------------------------------------------------------------------------------------------
 * @Name       CRMX_QuestionnaireBoard_Test
 * @Author     Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date       2025-01-08
 * @Group      Expo
 * --------------------------------------------------------------------------------------------------
 * @Description Test class to validate the correct functionality of the 
 *              CRMX_Questionnaire_Ctrl and CRMX_QuestionnaireBoard_Ctrl classes.
 *              Ensures 100% code coverage and proper functionality in questionnaire handling.
 * --------------------------------------------------------------------------------------------------
 * @Changes
 * |2025-01-08 Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 *             Class creation.
 * --------------------------------------------------------------------------------------------------
 */
@isTest
    private with sharing class CRMX_QuestionnaireBoard_Test {
    /**
     * @Description Test account name to associate with the questionnaire.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String CLIENT_NAME = 'Cuenta Prueba';
    /**
     * @Description Test questionnaire status "PENDING".
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String PENDING = 'PENDING';
    /**
     * @Description Test questionnaire status "COMPLETED".
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String COMPLETED = 'COMPLETED';
    /**
     * @Description Test questionnaire status "SENT".
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String SENT = 'SENT';
	/**
     * @Description Test client number to associate with the questionnaire.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String NO_CLIENTE = 'EM890531';
    /**
     * @Description Error message to display if the questionnaire is null.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_NOT_NULL = 'El cuestionario no debe ser nulo.';
    /**
     * @Description Error message to display in case of duplicates.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_NOT_DUPE = 'No debe crear cuestionarios duplicados.';
    /**
     * @Description RecordType of the test account to relate to the questionnaire.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String CLIENT_RECTYPE = 'DES_Subsidiary_Commercial_Client';
    /**
     * @Description sObject of the test account to relate to the questionnaire.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String SOBJECT_TYPE = 'Account';
    /**
     * @Description Test account ID to relate to the questionnaire.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static Id testAccountId;
    /**
     * @Description Exception message if the URL does not contain the questionnaire ID.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_ID_CHAIN = 'La URL debe incluir el ID del cuestionario.';
    /**
     * @Description Exception message if the questionnaire does not match the ID.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_WRAPPED_ID = 'El ID del cuestionario debe coincidir.';
    /**
     * @Description Exception message if the questionnaire status is not "SENT".
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_STATUS = 'El estado debería ser COMPLETED.';   
    /**
     * @Description Exception message if the client name does not match.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_WRAPPED_NM = 'El nombre del cliente debe coincidir.';
    /**
     * @Description Exception message if the questionnaire status is not "Pendiente".
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_WRAPPED_STS = 'El estado del cuestionario debe ser Pendiente.';
    /**
     * @Description Exception message when the list is empty.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final String QUEST_GET = 'La lista de cuestionarios no debe estar vacía.';
     /**
     * @Description Reusable constant for the query limit.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    private static final Integer LIMIT_ONE = 1;
    /**
    * @Description Value for the country field.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String ARGENTINA = 'Argentina';
    /**
    * @Description Value for the consumer field.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String CONSUMER = 'Consumer';
    /**
    * @Description User ID.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String USER_ID = '1234567';
    /**
    * @Description User's first name.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String FIRST_NAME = 'Test';
    /**
    * @Description User's last name.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String LAST_NAME = 'User';
    /**
    * @Description User's email.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String EMAIL = 'test.user.validate@example.com';
    /**
    * @Description User's alias.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String ALIAS = 'valuser';
    /**
    * @Description User's time zone.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String TIME_KEY = 'America/Mexico_City';
    /**
    * @Description User's locale.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String LOCAL = 'es_MX';
    /**
    * @Description User's encoding.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String ENCODING = 'UTF-8';
    /**
    * @Description User's language.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String LANGUAGE = 'es';
    /**
    * @Description User's profile name.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String PROFILE_NAME = 'Standard User';
    /**
    * @Description User's name.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String USER_NAME = 'Test User';
    /**
     * @Description Method that creates data for the tests in this class.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     */
    @testSetup 
    static void setup() {
        new CRMX_QuestionnaireBoard_Ctrl();
    	new CRMX_Questionnaire_Ctrl();
        new CRMX_Questionnaire_Data();
        new CRMX_Questionnaire_Service();
        new CRMX_DML_Selector();
        new CRMX_DML_Service();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PROFILE_NAME LIMIT 1];
        final User userTest = new User(
            FirstName = FIRST_NAME,
            LastName = LAST_NAME,
            Email = EMAIL,
            Username = EMAIL,
            Alias = ALIAS,
            TimeZoneSidKey = TIME_KEY,
            LocaleSidKey = LOCAL,
            EmailEncodingKey = ENCODING,
            LanguageLocaleKey = LANGUAGE,
            ID_User__c = USER_ID,
            ProfileId = profile.Id
        );
        insert userTest;
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = :SOBJECT_TYPE AND DeveloperName = :CLIENT_RECTYPE LIMIT 1].Id;
        final Account testAccount    = new Account();
		testAccount.Name             = CLIENT_NAME;
		testAccount.g_customer_id__c   = NO_CLIENTE;
		testAccount.RecordTypeId     = recordTypeId;
        insert testAccount;
        testAccountId = testAccount.Id;
        Final CRMX_Regulatory_Questionnaires__c testQuestionnaire = new CRMX_Regulatory_Questionnaires__c(
            CRMX_Client__c = testAccount.Id,
            CRMX_Questionnaire_Status__c = PENDING);
        insert testQuestionnaire;
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates the functionality to retrieve or create a questionnaire associated with an account.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testGetOrCreateCuestionario();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testGetOrCreateCuestionario() {
        Final Id questionnaireId = CRMX_Questionnaire_Ctrl.getOrCreateCuestionario(testAccountId);
        System.assertNotEquals(questionnaireId, null, QUEST_NOT_NULL);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates the functionality to retrieve or create a questionnaire without duplicates.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testGetOrCreateCuestionarioNoDuplicates();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testGetOrCreateCuestionarioNoDuplicates() {
        Final Id questionnaireId = CRMX_Questionnaire_Ctrl.getOrCreateCuestionario(testAccountId);
        Final Id duplicateId = CRMX_Questionnaire_Ctrl.getOrCreateCuestionario(testAccountId);
        System.assertEquals(duplicateId, questionnaireId, QUEST_NOT_DUPE);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates that the generated URL for the questionnaire PDF is correct.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testGetPDFUrl();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testGetPDFUrl() {
        Final CRMX_Regulatory_Questionnaires__c testQuestionnaire = new CRMX_Regulatory_Questionnaires__c( CRMX_Client__c = testAccountId, CRMX_Questionnaire_Status__c = COMPLETED);
        insert testQuestionnaire;
        Final String pdfUrl = CRMX_QuestionnaireBoard_Ctrl.getPDFUrl(testQuestionnaire.Id);
        System.assert(pdfUrl.contains(testQuestionnaire.Id), QUEST_ID_CHAIN);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates that the status of a questionnaire is updated correctly.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testUpdateQuestionnaireStatus();
     * --------------------------------------------------------------------------------------------------
     */
   @isTest
    static void testUpdateQuestionnaireStatus() {
        final CRMX_Regulatory_Questionnaires__c testQuestionnaire = [SELECT Id FROM CRMX_Regulatory_Questionnaires__c LIMIT 1];
        CRMX_QuestionnaireBoard_Ctrl.updateQuestionnaireStatus(testQuestionnaire.Id, 'COMPLETED');
        final CRMX_Regulatory_Questionnaires__c updatedQuestionnaire = [SELECT CRMX_Questionnaire_Status__c FROM CRMX_Regulatory_Questionnaires__c WHERE Id = :testQuestionnaire.Id];
        System.assertEquals('COMPLETED', updatedQuestionnaire.CRMX_Questionnaire_Status__c, QUEST_STATUS);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates that the QuestionnaireWrapper constructor correctly assigns the values of the ID.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testQuestionnaireWrapperConstructorId();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testQuestionnaireWrapperConstructorId() {
        Final CRMX_Regulatory_Questionnaires__c testQuestionnaire = [SELECT Id, CRMX_Questionnaire_Status__c, CRMX_Client__r.Name, CRMX_Commercial_Relationship__c, LastModifiedDate FROM CRMX_Regulatory_Questionnaires__c LIMIT :LIMIT_ONE];
        Final CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper objWrapper = new CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper(testQuestionnaire);
        System.assertEquals(testQuestionnaire.Id, objWrapper.questionnaireId,QUEST_WRAPPED_ID);
    }
     /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates that the QuestionnaireWrapper constructor correctly assigns the values of the Name.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testQuestionnaireWrapperConstructorName();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testQuestionnaireWrapperConstructorName() {
        Final CRMX_Regulatory_Questionnaires__c testQuestionnaire = [SELECT Id, CRMX_Questionnaire_Status__c, CRMX_Client__r.Name, CRMX_Commercial_Relationship__c, LastModifiedDate FROM CRMX_Regulatory_Questionnaires__c LIMIT :LIMIT_ONE];
        Final CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper objWrapper = new CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper(testQuestionnaire);
        System.assertEquals(testQuestionnaire.CRMX_Client__r.Name, objWrapper.clientName,QUEST_WRAPPED_NM);
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates that the QuestionnaireWrapper constructor correctly assigns the values of STS.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testQuestionnaireWrapperConstructorSTS();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testQuestionnaireWrapperConstructorSTS() {
        Final CRMX_Regulatory_Questionnaires__c testQuestionnaire = [SELECT Id, CRMX_Questionnaire_Status__c, CRMX_Client__r.Name, CRMX_Commercial_Relationship__c, LastModifiedDate FROM CRMX_Regulatory_Questionnaires__c LIMIT :LIMIT_ONE];
        Final CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper objWrapper = new CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper(testQuestionnaire);
        System.assertEquals(PENDING, objWrapper.strStatus,QUEST_WRAPPED_STS);
    }
     /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Validates that the getQuestionnaires method correctly retrieves the questionnaires.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-08
     * @example     testGetQuestionnairesBasic();
     **/
    @isTest
    static void testGetQuestionnairesBasic() {
        Final Account testAccount = [SELECT Id FROM Account WHERE g_customer_id__c = :NO_CLIENTE LIMIT :LIMIT_ONE];
        Final List<CRMX_QuestionnaireBoard_Ctrl.QuestionnaireWrapper> listWrappers = CRMX_QuestionnaireBoard_Ctrl.getQuestionnaires(testAccount.Id);
        System.assertNotEquals(true, listWrappers == null || listWrappers.isEmpty(), QUEST_GET);
    }
    /**
      *  --------------------------------------------------------------------------------------------------
      * @Description Test for performing a failed update on a record with FLS validation.
      *  --------------------------------------------------------------------------------------------------
      * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
      * @Date        2025-01-08
      * @param       void
      * @example     test_validateAccess();
      *  --------------------------------------------------------------------------------------------------
      */
    @isTest
    static void test_validateAccess() {
        boolean isException = false;
        try {
            CRMX_DML_Selector.insertRecords(new List<SObject>{});
        } catch (DMLException e) {
            isException = true;
        }
        final User user = [SELECT Id, Name FROM User WHERE Name =: USER_NAME LIMIT 1];
        final Account account = [SELECT Id, Name FROM Account WHERE Name =: CLIENT_NAME LIMIT 1];
        account.DES_Country_Client__c = ARGENTINA;
        account.DES_AGGR_Sector__c = CONSUMER;
        System.runAs(user) {
            try {
                CRMX_DML_Selector.updateRecords(new List<SObject>{account}, true);
            } catch (DMLException e) {
                isException = true;
            }
            System.assert(isException, 'An exception should be thrown.');
        }
    }
}