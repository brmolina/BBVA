/**
 * Clase Callable para gestionar operaciones de Tareas desde Integration Procedures
 * Implementa la interfaz Callable para ser invocada desde IPs
 */
public with sharing class DMT_TaskManager implements Callable {
    
    /**
     * Método principal de la interfaz Callable
     * @param action Nombre de la acción a ejecutar
     * @param args Parámetros de la acción
     * @return Resultado de la operación
     */

     public Object call(String action, Map<String, Object> args){

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }
     public static Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options){
        switch on methodName {
            when 'completeTask' {
                String taskId = (String)inputMap.get('taskId');system.debug('taskis'+ taskId);
                outMap = completeTask(taskId);
            }
            when 'createTask' {
                String caseId = (String)inputMap.get('caseId');
                String approverExternalId = String.valueOf(inputMap.get('approverExternalId'));
                String taskTypeExternalId = String.valueOf(inputMap.get('taskTypeExternalId'));
                Map<String, Object> additionalParams = (Map<String, Object>)inputMap.get('additionalParams');
                outMap =  createTask(caseId, approverExternalId, taskTypeExternalId, additionalParams);

            }
            when 'updateTasksToFinished' {
                List<String> taskIds = (List<String>)inputMap.get('taskIds');
                outMap =  updateTasksToFinished(taskIds);
            }
            when else {
                String taskId = (String)inputMap.get('taskId');
                outMap =  completeTask(taskId);
            }
        }
        system.debug('method '+ methodName);
        system.debug('mapa '+ outMap);
        return outMap;
    }
    
    /**
     * Método 1: Completar una tarea
     * Cambia el estado a 'Completed'
     * @param taskId ID de la tarea a completar
     * @return Resultado de la operación
     */
    public static Map<String, Object> completeTask(String taskId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(taskId)) {
                //throw new DMT_Exception('El ID de la tarea no puede estar vacío');
            }
            
            // Verificar que la tarea existe
            List<Task> tasks = [SELECT Id, Status, IsClosed 
                               FROM Task 
                               WHERE Id = :taskId 
                               LIMIT 1];
            
            if (tasks.isEmpty()) {
                //throw new DMT_Exception('No se encontró la tarea con ID: ' + taskId);
            }
            
            Task taskToUpdate = tasks[0];
            taskToUpdate.Status = 'Completed';
            
            update taskToUpdate;
            
            result.put('success', true);
            result.put('message', 'Tarea completada exitosamente');
            result.put('taskId', taskId);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error al completar la tarea: ' + e.getMessage());
            result.put('error', e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Método 2: Crear una nueva tarea
     * @param caseId ID del caso relacionado
     * @param approverExternalId ID externo de dmt_approver__c
     * @param taskTypeExternalId ID externo de dmt_task_type__c
     * @param additionalParams Parámetros adicionales para la tarea
     * @return Resultado con el ID de la tarea creada
     */
    public static Map<String, Object> createTask(
        String caseId, 
        String approverExternalId, 
        String taskTypeExternalId,
        Map<String, Object> additionalParams
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Validaciones básicas
            if (String.isBlank(caseId)) {
                //throw new DMT_Exception('El ID del caso no puede estar vacío');
            }
            
            if (String.isBlank(approverExternalId)) {
               // throw new DMT_Exception('El ID externo del approver no puede estar vacío');
            }
            
            // 1. Buscar el dmt_approver__c por externalId
            List<dmt_approver__c> approvers = [
                SELECT Id, dmt_group__c 
                FROM dmt_approver__c 
                WHERE DMT_External_Id__c  = :approverExternalId 
                LIMIT 1
            ];
            
            if (approvers.isEmpty()) {
                //throw new DMT_Exception('No se encontró el approver con externalId: ' + approverExternalId);
            }
            
            dmt_approver__c approver = approvers[0];
            String groupDeveloperName = approver.dmt_group__c;
            
            if (String.isBlank(groupDeveloperName)) {
               // throw new DMT_Exception('El campo dmt_group__c está vacío en el approver');
            }
            
            // 2. Buscar el Group (Queue) por DeveloperName
            List<Group> groups = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = :groupDeveloperName 
                AND Type = 'Queue'
                LIMIT 1
            ];
            
            if (groups.isEmpty()) {
              //  throw new DMT_Exception('No se encontró el grupo con DeveloperName: ' + groupDeveloperName);
            }
            
            String ownerId = groups[0].Id;
            
            // 3. Buscar el dmt_task_type__c por externalId
            String taskTypeId = null;
            if (String.isNotBlank(taskTypeExternalId)) {
                List<dmt_task_type__c> taskTypes = [
                    SELECT Id 
                    FROM dmt_task_type__c 
                    WHERE DMT_External_Id__c  = :taskTypeExternalId 
                    LIMIT 1
                ];
                
                if (!taskTypes.isEmpty()) {
                    taskTypeId = taskTypes[0].Id;
                }
            }
            
            // 4. Crear la nueva tarea
            Task newTask = new Task();
            newTask.WhatId = caseId; // Relacionar con el caso
            newTask.OwnerId = ownerId; // Asignar a la queue
            newTask.Status = 'Not Started';
            newTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(DMT_Constants.TASK_RT_APPROVAL_STEP).getRecordTypeId();
            
            // Mapear el task type si existe
            if (String.isNotBlank(taskTypeId)) {
                newTask.dmt_task_type__c = taskTypeId;
            }
            
            // Asignar parámetros adicionales si existen
            if (additionalParams != null) {
                // Campos de texto
                if (additionalParams.containsKey('Subject')) {
                    newTask.Subject = (String)additionalParams.get('Subject');
                }
                
                if (additionalParams.containsKey('Description')) {
                    newTask.Description = (String)additionalParams.get('Description');
                }
                
                if (additionalParams.containsKey('Priority')) {
                    newTask.Priority = (String)additionalParams.get('Priority');
                }
                
                // Campos de fecha
                if (additionalParams.containsKey('ActivityDate')) {
                    Object dateValue = additionalParams.get('ActivityDate');
                    if (dateValue instanceof Date) {
                        newTask.ActivityDate = (Date)dateValue;
                    } else if (dateValue instanceof String) {
                        newTask.ActivityDate = Date.valueOf((String)dateValue);
                    }
                }
                
                // Campos booleanos
                if (additionalParams.containsKey('IsReminderSet')) {
                    newTask.IsReminderSet = (Boolean)additionalParams.get('IsReminderSet');
                }
            }
            
            // Establecer valores por defecto si no se proporcionaron
            if (String.isBlank(newTask.Subject)) {
                newTask.Subject = 'Nueva Tarea - ' + System.now();
            }
            
            if (newTask.ActivityDate == null) {
                newTask.ActivityDate = System.today().addDays(7);
            }
            
            insert newTask;
            DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(newTask.Id, false);
            
            result.put('success', true);system.debug('tarea'+newTask.Id);
            result.put('message', 'Tarea creada exitosamente');
            result.put('taskId', newTask.Id);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error al crear la tarea: ' + e.getMessage());
            result.put('error', e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Método 3: Actualizar múltiples tareas a estado 'Finished'
     * @param taskIds Lista de IDs de tareas a actualizar
     * @return Resultado de la operación
     */
    public static Map<String, Object> updateTasksToFinished(List<String> taskIds) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (taskIds == null || taskIds.isEmpty()) {
                //throw new DMT_Exception('La lista de IDs de tareas no puede estar vacía');
            }
            
            // Consultar las tareas existentes
            List<Task> tasksToUpdate = [
                SELECT Id, Status 
                FROM Task 
                WHERE Id IN :taskIds
            ];
            
            if (tasksToUpdate.isEmpty()) {
                //throw new DMT_Exception('No se encontraron tareas con los IDs proporcionados');
            }
            
            // Actualizar el estado de cada tarea
            for (Task task : tasksToUpdate) {
                task.Status = 'Finished';
            }
            
            update tasksToUpdate;
            
            result.put('success', true);
            result.put('message', 'Se actualizaron ' + tasksToUpdate.size() + ' tareas a estado Finished');
            result.put('updatedCount', tasksToUpdate.size());
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error al actualizar las tareas: ' + e.getMessage());
            result.put('error', e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Método estático para llamadas directas (opcional)
     */
    public static Map<String, Object> executeAction(String action, Map<String, Object> args) {
        DMT_TaskManager manager = new DMT_TaskManager();
        return (Map<String, Object>)manager.call(action, args);
    }
    

}