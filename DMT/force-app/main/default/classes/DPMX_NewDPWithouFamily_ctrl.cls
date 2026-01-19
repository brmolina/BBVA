/**
* ____________________________________________________________________________
* Controller class for DPMX_NewDPWithouFamily.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero Garcia
* @modifiedBy
* @version     1.0
* @created     2023-12-21
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class DPMX_NewDPWithouFamily_ctrl {
	/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_NewDPWithouFamily_ctrl() {

    }
    /**
    * @description retrieve Profitability Sheets related to the participant
    * @return retMap with user, client, product and company names info
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData () {
        Map<String, Object> retMap = new Map<String, Object>();

        // Get Product info
        retMap.put('product', 'Acquirer');
        retMap.put('productLabel', Schema.DPMX_Dynamic_Pricing__c.fields.Product__c.getDescribe().getLabel());
        retMap.put('razonSocialLst', setListFamilies());
        retMap.put('razonSocialMp', setListFamiliesId());
        retMap.put('isCustom', true);
        return retMap;
    }
    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param dynamicPricingJSON : DPMX_Dynamic_Pricing__c data in JSON format
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> saveDynamicPricing (String dynamicPricingJSON, String familia, String familiaId, Boolean isCustom) {
        Map<String, Object> retMap = new Map<String, Object>();
        final DPMX_Dynamic_Pricing__c dynamicPricing = (DPMX_Dynamic_Pricing__c)JSON.deserialize(dynamicPricingJSON, DPMX_Dynamic_Pricing__c.class);
        try {
            dynamicPricing.familia__c = familia;
            dynamicPricing.familia_AcquiererCategories_Id__c = familiaId;
            dynamicPricing.isCustom__c = isCustom;
            insert dynamicPricing;
            retMap.put('dynamicPricingId', dynamicPricing.Id);
            retMap.put('success', true);
            return retMap;
        } catch (Exception e) { // NOSONAR
            throw new AuraHandledException(Label.cuco.generic_error + ' ' + e.getMessage()); // NOSONAR
        }
    }

    public static List<String> setListFamilies () {
        List<String> razonSocialLst = new List<String>();
        razonSocialLst.add('AGENCIA DE VIAJES');
        razonSocialLst.add('AGREGADORES');
        razonSocialLst.add('ASEGURADORAS');
        razonSocialLst.add('BENEFICENCIA');
        razonSocialLst.add('COLEGIOS Y UNIVERSIDADES');
        razonSocialLst.add('COMIDA RÁPIDA');
        razonSocialLst.add('EDUCACIÓN BÁSICA');
        razonSocialLst.add('ESTACIONAMIENTO');
        razonSocialLst.add('ENTRETENIMIENTO');
        razonSocialLst.add('FARMACIAS');
        razonSocialLst.add('GASOLINERAS');
        razonSocialLst.add('GOBIERNO');
        razonSocialLst.add('GRANDES SUPERFICIES');
        razonSocialLst.add('GUARDERÍAS');
        razonSocialLst.add('HOSPITALES');
        razonSocialLst.add('HOTELES');
        razonSocialLst.add('MÉDICOS Y DENTISTAS');
        razonSocialLst.add('MISCELANEAS');
        razonSocialLst.add('OTROS');
        razonSocialLst.add('PEAJE');
        razonSocialLst.add('REFACCIONES Y FERRETERÍA');
        razonSocialLst.add('RENTA DE AUTOS');
        razonSocialLst.add('RESTAURANTES');
        razonSocialLst.add('SALONES DE BELLEZA');
        razonSocialLst.add('SUPERMERCADOS');
        razonSocialLst.add('TELECOMUNICACIONES');
        razonSocialLst.add('TRANSPORTE AÉREO');
        razonSocialLst.add('TRANSPORTE TERRESTRE DE PASAJEROS');
        razonSocialLst.add('VENTAS AL MENUDEO');
        return razonSocialLst;
    }

    public static Map<String, String> setListFamiliesId () {
        Map<String, String> razonSocialMp = new Map<String, String>();
        razonSocialMp.put('AGENCIA DE VIAJES','1');
        razonSocialMp.put('AGREGADORES','2');
        razonSocialMp.put('ASEGURADORAS','3');
        razonSocialMp.put('BENEFICENCIA','4');
        razonSocialMp.put('COLEGIOS Y UNIVERSIDADES','5');
        razonSocialMp.put('COMIDA RÁPIDA','6');
        razonSocialMp.put('EDUCACIÓN BÁSICA','7');
        razonSocialMp.put('ESTACIONAMIENTO','8');
        razonSocialMp.put('ENTRETENIMIENTO','9');
        razonSocialMp.put('FARMACIAS','10');
        razonSocialMp.put('GASOLINERAS','11');
        razonSocialMp.put('GOBIERNO','12');
        razonSocialMp.put('GRANDES SUPERFICIES','13');
        razonSocialMp.put('GUARDERÍAS','14');
        razonSocialMp.put('HOSPITALES','15');
        razonSocialMp.put('HOTELES','16');
        razonSocialMp.put('MÉDICOS Y DENTISTAS','17');
        razonSocialMp.put('MISCELANEAS','18');
        razonSocialMp.put('OTROS','19');
        razonSocialMp.put('PEAJE','20');
        razonSocialMp.put('REFACCIONES Y FERRETERÍA','21');
        razonSocialMp.put('RENTA DE AUTOS','22');
        razonSocialMp.put('RESTAURANTES','23');
        razonSocialMp.put('SALONES DE BELLEZA','24');
        razonSocialMp.put('SUPERMERCADOS','25');
        razonSocialMp.put('TELECOMUNICACIONES','26');
        razonSocialMp.put('TRANSPORTE AÉREO','27');
        razonSocialMp.put('TRANSPORTE TERRESTRE DE PASAJEROS','28');
        razonSocialMp.put('VENTAS AL MENUDEO','29');
        return razonSocialMp;
    }

}