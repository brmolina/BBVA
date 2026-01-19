/**********************************************************************************
* @author  		Global Desktop
* @date         09/09/2019
* @description  Batch que asigna a las account territorios
* @Revision
**********************************************************************************/
public without sharing class AccountTerritoryDeleteBatch  implements Database.Batchable<Sobject> {
    /*
     *  @author     Global Desktop
     *
    **/
    private final String pQuery = 'select Id from AccountShare where UserOrGroupId in (select id from Group where Type = \'Territory\') and RowCause = \'Manual\'' + (Test.isRunningTest()?' LIMIT 1':'');

    /*
     *  CONSTRUCTOR
     *
    **/
    public AccountTerritoryDeleteBatch() {
        system.debug('>>>>> pQuery : ' + pQuery);
    }

    /*
     *  @author     Global Desktop
     *  @desc       START Method
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  @author     Global Desktop
     *  @desc       EXECUTE Method
    **/
    public void execute(Database.BatchableContext batchContext, List<AccountShare> listShare) {
		delete listShare;

    }//FIN execute

    /*
     *  @author     Global Desktop
     *  @desc       FINISH Method
    **/
    public void finish(Database.BatchableContext batchContext) {    }
}