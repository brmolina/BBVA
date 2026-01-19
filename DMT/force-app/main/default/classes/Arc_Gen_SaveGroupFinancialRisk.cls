/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveGroupFinancialRisk
* @Author   José Luis García <joseluis.garcia4.contractor@bbva.com>
* @Date     Created: 28/09/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that validates that the user saving a dynamic form tab on the ARCE analysis
* has edit access to the analysis.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-09-28 José Luis García <joseluis.garcia4.contractor@bbva.com>
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveGroupFinancialRisk implements dyfr.Save_Interface { //NOSONAR
    /**
    * @description: Value of the arce__smes_eur_comuty_defn_type__c field when the SME indicator is true.
    */
    private final static String SME_INDICATOR_YES = '1';
    /**
    * @description: Value of the arce__smes_eur_comuty_defn_type__c field when the SME indicator is false.
    */
    private final static String SME_INDICATOR_NO = '2';

    /**
    * @description: Lower bound of the employee count at which the customer can no longer be considered SME.
    */
    private final static Decimal SME_EMPLOYEE_LIMIT = 250;
    /**
    * @description: Lower bound of sales at which the customer can no longer be considered SME.
    */
    private final static Decimal SME_SALES_LIMIT = 50.0;
    /**
    * @description: Lower bound of balance at which the customer can no longer be considered SME.
    */
    private final static Decimal SME_BALANCE_LIMIT = 43.0;

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method executed when saving Financial Risk tab in a group. Checks for edit permissions
    * as well as it updates SME mark depending on input.
    * -----------------------------------------------------------------------------------------------
    * @Author   José Luis García  <joseluis.garcia4.contractor@bbva.com>
    * @Date     Created: 28/09/2020
    * @param listObject - List of the account has analisys object
    * @return String with the execution message
    * -----------------------------------------------------------------------------------------------
    **/
    public String save(List<sObject> listObject) {
      String retValue;
      boolean hasPermisson;

      Map<String, Object> financialRiskMap;
      final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
      final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];

      hasPermisson = Arc_Gen_TabSet_service.getPermissionToEdit(ahaData.Id) == 'true';

      if (hasPermisson) {

        financialRiskMap = Arc_Gen_FinRisk_Pers_Helper.financialInfoJSON(ahaData, accHasAnalysis);
        final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String>{accHasAnalysis.arce__Customer__c});
        final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(listacc.get(accHasAnalysis.arce__Customer__c).accNumber);
        final boolean financialInfo = Arc_Gen_OraclePers_service.financialRiskWS(participantId, accHasAnalysis.Name, financialRiskMap);
        retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(financialInfo,'',listObject));

        // Update SME mark.
        final Decimal empNumber = ahaData.arce__employees_number__c;
        final Decimal totalBalance = ahaData.arce__total_asset_local_amount__c;
        final Decimal totalSales = ahaData.arce__total_revenues_local_amount__c;

        ahaData.arce__smes_eur_comuty_defn_type__c = getSmeIndicator(accHasAnalysis.arce__Customer__c, empNumber, totalBalance, totalSales);

        // Update child AHAs SME.
        final List<arce__Account_has_Analysis__c> childAhas = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String> { accHasAnalysis.arce__Analysis__c });
        final List<arce__Account_has_Analysis__c> ahasToUpdate = new List<arce__Account_has_Analysis__c>();
        for (arce__Account_has_Analysis__c childAha : childAhas) {
            if (childAha.Id != ahaData.Id) {
                childAha.arce__smes_eur_comuty_defn_type__c = ahaData.arce__smes_eur_comuty_defn_type__c;
                ahasToUpdate.add(childAha);
            }
        }
        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(ahasToUpdate);

        // If SME indicator changed, clear leveraged results.
        if (accHasAnalysis.arce__smes_eur_comuty_defn_type__c != ahaData.arce__smes_eur_comuty_defn_type__c) {
            Arc_Gen_TestLeverage_service.clearTestLeveragedResultsAnalysis(accHasAnalysis.arce__Analysis__c);
        }
      } else {
        retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(false, Label.Arc_Gen_Generic_NotAllowed, listObject));
      }

      return retValue;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Calculates SME indicator depending on input
    * -----------------------------------------------------------------------------------------------
    * @Author   José Luis García  <joseluis.garcia4.contractor@bbva.com>
    * @Date     Created: 28/09/2020
    * @param customerId - Id of the customer.
    * @param empNumber - Number of employees entered by the user.
    * @param totalBalance - Total balance entered by the user.
    * @param totalSales - Total sales entered by the user.
    * @return Value of calculated SME indicator.
    * -----------------------------------------------------------------------------------------------
    **/
    global virtual String getSmeIndicator(Id customerId, Decimal empNumber, Decimal totalBalance, Decimal totalSales) {
        String smeIndicator;

        if (empNumber == null || totalBalance == null || totalSales == null) {
            smeIndicator = null;    // NOSONAR
        } else if (empNumber >= SME_EMPLOYEE_LIMIT) {
            smeIndicator = SME_INDICATOR_NO;
        } else {
            // Get customer currency for conversion.
            final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { customerId }).get(customerId);
            final Double conversionRate = Arc_Gen_TestLeverage_service.getCurrencyRate(accWrapper.currencyType);

            if (totalSales * conversionRate <= SME_SALES_LIMIT || totalBalance * conversionRate <= SME_BALANCE_LIMIT) {
                smeIndicator = SME_INDICATOR_YES;
            } else {
                smeIndicator = SME_INDICATOR_NO;
            }
        }

        return smeIndicator;
    }
}