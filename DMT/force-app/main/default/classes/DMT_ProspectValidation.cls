/**
 * @description Validation helper for Prospect clients in DMT Lines.
 * Contains invocable methods used by Flow to validate Prospect presence.
 */
public with sharing class DMT_ProspectValidation {
    
    /**
     * @description Método invocable para flows: valida si una línea tiene Prospect. 
     * Se usa en el flow AfterCreateLine para no dejar pasar a Close Won de forma automática 
     * si la línea tiene Prospect en cliente o en la multiholder.
     * @param lineIds Lista con el ID de la línea a validar
     * @return Lista con un boolean: true si tiene Prospect, false si no
     */
    @InvocableMethod(label='Check if Line has Prospect' description='Returns true if line has Prospect in client or multiholder')
    public static List<Boolean> hasProspectInLine(List<Id> lineIds) {
        List<Boolean> results = new List<Boolean>();
        
        if (lineIds == null || lineIds.isEmpty()) {
            results.add(false);
            return results;
        }
        
        Set<Id> clientIds = new Set<Id>();
        for (DMT_Line__c line : [SELECT Client__c FROM DMT_Line__c WHERE Id IN :lineIds WITH USER_MODE]) {
            if (line.Client__c != null) {
                clientIds.add(line.Client__c);
            }
        }
        
        DMT_Line_Helper helper = new DMT_Line_Helper();
        Set<Id> linesWithProspect = helper.getLineIdsWithProspectInClientOrMultiholder(new Set<Id>(lineIds), clientIds);
        for (Id lineId : lineIds) {
            results.add(linesWithProspect.contains(lineId));
        }
        return results;
    }
    
}