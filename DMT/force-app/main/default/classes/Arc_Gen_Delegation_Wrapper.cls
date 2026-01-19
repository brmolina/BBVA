/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Delegation_Wrapper
* @Author   Juan Ignacio Hita Manso juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-01-07
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Wrapper class "Arc_Gen_Delegation_Wrapper"
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2021-04-28 jose.hijar.contractor@bbva.com
*             Added lstUsers property copied from global desktop code
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_Delegation_Wrapper {
    /**
    * @Description : Analysis id
    */
    public Id analysisId {get;set;}
    /**
    * @Description : Ambit current user
    */
    public String ambit {get;set;}
    /**
    * @Description : Ambit sanction
    */
    public String sanctionAmbit {get;set;}
    /**
    * @Description : Status of if the analysis has delegation. Values: YES,NO,NOTCALCULATED
    */
    public String hasDelegation {get;set;}
    /**
    * @Description : List of ambit
    */
    public List<Map<String,String>> lstAmbits {get;set;}
    /**
    * @Description : List of comittees
    */
    public List<Map<String,String>> lstComittees {get;set;}
    /**
    * @Description : List of actions
    */
    public List<Map<String,String>> lstActions {get;set;}
    /**
    * @Description : Code status errors handling
    */
    public Integer codStatus {get;set;}
    /**
    * @Description : Message info in the errors handling
    */
    public String msgInfo {get;set;}
    /**
    * @Description : List of users
    */
    public List<Map<String,String>> lstUsers {get;set;}
    /**
    * @Description : List of ambit
    */
    public List<Map<String,String>> lstRegion {get;set;}
    /**
    * @Description : List of ambit
    */
    public List<Map<String,String>> lstLevel {get;set;}
    /**
    * @Description : Boolean validate
    */
    public Boolean validate {get;set;}
}