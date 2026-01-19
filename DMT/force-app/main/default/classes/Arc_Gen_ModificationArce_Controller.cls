/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_ModificationArce_Controller
  * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
  * @Date     Created: 2020-05-04
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller class to control all the modification logic of a ARCE
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-05-04 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Class Creation
  * |2020-05-12 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Change reference in field name in method persistenceDmlModificationARCE
  * |2020-05-13 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Add logic to assign group template
  * |2020-07-23 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Modified parameters in method documentation
  * |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
  *             Updated persistenceDmlModificationARCE method for Hu Renovation
  * |2020-09-24 eduardoefrain.hernandez.contractor@bbva.com
  *             Update persistenceDmlModificationARCE method parameters
  **/
  @SuppressWarnings('sf:TooManyMethods')
  public without sharing class Arc_Gen_ModificationArce_Controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_ModificationArce_Controller controller = new Arc_Gen_ModificationArce_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ModificationArce_Controller() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Insert account has analysis to new modified arce
    *-------------------------------------------------------------------------------
    * @date 04/05/2020
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @param Map<String, String> data - map with values (analysisId -> Id of Analysis ARCE,
    *                                                    modRenVar -> Justificacion value fro setting in ARCE name,
    *                                                    selectedSector -> Value of sector selection,
    *                                                    accountswraper -> JSON with de group structure info)
    * @return String id  to redirect
    * @example public static String persistenceDmlModificationARCE(Map<String, String> data) {
    */
      public static String persistenceDmlModificationARCE(Map<String, String> data) {
          return Arc_Gen_ModificationArce_Service.persistenceDmlModificationARCE(data);
      }
}