public with sharing class DailyDataQualityJob implements Schedulable {


    public void execute(SchedulableContext sc) {
        executeDataQualityChecks();
    }

    public String executeDataQualityChecks() {
         // 1. Cargar configuración
        DataQualityJobConfig__mdt cfg = DataQualityJobConfig__mdt.getInstance('Default');

        if (cfg == null || !cfg.IsActive__c) {
            System.debug('Job deshabilitado por configuración.');
            return 'Job deshabilitado por configuración.';
        }
        
        // 2. Métricas de Account
        Integer totalAccounts = [SELECT COUNT() FROM Account];
        Integer activeAccounts = [SELECT COUNT() FROM Account WHERE gf_prtcpt_act_status_ind_type__c = TRUE];

        Integer activePercentage = totalAccounts > 0 ? Integer.valueOf((Decimal.valueOf(activeAccounts) / totalAccounts) * 100) : 0;

        // 3. Verificación de relaciones
        Integer rel1 = [SELECT COUNT() FROM dwp_acmh__GBL_Account_Relationship__c];
        Integer rel2 = [SELECT COUNT() FROM DES_Subsidiary_Group_Relation__c];

        // 4. Evaluación de reglas
        Boolean alert = false;
        String issues = '';
        Integer size1 = 6;
        Integer size2 = 24;

        if (activePercentage < cfg.Threshold__c) {
            alert = true;
            issues = issues + '% de Cuentas Activas (gf_prtcpt_act_status_ind_type__c = true)    | ' + addPadding('FALLO',size1) + ' | ' + addPadding(activePercentage + '%', size2) + ' | ' + cfg.Threshold__c + '%\n';
        }

        if (rel1 == 0) {
            alert = true;
            issues = issues + 'Registros de Relaciones (dwp_acmh_GBL_Account_Relationship__c)    | ' + addPadding('FALLO',size1) + ' | ' + addPadding(rel1 + ' registros', size2) + ' | > 0 registros\n';
        }

        if (rel2 == 0) {
            alert = true;
            issues = issues + 'Registros de Grupo Subsidiario (DES_Subsidiary_Group_Relation__c) | ' + addPadding('FALLO',size1) + ' | ' + addPadding(rel2 + ' registros', size2) + ' | > 0 registros\n';
        }

        // 5. Construcción del email
        if (alert) {
            sendEmail(cfg.TargetEmail__c, issues);
        }
        System.debug('FIN DEL JOB.');
        return issues;
    }
       




    // Función para enviar email
    public void sendEmail(String target, String issues){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        Id orgWideId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'ans_clientcloud@bbva.com' LIMIT 1].Id;
        email.setOrgWideEmailAddressId(orgWideId);
        email.setToAddresses(new String[]{ target });
        email.setSubject('[ALERTA CRÍTICA] Fallo en la Calidad de Datos - Job Diario' + Date.today().format());

        String body = '<p>Estimado equipo ANS,</p>' +

        '<p>El Job de monitoreo de Calidad y Salud de Datos (Data Health Check), ejecutado a las 07:00 AM, ha detectado una o varias anomalías críticas que requieren su atención inmediata. ' +
        'La integridad de los datos de Cuenta y Relaciones es fundamental para la operatividad del sistema.</p>' +

        '<p><b>Resumen de Anomalías Detectadas</b><br>' +
        'A continuación, se detalla la métrica que ha fallado el umbral de aceptación:</p>' +

        '<pre><b>Métrica Evaluada                                                  | Estado | Valor Actual             | Umbral Aceptable</b>\n' +
        '------------------------------------------------------------------|--------|--------------------------|------------------\n' +
        issues + '</pre>' +

        '<p><b><i>Nota: Los campos marcados como "FALLO" indican la acción requerida.</i></b></p>' +

        '<p><b>Acción Recomendada: Prioridad de Ingesta de Datos</b><br>' +
        'Si la anomalía detectada requiere la ingesta de datos desde un backup (Fullcopy) o la restauración de registros, por favor, sigan estrictamente el siguiente orden de prioridad para garantizar la integridad referencial y evitar errores de dependencia:</p>' +

        '<ol>' +
        '<li>Accounts (Entidad principal)</li>' +
        '<li>dwp_acmh_GBL_Account_Relationship__c (Relaciones de Cuenta Globales)</li>' +
        '<li>DES_Subsidiary_Group_Relation__c (Relaciones de Grupo Subsidiario)</li>' +
        '</ol>' +

        '<p>Favor de confirmar la recepción y el inicio de la investigación.</p>' +
        '<p>Atentamente,<br>Sistema de Monitoreo Automático de Calidad de Datos</p>';

        email.setHtmlBody(body);
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
        }
    }


    // Función para rellenar con espacios
    String addPadding(String text, Integer size) {
        if (text == null) text = '';
        while (text.length() < size) {
            text += ' ';
        }
        return text;
    }

}