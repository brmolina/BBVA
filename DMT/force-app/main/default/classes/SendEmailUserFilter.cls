public with sharing class SendEmailUserFilter {
    @TestVisible
    private static List<String> userIds = new List<String>();

    @AuraEnabled(cacheable=true)
    public static List<EmailTemplate> getEmailTemplates() {
        List<EmailTemplate> templates = new List<EmailTemplate>();

        try {
            templates = [SELECT Id, Name FROM EmailTemplate WHERE IsActive = true ORDER BY Name];
        } catch (Exception e) {
            throw new AuraHandledException('Error al realizar la consulta: ' + e.getMessage());
        }

        if (templates.isEmpty()) {
            return templates; // Retorna una lista vacía
        }

        return templates;
    }

    @AuraEnabled
    public static String getTemplateContentById(String templateId) {
        String result;
        if (String.isBlank(templateId)) {
            throw new AuraHandledException('Template ID no puede ser nulo o vacío');
        }

        EmailTemplate template;
        try {
            template = [SELECT HtmlValue FROM EmailTemplate WHERE Id = :templateId AND IsActive = true LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error al obtener la plantilla: ' + e.getMessage());
        }

        if (template == null) {
            throw new AuraHandledException('No se encontró la plantilla con el ID proporcionado');
        }
        if(template.HtmlValue!=null){
            result = cleanHTML(template.HtmlValue); // Devuelve el HTML limpio
        }else {
            result='';
        }
        return result;
    }
    

    // Método para limpiar el HTML, si es necesario, puedes mantenerlo aquí o dentro de la clase EmailTemplateWrapper.
    private static String cleanHTML(String htmlToClean) {
        String html = htmlToClean.replaceAll('<script[^>]*>.*?</script>', '');
        html = htmlToClean.replaceAll('<style[^>]*>.*?</style>', '');
        return html;
    }



    @AuraEnabled(cacheable=true)
    public static List<String> sendEmails(String templateId, String userType, List<String> countries) {
        System.debug(userType+', '+templateId+',  '+countries);
        List<String> sendWithErrors = new List<String>();
        /* 
        List<Messaging.Email> mails= new List<Messaging.Email>();
        List<Messaging.SendEmailResult> sendResults= new List<Messaging.SendEmailResult>(); */
        List<User> usersToSend = new List<User>();
        String batchId = String.valueOf(Datetime.now().getTime());

        // Lógica para obtener usuarios según el tipo y países seleccionados
        if(!countries.isEmpty()){
            if (userType=='Riesgos') {
                usersToSend = [SELECT Id, Email, Name FROM User WHERE UserRole.Name = 'ARCE' AND DES_Country__c IN :countries AND IsActive=true AND Profile.UserLicense.Name='Salesforce' ];
            }else if(userType=='Negocio'){
                usersToSend = [SELECT Id, Email, Name FROM User WHERE UserRole.Name != 'ARCE' AND DES_Country__c IN :countries AND IsActive=true AND Profile.UserLicense.Name='Salesforce'];
            }else{
                usersToSend = [SELECT Id, Email, Name FROM User WHERE DES_Country__c IN :countries AND IsActive=true AND Profile.UserLicense.Name='Salesforce'];
            }
        }else{
            if (userType=='Riesgos') {
                usersToSend = [SELECT Id, Email, Name FROM User WHERE UserRole.Name = 'ARCE' AND IsActive=true AND Profile.UserLicense.Name='Salesforce'];
            }else if(userType=='Negocio'){
                usersToSend = [SELECT Id, Email, Name FROM User WHERE UserRole.Name != 'ARCE' AND IsActive=true AND Profile.UserLicense.Name='Salesforce'];
            }else{
                usersToSend = [SELECT Id, Email, Name FROM User  WHERE IsActive=true AND Profile.UserLicense.Name='Salesforce'];
            }
        }
       
        //List<String> userIds = new List<String>();
        for (User user : usersToSend) {
            if (!user.Email.contains('.invalid') && user.Email.contains('@bbva.com')) {
                userIds.add(user.Id);
                //sentUserNames.add('- '+ user.Name+ ' ( '+user.Email+')');
            }
        }
       
        if (!userIds.isEmpty()) {
          // Dividir los userIds en lotes de tamaño 100 y encolar cada lote
            Integer batchSize = 500;
            Integer totalUserIds = userIds.size();

            for (Integer i = 0; i < totalUserIds; i += batchSize) {
                List<String> batchUserIds = new List<String>();
        
                for (Integer j = i; j < Math.min(i + batchSize, totalUserIds); j++) {
                    batchUserIds.add(userIds[j]);
                }
        
                // `isLastBatch` es true solo en el último lote
                Boolean isLastBatch = (i + batchSize >= totalUserIds);
        
                System.enqueueJob(new EmailQueueable(templateId, batchUserIds, isLastBatch, batchId));
            }
        }else {
            System.debug('no hay usuarios');
            sendWithErrors.add('No hay usuarios');
        }
        List<iaso__GBL_Application_Log__c> appLogList = new List<iaso__GBL_Application_Log__c>();
        
        appLogList = [SELECT iaso__Transaction_Id__c, iaso__Message_LTA__c from iaso__GBL_Application_Log__c where iaso__Transaction_Id__c =: batchId];
        if (!appLogList.isEmpty()) {
            for (iaso__GBL_Application_Log__c appLog : appLogList) {
                if (appLog.iaso__Transaction_Id__c == batchId) {
                    System.debug('entra en el if del for');
                    sendWithErrors.add(appLog.iaso__Message_LTA__c);
                }
            }
            
        }
        return sendWithErrors;
    }

    /* @future
    public static void sendEmailToUser(String templateId, List<String> userIds) {
        List<Messaging.Email> mails= new List<Messaging.Email>();
        List<Messaging.SendEmailResult> sendResults= new List<Messaging.SendEmailResult>();
        OrgWideEmailAddress owea =[SELECT Id, Address from  OrgWideEmailAddress where Address ='globaldesktop@bbva.com'];

        for (String uId : userIds) {
                Messaging.SingleEmailMessage mailToSend = new Messaging.SingleEmailMessage();
                if(owea!=null){
                    mailToSend.setOrgWideEmailAddressId(owea.Id);
                }
                mailToSend.setTemplateID(templateId);
                mailToSend.setTargetObjectId(uId);
                mailToSend.setSaveAsActivity(false);
                mails.add(mailToSend);        
        }
        sendResults = Messaging.sendEmail(mails);
        for (Messaging.SendEmailResult sR : sendResults) {
            System.debug('Errors: '+sr.getErrors());
            System.debug('Errors: '+sr.isSuccess());

        }
    } */

    @AuraEnabled(cacheable = true)
    public static List<Map<String, String>> getCountryPicklistValues() {
        List<Map<String, String>> countryOptions = new List<Map<String, String>>();
        
        Schema.DescribeFieldResult fieldResult = User.DES_Country__c.getDescribe();
        List<Schema.PicklistEntry> countryEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : countryEntries) {
            Map<String, String> countryMap = new Map<String, String>();
            countryMap.put('label', entry.getLabel());
            countryMap.put('value', entry.getValue());
            countryOptions.add(countryMap);
        }
        
        return countryOptions; // Retorna una lista de mapas con label y value
    }
      
}