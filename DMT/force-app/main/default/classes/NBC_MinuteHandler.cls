/*
*Author: Vass
*handler de la minuta
*
*/
public with sharing class NBC_MinuteHandler {

    /*
    *Author: Vass
    *con patron sigleton
    *
    */
    private NBC_MinuteHandler() {
    }


  	/*
    *Author: Vass
    *busca las conversiones de currency
    *
    */
    public static Map<String, decimal> fillCurrencyType() {
      Map<String, decimal> mCurrType;
      mCurrType = new Map<String, decimal>();

      for(CurrencyType currType : [Select Id, ConversionRate, DecimalPlaces, IsActive, IsCorporate, IsoCode from CurrencyType limit 300]) {
          mCurrType.put(currType.IsoCode, currType.ConversionRate);
      }
      return mCurrType;
    }

  	/*
    *Author: Vass
    *divide la cadena y convierte
    *
    */
    public static String splitTo (String data, String curr, Map<String, decimal> mCurrType) {

      Decimal splitNumber;
      List <String> splitted;
      String assigned = '';
      assigned += '';
      if(assigned == '' && data != null && curr!=null && mCurrType.containsKey(curr)) {
        splitted = data.split('\n');
        for(String split : splitted) {
          split = split.replace(',','.');
          splitNumber = Decimal.valueOf(split)/mCurrType.get(curr);
          splitNumber = splitNumber.setScale(2);
          assigned += splitNumber;
          assigned += '\n';
        }
        assigned = assigned.removeEnd('\n');
        assigned = assigned.replace('.',',');
      }

      return assigned;
    }

  	/*
    *Author: Vass
    *divide la cadena y convierte
    *
    */
    public static Decimal convertDataCurrency (Decimal num, string curr, Map<String, decimal> mCurrType) {

    	Decimal result = 0;

  		if(num!=null && curr!=null && mCurrType.containsKey(curr)) {
  			result = num/mCurrType.get(curr);
  			result = result.setScale(2);
  		}
      	return result;
    }

  	/*
    *Author: Vass
    *devuelve la currency global si es recordtype ECA
    *
    */
    public static String isECA (DES_Template__c templ) {
            String currencyECA;
            String stringECA;
            stringECA = 'ECA';
            String stringNULL;
            stringNULL = 'NULL';
            currencyECA = stringNULL;
            if(templ.RecordType.DeveloperName == stringECA ) {
              currencyECA = templ.CurrencyIsoCode;
            }

            return currencyECA;

    }

  	/*
    *Author: Vass
    *devuelve currency de la tranche
    *
    */
    public static String getTrancheCurrency (String currTranche, String currencyECA) {
            String stringNULL;
            stringNULL = 'NULL';
            String currencyResult;
            currencyResult = currencyECA;

            if(currencyECA==stringNULL) {
              currencyResult = currTranche;
            }

            return currencyResult;
    }
}