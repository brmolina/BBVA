/**
  * @File Name          : Arc_Gen_Charts_controller_test.cls
  * @Description        :
  * @Author             : luisruben.quinto.munoz@bbva.com
  * @Group              :
  * @Last Modified By   : luisruben.quinto.munoz@bbva.com
  * @Last Modified On   : 20/8/2019 18:14:56
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                      Modification
  *==============================================================================
  * 1.0    7/6/2019 13:43:57   luisruben.quinto.munoz@bbva.com     Initial Version
  * 1.1    20/8/2019 13:43:57  luisruben.quinto.munoz@bbva.com     Change type in test
  * 1.2   17/10/2019 18:32:00  manuelhugo.castillo.contractor@bbva.com Modify getChartsJsonComponent param
  * 1.3   22/01/2020 18:21:00  mariohumberto.ramirez.contractor@bbva.com Update test class
  * 1.4   07/01/2020 13:12:00  javier.soto.carrascosa@bbva.com Add support for account wrapper and setupaccounts
  * 1.5   11/08/2020 14:12:00  javier.soto.carrascosa@bbva.com Update sector field
  * 1.5   23/09/2020           saimassimilianno.jordana.contractor@bbva.com Added arce. namespace
  *                             to all classes that are now in the arce-dependencies package
**/
@isTest
public class Arc_Gen_Charts_controller_test {
        @testSetup static void setup() {

        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        insert newSector;

        arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert newArce;

        arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        insert newAnalysis;


        arce__Data_Collections__c newDataCol = Arc_UtilitysDataTest_tst.crearDataCollection('TestGeo','Geographies','05');
        insert newDataCol;

        arce__Table_Content_per_Analysis__c newtableContent = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.id, newDataCol.id, 'Geographies','2017');
        insert newtableContent;


        }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @Author   luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-08-20
    * @param void
    * @return void
    * @example Arc_Gen_Charts_controller_test.getChartsJsonComponenttest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest public static void getChartsJsonComponenttest() {
        arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c limit 1];
        Test.startTest();
          Arc_Gen_Charts_controller obj= new Arc_Gen_Charts_controller();
          String responseJson=obj.getChartsJsonComponent('Geographies',accHasAnls.Id);
          Boolean isValid = responseJson != null ;
          system.assertEquals(true, isValid,'testGetComponents json responseJson contains correct values');
        Test.stopTest();
    }


}