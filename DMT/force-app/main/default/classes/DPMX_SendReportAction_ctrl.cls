/**
* ____________________________________________________________________________
* Controller class for DPMX_SendReportAction.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-02-09
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_SendReportAction_ctrl {
/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_SendReportAction_ctrl() {

    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String, Object> retMapRentBai = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        Map<String, Object> responseMapAcqAct = new Map<String, Object>();
        List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = new List<DPMX_AcquirerActivities_Wrapper>();
        DPMX_AcquirerActivities_Wrapper acqActWrp = new DPMX_AcquirerActivities_Wrapper();
        Map<String, Object> responseMapAcqFee = new Map<String, Object>();
        DPMX_AcquirerActivitiesFees_Wrapper acqActFeesWrp = new DPMX_AcquirerActivitiesFees_Wrapper();
        Map<String, Object> responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.corporateRates_JSON__c);
        List<DPMX_CorporateRates_Wrapper> corpRatWrp = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMapCopRat.get('data')), List<DPMX_CorporateRates_Wrapper>.class);
        Map<String, Object> responseMapValidate = new Map<String, Object>();
        DPMX_ValidateResponse_Wrapper validateResponseWrapper = new DPMX_ValidateResponse_Wrapper();
        DPMX_ValidateResponse_Wrapper validateResponse = new DPMX_ValidateResponse_Wrapper();
        List<DPMX_ValidateResponse_Wrapper.itemizeRates> itemLst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
        List<DPMX_ValidateResponse_Wrapper.itemizeRates> itemLstRst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
        boolean isLastMonthTab = dynamicPricing.isLastMonthTab__c;
        boolean isSimulationTab = dynamicPricing.isSimulationTab__c;
        retMap.put('dynamicPricing', dynamicPricing);
        Boolean errorTab = false;
        decimal debitTasa;
        decimal creditTasa;
        decimal internationalTasa;
        DateTime today = DateTime.now();
        String consultDate = today.format('yyyy-MM-dd');
        String DPMX_Company_Name;
        String DPMX_familia;
        String DPMX_NumeroCliente;
        String DPMX_debit;
        String DPMX_credit;
        String DPMX_International;
        String DPMX_Resultado;
        String DPMX_Rentabilidad;
        String DPMX_BAI;

        String DPMX_Date;

        String DPMX_monetaryCeiling;
        String DPMX_extraBilling;
        String DPMX_billing;
        String DPMX_cellnet;
        String DPMX_extraBillingRub;
        String DPMX_billingRub;
        String DPMX_cellnetRub;
        String DPMX_totalAmount;
        String DPMX_totalAmountSim;
        String DPMX_mit;

        String DPMX_transaction_y_debit_own;
        String DPMX_billing_debit_own;
        String DPMX_tickets_debit_own;
        String DPMX_percentage_debit_own;

        String DPMX_transaction_y_debit_thirdParty;
        String DPMX_billing_debit_thirdParty;
        String DPMX_tickets_debit_thirdParty;
        String DPMX_percentage_debit_thirdParty;

        String DPMX_transaction_y_credit_own;
        String DPMX_billing_credit_own;
        String DPMX_tickets_credit_own;
        String DPMX_percentage_credit_own;

        String DPMX_transaction_y_credit_thirdParty;
        String DPMX_billing_credit_thirdParty;
        String DPMX_tickets_credit_thirdParty;
        String DPMX_percentage_credit_thirdParty;

        String DPMX_transaction_y_international;
        String DPMX_billing_international;
        String DPMX_tickets_international;
        String DPMX_percentage_international;

        String DPMX_transaction_y_total;
        String DPMX_billing_total;
        String DPMX_tickets_total;
        String DPMX_percentage_total;

        String DPMX_terminal;
        String DPMX_pinPads;
        String DPMX_ecommerceCheckbox;
        String DPMX_devicesNumber;

        List<Map<String,String>> scenariosLst = new List<Map<String,String>>();
        
        String DPMX_debitPorpio;
        String DPMX_creditPorpio;
        String DPMX_interPorpio;
        String DPMX_resultPorpio;
        String DPMX_rentPorpio;
        String DPMX_baiPorpio;

        String DPMX_oppPosExtra;
        String DPMX_oppCallnet;
        String DPMX_oppLowBilling;

        String DPMX_basisPoints;

        String DPMX_interchangeRates_debit;
        String DPMX_interchangeRates_credit;
        String DPMX_interchangeRates_International;

        String DPMX_discountRates_debit;
        String DPMX_discountRates_credit;
        String DPMX_discountRates_International;
        
        String DPMX_DescuentoMaximo;

        String DPMX_debit_sel;
        String DPMX_credit_sel;
        String DPMX_International_sel;
        String DPMX_Resultado_sel;
        String DPMX_Rentabilidad_sel;
        String DPMX_BAI_sel;

        DPMX_Container_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
        DPMX_Container_Ctrl.Discount_Rates_Wrapper discountRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
        List<DPMX_Container_Ctrl.Company_Info> companies = new List<DPMX_Container_Ctrl.Company_Info>();
        Double debit;
        Double credit;
        Double international;
        for (DPMX_CorporateRates_Wrapper CorporateRate: corpRatWrp) {
        credit = CorporateRate.credit.value;
        international = CorporateRate.international.value;
        if(CorporateRate.itemizeType.value == null){
            debit = CorporateRate.itemizeType.amount;
        }else{
            debit = CorporateRate.itemizeType.value;
        }
            switch on CorporateRate.id_y {
                when 'INTERCHANGE' {
                    interchangeRates.credit = credit;
                    interchangeRates.debit = debit;
                    interchangeRates.international = international;
                }
                when 'DISCOUNT' {
                    discountRates.credit = credit;
                    discountRates.debit = debit;
                    discountRates.international = international;
                }
                when 'AVERAGE_DISCOUNT' {
                    DPMX_Container_Ctrl.Company_Info familyAverage = new DPMX_Container_Ctrl.Company_Info();
                    familyAverage.id = '';
                    familyAverage.name = System.Label.DPMX_CompanyComparison_Row1;
                    familyAverage.credit = credit;
                    familyAverage.debit = debit;
                    familyAverage.international = international;
                    companies.add(familyAverage);
                }
            }
        }

        if(!dynamicPricing.isCustom__c){
            responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquiererActy_JSON__c);
            acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMapAcqAct.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
            acqActWrp = acquirerActivitiesWrapperLst[0];
            responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquirerFees_JSON__c);
            if(acqActWrp != null){
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    retMapRentBai = DPMX_Container_Ctrl.updateRates(recordId, acqActWrp, interchangeRates, false, acqActWrp.discount.percentage.credit, acqActWrp.discount.debit.itemizeType.amount, acqActWrp.discount.percentage.international, false, acqActWrp.expenses.totalAmount.amount);
                }else {
                    acqActWrp.isGS = false;
                    retMapRentBai = DPMX_Container_Ctrl.updateRates(recordId, acqActWrp, interchangeRates, false, acqActWrp.discount.percentage.credit, acqActWrp.discount.debit.itemizeType.value, acqActWrp.discount.percentage.international, false, acqActWrp.expenses.totalAmount.amount);
                }
                acqActWrp.yieldPercentage = (Decimal) retMapRentBai.get('profitability')+'';
                acqActWrp.taxAcquirer.amount = (Decimal) retMapRentBai.get('profitAmount');
            }
        }
        if(dynamicPricing.validate_JSON__c != null){
            responseMapValidate = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.validate_JSON__c);
            validateResponseWrapper = (DPMX_ValidateResponse_Wrapper) Json.deserialize(JSON.serialize(responseMapValidate.get('data')), DPMX_ValidateResponse_Wrapper.class);
            validateResponse = validateResponseWrapper;
        }

        //información HTML simular email

            //Header
            DPMX_Company_Name =  dynamicPricing.Company_Name__r.Name;
            DPMX_familia =  dynamicPricing.familia__c;
            Local_Client__c localClient = DPMX_Utils.Local_ClientSelector(dynamicPricing.Company_Name__c);
            DPMX_NumeroCliente = localClient.unique_id__c;
            //Body
            //Tasas descuento actuales
            if(!dynamicPricing.isCustom__c){
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    DPMX_debit =  DPMX_Utils.returnCurrency(acqActWrp.discount.debit.itemizeType.amount);
                }else{
                    acqActWrp.isGS = false;
                    DPMX_debit =  DPMX_Utils.returnIsPercent(acqActWrp.discount.debit.itemizeType.value);
                }
                DPMX_credit = DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.credit);
                DPMX_International = DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.international);
                if(acqActWrp.yieldPercentage > '0'){
                    DPMX_Resultado = Label.DPMX_Profitable;
                }else{
                    DPMX_Resultado = Label.DPMX_NoProfitable;
                }
                DPMX_Rentabilidad = DPMX_Utils.returnIsPercent(acqActWrp.yieldPercentage);
                DPMX_BAI = DPMX_Utils.returnCurrency(acqActWrp.taxAcquirer.amount);
                //Fecha ultimo mes del cliente
                DPMX_Date =  acqActWrp.informationDate;
                //Resumen de información del último mes
                DPMX_monetaryCeiling =  DPMX_Utils.returnCurrency(acqActWrp.discount.monetaryCeiling.amount);
                DPMX_extraBilling=  DPMX_Utils.returnCurrency(acqActWrp.commission.extraBilling.amount);
                DPMX_billing=  DPMX_Utils.returnCurrency(acqActWrp.commission.billing.amount);
                DPMX_cellnet=  DPMX_Utils.returnCurrency(acqActWrp.commission.cellnet.amount);
                DPMX_totalAmount=  DPMX_Utils.returnCurrency(acqActWrp.expenses.totalAmount.amount);
                DPMX_mit=  DPMX_Utils.returnCurrency(acqActWrp.expenses.mit.amount);
            }

            if(IsLastMonthTab && !dynamicPricing.isCustom__c){
                
                dynamicPricing.formalizeTab__c = false;
                //Tasa seleccionada
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    DPMX_debit_sel = DPMX_Utils.returnCurrency(dynamicPricing.debitLastMonth__c);
                }else{
                    acqActWrp.isGS = false;
                    DPMX_debit_sel = DPMX_Utils.returnIsPercent(dynamicPricing.debitLastMonth__c);
                }
                DPMX_credit_sel = DPMX_Utils.returnIsPercent(dynamicPricing.CreditLastMonth__c);
                DPMX_International_sel = DPMX_Utils.returnIsPercent(dynamicPricing.IntLastMonth__c);
                if(dynamicPricing.resultLastMonth__c == 'Break even' || dynamicPricing.resultLastMonth__c == 'BREAK_EVEN'){
                    DPMX_Resultado_sel = 'BREAK EVEN';
                }else if(dynamicPricing.resultLastMonth__c == 'GOOD'){
                    DPMX_Resultado_sel = 'Bueno';
                }else if(dynamicPricing.resultLastMonth__c == 'OPTIMAL'){
                    DPMX_Resultado_sel = 'Optimo';
                }else if(dynamicPricing.resultLastMonth__c == 'Minimo viable'){
                    DPMX_Resultado_sel = 'Minimo viable';
                }else {
                    DPMX_Resultado_sel = 'Simulación';
                }
                DPMX_Rentabilidad_sel = DPMX_Utils.returnIsPercent(dynamicPricing.RentabildiadLastMonth__c.setScale(2));
                DPMX_BAI_sel = DPMX_Utils.returnCurrency(dynamicPricing.baiLastMonth__c.setScale(2));
                
                DPMX_transaction_y_debit_own = (acqActWrp.transaction_y.debit.own + acqActWrp.transaction_y.debit.thirdParty)+'';
                DPMX_billing_debit_own = DPMX_Utils.returnCurrency(acqActWrp.billing.debit.own.amount + acqActWrp.billing.debit.thirdParty.amount);
                DPMX_tickets_debit_own = DPMX_Utils.returnCurrency(acqActWrp.tickets.debit.own.amount + acqActWrp.tickets.debit.thirdParty.amount);
                DPMX_percentage_debit_own = DPMX_Utils.returnIsPercent2(acqActWrp.percentage.debit.mixOwn + acqActWrp.percentage.debit.mixExternal);

                //Info cliente - Debito ajeno - Ya no se usa
                DPMX_transaction_y_debit_thirdParty =  acqActWrp.transaction_y.debit.thirdParty+'';
                DPMX_billing_debit_thirdParty =  DPMX_Utils.returnCurrency(acqActWrp.billing.debit.thirdParty.amount);
                DPMX_tickets_debit_thirdParty =  DPMX_Utils.returnCurrency(acqActWrp.tickets.debit.thirdParty.amount);
                DPMX_percentage_debit_thirdParty =  DPMX_Utils.returnIsPercent2(acqActWrp.percentage.debit.mixExternal);

                DPMX_transaction_y_credit_own = (acqActWrp.transaction_y.credit.own + acqActWrp.transaction_y.credit.thirdParty)+'';
                DPMX_billing_credit_own = DPMX_Utils.returnCurrency(acqActWrp.billing.credit.own.amount + acqActWrp.billing.credit.thirdParty.amount);
                DPMX_tickets_credit_own = DPMX_Utils.returnCurrency(acqActWrp.tickets.credit.own.amount + acqActWrp.tickets.credit.thirdParty.amount);
                DPMX_percentage_credit_own = DPMX_Utils.returnIsPercent2(acqActWrp.percentage.credit.mixOwn + acqActWrp.percentage.credit.mixExternal);

                //Info cliente - credit ajeno - Ya no se usa
                DPMX_transaction_y_credit_thirdParty =  acqActWrp.transaction_y.credit.thirdParty+'';
                DPMX_billing_credit_thirdParty =  DPMX_Utils.returnCurrency(acqActWrp.billing.credit.thirdParty.amount);
                DPMX_tickets_credit_thirdParty =  DPMX_Utils.returnCurrency(acqActWrp.tickets.credit.thirdParty.amount);
                DPMX_percentage_credit_thirdParty =  DPMX_Utils.returnIsPercent2(acqActWrp.percentage.credit.mixExternal);

                //Info cliente - international
                DPMX_transaction_y_international = acqActWrp.transaction_y.international+'';
                DPMX_billing_international = DPMX_Utils.returnCurrency(acqActWrp.billing.international.amount);
                DPMX_tickets_international = DPMX_Utils.returnCurrency(acqActWrp.tickets.international.amount);
                DPMX_percentage_international = DPMX_Utils.returnIsPercent2(acqActWrp.percentage.mixInternational);

                //Info cliente - total
                DPMX_transaction_y_total = acqActWrp.transaction_y.acquirerAffiliation+'';
                DPMX_billing_total = DPMX_Utils.returnCurrency(acqActWrp.billing.totalAmount.amount);
                DPMX_tickets_total = DPMX_Utils.returnCurrency(acqActWrp.tickets.totalAmount.amount);
                DPMX_percentage_total = DPMX_Utils.returnIsPercent2(acqActWrp.percentage.total);

                //Dispositivos simulados
                DPMX_terminal = acqActWrp.terminal.id_y+'';
                DPMX_pinPads = acqActWrp.devices.pinPads.pinPadsNumber+'';
                if(acqActWrp.ecommerce == 'N'){
                    DPMX_ecommerceCheckbox = 'No';
                }else {
                    DPMX_ecommerceCheckbox = 'Si';
                }
                DPMX_devicesNumber =  acqActWrp.devices.devicesNumber+'';

                //Comisiones apartado rubro
                DPMX_extraBillingRub =  DPMX_Utils.returnCurrency(acqActWrp.commission.billing.amount);
                DPMX_billingRub =  DPMX_Utils.returnCurrency(acqActWrp.commission.extraBilling.amount);
                DPMX_cellnetRub =  DPMX_Utils.returnCurrency(acqActWrp.commission.cellnet.amount);

                //Tasas descuento propuestas
                acqActFeesWrp = DPMX_Container_Ctrl.calculatedBaiRentForFees(dynamicPricing.acquirerFees_JSON__c, recordId, acqActWrp, interchangeRates);

                list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> scenariosArry = new  list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'BREAK_EVEN') {
                        scenariosArry.add(acqActFeesWrp.scenarios[i]);
                    }
                }

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'Minimo viable') {
                        scenariosArry.add(acqActFeesWrp.scenarios[i]);
                    }
                }

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'GOOD') {
                        scenariosArry.add(acqActFeesWrp.scenarios[i]);
                    }
                }

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType != 'BREAK_EVEN') {
                        if (acqActFeesWrp.scenarios[i].scenarioType != 'Minimo viable') {
                            if (acqActFeesWrp.scenarios[i].scenarioType != 'GOOD') {
                                scenariosArry.add(acqActFeesWrp.scenarios[i]);
                            }
                        }
                    }
                }

                //Scenarios
                String debitStr = '';
                String creditStr = '';
                String internationalStr = '';
                String result = '';
                String rent = '';
                String bai = '';
                for (Integer i = 0; i != (scenariosArry).size(); i++) {
                    Map<String,String> scenarioMap =  new Map<String,String>();
                    if(scenariosArry[i].scenarioType == 'GOOD'){
                        result = 'Bueno';
                        scenariosArry[i].scenarioType = 'Bueno';
                    }else if(scenariosArry[i].scenarioType == 'OPTIMAL'){
                        result = 'Optimo';
                        scenariosArry[i].scenarioType = 'Optimo';
                    }else if(scenariosArry[i].scenarioType == 'BREAK_EVEN'){
                        result = 'Break even';
                        scenariosArry[i].scenarioType = 'Break even';
                    }else if(scenariosArry[i].scenarioType == 'Minimo viable'){
                        result = 'Minimo viable';
                        scenariosArry[i].scenarioType = 'Minimo viable';
                    }

                    for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                        switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                            when 'DEBIT' {		
                                if(dynamicPricing.familia__c == Label.DPMX_GS){
                                    debitStr = DPMX_Utils.returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                                }else{
                                    debitStr = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                                }
                            }	
                            when 'CREDIT' {		
                                creditStr = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                            when 'INTERNATIONAL' {		
                                internationalStr = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }
                    }
                    rent = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.profitability.percentage);
                    bai = DPMX_Utils.returnCurrency(scenariosArry[i].fees.profitability.amount.amount);

                    scenarioMap.put('result', result);
                    scenarioMap.put('debit', debitStr);
                    scenarioMap.put('credit', creditStr);
                    scenarioMap.put('inter', internationalStr);
                    scenarioMap.put('rent', rent);
                    scenarioMap.put('bai', bai);
                    scenariosLst.add(scenarioMap);
                }

                //Scenario propio

                decimal profitabilityRates = dynamicPricing.CustomAcquiredFeesRent__c;
                decimal profitAmount = dynamicPricing.CustomAcquiredFeesBai__c;

                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_debitPorpio = DPMX_Utils.returnCurrency(dynamicPricing.CustomAcquiredFeesDebit__c);
                }else{
                    DPMX_debitPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesDebit__c);
                }
                
                DPMX_creditPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesCredit__c);
                DPMX_interPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesInternational__c);
                DPMX_resultPorpio = dynamicPricing.resultTasaEdit__c;
                if(profitabilityRates != null){
                    DPMX_rentPorpio = DPMX_Utils.returnIsPercent(profitabilityRates.setscale(2));
                    DPMX_baiPorpio = DPMX_Utils.returnCurrency(profitAmount.setscale(2));
                }
                
                //Oportunidades
                DPMX_oppPosExtra = DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.posExtra.amount);
                DPMX_oppCallnet = DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.cellnet.amount);
                DPMX_oppLowBilling = DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.lowBilling.amount);

                //Referencias Gastos (ya tenemos anteriormente los gastos totales y los MID y eBind)
                DPMX_totalAmountSim = DPMX_totalAmount;
                // Calculate Basis points gastos
                if (acqActWrp.ecommerce != 'N' &&
                (acqActWrp.terminal.id_y == 0 || acqActWrp.terminal.id_y == null) &&
                (acqActWrp.Devices.PinPads.pinPadsNumber == 0 || acqActWrp.Devices.PinPads.pinPadsNumber == null) &&
                (acqActWrp.Devices.devicesNumber == 0 || acqActWrp.Devices.devicesNumber == null)) {
                        acqActWrp.basisPoints = '15';
                }else {
                    acqActWrp.basisPoints = '26';
                }
                DPMX_basisPoints = acqActWrp.basisPoints+' BPS';

                //Tasas de descuento máximas
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_interchangeRates_debit = DPMX_Utils.returnCurrency(interchangeRates.debit);
                }else{
                    DPMX_interchangeRates_debit = DPMX_Utils.returnIsPercent(interchangeRates.debit);
                }
                DPMX_interchangeRates_credit = DPMX_Utils.returnIsPercent(interchangeRates.credit);
                DPMX_interchangeRates_International = DPMX_Utils.returnIsPercent(interchangeRates.international);

                //Intercambio
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_discountRates_debit = DPMX_Utils.returnCurrency(discountRates.debit);
                }else{
                    DPMX_discountRates_debit = DPMX_Utils.returnIsPercent(discountRates.debit);
                }
                DPMX_discountRates_credit = DPMX_Utils.returnIsPercent(discountRates.credit);
                DPMX_discountRates_International = DPMX_Utils.returnIsPercent(discountRates.international);

                //Descuento Maximo
                DPMX_DescuentoMaximo = DPMX_Utils.returnIsPercent(acqActWrp.discount.monetaryCeiling.amount);

                //Información Tasa selecionada
                debitTasa = dynamicPricing.debitLastMonth__c.setScale(2);
                creditTasa = dynamicPricing.CreditLastMonth__c.setScale(2);
                internationalTasa = dynamicPricing.IntLastMonth__c.setScale(2);

            }else if(isSimulationTab || dynamicPricing.isCustom__c){
                dynamicPricing.formalizeTab__c = true;
                //Tasa seleccionada
                if(dynamicPricing.familia_AcquiererCategories_Id__c == '13'){
                    DPMX_debit_sel = DPMX_Utils.returnCurrency(dynamicPricing.debitSim__c);
                }else{
                    DPMX_debit_sel = DPMX_Utils.returnIsPercent(dynamicPricing.debitSim__c);
                }
                DPMX_credit_sel = DPMX_Utils.returnIsPercent(dynamicPricing.creditSim__c);
                DPMX_International_sel = DPMX_Utils.returnIsPercent(dynamicPricing.interSim__c);
                if(dynamicPricing.resultSim__c == 'Break even' || dynamicPricing.resultSim__c == 'BREAK_EVEN'){
                    DPMX_Resultado_sel = 'BREAK EVEN';
                }else if(dynamicPricing.resultSim__c == 'GOOD' || dynamicPricing.resultSim__c == 'Bueno'){
                    DPMX_Resultado_sel = 'Bueno';
                }else if(dynamicPricing.resultSim__c == 'OPTIMAL' || dynamicPricing.resultSim__c == 'Optimo'){
                    DPMX_Resultado_sel = 'Optimo';
                }else if(dynamicPricing.resultSim__c == 'Minimo viable'){
                    DPMX_Resultado_sel = 'Minimo viable';
                }else{
                    DPMX_Resultado_sel = 'Simulación';
                }
                DPMX_Rentabilidad_sel = DPMX_Utils.returnIsPercent(dynamicPricing.RentabildiadSim__c.setScale(2));
                DPMX_BAI_sel = DPMX_Utils.returnCurrency(dynamicPricing.baiSim__c.setScale(2));
                //Información Tasa selecionada
                debitTasa = dynamicPricing.debitSim__c.setScale(2);
                creditTasa = dynamicPricing.creditSim__c.setScale(2);
                internationalTasa = dynamicPricing.interSim__c.setScale(2);

                //Info cliente - Debito propio
                DPMX_transaction_y_debit_own =  (dynamicPricing.Sim_Transaction_Debit_Own__c).setscale(2)+'';
                DPMX_billing_debit_own =  DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Debit_Own_Amount__c);
                DPMX_tickets_debit_own =  DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Debit_Own_Amount__c);
                DPMX_percentage_debit_own = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixOwn__c.setscale(2));

                //Info cliente - Debito ajeno
                DPMX_transaction_y_debit_thirdParty = (dynamicPricing.Sim_Transaction_Debit_ThirdParty__c).setscale(2)+'';
                DPMX_billing_debit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Debit_ThirdParty_Amount__c);
                DPMX_tickets_debit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Debit_ThirdParty_Amount__c);
                DPMX_percentage_debit_thirdParty = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixExternal__c.setscale(2));

                //Info cliente - credit propio
                DPMX_transaction_y_credit_own = (dynamicPricing.Sim_Transaction_Credit_Own__c).setscale(2)+'';
                DPMX_billing_credit_own = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Credit_Own_Amount__c);
                DPMX_tickets_credit_own = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Credit_Own_Amount__c);
                DPMX_percentage_credit_own = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixOwn__c.setscale(2));

                //Info cliente - credit ajeno
                DPMX_transaction_y_credit_thirdParty = (dynamicPricing.Sim_Transaction_Credit_ThirdParty__c).setscale(2)+'';
                DPMX_billing_credit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Credit_ThirdParty_Amount__c);
                DPMX_tickets_credit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Credit_ThirdParty_Amount__c);
                DPMX_percentage_credit_thirdParty = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixExternal__c.setscale(2));

                //Info cliente - international
                DPMX_transaction_y_international =  (dynamicPricing.Sim_Transaction_International__c).setscale(2)+'';
                DPMX_billing_international = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_International_Amount__c);
                DPMX_tickets_international = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_International_Amount__c);
                DPMX_percentage_international = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_MixInternational__c.setscale(2));

                //Info cliente - total
                DPMX_transaction_y_total = (dynamicPricing.Sim_Transaction_AcquirerAffiliation__c).setscale(2)+'';
                DPMX_billing_total = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_TotalAmount_Amount__c);
                DPMX_tickets_total = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_TotalAmount_Amount__c);
                DPMX_percentage_total = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Total__c.setscale(2));

                //Dispositivos simulados y Oportunidades

                DPMX_terminal = dynamicPricing.Sim_Terminal_Id__c+'';
                if(dynamicPricing.Sim_PinPadsInfo_PinPads__c == null){
                    DPMX_pinPads = dynamicPricing.pinPadsInfo_withoutPinPads__c+'';
                }else{
                    DPMX_pinPads = dynamicPricing.Sim_PinPadsInfo_PinPads__c+'';
                }
                
                if(dynamicPricing.Sim_Ecommerce__c){
                    DPMX_ecommerceCheckbox = 'Si';
                }else {
                    DPMX_ecommerceCheckbox = 'No';
                }
                DPMX_devicesNumber =  dynamicPricing.Sim_DevicesInfo_Devices__c+'';
                
                if (dynamicPricing.Sim_Fees_Billing_Checkbox__c) {
                    DPMX_extraBillingRub = 416.44+'';
                } else {
                    DPMX_extraBillingRub = 0+'';
                }
                DPMX_oppPosExtra = 416.44+'';

                decimal nTPV = 0;
                nTPV = dynamicPricing.Sim_Terminal_Id__c;
                DPMX_cellnetRub = 0+'';
                if(dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c){
                    if (nTPV > 0) {
                        nTPV = (nTPV - 1) * Integer.valueOf(System.Label.DPMX_CommissionTPV);
                        DPMX_cellnetRub = nTPV+'';
                    }
                }

                if (dynamicPricing.Sim_Terminal_Id__c > 1) {
                    DPMX_oppCallnet = (dynamicPricing.Sim_Terminal_Id__c - 1) * Integer.valueOf(System.Label.DPMX_CommissionTPV)+'';
                }else{
                    DPMX_oppCallnet = 0+'';
                }
               
                if (dynamicPricing.Sim_Fees_Cellnet_Checkbox__c) {
                    DPMX_billingRub = 0.42+'';
                } else {
                    DPMX_billingRub = 0 + '';
                }
                DPMX_oppLowBilling = 0.42+'';

                //Tasas descuento propuestas
                //Buscar wrappers necesarios para el calculo de rentabilidad y bai
                //Buscar el wrapper validate y agregle orden de break even a optimo
                
                integer i = 0;
                integer z = 0;
                integer q = 0;
                integer orderIdProp = 0;
                integer orderIdItem = 0;
                boolean goodScenarioExist = false;
                boolean goodTwoScenarioExist = false;
                boolean optimalScenarioExist = false;
                dynamicPricing.gastoTotal__c = validateResponseWrapper.proposed[0].amount.amount;
                Map<String,Object> baiMAP = new Map<String,Object>();
                decimal debitVal = 0;
                decimal creditVal = 0;
                decimal internationalVal = 0;
                DPMX_ValidateResponse_Wrapper.Amount amountResponse = new DPMX_ValidateResponse_Wrapper.Amount();
                for(i = 0; i != validateResponseWrapper.proposed.size(); i++){
                    if(validateResponseWrapper.proposed[i].scenaryType == 'BREAK_EVEN' || validateResponseWrapper.proposed[i].scenaryType == 'Minimo viable'){
                        validateResponseWrapper.proposed[i].idOrder = 0;
                        validateResponse.proposed.set(0, validateResponseWrapper.proposed[i]);
                    }else if(validateResponseWrapper.proposed[i].scenaryType == 'GOOD'){
                        if(goodScenarioExist){
                            validateResponseWrapper.proposed[i].idOrder = 2;
                            validateResponse.proposed.set(2, validateResponseWrapper.proposed[i]);
                            goodTwoScenarioExist = true;
                        }else {
                            validateResponseWrapper.proposed[i].idOrder = 1;
                            validateResponse.proposed.set(1, validateResponseWrapper.proposed[i]);
                            goodScenarioExist = true;
                        }
                    }
                    for(z = 0; z != validateResponseWrapper.proposed[i].rate.itemizeRates.size(); z++){
                        if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'DEBIT_DISCOUNT'){
                            if(dynamicPricing.familia_AcquiererCategories_Id__c == '13'){
                                debitVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.amount;
                            }else{
                                debitVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            }
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'CREDIT_DISCOUNT'){
                            creditVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL_DISCOUNT'){
                            internationalVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                        }
                        if(debitVal != null && debitVal != 0 && creditVal != null && creditVal != 0 && internationalVal != null && internationalVal != 0){
                            baiMAP = DPMX_Container_Ctrl.updateRates(recordId, acqActWrp, interchangeRates, false, creditVal, debitVal, internationalVal, true, dynamicPricing.gastoTotal__c);
                            amountResponse.amount = (decimal) baiMAP.get('profitAmount');
                            amountResponse.currency_y = 'MXN';
                            validateResponseWrapper.proposed[i].amount = amountResponse;
                            for(q = 0; q != validateResponseWrapper.proposed[i].rate.itemizeRates.size(); q++){
                                if(validateResponseWrapper.proposed[i].rate.itemizeRates[q].rateType == 'RETURN'){
                                    validateResponseWrapper.proposed[i].rate.itemizeRates[q].itemizeRatesUnit.percentage = (decimal) baiMAP.get('profitability');
                                }
                            }
                        }
                        if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'DEBIT_DISCOUNT'){
                            debitVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 0;
                            itemLst.set(0, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'CREDIT_DISCOUNT'){
                            creditVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 1;
                            itemLst.set(1, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL_DISCOUNT'){
                            internationalVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 2;
                            itemLst.set(2, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'RETURN'){
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 3;
                            itemLst.set(3, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }
                    }
                    validateResponse.proposed[i].rate.itemizeRates = itemLst;
                    itemLst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
                    debitVal = 0;
                    debitVal = 0;
                    internationalVal = 0;
                    baiMAP.clear();
                    amountResponse = new DPMX_ValidateResponse_Wrapper.Amount();
                }
                for(i = 0; i != validateResponseWrapper.proposed.size(); i++){
                    if(validateResponseWrapper.proposed[i].scenaryType == 'OPTIMAL'){
                        if(optimalScenarioExist){
                            if(goodTwoScenarioExist){
                                validateResponseWrapper.proposed[i].idOrder = 4;
                                validateResponse.proposed.set(4, validateResponseWrapper.proposed[i]);
                            }else {
                                validateResponseWrapper.proposed[i].idOrder = 3;
                                validateResponse.proposed.set(3, validateResponseWrapper.proposed[i]);
                            }
                            
                        }else {
                            if(goodTwoScenarioExist){
                                validateResponseWrapper.proposed[i].idOrder = 3;
                                validateResponse.proposed.set(3, validateResponseWrapper.proposed[i]);
                            }else {
                                validateResponseWrapper.proposed[i].idOrder = 2;
                                validateResponse.proposed.set(2, validateResponseWrapper.proposed[i]);
                            }
                            optimalScenarioExist = true; 
                        }
                    }
                }

                //Scenarios
                String debitStr = '';
                String creditStr = '';
                String internationalStr = '';
                String result = '';
                String rent = '';
                String bai = '';
                system.debug(validateResponse);
                system.debug(validateResponse.proposed.size());
                for (i = 0; i != validateResponse.proposed.size(); i++) {
                    Map<String,String> scenarioMap =  new Map<String,String>();
                    system.debug(validateResponse.proposed[i].scenaryType);
                    if (validateResponse.proposed[i].scenaryType == 'OPTIMAL') {
                        result = 'Optimo';
                    } else if (validateResponse.proposed[i].scenaryType == 'GOOD') {
                         result = 'Bueno';
                    } else if(validateResponse.proposed[i].scenaryType == 'Minimo viable'){
                        result = 'Minimo viable';
                    }else {
                         result = 'Break even';
                    }
                    system.debug(validateResponse.proposed[i].rate.itemizeRates.size());
                    for(z = 0; z != validateResponse.proposed[i].rate.itemizeRates.size(); z++){
                        system.debug(validateResponse.proposed[i].rate.itemizeRates[z].idOrder);
                        switch on (validateResponse.proposed[i].rate.itemizeRates[z].idOrder) {
                            when (0){
                                if (dynamicPricing.familia_AcquiererCategories_Id__c == '13') {
                                    debitStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.amount+'';
                                } else {
                                    debitStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                                }
                            }
                            when (1){
                                creditStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                            }
                            when (2){
                                internationalStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                            }
                            when (3){
                                rent = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                            }
                        }
                    }
                    bai = validateResponse.proposed[i].amount.amount+'';
                    system.debug(debitStr);
                    system.debug(creditStr);
                    system.debug(internationalStr);
                    system.debug(rent);
                    system.debug(bai);
                    system.debug(result);

                    scenarioMap.put('result', result);
                    scenarioMap.put('debit', debitStr);
                    scenarioMap.put('credit', creditStr);
                    scenarioMap.put('inter', internationalStr);
                    scenarioMap.put('rent', rent);
                    scenarioMap.put('bai', bai);
                    scenariosLst.add(scenarioMap);
                }

                //Scenario propio
                decimal profitabilityRates = dynamicPricing.CustomSimulatedRent__c;
                decimal profitAmount = dynamicPricing.CustomSimulatedBai__c;
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_debitPorpio = DPMX_Utils.returnCurrency(dynamicPricing.CustomSimulatedDebit__c);
                }else{
                    DPMX_debitPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedDebit__c);
                }
                
                DPMX_creditPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedCredit__c);
                DPMX_interPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedInternational__c);
                DPMX_resultPorpio = dynamicPricing.resultTasaEditSim__c;
                if(profitabilityRates != null){
                    DPMX_rentPorpio = DPMX_Utils.returnIsPercent(profitabilityRates.setscale(2));
                    DPMX_baiPorpio = DPMX_Utils.returnCurrency(profitAmount.setscale(2));
                }

                //Referencias Gastos (ya tenemos anteriormente los MID)
                DPMX_totalAmountSim = DPMX_Utils.returnCurrency(dynamicPricing.gastoTotal__c);
                // Calculate Basis points gastos
                DPMX_basisPoints = dynamicPricing.basisPoint__c+' BPS';

                //Tasas de descuento máximas
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_interchangeRates_debit = DPMX_Utils.returnCurrency(interchangeRates.debit);
                }else{
                    DPMX_interchangeRates_debit = DPMX_Utils.returnIsPercent(interchangeRates.debit);
                }
                DPMX_interchangeRates_credit = DPMX_Utils.returnIsPercent(interchangeRates.credit);
                DPMX_interchangeRates_International = DPMX_Utils.returnIsPercent(interchangeRates.international);

                if(!dynamicPricing.isCustom__c){
                    System.debug(discountRates);
                    //Intercambio
                    if(dynamicPricing.familia__c == Label.DPMX_GS){
                        DPMX_discountRates_debit = DPMX_Utils.returnCurrency(discountRates.debit);
                    }else{
                        DPMX_discountRates_debit = DPMX_Utils.returnIsPercent(discountRates.debit);
                    }
                    DPMX_discountRates_credit = DPMX_Utils.returnIsPercent(discountRates.credit);
                    DPMX_discountRates_International = DPMX_Utils.returnIsPercent(discountRates.international);

                    //Descuento Maximo
                    DPMX_DescuentoMaximo = DPMX_Utils.returnIsPercent(acqActWrp.discount.monetaryCeiling.amount);
                }
                

            } else {
                errorTab = true;
            }

         retMap.put('errorTab', errorTab);
        //Mensaje de error por pesntaña no adecuada
        if(errorTab){
            retMap.put('msgErrorTab', 'Para usar en envio de correo debes estar en la pestaña de "Último mes del cliente" o "Simulación".');
        } else{
            //Envio de correo de simulacion
            retMap.put('DPMX_Company_Name__c', DPMX_Company_Name);
            retMap.put('DPMX_familia__c', DPMX_familia);
            retMap.put('DPMX_NumeroCliente__c', DPMX_NumeroCliente);
            retMap.put('consultDate', consultDate);

            retMap.put('DPMX_debit', DPMX_debit);
            retMap.put('DPMX_credit', DPMX_credit);
            retMap.put('DPMX_International', DPMX_International);
            retMap.put('DPMX_Resultado', DPMX_Resultado);
            retMap.put('DPMX_Rentabilidad', DPMX_Rentabilidad);
            retMap.put('DPMX_BAI', DPMX_BAI);

            retMap.put('DPMX_Date', DPMX_Date);

            retMap.put('DPMX_monetaryCeiling', DPMX_monetaryCeiling);
            retMap.put('DPMX_extraBilling', DPMX_extraBilling);
            retMap.put('DPMX_billing', DPMX_billing);
            retMap.put('DPMX_cellnet', DPMX_cellnet);
            retMap.put('DPMX_billingRub', DPMX_billingRub);
            retMap.put('DPMX_extraBillingRub', DPMX_extraBillingRub);
            retMap.put('DPMX_cellnetRub', DPMX_cellnetRub);
            retMap.put('DPMX_mit', DPMX_mit);

            retMap.put('DPMX_transaction_y_debit_own', DPMX_transaction_y_debit_own);
            retMap.put('DPMX_billing_debit_own', DPMX_billing_debit_own);
            retMap.put('DPMX_tickets_debit_own', DPMX_tickets_debit_own);
            retMap.put('DPMX_percentage_debit_own', DPMX_percentage_debit_own);

            retMap.put('DPMX_transaction_y_debit_thirdParty', DPMX_transaction_y_debit_thirdParty);
            retMap.put('DPMX_billing_debit_thirdParty', DPMX_billing_debit_thirdParty);
            retMap.put('DPMX_tickets_debit_thirdParty', DPMX_tickets_debit_thirdParty);
            retMap.put('DPMX_percentage_debit_thirdParty', DPMX_percentage_debit_thirdParty);
            
            retMap.put('DPMX_transaction_y_credit_own', DPMX_transaction_y_credit_own);
            retMap.put('DPMX_billing_credit_own', DPMX_billing_credit_own);
            retMap.put('DPMX_tickets_credit_own', DPMX_tickets_credit_own);
            retMap.put('DPMX_percentage_credit_own', DPMX_percentage_credit_own);

            retMap.put('DPMX_transaction_y_credit_thirdParty', DPMX_transaction_y_credit_thirdParty);
            retMap.put('DPMX_billing_credit_thirdParty', DPMX_billing_credit_thirdParty);
            retMap.put('DPMX_tickets_credit_thirdParty', DPMX_tickets_credit_thirdParty);
            retMap.put('DPMX_percentage_credit_thirdParty', DPMX_percentage_credit_thirdParty);

            retMap.put('DPMX_transaction_y_international', DPMX_transaction_y_international);
            retMap.put('DPMX_billing_international', DPMX_billing_international);
            retMap.put('DPMX_tickets_international', DPMX_tickets_international);
            retMap.put('DPMX_percentage_international', DPMX_percentage_international);

            retMap.put('DPMX_transaction_y_total', DPMX_transaction_y_total);
            retMap.put('DPMX_billing_total', DPMX_billing_total);
            retMap.put('DPMX_tickets_total', DPMX_tickets_total);
            retMap.put('DPMX_percentage_total', DPMX_percentage_total);

            retMap.put('DPMX_terminal', DPMX_terminal);
            retMap.put('DPMX_pinPads', DPMX_pinPads);
            retMap.put('DPMX_ecommerceCheckbox', DPMX_ecommerceCheckbox);
            retMap.put('DPMX_devicesNumber', DPMX_devicesNumber);

            retMap.put('DPMX_scenario', scenariosLst);
            
            retMap.put('DPMX_debitPorpio', DPMX_debitPorpio);
            retMap.put('DPMX_creditPorpio', DPMX_creditPorpio);
            retMap.put('DPMX_interPorpio', DPMX_interPorpio);
            retMap.put('DPMX_resultPorpio', DPMX_resultPorpio);
            retMap.put('DPMX_rentPorpio', DPMX_rentPorpio);
            retMap.put('DPMX_baiPorpio', DPMX_baiPorpio);

            retMap.put('DPMX_oppPosExtra', DPMX_oppPosExtra);
            retMap.put('DPMX_oppCallnet', DPMX_oppCallnet);
            retMap.put('DPMX_oppLowBilling', DPMX_oppLowBilling);

            retMap.put('DPMX_basisPoints', DPMX_basisPoints);

            retMap.put('DPMX_interchangeRates_debit', DPMX_interchangeRates_debit);
            retMap.put('DPMX_interchangeRates_credit', DPMX_interchangeRates_credit);
            retMap.put('DPMX_interchangeRates_International', DPMX_interchangeRates_International);

            retMap.put('DPMX_discountRates_debit', DPMX_discountRates_debit);
            retMap.put('DPMX_discountRates_credit', DPMX_discountRates_credit);
            retMap.put('DPMX_discountRates_International', DPMX_discountRates_International);

            retMap.put('DPMX_DescuentoMaximo', DPMX_DescuentoMaximo);

            retMap.put('DPMX_debit_sel', DPMX_debit_sel);
            retMap.put('DPMX_credit_sel', DPMX_credit_sel);
            retMap.put('DPMX_International_sel', DPMX_International_sel);
            retMap.put('DPMX_Resultado_sel', DPMX_Resultado_sel);
            retMap.put('DPMX_Rentabilidad_sel', DPMX_Rentabilidad_sel);
            retMap.put('DPMX_BAI_sel', DPMX_BAI_sel);
            retMap.put('DPMX_totalAmountSim', DPMX_totalAmountSim);
            retMap.put('DPMX_totalAmount', DPMX_totalAmount);
            //Envio de correo de Tasa
            retMap.put('debitTasa', debitTasa);
            retMap.put('creditTasa', creditTasa);
            retMap.put('internationalTasa', internationalTasa);

            retMap.put('isCustom', dynamicPricing.isCustom__c);
            retMap.put('isLastMonthTab', isLastMonthTab);
            
        }

        return retMap;
    }

    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param recordId : Client Id
    * @return retMap status update 
    */
    @AuraEnabled
    public static Map<String,Object> sendReport (string recordId, string templateName, string saludo, string intro, string close, string[] sendCC, String asunto) {
        Map<String, Object> retMapRentBai = new Map<String, Object>();
        decimal debitTasa;
        decimal creditTasa;
        decimal internationalTasa;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        System.debug(templateName);
        EmailTemplate emailTemp = [Select id, Subject, Body, HtmlValue From EmailTemplate Where DeveloperName =:templateName];
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
        boolean isLastMonthTab = dynamicPricing.isLastMonthTab__c;
        boolean isSimulationTab = dynamicPricing.isSimulationTab__c;
        string status = 'sendReport';
        Boolean sendReport = true;
        String htmlBody = emailTemp.HtmlValue;
        DateTime today = DateTime.now();
        String consultDate = today.format('yyyy-MM-dd');
        Map<String, Object> responseMapAcqAct = new Map<String, Object>();
        List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = new List<DPMX_AcquirerActivities_Wrapper>();
        DPMX_AcquirerActivities_Wrapper acqActWrp = new DPMX_AcquirerActivities_Wrapper();
        Map<String, Object> responseMapAcqFee = new Map<String, Object>();
        DPMX_AcquirerActivitiesFees_Wrapper acqActFeesWrp = new DPMX_AcquirerActivitiesFees_Wrapper();
        final Map<String, Object> responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.corporateRates_JSON__c);
        final List<DPMX_CorporateRates_Wrapper> corpRatWrp = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMapCopRat.get('data')), List<DPMX_CorporateRates_Wrapper>.class);
        Map<String, Object> responseMapValidate = new Map<String, Object>();
        DPMX_ValidateResponse_Wrapper validateResponseWrapper = new DPMX_ValidateResponse_Wrapper();
        DPMX_ValidateResponse_Wrapper validateResponse = new DPMX_ValidateResponse_Wrapper();
        List<DPMX_ValidateResponse_Wrapper.itemizeRates> itemLst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
        List<DPMX_ValidateResponse_Wrapper.itemizeRates> itemLstRst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
        Double debit;
        Double credit;
        Double international;

        DPMX_Container_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
        DPMX_Container_Ctrl.Discount_Rates_Wrapper discountRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
        List<DPMX_Container_Ctrl.Company_Info> companies = new List<DPMX_Container_Ctrl.Company_Info>();

        for (DPMX_CorporateRates_Wrapper CorporateRate: corpRatWrp) {
        credit = CorporateRate.credit.value;
        international = CorporateRate.international.value;
        if(CorporateRate.itemizeType.value == null){
            debit = CorporateRate.itemizeType.amount;
        }else{
            debit = CorporateRate.itemizeType.value;
        }
            switch on CorporateRate.id_y {
                when 'INTERCHANGE' {
                    interchangeRates.credit = credit;
                    interchangeRates.debit = debit;
                    interchangeRates.international = international;
                }
                when 'DISCOUNT' {
                    discountRates.credit = credit;
                    discountRates.debit = debit;
                    discountRates.international = international;
                }
                when 'AVERAGE_DISCOUNT' {
                    DPMX_Container_Ctrl.Company_Info familyAverage = new DPMX_Container_Ctrl.Company_Info();
                    familyAverage.id = '';
                    familyAverage.name = System.Label.DPMX_CompanyComparison_Row1;
                    familyAverage.credit = credit;
                    familyAverage.debit = debit;
                    familyAverage.international = international;
                    companies.add(familyAverage);
                }
            }
        }

        if(!dynamicPricing.isCustom__c){
            responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquiererActy_JSON__c);
            acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMapAcqAct.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
            acqActWrp = acquirerActivitiesWrapperLst[0];
            responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquirerFees_JSON__c);
            if(acqActWrp != null){
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    retMapRentBai = DPMX_Container_Ctrl.updateRates(recordId, acqActWrp, interchangeRates, false, acqActWrp.discount.percentage.credit, acqActWrp.discount.debit.itemizeType.amount, acqActWrp.discount.percentage.international, false, acqActWrp.expenses.totalAmount.amount);
                }else {
                    acqActWrp.isGS = false;
                    retMapRentBai = DPMX_Container_Ctrl.updateRates(recordId, acqActWrp, interchangeRates, false, acqActWrp.discount.percentage.credit, acqActWrp.discount.debit.itemizeType.value, acqActWrp.discount.percentage.international, false, acqActWrp.expenses.totalAmount.amount);
                }
                acqActWrp.yieldPercentage = (Decimal) retMapRentBai.get('profitability')+'';
                acqActWrp.taxAcquirer.amount = (Decimal) retMapRentBai.get('profitAmount');
            }
        }
        if(dynamicPricing.validate_JSON__c != null){
            responseMapValidate = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.validate_JSON__c);
            validateResponseWrapper = (DPMX_ValidateResponse_Wrapper) Json.deserialize(JSON.serialize(responseMapValidate.get('data')), DPMX_ValidateResponse_Wrapper.class);
            validateResponse = validateResponseWrapper;
        }
        if(templateName == 'DPMX_SendReportTasa'){
            if(isLastMonthTab && !dynamicPricing.isCustom__c){
                if(dynamicPricing.resultLastMonth__c == 'BREAK_EVEN' || dynamicPricing.resultLastMonth__c == 'Minimo viable'){
                    if(returnAuthIsAccepted(recordId, ''+dynamicPricing.debitLastMonth__c, ''+dynamicPricing.CreditLastMonth__c, ''+dynamicPricing.IntLastMonth__c))
                    {
                        debitTasa = dynamicPricing.debitLastMonth__c.setScale(2);
                        creditTasa = dynamicPricing.CreditLastMonth__c.setScale(2);
                        internationalTasa = dynamicPricing.IntLastMonth__c.setScale(2);
                    }else {
                        status = 'El break even tiene que ser aceptado para poder enviarse.';
                        sendReport = false;
                    }
                }else {
                    debitTasa = dynamicPricing.debitLastMonth__c.setScale(2);
                    creditTasa = dynamicPricing.CreditLastMonth__c.setScale(2);
                    internationalTasa = dynamicPricing.IntLastMonth__c.setScale(2);
                }
            }else if(isSimulationTab || dynamicPricing.isCustom__c){
                if(dynamicPricing.resultSim__c == 'BREAK_EVEN' || dynamicPricing.resultSim__c == 'Minimo viable'){
                    if(returnAuthIsAccepted(recordId, ''+dynamicPricing.debitSim__c, ''+dynamicPricing.creditSim__c, ''+dynamicPricing.interSim__c))
                    {
                        debitTasa = dynamicPricing.debitSim__c.setScale(2);
                        creditTasa = dynamicPricing.creditSim__c.setScale(2);
                        internationalTasa = dynamicPricing.interSim__c.setScale(2);
                    }else {
                        status = 'El break even tiene que ser aceptado para poder enviarse.';
                        sendReport = false;
                    }
                }else {
                    debitTasa = dynamicPricing.debitSim__c.setScale(2);
                    creditTasa = dynamicPricing.creditSim__c.setScale(2);
                    internationalTasa = dynamicPricing.interSim__c.setScale(2);
                }
            }
            
            htmlBody = htmlBody.replace('{!DPMX.saludo}',saludo);
            htmlBody = htmlBody.replace('{!DPMX.Introduccion}',intro);
            htmlBody = htmlBody.replace('{!DPMX.close}',close);
            if(dynamicPricing.familia__c == Label.DPMX_GS){
                htmlBody = htmlBody.replace('{!DPMX.debitTasa}',returnCurrency(debitTasa));
            }else{
                htmlBody = htmlBody.replace('{!DPMX.debitTasa}', returnIsPercent(debitTasa));
            }
            
            htmlBody = htmlBody.replace('{!DPMX.creditTasa}',returnIsPercent(creditTasa));
            htmlBody = htmlBody.replace('{!DPMX.internationalTasa}',returnIsPercent(internationalTasa));
        }else {
             //Header
             if(!dynamicPricing.isCustom__c){
                htmlBody = htmlBody.replace('{!DPMX.Company_Name__c}', dynamicPricing.Company_Name__r.Name);
                Local_Client__c localClient = DPMX_Utils.Local_ClientSelector(dynamicPricing.Company_Name__c);
                htmlBody = htmlBody.replace('{!DPMX.NumeroCliente__c}', localClient.unique_id__c);
                //Tasas descuento actuales
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.debit}', DPMX_Utils.returnCurrency(acqActWrp.discount.debit.itemizeType.amount));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.debit}', DPMX_Utils.returnIsPercent(acqActWrp.discount.debit.itemizeType.value));
                }
                htmlBody = htmlBody.replace('{!DPMX.credit}', DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.credit));
                htmlBody = htmlBody.replace('{!DPMX.International}', DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.international));
                if(acqActWrp.yieldPercentage > '0'){
                    htmlBody = htmlBody.replace('{!DPMX.Resultado}', Label.DPMX_Profitable);
                }else{
                    htmlBody = htmlBody.replace('{!DPMX.Resultado}', Label.DPMX_NoProfitable);
                }
                htmlBody = htmlBody.replace('{!DPMX.Rentabilidad}', DPMX_Utils.returnIsPercent(acqActWrp.yieldPercentage));
                htmlBody = htmlBody.replace('{!DPMX.BAI}', DPMX_Utils.returnCurrency(acqActWrp.taxAcquirer.amount));

                //Fecha ultimo mes del cliente
                htmlBody = htmlBody.replace('{!DPMX.Date}', acqActWrp.informationDate);

                //Resumen de información del último mes
                htmlBody = htmlBody.replace('{!DPMX.monetaryCeiling}', DPMX_Utils.returnCurrency(acqActWrp.discount.monetaryCeiling.amount));
                htmlBody = htmlBody.replace('{!DPMX.extraBilling}', DPMX_Utils.returnCurrency(acqActWrp.commission.extraBilling.amount));
                htmlBody = htmlBody.replace('{!DPMX.billing}', DPMX_Utils.returnCurrency(acqActWrp.commission.billing.amount));
                htmlBody = htmlBody.replace('{!DPMX.cellnet}', DPMX_Utils.returnCurrency(acqActWrp.commission.cellnet.amount));
                htmlBody = htmlBody.replace('{!DPMX.totalAmount}', DPMX_Utils.returnCurrency(acqActWrp.expenses.totalAmount.amount));
                htmlBody = htmlBody.replace('{!DPMX.mit}', DPMX_Utils.returnCurrency(acqActWrp.expenses.mit.amount));
            }
             htmlBody = htmlBody.replace('{!DPMX.familia__c}', dynamicPricing.familia__c);
             htmlBody = htmlBody.replace('{!consultDate}', consultDate);

             if(isLastMonthTab && !dynamicPricing.isCustom__c){
                //Tasa seleccionada
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.debitSel}', DPMX_Utils.returnCurrency(dynamicPricing.debitLastMonth__c));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.debitSel}', DPMX_Utils.returnIsPercent(dynamicPricing.debitLastMonth__c));
                }
                htmlBody = htmlBody.replace('{!DPMX.creditSel}', DPMX_Utils.returnIsPercent(dynamicPricing.CreditLastMonth__c));
                htmlBody = htmlBody.replace('{!DPMX.InternationalSel}', DPMX_Utils.returnIsPercent(dynamicPricing.IntLastMonth__c));
                if(dynamicPricing.resultLastMonth__c == 'Break even' || dynamicPricing.resultLastMonth__c == 'BREAK_EVEN'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'BREAK EVEN');
                }else if(dynamicPricing.resultLastMonth__c == 'GOOD'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Bueno');
                }else if(dynamicPricing.resultLastMonth__c == 'OPTIMAL'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Optimo');
                }else if(dynamicPricing.resultLastMonth__c == 'Minimo viable'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Minimo viable');
                }else{
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Simulación');
                }
                htmlBody = htmlBody.replace('{!DPMX.RentabilidadSel}', DPMX_Utils.returnIsPercent(dynamicPricing.RentabildiadLastMonth__c.setScale(2)));
                htmlBody = htmlBody.replace('{!DPMX.BAISel}', DPMX_Utils.returnCurrency(dynamicPricing.baiLastMonth__c.setScale(2)));

                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.own}', (acqActWrp.transaction_y.debit.own + acqActWrp.transaction_y.debit.thirdParty)+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.own}', DPMX_Utils.returnCurrency(acqActWrp.billing.debit.own.amount + acqActWrp.billing.debit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.own}', DPMX_Utils.returnCurrency(acqActWrp.tickets.debit.own.amount + acqActWrp.tickets.debit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.own}', DPMX_Utils.returnIsPercent2(acqActWrp.percentage.debit.mixOwn + acqActWrp.percentage.debit.mixExternal));

                //Info cliente - Debito ajeno - No se usa
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.thirdParty}', acqActWrp.transaction_y.debit.thirdParty+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.thirdParty}', DPMX_Utils.returnCurrency(acqActWrp.billing.debit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.thirdParty}', DPMX_Utils.returnCurrency(acqActWrp.tickets.debit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.thirdParty}', DPMX_Utils.returnIsPercent2(acqActWrp.percentage.debit.mixExternal));

                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.own}', (acqActWrp.transaction_y.credit.own + acqActWrp.transaction_y.credit.thirdParty)+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.own}', DPMX_Utils.returnCurrency(acqActWrp.billing.credit.own.amount + acqActWrp.billing.credit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.own}', DPMX_Utils.returnCurrency(acqActWrp.tickets.credit.own.amount + acqActWrp.tickets.credit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.own}',DPMX_Utils.returnIsPercent2(acqActWrp.percentage.credit.mixOwn + acqActWrp.percentage.credit.mixExternal));

                //Info cliente - credit ajeno - No se usa
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.thirdParty}', acqActWrp.transaction_y.credit.thirdParty+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.thirdParty}', DPMX_Utils.returnCurrency(acqActWrp.billing.credit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.thirdParty}', DPMX_Utils.returnCurrency(acqActWrp.tickets.credit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.thirdParty}', DPMX_Utils.returnIsPercent2(acqActWrp.percentage.credit.mixExternal));

                //Info cliente - international
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.international}', acqActWrp.transaction_y.international+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.international}', DPMX_Utils.returnCurrency(acqActWrp.billing.international.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.international}', DPMX_Utils.returnCurrency(acqActWrp.tickets.international.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.international}', DPMX_Utils.returnIsPercent2(acqActWrp.percentage.mixInternational));

                //Info cliente - total
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.total}', acqActWrp.transaction_y.acquirerAffiliation+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.total}', DPMX_Utils.returnCurrency(acqActWrp.billing.totalAmount.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.total}', DPMX_Utils.returnCurrency(acqActWrp.tickets.totalAmount.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.total}', DPMX_Utils.returnIsPercent2(acqActWrp.percentage.total));

                //Dispositivos simulados
                htmlBody = htmlBody.replace('{!DPMX.terminal}', acqActWrp.terminal.id_y+'');
                htmlBody = htmlBody.replace('{!DPMX.pinPads}', acqActWrp.devices.pinPads.pinPadsNumber+'');
                if(acqActWrp.ecommerce == 'N'){
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'No');
                }else {
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'Si');
                }
                htmlBody = htmlBody.replace('{!DPMX.devicesNumber}', acqActWrp.devices.devicesNumber+'');

                //Comisiones simuladas 
                htmlBody = htmlBody.replace('{!DPMX.extraBillingSim}',  DPMX_Utils.returnCurrency(acqActWrp.commission.billing.amount));
                htmlBody = htmlBody.replace('{!DPMX.cellnetSim}',  DPMX_Utils.returnCurrency(acqActWrp.commission.extraBilling.amount));
                htmlBody = htmlBody.replace('{!DPMX.billingSim}',  DPMX_Utils.returnCurrency(acqActWrp.commission.cellnet.amount));

                //Tasas descuento propuestas
                acqActFeesWrp = DPMX_Container_Ctrl.calculatedBaiRentForFees(dynamicPricing.acquirerFees_JSON__c, recordId, acqActWrp, interchangeRates);

                list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> scenariosArry = new  list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'BREAK_EVEN') {
                        scenariosArry.add(acqActFeesWrp.scenarios[i]);
                    }
                }

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'Minimo viable') {
                        scenariosArry.add(acqActFeesWrp.scenarios[i]);
                    }
                }

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'GOOD') {
                        scenariosArry.add(acqActFeesWrp.scenarios[i]);
                    }
                }

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType != 'BREAK_EVEN') {
                        if (acqActFeesWrp.scenarios[i].scenarioType != 'Minimo viable') {
                            if (acqActFeesWrp.scenarios[i].scenarioType != 'GOOD') {
                                scenariosArry.add(acqActFeesWrp.scenarios[i]);
                            }
                        }
                    }
                }
                
                //Scenarios
                String scenarios = '';
                String titles = '<tr Style="background-color: #eeeeee;"> <td> <p class="HeadboardTitlePadding-left">Débito</p> </td> <td> <p class="HeadboardTitle">Crédito</p> </td> <td> <p class="HeadboardTitle">Internacional</p> </td> <td> <p class="HeadboardTitle">Resultado</p> </td> <td> <p class="HeadboardTitle">Rentabilidad</p> </td> <td> <p class="HeadboardTitle">BAI</p> </td> </tr>';
                String content = '';
                String debitStr = '';
                String creditStr = '';
                String internationalStr = '';
                String result = '';
                String rent = '';
                String bai = '';
                for (Integer i = 0; i != (scenariosArry).size(); i++) {
                    scenarios = scenarios + titles;
                    if(scenariosArry[i].scenarioType == 'GOOD'){
                        result = 'Bueno';
                        scenariosArry[i].scenarioType = 'Bueno';
                    }else if(scenariosArry[i].scenarioType == 'OPTIMAL'){
                        result = 'Optimo';
                        scenariosArry[i].scenarioType = 'Optimo';
                    }else if(scenariosArry[i].scenarioType == 'BREAK_EVEN'){
                        result = 'Break even';
                        scenariosArry[i].scenarioType = 'Break even';
                    }else if(scenariosArry[i].scenarioType == 'Minimo viable'){
                        result = 'Minimo viable';
                        scenariosArry[i].scenarioType = 'Minimo viable';
                    }

                    for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                        switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                            when 'DEBIT' {		
                                if(dynamicPricing.familia__c == Label.DPMX_GS){
                                    debitStr = DPMX_Utils.returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                                }else{
                                    debitStr = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                                }
                            }	
                            when 'CREDIT' {		
                                creditStr = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                            when 'INTERNATIONAL' {		
                                internationalStr = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }
                    }
                    rent = DPMX_Utils.returnIsPercent(scenariosArry[i].fees.profitability.percentage);
                    bai = DPMX_Utils.returnCurrency(scenariosArry[i].fees.profitability.amount.amount);
                    content = '<tr> <td> <p class="padding-left">'+debitStr+'</p> </td> <td> <p>'+creditStr+'</p> </td> <td> <p>'+internationalStr+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+rent+'</p> </td> <td> <p>'+bai+'</p> </td> </tr>';
                    scenarios = scenarios + content;
                }
                htmlBody = htmlBody.replace('{!DPMX.scenario}', scenarios);

                //Scenario propio                
                string debitPropio = '';
                decimal profitabilityRates = dynamicPricing.CustomAcquiredFeesRent__c;
                decimal profitAmount = dynamicPricing.CustomAcquiredFeesBai__c;

                //acqActFeesWrp
                double optRat = 0;
                double goodRat = 0;
                double brkRat = 0;

                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'OPTIMAL') {
                        if (optRat == 0 || optRat > acqActFeesWrp.scenarios[i].fees.profitability.percentage) {
                            optRat = acqActFeesWrp.scenarios[i].fees.profitability.percentage;
                        }
                    } else if (acqActFeesWrp.scenarios[i].scenarioType == 'GOOD') {
                        if (goodRat == 0 || goodRat > acqActFeesWrp.scenarios[i].fees.profitability.percentage) {
                            goodRat = acqActFeesWrp.scenarios[i].fees.profitability.percentage;
                        }
                    } else {
                        if (brkRat == 0 || brkRat > acqActFeesWrp.scenarios[i].fees.profitability.percentage) {
                            brkRat = acqActFeesWrp.scenarios[i].fees.profitability.percentage;
                        }
                    }
                }

                result = dynamicPricing.resultTasaEdit__c;
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    debitPropio = DPMX_Utils.returnCurrency(dynamicPricing.CustomAcquiredFeesDebit__c);
                }else{
                    debitPropio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesDebit__c);
                }

                scenarios = '';
                content = '<tr> <td> <p class="padding-left">'+debitPropio+'</p> </td> <td> <p>'+DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesCredit__c)+'</p> </td> <td> <p>'+DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesInternational__c)+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+DPMX_Utils.returnIsPercent(profitabilityRates.setscale(2))+'</p> </td> <td> <p>'+DPMX_Utils.returnCurrency(profitAmount.setscale(2))+'</p> </td> </tr>';
                scenarios = titles + content;

                htmlBody = htmlBody.replace('{!DPMX.scenarioPropio}', scenarios);

                //Oportunidades
                htmlBody = htmlBody.replace('{!DPMX.oppPosExtra}', DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.posExtra.amount));
                htmlBody = htmlBody.replace('{!DPMX.oppCallnet}', DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.cellnet.amount));
                htmlBody = htmlBody.replace('{!DPMX.oppLowBilling}', DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.lowBilling.amount));

                //Referencias Gastos (ya tenemos anteriormente los gastos totales y los MID y eBind)
                htmlBody = htmlBody.replace('{!DPMX.totalAmountSim}', DPMX_Utils.returnCurrency(acqActWrp.expenses.totalAmount.amount));
                // Calculate Basis points gastos
                if (acqActWrp.ecommerce != 'N' &&
                (acqActWrp.terminal.id_y == 0 || acqActWrp.terminal.id_y == null) &&
                (acqActWrp.Devices.PinPads.pinPadsNumber == 0 || acqActWrp.Devices.PinPads.pinPadsNumber == null) &&
                (acqActWrp.Devices.devicesNumber == 0 || acqActWrp.Devices.devicesNumber == null)) {
                        acqActWrp.basisPoints = '15';
                }else {
                    acqActWrp.basisPoints = '26';
                }
                htmlBody = htmlBody.replace('{!DPMX.basisPoints}', acqActWrp.basisPoints+' BPS');

                //Intercambio
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.discountRates.debit}', DPMX_Utils.returnCurrency(interchangeRates.debit));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.discountRates.debit}', DPMX_Utils.returnIsPercent(interchangeRates.debit));
                }
                
                htmlBody = htmlBody.replace('{!DPMX.discountRates.credit}', DPMX_Utils.returnIsPercent(interchangeRates.credit));
                htmlBody = htmlBody.replace('{!DPMX.discountRates.International}', DPMX_Utils.returnIsPercent(interchangeRates.international));

                //Tasas de descuento máximas
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!v.DPMX_discountRates_debit}', DPMX_Utils.returnCurrency(discountRates.debit));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!v.DPMX_discountRates_debit}', DPMX_Utils.returnCurrency(discountRates.debit));
                }
                
                htmlBody = htmlBody.replace('{!v.DPMX_discountRates_credit}', DPMX_Utils.returnCurrency(discountRates.credit));
                htmlBody = htmlBody.replace('{!v.DPMX_discountRates_International}', DPMX_Utils.returnIsPercent(discountRates.international));

                //Descuento Maximo
                htmlBody = htmlBody.replace('{!DPMX.DescuentoMaximo}', DPMX_Utils.returnIsPercent(acqActWrp.discount.monetaryCeiling.amount));

            }else if(isSimulationTab || dynamicPricing.isCustom__c){
                //Tasa seleccionada
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.debitSel}', DPMX_Utils.returnCurrency(dynamicPricing.debitSim__c));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.debitSel}', DPMX_Utils.returnIsPercent(dynamicPricing.debitSim__c));
                }
                htmlBody = htmlBody.replace('{!DPMX.creditSel}', DPMX_Utils.returnIsPercent(dynamicPricing.creditSim__c));
                htmlBody = htmlBody.replace('{!DPMX.InternationalSel}', DPMX_Utils.returnIsPercent(dynamicPricing.interSim__c));
                if(dynamicPricing.resultSim__c == 'Break even' || dynamicPricing.resultSim__c == 'BREAK_EVEN'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'BREAK EVEN');
                }else if(dynamicPricing.resultSim__c == 'GOOD'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Bueno');
                }else if(dynamicPricing.resultSim__c == 'OPTIMAL'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Optimo');
                }else if(dynamicPricing.resultLastMonth__c == 'Minimo viable'){
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Minimo viable');
                }else{
                    htmlBody = htmlBody.replace('{!DPMX.ResultadoSel}', 'Simulación');
                }
                htmlBody = htmlBody.replace('{!DPMX.RentabilidadSel}', DPMX_Utils.returnIsPercent(dynamicPricing.RentabildiadSim__c.setScale(2)));
                htmlBody = htmlBody.replace('{!DPMX.BAISel}', DPMX_Utils.returnCurrency(dynamicPricing.baiSim__c.setScale(2)));
                //Info cliente - Debito propio
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.own}', dynamicPricing.Sim_Transaction_Debit_Own__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.own}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Debit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.own}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Debit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.own}', DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixOwn__c.setscale(2)));

                //Info cliente - Debito ajeno
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.thirdParty}', dynamicPricing.Sim_Transaction_Debit_ThirdParty__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.thirdParty}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Debit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.thirdParty}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Debit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.thirdParty}', DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixExternal__c.setscale(2)));

                //Info cliente - credit propio
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.own}', dynamicPricing.Sim_Transaction_Credit_Own__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.own}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Credit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.own}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Credit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.own}', DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixOwn__c.setscale(2)));

                //Info cliente - credit ajeno
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.thirdParty}', dynamicPricing.Sim_Transaction_Credit_ThirdParty__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.thirdParty}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Credit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.thirdParty}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Credit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.thirdParty}', DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixExternal__c.setscale(2)));

                //Info cliente - international
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.international}',  dynamicPricing.Sim_Transaction_International__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.international}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_International_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.international}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_International_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.international}', DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_MixInternational__c.setscale(2)));

                //Info cliente - total
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.total}', dynamicPricing.Sim_Transaction_AcquirerAffiliation__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.total}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_TotalAmount_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.total}', DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_TotalAmount_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.total}', DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Total__c.setscale(2)));

                //Dispositivos simulados//Oportunidades
                htmlBody = htmlBody.replace('{!DPMX.oppPosExtra}', DPMX_Utils.returnCurrency(416.44));
                if (dynamicPricing.Sim_Terminal_Id__c > 0) {
                    htmlBody = htmlBody.replace('{!DPMX.oppCallnet}', DPMX_Utils.returnCurrency((dynamicPricing.Sim_Terminal_Id__c - 1) * Integer.valueOf(System.Label.DPMX_CommissionTPV)));
                }else{
                    htmlBody = htmlBody.replace('{!DPMX.oppCallnet}', DPMX_Utils.returnCurrency(0));
                }
                
                htmlBody = htmlBody.replace('{!DPMX.oppLowBilling}', DPMX_Utils.returnCurrency(0.42));

                htmlBody = htmlBody.replace('{!DPMX.terminal}', dynamicPricing.Sim_Terminal_Id__c+'');
                if(dynamicPricing.Sim_PinPadsInfo_PinPads__c == null){
                    htmlBody = htmlBody.replace('{!DPMX.pinPads}', dynamicPricing.pinPadsInfo_withoutPinPads__c+'');
                }else{
                    htmlBody = htmlBody.replace('{!DPMX.pinPads}', dynamicPricing.Sim_PinPadsInfo_PinPads__c+'');
                }

                if(!dynamicPricing.Sim_Ecommerce__c){
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'No');
                }else {
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'Si');
                }
                htmlBody = htmlBody.replace('{!DPMX.devicesNumber}', dynamicPricing.Sim_DevicesInfo_Devices__c+'');

                //Comisiones simuladas - Se recogen antes DPMX.extraBilling, DPMX.billing, DPMX.cellnet
                if (dynamicPricing.Sim_Fees_Billing_Checkbox__c) {
                    htmlBody = htmlBody.replace('{!DPMX.extraBillingSim}', DPMX_Utils.returnCurrency(416.44));
                } else {
                    htmlBody = htmlBody.replace('{!DPMX.extraBillingSim}', DPMX_Utils.returnCurrency(0));
                }

                decimal nTPV = 0;
                nTPV = dynamicPricing.Sim_Terminal_Id__c;
                if(dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c){
                    if (nTPV > 0) {
                        nTPV = (nTPV - 1) * Integer.valueOf(System.Label.DPMX_CommissionTPV);
                        htmlBody = htmlBody.replace('{!DPMX.cellnetSim}', DPMX_Utils.returnCurrency(nTPV));
                    }else{
                        htmlBody = htmlBody.replace('{!DPMX.cellnetSim}', DPMX_Utils.returnCurrency(0));
                    }
                }else{
                    htmlBody = htmlBody.replace('{!DPMX.cellnetSim}', DPMX_Utils.returnCurrency(0));
                }

                if (dynamicPricing.Sim_Fees_Cellnet_Checkbox__c) {
                    htmlBody = htmlBody.replace('{!DPMX.billingSim}', DPMX_Utils.returnCurrency(0.42));
                } else {
                    htmlBody = htmlBody.replace('{!DPMX.billingSim}', DPMX_Utils.returnCurrency(0));
                }

                //Tasas descuento propuestas
                //Buscar wrappers necesarios para el calculo de rentabilidad y bai
                //Buscar el wrapper validate y agregle orden de break even a optimo
                integer i = 0;
                integer z = 0;
                integer q = 0;
                integer orderIdProp = 0;
                integer orderIdItem = 0;
                boolean goodScenarioExist = false;
                boolean goodTwoScenarioExist = false;
                boolean optimalScenarioExist = false;
                dynamicPricing.gastoTotal__c = validateResponseWrapper.proposed[0].amount.amount;
                Map<String,Object> baiMAP = new Map<String,Object>();
                decimal debitVal = 0;
                decimal creditVal = 0;
                decimal internationalVal = 0;
                DPMX_ValidateResponse_Wrapper.Amount amountResponse = new DPMX_ValidateResponse_Wrapper.Amount();
                for(i = 0; i != validateResponseWrapper.proposed.size(); i++){
                    if(validateResponseWrapper.proposed[i].scenaryType == 'BREAK_EVEN' || validateResponseWrapper.proposed[i].scenaryType == 'Minimo viable'){
                        validateResponseWrapper.proposed[i].idOrder = 0;
                        validateResponse.proposed.set(0, validateResponseWrapper.proposed[i]);
                    }else if(validateResponseWrapper.proposed[i].scenaryType == 'GOOD'){
                        if(goodScenarioExist){
                            validateResponseWrapper.proposed[i].idOrder = 2;
                            validateResponse.proposed.set(2, validateResponseWrapper.proposed[i]);
                            goodTwoScenarioExist = true;
                        }else {
                            validateResponseWrapper.proposed[i].idOrder = 1;
                            validateResponse.proposed.set(1, validateResponseWrapper.proposed[i]);
                            goodScenarioExist = true;
                        }
                    }
                    for(z = 0; z != validateResponseWrapper.proposed[i].rate.itemizeRates.size(); z++){
                        if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'DEBIT_DISCOUNT'){
                            if(dynamicPricing.familia_AcquiererCategories_Id__c == '13'){
                                debitVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.amount;
                            }else{
                                debitVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            }
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'CREDIT_DISCOUNT'){
                            creditVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL_DISCOUNT'){
                            internationalVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                        }
                        if(debitVal != null && debitVal != 0 && creditVal != null && creditVal != 0 && internationalVal != null && internationalVal != 0){
                            baiMAP = DPMX_Container_Ctrl.updateRates(recordId, acqActWrp, interchangeRates, false, creditVal, debitVal, internationalVal, true, dynamicPricing.gastoTotal__c);
                            amountResponse.amount = (decimal) baiMAP.get('profitAmount');
                            amountResponse.currency_y = 'MXN';
                            validateResponseWrapper.proposed[i].amount = amountResponse;
                            for(q = 0; q != validateResponseWrapper.proposed[i].rate.itemizeRates.size(); q++){
                                if(validateResponseWrapper.proposed[i].rate.itemizeRates[q].rateType == 'RETURN'){
                                    validateResponseWrapper.proposed[i].rate.itemizeRates[q].itemizeRatesUnit.percentage = (decimal) baiMAP.get('profitability');
                                }
                            }
                        }
                        if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'DEBIT_DISCOUNT'){
                            debitVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 0;
                            itemLst.set(0, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'CREDIT_DISCOUNT'){
                            creditVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 1;
                            itemLst.set(1, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL_DISCOUNT'){
                            internationalVal = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 2;
                            itemLst.set(2, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'RETURN'){
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 3;
                            itemLst.set(3, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }
                    }
                    validateResponse.proposed[i].rate.itemizeRates = itemLst;
                    itemLst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
                    debitVal = 0;
                    debitVal = 0;
                    internationalVal = 0;
                    baiMAP.clear();
                    amountResponse = new DPMX_ValidateResponse_Wrapper.Amount();
                }
                for(i = 0; i != validateResponseWrapper.proposed.size(); i++){
                    if(validateResponseWrapper.proposed[i].scenaryType == 'OPTIMAL'){
                        if(optimalScenarioExist){
                            if(goodTwoScenarioExist){
                                validateResponseWrapper.proposed[i].idOrder = 4;
                                validateResponse.proposed.set(4, validateResponseWrapper.proposed[i]);
                            }else {
                                validateResponseWrapper.proposed[i].idOrder = 3;
                                validateResponse.proposed.set(3, validateResponseWrapper.proposed[i]);
                            }
                            
                        }else {
                            if(goodTwoScenarioExist){
                                validateResponseWrapper.proposed[i].idOrder = 3;
                                validateResponse.proposed.set(3, validateResponseWrapper.proposed[i]);
                            }else {
                                validateResponseWrapper.proposed[i].idOrder = 2;
                                validateResponse.proposed.set(2, validateResponseWrapper.proposed[i]);
                            }
                            optimalScenarioExist = true; 
                        }
                    }
                }

                //Scenarios
                String scenarios = '';
                String titles = '<tr Style="background-color: #eeeeee;"> <td> <p class="HeadboardTitlePadding-left">Débito</p> </td> <td> <p class="HeadboardTitle">Crédito</p> </td> <td> <p class="HeadboardTitle">Internacional</p> </td> <td> <p class="HeadboardTitle">Resultado</p> </td> <td> <p class="HeadboardTitle">Rentabilidad</p> </td> <td> <p class="HeadboardTitle">BAI</p> </td> </tr>';
                String content = '';
                String debitStr = '';
                String creditStr = '';
                String internationalStr = '';
                String result = '';
                String rent = '';
                String bai = '';
                system.debug(validateResponse);
                system.debug(validateResponse.proposed.size());
                for (i = 0; i != validateResponse.proposed.size(); i++) {
                    Map<String,String> scenarioMap =  new Map<String,String>();
                    system.debug(validateResponse.proposed[i].scenaryType);
                    if (validateResponse.proposed[i].scenaryType == 'OPTIMAL') {
                        result = 'Optimo';
                    } else if (validateResponse.proposed[i].scenaryType == 'GOOD') {
                         result = 'Bueno';
                    } else if(validateResponse.proposed[i].scenaryType == 'Minimo viable'){
                        result = 'Minimo viable';
                    }else {
                         result = 'Break even';
                    }
                    system.debug(validateResponse.proposed[i].rate.itemizeRates.size());
                    for(z = 0; z != validateResponse.proposed[i].rate.itemizeRates.size(); z++){
                        system.debug(validateResponse.proposed[i].rate.itemizeRates[z].idOrder);
                        switch on (validateResponse.proposed[i].rate.itemizeRates[z].idOrder) {
                            when (0){
                                if (dynamicPricing.familia_AcquiererCategories_Id__c == '13') {
                                    debitStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.amount+'';
                                } else {
                                    debitStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                                }
                            }
                            when (1){
                                creditStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                            }
                            when (2){
                                internationalStr = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                            }
                            when (3){
                                rent = validateResponse.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage+'';
                            }
                        }
                    }
                    bai = validateResponse.proposed[i].amount.amount+'';
                    system.debug(debitStr);
                    system.debug(creditStr);
                    system.debug(internationalStr);
                    system.debug(rent);
                    system.debug(bai);
                    system.debug(result);
                    content = '<tr> <td> <p class="padding-left">'+debitStr+'</p> </td> <td> <p>'+creditStr+'</p> </td> <td> <p>'+internationalStr+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+rent+'</p> </td> <td> <p>'+bai+'</p> </td> </tr>';
                    scenarios = scenarios + content;
                }
                htmlBody = htmlBody.replace('{!DPMX.scenario}', scenarios); 
                string debitPropio = '';
                result = dynamicPricing.resultTasaEditSim__c;
                decimal profitabilityRates = dynamicPricing.CustomSimulatedRent__c;
                decimal profitAmount = dynamicPricing.CustomSimulatedBai__c;
                
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    debitPropio = DPMX_Utils.returnCurrency(dynamicPricing.CustomSimulatedDebit__c);
                }else{
                    debitPropio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedDebit__c);
                }
                scenarios = '';
                content = '<tr> <td> <p class="padding-left">'+debitPropio+'</p> </td> <td> <p>'+DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedCredit__c)+'</p> </td> <td> <p>'+DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedInternational__c)+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+DPMX_Utils.returnIsPercent(profitabilityRates.setscale(2))+'</p> </td> <td> <p>'+DPMX_Utils.returnCurrency(profitAmount.setscale(2))+'</p> </td> </tr>';
                scenarios = titles + content;
                htmlBody = htmlBody.replace('{!DPMX.scenarioPropio}', scenarios);

                if(!dynamicPricing.isCustom__c){
                    //Intercambio
                    if(dynamicPricing.familia__c == Label.DPMX_GS){
                        acqActWrp.isGS = true;
                        htmlBody = htmlBody.replace('{!DPMX.discountRates.debit}', DPMX_Utils.returnCurrency(interchangeRates.debit));
                    }else{
                        acqActWrp.isGS = false;
                        htmlBody = htmlBody.replace('{!DPMX.discountRates.debit}', DPMX_Utils.returnIsPercent(interchangeRates.debit));
                    }
                    
                    htmlBody = htmlBody.replace('{!DPMX.discountRates.credit}', DPMX_Utils.returnIsPercent(interchangeRates.credit));
                    htmlBody = htmlBody.replace('{!DPMX.discountRates.International}', DPMX_Utils.returnIsPercent(interchangeRates.international));
                    //Tasas máximas de descuento
                    if(dynamicPricing.familia__c == Label.DPMX_GS){
                        acqActWrp.isGS = true;
                        htmlBody = htmlBody.replace('{!v.DPMX_discountRates_debit}', DPMX_Utils.returnCurrency(discountRates.debit));
                    }else{
                        acqActWrp.isGS = false;
                        htmlBody = htmlBody.replace('{!v.DPMX_discountRates_debit}', DPMX_Utils.returnCurrency(discountRates.debit));
                    }
                    
                    htmlBody = htmlBody.replace('{!v.DPMX_discountRates_credit}', DPMX_Utils.returnCurrency(discountRates.credit));
                    htmlBody = htmlBody.replace('{!v.DPMX_discountRates_International}', DPMX_Utils.returnIsPercent(discountRates.international));

                    //Descuento Maximo
                    htmlBody = htmlBody.replace('{!DPMX.DescuentoMaximo}', DPMX_Utils.returnIsPercent(acqActWrp.discount.monetaryCeiling.amount));
                }

                //Referencias Gastos (ya tenemos anteriormente los gastos totales y los MID y eBind)
                htmlBody = htmlBody.replace('{!DPMX.totalAmountSim}', DPMX_Utils.returnCurrency(dynamicPricing.gastoTotal__c));
                // Calculate Basis points gastos

                htmlBody = htmlBody.replace('{!DPMX.basisPoints}', dynamicPricing.basisPoint__c+' BPS');

                //Tasas de descuento máximas
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.interchangeRates.debit}', DPMX_Utils.returnCurrency(interchangeRates.debit));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.interchangeRates.debit}', DPMX_Utils.returnIsPercent(interchangeRates.debit));
                }
                
                htmlBody = htmlBody.replace('{!DPMX.interchangeRates.credit}', DPMX_Utils.returnIsPercent(interchangeRates.credit));
                htmlBody = htmlBody.replace('{!DPMX.interchangeRates.International}', DPMX_Utils.returnIsPercent(interchangeRates.international));
            }
        }
        if(isLastMonthTab){
            htmlBody = htmlBody.replace('{!DPMX.tab}', 'Tasas de descuento pactadas en la última negociación');
        }else{
            htmlBody = htmlBody.replace('{!DPMX.tab}', 'Información simulada del cliente');
        }
        

        if(sendReport){
            htmlBody = htmlBody.replace('{!DPMX.tasasTable}', '');

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemp.Id);
            mail.setTargetObjectId(dynamicPricing.OwnerId);
            mail.setCcAddresses(sendCC);
            mail.setHtmlBody(htmlBody);
            mail.setSaveAsActivity(false);
            mail.setSubject(asunto);
            emailList.add(mail);
            
            if(Test.isRunningTest()){
                status = 'Verificacion de envio de email para classes test.';
            	sendReport = true;  
            }else  if(!emailList.isEmpty()){
                Messaging.sendEmail(emailList);
            }else {
                status = 'fail send report';
            }
        }
        retMap.put('sendReport', sendReport);
        retMap.put('status', status);
        return retMap;
    }

    private static string returnCurrency (decimal value) {
        string strReturn = value + ' MXN';
        return strReturn;
    }

    private static string returnIsPercent (decimal value) {
        string strReturn = value + '%';
        return strReturn;
    }

    private static string returnIsPercent (string value) {
        value = value + '%';
        return value;
    }

    private static string returnIsPercent2 (decimal value) {
        string strReturn = (value*100) + '%';
        return strReturn;
    }

    private static Boolean returnAuthIsAccepted (string recordId, string debit, string credit, string international) {
        Boolean authIsAccepted = false;

        list<DPMX_authorization__c> authLst = [SELECT Name, LKP_Dynamic_Pricing__r.Name, OwnerFullName__c, STR_AuthBai__c, 
        STR_AuthCredit__c, STR_AuthDebit__c, STR_AuthInternational__c, STR_AuthProfitability__c, STR_AuthResult__c, isGs__c, Status__c
        FROM DPMX_authorization__c
        WHERE LKP_Dynamic_Pricing__r.Id =:recordId
        AND STR_AuthDebit__c =: debit
        AND STR_AuthCredit__c =: credit
        AND STR_AuthInternational__c =: international
        AND Status__c = 'Aceptado'
        LIMIT 1
        ];
        if(authLst.size() > 0 ){
            authIsAccepted = true;
        }
        return authIsAccepted;
    }
}