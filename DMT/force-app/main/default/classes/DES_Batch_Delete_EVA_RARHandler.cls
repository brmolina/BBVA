/**********************************************************************************
* @author       Accenture
* @date         
* @description  Manejador del Batch para el borrado de RAR EVA RORC (DES_Historic_RAR_EVA_RORC__c)
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public with sharing class DES_Batch_Delete_EVA_RARHandler {
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
	public static void borrarEVARAR(List<DES_Historic_RAR_EVA_RORC__c> listaEVARAR) {
		
		system.debug('>>>>> listaEVARAR : ' + listaEVARAR);
	    if(!listaEVARAR.isEmpty()) {
	            delete listaEVARAR;
	            Database.emptyRecycleBin(listaEVARAR);
	        }	
	}
}