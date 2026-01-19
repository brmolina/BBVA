/*
* Clase para sobreescribir el buscador del componente seeker en OPR
*/
@SuppressWarnings('sf:AvoidFinalLocalVariable,sf:LocalVariableCouldBeFinal')
global with sharing class SeekerOverride implements sekr.Seeker_Interface_Service {//NOSONAR
/*
* Method que sobreescribe el buscador del componente seeker en OPR
*/
global static List<sekr.Seeker_Result_Wrapper_Service> seek(sekr__Seeker_Config_Item__mdt metadata, String searchString, List<String> selectedIds,Integer maxResults) {
    List<sekr.Seeker_Result_Wrapper_Service> results;
    results = new List<sekr.Seeker_Result_Wrapper_Service>();
    final String searchKey2 = searchString + '*';
    final List<List<Opportunity>>lstOfRecordsSOSL = [FIND :searchKey2 IN NAME FIELDS RETURNING Account(id, Name, DES_Structure_Type__c WHERE DES_Structure_Type__c = 'Subsidiary')];
    system.debug('lstOfRecordsSOSL---------------->'+lstOfRecordsSOSL);
    List < Id > lstIdFilt;
    lstIdFilt = new List < Id > ();
    List < Account > lstFiltrada;
    lstFiltrada = new List <Account> ();
    if(lstOfRecordsSOSL != null) {
      for(List<SObject> lObject : lstOfRecordsSOSL) {
          for(SObject op : lObject) {
              lstIdFilt.add(String.valueof(op.get('Id')));
          }
      }
      lstFiltrada = [SELECT id, Name, DES_Structure_Type__c FROM Account WHERE id =:lstIdFilt];

      for (Account obj : lstFiltrada) {
        String employeeId = obj.Id;
        Id salesforceId = obj.Id;
        String primaryField = obj.Name;
        String secondaryFields = obj.DES_Structure_Type__c;
        String entity = 'Account';
        String icon = 'standard:account';
        String type = 'Account';
        system.debug('type------>'+type);
        results.add(new sekr.Seeker_Result_Wrapper_Service(employeeId,salesforceId,
            entity, icon, primaryField,
            secondaryFields,''));
      }
    }
    system.debug('lstIdFilt-------->'+lstIdFilt);
    system.debug('lstFiltrada-------->'+lstFiltrada);
    system.debug('results---------------->'+results);
    return results;
  }
}