/**-------------------------------------------------------------------------------------------
* @Name     DMT_Currency_Conversion_Utils
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-05-05
* --------------------------------------------------------------------------------------------
* @Description Clase que recibe datos y les aplica un factor de conversion de unidades
* por ejemplo puede recibir un monto de 10 y converirlo en 10'000.000 o recibir 10'000.000
* y convertirlo en 10 dependiendo del factor de conversion que se haya definido en el metadata
* DMT_Currency_Conversion__mdt, la llave es el CurrencyIsoCode.    
* --------------------------------------------------------------------------------------------
*/
public with sharing class DMT_Currency_Conversion_Utils {

    public static final Map<String, String> localeFormats = new Map<String, String>{
                                                                'en_US' => '#,###.00',
                                                                'es_ES' => '#.###,00',
                                                                'es_CO' => '#.###,00',
                                                                'es_PE' => '#.###,00'
            };

    /**
     * @Description Convierte montos individuales basados en un 'recordId' y una 'action'.
     *              Extrae el CurrencyIsoCode de DMT_Line__c usando el 'recordId', busca el factor de conversion
     *              en DMT_Currency_Conversion__mdt y aplica la conversion a todos los campos numericos en inputMap
     *              (excepto 'recordId' y 'action').
     *              La 'action' puede ser 'input' (ingreso en base de datos, multiplica por factor) o
     *              'output' (mostrar dato desde base de datos divide por factor).
     * 
     * @param inputMap Mapa que contiene los datos de entrada. Debe incluir:
     *                 - 'recordId' (Id): El Id del registro DMT_Line__c para obtener el CurrencyIsoCode.
     *                 - 'action' (String): La acción a realizar ('input' para grabar en BD, 'output' para leer de BD).
     *                 - Otros campos (Decimal/Integer/Double): Valores numericos a convertir.
     * @param outMap Mapa donde se almacenaran los resultados de la conversion. Se poblara con los valores
     *               convertidos y/o mensajes de error ('error', 'error_nombreCampo', 'exceptionList').
     * @return Map<String, Object> El mapa 'outMap' modificado con los montos convertidos.
     *         Si ocurre un error, el mapa contendra una clave 'error' con el mensaje y
     *         'exceptionList' con los detalles de la excepcion. Los valores originales del inputMap
     *         (excluyendo recordId y action) se copian al outMap en caso de error o si no hay factor de conversion.
     * @throws DTM_Currency_Exception Si 'recordId' o 'action' no están presentes o son invalidos,
     *         o si no se encuentra la linea o el CurrencyIsoCode para el 'recordId'.
     */
    public static Map<String, Object> DMT_Single_Amount_Conversion(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options
    ) {
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

        try {
            
            // Obtener recordId, este es el Id de la linea
            Id recordId = (inputMap.containsKey('recordId') && inputMap.get('recordId') instanceof Id)
                ? (Id) inputMap.get('recordId')
                : null;

            // Obtener action, esto determina si la conversion sera para grabar en la base de datos o consultar la base de datos
            String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String)
                ? (String) inputMap.get('action')
                : null;

            //Si alguna de estas dos variables no existe, se retorna un error
            if (recordId == null || String.isBlank(action)) {
                throw new DTM_Currency_Exception('recordId o action no están presentes o son inválidos, por lo tanto no se puede ejecutar la conversion');
            }

            //Buscamos el CurrencyIsoCode de la linea en el objeto DMT_Line__c para saber si existe algun factor de conversion para esa geografia
            DMT_Line__c line;
            line = [SELECT CurrencyIsoCode FROM DMT_Line__c WHERE Id = :recordId LIMIT 1];

            
            // Si no se encuentra la linea o CurrencyIsoCode es nulo, retornar error
            if (line == null || line.CurrencyIsoCode == null) {
                throw new DTM_Currency_Exception('No se encontró la linea o el CurrencyIsoCode para el recordId por lo tanto no se puede ejecutar la conversion');
            }

            //Podemos enviar por parametro tambien el currencyIsoCode, si lo tiene lo usa sino usa el de la linea
            String currencyIsoCode = (inputMap.containsKey('currency') && inputMap.get('currency') instanceof String)
                ? (String) inputMap.get('currency')
                : line.CurrencyIsoCode;

            // Buscar si existe algun factor de Conversion asociado a la moneda de la linea
            List<DMT_Currency_Conversion__mdt> convList = [
                SELECT Conversion_Factor__c
                FROM DMT_Currency_Conversion__mdt
                WHERE CurrencyIsoCode__c = :currencyIsoCode
                LIMIT 1
            ];

            // Si no se encuentra la configuración de conversión, no ejecutar la conversión y no reportar log
            if (convList.isEmpty()) {
                outMap.put('error', 'No se encontró configuración en DMT_Currency_Conversion__mdt para esta linea');
                outMap.putAll(copyInputToOutput(inputMap));
                return outMap;
            }

            //Verifico si Conversion Factor contiene un valor numerico
            Decimal conversionFactor;

            conversionFactor = Decimal.valueOf(String.valueOf(convList[0].Conversion_Factor__c));
            
            // Si existe un factor de conversion, se procede a hacer la conversion de las variables que sean numericas
            // y que no sean ni recordId ni action
            for (String key : inputMap.keySet()) {

                if (key == 'recordId' || key == 'action') continue;

                    Object val = inputMap.get(key);

                    //Verifico que los valores sean numericos
                    if (val instanceof Decimal || val instanceof Integer || val instanceof Double) {

                    Decimal numericVal;
                    numericVal = Decimal.valueOf(String.valueOf(val));
                    
                    Decimal result;

                    //Si es un valor que se grabara en la base de datos
                    if (action.toLowerCase() == 'input') {
                        result = numericVal * conversionFactor;
                    //Si es un valor que se ha leido desde la base de datos
                    } else if (action.toLowerCase() == 'output') {
                        if (conversionFactor != 0) {
                            result = numericVal / conversionFactor;
                        //Validacion para evitar divisiones por cero
                        } else {
                            outMap.put('error_' + key, 'Conversion factor no puede ser cero para división');
                            outMap.putAll(copyInputToOutput(inputMap));
                            continue;
                        }
                    } else {
                        throw new DTM_Currency_Exception('Accion no definida, las operaciones validas son input o output');
                    }

                    outMap.put(key, result);
                } else {
                    // Si no es numérico, simplemente copiar el valor
                    outMap.put(key, val);
                }
            }

        } catch (Exception e) {
             // Logging centralizado
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Currency_Conversion_Utils', 'DMT_List_Amount_Conversion', 'DMT', '');
            exceptionList.add(dmtEcx);
            outMap.putAll(copyInputToOutput(inputMap));
        }

        if(exceptionList.size() > 0){
            outMap.put('exceptionList', exceptionList);
            outMap.put('error', 'Error en la conversión');
        }

        return outMap;
    }

    public static Map<String, Object> DMT_Multiple_Amount_Conversion(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
    
    List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

    try {

        //Definir variables de entrada del metodo

        String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String)
            ? (String) inputMap.get('action')
            : null;

        String fieldListStr = (inputMap.containsKey('list') && inputMap.get('list') instanceof String)
            ? (String) inputMap.get('list')
            : null;

        //Si la currency esta definida, ya no sera necesario definir objeto ni record id donde buscarla
        String currencyISO = (inputMap.containsKey('currency') && inputMap.get('currency') instanceof String)
            ? (String) inputMap.get('currency')
            : null;

        //Si la currency no esta definida es obligatorio definir el recordid y el objeto
        String objectName = (inputMap.containsKey('object') && inputMap.get('object') instanceof String)
            ? (String) inputMap.get('object')
            : null;

        Id recordId = (inputMap.containsKey('recordId') && inputMap.get('recordId') instanceof Id)
            ? (Id) inputMap.get('recordId')
            : null;

        //Los dos primeros parametros son obligatorios
        if (String.isBlank(action) || String.isBlank(fieldListStr)) {
            throw new DTM_Currency_Exception('Mandatory parameters missed: action, list.');
        }

        //Si no esta definido la currencyISO debe definirse el objeto y recordid de donde sacarlo
        if (String.isBlank(currencyISO)) {
            if(String.isBlank(objectName)  || String.isBlank(recordId)){
                throw new DTM_Currency_Exception('object and recordId parameters must be defined if currency not defined.');
            }
        }

        //Sacar los campos a convertir
        List<String> fieldsToConvert = fieldListStr.split(';');

         // Validar objeto soportado
        SObject record;

        String currencyIsoCode = '';

        if(String.isBlank(currencyISO)){
            if (objectName == 'DMT_Line__c') {
                record = [SELECT CurrencyIsoCode FROM DMT_Line__c WHERE Id = :recordId LIMIT 1];
            } else if (objectName == 'Opportunity ') {
                record = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :recordId LIMIT 1];
            } else {
                throw new DTM_Currency_Exception('object not supported: ' + objectName);
            }

            currencyIsoCode = record.get('CurrencyIsoCode') != null
            ? (String) record.get('CurrencyIsoCode')
            : null;

        } else {
            currencyIsoCode = currencyISO;
        }

        //Validar que tengamos el currency
        if (currencyIsoCode == null) {
            throw new DTM_Currency_Exception('CurrencyIsoCode not found');
        }

        // Obtener factor de conversión
        List<DMT_Currency_Conversion__mdt> convList = [
            SELECT Conversion_Factor__c
            FROM DMT_Currency_Conversion__mdt
            WHERE CurrencyIsoCode__c = :currencyIsoCode
            LIMIT 1
        ];

        if (convList.isEmpty()) {
            outMap.put('error', 'Configuration not found in DMT_Currency_Conversion__mdt for the currency: ' + currencyIsoCode);
            outMap.putAll(copyInputToOutput(inputMap));
            return outMap;
        }

        Decimal conversionFactor = Decimal.valueOf(String.valueOf(convList[0].Conversion_Factor__c));

        for (String fieldName : fieldsToConvert) {

            fieldName = fieldName.trim();
            
            if (!inputMap.containsKey(fieldName)) continue;

            Object val = inputMap.get(fieldName);
            
            if (!(val instanceof Decimal || val instanceof Integer || val instanceof Double)) {
                outMap.put(fieldName, val); // Copiar sin convertir
                continue;
            }

            Decimal numericVal = Decimal.valueOf(String.valueOf(val));
            Decimal result;

            if (action.toLowerCase() == 'input') {
                result = numericVal * conversionFactor;
            } else if (action.toLowerCase() == 'output') {
                if (conversionFactor == 0) {
                    outMap.put('error_' + fieldName, 'El factor de conversión no puede ser cero para dividir');
                    outMap.put(fieldName, val);
                    continue;
                }
                result = numericVal / conversionFactor;
            } else {
                throw new DTM_Currency_Exception('Acción no reconocida. Use "input" o "output".');
            }

            outMap.put(fieldName, result);
        }

    } catch (Exception e) {
        DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(
            e, 'DMT_Currency_Conversion_Utils', 'DMT_List_Amount_Conversion', 'DMT', ''
        );
        exceptionList.add(dmtEcx);
        outMap.putAll(copyInputToOutput(inputMap));
    }

    if (exceptionList.size() > 0) {
        outMap.put('exceptionList', exceptionList);
        outMap.put('error', 'Error en la conversión');
    }

    return outMap;
    }


    /**
     * @Description Metodo auxiliar para copiar el contenido de un mapa de entrada a un nuevo mapa,
     *              excluyendo las claves 'recordId' y 'action'. Usado para llenar el 'outMap'
     *              con los datos originales cuando la conversion no se realiza o falla.
     * @param inputMap El mapa de entrada del cual copiar los valores.
     * @return Map<String, Object> Un nuevo mapa con los valores copiados, excluyendo 'recordId' y 'action'.
     */
    private static Map<String, Object> copyInputToOutput(Map<String, Object> inputMap) {
        Map<String, Object> result = new Map<String, Object>();
        for (String key : inputMap.keySet()) {
            if (key != 'recordId' && key != 'action') {
                result.put(key, inputMap.get(key));
            }
        }
        return result;
    }

    /**
     * @Description Convierte una lista de montos. Cada elemento de la lista es un mapa que debe
     *              contener una clave 'line' (Id de DMT_Line__c) y 'amount' (Decimal).
     *              La conversion se basa en el CurrencyIsoCode de la linea y la 'action' proporcionada ('input' o 'output').
     *              Los factores de conversion se obtienen de DMT_Currency_Conversion__mdt.
     * @param inputMap Mapa de entrada. Debe contener:
     *                 - 'list' (List<Object>): Lista de elementos a convertir. Cada elemento es un Map<String, Object>
     *                   esperado con 'line' (String representando un Id de lineas) y 'amount' (Object convertible a Decimal).
     *                 - 'action' (String): La acción a realizar ('input' para grabar en bd, 'output' para leer de bd).
     * @param outMap Mapa donde se almacenara la lista convertida bajo la clave 'list'.
     *               Tambien puede contener 'error' y 'exceptionList' si ocurren problemas.
     * @return Map<String, Object> El mapa 'outMap' modificado. Contendra la lista de montos convertidos
     *         bajo la clave 'list'. Si ocurre un error, la lista original se devuelve en 'list'
     *         y se añaden las claves 'error' y 'exceptionList'.
     * @throws DTM_Currency_Exception Si la clave 'list' o 'action' no estan presentes o son invalidas en 'inputMap'.
     */
    public static Map<String, Object> DMT_List_Amount_Conversion(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
    
    List<Object> originalList;
    List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

    try {

        // Validar existencia y tipo de la lista
        if (!inputMap.containsKey('list') || !(inputMap.get('list') instanceof List<Object>)) {
            throw new DTM_Currency_Exception('No se encontró la lista o no es válida');
        }

        originalList = (List<Object>) inputMap.get('list');

        // Obtener el valor de 'action'
        String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String)
            ? (String) inputMap.get('action')
            : null;

        // Si no hay acción, retornar lista sin modificar
        if (String.isBlank(action)) {
            throw new DTM_Currency_Exception('No se definio el parametro action');
        }

        // Obtener configuración de conversión desde metadata
        Map<String, Map<String, Object>> DMT_Currency_Factors = new Map<String, Map<String, Object>>();
        for (DMT_Currency_Conversion__mdt mdt : [
            SELECT CurrencyIsoCode__c, Conversion_Factor__c, Currency_Label__c
            FROM DMT_Currency_Conversion__mdt
        ]) {
            Map<String, Object> factorData = new Map<String, Object>{
                'Conversion_Factor__c' => mdt.Conversion_Factor__c,
                'Currency_Label__c' => mdt.Currency_Label__c
            };
            DMT_Currency_Factors.put(mdt.CurrencyIsoCode__c, factorData);
        }

        // Extraer IDs únicos de líneas
        Set<Id> lineIds = new Set<Id>();
        for (Object itemObj : originalList) {
            if (itemObj instanceof Map<String, Object>) {
                Map<String, Object> item = (Map<String, Object>) itemObj;
                if (item.containsKey('line')) {
                    String lineRaw = String.valueOf(item.get('line'));
                    if (!String.isBlank(lineRaw) && lineRaw.length() == 18) {
                        try {
                            lineIds.add((Id) lineRaw);
                        } catch (Exception e) {
                            System.debug('No es un Id válido: ' + lineRaw);
                            // No es un Id válido, se ignora
                        }
                    }
                }
            }
        }

        // Consulta de DMT_Line__c
        Map<Id, DMT_Line__c> lineMap = new Map<Id, DMT_Line__c>();
        if (!lineIds.isEmpty()) {
            for (DMT_Line__c line : [
                SELECT CurrencyIsoCode
                FROM DMT_Line__c
                WHERE Id IN :lineIds
            ]) {
                lineMap.put(line.Id, line);
            }
        }

        // Procesar la lista
        List<Object> convertedList = new List<Object>();

        for (Object itemObj : originalList) {
            
            if (!(itemObj instanceof Map<String, Object>)) continue;

            Map<String, Object> item = new Map<String, Object>((Map<String, Object>) itemObj);

            String lineIdStr = String.valueOf(item.get('line'));

            if (String.isBlank(lineIdStr) || lineIdStr.length() != 18) {
                convertedList.add(item);
                continue;
            }

            Id lineId;

            try {
                lineId = (Id) lineIdStr;
            } catch (Exception e) {
                convertedList.add(item);
                continue;
            }

            if (!lineMap.containsKey(lineId)) {
                convertedList.add(item);
                continue;
            }

            String geography = lineMap.get(lineId).CurrencyIsoCode;
            
            if (String.isBlank(geography) || !DMT_Currency_Factors.containsKey(geography)) {
                convertedList.add(item);
                continue;
            }

            Map<String, Object> conversionInfo = DMT_Currency_Factors.get(geography);
            Object factorRaw = conversionInfo.get('Conversion_Factor__c');
            Decimal conversionFactor;

            try {
                conversionFactor = Decimal.valueOf(String.valueOf(factorRaw));
            } catch (Exception e) {
                convertedList.add(item);
                continue;
            }

            Object amountRaw = item.get('amount');
            Decimal amount;

            try {
                amount = Decimal.valueOf(String.valueOf(amountRaw));
            } catch (Exception e) {
                convertedList.add(item);
                continue;
            }

            Decimal newAmount;
            
            if (action.toLowerCase() == 'input') {
                newAmount = amount * conversionFactor;
            } else if (action.toLowerCase() == 'output') {
                if (conversionFactor != 0) {
                    Decimal ratio = amount / conversionFactor;
                
                    // Validacion: el amount debe ser al menos el 10% del factor para dividir
                    if (ratio >= 0.1) {
                        newAmount = ratio;
                    } else {
                        // El amount es demasiado pequeño para justificar conversion, se deja igual
                        convertedList.add(item);
                        continue;
                    }
                } else {
                    convertedList.add(item);
                    continue;
                }
            } else {
                // Acción no válida, devolver lista original
                outMap.put('list', originalList);
                return outMap;
            }

            item.put('amount', newAmount);
            convertedList.add(item);
        }

        // Resultado final
        outMap.put('list', convertedList);

    } catch (Exception e) {
        // Logging centralizado
        DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Currency_Conversion_Utils', 'DMT_List_Amount_Conversion', 'DMT', '');
        exceptionList.add(dmtEcx);
        outMap.put('list', originalList);
    }

    if(exceptionList.size() > 0){
        outMap.put('exceptionList', exceptionList);
        outMap.put('error', 'Error en la conversión');
    }

    return outMap;
}

