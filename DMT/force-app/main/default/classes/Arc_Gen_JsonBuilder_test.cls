/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_JsonBuilder_test
* @Author   Diego Miguel Tamarit - diego.miguel.contractor@bbva.com / dmiguelt@minsait.com
* @Date     Created: 2019-07-12
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_JsonBuilder class
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-04-12 diego.miguel.contractor@bbva.com
*             Class creation.
* |2019-07-23 luisruben.quinto.munoz@bbva.com
*             Added parameter
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_JsonBuilder_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description set up test method
    * --------------------------------------------------------------------------------------
    * @Author   diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-07-12
    * @param void
    * @return void
    * @example Arc_Gen_JsonBuilder_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-07-12
    * @param void
    * @return void
    * @example Arc_Gen_JsonBuilder_test.testGetComponents()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetComponents() {
        String collectionType = 'Activities';
        String apiNameObject = 'arce__Data_Collections__c';
        Account newAccount = [SELECT id FROM Account Limit 1];
        String recordId = newAccount.Id;
        String json = '{"collectionType":"'+collectionType+'","Activities" : "'+recordId+'","apiNameObject":"'+apiNameObject+'"}';
        Test.startTest();
        Arc_Gen_JsonBuilder jsonBuilder = new Arc_Gen_JsonBuilder();
        String responseJson = jsonBuilder.getComponents(recordId, json);

        Boolean isValid = responseJson.contains(collectionType) && responseJson.contains(recordId) && responseJson.contains(apiNameObject);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');

        Test.stopTest();
    }
}