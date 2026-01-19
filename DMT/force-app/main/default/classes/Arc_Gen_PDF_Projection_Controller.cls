/**
* ------------------------------------------------------------------------------------------------
* @Name Arc_Gen_PDF_Projection_Controller
* @Author   joseluis.miralles.contractor@bbva.com
* @Date     Created: 15/05/2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class for visualforce page Arc_Gen_PDF_Projection_DataTable_Summary
* -----------------------------------------------------------------------------------------------
* @Changes
**/
@SuppressWarnings('sf:LongVariable')
public without sharing class Arc_Gen_PDF_Projection_Controller {
    /**
    * @Description : Wrapper where data is stored for Base Case scenario
    */
    public Arc_Gen_PDF_Projection_Helper.TableProjectionWrapper tableDataWrapperBaseCase { get; set; }
        /**
        * @Description : Wrapper where data is stored for Down scenario
        */
    public Arc_Gen_PDF_Projection_Helper.TableProjectionWrapper tableDataWrapperDown { get; set; }
        /**
        * @Description : Wrapper where data is stored for Up scenario
        */
    public Arc_Gen_PDF_Projection_Helper.TableProjectionWrapper tableDataWrapperUp { get; set; }
        /**
        * @Description : Wrapper where client data is stored
        */
    public Arc_Gen_PDF_Projection_Helper.TableProjectionClient tableDataWrapperHeaderData { get; set; }
        /**
        * @Description : Wrapper where Simulation data
        */
    public Arc_Gen_PDF_Projection_Helper.TableProjectionWrapper tableDataWrapperSimulation { get; set; }
    /*------------------------------------------------------------------------------------------------------
    *@Description
    * -----------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     15/05/2023
    * @return   instance of Arc_Gen_PDF_Projection_Controller
    * @example  Arc_Gen_PDF_Projection_Controller()
    */
    public Arc_Gen_PDF_Projection_Controller() {
        final Id ahaId = ApexPages.currentPage().getParameters().get('ahaId');
        this.tableDataWrapperHeaderData = Arc_Gen_PDF_Projection_Helper.getClientData(ahaId);
        this.tableDataWrapperSimulation = Arc_Gen_PDF_Projection_Helper.getProjectionSimulationData(ahaId);
        this.tableDataWrapperBaseCase = Arc_Gen_PDF_Projection_Helper.getProjectionData(ahaId, 'Base Case');
        this.tableDataWrapperUp = Arc_Gen_PDF_Projection_Helper.getProjectionData(ahaId, 'Up');
        this.tableDataWrapperDown = Arc_Gen_PDF_Projection_Helper.getProjectionData(ahaId, 'Down');
        final String myFileName = tableDataWrapperHeaderData.fileName;
        Apexpages.currentPage().getHeaders().put('Content-Disposition', 'inline; filename=' + myFileName + '.pdf');
    }
}