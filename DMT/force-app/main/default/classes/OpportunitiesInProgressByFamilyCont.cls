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
        for(dwp_acmh__GBL_Account_Relationship__c acc : [SELECT Id, dwp_acmh__Child_Account__c, dwp_acmh__Parent_Account__c
                                                        FROM dwp_acmh__GBL_Account_Relationship__c
                                                        WHERE dwp_acmh__Child_Account__c IN :childrenByParent
                                                          AND dwp_acmh__Child_Account__r.DES_Country_Client__c = :countryDevName]) {
		        if(acc.dwp_acmh__Child_Account__c != null) {
	          		childrenCountry.add(acc.dwp_acmh__Child_Account__c);
		        }
		        if(acc.dwp_acmh__Parent_Account__c != null) {
	      			childrenCountry.add(acc.dwp_acmh__Parent_Account__c);
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
    List<dwp_acmh__Denorm_Account_Opportunity__c> relatedOpps = new List<dwp_acmh__Denorm_Account_Opportunity__c>();


    if(trueCondition(country)) {
      final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('LABEL');
      final String countryDevName = mapContryCodes.get(country);
      final Set<Id> childrenCountry = new Set<Id>();
      final List<Id> childrenByParent = new List<Id>();

      for(Account acc : [SELECT Id FROM Account WHERE DES_Main_Parent__c = :accId]) {
          childrenByParent.add(acc.Id);
      }

      if(!childrenByParent.isEmpty()) {
        for(dwp_acmh__GBL_Account_Relationship__c acc : [SELECT Id, dwp_acmh__Child_Account__c, dwp_acmh__Parent_Account__c
                                                        FROM dwp_acmh__GBL_Account_Relationship__c
                                                        WHERE dwp_acmh__Child_Account__c IN :childrenByParent
                                                          AND dwp_acmh__Child_Account__r.DES_Country_Client__c = :countryDevName]) {
          //FILTRAR MAS EN QUERY PARA QUE NO SALGAN LAS PROPIAS DEL PADRE SUPREMO???
            if(acc.dwp_acmh__Child_Account__c != null) {
              childrenCountry.add(acc.dwp_acmh__Child_Account__c);
            }
            if(acc.dwp_acmh__Parent_Account__c != null) {
              childrenCountry.add(acc.dwp_acmh__Parent_Account__c);
            }

        }
      }
      System.debug('::::::::::::::::::::childrenCountry:::: ' + JSON.serialize(childrenCountry));
      childrenCountry.remove(accId);
      System.debug('::::::::::::::::::::childrenCountry sin parent:::: ' + JSON.serialize(childrenCountry));

      relatedOpps = [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId,   //NOSONAR
  					  dwp_acmh__OpportunityId__r.Account.Name,
	                  dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c), dwp_acmh__OpportunityId__r.CloseDate, dwp_acmh__OpportunityId__r.DES_Expected_Probability__c,
	                  dwp_acmh__OpportunityId__r.DES_Booking_Geography__c, dwp_acmh__AccountId__r.DES_Country_Client__c, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c)
	                  FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c IN :childrenCountry
	                  AND (dwp_acmh__AccountId__r.DES_Country_Client__c = :countryDevName OR dwp_acmh__AccountId__r.DES_Country__c = :country)
	                  AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
	                  AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
	                  ORDER BY dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c DESC];
      System.debug('::::::::::::::::::::relatedOpps:::: ' + JSON.serialize(relatedOpps));

      if(!relatedOpps.isEmpty()) {

          Map<String, dwp_acmh__Denorm_Account_Opportunity__c> mapOppDac = new Map<String, dwp_acmh__Denorm_Account_Opportunity__c>();
          for(dwp_acmh__Denorm_Account_Opportunity__c dac : relatedOpps) {
              if(!mapOppDac.containsKey(dac.dwp_acmh__OpportunityId__c)) {
                mapOppDac.put(dac.dwp_acmh__OpportunityId__c, dac);
              }
          }
          if(!mapOppDac.isEmpty()) {
              relatedOpps = mapOppDac.values();
          }
      }
    } else if(family == null || String.isBlank(family) || family == 'All' || family == 'Todos') {
      System.debug('::::::::::NO hay country! : ' + country);
      relatedOpps = [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name, //NOSONAR
                    dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c), dwp_acmh__OpportunityId__r.CloseDate,
                    dwp_acmh__OpportunityId__r.DES_Booking_Geography__c, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.DES_Expected_Probability__c
                    FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :accId
                    AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
                    AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
                    ORDER BY dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c DESC];
    } else {
    	relatedOpps = [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name, //NOSONAR
                    dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c), dwp_acmh__OpportunityId__r.CloseDate,
                    dwp_acmh__OpportunityId__r.DES_Booking_Geography__c, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.DES_Expected_Probability__c
                    FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :accId
                    AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
                    AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
                    AND dwp_acmh__OpportunityId__c in (select OpportunityId from OpportunityLineItem a where DES_Product_Family__c  = :family)
                    ORDER BY dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c DESC];
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
    for(dwp_acmh__Denorm_Account_Opportunity__c i :relatedOpps) {
    	String labelCountry;
    	labelCountry = mapValueLabel.get(i.dwp_acmh__OpportunityId__r.DES_Booking_Geography__c);
    	system.debug('Valor de labelCountry: ' +labelCountry);

          listWrapperClass.add(new wrapperClass(i, labelCountry, oppNumber));
        system.debug('Valor de i.dwp_acmh__OpportunityId__r.Name: ' +i.dwp_acmh__OpportunityId__r.Name);
        system.debug('Valor de i.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c: ' +i.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c);
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
    public wrapperClass(dwp_acmh__Denorm_Account_Opportunity__c opp, String country, Integer oppNumber) {
        this.oppUrl = '/lightning/r/Opportunity/' + opp.dwp_acmh__OpportunityId__c + '/view';
        this.accUrl = '/lightning/r/Account/' + opp.dwp_acmh__OpportunityId__r.AccountId + '/view';
        this.oppName = opp.dwp_acmh__OpportunityId__r.Name;
        this.accName = opp.dwp_acmh__OpportunityId__r.Account.Name;
        this.status = opp.dwp_acmh__OpportunityId__r.StageName;
        this.expectedRevenue = opp.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c;
        this.closingDate = opp.dwp_acmh__OpportunityId__r.CloseDate;
        this.oppCountry = country;
        this.oppNumber = oppNumber;
        this.potentialRevenue = opp.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c;
        this.expProb = opp.dwp_acmh__OpportunityId__r.DES_Expected_Probability__c == null ? '' : String.valueOf(opp.dwp_acmh__OpportunityId__r.DES_Expected_Probability__c + '%');
    }
  }
}