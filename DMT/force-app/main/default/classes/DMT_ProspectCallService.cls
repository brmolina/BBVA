/**-------------------------------------------------------------------------------------------
 * @Name     DMT_ProspectCallService
 * @Author   
 * @Date     Created: 2026-02-16
 * ------------------------------------------------------------------------------------------------
 * @Description Callable class for Omnistudio to get Wrapper for prospects
 * ------------------------------------------------------------------------------------------------
 */
public with sharing class DMT_ProspectCallService {
    
     public static Map<String, Object> callMergeProspectService (String g_customer_id, String gf_customer_prospect_id, String g_group_id ) {
        String result;
        Map<String, Object> outMap = new Map<String, Object>();
        try {

            Map<String, Object> request = new Map<String, Object>();
           

            request.put('g_customer_id', g_customer_id != null ? g_customer_id : '');
            request.put('gf_customer_prospect_id', gf_customer_prospect_id != null ? gf_customer_prospect_id : '');
            request.put('g_group_id', g_group_id != null ? g_group_id : '');
           
            final String serviceName = 'DMT_MergeProspect';
            HttpResponse response = DMT_HPG_Utils.callService_DMT(serviceName, request, true);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
                result = String.valueOf(response.getStatusCode());
            } else {
                throw new CalloutException('ERROR createProspect' + ' ' + response.getStatus() +  '\n' + response.getBody());
            }
            outMap.put('result', result);
        } catch (Exception e) {
            outMap.put('error', true);
            outMap.put('errorMessage', JSON.serialize(new Map<String,Object> {'message' => e.getMessage(),'stackTrace' => e.getStackTraceString(),'type' => e.getTypeName()}));
        }
        return outMap;
    }

    public class prospectCallServiceWrapper{

        public prospectCallServiceWrapper (String g_customer_id, String gf_customer_prospect_id, String g_group_id) {
            this.g_customer_id = g_customer_id;
            this.gf_customer_prospect_id = gf_customer_prospect_id;
            this.g_group_id = g_group_id;
        }

        public String g_customer_id{  get; set; } 
        public String gf_customer_prospect_id{  get; set; } 
        public String g_group_id{  get; set; } 
    }
}