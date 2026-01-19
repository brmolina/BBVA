@RestResource(urlMapping='/deleteVisitManagTeamLocal')
global with sharing class DWA_WS_Delete_Visit_Manag_Team_Local {
	@HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Visit_Manag_Team_Local(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}