public class DMT_ConsolidatedLineService {
    
    /**
     * Método para actualizar el campo g_multioperation_ind_type__c en DMT_Consolidated_Line__c
     * @param lineUpdates Lista de objetos con lineId y nuevo valor para multi_operation_type
     * @return Resultado de la operación con éxito/errores
     */
    @AuraEnabled
    public static UpdateResult updateMultiOperationType(String lineId, Boolean multiOperationTypeValue) {
        UpdateResult result = new UpdateResult();
        result.success = true;
        
        try {
            // Recopilar todos los lineId__c únicos de los registros seleccionados
            Set<String> lineIds = new Set<String>();
            Map<String, Boolean> lineIdToValueMap = new Map<String, Boolean>();
            
            // for (LineUpdateRequest req : lineUpdates) {
            //     lineIds.add(req.lineId);
            //     lineIdToValueMap.put(req.lineId, req.multiOperationTypeValue);
            // }
            
            // Buscar TODOS los registros DMT_Consolidated_Line__c que tengan esos lineId__c
            List<DMT_Consolidated_Line__c> linesToUpdate = [
                SELECT Id, line_ID__c, g_multioperation_ind_type__c
                FROM DMT_Consolidated_Line__c
                WHERE line_ID__c = :lineId
            ];
            
            if (linesToUpdate.isEmpty()) {
                result.message = 'No se encontraron registros con los IDs proporcionados';
                return result;
            }
            
            // Actualizar cada registro con el nuevo valor
            for (DMT_Consolidated_Line__c line : linesToUpdate) {
                String newValue = (Boolean) multiOperationTypeValue == true ? 't' : 'x';
                if (newValue != null) {
                    line.g_multioperation_ind_type__c = newValue;
                }
            }
            
            // Realizar la actualización
            Database.SaveResult[] saveResults = Database.update(linesToUpdate, false);
            
            // Procesar resultados
            Integer successCount = 0;
            Integer errorCount = 0;
            List<String> errorMessages = new List<String>();
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                DMT_Consolidated_Line__c line = linesToUpdate[i];
                
                if (sr.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    String errorMsg = 'Error en registro ID ' + line.line_ID__c + ': ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    errorMessages.add(errorMsg);
                }
            }
            
            // Preparar resultado
            result.message = String.format(
                'Proceso completado. {0} registros actualizados, {1} errores.',
                new List<Object>{ successCount, errorCount }
            );
            
            if (!errorMessages.isEmpty()) {
                result.errorDetails = errorMessages;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error en el proceso: ' + e.getMessage();
            result.errorDetails = new List<String>{ e.getStackTraceString() };
        }
        
        return result;
    }
    
    
    @AuraEnabled(cacheable=false)
    public static Map<String, String> getConsolidatedLines(List<String> lineIds) {
        try {

            Map<String, String> resultMap = new Map<String, String>();
            if (lineIds == null || lineIds.isEmpty()) {
                return resultMap;
            }

            List<DMT_Consolidated_Line__c> consLines = [
                SELECT Id, Name, Status__c, Line_Id__c, g_multioperation_ind_type__c, g_line_name_desc__c
                FROM DMT_Consolidated_Line__c
                WHERE Line_Id__c IN :lineIds AND gf_group_priority_line_id__c = '00'
                WITH SECURITY_ENFORCED];

            for(DMT_Consolidated_Line__c cl : consLines) {
            resultMap.put(cl.Line_Id__c, cl.g_multioperation_ind_type__c);
            }
            
            return resultMap;
        } catch (Exception e) {
            throw new AuraHandledException('Error al cargar líneas consolidadas: ' + e.getMessage());
        }
    }
    

    public class LineUpdateRequest {
        @AuraEnabled
        public String lineId { get; set; }
        
        @AuraEnabled
        public Boolean multiOperationTypeValue { get; set; }
    }
    
    /**
     * Clase para el resultado de la operación
     */
    public class UpdateResult {
        @AuraEnabled
        public Boolean success { get; set; }
        
        @AuraEnabled
        public String message { get; set; }
        
        @AuraEnabled
        public List<String> errorDetails { get; set; }
        
        public UpdateResult() {
            this.success = false;
            this.errorDetails = new List<String>();
        }
    }
}