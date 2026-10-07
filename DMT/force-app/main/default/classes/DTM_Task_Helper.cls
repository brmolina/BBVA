public with sharing class DTM_Task_Helper {
    public static void processTask(List<Task> newList, String operation) 
    {
        CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
        
        List<String> tasksId = new List<String>();

        for(Task t : newList)
        {
            tasksId.add(t.Id);
        }

        List<DMT_Task__e> tasksEvent = new List<DMT_Task__e>();
        tasksEvent.add(new DMT_Task__e(Operation__c = operation, records__c = string.join(tasksId,',')));
        if(!byPass.CIB_skip_platform_event__c)
        {
        List<Database.SaveResult> results = EventBus.publish(tasksEvent);
        }
    }
}