/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_DwpTableWrapper
* @Author   Juan Ignacio Hita Manso
* @Date     Created: 27/07/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Wrapper class for build dynamic tables from manual constructor of rows
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-27 Juan Ignacio Hita Manso
*             Class creation.
* |2020-09-16 Juan Ignacio Hita Manso
*             Removed unused variables and added lblCell in Cell_Wrapper constructor
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD, sf:TooManyMethods')
global class Arc_Gen_DwpTableWrapper {
    /**
    * @Description: Global dynamic_table_wrapper attribute
    */
    @AuraEnabled global Dynamic_Table_Wrapper table { get; set; }
    /**
    * @Description: Label setting for empty table
    */
    @AuraEnabled global String lblEmptyTable { get; set; }
    /**
    *
    *
    * @author
    */
    global class Dynamic_Table_Wrapper {
        global List<Arc_Gen_DwpTableWrapper.Row_Wrapper> lstHeaders { get; set; }
        global List<Arc_Gen_DwpTableWrapper.Row_Wrapper> lstRows { get; set; }
    }
    /**
    *
    *
    * @author
    */
    public class Row_Wrapper {
        @AuraEnabled public String idRow;  //NOSONAR
        @AuraEnabled public Boolean isHidden;  //NOSONAR
        @AuraEnabled public Boolean isCollapsed; //NOSONAR
        @AuraEnabled public Boolean openCollapsible; //NOSONAR
        @AuraEnabled public Decimal lvlGroup;  //NOSONAR
        @AuraEnabled public Boolean isTotalRow;  //NOSONAR
        @AuraEnabled public List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCells;  //NOSONAR

        public void setRowWrapper(String ffssId, List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCells) {
            this.openCollapsible = null;//NOSONAR
            this.lvlGroup = null;//NOSONAR
            this.isTotalRow = null;//NOSONAR
            this.isHidden = false;
            this.isCollapsed = false;
            this.idRow = ffssId;
            this.lstCells = lstCells;
        }
    }
    /**
    *
    *
    * @author
    */
    global class Cell_Wrapper {
        @AuraEnabled global String idCell { get; set; }
        @AuraEnabled global Object valCell { get; set; }
        @AuraEnabled global String lblCell { get; set; }
        @AuraEnabled global Arc_Gen_DwpTableWrapper.TypeCell_Wrapper typeCell { get; set; }

        public Cell_Wrapper() {}

        public Cell_Wrapper(String idCell, Object valCell, Arc_Gen_DwpTableWrapper.TypeCell_Wrapper typeCell) {
            this.idCell = idCell;
            this.valCell = valCell;
            this.lblCell = lblCell;
            this.typeCell = typeCell;
            this.typeCell.align = 'center';
        }
    }
    /**
    *
    *
    * @author
    */
    public class TypeCell_Wrapper {
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String align { get; set; }
        @AuraEnabled public Decimal colspan { get; set; }
        @AuraEnabled public Decimal maximumFractionDigits { get; set; }
        @AuraEnabled public String currencyDisplayAs { get; set; }
        @AuraEnabled public String currencyCode { get; set; }
        @AuraEnabled public String href { get; set; }
        @AuraEnabled public List<Arc_Gen_DwpTableWrapper.Action_Wrapper> lstAction { get; set; }
    }
    /**
    *
    *
    * @author
    */
    global class Action_Wrapper {
        @AuraEnabled global String lblAction { get; set; }
        @AuraEnabled global String txtAction { get; set; }
        @AuraEnabled global String actionType { get; set; }
        @AuraEnabled global String componentName { get; set; }

        public Action_Wrapper() {}

        public Action_Wrapper(String lblAction, String txtAction, String actionType, String componentName) {
            this.lblAction = lblAction;
            this.txtAction = txtAction;
            this.actionType = actionType;
            this.componentName = componentName;
        }
    }
}