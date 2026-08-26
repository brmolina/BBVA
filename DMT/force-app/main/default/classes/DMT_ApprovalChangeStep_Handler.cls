/**
 * @description       : Class called via the integration procedure ApprovalChangeStep
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 10-31-2024
 * @last modified by  : Aníbal Cortés
 **/
global without sharing class DMT_ApprovalChangeStep_Handler implements Callable{

    // Maps each Status_JSON_Wrapper property name (the JSON section keys used in
    // DMT_ViewFieldStatusAtClose__c) to the SObject whose tracked fields
    // (DMT_AllFieldsInStatus__c) describe it. Used by getComparableFieldKeys so the
    // field-level diff walks the full configured field list instead of only the
    // fields that happened to be non-null (and therefore present as JSON keys,
    // since System.JSON.serialize(x, true) omits null fields entirely) at the time
    // the snapshot being compared against was taken.
    private static final Map<String, String> SNAPSHOT_SECTION_TO_OBJECT = new Map<String, String>{
        'line' => 'DMT_Line__c',
        'opportunity' => 'Opportunity',
        'riskLineList' => 'DMT_Risk_Line_Term__c',
        'customAssociationClientList' => 'Custom_Association_Client__c',
        'lineProductItemList' => 'DMT_Line_Product_Item__c',
        'warranties' => 'DMT_Warranty__c',
        'currencyProvisions' => 'DMT_Currency_Provision__c',
        'opportunityTenor' => 'DMT_Opportunity_Tenor__c',
        'opportunityMitigant' => 'DMT_Opportunity_Mitigant__c',
        'opportunityClient' => 'DMT_Opportunity_Client__c',
        'opportunityLineItem' => 'OpportunityLineItem',
        'opportunityXSell' => 'DMT_X_Sell__c'
    };

    /**
     * @description Returns the complete set of top-level field keys that should be
     * compared for a given snapshot section (e.g. 'line', 'lineProductItemList'),
     * derived from the tracked field configuration (fieldMapFromObject, built from
     * DMT_AllFieldsInStatus__c) rather than from whichever keys happen to be present
     * in a previously-stored snapshot JSON. A field that was null when the old
     * snapshot was taken has no key in that JSON, so relying on its keySet() alone
     * silently skips comparing that field forever, even after it's populated.
     * Relationship-traversal fields (e.g. "Client__r.Name") are reduced to their
     * top-level key ("Client__r") to match how the JSON nests them.
     * Falls back to fallbackKeys (the old snapshot's own keys) only if the section
     * isn't recognized, to fail safe rather than skip comparison entirely.
     * @author DMT_ApprovalChangeStep_Handler | CIBGLOBALD-4098
     **/
    private static Set<String> getComparableFieldKeys(String sectionName, Map<String, List<String>> fieldMapFromObject, Set<String> fallbackKeys) {
        String objectName = SNAPSHOT_SECTION_TO_OBJECT.get(sectionName);
        if (objectName == null || !fieldMapFromObject.containsKey(objectName)) {
            return fallbackKeys;
        }
        Set<String> keys = new Set<String>();
        for (String trackedField : fieldMapFromObject.get(objectName)) {
            keys.add(trackedField.contains('.') ? trackedField.substringBefore('.') : trackedField);
        }
        return keys;
    }

    /**
     * @description First method that calls the Integration Procedure
     * @author Aníbal Cortés | 10-31-2024
     * @param action
     * @param args
     * @return Object
     **/
    public Object call(String action, Map<String, Object> args){

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    /**
     * @description Checks which method was invoked in the Integration Procedure
     * @author Aníbal Cortés | 10-31-2024
     * @param methodName
     * @param inputMap
     * @param outMap
     * @param options
     * @return Object
     **/
    private static Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options){
        try{
            if (methodName == 'saveValuesUpdate'){
                updateTaskWithStatus((String) inputMap.get('recordId'), true);
            } else if (methodName == 'saveValuesInsert'){
                updateTaskWithStatus((String) inputMap.get('recordId'), false);
            }
        } catch (exception e){
            system.debug('Exception --> ' + e.getMessage());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_ApprovalChangeStep_Handler', 'invokeMethod', 'DMT', ''));
            //DES_Exception_Utils.logException(e,'DMT_ApprovalChangeStep_Handler', 'invokeMethod', 'DMT', '');
        }
        return outMap;
    }

    /**
     * @description Method that updates the task with the current status of the records from the view
     * @author Aníbal Cortés | 10-31-2024
     * @param recordId
     **/
    public static void updateTaskWithStatus(String recordId, Boolean createPdf){

        Status_JSON_Wrapper jsonFinal = new Status_JSON_Wrapper();

        Task task = DMT_ApprovalChangeStep_Selector.getTaskById(recordId);
        Case relatedCase = DMT_ApprovalChangeStep_Selector.getCaseById(task.WhatId);


        Id approverViewId = getApproverViewId(task.OwnerId, relatedCase);
        List<DMT_Items__c> itemsList = DMT_ApprovalChangeStep_Selector.getItemsByDmtView(approverViewId);
        System.debug('itemsList: '+ itemsList);
        // Map that contains each Object and a list of its field Names
        Map<String, List<String>> fieldMapFromObject = new Map<String, List<String>>();
        String allFields = '';

        // We loop through each item to obtain the fields of every Object
        for (DMT_Items__c item : itemsList){
            // We get a list of each Object.Field
            //List<String> fields = item?.DMT_Campos_componente_Refact__c.split(';', 0);

            List<String> fields = new List<String>();
            // Comprueba que 'item' exista Y que el campo tenga valor.
            if (item != null && String.isNotBlank(item.DMT_Campos_componente_Refact__c)) {

                fields = item.DMT_Campos_componente_Refact__c.split(';', 0);
            }
            //We obtain the Object Name and Field Name for each and store it in the Map
            for (String field : fields){
                List<String> cadenaPartida = field.split('\\.', 2);
                String objectName = cadenaPartida.get(0);
                String fieldName = cadenaPartida.get(1);
                List<String> fieldsFromMap = new List<String>();
                if (fieldMapFromObject.containsKey(objectName)){
                    fieldsFromMap = fieldMapFromObject.get(objectName);
                }
                // If the field is already on the list, we don't store it again to prevent duplicate fields on query
                if (!fieldsFromMap.contains(fieldName)){
                    fieldsFromMap.add(fieldName);
                    fieldMapFromObject.put(objectName, fieldsFromMap);
                    allFields += objectName + '.' + fieldName + ';';
                }
            }
        }

        allFields = allFields.removeEnd(';');
        System.debug('allFields --> ' + allFields);

        if (relatedCase.DMT_LineOpportunity__c == 'L'){
            System.debug('isLine lINE 104');
            // Makes the query for the DMT_Line__c object and stores on the jsonFinal var
            if (fieldMapFromObject.containsKey('DMT_Line__c')){
                Id lineId = relatedCase.DMT_Line__c;
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Line__c'), ',') + ' FROM DMT_Line__c WHERE ID = :lineId';
                List<DMT_Line__c> linesRetrieved = Database.query(String.escapeSingleQuotes(query));
                jsonFinal.line = linesRetrieved.get(0);
            }

            // Makes the query for the DMT_TeamMember__c object and stores on the jsonFinal var
            // if (fieldMapFromObject.containsKey('DMT_TeamMember__c')) {
            //     Id lineId = relatedCase.DMT_Line__c;
            //     String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_TeamMember__c'),',') + ' FROM DMT_TeamMember__c WHERE Line__c = :lineId ORDER BY Name ASC';
            //     Map<Id, DMT_TeamMember__c> membersRetrieved = new Map<Id, DMT_TeamMember__c>((List<DMT_TeamMember__c>) Database.query(String.escapeSingleQuotes(query)));
            //     jsonFinal.participantList = membersRetrieved;
            // }

            // Makes the query for the DMT_Risk_Line_Term__c object and stores on the jsonFinal var
            if (fieldMapFromObject.containsKey('DMT_Risk_Line_Term__c')){
                System.debug('DMT_Risk_Line_Term__c lINE 123');
                Id lineId = relatedCase.DMT_Line__c;
                List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Risk_Line_Term__c');
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Risk_Line_Term__c'), ',') + ' FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :lineId ORDER BY DMT_Init_Term__c ASC';
                List<DMT_Risk_Line_Term__c> riskLineTermRetrieved = Database.query(String.escapeSingleQuotes(query));
                Map<Integer, Map<String, Object>> riskLineListFormatted = new Map<Integer, Map<String, Object>>();
                Integer counter = 1;

                // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                for (DMT_Risk_Line_Term__c term : riskLineTermRetrieved){
                    // Creamos un mapa interno para los atributos de cada registro.
                    Map<String, Object> termAttributes = new Map<String, Object>();
                    // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                    for (String field : fieldsToQuery){
                        termAttributes.put(field, term.get(field));
                    }
                    // Añadimos el registro al mapa final con la clave numérica.
                    riskLineListFormatted.put(counter, termAttributes);
                    counter++;
                }

                // 5. Asignamos el mapa formateado al objeto final.
                jsonFinal.riskLineList = riskLineListFormatted;
            }

            // Makes the query for the Custom_Association__c object and stores on the jsonFinal var
            if (fieldMapFromObject.containsKey('Custom_Association_Client__c')){
                Id customAssociationLine = relatedCase.DMT_Line__r.Custom_Association__c;
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('Custom_Association_Client__c'), ',') + ' FROM Custom_Association_Client__c WHERE Custom_Association__c = :customAssociationLine ORDER BY Name ASC';
                Map<Id, Custom_Association_Client__c> customAssociationRetrieved = new Map<Id, Custom_Association_Client__c>((List<Custom_Association_Client__c>)Database.query(String.escapeSingleQuotes(query)));
                jsonFinal.customAssociationClientList = customAssociationRetrieved;
            }

           // Makes the query for the DMT_Currency_Provision__c object and stores on the jsonFinal var
            if (fieldMapFromObject.containsKey('DMT_Currency_Provision__c')){
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Currency_Provision__c'), ',') + ' FROM DMT_Currency_Provision__c WHERE DMT_Risk_Line_Term__r.DMT_Line__c = :lineId ORDER BY Name ASC';
                Map<Id, DMT_Currency_Provision__c> currencyProvision = new Map<Id, DMT_Currency_Provision__c>((List<DMT_Currency_Provision__c>)Database.query(String.escapeSingleQuotes(query)));
                jsonFinal.currencyProvisions = currencyProvision;
            }

           // Makes the query for the DMT_Warranty__c object and stores on the jsonFinal var
            if (fieldMapFromObject.containsKey('DMT_Warranty__c')){
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Warranty__c'), ',') + ' FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__r.DMT_Line__c = :lineId ORDER BY Name ASC';
                Map<Id, DMT_Warranty__c> warrantyRetrieved = new Map<Id, DMT_Warranty__c>((List<DMT_Warranty__c>)Database.query(String.escapeSingleQuotes(query)));
                jsonFinal.warranties = warrantyRetrieved;
            }

            // Makes the query for the DMT_Line_Product_Item__c object and stores on the jsonFinal var
            if (fieldMapFromObject.containsKey('DMT_Line_Product_Item__c')){
                Id lineId = relatedCase.DMT_Line__c;
                List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Line_Product_Item__c');
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Line_Product_Item__c'), ',') + ' FROM DMT_Line_Product_Item__c WHERE Line__c = :lineId ORDER BY Name ASC';
                List<DMT_Line_Product_Item__c> lineProductItemsRetrieved = Database.query(String.escapeSingleQuotes(query));

                Map<Integer, Map<String, Object>> lineProductItemsFormatted = new Map<Integer, Map<String, Object>>();
                Integer counter = 1;

                // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                for (DMT_Line_Product_Item__c term : lineProductItemsRetrieved){
                    // Creamos un mapa interno para los atributos de cada registro.
                    Map<String, Object> termAttributes = new Map<String, Object>();
                    // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                    for (String field : fieldsToQuery){
                        termAttributes.put(field, term.get(field));
                    }
                    // Añadimos el registro al mapa final con la clave numérica.
                    lineProductItemsFormatted.put(counter, termAttributes);
                    counter++;
                }

                // 5. Asignamos el mapa formateado al objeto final.
                jsonFinal.lineProductItemList = lineProductItemsFormatted;
            }
        }else if (relatedCase.DMT_LineOpportunity__c == 'O'){
                // Makes the query for the Opportunity object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('Opportunity')){
                    Id oppId = relatedCase.opportunity_id__c;
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('Opportunity'), ',') + ' FROM Opportunity WHERE ID = :oppId';
                    List<Opportunity> oppRetrieved = Database.query(String.escapeSingleQuotes(query));
                    jsonFinal.opportunity = oppRetrieved.get(0);
                }
                // Makes the query for the DMT_Opportunity_Tenor__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Opportunity_Tenor__c')){
                    Id oppId = relatedCase.opportunity_id__c;
                    List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Opportunity_Tenor__c');
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Opportunity_Tenor__c'), ',') + ' FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__r.OpportunityId = :oppId ORDER BY gj_nominal_amount_db__c ASC';
                    List<DMT_Opportunity_Tenor__c> opportunityTenorRetrieved = Database.query(String.escapeSingleQuotes(query));
                    Map<Integer, Map<String, Object>> opportunityTenorFormatted = new Map<Integer, Map<String, Object>>();
                    Integer counter = 1;

                    // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                    for (DMT_Opportunity_Tenor__c tenor : opportunityTenorRetrieved){
                        // Creamos un mapa interno para los atributos de cada registro.
                        Map<String, Object> termAttributes = new Map<String, Object>();
                        // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                        for (String field : fieldsToQuery){
                            termAttributes.put(field, tenor.get(field));
                        }
                        // Añadimos el registro al mapa final con la clave numérica.
                        opportunityTenorFormatted.put(counter, termAttributes);
                        counter++;
                    }

                    // 5. Asignamos el mapa formateado al objeto final.
                    jsonFinal.opportunityTenor = opportunityTenorFormatted;
                }
                // Makes the query for the DMT_Opportunity_Mitigant__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Opportunity_Mitigant__c')){
                    Id oppId = relatedCase.opportunity_id__c;
                    List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Opportunity_Mitigant__c');
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Opportunity_Mitigant__c'), ',') + ' FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__r.OpportunityId = :oppId ORDER BY Mitigant_Type__c ASC';
                    List<DMT_Opportunity_Mitigant__c> opportunityMitigantRetrieved = Database.query(String.escapeSingleQuotes(query));
                    Map<Integer, Map<String, Object>> opportunityMitigantFormatted = new Map<Integer, Map<String, Object>>();
                    Integer counter = 1;

                    // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                    for (DMT_Opportunity_Mitigant__c mitigant : opportunityMitigantRetrieved){
                        // Creamos un mapa interno para los atributos de cada registro.
                        Map<String, Object> termAttributes = new Map<String, Object>();
                        // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                        for (String field : fieldsToQuery){
                            termAttributes.put(field,  mitigant.get(field));
                        }
                        // Añadimos el registro al mapa final con la clave numérica.
                        opportunityMitigantFormatted.put(counter, termAttributes);
                        counter++;
                    }

                    // 5. Asignamos el mapa formateado al objeto final.
                    jsonFinal.opportunityMitigant = opportunityMitigantFormatted;
                }
                // Makes the query for the OpportunityLineItem object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('OpportunityLineItem')){
                    Id oppId = relatedCase.opportunity_id__c;
                    List<String> fieldsToQuery = fieldMapFromObject.get('OpportunityLineItem');
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('OpportunityLineItem'), ',') + ' FROM OpportunityLineItem WHERE OpportunityId = :oppId ORDER BY DMT_Deal_Amount_Tenors__c ASC';
                    List<OpportunityLineItem> opportunityLineItemRetrieved = Database.query(String.escapeSingleQuotes(query));
                    Map<Integer, Map<String, Object>> opportunityLineItemFormatted = new Map<Integer, Map<String, Object>>();
                    Integer counter = 1;

                    // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                    for (OpportunityLineItem oppItem : opportunityLineItemRetrieved){
                        // Creamos un mapa interno para los atributos de cada registro.
                        Map<String, Object> termAttributes = new Map<String, Object>();
                        // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                        for (String field : fieldsToQuery){
                            termAttributes.put(field, oppItem.get(field));
                        }
                        // Añadimos el registro al mapa final con la clave numérica.
                        opportunityLineItemFormatted.put(counter, termAttributes);
                        counter++;
                    }
                    // 5. Asignamos el mapa formateado al objeto final.
                    jsonFinal.opportunityLineItem = opportunityLineItemFormatted;
                }
                // Makes the query for the DMT_Opportunity_Client__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Opportunity_Client__c')){
                    Id oppId = relatedCase.opportunity_id__c;
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Opportunity_Client__c'), ',') + ' FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :oppId ORDER BY Name ASC';
                    Map<Id, DMT_Opportunity_Client__c> opportunityClientRetrieved = new Map<Id, DMT_Opportunity_Client__c>((List<DMT_Opportunity_Client__c>)Database.query(String.escapeSingleQuotes(query)));
                    jsonFinal.opportunityClient = opportunityClientRetrieved;
                }
                if (fieldMapFromObject.containsKey('DMT_X_Sell__c')){
                    Id oppId = relatedCase.opportunity_id__c;
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_X_Sell__c'), ',') + ' FROM DMT_X_Sell__c WHERE Opportunity__c = :oppId ORDER BY Name ASC';
                    Map<Id, DMT_X_Sell__c> opportunityXSellRetrieved = new Map<Id, DMT_X_Sell__c>((List<DMT_X_Sell__c>)Database.query(String.escapeSingleQuotes(query)));
                    jsonFinal.opportunityXSell = opportunityXSellRetrieved;
                }

        }
            // We create the DMT_TaskStatusWhenCompleted__c record which will store the data and we relate it to the task
            DMT_TaskStatusWhenCompleted__c taskStatus = new DMT_TaskStatusWhenCompleted__c();
            // We remove the attributes part because it can cause problems in the future and just to store the fields from the view
            taskStatus.DMT_ViewFieldStatusAtClose__c = System.JSON.serialize(jsonFinal, true).replaceAll('"attributes":\\{[^\\}]*\\},?', '');
            taskStatus.Case__c = task.WhatId;
            taskStatus.DMT_AllFieldsInStatus__c = allFields;

            if (createPdf){
                //content version and core documents are generated elsewhere. if deprecated.
            }

            if (task.DMT_ViewStatusAtClose__c != null){
                taskStatus.Id = task.DMT_ViewStatusAtClose__c;
                update taskStatus;
            } else{
                insert taskStatus;
                task.DMT_ViewStatusAtClose__c = taskStatus.Id;
                update task;
            }

    }
    public static Id getApproverViewId(String ownerId, Case relatedCase) {
        // We make all these queries to obtain the items which contains the fields we want to store within the task
        Group queue = DMT_ApprovalChangeStep_Selector.getGroupById(ownerId);
        DMT_Approver__c approver = DMT_ApprovalChangeStep_Selector.getApproverByDmtGroup(queue.DeveloperName);
        Id approverViewId;
        if(relatedCase.DMT_LineOpportunity__c == 'L'){
            if(relatedCase.DMT_Line__r.RecordType.DeveloperName == 'OtherProducts'){
                approverViewId = approver.Approvers_View__c;
            } else if(relatedCase.DMT_Line__r.RecordType.DeveloperName == 'TreasurySettlement'){
                approverViewId = approver.Approvers_View_Treasury__c;
            }
        }else if(relatedCase.DMT_LineOpportunity__c == 'O'){
            if(relatedCase.opportunity_id__r.RecordType.DeveloperName == 'DMT_Opportunity'){
                approverViewId = approver.Approvers_View_Opportunity__c;
            }

        }
        if(approverViewId == null){
            System.debug(LoggingLevel.ERROR, 'The approverViewId is null in DMT_ApprovalChangeStep_Handler in the getApproverViewId method.');
        }
        return approverViewId;
    }


    @AuraEnabled(cacheable=false)
    public static void compareTasksFromCaseLWC(String lineId) {
        List<Case> records = [SELECT Id, DMT_Related_feature_name__c, DMT_LineOpportunity__c, DMT_Line__c, opportunity_id__c
                              FROM Case
                              WHERE DMT_Line__c = :lineId];
        DMT_ApprovalChangeStep_Handler.Request request = new DMT_ApprovalChangeStep_Handler.Request();
        request.records= records;system.debug('record case'+records);
        compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{request});
    }

    /**
     * @description Method that updates the task with the current status of the records from the view
     * @author Aníbal Cortés | 10-31-2024
     * @param recordId
     **/
    @InvocableMethod(label = 'Compare tasks from case' description = 'Compares tasks from a list of cases')
    public static void compareTasksFromCase(List<Request> request){
        List<Case> records = request.get(0).records;
        String passportSanctionFilter = request.get(0).passportSanctionFilter;

        if (records == null || records.isEmpty()) {
            return;
        }

        // This filter only applies to Opportunity-related cases and is optional.
        // If no filter is provided, the current behavior remains unchanged.
        if (records.get(0).DMT_LineOpportunity__c == 'O' && String.isNotBlank(passportSanctionFilter)) {
            String normalizedFilter = passportSanctionFilter.trim().toLowerCase();
            List<Case> filteredRecords = new List<Case>();
            for (Case c : records) {
                if (c.DMT_Passport_Sanction__c != null && c.DMT_Passport_Sanction__c.trim().toLowerCase() == normalizedFilter) {
                    filteredRecords.add(c);
                }
            }
            records = filteredRecords;

            if (records.isEmpty()) {
                return;
            }
        }

        Status_JSON_Wrapper jsonFinal = new Status_JSON_Wrapper();
        // Map that contains each Object and a list of its field Names
        Map<String, List<String>> fieldMapFromObject = new Map<String, List<String>>();
        //Case relatedCase = [SELECT DMT_Line__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c FROM Case WHERE Id IN :recordId WITH SECURITY_ENFORCED LIMIT 1];


        Set<Id> casesIds = new Set<Id>();
        for (Case c : records){
            casesIds.add(c.Id);
        }

        // CIBGLOBALD-3233: already-approved ("green") features must not be reset even when
        // tracked fields differ - restored after being found missing from the deployed org
        // (still present in git history, commit 92e4a3ab63, never reverted there).
        Set<Id> opportunityIds = new Set<Id>();
        for (Case caseRecord : records){
            if (caseRecord.DMT_LineOpportunity__c == 'O' && caseRecord.opportunity_id__c != null){
                opportunityIds.add(caseRecord.opportunity_id__c);
            }
        }

        Map<Id, Map<String, String>> featureStatesByOpportunityId = new Map<Id, Map<String, String>>();
        if (!opportunityIds.isEmpty()){
            List<Passport__c> passports = [
                SELECT Id, Opportunity__c, DMT_Passport_Save__c, CreatedDate
                FROM Passport__c
                WHERE Opportunity__c IN :opportunityIds
                ORDER BY CreatedDate DESC
            ];

            for (Passport__c passport : passports){
                Map<String, String> featureStates = extractFeatureStatesFromPassport(passport.DMT_Passport_Save__c);
                if (passport.Opportunity__c != null && !featureStatesByOpportunityId.containsKey(passport.Opportunity__c)){
                    featureStatesByOpportunityId.put(passport.Opportunity__c, featureStates);
                }
            }
        }

        Map<Id, Boolean> caseFeatureIsGreenMap = new Map<Id, Boolean>();
        for (Case caseRecord : records){
            Boolean isGreen = false;
            String relatedFeatureName = caseRecord.DMT_Related_feature_name__c;
            if (caseRecord.DMT_LineOpportunity__c == 'O' && caseRecord.opportunity_id__c != null && !String.isBlank(relatedFeatureName)){
                Map<String, String> featureStates = featureStatesByOpportunityId.get(caseRecord.opportunity_id__c);
                if (featureStates != null){
                    String featureState = featureStates.get(relatedFeatureName.toUpperCase());
                    isGreen = featureState != null && featureState.equalsIgnoreCase('GREEN');
                }
            }
            caseFeatureIsGreenMap.put(caseRecord.Id, isGreen);
        }

        Map<Id, Task> tasksMap = new Map<Id, Task>([SELECT Id, OwnerId, Owner.Name, DMT_Task_Type__c, WhatId, Subject, DMT_ViewStatusAtClose__c, RecordTypeId, DMT_Not_Restart__c, Status
                                                    FROM Task
                                                    WHERE WhatId IN:casesIds AND Status != :DMT_Constants.CANCELLED AND DMT_Not_Restart__c = false]);

        Map<Id, Task> tasksStatusWithTaskMap = new Map<Id, Task>();
        Map<Id, List<Task>> casesWithTasksToCancel = new Map<Id, List<Task>>();

        for (Task task : tasksMap.values()){
            tasksStatusWithTaskMap.put(task.DMT_ViewStatusAtClose__c, task);
            List<Task> tasksList = new List<Task>();
            if (casesWithTasksToCancel.containsKey(task.WhatId)){
                tasksList = casesWithTasksToCancel.get(task.WhatId);
            }
            tasksList.add(task);
            casesWithTasksToCancel.put(task.WhatId, tasksList);
        }

        Map<Id, DMT_TaskStatusWhenCompleted__c> mapTaskStatus = new Map<Id, DMT_TaskStatusWhenCompleted__c>([SELECT Id, DMT_ViewFieldStatusAtClose__c, DMT_AllFieldsInStatus__c, Case__c, Case__r.Status
                                                                                                             FROM DMT_TaskStatusWhenCompleted__c
                                                                                                             WHERE Id IN:tasksStatusWithTaskMap.keySet()
                                                                                                             ORDER BY CreatedDate ASC]);
        Map<Id, List<DMT_TaskStatusWhenCompleted__c>> mapCasesTaskStatus = new Map<Id, List<DMT_TaskStatusWhenCompleted__c>>();

        for (DMT_TaskStatusWhenCompleted__c taskStatus : mapTaskStatus.values()){
            if (taskStatus.DMT_AllFieldsInStatus__c != null){
                List<DMT_TaskStatusWhenCompleted__c> taskStatusList = new List<DMT_TaskStatusWhenCompleted__c>();
                if (mapCasesTaskStatus.containsKey(taskStatus.Case__c)){
                    taskStatusList = mapCasesTaskStatus.get(taskStatus.Case__c);
                }
                taskStatusList.add(taskStatus);
                mapCasesTaskStatus.put(taskStatus.Case__c, taskStatusList);
            }
        }

        for (DMT_TaskStatusWhenCompleted__c taskStatus : mapTaskStatus.values()){
            // We get a list of each Object.Field
            if (taskStatus.DMT_AllFieldsInStatus__c != null){
                List<String> fields = taskStatus.DMT_AllFieldsInStatus__c.split(';', 0);
                //We obtain the Object Name and Field Name for each and store it in the Map
                for (String field : fields){
                    List<String> cadenaPartida = field.split('\\.', 2);
                    String objectName = cadenaPartida.get(0);
                    String fieldName = cadenaPartida.get(1);
                    List<String> fieldsFromMap = new List<String>();
                    if (fieldMapFromObject.containsKey(objectName)){
                        fieldsFromMap = fieldMapFromObject.get(objectName);
                    }
                    // If the field is already on the list, we don't store it again to prevent duplicate fields on query
                    if (!fieldsFromMap.contains(fieldName)){
                        fieldsFromMap.add(fieldName);
                        fieldMapFromObject.put(objectName, fieldsFromMap);
                    }
                }
            }
        }

        if(!records.isEmpty() && records != null){
             System.debug('records: '+records);
            if(records.get(0).DMT_LineOpportunity__c == 'L'){
                DMT_Line__c line = [SELECT Id, Custom_Association__c
                                    FROM DMT_Line__c
                                    WHERE Id = :records.get(0).DMT_Line__c
                                    WITH SECURITY_ENFORCED];
                // Makes the query for the DMT_Line__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Line__c')){
                    Id lineId = line.Id;
                    String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get('DMT_Line__c'), ',') + ' FROM DMT_Line__c WHERE ID = :lineId';
                    List<DMT_Line__c> linesRetrieved = Database.query(String.escapeSingleQuotes(query));
                    jsonFinal.line = linesRetrieved.get(0);
                }

                // Makes the query for the DMT_TeamMember__c object and stores on the jsonFinal var
                // if (fieldMapFromObject.containsKey('DMT_TeamMember__c')) {
                //     Id lineId = line.Id;
                //     String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get('DMT_TeamMember__c'),',') + ' FROM DMT_TeamMember__c WHERE Line__c = :lineId ORDER BY Name ASC';
                //     Map<Id, DMT_TeamMember__c> membersRetrieved = new Map<Id, DMT_TeamMember__c>((List<DMT_TeamMember__c>) Database.query(String.escapeSingleQuotes(query)));
                //     jsonFinal.participantList = membersRetrieved;
                // }

                // Makes the query for the DMT_Risk_Line_Term__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Risk_Line_Term__c')){
                    Id lineId = line.Id;
                    List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Risk_Line_Term__c');
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Risk_Line_Term__c'), ',') + ' FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :lineId ORDER BY DMT_Init_Term__c ASC';
                    List<DMT_Risk_Line_Term__c> riskLineTermRetrieved = Database.query(String.escapeSingleQuotes(query));
                    Map<Integer, Map<String, Object>> riskLineListFormatted = new Map<Integer, Map<String, Object>>();
                    Integer counter = 1;

                    // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                    for (DMT_Risk_Line_Term__c term : riskLineTermRetrieved){
                        // Creamos un mapa interno para los atributos de cada registro.
                        Map<String, Object> termAttributes = new Map<String, Object>();
                        // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                        for (String field : fieldsToQuery){
                            termAttributes.put(field, term.get(field));
                        }
                        // Añadimos el registro al mapa final con la clave numérica.
                        riskLineListFormatted.put(counter, termAttributes);
                        counter++;
                    }

                    // 5. Asignamos el mapa formateado al objeto final.
                    jsonFinal.riskLineList = riskLineListFormatted;
                }

                // Makes the query for the Custom_Association__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('Custom_Association_Client__c')){
                    Id customAssociationLine = line.Custom_Association__c;
                    String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get('Custom_Association_Client__c'), ',') + ' FROM Custom_Association_Client__c WHERE Custom_Association__c = :customAssociationLine ORDER BY Name ASC';
                    Map<Id, Custom_Association_Client__c> customAssociationRetrieved = new Map<Id, Custom_Association_Client__c>((List<Custom_Association_Client__c>)Database.query(String.escapeSingleQuotes(query)));
                    jsonFinal.customAssociationClientList = customAssociationRetrieved;
                }

                // Makes the query for the DMT_Currency_Provision__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Currency_Provision__c')){
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Currency_Provision__c'), ',') + ' FROM DMT_Currency_Provision__c WHERE DMT_Risk_Line_Term__r.DMT_Line__c = :lineId ORDER BY Name ASC';
                    Map<Id, DMT_Currency_Provision__c> currencyProvision = new Map<Id, DMT_Currency_Provision__c>((List<DMT_Currency_Provision__c>)Database.query(String.escapeSingleQuotes(query)));
                    jsonFinal.currencyProvisions = currencyProvision;
                }

                // Makes the query for the DMT_Warranty__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Warranty__c')){
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Warranty__c'), ',') + ' FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__r.DMT_Line__c = :lineId ORDER BY Name ASC';
                    Map<Id, DMT_Warranty__c> warrantyRetrieved = new Map<Id, DMT_Warranty__c>((List<DMT_Warranty__c>)Database.query(String.escapeSingleQuotes(query)));
                    jsonFinal.warranties = warrantyRetrieved;
                }

                // Makes the query for the DMT_Line_Product_Item__c object and stores on the jsonFinal var
                if (fieldMapFromObject.containsKey('DMT_Line_Product_Item__c')){
                    Id lineId = line.Id;
                    List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Line_Product_Item__c');
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Line_Product_Item__c'), ',') + ' FROM DMT_Line_Product_Item__c WHERE Line__c = :lineId ORDER BY Name ASC';
                    List<DMT_Line_Product_Item__c> lineProductItemsRetrieved = Database.query(String.escapeSingleQuotes(query));

                    Map<Integer, Map<String, Object>> lineProductItemsFormatted = new Map<Integer, Map<String, Object>>();
                    Integer counter = 1;

                    // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                    for (DMT_Line_Product_Item__c term : lineProductItemsRetrieved){
                        // Creamos un mapa interno para los atributos de cada registro.
                        Map<String, Object> termAttributes = new Map<String, Object>();
                        // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                        for (String field : fieldsToQuery){
                            termAttributes.put(field, term.get(field));
                        }
                        // Añadimos el registro al mapa final con la clave numérica.
                        lineProductItemsFormatted.put(counter, termAttributes);
                        counter++;
                    }

                    // 5. Asignamos el mapa formateado al objeto final.
                    jsonFinal.lineProductItemList = lineProductItemsFormatted;
                }
            }else if(records.get(0).DMT_LineOpportunity__c == 'O'){

                // Makes the query for the Opportunity object and stores on the jsonFinal var
                    if (fieldMapFromObject.containsKey('Opportunity')){
                        Id oppId = records.get(0).opportunity_id__c;
                        String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('Opportunity'), ',') + ' FROM Opportunity WHERE ID = :oppId';
                        List<Opportunity> oppRetrieved = Database.query(String.escapeSingleQuotes(query));
                        System.debug('oppRetrieved --> ' + oppRetrieved);
                        System.debug('oppRetrieved --> ' + oppRetrieved.get(0));
                        jsonFinal.opportunity = oppRetrieved.get(0);
                    }
                    // Makes the query for the DMT_Opportunity_Tenor__c object and stores on the jsonFinal var
                    if (fieldMapFromObject.containsKey('DMT_Opportunity_Tenor__c')){
                        Id oppId = records.get(0).opportunity_id__c;
                        List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Opportunity_Tenor__c');
                        String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Opportunity_Tenor__c'), ',') + ' FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__r.OpportunityId = :oppId ORDER BY gj_nominal_amount_db__c ASC';
                        List<DMT_Opportunity_Tenor__c> opportunityTenorRetrieved = Database.query(String.escapeSingleQuotes(query));
                        Map<Integer, Map<String, Object>> opportunityTenorFormatted = new Map<Integer, Map<String, Object>>();
                        Integer counter = 1;

                        // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                        for (DMT_Opportunity_Tenor__c tenor : opportunityTenorRetrieved){
                            // Creamos un mapa interno para los atributos de cada registro.
                            Map<String, Object> termAttributes = new Map<String, Object>();
                            // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                            for (String field : fieldsToQuery){
                                termAttributes.put(field, tenor.get(field));
                            }
                            // Añadimos el registro al mapa final con la clave numérica.
                            opportunityTenorFormatted.put(counter, termAttributes);
                            counter++;
                        }

                        // 5. Asignamos el mapa formateado al objeto final.
                        jsonFinal.opportunityTenor = opportunityTenorFormatted;
                    }
                    // Makes the query for the DMT_Opportunity_Mitigant__c object and stores on the jsonFinal var
                    if (fieldMapFromObject.containsKey('DMT_Opportunity_Mitigant__c')){
                        Id oppId = records.get(0).opportunity_id__c;
                        List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Opportunity_Mitigant__c');
                        String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Opportunity_Mitigant__c'), ',') + ' FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__r.OpportunityId = :oppId ORDER BY Mitigant_Type__c ASC';
                        List<DMT_Opportunity_Mitigant__c> opportunityMitigantRetrieved = Database.query(String.escapeSingleQuotes(query));
                        Map<Integer, Map<String, Object>> opportunityMitigantFormatted = new Map<Integer, Map<String, Object>>();
                        Integer counter = 1;

                        // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                        for (DMT_Opportunity_Mitigant__c mitigant : opportunityMitigantRetrieved){
                            // Creamos un mapa interno para los atributos de cada registro.
                            Map<String, Object> termAttributes = new Map<String, Object>();
                            // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                            for (String field : fieldsToQuery){
                                termAttributes.put(field,  mitigant.get(field));
                            }
                            // Añadimos el registro al mapa final con la clave numérica.
                            opportunityMitigantFormatted.put(counter, termAttributes);
                            counter++;
                        }

                        // 5. Asignamos el mapa formateado al objeto final.
                        jsonFinal.opportunityMitigant = opportunityMitigantFormatted;
                    }
                    // Makes the query for the OpportunityLineItem object and stores on the jsonFinal var
                    if (fieldMapFromObject.containsKey('OpportunityLineItem')){
                        Id oppId = records.get(0).opportunity_id__c;
                        List<String> fieldsToQuery = fieldMapFromObject.get('OpportunityLineItem');
                        String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('OpportunityLineItem'), ',') + ' FROM OpportunityLineItem WHERE OpportunityId = :oppId ORDER BY DMT_Deal_Amount_Tenors__c ASC';
                        List<OpportunityLineItem> opportunityLineItemRetrieved = Database.query(String.escapeSingleQuotes(query));
                        Map<Integer, Map<String, Object>> opportunityLineItemFormatted = new Map<Integer, Map<String, Object>>();
                        Integer counter = 1;

                        // 4. Iteramos sobre los resultados para construir el nuevo mapa.
                        for (OpportunityLineItem oppItem : opportunityLineItemRetrieved){
                            // Creamos un mapa interno para los atributos de cada registro.
                            Map<String, Object> termAttributes = new Map<String, Object>();
                            // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                            for (String field : fieldsToQuery){
                                termAttributes.put(field, oppItem.get(field));
                            }
                            // Añadimos el registro al mapa final con la clave numérica.
                            opportunityLineItemFormatted.put(counter, termAttributes);
                            counter++;
                        }
                        // 5. Asignamos el mapa formateado al objeto final.
                        jsonFinal.opportunityLineItem = opportunityLineItemFormatted;
                    }
                    // Makes the query for the DMT_Opportunity_Client__c object and stores on the jsonFinal var
                    if (fieldMapFromObject.containsKey('DMT_Opportunity_Client__c')){
                        Id oppId = records.get(0).opportunity_id__c;
                        String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Opportunity_Client__c'), ',') + ' FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :oppId ORDER BY Name ASC';
                        Map<Id, DMT_Opportunity_Client__c> opportunityClientRetrieved = new Map<Id, DMT_Opportunity_Client__c>((List<DMT_Opportunity_Client__c>)Database.query(String.escapeSingleQuotes(query)));
                        jsonFinal.opportunityClient = opportunityClientRetrieved;
                    }
                    if (fieldMapFromObject.containsKey('DMT_X_Sell__c')){
                        Id oppId = records.get(0).opportunity_id__c;
                        String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_X_Sell__c'), ',') + ' FROM DMT_X_Sell__c WHERE Opportunity__c = :oppId ORDER BY Name ASC';
                        Map<Id, DMT_X_Sell__c> opportunityXSellRetrieved = new Map<Id, DMT_X_Sell__c>((List<DMT_X_Sell__c>)Database.query(String.escapeSingleQuotes(query)));
                        jsonFinal.opportunityXSell = opportunityXSellRetrieved;
                    }
            }
        }



        String jsonFinalSerialized = System.JSON.serialize(jsonFinal, true).replaceAll('"attributes":\\{[^\\}]*\\},?', '');
        Map<String, Object> mapJsonFinal = (Map<String, Object>)JSON.deserializeUntyped(jsonFinalSerialized);
        List<Case> casesToUpdate = new List<Case>();
        List<Task> tasksToUpdate = new List<Task>();
        List<Task> tasksToCreate = new List<Task>();

        for (Id caseId : mapCasesTaskStatus.keySet()){
            Boolean isDifferent = false;

            for (Integer i = 0; i < mapCasesTaskStatus.get(caseId).size(); i++){
                Map<String, Object> mapTaskStatusJson = (Map<String, Object>)JSON.deserializeUntyped(mapCasesTaskStatus.get(caseId)[i].DMT_ViewFieldStatusAtClose__c);
                for (String fieldName : mapTaskStatusJson.keySet()){
                    //if (!isDifferent) {
                    if (!fieldName.equalsIgnoreCase('line') && !fieldName.equalsIgnoreCase('opportunity')){
                        Map<String, Object> listFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> listFromJson = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        if (listFromTask != null && listFromTask.size() == listFromJson.size() && listFromTask.keySet().equals(listFromJson.keySet())){
                            for (String item : listFromTask.keySet()){
                                System.debug( 'listFromTask.get(item) --> ' + listFromTask.get(item));
                                Map<String, Object> itemFromTask = (Map<String, Object>)listFromTask.get(item);
                                Map<String, Object> itemFull = (Map<String, Object>)listFromJson.get(item);
                                for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                    if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){
                                        if (caseFeatureIsGreenMap.containsKey(caseId) && caseFeatureIsGreenMap.get(caseId)){
                                            continue;
                                        }
                                        tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                        if (!isDifferent){
                                            tasksToCreate.add(DMT_ApprovalChangeStep_Helper.createResetTask(tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id)));
                                            casesToUpdate.add(DMT_ApprovalChangeStep_Helper.createResetCase(caseId, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).OwnerId));
                                        }
                                        isDifferent = true;
                                    }
                                }
                            }
                        } else{
                            if (caseFeatureIsGreenMap.containsKey(caseId) && caseFeatureIsGreenMap.get(caseId)){
                                continue;
                            }
                            tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                            if (!isDifferent){
                                tasksToCreate.add(DMT_ApprovalChangeStep_Helper.createResetTask(tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id)));
                                casesToUpdate.add(DMT_ApprovalChangeStep_Helper.createResetCase(caseId, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).OwnerId));
                            }
                            isDifferent = true;
                        }
                    } else if (fieldName.equalsIgnoreCase('line')){
                        Map<String, Object> itemFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> itemFull = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        if (itemFromTask != null && !itemFromTask.isEmpty()){
                            for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                if (fieldFromItem.equalsIgnoreCase('Client__r')){
                                    Map<String, Object> clientFromLine = (Map<String, Object>)itemFromTask.get(fieldFromItem);
                                    Map<String, Object> clientFromJSONFull = (Map<String, Object>)itemFull.get(fieldFromItem);
                                    for (String fieldFromClient : clientFromLine.keySet()){
                                        if (clientFromJSONFull.get(fieldFromClient) != clientFromLine.get(fieldFromClient)){
                                            tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;

                                            if (!isDifferent){
                                                tasksToCreate.add(DMT_ApprovalChangeStep_Helper.createResetTask(tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id)));
                                                casesToUpdate.add(DMT_ApprovalChangeStep_Helper.createResetCase(caseId, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).OwnerId));
                                            }
                                            isDifferent = true;
                                        }
                                    }
                                } else if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){

                                    tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                    if (!isDifferent){
                                        tasksToCreate.add(DMT_ApprovalChangeStep_Helper.createResetTask(tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id)));
                                        casesToUpdate.add(DMT_ApprovalChangeStep_Helper.createResetCase(caseId, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).OwnerId));
                                    }
                                    isDifferent = true;
                                }
                            }
                        }
                    }else if (fieldName.equalsIgnoreCase('opportunity')){
                        Map<String, Object> itemFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> itemFull = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        if (itemFromTask != null && !itemFromTask.isEmpty()){
                            for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){
                                    if (caseFeatureIsGreenMap.containsKey(caseId) && caseFeatureIsGreenMap.get(caseId)){
                                        continue;
                                    }
                                    tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                    if (!isDifferent){
                                        tasksToCreate.add(DMT_ApprovalChangeStep_Helper.createResetTask(tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id)));
                                        casesToUpdate.add(DMT_ApprovalChangeStep_Helper.createResetCase(caseId, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).OwnerId));
                                    }
                                    isDifferent = true;
                                }
                            }
                        }
                    }

                    //}
                }
                if (isDifferent){
                    tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                }
            }

            // if (!isDifferent && mapCasesTaskStatus.get(caseId)[0].Case__r.Status != DMT_Constants.FINISHED ) {
            //     tasksToCreate.add(DMT_ApprovalChangeStep_Helper.createResetTask(tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[mapCasesTaskStatus.get(caseId).size()-1].Id)));
            //     //isDifferent = true;
            //     casesToUpdate.add(DMT_ApprovalChangeStep_Helper.createResetCase(caseId, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[mapCasesTaskStatus.get(caseId).size()-1].Id).OwnerId));
            // }
            if (isDifferent){
                for (Task t : casesWithTasksToCancel.get(caseId)){
                    if (t.Status == DMT_Constants.FINISHED){
                        Task task = t.clone(true, true, false);
                        task.Status = 'Completed';
                        tasksToUpdate.add(task);
                    }
                    if (t.Status != DMT_Constants.COMPLETED && t.Status != DMT_Constants.FINISHED){
                        Task task = t.clone(true, true, false);
                        task.Status = 'Cancelled';
                        tasksToUpdate.add(task);
                    }
                }
            }

        }
        System.debug('Queries usadas before tasksToUpdate: ' + Limits.getQueries());
        if (tasksToUpdate.size() > 0){
            update tasksToUpdate;
        }
        System.debug('Queries usadas before casesToUpdate: ' + Limits.getQueries());
        if (casesToUpdate.size() > 0){
            update casesToUpdate;
        }
        System.debug('Queries usadas before tasksToCreate: ' + Limits.getQueries());
        if (tasksToCreate.size() > 0){
            insert tasksToCreate;
        }
        System.debug('Queries usadas before updateTaskWithStatus: ' + Limits.getQueries());
        for (Task t : tasksToCreate) {
            System.debug('t debug: ' + t);
            System.debug('Queries usadas inside for: ' + Limits.getQueries());
            updateTaskWithStatus(t.Id, false);
        }
        System.debug('Queries usadas after updateTaskWithStatus: ' + Limits.getQueries());
    }

    /**
     * @description CIBGLOBALD-3233: parses the Passport JSON and returns each feature's
     * current stateName keyed by uppercased feature name, used to identify already-approved
     * ("green") features so their cases are skipped when resetting tasks.
     * @author Alejandro Muñoz Lujan | 05-05-2026
     **/
    private static Map<String, String> extractFeatureStatesFromPassport(String passportJson){
        Map<String, String> featureStates = new Map<String, String>();
        if (String.isBlank(passportJson)){
            return featureStates;
        }

        try {
            Map<String, Object> rootMap = (Map<String, Object>)JSON.deserializeUntyped(passportJson);
            if (rootMap == null){
                return featureStates;
            }

            Map<String, Object> dataMap = (Map<String, Object>)rootMap.get('data');
            Object featuresObj = dataMap != null ? dataMap.get('features') : rootMap.get('features');
            if (featuresObj == null || !(featuresObj instanceof List<Object>)){
                return featureStates;
            }

            for (Object featureObj : (List<Object>)featuresObj){
                if (featureObj instanceof Map<String, Object>){
                    Map<String, Object> featureMap = (Map<String, Object>)featureObj;
                    String featureName = (String)featureMap.get('name');
                    String stateName = (String)featureMap.get('stateName');
                    if (!String.isBlank(featureName) && !String.isBlank(stateName)){
                        featureStates.put(featureName.toUpperCase(), stateName);
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Error parsing passport JSON in DMT_ApprovalChangeStep_Handler.extractFeatureStatesFromPassport: ' + ex.getMessage());
        }

        return featureStates;
    }

    /**
     * @description Method that previews the task that will be re-opened for every case.
     * @author Aníbal Cortés | 10-02-2025
     **/
    @AuraEnabled
    public static List<FeatureChangeWrapper> previewCompareTasksFromCase(String lineId){
        List<Case> records = [SELECT Id, DMT_Related_feature_name__c
                              FROM Case
                              WHERE DMT_Line__c = :lineId];
        Status_JSON_Wrapper jsonFinal = new Status_JSON_Wrapper();
        // Map that contains each Object and a list of its field Names
        Map<String, List<String>> fieldMapFromObject = new Map<String, List<String>>();
        DMT_Line__c line = [SELECT Id, Custom_Association__c
                            FROM DMT_Line__c
                            WHERE Id = :lineId
                            WITH SECURITY_ENFORCED];
        Map<Id, String> mapCasesFeatureName = new Map<Id, String>();
        for (Case c : records){
            mapCasesFeatureName.put(c.Id, c.DMT_Related_feature_name__c);
        }

        Map<Id, Task> tasksMap = new Map<Id, Task>([SELECT Id, OwnerId, Owner.Name, DMT_Task_Type__c, WhatId, Subject, DMT_ViewStatusAtClose__c, RecordTypeId, DMT_Not_Restart__c, Status
                                                    FROM Task
                                                    WHERE WhatId IN:mapCasesFeatureName.keySet() AND Status != :DMT_Constants.CANCELLED AND DMT_Not_Restart__c = false]);

        Map<Id, Task> tasksStatusWithTaskMap = new Map<Id, Task>();
        Map<Id, List<Task>> casesWithTasksToCancel = new Map<Id, List<Task>>();

        for (Task task : tasksMap.values()){
            tasksStatusWithTaskMap.put(task.DMT_ViewStatusAtClose__c, task);
            List<Task> tasksList = new List<Task>();
            if (casesWithTasksToCancel.containsKey(task.WhatId)){
                tasksList = casesWithTasksToCancel.get(task.WhatId);
            }
            tasksList.add(task);
            casesWithTasksToCancel.put(task.WhatId, tasksList);
        }

        Map<Id, DMT_TaskStatusWhenCompleted__c> mapTaskStatus = new Map<Id, DMT_TaskStatusWhenCompleted__c>([SELECT Id, DMT_ViewFieldStatusAtClose__c, DMT_AllFieldsInStatus__c, Case__c, Case__r.Status
                                                                                                             FROM DMT_TaskStatusWhenCompleted__c
                                                                                                             WHERE Id IN:tasksStatusWithTaskMap.keySet()
                                                                                                             ORDER BY CreatedDate ASC]);
        Map<Id, List<DMT_TaskStatusWhenCompleted__c>> mapCasesTaskStatus = new Map<Id, List<DMT_TaskStatusWhenCompleted__c>>();

        for (DMT_TaskStatusWhenCompleted__c taskStatus : mapTaskStatus.values()){
            if (taskStatus.DMT_AllFieldsInStatus__c != null){
                List<DMT_TaskStatusWhenCompleted__c> taskStatusList = new List<DMT_TaskStatusWhenCompleted__c>();
                if (mapCasesTaskStatus.containsKey(taskStatus.Case__c)){
                    taskStatusList = mapCasesTaskStatus.get(taskStatus.Case__c);
                }
                taskStatusList.add(taskStatus);
                mapCasesTaskStatus.put(taskStatus.Case__c, taskStatusList);
            }
        }

        for (DMT_TaskStatusWhenCompleted__c taskStatus : mapTaskStatus.values()){
            // We get a list of each Object.Field
            if (taskStatus.DMT_AllFieldsInStatus__c != null){
                List<String> fields = taskStatus.DMT_AllFieldsInStatus__c.split(';', 0);
                //We obtain the Object Name and Field Name for each and store it in the Map
                for (String field : fields){
                    List<String> cadenaPartida = field.split('\\.', 2);
                    String objectName = cadenaPartida.get(0);
                    String fieldName = cadenaPartida.get(1);
                    List<String> fieldsFromMap = new List<String>();
                    if (fieldMapFromObject.containsKey(objectName)){
                        fieldsFromMap = fieldMapFromObject.get(objectName);
                    }
                    // If the field is already on the list, we don't store it again to prevent duplicate fields on query
                    if (!fieldsFromMap.contains(fieldName)){
                        fieldsFromMap.add(fieldName);
                        fieldMapFromObject.put(objectName, fieldsFromMap);
                    }
                }
            }
        }

        // Makes the query for the DMT_Line__c object and stores on the jsonFinal var
        if (fieldMapFromObject.containsKey('DMT_Line__c')){
            //Id lineId = line.Id;
            String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get('DMT_Line__c'), ',') + ' FROM DMT_Line__c WHERE ID = :lineId';
            List<DMT_Line__c> linesRetrieved = Database.query(String.escapeSingleQuotes(query));
            jsonFinal.line = linesRetrieved.get(0);
        }

        // Makes the query for the DMT_Risk_Line_Term__c object and stores on the jsonFinal var
        if (fieldMapFromObject.containsKey('DMT_Risk_Line_Term__c')){
            //Id lineId = line.Id;
            List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Risk_Line_Term__c');
            String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Risk_Line_Term__c'), ',') + ' FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :lineId ORDER BY DMT_Init_Term__c ASC';
            List<DMT_Risk_Line_Term__c> riskLineTermRetrieved = Database.query(String.escapeSingleQuotes(query));
            Map<Integer, Map<String, Object>> riskLineListFormatted = new Map<Integer, Map<String, Object>>();
            Integer counter = 1;

            // 4. Iteramos sobre los resultados para construir el nuevo mapa.
            for (DMT_Risk_Line_Term__c term : riskLineTermRetrieved){
                // Creamos un mapa interno para los atributos de cada registro.
                Map<String, Object> termAttributes = new Map<String, Object>();
                // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                for (String field : fieldsToQuery){
                    termAttributes.put(field, term.get(field));
                }
                // Añadimos el registro al mapa final con la clave numérica.
                riskLineListFormatted.put(counter, termAttributes);
                counter++;
            }

            // 5. Asignamos el mapa formateado al objeto final.
            jsonFinal.riskLineList = riskLineListFormatted;
        }

        // Makes the query for the Custom_Association__c object and stores on the jsonFinal var
        if (fieldMapFromObject.containsKey('Custom_Association_Client__c')){
            Id customAssociationLine = line.Custom_Association__c;
            String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get('Custom_Association_Client__c'), ',') + ' FROM Custom_Association_Client__c WHERE Custom_Association__c = :customAssociationLine ORDER BY Name ASC';
            Map<Id, Custom_Association_Client__c> customAssociationRetrieved = new Map<Id, Custom_Association_Client__c>((List<Custom_Association_Client__c>)Database.query(String.escapeSingleQuotes(query)));
            jsonFinal.customAssociationClientList = customAssociationRetrieved;
        }

        // Makes the query for the DMT_Currency_Provision__c object and stores on the jsonFinal var
        if (fieldMapFromObject.containsKey('DMT_Currency_Provision__c')){
            String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Currency_Provision__c'), ',') + ' FROM DMT_Currency_Provision__c WHERE DMT_Risk_Line_Term__r.DMT_Line__c = :lineId ORDER BY Name ASC';
            Map<Id, DMT_Currency_Provision__c> currencyProvision = new Map<Id, DMT_Currency_Provision__c>((List<DMT_Currency_Provision__c>)Database.query(String.escapeSingleQuotes(query)));
            jsonFinal.currencyProvisions = currencyProvision;
        }

        // Makes the query for the DMT_Warranty__c object and stores on the jsonFinal var
        if (fieldMapFromObject.containsKey('DMT_Warranty__c')){
            String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Warranty__c'), ',') + ' FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__r.DMT_Line__c = :lineId ORDER BY Name ASC';
            Map<Id, DMT_Warranty__c> warrantyRetrieved = new Map<Id, DMT_Warranty__c>((List<DMT_Warranty__c>)Database.query(String.escapeSingleQuotes(query)));
            jsonFinal.warranties = warrantyRetrieved;
        }

        // Makes the query for the DMT_Line_Product_Item__c object and stores on the jsonFinal var
        if (fieldMapFromObject.containsKey('DMT_Line_Product_Item__c')){
            //Id lineId = line.Id;
            List<String> fieldsToQuery = fieldMapFromObject.get('DMT_Line_Product_Item__c');
            String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Line_Product_Item__c'), ',') + ' FROM DMT_Line_Product_Item__c WHERE Line__c = :lineId ORDER BY Name ASC';
            List<DMT_Line_Product_Item__c> lineProductItemsRetrieved = Database.query(String.escapeSingleQuotes(query));

            Map<Integer, Map<String, Object>> lineProductItemsFormatted = new Map<Integer, Map<String, Object>>();
            Integer counter = 1;

            // 4. Iteramos sobre los resultados para construir el nuevo mapa.
            for (DMT_Line_Product_Item__c term : lineProductItemsRetrieved){
                // Creamos un mapa interno para los atributos de cada registro.
                Map<String, Object> termAttributes = new Map<String, Object>();
                // Poblamos el mapa de atributos dinámicamente con los campos que consultamos.
                for (String field : fieldsToQuery){
                    termAttributes.put(field, term.get(field));
                }
                // Añadimos el registro al mapa final con la clave numérica.
                lineProductItemsFormatted.put(counter, termAttributes);
                counter++;
            }

            // 5. Asignamos el mapa formateado al objeto final.
            jsonFinal.lineProductItemList = lineProductItemsFormatted;
        }

        String jsonFinalSerialized = System.JSON.serialize(jsonFinal, true).replaceAll('"attributes":\\{[^\\}]*\\},?', '');
        Map<String, Object> mapJsonFinal = (Map<String, Object>)JSON.deserializeUntyped(jsonFinalSerialized);

        List<FeatureChangeWrapper> listFeaturesToReturn = new List<FeatureChangeWrapper>();

        Map<String, Map<String, WRAPPER_Response_NewField>> mapFeaturesWithDifferentField = new Map<String, Map<String, WRAPPER_Response_NewField>>();
        Map<String, Task> mapFeatureWithTaskToCreate = new Map<String, Task>();

        for (Id caseId : mapCasesTaskStatus.keySet()){
            Boolean isDifferent = false;

            for (Integer i = 0; i < mapCasesTaskStatus.get(caseId).size(); i++){
                Map<String, Object> mapTaskStatusJson = (Map<String, Object>)JSON.deserializeUntyped(mapCasesTaskStatus.get(caseId)[i].DMT_ViewFieldStatusAtClose__c);
                for (String fieldName : mapTaskStatusJson.keySet()){
                    if (!fieldName.equalsIgnoreCase('line')){
                        Map<String, Object> listFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> listFromJson = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        System.debug('listFromTask: ' + listFromTask);
                        System.debug('listFromJson: ' + listFromJson);
                        if (listFromTask != null && listFromTask.size() == listFromJson.size() && listFromTask.keySet().equals(listFromJson.keySet())){
                            for (String item : listFromTask.keySet()){
                                Map<String, Object> itemFromTask = (Map<String, Object>)listFromTask.get(item);
                                Map<String, Object> itemFull = (Map<String, Object>)listFromJson.get(item);
                                for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                    if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){
                                        if (!isDifferent){
                                            String featureName = mapCasesFeatureName.get(caseId);
                                            Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                            WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                            valuesFromField.oldValue = (String)itemFull.get(fieldFromItem);
                                            valuesFromField.newValue = (String)itemFromTask.get(fieldFromItem);
                                            fieldWithValues.put(fieldFromItem, valuesFromField);
                                            mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                            mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                                        } else{
                                            String featureName = mapCasesFeatureName.get(caseId);
                                            Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                            WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                            valuesFromField.oldValue = (String)itemFull.get(fieldFromItem);
                                            valuesFromField.newValue = (String)itemFromTask.get(fieldFromItem);
                                            fieldWithValues.put(fieldFromItem, valuesFromField);
                                            mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                        }
                                        isDifferent = true;
                                    }
                                }
                            }
                        } else{

                            tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                            if (!isDifferent){
                                String featureName = mapCasesFeatureName.get(caseId);
                                Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                valuesFromField.message = 'The list of ' + fieldName + 'is different than before';
                                fieldWithValues.put(fieldName, valuesFromField);
                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                            } else{
                                String featureName = mapCasesFeatureName.get(caseId);
                                Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                 valuesFromField.message = 'The list of ' + fieldName + 'is different than before';
                                fieldWithValues.put(fieldName, valuesFromField);
                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                            }
                            isDifferent = true;
                        }
                    } else{
                        Map<String, Object> itemFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> itemFull = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        if (itemFromTask != null && !itemFromTask.isEmpty()){
                            for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                if (fieldFromItem.equalsIgnoreCase('Client__r')){
                                    Map<String, Object> clientFromLine = (Map<String, Object>)itemFromTask.get(fieldFromItem);
                                    Map<String, Object> clientFromJSONFull = (Map<String, Object>)itemFull.get(fieldFromItem);
                                    for (String fieldFromClient : clientFromLine.keySet()){
                                        if (clientFromJSONFull.get(fieldFromClient) != clientFromLine.get(fieldFromClient)){
                                            tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                            if (!isDifferent){
                                                String featureName = mapCasesFeatureName.get(caseId);
                                                Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                                valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                                valuesFromField.newValue = (String)itemFromTask.get(fieldFromItem);
                                                fieldWithValues.put(fieldFromItem, valuesFromField);
                                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                                mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                                            } else{
                                                String featureName = mapCasesFeatureName.get(caseId);
                                                Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                                valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                                valuesFromField.newValue = (String) itemFromTask.get(fieldFromItem);
                                                fieldWithValues.put(fieldFromItem, valuesFromField);
                                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                            }
                                            isDifferent = true;
                                        }
                                    }
                                } else if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){

                                    tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                    if (!isDifferent){
                                        String featureName = mapCasesFeatureName.get(caseId);
                                        Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                        WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                        valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                        valuesFromField.newValue = (String) itemFromTask.get(fieldFromItem);
                                        fieldWithValues.put(fieldFromItem, valuesFromField);
                                        mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                        mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                                    } else{
                                        String featureName = mapCasesFeatureName.get(caseId);
                                        Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                        WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                        valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                        valuesFromField.newValue = (String) itemFromTask.get(fieldFromItem);
                                        fieldWithValues.put(fieldFromItem, valuesFromField);
                                        mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                    }
                                    isDifferent = true;
                                }
                            }
                        }
                    }
                }
            }

            if (!isDifferent){
                String featureName = mapCasesFeatureName.get(caseId);
                mapFeaturesWithDifferentField.put(featureName, null);
            }
        }

        for (String featureName : mapFeaturesWithDifferentField.keySet()){
            FeatureChangeWrapper feature = new FeatureChangeWrapper();
            feature.featureName = featureName;
            feature.changedFields = mapFeaturesWithDifferentField.get(featureName);
            feature.taskToRecreate = mapFeatureWithTaskToCreate.get(featureName);

            listFeaturesToReturn.add(feature);
        }

        return listFeaturesToReturn;
    }

    public class Status_JSON_Wrapper{
        public DMT_Line__c line;
        //public Map<Id, DMT_TeamMember__c> participantList;
        public Map<Integer, Map<String, Object>> riskLineList;
        public Map<Id, Custom_Association_Client__c> customAssociationClientList;
        public Map<Integer, Map<String, Object>> lineProductItemList;
        public Map<Id, DMT_Warranty__c> warranties;
        public Map<Id, DMT_Currency_Provision__c>  currencyProvisions;

        // Opportunity
        public Opportunity opportunity;
        public Map<Integer, Map<String, Object>>  opportunityTenor;
        public Map<Integer, Map<String, Object>>  opportunityMitigant;
        public Map<Id, 	DMT_Opportunity_Client__c>  opportunityClient;
        public Map<Integer, Map<String, Object>>  opportunityLineItem;
        public Map<Id, 	altm__Commercial_Alert__c>  altmCommercialAlert;
        public Map<Id, 	DMT_X_Sell__c>  opportunityXSell;

    }

    public class Response{
        @InvocableVariable
        public List<WRAPPER_Response_Flow> messageList;
    }

    public class Request{
        @InvocableVariable
        public List<Case> records;

        @InvocableVariable
        public String passportSanctionFilter;
    }

    public class WRAPPER_Response_Flow{
        @InvocableVariable
        public Id caseId;
        @InvocableVariable
        public Id taskType;
        @InvocableVariable
        public Id approver;
    }

    public class WRAPPER_Response_NewField{
        @AuraEnabled
        public String oldValue;
        @AuraEnabled
        public String newValue;
        @AuraEnabled
        public String message;
    }

    public class WRAPPER_Response_TaskFields{
        @AuraEnabled
        public String taskTypeName;
        @AuraEnabled
        public String taskOwner;
    }

    public class FeatureChangeWrapper{
        @AuraEnabled
        public String featureName;
        @AuraEnabled
        public Map<String, WRAPPER_Response_NewField> changedFields;
        @AuraEnabled
        public Task taskToRecreate;

    }

}