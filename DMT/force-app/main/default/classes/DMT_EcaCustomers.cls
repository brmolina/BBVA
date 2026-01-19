/**-------------------------------------------------------------------------------------------
 * @Name     DMT_EcaCustomers
 * @Author   
 * @Date     Created: 2025-10-29
 * ------------------------------------------------------------------------------------------------
* @Description Callable class for Omnistudio to get Wrapper for EcaCustomers
 * ------------------------------------------------------------------------------------------------
 */
public with sharing class DMT_EcaCustomers implements Callable{

    public Object call(String action, Map<String, Object> args) {

        final Map<String, Object> input = (Map<String, Object>)args.get('input');
        final Map<String, Object> output = (Map<String, Object>)args.get('output');
        final Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    /**
    * @description Invokable method to set values to get Eca Customers
    */
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            System.debug('DMT_EcaCustomers.invokeMethod: inputMap --> ' + json.serialize(inputMap));
            System.debug('DMT_EcaCustomers.invokeMethod: outMap --> ' + outMap);
            System.debug('DMT_EcaCustomers.invokeMethod: options --> ' + json.serialize(options));

            if(methodName == 'getEcaCustomer') {
                final Map<String, Object> result;
                final String rawValueCustomerId = (String) inputMap.get('customerId');

                System.debug('DMT_EcaCustomers.invokeMethod: rawValueCustomerId --> ' + rawValueCustomerId);

                if (rawValueCustomerId != null) {
                    final String requestStr = 'customerId=' + rawValueCustomerId;
                    result = DMT_EcaCustomers(requestStr, outMap);
                    if (result != null) {
                        outMap.putAll(result);
                    }
                } else {
                    outMap.put('isEcaCustomer', false);
                    outMap.put('error', true);
                }
            }
        } catch(exception e) {
            outMap.put('error', true);
            outMap.put('errorMessage', e.getMessage() + e.getStackTraceString() + e.getLineNumber() + e.getTypeName());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_EcaCustomers','invokeMethod','DMT',''));
        }
        System.debug('DMT_EcaCustomers.invokeMethod: outMap end --> ' + json.serialize(outMap));
        return outMap;
    }

    /**
    * @description Call service and return wrapper for GET Eca Customers
    */
    public static Map<String, Object> DMT_EcaCustomers(String requestStr, Map<String, Object> outMap) {

        final Map<String, Object> request = new Map<String, Object>();
        Boolean isEcaCustomer = false;

        System.debug('DMT_EcaCustomers.DMT_EcaCustomers: requestStr: ' + requestStr);
        request.put('jsonInput', requestStr);
        final HttpResponse response;
        final String serviceName='DMT_GetEcaCustomers';

        GetEcaCustomersWrapper res = new GetEcaCustomersWrapper();

        response = DMT_HPG_Utils.callService(serviceName, request);
        System.debug('DMT_EcaCustomers.DMT_EcaCustomers: Response status code: ' + response.getStatusCode());
        switch  on response.getStatusCode() {
            when 200, 201 {
                System.debug('DMT_EcaCustomers.DMT_EcaCustomers: Response: ' + response.getBody());
                res = (GetEcaCustomersWrapper)System.JSON.deserialize(response.getBody(), GetEcaCustomersWrapper.class);

                if (res != null && res.data != null) {
                    for (Data d : res.data) {
                        if (d.choosebleEcaIndType != null && d.choosebleEcaIndType == 'Y') {
                            isEcaCustomer = true;
                        }
                    }
                }
                System.debug('DMT_EcaCustomers.DMT_EcaCustomers: isEcaCustomer: ' + isEcaCustomer);
            }
            when else {
                System.debug('DMT_EcaCustomers.DMT_EcaCustomers: Response: ' + response.getBody());
                if (res != null) {
                    outMap.put('errorMessage', String.valueOf(response.getBody()));
                } else {
                    outMap.put('errorMessage', 'Error obtaining the ECA Customer data: ' + response.getStatusCode());
                }
                outMap.put('error', true);
            }
        }
        outMap.put('isEcaCustomer', isEcaCustomer);
        System.debug('DMT_EcaCustomers.DMT_EcaCustomers: Updated response: ' + JSON.serialize(res));
        System.debug('DMT_EcaCustomers.DMT_EcaCustomers: outMap end: ' + outMap);

        return outMap;
    }

    public virtual class DTM_Currency_Exception extends Exception {}


    /**
     * @Description: Class GetEcaCustomersWrapper
     */
    public class GetEcaCustomersWrapper{
        public List<Data> data{ get; set; }
    }

    /**
     * @Description: Class Data
     */
    public class Data{
        public String choosebleEcaIndType{ get; set; }
    }
}