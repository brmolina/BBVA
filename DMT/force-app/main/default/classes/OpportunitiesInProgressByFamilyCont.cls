/*
* @author Global Desktop
* @description Clase del componente lightning OpportunitiesInProgressByFamily de la ficha de grupo.
*/
public  with sharing class OpportunitiesInProgressByFamilyCont {

  /*
  * @author Global Desktop
  * @description Recupera los id de las cuentas hijas relacionadas
  */
  public static set<Id> getFieldLabels(String accId, String country) {

      final Set<Id> childrenCountry = new Set<Id>();
      final List<Id> childrenByParent = new List<Id>();
      for(Account acc : [SELECT Id FROM Account WHERE DES_Main_Parent__c = :accId]) {
        childrenByParent.add(acc.Id);
        }

        if(!childrenByParent.isEmpty() && country != 'All') {
      final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('LABEL');
      final String countryDevName = mapContryCodes.get(country);
        for(AMH_GBL_Account_Relationship__c acc : [SELECT Id, AMH_Child_Account__c, AMH_Parent_Account__c
                                                        FROM AMH_GBL_Account_Relationship__c
                                                        WHERE AMH_Child_Account__c IN :childrenByParent
                                                          AND AMH_Child_Account__r.DES_Country_Client__c = :countryDevName]) {
            if(acc.AMH_Child_Account__c != null) {
                childrenCountry.add(acc.AMH_Child_Account__c);
            }
            if(acc.AMH_Parent_Account__c != null) {
              childrenCountry.add(acc.AMH_Parent_Account__c);
            }
        }
      }
      childrenCountry.remove(accId);
      return childrenCountry;
  }

  /*
    * @author Global Desktop
    * @description Method auxiliar para comprobar una condicion negativa
    */
  private static boolean trueCondition (String country) {
    Boolean isTrue = false;
    if(country != null && country != '' && country != 'Todos' && country != 'All') {
      isTrue = true;
    }
    return isTrue;
  }

  /*
  * @author Global Desktop
  * @description Recupera las oportunidades relacionadas
  */
  @auraEnabled
  public static String getRelatedOpportunities(String tableSize, String accId, String family, String country) {
    List<AMH_Denorm_Account_Opportunity__c> relatedOpps = new List<AMH_Denorm_Account_Opportunity__c>();


    if(trueCondition(country)) {
      final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('LABEL');
      final String countryDevName = mapContryCodes.get(country);
      final Set<Id> childrenCountry = new Set<Id>();
      final List<Id> childrenByParent = new List<Id>();

      for(Account acc : [SELECT Id FROM Account WHERE DES_Main_Parent__c = :accId]) {
          childrenByParent.add(acc.Id);
      }

      if(!childrenByParent.isEmpty()) {
        for(AMH_GBL_Account_Relationship__c acc : [SELECT Id, AMH_Child_Account__c, AMH_Parent_Account__c
                                                        FROM AMH_GBL_Account_Relationship__c
                                                        WHERE AMH_Child_Account__c IN :childrenByParent
                                                          AND AMH_Child_Account__r.DES_Country_Client__c = :countryDevName]) {
          //FILTRAR MAS EN QUERY PARA QUE NO SALGAN LAS PROPIAS DEL PADRE SUPREMO???
            if(acc.AMH_Child_Account__c != null) {
              childrenCountry.add(acc.AMH_Child_Account__c);
            }
            if(acc.AMH_Parent_Account__c != null) {
              childrenCountry.add(acc.AMH_Parent_Account__c);
            }

        }
      }
      System.debug('::::::::::::::::::::childrenCountry:::: ' + JSON.serialize(childrenCountry));
      childrenCountry.remove(accId);
      System.debug('::::::::::::::::::::childrenCountry sin parent:::: ' + JSON.serialize(childrenCountry));

      relatedOpps = [SELECT Name, AMH_OpportunityId__c, AMH_OpportunityId__r.Name, AMH_OpportunityId__r.AccountId,   //NOSONAR
              AMH_OpportunityId__r.Account.Name,
                    AMH_OpportunityId__r.StageName, convertCurrency(AMH_OpportunityId__r.DES_Expected_Revenues__c), AMH_OpportunityId__r.CloseDate, AMH_OpportunityId__r.DES_Expected_Probability__c,
                    AMH_OpportunityId__r.DES_Booking_Geography__c, AMH_AccountId__r.DES_Country_Client__c, convertCurrency(AMH_OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
                    FROM AMH_Denorm_Account_Opportunity__c WHERE AMH_AccountId__c IN :childrenCountry
                    AND (AMH_AccountId__r.DES_Country_Client__c = :countryDevName OR AMH_AccountId__r.DES_Country__c = :country)
                    AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Won
                    AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Lose
                    ORDER BY AMH_OpportunityId__r.DES_Expected_Revenues__c DESC];
      System.debug('::::::::::::::::::::relatedOpps:::: ' + JSON.serialize(relatedOpps));

      if(!relatedOpps.isEmpty()) {

          Map<String, AMH_Denorm_Account_Opportunity__c> mapOppDac = new Map<String, AMH_Denorm_Account_Opportunity__c>();
          for(AMH_Denorm_Account_Opportunity__c dac : relatedOpps) {
              if(!mapOppDac.containsKey(dac.AMH_OpportunityId__c)) {
                mapOppDac.put(dac.AMH_OpportunityId__c, dac);
              }
          }
          if(!mapOppDac.isEmpty()) {
              relatedOpps = mapOppDac.values();
          }
      }
    } else if(family == null || String.isBlank(family) || family == 'All' || family == 'Todos') {
      System.debug('::::::::::NO hay country! : ' + country);
      relatedOpps = [SELECT Name, AMH_OpportunityId__c, AMH_OpportunityId__r.Name, AMH_OpportunityId__r.AccountId, AMH_OpportunityId__r.Account.Name, //NOSONAR
                    AMH_OpportunityId__r.StageName, convertCurrency(AMH_OpportunityId__r.DES_Expected_Revenues__c), AMH_OpportunityId__r.CloseDate,
                    AMH_OpportunityId__r.DES_Booking_Geography__c, convertCurrency(AMH_OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), AMH_OpportunityId__r.DES_Expected_Probability__c
                    FROM AMH_Denorm_Account_Opportunity__c WHERE AMH_AccountId__c = :accId
                    AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Won
                    AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Lose
                    ORDER BY AMH_OpportunityId__r.DES_Expected_Revenues__c DESC];
    } else {
      relatedOpps = [SELECT Name, AMH_OpportunityId__c, AMH_OpportunityId__r.Name, AMH_OpportunityId__r.AccountId, AMH_OpportunityId__r.Account.Name, //NOSONAR
                    AMH_OpportunityId__r.StageName, convertCurrency(AMH_OpportunityId__r.DES_Expected_Revenues__c), AMH_OpportunityId__r.CloseDate,
                    AMH_OpportunityId__r.DES_Booking_Geography__c, convertCurrency(AMH_OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), AMH_OpportunityId__r.DES_Expected_Probability__c
                    FROM AMH_Denorm_Account_Opportunity__c WHERE AMH_AccountId__c = :accId
                    AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Won
                    AND AMH_OpportunityId__r.StageName != :Label.DES_Closed_Lose
                    AND AMH_OpportunityId__c in (select OpportunityId from OpportunityLineItem a where DES_Product_Family__c  = :family)
                    ORDER BY AMH_OpportunityId__r.DES_Expected_Revenues__c DESC];
    }

    final Integer oppNumber = relatedOpps.size();
    Integer tSize;
    if(tableSize != null) {
      tSize = Integer.valueOf(tableSize);
    }

  final Schema.DescribeFieldResult fieldResult = Opportunity.DES_Booking_Geography__c.getDescribe();
  final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
  final Map<String,String> mapValueLabel = new Map<String,String>();
  for( Schema.PicklistEntry v : values) {
      mapValueLabel.put(v.getValue(),v.getLabel());
  }
  system.debug('Valor de mapValueLabel: ' +mapValueLabel);


    final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
    for(AMH_Denorm_Account_Opportunity__c i :relatedOpps) {
      String labelCountry;
      labelCountry = mapValueLabel.get(i.AMH_OpportunityId__r.DES_Booking_Geography__c);
      system.debug('Valor de labelCountry: ' +labelCountry);

          listWrapperClass.add(new wrapperClass(i, labelCountry, oppNumber));
        system.debug('Valor de i.AMH_OpportunityId__r.Name: ' +i.AMH_OpportunityId__r.Name);
        system.debug('Valor de i.AMH_OpportunityId__r.DES_Expected_Revenues__c: ' +i.AMH_OpportunityId__r.DES_Expected_Revenues__c);
    }

      if(tSize != null) {
        List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
          Integer regTable = tSize;
          if(tSize > listWrapperClass.size()) {
            regTable = listWrapperClass.size();
          }
          for(Integer cn = 0; cn < regTable ; cn++) {
            if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
              listaWrapperAux.add(listWrapperClass.get(cn));
            }
          }
          return JSON.serialize(listaWrapperAux);
      } else {
        system.debug('>>>>> listWrapperClass tSize NULL : ' + listWrapperClass);
        return JSON.serialize(listWrapperClass);
      }

    }

  /**
    * @author Global Desktop
    * @description clase para construir lista wrapper
    */
    public class wrapperClass {
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
      private Date closingDate; //NOSONAR
      /*
      * Attribute
      */
      private Decimal expectedRevenue; //NOSONAR
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
      private integer oppNumber; //NOSONAR

      /**
      * @author Global Desktop
      * @description Construye lista wrapper
      */
    public wrapperClass(AMH_Denorm_Account_Opportunity__c opp, String country, Integer oppNumber) {
        this.oppUrl = '/lightning/r/Opportunity/' + opp.AMH_OpportunityId__c + '/view';
        this.accUrl = '/lightning/r/Account/' + opp.AMH_OpportunityId__r.AccountId + '/view';
        this.oppName = opp.AMH_OpportunityId__r.Name;
        this.accName = opp.AMH_OpportunityId__r.Account.Name;
        this.status = opp.AMH_OpportunityId__r.StageName;
        this.expectedRevenue = opp.AMH_OpportunityId__r.DES_Expected_Revenues__c;
        this.closingDate = opp.AMH_OpportunityId__r.CloseDate;
        this.oppCountry = country;
        this.oppNumber = oppNumber;
        this.potentialRevenue = opp.AMH_OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
        this.expProb = opp.AMH_OpportunityId__r.DES_Expected_Probability__c == null ? '' : String.valueOf(opp.AMH_OpportunityId__r.DES_Expected_Probability__c + '%');
    }
  }
}