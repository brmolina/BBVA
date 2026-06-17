public class DES_cls_TestResultMailer {
public static String toCsv(List<DES_cls_ToolingApiClient.TestFailureDTO> fails) {
        // Cabecera
        List<String> lines = new List<String>{
            'Clase,Metodo,Outcome,Mensaje,StackTrace'
        };
        for (DES_cls_ToolingApiClient.TestFailureDTO f : fails) {
            lines.add(String.join(new List<String>{
                csv(f.className), csv(f.methodName), csv(f.outcome), csv(f.message), csv(f.stackTrace)
            }, ','));
        }
        return String.join(lines, '\n');
    }
    private static String csv(String s) {
        if (s == null) return '""';
        // Escapar comillas y envolver
        String q = s.replace('"','\"\"');
        // Normaliza saltos de línea para evitar romper el CSV
        q = q.replace('\r',' ').replace('\n',' ');
        return '"' + q + '"';
    }

    public static void sendFailuresCsv(List<String> recipients, String runId, List<DES_cls_ToolingApiClient.TestFailureDTO> fails) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipients);
        mail.setSubject('[Apex Tests] Fallos en ejecución ' + runId);
        String body = (fails.isEmpty() 
            ? 'Ejecución ' + runId + ' completada sin fallos.'
            : 'Ejecución ' + runId + ' completada. Se adjunta CSV con fallos (' + fails.size() + ').');
        mail.setPlainTextBody(body);

        if (!fails.isEmpty()) {
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName('apex-test-failures-' + Date.today().format() + '.csv');
            att.setContentType('text/csv');
            att.setBody(Blob.valueOf(toCsv(fails)));
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { att });
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}