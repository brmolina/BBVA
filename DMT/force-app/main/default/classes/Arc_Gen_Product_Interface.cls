/**
  * @File Name : Arc_Gen_Product_Interface.cls
  * @Description : Interface for poducts
  * @Author : javier.soto.carrascosa@bbva.com
  * @Group : ARCE - BBVA
  * @Last Modified By : javier.soto.carrascosa@bbva.com
  * @Last Modified On : 26/11/2019 17:59
  * @Modification Log :
  *==============================================================================
  * Ver Date Author          Modification
  *==============================================================================
  * 1.0 26/11/2019 ARCE TEAM Creation file
  **/
public interface Arc_Gen_Product_Interface {
    /**
    *
    * @Description : Retrieves all avalaible products/typologies available for a parent typology
    */
    Map<Id, Arc_Gen_Product_Wrapper> getProductsFromTypology(String typology);
    /**
    *
    * @Description : Retrieves all active products available for position tree grid (manual input)
    */
    Map<Id,Arc_Gen_Product_Wrapper> getProductsActive();
}