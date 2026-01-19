/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_CurrencyExchange_Service
* @Author   joseluis.garcia4.contractor@bbva.com
* @Date     Created: 30/07/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Global implementation of Arc_Gen_CurrencyExchange_Interface. Gets currency exchange
* information from the historicalExchangeRates service.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-30 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
public class Arc_GBL_CurrencyExchange_Service implements Arc_Gen_CurrencyExchange_Interface {
    /**
    * @Description: Name of the service
    */
    public final static String SERVICE_NAME = 'historicalExchangeRates';
    /**
    * @Description: Id used to filter the exchange rate.
    */
    public final static String RATIOS_FILTER = 'MONTH_END_EXCHANGE_RATE';

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get the implementation for the interface that queries
    * currency exchange information.
    *--------------------------------------------------------------------------------
    * @date		30/07/2020
    * @author	joseluis.garcia4.contractor@bbva.com
    * @param params Params to provide to the service
    * @return   Currency exchange information returned by the service
    */
    public Arc_Gen_CurrencyExchange_Wrapper getCurrencyExchangeInfo(Arc_Gen_CurrencyExchange_Params params) {
        Arc_Gen_CurrencyExchange_Wrapper respWrapper;

        if (params.targetCurrencies.size() == 1 && params.targetCurrencies.contains(params.baseCurrency)) {
            // If base currency is the same as target currency, omit service call.
            respWrapper = new Arc_Gen_CurrencyExchange_Wrapper();
            respWrapper.baseCurrency = params.baseCurrency;
            respWrapper.exchangeRateDate = System.today();
            respWrapper.setCurrencyExchangeRate(params.baseCurrency, 1);
        } else {
            // Build parameters to service.
            final Map<String, String> parameters = new Map<String, String>();
            parameters.put('baseCurrency', params.baseCurrency);
            parameters.put('targetCurrencies', String.join(params.targetCurrencies, ','));
            parameters.put('exchangeRateOrigin', params.exchangeRateOrigin);
            parameters.put('exchangeRateDate', String.valueOf(params.exchangeRateDate == null ? System.today() : params.exchangeRateDate));

            final arce.Arc_Gen_getIASOResponse.ServiceResponse response =
                arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, JSON.serialize(parameters));

            // Build result.
            respWrapper = getWrapperFromServiceResponse(response.serviceResponse);
        }

        return respWrapper;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Utility method that returns a wrapper object from the results of
    * the service.
    *--------------------------------------------------------------------------------
    * @date		30/07/2020
    * @author	joseluis.garcia4.contractor@bbva.com
    * @param serviceResponse Response from the service
    * @return   Currency exchange information
    */
    private Arc_Gen_CurrencyExchange_Wrapper getWrapperFromServiceResponse(Map<String, Object> serviceResponse) {
        final Arc_Gen_CurrencyExchange_Wrapper wrapper = new Arc_Gen_CurrencyExchange_Wrapper();

        // Get base currency.
        final Map<String, Object> dataObj = (Map<String, Object>) ((List<Object>) serviceResponse.get('data'))[0];
        final Map<String, Object> baseCurrencyObj = (Map<String, Object>) dataObj.get('baseCurrency');
        wrapper.baseCurrency = (String) baseCurrencyObj.get('id');

        // Get exchange rate date.
        wrapper.exchangeRateDate = Date.valueOf((String) dataObj.get('exchangeRateDate'));

        // Get target currencies.
        final List<Object> targetCurrencyList = (List<Object>) dataObj.get('targetCurrencies');
        for (Object targetCurrencyObj : targetCurrencyList) {
            final Map<String, Object> targetCurrencyCasted = (Map<String, Object>) targetCurrencyObj;
            final String targetCurrency = (String) targetCurrencyCasted.get('id');

            final List<Object> ratiosList = (List<Object>) targetCurrencyCasted.get('ratios');
            for (Object ratiosObj : ratiosList) {
                final Map<String, Object> ratiosCasted = (Map<String, Object>) ratiosObj;
                final String ratiosId = (String) ratiosCasted.get('id');
                if (ratiosId == RATIOS_FILTER) {
                    wrapper.setCurrencyExchangeRate(targetCurrency, (Double) ratiosCasted.get('value'));
                }
            }
        }

        return wrapper;
    }
}