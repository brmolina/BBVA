/*******************************************************************************************************
 * @name            DES_Sch_BulkIngestJobsLast24hSch
 * @author          David Díaz
 * @created         06/10/2025
 * @description     Clase Scheduler Apex encargada de ejecutar el Batch
 *                  DES_Batch_BulkIngestJobsLast24h de forma programada.
 *
 *                  Se recomienda su ejecución en horario nocturno para minimizar
 *                  impacto en límites de API y evitar competir con procesos críticos.
 *
 * @execution       Programado mediante CRON. Ejemplo:
 *                      0 0 7 * * ?   → Ejecutar todos los días a las 07:00 AM.
 *
 * @see             DES_Batch_BulkIngestJobsLast24h
 * @test            DES_Tst_BulkIngestJobsLast24hBatchTest
 *******************************************************************************************************/
global with sharing class DES_Sch_BulkIngestJobsLast24hSch implements Schedulable {
    /***************************************************************************************************
     * @method         execute
     * @description    Método principal del Scheduler Apex.
     *
     *                  Responsable de:
     *                      1. Invocar al Batch DES_Batch_BulkIngestJobsLast24h.
     *                      2. Establecer un tamaño de lote de 50 registros por ejecución para optimizar
     *                         los límites de callouts y memoria.
     *
     *                  Este método se ejecuta automáticamente según la programación CRON definida
     *                  mediante System.schedule().
     *
     * @params         sc → Contexto del ciclo de vida del job programado.
     *
     * @see            DES_Batch_BulkIngestJobsLast24h
     ***************************************************************************************************/
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DES_Batch_BulkIngestJobsLast24h(), 50);
    }
}