/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_Product_Locator
* @Author   javier.soto.carrascosa@bbva.com
* @Date     Created: 26/11/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class "Arc_GBL_Product_Locator"
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-11-15 javier.soto.carrascosa@bbva.com
*             Class creation
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Add new filed in querys 'ExternalId'
* -----------------------------------------------------------------------------------------------
*/
public class Arc_GBL_Product_Locator implements Arc_Gen_Product_Interface {//NOSONAR
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getProductsFromTypology" that retrieves products from typology
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-11-26
    * @param String Typology
    * @return   Map with Product Wrappers
    * @example Map<Id, Arc_Gen_Product_Wrapper> getProductsFromTypology(String typolgy)
    **/
    public Map<Id, Arc_Gen_Product_Wrapper> getProductsFromTypology(String typolgy) {
        Map<Id, Arc_Gen_Product_Wrapper> mapWrapper = new Map<Id, Arc_Gen_Product_Wrapper>();
        try {
            List<Product2> lstProd = [SELECT Id, Name, IsActive, Family, ProductCode, ExternalId FROM Product2 WHERE Family = :typolgy AND IsActive = TRUE];
            for(Product2 prod : lstProd) {
                Arc_Gen_Product_Wrapper wrapper = new Arc_Gen_Product_Wrapper();
                wrapper.productName = prod.Name;
                wrapper.productCode = prod.ProductCode;
                wrapper.productId = prod.Id;
                wrapper.parentTypology = prod.Family;
                wrapper.externalId = prod.ExternalId;
                mapWrapper.put(prod.Id, wrapper);
            }
        } catch(Exception ex) {
            throw new QueryException(ex);
        }
        return mapWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getProductsActive" that retrieves products from typology
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-11-26
    * @param String Typology
    * @return   Map with Product Wrappers
    * @example Map<Id, Arc_Gen_Product_Wrapper> getProductsActive()
    **/
    public Map<Id, Arc_Gen_Product_Wrapper> getProductsActive() {
        Map<Id, Arc_Gen_Product_Wrapper> mapWrapper = new Map<Id, Arc_Gen_Product_Wrapper>();
        try {
            List<Product2> lstProd = [SELECT Id, Name, IsActive, Family, ProductCode, ExternalId FROM Product2 WHERE IsActive = TRUE];
            for(Product2 prod : lstProd) {
                Arc_Gen_Product_Wrapper wrapper = new Arc_Gen_Product_Wrapper();
                wrapper.productName = prod.Name;
                wrapper.productCode = prod.ProductCode;
                wrapper.productId = prod.Id;
                wrapper.parentTypology = prod.Family;
                wrapper.externalId = prod.ExternalId;
                mapWrapper.put(prod.Id, wrapper);
            }
        } catch(Exception ex) {
            throw new QueryException(ex);
        }
        return mapWrapper;
    }
}