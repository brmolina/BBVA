/** ********************************************************************************
* @author       JSS
* @date         30/04/2020
* @description  Clase para testear la clase PRCButtonsValidationImpl
* @Revision
********************************************************************************* */
@isTest
public class PRCButtonsValidationImpl_TEST {


   /**
    * @description
    * @author Global Desktop | 03-05-2021
    * @return testmethod
    **/
    public static testmethod void test01() {
         //INSERT DATA NEEDED
		 final String OBJECT_TYPE = 'Opportunity';
         final String BUTTON_TYPE = 'Pricing_details';
         PRC_TestUtils utils = new PRC_TestUtils();
         String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterAmiweb((String) utils.opp.Id, utils.priceFullResponse, utils.selectedPrice);

         //START TEST
         
            List<String> msgList = PRCButtonsValidationImpl.getErrorMessagesList((String) utils.opp.Id, OBJECT_TYPE, BUTTON_TYPE);
         

         //ASSERTS
         System.assertEquals(1,msgList.size());
     }


    /**
    * @description
    * @author Global Desktop | 03-05-2021
    * @return testmethod
    **/
    public static testmethod void test02() {
         //INSERT DATA NEEDED
		   final String OBJECT_TYPE = 'Opportunity';
         final String BUTTON_TYPE = 'Send_to_Workflow';
         final String BUTTON_TYPE2 = 'Download_Pricing';//NO SONAR
         final PRC_TestUtils utils = new PRC_TestUtils();
         String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterAmiweb((String) utils.opp.Id, utils.priceFullResponse, utils.selectedPrice);

         //START TEST
         
            final List<String> msgList = PRCButtonsValidationImpl.getErrorMessagesList((String) utils.opp.Id, OBJECT_TYPE, BUTTON_TYPE);
            final List<String> msgList2 = PRCButtonsValidationImpl.getErrorMessagesList((String) utils.opp.Id, OBJECT_TYPE, BUTTON_TYPE2);//NOSONAR
         

         //ASSERTS
         System.assertEquals(1,msgList.size());
     }

}