/**********************************************************************************
* @author       VASS
* @date         20/11/2019
* @description  Helper para objeto Chatter_NBC_Virtual__c
* @Revision
                2019/11/20 Se crea la clase. Agregada logica para sharing
**********************************************************************************/
@SuppressWarnings('sf:AvoidGetSetMethods, sf:CyclomaticComplexity')
public without sharing class Chatter_NBC_Virtual_TriggerHelper {

  /*
   * SINGLETON PATTERN
   */
  private static Chatter_NBC_Virtual_TriggerHelper instance;

  /*
   * getInstance
   */
  private Chatter_NBC_Virtual_TriggerHelper() {  }

  /*
   * getInstance
   */
  public static Chatter_NBC_Virtual_TriggerHelper getInstance() {
    if (instance == null) instance = new Chatter_NBC_Virtual_TriggerHelper();//NOSONAR
    return instance;
  }

  /*
   *  @author Global Desktop
   *  @Description  Contiene la logica necesaria para gestionar el sharing via apex.
   *
  **/
  public static void createApexSharing(Map<Id, Chatter_NBC_Virtual__c> triggerNewMap) {
    final Set<String> setObjTypesSP = new Set<String>{Label.DES_Template_APIName, Label.Opportunity_Name};
    final Set<String> setObjTypesNBC = new Set<String>{Label.Opportunity_Name};
    system.debug( '::::: setObjTypesSP : ' + setObjTypesSP);
    system.debug( '::::: setObjTypesNBC : ' + setObjTypesNBC);
    List<Chatter_NBC_Virtual__Share> listShareToInsert;
    listShareToInsert = new List<Chatter_NBC_Virtual__Share>();
    //Obtengo el grupo del los usuarios de SP
    final Id groupSPTeam = getSPGroupId();
    //Obtengo el grupo del comite virtual
    final Id groupIdNBCVirtual = gtNBCVirtualGroupId();
    system.debug( '::::: groupSPTeam : ' + groupSPTeam);
    system.debug( '::::: groupIdNBCVirtual : ' + groupIdNBCVirtual);
    //Mapa que contiene como clave el Id de la oportunidad y como valor el Id del registro del chatter NBC Virtual relacionado
    final Map<Id, Id> mapOppIdCNBCVId = new Map<Id, Id>();
    //Mapa que contiene como clave el Id del Template y como Value el Id de la oportunidad que tiene asociada
    final Map<Id, Id> mapTemplIdOppId = getMapTemplIdOppId(triggerNewMap.values()); //NOSONAR
    for(Chatter_NBC_Virtual__c cNBCVirt : triggerNewMap.values()) {
      //Comparto el registro con el grupo de SP
      if(groupSPTeam != null && setObjTypesSP.contains(cNBCVirt.tipo_objeto__c)) {
        listShareToInsert.add(createChatterNBCVirtualShare(cNBCVirt.Id, groupSPTeam, 'Edit', Label.APEX_SHARING_REASON_GROUP_SP));
      }

      //Comparto el registro con el grupo de NBC Virtual
      if(groupIdNBCVirtual != null && setObjTypesNBC.contains(cNBCVirt.tipo_objeto__c)) {
        listShareToInsert.add(createChatterNBCVirtualShare(cNBCVirt.Id, groupIdNBCVirtual, 'Edit', Label.APEX_SHARING_REASON_GROUP_NBC_VIRTUAL));
      }

      //Relleno el mapa mapOppIdCNBCVId
      if(cNBCVirt.tipo_objeto__c != null
      && cNBCVirt.id_objeto__c != null) {
        if(cNBCVirt.tipo_objeto__c == Label.Opportunity_Name) {
          mapOppIdCNBCVId.put(cNBCVirt.id_objeto__c, cNBCVirt.Id);
        } else if(cNBCVirt.tipo_objeto__c == Label.DES_Template_APIName) {
          mapOppIdCNBCVId.put(mapTemplIdOppId.get(cNBCVirt.id_objeto__c), cNBCVirt.Id);
        }

      }

    }
    system.debug('::::: mapOppIdCNBCVId : ' + mapOppIdCNBCVId);
    //COMPARTO EL CHATTER CON LOS MIEMBROS DE CADA OPORTUNIDAD
    listShareToInsert.addAll(shareWithOppsTeams(mapOppIdCNBCVId));

    system.debug('::::: listShareToInsert : ' + listShareToInsert);
    if(!listShareToInsert.isEmpty()) {
      insert listShareToInsert;
    }
  }

  /*
   *  @author Global Desktop
   *  @Description  Contiene la logica que genera un mapa que contiene
   *                como clave el Id del Template y como Value el Id de la oportunidad que tiene asociada
   *  @return
  **/
  public static Map<Id, Id> getMapTemplIdOppId(List<Chatter_NBC_Virtual__c> triggerNew) {
    Map<Id, Id> mapTemplIdOppId;
    mapTemplIdOppId = new Map<Id, Id>();
    final Set<Id> setTemplId = new Set<Id>();
    for(Chatter_NBC_Virtual__c chNBC : triggerNew) {
      if(chNBC.tipo_objeto__c == Label.DES_Template_APIName) {
        setTemplId.add(chNBC.id_objeto__c);
      }
    }

    for(DES_Template__c templ : [SELECT Id, opportunity_id__c FROM DES_Template__c WHERE Id IN :setTemplId]) {
      mapTemplIdOppId.put(templ.Id, templ.opportunity_id__c);
    }
    system.debug('::::: mapTemplIdOppId : ' + mapTemplIdOppId);
    return mapTemplIdOppId;
  }

  /*
   *  @author Global Desktop
   *  @Description  Contiene la logica necesaria para gestionar el sharing via apex.
   *
  **/
  private static List<Chatter_NBC_Virtual__Share> shareWithOppsTeams(Map<Id, Id> mapOppIdCNBCVId) {
    final List<Chatter_NBC_Virtual__Share> listShareToInsert = new List<Chatter_NBC_Virtual__Share>();

    //Recorro los miembros de las oportunidades y voy creando el share al Chatter_NBC_Virtual__c correspondiente
    for (DES_Opportunity_Management_member__c oppTM : [SELECT Id, DES_User__c, DES_Opportunity__c FROM DES_Opportunity_Management_member__c WHERE DES_Opportunity__c IN :mapOppIdCNBCVId.keySet() AND DES_User__r.isActive = true]) {
      system.debug('::::: mapOppIdCNBCVId.get(oppTM.DES_Opportunity__c): ' + mapOppIdCNBCVId.get(oppTM.DES_Opportunity__c));
      if(mapOppIdCNBCVId.get(oppTM.DES_Opportunity__c) != null) {
        listShareToInsert.add(createChatterNBCVirtualShare(mapOppIdCNBCVId.get(oppTM.DES_Opportunity__c), oppTM.DES_User__c, 'Edit', Label.APEX_SHARING_REASON_CHATTER_NBC_VIRTUAL_OPP_TEAM_MEMBER));
      }
    }


    return listShareToInsert;
  }

  /*
   *  @author Global Desktop
   *  @Description  Contiene la logica necesaria para gestionar el sharing via apex.
   *
  **/
  private static Id getSPGroupId() {
    return [SELECT Id FROM Group WHERE DeveloperName = :Label.SP_Users_Group_DevName LIMIT 1].Id;
  }

  /*
   *  @author Global Desktop
   *  @Description  Devuelve el ID del grupo
   *
  **/
  private static Id gtNBCVirtualGroupId() {
    return [SELECT Id FROM Group WHERE DeveloperName = :Label.GroupNBCVirtualDevName LIMIT 1].Id;
  }

  /*
   *  @author Global Desktop
   *  @Description  Funcion que genera el __Share del objeto con las caracteristicas que se pasan por parametro
   *
  **/
  public static Chatter_NBC_Virtual__Share createChatterNBCVirtualShare(Id recordId, Id userOrGroupId, String accessType, String apexReasonText) {

    final Chatter_NBC_Virtual__Share chatterNBCVShare  = new Chatter_NBC_Virtual__Share();
    chatterNBCVShare.ParentId = recordId;
    chatterNBCVShare.UserOrGroupId = userOrGroupId;
    chatterNBCVShare.AccessLevel = accessType;
    if(apexReasonText == Label.APEX_SHARING_REASON_GROUP_SP) {//NOSONAR
      chatterNBCVShare.RowCause = Schema.Chatter_NBC_Virtual__Share.RowCause.GROUP_SP__c;
    } else if(apexReasonText == Label.APEX_SHARING_REASON_GROUP_NBC_VIRTUAL) {//NOSONAR
      chatterNBCVShare.RowCause = Schema.Chatter_NBC_Virtual__Share.RowCause.GROUP_NBC_VIRTUAL__c;
    } else if(apexReasonText == Label.APEX_SHARING_REASON_CHATTER_NBC_VIRTUAL_OPP_TEAM_MEMBER) {//NOSONAR
      chatterNBCVShare.RowCause = Schema.Chatter_NBC_Virtual__Share.RowCause.OPP_TEAM_MEMBER__c;
    } else {
      chatterNBCVShare.RowCause = Schema.Chatter_NBC_Virtual__Share.RowCause.Manual;
    }

    return chatterNBCVShare;

  }

}