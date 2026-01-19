// Clase utilitaria
@JsonAccess(serializable='always' deserializable='always')
global without sharing class DMT_Utils implements Callable {

    global Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        System.debug('invokeMethod methodname, '+methodName);
        try {
            Map<String, Object> result;
            if (methodName == 'hasWriteAccess') {
                Boolean access = hasWriteAccess();
                result = new Map<String, Object>{ 'result' => access };
            } else if (methodName == 'consumptionsReassign') {
                String outcome = postConsumptionReassign('DMT_consumptionsReassign', inputMap);
                result = new Map<String, Object>{ 'result' => outcome }; // 'OK' or 'KO'
            }else  if (methodName == 'checkLineGodUser') {
                Boolean access = checkLineGodUser();
                result = new Map<String, Object>{ 'result' => access };
            }if (result != null) {
                outMap.putAll(result);
            }
        } catch (Exception e) {
            System.debug('Exception --> ' + e.getMessage());
            outMap.put('error', e.getMessage());
        }
        return outMap;
    }
    public static List<String> splitString(String input, String delimiter) {
        if (input == null || delimiter == null) {
            return new List<String>();
        }
        /*List<String> parts = input.split(delimiter);
        for (Integer i = 0; i < parts.size(); i++) {
            parts[i] = parts[i].trim();
        }
        return parts;*/
        return input.split(delimiter);
    }

    // Método para reemplazar espacios en blanco por %20 en una cadena de consulta
    public static String encodeSpacesInQueryString(String queryString) {
        // Reemplazar espacios en blanco por %20
        String encodedQueryString = queryString.replace(' ', '%20');
        return encodedQueryString;
    }

    public static String createQueryString(Map<String, Object> payload) {
        List<String> queryStringParams = new List<String>();
        // Iterar sobre los elementos del mapa
        for (String key : payload.keySet()) {
            Object value = payload.get(key);
            if (value != null && String.valueOf(value).trim() != '') {
                // Añadir el parámetro a la lista en formato clave=valor
                queryStringParams.add(key + '=' + EncodingUtil.urlEncode(value.toString(), 'UTF-8'));
            }
        }
        // Unir los parámetros con '&' para formar la cadena de consulta
        return String.join(queryStringParams, '&');
    }

    // Método para establecer la solicitud
    public static Map<String, Object> setRequest(Map<String, Object> payload, String federationIdentifier) {
        Map<String, Object> request = new Map<String, Object>();
        //request.put(DMT_Constants.PAYLOAD , JSON.serialize(payload));
        //request.put(DMT_Constants.USER_ID, federationIdentifier);

        // Crear la cadena de consulta
        String queryString = createQueryString(payload);
        queryString = encodeSpacesInQueryString(queryString);
        request.put('queryString', queryString);
        return request;
    }
    // Método para llamar al servicio
    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        return  DMT_HPG_Utils.callService_DMT(serviceName, request);
    }
    public static String listToString(List<String> stringList, String delimiter) {
        // Verifica si la lista es nula o está vacía
        if (stringList == null || stringList.isEmpty()) {
            return '';
        }
        // Usa el método String.join para concatenar los elementos de la lista
        return String.join(stringList, delimiter);
    }

     /**
     * Determines if the current user has 'Read/Write' access
     * based on roles defined in the DMT_User_Role__c field and
     * custom metadata (DES_User_Roles__mdt).
     */
    @AuraEnabled(cacheable=true)
    public static Boolean hasWriteAccess() {
        String rolesRaw = [SELECT DMT_User_Role__c FROM User WHERE Id = :UserInfo.getUserId() ].DMT_User_Role__c;

        if (String.isBlank(rolesRaw)) return false;

        Set<String> roleSet = new Set<String>(splitString(rolesRaw, ';'));

        return ![SELECT Id FROM DES_User_Roles__mdt WHERE DES_Role_Developer_Name__c IN :roleSet AND DES_Access_Level__c = 'Read/Write' LIMIT 1 ].isEmpty();
    }

    /**
     * Determines if the current user has the custom permission of DMT_Line_God
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkLineGodUser() {
        return FeatureManagement.checkPermission('DMT_Line_God');
    }

    /**
     * Flow-invocable method to check Write access from roles.
     */
    @InvocableMethod(label='Has Write Access from Roles?' description='Returns true if current user has any role with Read/Write access in DES_User_Roles__mdt.')
    public static List<Output> checkUserWriteAccess() {
        return new List<Output>{ new Output(hasWriteAccess()) };
    }

    private static String postConsumptionReassign(String serviceName, Map<String, Object> inputMap) {
        try {
            // Build payload
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('initDate', String.valueOf(Date.today()));

            Map<String, Object> clientMap = new Map<String, Object>();
            clientMap.put('groupId', (String) inputMap.get('groupId'));
            payload.put('client', clientMap);

            Map<String,Object> request = new Map<String,Object>();
            request.put('jsonInput', JSON.serialize(payload));

            // Call the service
            HttpResponse response = DMT_HPG_Utils.callService_DMT(serviceName, request, true);

            // Return OK/KO depending on status
            if (response != null && response.getStatusCode() == 204) {
                return 'OK';
            } else {
                System.debug('Service response: ' + (response != null ? response.getBody() : 'null'));
                return 'KO';
            }
        } catch (Exception e) {
            DMT_Integration_GenericService.commitAllLogsViaBatch();
            System.debug('Error in postConsumptionReassign: ' + e.getMessage()+ 'line number: ' + e.getLineNumber());
            return 'KO';
        }
    }


    /**
     * Output class used for Flow integration.
     */
    public class Output {
        @InvocableVariable(label='User has Write Access?'description='Indicates whether the user has Read/Write access based on roles.')
        public Boolean hasWriteAccess;

        public Output(Boolean access) {
            this.hasWriteAccess = access;
        }
    }

}