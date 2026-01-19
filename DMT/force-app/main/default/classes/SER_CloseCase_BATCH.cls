/*-----------------------------------------------------------------------------------------------
    Company:       Accenture
    Description:   Clase globar para el batch de cerrado de casos

    History:
    <Date>                  <Author>                <Change Description>
                                                    Initial version
-------------------------------------------------------------------------------------------------*/

global without sharing class SER_CloseCase_BATCH implements Database.Batchable<sObject> {

  /* Set de Id de los casos hijos que queremos atualizar.*/
  Set<Id> setCaseToUpdateId;
  /*Mapa de los casos actualizados mapChildrenCasesToUpdate*/
  Map<Id,Case> mapCCasesToUpdate;
  /*Mapa del caso maestro/padre */
  Map<Id,Case> mapMasterCases;
  /*Mapa con los valores de la picklist*/
  Map<String,String> mapPicklistValues;

  /*-----------------------------------------------------------------------------------------------
      Company:       Accenture
      Description:   Constructor SER_CloseCase_BATCH
  -------------------------------------------------------------------------------------------------*/
  global SER_CloseCase_BATCH( Map<Id,Case> mapMasterCases,Map<Id,Case> mapCCasesToUpdate, Map<String,String> mapPicklistValues ) {

    this.mapCCasesToUpdate = mapCCasesToUpdate;
    this.mapMasterCases = mapMasterCases;
    this.setCaseToUpdateId = mapCCasesToUpdate.keyset();
    this.mapPicklistValues = mapPicklistValues;
  }

  /*-----------------------------------------------------------------------------------------------
      Company:       Accenture
      Description:   QueryLocator -> query para obtener los casos hijos de los casos maestros
      
  -------------------------------------------------------------------------------------------------*/
  global Database.QueryLocator start(Database.BatchableContext dataBC) {
    String query;
    query = 'SELECT  Id,ParentId,AccountId,SER_Asset__c,SER_Master_Case__c ,SER_Close__c,SER_Type_EST__c,SER_Pre_liquidacion__c,SER_Post_liquidation__c,SER_Web_App__c,Subject,Description,SER_Classification__c,SER_Type_GM__c,SER_Subtype_GM__c,SER_MailingGroup__c,SER_Outbound_Mailbox__c,SER_Business_Case_Type__c,Status, activity_status_type__c, gf_case_channel_source_name__c, case_channel_source_type__c, gf_case_environment_name__c, gf_case_countries_desc__c, gf_case_creation_type__c, SER_Initial_Classification__c FROM  Case  WHERE   Id IN :setCaseToUpdateId';
    return Database.getQueryLocator(query);
  }

  /*-----------------------------------------------------------------------------------------------
      Company:       Accenture
      Description:   Ejecución del batch
  -------------------------------------------------------------------------------------------------*/
  global void execute(Database.BatchableContext dataBC, List<Case> scope) {

    final List<Case> listToUpdate = new List<Case>();     //Lista de casos a actualizar

    for (Case c: scope) {

      //Definimos el caso maestro y el hijo
      Case mastercase;

      //Copiamos el caso hijo del scope con los valores actualizados
      //Case auxcase;
      //auxcase = c;

      if(c.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM || c.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC) {
        mastercase = mapMasterCases.get(c.ParentId);
      }

      SER_CaseMethods_HELPER_ParentCp.copyParentFieldsUPDATE(c, mastercase, mapPicklistValues);

      //Añadimos el caso actualizado del scope a la lista de actualiar
      listToUpdate.add(c);
    }

    if(!listToUpdate.isEmpty()) {
      //Actualizamos la lista de casos hijos
      Database.update(listToUpdate, false);
    }
  }
  /*-----------------------------------------------------------------------------------------------
      Company:       Accenture
      Description:   Finish empty
  -------------------------------------------------------------------------------------------------*/
  global void finish(Database.BatchableContext dataBC) {
    System.debug('finish(Database.BatchableContext dataBC)-> '+dataBC);
  }
}