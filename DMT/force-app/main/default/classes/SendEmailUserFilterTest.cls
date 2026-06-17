@isTest
private class SendEmailUserFilterTest{
    @testSetup
    static void setup(){
        // Configura los datos iniciales necesarios para las pruebas
        Id consultantITProfileId = [SELECT Id
                                    FROM Profile
                                    WHERE Name = 'Consultation IT'
                                    LIMIT 1].Id;
        Id arceRolId = [SELECT Id
                        FROM UserRole
                        WHERE Name = 'ARCE'
                        LIMIT 1].Id;
        Id userLicense = [SELECT Id, Name
                          from UserLicense
                          where Name = 'Salesforce'].Id;

        // Crea usuarios de prueba
        List<User> users = new List<User>();

        User userRiesgos = new User(
            FirstName = 'Riesgo', 
            LastName = 'User', 
            Alias = 'rsgo', 
            Email = 'riesgo@bbva.com', 
            Username = 'riesgo@bbva.com', 
            ProfileId = consultantITProfileId, 
            isActive = true, 
            ID_User__c = 'RUserESP', 
            //Profile.UserLicenseId =userLicense,
            UserRoleId = arceRolId, 
            DES_Country__c = 'ESP', 
            EmailEncodingKey = 'UTF-8', 
            Timezonesidkey = 'Europe/London', 
            Localesidkey = 'en_US', 
            languagelocalekey = 'en_US', 
            DES_LevelUO_1__c = '00003906', 
            DES_LevelUO_5__c = '00011823'
        );

        User userNegocioESP = new User(
            FirstName = 'Negocio', 
            LastName = 'User', 
            Alias = 'ngc', 
            Email = 'negocio@bbva.com', 
            Username = 'negocio@bbva.com', 
            ProfileId = consultantITProfileId, 
            isActive = true, 
            ID_User__c = 'NUserESP', 
            UserRoleId = null, 
            DES_Country__c = 'ESP', 
            //Profile.UserLicenseId =userLicense,
            EmailEncodingKey = 'UTF-8', 
            Timezonesidkey = 'Europe/London', 
            Localesidkey = 'en_US', 
            languagelocalekey = 'en_US', 
            DES_LevelUO_1__c = '00003906', 
            DES_LevelUO_6__c = '00080132'

        );
        User userNegocioALB = new User(
            FirstName = 'Negocio ALB', 
            LastName = 'User', 
            Alias = 'ngc_ALB', 
            Email = 'negocioALB@bbva.com', 
            Username = 'negocioALB@bbva.com', 
            ProfileId = consultantITProfileId, 
            isActive = true, 
            //Profile.UserLicenseId =userLicense,
            ID_User__c = 'NUserALB', 
            UserRoleId = null, 
            DES_Country__c = 'ALB', 
            EmailEncodingKey = 'UTF-8', 
            Timezonesidkey = 'Europe/London', 
            Localesidkey = 'en_US', 
            languagelocalekey = 'en_US', 
            DES_LevelUO_1__c = '00003906', 
            DES_LevelUO_6__c = '00080132'
        );

        User userInvalid = new User(
            FirstName = 'Invalid', 
            LastName = 'User', 
            Alias = 'inv', 
            Email = 'invalid@bbva.com.invalid', 
            Username = 'invalid@bbva.com', 
            ProfileId = consultantITProfileId, 
            isActive = true, 
            //Profile.UserLicenseId =userLicense,
            ID_User__c = 'InUserESP', 
            UserRoleId = null, 
            DES_Country__c = 'ESP', 
            EmailEncodingKey = 'UTF-8', 
            Timezonesidkey = 'Europe/London', 
            Localesidkey = 'en_US', 
            languagelocalekey = 'en_US', 
            DES_LevelUO_1__c = '00003906', 
            DES_LevelUO_6__c = '00080132'
        );

        users.add(userRiesgos);
        users.add(userNegocioESP);
        users.add(userNegocioALB);
        users.add(userInvalid);
        insert users;

        // Crea plantillas de correo
        EmailTemplate et = new EmailTemplate(
            isActive = true, 
            Name = 'emailTemplateTest', 
            DeveloperName = 'emailTemplateTest', 
            TemplateType = 'text', 
            Subject = 'Test Subject', 
            HtmlValue = '<p>Test</p>', 
            FolderId = UserInfo.getUserId()
        );
        insert et;

        EmailTemplate etWithOutHTML = new EmailTemplate(
            isActive = true, 
            Name = 'emailTemplateWithoutHTML', 
            DeveloperName = 'emailTemplateWithoutHTML', 
            TemplateType = 'text', 
            Subject = 'No HTML Subject', 
            FolderId = UserInfo.getUserId()
        );
        insert etWithOutHTML;
    }

    // Prueba para el método getTemplateContentById con HTMLValue
    @isTest
    static void testGetTemplateContentById(){
        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];

