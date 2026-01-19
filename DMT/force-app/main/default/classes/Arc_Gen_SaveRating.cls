/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveRating
* @Author   Ricardo Almanza Angeles
* @Date     Created: 13/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Rating.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-02-13 Ricardo Almanza Angeles
*             Class creation.
* |2019-02-13 Eduardo Efrain Hernandez Rendon
*             Add In Preparation stage validation
* |2020-07-31 José Luis García Díaz
*             Clear Leveraged Test results if override changes.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-24 Juan Manuel Perez Ortiz
*             Modified method called getOverrideResponse to prevent service execution when field have null value
* |2022-06-06 Juan Ignacio Hita
*             Add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveRating implements dyfr.Save_Interface {
    /**
        * @Description: string with the class name of object Acc has analysis ARCE
    */
    Static Final String ARCAHA = 'arce__Account_has_Analysis__c', RATVAR = 'arce__rating_variables_detail__c';
    public String save(List<sObject> listObject) {
        arce__Analysis__c arceVar = new arce__Analysis__c();
        arce.Arc_Gen_wrpSave succesOR;
        Final List<sObject> listAccs = new List<sObject> (), listrvar = new List<sObject>();
        String ahaId;
        if(!listObject.isEmpty()) {
            Final set<String> arcAcc = new Set<String>();
            for(sObject obj : listObject) {
                if(ARCAHA.equals(String.valueOf(obj.getSObjectType()))) {
                    arcAcc.add(String.valueOf(obj.get('Id')));
                    arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(String.valueOf(obj.get('Id')));
                    ahaId = String.valueOf(obj.get('Id'));
                    arcAcc.add(ahaId);

                    // Validate that the user has permission to edit the record
                    // before saving.
                    if (Arc_Gen_TabSet_service.getPermissionToEdit(ahaId) != 'true') {
                        throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
                    }

                    listAccs.add(obj);
                } else if(RATVAR.equals(String.valueOf(obj.getSObjectType()))) {
                    listrvar.add(obj);
                }
            }
            final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
            Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_BasicData_Pers_service.class.getName()));

            succesOR = getOverrideResponse(arcAcc, listAccs, listrvar, arceVar);

            // Check if override has changed. If changed, reset leveraged test results.
            clearLeveragedIfOverrideChanged(ahaId, listrvar);
        }
        return JSON.serialize(new arce.Arc_Gen_wrpSave(succesOR.validated,succesOR.message,listObject));
    }
    /**
    *-------------------------------------------------------------------------------
    * @description evaluateIdentification
    *--------------------------------------------------------------------------------
    * @date   15/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Id : accHasAnalysisId
    * @param  Object : wrapper
    * @param  String : userId
    * @return String : JSON serialize of the delegation wrapper
    * @example  String res = evaluateIdentification(accHasId, wrapper, userId);
    */
    private static arce.Arc_Gen_wrpSave getOverrideResponse(set<String> arcAcc, List<sObject> listAccs, List<sObject> listrvar, arce__Analysis__c arceVar) {
        arce.Arc_Gen_wrpSave response;
        if(arceVar.isSet('Id')) {
            switch on arceVar.arce__Stage__c {
                when '1' {
                    response = new arce.Arc_Gen_wrpSave(true,'',null);
                }
                when '2' {
                    if (String.valueOf(listrvar[0].get('arce__adj_long_rating_value_type__c')) == null) {
                        response = new arce.Arc_Gen_wrpSave(true,'',null);
                    } else {
                        response = Arc_Gen_OverRide_Service.persistOR(new List<String>(arcAcc),listAccs,listrvar);
                    }
                }
            }
        }
        Return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Clears leveraged test results if rating override changes.
    *--------------------------------------------------------------------------------
    * @date   31/07/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param  ahaId Id of the account has analysis
    * @param  listrvar List of rating variables included in the dynamic form
    * @return String : JSON serialize of the delegation wrapper
    */
    private static void clearLeveragedIfOverrideChanged(String ahaId, List<SObject> listrvar) {
        final List<arce__rating_variables_detail__c> varList = arce.Arc_Gen_Rating_Var_detail_Data.getOverrideVariable(ahaId);
        if (!varList.isEmpty()) {
            final arce__rating_variables_detail__c oldOverrideVar = varList[0];
            for (Object obj : listrvar) {
                final arce__rating_variables_detail__c newVar = (arce__rating_variables_detail__c) obj;
                if (newVar.Id == oldOverrideVar.Id && newVar.arce__adj_long_rating_value_type__c != oldOverrideVar.arce__adj_long_rating_value_type__c) {
                    Arc_Gen_TestLeverage_service.clearTestLeveragedResults(ahaId);
                }
            }
        }
    }
}