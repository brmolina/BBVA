/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidationRating_Interface
* @Author   ARCE
* @Date     Created: 20/04/2020
* -----------------------------------------------------------------------------------------------
* @Description Interface to validations of the rating process
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-20 juanignacio.hita.contractor@bbva.com
*             Interface creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_ValidationsRating_Interface {
    /**
    *
    * @Description : Method that validate the question qualitative of the analysis
    * @param : recordId : record id to acc has analysis
    * @param : templateDevName  : developer name of the template
    * @return : List<String> : list of developer names of the empty fields
    */
    List<String> validateQualitativeQuestion(String recordId, String templateDevName);
    /**
    *
    * @Description : Validation to validate that the user who validates
    * that the user who validates the analysis must be different from the user
    * who proposed it.
    * @param : proposeUserId : record id of the proposing user
    * @return : String : If the validation is successful 'OK' will be returned, otherwise the error message
    */
    String userValidate(String proposeUserId);

}