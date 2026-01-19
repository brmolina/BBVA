/**
 * --------------------------------------------------------------------------------------
 * @Name              : CRMX_DML_Service.cls
 * @Author            : César Chávez García cesar.chavez.garcia@bbva.com
 * @Date              : 07-08-2024
 * @Group             : OPS - Org Health
 * --------------------------------------------------------------------------------------
 * @Description       : Helper class to complement the functionality of the MX_ENGMX_DML_Selector class
 * --------------------------------------------------------------------------------------
 * @Changes
 * 07-08-2024   cesar.chavez.garcia@bbva.com
 *              Initial version of the CRMX_DML_Service class
 * --------------------------------------------------------------------------------------
 */
public with sharing class CRMX_DML_Service {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Private constructor of the class
    * --------------------------------------------------------------------------------------
    * @Author César Chávez García cesar.chavez.garcia@bbva.com
    * @Date 07-08-2024
    * @param none
    * @return void
    * @example CRMX_DML_Service instance = CRMX_DML_Service()
    * --------------------------------------------------------------------------------------
    */
    @testVisible
    private CRMX_DML_Service() {}
    /**
     * --------------------------------------------------------------------------------------
     * @Description Method that validates if the record list is empty; throws an error if true
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to validate
     * @return void
     * @example CRMX_DML_Service.validateList(lRecords)
     */
    public static void validateList(List<SObject> lRecords) {
        if (lRecords.isEmpty()) {
            throw new DMLException(System.StatusCode.MISSING_ARGUMENT.name());
        }
    }
    /**
     * --------------------------------------------------------------------------------------
     * @Description Method that validates field access for a list of records
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to validate
     * @param System.AccessType typeAccess - Type of access
     * @param Boolean forceError - Force the error
     * @return List<SObject> - List of records with validated fields
     * @example CRMX_DML_Service.validateFieldsAccess(lRecords, typeAccess, forceError)
     */
    public static List<SObject> validateFieldsAccess(List<SObject> lRecords, System.AccessType typeAccess, Boolean forceError) {
        final SObjectAccessDecision decision = Security.stripInaccessible(typeAccess, lRecords);
        final Map<String,Set<String>> removedFields = decision.getRemovedFields();
        if(forceError && !removedFields.values().isEmpty()) {
            throw new DMLException(System.StatusCode.INSUFFICIENT_ACCESS.name());
        }
        return decision.getRecords();
    }
}