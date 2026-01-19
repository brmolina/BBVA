/**
* @description Interface that can be extended implementing your own Apex authentication class if needed.
* The framework provides authentication implementation that you can use:
* iaso_GBL_Integration_GrantingTickets
**/
public interface iaso_GBL_Integration_Authentication {
  HttpRequest applySecurity(HttpRequest request, iaso__GBL_Authentication_Service__mdt authenticationConfig);
  iaso__GBL_Application_Log__c resetToken(iaso__GBL_Authentication_Service__mdt authenticationConfig);
  Boolean isAuthenticated(iaso__GBL_Authentication_Service__mdt authenticationConfig);
}