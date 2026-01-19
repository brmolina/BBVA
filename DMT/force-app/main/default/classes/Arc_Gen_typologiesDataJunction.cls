/**
* @File Name          : Arc_Gen_typologiesDataJunction.cls
* @Description        : wrapper class to join typologies wrappers
* @Author             :luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : luisarturo.parra.contractor@bbva.com
* @Last Modified On   : 15/10/2019 05:17
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    15/12/2019           luisarturo.parra.contractor@bbva.com     Initial Version
* 1.0    23/09/2020     saimassimilianno.jordana.contractor@bbva.com   Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public class Arc_Gen_typologiesDataJunction {
    /** instance of typology data names**/
    public Arc_Gen_TypologiesAmmountsWrapper typonames { get;set;}
    /** instance of customer data information**/
    public arce.Arc_Gen_GenericUtilities.Customerinfo customerinfo { get;set;}
    /** instance of a map to save ammounts**/
    public Map<String,String> typosammounts { get;set;}
    /** instance of a map to save names**/
    public Map<String,String> typosname { get;set;}
    /**
*-------------------------------------------------------------------------------
* @description instance of constructor
*-------------------------------------------------------------------------------
* @date 30/04/2019
* @author luisarturo.parra.contractor@bbva.com
* @param none
* @return  none
* @example public Arc_Gen_typologiesDataJunction(){
*/
    public Arc_Gen_typologiesDataJunction(){
        typosammounts = new Map<String,String>();
        typosname = new Map<String,String>();
        typonames = new Arc_Gen_TypologiesAmmountsWrapper();
        customerinfo = new arce.Arc_Gen_GenericUtilities.Customerinfo();
    }
}