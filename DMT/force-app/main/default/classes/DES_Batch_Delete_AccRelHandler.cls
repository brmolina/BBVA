/**********************************************************************************
* @author       Accenture
* @date         
* @description  Manejador del Batch para el borrado de JerarquiaClientes (AMH_GBL_Account_Relationship__c)
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public with sharing class DES_Batch_Delete_AccRelHandler {
            
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
  public static void borrarAccRel(List<AMH_GBL_Account_Relationship__c> listaAccRel) {
    
    system.debug('>>>>> listaAccRel : ' + listaAccRel);
      if(!listaAccRel.isEmpty()) {
              delete listaAccRel;
              Database.emptyRecycleBin(listaAccRel);
          }  
  }

}