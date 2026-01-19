/**
FECHA       -   AUTOR			-   DESCRIPCIÓN DEL CAMBIO
20/06/2018 	-	Accenture JSS 	-	Creación: Clase programable que lanza el proceso de DES_DenormalizeVisitsUtils que lanza a su vez el Batch de denormalización de visitas
*/ 
global class DES_DenormalizeVisitsSchedulable implements Schedulable{

    global void execute(SchedulableContext scMain){
			DES_DenormalizeVisitsUtils visitUtil = new DES_DenormalizeVisitsUtils();
			visitUtil.restore();
    }
}