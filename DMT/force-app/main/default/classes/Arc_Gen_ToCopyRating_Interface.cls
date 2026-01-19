/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ToCopyRating_Interface
* @Author   Antonio Muñoz Pérez  antonio.munoz.perez.contractor@bbva.com
* @Date     Created: 2020-12-16
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Interface "Arc_Gen_ToCopyRating_Interface"
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-12-16 antonio.munoz.perez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_ToCopyRating_Interface {
    /**
    *
    * @Description : Retrieves an aha given the current aha.Id and a list with all the ahas data in the analysis.
    */
    arce__Account_has_Analysis__c getMatrix (List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaLst, ID idRecord);
    /**
    *
    * @Description : Retrieves an aha given the current aha.Id and a list with all the ahas data in the analysis.
    */
    arce__Account_has_Analysis__c getHeader (List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaLst, ID idRecord);
    /**
    *
    * @Description : Retrieves true or false given two arce__Account_has_Analysis__c.
    */
    Boolean doCopy (arce__Account_has_Analysis__c matrix, arce__Account_has_Analysis__c header);
    /**
    *
    * @Description : Retrieves a result of a local operation given two arce__Account_has_Analysis__c.
    */
    arce.Arc_Gen_ServiceAndSaveResponse updateRating (arce__Account_has_Analysis__c matrix, arce__Account_has_Analysis__c header);
}