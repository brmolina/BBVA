public with sharing class DTM_Task_Helper {
    public static void processTask(List<Task> newList, String operation) 
    {
        List<String> tasksId = new List<String>();

        for(Task t : newList)
        {
            tasksId.add(t.Id);
        }

        List<DMT_Task__e> tasksEvent = new List<DMT_Task__e>();
        tasksEvent.add(new DMT_Task__e(Operation__c = operation, records__c = string.join(tasksId,',')));

        List<Database.SaveResult> results = EventBus.publish(tasksEvent);
    }
}