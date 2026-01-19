/**
FECHA       -   AUTOR			-   DESCRIPCIÓN DEL CAMBIO
19/07/2018 	-	VASS DSL 	-	Creación: Clase programable que lanza el proceso de borrado de contrapartidas.
*/ 
global class DES_Delete_Counterparties_Schedulable implements Schedulable{

    global void execute(SchedulableContext scMain){
		Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_AccRel_Counterparties(), 10000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    }
}