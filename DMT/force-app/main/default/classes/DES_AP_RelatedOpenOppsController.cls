/**********************************************************************************
* @author       Global Desktop
* @description  DES_AP_RelatedOpenOppsController
* @Revision     
**********************************************************************************/
public with sharing class DES_AP_RelatedOpenOppsController {
    /* Declarando variable */
   public static final String WONLY = 'WonLastYear';
    /* Declarando variable */
   public static final String LOSTLY = 'LostLastYear';
    /* Declarando variable */
   public static final String WONL4M = 'WonLast4M';
    /* Declarando variable */
   public static final String LOSTL4M = 'LostLast4M';
    /* Declarando variable */
   public static final String CREATEDLY = 'CreatedLastYear';
    /* Declarando variable */
   public static final String CREATEDL4M = 'CreatedLast4M';
    
   	/*
	* @author Global Desktop
	* @description Recupera la cuenta relacionada con el Account Plan
	*/
  	@auraEnabled
  	public static String gtAPAccountId(String apId) {
        return [SELECT acpl__participant_id__c FROM acpl__Account_Planning__c WHERE Id = :apId].acpl__participant_id__c;
    }

    /*
	* @author Global Desktop
	* @description Recupera la cuenta relacionada con el Group Analysis
	*/
  	@auraEnabled
  	public static String gtGAAccountId(String gaId) {
        return [SELECT participant_id__c FROM DES_Group_Analysis__c WHERE Id = :gaId].participant_id__c;
    }

	/*
	* @author Global Desktop
	* @description Recupera las oportunidades relacionadas con la cuenta
	*/
  	@auraEnabled
  	public static String getRelatedOpportunities(String tableSize, String accId, String qType) {
	    
        // calcular la fecha de -4 meses
        final Date last4MDate = date.today().addMonths(-4);
        System.debug('last4MDate: ' + last4MDate);
		final List<dwp_acmh__Denorm_Account_Opportunity__c> relatedOpps = gtRelatedOpps(accId, qType, last4MDate);
        
        Integer oppNumber = relatedOpps.size();
	    Integer tSize;
	    if(tableSize != null){
	      tSize = Integer.valueOf(tableSize);
	    }

	    List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	    for(dwp_acmh__Denorm_Account_Opportunity__c i :relatedOpps){
	          listWrapperClass.add(new wrapperClass(i.dwp_acmh__OpportunityId__c, i.dwp_acmh__OpportunityId__r.Name, i.dwp_acmh__OpportunityId__r.AccountId,
	                                                i.dwp_acmh__OpportunityId__r.Account.Name, i.dwp_acmh__OpportunityId__r.StageName,
	                                                i.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c, i.dwp_acmh__OpportunityId__r.CloseDate,
	                                                i.dwp_acmh__OpportunityId__r.DES_Booking_Geography__c, oppNumber));
	    }

	  if(tSize != null) {
	    List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
	      Integer regTable = tSize;
	      if(tSize > listWrapperClass.size()) {
	        regTable = listWrapperClass.size();
	      }
	      for(Integer cn = 0; cn < regTable ; cn++){
	        if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
	          listaWrapperAux.add(listWrapperClass.get(cn));
	        }
	      }
	      return JSON.serialize(listaWrapperAux);
	  }else{
	    system.debug('>>>>> listWrapperClass tSize NULL : ' + listWrapperClass);
	    return JSON.serialize(listWrapperClass);
	  }
    }
    
    /*
	* @author Global Desktop
	* @description Obtiene la lista de oportunidades
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtRelatedOpps(String accId, String qType, Date last4MDate) {
        List<dwp_acmh__Denorm_Account_Opportunity__c> relatedOpps;
        relatedOpps = new List<dwp_acmh__Denorm_Account_Opportunity__c>();
        if(qType == null) {
            relatedOpps = gtNullOpp(accId);
        } else if(qType == WONL4M) {
            relatedOpps = gtWONL4MOpp(accId, last4MDate);
        } else if(qType == LOSTL4M) {
            relatedOpps = gtLOSTL4MOpp(accId, last4MDate);
        } else if(qType == WONLY) {
            relatedOpps = gtWONLYOpp(accId);
        } else if(qType == LOSTLY) {
            relatedOpps = gtLOSTLYOpp(accId);
        } else if(qType == CREATEDL4M) {
            relatedOpps = gtCREATEDL4MOpp(accId, last4MDate);
        } else if(qType == CREATEDLY) {
            relatedOpps = gtCREATEDLYOpp(accId);
        }
        return relatedOpps;
    }
    
    /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = null
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtNullOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }
    /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = WONL4M
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtWONL4MOpp(String accId, Date last4MDate) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, dwp_acmh__OpportunityId__r.DES_Date_Won_Lost__c, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.CloseDate >= :last4MDate
                AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Won
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }

   /*
	* @author Global Desktop
	* @description Recupera las oportunidades si qType = LOSTL4M
	*/
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtLOSTL4MOpp(String accId, Date last4MDate) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.CloseDate >= :last4MDate
                AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Lose
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }
    
    /*
    * @author Global Desktop
    * @description Recupera las oportunidades si qType = WONLY
    */
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtWONLYOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.CloseDate = THIS_YEAR
                AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Won
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }

    /*
    * @author Global Desktop
    * @description Recupera las oportunidades si qType = LOSTLY
    */
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtLOSTLYOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.CloseDate = THIS_YEAR
                AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Lose
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }

    /*
    * @author Global Desktop
    * @description Recupera las oportunidades si qType = CREATEDL4M
    */
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtCREATEDL4MOpp(String accId, Date last4MDate) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.CreatedDate >= :last4MDate
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }

   /*
    * @author Global Desktop
    * @description Recupera las oportunidades si qType = CREATEDLY
    */
    public static List<dwp_acmh__Denorm_Account_Opportunity__c> gtCREATEDLYOpp(String accId) {
        return [SELECT Name, dwp_acmh__OpportunityId__c, dwp_acmh__OpportunityId__r.Name, dwp_acmh__OpportunityId__r.AccountId, dwp_acmh__OpportunityId__r.Account.Name,
                dwp_acmh__OpportunityId__r.StageName, convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c), dwp_acmh__OpportunityId__r.CloseDate,
                dwp_acmh__OpportunityId__r.DES_Booking_Geography__c
                FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
                AND dwp_acmh__OpportunityId__r.CreatedDate = THIS_YEAR
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Won
                AND dwp_acmh__OpportunityId__r.StageName != :Label.DES_Closed_Lose
                ORDER BY dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c DESC];
    }

	/*
	* @author Global Desktop
	* @description clase wrapper para devolver la informacion al componente lightning
	*/
    public class wrapperClass {
	/*
    * @author Global Desktop
    * @description Declaracion de los canpos de la lista wrapper
    */
      private String oppUrl; //NOSONAR
    /*
    * wrapper field
    */
      private String accUrl; //NOSONAR
    /*
    * wrapper field
    */
      private String oppName; //NOSONAR
    /*
    * wrapper field
    */
      private String accName; //NOSONAR
    /*
    * wrapper field
    */
      private String status; //NOSONAR
    /*
    * wrapper field
    */
      private Date closingDate; //NOSONAR
    /*
    * wrapper field
    */
      private Decimal potentialRevenue; //NOSONAR
    /*
    * wrapper field
    */
      private String oppCountry; //NOSONAR
    /*
    * wrapper field
    */
      private integer oppNumber; //NOSONAR
      /*
    * @author Global Desktop
    * @description Construye la lista wrapper
    */
      public wrapperClass(Id oppId, String oppName, Id clientId, String clientName, String status, Decimal potRev, Date closDate, String country, Integer oppNumber) {
        this.oppUrl = '/lightning/r/Opportunity/' + oppId + '/view';
        this.accUrl = '/lightning/r/Account/' + clientId + '/view';
        this.oppName = oppName;
        this.accName = clientName;
        this.status = status;
        this.potentialRevenue = potRev;
        this.closingDate = closDate;
        this.oppCountry = country;
        this.oppNumber = oppNumber;
    }
  }
}