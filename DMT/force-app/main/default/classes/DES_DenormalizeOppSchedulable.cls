/**
FECHA       -   AUTOR			-   DESCRIPCIÓN DEL CAMBIO
20/06/2018 	-	Accenture JSS 	-	Creación: Clase programable que lanza el proceso de dwp_acmh.GBL_DenormalizeOpportunitiesUtils que lanza a su vez el Batch de denormalización de oportunidades
*/ 
global class DES_DenormalizeOppSchedulable implements Schedulable{

    global void execute(SchedulableContext scMain){
			dwp_acmh.GBL_DenormalizeOpportunitiesUtils oppUtil = new dwp_acmh.GBL_DenormalizeOpportunitiesUtils();
			oppUtil.restore();	
    }
}