global without sharing class DMT_TeamMemberSharingBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // Para rastrear estadísticas y logs durante la ejecución
    global Integer recordsProcessed = 0;
    global Integer sharesCreated = 0;
    global Integer errorsCount = 0;
    global List<String> errorMessages = new List<String>();
    
    // La consulta obtiene los DMT_TeamMember__c creados o modificados en las últimas 24 horas.
    // Puedes ajustar el criterio de fecha si lo necesitas (CreatedDate, LastModifiedDate).
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Filtra por registros del día actual. Cambia según tu necesidad.
        Datetime yesterday = Datetime.now().addDays(-1);
        String query = 'SELECT Id, Name, Line__c, User__c, AccessLevel__c, ' +
                       'Line__r.OwnerId ' + // Necesitamos el Owner para no crear shares duplicados o innecesarios.
                       'FROM DMT_TeamMember__c ' +
                       'WHERE Line__r.LastModiFiedDate >= LAST_WEEK ' + // Solo procesar los creados recientemente.
                       'ORDER BY CreatedDate DESC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<DMT_TeamMember__c> teamMembers) {
        
        // Mapas para organizar la información
        Map<Id, DMT_Line__c> parentLinesMap = new Map<Id, DMT_Line__c>();
        Map<Id, DMT_TeamMember__c> teamMemberMap = new Map<Id, DMT_TeamMember__c>();
        Set<Id> lineIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        
        for (DMT_TeamMember__c tm : teamMembers) {
            if (tm.Line__c != null && tm.User__c != null) {
                lineIds.add(tm.Line__c);
                userIds.add(tm.User__c);
                teamMemberMap.put(tm.Id, tm);
            }
        }
        
        // 1. Consultar los shares existentes para estos DMT_Line__c y usuarios.
        //    Esto evita crear duplicados.
        Map<String, DMT_Line__Share> existingSharesMap = new Map<String, DMT_Line__Share>();
        for (DMT_Line__Share share : [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause 
                                      FROM DMT_Line__Share 
                                      WHERE ParentId IN :lineIds 
                                      AND UserOrGroupId IN :userIds
                                      AND RowCause = 'Manual']) { // Filtramos solo los shares manuales.
            // Creamos una clave única para identificar el share por Parent + User.
            String key = share.ParentId + '_' + share.UserOrGroupId;
            existingSharesMap.put(key, share);
        }
        
        // 2. Preparar la lista de nuevos shares a crear.
        List<DMT_Line__Share> sharesToInsert = new List<DMT_Line__Share>();
        
        for (DMT_TeamMember__c tm : teamMembers) {
            recordsProcessed++;
            
            // Validaciones básicas
            if (tm.Line__c == null || tm.User__c == null || tm.AccessLevel__c == null) {
                errorsCount++;
                errorMessages.add('Team Member ' + tm.Id + ' tiene campos requeridos nulos (Line, User o Access Level).');
                continue;
            }
            
            // No crear share si el usuario es el propietario del registro (ya tiene acceso completo).
            if (tm.User__c == tm.Line__r.OwnerId) {
                continue;
            }
            
            // Determinar el nivel de acceso para el share.
            String accessLevel;
            if (tm.AccessLevel__c.contains('Edit') || tm.AccessLevel__c == 'Edit') {
                accessLevel = 'Edit';
            } else if (tm.AccessLevel__c.contains('Read') || tm.AccessLevel__c == 'Read') {
                accessLevel = 'Read';
            } else {
                // Si no es Edit ni Read, se omite.
                errorsCount++;
                errorMessages.add('Team Member ' + tm.Id + ' tiene un Access Level no soportado: ' + tm.AccessLevel__c);
                continue;
            }
            
            // Verificar si el share ya existe.
            String key = tm.Line__c + '_' + tm.User__c;
            DMT_Line__Share existingShare = existingSharesMap.get(key);
            
            if (existingShare != null) {
                // Si existe, verificamos si el nivel de acceso es el correcto.
                if (existingShare.AccessLevel != accessLevel) {
                    // Podemos actualizar el share existente si es necesario.
                    // En este caso, lo actualizamos.
                    existingShare.AccessLevel = accessLevel;
                    sharesToInsert.add(existingShare); // Al ser un registro existente, se hará un UPDATE.
                }
                // Si el nivel de acceso ya es el correcto, no hacemos nada.
            } else {
                // Si no existe, creamos un nuevo share.
                DMT_Line__Share newShare = new DMT_Line__Share();
                newShare.ParentId = tm.Line__c;
                newShare.UserOrGroupId = tm.User__c;
                newShare.AccessLevel = accessLevel;
                newShare.RowCause = Schema.DMT_Line__Share.RowCause.Manual; // Importante: causa manual.
                sharesToInsert.add(newShare);
            }
        }
        
        // 3. Realizar las operaciones DML (UPSERT para insertar o actualizar).
        if (!sharesToInsert.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(sharesToInsert, false); // 'false' para procesar parcialmente.
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult sr = results[i];
                if (!sr.isSuccess()) {
                    errorsCount++;
                    for (Database.Error err : sr.getErrors()) {
                        errorMessages.add('Error en Share para Parent ' + sharesToInsert[i].ParentId + 
                                          ' y User ' + sharesToInsert[i].UserOrGroupId + ': ' + err.getMessage());
                    }
                } else {
                    if (sr.isCreated()) {
                        sharesCreated++;
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Enviar un email con el resumen de la ejecución.
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, 
                            TotalJobItems, CreatedBy.Email 
                            FROM AsyncApexJob 
                            WHERE Id = :bc.getJobId()];
        
        String emailSubject = 'Batch de Sharing DMT_TeamMember__c Finalizado: ' + job.Status;
        String emailBody = 'El batch ha completado su ejecución.\n\n' +
                           'Detalles del trabajo:\n' +
                           'Total de Team Members procesados: ' + recordsProcessed + '\n' +
                           'Shares creados/actualizados: ' + sharesCreated + '\n' +
                           'Errores encontrados: ' + errorsCount + '\n' +
                           'Total de Job Items: ' + job.TotalJobItems + '\n' +
                           'Número de Errores del Batch: ' + job.NumberOfErrors + '\n\n';
        
        if (!errorMessages.isEmpty()) {
            emailBody += 'Lista de Errores:\n';
            for (String err : errorMessages) {
                emailBody += ' - ' + err + '\n';
            }
        }
        
        // Enviar notificación por email.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { job.CreatedBy.Email }; // Enviar al que programó el batch.
        // Puedes agregar más destinatarios fijos si lo necesitas:
        // String[] additionalRecipients = new String[] { 'admin@tuempresa.com' };
        // toAddresses.addAll(additionalRecipients);
        mail.setToAddresses(toAddresses);
        mail.setSubject(emailSubject);
        mail.setPlainTextBody(emailBody);
        
        // Envía el email. En un org de producción, considera manejar límites.
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        
        // También puedes registrar un log custom o imprimir en debug.
        System.debug('Batch finalizado: ' + emailBody);
    }
}