/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_RatingSystem_Controller
* @author      marcos.gimeno.next@bbva.com
* @date        05-02-2024
*
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Rating System class (Presentation layer)
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.next@bbva.com
* 19-10-2023   Class creation.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('sf:UseSingleton, sf:AvoidGetSetMethods, sf:AvoidHardCodedError, sf:PreserveStackTrace')
public with sharing class Arc_Gen_RatingSystem_Controller {
   
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get the arce config metadata records.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        05-02-2024
    * @param       forceException Boolean to force an exception.
    * @return      String with the serialized response.
    * @throws      AuraHandledException with the error message.
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled(cacheable=true)
    public static String getArceConfigMdt(Boolean forceException) {
        try {
            if (forceException) {
                throw new AuraHandledException('Forced exception');
            }

            // Assert access
            Arc_Gen_RatingSystem_Service.checkObjectIsReadable(Schema.arce__Arce_Config__mdt.sObjectType);

            // Return the response
            return Arc_Gen_RatingSystem_Service.queryArceConfigMdt();
        } catch (Exception e) {
            final AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getStackTraceString());
            throw auraException;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get the persistence metadata records.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        05-02-2024
    * @param       forceException Boolean to force an exception.
    * @return      Json with the response.
    * @throws      AuraHandledException with the error message.
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled(cacheable=true)
    public static String getPersistenceMdt(Boolean forceException) {
        try {
            if (forceException) {
                throw new AuraHandledException('Forced exception');
            }

            // Assert access
            Arc_Gen_RatingSystem_Service.checkObjectIsReadable(Schema.arce__Service_persistence__mdt.sObjectType);

            // Return the response
            return Arc_Gen_RatingSystem_Service.queryPersistenceMdt();
        } catch (Exception e) {
            final AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getStackTraceString());
            throw auraException;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Call the rating system service.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        05-02-2024
    * @param       serializeParams String with the serialized parameters.
    * @param       isMock Flag to enable / disable mock.
    * @return      String with the serialized response.
    * @throws      AuraHandledException with the error message.
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String callRatingSystem(String recordId, Boolean isMock) {
        try {
            // Sanitise
            final Id ahaId = (Id) recordId;

            // Assert access
            Arc_Gen_RatingSystem_Service.checkObjectIsReadable(Schema.arce__Account_has_Analysis__c.SObjectType);

            // Return the response
            // return Arc_Gen_RatingSystem_Service.callService(ahaId);
            return Arc_Gen_CallRatingSystems.callRatingSystems(ahaId, isMock);
            } catch (Exception e) {
                final AuraHandledException auraException = new AuraHandledException(e.getMessage());
                auraException.setMessage(e.getStackTraceString());
                throw auraException;
        } 
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get the arce config metadata records.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        05-02-2024
    * @return      String with the serialized response.
    * @throws      AuraHandledException with the error message.
    * -----------------------------------------------------------------------------------------------
    **/
    /*@AuraEnabled(cacheable=true)
    public static String getArceConfigs(String s) {
        try {
            return getArceConfigMdt();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/
    
}