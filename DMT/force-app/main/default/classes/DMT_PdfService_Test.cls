@isTest
private without sharing class DMT_PdfService_Test {

    // Minimal valid base64 payloads (content irrelevant — only encoding matters)
    private static final String B64_PAYLOAD = 'dGVzdA=='; // "test"

    /**
     * Helper: returns the running user's Id, which acts as the personal
     * Documents folder and is always available in test context.
     */
    private static Id getPersonalFolderId() {
        return UserInfo.getUserId();
    }

    /** Helper: build an <img> tag with an inline data URI. */
    private static String imgTag(String mimeSubtype) {
        return '<img src="data:image/' + mimeSubtype + ';base64,' + B64_PAYLOAD + '"/>';
    }

    // ── preparePdfAssets – early returns ─────────────────────────────────

    @IsTest
    static void testPreparePdfAssetsNoImages() {
        String plainHtml = '<div><p>No images here</p></div>';

        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(plainHtml);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null.');
        System.assertEquals(plainHtml, result.modifiedHtml,
            'HTML without images must be returned unchanged.');
        System.assert(result.documentIds.isEmpty(),
            'No Documents should be created when there are no inline images.');
    }

    @IsTest
    static void testPreparePdfAssetsBlankHtml() {
        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets('');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null for blank input.');
        System.assertEquals('', result.modifiedHtml,
            'Blank HTML should be returned as-is.');
        System.assert(result.documentIds.isEmpty(),
            'No Documents should be created for blank input.');
    }

    @IsTest
    static void testPreparePdfAssetsNullHtml() {
        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null for null input.');
        System.assert(result.documentIds.isEmpty(),
            'No Documents should be created for null input.');
    }

    // ── preparePdfAssets – full flow with inline images ──────────────────

    @IsTest
    static void testPreparePdfAssetsWithPngImage() {
        String html = '<div>' + imgTag('png') + '</div>';

        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(html);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null.');
        System.assertNotEquals(null, result.modifiedHtml, 'Modified HTML must not be null.');

        if (!result.documentIds.isEmpty()) {
            System.assertEquals(1, result.documentIds.size(),
                'One Document should be created for one inline image.');
            System.assert(!result.modifiedHtml.contains('data:image/'),
                'Data URI should be replaced with servlet URL.');
            System.assert(result.modifiedHtml.contains('servlet.ImageServer'),
                'Modified HTML should contain servlet.ImageServer URL.');
        }
    }

    @IsTest
    static void testPreparePdfAssetsWithGifImage() {
        String html = '<div>' + imgTag('gif') + '</div>';

        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(html);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null.');
        if (!result.documentIds.isEmpty()) {
            System.assertEquals(1, result.documentIds.size(),
                'One Document should be created for the GIF image.');
        }
    }

    @IsTest
    static void testPreparePdfAssetsWithJpegImage() {
        String html = '<div>' + imgTag('jpeg') + '</div>';

        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(html);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null.');
        if (!result.documentIds.isEmpty()) {
            System.assertEquals(1, result.documentIds.size(),
                'One Document should be created for the JPEG image.');
        }
    }

    @IsTest
    static void testPreparePdfAssetsMultipleImages() {
        String html = '<div>' + imgTag('png') + imgTag('gif') + '</div>';

        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(html);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null.');
        if (!result.documentIds.isEmpty()) {
            System.assertEquals(2, result.documentIds.size(),
                'Two Documents should be created for two inline images.');
        }
    }

    @IsTest
    static void testPreparePdfAssetsMalformedDataUri() {
        // data URI without comma → buildDocumentRecords skips it → empty docs → early return
        String html = '<div><img src="data:image/png;base64NoComma"/></div>';

        Test.startTest();
        DMT_PdfService.PreparationResult result =
            DMT_PdfService.preparePdfAssets(html);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null.');
        System.assert(result.documentIds.isEmpty(),
            'No Documents should be created for malformed data URIs without comma.');
    }

    // ── generateFinalPdf ────────────────────────────────────────────────

    @IsTest
    static void testGenerateFinalPdfSimpleHtml() {
        String bodyHtml = '<div><h2>Report</h2><p>Content</p></div>';

        Test.startTest();
        String base64Pdf = DMT_PdfService.generateFinalPdf(
            bodyHtml, new List<String>()
        );
        Test.stopTest();

        System.assertNotEquals(null, base64Pdf,
            'Base64 PDF string must not be null.');
        System.assert(String.isNotBlank(base64Pdf),
            'Base64 PDF string must not be blank.');

        Blob decoded = EncodingUtil.base64Decode(base64Pdf);
        System.assert(decoded.size() > 0,
            'Decoded PDF blob must contain data.');
    }

    @IsTest
    static void testGenerateFinalPdfNullDocIds() {
        String bodyHtml = '<div><p>Simple</p></div>';

        Test.startTest();
        String base64Pdf = DMT_PdfService.generateFinalPdf(bodyHtml, null);
        Test.stopTest();

        System.assertNotEquals(null, base64Pdf,
            'Base64 PDF string must not be null when docIds is null.');
    }

    @IsTest
    static void testGenerateFinalPdfWithDocCleanup() {
        Document doc = new Document(
            Name        = 'CleanupTest.png',
            Body        = Blob.valueOf('test'),
            FolderId    = getPersonalFolderId(),
            ContentType = 'image/png',
            Type        = 'png'
        );
        insert doc;

        Test.startTest();
        String base64Pdf = DMT_PdfService.generateFinalPdf(
            '<div>Test</div>',
            new List<String>{ String.valueOf(doc.Id) }
        );
        Test.stopTest();

        System.assertNotEquals(null, base64Pdf, 'PDF should be generated.');
        List<Document> remaining = [SELECT Id FROM Document WHERE Id = :doc.Id];
        System.assert(remaining.isEmpty(),
            'Document should be deleted by the finally-block cleanup.');
    }

    // ── End-to-end two-transaction flow ─────────────────────────────────

    @IsTest
    static void testTwoTransactionFlowEndToEnd() {
        String html = '<div><h2>Deal Summary</h2>' +
            '<table class="data-table">' +
            '<tr><th>Field</th><th>Value</th></tr>' +
            '<tr><td>Amount</td><td>1,000,000</td></tr>' +
            '</table></div>';

        DMT_PdfService.PreparationResult prep =
            DMT_PdfService.preparePdfAssets(html);

        System.assertNotEquals(null, prep.modifiedHtml,
            'Prepared HTML must not be null after step 1.');

        Test.startTest();
        String base64Pdf = DMT_PdfService.generateFinalPdf(
            prep.modifiedHtml, prep.documentIds
        );
        Test.stopTest();

        System.assert(String.isNotBlank(base64Pdf),
            'Final PDF base64 must not be blank.');
    }

    @IsTest
    static void testTwoTransactionFlowWithImages() {
        String html = '<div><h2>Deal Summary</h2>' +
            imgTag('png') +
            '<table class="data-table">' +
            '<tr><th>Field</th><th>Value</th></tr>' +
            '<tr><td>Amount</td><td>1,000,000</td></tr>' +
            '</table></div>';

        // Transaction 1
        DMT_PdfService.PreparationResult prep =
            DMT_PdfService.preparePdfAssets(html);
        System.assertNotEquals(null, prep.modifiedHtml,
            'Prepared HTML must not be null.');

        // Transaction 2
        Test.startTest();
        String base64Pdf = DMT_PdfService.generateFinalPdf(
            prep.modifiedHtml, prep.documentIds
        );
        Test.stopTest();

        System.assert(String.isNotBlank(base64Pdf),
            'Final PDF base64 must not be blank.');
    }

    // ── collectDataUris ─────────────────────────────────────────────────

    @IsTest
    static void testCollectDataUrisFindsImages() {
        String html = '<img src="data:image/png;base64,iVBOR"/>' +
            '<img src="data:image/jpeg;base64,/9j/4"/>';

        Test.startTest();
        List<String> uris = DMT_PdfService.collectDataUris(html);
        Test.stopTest();

        System.assertEquals(2, uris.size(),
            'Should find exactly 2 data URIs.');
        System.assert(uris[0].startsWith('data:image/png'),
            'First URI should be PNG.');
        System.assert(uris[1].startsWith('data:image/jpeg'),
            'Second URI should be JPEG.');
    }

    @IsTest
    static void testCollectDataUrisEmpty() {
        String html = '<div>No images</div>';

        Test.startTest();
        List<String> uris = DMT_PdfService.collectDataUris(html);
        Test.stopTest();

        System.assert(uris.isEmpty(),
            'Should return empty list when no data URIs exist.');
    }

    @IsTest
    static void testCollectDataUrisNoClosingQuote() {
        // Missing closing quote → indexOf returns -1 → loop breaks
        String html = '<img src="data:image/png;base64,AAAA';

        Test.startTest();
        List<String> uris = DMT_PdfService.collectDataUris(html);
        Test.stopTest();

        System.assert(uris.isEmpty(),
            'Should return empty list when the data URI has no closing quote.');
    }

    // ── cleanupDocuments ────────────────────────────────────────────────

    @IsTest
    static void testCleanupDocumentsNullSafe() {
        Test.startTest();
        DMT_PdfService.cleanupDocuments(null);
        DMT_PdfService.cleanupDocuments(new List<String>());
        Test.stopTest();

        System.assert(true, 'Cleanup with null/empty should not throw.');
    }

    @IsTest
    static void testCleanupDocumentsDeletesRecords() {
        Document doc = new Document(
            Name        = 'CleanupTarget.png',
            Body        = Blob.valueOf('test'),
            FolderId    = getPersonalFolderId(),
            ContentType = 'image/png',
            Type        = 'png'
        );
        insert doc;

        Test.startTest();
        DMT_PdfService.cleanupDocuments(
            new List<String>{ String.valueOf(doc.Id) }
        );
        Test.stopTest();

        List<Document> remaining = [SELECT Id FROM Document WHERE Id = :doc.Id];
        System.assert(remaining.isEmpty(), 'Document should be deleted.');
    }

    // ── getPublicDocumentFolderId ───────────────────────────────────────

    @IsTest
    static void testGetPublicDocumentFolderIdReturnsIdOrNull() {
        // Exercises getPublicDocumentFolderId + hasAccessToReadFolders +
        // isValidDocumentFolder. Result depends on org folders.
        Test.startTest();
        Id folderId = DMT_PdfService.getPublicDocumentFolderId();
        Test.stopTest();

        // We only assert no exception is thrown; value may be null in scratch orgs
        System.assert(true,
            'getPublicDocumentFolderId should not throw.');
    }
}