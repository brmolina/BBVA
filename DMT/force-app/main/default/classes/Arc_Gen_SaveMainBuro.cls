/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveMainBuro
* @Author   Bertha Elena Tellez Lira
* @Date     Created: 14/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Main and Bureau.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-03-16 José Luis García Díaz
*             Validate if user has edit permission on analysis.
* |2020-02-14 Bertha Elena Téllez Lira
*             Class creation.
* |2021-03-12 Juan Pedro Benito González
*             Unescape /n in the fields arce__capital_provision_desc__c, arce__banking_pool_desc__c and arce__rar_profitability_desc__c
* |2021-05-14 Juan Ignacio Hita Manso
*             Unescape textarea fields in save method
* |2021-06-17 Juan Ignacio Hita Manso
*             Validate if the object saved is an AHA
* |2021-06-28 Juan Ignacio Hita Manso
*             Refactors getWithRemovedNewlines method major sonar
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveMainBuro implements dyfr.Save_Interface {
/**
* -----------------------------------------------------------------------------------------------
* @Description - Method that is responsible for invoking the classes to save the mains and bureau
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 14/02/2020
* @param listObject - List of the account has analisys object
* @return String with the execution message
* @example save (listObject)
* -----------------------------------------------------------------------------------------------
**/
    public String save(List<sObject> listObject) {
        final List<String> ids = new list<String>();
        final List<Arc_Gen_SaveMainBuroHelper.DataMainBuro> dataEnv = new List<Arc_Gen_SaveMainBuroHelper.DataMainBuro>();
        for(sObject obj : listObject) {
            final Arc_Gen_SaveMainBuroHelper.DataMainBuro objR = new Arc_Gen_SaveMainBuroHelper.DataMainBuro();
            final String idAnalisis = obj.get('Id').toString();
            // Only validate if what is being saved is an Account_has_analysis__c record
            if (Id.valueOf(idAnalisis).getSobjectType() != arce__Account_has_Analysis__c.SObjectType) {
                continue;
            }
            ids.add(idAnalisis);
            objR.idDF = obj.get('Id').toString();
            objR.hasSummaryComm = String.valueOf(obj.get('arce__risk_position_summary_type__c'));
            objR.commentsRisk = getWithRemovedNewlines(String.valueOf(obj.get('arce__risk_position_summary_desc__c')));
            objR.numOfBanks = String.valueOf(obj.get('arce__number_entity_type__c'));
            objR.othersProducs = String.valueOf(obj.get('arce__other_contracted_product_type__c'));
            objR.othersProdComm = getWithRemovedNewlines(String.valueOf(obj.get('arce__other_contracted_product_desc__c')));
            objR.otherOperations = String.valueOf(obj.get('arce__other_operation_type__c'));
            objR.otherOprDesc = getWithRemovedNewlines(String.valueOf(obj.get('arce__other_operation_desc__c')));
            objR.rarRentab = String.valueOf(obj.get('arce__rar_profitability_per__c'));
            objR.rarComm = getWithRemovedNewlines(String.valueOf(obj.get('arce__rar_profitability_desc__c')));
            objR.nivelWL = String.valueOf(obj.get('arce__hats_risk_qualification_number__c'));
            objR.stageColl = String.valueOf(obj.get('arce__stage_collective_type__c'));
            objR.stageCollDesc = getWithRemovedNewlines(String.valueOf(obj.get('arce__stage_collective_desc__c')));
            objR.custProductUsage = getWithRemovedNewlines(String.valueOf(obj.get('arce__customer_product_usage_desc__c')));
            objR.bankPool = getWithRemovedNewlines(String.valueOf(obj.get('arce__banking_pool_desc__c')));
            objR.capProvTyp = String.valueOf(obj.get('arce__capital_provision_per__c'));
            objR.capProvDesc = getWithRemovedNewlines(String.valueOf(obj.get('arce__capital_provision_desc__c')));
            objR.covenBreach = String.valueOf(obj.get('arce__fin_covenants_breach_type__c'));
            objR.covenBreachDesc = getWithRemovedNewlines(String.valueOf(obj.get('arce__fin_covenants_breach_desc__c')));
            dataEnv.add(objR);
        }

        for (String ahaId : ids) {
            // Validate that the user has permission to edit the record
            // before saving.
            if (Arc_Gen_TabSet_service.getPermissionToEdit(ahaId) != 'true') {
                throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
            }
        }

        final Boolean result = Arc_Gen_Persistance_MB_Service.persistenceMB(ids, dataEnv, listObject);
        return JSON.serialize(new arce.Arc_Gen_wrpSave(result,'Errs',listObject));
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Removes newlines from the string.
    * -----------------------------------------------------------------------------------------------
    * @Author   José Luis García Díaz <joseluis.garcia4.contractor@bbva.com>
    * @Date     Created: 22/03/2021
    * @param original - Original string
    * @return String trimmed string
    * -----------------------------------------------------------------------------------------------
    **/
    private String getWithRemovedNewlines(String original) {
        return original == null ? '' : original.replaceAll('\n','').replaceAll('\r','');
    }

}