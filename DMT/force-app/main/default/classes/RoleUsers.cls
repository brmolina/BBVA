@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class RoleUsers {

    public static Wrapper getRoleUsers(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = PRF_Utils.callService('getRoleUsers', request);
        final HttpRequest req;

        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                system.debug('Respuesta Json '+response.getBody());
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
    * @Description: Class Wrapper of RoleUsers
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

    public class Data {

        /* @Description: uuaa */
        @AuraEnabled
        public String uuaa {get;set;}

        /* @Description: nombre */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: usuarios */
        @AuraEnabled
        public List<User> users {get;set;}

    }

    public class User {

        /* @Description: userId */
        @AuraEnabled
        public String userCode {get;set;}

        /* @Description: Name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: surname1 */
        @AuraEnabled
        public String surname1 {get;set;}

        /* @Description: surname2 */
        @AuraEnabled
        public String surname2 {get;set;}

        /* @Description: uo */
        @AuraEnabled
        public String ou {get;set;}

    }

}