/***********************************************************************************************
Name:            DES_MigrateOwnerOppToTeamMember_Batch
Description:     Batch class to migrate the owner of the visit to team member
Test Class:      -

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            15/10/2019                        Class creation

***********************************************************************************************/
public class Batch_UpdateOwnerVisitTeam implements Database.Batchable<Sobject>, Database.Stateful {

    /**
	 * Query used in the batch
	 */
	final private String pQuery = 'SELECT Id, OwnerId FROM dwp_kitv__Visit__c' + (Test.isRunningTest() ? ' LIMIT 200' : ' WHERE CreatedDate < 2019-07-18T00:00:00Z');

    /**
     * Constructor
     */	
	public Batch_UpdateOwnerVisitTeam() {
		System.debug('Batch_UpdateOwnerVisitTeam constructor');
    }

    /**
	 * Implementation of the start method of the Database.Batchable interface
     */
    public Database.QueryLocator start(Database.BatchableContext bContext) {
        System.debug('>>>>> Query: ' + pQuery);
        return Database.getQueryLocator(pQuery);
    }
    
    /**
	 * Implementation of the execute method of the Database.Batchable interface
     */
    public void execute(Database.BatchableContext bContext, List<dwp_kitv__Visit__c> scope) {
		final map<String, String> visitOwner = new map<String, String>();
		for(dwp_kitv__Visit__c vis: scope) {
			visitOwner.put(vis.Id, vis.OwnerId);
		}
		
		final Map<Id, dwp_kitv__Visit__c> mapVisit = new Map <Id, dwp_kitv__Visit__c>([SELECT Id,
																						OwnerId,
																						Owner.Name,
																						(SELECT Id,
																							dwp_kitv__visit_id__c,
																							dwp_kitv__user_id__c,
																							dwp_kitv__user_id__r.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c
																						FROM dwp_kitv__Visit_Management_Teams__r)
																					FROM dwp_kitv__Visit__c
																					WHERE Id IN :scope]);

        final List<dwp_kitv__Visit_Management_Team__c> listVisitMember = new List<dwp_kitv__Visit_Management_Team__c>();
        for(dwp_kitv__Visit__c iVisit : mapVisit.values()) {
            Boolean noOwner = true;
            for(dwp_kitv__Visit_Management_Team__c iVisitMember : iVisit.dwp_kitv__Visit_Management_Teams__r) {
                if(iVisitMember.dwp_kitv__user_id__c == iVisit.OwnerId) {
                    noOwner = false;
                }
            }

            if(noOwner) {
                final dwp_kitv__Visit_Management_Team__c iVisitMember = new dwp_kitv__Visit_Management_Team__c(
                    dwp_kitv__visit_id__c = iVisit.Id,
                    dwp_kitv__user_id__c = iVisit.OwnerId);
                listVisitMember.add(iVisitMember);
            }
        }

        if(!listVisitMember.isEmpty()) {
            insert listVisitMember;
        }

		final Map<Id, dwp_kitv__Visit__c> mapVisitInvArea = new Map <Id, dwp_kitv__Visit__c>([SELECT Id,
																						OwnerId,
																						Owner.Name,
																						(SELECT Id,
																							dwp_kitv__visit_id__c,
																							dwp_kitv__user_id__c,
																							dwp_kitv__user_id__r.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c
																						FROM dwp_kitv__Visit_Management_Teams__r)
																					FROM dwp_kitv__Visit__c
																					WHERE Id IN :scope]);
		visitInvolvedAreas(mapVisitInvArea);
	}

    /**
	 * Implementation of the finish method of the Database.Batchable interface
     */
	public void finish(Database.BatchableContext bContext) {
		system.debug('FINISH');
	}

    /**
     * @author GlobalDesktop 
     */
	public void visitInvolvedAreas(Map<Id, dwp_kitv__Visit__c> mapVisit) {
		final Batch_InvolvedAreas_Handler iInvAreaHandler = Batch_InvolvedAreas_Handler.getInstance(); 
		for(dwp_kitv__Visit__c iVisit : mapVisit.values()) {
			iInvAreaHandler.logicSetInvolvedAreas(iVisit.dwp_kitv__Visit_Management_Teams__r);
		}
	}
}