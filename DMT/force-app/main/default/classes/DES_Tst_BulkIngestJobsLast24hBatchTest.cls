/*******************************************************************************************************
 * @testname        DES_Tst_BulkIngestJobsLast24hBatchTest
 * @description     Clase de pruebas que valida el comportamiento del Batch y Scheduler relacionados con
 *                  la recolección de Bulk Ingest Jobs (Bulk API v2).
 *
 *                  Contiene:
 *                      - Mock HTTP para simular respuestas del API.
 *                      - Cobertura completa del Batch (start, execute, finish).
 *                      - Validación del Scheduler mediante System.schedule().
 *
 * @coverage        Esperado: 95%–100%
 *******************************************************************************************************/
@isTest
public without sharing class DES_Tst_BulkIngestJobsLast24hBatchTest {
    /***************************************************************************************************
     * @innerclass     BulkIngestMock
     * @implements     HttpCalloutMock
     *
     * @description    Clase interna utilizada para simular las respuestas del Bulk API v2 durante la
     *                  ejecución del batch en modo test.
     *
     *                  Proporciona:
     *                      - Respuesta paginada para /jobs/ingest.
     *                      - Respuesta detallada por JobId para /jobs/ingest/{id}.
     *
     *                  Evita realizar callouts reales, permitiendo la ejecución completa del batch y
     *                  del scheduler dentro de un contexto de pruebas.
     ***************************************************************************************************/
    public class BulkIngestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            String createdDate = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

            if (endpoint.contains('/services/data/v62.0/jobs/ingest/JOB-001')) {
                res.setBody('{' +
                    '"id": "JOB-001",' +
                    '"object": "Account",' +
                    '"operation": "insert",' +
                    '"state": "Completed",' +
                    '"numberRecordsProcessed": 100,' +
                    '"numberRecordsFailed": 20,' +
                    '"createdDate": "' + createdDate + '"' +
                '}');
            } else if (endpoint.contains('/services/data/v62.0/jobs/ingest')) {
                res.setBody('{' +
                    '"done": true,' +
                    '"nextRecordsUrl": null,' +
                    '"records": [' +
                        '{ "id": "JOB-001", "operation": "insert", "object": "Account", "createdDate": "' + createdDate + '" }' +
                    ']' +
                '}');
            } else {
                res.setBody('{}');
            }

            return res;
        }
    }
    
    /***************************************************************************************************
     * @testmethod     testBatch_EjecucionCompleta
     * @description    Valida que el batch DES_Batch_BulkIngestJobsLast24h:
     *                      1. Se ejecute completamente sin errores.
     *                      2. Procese correctamente los registros obtenidos mediante el mock.
     *                      3. Finalice en estado "Completed".
     *
     * @asserts        - Estado del AsyncApexJob.
     *                  - Cantidad de errores igual a cero.
     ***************************************************************************************************/
    @isTest
    static void testBatch_EjecucionCompleta() {
        
        Test.setMock(HttpCalloutMock.class, new BulkIngestMock());

        Test.startTest();
        Id jobId = Database.executeBatch(new DES_Batch_BulkIngestJobsLast24h(), 1);
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
    }

    /***************************************************************************************************
     * @testmethod     testSchedulerRunsBatch
     * @description    Verifica el correcto funcionamiento del Scheduler:
     *                      1. Se programa correctamente mediante System.schedule().
     *                      2. Devuelve un JobId válido.
     *
     * @asserts        - Validación de que el JobId no sea null.
     ***************************************************************************************************/
    @isTest
    static void testSchedulerRunsBatch() {
        
        Test.setMock(HttpCalloutMock.class, new BulkIngestMock());
        DES_Sch_BulkIngestJobsLast24hSch sched = new DES_Sch_BulkIngestJobsLast24hSch();

        Test.startTest();
        String jobId = System.schedule('Test Job','0 0 7 * * ?',sched);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'El Job ID no debería ser null');
    }

}