/*
* @author Global Desktop
* @description Clase del componente lightning IpOppInProgressList de la home de compliance.
* @revision
*			2019/09/06	JSS	- Modificado método relateOpportunities: en el where de la query habia un bug y se arreglado poniendo la correcta Label.DES_Closed_Won
*/
public with sharing class IpOppClosedCtll {
	/*
  	* @author Global Desktop
  	* @description Method para recuperar las oportunidades IP relacionadas con visitas no ip
  	*/
  	@auraEnabled
  	public static String relateOpportunities(String tableSize) {
  		try {
  			List<Opportunity> opps = [select id, Name, compliance_form_status_type__c, CreatedDate, operation_privileged_user_name__c from Opportunity
                        where disclosure_info_type__c = :Label.DES_OP_Inside and
                            StageName in (:Label.DES_Closed_Won, :Label.DES_Closed_Lose)
                            Order by CreatedDate desc
  							];
  			List<String> ownersIds = new List<String>();
            for(Opportunity opp : opps) {
                if (opp.operation_privileged_user_name__c != null) {
                    ownersIds.add(opp.operation_privileged_user_name__c);
                }
            }

            Map<String,String> countryMap = userCountries();
            Map<Id,String> ownersMap = new  Map<Id,String>();

            List<User> owners = [select id, DES_Country__c  from User where id in :ownersIds];

            for(User user : owners) {
                ownersMap.put(user.Id, countryMap.get(user.DES_Country__c));
            }

	  		final Integer cSize = opps.size();
	  		List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	  		for(Opportunity opp : opps) {
	  			listWrapperClass.add(new wrapperClass(opp.Id, opp.Name, opp.compliance_form_status_type__c, opp.CreatedDate, ownersMap.get(opp.operation_privileged_user_name__c) ,cSize));
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
  	
	private static Map<String,String> userCountries() {
       	Map<String,String> countryMap = new Map<String,String>();	
        Schema.DescribeFieldResult F = User.DES_Country__c.getDescribe();
		Schema.sObjectField T = F.getSObjectField();
		List<PicklistEntry> entries = T.getDescribe().getPicklistValues();        
        
        for (PicklistEntry entry : entries) {
            countryMap.put(entry.getValue(),entry.getLabel());
        }
        
        return countryMap;
    }
  	
  	
  	/**
    * @author Global Desktop
    * @description clase para construir lista wrapper
    */
    public class wrapperClass {
        /*Url de la oportunidad*/
      	private String oppUrl; //NOSONAR
    	/*Nombre de la oportunidad*/
      	private String cOppName; //NOSONAR
        /*Information disclosure de la opp*/
      	private String formStatus; //NOSONAR
      	 /*Information disclosure de la visita*/
      	private Datetime createdDate; //NOSONAR
        /*Information disclosure de la visita*/
      	private String country; //NOSONAR
      	/*Numero de contratos*/
      	private Integer nSize; //NOSONAR
      	
      	/**
      	* @author Global Desktop
      	* @description Construye lista wrapper
      	*/
      	public wrapperClass(String oppUrlP, String cOppNameP,  String cformStatusP, Datetime ccreatedDateP, String cCountryP ,Integer nSizeP) {
      		this.oppUrl = '/lightning/r/Opportunity/' + oppUrlP + '/view';         
            this.cOppName = cOppNameP;
            this.formStatus = cformStatusP;
      		this.createdDate = ccreatedDateP;
            this.country = cCountryP;
      		this.nSize = nSizeP;
      	}
      	
    }
    
}