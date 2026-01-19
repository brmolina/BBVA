/**-------------------------------------------------------------------------------------------
* @Name     DMT_Opportunity_Handler
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-03-11
* --------------------------------------------------------------------------------------------
* @Description Callable class for Omnistudio
* --------------------------------------------------------------------------------------------
*/
global with sharing class DES_Exception_Handler implements Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try{
            Map<String, Object> result;
            if(methodName == 'logExceptionList') {
                result = logExceptionList(inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_TestTryCatch'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'CustomAssociationCreation'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_SAVE_CLIENT'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_GetOppClient'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMTLoadClientGroup'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_SetOppClient'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_SetOppClient_Update'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DealManagementRenewLine'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_conditionsCloseCase'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'ApprovalStepLoad'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'addProductsRisk'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_GetLinePassport'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'ApprovalChangeStep'){
                result = logException(methodName,inputMap,outMap,options);  
            }else if(methodName == 'adminApproverMember'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'CustomAssociationTable'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'launchDealManagement'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_GetPickListLimit'){
                result = logException(methodName,inputMap,outMap,options);  
            }else  if(methodName == 'getResponseSimulate'){
                result = logException(methodName,inputMap,outMap,options);  
            }else if(methodName == 'selectClientInLIne'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'createProductsLine'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'CreateRiskLineTerm'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'CreateDealInterveners'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'initDealManagement'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMTGetClientGroupInfo'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_GetRiskLineForm'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_SetRiskLineForm'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'DMT_IP_GetRiskLineTerm'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'SaveOpportunitInfoTab'){
                result = logException(methodName,inputMap,outMap,options);
            }else if(methodName == 'OpportunityMitigantEdit'){
                result = logException(methodName,inputMap,outMap,options);
            }

            if (result != null) {
                outMap.putAll(result);
            }
            
        }catch(exception e){
            Boolean logged = false;
            logged = DES_Exception_Utils.logException(e,
                                                  'DES_Exception_Handler',
                                                  'invokeMethod',
                                                  'DMT',
                                                  '');
            outMap.put('logged', logged);
        }
        return outMap;
    }

    public static Map<String, Object> logException(String processIntegrationName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        String inputAsString = JSON.serialize(inputMap);
        Boolean logged = false;

        Exception customEx;
        try {
            throw new ProcessIntegrationException(inputAsString);
        } catch (Exception e) {
            customEx = e;
        }

        logged = DES_Exception_Utils.logException(customEx,
                                                  'Process_Integration',
                                                  processIntegrationName,
                                                  'DMT',
                                                  '');
        outMap.put('logged', logged);
        return outMap;
    }

    public static Map<String, Object> logExceptionList(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Boolean logged = false;
        try {
            
            if (inputMap == null || !inputMap.containsKey('list')) {
                return outMap;
            }

            List<DES_Exceptions__b> exceptionList = (List<DES_Exceptions__b>) inputMap.get('list');
            logged = DES_Exception_Utils.logDesExceptionsList(exceptionList);
            outMap.put('logged', logged);

        } catch (Exception e) {
            logged = DES_Exception_Utils.logException(
                e,
                'DES_Exception_Handler',
                'logExceptionListFromInput',
                'GEN',
                'GenericHandler'
            );
            outMap.put('logged', logged);
        }
        return outMap;
    }

    public class MissingFieldsException extends Exception {}
    public class ProcessIntegrationException extends Exception {}

}