/**
  * @File Name : Arc_Gen_Product_Wrappers.cls
  * @Description : Wrapper utility to for Product interfaces
  * @Author : javier.soto.carrascposa@bbva.com
  * @Group : ARCE - BBVA
  * @Last Modified By : javier.soto.carrascosar@bbva.com
  * @Last Modified On : 26/11/2019 17:59
  * @Modification Log :
  *==============================================================================
  * Ver Date Author          Modification
  *==============================================================================
  * 1.0 07/11/2019 ARCE TEAM Creation file
  * 1.1 28/01/2020 mariohumberto.ramirez.contractor@bbva.com  added new param externalId
  **/
public class Arc_Gen_Product_Wrapper {
    /**
    *
    * @Description : Name of the product
    */
    public String productName {get; set;}
    /**
    *
    * @Description : string with code of the product
    */
    public String productCode {get; set;}
    /**
    *
    * @Description : Salesforce Id of the product
    */
    public Id productId {get; set;}
    /**
    *
    * @Description : Parent typology code
    */
    public String parentTypology {get; set;}
    /**
    *
    * @Description : external Id code
    */
    public String externalId {get; set;}
}