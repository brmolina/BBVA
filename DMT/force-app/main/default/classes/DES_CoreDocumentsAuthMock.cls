@isTest
public class DES_CoreDocumentsAuthMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('tsec', 'token-de-prueba-12345'); 
        res.setBody('{"status": "success", "message": "Autenticado correctamente"}');
        res.setStatusCode(200);
        return res;
    }
}