/**
 * Realiza la conversión de moneda en múltiples campos numéricos dentro de una lista de mapas,
 * utilizando factores definidos por geografía (CurrencyIsoCode) asociados a cada línea.
 *
 * @param inputMap Mapa de entrada que debe contener:
 *                 - 'list': Lista de elementos tipo Map<String, Object>.
 *                 - 'action': Puede ser 'input' (multiplicar) o 'output' (dividir).
 *                 - 'fieldsToConvert': (opcional) String con campos separados por ';'. Por defecto usa 'amount'.
 * @param outMap   Mapa de salida donde se incluirá la lista convertida y posibles errores.
 * @param options  Parámetros adicionales (no usados actualmente).
 * @return Mapa con la lista convertida bajo la clave 'list' y posibles errores en 'exceptionList' y 'error'.
 */
public static Map<String, Object> DMT_List_convertCurrencyFieldsInList(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
    
   List<Object> originalList;
    List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

    try {

        Object rawList = inputMap.get('list');

        if (rawList == null) {
            throw new DTM_Currency_Exception('No se encontró el parámetro list');
        }

        originalList = new List<Object>();

        if (rawList instanceof List<Object>) {
            originalList = (List<Object>) rawList;
        } else if (rawList instanceof Map<String, Object>) {
            originalList.add((Map<String, Object>) rawList); // Envolver en una lista
        } else {
            throw new DTM_Currency_Exception('El parámetro list no tiene un formato válido (debe ser lista o mapa)');
        }

        String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String)
            ? (String) inputMap.get('action')
            : null;

        if (String.isBlank(action)) {
            throw new DTM_Currency_Exception('No se definió el parámetro action');
        }

         //Si la currency esta definida, ya no sera necesario definir objeto ni record id donde buscarla
        String currencyISO = (inputMap.containsKey('currency') && inputMap.get('currency') instanceof String)
            ? (String) inputMap.get('currency')
            : null;

       String externalRecordId = (inputMap.containsKey('recordId') && inputMap.get('recordId') instanceof String)
            ? (String) inputMap.get('recordId')
            : null;

        //Si no esta definido la currencyISO debe definirse el objeto y recordid de donde sacarlo
        if (String.isBlank(currencyISO)) {
            if(String.isBlank(externalRecordId)){
                throw new DTM_Currency_Exception('recordId parameters must be defined if currency not defined.');
            }
        }

        // Obtener los campos a convertir
        String fieldsRaw = (inputMap.containsKey('fieldsToConvert') && inputMap.get('fieldsToConvert') instanceof String)
            ? (String) inputMap.get('fieldsToConvert')
            : 'amount';

        List<String> fieldsToConvert = new List<String>();

        for (String field : fieldsRaw.split(';')) {
            if (!String.isBlank(field)) {
                fieldsToConvert.add(field.trim());
            }
        }

        // Configuración desde metadata

        Map<String, Map<String, Object>> DMT_Currency_Factors = new Map<String, Map<String, Object>>();
        
        for (DMT_Currency_Conversion__mdt mdt : [
            SELECT CurrencyIsoCode__c, Conversion_Factor__c, Currency_Label__c
            FROM DMT_Currency_Conversion__mdt
        ]) {
            DMT_Currency_Factors.put(mdt.CurrencyIsoCode__c, new Map<String, Object>{
                'Conversion_Factor__c' => mdt.Conversion_Factor__c,
                'Currency_Label__c' => mdt.Currency_Label__c
            });
        }

        //Configuracion desde ID para Lines
        // Crear set de IDs usando el parámetro externalRecordId
        
        String geography = '';
        
        if (String.isBlank(currencyISO)) {

            Set<Id> lineIds = new Set<Id>();
            Map<Id, DMT_Line__c> lineMap = new Map<Id, DMT_Line__c>();

            try {
                lineIds.add((Id) externalRecordId);
            } catch (Exception e) {
                throw new DTM_Currency_Exception('El recordId proporcionado no es válido: ' + externalRecordId, e);
            }

            if (!lineIds.isEmpty()) {
                for (DMT_Line__c line : [
                    SELECT CurrencyIsoCode
                    FROM DMT_Line__c
                    WHERE Id IN :lineIds
                ]) {
                    lineMap.put(line.Id, line);
                }
            }

            // Verificar que se haya obtenido la línea correctamente
            if (!lineMap.containsKey((Id) externalRecordId)) {
                throw new DTM_Currency_Exception('No se encontró la línea con el recordId proporcionado: ' + externalRecordId);
            }

            // Obtener la geografía y factor de conversión a partir del recordId
            geography = lineMap.get((Id) externalRecordId).CurrencyIsoCode;
        } else {
            geography = currencyISO;
        }

        if (String.isBlank(geography) || !DMT_Currency_Factors.containsKey(geography)) {
            throw new DTM_Currency_Exception('No se encontró información de conversión para la Currency ' + geography);
        }
        
        Map<String, Object> conversionInfo = DMT_Currency_Factors.get(geography);
        Decimal conversionFactor;
        try {
            conversionFactor = Decimal.valueOf(String.valueOf(conversionInfo.get('Conversion_Factor__c')));
        } catch (Exception e) {
            throw new DTM_Currency_Exception('El factor de conversión no es válido para la currency: ' + geography, e);
        }

        List<Object> convertedList = new List<Object>();

        // Recorrer cada elemento y aplicar la conversión usando el factor obtenido
        for (Object itemObj : originalList) {
            if (!(itemObj instanceof Map<String, Object>)) continue;

            Map<String, Object> item = new Map<String, Object>((Map<String, Object>) itemObj);

            // Aplicar conversión a cada campo especificado
            for (String fieldName : fieldsToConvert) {
                if (!item.containsKey(fieldName)) continue;

                Object rawValue = item.get(fieldName);
                Decimal originalValue;

                try {
                    originalValue = Decimal.valueOf(String.valueOf(rawValue));
                } catch (Exception e) {
                    continue;
                }

                Decimal newValue;
                if (action.toLowerCase() == 'input') {
                    newValue = originalValue * conversionFactor;
                } else if (action.toLowerCase() == 'output') {
                    if (conversionFactor != 0) {
                        Decimal ratio = originalValue / conversionFactor;
                        if (ratio >= 0.1) {
                            newValue = ratio;
                        } else {
                            continue;
                        }
                    } else {
                        continue;
                    }
                } else {
                    outMap.put('list', originalList);
                    return outMap;
                }
                item.put(fieldName, newValue);
            }
            convertedList.add(item);
        }

        outMap.put('list', convertedList);

    } catch (Exception e) {
        DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Currency_Conversion_Utils', 'convertCurrencyFieldsInList', 'DMT', '');
        exceptionList.add(dmtEcx);
        outMap.put('list', inputMap.get('list'));
    }

    if (exceptionList.size() > 0) {
        outMap.put('exceptionList', exceptionList);
        outMap.put('error', 'Error en la conversión');
    }

    return outMap;
}

