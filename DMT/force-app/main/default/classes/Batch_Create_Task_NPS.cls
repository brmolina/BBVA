/**********************************************************************************
* @author       Global Desktop
* @date         13/07/2020
* @description  Batch para crear las tareas relacionas a las cuentas NPS
**********************************************************************************/
public with sharing class Batch_Create_Task_NPS implements Database.Batchable<Sobject>, Database.Stateful {
  /**
  * @author Global Desktop
  * @Description iQuery
  */
  private final String iQuery;
  /**
  * @author Global Desktop
  * @Description se usa para notificar al finalizar el batch
  */
  private Map<Id, Contact> mapOwnerId = new Map<Id, Contact>();
  private Map<String,String> listContactsNPSMail = new Map<String,String>();
  private Map<String,String> listGlobalBankerEmail = new Map<String,String>();

  private NPS_Wave__c iWave; //NOSONAR
  /**
  * @author Global Desktop
  * @Description listAccNPS
  */
  private List<Account> listAccNPS; //NOSONAR

  /**
  * @author Global Desktop
  * @Description constructor
  */
  public Batch_Create_Task_NPS(NPS_Wave__c iWavePar, List<Account> listNPSAccount) {
    iWave = iWavePar;
    listAccNPS = new List<Account>();
    listAccNPS.addAll(listNPSAccount);
    iQuery = 'SELECT Id, survey_nps_contact_type__c FROM Account WHERE Id IN :listAccNPS';
  }

  /**
  * @author Global Desktop
  * @Description start
  */
  public Database.QueryLocator start(Database.BatchableContext iBatchableContext) {
    return Database.getQueryLocator(iQuery);
  }

  /**
  * @author Global Desktop
  * @Description execute
  */
  public void execute(Database.BatchableContext iBatchableContext, List<Account> listAccount) {
    system.debug('Entro mapOwnerId==='+mapOwnerId.keySet().size()+' listContactsNPSMail=='+listContactsNPSMail.size()+'  listGlobalBankerEmail=='+listGlobalBankerEmail.size());

    NPS_Wave_Helper.npsNotification(new List<NPS_Wave__c> {iWave}, listAccount,listContactsNPSMail,listGlobalBankerEmail);
    Home_NPS_Wave_Cnt_Aux.loadNPSTask(mapOwnerId,listAccount, iWave);
  }

  /**
  * @author Global Desktop
  * @Description finish
  */
  public void finish(Database.BatchableContext iBatchableContext) {
    system.debug('Salio mapOwnerId==='+mapOwnerId.keySet().size()+' listContactsNPSMail=='+listContactsNPSMail.size()+'  listGlobalBankerEmail=='+listGlobalBankerEmail.size());

    Home_NPS_Wave_Cnt_Aux.createAlerts(mapOwnerId,iWave);
    final AsyncApexJob iJob = [SELECT Id,
                          Status,
                          NumberOfErrors,
                          JobItemsProcessed
                        FROM AsyncApexJob
                        WHERE Id = :iBatchableContext.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + iJob.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + iJob.NumberOfErrors);
    System.debug('>>>>>   Status: ' + iJob.Status);
  }
}