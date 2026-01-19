/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Ratios_Calc_Core_Service
* @Author   saimassimilianno.jordana.contractor@bbva.com
* @Date     Created: 21/07/2023 
* @Group    ARCE
* @Description Class copied from SP2_CORE to calculate the ratio in projection process
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_Ratios_Calc_Core_Service
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods,PMD.ExcessiveParameterList,PMD.ExcessiveglobalCount')
global with sharing class Arc_Gen_Ratios_Calc_Core_Service {
    /**
    * @Description: name of ratings service
    */
    final static String SERVICENAME = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Is_Corporate')[0].arce__Value1__c == 'true' ? 'currencyService': 'currencyServiceCore';
    /**
    * @Description: Good response code from service.
    */
    final static String TWOHUNDRED = '200';
    /**
    * @Description: No data error code.
    */
    final static String TWOHFOUR = '204';
    /**
    * @Description: Double value for billion division.
    */
    final static Double BILLION = Double.valueOf('1000000000000');
    /**
    * @Description: Double value for million division.
    */
    final static Double MILLION = Double.valueOf('1000000');
    /**
    * @Description: Double value for million division.
    */
    final static Double THOUSAND = Double.valueOf('1000');
    /**
    *-------------------------------------------------------------------------------
    * @Description constructor
    *--------------------------------------------------------------------------------
    * @ Author saimassimilianno.jordana.contractor@bbva.com
    * @ Date   Created: 03-02-2022
    *--------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Ratios_Calc_Core_Service() {}

    /**
    * @Description: class to manage Exceptions.
    */
    global class CalculatorException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description class used to provide currenciesEngine method the needed arguments
    * to call the ratios engine
    *--------------------------------------------------------------------------------
    * @author   ARCE TEAM
    * @date     03/02/2022
    **/
    global class CurrencySrvcParameters {
        /*
        * @Description Federation Id.
        */
        global String baseCurrencyId { get; set; } //NOSONAR
        /*
        * @Description Customer Id.
        */
        global String targetCurrenciesId { get; set; } //NOSONAR
        /*
        * @Description Customer number.
        */
        global String exchangeRateOrigin { get; set; } //NOSONAR
        /*
        * @Description Id of the analysis in the service.
        */
        global String exchangeRateDate { get; set; } //NOSONAR

        /*
        * @Description CurrencySrvcParameters constructor.
        */
        global CurrencySrvcParameters(String baseCurrId, String trgtCurrsId, String exchgRateOrg, String exchgRateDat) {
            this.baseCurrencyId = baseCurrId;
            this.targetCurrenciesId = trgtCurrsId;
            this.exchangeRateOrigin = exchgRateOrg;
            this.exchangeRateDate = exchgRateDat;//'2016-12-01';
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method targtCurrncy
    *--------------------------------------------------------------------------------
    * @ Author saimassimilianno.jordana.contractor@bbva.com
    * @ Date   Created: 03-02-2022
    *--------------------------------------------------------------------------------
    **/
    global static Map<String,Map<String,Double>> targtCurrncy(CurrencySrvcParameters inputData) {
        final CurrencyResponse response = callCurrnciesServ(inputData);
        System.debug('response del servicio: ' + response);
        final List<TrgtCurrncs> trgetCurr = response.data[0].targetCurrencies;
        final Map<String,Map<String,Double>> mapCurrency = new Map<String,Map<String,Double>>();
        for(TrgtCurrncs currentTrg : trgetCurr) {
            final Map<String,Double> auxMap = new Map<String,Double>();
            for(RatiosData ratios : currentTrg.ratios) {
                auxMap.put(ratios.id, ratios.value);
            }
            mapCurrency.put(currentTrg.id, auxMap);
        }
        return mapCurrency;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method callCurrnciesServ
    *--------------------------------------------------------------------------------
    * @ Author saimassimilianno.jordana.contractor@bbva.com
    * @ Date   Created: 03-02-2022
    *--------------------------------------------------------------------------------
    **/
    global static CurrencyResponse callCurrnciesServ(CurrencySrvcParameters inputData) {
        arce.Arc_Gen_getIASOResponse.ServiceResponse servAndResp = new arce.Arc_Gen_getIASOResponse.ServiceResponse();
        final String jsonInput = JSON.serialize(inputData);
        servAndResp = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICENAME, jsonInput);
        if(servAndResp.serviceCode != TWOHUNDRED) {
            System.debug(':::::' + SERVICENAME + ' Error - CODE: ' + servAndResp.serviceCode + ' Message: '+ servAndResp.serviceMessage);
            throw new CalculatorException(servAndResp.serviceCode == TWOHFOUR ? 'There is no data for this exchange rate' : 'There is an error trying to retrieve exchange currency data');
        }
        final String jsonOutput = JSON.serialize(servAndResp.serviceResponse);
        final CurrencyResponse respOutput = (CurrencyResponse) JSON.deserialize(jsonOutput,CurrencyResponse.class);
        respOutput.serviceCode = servAndResp.serviceCode;
        respOutput.serviceMessage = servAndResp.serviceMessage;
        return respOutput;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Class for CurrencyResponse
    *--------------------------------------------------------------------------------
    * @ Author ARCE TEAM
    * @ Date   Created: 03/02/2022
    *--------------------------------------------------------------------------------
    **/
    global class CurrencyResponse {
        /**
        * @Description: data of WrapperRatingSP2
        */
        global List<CurrencyData> data {get;set;}
        /**
        * @Description: id of FFSS
        */
        global String serviceCode {get;set;}
        /**
        * @Description: id of FFSS
        */
        global String serviceMessage {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Class for CurrencyData
    *--------------------------------------------------------------------------------
    * @ Author ARCE TEAM
    * @ Date   Created: 03/02/2022
    *--------------------------------------------------------------------------------
    **/
    global class CurrencyData {
        /**
        * @Description: Object that contains the information of the base currency.
        */
        global BseCurrncData baseCurrency {get;set;} //NOSONAR
        /**
        * @Description: List of exchange rates for a particular target currency.
        */
        global List<TrgtCurrncs> targetCurrencies {get;set;} //NOSONAR
        /**
        * @Description: Origin of the conversion (responsible for facilitating the change).
        */
        global String exchangeRateOrigin {get;set;} //NOSONAR
        /**
        * @Description: The date of the exchange rate.
        */
        global String exchangeRateDate {get;set;} //NOSONAR
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Class for BseCurrncData
    *--------------------------------------------------------------------------------
    * @ Author ARCE TEAM
    * @ Date   Created: 03/02/2022
    *--------------------------------------------------------------------------------
    **/
    global class BseCurrncData {
        /**
        * @Description: String based on ISO-4217 for specifying the base currency.
        */
        global String id {get;set;} //NOSONAR
        /**
        * @Description: Name of the currency for a certain country.
        */
        global String name {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Class for TrgtCurrncs
    *--------------------------------------------------------------------------------
    * @ Author ARCE TEAM
    * @ Date   Created: 03/02/2022
    *--------------------------------------------------------------------------------
    **/
    global class TrgtCurrncs {
        /**
        * @Description: String based on ISO-4217 for specifying the target currency.
        */
        global String id {get;set;} //NOSONAR
        /**
        * @Description: Name of the currency for a certain country.
        */
        global String name {get;set;}
        /**
        * @Description: Listing with the possible types of changes for a certain currency destination on a currency origin.
        */
        global List<RatiosData> ratios {get;set;}

    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Class for RatiosData
    *--------------------------------------------------------------------------------
    * @ Author ARCE TEAM
    * @ Date   Created: 03/02/2022
    *--------------------------------------------------------------------------------
    **/
    global class RatiosData {
        /**
        * @Description: Exchange type for the value for this exchange rate.
        */
        global String id {get;set;} //NOSONAR
        /**
        * @Description: Description of the type of change.
        */
        global String description {get;set;}
        /**
        * @Description: Value of the exchange for purchase or sale.
        */
        global Double value {get;set;}
    }
}