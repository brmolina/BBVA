/**
* ────────────────────────────────────────────────────────────────────
* CucoSchedulableBatchError
* Schedulable class for CucoProfitabilityErrorBatch
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
global with sharing class CucoSchedulableBatchError implements Schedulable {

    /*
    * @author         CIB
    * @Description    Batchable method
    */
    global void execute(SchedulableContext scontext) {
        final CucoProfitabilityErrorBatch cucoPEB = new CucoProfitabilityErrorBatch();
        database.executebatch(cucoPEB,Integer.valueOf(System.Label.Batch_Size));
    }
}