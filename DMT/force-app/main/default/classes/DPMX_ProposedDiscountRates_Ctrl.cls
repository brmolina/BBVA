/**
* ____________________________________________________________________________
* Controller class for DPMX_ProposedDiscountRates.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-22
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_ProposedDiscountRates_Ctrl {
	/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_ProposedDiscountRates_Ctrl() {

    }
    /**
    * @description ??????????????????????
    * @param recordId : Client Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> updateFields (DPMX_AcquirerActivity_Wrapper acquirerActivityWrapper, Discount_Rates_Wrapper interchangeRates, Boolean checkbox, Decimal credit, Decimal debit, Decimal international) {
        Map<String, Object> retMap = new Map<String, Object>();
        // Ingresos cliente = Ingreso bruto () + Comisión baja facturación (acquirerActivityWrapper.fees.billing.amount) + Comisión red celular (acquirerActivityWrapper.fees.cellnet.amount) + Renta TPVs (acquirerActivityWrapper.fees.cellnet.amount)
        // Gastos cliente = Gastos totales (acquirerActivityWrapper.expenses.totalAmount.amount) + Gastos MIT y eBIND (acquirerActivityWrapper.expenses.mit.amount) + Gastos Intercambio ()
        Decimal grossIncome = (acquirerActivityWrapper.billing.credit.own.amount + acquirerActivityWrapper.billing.credit.thirdParty.amount) * (credit/100) + acquirerActivityWrapper.billing.international.amount * (international/100);
        Decimal exchangeFees = 0;
        System.debug('CAO - acquirerActivityWrapper.isGS: ' + acquirerActivityWrapper.isGS);
        System.debug('CAO - grossIncome INI: ' + grossIncome);
        System.debug('CAO - exchangeFees INI: ' + exchangeFees);
        if (acquirerActivityWrapper.isGS) {
            grossIncome = grossIncome + (acquirerActivityWrapper.transaction_y.debit.own + acquirerActivityWrapper.transaction_y.debit.thirdParty) * debit;
            exchangeFees = (acquirerActivityWrapper.transaction_y.debit.own + acquirerActivityWrapper.transaction_y.debit.thirdParty) * interchangeRates.debit + (acquirerActivityWrapper.billing.credit.own.amount + acquirerActivityWrapper.billing.credit.thirdParty.amount) * (interchangeRates.credit/100) + acquirerActivityWrapper.billing.international.amount * (interchangeRates.international/100);
            System.debug('CAO - grossIncome 1: ' + grossIncome);
            System.debug('CAO - exchangeFees 1: ' + exchangeFees);
        }else {
            if ((acquirerActivityWrapper.transaction_y.debit.own > 0) && ((acquirerActivityWrapper.billing.debit.own.amount * (debit/100)) / acquirerActivityWrapper.transaction_y.debit.own > acquirerActivityWrapper.discount.amount.amount)) {
                grossIncome = grossIncome + acquirerActivityWrapper.transaction_y.debit.own * acquirerActivityWrapper.discount.amount.amount;
                System.debug('CAO - grossIncome 2: ' + grossIncome);
            }else {
                grossIncome = grossIncome + acquirerActivityWrapper.billing.debit.own.amount * (debit/100);
                System.debug('CAO - grossIncome 3.1: ' + acquirerActivityWrapper.billing.debit.own.amount + ' - ' + debit/100 + ' - ' + acquirerActivityWrapper.billing.debit.own.amount * (debit/100));
                System.debug('CAO - grossIncome 3: ' + grossIncome);
            }
            if ((acquirerActivityWrapper.transaction_y.debit.thirdParty > 0) && ((acquirerActivityWrapper.billing.debit.thirdParty.amount * (debit/100)) / acquirerActivityWrapper.transaction_y.debit.thirdParty > acquirerActivityWrapper.discount.amount.amount)) {
                grossIncome = grossIncome + acquirerActivityWrapper.transaction_y.debit.thirdParty * acquirerActivityWrapper.discount.amount.amount;
                System.debug('CAO - grossIncome 4.1: ' + acquirerActivityWrapper.transaction_y.debit.thirdParty + ' - ' + acquirerActivityWrapper.discount.amount.amount + ' - ' + acquirerActivityWrapper.transaction_y.debit.thirdParty * acquirerActivityWrapper.discount.amount.amount);
                System.debug('CAO - grossIncome 4: ' + grossIncome);
            }else {
                grossIncome = grossIncome + acquirerActivityWrapper.billing.debit.thirdParty.amount * (debit/100);
                System.debug('CAO - grossIncome 5: ' + grossIncome);
            }
            final Decimal exchangeCap = 13.5;
           
            if ((acquirerActivityWrapper.transaction_y.debit.own > 0) && ((acquirerActivityWrapper.billing.debit.own.amount * (interchangeRates.debit/100)) / acquirerActivityWrapper.transaction_y.debit.own > exchangeCap)) {
                exchangeFees = exchangeFees + acquirerActivityWrapper.transaction_y.debit.own * exchangeCap;
                System.debug('CAO - exchangeFees 2: ' + exchangeFees);
            }else {
                exchangeFees = exchangeFees + acquirerActivityWrapper.billing.debit.own.amount * (interchangeRates.debit/100);
                System.debug('CAO - exchangeFees 3: ' + exchangeFees);
            }
            if ((acquirerActivityWrapper.transaction_y.debit.thirdParty > 0) && ((acquirerActivityWrapper.billing.debit.thirdParty.amount * (interchangeRates.debit/100))/acquirerActivityWrapper.transaction_y.debit.thirdParty > exchangeCap)) {
                exchangeFees = exchangeFees + acquirerActivityWrapper.transaction_y.debit.thirdParty * exchangeCap;
                System.debug('CAO - exchangeFees 4.1: ' + acquirerActivityWrapper.billing.debit.thirdParty.amount + ' - ' + (interchangeRates.debit/100) + ' - ' + acquirerActivityWrapper.transaction_y.debit.thirdParty);
                System.debug('CAO - exchangeFees 4.1: ' + acquirerActivityWrapper.transaction_y.debit.thirdParty * exchangeCap);
                System.debug('CAO - exchangeFees 4: ' + exchangeFees);
            }else {
                exchangeFees = exchangeFees + acquirerActivityWrapper.billing.debit.thirdParty.amount * (interchangeRates.debit/100);
                System.debug('CAO - exchangeFees 5: ' + exchangeFees);
            }
            exchangeFees = exchangeFees + ((acquirerActivityWrapper.billing.credit.own.amount + acquirerActivityWrapper.billing.credit.thirdParty.amount) * (interchangeRates.credit))/100 + (acquirerActivityWrapper.billing.international.amount * interchangeRates.international)/100;
            //exchangeFees = exchangeFees + (acquirerActivityWrapper.billing.credit.own.amount + acquirerActivityWrapper.billing.credit.thirdParty.amount) * (credit/100) + acquirerActivityWrapper.billing.international.amount * (international/100);
            System.debug('CAO - exchangeFees 6.1: ' + acquirerActivityWrapper.billing.credit.own.amount + ' - ' + interchangeRates.credit/100 + (acquirerActivityWrapper.billing.credit.own.amount) * (interchangeRates.credit/100));
            System.debug('CAO - exchangeFees 6.2: ' + acquirerActivityWrapper.billing.credit.thirdParty.amount + ' - ' + interchangeRates.credit/100 + (acquirerActivityWrapper.billing.credit.thirdParty.amount) * (interchangeRates.credit/100));
            System.debug('CAO - exchangeFees 6.3: ' + acquirerActivityWrapper.billing.international.amount + ' - ' + (interchangeRates.international/100) + acquirerActivityWrapper.billing.international.amount * (interchangeRates.international/100));
            System.debug('CAO - exchangeFees 6: ' + exchangeFees);
        }
        Decimal customerIncome = grossIncome + acquirerActivityWrapper.fees.billing.amount + acquirerActivityWrapper.fees.cellnet.amount + acquirerActivityWrapper.fees.cellnet.amount;
        Decimal customerExpenses = exchangeFees + acquirerActivityWrapper.expenses.totalAmount.amount + acquirerActivityWrapper.expenses.mit.amount;
        System.debug('CAO - acquirerActivityWrapper.expenses.totalAmount.amount: ' + acquirerActivityWrapper.expenses.totalAmount.amount);
        System.debug('CAO - acquirerActivityWrapper.expenses.mit.amount: ' + acquirerActivityWrapper.expenses.mit.amount);
        System.debug('CAO - customerIncome: ' + customerIncome);
        System.debug('CAO - customerExpenses: ' + customerExpenses);
        Decimal profitability = (customerIncome/customerExpenses) - 1;
        retMap.put('profitability', profitability);
        Decimal profitAmount = customerIncome - customerExpenses;
        retMap.put('profitAmount', profitAmount);
        retMap.put('success', true);
        return retMap;
    }
    public class Discount_Rates_Wrapper {
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal international {get; set;}
    }
}