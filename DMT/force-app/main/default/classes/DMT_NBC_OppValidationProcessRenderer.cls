public without sharing class DMT_NBC_OppValidationProcessRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {

        try {
            return data.opportunity != null && data.opportunity.DMT_Product_Area__c == 'GTB' ? renderGTBHtml(data) : renderIBFHtml(data);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppValidationProcessRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderIBFHtml(DMT_ViewController.LineDataWrapper data) {

        if (data == null || data.allsteps == null || data.allsteps.isEmpty()) {
            return '<div>Validation process not provided</div>';
        }

        List<DMT_Case_Steps_Controller.WRAPPER_Step> validationFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        // Filtramos los steps para obtener solo los de passport (Validation)
        for (DMT_Case_Steps_Controller.WRAPPER_Step feature : data.allsteps) {
            if (feature?.featureType == 'passport' || feature?.featureType == null) {
                if (feature?.featureName != null) {
                    validationFeatures.add(feature);
                } else if (feature?.subitems != null && !feature.subitems.isEmpty()) {
                    validationFeatures.add(feature.subitems[0]);
                }
            }
        }

        if (validationFeatures.isEmpty()) {
            return '<div>There is no information about the validation process.</div>';
        }

        String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">';
               html += '<h2 style="font-size: 12px; color: #004481; margin-bottom: 10px; font-weight: bold">Validation Process</h2>';

        for (DMT_Case_Steps_Controller.WRAPPER_Step feature : validationFeatures) {
            if (feature.featureType == 'passport' || feature.featureType == null) {

                // Si el nombre de la feature está vacío, usamos el título genérico
                String title = String.isNotBlank(feature.featureName) ? feature.featureName : 'Validation Process';

                html += '<div style="margin-bottom: 20px; page-break-inside: avoid; break-inside: avoid;">'
                    + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: center; border: 1px solid #ccc; page-break-inside: avoid; break-inside: avoid;">'

                    // Título de la tabla (Fondo Azul, texto blanco)
                    + '<tr>'
                    + '<td colspan="7" style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-align: left;">' + title + '</td>'
                    + '</tr>'

                    // Cabeceras (7 columnas, texto azul centrado)
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
        html += '</div>';
        return html;
    }

    private String renderGTBHtml(DMT_ViewController.LineDataWrapper data) {
            if (data == null || data.allsteps == null || data.allsteps.isEmpty()) {
                return '<div>Validation process not provided</div>';
            }

            List<DMT_Case_Steps_Controller.WRAPPER_Step> validationFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

            // Filtramos los steps para obtener solo los de passport (Validation)
            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : data.allsteps) {
                if (feature?.featureType == 'passport' || feature?.featureType == null) {
                    if (feature?.featureName != null) {
                        validationFeatures.add(feature);
                    } else if (feature?.subitems != null && !feature.subitems.isEmpty()) {
                        validationFeatures.add(feature.subitems[0]);
                    }
                }
            }

            if (validationFeatures.isEmpty()) {
                return '<div>There is no information about the validation process.</div>';
            }

            String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">';
                html += '<h2 style="font-size: 12px; color: #004481; margin-bottom: 10px; font-weight: bold">Validation Process</h2>';

            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : validationFeatures) {
                if (feature.featureType == 'passport' || feature.featureType == null) {

                    // Si el nombre de la feature está vacío, usamos el título genérico
                    String title = String.isNotBlank(feature.featureName) ? feature.featureName : 'Validation Process';

                    html += '<div style="margin-bottom: 20px; page-break-inside: avoid; break-inside: avoid;">'
                        + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: center; border: 1px solid #ccc; page-break-inside: avoid; break-inside: avoid;">'

                        // Título de la tabla (Fondo Azul, texto blanco)
                        + '<tr>'
                        + '<td colspan="7" style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-align: left;">' + title + '</td>'
                        + '</tr>'

                        // Cabeceras (7 columnas, texto azul centrado)
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
            html += '</div>';
            
            return html;
    }

    // ====================================================================================================
    // HELPER: Genera la fila de valores (7 columnas) + la fila de comentarios (1 columna que ocupa todo)
    // ====================================================================================================
    private String generateRows(DMT_Case_Steps_Controller.WRAPPER_Step item) {
        String approverValue = toBreakableHtml(DMT_FormattingUtils.checkNull(item.approver));
        String taskValue = toBreakableHtml(DMT_FormattingUtils.checkNull(item?.step?.urlLabel));

        // Nota: Agregamos font-weight: bold a las celdas de datos para que coincida exactamente con la captura proporcionada
        String row = '<tr>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle; text-align: left; white-space: normal; overflow-wrap: anywhere; word-break: break-word;">' + approverValue + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle; text-align: left; white-space: normal; overflow-wrap: anywhere; word-break: break-word;">' + taskValue + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle;">' + DMT_FormattingUtils.checkNull(item.status) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle;">' + DMT_FormattingUtils.checkNull(item.user) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle;">' + DMT_FormattingUtils.checkNull(item.startDate) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle;">' + DMT_FormattingUtils.checkNull(item.endDate) + '</td>'
                   + '<td style="padding: 6px; border-bottom: 1px solid #ccc; color: #000000; vertical-align: middle;">' + DMT_FormattingUtils.checkNull(item.result) + '</td>'
                   + '</tr>';
                   
        // Fila de comentarios abajo de todo ocupando las 7 columnas
        row += '<tr>'
             + '<td colspan="7" style="padding: 6px; background-color: #f2f2f2; text-align: left; border-bottom: 1px solid #ccc; color: #000000;">'
             + 'Comments: ' + DMT_FormattingUtils.checkNull(item.description)
             + '</td>'
             + '</tr>';
             
        return row;
    }

    private String toBreakableHtml(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        return value.replace('_', '_<br/>');
    }
}