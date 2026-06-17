/**********************************************************************************************************
 * @name            SendEmailUserFilter
 * @author          María Martínez Sanz
 * @created         12/09/2024
 * @description     Clase para filtrar usuarios y enviar emails masivos, gestionando plantillas y filtros dinámicos.
 **********************************************************************************************************/
 public with sharing class SendEmailUserFilter{
    @TestVisible
    private static List<String> userIds;
    /**********************************************************************************************************
     * @name            getTemplateContentById
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve el contenido de una plantilla de email por Id.
     * @param           String templateId - Id de la plantilla.
     * @return          Map<String, String> - Mapa con subject y body.
     **********************************************************************************************************/
	 @AuraEnabled
    public static Map<String, String> getTemplateContentById(String templateId){
        if (String.isBlank(templateId)){
            throw new AuraHandledException('Template ID no puede ser nulo o vacío');
        }

        try{
            // Añadimos 'Subject' a la consulta
            EmailTemplate template = [SELECT HtmlValue, Subject
                                      FROM EmailTemplate
                                      WHERE Id = :templateId AND IsActive = true
                                      LIMIT 1];

            Map<String, String> response = new Map<String, String>();

            // Procesamos el Subject
            response.put('subject', template.Subject != null ? template.Subject : '');

            // Procesamos el HTML
            if (template.HtmlValue != null){
                response.put('body', cleanHTML(template.HtmlValue));
            } else{
                response.put('body', '');
            }

            return response;

        } catch (Exception e){
            throw new AuraHandledException('Error al obtener la plantilla: ' + e.getMessage());
        }
    }

    /**********************************************************************************************************
     * @name            getOrgWideEmailAddresses
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve las direcciones de correo org-wide configuradas.
     * @return          List<Map<String, Object>> - Lista de direcciones.
     **********************************************************************************************************/
	 @AuraEnabled(cacheable = true)
    public static List<Map<String, Object>> getOrgWideEmailAddresses(){

        List<Map<String, Object>> result = new List<Map<String, Object>>();

        List<OrgWideEmailAddress> oweaList = [SELECT Id, Address, DisplayName
                                              FROM OrgWideEmailAddress
                                              ORDER BY Address];

        for (OrgWideEmailAddress o : oweaList){

            Boolean isDefault = o.Address != null && o.Address.toLowerCase() == 'globaldesktop@bbva.com';

            result.add(new Map<String, Object>{ 'label' => o.DisplayName != null ? o.DisplayName + ' (' + o.Address + ')' : 
                o.Address, 'value' => o.Id, 'isDefault' => isDefault });
        }
        return result;
    }

    // Método para limpiar el HTML, si es necesario, puedes mantenerlo aquí o dentro de la clase EmailTemplateWrapper.
    private static String cleanHTML(String htmlToClean){
        String html = htmlToClean.replaceAll('<script[^>]*>.*?</script>', '');
        html = htmlToClean.replaceAll('<style[^>]*>.*?</style>', '');
        return html;
    }

    /**********************************************************************************************************
     * @name            getUsersToSend
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve los usuarios a los que se enviará el email según los filtros.
     * @param           List<String> countries
     * @param           Map<String, String> levels
     * @param           String userType
     * @param           String filterLogic
     * @param           String customLogic
     * @param           List<String> permissionSets
     * @return          List<User>
     **********************************************************************************************************/
	 public static List<User> getUsersToSend(List<String> countries, Map<String, String> levels, String userType, String filterLogic, String customLogic, List<String> permissionSets){
        // Lista blanca de campos permitidos para filtrar
        Set<String> allowedFields = new Set<String>{ 'Title', 'Department', 'DES_Country__c', 'UserRole.Name', 'Profile.Name' };
        Map<String, Schema.SObjectField> userFields = Schema.SObjectType.User.fields.getMap();

        String baseQuery = 'SELECT Id, Email, Name FROM User WHERE IsActive=true AND Profile.UserLicense.Name=\'Salesforce\' AND (NOT Email LIKE \'%.invalid%\') AND Email LIKE \'%@bbva.com\' ';
        String userArce = 'ARCE';

        // Filtro por países
        if (countries != null && !countries.isEmpty()){
            baseQuery += ' AND DES_Country__c IN :countries';
        }
        // Filtro por permission sets
        if (permissionSets != null && !permissionSets.isEmpty()){
            baseQuery += ' AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN :permissionSets)';
        }
        // Filtros de niveles
        if (levels != null && !levels.isEmpty()){
            List<String> sortedKeys = new List<String>(levels.keySet());
            sortedKeys.sort ();
            Map<Integer, String> conditionMap = new Map<Integer, String>();
            Integer index = 1;
            for (String field : sortedKeys){
                // Validar campo permitido
                if (!allowedFields.contains(field) && !userFields.containsKey(field)){
                    throw new AuraHandledException('Campo de filtro no permitido: ' + field);
                }
                String rawValue = levels.get(field);
                if (!String.isEmpty(rawValue)){
                    List<String> values = rawValue.split(',');
                    List<String> cleanedValues = new List<String>();
                    for (String val : values){
                        String cleaned = String.escapeSingleQuotes(val.trim());
                        cleanedValues.add('\'' + cleaned + '\'');
                    }
                    String condition;
                    if (cleanedValues.size() == 1){
                        condition = field + ' = ' + cleanedValues[0];
                    } else{
                        condition = field + ' IN (' + String.join(cleanedValues, ', ') + ')';
                    }
                    conditionMap.put(index, condition);
                    index++;
                }
            }
            if (!conditionMap.isEmpty()){
                if (filterLogic == 'CustomLogic' && !String.isBlank(customLogic)){
                    // Validar customLogic: solo números, paréntesis, espacios y operadores lógicos AND/OR
                    String logicCheck = customLogic.replaceAll('AND', '').replaceAll('OR', '');
                    if (!Pattern.matches('^[0-9\\s\\(\\)]+$', logicCheck)){
                        throw new AuraHandledException('Lógica personalizada no permitida');
                    }
                    String parsedLogic = customLogic;
                    for (Integer i : conditionMap.keySet()){
                        parsedLogic = parsedLogic.replaceAll('\\b' + String.valueOf(i) + '\\b', '(' + conditionMap.get(i) + ')');
                    }
                    baseQuery += ' AND (' + parsedLogic + ')';
                } else if (filterLogic == 'OR'){
                    baseQuery += ' AND (' + String.join(conditionMap.values(), ' OR ') + ')';
                } else{
                    baseQuery += ' AND ' + String.join(conditionMap.values(), ' AND ');
                }
            }
        }
        // Filtro tipo usuario seleccionado (Riesgos o Negocio)
        if (userType != null){
            if (userType == 'Riesgos'){
                baseQuery += ' AND UserRole.Name=\'' + userArce + '\'';
            } else{
                baseQuery += ' AND UserRole.Name!=\'' + userArce + '\'';
            }
        }
        return Database.query(baseQuery);
    }

    /**********************************************************************************************************
     * @name            sendEmails
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Envía emails masivos a los usuarios filtrados y registra el historial.
     * @param           String templateId
     * @param           Map<String, String> levels
     * @param           List<String> countries
     * @param           String userType
     * @param           String filterLogic
     * @param           String customLogic
     * @param           List<String> permissionSets
     * @param           String oweaId
     * @param           DateTime scheduledDateTime
     * @return          List<String> - Errores encontrados.
     **********************************************************************************************************/
    @AuraEnabled
    public static List<String> sendEmails(String templateId, Map<String, String> levels, List<String> countries, String userType, String filterLogic, String customLogic, List<String> permissionSets, String oweaId, DateTime scheduledDateTime){
        List<String> sendWithErrors = new List<String>();
        DES_obj_MassEmailHistory__c history;

        try{

            String batchId = String.valueOf(Datetime.now().getTime());
            EmailTemplate template;
            if (templateId != null){
                template = [SELECT Id, Name
                            FROM EmailTemplate
                            WHERE Id = :templateId
                            LIMIT 1];
            }
            OrgWideEmailAddress owea;
            if (oweaId != null){
                owea = [SELECT Id, Address
                        FROM OrgWideEmailAddress
                        WHERE Id = :oweaId
                        LIMIT 1];
            }

            List<User> usersToSend = getUsersToSend(countries, levels, userType, filterLogic, customLogic, permissionSets);

            // Construir filtros JSON
            Map<String, Object> filtersToStore = new Map<String, Object>{ 'countries' => countries, 'levels' => levels, 'permissionSets' => permissionSets, 'userType' => userType, 'filterLogic' => filterLogic, 'customLogic' => customLogic };

            //  Crear history SIEMPRE
            history = new DES_obj_MassEmailHistory__c(
                DES_fld_EmailTemplate__c = template.Name, 
                DES_fld_FromAddress__c = owea.Address, 
                DES_fld_TotalUsers__c = usersToSend.size(), 
                DES_fld_Status__c = 'In progress', 
                DES_fld_FilterJSON__c = JSON.serializePretty(filtersToStore), 
                DES_fld_TemplateId__c = templateId, 
                DES_fld_OrgWideEmailId__c = oweaId, 
                DES_fld_BatchID__c = batchId
            );

            Boolean isScheduled = scheduledDateTime != null && scheduledDateTime > System.now();

            if (isScheduled){
                history.DES_fld_Status__c = 'Scheduled';
                history.DES_fld_ScheduleDateTime__c = scheduledDateTime;
            } else{
                history.DES_fld_Status__c = 'In Progress';
            }

            insert history;

            if (usersToSend.isEmpty()){

                history.DES_fld_Status__c = 'Failed';
                history.DES_fld_ErrorLog__c = 'No users found';
                update history;

                sendWithErrors.add('No users found');
                return sendWithErrors;
            }

            List<DES_obj_MassEmailUser__c> userRecords = new List<DES_obj_MassEmailUser__c>();
            userIds = new List<String>();

            for (User user : usersToSend){
                userIds.add(user.Id);

                userRecords.add(new DES_obj_MassEmailUser__c(
                    DES_fld_Email__c = history.Id, 
                    DES_fld_User__c = user.Id
                ));
            }

            insert userRecords;

            if (!isScheduled){

                launchQueueables(templateId, userIds, batchId, history.Id, oweaId);
            }

            /*  if (!userIds.isEmpty()) {
             // Dividir los userIds en lotes de tamaño 100 y encolar cada lote
             Integer batchSize = 100;
             Integer totalUserIds = userIds.size();
             DES_obj_MassEmailHistory__c historyUpdated = new DES_obj_MassEmailHistory__c();
             for (Integer i = 0; i < totalUserIds; i += batchSize) {
             List<String> batchUserIds = new List<String>();

             for (Integer j = i; j < Math.min(i + batchSize, totalUserIds); j++) {
             batchUserIds.add(userIds[j]);
             }

             Boolean isLastBatch = (i + batchSize >= totalUserIds);

             System.enqueueJob(new EmailQueueable(templateId, batchUserIds, isLastBatch, batchId,history.Id, oweaId));

             }


             } */
        } catch (Exception e){

            if (history != null){
                history.DES_fld_Status__c = 'Failed';
                history.DES_fld_ErrorLog__c = e.getMessage() + '\n\n' + e.getStackTraceString();

                update history;

            } else{
                insert new DES_obj_MassEmailHistory__c(
                    DES_fld_Status__c = 'Failed', 
                    DES_fld_ErrorLog__c = e.getMessage() + '\n\n' + e.getStackTraceString()
                );

            }

            sendWithErrors.add(e.getMessage());
        }

        return sendWithErrors;
    }

    /**********************************************************************************************************
     * @name            launchQueueables
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Divide los usuarios en lotes y lanza los procesos encolados para el envío de emails.
     * @param           String templateId - Id de la plantilla de email.
     * @param           List<String> userIds - Lista de Ids de usuario a los que enviar.
     * @param           String batchId - Identificador del lote.
     * @param           Id historyId - Id del historial de envío.
     * @param           String oweaId - Id de la dirección org-wide.
     **********************************************************************************************************/
    private static void launchQueueables(String templateId, List<String> userIds, String batchId, Id historyId, String oweaId){

        Integer batchSize = 100;
        Integer totalUserIds = userIds.size();

        for (Integer i = 0; i < userIds.size(); i += batchSize){

            List<String> batchUserIds = new List<String>();

            for (Integer j = i; j < Math.min(i + batchSize, totalUserIds); j++){
                batchUserIds.add(userIds[j]);
            }
            Boolean isLastBatch = (i + batchSize >= totalUserIds);

            System.enqueueJob(new EmailQueueable(templateId, batchUserIds, isLastBatch, batchId, historyId, oweaId));
        }
    }

    /**********************************************************************************************************
     * @name            launchScheduledEmails
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Ejecuta los Queueables para un registro de historial programado.
     * @param           List<Id> historyIds - Lista de Ids de historiales programados.
     **********************************************************************************************************/
    @InvocableMethod(label = 'Lanzar Envío Programado'description = 'Ejecuta los Queueables para un registro de historial programado')
    public static void launchScheduledEmails(List<Id> historyIds){
        // 1. Recuperamos la info del historial y sus destinatarios usando la relación Master-Detail
        List<DES_obj_MassEmailHistory__c> histories = [SELECT Id, DES_fld_BatchID__c, DES_fld_TemplateId__c, DES_fld_OrgWideEmailId__c, (SELECT DES_fld_User__c
                                                                                                                                         FROM DES_fld_Users__r)
                                                       FROM DES_obj_MassEmailHistory__c 
                                                       WHERE Id IN:historyIds];

        List<DES_obj_MassEmailHistory__c> toUpdate = new List<DES_obj_MassEmailHistory__c>();

        for (DES_obj_MassEmailHistory__c hist : histories){

            List<String> userIds = new List<String>();
            for (DES_obj_MassEmailUser__c child : hist.DES_fld_Users__r){
                userIds.add(child.DES_fld_User__c);
            }

            if (!userIds.isEmpty()){
                // 4. Marcamos como 'In Progress' para el histórico
                hist.DES_fld_Status__c = 'In Progress';
                toUpdate.add(hist);

                // 5. Reutilizamos tu método launchQueueables original
                launchQueueables(hist.DES_fld_TemplateId__c, userIds, hist.DES_fld_BatchID__c, hist.Id, hist.DES_fld_OrgWideEmailId__c);
            }
        }

        if (!toUpdate.isEmpty())
            update toUpdate;
    }

    /**********************************************************************************************************
     * @name            getCountryPicklistValues
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve los valores del picklist de países del usuario.
     * @return          List<Map<String, String>> - Lista de países (label y value).
     **********************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<Map<String, String>> getCountryPicklistValues(){
        List<Map<String, String>> countryOptions = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldResult = User.DES_Country__c.getDescribe();
        List<Schema.PicklistEntry> countryEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : countryEntries){
            Map<String, String> countryMap = new Map<String, String>();
            countryMap.put('label', entry.getLabel());
            countryMap.put('value', entry.getValue());
            countryOptions.add(countryMap);
        }

        return countryOptions;
    }

    /**********************************************************************************************************
     * @name            getPermissiontSetValues
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve los valores de los Permission Sets disponibles.
     * @return          List<Map<String, String>> - Lista de permission sets (label y value).
     **********************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<Map<String, String>> getPermissiontSetValues(){
        List<Map<String, String>> permissionSetOptions = new List<Map<String, String>>();

        List<PermissionSet> permSets = [SELECT Id, Name, Label
                                        FROM PermissionSet
                                        WHERE IsOwnedByProfile = FALSE AND Type = 'Regular'
                                        ORDER BY Label];

        for (PermissionSet ps : permSets){
            Map<String, String> psMap = new Map<String, String>();
            psMap.put('label', ps.Label);
            psMap.put('value', ps.Name);
            permissionSetOptions.add(psMap);
        }

        return permissionSetOptions;
    }

    /**********************************************************************************************************
     * @name            getEmailHistory
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve el historial de envíos masivos de emails.
     * @return          List<DES_obj_MassEmailHistory__c> - Lista de historiales.
     **********************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<DES_obj_MassEmailHistory__c> getEmailHistory(){
        return [SELECT Id, Name, DES_fld_Status__c, DES_fld_TotalUsers__c, CreatedDate, CreatedBy.Name, DES_fld_FromAddress__c, DES_fld_EmailTemplate__c, DES_fld_ErrorLog__c, DES_fld_FilterJSON__c
                FROM DES_obj_MassEmailHistory__c
                ORDER BY CreatedDate DESC
                LIMIT 100];
    }

    /**********************************************************************************************************
     * @name            getUserEmailDetails
     * @author          María Martínez Sanz
     * @created         12/09/2024
     * @description     Devuelve los detalles de usuarios de un envío masivo concreto.
     * @param           Id historyId - Id del historial de envío.
     * @return          List<DES_obj_MassEmailUser__c> - Lista de detalles de usuarios.
     **********************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<DES_obj_MassEmailUser__c> getUserEmailDetails(Id historyId){
        return [SELECT DES_fld_User__r.Name, DES_fld_UserEmail__c, DES_fld_Status__c
                FROM DES_obj_MassEmailUser__c
                WHERE DES_fld_Email__c = :historyId
                ORDER BY CreatedDate];
    }

}