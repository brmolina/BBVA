/*
* @author Global Desktop
* @description Clase del componente lightning LegalAgreementsList de la ficha de grupo.
*/
public with sharing class LegalAgreementsListCnt {
	
	/*
  	* @author Global Desktop
  	* @description Method para recuperar los contratos marco relacionados al cliente
  	*/
  	@auraEnabled
  	public static String relateContratos(String tableSize, String accId) {
 		 try {
  				system.debug('LegalAgreementsListCnt: Valor de accId: ' +accId);
            	List<Contrato_Marco__c> cMarco = [SELECT participant_id__c, participant_id__r.Name, gf_agree_annex_typo_desc__c, master_agreement_type__c, star_counterparty_oper_desc__c, bbva_entity_name__c,
 									gf_deal_signing_date__c, gf_agree_version_id__c, Name
  							   FROM Contrato_Marco__c
  							  WHERE participant_id__c = :accId
  							];		
  			system.debug('Valor de cMarco: ' +cMarco);				
	  		final Integer cMarcoNum = cMarco.size();
	  		List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	  		for(Contrato_Marco__c cMr : cMarco) {
            	listWrapperClass.add(new wrapperClass(cMr.participant_id__c, cMr.Name, cMr.participant_id__r.Name, cMr.master_agreement_type__c, cMr.gf_deal_signing_date__c, cMr.star_counterparty_oper_desc__c,
  													cMr.bbva_entity_name__c, cMarcoNum, cMr.gf_agree_annex_typo_desc__c, cMr.gf_agree_version_id__c));
	  		}
	  		
	  		Integer tSize;
	  		if(tableSize != null) {
	      		tSize = Integer.valueOf(tableSize);
	    	}
	    	if(tSize != null) {
		        final List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
		          Integer regTable = tSize;
		          if(tSize > listWrapperClass.size()) {
		            regTable = listWrapperClass.size();
		          }
		          for(Integer cn = 0; cn < regTable ; cn++) {
		            if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
		              listaWrapperAux.add(listWrapperClass.get(cn));
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
    public class wrapperClass {
		/*Attribute*/
      	private String accUrl; //NOSONAR
    	/*Nombre del contrato*/
      	private String cName; //NOSONAR
      	/*Nombre de la cuenta*/
      	private String accName; //NOSONAR
      	/*Tipo del contrato*/
      	private String cType; //NOSONAR
      	/*Fecha del contrato*/
      	private Date cDate; //NOSONAR
        /*Contrapartida del contrato*/
      	private String cCounterparty; //NOSONAR
      	/*Entidad del contrato*/
      	private String cEntity; //NOSONAR
      	/*Numero de contratos*/
      	private Integer nMarcos; //NOSONAR
        /*Tipo de Contrato Colateral*/
        private String cCollateralType; //NOSONAR
        /*Versión del contrato*/
        private String cVersion; //NOSONAR
      	
      	/**
      	* @author Global Desktop
      	* @description Construye lista wrapper
      	*/
      	public wrapperClass(String legalAg, String cNameP, String accNameP, String cTypeP, Date cDateP, String cCounterpartyP, String cEntityP, Integer nMarcosP, String cCollateralTypeP, String cVersionP) {
      		this.accUrl = '/lightning/r/Account/' + legalAg + '/view';
			this.cName = cNameP;
      		this.accName = accNameP;
      		this.cType = cTypeP;
      		this.cDate = cDateP;
            this.cCounterparty = cCounterpartyP;
      		this.cEntity = cEntityP;
      		this.nMarcos = nMarcosP;
            this.cCollateralType = cCollateralTypeP;
            this.cVersion = cVersionP;
      	}
      	
    }
    
    
	
}