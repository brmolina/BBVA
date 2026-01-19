public class Batch_UpdateSubsidiary_Total_Won_opps implements Database.Batchable<Sobject>, Database.Stateful {
 /*
  * Query attribute
  */
  private final String query = 'SELECT id, name, customer_open_oppy_number__c, customer_open_oppy_amount__c, RecordType.DeveloperName, customer_won_oppy_number__c, customer_won_oppy_amount__c, business_group_id__c, DES_Global_banker__c, DES_Country_of_Management__c, DES_Group_Code__c, DES_Structure_Type__c FROM Account WHERE DES_Structure_Type__c != null ' + (Test.isRunningTest()?' LIMIT 1':'');

  /*
  *Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public Batch_UpdateSubsidiary_Total_Won_opps() {
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
	final List<Account> accsUpdate = new List<Account>();
    final Set <Id> accsIds = new Set <Id>();
    Desktop_Utils utils = Desktop_Utils.getInstance();
    for(Account acc : listAccount) {
        acc.customer_open_oppy_number__c = 0;
        acc.customer_open_oppy_amount__c = 0;
        acc.customer_won_oppy_number__c = 0;
        acc.customer_won_oppy_amount__c = 0;

        mapDenorm.put(acc.id, acc);
        if(!accsIds.contains(acc.Id)) {
        	accsIds.add(acc.Id);
        }
    }
      
   final List<DES_Subsidiary_Group_Relation__c> subsidiaryGroupRelation = [SELECT Id FROM DES_Subsidiary_Group_Relation__c limit 1]; 
   Boolean hasSubsidiaryGroupRelations = !subsidiaryGroupRelation.isEmpty();
   final Map<Id, DES_Subsidiary_Group_Relation__c > subsidiaryGroup = new Map <Id, DES_Subsidiary_Group_Relation__c >();

        for(DES_Subsidiary_Group_Relation__c matrix : [SELECT Id, participant_parent_id__c, participant_child_id__c , participant_parent_id__r.DES_Global_banker__c, participant_parent_id__r.DES_Group_Code__c, participant_parent_id__r.DES_Country_of_Management__c
        FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c  IN :accsIds AND main_subsidiary_ind_type__c = true]) {
            if(subsidiaryGroup.get(matrix.participant_child_id__c ) == null) {
                subsidiaryGroup.put(matrix.participant_child_id__c , matrix);
            }
        }

        for(Account acc : listAccount) {
            if(subsidiaryGroup.get(acc.Id) != null) {
                acc.business_group_id__c = subsidiaryGroup.get(acc.Id).participant_parent_id__c;
                acc.group_global_banker_user_id__c = subsidiaryGroup.get(acc.Id).participant_parent_id__r.DES_Global_banker__c;
                acc.group_management_country_id__c = subsidiaryGroup.get(acc.Id).participant_parent_id__r.DES_Country_of_Management__c;
                acc.DES_Subsidiary_Group_Code__c = subsidiaryGroup.get(acc.Id).participant_parent_id__r.DES_Group_Code__c;
            } else if(acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Supragroup
                || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Group
                || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Subgroup
                || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Shared_Manag_Group) {
                    acc.business_group_id__c = null;
                    acc.group_global_banker_user_id__c = acc.DES_Global_banker__c;
                    acc.group_management_country_id__c = acc.DES_Country_of_Management__c;
                    acc.DES_Subsidiary_Group_Code__c = acc.DES_Group_Code__c;
            } else if (hasSubsidiaryGroupRelations){
                //No debe ejecutarse esta parte si por algún fallo de carga no se generado ningún registro del objeto DES_Subsidiary_Group_Relation__c
                acc.business_group_id__c = null;
                acc.group_global_banker_user_id__c = null;
                acc.group_management_country_id__c = null;
                acc.DES_Subsidiary_Group_Code__c = null;
            }
            accsUpdate.add(acc);
        }

        if(!accsUpdate.isEmpty()) {
            system.debug(':::::: objList A Actualizar : ' + accsUpdate);
            utils.upsertWithRetry(accsUpdate, 'update');
        }
      
	/// Parte Total Won Opps
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
    
    if(!mapDenorm.isEmpty()) {
        system.debug('::::: objList A Actualizar : ' + mapDenorm.values());
        utils.upsertWithRetry(mapDenorm.values(), 'update');
    }

   
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