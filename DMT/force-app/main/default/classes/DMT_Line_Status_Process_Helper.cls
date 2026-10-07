public with sharing class DMT_Line_Status_Process_Helper {

    // Valores (API name) del picklist DMT_Line__c.DMT_Destination_Light__c
    // Son los valores que espera el atributo status del LWC dmt_traffic_light
    public static final String LIGHT_GREEN  = 'green';
    public static final String LIGHT_YELLOW = 'yellow';
    public static final String LIGHT_RED    = 'red';

    private static final Integer ERROR_MAX_LENGTH =
        Schema.SObjectType.DMT_Line__c.fields.DMT_Destination_Error__c.getLength();

    public void syncDestinationStatusToLines(List<DMT_line_status_process__c> changedRecords){

        // 1. Recoger los códigos de línea de los registros que han cambiado
        Set<String> lineCodes = new Set<String>();
        for (DMT_line_status_process__c record : changedRecords){
            if (String.isNotBlank(record.DMT_Line_Code_SF__c)){
                lineCodes.add(record.DMT_Line_Code_SF__c);
            }
        }

        if (lineCodes.isEmpty()){
            return;
        }

        // 2. Traer TODOS los registros de status de esas líneas (no solo los del trigger).
        //    Para decidir el estado agregado de una línea de tipo Grupo necesito ver todos
        //    sus clientes/counterparties, no solo el/los que acaban de cambiar.
            
        Map<String, List<DMT_line_status_process__c>> statusRecordsByLineCode = new Map<String, List<DMT_line_status_process__c>>();
        for (DMT_line_status_process__c record : [
                SELECT Id, DMT_Line_Code_SF__c, DMT_Status__c,
                       DMT_Description_Error__c, DMT_Counterparty_Code__c, DMT_Date__c
                FROM DMT_line_status_process__c
                WHERE DMT_Line_Code_SF__c IN :lineCodes
                ORDER BY CreatedDate ASC, Id ASC
        ]){
            if (!statusRecordsByLineCode.containsKey(record.DMT_Line_Code_SF__c)){
                statusRecordsByLineCode.put(record.DMT_Line_Code_SF__c, new List<DMT_line_status_process__c>());
            }
            statusRecordsByLineCode.get(record.DMT_Line_Code_SF__c).add(record);
        }

        // 3. Traer las líneas que matchean por Line_Id__c
        Map<String, DMT_Line__c> lineByCode = new Map<String, DMT_Line__c>();
        for (DMT_Line__c line : [
                SELECT Id, Line_Id__c, DMT_RecordTypeName__c,
                       DMT_Destination_Status__c, DMT_Destination_Id__c,
                       DMT_Destination_Light__c, DMT_Destination_Error__c, DMT_Destination_Date__c
                FROM DMT_Line__c
                WHERE Line_Id__c IN :lineCodes
        ]){
            lineByCode.put(line.Line_Id__c, line);
        }

        if (lineByCode.isEmpty()){
            return;
        }

        // 4. Parametrización del CMDT
        Map<String, DMT_Destination_Mapping__mdt> mappingsByRecordType = getDestinationMappings();

        // 5. Por cada línea: calcular estado agregado, semáforo, error, fecha e id
        List<DMT_Line__c> linesToUpdate = new List<DMT_Line__c>();

        for (String lineCode : lineByCode.keySet()){
            DMT_Line__c line = lineByCode.get(lineCode);
            List<DMT_line_status_process__c> statusRecords = statusRecordsByLineCode.get(lineCode);

            if (statusRecords == null || statusRecords.isEmpty()){
                continue;
            }

            // Si el record type de la línea no está parametrizado en el CMDT,
            // no hay textos OK/KO que aplicar -> no se toca la línea
            DMT_Destination_Mapping__mdt mapping = mappingsByRecordType.get(line.DMT_RecordTypeName__c);
            if (mapping == null){
                continue;
            }

            // --- Agregación ---
            // Regla de negocio: KO si ALGÚN registro viene con DMT_Status__c = false.
            // Todos true -> OK.
            // Se recorren todos los registros (sin break) para recoger todos los errores
            // y la fecha más reciente.
            // Fecha: DMT_Date__c, informada por MENTOR en su respuesta. En líneas de Grupo
            // se toma la más reciente; los registros sin fecha se ignoran.
            Boolean isGroupLine = statusRecords.size() > 1;
            Boolean allOk = true;
            Date lastReceptionDate;
            List<String> errorMessages = new List<String>();

            for (DMT_line_status_process__c record : statusRecords){
                if (record.DMT_Date__c != null
                        && (lastReceptionDate == null || record.DMT_Date__c > lastReceptionDate)){
                    lastReceptionDate = record.DMT_Date__c;
                }
                if (record.DMT_Status__c == false){
                    allOk = false;
                    String message = buildErrorMessage(record, isGroupLine);
                    if (message != null){
                        errorMessages.add(message);
                    }
                }
            }

            String aggregatedStatus = allOk ? mapping.DMT_OK_Status__c : mapping.DMT_KO_Status__c;
            String aggregatedLight  = allOk ? LIGHT_GREEN : LIGHT_RED;

            // KO sin descripción -> error vacío; en pantalla solo se ve el status de KO del CMDT.
            // El truncado evita STRING_TOO_LONG al concatenar varios errores en líneas de Grupo.
            String errorDetail = errorMessages.isEmpty()
                                    ? null
                                    : String.join(errorMessages, '\n').abbreviate(ERROR_MAX_LENGTH);

            // --- Id de línea ---
            // No se usa ningún counterparty (identifican clientes, no la línea).
            // Se usa el propio código de línea, común a todos los registros de esa línea.
            String lineDestinationId = lineCode;

          
            if (line.DMT_Destination_Status__c != aggregatedStatus
                    || line.DMT_Destination_Id__c    != lineDestinationId
                    || line.DMT_Destination_Light__c != aggregatedLight
                    || line.DMT_Destination_Error__c != errorDetail
                    || line.DMT_Destination_Date__c  != lastReceptionDate){

                line.DMT_Destination_Status__c = aggregatedStatus;
                line.DMT_Destination_Id__c     = lineDestinationId;
                line.DMT_Destination_Light__c  = aggregatedLight;
                line.DMT_Destination_Error__c  = errorDetail;
                line.DMT_Destination_Date__c   = lastReceptionDate;
                linesToUpdate.add(line);
            }
        }

        // 6. DML final, una sola vez, fuera de bucles
        if (!linesToUpdate.isEmpty()){
            update linesToUpdate;
        }
    }

    // En líneas de Grupo se antepone el counterparty para saber qué cliente ha fallado
    private String buildErrorMessage(DMT_line_status_process__c record, Boolean withCounterparty){
        if (String.isBlank(record.DMT_Description_Error__c)){
            return null;
        }
        String message = record.DMT_Description_Error__c.trim();
        if (withCounterparty && String.isNotBlank(record.DMT_Counterparty_Code__c)){
            message = '[' + record.DMT_Counterparty_Code__c + '] ' + message;
        }
        return message;
    }

    private Map<String, DMT_Destination_Mapping__mdt> getDestinationMappings(){
        Map<String, DMT_Destination_Mapping__mdt> mappingsByRecordType = new Map<String, DMT_Destination_Mapping__mdt>();
        for (DMT_Destination_Mapping__mdt mapping : DMT_Destination_Mapping__mdt.getAll().values()){
            if (String.isNotBlank(mapping.DMT_RecordTypeName__c)){
                mappingsByRecordType.put(mapping.DMT_RecordTypeName__c, mapping);
            }
        }
        return mappingsByRecordType;
    }
}