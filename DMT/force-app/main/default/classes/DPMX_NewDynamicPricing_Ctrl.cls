/**
* ____________________________________________________________________________
* Controller class for DPMX_NewDynamicPricing.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-11
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class DPMX_NewDynamicPricing_Ctrl {
	/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_NewDynamicPricing_Ctrl() {

    }
    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param recordId : Client Id
    * @return retMap with user, client, product and company names info
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        String customerId;
        Map<String, Object> retMap = new Map<String, Object>();
        Boolean ClientExist = false;
        Boolean isCustom = false;
        // Get current user info
        User user = [SELECT Id, Name FROM User WHERE Id =: userInfo.getUserId()];
        retMap.put('user', user);
        // Get client info
        Account client = [SELECT Id, Name FROM Account WHERE Id =: recordId];

        retMap.put('client', client);
        retMap.put('clientLabel', Schema.DPMX_Dynamic_Pricing__c.fields.Client__c.getDescribe().getLabel());
        // Get Product info
        retMap.put('product', 'Acquirer');
        retMap.put('productLabel', Schema.DPMX_Dynamic_Pricing__c.fields.Product__c.getDescribe().getLabel());
        // Get Company Name info
        try{
            Local_Client__c localClient = [SELECT Id, unique_id__c FROM Local_Client__c WHERE Cib_Client__c =:recordId LIMIT 1];
            System.debug('localClient.unique_id__c: '+localClient.unique_id__c);
            customerId = localClient.unique_id__c;
            ClientExist = true;
        } catch(Exception ex){
            System.debug('Cliente no encontrado');
            retMap.put('error', 'Cliente no encontrado');
        }
        if(ClientExist){
            retMap = callAcquirerCategoriesService(retMap, customerId);
            isCustom = !(Boolean)retMap.get('success');
            retMap.put('companyNameLabel', Schema.DPMX_Dynamic_Pricing__c.fields.Company_Name__c.getDescribe().getLabel());
        }else{
            /*retMap.put('razonSocialLst', setListFamilies());
            retMap.put('razonSocialMp', setListFamiliesId());
            isCustom = true;*/
        }
        retMap.put('isCustom', isCustom);
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
        System.debug(dynamicPricingJSON);
        System.debug(familia);
        System.debug(familiaId);
        System.debug(isCustom);
        
        if(!isCustom){
            Local_Client__c localClient = [SELECT Id, unique_id__c FROM Local_Client__c WHERE Cib_Client__c =:dynamicPricing.Client__c LIMIT 1];
            String customerId = localClient.unique_id__c;
            dynamicPricing.NumeroCliente__c = customerId;
        }
        
            dynamicPricing.familia__c = familia;
            dynamicPricing.familia_AcquiererCategories_Id__c = familiaId;
            dynamicPricing.isCustom__c = isCustom;
            
            insert dynamicPricing;
            retMap.put('dynamicPricingId', dynamicPricing.Id);
            retMap.put('success', true);
            return retMap;

    }

    public static Map<String,Object> callAcquirerCategoriesService (Map<String,Object> retMap, String customerId) {
        Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('customerId', customerId);

        HttpResponse response = DPMX_Utils.callWebService('DPMX_AcquirerCategories', jsonInputMap);
        System.debug(response);
        switch on response.getStatusCode() {
            when 200 {
                final List<DPMX_AcquirerCategories_Wrapper> acquirerCategoriesWrapperLst;
                final Map<String, Object> responseMap;
                if(Test.isRunningTest()){
                    String responseReplace = '{"data":[{"id":"21","description":"Refacciones_y_ferreteria","businessInformation":{"companyName":"ECOSISTEMAS Y RECUBR IMIENTOS DE MEXICO S A DE CV","groupName":"GRUPO IMPAC","rate":{"itemizeRates":[{"rateType":"rateTypetest","itemizeRateUnit":{"amount":11,"currency_y":11,"unitType":11,"value":11}}]}}}]}';
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                    System.debug(responseMap);
                	acquirerCategoriesWrapperLst = (List<DPMX_AcquirerCategories_Wrapper>) Json.deserialize(JSON.serialize(responseMap.get('data')), List<DPMX_AcquirerCategories_Wrapper>.class);
					System.debug(acquirerCategoriesWrapperLst);
                    retMap.put('acquirerCategoriesWrapperLst', acquirerCategoriesWrapperLst);
                    System.debug(retMap.get('acquirerCategoriesWrapperLst'));
                } else {
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                	acquirerCategoriesWrapperLst = (List<DPMX_AcquirerCategories_Wrapper>) Json.deserialize(JSON.serialize(responseMap.get('data')), List<DPMX_AcquirerCategories_Wrapper>.class);
                }
                List<String> razonSocialLst = new List<String>();
                Map<String, String> razonSocialMp = new Map<String, String>();
                if(acquirerCategoriesWrapperLst.size() == 1){
                    retMap.put('moreThanOne', false);
                }else {
                    retMap.put('moreThanOne', true);
                }
                for(DPMX_AcquirerCategories_Wrapper acquirerCategoriesWrapper : acquirerCategoriesWrapperLst){
                    razonSocialLst.add(acquirerCategoriesWrapper.description);
                    System.debug(acquirerCategoriesWrapper.description);
                    System.debug(acquirerCategoriesWrapper.id);
                    razonSocialMp.put(acquirerCategoriesWrapper.description, acquirerCategoriesWrapper.id);
                }
                retMap.put('razonSocialLst', razonSocialLst);
                retMap.put('razonSocialMp', razonSocialMp);
                System.debug('200');
                retMap.put('success', true);
            }
            when else {
                System.debug('400');
                retMap.put('success', false);
                //retMap.put('razonSocialLst', setListFamilies());
                //retMap.put('razonSocialMp', setListFamiliesId());
                retMap.put('isCustom', true);
            }
        }
        return retMap;
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