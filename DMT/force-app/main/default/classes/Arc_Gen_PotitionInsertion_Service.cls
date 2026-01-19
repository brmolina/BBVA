/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionInsertion_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_PotitionInsertion_Service CMP
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_PotitionInsertion_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_PotitionInsertion_Service service = new Arc_Gen_PotitionInsertion_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_PotitionInsertion_Service() {

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
    public static List<Map<string,string>> getProductsActive() {
        final List<Map<string,string>> listaProd = new List<Map<string,string>>();
        Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsActive();
        Arc_Gen_Product_Wrapper prod = new Arc_Gen_Product_Wrapper();
        for (id prodId: pWrap.keySet()) {
            prod = pWrap.get(prodId);
            listaProd.add(new map<String,String>{'value' => prodId , 'label' => prod.productName});
        }
        return listaProd;
    }
}