/**
 * @Description Convierte montos dentro de una estructura anidada 'RiskLineTerm', este metodo es especifico para grabar
 *              desde lines-products, no usar en otro.
 *              
 * @param inputMap Mapa de entrada. Debe contener:
 *                 - 'action' (String): La accion a realizar ('input' para grabar, 'output' para leer).
 *                 - 'RiskLineTerm' (Map<String, Object>): Estructura anidada. Se espera que los valores
 *                   que son List<Object> contengan mapas con 'line' (String Id) y 'amount' (Object convertible a Decimal).
 * @param outMap Mapa donde se almacenará el 'RiskLineTerm' modificado.
 *               Tambien puede contener 'error' y 'exceptionList' si ocurren problemas.
 * @return Map<String, Object> El mapa 'outMap' modificado. Contendra el 'RiskLineTerm' actualizado.
 *         Si ocurre un error, el 'inputMap' original se copia a 'outMap'
 *         y se añaden las claves 'error' y 'exceptionList'.
 * @throws DTM_Currency_Exception Si 'action' o 'RiskLineTerm' no estan presentes o son invalidos en 'inputMap'.
 */
public static Map<String, Object> DMT_Risk_Term_Conversion(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
    List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();
    try {
        // Obtener action
        String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String)
            ? (String) inputMap.get('action')
            : null;

        if (String.isBlank(action)) {
            throw new DTM_Currency_Exception('No se definio el parametro action');
        }

        // Obtener RiskLineTerm
        Map<String, Object> riskLineTerm = (inputMap.containsKey('RiskLineTerm') && inputMap.get('RiskLineTerm') instanceof Map<String, Object>)
            ? (Map<String, Object>) inputMap.get('RiskLineTerm')
            : null;

        if (riskLineTerm == null) {
            throw new DTM_Currency_Exception('No se definio el parametro RiskLineTerm');
        }

        
        // Preparar mapa de factores desde el metadata
        Map<String, Map<String, Object>> DMT_Currency_Factors = new Map<String, Map<String, Object>>();
        for (DMT_Currency_Conversion__mdt mdt : [
            SELECT CurrencyIsoCode__c, Conversion_Factor__c, Currency_Label__c
            FROM DMT_Currency_Conversion__mdt
        ]) {
            DMT_Currency_Factors.put(mdt.CurrencyIsoCode__c, new Map<String, Object>{
                'Conversion_Factor__c' => mdt.Conversion_Factor__c,
                'Currency_Label__c' => mdt.Currency_Label__c
            });
        }

        // Recolectar todas las líneas (line Ids)
        Set<Id> lineIds = new Set<Id>();
        for (String key : riskLineTerm.keySet()) {
            Object value = riskLineTerm.get(key);
            if (!(value instanceof List<Object>)) continue;

            for (Object itemObj : (List<Object>) value) {
                if (itemObj instanceof Map<String, Object>) {
                    String lineRaw = String.valueOf(((Map<String, Object>) itemObj).get('line'));
                    if (!String.isBlank(lineRaw) && lineRaw.length() == 18) {
                        try {
                            lineIds.add((Id) lineRaw);
                        } catch (Exception e) {
                           System.debug('No es un Id válido: ' + lineRaw);
                            // No es un Id válido, se ignora
                        }
                    }
                }
            }
        }

        // Consultar Booking_Geography__c por línea
        Map<Id, DMT_Line__c> lineMap = new Map<Id, DMT_Line__c>();
        if (!lineIds.isEmpty()) {
            for (DMT_Line__c line : [
                SELECT CurrencyIsoCode FROM DMT_Line__c WHERE Id IN :lineIds
            ]) {
                lineMap.put(line.Id, line);
            }
        }

        // Procesar cada sublista que tenga ítems con amount y line
        for (String key : riskLineTerm.keySet()) {
            Object value = riskLineTerm.get(key);
            if (!(value instanceof List<Object>)) continue;

            List<Object> originalList = (List<Object>) value;
            List<Object> updatedList = new List<Object>();

            for (Object itemObj : originalList) {
                if (!(itemObj instanceof Map<String, Object>)) {
                    updatedList.add(itemObj);
                    continue;
                }

                Map<String, Object> item = new Map<String, Object>((Map<String, Object>) itemObj);
                String lineIdStr = String.valueOf(item.get('line'));

                if (String.isBlank(lineIdStr) || lineIdStr.length() != 18) {
                    updatedList.add(item);
                    continue;
                }

                Id lineId;
                try {
                    lineId = (Id) lineIdStr;
                } catch (Exception e) {
                    updatedList.add(item);
                    continue;
                }

                if (!lineMap.containsKey(lineId)) {
                    updatedList.add(item);
                    continue;
                }

                String geography = lineMap.get(lineId).CurrencyIsoCode;
                if (String.isBlank(geography) || !DMT_Currency_Factors.containsKey(geography)) {
                    updatedList.add(item);
                    continue;
                }

                Decimal factor;
                try {
                    factor = Decimal.valueOf(String.valueOf(DMT_Currency_Factors.get(geography).get('Conversion_Factor__c')));
                } catch (Exception e) {
                    updatedList.add(item);
                    continue;
                }

                Object amountRaw = item.get('amount');
                Decimal amount;
                try {
                    amount = Decimal.valueOf(String.valueOf(amountRaw));
                } catch (Exception e) {
                    updatedList.add(item);
                    continue;
                }

                Decimal newAmount;
                if (action.toLowerCase() == 'input') {
                    newAmount = amount * factor;
                } else if (action.toLowerCase() == 'output') {
                    newAmount = (factor != 0) ? amount / factor : amount;
                } else {
                    updatedList.add(item);
                    continue;
                }

                item.put('amount', newAmount);
                updatedList.add(item);
            }

            // Reemplazar sublista modificada
            riskLineTerm.put(key, updatedList);
        }

        // Colocar el objeto modificado en el outMap
        outMap.put('RiskLineTerm', riskLineTerm);

    } catch (Exception e) {
       // Logging centralizado
        DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Currency_Conversion_Utils', 'DMT_List_Amount_Conversion', 'DMT', '');
        exceptionList.add(dmtEcx);
        outMap.putAll(inputMap);
    }

    if(exceptionList.size() > 0){
        outMap.put('exceptionList', exceptionList);
        outMap.put('error', 'Error en la conversión');
    }

    return outMap;
}

