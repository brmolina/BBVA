/*
* Handler del Trigger de Asset Template
*/
public without sharing class Asset_Template_Handler_out {

  /** instance */
  private static Asset_Template_Handler_out instance;

  /*
  * getInstance
  */
  public static Asset_Template_Handler_out getInstance() { //NOSONAR
    if (instance == null) {
        instance = new Asset_Template_Handler_out();
      }
      return instance;
  }
  /*
  * Met0d0 para pasar sonar
  */
  private Asset_Template_Handler_out() {}

  /*
  * Met0d0 para comprobar si debe o no eliminarse el Asset_Template
  */
  public static void checkDelete(List<Asset_Template__c> oldList) { //NOSONAR
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger E-commerce Registry (before delete)');
    String completed;
    completed = 'Completed';
    final String userId = UserInfo.getUserId();
    EsalesDynamicButtonsHandler dynamicButton;
    dynamicButton = new EsalesDynamicButtonsHandler();
    final Boolean eSales = dynamicButton.rolImplement('GLOBAL MARKETS ECOMMERCE SALES');
    for (Asset_Template__c template : oldList) {
      System.debug('template--------------------->'+template.Status__c);
      if(template.Status__c == completed) {
        if(!EsalesDynamicButtonsHandler.getProfile()) {
          template.AddError(Label.DES_Delete_Asset_Template);
        }
      } else if(template.OwnerId != userId && !eSales) {
        template.AddError(Label.DES_Delete_Asset_Template);
      }
    }
    System.debug('eSales--->'+eSales);
    System.debug('userId--->'+userId);
  }
}