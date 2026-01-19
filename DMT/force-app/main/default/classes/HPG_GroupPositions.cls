/**-------------------------------------------------------------------------------------------
* @Name     HPG GroupPositions
* @Author
* @Date     Created: 2024-06-24
* --------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* --------------------------------------------------------------------------------------------
*/
public with sharing class HPG_GroupPositions {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getGroupPositions(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = HPG_Utils.callService('HPG_GetGroupPositions', request);
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
    * @Description: Class Wrapper
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
    * @Description: Class Data
    */
    public class Data {

        /* @Description: groupId */
        @AuraEnabled
        public String groupId {get;set;}
    }
}