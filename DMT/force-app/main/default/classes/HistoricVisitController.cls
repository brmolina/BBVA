/**
* @author Global Desktop
*/
public with sharing class HistoricVisitController {
/**
  * SINGLETON PATTERN
  */
  private static HistoricVisitController instance;

  /**
  * Constructor
  */
  private HistoricVisitController() {
  }

  /**
  * getInstance
  */
  public static HistoricVisitController getInstance() {//NOSONAR
    if (instance == null) {
      instance = new HistoricVisitController();
    }
    return instance;
  }

  /**
  * Devuelve fields de un objeto
  */
  @AuraEnabled
  public static String getDataVisit(String visitId,String accId) {//NOSONAR
  	final Visit__b opp = getVisitByIdAndAccount(visitId,accId);
    final List<SObject> lista = new List<SObject>();
    lista.add(opp);
    return getData(lista);
  }


  /**
  * Devuelve fields de un objeto
  */
  public static String getData(List<SObject> arrayObj) {//NOSONAR
    String allObjJSON = '{"Items": [';
    for( SObject sObj : arrayObj ) {
      if(!allObjJSON.equalsIgnoreCase('{"Items": [')) {
        allObjJSON += ', ';
      }
      final DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();
      final Map<String, Schema.SObjectField> desribedFields = describeResult.fields.getMap();
      String objJSON = '[';
      for( String fieldName :  desribedFields.keySet() ) {
        final Schema.SObjectField field = desribedFields.get( fieldName );
				final Schema.DescribeFieldResult fDesc = field.getDescribe();
        try {
          if(sObj.get(fDesc.getName()) != null) {
            if(!objJSON.equalsIgnoreCase('[') ) {
              objJSON += ', ';
            }
            objJSON += '{';
            objJSON += '"name":"'+fDesc.getName() + '", ' + '"label" : "' + fDesc.getLabel() + '","value":"' + String.valueOf(sObj.get(fDesc.getName())).replaceAll('"','').replaceAll('\n','').replaceAll('\r','') + '"';
            objJSON += '}';
          }
        } catch (SObjectException e) {
          System.debug('Info: Campo no cargado en la query ' + fDesc.getName() );
        }
      }
      objJSON += ']';
      allObjJSON += objJSON;
    }
    allObjJSON += ']}';
    System.debug( ' JSON STRING : ' + allObjJSON );
    return allObjJSON;
  }

  /**
  * Devuelve una opportunity por id opp y id account
  */
  @AuraEnabled
  public static Visit__b getVisitByIdAndAccount(String optyId,String accId  ) {//NOSONAR
    try {
      final List <Visit__b> lstOfOpportunity = [SELECT Business_line_desc__c, CreatedDate__c, CurrencyIsoCode__c, DES_Client_Type__c, EMPLOYEE_DEPARTMENT_DESC__c, Entity_name__c, Id__c, Name__c, Owner__c,
                                                coverage_country_name__c, disclosure_info_type__c, dwp_kitv_Main_Contact__c, dwp_kitv_TravelTime__c, dwp_kitv_account_id__c, dwp_kitv_country_name__c,
                                                dwp_kitv_event_changed_bool__c, dwp_kitv_region_name__c, dwp_kitv_solution_name_path_desc__c, dwp_kitv_visit_channel__c, dwp_kitv_visit_desc__c,
                                                dwp_kitv_visit_duration_number__c, dwp_kitv_visit_end_date__c, dwp_kitv_visit_location_desc__c, dwp_kitv_visit_purpose_type__c, dwp_kitv_visit_start_date__c,
                                                dwp_kitv_visit_status_type__c, dwp_kitv_visit_summary_desc__c, gf_comm_plan_visit_ind_type__c, gf_visit_users_products_desc__c, sustainable_finance_ind_type__c,
                                                user_country__c, visit_type__c, Attendees__c, Opportunities__c, DES_AccountName__c  FROM Visit__b WHERE dwp_kitv_account_id__c = :accId and Id__c = :optyId ];
      Visit__b opp;
      opp = new Visit__b();
      if(!lstOfOpportunity.isEmpty()) {
          opp = lstOfOpportunity.get(0);
      }
      return opp;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }
}