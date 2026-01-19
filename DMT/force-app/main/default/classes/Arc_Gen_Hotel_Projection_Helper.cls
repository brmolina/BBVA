/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Hotel_Projection_Helper
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Helper class of Arc_Gen_Hotel_Projection_Table component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  **/
public without sharing class Arc_Gen_Hotel_Projection_Helper {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-10-21
    * @param void
    * @return void
    * @example Arc_Gen_Hotel_Projection_Helper helper = new Arc_Gen_Hotel_Projection_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Hotel_Projection_Helper() {

    }
    /*
        @Description wrapper with the info of the porojection table table
    */
    public class ProjectionTable {
        /*
            @Description column information of the table
        */
        @AuraEnabled public List<String> columns {get;set;}
        /*
            @Description row information of the table
        */
        @AuraEnabled public List<List<String>> rows {get;set;}
        /*
            @Description currency information of the table
        */
        @AuraEnabled public String currencyVal {get;set;}
        /*
            @Description unit information of the table
        */
        @AuraEnabled public String unit {get;set;}
        /*
            @Description show / hide manage button
        */
        @AuraEnabled public String showButton {get;set;}
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the projection table info needed to build the table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   hotelLts - List of arce__hotel_projection__c object
    * @return  String
    * @example getTableData(hotelLts)
    * --------------------------------------------------------------------------------------------------
    **/
    public static ProjectionTable getTableData(List<arce__hotel_projection__c> hotelLts) {
        final ProjectionTable tableData = new ProjectionTable();
        List<String> columns = new List<String>();
        for(arce__hotel_projection__c hotel: hotelLts) {
            columns.add(hotel.arce__gf_const_proj_year_number_type__c);
        }
        columns.sort();
        columns[5] = columns[5].contains('> 5') ? columns[5] : columns[5] + ' > 5';
        final Map<String,Map<String,String>> mapStructure = new Map<String,Map<String,String>>();
        for (String column: columns) {
            Map<String,String> mapAux = new Map<String,String>();
            for (arce__hotel_projection__c hotProj: hotelLts) {
                if (column == hotProj.arce__gf_const_proj_year_number_type__c || column == hotProj.arce__gf_const_proj_year_number_type__c + ' > 5') {
                    mapAux.put(Label.Arc_Gen_ADR,hotProj.arce__gf_hotel_avg_daily_rate_amount__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_PercentOccupancy,hotProj.arce__gf_hotel_occupancy_per__c.setscale(2).format() + ' %');
                    mapAux.put(Label.Arc_Gen_REVPAR,hotProj.arce__gf_rev_per_avail_room_amount__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_GOP,hotProj.arce__gf_htl_gs_oper_profit_amount__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_FundsAvailableDS,hotProj.arce__gf_debt_available_funds_amount__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_INTERESTS,hotProj.arce__gf_interest_expense_amount__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_PRINCIPAL,hotProj.arce__gf_loan_funded_amount__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_RCSD_PROJECTED,hotProj.arce__gf_debt_svc_covrg_ratio_number__c.setscale(2).format());
                    mapAux.put(Label.Arc_Gen_OccupationBreakEv,hotProj.arce__gf_hotel_breakeven_occup_per__c.setscale(2).format());
                }
            }
            mapStructure.put(column,mapAux);
        }
        final List<String> colNamesFinal = new List<String>{''};
        colNamesFinal.addAll(columns);
        final List<List<String>> listaFinal = new List<List<String>>();
        final Set<String> nombres = mapStructure.get(columns[0]).keySet();
        for (String nombre: nombres) {
            final List<String> listaAux = new List<String>();
            listaAux.add(nombre);
            for (String columnName: columns) {
                listaAux.add(mapStructure.get(columnName).get(nombre));
            }
            listaFinal.add(listaAux);
        }
        tableData.columns = colNamesFinal;
        tableData.rows = listaFinal;
        return tableData;
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the unit of the table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   val - unit of the picklist arce__magnitude_unite_type
    * @return  String
    * @example getUnit(hotelLts)
    * --------------------------------------------------------------------------------------------------
    **/
    public static String getUnit(String val) {
        String unit = '';
        switch on val {
            when '1' {
                unit = Label.Arc_Gen_Unit;
            }
            when '2' {
                unit = Label.Arc_Gen_Thousands;
            }
            when '3' {
                unit = Label.Arc_Gen_Millions;
            }
        }
        return unit;
    }
}