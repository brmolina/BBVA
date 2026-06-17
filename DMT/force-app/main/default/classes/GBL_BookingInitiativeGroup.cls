/************************************************************************
 * @name:                GBL_BookingInitiativeGroup
 * @author               bbva.com developers
 * @date:                2019
 * @version:             1.0
 * @group:               Global Desktop
 * @description:         Interface that implements Client Filter
 ***************************************************************************/
global without sharing class GBL_BookingInitiativeGroup implements intt.GBL_ClientFilter_interface{
   //NOSONAR
  /**********************************************************************************************************
   * @name        initiativeTeamFilter
   * @author      bbva.com developers
   * @created     2019
   * @description Obtiene el equipo de la iniciativa filtrando usuarios por solución y país.
   * @param       campana           Campaign   Campaña con los valores a filtrar.
   * @param       mapGroupFilter    Map<String, String>   Filtros adicionales para el grupo.
   * @return      List<intt__Team_initiative__c>   Lista de equipos de la iniciativa.
   **********************************************************************************************************/
  global List<intt__Team_initiative__c> initiativeTeamFilter(Campaign campana, Map<String, String> mapGroupFilter){
    final List<User> lstUsers = [SELECT id
                                 FROM User
                                 WHERE gf_user_work_product_desc__c INCLUDES( :campana.solution_name_path_desc__c) AND gf_user_work_country_desc__c INCLUDES( :campana.gf_user_country_name__c)];

    final List<intt__Team_initiative__c> lstInitiativeTeam = new List<intt__Team_initiative__c>();
    final Map<String, String> mapTeam = new map<String, String>();

    //add user to the iniciative group
    for (Integer i = 0; i < lstUsers.size(); i++){
      if (!mapTeam.containsKey(lstUsers[i].id)){
        mapTeam.put(lstUsers[i].id, lstUsers[i].id);
        final intt__Team_initiative__c objTeam = new intt__Team_initiative__c();
        objTeam.intt__campaign_id__c = campana.id;
        objTeam.intt__manager_team_id__c = lstUsers[i].id;
        lstInitiativeTeam.add(objTeam);
      }
    }

    return lstInitiativeTeam;
  }

  /**********************************************************************************************************
   * @name        clientFilter
   * @author      bbva.com developers
   * @created     2019
   * @description Valida el filtro de cliente y obtiene la lista de cuentas filtradas.
   * @param       campana    Campaign   Campaña con los valores a filtrar.
   * @return      List<Account>        Lista de cuentas filtradas.
   **********************************************************************************************************/
  global List<Account> clientFilter(Campaign campana){
    //valida el filtro
    if (campana.Type != null && campana.Type == 'Commercial Group' && campana.tier_desc__c != null){
      throw new initiativeException(system.Label.validationFilterClient);
    }

    return getClientGroup(campana);
  }

  /**********************************************************************************************************
   * @name        getClientGroup
   * @author      bbva.com developers
   * @created     2019
   * @description Devuelve la lista de cuentas (Account) que cumplen los filtros definidos en los metadatos
   *              y en la campaña, validando los campos y escapando los valores para evitar SOQL Injection.
   * @param       campana    Campaign   Campaña con los valores a filtrar.
   * @return      List<Account>        Lista de cuentas filtradas.
   **********************************************************************************************************/
  global static List<Account> getClientGroup(Campaign campana){
    final List<intt__GBL_FilterIniciative__mdt> lstMetadata = [SELECT Id, Label, intt__AccountField__c, intt__InitiativeField__c
                                                               FROM intt__GBL_FilterIniciative__mdt
                                                               LIMIT 500];
    Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    List<String> conditions = new List<String>();

    for (Integer i = 0; i < lstMetadata.size(); i++){
      final String fieldName = lstMetadata[i].intt__InitiativeField__c;
      final String fieldNameClient = lstMetadata[i].intt__AccountField__c;

      // Validar campo
      if (!accountFields.containsKey(fieldNameClient)){
        throw new initiativeException('Campo no permitido en Account: ' + fieldNameClient);
      }

      if (fieldName != 'country_name__c' && campana.get(fieldName) != null){
        String valor = String.valueOf(campana.get(fieldName));
        if (valor.indexOf(';') > 0){
          List<String> valores = new List<String>();
          for (String v : valor.split(';')){
            valores.add(String.escapeSingleQuotes(v.trim()));
          }
          conditions.add(fieldNameClient + ' IN (\'' + String.join(valores, '\',\'') + '\')');
        } else{
          valor = String.escapeSingleQuotes(valor);
          conditions.add(fieldNameClient + ' = \'' + valor + '\'');
        }
      }
    }

    if (conditions.isEmpty()){
      return new List<Account>();
    }

    List<String> recordTypes = new List<String>{ 'Group' };
    String query = 'SELECT Id, Name FROM Account WHERE (' + String.join(conditions, ' AND ') + ') AND RecordType.Name IN :recordTypes';

    query = query.replace('(  and', '(');
    List<Account> lstAccount = Database.query(query);

    System.debug(lstAccount);
    System.debug(query);
    return lstAccount;
  }

  /**********************************************************************************************************
   * @name        initiativeException
   * @author      bbva.com developers
   * @created     2019
   * @description Excepción personalizada para errores en la iniciativa.
   **********************************************************************************************************/
  class initiativeException extends Exception{
  }

}