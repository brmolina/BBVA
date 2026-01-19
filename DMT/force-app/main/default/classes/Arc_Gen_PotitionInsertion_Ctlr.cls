/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionInsertion_Ctlr
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_PotitionTableInsertion CMP
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_PotitionInsertion_Ctlr {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_PotitionInsertion_Ctlr ctlr = new Arc_Gen_PotitionInsertion_Ctlr()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_PotitionInsertion_Ctlr() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Return a list of products
    * -----------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-07-24
    * @param void
    * @return List of products
    * @example getProductsActive()
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<Map<string,string>> getProductsActive() {
        List<Map<string,string>> productList = new List<Map<string,string>>();
        try {
            productList = Arc_Gen_PotitionInsertion_Service.getProductsActive();
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
        return productList;
    }
}