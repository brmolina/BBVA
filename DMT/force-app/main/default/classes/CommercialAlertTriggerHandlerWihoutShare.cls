/**********************************************************************************
* @author      	Global Desktop 
* @date         07/03/2019
* @description  Clase without sharing de alertas
* @Revision     
**********************************************************************************/
public without sharing class CommercialAlertTriggerHandlerWihoutShare {
    
	/*
	* @author Global Desktop
	* @Description Inserta los registros __Share de alertas
	*/
	public static List<almd__Commercial_Alert__Share> insertCommAlertShare (List<almd__Commercial_Alert__Share> listComAlertShare) {
		system.debug('>>>>> listComAlertShare : ' + listComAlertShare);
		if(!listComAlertShare.isEmpty()) {
            try {
                List<Database.SaveResult> listSR = Database.insert(listComAlertShare,false);
                system.debug('>>>>> listSR : ' + JSON.serialize(listSR));
                system.debug('>>>>> listComAlertShare : ' + JSON.serialize(listComAlertShare));
            } catch(Exception e) {
              system.debug('>>>>> e : ' + e);
            }
        }
        return listComAlertShare;
	}
	
    /*
	* @author Global Desktop
	* @Description Borra los registros __Share de alertas
	*/
    public static void alertShareToDelete (String alertShareToDeleteJSON) {
        if(System.IsBatch() == false && System.isFuture() == false) {
            alertShareToDeleteFuture(alertShareToDeleteJSON);
        }
    }
    
    
	/*
	* @author Global Desktop
	* @Description Borra los registros __Share de alertas
	*/
    @future 
    public static void alertShareToDeleteFuture (String alertShareToDeleteJSON) {
        List<almd__Commercial_Alert__Share> alertShareToDelete = (List<almd__Commercial_Alert__Share>)JSON.deserialize(alertShareToDeleteJSON, List<almd__Commercial_Alert__Share>.class);     
        if(!alertShareToDelete.isEmpty()) {
        	system.debug('>>>>> alertShareToDelete : ' + alertShareToDelete);
            delete alertShareToDelete;	
        }
    }
}