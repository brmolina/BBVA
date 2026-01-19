/**********************************************************************************
* @author       VASS - DSL
* @date         23/04/2018
* @description  Clase que recupera las oportunidades que más tiempo llevan sin haber interaccionado con ellas
* @Revision     [03/07/2018] - Se modifica la clase para que, en caso de que no se quiera 
								filtrar el país, se muestres las oportunidades del usuario que lo visualiza y de los usuarios 
								que están por debajo de la jerarquía de roles.                
**********************************************************************************/
public with sharing class DES_Alive_Opportunities_Home {

	/*Met0d0 que devuelve el CurrentUserISOCode
    */
	@AuraEnabled
	public static String getCurrentUserISOCode() {
		return UserInfo.getDefaultCurrency(); 
	}
	/*Met0d0 que devuelve una lista de visitas vivas en las que participo, soy owner, 
	* o cualquiera de los usuarios que están debajo de mi en la jerarquia 
	* de roles son owner o forman parte del equipo
    */
	@AuraEnabled
	public static String getData(String tableSize, String countToDisplay, Boolean roleHierarchy, boolean gmRolVery) {
        system.debug('>>>>> roleHierarchy : ' + roleHierarchy);
        Boolean roleHier = true;
        Integer tSize;
		if(tableSize != null) {
			tSize = Integer.valueOf(tableSize);
		}
        final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
        
        //1. Busco las oportunidades en las que el usuario es el global banker es propietario o miembro de éstas
        system.debug('>>>>> countToDisplay : ' + countToDisplay);
        final List<String> countriesM;
        final Set<String> setCountriesQuery = new Set<String>();
        List<DES_Opportunity_Management_member__c> listOMM = new List<DES_Opportunity_Management_member__c>();
        
        Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>();

        if(countToDisplay == null) {
			/*si no se ha rellenado, no hay que meter ningun filtro de paises
        	* Todas las oportunidades vivas en las que participo, soy owner,
			* o cualquiera de los usuarios que están debajo de mi en la jerarquia 
			* de roles son owner o forman parte del equipo
			*/
        	system.debug('>>>>> ESTÁ VACIO - countToDisplay :' + countToDisplay);
        	final Set<Id> setIdChildRoles = new Set<Id>();
        	Set<Id> setIdChilds = new Set<Id>();
        	setIdChilds.add((Id)UserInfo.getUserRoleId());
        	Set<Id> setIdsRoles = new Set<Id>();
        	Integer cont = 0;
        	
        	/*
        	 *	SE HACE UNA QUERY DENTRO DE UN BUCLE PORQUE NECESTIMOS COGER TODA LA JERARQUÍA DE ROLES, 
        	 *	NO SOLO LOS HIJOS DIRECTOS. TIENE UN LIMITE DE 11 VUELTAS.
        	 *
        	**/
        	Map<Id, User> mapUsersChildRole = new Map<Id, User>();
        	system.debug('>>>>> roleHier : ' + roleHier);
        	if(roleHier) {
        		do {
	        		//Set<Id> setIdsRoles = new Set<Id>();
	        		system.debug('>>>>> cont : ' + cont);
	        		if(cont >= 10) {
	        			break;
	        			}
	        		system.debug('>>>>> setIdChilds : ' + setIdChilds);
	        		system.debug('>>>>> setIdChildRoles : ' + setIdChildRoles);
	        		
	        		if(setIdsRoles.isEmpty()) {
						setIdsRoles = DES_RoleUtils.getAllSubRoleIds(setIdChilds);
	        			
	        		} else {
	        			setIdsRoles = DES_RoleUtils.getAllSubRoleIds(setIdsRoles);
	        		}
	        		setIdChildRoles.addAll(setIdsRoles);
	        		system.debug('>>>>> setIdsRoles : ' + setIdsRoles);
	        		cont++;
	        	} while(!setIdsRoles.isEmpty());
	        	
	        	mapUsersChildRole = DES_RoleUtils.getAllUserWithRoles(setIdChildRoles);
				listOMM=getoppmanamember(gmRolVery,mapUsersChildRole);                
	        	
        	} else {
        		listOMM = new List<DES_Opportunity_Management_member__c>([
												SELECT DES_Opportunity__c
												FROM DES_Opportunity_Management_member__c
												WHERE DES_User__c = :UserInfo.getUserId()]);
        	}
        	system.debug('>>>>> mapUsersChildRole : ' + mapUsersChildRole);
        	//LA SIGUIENTE LINEA ESTÁ COMENTADA PORQUE NO TIENE QUE TENER EN CUENTA EL ROLE DEL USUARIO
        	//mapUsersChildRole.put(UserInfo.getUserId(), new User(Id=UserInfo.getUserId(), userRoleId = UserInfo.getUserRoleId()));//Guardo el usuario actual
        	/*listOMM = new List<DES_Opportunity_Management_member__c>([
												SELECT DES_Opportunity__c
												FROM DES_Opportunity_Management_member__c
												//WHERE DES_User__c = :UserInfo.getUserId()]);
												WHERE DES_User__c IN :mapUsersChildRole.keySet()
												OR DES_User__c = :UserInfo.getUserId()]);*/
			
			system.debug('>>>>> listOMM: ' + listOMM);
			

	
			mapOpps = getMapOpp(listOMM,mapUsersChildRole);
			
			system.debug('>>>>> mapOpps: ' + mapOpps);	
        } else {
        	setMapOpp(countToDisplay,setCountriesQuery);
        }
        system.debug('>>>>> setCountriesQuery : ' + setCountriesQuery);
		system.debug('>>>>> mapOpps : ' + mapOpps);
        final List<OpportunityLineItem> listOpli = new List<OpportunityLineItem>([
            				SELECT 	Product2.Name,
            						OpportunityId
            				FROM OpportunityLineItem
            				WHERE OpportunityId IN :mapOpps.keySet()
        ]);
        Map<Id, String> mapOppProducts = new Map<Id, String>();//Este mapa tiene el id de la oportunidad como key y la concatenacion de los productos como value
        //Guardo en un mapa el ID de la opp y un string con los nombres de los productos que tiene la Opp
        mapOppProducts= setoppProducts(listOpli);
        system.debug('>>>>> mapOppProducts : ' + mapOppProducts);
		setwrapper(mapOppProducts,mapOpps,listWrapperClass);
        //Este mapa tendrá como Key el api name del campo countriesParticipants y como value las labels correspondientes de cada pais
       system.debug('>>>>> listWrapperClass: ' + listWrapperClass);
       return serializeWrapper(tSize,listWrapperClass);
    }
    
    /*
     * Met0d0 que contruye el JSON que devolvera el met0d0
     */
    public static String serializeWrapper(Integer tSize,List<wrapperClass> listWrapperClass) {
        final List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
		if(tSize == null) {
			system.debug('>>>>> listWrapperClass tSize NULL : ' + listWrapperClass);
			listaWrapperAux =listWrapperClass;
		} else {
            Integer regTable = tSize;
            if(tSize > listWrapperClass.size()) {
                regTable = listWrapperClass.size();
            }
            for(Integer cn = 0; cn < regTable ; cn++) {
				if( !listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
					listaWrapperAux.add(listWrapperClass.get(cn));
				}
			}
			system.debug('>>>>> listaWrapperAux : ' + listaWrapperAux);
			
		}
        return JSON.serialize(listaWrapperAux);
	}
    /*
     * met0d0 que itera opp con DES_Countries__c rellenos para montar un string de participantes de una opp, 
     * para luego montar la lista de Wrapper
     */
     public static void setwrapper(Map<Id, String> mapOppProducts,Map<Id, Opportunity> mapOpps,List<wrapperClass> listWrapperClass) {
		final  Map<String, String> mapCountPart = getCounPartiPcklst();
        for(Opportunity opp : mapOpps.values()) {
        	String countPartOpp;

        	if(opp.DES_Countries__c != null) {
        		final List<String> listCountsPart = opp.DES_Countries__c.split(';');
        		system.debug('>>>>> listCountsPart : ' + listCountsPart);
        		for(String countryPart : listCountsPart) {
        			if(countPartOpp == null) {
        				countPartOpp = '';
        			} else {
        				countPartOpp += ', ';
        			}
        			countPartOpp +=  mapCountPart.get(countryPart);
        		}
        	}
        	system.debug('>>>>> countriesParticipantsOpp : ' + countPartOpp);
            listWrapperClass.add(new wrapperClass(opp.Id, opp.Name, opp.AccountId, opp.Account.Name, opp.DES_Prospect__c, opp.DES_Prospect__r.Company, mapOppProducts.get(opp.Id), opp.StageName, opp.DES_Expected_Revenues__c, opp.CloseDate, countPartOpp));
        }
	}
	/*
     * met0d0 que construye el mapa de opp
     */
public static void setMapOpp(String countToDisplay,Set<String> setCountriesQuery) {
    final Set<Id> setIdOppsMiembro = new Set<Id>();
            //si se ha rellenado, se filtra visibilidad por ALL OPPORTUNITIES y por PAISES
            List<DES_Opportunity_Management_member__c> listOMM;
        	system.debug('>>>>> NO ESTÁ VACIO - countToDisplay :' + countToDisplay);
    		Map<Id, Opportunity> mapOpps;
    		List<String> countriesM;
        	countriesM = countToDisplay.split(',');
        	system.debug('>>>>> countriesM : ' + countriesM);
        	for(String country : countriesM) {
        		setCountriesQuery.add(country);
        	}
        	
        	listOMM = new List<DES_Opportunity_Management_member__c>([
												SELECT DES_Opportunity__c
												FROM DES_Opportunity_Management_member__c
												WHERE DES_User__r.DES_Country__c IN :setCountriesQuery/*DES_User__c = :UserInfo.getUserId()*/]); // QUITAR DES_User__c = :UserInfo.getUserId() y poner DES_User__r.DES_Country__c = :curUser.DES_Country__c pais del usuario que está visualizando el report 
	        system.debug('>>>>> listOMM : ' + listOMM);
			for(DES_Opportunity_Management_member__c oppmm : listOMM) {
				if(!setIdOppsMiembro.contains(oppmm.DES_Opportunity__c)) {
					setIdOppsMiembro.add(oppmm.DES_Opportunity__c);
				}
			}
			system.debug('>>>>> setIdOppsMiembro : ' + setIdOppsMiembro);
	        mapOpps = new Map<Id, Opportunity>([
	            				SELECT 	Id, 
	            					 	Name,
	            						AccountId,
	            						Account.Name,
                						DES_Prospect__c,
                						DES_Prospect__r.Company,
	            						convertCurrency(DES_Expected_Revenues__c),
	            						StageName,
	            						CloseDate,
	            						DES_Countries__c
	            				FROM Opportunity
	            				WHERE IsClosed = false
	            					AND Id IN :setIdOppsMiembro
	            				ORDER BY DES_Expected_Revenues__c DESC, CloseDate
	        ]);
	}
/*
     * met0d0 que devuelve una lista de DES_Opportunity_Management_member__c
     */
    public static List<DES_Opportunity_Management_member__c> getoppmanamember(Boolean gmRolVery,Map<Id, User> mapUsersChildRole) {
        List<DES_Opportunity_Management_member__c> listOMMs = new List<DES_Opportunity_Management_member__c>();
        if(gmRolVery == true) {
                   listOMMs = new List<DES_Opportunity_Management_member__c>([
												SELECT DES_Opportunity__c
												FROM DES_Opportunity_Management_member__c
												//WHERE DES_User__c = :UserInfo.getUserId()]);
												WHERE DES_User__c IN :mapUsersChildRole.keySet()
												OR DES_User__c = :UserInfo.getUserId() or DES_User__r.UserRoleid =:(Id)UserInfo.getUserRoleId()]);
                } else {
                   listOMMs = new List<DES_Opportunity_Management_member__c>([
												SELECT DES_Opportunity__c
												FROM DES_Opportunity_Management_member__c
												//WHERE DES_User__c = :UserInfo.getUserId()]);
												WHERE DES_User__c IN :mapUsersChildRole.keySet()
												OR DES_User__c = :UserInfo.getUserId()]);
                }
        return listOMMs;
    }
    /*
     * met0d0 que devuelve un mapa de opps
     */
    public static Map<Id, Opportunity> getMapOpp(List<DES_Opportunity_Management_member__c> listOMM,Map<Id, User> mapUsersChildRole){
        final Set<Id> setIdOppsMiembro = new Set<Id>();
        for(DES_Opportunity_Management_member__c oppmm : listOMM) {
				if(!setIdOppsMiembro.contains(oppmm.DES_Opportunity__c)) {
					setIdOppsMiembro.add(oppmm.DES_Opportunity__c);
				}
			}
	
			return new Map<Id, Opportunity>([
								SELECT 	Id, 
										Name,
										AccountId,
										Account.Name,
                						DES_Prospect__c,
                						DES_Prospect__r.Company,
										convertCurrency(DES_Expected_Revenues__c),
										StageName,
										CloseDate,
										DES_Countries__c
								FROM Opportunity
								WHERE IsClosed = false
									AND (OwnerId  IN :mapUsersChildRole.keySet()
										OR Id IN :setIdOppsMiembro)
								ORDER BY DES_Expected_Revenues__c DESC, CloseDate
			]);
    }
    /*
     * met0d0 que devuelve un mapa de opp-product
     */
     public static Map<Id, String> setoppProducts(List<OpportunityLineItem> listOpli) {
         
         final Map<Id, String> mapOppProducts= new Map<Id, String>();
         for(OpportunityLineItem opli : listOpli) {
            if(mapOppProducts.get(opli.OpportunityId) == null) {
				mapOppProducts.put(opli.OpportunityId, opli.Product2.Name);
            } else {
                final String prdcts = mapOppProducts.get(opli.OpportunityId) + ', ' + opli.Product2.Name;
                mapOppProducts.put(opli.OpportunityId, prdcts);
            }
        }
         return mapOppProducts;
     }

	/*
     * clase wrapper
     */
	public class wrapperClass{
		public String oppUrl;//NOSONAR
		public String oppName;//NOSONAR
		public String clientProspectURL;//NOSONAR
		public String clientProspect;//NOSONAR
        public String products;//NOSONAR
        public String status;//NOSONAR
        public Date closingDate;//NOSONAR
		public Decimal expectedRevenue;//NOSONAR
		public String countriesParticipants;//NOSONAR
		/*
		 * met0d0 que construye el wrapper
		 */
		public wrapperClass(Id oppId, String oppName, Id clientId, String clientName, Id prospectId, String prospectCompany, String prods, String status, Decimal expRev, Date closDate, String countsPar) {
			this.oppUrl = '/lightning/r/Opportunity/' + oppId + '/view';
			this.oppName = oppName;
			this.clientProspectURL = '/lightning/r/Lead/' + prospectId + '/view';
			this.clientProspect = prospectCompany;
            if (clientName != null) {
               this.clientProspect = clientName; 
               this.clientProspectURL = '/lightning/r/Account/' + clientId + '/view';
            }
            this.products = prods;
            this.status = status;
			this.expectedRevenue = expRev;
			this.closingDate = closDate;
			this.countriesParticipants = countsPar;
		}
		
	}
	 /*
	*Met0d0 que devuelve el valor de la picklist de CounParti
	*/
	public static Map<String, String> getCounPartiPcklst() {
		final Map<String, String> mapPicklist = new Map<String, String>();
		final Schema.DescribeFieldResult fieldResult = Opportunity.DES_Countries__c.getDescribe();
		final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
			mapPicklist.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		
		system.debug('>>>>> mapPicklist : ' + mapPicklist);
		return mapPicklist;
	}

}//FIN DES_Alive_Opportunities_Home