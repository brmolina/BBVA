/**
* ____________________________________________________________________________
* Controller class for DPMX_SimulatorClientInfo.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-09-04
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public  class DPMX_SimulatorClientInfo_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_SimulatorClientInfo_Ctrl() {

    }
    /**
    * @description ??????????????????????
    * @param acquirerActivitiesWrapper : DPMX_AcquirerActivity_Wrapper record obtained from Acquirer Activity Service
    * @param action : 'add' or 'edit'
    * @param dynamicPricing : DPMX_Dynamic_Pricing__c record info
    * @return retMap DPMX_Dynamic_Pricing__c record for Simulation
    */
    @AuraEnabled
    public static Map<String,Object> getData(DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, String action, DPMX_Dynamic_Pricing__c dynamicPricing) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricingUpsert = new DPMX_Dynamic_Pricing__c();
        dynamicPricingUpsert.Id = dynamicPricing.Id;
        if(!dynamicPricing.isCustom__c){
            dynamicPricingUpsert.Sim_Billing_TotalAmount_Currency__c = acquirerActivitiesWrapper.billing.totalAmount.currency_y;
            dynamicPricingUpsert.Sim_Tickets_TotalAmount_Currency__c = acquirerActivitiesWrapper.tickets.totalAmount.currency_y;
        }
        if (action != 'edit') {
            if(!dynamicPricing.isCustom__c){
                dynamicPricingUpsert.Sim_Transaction_Debit_Own__c = acquirerActivitiesWrapper.transaction_y.debit.total;
                dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c = acquirerActivitiesWrapper.billing.debit.total;
                dynamicPricingUpsert.Sim_Billing_Debit_Own_Currency__c = acquirerActivitiesWrapper.tickets.debit.own.currency_y;
                dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c = acquirerActivitiesWrapper.tickets.debit.total;
                dynamicPricingUpsert.Sim_Tickets_Debit_Own_Currency__c = acquirerActivitiesWrapper.tickets.debit.own.currency_y;

                //dynamicPricingUpsert.Sim_Transaction_Debit_ThirdParty__c = acquirerActivitiesWrapper.transaction_y.debit.thirdParty;
                //dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Amount__c = acquirerActivitiesWrapper.billing.debit.thirdParty.amount;
                //dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Currency__c = acquirerActivitiesWrapper.billing.debit.thirdParty.currency_y;
                //dynamicPricingUpsert.Sim_Tickets_Debit_ThirdParty_Amount__c = acquirerActivitiesWrapper.tickets.debit.thirdParty.amount;
                //dynamicPricingUpsert.Sim_Tickets_Debit_ThirdParty_Currency__c = acquirerActivitiesWrapper.tickets.debit.thirdParty.currency_y;

                dynamicPricingUpsert.Sim_Transaction_Credit_Own__c = acquirerActivitiesWrapper.transaction_y.credit.total;
                dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c = acquirerActivitiesWrapper.billing.credit.total;
                dynamicPricingUpsert.Sim_Billing_Credit_Own_Currency__c = acquirerActivitiesWrapper.tickets.credit.own.currency_y;
                dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c = acquirerActivitiesWrapper.tickets.credit.total;
                dynamicPricingUpsert.Sim_Tickets_Credit_Own_Currency__c = acquirerActivitiesWrapper.tickets.credit.thirdParty.currency_y;

                //dynamicPricingUpsert.Sim_Transaction_Credit_ThirdParty__c = acquirerActivitiesWrapper.transaction_y.credit.thirdParty;
                //dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Amount__c = acquirerActivitiesWrapper.billing.credit.thirdParty.amount;
                //dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Currency__c = acquirerActivitiesWrapper.billing.credit.thirdParty.currency_y;
                //dynamicPricingUpsert.Sim_Tickets_Credit_ThirdParty_Amount__c = acquirerActivitiesWrapper.tickets.credit.thirdParty.amount;
                //dynamicPricingUpsert.Sim_Tickets_Credit_ThirdParty_Currency__c = acquirerActivitiesWrapper.tickets.credit.thirdParty.currency_y;

                dynamicPricingUpsert.Sim_Transaction_International__c = acquirerActivitiesWrapper.transaction_y.international;
                dynamicPricingUpsert.Sim_Billing_International_Amount__c = acquirerActivitiesWrapper.billing.international.amount;
                dynamicPricingUpsert.Sim_Billing_International_Currency__c = acquirerActivitiesWrapper.billing.international.currency_y;
                dynamicPricingUpsert.Sim_Tickets_International_Amount__c = acquirerActivitiesWrapper.tickets.international.amount;
                dynamicPricingUpsert.Sim_Tickets_International_Currency__c = acquirerActivitiesWrapper.tickets.international.currency_y;
            }
        } else {
            dynamicPricingUpsert.Sim_Transaction_Debit_Own__c = dynamicPricing.Sim_Transaction_Debit_Own__c;
            dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c = dynamicPricing.Sim_Billing_Debit_Own_Amount__c;
            dynamicPricingUpsert.Sim_Billing_Debit_Own_Currency__c = dynamicPricing.Sim_Billing_Debit_Own_Currency__c;
            dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c = dynamicPricing.Sim_Tickets_Debit_Own_Amount__c;
            dynamicPricingUpsert.Sim_Tickets_Debit_Own_Currency__c = dynamicPricing.Sim_Tickets_Debit_Own_Currency__c;

            /*dynamicPricingUpsert.Sim_Transaction_Debit_ThirdParty__c = dynamicPricing.Sim_Transaction_Debit_ThirdParty__c;
            dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Amount__c = dynamicPricing.Sim_Billing_Debit_ThirdParty_Amount__c;
            dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Currency__c = dynamicPricing.Sim_Billing_Debit_ThirdParty_Currency__c;
            dynamicPricingUpsert.Sim_Tickets_Debit_ThirdParty_Amount__c = dynamicPricing.Sim_Tickets_Debit_ThirdParty_Amount__c;
            dynamicPricingUpsert.Sim_Tickets_Debit_ThirdParty_Currency__c = dynamicPricing.Sim_Tickets_Debit_ThirdParty_Currency__c;*/

            dynamicPricingUpsert.Sim_Transaction_Credit_Own__c = dynamicPricing.Sim_Transaction_Credit_Own__c;
            dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c = dynamicPricing.Sim_Billing_Credit_Own_Amount__c;
            dynamicPricingUpsert.Sim_Billing_Credit_Own_Currency__c = dynamicPricing.Sim_Billing_Credit_Own_Currency__c;
            dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c = dynamicPricing.Sim_Tickets_Credit_Own_Amount__c;
            dynamicPricingUpsert.Sim_Tickets_Credit_Own_Currency__c = dynamicPricing.Sim_Tickets_Credit_Own_Currency__c;

            /*dynamicPricingUpsert.Sim_Transaction_Credit_ThirdParty__c = dynamicPricing.Sim_Transaction_Credit_ThirdParty__c;
            dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Amount__c = dynamicPricing.Sim_Billing_Credit_ThirdParty_Amount__c;
            dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Currency__c = dynamicPricing.Sim_Billing_Credit_ThirdParty_Currency__c;
            dynamicPricingUpsert.Sim_Tickets_Credit_ThirdParty_Amount__c = dynamicPricing.Sim_Tickets_Credit_ThirdParty_Amount__c;
            dynamicPricingUpsert.Sim_Tickets_Credit_ThirdParty_Currency__c = dynamicPricing.Sim_Tickets_Credit_ThirdParty_Currency__c;*/
            
            dynamicPricingUpsert.Sim_Transaction_International__c = dynamicPricing.Sim_Transaction_International__c;
            dynamicPricingUpsert.Sim_Billing_International_Amount__c = dynamicPricing.Sim_Billing_International_Amount__c;
            dynamicPricingUpsert.Sim_Billing_International_Currency__c = dynamicPricing.Sim_Billing_International_Currency__c;
            dynamicPricingUpsert.Sim_Tickets_International_Amount__c = dynamicPricing.Sim_Tickets_International_Amount__c;
            dynamicPricingUpsert.Sim_Tickets_International_Currency__c = dynamicPricing.Sim_Tickets_International_Currency__c;
        }
        dynamicPricingUpsert.isCustomCliEdt__c = dynamicPricing.isCustomCliEdt__c;
        dynamicPricingUpsert.isCustomDisEdt__c = dynamicPricing.isCustomDisEdt__c;
        dynamicPricingUpsert.isCustom__c = dynamicPricing.isCustom__c;
        retMap.put('dynamicPricingUpsert', dynamicPricingUpsert);
        retMap.put('isCustom', dynamicPricing.isCustom__c);
        return retMap;
    }
    /**
    * @description ??????????????????????
    * @param dynamicPricingUpsert : DPMX_Dynamic_Pricing__c record with Simulator info
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> saveData(DPMX_Dynamic_Pricing__c dynamicPricingUpsert, Integer flagBool) {
        Map<String, Object> retMap = new Map<String, Object>();
        System.debug('in');
        dynamicPricingUpsert.Client_Information__c = true;
        //auto calculo de Transaccion si existen los otros dos valores de debito, credito o internacional.
        if(dynamicPricingUpsert.Sim_Transaction_Debit_Own__c == null || dynamicPricingUpsert.Sim_Transaction_Debit_Own__c == 0){
            if(dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c != 0 && dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c != 0){
                dynamicPricingUpsert.Sim_Transaction_Debit_Own__c = (dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c / dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c).setscale(2);
            }
        }

        if(dynamicPricingUpsert.Sim_Transaction_Credit_Own__c == null || dynamicPricingUpsert.Sim_Transaction_Credit_Own__c == 0){
            if(dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c != 0 && dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c != 0){
                dynamicPricingUpsert.Sim_Transaction_Credit_Own__c = (dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c / dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c).setscale(2);
            }
        }

        if(dynamicPricingUpsert.Sim_Transaction_International__c == null || dynamicPricingUpsert.Sim_Transaction_International__c == 0){
            if(dynamicPricingUpsert.Sim_Billing_International_Amount__c != null && dynamicPricingUpsert.Sim_Billing_International_Amount__c != 0 && dynamicPricingUpsert.Sim_Tickets_International_Amount__c != null && dynamicPricingUpsert.Sim_Tickets_International_Amount__c != 0){
                dynamicPricingUpsert.Sim_Transaction_International__c = (dynamicPricingUpsert.Sim_Billing_International_Amount__c / dynamicPricingUpsert.Sim_Tickets_International_Amount__c).setscale(2);
            }
        }

        //auto calculo de Facturación mensual si existen los otros dos valores de debito, credito o internacional.
        if(dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c == null || dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c == 0){
            if(dynamicPricingUpsert.Sim_Transaction_Debit_Own__c != null && dynamicPricingUpsert.Sim_Transaction_Debit_Own__c != 0 && dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c != 0){
                dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c = (dynamicPricingUpsert.Sim_Transaction_Debit_Own__c * dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c).setscale(2);
            }
        }

        if(dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c == null || dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c == 0){
            if(dynamicPricingUpsert.Sim_Transaction_Credit_Own__c != null && dynamicPricingUpsert.Sim_Transaction_Credit_Own__c != 0 && dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c != 0){
                dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c = (dynamicPricingUpsert.Sim_Transaction_Credit_Own__c * dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c).setscale(2);
            }
        }

        if(dynamicPricingUpsert.Sim_Billing_International_Amount__c == null || dynamicPricingUpsert.Sim_Billing_International_Amount__c == 0){
            if(dynamicPricingUpsert.Sim_Transaction_International__c != null && dynamicPricingUpsert.Sim_Transaction_International__c != 0 && dynamicPricingUpsert.Sim_Tickets_International_Amount__c != null && dynamicPricingUpsert.Sim_Tickets_International_Amount__c != 0){
                dynamicPricingUpsert.Sim_Billing_International_Amount__c = (dynamicPricingUpsert.Sim_Transaction_International__c * dynamicPricingUpsert.Sim_Tickets_International_Amount__c).setscale(2);
            }
        }

        //auto calculo de ticket promedio si existen los otros dos valores de debito, credito o internacional.
        if(dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c == null || dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c == 0){
            if(dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c != 0 && dynamicPricingUpsert.Sim_Transaction_Debit_Own__c != null && dynamicPricingUpsert.Sim_Transaction_Debit_Own__c != 0){
                dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c = (dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c / dynamicPricingUpsert.Sim_Transaction_Debit_Own__c).setscale(2);
            }
        }

        if(dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c == null || dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c == 0){
            if(dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c != null && dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c != 0 && dynamicPricingUpsert.Sim_Transaction_Credit_Own__c != null && dynamicPricingUpsert.Sim_Transaction_Credit_Own__c != 0){
                dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c = (dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c / dynamicPricingUpsert.Sim_Transaction_Credit_Own__c).setscale(2);
            }
        }

        if(dynamicPricingUpsert.Sim_Tickets_International_Amount__c == null || dynamicPricingUpsert.Sim_Tickets_International_Amount__c == 0){
            if(dynamicPricingUpsert.Sim_Billing_International_Amount__c != null && dynamicPricingUpsert.Sim_Billing_International_Amount__c != 0 && dynamicPricingUpsert.Sim_Transaction_International__c != null && dynamicPricingUpsert.Sim_Transaction_International__c != 0){
                dynamicPricingUpsert.Sim_Tickets_International_Amount__c = (dynamicPricingUpsert.Sim_Billing_International_Amount__c / dynamicPricingUpsert.Sim_Transaction_International__c).setscale(2);
            }
        }

        dynamicPricingUpsert.Sim_Transaction_AcquirerAffiliation__c = dynamicPricingUpsert.Sim_Transaction_Debit_Own__c + dynamicPricingUpsert.Sim_Transaction_Credit_Own__c + dynamicPricingUpsert.Sim_Transaction_International__c;
        dynamicPricingUpsert.Sim_Billing_TotalAmount_Amount__c = dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c + dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c + dynamicPricingUpsert.Sim_Billing_International_Amount__c;
        dynamicPricingUpsert.Sim_Tickets_TotalAmount_Amount__c = dynamicPricingUpsert.Sim_Tickets_Debit_Own_Amount__c + dynamicPricingUpsert.Sim_Tickets_Credit_Own_Amount__c + dynamicPricingUpsert.Sim_Tickets_International_Amount__c;
        
        dynamicPricingUpsert.Sim_Percentage_Debit_MixOwn__c = 100 * dynamicPricingUpsert.Sim_Billing_Debit_Own_Amount__c/dynamicPricingUpsert.Sim_Billing_TotalAmount_Amount__c;
        //dynamicPricingUpsert.Sim_Percentage_Debit_MixExternal__c = 100 * dynamicPricingUpsert.Sim_Billing_Debit_ThirdParty_Amount__c/dynamicPricingUpsert.Sim_Billing_TotalAmount_Amount__c;
        dynamicPricingUpsert.Sim_Percentage_Credit_MixOwn__c = 100 * dynamicPricingUpsert.Sim_Billing_Credit_Own_Amount__c/dynamicPricingUpsert.Sim_Billing_TotalAmount_Amount__c;
        //dynamicPricingUpsert.Sim_Percentage_Credit_MixExternal__c = 100 * dynamicPricingUpsert.Sim_Billing_Credit_ThirdParty_Amount__c/dynamicPricingUpsert.Sim_Billing_TotalAmount_Amount__c;
        dynamicPricingUpsert.Sim_Percentage_MixInternational__c = 100 * dynamicPricingUpsert.Sim_Billing_International_Amount__c/dynamicPricingUpsert.Sim_Billing_TotalAmount_Amount__c;
        dynamicPricingUpsert.Sim_Percentage_Total__c = dynamicPricingUpsert.Sim_Percentage_Debit_MixOwn__c + dynamicPricingUpsert.Sim_Percentage_Credit_MixOwn__c + dynamicPricingUpsert.Sim_Percentage_MixInternational__c;
        dynamicPricingUpsert.flagBool__c = flagBool;

        if(!dynamicPricingUpsert.isCustomCliEdt__c){
            dynamicPricingUpsert.isCustomCliEdt__c = true;
        }

        update dynamicPricingUpsert;
        retMap.put('dynamicPricingUpsert', dynamicPricingUpsert);
        return retMap;
    }
}