/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SetAutomatedFileds_Service
* @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2020-04-24
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that populates the automated group fields
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-24 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-01-14 joseluis.garcia4.contractor@bbva.com
*             Remove automatic calculation of provision and qualitative client fields.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_SetAutomatedFileds_Service {
    /**
        * @Description: string with the value of preparing analysis status
    */
    static final string ONE = '1';
    /**
        * @Description: string with the value of preparing analysis status
    */
    static final string TWO = '2';
    /**
        * @Description: string with the value false
    */
    static final string FALSE_S = 'false';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-04-23
    * @param void
    * @return void
    * @example Arc_Gen_SetAutomatedFileds_Service service = new Arc_Gen_SetAutomatedFileds_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_SetAutomatedFileds_Service() {

    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2020-04-23
    * @param    List<Date> dateList - List of Date values to compare
    * @return   Boolean indicator - If is true, the method will obtain the newest value, if not, it will obtain the oldest one
    * @example  public static date updateGroupFields(List<Date> dateList)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAccHasAnalysis(String accHasAnId) {
        List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<Id>{accHasAnId});
        if(ahaList.isEmpty()) {
            throw new ListException(System.Label.Arc_Gen_empty_table);
        }
        Return ahaList[0];
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description Gets the oldest or the newest date of a given list
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2020-04-23
    * @param    List<Date> dateList - List of Date values to compare
    * @return   Boolean indicator - If is true, the method will obtain the newest value, if not, it will obtain the oldest one
    * @example  public static date oldestOrNewestDate(List<Date> dateList)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_GenericUtilities.SaveResult updateGroupFields(arce__Account_has_Analysis__c ahaActual) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{ahaActual.arce__Analysis__c});
        List<Date> dateList = new List<Date>();
        if(ahaList.isEmpty()) {
            throw new ListException(System.Label.Arc_Gen_empty_table);
        } else {
            for(arce__Account_has_Analysis__c aha : ahaList) {
                if(aha.arce__inReview__c && aha.arce__group_asset_header_type__c == TWO) {
                    dateList.add(aha.arce__participant_srty_age_number__c);
                }
            }
            final Date oldestDate = getOldestDate(dateList);
            if(oldestDate != null){
              ahaActual.arce__participant_srty_age_number__c = oldestDate;
            }
        }
        Return arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{ahaActual});
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description Gets the oldest or the newest date of a given list
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2020-04-23
    * @param    List<Date> dateList - List of Date values to compare
    * @return   Boolean indicator - If is true, the method will obtain the newest value, if not, it will obtain the oldest one
    * @example  private static date oldestOrNewestDate(List<Date> dateList)
    * ----------------------------------------------------------------------------------------------------
    **/
    private static Date getOldestDate(List<Date> dateList) {
        Date tempDate = null;
        if(!dateList.isEmpty()) {
            tempDate = System.today();
        }
        for(Date dt : dateList) {
            if(dt < tempDate) {
                tempDate = dt;
            }
        }
        Return tempDate;
    }
}