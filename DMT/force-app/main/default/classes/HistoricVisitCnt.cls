/**
* @author Global Desktop
*/
public with sharing class HistoricVisitCnt {
  /**
  * SINGLETON PATTERN
  */
  private static HistoricVisitCnt instance;

  /**
  * Constructor
  */
  private HistoricVisitCnt() {
  }

  /**
  * getInstance
  */
  public static HistoricVisitCnt gtInstance() {//NOSONAR
    if (instance == null) {
      instance = new HistoricVisitCnt();
    }
    return instance;
  }

  /*
  * @author Global Desktop
  * @description Recupera los productos de las oportunidades
  */
  @AuraEnabled
  public static String gtOpps(String accountId, String visitId) {
    try {
      final List<Visit__b> historicOpps = new List<Visit__b>([
        SELECT Opportunities__c
        FROM Visit__b
        WHERE dwp_kitv_account_id__c = :accountId AND Id__c = :visitId
      ]);
      final List<WrapperOpp> listWrapperOpp = new List<WrapperOpp>();
      if(!historicOpps.isEmpty()) {
        for(String opp : historicOpps.get(0).Opportunities__c.split('//')) {
          listWrapperOpp.add(new WrapperOpp(opp.split(';').get(0), opp.split(';').get(1), opp.split(';').get(2), opp.split(';').get(3), opp.split(';').get(4), opp.split(';').get(5)));
        }
      }
      system.debug(JSON.serialize(listWrapperOpp));
      return JSON.serialize(listWrapperOpp);
    } catch(Exception exc) {
      throw new AuraHandledException(Label.DES_Error + exc);
    }
  }

  /*
  * @author Global Desktop
  * @description Recupera las oportunidades relacionadas
  */
  @AuraEnabled
  public static String gtVisits(Integer tableSize, String accId) {
    try {
      final List<Visit__b> historicVisit = new List<Visit__b>([
        SELECT Name__c, Id__c, dwp_kitv_visit_status_type__c , disclosure_info_type__c, dwp_kitv_visit_end_date__c, dwp_kitv_visit_start_date__c,
        dwp_kitv_account_id__c, dwp_kitv_visit_channel__c, DES_AccountName__c
        FROM Visit__b
        WHERE dwp_kitv_account_id__c = :accId
      ]);
      List<WrapperClass> listWrapperClass = new List<WrapperClass>();
      for(Visit__b visit : historicVisit) {
        listWrapperClass.add(new WrapperClass(visit, historicVisit.size()));
      }

      if(tableSize != null) {
        final List<WrapperClass> listaWrapperAux = new List<WrapperClass>();
        Integer regTable = tableSize;
        if(tableSize > listWrapperClass.size()) {
          regTable = listWrapperClass.size();
        }
        for(Integer cnt = 0; cnt < regTable ; cnt++) {
          if(!listWrapperClass.isEmpty() && listWrapperClass.get(cnt) != null) {
            listaWrapperAux.add(listWrapperClass.get(cnt));
          }
        }
        listWrapperClass = listaWrapperAux;
      }
      return JSON.serialize(listWrapperClass);
    } catch(Exception exc) {
      throw new AuraHandledException(Label.DES_Error + exc);
    }
  }

  /**
  * @author Global Desktop
  * @description clase para construir lista wrapper
  */
  public class WrapperClass {
    /**
    * @author Global Desktop
    * @description Variables de la clase wrapper
    */
    private String visitUrl; //NOSONAR
    /*
    * Attribute
    */
    private String visitName; //NOSONAR
    /*
    * Attribute
    */
    private String accName; //NOSONAR
    /*
    * Attribute
    */
    private String status; //NOSONAR
    /*
    * Attribute
    */
    private DateTime endDate; //NOSONAR
    /*
    * Attribute
    */
    private DateTime startDate; //NOSONAR
    /*
    * Attribute
    */
    private String disclosure; //NOSONAR
    /*
    * Attribute
    */
    private Integer visitNumber; //NOSONAR
    /**
    * @author Global Desktop
    * @description Construye lista wrapper
    */
    public WrapperClass(Visit__b visit, Integer visitNumber) {
      this.visitUrl = '/lightning/cmp/c__HistoricVisitAccount?c__accountId=' + visit.dwp_kitv_account_id__c + '&c__visitId=' + visit.Id__c;
      this.visitName = visit.Name__c;
      this.accName = visit.DES_AccountName__c;
      this.status = visit.dwp_kitv_visit_status_type__c;
      this.disclosure = visit.disclosure_info_type__c;
      this.endDate = visit.dwp_kitv_visit_end_date__c;
      this.startDate = visit.dwp_kitv_visit_start_date__c;
      this.visitNumber = visitNumber;
    }
  }

  /**
  * @author Global Desktop
  * @description clase para para lista de opps
  */
  public class WrapperOpp {
    /**
    * @author Global Desktop
    * @description Variables de la clase wrapper
    */
    private String name; //NOSONAR
    /*
    * Attribute
    */
    private String opportunityId; //NOSONAR
    /*
    * Attribute
    */
    private String stageName; //NOSONAR
    /*
    * Attribute
    */
    private String accountId; //NOSONAR
    /*
    * Attribute
    */
    private String createdDate; //NOSONAR
    /*
    * Attribute
    */
    private String owner; //NOSONAR

    /**
    * @author Global Desktop
    * @description Construye lista wrapper
    */
    public WrapperOpp(String name, String opportunityId, String stageName, String accountId, String createdDate, String owner) {
      this.name = name;
      this.opportunityId = opportunityId;
      this.stageName = stageName;
      this.accountId = accountId;
      this.createdDate = createdDate;
      this.owner = owner;
    }
  }
}