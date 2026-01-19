public with sharing class insertShareVisit implements Queueable {

    List<dwp_kitv__Visit__Share> listvisitSharing;
    public insertShareVisit(List<dwp_kitv__Visit__Share> listvisitSharing) {
        this.listvisitSharing = listvisitSharing;
    }
    public void execute(QueueableContext context) {
        Integer limitDML=9999;
        List<dwp_kitv__Visit__Share> listvisitSharingInsert=new List<dwp_kitv__Visit__Share>();
        List<dwp_kitv__Visit__Share> listvisitSharingRes=new List<dwp_kitv__Visit__Share>();
        for (Integer i=0;i< listvisitSharing.size();i++) {
            if(i<limitDML) {
                listvisitSharingInsert.add(listvisitSharing[i]);
            } else {
                listvisitSharingRes.add(listvisitSharing[i]);
            }
        }
		List<Database.SaveResult> listSR = Database.insert(listvisitSharingInsert, false);
        if(listvisitSharingRes.size()>0&&!Test.isRunningTest()) {
			ID jobID = System.enqueueJob(new insertShareVisit(listvisitSharingRes));
		}
    }
}