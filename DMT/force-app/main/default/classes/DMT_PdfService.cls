/**
 * DMT_PdfService — Orchestrates server-side PDF generation in TWO separate
 * @AuraEnabled transactions so that inline base64 images are resolvable
 * by the Blob.toPdf() rendering engine.
 *
 * FLOW (called from LWC):
 *   Transaction 1 → preparePdfAssets():  Extracts data:image URIs from the HTML,
 *                   persists them as public Document records, and replaces the
 *                   data URIs with servlet.ImageServer URLs.
 *   --- LWC awaits, Salesforce commits Transaction 1 ---
 *   Transaction 2 → generateFinalPdf():  Calls DMT_BlobBuilderForPDF.buildPdfBlob()
 *                   with the prepared HTML (images are now committed & accessible),
 *                   cleans up temporary Documents, and returns the PDF as base64.
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

    // ── Transaction 1: Create temporary Document images ─────────────────────

    /**
     * Extracts every inline base64 image from the supplied HTML, persists each
     * one as a temporary Document in a public folder, and replaces the data
     * URIs with servlet.ImageServer URLs.
     *
     * The caller (LWC) MUST await this call before invoking generateFinalPdf()
     * so that the Documents are committed and visible to the PDF engine.
     *
     * @param  originalHtml  Raw HTML that may contain data:image/…;base64,… src attributes.
     * @return PreparationResult with the rewritten HTML and temporary Document Ids.
     */
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

    /**
     * Generates the final PDF from the prepared HTML (images already committed)
     * and cleans up the temporary Document records.
     *
     * @param  finalHtml  HTML with servlet.ImageServer URLs (output of preparePdfAssets).
     * @param  docIds     Temporary Document Ids to delete after PDF generation.
     * @return The PDF encoded as a base64 string.
     */
    @AuraEnabled
    public static String generateFinalPdf(String finalHtml, List<String> docIds) {
        try {
            Blob pdfBlob = DMT_BlobBuilderForPDF.buildPdfBlob(finalHtml);
            return EncodingUtil.base64Encode(pdfBlob);
        } finally {
            cleanupDocuments(docIds);
        }
    }

    // ── Data URI extraction ─────────────────────────────────────────────────

    @TestVisible
    private static List<String> collectDataUris(String html) {
        List<String> uris = new List<String>();
        String remaining = html;

        while (remaining.contains(DATA_IMAGE_MARKER)) {
            Integer srcIdx = remaining.indexOf(DATA_IMAGE_MARKER);
            Integer uriStart = srcIdx + 5; // right after src="
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