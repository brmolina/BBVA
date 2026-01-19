/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de total de oportunidades de Account
* @Revision
**********************************************************************************/
public without sharing class Batch_Total_Live_Won_Opps implements Database.Batchable<Sobject>, Database.Stateful {
   /*
  * Query attribute
  */
  private final String query = 'SELECT id, name, customer_open_oppy_number__c, customer_open_oppy_amount__c, RecordType.DeveloperName, customer_won_oppy_number__c, customer_won_oppy_amount__c FROM Account WHERE DES_Structure_Type__c != null' + (Test.isRunningTest()?' LIMIT 1':'');

  /*
  *Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public Batch_Total_Live_Won_Opps() {
    system.debug('>>>>> Query: ' + query);
  }

  /*
  *Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public Database.QueryLocator start(Database.BatchableContext bc1) {
    system.debug('>>>>> query : ' + query);
    return Database.getQueryLocator(query);
  }
  /*
  *Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public void execute(Database.BatchableContext bc1, List<Account> listAccount) {
    final Map<String, Account> mapDenorm = new Map<String, Account>();

    for(Account acc : listAccount) {
        acc.customer_open_oppy_number__c = 0;
        acc.customer_open_oppy_amount__c = 0;
        acc.customer_won_oppy_number__c = 0;
        acc.customer_won_oppy_amount__c = 0;

        mapDenorm.put(acc.id, acc);
    }

    final List<dwp_acmh__Denorm_Account_Opportunity__c> lAccOpp = [SELECT id,
                                                                    dwp_acmh__AccountId__c,
                                                                    dwp_acmh__OpportunityId__c,
                                                                    convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c),
                                                                    dwp_acmh__OpportunityId__r.StageName,
                                                                    dwp_acmh__OpportunityId__r.DES_Date_Won_Lost__c,
                                                                    convertCurrency(DES_Opportunity_Potential_Revenue_Rollup__c)
                                                                    FROM dwp_acmh__Denorm_Account_Opportunity__c
                                                                    WHERE dwp_acmh__AccountId__c  IN :mapDenorm.keySet()];

    for(dwp_acmh__Denorm_Account_Opportunity__c oppDenorm : lAccOpp) {
        mapDenorm.put(oppDenorm.dwp_acmh__AccountId__c, isLiveCheck(oppDenorm, mapDenorm.get(oppDenorm.dwp_acmh__AccountId__c)));
        mapDenorm.put(oppDenorm.dwp_acmh__AccountId__c, isWonLastMonth(oppDenorm, mapDenorm.get(oppDenorm.dwp_acmh__AccountId__c)));
    }

    Database.update(mapDenorm.values(), false);

  }

  /*
  *Comprueba si viva
  */
  private Account isLiveCheck(dwp_acmh__Denorm_Account_Opportunity__c idao, Account acc) {
        if(idao.dwp_acmh__OpportunityId__r.StageName != Label.DES_Closed_Won && idao.dwp_acmh__OpportunityId__r.StageName != Label.DES_Closed_Lose && idao.dwp_acmh__OpportunityId__r.StageName != Label.DES_Draft) {
            acc.customer_open_oppy_number__c = acc.customer_open_oppy_number__c + 1;
            acc.customer_open_oppy_amount__c = acc.customer_open_oppy_amount__c + (idao.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c == null ? 0 : idao.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c);
        }
        return acc;
  }

  /*
  *Comprueba si ganada ultimo mes
  */
  private Account isWonLastMonth(dwp_acmh__Denorm_Account_Opportunity__c idao, Account acc) {
        final Date lastmonth = date.today().addmonths(-1);
        final Date firstOfLastMonth = date.newInstance(lastmonth.year(), lastmonth.month(), 1);

        final Integer numberOfDays = Date.daysInMonth(firstOfLastMonth.year(), firstOfLastMonth.month());
        final Date lastDayLastMonth = Date.newInstance(firstOfLastMonth.year(), firstOfLastMonth.month(), numberOfDays);

        if((acc.RecordType.DeveloperName == Label.DES_RT_Group || acc.RecordType.DeveloperName == Label.DES_RT_SupraGroup || acc.RecordType.DeveloperName == 'DES_Commercial_Client' || acc.RecordType.DeveloperName == 'DES_Commercial_Client_BEC_Manually') &&
        idao.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Won && idao.dwp_acmh__OpportunityId__r.DES_Date_Won_Lost__c >= firstOfLastMonth && idao.dwp_acmh__OpportunityId__r.DES_Date_Won_Lost__c <= lastDayLastMonth) {
            acc.customer_won_oppy_number__c = acc.customer_won_oppy_number__c + 1;
            acc.customer_won_oppy_amount__c = acc.customer_won_oppy_amount__c + idao.DES_Opportunity_Potential_Revenue_Rollup__c;
        }
        return acc;
  }
  /*
  *Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public void finish(Database.BatchableContext bc1) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc1.getJobId()];
    system.debug('++ job ' + job);
  }
}