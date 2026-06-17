/*-------------------------------------------------------------------------------------------
* @Name     GroupPositions
* @Date     Created: 2025-02-25
* @Author   DMT
* -------------------------------------------------------------------------------------------
* @Description Wrapper Class for request 'group-positions' service
* -------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_GroupPositions {

    /**
    * @description Call service and return wrapper
    * @param request : request to call service
    * @return service data
    */
    public static Wrapper getGroupPositions(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService('DMT_HPG_GetGroupPositions', request);
        switch on response.getStatusCode() {
            when 200, 201 {
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

    /**
    * @Description: Wrapper
    */
    public class Wrapper {

        /* @Description: data */
        @AuraEnabled
        public Data data {get;set;}

        /* @Description: success */
        @AuraEnabled
        public boolean success {get;set;}

        /* @Description: errorMessage */
        @AuraEnabled
        public String errorMessage {get;set;}
    }

    /**
    * @Description: Data
    */
    public class Data {

        /* @Description: groupId */
        @AuraEnabled
        public String groupId {get;set;}
        public String groupName {get;set;}
        public String subgroupId {get;set;}
        public String supragroupId {get;set;}
    }
}