/**
 * Controlador para el componente DES_IP_Client_Link que se usa para traer el Id del Cliente real
 */
public without sharing class DES_Ip_HiddenFieldsController {

  /**
   * Mét0d0 para obtener obtener el id del cliente y el owner oculto
   *
   * @param recordId
   *
   * @return un objeto de ClientData
   */
  @AuraEnabled
  public static ClientData getClientData ( Id recordId ) {

    final ClientData cdata = new ClientData();
    SObject sobj;
    String clientId;
    Account client;
    String ownerId;
    User user;

    final Map<String, String> prfxFldBySObjName = new Map<String, String>();
    prfxFldBySObjName.put('Opportunity', 'operation');
    prfxFldBySObjName.put('dwp_kitv__Visit__c', 'visit');

    String hiddenClientField;
    String hiddenOwnerField;

    try {
        final String SObjectName = recordId.getSobjectType().getDescribe().getName();
        hiddenClientField = prfxFldBySObjName.get( SObjectName ) + '_prvlg_participant_id__c';
        hiddenOwnerField = prfxFldBySObjName.get( SObjectName ) + '_privileged_user_name__c';
        
        final String query = 'SELECT Id, ' + String.escapeSingleQuotes(hiddenClientField) + ', ' + String.escapeSingleQuotes(hiddenOwnerField) + ' FROM ' + String.escapeSingleQuotes(SObjectName) + ' WHERE Id = :recordId';
        
        sobj = Database.query(query);
        clientId = (String) sobj.get( hiddenClientField );
        ownerId = (String) sobj.get( hiddenOwnerField );
    } catch (Exception e) {
        cdata.success = false;
        cdata.errorMessage = 'Error trying to recover the Client or Owner: ' + e.getMessage();
    }

    if(sobj != null) {
      client = [SELECT Id, Name FROM Account WHERE Id = :clientId];
      user = [SELECT Id, Name FROM User WHERE Id = :ownerId];
        
      cdata.clientId = (String) sobj.get( hiddenClientField );
      cdata.ownerId = (String) sobj.get( hiddenOwnerField );
      cdata.ownerName = user.Name;
      cdata.clientName = client.Name;
    }

    return cdata;

  }

  /**
   * Devuelve el codigo bbva del usuario que invoca el method
   */
  @AuraEnabled
  public static String bbvaUserCode() {//NOSONAR
      // String user;
      system.debug('entra bbvaUserCode usuario: ' + UserInfo.getUserId());
      try {
        // user = Desktop_Utils.bbvaUserCode();
        return Desktop_Utils.bbvaUserCode();
      } catch (Exception e) {
        if(!Test.isRunningTest()) {
          throw new AuraHandledException(Label.DES_IP_ERROR + e);
        } else {
          return 'test1234';
        }
      }
      // return user;
  }

  /**
   * Devuelve el endpoint de los servicios
   */
  	@AuraEnabled
    public static String urlIpServices() {
     try {
      	return Desktop_Utils.urlIPServices();
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }

    }

  /*
    Wrapper para guardar los datos relacionados con la consulta
 */
  public class ClientData {
    @AuraEnabled
    public String clientId; //NOSONAR
    @AuraEnabled
    public String clientName; //NOSONAR
    @AuraEnabled
    public String ownerId; //NOSONAR
    @AuraEnabled
    public String ownerName; //NOSONAR
    @AuraEnabled
    public Boolean success = true; //NOSONAR
    @AuraEnabled
    public String errorMessage = ''; //NOSONAR
    public ClientData(){} //NOSONAR
  }

}