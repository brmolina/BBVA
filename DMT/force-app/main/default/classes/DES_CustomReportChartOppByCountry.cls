/**********************************************************************************
* @author       Accenture -JSS
* @date         13/04/2018
* @description  Clase que recupera los datos de Oportunidades, los procesa y devuelve el resultado en el formato apropiado para poder crear posteriormente el chart con la libreria CHART.JS
* @Revision     12/07/2018	-	VASS DSL	-	Se modifica TODA la clase para que en la Query recoja tambien todas las oportunidades que son MIAS y son DRAFT, cambiando el objeto principal de la query a Opportunity
**********************************************************************************/
global with sharing class DES_CustomReportChartOppByCountry {
	
	global DES_CustomReportChartOppByCountry (){
		
	}
	
	@AuraEnabled
	public static String getDataChart(String clientId){
		system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);
		
		Set<Id> setIdOppsDenormClient = new Set<Id>();
		for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c = :clientId]){
			if(!setIdOppsDenormClient.contains(denOpp.dwp_acmh__OpportunityId__c)){
				setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
			}
		}
		//Recojo todos los Opportunity Products que pertenezcan a alguna oportunidad de la cuenta de la tabla Desnormalizada 
		List<Opportunity> listOpp = new List<Opportunity>([
									SELECT  toLabel(DES_Booking_Geography__c),
											convertCurrency(DES_Expected_Revenues__c),
											Id,
											Name,
											AccountId,
											Account.Name
									FROM Opportunity
									WHERE IsClosed = false AND DES_Expected_Revenues__c != 0
									AND ((Opportunity.StageName != :Label.DES_Draft AND Id IN :setIdOppsDenormClient) OR (Opportunity.StageName = :Label.DES_Draft AND Opportunity.OwnerId = :UserInfo.getUserId()))
		]);
		
		system.debug('>>>>> listOpp : ' + listOpp);

		//Mapa que tiene como key el Country y como Value el Potential Revenue total de ese Country
		Map<String, Double> mapFPPR = new Map<String, Double>();
		//Si la lista no está vacia
		if(!listOpp.isEmpty()){

			for(Opportunity opp : listOpp){
				if(opp.DES_Booking_Geography__c != null){
					//Si tiene informado el potential revenue y tiene algun país
					if(opp.DES_Expected_Revenues__c != null){
						if(mapFPPR.containsKey(opp.DES_Booking_Geography__c)){
							//Si ya existe ese valor Country, le sumo el potential revenue a ese mismo Country
							mapFPPR.put(opp.DES_Booking_Geography__c, mapFPPR.get(opp.DES_Booking_Geography__c) + (opp.DES_Expected_Revenues__c));
						}else{
							//Si no exieste se añade la key de ese Country con el valor del Potential Revenue de ese country
							mapFPPR.put(opp.DES_Booking_Geography__c, (opp.DES_Expected_Revenues__c));
						}
					}
				}
			}

		}//FIN !listOpp.isEmpty()

		system.debug('>>>>> mapFPPR : ' + mapFPPR);
		return JSON.serialize(mapFPPR);
	} 
	
	
	
	
	@AuraEnabled
	public static String getDataTable(String clientId){
		system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);

		//Recojo todos los Opportunity Products que pertenezcan a alguna oportunidad de la cuenta de la tabla Desnormalizada 
		List<Opportunity> listOpp = new List<Opportunity>([
									SELECT  Id,
											Name,									
											toLabel(DES_Booking_Geography__c),
											convertCurrency(DES_Expected_Revenues__c),
											convertCurrency(DES_Potential_Revenue_By_Country__c),
											CreatedDate,
											CloseDate,
											StageName,											
											Account.Name,
											AccountId
									FROM Opportunity
									WHERE AccountId = :clientId AND IsClosed = FALSE
									AND (StageName != :Label.DES_Draft OR (StageName = :Label.DES_Draft AND OwnerId = :UserInfo.getUserId()))
									ORDER BY CreatedDate Desc]);
		
		system.debug('>>>>> listOpp : ' + listOpp);
		system.debug('>>>>> listOpp.get(0) : ' + listOpp.get(0).Name);

		//Lista que devuelve el método, que es la misma pero hemos denormalizado la lista de oportunidades separando los países del multipicklist
		List<WrapperClass> listOppDenormWrapper = new List<WrapperClass>();

		
		//Si la lista no está vacia        
		if(!listOpp.isEmpty()){
			for(Opportunity opli : listOpp){
				if(opli.DES_Booking_Geography__c != null){
					//Si tiene informado el potential revenue y tiene algun país
					if(opli.DES_Expected_Revenues__c != null){               
						listOppDenormWrapper.add(new WrapperClass(opli.Id, opli.Name, 
							opli.DES_Booking_Geography__c, opli.DES_Expected_Revenues__c,
							opli.CreatedDate, opli.CloseDate, opli.StageName,
							opli.Account, opli.Account.Name));

					}
				}
				
				
			}

		}//FIN !listOpp.isEmpty()

		system.debug('>>>>> Lista de listOppDenormWrapper : ' + listOppDenormWrapper);
		system.debug('>>>>>listOppDenormWrapper : ' + listOppDenormWrapper);
		return JSON.serialize(listOppDenormWrapper); 
	} 
	
	@AuraEnabled
	public static String getCurrentUserISOCode(){
		
		return UserInfo.getDefaultCurrency(); 
	}
	
	public class WrapperClass{
		
		/*
		 *	CREAR VARIABLE QUE TEGA LA URL A LA QUE VA A REDIRECCIONAR LA COLUMNA ( TENDRÁ UNA PARA LA OPORTUNIDAD ¿Y OTRA PARA EL PRODUCTO?) 
		 * 
		 */
		public String oppName;
		public String country;
		public Decimal expRevenueByCountry;
		public DateTime createdDate;
		public Date closeDate;
		public String stageName;   
		public Account account;
		public String accountName;    
		public String urlOpp;
		public String urlAccount;

		public WrapperClass(Id oppId, String oppName, String country, Decimal expRevenueByCountry, Datetime createdDate, Date closeDate, 
							String stageName, Account account, String accountName){
			this.urlOpp = '/lightning/r/Opportunity/' + oppId + '/view';
			this.oppName = oppName;
			this.country = country;
			this.expRevenueByCountry = expRevenueByCountry;
			this.createdDate = createdDate;
			this.closeDate = closeDate;
			this.stageName = stageName;
			this.urlAccount = '/lightning/r/Account/' + Account.Id + '/view';
			this.accountName = accountName;
		}
	}

}