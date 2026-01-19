/*
*Name:            Batch_VisitKit4Migrate
*Description:     Class with Batch_VisitKit4Migrate   -
*/
global class Batch_VisitKit4Migrate implements Database.Batchable<sObject> {//NOSONAR
    /**
    * String para generar la query a usar en el batch.
     */
    private final static String QUERY_MT = 'Select Id, Name, dwp_kitv__contact_email_desc__c, dwp_kitv__user_id__c,dwp_kitv__gf_sf_external_cust_mail_desc__c,'+
         'dwp_kitv__gf_sf_external_customer_id__c,dwp_kitv__gf_sf_external_customer_name__c from dwp_kitv__Visit_Management_Team__c';

    /**
    * Met0d0 de inicio del batch.
     */
    global Database.QueryLocator start(Database.BatchableContext batch) {
       return Database.getQueryLocator(QUERY_MT);
    }

    /**
    * Met0d0 de ejecucion del batch.
     */
    global void execute(Database.BatchableContext batch, dwp_kitv__Visit_Management_Team__c[] teamMembers) {
        final String queryUsers = 'Select Name,id,FederationIdentifier, Email from User' + 
            (Test.isRunningTest()? ' WHERE Username LIKE \'%@test.comm\'' : '');

        User [] users;
        users = Database.query(queryUsers);
        dwp_kitv__Visit_Management_Team__c [] mTeamList;
        mTeamList = new List<dwp_kitv__Visit_Management_Team__c>();

        for(dwp_kitv__Visit_Management_Team__c teamMember : teamMembers) {
            for(User userquery : users) {
                if(userquery.FederationIdentifier != '' && userquery.id == teamMember.dwp_kitv__user_id__c) {
                    teamMember.dwp_kitv__gf_sf_external_cust_mail_desc__c = String.valueOf(userquery.Email);
                    teamMember.dwp_kitv__gf_sf_external_customer_id__c = String.valueOf(userquery.FederationIdentifier);
                    teamMember.dwp_kitv__gf_sf_external_customer_name__c = String.valueOf(userquery.Name);
                }
            }
            mTeamList.add(teamMember);
        }
        try {
            upsert mTeamList;
        } catch (System.DmlException e) {
            System.debug(e);

        }
    }

    /**
    * Met0d0 de finalizacion del batch.
     */
    global void finish(Database.BatchableContext batch) {
         final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batch.getJobId()];
        system.debug('++ job ' + job);
    }

}