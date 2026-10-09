/**-------------------------------------------------------------------------------------------
 * @Name     DMT_SnapshotEvaluationVersions
 * @Author
 * @Date     Created: 2025-04-30
 * ------------------------------------------------------------------------------------------------
 * @Description Wrapper Class for SnapshotEvaluationVersions
 * ------------------------------------------------------------------------------------------------
 */
public with sharing class DMT_SnapshotEvaluationVersions{
    private static final Boolean EMAIL_ENABLED = true; // Set to true to enable email sending, false to disable

    /**
     * @description Call service and return wrapper string for GET Snapshot Evaluation Versions
     */
    @auraEnabled
    public static String getSnapshotEvaluationVersions(String requestStr){
        System.debug('requestStr: ' + requestStr);
        Map<String, Object> request = new Map<String, Object>();
        request.put('queryString', requestStr);
        HttpResponse response;
        String serviceName = 'DMT_GetSnapshotEvaluationVersions';

        GetSnapshotEvaluationVersionsWrapper res = new GetSnapshotEvaluationVersionsWrapper();

        response = DMT_HPG_Utils.callService(serviceName, request);
        System.debug('Response status code: ' + response.getStatusCode());
        switch  on response.getStatusCode(){
            when 200, 201{
                System.debug('Response: ' + response.getBody());
                res = (GetSnapshotEvaluationVersionsWrapper)System.JSON.deserialize(response.getBody(), GetSnapshotEvaluationVersionsWrapper.class);
                res.success = true;
                repairVersionBodies(res, response.getBody());
            }
            when else{
                System.debug('Response: ' + response.getBody());
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }

        res = updateUserProperty(res);
        System.debug('Updated response: ' + JSON.serialize(res));
        return JSON.serialize(res);
    }

    private static getSnapshotEvaluationVersionsWrapper updateUserProperty(getSnapshotEvaluationVersionsWrapper res){
        // 1. Collect all unique user codes from the versions
        Set<String> userCodeSet = new Set<String>();
        if (res != null && res.data != null && res.data.versions != null){
            for (Version v : res.data.versions){
                if (v.user != null){
                    v.userCode = v.user;
                    userCodeSet.add(v.user);
                }
            }
        }

        // 2. Query User records by ID_User__c
        Map<String, String> userCodeToName = new Map<String, String>();
        if (!userCodeSet.isEmpty()){
            for (User u : [SELECT ID_User__c, Name
                           FROM User
                           WHERE ID_User__c IN:userCodeSet]){
                userCodeToName.put(u.ID_User__c, u.Name);
            }
        }

        // 3. Replace user code with user name in the wrapper
        if (res != null && res.data != null && res.data.versions != null){
            for (Version v : res.data.versions){
                if (v.user != null && userCodeToName.containsKey(v.user)){
                    v.user = userCodeToName.get(v.user);
                    
                }
            }
        }

        return res;
    }

    // Repairs Version.body fields that the typed deserializer sets to null when the service
    // returns the body as a JSON object instead of a JSON string.
    private static void repairVersionBodies(GetSnapshotEvaluationVersionsWrapper res, String rawBody) {
        if (res.data == null || res.data.versions == null || res.data.versions.isEmpty()) {
            return;
        }
        try {
            Map<String, Object> rawResponse = (Map<String, Object>) JSON.deserializeUntyped(rawBody);
            Map<String, Object> rawData = (Map<String, Object>) rawResponse.get('data');
            if (rawData == null) return;
            List<Object> rawVersions = (List<Object>) rawData.get('versions');
            if (rawVersions == null) return;
            for (Integer i = 0; i < res.data.versions.size() && i < rawVersions.size(); i++) {
                if (res.data.versions[i].body == null) {
                    Map<String, Object> rawVersion = (Map<String, Object>) rawVersions.get(i);
                    Object rawBodyObj = rawVersion.get('body');
                    if (rawBodyObj != null && !(rawBodyObj instanceof String)) {
                        res.data.versions[i].body = JSON.serialize(rawBodyObj);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, '[DMT_SnapshotEvalVers] repairVersionBodies: ' + e.getMessage());
        }
    }

    /**
     * @description Receives a Map containing 'wrapper' and 'fullJson'
     */
    @auraEnabled
    public static String postSnapshotEvaluationVersions(String jsonInput){
        System.debug('jsonInput (Map): ' + jsonInput);
        
        // 1. Deserialize the incoming Map
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(jsonInput);
        
        // 2. Get the Wrapper String, Full JSON, and skinny flag from the Map
        String wrapperString = (String)inputMap.get('wrapper');
        String fullJson      = (String)inputMap.get('fullJson');
        Boolean skinnyBody   = inputMap.get('skinnyBody') == true;

        // 3. Prepare Service Request (Send ONLY the wrapper string)
        Map<String, Object> request = new Map<String, Object>();
        request.put('jsonInput', wrapperString); 
        
        HttpResponse response;
        String serviceName = 'DMT_PostSnapshotEvaluationVersions';
        PostSnapshotEvaluationVersionsWrapper res = new PostSnapshotEvaluationVersionsWrapper();

        // 4. Call Service
        response = DMT_HPG_Utils.callService(serviceName, request);

        System.debug('Response status code: ' + response.getStatusCode());
        switch on response.getStatusCode(){
            when 200, 201{
                System.debug('Response: ' + response.getBody());
                res = (PostSnapshotEvaluationVersionsWrapper)System.JSON.deserialize(response.getBody(), PostSnapshotEvaluationVersionsWrapper.class);
                res.success = true;

                // Process the full JSON to extract necessary info for email sending
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(fullJson);
                System.debug('Full JSON deserialized for email processing: ' + String.valueOf(resultMap.get('HTML')));
                resultMap.put('categoryId', res.data.categoryId);
                resultMap.put('versionId', res.data.versionId);
                resultMap.put('eventDate', res.data.eventDate);
                resultMap.put('user', res.data.user);

                // CIBGLOBALD-3731: generate PDF and upload to CoreDocuments for every new version,
                // regardless of EMAIL_ENABLED or email eligibility. PDF is generated once here so
                // DMT_SendEmailService can reuse it without regenerating it.
                String pdfBase64ForVersion = null;
                Object recordLineIdObj = resultMap.get('recordLineId'); // declared outside try so catch can access it
                try {
                    String htmlForPdf = String.valueOf(resultMap.get('HTML'));
                    System.debug(LoggingLevel.INFO, '[DMT_SnapshotEvalVers] ▶ PDF generation — versionId: '
                        + res.data.versionId + ' | recordLineId: ' + recordLineIdObj
                        + ' | htmlLength: ' + (String.isNotBlank(htmlForPdf) ? String.valueOf(htmlForPdf.length()) : 'BLANK'));
                    if (String.isNotBlank(htmlForPdf) && recordLineIdObj != null) {
                        Id sfRecordId = (Id) String.valueOf(recordLineIdObj);
                        Blob pdfBlob = DMT_BlobBuilderForPDF.buildPdfBlob(htmlForPdf);
                        pdfBase64ForVersion = EncodingUtil.base64Encode(pdfBlob);
                        System.debug(LoggingLevel.INFO, '[DMT_SnapshotEvalVers] ✅ PDF generated — base64 size: ' + pdfBase64ForVersion.length());
                        String dateStr = res.data.eventDate != null
                            ? String.valueOf(res.data.eventDate).replace('-', '')
                            : String.valueOf(Date.today()).replace('-', '');
                        String fileBaseName = String.valueOf(resultMap.get('lineName'))
                            + '_' + res.data.versionId
                            + '_' + dateStr
                            + '_' + String.valueOf(resultMap.get('user'));
                        System.debug(LoggingLevel.INFO, '[DMT_SnapshotEvalVers] ▶ Enqueueing CoreDocuments upload — file: ' + fileBaseName + '.pdf');
                        DMT_AsyncOrchestrator.enqueue(new DMT_CoreDocumentsUploadPayload(sfRecordId, fileBaseName, pdfBase64ForVersion));
                        DMT_AsyncOrchestrator.flush();
                        System.debug(LoggingLevel.INFO, '[DMT_SnapshotEvalVers] ✅ CoreDocuments upload enqueued — file: ' + fileBaseName + '.pdf');
                    }
                } catch (Exception pdfEx) {
                    System.debug(LoggingLevel.ERROR, '[DMT_SnapshotEvalVers] ❌ PDF/CoreDocs upload error: '
                        + pdfEx.getMessage() + ' | type: ' + pdfEx.getTypeName());
                    // If the body was stored skinny (styles stripped) and CoreDocuments upload failed,
                    // save the full styled HTML to a local ContentVersion so the LWC can later
                    // regenerate the PDF, retry the upload, and then clean up this backup.
                    if (skinnyBody && recordLineIdObj != null) {
                        String htmlForBackup = String.valueOf(resultMap.get('HTML'));
                        saveSnapshotContentVersion((Id) String.valueOf(recordLineIdObj), res.data.versionId, htmlForBackup);
                    }
                }

                if (EMAIL_ENABLED) {
                    if (pdfBase64ForVersion != null) {
                        // PDF already generated and uploaded — pass it so the service skips both
                        DMT_SendEmailService.processMapAndSendEmail(resultMap, pdfBase64ForVersion);
                    } else {
                        DMT_SendEmailService.processMapAndSendEmail(resultMap);
                    }
                } else {
                    System.debug('Email sending disabled by EMAIL_ENABLED flag.');
                }

                // Update the Line record with the last generated version info
                fillLastGeneratedVersionField(res.data.opportunityId, res.data.versionDescription, res.data.categoryId, res.data.versionId);
            }
            when else{
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        
        // 5. Handle Success using the Full JSON we passed in the Map
        if (res.success){
            // Pass the fullJson (with StatusLine/RecordType) to your save method
            System.debug('res.success' + res);

            DMT_LINES__e evt = new DMT_LINES__e();

            Database.SaveResult sr = EventBus.publish(evt);
            if (!sr.isSuccess()){
                System.debug('Failed to publish event: ' + sr.getErrors()[0].getMessage());
            }
        }
        return JSON.serialize(res);
    }
    /**
     * @description Helper to process the request, extract body, and call the service
     */
    @auraEnabled
    public static String processPostSnapshotEvaluationVersion(String requestStr, Id recordId, String type){

        // 1. Deserialize the incoming request wrapper
        PostRequestWrapperClass wrapper = (PostRequestWrapperClass)JSON.deserialize(requestStr, PostRequestWrapperClass.class);

        String fullJson = '';
        if (Test.isRunningTest()){
            fullJson = '{"HTML": "Mocked HTML Body", "StatusLine": "Close"}';
        } else {
            // Get Full JSON Map string
            fullJson = generateVersionHtml(recordId, type);
        }

        // 2. EXTRACT HTML and wrap in a JSON envelope {"html":"..."} so the external service
        //    receives valid JSON (it rejects raw HTML strings with 400 bad request).
        //    Readers detect this format by checking for the "html" key in the parsed body.
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(fullJson);
        Boolean skinnyBody = false;
        if (responseMap.containsKey('HTML')) {
            String htmlContent = (String)responseMap.get('HTML');
            // Try storing full styled HTML first — {"html":"...","full":true}.
            // "full":true signals the LWC that it can re-generate the PDF directly from this body.
            // "full":false signals skinny storage: a ContentVersion backup holds the full HTML.
            final Integer MAX_SNAPSHOT_BODY_SIZE = 999999999;
            String fullEnvelope = JSON.serialize(new Map<String, Object>{ 'html' => htmlContent, 'full' => true });
            if (fullEnvelope.length() <= MAX_SNAPSHOT_BODY_SIZE) {
                wrapper.body = fullEnvelope;
                System.debug('[DMT_SnapshotEvalVers] ✅ Body — full HTML stored (' + fullEnvelope.length() + ' chars)');
            } else {
                String minimalHtml = htmlContent.replaceAll(' style="[^"]*"', '').replaceAll(' class="[^"]*"', '');
                wrapper.body = JSON.serialize(new Map<String, Object>{ 'html' => minimalHtml, 'full' => false });
                skinnyBody = true;
                System.debug('[DMT_SnapshotEvalVers] ⚠ Body — skinny HTML stored (full: ' + fullEnvelope.length() + ', skinny: ' + wrapper.body.length() + ')');
            }
        } else {
            wrapper.body = '';
        }

        // 3. CREATE MAP to transport data
        Map<String, Object> requestMap = new Map<String, Object>();

        // Put the Serialized Wrapper (containing the PDF body) into the map
        requestMap.put('wrapper', JSON.serialize(wrapper));

        // Put the Full JSON (containing StatusLine, etc.) into the map for later use
        requestMap.put('fullJson', fullJson);

        // Signal whether the body was stored skinny — used to trigger ContentVersion backup
        requestMap.put('skinnyBody', skinnyBody);

        // 4. Send the Map to the Post method
        return postSnapshotEvaluationVersions(JSON.serialize(requestMap));
    }
    
    /**
     * @description Creates a new Snapshot Version using a pre-generated JSON string from the client, avoiding server regeneration.
     */
    /* @AuraEnabled
    public static String createSnapshotVersionFromCachedJson(String requestStr, String cachedJson) {
        // 1. Deserialize the incoming request wrapper (metadata)
        PostRequestWrapperClass wrapper = (PostRequestWrapperClass)JSON.deserialize(requestStr, PostRequestWrapperClass.class);

        // 2. EXTRACT PDF from the cached JSON and assign to wrapper.body
        if (String.isNotBlank(cachedJson)) {
                wrapper.body = cachedJson;
        } else {
            throw new AuraHandledException('Cached JSON is empty. Cannot create snapshot version.');
        }
        
        System.debug('wrapper.body successfully set from client cachedJson');

        // 3. CREATE MAP to transport data (matching the logic in processPostSnapshotEvaluationVersion)
        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('wrapper', JSON.serialize(wrapper)); 
        requestMap.put('fullJson', String.isNotBlank(cachedJson) ? cachedJson : '{}');

        // 4. Send directly to the Post method
        return postSnapshotEvaluationVersions(JSON.serialize(requestMap));
    } */

    @AuraEnabled(cacheable = true)
    public static String getDMTUserId(){
        return [SELECT ID_User__c
                FROM User
                WHERE Id = :UserInfo.getUserId()].ID_User__c;
    }

    @AuraEnabled
    public static String generateVersionHtml(String recordId, String type){
    // Create a list of DMT_ViewController.ItemWrapper
        List<DMT_ViewController.ItemWrapper> itemsList = new List<DMT_ViewController.ItemWrapper>();

        ViewTypeInfo info = getViewTypeInfoFromRecordId(recordId);

        List<String> components = new List<String>();
        components = DMT_View_Selector.getFilteredComponentItemOptionByVersionView(info.viewType);
        if (components.isEmpty()){
            components = DMT_ItemController.getFilteredComponentItemOptions(info.viewType);
        }

        for (String component : components){
            DMT_ViewController.ItemWrapper item = new DMT_ViewController.ItemWrapper();
            item.component = component;
            itemsList.add(item);
        }

    String fullResponse = '';
    if (Test.isRunningTest()){
        fullResponse = '{"HTML": "Mocked HTML Content", "StatusLine": "Open", "RecordTypeName": "OtherProducts"}';
    } else {
        fullResponse = DMT_ViewController.loadVersionSnapshot(recordId, type, JSON.serialize(itemsList));
    }
    return fullResponse; 
}

    // get viewType info from the recordId
    public static ViewTypeInfo getViewTypeInfoFromRecordId(Id recordId){
        ViewTypeInfo info = new ViewTypeInfo();
        Schema.SObjectType sObjectType = recordId.getSObjectType();

        if (sObjectType == DMT_Line__c.SObjectType){
            DMT_Line__c line = [SELECT RecordType.DeveloperName
                                FROM DMT_Line__c
                                WHERE Id = :recordId
                                LIMIT 1];
            info.recordTypeDeveloperName = line.RecordType.DeveloperName;
            switch on line.RecordType.DeveloperName {
                when 'TreasurySettlement' {
                    info.viewType = 'Line_Treasury';
                }
                when 'OtherProducts' {
                    info.viewType = 'Line';
                }
                when 'Sanction' {
                    info.viewType = 'Line_Sanction';
                }
            }
        } else if (sObjectType == Opportunity.SObjectType){
            info.viewType = 'Opportunity';
            info.recordTypeDeveloperName = 'DMT_Opportunity'; // or set as needed
        }
        return info;
    }
    @AuraEnabled
    public static void sendEmailToApprovers(String  pdfBase64, String lineId, String lineName) {
        DMT_SendEmailService.sendEmailToApprovers(pdfBase64, lineId, lineName);
    }

    @AuraEnabled
    public static void fillLastGeneratedVersionField(String LineId, String description, String category, String version) {
        // Normalizar strings
        description = String.isBlank(description) ? '' : description;
        category    = String.isBlank(category)    ? '' : category;

        List<DMT_Line__c> lines = [
            SELECT Id, DMT_LastGeneratedVersionName__c
            FROM DMT_Line__c
            WHERE Line_Id__c = :LineId
            LIMIT 1
        ];

        if (lines.isEmpty()) {
            return;
        }

        DMT_Line__c line = lines[0];

        // Construir nuevo valor
        String newValue = String.isBlank(description)
            ? category + ' - ' + version
            : category + ' - ' + description + ' - ' + version;

        if (line.DMT_LastGeneratedVersionName__c != newValue) {
            line.DMT_LastGeneratedVersionName__c = newValue;
            update line;
        }
    }


    public class ViewTypeInfo{
        public String viewType;
        public String recordTypeDeveloperName;
    }

    // Define the PostRequestWrapperClass to match the required pattern
    public class PostRequestWrapperClass{
        public String body;
        public String categoryId;
        public String opportunityId;
        public String user;
        public String versionDescription;

    }

    /**
     * @Description: Class GetSnapshotEvaluationVersionsWrapper
     */
    public class GetSnapshotEvaluationVersionsWrapper{
        public Data data{ get; set; }

        public boolean success{ get; set; }

        public String errorMessage{ get; set; }

    }

    /**
     * @Description: Class PostSnapshotEvaluationVersionsWrapper
     */
    public class PostSnapshotEvaluationVersionsWrapper{
        public Data data{ get; set; }

        public boolean success{ get; set; }

        public String errorMessage{ get; set; }

    }
    public class PostEvaluationWrapper {
        public String jsonInput;
        public String requestJSON;
        public String recordId;
    }

    /**
     * @Description: Class Data
     */
    public class Data{
        public Integer auditId{ get; set; }

        public String opportunityId{ get; set; }

        public String versionId{ get; set; }

        public String versionDescription{ get; set; }

        public String body{ get; set; }

        public String user{ get; set; }

        public String userAuditId{ get; set; }

        public String categoryId{ get; set; }

        public Date eventDate{ get; set; }

        public Datetime auditDate{ get; set; }

        public List<Version> versions{ get; set; }

        // For GET use case
    }

    /**
     * @Description: Class Version
     */
    public class Version{
        public String id{ get; set; }

        public Integer auditId{ get; set; }

        public String user{ get; set; }
        
        public String userCode{ get; set; }

        public Date eventDate{ get; set; }

        public String description{ get; set; }

        public String categoryId{ get; set; }

        public String body{ get; set; }

    }

    // ── ContentVersion backup helpers ─────────────────────────────────────────
    // Used when the snapshot body is stored skinny (styles stripped) and
    // CoreDocuments upload failed. The full styled HTML is saved locally so the
    // LWC can regenerate the PDF, retry the upload, and clean up the backup.

    private static void saveSnapshotContentVersion(Id sfRecordId, String versionId, String htmlContent) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'SNAPSHOT_' + versionId;
            cv.PathOnClient = 'snapshot_' + versionId + '.html';
            cv.VersionData = Blob.valueOf(htmlContent);
            cv.FirstPublishLocationId = sfRecordId;
            insert cv;
            System.debug(LoggingLevel.INFO, '[DMT_SnapshotEvalVers] ✅ ContentVersion backup saved for versionId: ' + versionId);
        } catch (Exception cvEx) {
            System.debug(LoggingLevel.ERROR, '[DMT_SnapshotEvalVers] ❌ ContentVersion backup save failed: ' + cvEx.getMessage());
        }
    }

    @AuraEnabled
    public static String getSnapshotContentVersionHtml(Id recordId, String versionId) {
        try {
            List<ContentDocumentLink> links = [
                SELECT ContentDocument.LatestPublishedVersion.VersionData
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                AND ContentDocument.Title = :('SNAPSHOT_' + versionId)
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            if (links.isEmpty()) return null;
            Blob versionData = links[0].ContentDocument.LatestPublishedVersion.VersionData;
            return versionData != null ? versionData.toString() : null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[DMT_SnapshotEvalVers] getSnapshotContentVersionHtml error: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static void deleteSnapshotContentVersion(Id recordId, String versionId) {
        try {
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                AND ContentDocument.Title = :('SNAPSHOT_' + versionId)
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            if (!links.isEmpty()) {
                delete [SELECT Id FROM ContentDocument WHERE Id = :links[0].ContentDocumentId WITH SYSTEM_MODE LIMIT 1];
                System.debug(LoggingLevel.INFO, '[DMT_SnapshotEvalVers] ✅ ContentVersion backup deleted for versionId: ' + versionId);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[DMT_SnapshotEvalVers] deleteSnapshotContentVersion error: ' + e.getMessage());
        }
    }

}