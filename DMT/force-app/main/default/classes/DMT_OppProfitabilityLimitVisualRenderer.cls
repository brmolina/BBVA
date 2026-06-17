public with sharing class DMT_OppProfitabilityLimitVisualRenderer implements DMT_ViewRenderer {
    /**
     * Renders HTML for the Opportunity Profitability feature.
     * @param data The LineDataWrapper containing featuresList.
     * @return HTML string for rendering in the UI.
     */
    @TestVisible
    private class TestException extends Exception {}

    public static String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return '<div>Features data not provided.</div>';
        }

        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() || data.opportunity.OpportunityLineItems.isEmpty()) {
            return '<div>Opportunity or OpportunityLineItems data not provided.</div>';
        }

        Map<String, Object> feature = getProfitabilityFeature(data.featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return '<div>Profitability data not provided.</div>';
        }

        Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
        List<Object> results = (List<Object>) profitability.get('results');
        Map<String, Object> audit = profitability.containsKey('audit') && profitability.get('audit') != null
            ? (Map<String, Object>) profitability.get('audit')
            : new Map<String, Object>();

        if (results == null || results.isEmpty()) {
            return '<div class="error-message">no Profitability results found.</div>';
        }

        if (Test.isRunningTest() && data.forceException) {
            throw new AuraHandledException('Forced exception for test');
        }

        try {
            String html = '';
            Boolean hasProfitabilityVisual = false;

            /*
            html += '<div style="margin-top: 24px;">'
                + '<img alt="profitability" src="' + data.itemImgBase64[0].imgB64 + '" style="width:100%;height:100%;object-fit:contain;"/>'
                + '</div>';
            */

            if (data.isImg64 && !data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 7) {
                html += '<div>'
                    + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Profitability Visual</h2>'
                    + '<div class="slds-scope">';

                Integer j = data.itemImgBase64.size() <= 3 ? 0 : -1;
                if (j >= 0 && j < data.itemImgBase64.size()) {
                    String raw = normalizeImageBase64(data.itemImgBase64[j]?.imgB64);
                    String dataUri = toImageDataUri(raw);

                    if (String.isNotBlank(dataUri)) {
                        html += '<div style="margin-top: 24px;">'
                            + '<img alt="profitability" src="' + DMT_FormattingUtils.checkNull(dataUri) + '" style="width:100%;height:100%;object-fit:contain;"/>'
                            + '</div>';
                        hasProfitabilityVisual = true;
                    }
                }

                html += '</div></div>';
            } else if (!hasProfitabilityVisual) {
                DMT_ProfitabilityChartGenerator.ChartRequest profitabilityChartRequest =
                    DMT_ProfitabilityChartGenerator.buildChartRequest(profitability);

                String profitabilityChartHtml = DMT_ProfitabilityChartGenerator.getMixedChartHtml(profitabilityChartRequest);

                if (String.isNotBlank(profitabilityChartHtml)) {
                    html += '<div style="margin-top:24px; page-break-before:always; break-before:page; page-break-inside:avoid; break-inside:avoid;">'
                        + profitabilityChartHtml
                        + '</div>';
                }
            } else {
                return '<div class="error-message">Profitability visual not available.</div>';
            }

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppProfitabilityLimitVisualRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    /**
     * Generates PDF JSON for the Opportunity Profitability feature.
     * @param data The LineDataWrapper containing featuresList.
     * @return PDF JSON string.
     */
    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        Map<String, Object> componentLimitDetailVisual = new Map<String, Object>();

        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return componentLimitDetailVisual;
        }

        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() || data.opportunity.OpportunityLineItems.isEmpty()) {
            return componentLimitDetailVisual;
        }

        Map<String, Object> feature = getProfitabilityFeature(data.featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return componentLimitDetailVisual;
        }

        Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
        List<Object> results = (List<Object>) profitability.get('results');
        Map<String, Object> audit = profitability.containsKey('audit') && profitability.get('audit') != null
            ? (Map<String, Object>) profitability.get('audit')
            : new Map<String, Object>();

        if (results == null || results.isEmpty()) {
            return componentLimitDetailVisual;
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new TestException('Forced exception for test');
            }

            List<Object> contentListLimitDetailVisual = new List<Object>();

            // Main Title: Profitability Visual
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 0
            };
            contentListLimitDetailVisual.add(pageBreak);
            contentListLimitDetailVisual.add(DMT_Create_Pdf_Controller.createTitle('Profitability Visual'));

            // --- 1. IMAGE ---
            if (data.isImg64 && !data.itemImgBase64.isEmpty()) {
                Map<String, Object> img = new Map<String, Object>{
                    'type' => 'image',
                    'src' => data.itemImgBase64[0]?.imgB64,
                    'width' => 170,
                    'aspectRatio' => 0.40,
                    'format' => 'JPEG',
                    'margin' => new Map<String, Object>{
                        'top' => 5,
                        'bottom' => 5,
                        'left' => 5,
                        'right' => 5
                    }
                };

                contentListLimitDetailVisual.add(img);
            }

            componentLimitDetailVisual.put('content', contentListLimitDetailVisual);
            return componentLimitDetailVisual;
        } catch (Exception e) {
            System.debug('Error in DMT_OppProfitabilityLimitVisualRenderer renderPdfJson: ' + e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(
                new DMT_LogExceptionPayload(
                    e.getMessage(),
                    e.getStackTraceString(),
                    e.getLineNumber(),
                    e.getTypeName(),
                    'DMT_OppProfitabilityLimitVisualRenderer',
                    'renderPdfJson',
                    'DMT',
                    ''
                )
            );
            return componentLimitDetailVisual;
        }
    }

    private static String normalizeImageBase64(String raw) {
        if (raw == null) {
            return null;
        }

        return raw.replaceAll('\\s+', '');
    }

    private static String toImageDataUri(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }

        String cleaned = raw.trim();
        if (cleaned.toLowerCase().startsWith('data:')) {
            return cleaned;
        }

        String lower = cleaned.toLowerCase();
        String mime = 'image/jpeg';

        if (lower.startsWith('ivborw0kggo')) {
            mime = 'image/png';
        } else if (lower.startsWith('r0lgod')) {
            mime = 'image/gif';
        }

        return 'data:' + mime + ';base64,' + cleaned;
    }

    // Helper to extract the profitability feature from featuresList
    private static Map<String, Object> getProfitabilityFeature(List<Object> featuresList) {
        for (Object obj : featuresList) {
            Map<String, Object> feature = (Map<String, Object>) obj;
            if (feature != null && feature.containsKey('profitability')) {
                return feature;
            }
        }

        return new Map<String, Object>();
    }
}