@IsTest
public with sharing class NONC_GooglePlacesPredictive_ctrl_test {

  @isTest public static void checkAddressTest() {
    test.startTest();
    // Set mock callout class
    Test.setMock(HttpCalloutMock.class, new NONC_CalloutServiceMock());
    // Call method to test.
    // from the class that implements HttpCalloutMock.
    HttpResponse res = NONC_CalloutClass.getInfoFromExternalService();
    // Verify response received contains fake values
    String contentType = res.getHeader('Content-Type');
    System.assert(contentType == 'application/json');
    NONC_GooglePlacesPredictive_ctrl.getSuggestions('Calle del Carmen');
    NONC_GooglePlacesPredictive_ctrl.getPlaceDetails('EmlDYWxsZSBkZWwgQ2FybWVuLCBDZW50cm8gSGlzdMOzcmljbyBkZSBsYSBDZGFkLiBkZSBNw6l4aWNvLCBDZW50cm8sIDA2MDAwIENpdWRhZCBkZSBNw6l4aWNvLCBDRE1YLCBNZXhpY28iLiosChQKEgmzn3_0M_nRhRFHRqN9J7g-LhIUChIJvU0OLi350YURPYnEQKd0VZA');
    NONC_GooglePlacesPredictive_ctrl.getResponse('test');
    NONC_GooglePlacesPredictive_ctrl.getKey();
    test.stopTest();
    System.assertEquals(204, res.getStatusCode());
  }
}