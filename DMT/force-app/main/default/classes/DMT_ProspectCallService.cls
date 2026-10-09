/**-------------------------------------------------------------------------------------------
 * @Name     DMT_ProspectCallService
 * @Author   
 * @Date     Created: 2026-02-16
 * ------------------------------------------------------------------------------------------------
 * @Description Callable class for Omnistudio to get Wrapper for prospects
 * ------------------------------------------------------------------------------------------------
 */
public with sharing class DMT_ProspectCallService {

    @TestVisible
    private static Boolean simulateServiceError = false;

     public static Map<String, Object> callMergeProspectService (String customerId, String customerProspectId, String groupId, String groupProspectId) {
        String result;
        Map<String, Object> outMap = new Map<String, Object>();
        try {

            final String serviceName = 'DMT_MergeProspect';
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('customerId', customerId != null ? customerId : '');
            payload.put('customerProspectId', customerProspectId != null ? customerProspectId : '');
            payload.put('groupId', groupId != null ? groupId : '');
            payload.put('groupProspectId', groupProspectId != null ? groupProspectId : '');
           
            System.debug('** log::DMT_MergeProspectCalloutQueueable - Request: ' + JSON.serialize(payload));

            Map<String, Object> requestMap = new Map<String, Object>();
            requestMap.put('payload', JSON.serialize(payload));

            HttpResponse response = DMT_HPG_Utils.callService(serviceName, requestMap);
            if (simulateServiceError) {
                throw new CalloutException('Simulated service error for test coverage');
            }
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
                result = String.valueOf(response.getStatusCode());
            } else {
                throw new CalloutException('ERROR mergeProspect' + ' ' + response.getStatus() +  '\n' + response.getBody());
            }
            outMap.put('result', result);
        } catch (Exception e) {
            outMap.put('error', true);
            outMap.put('errorMessage', JSON.serialize(new Map<String,Object> {'message' => e.getMessage(),'stackTrace' => e.getStackTraceString(),'type' => e.getTypeName()}));
        }
        return outMap;
    }

    public class prospectCallServiceWrapper{

        public prospectCallServiceWrapper (String customerId, String customerProspectId, String groupId, String groupProspectId) {
            this.customerId = customerId;
            this.customerProspectId = customerProspectId;
            this.groupId = groupId;
            this.groupProspectId = groupProspectId;
        }

        public String customerId{  get; set; } 
        public String customerProspectId{  get; set; } 
        public String groupId{  get; set; } 
        public String groupProspectId{  get; set; } 
    }
}