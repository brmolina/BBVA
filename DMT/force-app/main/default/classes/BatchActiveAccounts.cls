/**********************************************************************************
* @author  		Global Desktop
* @date         01/04/2020
* @description  Batch que desmarca el check de activo
* @Revision
**********************************************************************************/
public without sharing class BatchActiveAccounts implements Database.Batchable<Sobject> {
    /*
    *  String query variable
    **/
    private final String pQuery = 'SELECT Id, gf_prtcpt_act_status_ind_type__c FROM Account WHERE gf_prtcpt_act_status_ind_type__c = true' + (Test.isRunningTest()?' LIMIT 1':'');

    /*
        *  @author     Global Desktop
        *  @description    batch START method
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(pQuery);
    }

    /*
        *  @author     Global Desktop
        *  @description    batch EXECUTE method
    **/
    public void execute(Database.BatchableContext batchContext, List<Account> listAccounts) {
            ActiveAccountsHandler.desactivateAccounts(listAccounts);
    }//FIN execute

    /**
    * @description 
    * @author Global Desktop | 27/4/2020 
    * @param batchContext 
    * @return void 
    **/
    public void finish(Database.BatchableContext batchContext) {

    }


}