/**
 * @Description Formatea los valores numericos del inputMap usando una mascara dada.
 *              Si no se encuentra la mascara, simplemente copia el inputMap al outMap.
 *
 * @param inputMap Mapa que contiene los datos de entrada. Puede incluir:
 *                 - 'mask' (String): La máscara a aplicar a los campos numericos.
 *                 - Otros campos: Valores numericos a formatear.
 * @param outMap Mapa donde se almacenaran los resultados formateados.
 * @param options Parametros adicionales que podrian ser utilizados.
 * @return Map<String, Object> con los valores procesados o error si ocurre excepción.
 */ 
 public static Map<String, Object> DMT_Currency_Amount_Format(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
    
    List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

    try {
        outMap.clear();

        // Validar existencia de la mascara
        String mask = (inputMap.containsKey('mask') && inputMap.get('mask') instanceof String)
            ? String.valueOf(inputMap.get('mask'))
            : null;

        // Si no se envia la mascara, se busca el locale del usuario, si no encuentra la mascara 
        //configurada usamos por defecto la de españa
        if (String.isBlank(mask)) {
            String userLocale = UserInfo.getLocale();
            
            if (localeFormats.containsKey(userLocale)) {
                mask = localeFormats.get(userLocale);
            } else {
                // Valor por defecto si no se encuentra el locale
                mask = localeFormats.get('es_ES');
            }
        }
        
        for (String key : inputMap.keySet()) {

            Object val = inputMap.get(key);

            if (key != 'mask' && val != null && (
                val instanceof Decimal || val instanceof Double || val instanceof Integer)) {
                try {
                    Decimal numericVal = Decimal.valueOf(String.valueOf(val));
                    String formatted = applyCustomMask(numericVal, mask);
                    outMap.put(key, formatted);
                } catch (Exception e) {
                    // Si falla el formateo, se guarda el valor original como string
                    outMap.put(key, String.valueOf(val));
                }
            } else if (key != 'mask') {
                outMap.put(key, val);
            }
        }

    } catch (Exception e) {
        DES_Exceptions__b dmtExc = DES_Exception_Utils.logExceptionWithoutInsert(
            e, 'DMT_Currency_Conversion_Utils', 'DMT_Currency_Amount_Format', 'DMT', ''
        );
        exceptionList.add(dmtExc);
        outMap.putAll(inputMap);
    }

    if(exceptionList.size() > 0){
        outMap.put('exceptionList', exceptionList);
        outMap.put('error', 'Error al formatear los montos');
    }

    return outMap;
}

