/*******************************************************************************************************
 * @name            DES_Batch_BulkIngestJobsLast24h
 * @author          David Díaz
 * @created         06/10/2025
 * @description     Batch Apex encargado de recopilar, procesar y consolidar información de todos los
 *                  Bulk Data Load Jobs (Bulk API v2 – Ingest) creados en las últimas 24 horas.
 *
 *                  Funcionalidad:
 *                      1. Pagina el endpoint REST /services/data/v62.0/jobs/ingest, obteniendo todos
 *                         los registros disponibles incluso más allá del límite de 200 por página.
 *                      2. Filtra únicamente los jobs creados dentro de la ventana temporal analizada.
 *                      3. Recupera el detalle individual de cada Job (estado, operación, totales, etc.).
 *                      4. Construye un archivo Excel (HTML) con el consolidado.
 *                      5. Envía el archivo por correo electrónico al destinatario configurado.
 *
 * @implementation  Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts
 * @scope           50 registros por ejecución (optimizado para límite de callouts).
 *
 * @limitations     - Requiere permisos de API.
 *                  - Realiza múltiples callouts HTTP, por lo que solo debe ejecutarse 1 vez al día.
 *
 * @scheduler       Invocado por DES_Sch_BulkIngestJobsLast24hSch.
 * @test            DES_Tst_BulkIngestJobsLast24hBatchTest
 *******************************************************************************************************/
