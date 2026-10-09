/**
 * @description Lightweight LWC Controller to bridge frontend components with the DES_CoreDocuments framework.
 */
public with sharing class DMT_CoreDocuments_Controller {
    
    private static final String CONFIG_NAME = 'DMT';

    @AuraEnabled
    public static DES_CoreDocumentsExpedientFolders.Wrapper getDocuments(String folderCode) {
        DES_CoreDocumentsExpedientFolders.Wrapper expedientFolders = new DES_CoreDocumentsExpedientFolders.Wrapper();
        try {
            Map<String, Object> request = new Map<String, Object>();
            request.put('qExpression', 'businessCode.folderCode==*' + folderCode + '*');
            request.put('timestamp', String.valueOf(DateTime.now().getTime()));
            request.put('page', '1');
            request.put('pageSize', '100');
            expedientFolders = DES_CoreDocumentsExpedientFolders.getExpedientFolders(request, CONFIG_NAME);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return expedientFolders;
    }

    @AuraEnabled
    public static Map<String, Object> getUploadConfig() {
        try {
            Map<String, Object> config = new Map<String, Object>();
            config.put('endpoint', DES_CoreDocuments.getUploadUrl(CONFIG_NAME));
            config.put('headers', DES_CoreDocuments.getUploadHeaders(CONFIG_NAME));
            return config;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating upload config: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateFileMetadata(String fileId, String fileName, String docType, String folderId) {
        updateFileMetadataWithObjectCode(fileId, fileName, docType, folderId, docType);
    }

    @AuraEnabled
    public static void updateFileMetadataWithObjectCode(String fileId, String fileName, String docType, String folderId, String objectCode) {
        try {
            System.debug('*** updateFileMetadataWithObjectCode called with fileId: ' + fileId + ', fileName: ' + fileName + ', docType: ' + docType + ', folderId: ' + folderId + ', objectCode: ' + objectCode);
            DES_CoreDocuments.UpdateFileMetadataRequest req = new DES_CoreDocuments.UpdateFileMetadataRequest();
            req.fileId = fileId;
            req.fileName = fileName;
            req.docType = docType;
            req.folderId = folderId;
            req.configName = CONFIG_NAME;
            req.objectCode = objectCode;
            DES_CoreDocuments.updateFileMetadata(req);
        } catch (Exception e) {
            System.debug('*** Error in updateFileMetadata: ' + e.getMessage());
            System.debug('stack trace: ' + e.getStackTraceString());
            System.debug('line number: ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getDownloadEndpoint(String contentLocator) {
        try {
            return DES_CoreDocuments.getDownloadUrl(CONFIG_NAME, contentLocator);
        } catch (Exception e) {
            throw new AuraHandledException('Error getting download endpoint: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getDownloadHeaders() {
        try {
            return DES_CoreDocuments.getDownloadHeaders(CONFIG_NAME);
        } catch (Exception e) {
            throw new AuraHandledException('Error getting download headers: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static DownloadFilePayload downloadFileBase64(String contentLocator) {
        try {
            HttpResponse response = sendDownloadRequest(contentLocator);
            
            DownloadFilePayload payload = new DownloadFilePayload();
            payload.base64Data = EncodingUtil.base64Encode(response.getBodyAsBlob());
            payload.contentType = String.isNotBlank(response.getHeader('Content-Type'))
                ? response.getHeader('Content-Type')
                : 'application/octet-stream';

            return payload;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error downloading file: ' + e.getMessage());
        }
    }

    /**
     * @description Private helper to execute HTTP GET request with Core Documents auth headers
     * @param contentLocator Content locator from Core Documents API
     * @return HttpResponse with validated status code
     * @throws AuraHandledException if HTTP status indicates error
     */
    private static HttpResponse sendDownloadRequest(String contentLocator) {
        String endpoint = DES_CoreDocuments.getDownloadUrl(CONFIG_NAME, contentLocator);
        Map<String, String> headers = DES_CoreDocuments.getDownloadHeaders(CONFIG_NAME);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);

        for (String headerName : headers.keySet()) {
            req.setHeader(headerName, headers.get(headerName));
        }

        HttpResponse response = new Http().send(req);
        Integer statusCode = response.getStatusCode();
        Set<Integer> validStatuses = new Set<Integer> { 200, 201, 204 };
        if (!validStatuses.contains(statusCode)) {
            throw new AuraHandledException('HTTP ' + statusCode + ': ' + response.getStatus());
        }

        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<TaxonomyOption> getCatalogsDescriptions(List<String> docTypeCodes, String entific, String catalogValue3) {
        List<TaxonomyOption> optionsList = new List<TaxonomyOption>();
        try {
            // Do not query if the mandatory LWC filters haven't populated yet
            if (docTypeCodes == null || docTypeCodes.isEmpty() || String.isBlank(entific) || String.isBlank(catalogValue3)) {
                return optionsList;
            }

            // MAP: Link the Catalog Code (key) back to the requested docTypeCode (value)
            Map<String, String> catalogToDocTypeMap = new Map<String, String>();
            
            for (String dtCode : docTypeCodes) {
                if (dtCode == 'CO-OF-00240') {
                    List<String> catalogCodes = new List<String>{'I222'}; // add more catalogCodes for dtCode 'CO-OF-00240'
                    for (String catCode : catalogCodes) {
                        catalogToDocTypeMap.put(catCode, dtCode);
                    }
                }
                // Future types can easily be added here
            }
            
            if (!catalogToDocTypeMap.isEmpty()) {
                String likeCatalogValue = '%' + catalogValue3 + '%';
                List<DMT_Taxonomy_Values__c> records = [
                    SELECT Id, DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_External_Id__c, DMT_Catalog__c, DMT_Entific__c
                    FROM DMT_Taxonomy_Values__c 
                    WHERE DMT_Catalog__c IN :catalogToDocTypeMap.keySet() 
                      AND DMT_Active__c = true
                      AND gf_catalog_atrb_val1_name_c__c = :entific
                      AND gf_catalog_atrb_val3_name__c LIKE :likeCatalogValue
                      AND DMT_Active__c = true
                    WITH SYSTEM_MODE
                ];
                if(!records.isEmpty()){
                    for (DMT_Taxonomy_Values__c rec : records) {
                        TaxonomyOption opt = new TaxonomyOption();
                        opt.label = String.isNotBlank(rec.DMT_Name_EN__c) ? rec.DMT_Name_EN__c : rec.DMT_Name__c;
                        opt.value = rec.DMT_Value__c; // Unique value for combobox
                        opt.docTypeCode = catalogToDocTypeMap.get(rec.DMT_Catalog__c); // Maps back to 'CO-OF-00240'
                        opt.externalId = rec.DMT_External_Id__c;
                        opt.entific = rec.DMT_Entific__c;
                        opt.catalogCode = rec.DMT_Catalog__c;
                        optionsList.add(opt);
                    }
                }
            }
            return optionsList;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching catalogs: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String appendTaxonomyValue(Id recordId, String objectApiName, String recordTypeDevName, String taxonomyValue) {
        try {
            if (String.isBlank(taxonomyValue)) {
                return 'No value to append';
            }

            // Dynamically query the specific record and the target field
            String query = 'SELECT Id, CoreDocsTaxonomyValues__c FROM ' + String.escapeSingleQuotes(objectApiName) + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query, AccessLevel.SYSTEM_MODE);
            
            if (!records.isEmpty()) {
                SObject rec = records[0];
                String currentVals = (String)rec.get('CoreDocsTaxonomyValues__c');
                
                if (String.isBlank(currentVals)) {
                    rec.put('CoreDocsTaxonomyValues__c', taxonomyValue);
                } else {
                    // Concatenate using comma, intentionally allowing duplicates for audit purposes
                    rec.put('CoreDocsTaxonomyValues__c', currentVals + ',' + taxonomyValue);
                }
                
                // Perform the secure system-level update
                Database.update(rec, AccessLevel.SYSTEM_MODE);
                return 'Success, current values in field:' + (String)rec.get('CoreDocsTaxonomyValues__c');
            }
            return 'Record not found';
        } catch (Exception e) {
            throw new AuraHandledException('Error updating taxonomy values: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String triggerPassportUpdate(Id recordId, Id clientId, String objectApiName) {
        try {
            if (recordId == null || clientId == null) {
                return 'Missing required IDs for Passport Update.';
            }

            // Determine the correct service name based on the object type
            String serviceName = (objectApiName == 'Opportunity') ? 'DMTO_EvaluationOpportunity' : 'DMTO_EvaluationLine';
            
            // Construct the payload expected by the handler
            DMT_PassportPayload payload = new DMT_PassportPayload(recordId, clientId, serviceName);

            // Execute the existing logic synchronously (Fetches HPG data, then updates Passport)
            DMT_Passport_Handler.handlePassportIntegration(payload);

            return 'Success';
        } catch (Exception e) {
            // We throw this so the LWC can catch it and show a toast if the integration fails
            throw new AuraHandledException('Passport Integration Failed: ' + e.getMessage());
        }
    }

    /**
     * Retrieves Task details securely.
     * Replaces the UI API getRecord call due to polymorphic field limitations in production.
     */
    @AuraEnabled(cacheable=true)
    public static Task getTaskDetails(Id taskId) {
        try {
            return [
                SELECT Id, WhatId 
                FROM Task 
                WHERE Id = :taskId 
                WITH USER_MODE 
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Task details: ' + e.getMessage());
        }
    }

    /** JIRA 4332
     * @description Whether documents can be deleted for the given Opportunity/DMT_Line__c/Case,
     *              based on the record reaching a final state (Closed Won / Closed Case).
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isDocumentDeletionAllowed(Id recordId) {
        if (recordId == null) {
            return false;
        }
        try {
            Schema.SObjectType sType = recordId.getSObjectType();
            if (sType == DMT_Line__c.SObjectType) {
                DMT_Line__c line = [SELECT Status__c, DMT_Status_Completed__c FROM DMT_Line__c WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
                return !(line.Status__c == 'Closed' && line.DMT_Status_Completed__c == 'Closed Won');
            }
            if (sType == Opportunity.SObjectType) {
                Opportunity opp = [SELECT StageName FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
                return opp.StageName != 'Closed Won';
            }
            if (sType == Case.SObjectType) {
                Case caseRecord = [SELECT IsClosed FROM Case WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
                return !caseRecord.IsClosed;
            }
            return true;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_CoreDocuments_Controller', 'isDocumentDeletionAllowed', 'DMT', '');
            return false;
        }
    }

    // --- WRAPPER FOR LWC COMBOBOX ---
    public class TaxonomyOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value; 
        @AuraEnabled public String docTypeCode; 
        @AuraEnabled public String externalId;
        @AuraEnabled public String entific;
        @AuraEnabled public String catalogCode;
    }

    public class DownloadFilePayload {
        @AuraEnabled public String base64Data;
        @AuraEnabled public String contentType;
    }
}