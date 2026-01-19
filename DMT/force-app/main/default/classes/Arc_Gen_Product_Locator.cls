/**
  * @File Name : Arc_Gen_Product_Locator.cls
  * @Description : Locator for products
  * @Author : javier.soto.carrascosa@bbva.com
  * @Group : ARCE - BBVA
  * @Last Modified By : javier.soto.carrascosa@bbva.com
  * @Last Modified On : 26/11/2019 17:59
  * @Modification Log :
  *==============================================================================
  * Ver   Date        Author                              Modification
  *==============================================================================
  * 1.0   26/11/2019  ARCE TEAM                           Creation file
  * 1.1   30/06/2020  javier.soto.carrascosa@bbva.com     Change getAccLocatorClass method, enforce GBL class execution in tests
  * 1.1   23/09/2020  saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.2   30/04/2021  otiliaramona.veres.contractor@bbva.com Added an empty constructor method.
  * 1.3   04/05/2021  otiliaramona.veres.contractor@bbva.com Added annotation '@testVisible' to the empty constructor method.
  **/
public without sharing class Arc_Gen_Product_Locator implements Arc_Gen_Product_Interface {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    * @Date   Created:2021-04-30
    * @param void
    * @return void
    * @example Arc_Gen_Product_Locator locator = new Arc_Gen_Product_Locator()
    */
    @TestVisible
    private Arc_Gen_Product_Locator() { }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that retrieves products based on typology
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-11-26
    * @param String Typology
    * @return Map<Id,Arc_Gen_Product_Wrapper>
    * @example public static Map<Id,Arc_Gen_Product_Wrapper> getProductsFromTypology(String typology) {
    **/
    public static Map<Id,Arc_Gen_Product_Wrapper> getProductsFromTypology(String typology) {
        Map<Id,Arc_Gen_Product_Wrapper> lstWrapper = new Map<Id,Arc_Gen_Product_Wrapper>();
        Arc_Gen_Product_Interface classLocatorProd = getProdLocatorClass();
        if (classLocatorProd != null) {
            try {
                lstWrapper = classLocatorProd.getProductsFromTypology(typology);
            } catch(Exception ex) {
                throw new QueryException(ex);
            }
        }
        return lstWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that retrieves all active products to be select in positions
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-11-26
    * @param String Typology
    * @return Map<Id,Arc_Gen_Product_Wrapper>
    * @example public static Map<Id,Arc_Gen_Product_Wrapper> getProductsActive()
    **/
    public static Map<Id,Arc_Gen_Product_Wrapper> getProductsActive() {
        Map<Id,Arc_Gen_Product_Wrapper> lstWrapper = new Map<Id,Arc_Gen_Product_Wrapper>();
        Arc_Gen_Product_Interface classLocatorProd = getProdLocatorClass();
        if (classLocatorProd != null) {
            try {
                lstWrapper = classLocatorProd.getProductsActive();
            } catch(Exception ex) {
                throw new QueryException(ex);
            }
        }
        return lstWrapper;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method "getAccLocatorClass" to find the class with the interface Arc_Gen_Account_Interface
    * ---------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2019-11-26
    * @return   Arc_Gen_Account_Interface
    * @example Arc_Gen_Account_Interface accInterface = getAccLocatorClass(nameConfig)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_Product_Interface getProdLocatorClass() {
        final List<arce__Arce_Config__mdt> lstArceConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ProductInterface');
        final String localClass = Test.isRunningTest() ? 'Arc_GBL_Product_Locator' : lstArceConfig.get(0).arce__Value1__c;
        System.Type objType = Type.forName(localClass);
        Arc_Gen_Product_Interface classLocatorProd = (Arc_Gen_Product_Interface) objType.newInstance();
        return classLocatorProd;
    }
}