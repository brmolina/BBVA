/**
*Name:         	 ManagerFranchise_Trigger
*Description:     Trigger class for Manager_Franchise_c object
*Test Class:      
*
*Version        Date            Author            Summary of changes
*--------------------------------------------------------------------------------------------------------------
*0.1            19/02/2019      Accenture         Class creation 
*/
trigger ManagerFranchise_Trigger on Manager_Franchise__c (before insert) {
 	//Trigger handler class for ManagerFranchise_Trigger
	ManagerFranchise_TriggerHandler mf_handler = new ManagerFranchise_TriggerHandler();
	
	if(trigger.isBefore) {
		if(trigger.isInsert) {
			mf_handler.setVisitGMFields(trigger.new);
    	}
	}

}