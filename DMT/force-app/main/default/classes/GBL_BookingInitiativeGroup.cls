/************************************************************************
* @name:                GBL_BookingInitiativeGroup
* @author               bbva.com developers
* @date:                2019
* @version:             1.0
* @group:               Global Desktop
* @description:         Interface that implements Client Filter
***************************************************************************/
global without sharing class GBL_BookingInitiativeGroup implements intt.GBL_ClientFilter_interface { //NOSONAR

	/**
	* @description get Initiative Team Filter
	* @return void
	*/
	global List<intt__Team_initiative__c> initiativeTeamFilter(Campaign campana, Map<String,String> mapGroupFilter) {
    final List<User> lstUsers =  [SELECT id FROM User WHERE gf_user_work_product_desc__c INCLUDES(:campana.solution_name_path_desc__c) AND gf_user_work_country_desc__c INCLUDES(:campana.gf_user_country_name__c) ];

    final List<intt__Team_initiative__c> lstInitiativeTeam = new List<intt__Team_initiative__c>();
    final Map<String,String> mapTeam=new map<String,String>();

    //add user to the iniciative group
    for(Integer i = 0; i < lstUsers.size(); i++) {
      if(!mapTeam.containsKey(lstUsers[i].id)) {
      mapTeam.put(lstUsers[i].id,lstUsers[i].id);
      final intt__Team_initiative__c objTeam = new intt__Team_initiative__c();
      objTeam.intt__campaign_id__c = campana.id;
      objTeam.intt__manager_team_id__c = lstUsers[i].id;
      lstInitiativeTeam.add(objTeam);
      }
    }

    return lstInitiativeTeam;
	}

  /**
   * @description get Cient filter
   * @return void
   */
  global List<Account> clientFilter(Campaign campana) {
    //valida el filtro
    if(campana.Type != null && campana.Type == 'Commercial Group' && campana.tier_desc__c != null) {
      throw new initiativeException(system.Label.validationFilterClient);
    }

    return getClientGroup(campana);
  }

  /**
  * @description get Client Group
  * @return void
  **/
  global static List<Account> getClientGroup(Campaign campana) {

    final List<intt__GBL_FilterIniciative__mdt> lstMetadata = [SELECT Id, Label, intt__AccountField__c, intt__InitiativeField__c FROM intt__GBL_FilterIniciative__mdt LIMIT 500];

    String strWhere = ' ';

    for(Integer i = 0; i < lstMetadata.size(); i ++) {
      final String fieldName = lstMetadata[i].intt__InitiativeField__c;
      final String fieldNameClient = lstMetadata[i].intt__AccountField__c;

      if(fieldName != 'country_name__c' && campana.get(fieldName) != null) {
        String valor = String.ValueOf(campana.get(fieldName));
        //si es una lista multiseleccion
        if(valor.indexOf(';') > 0) {
          valor = valor.replace(';','\',\'');
          strWhere = strWhere + ' and ' + fieldNameClient + ' in(\'' + valor + '\')';
        } else {
          strWhere = strWhere + ' and ' + fieldNameClient + '=\'' + valor + '\'';
        }
      }
    }

    String query = '';    //NOSONAR

    if(strWhere.trim().length() > 0) {    //NOSONAR
      List<String> recordTypes = new List<String> {'Group'};    //NOSONAR
      query = 'select id,name from Account where ('+strWhere+') and RecordType.Name IN :recordTypes';
    } else {
      return new List<Account>();    //NOSONAR
    }

    //lista las cuentas
    query = query.replace('(  and','(');
    List<Account> lstAccount = Database.query(query);    //NOSONAR

    System.debug(lstAccount);
    System.debug(query);
    return lstAccount;
  }

  /**
  * @description class throw exception
  * @return void
  */
  class initiativeException extends Exception {}
}