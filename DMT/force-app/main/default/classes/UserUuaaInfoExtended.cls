@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class UserUuaaInfoExtended {
    
    public static Wrapper getUserUuaaInfoExtended(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response;
        response = PRF_Utils.callService('getUserUuaaInfoExtended', request);
        System.debug('response: ' + response.getBody());
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                system.debug('Respuesta Json '+response.getBody());
                res = (Wrapper)obj;
                res.success = true;
            }
            when 404 {
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
            when else {
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        System.debug('res: ' + res);
        return res;
    }


    /***
    * @Description: Class Wrapper of UserExtended
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


        /* @Description: code */
        @AuraEnabled
        public String userCode {get;set;}

        /* @Description: name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: surname */
        @AuraEnabled
        public String surname {get;set;}

        /* @Description: secondSurname */
        @AuraEnabled
        public String secondSurname {get;set;}

        /* @Description: paisTrab */
        @AuraEnabled
        public String workCountry {get;set;}

        /* @Description: email */
        @AuraEnabled
        public String email {get;set;}

        /* @Description: organizationalUnit */
        @AuraEnabled
        public OrganizationalUnit organizationalUnit {get;set;}


        /* @Description: roles */
        @AuraEnabled
        public List<Role> roles {get;set;}

        /* @Description: attributes */
        @AuraEnabled
        public List<Attribute> attributeSet {get;set;}


    }

    public class OrganizationalUnit {

        /* @Description: unitCode */
        @AuraEnabled
        public String unitCode {get;set;}

        /* @Description: unitName */
        @AuraEnabled
        public String unitName {get;set;}

        /* @Description: parentCode1 */
        @AuraEnabled
        public String parentCode1 {get;set;}

        /* @Description: parentCode2 */
        @AuraEnabled
        public String parentCode2 {get;set;}

        /* @Description: parentCode3 */
        @AuraEnabled
        public String parentCode3 {get;set;}

        /* @Description: parentCode4 */
        @AuraEnabled
        public String parentCode4 {get;set;}

        /* @Description: parentCode5 */
        @AuraEnabled
        public String parentCode5 {get;set;}

        /* @Description: parentCode6 */
        @AuraEnabled
        public String parentCode6 {get;set;}

        /* @Description: parentCode7 */
        @AuraEnabled
        public String parentCode7 {get;set;}

        /* @Description: parentCode8 */
        @AuraEnabled
        public String parentCode8 {get;set;}

        /* @Description: parentCode9 */
        @AuraEnabled
        public String parentCode9 {get;set;}

        /* @Description: parentCode10 */
        @AuraEnabled
        public String parentCode10 {get;set;}

        /* @Description: parentName1 */
        @AuraEnabled
        public String parentName1 {get;set;}

        /* @Description: parentName2 */
        @AuraEnabled
        public String parentName2 {get;set;}

        /* @Description: parentName3 */
        @AuraEnabled
        public String parentName3 {get;set;}

        /* @Description: parentName4 */
        @AuraEnabled
        public String parentName4 {get;set;}

        /* @Description: parentName5 */
        @AuraEnabled
        public String parentName5 {get;set;}

        /* @Description: parentName6 */
        @AuraEnabled
        public String parentName6 {get;set;}

        /* @Description: parentName7 */
        @AuraEnabled
        public String parentName7 {get;set;}

        /* @Description: parentName8 */
        @AuraEnabled
        public String parentName8 {get;set;}

        /* @Description: parentName9 */
        @AuraEnabled
        public String parentName9 {get;set;}

        /* @Description: parentName10 */
        @AuraEnabled
        public String parentName10 {get;set;}

    }

    public class Role {

        /* @Description: uuaa */
        @AuraEnabled
        public String uuaa {get;set;}

        /* @Description: name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: roles */
        @AuraEnabled
        public List<Resource> resources {get;set;}

    }

    public class Resource{

        /* @Description: resourceCode */
        @AuraEnabled
        public String resourceCode {get;set;}

        /* @Description: value */
        @AuraEnabled
        public String value {get;set;}

        /* @Description: name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: type */
        @AuraEnabled
        public String type {get;set;}
    }

    public class Attribute{

        /* @Description: key */
        @AuraEnabled
        public String setCode {get;set;}

        /* @Description: roles */
        @AuraEnabled
        public List<Attributes> attributes {get;set;}
    }

    public class Attributes{

        /* @Description: key */
        @AuraEnabled
        public String attributeName {get;set;}

        /* @Description: value */
        @AuraEnabled
        public String attributeValue {get;set;}

    }

}