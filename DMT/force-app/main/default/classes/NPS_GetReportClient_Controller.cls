/**********************************************************************************
* @author       Global Desktop
* @date         21/04/2020
* @description  Controller del componente NPS_GetReportClient
**********************************************************************************/
public with sharing class NPS_GetReportClient_Controller {
    /**
     * @author Global Desktop
     * @description URL de la list view My NPS Contacts
     */
    public String reportURL {get; set;}

    /**
     * @author Global Desktop
     * @description Constructor
     */
    public NPS_GetReportClient_Controller() {
      final List<Report> listReport = [SELECT Id,
                                        Name,
                                        DeveloperName
                                      FROM Report
                                      WHERE DeveloperName = 'NPS_Perimeter'];
      reportURL = System.URL.getOrgDomainUrl().toExternalForm() + '/' + listReport[0].Id;
    }
  }