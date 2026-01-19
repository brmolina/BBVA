/*
 *  @author Global Desktop
 *  @Description Clase que contiene las funciones necesarias para completar los registro del objeto KPIS.
 *
**/
@SuppressWarnings('sf:AvoidUsingTestIsRunningTest, sf:AvoidSoqlWithNegativeLogic')
public without sharing class KPI_Logic_Helper {

  /*
   * SINGLETON PATTERN
   */
  private static KPI_Logic_Helper instance;

  /*
   * Mapa con un string como key (expired,won,lost) y como value el numero total de oportunitdades
   */
  private static final Map<String, Integer> MAPDATA = new Map<String, Integer>();

  /*
   * Configuracion de los KPI
   */
   private static KPI_Configuration__mdt kpiConfig;

  /*
   * getInstance
   */
  private KPI_Logic_Helper() {  }

  /*
   * getInstance
   */
  @SuppressWarnings('sf:AvoidGetSetMethods')
  public static KPI_Logic_Helper getInstance() {
    if (instance == null) instance = new KPI_Logic_Helper();//NOSONAR
    return instance;
  }

  /*
   *  @author Global Desktop
   *  @Description  Funcion que genera el registro nuevo del objeto KPIS con el resumen del mes anterior
   *
   */
  public void createKPIRecord (Id kpiId) {
    gtOpportunities();
    gtKPIConfiguration();
    system.debug('::::: kpiConfig : ' + kpiConfig);
    KPIS__c newKPI = new KPIS__c(); //NOSONAR
    if(kpiId != null) {
      newKPI.Id = kpiId;
    }
    newKPI.Name = Label.KPI_NAME_OPPS_BANKER;
    newKPI.data_actual_date__c = Date.today();
    newKPI.gf_opportunity_won_number__c = MAPDATA.get(Label.DES_Closed_Won);
    newKPI.gf_opportunity_lost_number__c = MAPDATA.get(Label.DES_Closed_Lose);
    newKPI.gf_opportunity_expired_number__c = MAPDATA.get(Label.Opportunity_expired);
    newKPI.gf_live_opportunity_number__c = MAPDATA.get(Label.DES_Alive);
    if((kpiConfig != null
    && kpiConfig.Total_of_bankers__c == Label.KPI_STATIC
    && kpiConfig.Static_number_of_bankers__c > 0) || Test.isRunningTest()) {//SI ESTA CONFIGURADO PARA QUE SEA DINAMICO
      newKPI.gf_opportunity_managers_number__c = kpiConfig.Static_number_of_bankers__c;
    } else { // SI ESTÁ CONFIGURADO PARA QUE SEA ESTÁTICO
      newKPI.gf_opportunity_managers_number__c = gtNumberOfBankers();
    }
    newKPI.gf_opportunity_close_number__c = MAPDATA.get(Label.DES_Closed_Won) + MAPDATA.get(Label.DES_Closed_Lose);
    system.debug('>>>>> newKPI: ' + newKPI);
    upsert newKPI;
  }//FIN createKPIRecord

  /*
   *  @author Global Desktop
   *  @Description  Funcion que calcula el de banqueros miembros de cuentas y que
   *
   */
  public Integer gtNumberOfBankers () {//NOSONAR
    final Id userIntegratorId = [SELECT Id FROM User WHERE ID_User__c = :Label.USER_INTEGRATOR_ID_USER LIMIT 1].Id;
    final Set<String> setUsrBnkrsRls = new Set<String>{Label.DES_ROLE_GLOBAL_BANKER , Label.DES_Role_Transactional_Banker};
    final List<AggregateResult> listBBVAMTeam = new List<AggregateResult>([SELECT DES_User__C, DES_User__r.Name
                                                                    FROM DES_BBVA_Management_team__c
                                                                    WHERE CreatedById = :userIntegratorId AND DES_Member_Role__c IN :setUsrBnkrsRls
                                                                    GROUP BY DES_User__c, DES_User__r.Name]);
    system.debug('::::: calculateTotalBankers - listBBVAMTeam: ' + listBBVAMTeam);
    Integer numberOfBankers;
    numberOfBankers = listBBVAMTeam.size();
    return numberOfBankers;
  }//FIN gtNumberOfBankers

  /*
   *  @author Global Desktop
   *  @Description  Funcion que rellena el mapa que cuenta las oportunidades ganadas, perdidas, expiradas y vivas
   *
   */
  public void gtOpportunities () {
    resetMAPDATA();
    for (AggregateResult aggRes : [SELECT COUNT(Id) oppsCount, StageName FROM Opportunity WHERE StageName != :Label.DES_Closed_Won AND StageName != :Label.DES_Closed_Lose GROUP BY StageName LIMIT 50000]) {
      system.debug('::::: aggRes : ' + aggRes);
      MAPDATA.put((String)aggRes.get('StageName'), (Integer)aggRes.get('oppsCount'));
    }

    //PARA OPORTUNIDADES CERRADAS EN ESTE MES
    for (AggregateResult aggRes : [SELECT COUNT(Id) oppsCount, StageName FROM Opportunity WHERE DES_Date_Won_Lost__c = THIS_MONTH AND (StageName = :Label.DES_Closed_Won OR StageName = :Label.DES_Closed_Lose) GROUP BY StageName LIMIT 50000]) {
      system.debug('::::: aggRes : ' + aggRes);
      MAPDATA.put((String)aggRes.get('StageName'), (Integer)aggRes.get('oppsCount'));
    }

    system.debug('::::: MAPDATA : ' + MAPDATA);
    MAPDATA.put(Label.Opportunity_expired, Database.countQuery('SELECT COUNT() FROM Opportunity WHERE DES_Date_Won_Lost__c = THIS_MONTH AND StageName = \'' + String.escapeSingleQuotes(Label.DES_Closed_Lose) + '\' AND DES_Reasons_Lost__c = \'' + String.escapeSingleQuotes(Label.Opportunity_expired) + '\'')); //EXPIRADAS
    MAPDATA.put(Label.DES_Alive, MAPDATA.get(Label.DES_Draft) + MAPDATA.get(Label.DES_Proposal) + MAPDATA.get(Label.DES_Approvals) + MAPDATA.get(Label.DES_Ready_to_close));
  }//FIN gtOpportunities

  /*
   *  @author Global Desktop
   *  @Description  Funcion que obtiene el registro de configuración del KPI
   *
   */
  public void gtKPIConfiguration () { //NOSONAR
    kpiConfig = [SELECT Total_of_bankers__c, Static_number_of_bankers__c FROM KPI_Configuration__mdt LIMIT 1];
  }//FIN gtKPIConfiguration

  /*
   *  @author Global Desktop
   *  @Description  Funcion que resetea los valores del mapa MAPDATA a 0 para ALL las Stages
   *
   */
  private void resetMAPDATA () { //NOSONAR
    MAPDATA.put(Label.DES_Draft, 0);
    MAPDATA.put(Label.DES_Proposal, 0);
    MAPDATA.put(Label.DES_Approvals, 0);
    MAPDATA.put(Label.DES_Ready_to_close, 0);
    MAPDATA.put(Label.DES_Closed_Won, 0);
    MAPDATA.put(Label.DES_Closed_Lose, 0);
  }//FIN resetMAPDATA



  /*
   *  @author Global Desktop
   *  @Description  Funcion que contiene la lógica para actualizar los KPIS en tiempo real desde el trigger de Opp
   *
   */
  public void kpiLogic () {
    final Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
    if(gdSettings.Enable_KPIS_Logic__c) {
      final List<KPIS__c> listKPIS = new List<KPIS__c>([SELECT Id, gf_opportunity_lost_number__c, gf_opportunity_close_number__c, gf_opportunity_won_number__c, gf_opportunity_expired_number__c,
                                                      data_actual_date__c, gf_live_opportunity_number__c, month_name__c, gf_opportunity_managers_number__c, gf_average_managed_oppy_number__c
                                                FROM KPIS__c
                                                WHERE month_number__c = :Date.today().month()
                                                ORDER BY LastModifiedDate DESC]);
      system.debug('::::: listKPIS : ' + listKPIS);
      if (listKPIS.isEmpty()) {
        createKPIRecord(null);
      } else {
        createKPIRecord(listKPIS.get(0).Id);
      }
    }
  }// FIN kpiLogic

  /*
   *  @author Global Desktop
   *  @description  Función que comprueba si cumple las condiciones para que, durante la ejecucion del trigger de oportunidades, se actualicen los KPIs
   *
  **/
  public void checkNeedUpdKpi(Boolean needUpdate, Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {//NOSONAR
    Boolean isUpdNeeded = needUpdate;
    if(!needUpdate) {
      for(Opportunity opp : triggerNewMap.values()) {
        if(triggerOldMap != null && opp.StageName != triggerOldMap.get(opp.Id).StageName
        && (opp.StageName == Label.DES_Closed_Won || opp.StageName == Label.DES_Closed_Lose
          || triggerOldMap.get(opp.Id).StageName == Label.DES_Closed_Won || triggerOldMap.get(opp.Id).StageName == Label.DES_Closed_Lose
          || opp.DES_Reasons_Lost__c == Label.Opportunity_expired || triggerOldMap.get(opp.Id).DES_Reasons_Lost__c == Label.Opportunity_expired)) {// SI HA CAMBIADO EL STAGE Y  (ANTES O AHORA ERA CLOSED WON O LOST O SI LA REASON ANTES ERA O AHORA ES EXPIRADA)
          isUpdNeeded = true;
        }
      }
    }

    if(isUpdNeeded) {
      kpiLogic();
    }
  }

}