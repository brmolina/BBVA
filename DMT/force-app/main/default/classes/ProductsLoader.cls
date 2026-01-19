public with sharing class ProductsLoader {
	/*
     * @author	-	Global Desktop - DSL
     * @Description	-	Recoge los datos de la oportunidad y sus OppProducts relacionados 
     * @Return	-	Devuelve la oportunidad.
     */
    @AuraEnabled
    public static Opportunity gtData(String oppId) {
        Opportunity opp = [SELECT Id, Name, stage_changed_type__c, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE Id = :oppId];
        return opp;
    }
    
    /*
     * @author	-	Global Desktop - DSL
     * @Description	-	Desmarca el check de 'Stage Changed'
     * @Return	-	Devuelve un String con 'OK' o con el mensaje de error (si hay) al actualizar la opp.
     */
    @AuraEnabled
    public static String uncheckStageChanged(String oppId) {
        String toReturn = 'OK';
        Opportunity opp = new Opportunity(Id=oppId, stage_changed_type__c=false);
        try{
            update opp;
        } catch(DMLException e) {
            toReturn = e.getDMLMessage(0);
        }
        return toReturn;
    }
}