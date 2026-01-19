/*********************************************************************************
Name:            DES_VisitManagementTeam_TriggerHandler
Description:     Class with VisitManagementTeam_Trigger custom methods
Test Class:      -

Version        Date            Author            Summary of changes
---------------------------------------------------------------------------------
0.1            11/05/2018      Accenture         Class creation
**********************************************************************************/
public with sharing class DES_VisitManagementTeam_TriggerHandler { //NOSONAR
	/*
	* Clase auxiliar Desktop Utils
	*/
    final Desktop_Utils utilsDesktop = Desktop_Utils.getInstance();

	/*
	* Method que setea los roles del equipo de la visita
	*/
    public static void fillRoleVisitManagementTeam(List<dwp_kitv__Visit_Management_Team__c> lstNew) {
        // 1) recorro lstNew y meto los ids de visitas en la lista "visitList"
        Set<Id> visitList;
		visitList = new Set<Id>();
        for(dwp_kitv__Visit_Management_Team__c i : lstNew) {
            visitList.add(i.dwp_kitv__visit_id__c);
        }

        // 2) query para traer clientes de la lista de ids de visita  -> creo que puedo traer directmanete la query desde BBVA Client Team ¿?
        final List<dwp_kitv__Visit__c> clientList = [SELECT dwp_kitv__account_id__c FROM dwp_kitv__Visit__c WHERE Id IN:visitList];
        Set<Id> clientIds;
		clientIds = new Set<Id>();
        for(dwp_kitv__Visit__c i : clientList) {
            clientIds.add(i.dwp_kitv__account_id__c);
        }

        // 3) mapa del tipo map<IdClient,visitManagementTeam>
        Map<Id,dwp_kitv__Visit_Management_Team__c> mapTeamClient = new Map<Id,dwp_kitv__Visit_Management_Team__c>();
		mapTeamClient = fillMapTeamClient(lstNew,clientList,mapTeamClient);


        // obtengo los BBVA Client Team Members que tienen cliente contenido en clientList
        final List<DES_BBVA_Management_team__c> listBBVATeam = [SELECT Id,DES_User__c,DES_Client__c,DES_Member_Role__c FROM DES_BBVA_Management_team__c WHERE DES_Client__c IN:clientIds];

        // 4) compara si el client y el usuario son iguales en VisitManagement y BBVA Client team
		mapTeamClient = compareClientUser(mapTeamClient,listBBVATeam);
    }

	/*
	* Realiza comparticion manual de visitas
	*/
	public static Map<Id,dwp_kitv__Visit_Management_Team__c> fillMapTeamClient(List<dwp_kitv__Visit_Management_Team__c> lstNew, List<dwp_kitv__Visit__c> clientList, Map<Id,dwp_kitv__Visit_Management_Team__c> mapTeamClient) {
		for(dwp_kitv__Visit_Management_Team__c i : lstNew) {
            for(dwp_kitv__Visit__c j : clientList) {
                if(i.dwp_kitv__visit_id__c == j.Id) {
                    mapTeamClient.put(j.dwp_kitv__account_id__c, i);
                }
            }
        }

		return mapTeamClient;
	}

	/*
	*  4) compara si el client y el usuario son iguales en VisitManagement y BBVA Client team
	*/
	public static Map<Id,dwp_kitv__Visit_Management_Team__c> compareClientUser(Map<Id,dwp_kitv__Visit_Management_Team__c> mapTeamClient,List<DES_BBVA_Management_team__c> listBBVATeam) {
		for(Id key : mapTeamClient.keySet()) {
            for(DES_BBVA_Management_team__c i : listBBVATeam) {
            		system.debug('Valor de key: ' +mapTeamClient.get(key).dwp_kitv__user_id__c);
                if(key == i.DES_Client__c && mapTeamClient.get(key).dwp_kitv__user_id__c == i.DES_User__c) {
                	mapTeamClient.get(key).DES_Member_Role__c = i.DES_Member_Role__c;
                }
            }
        }

		return mapTeamClient;
	}

	/*
	* Realiza comparticion manual de visitas
	*/
	public static void fillVisitManualSharing(List<dwp_kitv__Visit_Management_Team__c> triggerNew) {
		List<dwp_kitv__Visit__Share> listVisitSharing;
		listVisitSharing = new List<dwp_kitv__Visit__Share>();
		Set<Id> visitIdList;
		visitIdList = new Set<Id>();
        for (dwp_kitv__Visit_Management_Team__c i : triggerNew) {
            visitIdList.add(i.dwp_kitv__visit_id__c);
        }
        final List<dwp_kitv__Visit__c> visitList = [SELECT id, disclosure_info_type__c  FROM dwp_kitv__Visit__c WHERE Id IN :visitIdList and disclosure_info_type__c = :Label.DES_OP_Inside];
        Set<ID> iptIds;
		iptIds = new Set<Id>();
        for (dwp_kitv__Visit__c i : visitList) {
        	iptIds.add(i.id);
        }
		Desktop_Utils utilsDesktop2;
		for (dwp_kitv__Visit_Management_Team__c visitTM : triggerNew) {
			if (!iptIds.contains(visitTM.dwp_kitv__visit_id__c )) {
				utilsDesktop2 = Desktop_Utils.getInstance();
				listVisitSharing.add(utilsDesktop2.newManualSharingVisit(visitTM.dwp_kitv__visit_id__c, visitTM.dwp_kitv__user_id__c, 'Edit'));
			}
		}
		final List<Database.SaveResult> listSR = Database.insert(listVisitSharing,false); //NOSONAR
		
	}


	/**
  	* updatePaticipantFields
  	*/
	public static void updateParticipantFields(List<dwp_kitv__Visit_Management_Team__c> triggerNew) {
		if(!System.isFuture() && !System.isBatch()){
			List<ID> participantsIds = new List<Id>();
			for(dwp_kitv__Visit_Management_Team__c vp :triggerNew ){
				participantsIds.add(vp.Id);
			}
			futureUpdateParticipantFields(participantsIds);
		}
	}  //FIN  

	@future
	private static void futureUpdateParticipantFields(List<Id> listID) {
		System.debug('entra al método');
		List<dwp_kitv__Visit_Management_Team__c> participantsToUpdate = [SELECT id, dwp_kitv__user_id__c from dwp_kitv__Visit_Management_Team__c WHERE id IN: listID];

		Set<Id> userIDs = new Set<Id>();
		for(dwp_kitv__Visit_Management_Team__c vp : participantsToUpdate){
			if (vp.dwp_kitv__user_id__c != null) {
				userIDs.add(vp.dwp_kitv__user_id__c);
			}
		}

		Map<Id, User> userMap = new Map<Id, User>([SELECT Id, EMAIL, ID_User__c, NAME FROM User	WHERE Id IN :userIDs]);
		System.debug('userMap es: ' + userMap);
		for(dwp_kitv__Visit_Management_Team__c visitParticipant : participantsToUpdate){
			if (userMap.containsKey(visitParticipant.dwp_kitv__user_id__c)) {
				System.debug('entra al if');
				User relatedUser = userMap.get(visitParticipant.dwp_kitv__user_id__c);
				visitParticipant.dwp_kitv__gf_sf_external_cust_mail_desc__c = relatedUser.Email;
				visitParticipant.dwp_kitv__gf_sf_external_customer_id__c = relatedUser.ID_User__c;
				visitParticipant.dwp_kitv__gf_sf_external_customer_name__c = relatedUser.Name;
			}
		}
		
		
		if (!participantsToUpdate.isEmpty()){
			update participantsToUpdate;
		}
	}

	/*ADVERTENCIA:
	* No está pensada para que funcione correctamente si se desean borrar de forma masiva los miembros de las visitas
	* (entendiendo con de forma masiva a borrar de forma masiva varios miembros de varios equipos de visitas, no mostrará errores, pero no lo hará bien)
	*/
	public static void deleteManualSharing(List<dwp_kitv__Visit_Management_Team__c> triggerNew, Map<Id, dwp_kitv__Visit_Management_Team__c> triggerOldMap) {
		final Desktop_Utils utilsDesktop3 = Desktop_Utils.getInstance();
		//Guardo los id's de los usuarios en un set
		//Guardo los id's de los clientes en un set
		Set<Id> setAccountsIds;
		setAccountsIds = new Set<Id>();
		Set<Id> setUserIds;
		setUserIds = new Set<Id>();
		final Set<Id> setVisitIds = new Set<Id>();
		for(dwp_kitv__Visit_Management_Team__c visitMember : triggerOldMap.values()) {
			if(!setAccountsIds.contains(visitMember.Visit_Client_Id__c)) {
				setAccountsIds.add(visitMember.Visit_Client_Id__c);
			}
			if(!setUserIds.contains(visitMember.dwp_kitv__user_id__c)) {
				setUserIds.add(visitMember.dwp_kitv__user_id__c);
			}
			if(!setVisitIds.contains(visitMember.dwp_kitv__visit_id__c)) {
				setVisitIds.add(visitMember.dwp_kitv__visit_id__c);
			}
		}

		final Map<Id, Boolean> mapVstInsInf = gtMapVisitInsideInfo(setVisitIds);
		system.debug('>>>>> setAccountsIds : ' + setAccountsIds);
		//RECOJO LOS ID'S DE LAS CUENTAS PADRE
		final Map<Id, Id> mapClientGroup = utilsDesktop3.getMapClientGroup(setAccountsIds);
		system.debug('>>>>> mapClientGroup : ' + mapClientGroup);
		setAccountsIds.addAll(mapClientGroup.values());
		system.debug('>>>>> setAccountsIds : ' + setAccountsIds);

		final Map<Id, String> mapAccMembers =  getMapAccountAccMembers(setAccountsIds/*, setUserIds*/);
		final List<dwp_kitv__Visit_Management_Team__c> lMembsShToDel = getListMembersShareToDelete(triggerOldMap, mapAccMembers, mapClientGroup, mapVstInsInf);

		system.debug('>>>>> listMembersShareToDelete: ' + lMembsShToDel);
		Set<Id> setVisitShareDel;
		setVisitShareDel = new Set<Id>();
		Set<Id> setUserShareDel;
		setUserShareDel = new Set<Id>();
		for(dwp_kitv__Visit_Management_Team__c visitMember : lMembsShToDel) {
			system.debug('>>>>> visitMember : ' + visitMember);
			if(!setVisitShareDel.contains(visitMember.dwp_kitv__visit_id__c)) {
				setVisitShareDel.add(visitMember.dwp_kitv__visit_id__c);
			}
			if(!setUserShareDel.contains(visitMember.dwp_kitv__user_id__c)) {
				setUserShareDel.add(visitMember.dwp_kitv__user_id__c);
			}
		}

		system.debug('>>>>> setUserShareDel: ' + setUserShareDel);
		system.debug('>>>>> setVisitShareDel: ' + setVisitShareDel);
		final List<dwp_kitv__Visit__Share> listDelete = new List<dwp_kitv__Visit__Share>([
			SELECT Id
			FROM dwp_kitv__Visit__Share
			WHERE ParentId IN :setVisitShareDel
				AND UserOrGroupId IN :setUserShareDel
				AND RowCause = 'Manual'
		]);

		system.debug('>>>>> listDelete : ' + listDelete);

		delete listDelete;

	}//FIN deleteManualSharing

	private static Map<Id, Boolean> gtMapVisitInsideInfo(Set<Id> setVisitIds) {
		Map<Id, Boolean> mapInfoInside;
		mapInfoInside = new Map<Id, Boolean>();
		for(dwp_kitv__Visit__c visit : [SELECT Id, disclosure_info_type__c FROM dwp_kitv__Visit__c WHERE Id IN :setVisitIds]) {
			mapInfoInside.put(visit.Id, (visit.disclosure_info_type__c == Label.DES_OP_Inside)? true : false);
		}
		return mapInfoInside;
	}

	private static Map<Id, String> getMapAccountAccMembers(Set<Id> setAccountsIds/*, Set<Id> setUserIds*/) {
		Map<Id, String> mapAccMembers;
		mapAccMembers = new Map<Id, String>();
		system.debug('>>>>> setAccountsIds : ' + setAccountsIds);
		//system.debug('>>>>> setUserIds : ' + setUserIds);
		system.debug('>>>>> QUERY : ' + [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN :setAccountsIds/* AND UserId IN :setUserIds*/]);
		//Lanzo una query para obtener los miembros de las cuentas que estén en alguno de los clientes de las visitas.
		for(AccountTeamMember acctm : [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN :setAccountsIds/* AND UserId IN :setUserIds*/]) {
			system.debug('>>>>> acctm : ' + acctm);
			system.debug('>>>>> mapAccMembers.get(acctm.AccountId) : ' + mapAccMembers.get(acctm.AccountId));
			if(mapAccMembers.get(acctm.AccountId) == null) {
				mapAccMembers.put(acctm.AccountId, acctm.UserId);
			} else {
				mapAccMembers.put(acctm.AccountId, mapAccMembers.get(acctm.AccountId) + ';' + acctm.UserId);
			}
		}
		system.debug('>>>>> mapAccMembers : ' + mapAccMembers);
		return mapAccMembers;
	}

	private static List<dwp_kitv__Visit_Management_Team__c> getListMembersShareToDelete(Map<Id, dwp_kitv__Visit_Management_Team__c> triggerOldMap, Map<Id, String> mapAcctAccMembs, Map<Id, Id> mapClientGroup, Map<Id, Boolean> mapVstInsInf) {
		List<dwp_kitv__Visit_Management_Team__c> listDelete;
		listDelete = new List<dwp_kitv__Visit_Management_Team__c>();
		for(dwp_kitv__Visit_Management_Team__c visitMember : triggerOldMap.values()) {
			system.debug('>>>>> visitMember.Visit_Client_Id__c : ' + visitMember.Visit_Client_Id__c);
			system.debug('>>>>> visitMember.UserId : ' + visitMember.dwp_kitv__user_id__c);
			system.debug('>>>>> mapAccMembers : ' + mapAcctAccMembs);

			//Compruebo si el miembro que se borra está como miembro en el equipo
			//Compruebo si el miembro que se borra está como miembro en el equipo del grupo
			if(mapVstInsInf.get(visitMember.dwp_kitv__visit_id__c)
			|| checkMapClient(visitMember, mapAcctAccMembs, mapClientGroup)
			|| checkVisitMembrs(visitMember, mapAcctAccMembs, mapClientGroup)) {
				//Si no está como miembro, elimino el manual sharing
				listDelete.add(visitMember);
			}



		}
		system.debug('>>>>> listDelete : ' + listDelete);
		return listDelete;
	}
/***********************************************************************************************
Name:           updateFamiliesOnVisit
Description:    After Update Participante - Update field in Visit based on Participante.User.field
Apex Tests:		VisitsByRegionAndProductsYTDcntTest

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------------
0.1            13/11/2018      SunnyTrail         Initial Version
************************************************************************************************/
	/*public static void updateFamiliesOnVisit(List<dwp_kitv__Visit_Management_Team__c> lstParticipantes, Boolean deletion){
		//try{
			System.debug('::::updateFamiliesOnVisit init');
			Map<String, String> mapParticipanteVisita = new Map<String, String>();
			Map<String, String> mapParticipanteUser = new Map<String, String>();
			Set<String> setUserIds = new Set<String>();
			Set<String> setVisita = new Set<String>();

			for(dwp_kitv__Visit_Management_Team__c participante : lstParticipantes){
				mapParticipanteVisita.put(participante.Id, participante.dwp_kitv__visit_id__c);
				mapParticipanteUser.put(participante.Id, participante.dwp_kitv__user_id__c);
				setUserIds.add(participante.dwp_kitv__user_id__c);
				setVisita.add(participante.dwp_kitv__visit_id__c);
			}

			List<User_department_areas__mdt> userDepartmentAreas = new List<User_department_areas__mdt>();
			map<String, String> departmentRelatedArea = new map<String, String>();
			userDepartmentAreas = [SELECT User_department__c, User_profile__c, Visit_involved_area__c FROM User_department_areas__mdt];
			system.debug('Valor de userDepartmentAreas: ' +userDepartmentAreas);
			for(User_department_areas__mdt uda : userDepartmentAreas){
				departmentRelatedArea.put(uda.User_department__c, uda.Visit_involved_area__c);
			}
			system.debug('Valor de departmentRelatedArea: ' +departmentRelatedArea);
			//System.debug('::::mapParticipanteVisita' + JSON.serialize(mapParticipanteVisita));
			//System.debug('::::mapParticipanteUser' + JSON.serialize(mapParticipanteUser));
			//System.debug('::::setUserIds' + setUserIds);

			if(!mapParticipanteUser.isEmpty()){

				Map<String, String> getmapVisitasId = getParticipantUsers(setUserIds, mapParticipanteUser, mapParticipanteVisita,departmentRelatedArea);
				/////
				/*List<User> lstUsers = [SELECT Id, EMPLOYEE_DEPARTMENT_DESC__c FROM User
										WHERE Id IN :setUserIds];//:mapParticipantes.keyset()]; to avoid duplicates
				System.debug('::::lstUsers tras query' + JSON.serialize(lstUsers));
				List<dwp_kitv__Visit__c> lstVisits = new List<dwp_kitv__Visit__c>();
				Map<String, String> mapVisitasId = new Map<String, String>();

				for(String part : mapParticipanteUser.keySet()){
					for(User user : lstUsers){
						if(mapParticipanteUser.get(part) == user.Id){
							if(user.EMPLOYEE_DEPARTMENT_DESC__c != 'Default' || user.EMPLOYEE_DEPARTMENT_DESC__c != ''){
								mapVisitasId.put(mapParticipanteVisita.get(part), helperParseDepartment(user.EMPLOYEE_DEPARTMENT_DESC__c));
							}
						}
					}
				}*/
				/////
				/*if(!getmapVisitasId.isEmpty()){
				//if(!mapVisitasId.isEmpty()){

					List<Database.SaveResult> listSR = Database.update(getLstVisitasPre(getmapVisitasId, deletion, setVisita, departmentRelatedArea), false);
					//getLstVisitasPre(getmapVisitasId, deletion, setVisita);
					/////////
					/*List<dwp_kitv__Visit__c> lstVisitasPre = [SELECT Id, solution_name_path_desc__c
																FROM dwp_kitv__Visit__c WHERE Id IN :mapVisitasId.keySet()];
					System.debug('::::Final flow lstVisitasPre ' + lstVisitasPre);

					for(dwp_kitv__Visit__c visita : lstVisitasPre){
						String arrayDep = visita.solution_name_path_desc__c;
						//System.debug('::::arrayDep ' + arrayDep);
						if(arrayDep != null){
							List<String> lstDepartamentos = arrayDep.split(';');
							Set<String> setDepartamentos = new Set<String>(lstDepartamentos);

							if(deletion != true){
								setDepartamentos.add(mapVisitasId.get(visita.Id));
							}else{
								System.debug('::::deletion ');
								Map<String, Integer> mapCountDepartments = helperGetMapDepartments(setVisita);
								//System.debug('::::visita.id ' + visita.id);
								if(!mapCountDepartments.isEmpty()){
									for(String dep : setDepartamentos){
										//System.debug('::::mapCountDepartments.get(dep) ' + mapCountDepartments.get(dep));
										if(mapCountDepartments.get(dep) == null){
											//System.debug('::::setDepartamentosPreRemove (contador a 1) ' + setDepartamentos);
											setDepartamentos.remove(mapVisitasId.get(visita.Id));
										}
									}
								}else{
									setDepartamentos.remove(mapVisitasId.get(visita.Id));
								}
								//System.debug('::::setDepartamentosFinal ' + setDepartamentos);
							}
							visita.solution_name_path_desc__c = helperJoinLSTStringToString(setDepartamentos);
						}else{
							visita.solution_name_path_desc__c = mapVisitasId.get(visita.Id);
						}
						lstVisits.add(visita);
					}*/




				//}
				//List<Database.SaveResult> listSR = Database.update(lstVisits, false);
				////////////



			//}
		/*}catch (DmlException e) {
            throw new AuraHandledException('Error DML en DES_VisitManagementTeam_TriggerHandler.updateFamiliesOnVisit ' + e);
		}catch (Exception e) {
            throw new AuraHandledException('Error en DES_VisitManagementTeam_TriggerHandler.updateFamiliesOnVisit ' +  e);
        }*/
	//}

	/*private static Map<String, String> getParticipantUsers(Set<String> setUserIds, Map<String, String> mapParticipanteUser, Map<String, String> mapParticipanteVisita,map<String, String> departmentRelatedArea){
		List<User> lstUsers = [SELECT Id, EMPLOYEE_DEPARTMENT_DESC__c FROM User
							   WHERE Id IN :setUserIds];//:mapParticipantes.keyset()]; to avoid duplicates
			System.debug('::::lstUsers tras query' + JSON.serialize(lstUsers));
			//List<dwp_kitv__Visit__c> lstVisits = new List<dwp_kitv__Visit__c>();
			Map<String, String> mapVisitasId = new Map<String, String>();



			for(String part : mapParticipanteUser.keySet()){
				for(User user : lstUsers){
					if(mapParticipanteUser.get(part) == user.Id){
						if(user.EMPLOYEE_DEPARTMENT_DESC__c != 'Default' || user.EMPLOYEE_DEPARTMENT_DESC__c != ''){
							mapVisitasId.put(mapParticipanteVisita.get(part), helperParseDepartment(user.EMPLOYEE_DEPARTMENT_DESC__c, departmentRelatedArea));
						}
					}
				}
			}
			return mapVisitasId;
	}*/


	/*private static List<dwp_kitv__Visit__c> getLstVisitasPre(Map<String, String> mapVisitasId, boolean deletion, Set<String> setVisita, map<String,String>departmentRelatedArea){
		List<dwp_kitv__Visit__c> lstVisits = new List<dwp_kitv__Visit__c>();
		List<dwp_kitv__Visit__c> lstVisitasPre = [SELECT Id, solution_name_path_desc__c
																FROM dwp_kitv__Visit__c WHERE Id IN :mapVisitasId.keySet()];
		System.debug('::::Final flow lstVisitasPre ' + lstVisitasPre);

		/*List<User_department_areas__mdt> userDepartmentAreas = new List<User_department_areas__mdt>();
		map<String, String> departmentRelatedArea = new map<String, String>();
		userDepartmentAreas = [SELECT User_department__c, User_profile__c, Visit_involved_area__c FROM User_department_areas__mdt];
		system.debug('Valor de userDepartmentAreas: ' +userDepartmentAreas);
		for(User_department_areas__mdt uda : userDepartmentAreas){
			departmentRelatedArea.put(uda.User_department__c, uda.Visit_involved_area__c);
		}
		system.debug('Valor de departmentRelatedArea: ' +departmentRelatedArea);*/

		/*for(dwp_kitv__Visit__c visita : lstVisitasPre){
			String arrayDep = visita.solution_name_path_desc__c;
			//System.debug('::::arrayDep ' + arrayDep);
			if(arrayDep != null){

				//arrayDepFull(arrayDep, mapVisitasId, setVisita);
				/////////
				/*List<String> lstDepartamentos = arrayDep.split(';');
							Set<String> setDepartamentos = new Set<String>(lstDepartamentos);

							if(deletion != true){
								setDepartamentos.add(mapVisitasId.get(visita.Id));
							}else{
								System.debug('::::deletion ');
								Map<String, Integer> mapCountDepartments = helperGetMapDepartments(setVisita);
								//System.debug('::::visita.id ' + visita.id);
								if(!mapCountDepartments.isEmpty()){
									for(String dep : setDepartamentos){
										//System.debug('::::mapCountDepartments.get(dep) ' + mapCountDepartments.get(dep));
										if(mapCountDepartments.get(dep) == null){
											//System.debug('::::setDepartamentosPreRemove (contador a 1) ' + setDepartamentos);
											setDepartamentos.remove(mapVisitasId.get(visita.Id));
										}
									}
								}else{
									setDepartamentos.remove(mapVisitasId.get(visita.Id));
								}
								//System.debug('::::setDepartamentosFinal ' + setDepartamentos);
							}*/
				////////////

				//visita.solution_name_path_desc__c = helperJoinLSTStringToString(setDepartamentos);
				/*visita.solution_name_path_desc__c = arrayDepFull(arrayDep, mapVisitasId, setVisita, deletion, visita, departmentRelatedArea);
			}else{
				visita.solution_name_path_desc__c = mapVisitasId.get(visita.Id);
			}
			lstVisits.add(visita);
		}
		return lstVisits;
	}*/

	/*private static string arrayDepFull(String arrayDep, Map<String, String> mapVisitasId, Set<String> setVisita,
	boolean deletion, dwp_kitv__Visit__c visita, map<String, String> departmentRelatedArea){
		List<String> lstDepartamentos = arrayDep.split(';');
		Set<String> setDepartamentos = new Set<String>(lstDepartamentos);

		if(deletion != true){
			setDepartamentos.add(mapVisitasId.get(visita.Id));
		}else{
			Map<String, Integer> mapCountDepartments = helperGetMapDepartments(setVisita, departmentRelatedArea);
			if(!mapCountDepartments.isEmpty()){
				for(String dep : setDepartamentos){
					if(mapCountDepartments.get(dep) == null){
						setDepartamentos.remove(mapVisitasId.get(visita.Id));
					}
				}
			}else{
				setDepartamentos.remove(mapVisitasId.get(visita.Id));
			}
		}
		return helperJoinLSTStringToString(setDepartamentos);
	}*/

/************************************************************************************************************
Name:           helperParseDepartment
Description:    Method para parsear el departamento recogido del User al formato deseado a guardar en el campo de Visita
					Valores ( GTB, GM, GF, GCC, CIB y Finance)
Apex Tests:		VisitsByRegionAndProductsYTDcntTest

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------
0.1            13/11/2018      SunnyTrail         Initial Version
*************************************************************************************************************/
	public static String helperParseDepartment(String department, map<String, String> departArea) {
		String dep;
		system.debug('Valor de departArea: ' +departArea);
		if(department != null) {
			system.debug('Valor de departArea.get(department): ' +departArea.get(department));
			dep = departArea.get(department);
			//"switch when" aún no acepta Labels o variables en el when, usamos if else
			/*if(department.equalsIgnoreCase(Label.GTB)) { // 'Global Transactional Banking'
				dep = 'GTB';
			} else if(department.equalsIgnoreCase(Label.GM)) { // 'Global Market'
				dep ='GM';
			} else if(department.equalsIgnoreCase(Label.GF)) { // 'Global Finance'
				dep = 'GF';
			} else if(department.equalsIgnoreCase(Label.GCC)) { // 'Global Client Coverage'
				dep = 'GCC';
			}else { //CIB y FINANCE de momento son iguales en ambos campos
				dep = department;
			}*/
		}
		//System.debug('::::department inbound: ' + department);
		//System.debug('::::department outbound: ' + dep);
		return dep;
	}
/**************************************************************************************
Name:           helperJoinLSTStringToString
Description:    Helper para concatenar una lista de Strings en un String para ser usado en un campo multipicklist
Apex Tests:		VisitsByRegionAndProductsYTDcntTest

Version        Date            Author            Summary of changes
---------------------------------------------------------------------------------------
0.1            13/11/2018      SunnyTrail         Initial Version
**************************************************************************************/
	/*public static String helperJoinLSTStringToString(Set<String> values) {
		System.debug('::::helperJoinLSTStringToString init');
		List<String> valueCopy = new List<String>(values);
		if(valueCopy.isEmpty())
		    return null;
		String result = valueCopy[0];
		valueCopy.remove(0);
		while(!valueCopy.isEmpty()) {
			result += ';' + valueCopy[0];
		    valueCopy.remove(0);
		}
	  	return result;
	}*/
/*****************************************************************************************
Name:           helperGetMapDepartments
Description:    Devuelve contador de los departamentos por visita para borrar sólo cuando éste es ==1 y no mayor
Apex Tests:		VisitsByRegionAndProductsYTDcntTest

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            13/11/2018      SunnyTrail         Initial Version
*****************************************************************************************/
	/*public static Map<String, Integer> helperGetMapDepartments(Set<String> setVisita, map<String, String> departmentRelatedArea){
		try{
			system.debug('helperGetMapDepartments. Valor de departmentRelatedArea: ' +departmentRelatedArea);
			System.debug('::::helperGetMapDepartments init');
			Map<String, Integer> mapCountDepartments = new Map<String, Integer>();
			Integer contador;
			List<dwp_kitv__Visit_Management_Team__c> lstParticipantesPorVisita = [SELECT Id, dwp_kitv__user_id__r.EMPLOYEE_DEPARTMENT_DESC__c
															FROM dwp_kitv__Visit_Management_Team__c
															WHERE dwp_kitv__visit_id__c IN :setVisita];
			System.debug('::::lstParticipantesPorVisita' + lstParticipantesPorVisita);

			if(!lstParticipantesPorVisita.isEmpty()){
				for(dwp_kitv__Visit_Management_Team__c visita : lstParticipantesPorVisita){
					contador = 1;
			        if(mapCountDepartments.containsKey(visita.Id)){
			            contador += 1;
			        }
			        mapCountDepartments.put(helperParseDepartment(visita.dwp_kitv__user_id__r.EMPLOYEE_DEPARTMENT_DESC__c,departmentRelatedArea), contador);
			    }
			    System.debug('::::mapCountDepartments: ' + mapCountDepartments);
			}
			return mapCountDepartments; //si no entra lo devuelvo vació
		}catch (Exception e) {
            throw new AuraHandledException('Error en DES_VisitManagementTeam_TriggerHandler.helperGetMapDepartments ' +  e);
        }
	}*/
	/*
	 * Method
	 */
	private static Boolean checkMapClient(dwp_kitv__Visit_Management_Team__c visitMember, Map<Id, String> mapAcctAccMembs, Map<Id, Id> mapClientGroup) {
		Boolean checkClient;
		checkClient = false;

		if((mapAcctAccMembs.get(visitMember.Visit_Client_Id__c) == null && mapAcctAccMembs.get(mapClientGroup.get(visitMember.Visit_Client_Id__c)) == null)
				|| (mapAcctAccMembs.get(visitMember.Visit_Client_Id__c) == null && mapAcctAccMembs.get(mapClientGroup.get(visitMember.Visit_Client_Id__c)) != null && !mapAcctAccMembs.get(mapClientGroup.get(visitMember.Visit_Client_Id__c)).contains(visitMember.dwp_kitv__user_id__c))) {
			checkClient =  true;
		}

		return checkClient;
	}

	/*
	 * Method
	 */
	private static Boolean checkVisitMembrs(dwp_kitv__Visit_Management_Team__c visitMember, Map<Id, String> mapAcctAccMembs, Map<Id, Id> mapClientGroup) {
		Boolean checkVstM;
		checkVstM = false;

		if( (mapAcctAccMembs.get(visitMember.Visit_Client_Id__c) != null && !mapAcctAccMembs.get(visitMember.Visit_Client_Id__c).contains(visitMember.dwp_kitv__user_id__c) && mapAcctAccMembs.get(mapClientGroup.get(visitMember.Visit_Client_Id__c)) == null)
				|| (mapAcctAccMembs.get(visitMember.Visit_Client_Id__c) != null && !mapAcctAccMembs.get(visitMember.Visit_Client_Id__c).contains(visitMember.dwp_kitv__user_id__c) && mapAcctAccMembs.get(mapClientGroup.get(visitMember.Visit_Client_Id__c)) != null && !mapAcctAccMembs.get(mapClientGroup.get(visitMember.Visit_Client_Id__c)).contains(visitMember.dwp_kitv__user_id__c))) {
			checkVstM =  true;
		}

		return checkVstM;
	}

  /*
	 *	@author		Global Desktop
	 *	@description	Funcion que agrega al campo 'Involved Products' los productos a nivel 2 de la visita
	 *
	**/
	public static void fillInvolvedProducts(List<dwp_kitv__Visit_Management_Team__c> triggerNew, Boolean isDeleted) {//NOSONAR
		final Map<Id, dwp_kitv__Visit__c> mapVisitUpd = new Map<Id, dwp_kitv__Visit__c>();
		final Map<Id, String> mapVisitProducts = new Map<Id, String>();
		final Map<Id, String> mapUserProducts = new Map<Id, String>();
		final Set<Id> relatedUserIds = new Set<Id>();
		final Set<Id> relatedVisitIds = new Set<Id>();
		String strInvolvedProd;

		for(dwp_kitv__Visit_Management_Team__c visitTM : triggerNew) {
			if (!relatedVisitIds.contains(visitTM.dwp_kitv__visit_id__c)) {
				relatedVisitIds.add(visitTM.dwp_kitv__visit_id__c);
			}
			if (!relatedUserIds.contains(visitTM.dwp_kitv__user_id__c)) {
				relatedUserIds.add(visitTM.dwp_kitv__user_id__c);
			}
		}
		for(dwp_kitv__Visit__c visit : [SELECT Id, gf_visit_users_products_desc__c FROM dwp_kitv__Visit__c WHERE Id IN :relatedVisitIds]) {
			if(isDeleted) {
				mapVisitProducts.put(visit.Id, '');
			} else {
				mapVisitProducts.put(visit.Id, visit.gf_visit_users_products_desc__c);
			}
		}
		for(User usr : [SELECT Id, gf_user_work_product_desc__c FROM User WHERE Id IN :relatedUserIds]) {
			mapUserProducts.put(usr.Id, usr.gf_user_work_product_desc__c);
		}
		system.debug(':::::  mapUserProducts: ' + mapUserProducts);
		system.debug(':::::  mapVisitProducts: ' + mapVisitProducts);

		final String regEx = 'PRODUCTO|^PRODUCTO;.*|.*;PRODUCTO;.*|.*PRODUCTO';//NOSONAR
		system.debug('::::: regEx : ' + regEx);
		//codeA|^codeA;.*|.*;codeA;.*|.*codeA$
		for(dwp_kitv__Visit_Management_Team__c visitTM : triggerNew) {
			system.debug('::::: mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c) : ' + mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c));
			if(mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c) == null || mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c) == '') {
				strInvolvedProd = mapUserProducts.get(visitTM.dwp_kitv__user_id__c);
				mapVisitProducts.put(visitTM.dwp_kitv__visit_id__c, strInvolvedProd);
			} else {//SI EL CAMPO DE LA VISITA YA TIENE VALORES
				//COMPRUEBO SI EL USUARIO TIENE VARIOS VALORES O TIENE SOLO 1
				if(mapUserProducts.get(visitTM.dwp_kitv__user_id__c) != null && mapUserProducts.get(visitTM.dwp_kitv__user_id__c).contains(';')) {
					//RECORRO LOS PRODUCTOS DEL USUARIO QUE SE AGREGA A LA VISITA
					system.debug(':::::  mapUserProducts.get(visitTM.dwp_kitv__user_id__c): ' + mapUserProducts.get(visitTM.dwp_kitv__user_id__c));
					for(String strProd : mapUserProducts.get(visitTM.dwp_kitv__user_id__c).split(';')) {
						String regExAux = regEx;
						system.debug(':::::  regExAux antes replaceAll: ' + regExAux);
						regExAux = regExAux.replaceAll('PRODUCTO', strProd);
						system.debug(':::::  regExAux despues replaceAll: ' + regExAux);
						system.debug(':::::  !Pattern.matches(regExAux, mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c)): ' + !Pattern.matches(regExAux, mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c)));
						if(!Pattern.matches(regExAux, mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c))) {
							strInvolvedProd = mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c);
							strInvolvedProd += ';' + strProd;
							mapVisitProducts.put(visitTM.dwp_kitv__visit_id__c, strInvolvedProd);
						}
					}

				} else if (mapUserProducts.get(visitTM.dwp_kitv__user_id__c) != null) { //NOSONAR //SI TIENE UN SOLO VALOR
					String regExAux = regEx;
					system.debug(':::::  regExAux antes del replaceall: ' + regExAux);
					system.debug(':::::  mapUserProducts.get(visitTM.dwp_kitv__user_id__c): ' + mapUserProducts.get(visitTM.dwp_kitv__user_id__c));
					regExAux = regExAux.replaceAll('PRODUCTO', mapUserProducts.get(visitTM.dwp_kitv__user_id__c));
					system.debug(':::::  regExAux despues del replaceall: ' + regExAux);
					system.debug(':::::  !Pattern.matches(regExAux, mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c)): ' + !Pattern.matches(regExAux, mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c)));
					if(!Pattern.matches(regExAux, mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c))) {
						strInvolvedProd = mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c);
						strInvolvedProd += ';' + mapUserProducts.get(visitTM.dwp_kitv__user_id__c);
						mapVisitProducts.put(visitTM.dwp_kitv__visit_id__c, strInvolvedProd);
					}
				}
			}
			mapVisitUpd.put(visitTM.dwp_kitv__visit_id__c, new dwp_kitv__Visit__c(Id = visitTM.dwp_kitv__visit_id__c, gf_visit_users_products_desc__c = mapVisitProducts.get(visitTM.dwp_kitv__visit_id__c)));
		}//FIN FOR


		system.debug('::::: mapVisitUpd : ' + mapVisitUpd);
		if(!mapVisitUpd.isEmpty()) {
			//update mapVisitUpd.values();
			Database.update(mapVisitUpd.values(), false);
		}
	}//fillInvolvedProducts

	/*
	 *	@author		Global Desktop
	 *	@description	Funcion que recalcula  el campo 'Involved Products' los productos a nivel 2 de la visita
	 *
	**/
	public static void recalculateInvolvedProducts(List<dwp_kitv__Visit_Management_Team__c> triggerNew) {
		final Set<Id> setVisitsIds = new Set<Id>();
		for(dwp_kitv__Visit_Management_Team__c visitTM : triggerNew) {
			if(!setVisitsIds.contains(visitTM.dwp_kitv__visit_id__c)) {
				setVisitsIds.add(visitTM.dwp_kitv__visit_id__c);
			}
		}
		List<dwp_kitv__Visit_Management_Team__c> listActualTM;
		listActualTM = new List<dwp_kitv__Visit_Management_Team__c>([SELECT Id, dwp_kitv__visit_id__c, dwp_kitv__user_id__c
																																																					FROM dwp_kitv__Visit_Management_Team__c
																																																					WHERE dwp_kitv__visit_id__c IN :setVisitsIds]);
		system.debug('::::: listActualTM : ' + listActualTM);
		fillInvolvedProducts(listActualTM, true);
	}

    /*
	* @author Global Desktop
	* @Description Actualiza los paises de los miembros de visita en la visita
	*/
    /*public static void updateIPVisitCountry(List <dwp_kitv__Visit_Management_Team__c> triggerNew) {
        // FILTRAR POR RECORD TYPE ?
        Set<Id> setUsersId = new Set<Id>();
        Set<Id> visitIdSet = new Set<Id>();
        Map<Id, String> visitCountriesMap = new Map<Id, String>();

        //Cojo los ids de los usuarios de los miembros de la visita y las visitas
        for(dwp_kitv__Visit_Management_Team__c visitMember : triggerNew) {
            if(visitMember.dwp_kitv__user_id__c != null && !setUsersId.contains(visitMember.dwp_kitv__user_id__c)) {
                setUsersId.add(visitMember.dwp_kitv__user_id__c);
            }
            if(!visitIdSet.contains(visitMember.dwp_kitv__visit_id__c)) {
                visitIdSet.add(visitMember.dwp_kitv__visit_id__c);
            }
        }
        //Recojo los usuarios de Salesforce para coger su país
        Map<Id, User>mapUsers = new Map<Id, User>([SELECT Id, DES_Country__c FROM User WHERE Id IN :setUsersId]);

        System.debug('getVisitCountriesMap: ' + triggerNew);
        visitCountriesMap = getVisitCountriesMap(triggerNew, mapUsers);

        //Recojo las visitas para ponerles el país
        List<dwp_kitv__Visit__c> visitList = new List<dwp_kitv__Visit__c>([SELECT Id, visit_participate_country_desc__c FROM dwp_kitv__Visit__c WHERE Id IN :visitIdSet]);

        //Pongo el país en las oportunidades
        for(dwp_kitv__Visit__c visit : visitList) {
            visit.visit_participate_country_desc__c += visitCountriesMap.get(visit.Id);
            system.debug('visitCountriesMap.get(visit.Id): ' +visitCountriesMap.get(visit.Id));
            System.debug('visit.visit_participate_country_desc__c: ' + visit.visit_participate_country_desc__c);
        }
        System.debug('visitList: ' + visitList);

        update visitList;
    }//FIN updateIPVisitCountry*/


    /*
	* @author Global Desktop
	* @Description Borra los paises de los miembros de visita en la visita
	*/
   /* public static void deleteIPVisitCountry(List <dwp_kitv__Visit_Management_Team__c> triggerOld) {
        // FILTRAR POR RECORD TYPE ?
        Set<Id> setUsersId = new Set<Id>();
        Set<Id> visitIdSet = new Set<Id>();
        Map<Id, String> visitCountriesMap = new Map<Id, String>();

        //Cojo los ids de los usuarios de los miembros de la visita y las visitas
        for(dwp_kitv__Visit_Management_Team__c visitMember : triggerOld) {
            if(!visitIdSet.contains(visitMember.dwp_kitv__visit_id__c)) {
                visitIdSet.add(visitMember.dwp_kitv__visit_id__c);
            }
        }

        //Recojo las visitas para ponerles el país
        List<dwp_kitv__Visit__c> visitList = new List<dwp_kitv__Visit__c>([SELECT Id, visit_participate_country_desc__c, OwnerId FROM dwp_kitv__Visit__c WHERE Id IN :visitIdSet]);

        //Recojo los miembros de visitas de las visitas
        List<dwp_kitv__Visit_Management_Team__c> visitTMList = new List<dwp_kitv__Visit_Management_Team__c>([
            SELECT Id, dwp_kitv__user_id__c, dwp_kitv__visit_id__c from dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__c IN :visitIdSet]);

        //Construyo un set de ids de usuarios - miembros de visita
        for(dwp_kitv__Visit_Management_Team__c visitTMAux : visitTMList) {
            if(!setUsersId.contains(visitTMAux.dwp_kitv__user_id__c)) {
                setUsersId.add(visitTMAux.dwp_kitv__user_id__c);
            }
        }
        //Meto también los owners
        for(dwp_kitv__Visit__c visitAux : visitList) {
            if(!setUsersId.contains(visitAux.OwnerId)) {
                setUsersId.add(visitAux.OwnerId);
            }
        }

        //Recojo los usuarios de Salesforce para coger su país
        Map<Id, User>mapUsers = new Map<Id, User>([SELECT Id, DES_Country__c FROM User WHERE Id IN :setUsersId]);

        visitCountriesMap = getVisitCountriesMap(visitTMList, mapUsers);

        //Añado al mapa los ids de las visitas y sus países - owners
        for(dwp_kitv__Visit__c visitAux : visitList) {
            //Si ya tengo la visita, meto el país del miembro de la visita
            if(visitCountriesMap.get(visitAux.Id) != null) {
                String concat = visitCountriesMap.get(visitAux.Id);
                concat +=  mapUsers.get(visitAux.OwnerId).DES_Country__c + ';' ;
                visitCountriesMap.put(visitAux.Id, concat);
            } else {
                //Meto nueva oportunidad
                visitCountriesMap.put(visitAux.Id, mapUsers.get(visitAux.OwnerId).DES_Country__c + ';');
            }
        }

        //Pongo el país en las visitas
        for(dwp_kitv__Visit__c visit : visitList) {
            visit.visit_participate_country_desc__c = visitCountriesMap.get(visit.Id);
            System.debug('visit.visit_participate_country_desc__c: ' + visit.visit_participate_country_desc__c);
        }
        System.debug('visitList: ' + visitList);
        update visitList;

    }*/

    /*
    * @author Global Desktop
    * @Description Construyo un mapa con los ids de las visitas y sus países - miembros de visita
    */
    /*public static Map<Id, String> getVisitCountriesMap(List<dwp_kitv__Visit_Management_Team__c> visitMTList, Map<Id, User> mapUsers) {
        System.debug('dentro de getVisitCountriesMap');
        Map<Id, String> visitCountriesMap = new Map<Id, String>();
        for(dwp_kitv__Visit_Management_Team__c visitMember : visitMTList) {
            //Si ya tengo la visita, meto el país del miembro de la visita
            if(visitCountriesMap.get(visitMember.dwp_kitv__visit_id__c) != null) {
                System.debug('dentro del if');
                String concat = visitCountriesMap.get(visitMember.dwp_kitv__visit_id__c);
                concat +=  mapUsers.get(visitMember.dwp_kitv__user_id__c).DES_Country__c + ';' ;
                visitCountriesMap.put(visitMember.dwp_kitv__visit_id__c, concat);
            } else {
                System.debug('dentro del else');
                //Meto nueva oportunidad
                visitCountriesMap.put(visitMember.dwp_kitv__visit_id__c, mapUsers.get(visitMember.dwp_kitv__user_id__c).DES_Country__c + ';');
            }
            System.debug('visitCountriesMap: ' + visitCountriesMap);
        }
        return visitCountriesMap;
    }*/
    /*public void logicBeforeDelete(Map<Id, dwp_kitv__Visit_Management_Team__c> triggerOldMap) {
        checkDeleteIPVisitMember(triggerOldMap);
    }*/

    /*
    *   @author Global Desktop
    *   @Description Funcion que, si la oportunidad es IP, no deja borrar a los miembros de la oportunidad si ya ha iniciado sesión en algun momento
    *
    */
    /*private void checkDeleteIPVisitMember(Map<Id, dwp_kitv__Visit_Management_Team__c> triggerOldMap) {
			system.debug('>>>>> triggerOldMap: ' + triggerOldMap);
			Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
			if(gdSettings.URL_Lightning__c != null && gdSettings.URL_Lightning__c != '') {
				final Set<String> setVisitsId = new Set<String>();
				final Set<String> setVisitsURL = new Set<String>();
				final Set<Id> setUserId = new Set<Id>();
				final Set<String> setUserVisitEvent = new Set<String>();
				//Recorro el triggerNew para recuperar todos los Ids de las opps y los usuarios relacionados
				for(dwp_kitv__Visit_Management_Team__c visitTeam : triggerOldMap.values()) {
					if(!setVisitsId.contains(visitTeam.dwp_kitv__visit_id__c)) {
						setVisitsId.add(visitTeam.dwp_kitv__visit_id__c);
					}
					if(!setUserId.contains(visitTeam.dwp_kitv__user_id__c)) {
						setUserId.add(visitTeam.dwp_kitv__user_id__c);
					}
				}

				//Construyo las URLS de las Opps relacionadas que sean inside information
				for(dwp_kitv__Visit__c visit : [SELECT Id, disclosure_info_type__c FROM dwp_kitv__Visit__c WHERE disclosure_info_type__c = :Label.DES_OP_Inside AND Id IN :setVisitsId]) {
						if(!setVisitsURL.contains(gdSettings.URL_Lightning__c + 'lightning/r/dwp_kitv__Visit__c/' + visit.Id + '/view')) {
								setVisitsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/dwp_kitv__Visit__c/' + visit.Id + '/view');
						}
				}
				system.debug('>>>>> setUserId: ' + setUserId);
				system.debug('>>>>> setVisitsURL: ' + setVisitsURL);
				system.debug('>>>>> query: ' + [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
																																		etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
																														FROM etrk__EventTracker_Event__c
																														WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setVisitsURL]);
				if(!setVisitsURL.isEmpty()) {
					//Recorro los eventtracker para ver si el usuario ha visitado la oportunidad que quiere comprobar
					for(etrk__EventTracker_Event__c eventTracker : [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
																																	etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
																													FROM etrk__EventTracker_Event__c
																													WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setVisitsURL]) {
						system.debug('>>>>> eventTracker: ' + eventTracker);
						String visitId = eventTracker.etrk__Location__c.substringBeforeLast('/'); //NOSONAR
						visitId = visitId.substringAfterLast('/');
						if(!setUserVisitEvent.contains(eventTracker.etrk__User__c + '_' + visitId)) {
							setUserVisitEvent.add(eventTracker.etrk__User__c + '_' + visitId);
						}
					}
					for(dwp_kitv__Visit_Management_Team__c visitTeam : triggerOldMap.values()) {
						if(setUserVisitEvent.contains(visitTeam.dwp_kitv__user_id__c + '_' + visitTeam.dwp_kitv__visit_id__c)) {
							visitTeam.addError(Label.ERROR_IP_CANNOT_DELETE_VISIT_MEMBER);
						}
					}
				}

			}

        //etrk__EventTracker_Event__c
    }*/
}