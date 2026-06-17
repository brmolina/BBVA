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
    /** Persistence custom metadata names */
    private static final Set<String> PERS_CONFIGS = new Set<String>{ 'Model_RS_Conditions', 'IFIS_InstitutionTypes' };

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
            return JSON.serialize(Arc_Gen_RatingSystem_Service.queryPersistenceMdt(PERS_CONFIGS));
        } catch (Exception e) {
            final AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getStackTraceString());
            throw auraException;
        }
    }
}