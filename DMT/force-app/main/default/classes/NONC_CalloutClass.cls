public with sharing class NONC_CalloutClass {
  public static HttpResponse getInfoFromExternalService() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('ENDPOINT');
    req.setMethod('GET');
    Http h = new Http();
    HttpResponse res = h.send(req);
    return res;
  }
}