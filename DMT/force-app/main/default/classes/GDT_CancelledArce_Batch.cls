/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_CancelledArce_Batch
* @Author   hectorjeshua.vasquez.contractor@bbva.com
* @Date     Created: 08/03/2024
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class "GDT_CancelledArce_Batch" that cancel ARCEs with more than 15 days being in the cancelled status
* -----------------------------------------------------------------------------------------------
* @Changes
* |08/03/2024 hectorjeshua.vasquez.contractor@bbva.com
*             Initial version
* -----------------------------------------------------------------------------------------------
*/
public with sharing class GDT_CancelledArce_Batch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    /**
    * @Description: String with ARCE Stage
    */
    private static final String stage = '3';
    /**
    * @Description: String with ARCE Status
    */
    private static final String status = '14';
    /**
    * @Description: String with query
    */
    private final String query = 'select Id, name, LastModifiedDate from arce__Analysis__c where arce__Stage__c =\''+stage+'\' and arce__wf_status_id__c =\''+status+'\' and LastModifiedDate <LAST_N_DAYS:15';
    /**
    * @Description: Batch start method
    */
    public Database.QueryLocator start(Database.BatchableContext iBatchableContext) {
        return Database.getQueryLocator(query);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Batch execute method that erase all cancelled ARCEs made more than 15 days ago
    --------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 08/03/2024
    **/
    public void execute(Database.BatchableContext iBatchableContext, List<sObject> scope) {
        List<arce__Analysis__c> recordsToDelete = new List<arce__Analysis__c>();
        List<arce__esg_toolkitSummary__c> toolkitToDelete = new List<arce__esg_toolkitSummary__c>();
        List<arce__JointVenture__c > jointventureToDelete = new List<arce__JointVenture__c >();
        for(arce__Analysis__c analysis : (List<arce__Analysis__c>) scope) {
            recordsToDelete.add(analysis);
        }
        Map<String, arce__esg_toolkitSummary__c> toolkitMap = new Map<String, arce__esg_toolkitSummary__c>();
        for(arce__esg_toolkitSummary__c objCS : [SELECT id, arce__esg_Account_has_Analysis__r.arce__Analysis__c FROM arce__esg_toolkitSummary__c]){
        	toolkitMap.put(objCS.arce__esg_Account_has_Analysis__r.arce__Analysis__c, objCS);
        }
        Map<String, arce__JointVenture__c> jointventureMap = new Map<String, arce__JointVenture__c>();
        for(arce__JointVenture__c objCS : [SELECT id, arce__AccountHasAnalysis__r.arce__Analysis__c FROM arce__JointVenture__c]){
        	jointventureMap.put(objCS.arce__AccountHasAnalysis__r.arce__Analysis__c, objCS);
        }
        for(arce__Analysis__c analysis : recordsToDelete){
            if (toolkitMap.containsKey(analysis.Id)){
                toolkitToDelete.add(toolkitMap.get(analysis.Id));
            }
            if (jointventureMap.containsKey(analysis.Id)){
                jointventureToDelete.add(jointventureMap.get(analysis.Id));
            }
        }
        
        if(toolkitToDelete != null || !toolkitToDelete.isempty()){
            delete toolkitToDelete;
        }
        if(jointventureToDelete != null || !jointventureToDelete.isempty()){
            delete jointventureToDelete;
        }
   		if(recordsToDelete != null || !recordsToDelete.isempty()){
        	delete recordsToDelete;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Batch finish method that sends all emails
    --------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 08/03/2024
    **/
    public void finish(Database.BatchableContext iBatchableContext) {
        final List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Schedulable execute method
    --------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 08/03/2024
    **/
    public void execute(SchedulableContext scheduleContext) {
        Database.executeBatch(this);
    }
}