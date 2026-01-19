/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_HotelProjSaveCombo_Service
* @Author   Mario Humberto Ramirez Lio
* @Date     Created: 2020-11-12
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for save currency and units combo from Hotels projection table
* ------------------------------------------------------------------------------------------------
* |2020-11-12 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
public without sharing class Arc_Gen_HotelProjSaveCombo_Service implements Arc_Gen_RelatedTableManager_Interface {
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Save currency and unit combo box
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-11-12
    * @param   recordId - id of the account has analysis
    * @param   value - value to save
    * @param   combo - type of combo
    * @return  String
    * @example saveCombos(recordId, value, combo)
    * --------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse saveCombos(String recordId, String value, String combo) {
        arce.Arc_Gen_ServiceAndSaveResponse wrapperResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final List<arce__hotel_projection__c> hotelRecords = Arc_Gen_Hotel_Projection_Locator.getHotelProjectionInfo(recordId);
        if (combo == 'currency' && !hotelRecords.isEmpty()) {
            for (arce__hotel_projection__c hotel: hotelRecords) {
                hotel.CurrencyIsoCode = value;
            }
            wrapperResp = Arc_Gen_Hotel_Projection_Locator.updateHotelProj(hotelRecords);
        } else if (combo == 'unit' && !hotelRecords.isEmpty()) {
            for (arce__hotel_projection__c hotel: hotelRecords) {
                hotel.arce__magnitude_unit_type__c = value;
            }
            wrapperResp = Arc_Gen_Hotel_Projection_Locator.updateHotelProj(hotelRecords);
        }
        return wrapperResp;
    }
}