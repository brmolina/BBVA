/**
* @author       Global Desktop
* @date         05/07/2019
* @description  Handler del trigger de Case con los mét0d0s que aplican sólo a funcionalidad dentro de Global Desktop
* @Revision
* Version   Date            Author          Summary of changes
* ----------------------------------------------------------------------------------
* 0.1        2019/11/08      JSS            Modificada query mét0d0 copyAPTeamFromGroup para recuperar solo los 'Global Banker'
*                                           Añadido mét0d0 checkAPperiod
*                                           Añadido mét0d0 setFieldsBeforeInsert
*                                           Añadidos mét0d0s para que después de insertar un AP se cree la estructura del Business Plan:
*                                           (BP, Version, Items...) relacionado con dicho AP.
*/
@SupressWarnings('sf:UseSingleton')
public without sharing class DES_CaseHandler {
    /*
    * @author       Global Desktop
    * @Description  Inserta manual share a AP si el owner del caso del AP cambia
    */
    public static void insertAPShare(List<Case> triggerNew, Map<Id, Case> triggerOldMap) {
        System.debug('dentro de insertAPShare');
        final Id apCaseRT = [SELECT Id FROM RecordType WHERE DeveloperName='Account_Plan_Validation'].Id;
        final List<acpl__Account_Planning__Share> apShareInsertList = new List<acpl__Account_Planning__Share>();
        
        for(Case caseAux : triggerNew) {
            System.debug('caseAux.RecordTypeId: ' + caseAux.RecordTypeId);
            System.debug('apCaseRT: ' + apCaseRT);
            System.debug('caseAux.OwnerId: ' + caseAux.OwnerId);
            System.debug('triggerOldMap.get(caseAux.Id).OwnerId: ' + triggerOldMap.get(caseAux.Id).OwnerId);
            if(caseAux.RecordTypeId == apCaseRT && caseAux.OwnerId != triggerOldMap.get(caseAux.Id).OwnerId) {
                acpl__Account_Planning__Share apShareToInsert;
                apShareToInsert = Desktop_Utils_aux.newManualSharingAccountPlanning(caseAux.acpl__Account_plan_id__c, caseAux.OwnerId, 'Edit');
                System.debug('AP share insertado: ' + apShareToInsert);
                if(apShareToInsert != null) {
                    apShareInsertList.add(apShareToInsert);
                }
            }
        }
        System.debug('apShareInsertList: ' + apShareInsertList);
        if(!apShareInsertList.isEmpty()) {
            insert apShareInsertList;
        }
    } //FIN de insertAPShare

}