/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 06-05-2021
 * @last modified by  : Global Desktop
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   26-04-2021   Global Desktop   Initial Version
**/
@SuppressWarnings('sf:ShortVariable,sf:VariableNamingConventions,sf:VariableDeclarationHidesAnothe')
public with sharing class DES_Arc_Prospect {

    /**
    * @Description : Origin of the prospect business creation.
    */
    public String origin {get; set;}
    /**
    * @Description : Unique identifier designed by BBVA for prospect business.
    */
    public String id {get; set;}
    /**
    * @Description : Legal name of the prospect business.
    */
    public String legalName {get; set;}
    /**
    * @Description : Unique business customer identifier.
    */
    public String businessId {get; set;}
    /**
    * @Description : List of business documents related to the prospect business creation process.
    */
    public List<businessDocuments> businessDocuments {get; set;}

    /**
    * @description
    * @author Global Desktop | 06-05-2021
    **/
    public DES_Arc_Prospect() {
        this.origin = 'GLOBAL_DESKTOP';
        this.legalName = '';
    }
    /**
    * @Description : Wrapper of businessDocuments
    */
    public class businessDocuments {
        /**
        * @Description: Value number of the business document.
        */
        public String number_y {get;set;}
        /**
        * @Description: Business document number type identifier.
        */
        public numberType numberType {get;set;}

        /**
        * @description
        * @author Global Desktop | 06-05-2021
        **/
        public businessDocuments() {}
        /**
        * @description
        * @author Global Desktop | 06-05-2021
        * @param number_y
        **/
        public businessDocuments(String number_y) {
            this.number_y = number_y;
            this.numberType = new numberType();
        }
    }

    /**
    * @Description : Wrapper of links
    */
    public class numberType {
        /**
        * @Description: Links
        */
        public String id {get;set;}

        public numberType() {
            this.id = 'CIF';
        }
        public numberType(String id) {
            this.id = id;
        }
    }
}