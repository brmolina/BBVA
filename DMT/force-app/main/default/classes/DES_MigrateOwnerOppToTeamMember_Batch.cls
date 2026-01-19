/***********************************************************************************************
Name:            DES_MigrateOwnerOppToTeamMember_Batch
Description:     Batch class to migrate the owner of the opp to team member
Test Class:      -

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            13/08/2019                        Class creation

***********************************************************************************************/
public class DES_MigrateOwnerOppToTeamMember_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    /**
	 * Query used in the batch
	 */
    String batchQuery;

    /**
     * Constructor
     */
    public DES_MigrateOwnerOppToTeamMember_Batch(String query) {
        this.batchQuery = query;
    }

    /**
	 * Implementation of the start method of the Database.Batchable interface
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator(batchQuery);
    }
    
    /**
	 * Implementation of the execute method of the Database.Batchable interface
     */
    public void execute(Database.BatchableContext batchableContext, List<SObject> records) {
        List<Opportunity> listOpp = new List<Opportunity>();
        listOpp = (List<Opportunity>) records;

        final Savepoint iSavePoint = Database.setSavepoint();
        // try {
        final Map<Id, Opportunity> mapOpp = new Map <Id, Opportunity>([SELECT Id,
                                                                        OwnerId,
                                                                        Owner.Name,
                                                                        (SELECT Id,
                                                                            DES_Owner__c,
                                                                            DES_User__c
                                                                        FROM Opportunity_Management_members__r)
                                                                    FROM Opportunity
                                                                    WHERE Id IN :listOpp]);

        final List<DES_Opportunity_Management_member__c> listOppMember = new List<DES_Opportunity_Management_member__c>();
        for(Opportunity iOpportunity : mapOpp.values()) {
            Boolean noOwner = true;
            for(DES_Opportunity_Management_member__c iOppMember : iOpportunity.Opportunity_Management_members__r) {
                if(iOppMember.DES_User__c == iOpportunity.OwnerId) {
                    if(iOppMember.DES_Owner__c == false) {
                        iOppMember.DES_Owner__c = true;
                        listOppMember.add(iOppMember);
                    }
                    noOwner = false;
                } else if(iOppMember.DES_Owner__c == true) {
                    iOppMember.DES_Owner__c = false;
                    listOppMember.add(iOppMember);
                }
            }

            if(noOwner) {
                final DES_Opportunity_Management_member__c iOppMember = new DES_Opportunity_Management_member__c(
                    DES_Opportunity__c = iOpportunity.Id,
                    DES_User__c = iOpportunity.OwnerId,
                    DES_Owner__c = true,
                    Name = iOpportunity.Owner.Name);
                listOppMember.add(iOppMember);
            }
        }

        if(!listOppMember.isEmpty()) {
            upsert listOppMember;
        }
        // } catch(Exception e) {
        //     Database.rollback(iSavePoint);
        //     System.debug(e);
        // }
    }

    /**
	 * Implementation of the finish method of the Database.Batchable interface
     */
    public void finish(Database.BatchableContext batchableContext) {
        System.debug('DES_MigrateOwnerOppToTeamMember_Batch finish');
    }    
}