public static String applyCustomMask(Decimal value, String mask) {

    Decimal workingValue = value; 

    // Separar máscara
    List<String> parts = mask.split('\\.');
    String intMask = parts[0];
    String decMask = (parts.size() > 1) ? parts[1] : '';

    // --- Parte entera ---
    Integer intMinDigits = 0;
    for (Integer i = 0; i < intMask.length(); i++) {
        String ch = intMask.substring(i, i + 1);
        if (ch == '0') {
            intMinDigits++;
        }
    }

    // --- Parte decimal ---
    Integer decFixed = 0;
    Integer decMax = 0;
    for (Integer i = 0; i < decMask.length(); i++) {
        String ch = decMask.substring(i, i + 1);
        if (ch == '0') decFixed++;
        if (ch == '#' || ch == '0') decMax++;
    }

    workingValue =  workingValue.setScale(decMax, RoundingMode.HALF_UP);
    String[] valParts = String.valueOf(workingValue).split('\\.');
    String intPart = valParts[0];
    String decPart = (valParts.size() > 1) ? valParts[1] : '';

    // Rellenar ceros a la izquierda si aplica
    while (intPart.length() < intMinDigits) {
        intPart = '0' + intPart;
    }

    // Detectar separadores desde la máscara
    String decimalSep = (mask.contains(',') && mask.contains('.')) ?
        ((mask.indexOf(',') > mask.indexOf('.')) ? ',' : '.') :
        (mask.contains(',') ? ',' : '.');

    String thousandSep = (decimalSep == ',') ? '.' : ',';

    // Formatear con separadores de miles
    intPart = addThousandSeparators(intPart, thousandSep);

    // Truncar o forzar decimales
    if (decPart != '') {
        if (decMax > decFixed) {
            while (decPart.endsWith('0') && decPart.length() > decFixed) {
                decPart = decPart.substring(0, decPart.length() - 1);
            }
        }
        if (decFixed > 0 && decPart.length() < decFixed) {
            while (decPart.length() < decFixed) {
                decPart += '0';
            }
        }
        if (decFixed > 0 && decPart.length() > decFixed) {
            decPart = decPart.substring(0, decFixed);
        }

        return intPart + decimalSep + decPart;
    }

    // Si se espera .00 aunque no haya parte decimal
    if (decFixed > 0) {
        return intPart + decimalSep + '0'.repeat(decFixed);
    }

    return intPart;
}


