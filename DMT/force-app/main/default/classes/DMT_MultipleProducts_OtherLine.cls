public with sharing class DMT_MultipleProducts_OtherLine {

    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
        @InvocableVariable
        public String Family;
        @InvocableVariable
        public String Subfamily;
        @InvocableVariable
        public String Category;
        @InvocableVariable
        public String Subcategory;
        @InvocableVariable
        public String Globalproduct;
        @InvocableVariable
        public String lineId;
        @InvocableVariable
        public String lastLevelId;
        @InvocableVariable
        public String groupPriorityLineId;
        @InvocableVariable
        public String maxTerm;
    }

    public class Response {
        @InvocableVariable
        public DMT_Risk_Line_Term__c updatedRecordId;

        @InvocableVariable
        public List<DMT_Risk_Line_Term__c> newRecordIds;
    }

    @InvocableMethod(label='Split Risk Line Term by Semicolon')
    public static List<Response> splitRecords(List<Request> requests) {
        List<Response> results = new List<Response>();


        List<DMT_Risk_Line_Term__c> toUpdate = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> toInsert = new List<DMT_Risk_Line_Term__c>();

        for (Request req : requests) {
            Response res = new Response();
            res.newRecordIds = new List<DMT_Risk_Line_Term__c>();
            DMT_Risk_Line_Term__c original = new DMT_Risk_Line_Term__c(Id = req.recordId, DMT_End_Term__c = req.maxTerm);
            if (original == null) {
                results.add(res);
                continue;
            }

            // Procesamos todos los campos definidos
            processField(original, 'g_global_product_family_id__c', req.Family, toInsert, req);
            processField(original, 'g_global_product_subfamily_id__c', req.Subfamily, toInsert, req);
            processField(original, 'g_global_product_category_id__c', req.Category, toInsert, req);
            processField(original, 'g_gbl_product_subcategory_id__c', req.Subcategory, toInsert, req);
            processField(original, 'g_global_product_id__c', req.Globalproduct, toInsert, req);
            //processField(original, 'DMT_End_Term__c', req.maxTerm, toInsert, req);
            toUpdate.add(original);
            res.updatedRecordId = original;
            res.newRecordIds = toInsert;
            results.add(res);
        }
        if (!toUpdate.isEmpty()) {
            List<DMT_Risk_Line_Term__c> normalizedToUpdate = normalizeProductHierarchy(toUpdate);

            update normalizedToUpdate;
        }

        if (!toInsert.isEmpty()) {
            List<DMT_Risk_Line_Term__c> normalizedToInsert = normalizeProductHierarchy(toInsert);
            insert normalizedToInsert;
        }

        return results;
    }

    private static void processField(
        DMT_Risk_Line_Term__c original,
        String fieldName,
        String value,
        List<DMT_Risk_Line_Term__c> toInsert,
        Request req
    ) {
        List<String> trimmedParts = new List<String>();
        if (value != null && !String.isBlank(value) && value.contains(';')){
            List<String> parts = value.split(';');
            for (String p : parts) {
                if (String.isNotBlank(p)) {
                    trimmedParts.add(p.trim());
                }
            }
        }


        if (!trimmedParts.isEmpty()){
            // 1) Actualizamos el registro original con el primer valor
            setFieldValue(original, fieldName, trimmedParts[0]);
            setFieldValue(original, 'DMT_Init_Term__c', '0' );
            setFieldValue(original, 'DMT_End_Term__c', req.maxTerm?.split(';').size() > 0 ? req.maxTerm?.split(';')[0] : '');

        // 2) Creamos clones por cada valor extra
            Integer count = 0;
            for (Integer i = 1; i < trimmedParts.size(); i++) {
                DMT_Risk_Line_Term__c cloneRec = original.clone(false, true, false, false);
                setFieldValue(cloneRec, fieldName, trimmedParts[i]);
                cloneRec.DMT_Line__c = req.lineId;
                cloneRec.DMT_LastLevelId__c = req.lastLevelId;
                cloneRec.g_limit_last_level_type__c = req.lastLevelId;
                cloneRec.DMT_Init_Term__c = '0';
                cloneRec.DMT_End_Term__c = req.maxTerm?.split(';').size() > i ? req.maxTerm?.split(';')[i] : null;
                cloneRec.gf_group_priority_line_id__c = Integer.valueOf(req.groupPriorityLineId) > 9 ? String.valueOf(Integer.valueOf(req.groupPriorityLineId) + 1 + count) : '0' + String.valueOf(Integer.valueOf(req.groupPriorityLineId) + 1 + count) ;
                toInsert.add(cloneRec);
                count++;
            }
        }else{
            setFieldValue(original, fieldName, value);
        }

    }

    private static void setFieldValue(DMT_Risk_Line_Term__c record, String fieldName, String value) {
        record.put(fieldName, value);
    }

    private static List<DMT_Risk_Line_Term__c> normalizeProductHierarchy(List<DMT_Risk_Line_Term__c> records) {
    List<DMT_Risk_Line_Term__c> normalized = new List<DMT_Risk_Line_Term__c>();

    for (DMT_Risk_Line_Term__c record : records) {
        // Obtener todos los códigos disponibles
        String[] allCodes = new List<String>{
            (String) record.get('g_global_product_id__c'),
            (String) record.get('g_gbl_product_subcategory_id__c'),
            (String) record.get('g_global_product_category_id__c'),
            (String) record.get('g_global_product_subfamily_id__c'),
            (String) record.get('g_global_product_family_id__c')
        };

        // Buscar el valor más específico informado
        String baseCode;
        for (String code : allCodes) {
            if (!String.isBlank(code)) {
                baseCode = code.trim();
                break;
            }
        }

        // Validación básica del código
        if (String.isBlank(baseCode) || baseCode.length() != 10 || !Pattern.matches('^[0-9]+$', baseCode)) {
            normalized.add(record); // No se puede normalizar
            continue;
        }

        // Determinar el nivel jerárquico según ceros finales
        Integer level;
        if (baseCode.endsWith('00000000')) {
            level = 1; // Family
        } else if (baseCode.endsWith('000000')) {
            level = 2; // Subfamily
        } else if (baseCode.endsWith('0000')) {
            level = 3; // Category
        } else if (baseCode.endsWith('00')) {
            level = 4; // Subcategory
        } else {
            level = 5; // Global Product
        }

        // Limpiar todos los campos primero
        record.g_global_product_family_id__c = null;
        record.g_global_product_subfamily_id__c = null;
        record.g_global_product_category_id__c = null;
        record.g_gbl_product_subcategory_id__c = null;
        record.g_global_product_id__c = null;

        // Asignar valores correctos según el nivel detectado
        if (level >= 1) {
            record.g_global_product_family_id__c = baseCode.left(2) + '00000000';
        }
        if (level >= 2) {
            record.g_global_product_subfamily_id__c = baseCode.left(4) + '000000';
        }
        if (level >= 3) {
            record.g_global_product_category_id__c = baseCode.left(6) + '0000';
        }
        if (level >= 4) {
            record.g_gbl_product_subcategory_id__c = baseCode.left(8) + '00';
        }
        if (level == 5) {
            record.g_global_product_id__c = baseCode;
        }

        normalized.add(record);
    }

    return normalized;
    }
}