global with sharing class DMT_Profitability_Handler implements Callable{

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private static Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        System.debug('Apex remote called method '+methodName);
       try{
            if(methodName == 'callProfitabilityMatrix'){
                Map<String, Object> request = new Map<String, Object>();
                String jsonRequest = DMT_ProfitabilityMatrix_Wrapper.createRequest(inputMap);
                request.put('payload',jsonRequest);
                DMT_Profitability_Helper.callProfitabilityMatrixService(request, outMap);
            }else if(methodName == 'orderCatalogs'){
                DMT_Profitability_Helper.orderCatalogs(inputMap, outMap);
            }
        }catch(exception e){
            DES_Exception_Utils.logException(e,'DMT_Profitability_Handler', 'invokeMethod', 'DMT', '');
            outMap.put('result', false);
            outMap.put('message', e.getMessage());
            outMap.put('messageTitle', 'Error when calculate: ');

        }
        DMT_Integration_GenericService.commitAllLogsViaBatch();
        return outMap;
    }
}