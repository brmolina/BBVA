/**
FECHA       -   AUTOR      -   DESCRIPCIÓN DEL CAMBIO
20/06/2018   -  Accenture JSS   -  Creación: Clase programable que lanza el proceso de GBL_DenormalizeOpportunitiesUtils que lanza a su vez el Batch de denormalización de oportunidades
*/ 
global class DES_DenormalizeOppSchedulable implements Schedulable{

    global void execute(SchedulableContext scMain){
      GBL_DenormalizeOpportunitiesUtils oppUtil = new GBL_DenormalizeOpportunitiesUtils();
      oppUtil.restore();  
    }
}