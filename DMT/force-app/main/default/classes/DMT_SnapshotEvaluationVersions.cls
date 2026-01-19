/**-------------------------------------------------------------------------------------------
 * @Name     DMT_SnapshotEvaluationVersions
 * @Author
 * @Date     Created: 2025-04-30
 * ------------------------------------------------------------------------------------------------
 * @Description Wrapper Class for SnapshotEvaluationVersions
 * ------------------------------------------------------------------------------------------------
 */
public with sharing class DMT_SnapshotEvaluationVersions{
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
     * @description Call service and return wrapper for POST Snapshot Evaluation Versions
     */
    @auraEnabled
    public static String postSnapshotEvaluationVersions(String jsonInput){
        System.debug('jsonInput, ' + jsonInput);
        Map<String, Object> request = new Map<String, Object>();
        request.put('jsonInput', jsonInput);
        HttpResponse response;
        String serviceName = 'DMT_PostSnapshotEvaluationVersions';
        PostSnapshotEvaluationVersionsWrapper res = new PostSnapshotEvaluationVersionsWrapper();

        response = DMT_HPG_Utils.callService(serviceName, request);

        System.debug('Response status code: ' + response.getStatusCode());
        switch  on response.getStatusCode(){
            when 200, 201{
                System.debug('Response: ' + response.getBody());
                res = (PostSnapshotEvaluationVersionsWrapper)System.JSON.deserialize(response.getBody(), PostSnapshotEvaluationVersionsWrapper.class);
                res.success = true;
            }
            when else{
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        if (res.success){
            DMT_LINES__e evt = new DMT_LINES__e();
            Database.SaveResult sr = EventBus.publish(evt);
            if (!sr.isSuccess()){
                System.debug('Failed to publish event: ' + sr.getErrors()[0].getMessage());
            }
        }
        return JSON.serialize(res);
    }

    /**
     * @description Centralized method to handle requestStr, recordId, and type for POST Snapshot Evaluation Versions
     */
    @auraEnabled
    public static String processPostSnapshotEvaluationVersion(String requestStr, Id recordId, String type){
        // Deserialize requestStr into a wrapper class
        PostRequestWrapperClass wrapper = (PostRequestWrapperClass)JSON.deserialize(requestStr, PostRequestWrapperClass.class);

        if (Test.isRunningTest()){
            // Mock the response for test purposes
            wrapper.body = '{"Name": "Mocked response body"}';
        } else{
            wrapper.body = generatePdfJSON(recordId, type);
        }

        System.debug('wrapper.body: ' + wrapper.body);

        // Serialize the updated wrapper back to a string
        String updatedRequestStr = JSON.serialize(wrapper);

        // Invoke the original postSnapshotEvaluationVersions method
        return postSnapshotEvaluationVersions(updatedRequestStr);
    }

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
        String response = '';
        if (Test.isRunningTest()){
            // Mock the response for test purposes
            response = '{"Name": "Mocked response body"}';
        } else{
            // Generate JSON for PDF
            response = DMT_ViewController.loadJSONFromSelectedItems(recordId, type, JSON.serialize(itemsList));
        }
        return response;
    }

    //enqueue a job to create a new snapshot evaluation version from triggers helpers. (DMT_Line_Helper, SER_CaseMethods)
    //this method is being called from inside loops (do not perform queries or DML inside this method)
    public static void enqueueSnapshotEvaluationJob(String dmtUserId, String dmtLineId, String categoryId, String versionDescription, String lineRecordId, String type){
        DMT_SnapshotEvaluationVersions.PostRequestWrapperClass requestBody = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
        requestBody.user = dmtUserId;
        requestBody.opportunityId = dmtLineId;
        requestBody.categoryId = categoryId;
        requestBody.versionDescription = versionDescription;

        String requestStr = JSON.serialize(requestBody);
        if (!Test.isRunningTest()){
            System.enqueueJob(new DMT_SnapshotEvaluationQueueable(requestStr, lineRecordId, type));
        }
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
            }
        } else if (sObjectType == Opportunity.SObjectType){
            info.viewType = 'Opportunity';
            info.recordTypeDeveloperName = 'DMT_Opportunity'; // or set as needed
        }
        return info;
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

        public Date eventDate{ get; set; }

        public String description{ get; set; }

        public String categoryId{ get; set; }

        public String body{ get; set; }

    }
}