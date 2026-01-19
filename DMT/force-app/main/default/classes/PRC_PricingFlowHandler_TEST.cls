/** ********************************************************************************
 * @author       JSS
 * @date         29/04/2020
 * @description  Clase para testear el controlador PRC_PricingFlowHandler_CONTROLLER
 * @Revision
 ********************************************************************************* */
@isTest
public class PRC_PricingFlowHandler_TEST {
    /**
     * @description
     * @author Global Desktop | 03-08-2021
     * @return testmethod
     **/
    public static testmethod void getstatetest01() {
        //INSERT DATA NEEDED
        final PRC_TestUtils utils = new PRC_TestUtils();
        delete utils.pd;

        //START TEST
        String resp = PRC_PricingFlowHandler_CONTROLLER.getstate((String) utils.opp.Id);

        //ASSERTS
        System.assertEquals('Product Selector', resp);
    }

    /**
     * @description
     * @author Global Desktop | 03-08-2021
     * @return testmethod
     **/
    public static testmethod void getstatetest02() {
        //INSERT DATA NEEDED
        final PRC_TestUtils utils = new PRC_TestUtils();

        //START TEST
        String resp = PRC_PricingFlowHandler_CONTROLLER.getstate((String) utils.opp.Id);

        //ASSERTS
        System.assertEquals('Price Form', resp);
    }

    /**
     * @description
     * @author Global Desktop | 03-08-2021
     * @return testmethod
     **/
    public static testmethod void callWsPrcCalculateMatrixtest() {
        //INSERT DATA NEEDED
        final PRC_TestUtils utils = new PRC_TestUtils();

        //START TEST
        final PRC_PFS_Response respObject = PRC_PricingFlowHandler_CONTROLLER.callWS((String) utils.opp.Id);

        //ASSERTS -- se podrían añadir más asserts de respObject
        System.assertNotEquals(null, respObject);
    }

    /**
     * @description
     * @author Global Desktop | 03-08-2021
     * @return testmethod
     **/
    public static testmethod void callWsPrcCalculateMatrixUserDefinedtest() {
        //INSERT DATA NEEDED
        final PRC_TestUtils utils = new PRC_TestUtils();

        utils.pd.amortization_desc__c = 'USER_DEFINED';
        update utils.pd;

        //START TEST
        final PRC_PFS_Response respObject = PRC_PricingFlowHandler_CONTROLLER.callWS((String) utils.opp.Id);

        //ASSERTS -- se podrían añadir más asserts de respObject
        System.assertNotEquals(null, respObject);
    }

}