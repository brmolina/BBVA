/**
FECHA       -   AUTOR			-   DESCRIPCIÓN DEL CAMBIO
23/07/2018 	-	VASS DSL 	-	Creación: Clase programable que lanza el proceso Batch que se encarga de borrar todos el BBVA Client Team
*/ 
global class DES_Schedulable_Delete_BBVATeamMembers implements Schedulable{

    global void execute(SchedulableContext scMain){
		Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_BBVATeamMember(), 10000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    }
}