/*
* Controller of HistoricOpps and HistoricOppLineItems cmps
*/
public with sharing class HistoricOppsCnt {
  /**
  * SINGLETON PATTERN
  */
  private static HistoricOppsCnt instance;

  /**
  * Constructor
  */
  private HistoricOppsCnt() {
  }

  /**
  * getInstance
  */
  public static HistoricOppsCnt gtInstance() {//NOSONAR
    if (instance == null) {
      instance = new HistoricOppsCnt();
    }
    return instance;
  }

  /*
  * @author Global Desktop
  * @description Recupera los productos de las oportunidades
  */
  @AuraEnabled
  public static String getProducts(String oppId) {
    try {
      final List<OpportunityLineItem__b> historicOlis = new List<OpportunityLineItem__b>([
        SELECT OpportunityLineItemId__c, OpportunityId__c, DES_Product_Family__c, solution_classification_desc__c
        FROM OpportunityLineItem__b
        WHERE OpportunityId__c = :oppId
      ]);
      return JSON.serialize(historicOlis);
    } catch(Exception exc) {
      throw new AuraHandledException(Label.DES_Error + exc);
    }
  }

  /*
  * @author Global Desktop
  * @description Recupera las oportunidades relacionadas
  */
  @AuraEnabled
  public static String getOpps(Integer tableSize, String accId) {
    try {
      final Schema.DescribeFieldResult fieldResult = Opportunity.DES_Booking_Geography__c.getDescribe();
      final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
      final Map<String,String> mapValueLabel = new Map<String,String>();
      for( Schema.PicklistEntry v : values) {
          mapValueLabel.put(v.getValue(),v.getLabel());
      }
      system.debug('Valor de mapValueLabel: ' +mapValueLabel);

      final List<Opportunity__b> historicOpps = new List<Opportunity__b>([
        SELECT Name__c, Id__c, StageName__c, DES_Booking_Geography__c, DES_Expected_Probability__c, DES_Client_Text__c,
        CloseDate__c, Owner__c, DES_Expected_Revenues__c, pre_oppy_revenue_next_12m_amount__c, AccountId__c, DES_Date_Won_Lost__c, disclosure_info_type__c
        FROM Opportunity__b
        WHERE AccountId__c = :accId
      ]);
      List<WrapperClass> listWrapperClass = new List<WrapperClass>();
      for(Opportunity__b opp : historicOpps) {
        listWrapperClass.add(new WrapperClass(opp, mapValueLabel.get(opp.DES_Booking_Geography__c), historicOpps.size()));
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
    private String oppUrl; //NOSONAR
    /*
    * Attribute
    */
    private String accUrl; //NOSONAR
    /*
    * Attribute
    */
    private String oppName; //NOSONAR
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
    private DateTime closingDate; //NOSONAR
    /*
    * Attribute
    */
    private String disclosure; //NOSONAR
    /*
    * Attribute
    */
    private Decimal potentialRevenue; //NOSONAR
    /*
    * Attribute
    */
    private String expProb; //NOSONAR
    /*
    * Attribute
    */
     @Testvisible
    private String oppCountry; //NOSONAR
    /*
    * Attribute
    */
    private Integer oppNumber; //NOSONAR
    /**
    * @author Global Desktop
    * @description Construye lista wrapper
    */
    public WrapperClass(Opportunity__b opp, String country, Integer oppNumber) {
      this.oppUrl = '/lightning/cmp/c__HistoricOppAccount?c__accountId=' + opp.AccountId__c + '&c__oppId=' + opp.Id__c;
      this.accUrl = '/lightning/r/Account/' + opp.AccountId__c + '/view';
      this.oppName = opp.Name__c;
      this.accName = opp.DES_Client_Text__c;
      this.status = opp.StageName__c;
      this.disclosure = opp.disclosure_info_type__c;
      this.closingDate = opp.DES_Date_Won_Lost__c;
      this.oppCountry = country;
      this.potentialRevenue = opp.pre_oppy_revenue_next_12m_amount__c;
      this.oppNumber = oppNumber;
      this.expProb = opp.DES_Expected_Probability__c == null ? '' : String.valueOf(opp.DES_Expected_Probability__c + '%');
    }
  }
}