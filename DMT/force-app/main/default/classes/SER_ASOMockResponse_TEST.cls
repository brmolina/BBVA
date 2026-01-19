/*--------------------------------------------------------------------------------
    @author       Accenture
    @date         17/01/2018
    @description  TEST for MOCK HTTP.
    ------------------------------------------------------------------------------------*/
@isTest
public with sharing class SER_ASOMockResponse_TEST implements HttpCalloutMock {
  /*Http response code */
  protected Integer code;
  /*Http response status */
  protected String status;
  /*Http response body */
  protected String bodyAsString;
  /*Http response body as bitmap */
  protected Blob bodyAsBlob;
  /*Http response headers */
  protected Map<String, String> responseHeaders;
  /*Body null*/
  private final blob BLB_BODY_NULL;
  /*String body null*/
  private final string STR_BODY_NULL;

  /*Constructor with body as string*/
  public SER_ASOMockResponse_TEST(Integer code, String status, String body, Map<String, String> responseHeaders) {
    this.status = status;
    this.code = code;
    this.bodyAsString = body;
    this.bodyAsBlob = BLB_BODY_NULL;
    this.responseHeaders = responseHeaders;
  }

  /*Constructor with body as bitmap*/
  public SER_ASOMockResponse_TEST(Integer code, String status, Blob body, Map<String, String> responseHeaders) {
    this.code = code;
    this.status = status;
    this.bodyAsBlob = body;
    this.bodyAsString = STR_BODY_NULL;
    this.responseHeaders = responseHeaders;
  }

  /*--------------------------------------------------------------------------------
      @author       Accenture
      @date         17/01/2018
      @description  TEST for respond
          IN HTTPRequest
          OUT HTTPResponse
      ------------------------------------------------------------------------------------*/
  public HTTPResponse respond(HTTPRequest req) {
    final HttpResponse resp = new HttpResponse();
    resp.setStatusCode(code);
    resp.setStatus(status);

    if (bodyAsBlob == null) {
      resp.setBody(bodyAsString);
    } else {
      resp.setBodyAsBlob(bodyAsBlob);
    }

    if (responseHeaders != null) {
      for (String key : responseHeaders.keySet()) {
        resp.setHeader(key, responseHeaders.get(key));
      }
    }

    return resp;
  }
}