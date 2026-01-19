/******************************************************************************************************************************************************************
Name:            DES_CurrencyExchangeRate_Handler
Description:     Class with CurrencyExchangeRate Trigger Handler methods custom methods for GLOBAL_DESKTOP
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
0.1            26/06/2018      Accenture         Class creation
0.2            29/06/2018      Accenture         Esta clase no se necesita y se comenta entera
*******************************************************************************************************************************************************************/
public with sharing class DES_CurrencyExchangeRate_Handler {
	private Integer timesExecuted = 0;
  	//private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();  
  	//private CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();

	public DES_CurrencyExchangeRate_Handler() {		
	}

/*
 * Copia los registros que se cargan via Dataloader en el objeto custom, tambien en el objeto standard CurrencyType de Salesforce para la Multidivisa  

  public void copyToStandardCurrencyType (List<SER_EUR_Currency_exchange_rate__c> newCurrencyExchangeRateList){
		    
		list<CurrencyType> currencyTypeList = new list<CurrencyType>();
        system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Inserting records to a DenormalizeVisits custom object...');        
        for (SER_EUR_Currency_exchange_rate__c cer : newCurrencyExchangeRateList){
        	CurrencyType newCurrencyType = new CurrencyType(ConversionRate=cer.SER_Exchange_rate__c,IsoCode=cer.SER_Counter_currency__c,DecimalPlaces=2,IsActive=true);
            currencyTypeList.add(newCurrencyType);
        }

        if (!currencyTypeList.isEmpty()){
        	//insert currencyTypeList;
        }          
    	timesExecuted ++;
  }//FIN Method
 */
}