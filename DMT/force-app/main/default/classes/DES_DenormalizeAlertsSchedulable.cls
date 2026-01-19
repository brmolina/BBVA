/**
FECHA       -   AUTOR			-   DESCRIPCIÓN DEL CAMBIO
31/10/2018 	-	Accenture 	-	Creación: Clase programable que lanza el proceso de DES_DenormalizeAlertsUtils que lanza a su vez el Batch de denormalización de alertas
*/
global class DES_DenormalizeAlertsSchedulable implements Schedulable{

    global void execute(SchedulableContext scMain){
			DES_DenormalizeAlertsUtils alertUtil = new DES_DenormalizeAlertsUtils();
			alertUtil.restore();
    }
}