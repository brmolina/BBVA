/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  GBL_TeamInitiative class
**********************************************************************************/
global without sharing class GBL_TeamInitiative implements intt.GBL_Initiative_interface { //NOSONAR
  /**
  * @author Global Desktop
  * @Description clientInitiativeTeamFilter
  */
  global List<intt__Team_initiative__c> clientInitiativeTeamFilter(List<cond__Account_Campaign__c> listAccCampaign) {
    return new List<intt__Team_initiative__c>();
  }

  /**
  * @author Global Desktop
  * @Description clientInitiativeTeamFilterLocal
  */
  global List<intt__Team_initiative__c> clientInitiativeTeamFilterLocal(List<cond__Account_Campaign__c> listAccCampaign) {
    //add user team account to the initiative group
    //SELECT AccountId,UserId,id FROM AccountTeamMember
    final Map<Id, cond__Account_Campaign__c> mapFilialId = new Map<Id, cond__Account_Campaign__c>();
    final List<cond__Account_Campaign__c> lstAccountCamp = [SELECT Id,cond__campaign_id__c,cond__participant_id__c,cond__campaign_id__r.soluction_category_id__c, cond__campaign_id__r.gf_user_country_name__c FROM cond__Account_Campaign__c WHERE Id IN :listAccCampaign];
    for(cond__Account_Campaign__c iAccountCampaign : lstAccountCamp) {

      if(mapFilialId.containsKey(iAccountCampaign.cond__participant_id__c)==false) {
        mapFilialId.put(iAccountCampaign.cond__participant_id__c, iAccountCampaign);
      }
    }

    return clientInitiativeTeamFilterAux(mapFilialId);
  }

  /*
  * @author Global Desktop
  * @Desription Helper for initiativeTeamFilter
  */
  public List<User> matchCntryInit(Campaign campana, User user, set<Id> matchCountry, list<User> userList) {
	if(campana.gf_user_country_name__c != null && campana.gf_user_country_name__c.contains(';')) {
		for(String str: campana.gf_user_country_name__c.split(';')) {
			if(user.gf_user_work_country_desc__c!= null && user.gf_user_work_country_desc__c.contains(str)) {
				userList.add(user);
			}
		}
	} else {
		if(campana.gf_user_country_name__c != null && user.gf_user_work_country_desc__c!= null && user.gf_user_work_country_desc__c.contains(campana.gf_user_country_name__c)) {
			userList.add(user);
		}
	}
	return userList;
  }
  /*
  * @author Global Desktop
  * @Desription Helper for initiativeTeamFilter
  */
  public set<Id> matchPrdInit (Campaign campana, List<User> userList, set<Id> matchProduct) {
	for(User user : userList) {
		if(campana.solution_name_path_desc__c != null && campana.solution_name_path_desc__c.contains(';')) {
			for(String str: campana.solution_name_path_desc__c.split(';')) {
				if(user.gf_user_work_product_desc__c!= null && user.gf_user_work_product_desc__c.contains(str)) {
					matchProduct.add(user.Id);
				}
			}
		} else {
			if(campana.solution_name_path_desc__c != null && user.gf_user_work_product_desc__c!= null && user.gf_user_work_product_desc__c.contains(campana.solution_name_path_desc__c)) {
				matchProduct.add(user.Id);
			}
		}
	}
	
	return matchProduct;
  }

  /**
  * @author Global Desktop
  * @Description initiativeTeamFilter
  */
  global List<intt__Team_initiative__c> initiativeTeamFilter(Campaign campana) {
	final List<User> lstUFilter = [SELECT Id,profile.name, gf_user_work_country_desc__c, gf_user_work_product_desc__c   //NOSONAR
                                 FROM User
                                 WHERE isActive = true and (Profile.Name = 'BBVA Desktop GM Standard' OR Profile.Name = 'BBVA Desktop IBF Standard'
                                 OR Profile.Name = 'BBVA Desktop GTB Standard') and (gf_user_work_country_desc__c != null OR gf_user_work_product_desc__c != null)];
	set<Id> matchCountry;
  	matchCountry = new set<Id>();
  	List<user> userFilter = new List<user>();
	set<Id> matchProduct;
  	matchProduct = new set<Id>();
	for(User user : lstUFilter) {
		//Para país
		userFilter = matchCntryInit(campana,user,matchCountry, userFilter);
	}
	//Para producto
	matchProduct = matchPrdInit(campana,userFilter,matchProduct);
	
	final List<intt__Team_initiative__c> lstInitiativeTeam = new List<intt__Team_initiative__c>();
	for(Id userId : matchProduct) {
		//if(matchProduct.contains(userId)) {
            final intt__Team_initiative__c objTeam = new intt__Team_initiative__c();
            objTeam.intt__campaign_id__c = campana.id;
            objTeam.intt__manager_team_id__c = userId;
            lstInitiativeTeam.add(objTeam);
		//}
	}

    return lstInitiativeTeam;
  }

  /**
  * @author Global Desktop
  * @Description clientInitiativeTeamFilterAux
  */
  public List<intt__Team_initiative__c> clientInitiativeTeamFilterAux(Map<Id, cond__Account_Campaign__c> mapFilialId) {
    List<intt__Team_initiative__c> listTI;
    listTI = new List<intt__Team_initiative__c>();
    // consulta los transaccional banker y global banker de las cuentas
    for(DES_BBVA_Management_team__c iBBVATeam : [SELECT Id, DES_Client__c, DES_Member_Role__c, DES_Local_Banker_Country__c, DES_Client__r.DES_Tier__c, DES_User__c FROM DES_BBVA_Management_team__c WHERE DES_Client__c IN :mapFilialId.keySet() AND (DES_Member_Role__c =: Label.DES_ROLE_GLOBAL_BANKER OR DES_Member_Role__c =: Label.DES_Role_Transactional_Banker)]) {

      //filtra los usuarios que tengan el filtro
      if((iBBVATeam.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER && (iBBVATeam.DES_Client__r.DES_Tier__c == '00000021' // CIB-Gold
      || iBBVATeam.DES_Client__r.DES_Tier__c == '00000020')) // CIB-Platinum
      || (iBBVATeam.DES_Member_Role__c == Label.DES_Role_Transactional_Banker && (iBBVATeam.DES_Client__r.DES_Tier__c == '00000022' //CIB-Silver
      || (mapFilialId.get(iBBVATeam.DES_Client__c).cond__campaign_id__r.soluction_category_id__c == 'GTB'
      && iBBVATeam.DES_Local_Banker_Country__c == mapFilialId.get(iBBVATeam.DES_Client__c).cond__campaign_id__r.gf_user_country_name__c)))) {

        final intt__Team_initiative__c iTeamInitiative = new intt__Team_initiative__c(
          intt__gf_group_campaign_id__c = mapFilialId.get(iBBVATeam.DES_Client__c).Id,
          intt__manager_team_id__c = iBBVATeam.DES_User__c
          );
        listTI.add(iTeamInitiative);
      }
    }
    return listTI;
  }
}