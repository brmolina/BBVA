/**
 * --------------------------------------------------------------------------------------
 * @Name              : CRMX_DML_Selector.cls
 * @Author            : César Chávez García cesar.chavez.garcia@bbva.com
 * @Date              : 07-08-2024
 *
 * @Group             : OPS - ORG Health
 * --------------------------------------------------------------------------------------
 * @Description       : Class used to validate field access in DML operations
 * --------------------------------------------------------------------------------------
 * @Changes
 * 07-08-2024   cesar.chavez.garcia@bbva.com
 *              Initial version of the CRMX_DML_Selector class
 * --------------------------------------------------------------------------------------
**/
public with sharing class CRMX_DML_Selector {
    /**
     * --------------------------------------------------------------------------------------
     * @Description Private constructor of the class
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param none
     * @return void
     * @example CRMX_DML_Selector instance = CRMX_DML_Selector()
     * --------------------------------------------------------------------------------------
     */
    @testVisible
     private CRMX_DML_Selector() {}
    /**
     * --------------------------------------------------------------------------------------
     * @Description Overloaded method used to insert a list of SObject records
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to be processed in the database
     * @return List<Database.SaveResult> - List of results that were processed
     * @example CRMX_DML_Selector.insertRecords(lRecords)
     */
    public static List<Database.SaveResult> insertRecords(List<SObject> lRecords) {
        return insertRecords(lRecords, true);
    }
    /**
     * --------------------------------------------------------------------------------------
     * @Description Method used to insert a list of SObject records
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to be processed in the database
     * @param Boolean notPartial - Set to false if you want the operation to be partial
     * @return List<Database.SaveResult> - List of results that were processed
     * @example CRMX_DML_Selector.insertRecords(lRecords, notPartial)
     **/
    public static List<Database.SaveResult> insertRecords(List<SObject> lRecords, Boolean notPartial) {
        CRMX_DML_Service.validateList(lRecords);
        return Database.insert(CRMX_DML_Service.validateFieldsAccess(lRecords, AccessType.CREATABLE, true), notPartial);
    }
    /**
     * --------------------------------------------------------------------------------------
     * @Description Overloaded method used to update a list of SObject records
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to be processed in the database
     * @return List<Database.SaveResult> - List of results that were processed
     * @example MX_ENGCRMX_DML_SelectorMX_DML_Selector.updateRecords(lRecords)
     **/
    /*public static List<Database.SaveResult> updateRecords(List<SObject> lRecords) {
        return updateRecords(lRecords, true);
    }*/
    /**
     * --------------------------------------------------------------------------------------
     * @Description Method used to update a list of SObject records
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to be processed in the database
     * @param Boolean notPartial - Set to false if you want the operation to be partial
     * @return List<Database.SaveResult> - List of results that were processed
     * @example CRMX_DML_Selector.updateRecords(lRecords, notPartial)
     */
    public static List<Database.SaveResult> updateRecords(List<SObject> lRecords, Boolean notPartial) {
        CRMX_DML_Service.validateList(lRecords);
        return Database.update(CRMX_DML_Service.validateFieldsAccess(lRecords, AccessType.UPDATABLE, true), notPartial);
    }
    /**
     * --------------------------------------------------------------------------------------
     * @Description Method used to perform secure queries
     * --------------------------------------------------------------------------------------
     * @Author César Chávez García cesar.chavez.garcia@bbva.com
     * @Date 07-08-2024
     * @param List<SObject> lRecords - List of records to be processed in the database
     * @return List<SObject> - List of query results
     * @example CRMX_DML_Selector.secureQuery(lRecords)
     */
    public static List<SObject> secureQuery(List<SObject> lRecords) {
        return CRMX_DML_Service.validateFieldsAccess(lRecords, AccessType.READABLE, false);
    }
}