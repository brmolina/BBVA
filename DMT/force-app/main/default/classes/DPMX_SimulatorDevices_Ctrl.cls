/**
* ____________________________________________________________________________
* Controller class for DPMX_SimulatorDevices.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-09-05
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_SimulatorDevices_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_SimulatorDevices_Ctrl() {

    }
    /**
    * @description ??????????????????????
    * @param acquirerActivitiesWrapper : DPMX_AcquirerActivities_Wrapper record obtained from Acquirer Activity Service
    * @param action : 'add' or 'edit'
    * @param dynamicPricing : DPMX_Dynamic_Pricing__c record info
    * @return retMap DPMX_Dynamic_Pricing__c record and checkboxes for Simulation
    */
    @AuraEnabled
    public static Map<String,Object> getData(DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, String action, DPMX_Dynamic_Pricing__c dynamicPricing) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricingUpsert = new DPMX_Dynamic_Pricing__c();
        Checboxes_Wrapper checkboxesWrapper = new Checboxes_Wrapper();
        Boolean withPinPadsBool = false;
        Boolean withOutPinPadsBool = false;
        Boolean isCustom = dynamicPricing.isCustom__c;
        dynamicPricingUpsert.Id = dynamicPricing.Id;
        if(!dynamicPricing.isCustom__c){
            dynamicPricingUpsert.Sim_Billing_TotalAmount_Currency__c = acquirerActivitiesWrapper.billing.totalAmount.currency_y;
            dynamicPricingUpsert.Sim_Tickets_TotalAmount_Currency__c = acquirerActivitiesWrapper.tickets.totalAmount.currency_y;
        }
        if (action != 'edit') {
            if(!dynamicPricing.isCustom__c){
                dynamicPricingUpsert.Sim_Terminal_Id__c = acquirerActivitiesWrapper.terminal.id_y;
                dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c = acquirerActivitiesWrapper.devices.pinPads.pinPadsNumber;
                dynamicPricingUpsert.Sim_Ecommerce__c = acquirerActivitiesWrapper.ecommerceCheckbox;
                dynamicPricingUpsert.Sim_DevicesInfo_Devices__c = acquirerActivitiesWrapper.devices.devicesNumber;
                dynamicPricingUpsert.Sim_Fees_ExtraBilling_Amount__c = acquirerActivitiesWrapper.commission.extraBilling.amount;
                dynamicPricingUpsert.Sim_Fees_ExtraBilling_Currency__c = acquirerActivitiesWrapper.commission.extraBilling.currency_y;
                dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c = acquirerActivitiesWrapper.devices.pinPads.pinPadsNumber;
            }
        } else {
            dynamicPricingUpsert.Sim_Terminal_Id__c = dynamicPricing.Sim_Terminal_Id__c;
            dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c = dynamicPricing.Sim_PinPadsInfo_PinPads__c;
            dynamicPricingUpsert.Sim_Ecommerce__c = dynamicPricing.Sim_Ecommerce__c;
            dynamicPricingUpsert.Sim_DevicesInfo_Devices__c = dynamicPricing.Sim_DevicesInfo_Devices__c;
            dynamicPricingUpsert.Sim_Fees_ExtraBilling_Amount__c = dynamicPricing.Sim_Fees_ExtraBilling_Amount__c;
            dynamicPricingUpsert.Sim_Fees_ExtraBilling_Currency__c = dynamicPricing.Sim_Fees_ExtraBilling_Currency__c;
            dynamicPricingUpsert.Sim_Fees_ExtraBilling_Checkbox__c = dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c;
            dynamicPricingUpsert.Sim_Fees_Cellnet_Checkbox__c = dynamicPricing.Sim_Fees_Cellnet_Checkbox__c;
            dynamicPricingUpsert.Sim_Fees_Billing_Checkbox__c = dynamicPricing.Sim_Fees_Billing_Checkbox__c;
            dynamicPricingUpsert.posCheckbox__c = dynamicPricing.posCheckbox__c;
            dynamicPricingUpsert.Sim_Recurring_Charges__c = dynamicPricing.Sim_Recurring_Charges__c;
            dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c = dynamicPricing.pinPadsInfo_withoutPinPads__c;
        }
        //Checkboxes
        if (dynamicPricingUpsert.Sim_Terminal_Id__c != 0 && dynamicPricingUpsert.Sim_Terminal_Id__c != null) {
            checkboxesWrapper.terminalIdCheckbox = true;
        }else {
            checkboxesWrapper.terminalIdCheckbox = false;
        }

        if (dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c != 0 && dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c != null) {
            withPinPadsBool = true;
        }

        if (dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c != 0 && dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c != null) {
            withOutPinPadsBool = true;
        }

        if(withPinPadsBool || withOutPinPadsBool){
            checkboxesWrapper.pinPadsInfoPinPadsCheckbox = true;
        }else {
            checkboxesWrapper.pinPadsInfoPinPadsCheckbox = false;
        }

        checkboxesWrapper.feesExtraBillingAmountCheckbox = dynamicPricingUpsert.Sim_Fees_ExtraBilling_Checkbox__c;

        checkboxesWrapper.feesCellnetAmountCheckbox = dynamicPricingUpsert.Sim_Fees_Cellnet_Checkbox__c;

        checkboxesWrapper.feesBillingAmountCheckbox = dynamicPricingUpsert.Sim_Fees_Billing_Checkbox__c;

        checkboxesWrapper.posCheckbox = dynamicPricingUpsert.posCheckbox__c;

        checkboxesWrapper.RecurringChargesCheckbox = dynamicPricingUpsert.Sim_Recurring_Charges__c;

        retMap.put('isCustom', dynamicPricing.isCustom__c);
        retMap.put('dynamicPricingUpsert', dynamicPricingUpsert);
        retMap.put('checkboxesWrapper', checkboxesWrapper);
        return retMap;
    }
    /**
    * @description ??????????????????????
    * @param dynamicPricingUpsert : DPMX_Dynamic_Pricing__c record with Simulator info
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> saveData(DPMX_Dynamic_Pricing__c dynamicPricingUpsert, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, Checboxes_Wrapper checkboxesWrapper, Integer flagBool, boolean isCustom) {
        Map<String, Object> retMap = new Map<String, Object>();
        dynamicPricingUpsert.Devices__c = true;
        dynamicPricingUpsert.flagBool__c = flagBool;

        System.debug(dynamicPricingUpsert.Sim_Fees_ExtraBilling_Checkbox__c);
        System.debug(dynamicPricingUpsert.Sim_Fees_Cellnet_Checkbox__c);
        System.debug(dynamicPricingUpsert.Sim_Fees_Billing_Checkbox__c);

        if (!checkboxesWrapper.terminalIdCheckbox) {
            dynamicPricingUpsert.Sim_Terminal_Id__c = 0;
        }
        if (!checkboxesWrapper.pinPadsInfoPinPadsCheckbox) {
            dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c = 0;
            dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c = 0;
        }

        System.debug(checkboxesWrapper.feesExtraBillingAmountCheckbox);
        System.debug(checkboxesWrapper.feesCellnetAmountCheckbox);
        System.debug(checkboxesWrapper.feesBillingAmountCheckbox);

        dynamicPricingUpsert.Sim_Fees_ExtraBilling_Checkbox__c = checkboxesWrapper.feesExtraBillingAmountCheckbox;

        dynamicPricingUpsert.Sim_Fees_Cellnet_Checkbox__c = checkboxesWrapper.feesCellnetAmountCheckbox;

        dynamicPricingUpsert.Sim_Fees_Billing_Checkbox__c = checkboxesWrapper.feesBillingAmountCheckbox;

        dynamicPricingUpsert.posCheckbox__c = checkboxesWrapper.posCheckbox;

        dynamicPricingUpsert.Sim_Recurring_Charges__c = checkboxesWrapper.RecurringChargesCheckbox;

        // Actualizar el total
        if(dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c == 0 && dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c == 0){
            dynamicPricingUpsert.withOutPinPadsCheckbox__c = false;
            dynamicPricingUpsert.Sim_DevicesInfo_Devices__c = 0;
        }else if(dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c > 0){
            dynamicPricingUpsert.Sim_DevicesInfo_Devices__c = dynamicPricingUpsert.Sim_Terminal_Id__c + dynamicPricingUpsert.pinPadsInfo_withoutPinPads__c;
            dynamicPricingUpsert.withOutPinPadsCheckbox__c = true;
        }else {
            dynamicPricingUpsert.Sim_DevicesInfo_Devices__c = dynamicPricingUpsert.Sim_Terminal_Id__c + dynamicPricingUpsert.Sim_PinPadsInfo_PinPads__c;
            dynamicPricingUpsert.withOutPinPadsCheckbox__c = true;
        }

        if(!dynamicPricingUpsert.isCustomCliEdt__c){
            dynamicPricingUpsert.isCustomCliEdt__c = true;
        }

        //Si ecommerce es true y lo demas es false 15, otros casos 26
        if(dynamicPricingUpsert.Sim_Ecommerce__c && (!dynamicPricingUpsert.Sim_Recurring_Charges__c && !dynamicPricingUpsert.withOutPinPadsCheckbox__c && !dynamicPricingUpsert.posCheckbox__c && dynamicPricingUpsert.Sim_Terminal_Id__c == 0)){
            dynamicPricingUpsert.basisPoint__c = 15;
        }else {
            dynamicPricingUpsert.basisPoint__c = 26;
        }

        update dynamicPricingUpsert;
        retMap.put('dynamicPricingUpsert', dynamicPricingUpsert);
        return retMap;
    }
    public class Checboxes_Wrapper {
        @AuraEnabled
        public Boolean terminalIdCheckbox {get; set;}
        @AuraEnabled
        public Boolean pinPadsInfoPinPadsCheckbox {get; set;}
        @AuraEnabled
        public Boolean feesExtraBillingAmountCheckbox {get; set;}
        @AuraEnabled
        public Boolean feesCellnetAmountCheckbox {get; set;}
        @AuraEnabled
        public Boolean feesBillingAmountCheckbox {get; set;}
        @AuraEnabled
        public Boolean posCheckbox {get; set;}
        @AuraEnabled
        public Boolean RecurringChargesCheckbox {get; set;}
    }
}