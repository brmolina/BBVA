public with sharing class DMT_BlobBuilderForPDF {

    private static final String LOGO_SRC = '/resource/DMT_ET_BBVA';

    private static final List<String> DAY_NAMES = new List<String>{
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    };

    private static final List<String> MONTH_NAMES = new List<String>{
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
    };

    @TestVisible
    private static Boolean forceLegacyFallbackForTest = false;

    @TestVisible
    private static Boolean forceUltraSafeFallbackForTest = false;

    public static Blob buildPdfBlob(String htmlForPdf) {
        String invoiceDateStr = getInvoiceDateStr();
        String safeHtmlForPdf = sanitizeHtmlForPdf(htmlForPdf);

        Boolean tryLegacy = Test.isRunningTest() && forceLegacyFallbackForTest;

        if (!tryLegacy) {
            try {
                return Blob.toPdf(buildPdfHtmlDocument(invoiceDateStr, safeHtmlForPdf, true));
            } catch (System.InvalidParameterValueException ex) {
                tryLegacy = true;
            }
        }

        String legacySafeHtml = sanitizeHtmlForLegacyPdf(safeHtmlForPdf);
        Boolean tryUltraSafe = Test.isRunningTest() && forceUltraSafeFallbackForTest;

        if (!tryUltraSafe) {
            try {
                return Blob.toPdf(buildPdfHtmlDocument(invoiceDateStr, legacySafeHtml, false));
            } catch (System.InvalidParameterValueException ex2) {
                tryUltraSafe = true;
            }
        }

        String ultraSafeHtml = buildUltraSafePdfHtml(invoiceDateStr, legacySafeHtml);
        return Blob.toPdf(ultraSafeHtml);
    }

    private static String buildPdfHtmlDocument(String invoiceDateStr, String bodyHtml, Boolean modernCss) {
        List<String> parts = new List<String>{
            '<html xmlns="http://www.w3.org/1999/xhtml">\n',
            '<head>\n',
            '<title>PDF</title>\n',
            '<style type="text/css" media="print">\n',
            'body { font-family: "Helvetica", sans-serif; font-size: 12px; color: #333; margin: 0; padding: 0; }\n',
            'h1 { color: #004085; }\n',
            'strong { color: #000; }\n'
        };

        if (modernCss) {
            parts.add('@page { size: A4 portrait; margin-top: 0.50cm; margin-bottom: 1cm; margin-left: 1cm; margin-right: 1cm; @bottom-right { content: "Page " counter(page) " of " counter(pages); font-size: 11px; color: #2b2a2a; padding-top: 10px; } }\n');
            parts.add('.page-break { display: block; page-break-before: always; break-before: page; }\n');
            parts.add('.page-break-after { display: block; page-break-after: always; break-after: page; }\n');
            parts.add('.avoid-break { page-break-inside: avoid; break-inside: avoid; }\n');
            parts.add('.style-table td { padding: 3px; overflow-wrap: anywhere; word-break: break-word; }\n');
        } else {
            parts.add('@page { size: A4 portrait; margin-top: 0.50cm; margin-bottom: 1cm; margin-left: 1cm; margin-right: 1cm; }\n');
            parts.add('.page-break { display: block; page-break-before: always; }\n');
            parts.add('.page-break-after { display: block; page-break-after: always; }\n');
            parts.add('.avoid-break { page-break-inside: avoid; }\n');
            parts.add('.style-table td { padding: 3px; word-wrap: break-word; word-break: break-word; }\n');
       }

        parts.addAll(new List<String>{
            '#header-container { width: 100%; margin-bottom: 5px; padding: 2px 0;}\n',
            '.layout-table { width: 100%; border-collapse: collapse; border: none; }\n',
            '.layout-table td { vertical-align: middle; border: none; padding: 3px 6px; }\n',
            '.data-table { width: 100%; border-collapse: collapse; margin-top: 15px; }\n',
            '.data-table th, .data-table td { text-align: left; padding: 4px; border-bottom: 1px solid #ddd; }\n',
            '.data-table th { background-color: rgb(214, 214, 214); color: #004085; font-weight: bold; }\n',
            '.logo-img { width: 95px; height: auto;}\n',
            '.header-date { text-align: right; color: #666; font-style: italic; font-size: 10px; padding-bottom: 0; white-space: nowrap; }\n',
            '.style-table { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 10px; }\n',
            '</style>\n',
            '</head>\n',
            '<body>\n',
            '<div id="header-container">\n',
            '  <table class="layout-table">\n',
            '    <tr>\n',
            '      <td style="width: 40%;">\n',
            '        <img src="', LOGO_SRC, '" alt="BBVA Logo" class="logo-img" />\n',
            '      </td>\n',
            '      <td style="width: 60%;" class="header-date">\n', invoiceDateStr, '\n',
            '      </td>\n',
            '    </tr>\n',
            '  </table>\n',
            '</div>\n',
            bodyHtml,
            '</body>\n',
            '</html>'
        });

        return String.join(parts, '');
    }

    public static String getInvoiceDateStr() {
        return formatInvoiceDate(Date.today());
    }

    private static String sanitizeHtmlForPdf(String inputHtml) {
        if (String.isBlank(inputHtml)) {
            return '';
        }

        return inputHtml
            .replace('&nbsp;', '&#160;')
            .replace('&nbsp', '&#160;')
            .replace('</br>', '<br/>')
            .replace('<br>', '<br/>')
            .replace('<br />', '<br/>')
            .replace('<tr></tr>', '');
    }

    private static String sanitizeHtmlForLegacyPdf(String inputHtml) {
        if (String.isBlank(inputHtml)) {
            return '';
        }

        String cleaned = inputHtml;
        cleaned = cleaned.replaceAll('(?is)<style[^>]*>.*?</style>', '');
        cleaned = cleaned.replaceAll('(?i)break-inside\\s*:\\s*avoid\\s*;?', '');
        cleaned = cleaned.replaceAll('(?i)break-before\\s*:\\s*page\\s*;?', '');
        cleaned = cleaned.replaceAll('(?i)break-after\\s*:\\s*page\\s*;?', '');
        cleaned = cleaned.replaceAll('(?i)overflow-wrap\\s*:\\s*anywhere\\s*;?', 'word-wrap:break-word;');
        return sanitizeHtmlForPdf(cleaned);
    }

    private static String buildUltraSafePdfHtml(String invoiceDateStr, String htmlContent) {
        String plainText = toPlainText(htmlContent);
        return '<html><body style="font-family:Helvetica,Arial,sans-serif;font-size:11px;color:#333;">'
            + '<div style="margin-bottom:8px;"><strong>BBVA</strong></div>'
            + '<div style="margin-bottom:12px;">' + invoiceDateStr + '</div>'
            + '<pre style="white-space:pre-wrap;word-wrap:break-word;">' + plainText + '</pre>'
            + '</body></html>';
    }

    private static String toPlainText(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            return '';
        }

        String text = htmlContent;
        text = text.replaceAll('(?is)<script[^>]*>.*?</script>', ' ');
        text = text.replaceAll('(?is)<style[^>]*>.*?</style>', ' ');
        text = text.replaceAll('(?i)<br\\s*/?>', '\n');
        text = text.replaceAll('(?i)</p>', '\n');
        text = text.replaceAll('(?i)</div>', '\n');
        text = text.replaceAll('(?i)</tr>', '\n');
        text = text.replaceAll('(?i)</td>', ' ');
        text = text.replaceAll('(?i)</th>', ' ');
        text = text.replaceAll('(?is)<[^>]+>', ' ');
        text = text.replace('&nbsp;', ' ').replace('&#160;', ' ');
        text = text.replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&').replace('&quot;', '"').replace('&#39;', '\'');
        text = text.replaceAll('[\\t\\x0B\\f\\r]+', ' ');
        text = text.replaceAll('\\n{3,}', '\n\n');
        text = text.replaceAll('[ ]{2,}', ' ');
        return text.trim();
    }

    public static String formatInvoiceDate(Date inputDate) {
        Date effectiveDate = inputDate == null ? Date.today() : inputDate;

        Integer dayOfWeekIso = Integer.valueOf(
            Datetime.newInstance(effectiveDate, Time.newInstance(12, 0, 0, 0)).format('u', 'GMT')
        );

        return DAY_NAMES[dayOfWeekIso - 1] + ', ' +
               MONTH_NAMES[effectiveDate.month() - 1] + ' ' +
               effectiveDate.day() + ', ' +
               effectiveDate.year();
    }
}