        Test.startTest();
        Map<String, String> result = SendEmailUserFilter.getTemplateContentById(template.Id);
        Test.stopTest();

        Assert.areEqual('<p>Test</p>', result.get('body'), 'El body no coincide');
        Assert.areEqual('Test Subject', result.get('subject'), 'El subject no coincide');
    }

    // Prueba para el método getTemplateContentById sin HTMLValue
    @isTest
    static void testGetTemplateContentByIdWithOutHTML(){
        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateWithoutHTML'
                                  LIMIT 1];

        Test.startTest();
        Map<String, String> result = SendEmailUserFilter.getTemplateContentById(template.Id);
        Test.stopTest();

        Assert.areEqual('', result.get('body'), 'El body debería estar vacío');
        Assert.areEqual('No HTML Subject', result.get('subject'), 'El subject no coincide');
    }

    // Prueba para el método sendEmails con userType = Negocio y Countries = ESP
    @isTest
    static void testSendEmailsNegocio(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];

        // Configura los parámetros para llamar a sendEmails
        Map<String, String> levels = new Map<String, String>();
        levels.put('DES_LevelUO_1__c', '00003906');
        levels.put('DES_LevelUO_6__c', '00080132');
        //levels.put('DES_LevelUO_5__c','00011823');

        List<String> countries = new List<String>{ 'ESP' };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        List<String> psList = new List<String>();
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, 'Negocio', 'AND', null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();

        System.debug('userIds::' + userIds);
        System.debug('SendEmailUserFilter.userIds.contains(userNegocioESP):::' + userIds.contains(userNegocioESP));
        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isTrue(userIds.contains(userNegocioESP), 'Debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isFalse(userIds.contains(userRiesgos), 'No debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método sendEmails con tipo "Riesgos" y Countries = 'ESP'
    @isTest
    static void testSendEmailsRiesgos(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];

        // Configura los parámetros para llamar a sendEmails
        Map<String, String> levels = new Map<String, String>();
        levels.put('DES_LevelUO_1__c', '00003906');
        //levels.put('DES_LevelUO_6__c','00080132');
        levels.put('DES_LevelUO_5__c', '00011823');
        List<String> countries = new List<String>{ 'ESP' };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        List<String> psList = new List<String>();
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, 'Riesgos', 'AND', null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isFalse(userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método sendEmails con userType = null y Countries = 'ESP'
    @isTest
    static void testSendEmailsWithOutUserType(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];

        // Configura los parámetros para llamar a sendEmails
        Map<String, String> levels = new Map<String, String>();
        List<String> countries = new List<String>{ 'ESP' };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        List<String> psList = new List<String>();
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, null, null, null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();

        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isTrue(userIds.contains(userNegocioESP), 'Debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método sendEmails con userType = null y Countries = 'ESP', 'ALB'
    @isTest
    static void testSendEmailsWithOutUserTypeAndWithTwoCountries(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];

        // Configura los parámetros para llamar a sendEmails
        Map<String, String> levels = new Map<String, String>();
        List<String> countries = new List<String>{ 'ESP', 'ALB' };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;

        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();
        List<String> psList = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, null, null, null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();


        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isTrue(userIds.contains(userNegocioESP), 'Debería enviar el correo a "Negocio User" y country ESP');
        Assert.isTrue(userIds.contains(userNegocioALB), 'Debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método sendEmails con userType = Negocio  y Countries = null
    @isTest
    static void testSendEmailsNegocioWithOutCountries(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];
        Map<String, String> levels = new Map<String, String>();
        levels.put('DES_LevelUO_1__c', '00003906');
        levels.put('DES_LevelUO_6__c', '00080132');
        //levels.put('DES_LevelUO_5__c','00011823');
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{  };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        List<String> psList = new List<String>();
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, 'Negocio', 'AND', null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isTrue(userIds.contains(userNegocioESP), 'Debería enviar el correo a "Negocio User" y country ESP');
        Assert.isTrue(userIds.contains(userNegocioALB), 'Debería enviar el correo a "Negocio User" y country ALB');
        Assert.isFalse(userIds.contains(userRiesgos), 'No debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método sendEmails con userType = Riesgos  y Countries = null
    @isTest
    static void testSendEmailsRiesgosWithOutCountries(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];
        Map<String, String> levels = new Map<String, String>();
        levels.put('DES_LevelUO_1__c', '00003906');
        //levels.put('DES_LevelUO_6__c','00080132');
        levels.put('DES_LevelUO_5__c', '00011823');
        // Configura los parámetros para llamar a sendEmails
        List<String> countries = new List<String>{  };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        List<String> psList = new List<String>();
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, 'Riesgos', 'AND', null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isFalse(userIds.contains(userNegocioESP), 'No debería enviar el correo a "Negocio User" y country ESP');
        Assert.isFalse(userIds.contains(userNegocioALB), 'No debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método sendEmails con userType = null y Countries = null
    @isTest
    static void testSendEmailsWithOutUserTypeAndWithOutCountries(){
        // Obtiene la plantilla de correo creada en setup
        List<User> testUser = [SELECT Id, Name, Email
                               from User
                               Where UserName IN ('riesgo@bbva.com', 'negocio@bbva.com', 'invalid@bbva.com', 'negocioALB@bbva.com') AND Profile.UserLicense.Name = 'Salesforce'
                               ORDER BY Name];

        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];

        // Configura los parámetros para llamar a sendEmails
        Map<String, String> levels = new Map<String, String>();
        List<String> countries = new List<String>{  };
        String userInvalid = testUser[0].Id;
        String userNegocioALB = testUser[1].Id;
        String userNegocioESP = testUser[2].Id;
        String userRiesgos = testUser[3].Id;
        List<String> psList = new List<String>();
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        List<String> userIds = new List<String>();

        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, null, null, null, psList, oweaList[0].Id, null);
        for (String user : SendEmailUserFilter.userIds){
            userIds.add(user);
        }
        Test.stopTest();

        // Verifica los resultados: debería incluir solo el usuario de "Negocio" y excluir al usuario inválido
        Assert.isTrue(sendWithErrors.size() == 0, 'No deberia haber errores');
        Assert.isTrue(userIds.contains(userNegocioESP), 'Debería enviar el correo a "Negocio User" y country ESP');
        Assert.isTrue(userIds.contains(userNegocioALB), 'Debería enviar el correo a "Negocio User" y country ALB');
        Assert.isTrue(userIds.contains(userRiesgos), 'Debería enviar el correo a "Riesgos User" y country ESP');
        Assert.isFalse(userIds.contains(userInvalid), 'No deberia enviar el correo a "Invalid User"');
    }

    // Prueba para el método getCountryPicklistValues
    @isTest
    static void testGetCountryPicklistValues(){
        Test.startTest();
        List<Map<String, String>> countryValues = SendEmailUserFilter.getCountryPicklistValues();
        Test.stopTest();
        Assert.isTrue(!countryValues.isEmpty(), 'La lista de valores de países no debería estar vacía');
        Boolean found = false;
        for (Map<String, String> country : countryValues){
            if (country.get('value') == 'ESP'){
                found = true;
                break;
            }
        }
        Assert.isTrue(found, 'Debería incluir la opción de país ESP en los valores de la lista');
    }

    @isTest
    static void testSendEmailsNoUsers(){
        EmailTemplate template = [SELECT Id
                                  FROM EmailTemplate
                                  WHERE Name = 'emailTemplateTest'
                                  LIMIT 1];
        List<OrgWideEmailAddress> oweaList = [SELECT id
                                              from OrgWideEmailAddress
                                              LIMIT 1];
        Map<String, String> levels = new Map<String, String>();
        List<String> countries = new List<String>{ 'ZZZ' }; // País inexistente
        List<String> psList = new List<String>();
        Test.startTest();
        List<String> sendWithErrors = SendEmailUserFilter.sendEmails(template.Id, levels, countries, null, null, null, psList, oweaList[0].Id, null);
        Test.stopTest();
        System.assertEquals(1, sendWithErrors.size(), 'Debe devolver error por no encontrar usuarios');
    }

    @isTest
    static void testGetOrgWideEmailAddresses(){
        Test.startTest();
        List<Map<String, Object>> result = SendEmailUserFilter.getOrgWideEmailAddresses();
        Test.stopTest();
        System.assert(result != null, 'Debe devolver una lista');
    }

    @isTest
    static void testGetPermissiontSetValues(){
        Test.startTest();
        List<Map<String, String>> result = SendEmailUserFilter.getPermissiontSetValues();
        Test.stopTest();
        System.assert(result != null, 'Debe devolver una lista');
    }

    @isTest
    static void testGetEmailHistory(){
        Test.startTest();
        List<DES_obj_MassEmailHistory__c> result = SendEmailUserFilter.getEmailHistory();
        Test.stopTest();
        System.assert(result != null, 'Debe devolver una lista');
    }

    @isTest
    static void testGetUserEmailDetails(){
        // Crea un historial y un usuario de email de prueba si es necesario
        List<DES_obj_MassEmailHistory__c> histories = [SELECT Id
                                                       FROM DES_obj_MassEmailHistory__c
                                                       LIMIT 1];
        if (!histories.isEmpty()){
            Test.startTest();
            List<DES_obj_MassEmailUser__c> result = SendEmailUserFilter.getUserEmailDetails(histories[0].Id);
            Test.stopTest();
            System.assert(result != null, 'Debe devolver una lista');
        }
    }

}