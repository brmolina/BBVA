@isTest
private without sharing class DMT_BlobBuilderForPDF_Test {
    @IsTest
    static void testBuildPdfBlobWithSanitizedHtml() {
        String htmlWithEdgeCases =
            '<div>' +
            '<h2>LINE INFO</h2>' +
            '<table class="style-table">' +
            '<tr><td><strong>Customer ID:</strong></td><td>CO0013005563623</td></tr>' +
            '<tr><td><strong>Derivatives:</strong></td><td>24523523.00</td></tr>' +
            '<tr></tr>' +
            '</table>' +
            '&nbsp</br>' +
            '</div>';

        Test.startTest();
        Blob resultPdf = DMT_BlobBuilderForPDF.buildPdfBlob(htmlWithEdgeCases);
        Test.stopTest();

        System.assertNotEquals(null, resultPdf, 'The generated PDF blob must not be null.');
        System.assert(resultPdf.size() > 0, 'The generated PDF blob must contain data.');
    }

    @IsTest
    static void testFormatInvoiceDateKnownDate() {
        Date sampleDate = Date.newInstance(2026, 3, 16);

        String formatted = DMT_BlobBuilderForPDF.formatInvoiceDate(sampleDate);

        System.assertEquals('Monday, March 16, 2026', formatted, 'The date format must match expected output.');
    }

    @IsTest
    static void testGetInvoiceDateStrNotBlank() {
        String todayFormatted = DMT_BlobBuilderForPDF.getInvoiceDateStr();

        System.assertNotEquals(null, todayFormatted, 'Today formatted date must not be null.');
        System.assert(!String.isBlank(todayFormatted), 'Today formatted date must not be blank.');
        System.assert(todayFormatted.contains(String.valueOf(Date.today().year())), 'Formatted date should include current year.');
    }

    @IsTest
    static void testBuildPdfBlobForcedLegacyFallback() {
        String html = '<div><p>Legacy fallback path</p><style>.x{break-inside:avoid;}</style></div>';

        Test.startTest();
        DMT_BlobBuilderForPDF.forceLegacyFallbackForTest = true;
        DMT_BlobBuilderForPDF.forceUltraSafeFallbackForTest = false;
        Blob resultPdf = DMT_BlobBuilderForPDF.buildPdfBlob(html);
        Test.stopTest();

        DMT_BlobBuilderForPDF.forceLegacyFallbackForTest = false;
        DMT_BlobBuilderForPDF.forceUltraSafeFallbackForTest = false;

        System.assertNotEquals(null, resultPdf, 'Legacy fallback should return a PDF blob.');
        System.assert(resultPdf.size() > 0, 'Legacy fallback PDF blob should contain data.');
    }

    @IsTest
    static void testBuildPdfBlobForcedUltraSafeFallback() {
        String html = '<div><h2>Ultra Safe</h2><script>alert(1)</script><p>Text</p></div>';

        Test.startTest();
        DMT_BlobBuilderForPDF.forceLegacyFallbackForTest = true;
        DMT_BlobBuilderForPDF.forceUltraSafeFallbackForTest = true;
        Blob resultPdf = DMT_BlobBuilderForPDF.buildPdfBlob(html);
        Test.stopTest();

        DMT_BlobBuilderForPDF.forceLegacyFallbackForTest = false;
        DMT_BlobBuilderForPDF.forceUltraSafeFallbackForTest = false;

        System.assertNotEquals(null, resultPdf, 'Ultra-safe fallback should return a PDF blob.');
        System.assert(resultPdf.size() > 0, 'Ultra-safe fallback PDF blob should contain data.');
    }
}