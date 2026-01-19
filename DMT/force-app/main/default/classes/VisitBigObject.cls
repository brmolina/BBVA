/**
* @author Global Desktop
*/
public with sharing class VisitBigObject  implements Database.Batchable<Sobject>, Database.Stateful {
  /* Two years Date */
  //private Date twoYears = Date.newInstance(date.today().year()-2, 1, 1); //NOSONAR
  /* Se cambia para poder historificar en Big Object a los 3 años en luar de a los 2 */
  private Date threeYears = Date.newInstance(date.today().year()-3, 1, 1); //NOSONAR
  /* Query */
  private String fieldsToSave = ''; //NOSONAR
  /* Query */
  private String pQuery = ''; //NOSONAR
  /* Query */
  private Set<Id> visitsIds = new Set<Id>(); //NOSONAR

  /*
  * Constructor
  */
  public VisitBigObject() {
    this.fieldsToSave += 'Owner.Name, Name, CurrencyIsoCode, CreatedDate, dwp_kitv__account_id__c, dwp_kitv__account_id__r.Name, dwp_kitv__event_changed_bool__c, toLabel(dwp_kitv__visit_channel__c), dwp_kitv__visit_desc__c';
    this.fieldsToSave += ', dwp_kitv__visit_duration_number__c, dwp_kitv__visit_end_date__c, dwp_kitv__visit_location_desc__c, toLabel(dwp_kitv__visit_purpose_type__c), dwp_kitv__visit_start_date__c';
    this.fieldsToSave += ', toLabel(dwp_kitv__visit_status_type__c), dwp_kitv__visit_summary_desc__c, DES_Client_Type__c, EMPLOYEE_DEPARTMENT_DESC__c, disclosure_info_type__c';
    this.fieldsToSave += ', Business_line_desc__c, coverage_country_name__c, Entity_name__c, dwp_kitv__Main_Contact__c, dwp_kitv__country_name__c, dwp_kitv__region_name__c, dwp_kitv__solution_name_path_desc__c';
    this.fieldsToSave += ', sustainable_finance_ind_type__c, user_country__c, visit_type__c, gf_comm_plan_visit_ind_type__c, gf_visit_users_products_desc__c';
    // Se cambia para seleccionar los regitros de más de 3 años en lugar de 2
    //this.pQuery = 'SELECT Id, (Select dwp_kitv__opportunity_id__r.AccountId, dwp_kitv__opportunity_id__c, dwp_kitv__opportunity_id__r.Name, dwp_kitv__opportunity_id__r.CreatedDate, dwp_kitv__opportunity_id__r.StageName, dwp_kitv__opportunity_id__r.Owner.Name from dwp_kitv__Visit_Topics__r where dwp_kitv__opportunity_id__c != null), (SELECT dwp_kitv__user_id__r.Name, dwp_kitv__user_id__r.Email from dwp_kitv__Visit_Management_Teams__r), (SELECT dwp_kitv__contact_id__r.Name, dwp_kitv__contact_id__r.Email_ExternalID__c from dwp_kitv__Visit_Contacts__r), '+ this.fieldsToSave + ' FROM dwp_kitv__Visit__c ' + (Test.isRunningTest() ? 'LIMIT 1' : 'WHERE CreatedDate < :twoYears AND dwp_kitv__account_id__c != null AND (disclosure_info_type__c = null OR disclosure_info_type__c = \'Not applicable\' OR disclosure_info_type__c = \'Confidential information\') AND Committee_id__c = null'); //NOSONAR
    this.pQuery = 'SELECT Id, (Select dwp_kitv__opportunity_id__r.AccountId, dwp_kitv__opportunity_id__c, dwp_kitv__opportunity_id__r.Name, dwp_kitv__opportunity_id__r.CreatedDate, dwp_kitv__opportunity_id__r.StageName, dwp_kitv__opportunity_id__r.Owner.Name from dwp_kitv__Visit_Topics__r where dwp_kitv__opportunity_id__c != null), (SELECT dwp_kitv__user_id__r.Name, dwp_kitv__user_id__r.Email from dwp_kitv__Visit_Management_Teams__r), (SELECT dwp_kitv__contact_id__r.Name, dwp_kitv__contact_id__r.Email_ExternalID__c from dwp_kitv__Visit_Contacts__r), '+ this.fieldsToSave + ' FROM dwp_kitv__Visit__c ' + (Test.isRunningTest() ? 'LIMIT 1' : 'WHERE CreatedDate < :threeYears AND dwp_kitv__account_id__c != null AND (disclosure_info_type__c = null OR disclosure_info_type__c = \'Not applicable\' OR disclosure_info_type__c = \'Confidential information\') AND Committee_id__c = null'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('threeYears: ' + threeYears);
    system.debug('Query: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<dwp_kitv__Visit__c> scope) { //NOSONAR
    final List<Visit__b> bigVisits = new List<Visit__b>();
    for(dwp_kitv__Visit__c visit : scope) {
      String attendees = '';
      String opportunities = '';
      visitsIds.add(visit.Id);
      attendees = informAttendees(visit.dwp_kitv__Visit_Management_Teams__r);
      for(dwp_kitv__Visit_Contact__c iVisContact : visit.dwp_kitv__Visit_Contacts__r) {
        attendees += 'con' + ';' + iVisContact.dwp_kitv__contact_id__r.Name + ';' + (iVisContact.dwp_kitv__contact_id__r.Email_ExternalID__c == null ? '' : iVisContact.dwp_kitv__contact_id__r.Email_ExternalID__c) + '//';
      }
      for(dwp_kitv__Visit_Topic__c iVisTopic : visit.dwp_kitv__Visit_Topics__r) {
        opportunities += iVisTopic.dwp_kitv__opportunity_id__r.Name + ';' + iVisTopic.dwp_kitv__opportunity_id__c + ';' + iVisTopic.dwp_kitv__opportunity_id__r.StageName + ';' + (iVisTopic.dwp_kitv__opportunity_id__r.AccountId == null ? '' : iVisTopic.dwp_kitv__opportunity_id__r.AccountId) + ';' + iVisTopic.dwp_kitv__opportunity_id__r.CreatedDate + ';' + iVisTopic.dwp_kitv__opportunity_id__r.Owner.Name + '//';
      }
      final Visit__b bigVisit = new Visit__b();
      bigVisit.Attendees__c = attendees == '' ? '' : attendees.substring(0,attendees.length()-2);
      bigVisit.Opportunities__c = opportunities == '' ? '' : opportunities.substring(0,opportunities.length()-2);
      bigVisit.Owner__c = visit.Owner.Name;
      bigVisit.Id__c = visit.Id;
      bigVisit.Name__c = visit.Name;
      bigVisit.CurrencyIsoCode__c = visit.CurrencyIsoCode;
      bigVisit.CreatedDate__c = visit.CreatedDate;
      bigVisit.dwp_kitv_account_id__c = visit.dwp_kitv__account_id__c;
      bigVisit.dwp_kitv_event_changed_bool__c = isBoolean(visit.dwp_kitv__event_changed_bool__c);
      bigVisit.dwp_kitv_visit_channel__c = visit.dwp_kitv__visit_channel__c;
      bigVisit.dwp_kitv_visit_desc__c = visit.dwp_kitv__visit_desc__c;
      bigVisit.dwp_kitv_visit_duration_number__c = visit.dwp_kitv__visit_duration_number__c;
      bigVisit.dwp_kitv_visit_end_date__c = visit.dwp_kitv__visit_end_date__c;
      bigVisit.dwp_kitv_visit_location_desc__c = visit.dwp_kitv__visit_location_desc__c;
      bigVisit.dwp_kitv_visit_purpose_type__c = visit.dwp_kitv__visit_purpose_type__c;
      bigVisit.dwp_kitv_visit_start_date__c = visit.dwp_kitv__visit_start_date__c;
      bigVisit.dwp_kitv_visit_status_type__c = visit.dwp_kitv__visit_status_type__c;
      bigVisit.dwp_kitv_visit_summary_desc__c = visit.dwp_kitv__visit_summary_desc__c;
      bigVisit.DES_Client_Type__c = visit.DES_Client_Type__c;
      bigVisit.EMPLOYEE_DEPARTMENT_DESC__c = visit.EMPLOYEE_DEPARTMENT_DESC__c;
      bigVisit.disclosure_info_type__c = visit.disclosure_info_type__c;
      bigVisit.Business_line_desc__c = visit.Business_line_desc__c;
      bigVisit.coverage_country_name__c = visit.coverage_country_name__c;
      bigVisit.Entity_name__c = visit.Entity_name__c;
      bigVisit.dwp_kitv_Main_Contact__c = visit.dwp_kitv__Main_Contact__c;
      bigVisit.dwp_kitv_country_name__c = visit.dwp_kitv__country_name__c;
      bigVisit.dwp_kitv_region_name__c = visit.dwp_kitv__region_name__c;
      bigVisit.dwp_kitv_solution_name_path_desc__c = visit.dwp_kitv__solution_name_path_desc__c;
      bigVisit.sustainable_finance_ind_type__c = isBoolean(visit.sustainable_finance_ind_type__c);
      bigVisit.user_country__c = visit.user_country__c;
      bigVisit.visit_type__c = visit.visit_type__c;
      bigVisit.gf_visit_users_products_desc__c = visit.gf_visit_users_products_desc__c;
      bigVisit.gf_comm_plan_visit_ind_type__c = isBoolean(visit.gf_comm_plan_visit_ind_type__c);
      bigVisit.DES_AccountName__c = visit.dwp_kitv__account_id__r.Name;
      bigVisits.add(bigVisit);
    }
    if(!Test.isRunningTest()) { //NOSONAR
      database.insertImmediate(bigVisits);
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    Database.executeBatch(new VisitsEventDelete(visitsIds, 'dwp_kitv__visit_id__c', 'Visit'), 100);
  }

  /*
  * informAttendees method
  */
  private String informAttendees(List<dwp_kitv__Visit_Management_Team__c> members) {
    String attendees = '';
    for(dwp_kitv__Visit_Management_Team__c iVisMember : members) {
      attendees += 'us' + ';' + iVisMember.dwp_kitv__user_id__r.Name + ';' + iVisMember.dwp_kitv__user_id__r.Email + '//';
    }
    return attendees;
  }

  /*
  * getExecuteBatchSize method
  */
  private String isBoolean(Boolean value) {
    return value ? 'true' : 'false';
  }
}