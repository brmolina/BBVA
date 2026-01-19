/**********************************************************************************
* @author       Global Desktop
* @date         24/01/2020
* @description  ReportComponentControllerTest
**********************************************************************************/
@isTest
private class ReportComponentControllerTest {

    @isTest static void getReportMetadataInvalidID() {
        String bogusName;
        bogusName = '00Q000000000000';
        Exception expectedEx;
        String reportJSON;
        try {
            Test.startTest();
                reportJSON = ReportComponentController.getReportMetadata(bogusName);
            Test.stopTest();
        } catch( Exception ex ) {
            expectedEx = ex;
        }

        System.assertEquals( null, reportJSON, 'No report json should be returned' );
        System.assertNotEquals( null, expectedEx, 'An exception should been thronw to be handled by the front-end' );
        
        ReportComponentController repCompCont;
        repCompCont = ReportComponentController.getInstance();

        System.debug(repCompCont);
    }
}