private static String addThousandSeparators(String numberStr, String thousandSep) {
    String result = '';
    Integer length = numberStr.length();
    Integer digitCount = 0;

    for (Integer i = length - 1; i >= 0; i--) {
        String digit = numberStr.substring(i, i + 1);
        result = digit + result;
        digitCount++;

        if (Math.mod(digitCount, 3) == 0 && i > 0) {
            result = thousandSep + result;
        }
    }
    return result;
}

/**
 * @Description Método auxiliar que reemplaza un nodo específico dentro del objeto en una estructura JSON,
 *              utilizando los parámetros entregados en el mapa de entrada. El nuevo valor es tomado del parámetro 'replacementNode'
 *              y se asigna bajo el nombre definido por 'nodeToReplace'. El resultado se coloca en 'outMap' bajo la clave 'result'.
 *              
 *              Este método es útil para integraciones que requieren modificar estructuras anidadas antes de devolverlas
 *              como parte de un Integration Procedure en OmniStudio.
 *
 * @param inputMap Mapa de entrada que debe contener:
 *                 - 'originalJson' (Map<String, Object>): Estructura JSON completa.
 *                 - 'nodeToReplace' (String): Nombre del nodo dentro del JSON que se desea reemplazar.
 *                 - 'replacementNode' (Object): Contenido con el que se reemplazará el nodo indicado.
 * @param outMap Mapa de salida donde se insertará la estructura modificada bajo la clave 'result'.
 *               También incluirá 'error' y 'exceptionList' si ocurre una excepción.
 * @param options Mapa de opciones adicionales (actualmente no se usa, reservado para futura extensión).
 *
 * @return Map<String, Object> El mapa de salida con el resultado de la transformación o información de error.
 */

