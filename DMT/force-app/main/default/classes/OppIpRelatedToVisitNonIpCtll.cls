/*
* @author Global Desktop
* @description Clase del componente lightning OppIpRelatedToVisitNonIp de la home de compliance.
*/
public with sharing class OppIpRelatedToVisitNonIpCtll {
	/*
  	* @author Global Desktop
  	* @description Method para recuperar las oportunidades IP relacionadas con visitas no ip
  	*/
  	@auraEnabled
  	public static String relateOpportunities(String tableSize) {
  		try {
  				List<dwp_kitv__Visit_Topic__c> topics = [select id, dwp_kitv__opportunity_id__c, dwp_kitv__visit_id__c, dwp_kitv__opportunity_id__r.Name, dwp_kitv__visit_id__r.Name, 
                        dwp_kitv__opportunity_id__r.disclosure_info_type__c, dwp_kitv__visit_id__r.disclosure_info_type__c from dwp_kitv__Visit_Topic__c 
                        where (dwp_kitv__opportunity_id__r.disclosure_info_type__c = :Label.DES_OP_Inside 
                              and  dwp_kitv__visit_id__r.disclosure_info_type__c != :Label.DES_OP_Inside) or
                        (dwp_kitv__opportunity_id__r.disclosure_info_type__c !=:Label.DES_OP_Inside and  dwp_kitv__visit_id__r.disclosure_info_type__c =:Label.DES_OP_Inside 
                         and dwp_kitv__opportunity_id__c != null)                                    
  							];		
  							
	  		final Integer cSize = topics.size();
	  		List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	  		for(dwp_kitv__Visit_Topic__c topic : topics) {
	  			listWrapperClass.add(new wrapperClass(topic.dwp_kitv__opportunity_id__c, topic.dwp_kitv__visit_id__c ,topic.dwp_kitv__opportunity_id__r.Name, topic.dwp_kitv__visit_id__r.Name,
                                      topic.dwp_kitv__opportunity_id__r.disclosure_info_type__c ,  topic.dwp_kitv__visit_id__r.disclosure_info_type__c ,cSize));
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
        /*Url de la oportunidad*/
      	private String oppUrl; //NOSONAR
        /*Url de la Visita*/
      	private String visitUrl; //NOSONAR
    	/*Nombre de la oportunidad*/
      	private String cOppName; //NOSONAR
      	/*Nombre de la visita*/
      	private String cVisitName; //NOSONAR
        /*Information disclosure de la opp*/
      	private String cInfDiscOpp; //NOSONAR
      	 /*Information disclosure de la visita*/
      	private String cInfDiscVisit; //NOSONAR
      	/*Numero de contratos*/
      	private Integer nSize; //NOSONAR
      	
      	/**
      	* @author Global Desktop
      	* @description Construye lista wrapper
      	*/
      	public wrapperClass(String oppUrlP, String visitUrlP, String cOppNameP, String cVisitNameP, String cInfDiscOppP, String cInfDiscVisitP, Integer nSizeP) {
      		this.oppUrl = '/lightning/r/Opportunity/' + oppUrlP + '/view';         
            this.visitUrl = '/lightning/r/dwp_kitv__Visit__c/' + visitUrl + '/view';
            this.cOppName = cOppNameP;
      		this.cVisitName = cVisitNameP;
            this.cInfDiscOpp = cInfDiscOppP;
      		this.cInfDiscVisit = cInfDiscVisitP;
      		this.nSize = nSizeP;
      	}
      	
    }
    

}