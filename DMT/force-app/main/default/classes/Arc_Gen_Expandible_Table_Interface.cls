/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Expandible_Table_Interface
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-05-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Interfaz for Arc_Gen_Expandible_Table_cmp
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-06 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getproductService
* -----------------------------------------------------------------------------------------------
*/
global interface Arc_Gen_Expandible_Table_Interface {
    /**
    * --------------------------------------------------------------------------------------
    * @Description get data to build table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param recordId - id of the acc has analysis object
    * @return Arc_Gen_DataTable - wrapper with the info to build the table
    * @example getData(recordId)
    * --------------------------------------------------------------------------------------
    **/
    Arc_Gen_DataTable getData(Id recordId);
    /**
    * --------------------------------------------------------------------------------------
    * @Description get a list of products
    * --------------------------------------------------------------------------------------
    * @param accHasAId - Id of the account has analysis object
    * @param tipologia - name of the typology
    * @param parentId -  Id of the parent record
    * @return true/false
    * @example getProductsService(accHasAId,tipologia,parentId)
    * --------------------------------------------------------------------------------------
    **/
    Map<String,Double> insertProducts(String accHasAId, String tipologia, String prodId);
}