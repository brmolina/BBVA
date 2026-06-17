/**-------------------------------------------------------------------------------------------
* @Name     OpportunityCodes
* @Author
* @Date     Created: 2023-04-24
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class external opportunity/line code
*              https://catalogs.platform.bbva.com/apicatalog/business/apis/apis-finances-dmto/versions/global-0.17.0/resources/dmtoapiopportunitiescodesv0/
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DMT_OpportunityCodes {

    /**
    * @description Call service and return wrapper
    */
    @InvocableMethod
    public static List<String> getOpportunityCodeByFlow(List<List<String>> flowInput){
        Map<String, Object> mapRequest = new Map<String, Object>();
        List<String> returnList = new List<String>();
        List<String> listInput = flowInput[0];
        
        mapRequest.put('origin', listInput[0]);
        mapRequest.put('operationType', listInput[1]);
        mapRequest.put('entific', listInput[2]);
        returnList.add(getOpportunityCode(mapRequest).Data.opportunityId);
        return returnList;
    }

    public static Wrapper getOpportunityCode(Map<String, Object> request) {

        Wrapper res = new Wrapper();

        final HttpResponse response = DMT_Utils.callService('DMT_OpportunityCodes', request);

        switch on response.getStatusCode() {
            when 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                res.success = true;
            }
            when else {
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        return res;
    }

    public class Wrapper {

        /**Description: data*/
        @AuraEnabled
        public Data data {get;set;}

        /* @Description: pagination */
        @AuraEnabled
        public boolean success {get;set;}

        /* @Description: pagination */
        @AuraEnabled
        public String errorMessage {get;set;}
    }

    /**
    * @Description: Class Data
    */
    public class Data {

        /* @Description: line external code */
        @AuraEnabled
        public String opportunityId {get;set;}
    }
}