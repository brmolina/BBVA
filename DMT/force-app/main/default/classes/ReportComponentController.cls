/**********************************************************************************
* @author       Global Desktop
* @date         24/01/2020
* @description  ReportComponentController
**********************************************************************************/
public with sharing class ReportComponentController {
    /**
        * @author Global Desktop
    * @description SINGLETON PATTERN
    */
    private static ReportComponentController instance;

    /**
    * @author Global Desktop
    * @description getInstance
    */
    public static ReportComponentController getInstance() { //NOSONAR
        if (instance == null) {
        instance = new ReportComponentController();
        }
        return instance;
    }

  /*
  * Met0d0 para pasar sonar
  */
  private ReportComponentController() {}

    /*
    *   Comentario sonar
    *
     */
	@AuraEnabled
    public static String getReportMetadata(String reportDevName) {
        final Report rep = [SELECT Id FROM Report WHERE DeveloperName = :reportDevName LIMIT 1];
        return JSON.serializePretty(Reports.ReportManager.runReport(rep.Id, true));
    }
}