global with sharing class DMT_Callout_LeveragedLending implements Callable {

    public Object call(String action, Map<String, Object> args) {
        final Map<String, Object> input = (Map<String, Object>) args.get('input');
        final Map<String, Object> output = (Map<String, Object>) args.get('output');
        final Map<String, Object> options = (Map<String, Object>) args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            if (methodName == 'getLeveragedLending') {
                // Obtener los inputs (groupId, searchDate)
                String groupId = (String) inputMap.get('groupId');
                String searchDate = (String) inputMap.get('searchDate');

                System.debug('INPUT groupId: ' + groupId);
                System.debug('INPUT searchDate: ' + searchDate);

                // Llamar al servicio con los nuevos inputs
                Map<String, Object> result = callLeveragedLendingService(groupId, searchDate, outMap);
                if (result != null) {
                    outMap.putAll(result);
                }
            }
        } catch (Exception e) {
            outMap.put('error', true);
            outMap.put('errorMessage', JSON.serialize(new Map<String,Object> {
                'message' => e.getMessage(),
                'stackTrace' => e.getStackTraceString(),
                'lineNumber' => e.getLineNumber(),
                'type' => e.getTypeName()
            }));
        }
        return outMap;
    }

    public static Map<String, Object> callLeveragedLendingService(String groupId, String searchDate, Map<String, Object> outMap) {
        String leveragedValue;

        // Construir el query string con groupId y searchDate
        String queryString = 'groupId=' + EncodingUtil.urlEncode(groupId, 'UTF-8') + '&searchDate=' + EncodingUtil.urlEncode(searchDate, 'UTF-8');
        System.debug('Irene queryString ' + queryString);

        Map<String, Object> request = new Map<String, Object>();
        request.put('queryString', queryString);

        final String serviceName = 'DMT_GetLeveragedLending';
        HttpResponse response =DMT_HPG_Utils.callService(serviceName, request);

        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            LeveragedLendingWrapper res = (LeveragedLendingWrapper) JSON.deserialize(response.getBody(), LeveragedLendingWrapper.class);

            if (res != null && res.data != null) {
                for (Data d : res.data) {
                    if (d.leveragedLendingIndType != null) {
                        leveragedValue = d.leveragedLendingIndType;
                    }
                }
            }
        } else {
            outMap.put('error', true);
            outMap.put('errorMessage', response.getBody() != null ? response.getBody() : 'Error calling service: ' + response.getStatusCode());
        }
        outMap.put('leveragedLendingIndType', leveragedValue);
        return outMap;
    }

    public class LeveragedLendingWrapper {
        public List<Data> data { get; set; }
    }

    public class Data {
        public String leveragedLendingIndType { get; set; }
    }
}