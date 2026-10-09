public without sharing class DMT_NBC_OppApprovalProcessRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    // The only genuinely persisted field this renders is DMT_Financial_Sponsors__c. Everything else
    // (Approver/Task/Status/User/dates/Result/Comments) is the approval workflow's own LIVE state -
    // watching it would be circular, restarting the very tasks being processed.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Financial_Sponsors__c'};
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return buildEmptyApprovalTableHtml();
        }

        try {
            return renderIBFAndGTBHtml(data);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppApprovalProcessRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderIBFAndGTBHtml(DMT_ViewController.LineDataWrapper data) {
        List<DMT_Case_Steps_Controller.WRAPPER_Step> sourceSteps = getAvailableApprovalSteps(data);
        List<DMT_Case_Steps_Controller.WRAPPER_Step> approvalFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        // Filtramos los steps para obtener solo los de approval
        if (sourceSteps != null && !sourceSteps.isEmpty()) {
            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : sourceSteps) {
                if (isApprovalFeature(feature)) {
                    if (feature?.featureName != null) {
                        approvalFeatures.add(feature);
                    } else if (feature?.subitems != null && !feature.subitems.isEmpty()) {
                        approvalFeatures.add(feature.subitems[0]);
                    }
                }
            }
        }

        if (approvalFeatures.isEmpty()) {
            return buildEmptyApprovalTableHtml();
        }

        String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'
                    + '<h2 style="font-size: 12px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Process</h2>';

        for (DMT_Case_Steps_Controller.WRAPPER_Step feature : approvalFeatures) {
            if (isApprovalFeature(feature)) {
                // Si el nombre de la feature está vacío, usamos el título genérico
                String title = String.isNotBlank(feature.featureName) ? feature.featureName : 'Approval Process';

                html += '<div style="margin-bottom: 20px;">'
                    + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: center; border: 1px solid #ccc;">'

                    // Título de la tabla (Fondo Azul, texto blanco)
                    + '<tr>'
                    + '<td colspan="7" style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-align: left;">' + title + '</td>'
                    + '</tr>'

                    // Cabeceras (7 columnas, texto azul)
                    + '<tr>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Approver</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Task</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Status</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">User</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Start Date</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">End Date</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Result</td>'
                    + '</tr>';

                // Generar fila de datos y comentarios para la feature principal
                html += generateRows(feature);

                // Generar fila de datos y comentarios para los subitems, si existen
                if (feature.subitems != null && !feature.subitems.isEmpty()) {
                    for (DMT_Case_Steps_Controller.WRAPPER_Step task : feature.subitems) {
                        html += generateRows(task);
                    }
                }

                html += '</table></div>';
            }
        }

        // ── Financial Sponsors field ────────────────────────────────────────
        String fsCheckboxStyle = 'display: inline-block; width: 12px; height: 12px; border: 1px solid #004481; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial, sans-serif; font-size: 10px; color: #004481; font-weight: bold; margin-right: 6px;';
        String fsCheckValue = data.opportunity.DMT_Financial_Sponsors__c == true ? 'X' : '&nbsp;';
        html += '<div style="margin-bottom: 10px; font-family: Arial, sans-serif; font-size: 11px; color: #004481;">'
             + '<div style="' + fsCheckboxStyle + '">' + fsCheckValue + '</div>'
             + '<strong>Financial Sponsors</strong>'
             + '</div>';

        html += '</div>';
        return html;
    }
    private String buildEmptyApprovalTableHtml() {
        String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'
                    + '<div style="margin-bottom: 20px;">'
                    + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: center; border: 1px solid #ccc;">'
                    + '<tr>'
                    + '<td colspan="7" style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-align: left;">Approval Process</td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Approver</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Task</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Status</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">User</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Start Date</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">End Date</td>'
                    + '<td style="color: #004481; padding: 6px; border-bottom: 1px solid #ccc; font-weight: bold;">Result</td>'
                    + '</tr>'
                    + generateRows(new DMT_Case_Steps_Controller.WRAPPER_Step())
                    + '</table></div></div>';
        return html;
    }

    // ====================================================================================================
    // HELPER: Genera la fila de valores (7 columnas) + la fila de comentarios (1 columna que ocupa todo)
    // ====================================================================================================
    private String generateRows(DMT_Case_Steps_Controller.WRAPPER_Step item) {
        String row = '<tr>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item.approver) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item?.step?.urlLabel) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item.status) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item.user) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item.startDate) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item.endDate) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: top;">' + DMT_FormattingUtils.checkNull(item.result) + '</td>'
                   + '</tr>';
                   
        // Fila de comentarios abajo de todo ocupando las 7 columnas
        row += '<tr>'
             + '<td colspan="7" style="padding: 6px; background-color: #f2f2f2; text-align: left; border-bottom: 1px solid #ccc; color: #000000;">'
             + 'Comments: ' + DMT_FormattingUtils.checkNull(item.description)
             + '</td>'
             + '</tr>';
             
        return row;
    }

    private List<DMT_Case_Steps_Controller.WRAPPER_Step> getAvailableApprovalSteps(DMT_ViewController.LineDataWrapper data) {
        if (data.allsteps != null && !data.allsteps.isEmpty()) {
            return data.allsteps;
        }
        if (data.sanctionOppAllsteps != null && !data.sanctionOppAllsteps.isEmpty()) {
            return data.sanctionOppAllsteps;
        }
        if (data.sanctionAllsteps != null && !data.sanctionAllsteps.isEmpty()) {
            return data.sanctionAllsteps;
        }
        return new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
    }

    private Boolean isApprovalFeature(DMT_Case_Steps_Controller.WRAPPER_Step feature) {
        return feature != null && (feature?.featureType == null || 'approval'.equalsIgnoreCase(feature.featureType));
    }
}