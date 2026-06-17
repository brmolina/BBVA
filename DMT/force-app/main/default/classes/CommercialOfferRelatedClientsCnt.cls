/**
* @author Global Desktop
* @description Clase del componente lightning CommercialOfferRelatedClients
*/
public with sharing class CommercialOfferRelatedClientsCnt {

    /**
	* @author Global Desktop
	* @description SINGLETON PATTERN
	*/
  	private static CommercialOfferRelatedClientsCnt instance;

  	/**
   	* @author Global Desktop
   	* @description getInstance
   	*/
  	public static CommercialOfferRelatedClientsCnt getInstance() { //NOSONAR
    	if (instance == null) {
      		instance = new CommercialOfferRelatedClientsCnt();
    	}
    	return instance;
  	}

    /*
    * Met0d0 para pasar sonar
    */
    private CommercialOfferRelatedClientsCnt() {}

    /*Met0d0 que recupera las cuentas relacionadas a la oferta comercial*/
    @AuraEnabled
    public static String getClients(String cOfferId) {
        final coff__Commercial_Offer__c cOffer = [SELECT Id, coff__participant_id__c From coff__Commercial_Offer__c WHERE Id = :cOfferId LIMIT 1];
        final set<Id> accIds = new set<Id>();
        accIds.add(cOffer.coff__participant_id__c);

        final Account accRelated = [SELECT Id, Name, DES_Client_Type__c, RecordType.DeveloperName FROM Account
                              WHERE Id = :cOffer.coff__participant_id__c LIMIT 1];

        //Grupo relacionado
        accIds.add(relGroup(accRelated));

        //Oportunidades relacionadas
        accIds.addAll(relOpps(cOfferId));
        
        //Visitas relacionadas
        accIds.addAll(relVisits(cOfferId));

        //Recupera todas las cuentas relacionadas
        final List<Account> accReturn = [SELECT Id, Name, DES_Client_Type__c, DES_Global_banker__c, toLabel(DES_Country_Client__c), g_customer_id__c,
                                   DES_Country_of_Management__c, DES_RAR_YTD__c, rar_entity_last_12m_amount__c, convertCurrency(DES_GROSS_MARGIN__c),
                                   DES_RORC_YTD__c FROM Account WHERE Id IN :accIds];
        
        
        //Construye la clase wrapper
        final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
        for(Account acc : accReturn) {
            listWrapperClass.add(new wrapperClass(acc.Id, acc.Name, acc.DES_Client_Type__c, acc.DES_Global_banker__c, acc.g_customer_id__c,
                                                 acc.DES_Country_Client__c, acc.DES_Country_of_Management__c, String.valueOf(acc.DES_RAR_YTD__c),
                                                 String.valueOf(acc.rar_entity_last_12m_amount__c), String.valueOf(acc.DES_GROSS_MARGIN__c),
                                                 String.valueOf(acc.DES_RORC_YTD__c)));
        }

        //return de las cuentas en formato json
        return JSON.serialize(listWrapperClass);
    }
    
    /*
    * Recupera el grupo relacionado a la filial de la oferta comercial
    */
    public static Id relGroup(Account acc) {
    	String idReturn = null;
    	if(acc.RecordType.DeveloperName == 'Subsidiary' || acc.RecordType.DeveloperName == 'DES_Subsidiary_Commercial_Client') {
            final List<DES_Subsidiary_Group_Relation__c> accParent = [SELECT participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c
                                                         WHERE participant_child_id__c = :acc.Id AND main_subsidiary_ind_type__c = true
                                                         LIMIT 1];
            if(accParent.isEmpty()) {
            	system.debug('Query empty');
            } else {
            	idReturn = accParent[0].participant_parent_id__c;
            }
        }
        return idReturn;
    }
    
    /*
    * Recupera los clientes asociados a las oportunidades relacionadas
    */
    public static set<Id> relOpps(String cOfferId) {
    	final set<Id> accOppsRel = new set<Id>();
    	final List<Opportunity> oppRel = [SELECT AccountId FROM Opportunity WHERE coff__gf_commercial_offer_id__c = :cOfferId];
        if(oppRel != null) {
            for(Opportunity opp : oppRel) {
            	accOppsRel.add(opp.AccountId);
            }
        }
        system.debug(accOppsRel);
        return accOppsRel;
    }
    
    /*
    * Recupera los clientes asociados a las visitas relacionadas
    */
    public static set<Id> relVisits(String cOfferId) {
    	final set<Id> aVistRel = new set<Id>();
    	final List<dwp_kitv__Visit_Topic__c> vTopicList = [SELECT dwp_kitv__visit_id__c FROM dwp_kitv__Visit_Topic__c
                                                     WHERE gf_commercial_offer_oppy_id__c = :cOfferId];
        if(vTopicList != null) {
            final set<Id> visitIds = new set<Id>();
            for(dwp_kitv__Visit_Topic__c vTopic : vTopicList) {
                visitIds.add(vTopic.dwp_kitv__visit_id__c);
            }
            final List<dwp_kitv__Visit__c> vList = [SELECT dwp_kitv__account_id__c FROM dwp_kitv__Visit__c WHERE Id IN :visitIds];
            for(dwp_kitv__Visit__c visit : vList) {
                aVistRel.add(visit.dwp_kitv__account_id__c);
            }
    	}
    	system.debug(aVistRel);
    	return aVistRel;
    }
	
	/*
	* Clase Wrapper
	*/
    public class wrapperClass {
	  /*
  	  * @author Global Desktop
  	  * @description Declaracion de los campos de la lista wrapper
  	  */
      private String cId; //NOSONAR
      private String clientUrl; //NOSONAR
      private String clientName; //NOSONAR
      private String cType; //NOSONAR
      private String clientType; //NOSONAR
      private String globalBanker; //NOSONAR
      private String codeClient; //NOSONAR
      private String labelCountry; //NOSONAR
      private String labelCountryManag; //NOSONAR
      private String rarYtd; //NOSONAR
      private String rar12Ytd; //NOSONAR
      private String marginYtd; //NOSONAR
      private String rorcPar; //NOSONAR  
        /*
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
        public wrapperClass(String clientId, String cName, String clientType, String gBanker, String cClient, String country, String countrManag, String ytd, String rar12, String margin, String rorc) { //NOSONAR
            this.cId = clientId;
            this.clientUrl = '/lightning/r/Account/' + clientId + '/view';
            this.clientName = cName;
            this.cType = clientType;
            this.globalBanker = gBanker;
            this.codeClient = cClient;
            this.labelCountry = country;
            this.labelCountryManag = countrManag;
            if(ytd != null) {
                this.rarYtd = ytd+'%';    
            }
            if(rar12 != null) {
                this.rar12Ytd = rar12+'%';
            }
            if(margin != null) {
                this.marginYtd = margin+' '+UserInfo.getDefaultCurrency();      
            }
            if(rorc != null) {  
                this.rorcPar = rorc+'%';
            }
        }
  	}

}