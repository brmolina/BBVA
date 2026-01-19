/*
* @author Global Desktop
* @description Clase del componente lightning AlertRelatedList de la ficha de grupo.
*/
public with sharing class AlertsRelatedListCnt {
	
	/*
  	* @author Global Desktop
  	* @description Method para recuperar las alertas relacionadas al cliente
  	*/
  	@auraEnabled
  	public static String relatedAlerts(String tableSize, String accId, String family) {
  		try {
	  		List<DES_Denorm_AccountAlert__c> alDenList = new List<DES_Denorm_AccountAlert__c>();
	  		final String famFilter = '%'+family+'%';
	  		system.debug(famFilter);

	  		if(trueCondition(family)) {
  				alDenList = [SELECT commercial_alert_id__r.Id, commercial_alert_id__r.Name, commercial_alert_id__r.altm__commercial_alert_task_type__c, commercial_alert_id__r.altm__commercial_alert_desc__c,
  									commercial_alert_id__r.OwnerId, commercial_alert_id__r.Owner.Name, commercial_alert_id__r.altm__User_id__c,
  									commercial_alert_id__r.altm__User_id__r.Name
  							   FROM DES_Denorm_AccountAlert__c
  							  WHERE participant_id__c = :accId
  							    AND commercial_alert_id__r.altm__commercial_alert_record_type__c LIKE :famFilter
  							];		
	  		} else {
  				alDenList = [SELECT commercial_alert_id__r.Id, commercial_alert_id__r.Name, commercial_alert_id__r.altm__commercial_alert_task_type__c, commercial_alert_id__r.altm__commercial_alert_desc__c,
  									commercial_alert_id__r.OwnerId, commercial_alert_id__r.Owner.Name, commercial_alert_id__r.altm__User_id__c,
  									commercial_alert_id__r.altm__User_id__r.Name
  							   FROM DES_Denorm_AccountAlert__c
  							  WHERE participant_id__c = :accId
  							];		
	  		}
	  		final Integer oppNumber = alDenList.size();

	  		List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	  		for(DES_Denorm_AccountAlert__c alr : alDenList) {
	  			listWrapperClass.add(new wrapperClass(alr.commercial_alert_id__r.Id, alr.commercial_alert_id__r.Name, 
  										alr.commercial_alert_id__r.altm__commercial_alert_task_type__c, 
  										alr.commercial_alert_id__r.altm__commercial_alert_desc__c,
	  									alr.commercial_alert_id__r.OwnerId, alr.commercial_alert_id__r.Owner.Name,
	  									alr.commercial_alert_id__r.altm__User_id__c, alr.commercial_alert_id__r.altm__User_id__r.Name, oppNumber));
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
  	
  	
  	/*
  	* @author Global Desktop
  	* @description Method auxiliar para comprobar una condicion negativa
  	*/	
	private static boolean trueCondition (String family) {
		Boolean isTrue = false;
		if(family != null && family != '' && family != 'Todos' && family != 'All') {
			isTrue = true;
		}
		return isTrue;
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
      	/*Nombre de la alerta*/
      	private String alName; //NOSONAR
      	/*Url de la alerta*/
      	private String alUrl; //NOSONAR
      	/*Tipo de la alerta*/
      	private String altype; //NOSONAR
      	/*Descripcion de la alerta*/
      	private String descrip; //NOSONAR
      	/*Url de Owner de la alerta*/
      	private String urlOwner; //NOSONAR
      	/*Name de Owner de la alerta*/
      	private String nameOwner; //NOSONAR
      	/*Url de Banker de la alerta*/
      	private String urlBanker; //NOSONAR
      	/*Name de Banker de la alerta*/
      	private String nameBanker; //NOSONAR
      	/*Numero de alertas relacionadas*/
      	private Integer nAlert; //NOSONAR
      	
      	/**
      	* @author Global Desktop
      	* @description Construye lista wrapper
      	*/
      	public wrapperClass(Id alIdP, String alNameP, String alTypeP, String descriP, String idOwnerP, String nameOwnerP, String idBankerP, String nameBankerP, Integer nAlertP) {
      		this.alUrl = '/lightning/r/Account/' + alIdP + '/view';
      		this.alName = alNameP;
      		this.altype = alTypeP;
      		this.descrip = descriP;
      		this.urlOwner = '/lightning/r/Account/' + idOwnerP + '/view';
      		this.nameOwner = nameOwnerP;
      		if(idBankerP != null) {
      			this.urlBanker = '/lightning/r/Account/' + idBankerP + '/view';
      		}
      		this.nameBanker = nameBankerP;
      		this.nAlert = nAlertP;
      	}
      	
    }
	
}