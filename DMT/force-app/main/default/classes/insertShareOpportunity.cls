public class insertShareOpportunity implements Queueable {
    List<OpportunityShare> listOppShIns;
    public insertShareOpportunity(List<OpportunityShare> listOppShInsIn) {
        this.listOppShIns = listOppShInsIn;
    }
    public void execute(QueueableContext context) {
		Integer limitDML=9999;
		List<OpportunityShare> listOppShInsInsert=new List<OpportunityShare>();
		List<OpportunityShare> listOppShInsRes=new List<OpportunityShare>();
		
		for (Integer i=0;i< listOppShIns.size();i++) {
			if(i<limitDML) {
				listOppShInsInsert.add(listOppShIns[i]);
			} else {
				listOppShInsRes.add(listOppShIns[i]);
			}
        }
		List<Database.SaveResult> listSR = Database.insert(listOppShInsInsert, false);
        if(listOppShInsRes.size()>0&&!Test.isRunningTest()) {
			ID jobID = System.enqueueJob(new insertShareOpportunity(listOppShInsRes));
		}
    }
}