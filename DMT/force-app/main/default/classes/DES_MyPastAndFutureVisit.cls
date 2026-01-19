/**
    *Autor: Alejandro del Rio
     */
	 public with sharing class DES_MyPastAndFutureVisit {
	/*Met0d0 que devuelve una lista de visitas vivas en las que participo, soy owner,
	* o cualquiera de los usuarios que están debajo de mi en la jerarquia
	* de roles son owner o forman parte del equipo
    */
    @AuraEnabled
	public static String getData(Integer tableSize, boolean gmRolVery) {
        final List<wrapperClass> listWrapperClass = new List<wrapperClass>();//NOSONAR
        final Boolean roleHier = true;//NOSONAR
        Integer conter=0;//NOSONAR
        List<dwp_kitv__Visit_Management_Team__c> listVisManag = new List<dwp_kitv__Visit_Management_Team__c>();
        final Map<String, String> maptype = gettype();//NOSONAR
        final Map<String, String> mappurpouse = getpurpouse();//NOSONAR
        if(listVisManag.isEmpty()) {
        	/*Todas las oportunidades vivas en las que participo, soy owner,
			* o cualquiera de los usuarios que están debajo de mi en la jerarquia
			* de roles son owner o forman parte del equipo
        	*/
        	final Set<Id> setIdChildRoles = new Set<Id>();//NOSONAR
        	final Set<Id> setIdChilds = new Set<Id>();
        	setIdChilds.add((Id)UserInfo.getUserRoleId());
        	Set<Id> setIdsRoles = new Set<Id>();//NOSONAR
        	Integer cont = 0;//NOSONAR

        	/*
        	 *	SE HACE UNA QUERY DENTRO DE UN BUCLE PORQUE NECESTIMOS COGER TODA LA JERARQUÍA DE ROLES,
        	 *	NO SOLO LOS HIJOS DIRECTOS. TIENE UN LIMITE DE 11 VUELTAS.
        	 *
        	**/
        	Map<Id, User> mapUsersChildRole = new Map<Id, User>();
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
                if(gmRolVery==true) {
                     listVisManag = new List<dwp_kitv__Visit_Management_Team__c>([
												SELECT id,dwp_kitv__visit_id__r.id, dwp_kitv__visit_id__r.name,
                                                dwp_kitv__visit_id__r.dwp_kitv__account_id__r.id,
                                                dwp_kitv__visit_id__r.dwp_kitv__account_id__r.name,
                                                dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c,
                                                dwp_kitv__visit_id__r.dwp_kitv__visit_channel__c,
                                                dwp_kitv__visit_id__r.dwp_kitv__visit_purpose_type__c,
                                                CurrentUser__c
												FROM dwp_kitv__Visit_Management_Team__c
												//WHERE DES_User__c = :UserInfo.getUserId()]);
												WHERE (dwp_kitv__user_id__c IN :mapUsersChildRole.keySet()
												or dwp_kitv__user_id__r.UserRoleid =:(Id)UserInfo.getUserRoleId()
												or dwp_kitv__user_id__c =:(Id)UserInfo.getUserId())
                         						and (dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c = LAST_N_DAYS:365 OR dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c > TODAY) ORDER BY dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c desc]);
                } else {
                    listVisManag = new List<dwp_kitv__Visit_Management_Team__c>([
												SELECT id,dwp_kitv__visit_id__r.id, dwp_kitv__visit_id__r.name,
                                                dwp_kitv__visit_id__r.dwp_kitv__account_id__r.id,
                                                dwp_kitv__visit_id__r.dwp_kitv__account_id__r.name,
                                                dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c,
                                                dwp_kitv__visit_id__r.dwp_kitv__visit_channel__c,
                                                dwp_kitv__visit_id__r.dwp_kitv__visit_purpose_type__c,
                                                CurrentUser__c
												FROM dwp_kitv__Visit_Management_Team__c
												//WHERE DES_User__c = :UserInfo.getUserId()]);
												WHERE (dwp_kitv__user_id__c IN :mapUsersChildRole.keySet()
												or dwp_kitv__user_id__c =:(Id)UserInfo.getUserId())
                         						and (dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c = LAST_N_DAYS:365 OR dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c > TODAY) ORDER BY dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c desc]);

                }

        	}
        }
        system.debug(tableSize);
        for(dwp_kitv__Visit_Management_Team__c vism : listVisManag) {
            if(conter <= tableSize) {
            	listWrapperClass.add(new wrapperClass(vism, maptype.get(vism.dwp_kitv__visit_id__r.dwp_kitv__visit_channel__c), mappurpouse.get(vism.dwp_kitv__visit_id__r.dwp_kitv__visit_purpose_type__c)));
        		conter++;//NOSONAR
            }
        }

		return JSON.serialize(listWrapperClass);
    }
	/*
     * clase wrapper
     */
    public class wrapperClass {
		private String visitUrl;//NOSONAR
        private String visName;//NOSONAR
		private String clientProspectURL;//NOSONAR
		private String clientProspect;//NOSONAR
		private Datetime StartDate;//NOSONAR
        private String types;//NOSONAR
        private String PurposType;//NOSONAR
		/*
		*met0d0 que construye el wrapper
		*/
		public wrapperClass(dwp_kitv__Visit_Management_Team__c listVisManag,string vtype, string vpurpouse) {
			this.visitUrl = '/lightning/r/dwp_kitv__Visit__c/' + listVisManag.dwp_kitv__visit_id__r.id + '/view';
            this.visName = listVisManag.dwp_kitv__visit_id__r.name;
			this.clientProspectURL = '/lightning/r/Account/' + listVisManag.dwp_kitv__visit_id__r.dwp_kitv__account_id__r.id + '/view';
			this.clientProspect = listVisManag.dwp_kitv__visit_id__r.dwp_kitv__account_id__r.name;
			this.StartDate = listVisManag.dwp_kitv__visit_id__r.dwp_kitv__visit_start_date__c;
            this.types = vtype;
			this.PurposType = vpurpouse;
		}


	/*
	*Met0d0 que devuelve el valor de la picklist de visit type
	*/
	}
    public static Map<String, String> gettype() {
		final Map<String, String> mapPicklist = new Map<String, String>();
		final Schema.DescribeFieldResult fieldResult = dwp_kitv__Visit__c.dwp_kitv__visit_channel__c.getDescribe();
		final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
			mapPicklist.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		return mapPicklist;
	}
    /*
	*Met0d0 que devuelve el valor de la picklist de visit purpouse
	*/
    public static Map<String, String> getpurpouse() {
		final Map<String, String> mapPicklist = new Map<String, String>();
		final Schema.DescribeFieldResult fieldResult = dwp_kitv__Visit__c.dwp_kitv__visit_purpose_type__c.getDescribe();
		final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
			mapPicklist.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		return mapPicklist;
	}
}