public with sharing class DES_Batch_BulkIngestJobsLast24h implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts{
    private List<Map<String, String>> jobData = new List<Map<String, String>>();
    private static final String RECIPIENT = Label.EmailService_LogAnalizer_ToAddress;
    private String customMessage = '';
    /***************************************************************************************************
     * @method         start
     * @description    Punto inicial del Batch. Realiza:
     *                      1. Llamada REST paginada al endpoint Bulk API v2 (/jobs/ingest).
     *                      2. Filtrado de jobs por ventana temporal (últimas 24h).
     *                      3. Recolección de IDs de cada Job para procesarlos en execute().
     *
     *                  En modo test, se omite el filtrado temporal para permitir la simulación completa.
     *
     * @returns        Iterable<String> → Lista de IDs de Jobs a procesar en execute().
     *
     * @callouts       Sí, múltiples GET al endpoint público de Bulk API.
     ***************************************************************************************************/
    public Iterable<String> start(Database.BatchableContext bc){

        List<String> jobIds = new List<String>();
        Datetime endDt = System.now();
        Datetime startDt = endDt.addDays(-1);

        String base = System.Url.getOrgDomainUrl().toExternalForm();
        String url = base + '/services/data/v62.0/jobs/ingest';

        Http http = new Http();
        Integer pageCounter =1;

        while (String.isNotBlank(url)){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            HTTPResponse res = http.send(req);

            if (res.getStatusCode() != 200){
              this.customMessage = 'Error en API: ' + res.getStatusCode() + ' - ' + res.getBody()+' URL intentada: ' + url;
                System.debug(LoggingLevel.ERROR, this.customMessage);
                break;
            }else {

                Map<String, Object> page = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>)page.get('records');

                String nextUrl = (String)page.get('nextRecordsUrl');
                if(pageCounter ==1){
                    if (String.isNotBlank(nextUrl)) {
                        String nextUrlModificada = nextUrl.substring(0, nextUrl.lastIndexOf('-')+1);
                        url = nextUrlModificada.startsWith('http') ? nextUrlModificada : base + nextUrlModificada+'800';
                        pageCounter++;
                        continue;
                    } else {
                        processRecords(records, startDt, endDt, jobIds);
                        url = null;
                    }
                }else{
                    processRecords(records, startDt, endDt, jobIds);

                    if (String.isNotBlank(nextUrl)) {
                        url = nextUrl.startsWith('http') ? nextUrl : base + nextUrl;
                        pageCounter++;
                    } else {
                        url = null;
                    }
                } 
            }
        }

        return jobIds;
    }

    private void processRecords(List<Object> records, Datetime startDt, DateTime endDt, List<String> jobIds){
        for (Object obj : records) {
            Map<String, Object> job = (Map<String, Object>)obj;
            Datetime created = (Datetime)JSON.deserialize('"' + (String)job.get('createdDate') + '"', Datetime.class);

            if (!Test.isRunningTest()){
                if (created >= startDt && created <= endDt){
                    jobIds.add((String) job.get('id'));
                }
            } else{
                jobIds.add((String) job.get('id'));
            }
        }
    }

    /***************************************************************************************************
     * @method         execute
     * @description    Procesa en detalle cada Job en el scope:
     *                      1. Realiza un callout GET por cada Job (/jobs/ingest/{jobId}).
     *                      2. Extrae información relevante:
     *                          - Objeto
     *                          - Operación
     *                          - Estado
     *                          - Registros procesados / fallidos
     *                          - Fecha de creación
     *                      3. Calcula el porcentaje de error.
     *                      4. Acumula la información estructurada en la variable stateful jobData.
     *
     * @params         bc    → Contexto de ejecución del batch.
     * @params         scope → Lista de IDs del Job (cada ejecución procesa un subconjunto).
     *
     * @stateful       Sí, almacena resultados en jobData para su uso en finish().
     *
     * @callouts       Sí, un callout por job.
     ***************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<String> scope){
        Http http = new Http();
        for (String jobId : scope){
            HttpRequest det = new HttpRequest();
            det.setEndpoint(System.Url.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/jobs/ingest/' + jobId);
            det.setMethod('GET');
            det.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            HTTPResponse r = http.send(det);

            if (r.getStatusCode() != 200){
                System.debug(LoggingLevel.WARN, 'No se pudo leer detalle de ' + jobId + ': ' + r.getStatusCode());
                continue;
            }

            Map<String, Object> d = (Map<String, Object>)JSON.deserializeUntyped(r.getBody());
            Integer failedPercent = 0;
            if (Integer.valueOf(d.get('numberRecordsFailed')) > 0){
                failedPercent = (Integer.valueOf(d.get('numberRecordsFailed')) / Integer.valueOf(d.get('numberRecordsProcessed'))) * 100;
            }

            Map<String, String> row = new Map<String, String>{ 'JobId' => (String) d.get('id'), 'Object' => (String) d.get('object'), 'Operation' => (String) d.get('operation'), 'State' => (String) d.get('state'), 'Processed' => String.valueOf(d.get('numberRecordsProcessed')), 'Failed' => String.valueOf(d.get('numberRecordsFailed')), 'Error Percent' => String.valueOf(failedPercent) + '%', 'CreatedDate' => (String) d.get('createdDate') };
            jobData.add(row);
        }
    }

    /***************************************************************************************************
     * @method         finish
     * @description    Fase final del Batch. Realiza:
     *                      1. Construcción dinámica de un archivo Excel (HTML compatible con .xls).
     *                      2. Inserción de filas basadas en la data acumulada en jobData.
     *                      3. Generación del Blob binario del archivo.
     *                      4. Envío por correo electrónico al destinatario configurado.
     *
     *                  El archivo no se guarda en Salesforce, solo se adjunta en el email.
     *
     * @email          Usa EmailFileAttachment para adjuntar el Excel.
     * @recipient      Label.EmailService_LogAnalizer_ToAddress
     *
     * @callouts       No.
     ***************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        String subject;
        String body;
        Boolean hayDatos = !jobData.isEmpty();

        if (hayDatos) {
            subject = 'Bulk Ingest Jobs - Últimas 24h (' + Date.today().format() + ')';
            body = 'Adjunto encontrarás el reporte Excel con los Bulk Data Load Jobs procesados en las últimas 24 horas.';
        } else {
            subject = 'Bulk Ingest Jobs - Últimas 24h - Sin resultados o Aviso de Entorno';
            body = 'No se han encontrado registros para procesar.';
            // Si customMessage tiene algo (el error del salto en PRE), lo añadimos al cuerpo
            if (String.isNotBlank(this.customMessage)) {
                body += '\n\nDetalle técnico del entorno: ' + this.customMessage;
            }
        }
        String html = '' + 
                   '<html xmlns:x="urn:schemas-microsoft-com:office:excel">' + 
                   '<head>' + 
                   '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>' + 
                   '<style>' + 
                   'table { border-collapse: collapse; width: 100%; }' + 
                   'th, td { border: 1px solid #999; padding: 4px; text-align: left; }' + 
                   'th { background-color: #f2f2f2; }' + 
                   '</style>' + 
                   '</head><body>' + 
                   '<table x:autofilter="all">' + 
                   '<thead><tr>' + 
                   '<th>JobId</th><th>Object</th><th>Operation</th><th>State</th>' + 
                   '<th>Processed</th><th>Failed</th><th>Error Percent</th><th>CreatedDate</th>' + 
                   '</tr></thead><tbody>';

        for (Map<String, String> row : jobData){
            html += '<tr>' + 
                    '<td>' + safe(row.get('JobId')) + '</td>' + 
                    '<td>' + safe(row.get('Object')) + '</td>' + 
                    '<td>' + safe(row.get('Operation')) + '</td>' + 
                    '<td>' + safe(row.get('State')) + '</td>' + 
                    '<td>' + safe(row.get('Processed')) + '</td>' + 
                    '<td>' + safe(row.get('Failed')) + '</td>' + 
                    '<td>' + safe(row.get('Error Percent')) + '</td>' + 
                    '<td>' + safe(row.get('CreatedDate')) + '</td>' + 
                    '</tr>';
        }

        html += '</tbody></table></body></html>';

        Blob excelBlob = Blob.valueOf(html);

        try{
             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ RECIPIENT });
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            if(hayDatos){
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setFileName('Bulk_Ingest_Jobs_' + Date.today().format() + '.xls');
                attach.setBody(excelBlob);
                attach.setContentType('application/vnd.ms-excel');
                mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attach });
            }
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            System.debug('Excel enviado correctamente a ' + RECIPIENT);
        } catch (Exception e){
            System.debug(LoggingLevel.ERROR, 'Error enviando Excel: ' + e.getMessage());
        }
    }

    /***************************************************************************************************
     * @method         safe
     * @description    Limpia caracteres especiales para evitar problemas de renderización HTML
     *                 dentro del archivo Excel generado.
     *
     * @param          s → Texto a sanear.
     * @returns        String → Texto limpio y seguro para insertarse en HTML.
     ***************************************************************************************************/
    private static String safe(String s){
        if (s == null)
            return '';
        return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;').replace('\'', '&#39;');
    }

}