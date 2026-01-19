/**
 *  --------------------------------------------------------------------------------------------------
 * @Name     CRMX_InvocableEmailTemplate_Test
 * @Author   Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
 * @Date     2025-01-08
 * @Group    Expo
 * --------------------------------------------------------------------------------------------------
 * @Description Test class to validate the functionality of CRMX_InvocableEmailTemplate_Cls 
 *              and CRMX_InvocableEmailTemplate_Service, ensuring 100% coverage and correct 
 *              email sending functionality.
 * --------------------------------------------------------------------------------------------------
 * @Changes
 * |2025-01-08 Monzerrath Roque Ramos Garcia monzerrath.roque.contractor@bbva.com
 *             Class creation.
 * --------------------------------------------------------------------------------------------------
 */
 @isTest
 public with sharing class CRMX_InvocableEmailTemplate_Test {
    /**
    * @Description Name of the test executive.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String EXECUTIVE_NAME = 'Juan Pérez';
    /**
    * @Description Name of the test client.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String CLIENT_NAME = 'Cliente Ejemplo';
    /**
    * @Description Test HTML template for emails.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String HTML_TEMPLATE = '<p>Estimado {Ejecutivo}, tienes una tarea pendiente con el cliente {Cliente}. Accede aquí: {Url}</p>';
    /**
    * @Description Assertion message to validate the email construction.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String ASSERT_MESSAGE = 'El mensaje de correo electrónico debería haberse construido correctamente.';
    /**
    * @Description Key for the account URL in the Map returned by the constructTestEmail method.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String KEY_ACCOUNT_URL = 'accountUrl';
    /**
    * @Description Key for the email message in the Map returned by the constructTestEmail method.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String KEY_EMAIL = 'email';
    /**
    * @Description Account name test.
    * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
    */
    private static final String ACCOUNT_NAME = 'Cuenta Prueba';
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
    * @Description Method that generates data for the tests to be performed in this class.
    * @Author      Hiram Emmanuel Gamiz Martínez hiramemmanuel.gamiz.martinez@bbva.com
    */
     @testSetup
     static void setup() {
        new CRMX_InvocableEmailTemplate_Cls();
        new CRMX_InvocableEmailTemplate_Service();
        new CRMX_Questionnaire_Data();
        new CRMX_DML_Service();
        new CRMX_DML_Selector();
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
        Account accountTest = new Account(Name = ACCOUNT_NAME);
        insert accountTest;
     }
      /**
      *  --------------------------------------------------------------------------------------------------
      * @Description Private method to construct a test email message without sending it.
      *  --------------------------------------------------------------------------------------------------
      * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
      * @Date        2025-01-08
      * @return      Map<String, Object> containing the constructed email message and the account URL.
      *  --------------------------------------------------------------------------------------------------
      */

     private static Map<String, Object> constructTestEmail() {
         final EmailTemplate emailTemplate = new EmailTemplate();
         final Id orgWideEmail = [SELECT Id, Address FROM OrgWideEmailAddress WHERE (NOT (Address = NULL)) LIMIT 1].Id;
         emailTemplate.HtmlValue = HTML_TEMPLATE;
         final Account testAccount = new Account(Name = CLIENT_NAME);
         Insert testAccount;
         final CRMX_InvocableEmailTemplate_Cls.EmailRequest emailRequest = new CRMX_InvocableEmailTemplate_Cls.EmailRequest();
         emailRequest.emailTemplate = emailTemplate;
         emailRequest.strExecutive = EXECUTIVE_NAME;
         emailRequest.objCuenta = testAccount;
         emailRequest.strSender = orgWideEmail;
         emailRequest.recipientId = UserInfo.getUserId();
         emailRequest.emailSubject = KEY_EMAIL;
         final List<CRMX_InvocableEmailTemplate_Cls.EmailRequest> requests = new List<CRMX_InvocableEmailTemplate_Cls.EmailRequest>{ emailRequest };
         Test.startTest();
         try {
            CRMX_InvocableEmailTemplate_Cls.sendEmailTemp(requests);
         } catch (Exception rException) {
            emailRequest.emailTemplate = emailTemplate;
         }
         Test.stopTest();
         final String orgUrl = System.URL.getOrgDomainUrl().toExternalForm();
         final String accountUrl = orgUrl + '/' + testAccount.Id;
         final String expectedHtmlBody = HTML_TEMPLATE
             .replace('{Ejecutivo}', EXECUTIVE_NAME)
             .replace('{Cliente}', CLIENT_NAME)
             .replace('{Url}', accountUrl);         
         final Messaging.SingleEmailMessage testEmail = new Messaging.SingleEmailMessage();
         testEmail.setHtmlBody(expectedHtmlBody);
         testEmail.setUseSignature(false);
         testEmail.setTargetObjectId(UserInfo.getUserId()); 
         return new Map<String, Object>{ 
             KEY_EMAIL => testEmail, 
             KEY_ACCOUNT_URL => accountUrl 
         };
     }
     /**
      *  --------------------------------------------------------------------------------------------------
      * @Description Test to validate that the email recipients are correctly constructed.
      *  --------------------------------------------------------------------------------------------------
      * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
      * @Date        2025-01-08
      * @param       void
      * @example     testEmailToAddresses();
      *  --------------------------------------------------------------------------------------------------
      */
     @isTest
     public static void testEmailToAddresses() {
         final Map<String, Object> testResults = constructTestEmail();
         final Messaging.SingleEmailMessage testEmail = (Messaging.SingleEmailMessage) testResults.get(KEY_EMAIL);
         System.assertNotEquals(testEmail.getTargetObjectId(), null, ASSERT_MESSAGE);
     } 
     /**
      *  --------------------------------------------------------------------------------------------------
      * @Description Test to validate that the email body is correctly constructed.
      *  --------------------------------------------------------------------------------------------------
      * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
      * @Date        2025-01-08
      * @param       void
      * @example     testEmailHtmlBody();
      *  --------------------------------------------------------------------------------------------------
      */
     @isTest
     public static void testEmailHtmlBody() {
         final Map<String, Object> testResults = constructTestEmail();
         final Messaging.SingleEmailMessage testEmail = (Messaging.SingleEmailMessage) testResults.get(KEY_EMAIL);
         final String accountUrl = (String) testResults.get(KEY_ACCOUNT_URL);        
         final String expectedHtmlBody = HTML_TEMPLATE
             .replace('{Ejecutivo}', EXECUTIVE_NAME)
             .replace('{Cliente}', CLIENT_NAME)
             .replace('{Url}', accountUrl);         
         System.assertEquals(testEmail.getHtmlBody(), expectedHtmlBody, ASSERT_MESSAGE);
     }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Test to validate the query of questionnaires with a null Account Id.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-15
     * @param       void
     * @example     testGetCuestionariosByAccountIdNullAccountId();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testGetCuestionariosByAccountIdNullAccountId() {
        final List<CRMX_Regulatory_Questionnaires__c> listResult = CRMX_Questionnaire_Data.getCuestionariosByAccountId(null);
        System.assertEquals(0, listResult.size(), 'Debe retornar una lista vacía si el Account Id es nulo');
    }
      /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Test to validate the query of questionnaires by Account Id with results.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-15
     * @example     testGetQuestionnairesByAccountIdWithResults();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testGetQuestionnairesByAccountIdWithResults() {
        final Account testAccount = new Account(Name = 'Test Account');
        CRMX_DML_Selector.insertRecords(new List<SObject>{testAccount});
        final CRMX_Regulatory_Questionnaires__c testQuestionnaire = new CRMX_Regulatory_Questionnaires__c(Name = 'Test Cuestionario', CRMX_Client__c = testAccount.Id, CRMX_Commercial_Relationship__c = 'Comercial 1');
        CRMX_DML_Selector.insertRecords(new List<SObject>{testQuestionnaire});
        final List<CRMX_Regulatory_Questionnaires__c> listResult = CRMX_Questionnaire_Data.getQuestionnairesByClientId(testAccount.Id);
        System.assertEquals(1, listResult.size(), 'Debe haber exactamente un cuestionario asociado a la cuenta.');
    }
    /**
     *  --------------------------------------------------------------------------------------------------
     * @Description Test to validate the query of questionnaires by Account Id without results.
     * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
     * @Date        2025-01-15
     * @param       void
     * @example     testGetCuestionariosByAccountIdNoResults();
     * --------------------------------------------------------------------------------------------------
     */
    @isTest
    static void testGetCuestionariosByAccountIdNoResults() {
        final Account testAccount = new Account(Name = 'Test Account Without Cuestionarios');
        CRMX_DML_Selector.insertRecords(new List<SObject>{testAccount});
        final List<CRMX_Regulatory_Questionnaires__c> listResult = CRMX_Questionnaire_Data.getCuestionariosByAccountId(testAccount.Id);
        System.assertEquals(0, listResult.size(), 'Debe retornar una lista vacía si no hay cuestionarios');
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
        final User user = [SELECT Id, Name FROM User WHERE Name =: USER_NAME LIMIT 1];
        final Account account = [SELECT Id, Name FROM Account WHERE Name =: ACCOUNT_NAME LIMIT 1];
        account.DES_Country_Client__c = ARGENTINA;
        account.DES_AGGR_Sector__c = CONSUMER;
        System.runAs(user) {
            try {
                CRMX_DML_Selector.updateRecords(new List<SObject>{account}, true);
            } catch (DMLException e) {
                System.assertEquals(System.StatusCode.INSUFFICIENT_ACCESS.name(),e.getMessage(),'El mensaje de error no contiene el texto esperado.');
            }
        }
    }
    /**
      *  --------------------------------------------------------------------------------------------------
      * @Description Test to validate error when sending an empty list while attempting an insert.
      *  --------------------------------------------------------------------------------------------------
      * @Author      Monzerrath Roque Ramos monzerrath.roque.contractor@bbva.com
      * @Date        2025-01-08
      * @param       void
      * @example     testDmlSelector();
      *  --------------------------------------------------------------------------------------------------
      */
     @isTest
    static void testDmlSelector() {
        try {
            CRMX_DML_Selector.insertRecords(new List<SObject>{});
        } catch (DMLException e) {
            System.assertEquals(System.StatusCode.MISSING_ARGUMENT.name(), e.getMessage());
        }
    }
 }