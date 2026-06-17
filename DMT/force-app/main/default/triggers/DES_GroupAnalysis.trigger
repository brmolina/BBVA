/**
* @author       Global Desktop
* @date         05/07/2019
* @description  Trigger de Account Planning
* @Revision
*
* Version   Date           Author           Summary of changes
* ----------------------------------------------------------------------------------
* 0.1       2020/04/23     Global Desktop 	Añadida la función
*/
trigger DES_GroupAnalysis on DES_Group_Analysis__c (after insert) {

    final DES_GroupAnalysisHandler des_gaHandler = DES_GroupAnalysisHandler.getInstance();
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            des_gaHandler.updateGAlookupInAP(Trigger.new);
        }
    }
}