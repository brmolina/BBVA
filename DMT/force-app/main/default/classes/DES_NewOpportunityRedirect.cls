public class DES_NewOpportunityRedirect {

    @AuraEnabled
    public static String getDomain(){
        return URL.getOrgDomainURL().toExternalForm().split('.cs')[0];
        //return URL.getOrgDomainURL().getHost().split('.cs83.my.salesforce.com')[0];
    }
    
}