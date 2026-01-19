/**-------------------------------------------------------------------------------------------
* @Name     HPG ExchangeRates - DEPRECATED
* @Author
* @Date     Created: 2023-09-25
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class HPG_ExchangeRates {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getExchangeRates(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = HPG_Utils.callService('currencyService', request);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                ExchangeCurrency exchangeCurrency = new ExchangeCurrency();
                final List<TrgtCurrncs> trgetCurr = res.data[0].targetCurrencies;
                exchangeCurrency.currencyId = trgetCurr[0].id;
                exchangeCurrency.currencyName = trgetCurr[0].name;
                exchangeCurrency.ratioId = trgetCurr[0].ratios[0].id;
                exchangeCurrency.ratioDescription = trgetCurr[0].ratios[0].description;
                exchangeCurrency.ratioValue = trgetCurr[0].ratios[0].value;
                res.exchangeCurrency = exchangeCurrency;
                res.success = true;
            }
            when else {
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        return res;
    }

    /**
    * @Description: Class Wrapper
    */
    public class Wrapper {

        /* @Description: data */
        @AuraEnabled
        public List<CurrencyData> data {get;set;}

        /* @Description: exchangeCurrency */
        @AuraEnabled
        public ExchangeCurrency exchangeCurrency {get;set;}

        /* @Description: success */
        @AuraEnabled
        public boolean success {get;set;}

        /* @Description: errorMessage */
        @AuraEnabled
        public String errorMessage {get;set;}
    }

    /**
    * @Description: Class for CurrencyData
    */
    public class CurrencyData {

        /**
        * @Description: Object that contains the information of the base currency.
        */
        public BaseCurrencyData baseCurrency {get;set;}

        /**
        * @Description: List of exchange rates for a particular target currency.
        */
        public List<TrgtCurrncs> targetCurrencies {get;set;}

        /**
        * @Description: Origin of the conversion (responsible for facilitating the change).
        */
        public String exchangeRateOrigin {get;set;}

        /**
        * @Description: The date of the exchange rate.
        */
        public String exchangeRateDate {get;set;}
    }

    /**
    * @Description: Class for BaseCurrencyData
    */
    public class BaseCurrencyData {

        /**
        * @Description: String based on ISO-4217 for specifying the base currency.
        */
        public String id {get;set;}

        /**
        * @Description: Name of the currency for a certain country.
        */
        public String name {get;set;}
    }
    /**
    * @Description: Class for TrgtCurrncs
    */
    public class TrgtCurrncs {
        /**
        * @Description: String based on ISO-4217 for specifying the target currency.
        */
        public String id {get;set;}

        /**
        * @Description: Name of the currency for a certain country.
        */
        public String name {get;set;}

        /**
        * @Description: Listing with the possible types of changes for a certain currency destination on a currency origin.
        */
        public List<RatiosData> ratios {get;set;}
    }

    /**
    * @Description: Class for RatiosData
    */
    public class RatiosData {

        /**
        * @Description: Exchange type for the value for this exchange rate.
        */
        public String id {get;set;}

        /**
        * @Description: Description of the type of change.
        */
        public String description {get;set;}

        /**
        * @Description: Value of the exchange for purchase or sale.
        */
        public Double value {get;set;}
    }

    /**
    * @Description: Class for RatiosData
    */
    public class ExchangeCurrency {

        /**
        * @Description: String based on ISO-4217 for specifying the target currency.
        */
        public String currencyId {get;set;}

        /**
        * @Description: Name of the currency for a certain country.
        */
        public String currencyName {get;set;}

        /**
        * @Description: Exchange type for the value for this exchange rate.
        */
        public String ratioId {get;set;}

        /**
        * @Description: Description of the type of change.
        */
        public String ratioDescription {get;set;}

        /**
        * @Description: Value of the exchange for purchase or sale.
        */
        public Double ratioValue {get;set;}
    }
}