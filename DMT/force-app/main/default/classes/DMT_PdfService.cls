/**
 * DMT_PdfService — Orchestrates server-side PDF generation in TWO separate
 * @AuraEnabled transactions so that inline base64 images are resolvable
 * by the Blob.toPdf() rendering engine.
 */
public with sharing class DMT_PdfService {

    // ── Public wrapper returned by preparePdfAssets ──────────────────────────

    public class PreparationResult {
        @AuraEnabled public String modifiedHtml;
        @AuraEnabled public List<String> documentIds;

        public PreparationResult() {
            this.documentIds = new List<String>();
        }
    }

    // ── Constants ────────────────────────────────────────────────────────────

    private static final String DATA_IMAGE_MARKER = 'src="data:image/';
    private static final String PAGE_BREAK_BORDER_STYLE = 'border-top: 2px dashed #004481;';

    // ── Transaction 1: Create temporary Document images ─────────────────────

    @AuraEnabled
    public static PreparationResult preparePdfAssets(String originalHtml) {
        PreparationResult result = new PreparationResult();

        if (String.isBlank(originalHtml) || !originalHtml.contains('data:image/')) {
            result.modifiedHtml = originalHtml;
            return result;
        }

        if (!hasAccessToCreateDocuments()) {
            result.modifiedHtml = originalHtml;
            return result;
        }

        Id folderId = getPublicDocumentFolderId();
        if (folderId == null) {
            result.modifiedHtml = originalHtml;
            return result;
        }

        List<String> dataUris = collectDataUris(originalHtml);
        if (dataUris.isEmpty()) {
            result.modifiedHtml = originalHtml;
            return result;
        }

        List<Document> docsToInsert = buildDocumentRecords(dataUris, folderId);
        if (docsToInsert.isEmpty()) {
            result.modifiedHtml = originalHtml;
            return result;
        }

        Database.insert(docsToInsert, AccessLevel.SYSTEM_MODE);

        String orgId15 = toSafe15(UserInfo.getOrganizationId());
        String html = originalHtml;

        for (Integer i = 0; i < docsToInsert.size(); i++) {
            String docId15 = toSafe15(docsToInsert[i].Id);
            String url = '/servlet/servlet.ImageServer?id=' + docId15 + '&amp;oid=' + orgId15;
            html = html.replace(dataUris[i], url);
            result.documentIds.add(String.valueOf(docsToInsert[i].Id));
        }

        result.modifiedHtml = html;
        return result;
    }

    // ── Transaction 2: Generate PDF and clean up ────────────────────────────

    @AuraEnabled
    public static String generateFinalPdf(String finalHtml, List<String> docIds, Boolean isMobile) {
        try {
            String cleanPageBreakHtml = cleanPageBreakBorders(finalHtml);
            Blob pdfBlob = DMT_BlobBuilderForPDF.buildPdfBlob(cleanPageBreakHtml);

            if (isMobile != null && isMobile) {
                // 1. Limpiar PDFs temporales antiguos (>30 min) para no acumular basura
                purgeOldTempDocuments();

                // 2. Crear ContentVersion efímero
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Temp_DMT_PDF_' + System.currentTimeMillis();
                cv.PathOnClient = 'DMT_ViewPDF.pdf';
                cv.VersionData = pdfBlob;
                cv.IsMajorVersion = true;
                
                Database.insert(cv, AccessLevel.SYSTEM_MODE);

                cv = [
                    SELECT Id, ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :cv.Id 
                    WITH SYSTEM_MODE 
                    LIMIT 1
                ];

                // Devuelve el ContentDocumentId para la visualización/descarga móvil
                return cv.ContentDocumentId;
            }

            return EncodingUtil.base64Encode(pdfBlob);
        } finally {
            cleanupDocuments(docIds);
        }
    }

    // Limpia archivos temporales creados hace más de 30 minutos
    private static void purgeOldTempDocuments() {
        try {
            Datetime threshold = Datetime.now().addMinutes(-30);
            List<ContentDocument> oldTempDocs = [
                SELECT Id 
                FROM ContentDocument 
                WHERE Title LIKE 'Temp_DMT_PDF_%' 
                AND CreatedDate < :threshold 
                WITH SYSTEM_MODE 
                LIMIT 50
            ];
            if (!oldTempDocs.isEmpty()) {
                Database.delete(oldTempDocs, false, AccessLevel.SYSTEM_MODE);
            }
        } catch (Exception e) {
            System.debug('Error purging old temp docs: ' + e.getMessage());
        }
    }

    // ── Data URI extraction ─────────────────────────────────────────────────

    @TestVisible
    private static List<String> collectDataUris(String html) {
        List<String> uris = new List<String>();
        String remaining = html;

        while (remaining.contains(DATA_IMAGE_MARKER)) {
            Integer srcIdx = remaining.indexOf(DATA_IMAGE_MARKER);
            Integer uriStart = srcIdx + 5;
            Integer uriEnd = remaining.indexOf('"', uriStart);
            if (uriEnd == -1) {
                break;
            }
            uris.add(remaining.substring(uriStart, uriEnd));
            remaining = remaining.substring(uriEnd + 1);
        }
        return uris;
    }

    // ── Document building ───────────────────────────────────────────────────

    private static List<Document> buildDocumentRecords(List<String> dataUris, Id folderId) {
        List<Document> docs = new List<Document>();

        for (Integer i = 0; i < dataUris.size(); i++) {
            String dataUri = dataUris[i];
            Integer commaIdx = dataUri.indexOf(',');
            if (commaIdx == -1) {
                continue;
            }

            String base64Body = dataUri.substring(commaIdx + 1);
            String header = dataUri.substring(0, commaIdx).toLowerCase();
            String[] typeInfo = resolveImageType(header);

            Document doc = new Document();
            doc.Name = 'TempChart_' + Datetime.now().getTime() + '_' + i + '.' + typeInfo[1];
            doc.Body = EncodingUtil.base64Decode(base64Body);
            doc.FolderId = folderId;
            doc.IsPublic = true;
            doc.ContentType = typeInfo[0];
            doc.Type = typeInfo[1];
            docs.add(doc);
        }

        return docs;
    }

    private static String[] resolveImageType(String header) {
        if (header.contains('image/png')) {
            return new String[]{ 'image/png', 'png' };
        }
        if (header.contains('image/gif')) {
            return new String[]{ 'image/gif', 'gif' };
        }
        return new String[]{ 'image/jpeg', 'jpg' };
    }

    // ── Folder lookup ───────────────────────────────────────────────────────

    @TestVisible
    private static Id getPublicDocumentFolderId() {
        if (!hasAccessToReadFolders()) {
            return null;
        }

        List<Folder> folders = [
            SELECT Id, DeveloperName
            FROM Folder
            WHERE Type = 'Document'
            AND AccessType IN ('Public', 'Public Read Only')
            ORDER BY LastModifiedDate DESC
            LIMIT 25
        ];

        for (Folder f : folders) {
            if (isValidDocumentFolder(f)) {
                return f.Id;
            }
        }

        return null;
    }

    private static Boolean isValidDocumentFolder(Folder f) {
        return f != null
            && f.Id != null
            && String.valueOf(f.Id).startsWith('00l')
            && String.isNotBlank(f.DeveloperName);
    }

    // ── Cleanup ─────────────────────────────────────────────────────────────

    @TestVisible
    private static String cleanPageBreakBorders(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            return htmlContent;
        }
        return htmlContent.replace(
            '<div data-dmt="page-break" style="' + PAGE_BREAK_BORDER_STYLE,
            '<div data-dmt="page-break" style="'
        );
    }

    @TestVisible
    private static void cleanupDocuments(List<String> docIdStrings) {
        if (docIdStrings == null || docIdStrings.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Document.isDeletable()) {
            return;
        }

        List<Document> toDelete = new List<Document>();
        for (String idStr : docIdStrings) {
            toDelete.add(new Document(Id = Id.valueOf(idStr)));
        }

        Database.delete(toDelete, false, AccessLevel.SYSTEM_MODE);
    }

    // ── Security checks ─────────────────────────────────────────────────────

    private static Boolean hasAccessToCreateDocuments() {
        return Schema.sObjectType.Document.isCreateable()
            && Schema.sObjectType.Document.fields.Name.isCreateable()
            && Schema.sObjectType.Document.fields.FolderId.isCreateable()
            && Schema.sObjectType.Document.fields.IsPublic.isCreateable()
            && Schema.sObjectType.Document.fields.Body.isCreateable()
            && Schema.sObjectType.Document.fields.ContentType.isCreateable()
            && Schema.sObjectType.Document.fields.Type.isCreateable();
    }

    private static Boolean hasAccessToReadFolders() {
        return Schema.sObjectType.Folder.isAccessible()
            && Schema.sObjectType.Folder.fields.Id.isAccessible()
            && Schema.sObjectType.Folder.fields.DeveloperName.isAccessible()
            && Schema.sObjectType.Folder.fields.Type.isAccessible()
            && Schema.sObjectType.Folder.fields.AccessType.isAccessible();
    }

    // ── Utilities ───────────────────────────────────────────────────────────

    private static String toSafe15(Object salesforceId) {
        String idVal = String.valueOf(salesforceId);
        return (idVal != null && idVal.length() >= 15) ? idVal.substring(0, 15) : idVal;
    }
}