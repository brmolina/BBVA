public with sharing class DMT_ScreenViewManagementController {

    @AuraEnabled(cacheable=false)
    public static String getApproversViews() {
        List<DMT_ApproversView__c> approverViews = [SELECT Id, Name, DMT_DeveloperName__c, IsVersionView__c, DisplayInOpportunity__c, LastModifiedDate, toLabel(DMT_Type__c), Profitability__c FROM DMT_ApproversView__c ORDER BY LastModifiedDate DESC];
        return JSON.serialize(approverViews);
    }

    @AuraEnabled(cacheable=false)
    public static String getItemsForView(String recordId) {
        List<DMT_Items__c> itemsForViewList = [SELECT Id, DMT_Component_Item__c, DMT_order_display__c, DMT_View__c, Type_Item__c, DMT_Text__c FROM DMT_Items__c WHERE DMT_View__c = :recordId ORDER BY DMT_order_display__c];
        return JSON.serialize(itemsForViewList);
    }

    @AuraEnabled(cacheable=true)
    public static String getDMTTypePicklistOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        // Get describe result for the object
        Schema.DescribeSObjectResult describeResult = DMT_ApproversView__c.SObjectType.getDescribe();

        // Get describe result for the picklist field
        Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get('DMT_Type__c').getDescribe();

        // Get picklist values
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }

        return JSON.serialize(options);
    }

    @AuraEnabled
    public static String upsertApproversViewWithItems(String jsonPayload) {

        System.Savepoint sp = Database.setSavepoint();

        try{
            // 1. Deserialize the single payload string
            Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(jsonPayload);

            // 2. Extract variables from the Map
            String recordId = (String) input.get('recordId');
            String viewName = (String) input.get('viewName');
            String viewType = (String) input.get('viewType');
            Boolean isVersionView = (Boolean) input.get('isVersionView');
            Boolean displayInOpportunity = (Boolean) input.get('displayInOpportunity');

            // 3. Extract the items list directly (It was stringified as part of the main payload)
            List<Object> rawItems = (List<Object>) input.get('items');

            // Deserialize the selected items
            List<DMT_Items__c> itemsToUpsert = new List<DMT_Items__c>();

            Id viewId;

            DMT_ApproversView__c view = new DMT_ApproversView__c();

            if(String.isNotBlank(recordId)){
                // Delete existing DMT_Items__c records related to the view
                List<DMT_Items__c> existingItems = DMT_View_Selector.getItemsByApproversViewRecordId(recordId);
                if (!existingItems.isEmpty()) {
                    delete existingItems;
                }
                // Create or update DMT_ApproversView__c using upsert
                view.Id = recordId;
            }

            view.DMT_Type__c = viewType;
            view.DMT_DeveloperName__c = viewname;
            view.Name = viewName;
            view.IsVersionView__c = isVersionView;
            view.DisplayInOpportunity__c = displayInOpportunity;

            // If IsVersionView__c is being set to TRUE, we must uncheck others of the same Type.
            if (isVersionView == true && String.isNotBlank(viewType)) {
                // Query existing active versions for this type
                // We exclude the current recordId to avoid self-locking issues if it already exists
                List<DMT_ApproversView__c> approversToDeactivateIsVersionView = DMT_View_Selector.getViewToDeactivateVersion(viewType, recordId);

                if (!approversToDeactivateIsVersionView.isEmpty()) {
                    for (DMT_ApproversView__c oldView : approversToDeactivateIsVersionView) {
                        oldView.IsVersionView__c = false;
                    }
                    update approversToDeactivateIsVersionView; // Deactivate siblings
                }
            }

            upsert view;

            viewId = view.Id; // Save the actual ID to assign to items

            // Construct the DMT_Items__c list
            for (Object itemObj : rawItems) {
                Map<String, Object> item = (Map<String, Object>) itemObj;

                DMT_Items__c newItem = new DMT_Items__c();
                newItem.DMT_View__c = viewId;
                newItem.DMT_order_display__c = (Integer) item.get('orderDisplay');
                newItem.Type_Item__c = (String) item.get('type');
                newItem.DMT_Component_Item__c = (String) item.get('component');
                newItem.DMT_Text__c = (String) item.get('textValue');

                itemsToUpsert.add(newItem);
            }

            if (!itemsToUpsert.isEmpty()) {
                upsert itemsToUpsert;
            }

            return 'Success';
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Error on DMT_ScreenViewManagementController upsertApproversViewWithItems, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','upsertApproversViewWithItems','DMT',''));
            throw new AuraHandledException('Error while trying to update or create views. '+e.getMessage() + ' '+ e.getLineNumber());
        }
    }
}