public static Map<String, Object> DMT_Replace_Node_In_Object(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
    
    List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

    try {
        // Validaciones básicas
        if (inputMap == null || !inputMap.containsKey('originalJson')) {
            throw new DTM_Currency_Exception('No se encontró el parámetro originalJson');
        }

        if (!inputMap.containsKey('nodeToReplace') || !(inputMap.get('nodeToReplace') instanceof String)) {
            throw new DTM_Currency_Exception('No se definió correctamente el parámetro nodeToReplace');
        }

        if (!inputMap.containsKey('replacementNode')) {
            throw new DTM_Currency_Exception('No se proporcionó replacementNode');
        }

        Object rawJson = inputMap.get('originalJson');
        if (!(rawJson instanceof Map<String, Object>)) {
            throw new DTM_Currency_Exception('El parámetro originalJson debe ser un Map<String, Object>');
        }

        Map<String, Object> originalJson = (Map<String, Object>) rawJson;
        String nodeToReplace = (String) inputMap.get('nodeToReplace');
        Object replacementNode = inputMap.get('replacementNode');

        // Lógica recursiva
        Integer replacements = replaceAllNodesRecursive(originalJson, nodeToReplace, replacementNode);

        if (replacements == 0) {
            throw new DTM_Currency_Exception('No se encontró el nodo "' + nodeToReplace + '" en la estructura JSON.');
        }

        outMap.put('result', originalJson);
        outMap.put('replacementsCount', replacements);
        
    } catch (Exception e) {
        DES_Exceptions__b ex = DES_Exception_Utils.logExceptionWithoutInsert(
            e, 'DMT_JSON_Transformation_Utils', 'DMT_Replace_Node_In_Object', 'DMT', ''
        );
        exceptionList.add(ex);
        outMap.put('error','Error en reemplazando el nodo');
        outMap.put('originalJson', inputMap.get('originalJson'));
    }

    if (!exceptionList.isEmpty()) {
        outMap.put('exceptionList', exceptionList);
    }

    return outMap;
}

