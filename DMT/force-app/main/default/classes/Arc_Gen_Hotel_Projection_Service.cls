/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Hotel_Projection_Service
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Service class of Arc_Gen_Hotel_Projection_Table component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  * |2020-12-07 mariohumberto.ramirez.contractor@bbva.com
  *             Added custom label for the year column
  **/
public without sharing class Arc_Gen_Hotel_Projection_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-10-21
    * @param void
    * @return void
    * @example Arc_Gen_Hotel_Projection_Service service = new Arc_Gen_Hotel_Projection_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Hotel_Projection_Service() {

    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description insert the projection table records
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   recordId - id of the account has analysis
    * @return  void
    * @example insertTableRecords(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    public static void insertTableRecords(String recordId) {
        final List<arce__hotel_projection__c> hotelLts = new List<arce__hotel_projection__c>();
        if (Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(recordId).isEmpty()) {
            for (integer i = 1; i <= 6; i++) {
                arce__hotel_projection__c hotel = new arce__hotel_projection__c();
                hotel.arce__account_has_analysis_id__c = recordId;
                hotel.arce__gf_const_proj_year_number_type__c = i == 6 ? Label.Arc_Gen_Year + ' > 5' : Label.Arc_Gen_Year + ' ' + i;
                hotel.arce__gf_hotel_avg_daily_rate_amount__c = 0;
                hotel.arce__gf_hotel_occupancy_per__c = 0;
                hotel.arce__gf_rev_per_avail_room_amount__c = 0;
                hotel.arce__gf_htl_gs_oper_profit_amount__c = 0;
                hotel.arce__gf_debt_available_funds_amount__c = 0;
                hotel.arce__gf_interest_expense_amount__c = 0;
                hotel.arce__gf_loan_funded_amount__c = 0;
                hotel.arce__gf_debt_svc_covrg_ratio_number__c = 0;
                hotel.arce__gf_hotel_breakeven_occup_per__c = 0;
                hotelLts.add(hotel);
            }
            insert hotelLts;
        }
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the projection table info needed to build the table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   recordId - id of the account has analysis
    * @return  String
    * @example getTableData(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    public static String getTableData(String recordId) {
        Arc_Gen_Hotel_Projection_Helper.ProjectionTable tableInfo = new Arc_Gen_Hotel_Projection_Helper.ProjectionTable();
        final List<arce__hotel_projection__c> hotelLts = Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(recordId);
        if (hotelLts.isEmpty()) {
            throw new QueryException(Label.Arc_Gen_NoDataShow);
        }
        tableInfo = Arc_Gen_Hotel_Projection_Helper.getTableData(hotelLts);
        tableInfo.currencyVal = hotelLts[0].currencyIsoCode;
        tableInfo.unit = Arc_Gen_Hotel_Projection_Helper.getUnit(hotelLts[0].arce__magnitude_unit_type__c);
        tableInfo.showButton = Arc_Gen_TabSet_service.getPermissionToEdit(recordId);
        return JSON.serialize(tableInfo);
    }
}