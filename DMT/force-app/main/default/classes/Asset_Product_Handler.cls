/*
* Handler del Trigger de Asset Product
*/
public with sharing class Asset_Product_Handler {

  /** instance */
  private static Asset_Product_Handler instance;

  /*
  * getInstance
  */
  public static Asset_Product_Handler getInstance() { //NOSONAR
    if (instance == null) {
        instance = new Asset_Product_Handler();
      }
      return instance;
  }

    /*
    * Met0d0 para notificar que el cliente no confirma via Markitwire Does_the_client_confirm_via_Markitwire__c
    */
    public void notifyMarkitwire(List<Asset_Product__c> newList, Map<ID, Asset_Product__c> mapOldList) { //NOSONAR
        Set<Id> setIds;
        setIds = new Set<Id>();
        for (Asset_Product__c product : newList) {
            if(product.Does_the_client_confirm_via_Markitwire__c == 'No' && mapOldList.get(product.id).Does_the_client_confirm_via_Markitwire__c != 'No') {
                setIds.add(product.Asset_Template__c);
            }
        }
        final List<Asset_Template__c> lstTemp = [SELECT Id, Name, Client__r.Name FROM Asset_Template__c WHERE Id IN: setIds];
        generarNotificacion(lstTemp);
    }


    private static void generarNotificacion(List<Asset_Template__c> lstTemp) {
        Set<Id> roles;
        roles = WrongDataFlow.rolESales();
        final String texto = ' does not confirm via Markitwire, please set up a drop copy before moving on with the request in form '; //NOSONAR
        final List<User> users = new List<User>([
        SELECT Id FROM User WHERE UserRoleId IN :roles AND DES_Disable_Chatter__c = false AND isActive = true
        ]);
        String mensaje;
        for(Asset_Template__c temp : lstTemp) {
            if(temp.Client__r.Name == null) {
                mensaje = 'This Client of the E-commerce Registry ' + texto + temp.Name + '. ' + URL.getOrgDomainURL().toExternalForm() + '/' + temp.Id;
            } else {
                mensaje = temp.Client__r.Name + texto + temp.Name + '. ' + URL.getOrgDomainURL().toExternalForm() + '/' + temp.Id;
            }
            for(User user : users) {
                WrongDataFlow.generarPostChatter(user.Id, mensaje);
            }
        }

        System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());
        for(ConnectApi.BatchInput batch : Desktop_Utils.batchFeedItemInputs) {
          System.debug('batch: ' + batch);
        }

        if(!Desktop_Utils.batchFeedItemInputs.isEmpty() && !test.isRunningTest()) {             //NOSONAR
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
        }
    }

}