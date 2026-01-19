/**
 * @author: Vido
 *
 * @ClassName: DMT_SingleRequestMock
 *
 * @Description: Mock class for tests
 */
@isTest
public class DMT_SingleRequestMock implements HttpCalloutMock {

    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;

    public class Wrapper {
		public Integer code { get; set; }
		public String status { get; set; }
		public String bodyAsString { get; set; }
		public Blob bodyAsBlob { get; set; }
		public Map<String, String> responseHeaders { get; set; }
    }

	/**
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* @Author Vido
	* @Date 2024
	* @Description Request Constructor with body type String
	**/
	public DMT_SingleRequestMock(Wrapper item) {
		this.code = item.code;
		this.status = item.status;
		this.bodyAsString = item.bodyAsString;
		//this.bodyAsBlob = item.bodyAsBlob;
		this.responseHeaders = item.responseHeaders;
	}

	/**
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* @Author Vido
	* @Date 2024
	* @Description return the respond for a given request
	**/
	public HTTPResponse respond(HTTPRequest req) {
	    HttpResponse resp = new HttpResponse();
		resp.setStatusCode(code);
		resp.setStatus(status);
		if (bodyAsBlob != null) {
			resp.setBodyAsBlob(bodyAsBlob);
		} else {
			resp.setBody(bodyAsString);
		}

		if (this.responseHeaders != null) {
			for (String key : this.responseHeaders.keySet()) {
			    resp.setHeader(key, this.responseHeaders.get(key));
			}
		}
		return resp;
	}
}