/**
FECHA       -   AUTOR           -   DESCRIPCIÓN DEL CAMBIO
09/07/2018	-	ACCENTURE TAF   -   Creación: Clase programable que lanza todos los procesos cuya ejecución está planeada 1 vez a la semana. Actualmente es 1 el proceso que se ejecuta: Denormalize de Visits 
*/ 
global class DES_Schedulable_AllWeeks_part2 implements Schedulable{
    global void execute(SchedulableContext scMain){
            //Denormalize de Visits
            system.debug('>>>>> Inicio Batch DES_DenormalizeVisits ');
            DES_DenormalizeVisitsUtils visitUtil = new DES_DenormalizeVisitsUtils();
            visitUtil.restore();
            
            system.debug('>>>>> FIN ALL BATCHES PART 2');
    }
}