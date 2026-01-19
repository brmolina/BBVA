/******************************************************************************************************************************************************************
Name:            DES_DenormalizeVisitsExecute
Description:     Clase batch para que se invoque semanalmente desde una clase Scheduled y se vuelva a generar la tabla de VisitDenorm
                  Como posible mejora por si en el futuro hay muchas visitas, se puede reducir la Query metiendo en el WHERE por ejemplo que no seleccione si la fecha es menor de XXXX.
                  Esta mejora se podría además hacer configurable cogiendo el parámetro de un customSettings/customMetadata
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
0.1            08/05/2018      Accenture         Class creation
0.2            22/06/2018      Accenture         Update -> se añade modificación en la query para que funcione también con Visitas relacionadas con Prospects (Lead)
*******************************************************************************************************************************************************************/
public without sharing class DES_DenormalizeVisitsExecute implements Database.Batchable<Sobject>, Database.Stateful{

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  /* recordsProcessed */
  private Integer recordsProcessed = 0;
  /* relationshipsCreated */
  private Integer relationshipsCreated = 0;
  /* Two years Date */
  private final Date twoYears = Date.newInstance(date.today().year()-1, 1, 1); //NOSONAR
  /* Query */
  private final String query = 'SELECT Id, dwp_kitv__account_id__c, Name, dwp_kitv__visit_start_date__c, dwp_kitv__lead_id__c, dwp_kitv__lead_id__r.DES_Group__c FROM dwp_kitv__Visit__c Where CreatedDate > :twoYears'; //NOSONAR

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_DenormalizeVisitsExecute() {
    system.debug('Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bch) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bch, List<dwp_kitv__Visit__c> scope) {
    DES_DenormalizeVisitsUtils doUtil = new DES_DenormalizeVisitsUtils();

    for (dwp_kitv__Visit__c visit : scope) {
      relationshipsCreated = relationshipsCreated + doUtil.denormalize(visit);
      recordsProcessed++;
    }
  }

  public void finish(Database.BatchableContext bch) {
    AsyncApexJob job3 = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    system.debug(job3);
  }
}