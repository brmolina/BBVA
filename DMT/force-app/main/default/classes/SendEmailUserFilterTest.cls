@isTest
private class SendEmailUserFilterTest {

    @testSetup
    static void setup() {
        // Configura los datos iniciales necesarios para las pruebas
        Id consultantITProfileId = [SELECT Id FROM Profile WHERE Name = 'Consultation IT' LIMIT 1].Id;
        Id arceRolId = [SELECT Id FROM UserRole WHERE Name ='ARCE' LIMIT 1].Id;
        Id userLicense=[SELECT Id, Name from UserLicense where Name ='Salesforce'].Id;

        // Crea usuarios de prueba
        List<User> users = new List<User>();
        
        User userRiesgos = new User(
            FirstName = 'Riesgo', LastName = 'User', Alias = 'rsgo',
            Email = 'riesgo@bbva.com', Username = 'riesgo@bbva.com', 
            ProfileId = consultantITProfileId, isActive = true,
            ID_User__c = 'RUserESP',
            //Profile.UserLicenseId =userLicense,
            UserRoleId = arceRolId, DES_Country__c = 'ESP',
            EmailEncodingKey = 'UTF-8', Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US', languagelocalekey = 'en_US'
        );
        
        User userNegocioESP = new User(
            FirstName = 'Negocio', LastName = 'User', Alias = 'ngc',
            Email = 'negocio@bbva.com', Username = 'negocio@bbva.com',
            ProfileId = consultantITProfileId, isActive = true,
            ID_User__c = 'NUserESP',
            UserRoleId = null, DES_Country__c = 'ESP',
            //Profile.UserLicenseId =userLicense,
            EmailEncodingKey = 'UTF-8', Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US', languagelocalekey = 'en_US'
        );
        User userNegocioALB = new User(
            FirstName = 'Negocio ALB', LastName = 'User', Alias = 'ngc_ALB',
            Email = 'negocioALB@bbva.com', Username = 'negocioALB@bbva.com',
            ProfileId = consultantITProfileId, isActive = true,
            //Profile.UserLicenseId =userLicense,
            ID_User__c = 'NUserALB',
            UserRoleId = null, DES_Country__c = 'ALB',
            EmailEncodingKey = 'UTF-8', Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US', languagelocalekey = 'en_US'
        );

        User userInvalid = new User(
            FirstName = 'Invalid', LastName = 'User', Alias = 'inv',
            Email = 'invalid@bbva.com.invalid', Username = 'invalid@bbva.com',
            ProfileId = consultantITProfileId, isActive = true,
            //Profile.UserLicenseId =userLicense,
            ID_User__c = 'InUserESP',
            UserRoleId = null, DES_Country__c = 'ESP',
            EmailEncodingKey = 'UTF-8', Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US', languagelocalekey = 'en_US'
        );

        users.add(userRiesgos);
        users.add(userNegocioESP);
        users.add(userNegocioALB);
        users.add(userInvalid);
        insert users;

        // Crea una plantilla de correo electrónico
        EmailTemplate et = new EmailTemplate(
            isActive = true,
            Name = 'emailTemplateTest',
            DeveloperName = 'emailTemplateTest',
            TemplateType = 'text',
            HtmlValue = '<p> Test<p>',
            FolderId = UserInfo.getUserId()
        );
        insert et;
        EmailTemplate etWithOutHTML = new EmailTemplate(
            isActive = true,
            Name = 'emailTemplateWithoutHTML',
            DeveloperName = 'emailTemplateWithoutHTML',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert etWithOutHTML;
    }

    // Prueba para el método getEmailTemplates
    @isTest
    static void testGetEmailTemplates() {
        Test.startTest();
        List<EmailTemplate> templates = SendEmailUserFilter.getEmailTemplates();
        Test.stopTest();
        // Verifica que se obtengan plantillas activas y que el nombre coincida
        Assert.isTrue(!templates.isEmpty(), 'Debería haber al menos una plantilla de correo activa');
        integer countEt = 0;
        for (EmailTemplate et : templates) {
            if (et.Name=='emailTemplateTest') {
                countEt++;
            }
        }
        Assert.isTrue(countEt>0);
    }

    // Prueba para el método getTemplateContentById con HTMLValue
    @isTest
    static void testGetTemplateContentById() {
        // Obtiene la plantilla creada en setup
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
        Test.startTest();
        String content = SendEmailUserFilter.getTemplateContentById(template.Id);
        Test.stopTest();
        // Llama al método y verifica el contenido
        //String content = SendEmailUserFilter.getTemplateContentById(template.Id);
        Assert.isFalse(content==null, 'El contenido de la plantilla no debería ser nulo');
    }

    // Prueba para el método getTemplateContentById sin HTMLValue
    @isTest
    static void testGetTemplateContentByIdWithOutHTML() {
        // Obtiene la plantilla creada en setup
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateWithoutHTML' LIMIT 1];
        Test.startTest();
        String content = SendEmailUserFilter.getTemplateContentById(template.Id);
        Test.stopTest();
        // Llama al método y verifica el contenido
        //String content = SendEmailUserFilter.getTemplateContentById(template.Id);
        Assert.areEqual('', content, 'El contenido de la plantilla debería ser vacio');
    }

    // Prueba para el método sendEmails con userType = Negocio y Countries = ESP
    @isTest
    static void testSendEmailsNegocio() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
        
        // Configura los parámetros para llamar a sendEmails
        String userType = 'Negocio';
        List<String> countries = new List<String>{'ESP'};
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, userType, countries);
        Test.stopTest();

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"'); 
    }
    // Prueba para el método sendEmails con tipo "Riesgos" y Countries = 'ESP'
    @isTest
    static void testSendEmailsRiesgos() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];

        // Configura los parámetros para llamar a sendEmails
        String userType = 'Riesgos';
        List<String> countries = new List<String>{'ESP'};
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, userType, countries);
        Test.stopTest();

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"'); 
    }
    // Prueba para el método sendEmails con userType = null y Countries = 'ESP'
    @isTest
    static void testSendEmailsWithOutUserType() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
        
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{'ESP'};
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;

        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, null, countries);
        Test.stopTest();
        
        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"'); 
    }
    // Prueba para el método sendEmails con userType = null y Countries = 'ESP', 'ALB'
    @isTest
    static void testSendEmailsWithOutUserTypeAndWithTwoCountries() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
    
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{'ESP', 'ALB'};
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;

        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, null, countries);
        Test.stopTest();
        

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"'); 
    }
    // Prueba para el método sendEmails con userType = Negocio  y Countries = null
    @isTest
    static void testSendEmailsNegocioWithOutCountries() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
        String userType = 'Negocio';
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{}; 
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;

        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, userType, countries);
        Test.stopTest();
        

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');  
    }

    // Prueba para el método sendEmails con userType = Riesgos  y Countries = null
    @isTest
    static void testSendEmailsRiesgosWithOutCountries() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
        String userType = 'Riesgos';
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{};
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;

        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, userType, countries);
        Test.stopTest();
        
        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"'); 
     }
  
    // Prueba para el método sendEmails con userType = null y Countries = null
    @isTest
    static void testSendEmailsWithOutUserTypeAndWithOutCountries() {
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email from User Where UserName IN ('riesgo@bbva.com','negocio@bbva.com','invalid@bbva.com','negocioALB@bbva.com') AND Profile.UserLicense.Name='Salesforce' ORDER BY Name];

        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE Name = 'emailTemplateTest' LIMIT 1];
        
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{};
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP =testUser[2].Id;
        String userRiesgos = testUser[3].Id;

        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, null, countries);
        Test.stopTest();
        
        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size()==0, 'No deberia haber errores');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(SendEmailUserFilter.userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP'); 
        Assert.isFalse(SendEmailUserFilter.userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"'); 
    }
   
    // Prueba para el método getCountryPicklistValues
    @isTest
    static void testGetCountryPicklistValues() {
        Test.startTest();
        List<Map<String, String>> countryValues = SendEmailUserFilter.getCountryPicklistValues();
        Test.stopTest();
        Assert.isTrue(!countryValues.isEmpty(), 'La lista de valores de países no debería estar vacía');
        Boolean found = false;
        for (Map<String, String> country : countryValues) {
            if (country.get('value') == 'ESP') {
                found = true;
                break;
            }
        }
        Assert.isTrue(found, 'Debería incluir la opción de país ESP en los valores de la lista');
    }

}