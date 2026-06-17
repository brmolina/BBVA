public class DES_cls_ToolingApiClient {

    public static final String base = System.Url.getOrgDomainUrl().toExternalForm();
    public static final String API_VERSION = '62.0'; // ajusta a tu versión mínima soportada
    public static final String sessionId = UserInfo.getSessionId(); 

    public class RunResponse { public String id; }

    public static String runAllLocalTests(Boolean skipCoverage) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(base+ '/services/data/v' + API_VERSION + '/tooling/runTestsAsynchronous');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + sessionId);//NOSONAR
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'testLevel' => 'RunLocalTests',
            'skipCodeCoverage' => skipCoverage
        }));
               
        System.debug('req:::'+req.getBody());
        HttpResponse res = h.send(req);
        // 🛑 AÑADIR ESTO PARA VERIFICAR LA RESPUESTA
        System.debug('HTTP Status Code: ' + res.getStatusCode());
        System.debug('HTTP Status: ' + res.getStatus());
        System.debug('Response Body: ' + res.getBody());
        // 🛑 FIN DE INSPECCIÓN
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
          String responseBody = res.getBody();
            
            try {
                RunResponse r = (RunResponse) JSON.deserialize(responseBody, RunResponse.class);
                return r.id; 
            } catch(System.JSONException jsonEx) {
                if (responseBody.startsWith('"') && responseBody.endsWith('"')) {
                    String runId = responseBody.replaceAll('"', '');
                    System.debug('ID extraído como cadena: ' + runId);
                    return runId;
                } else {
                    throw jsonEx;
                }
            }
        }
        throw new CalloutException('Error lanzando tests: ' + res.getStatus() + ' ' + res.getBody());
    }

    public class RunStatusDTO {
        public String status; 
        public String runResultId; 
    }

    public static RunStatusDTO getRunStatus(String runId) {
        String soql = 'SELECT Id, Status FROM ApexTestRunResult WHERE AsyncApexJobId  = \'' + String.escapeSingleQuotes(runId) + '\'';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(base + '/services/data/v' + API_VERSION + '/tooling/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + sessionId);//NOSONAR
        HttpResponse res = h.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) m.get('records');
            if (records != null && !records.isEmpty()) {
                Map<String, Object> record = (Map<String, Object>) records[0];
                
                RunStatusDTO result = new RunStatusDTO();
                result.status = (String) record.get('Status'); 
                result.runResultId = (String) record.get('Id'); 
                
                return result;
            }
            RunStatusDTO pending = new RunStatusDTO();
            pending.status = 'Pending';
            pending.runResultId = null;
            return pending;
        }
        throw new CalloutException('Error consultando estado: ' + res.getStatus() + ' ' + res.getBody());
    }

    public class TestFailureDTO {
        public String className;
        public String methodName;
        public String message;
        public String stackTrace;
        public String outcome;
    }

    public static List<TestFailureDTO> getFailures(String runId) {
        String soql = 'SELECT ApexClass.Name, MethodName, Outcome, Message, StackTrace ' +
                      'FROM ApexTestResult ' +
                      'WHERE ApexTestRunResultId = \'' + String.escapeSingleQuotes(runId) + '\' ' +
                      'AND Outcome = \'Fail\' ' +
                      'ORDER BY ApexClass.Name, MethodName';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(base + '/services/data/v' + API_VERSION + '/tooling/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + sessionId);//NOSONAR
        HttpResponse res = h.send(req);
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) payload.get('records');
            List<TestFailureDTO> out = new List<TestFailureDTO>();
            for (Object o : records) {
                Map<String,Object> r = (Map<String,Object>) o;
                Map<String,Object> cls = (Map<String,Object>) r.get('ApexClass');
                TestFailureDTO dto = new TestFailureDTO();
                dto.className = (String) cls.get('Name');
                dto.methodName = (String) r.get('MethodName');
                dto.outcome = (String) r.get('Outcome');
                dto.message = (String) r.get('Message');
                dto.stackTrace = (String) r.get('StackTrace');
                out.add(dto);
            }
            return out;
        }
        throw new CalloutException('Error consultando fallos: ' + res.getStatus() + ' ' + res.getBody());
    }

}