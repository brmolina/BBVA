/**
FECHA       -   AUTOR           -   DESCRIPCIÓN DEL CAMBIO
27/06/2018  -   VASS DSL        -   Creación: Clase programable que lanza todos los procesos cuya ejecución está planeada 1 vez a la semana. Actualmente son 3 los procesos que se ejecutan: Denormalize de Opportunities, Denormalize de Visits y Cálculo del YOY y de los Revenues desde la tabla DES_Booking__c
09/07/2018  -   ACCENTURE TAF   -   Modificación: Se mueve el batch de visitas a la clase DES_Schedulable_AllWeeks_part2
*/ 
global class DES_Schedulable_AllWeeks implements Schedulable{

    global void execute(SchedulableContext scMain){
            //Cálculo de Revenues y YOY
            system.debug('>>>>> Inicio Batch Booking ');
            Id batchInstanceId = Database.executeBatch(new DES_Booking_Batch(), 10000);
            system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
            
            //Denormalize de Opportunities
            /*system.debug('>>>>> Inicio Batch GBL_DenormalizeOpportunities ');
            dwp_acmh.GBL_DenormalizeOpportunitiesUtils oppUtil = new dwp_acmh.GBL_DenormalizeOpportunitiesUtils();
            oppUtil.restore();*/  
            
            
            //Denormalize de Visits
            /*system.debug('>>>>> Inicio Batch DES_DenormalizeVisits ');
            DES_DenormalizeVisitsUtils visitUtil = new DES_DenormalizeVisitsUtils();
            visitUtil.restore();*/


            //Account Renewal Date
            /*system.debug('>>>>> Inicio Batch Account Renewal Date');
            Id batchInstanceId_2 = Database.executeBatch(new DES_AccountRenewalDateAlertBatch(), 10000);
            system.debug('>>>>> id BATCH JO: ' + batchInstanceId_2);*/

            
            system.debug('>>>>> FIN ALL BATCHES');
    }
}