/**
 * Busca y reemplaza recursivamente todas las coincidencias de una clave en el JSON.
 * 
 * @param node Nodo actual (Map o List).
 * @param targetKey Clave que se desea reemplazar.
 * @param replacement Valor que se asignará a cada coincidencia.
 * @return Número total de reemplazos realizados.
 */
public static Integer replaceAllNodesRecursive(Object node, String targetKey, Object replacement) {
    Integer count = 0;

    if (node instanceof Map<String, Object>) {
        Map<String, Object> mapNode = (Map<String, Object>) node;

        if (mapNode.containsKey(targetKey)) {
            mapNode.put(targetKey, replacement);
            count++;
        }

        for (String key : mapNode.keySet()) {
            Object child = mapNode.get(key);
            if (child instanceof Map<String, Object> || child instanceof List<Object>) {
                count += replaceAllNodesRecursive(child, targetKey, replacement);
            }
        }

    } else if (node instanceof List<Object>) {
        for (Object item : (List<Object>) node) {
            if (item instanceof Map<String, Object> || item instanceof List<Object>) {
                count += replaceAllNodesRecursive(item, targetKey, replacement);
            }
        }
    }

    return count;
}

/**
 * Used to format the amount when it comes as a scientific notation
 * 
  * @param inputMap Mapa de entrada que debe contener:
 *                 - 'originalJson' (Map<String, Object>): Estructura JSON completa.
 * @param outMap Mapa de salida donde se insertará la estructura modificada bajo la clave 'result'.
 *               También incluirá 'error' -
 * @param options Mapa de opciones adicionales (actualmente no se usa, reservado para futura extensión).
 * @return the format number
 */
public static Map<String, Object> formatAmountScientificNotation (Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
     try {
        if(inputMap.get('arguments') != null){
            list<object> arguments = (List<Object>) inputMap.get('arguments');
            System.debug('arguments: ' + arguments);
            System.debug('arguments[0]: ' + arguments[0]);
            Decimal aux = Decimal.valueOf((String) arguments[0]);
            System.debug('aux: ' + aux);
            System.debug('aux.toPlainString(): ' + aux.toPlainString());
            String result = String.valueOf(aux.toPlainString());
            outMap.put('result', Decimal.valueOf(result));
        }
    }catch (Exception e) {
        outMap.put('error','Error formateo de notacion cientifica');
    }

    return outMap;
}

/**
* @Description Excepción personalizada utilizada dentro de la clase DMT_Currency_Conversion_Utils
*              para señalar errores específicos relacionados con la conversión de divisas,
*              como parámetros faltantes o inválidos.
*/
public virtual class DTM_Currency_Exception extends Exception {}

}