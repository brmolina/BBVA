public class LeadTriggerHandler {
    public void onAfterUpdate(List<Lead> newLeads){
        LeadUtils.insertLeads(NewLeads);
    }    
}