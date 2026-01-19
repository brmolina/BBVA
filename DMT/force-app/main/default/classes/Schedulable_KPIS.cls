/**********************************************************************************
* @author  		VASS
* @date
* @description  Clase Schedulable que será ejecutada el día 1 de cada mes a las 00:00 para generar un registro resumen de todo el mes pasado
* @Revision
**********************************************************************************/

global class Schedulable_KPIS implements Schedulable{

    /*
     * KPIS Helper Class
     */
    final KPI_Logic_Helper kpiHelper = KPI_Logic_Helper.getInstance();

    /*
     * execute Schedulable method
     */
    global void execute(SchedulableContext scMain){
      system.debug('::::: Schedulable_KPIS');
      kpiHelper.kpiLogic();
    }


}