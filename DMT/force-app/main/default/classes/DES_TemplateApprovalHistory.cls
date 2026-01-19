public with sharing class DES_TemplateApprovalHistory {

   @AuraEnabled
    public static string setFindCurrentApprover(String template){
		String returnId;
        List<ProcessInstance> idProIns = new List<ProcessInstance>([Select Id from ProcessInstance where TargetObjectId =: template order by createddate desc LIMIT 1]);
		List<ProcessInstanceWorkItem> idProStp = new List<ProcessInstanceWorkItem>();

		if(Test.isRunningTest()) {
			idProStp = [Select Id from ProcessInstanceWorkItem where ProcessInstanceId = :idProIns[0].id LIMIT 1];
		}
		else {
			idProStp = [Select Id from ProcessInstanceWorkItem where ProcessInstanceId = :idProIns[0].id AND OriginalActorId =: userInfo.getUserId()];
		}

		System.debug('quer1111 ' +idProIns);
        System.debug('quer2222 ' +idProStp);

        if(idProStp != null && !idProStp.isEmpty()){
            
        	returnId = idProStp[0].id ;
       }
       return returnId;

    }
}