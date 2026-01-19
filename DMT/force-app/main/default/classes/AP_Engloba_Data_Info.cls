/**********************************************************************************
* @author       Accenture
* @date         01/11/2019
* @description  Clase que calcula la fecha de engloba para mostrarla en el Account Plan
* @Revision
**********************************************************************************/
public with sharing class AP_Engloba_Data_Info {
     /*
    * @author Global Desktop
    * @description Recupera la fecha de engloba
    */
    @AuraEnabled
    public static String getEnglobaData(Id recordId){
        String clientId = [
                            SELECT acpl__participant_id__c
                            FROM acpl__Account_Planning__c WHERE Id = :recordId
                            LIMIT 1
        ].acpl__participant_id__c;
        
        String englobaDate = [
                            SELECT Id,
                                    DES_Engloba_Date_Info__c
                            FROM DES_Booking__c WHERE DES_Client__c = :clientId
                            LIMIT 1
        ].DES_Engloba_Date_Info__c;
        return englobaDate;
    }       
    
}