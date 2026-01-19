@RestResource(urlMapping='/deleteDwpCvadActAudD')
global with sharing class DES_WS_Delete_dwp_cvad_ActAudD {
	@HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_dwp_cvad_ActAudD(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}