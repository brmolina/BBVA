/**-------------------------------------------------------------------------------------------
 * @Name     DMT_SnapshotEvaluationVersions
 * @Author
 * @Date     Created: 2025-04-30
 * ------------------------------------------------------------------------------------------------
 * @Description Wrapper Class for SnapshotEvaluationVersions
 * ------------------------------------------------------------------------------------------------
 */
public with sharing class DMT_SnapshotEvaluationVersions{
    private static final Boolean EMAIL_ENABLED = true;

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
    /**
     * @description Receives a Map containing 'wrapper' and 'fullJson'
     */
    @auraEnabled
    public static String postSnapshotEvaluationVersions(String jsonInput){
        System.debug('jsonInput (Map): ' + jsonInput);
        
        // 1. Deserialize the incoming Map
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(jsonInput);
        
        // 2. Get the Wrapper String and Full JSON from the Map
        String wrapperString = (String)inputMap.get('wrapper');
        String fullJson = (String)inputMap.get('fullJson');

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
                if (EMAIL_ENABLED) {
                   DMT_SendEmailService.processMapAndSendEmail(resultMap);
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
            fullJson = '{"PDF": "Mocked PDF Body", "StatusLine": "Close"}';
        } else {
            // Get Full JSON Map string
            fullJson = generatePdfJSON(recordId, type);
        }

        // 2. EXTRACT PDF and assign to wrapper.body
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(fullJson);
        if (responseMap.containsKey('PDF')) {
            wrapper.body = (String)responseMap.get('PDF');
        } else {
            wrapper.body = '';
        }
        
        System.debug('wrapper.body set to PDF: ' + wrapper.body);

        // 3. CREATE MAP to transport data
        Map<String, Object> requestMap = new Map<String, Object>();
        
        // Put the Serialized Wrapper (containing the PDF body) into the map
        requestMap.put('wrapper', JSON.serialize(wrapper)); 
        
        // Put the Full JSON (containing StatusLine, etc.) into the map for later use
        requestMap.put('fullJson', fullJson);

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
    public static String generatePdfJSON(String recordId, String type){
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
        fullResponse = '{"PDF": "Mocked PDF Content", "StatusLine": "Open", "RecordTypeName": "OtherProducts"}';
    } else {
        fullResponse = DMT_ViewController.loadJSONFromSelectedItems(recordId, type, JSON.serialize(itemsList));
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

}