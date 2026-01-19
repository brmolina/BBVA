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
public class DPMX_SendReport_ctrl {
/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_SendReport_ctrl() {

    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        final Map<String, Object> responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquiererActy_JSON__c);
        final List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMapAcqAct.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
        DPMX_AcquirerActivities_Wrapper acqActWrp = acquirerActivitiesWrapperLst[0];
        final Map<String, Object> responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquirerFees_JSON__c);
        final DPMX_AcquirerActivitiesFees_Wrapper acqActFeesWrp = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMapAcqFee.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
        final Map<String, Object> responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.corporateRates_JSON__c);
        final List<DPMX_CorporateRates_Wrapper> corpRatWrp = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMapCopRat.get('data')), List<DPMX_CorporateRates_Wrapper>.class);
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
        String DPMX_totalAmount;
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

        //información HTML simular email

            //Header
            DPMX_Company_Name =  dynamicPricing.Company_Name__r.Name;
            DPMX_familia =  dynamicPricing.familia__c;
            Local_Client__c localClient = DPMX_Utils.Local_ClientSelector(dynamicPricing.Company_Name__c);
            DPMX_NumeroCliente = localClient.unique_id__c;
            //Body
            //Tasas descuento actuales
            if(dynamicPricing.familia__c == Label.DPMX_GS){
                acqActWrp.isGS = true;
                DPMX_debit =  returnCurrency(acqActWrp.discount.debit.itemizeType.amount);
            }else{
                acqActWrp.isGS = false;
                DPMX_debit =  returnIsPercent(acqActWrp.discount.debit.itemizeType.value);
            }
            DPMX_credit = returnIsPercent(acqActWrp.discount.percentage.credit);
            DPMX_International = returnIsPercent(acqActWrp.discount.percentage.international);
            DPMX_Resultado = dynamicPricing.familia__c;
            DPMX_Rentabilidad = returnIsPercent(acqActWrp.yieldPercentage);
            DPMX_BAI = returnCurrency(acqActWrp.taxAcquirer.amount);
            //Fecha ultimo mes del cliente
            DPMX_Date =  acqActWrp.informationDate;
            //Resumen de información del último mes
            DPMX_monetaryCeiling =  returnCurrency(acqActWrp.discount.monetaryCeiling.amount);
            DPMX_extraBilling=  returnCurrency(acqActWrp.commission.extraBilling.amount);
            DPMX_billing=  returnCurrency(acqActWrp.commission.billing.amount);
            DPMX_cellnet=  returnCurrency(acqActWrp.commission.cellnet.amount);
            DPMX_totalAmount=  returnCurrency(acqActWrp.expenses.totalAmount.amount);
            DPMX_mit=  returnCurrency(acqActWrp.expenses.mit.amount);

            if(IsLastMonthTab){

                //Info cliente - Debito propio
                DPMX_transaction_y_debit_own =  acqActWrp.transaction_y.debit.own+'';
                DPMX_billing_debit_own =  returnCurrency(acqActWrp.billing.debit.own.amount);
                DPMX_tickets_debit_own =  returnCurrency(acqActWrp.tickets.debit.own.amount);
                DPMX_percentage_debit_own =  returnIsPercent2(acqActWrp.percentage.debit.mixOwn);

                //Info cliente - Debito ajeno
                DPMX_transaction_y_debit_thirdParty =  acqActWrp.transaction_y.debit.thirdParty+'';
                DPMX_billing_debit_thirdParty =  returnCurrency(acqActWrp.billing.debit.thirdParty.amount);
                DPMX_tickets_debit_thirdParty =  returnCurrency(acqActWrp.tickets.debit.thirdParty.amount);
                DPMX_percentage_debit_thirdParty =  returnIsPercent2(acqActWrp.percentage.debit.mixExternal);

                //Info cliente - credit propio
                DPMX_transaction_y_credit_own =  acqActWrp.transaction_y.credit.own+'';
                DPMX_billing_credit_own =  returnCurrency(acqActWrp.billing.credit.own.amount);
                DPMX_tickets_credit_own =  returnCurrency(acqActWrp.tickets.credit.own.amount);
                DPMX_percentage_credit_own =  returnIsPercent2(acqActWrp.percentage.credit.mixOwn);

                //Info cliente - credit ajeno
                DPMX_transaction_y_credit_thirdParty =  acqActWrp.transaction_y.credit.thirdParty+'';
                DPMX_billing_credit_thirdParty =  returnCurrency(acqActWrp.billing.credit.thirdParty.amount);
                DPMX_tickets_credit_thirdParty =  returnCurrency(acqActWrp.tickets.credit.thirdParty.amount);
                DPMX_percentage_credit_thirdParty =  returnIsPercent2(acqActWrp.percentage.credit.mixExternal);

                //Info cliente - international
                DPMX_transaction_y_international = acqActWrp.transaction_y.international+'';
                DPMX_billing_international = returnCurrency(acqActWrp.billing.international.amount);
                DPMX_tickets_international = returnCurrency(acqActWrp.tickets.international.amount);
                DPMX_percentage_international = returnIsPercent2(acqActWrp.percentage.mixInternational);

                //Info cliente - total
                DPMX_transaction_y_total = acqActWrp.transaction_y.acquirerAffiliation+'';
                DPMX_billing_total = returnCurrency(acqActWrp.billing.totalAmount.amount);
                DPMX_tickets_total = returnCurrency(acqActWrp.tickets.totalAmount.amount);
                DPMX_percentage_total = returnIsPercent2(acqActWrp.percentage.total);

                //Dispositivos simulados
                DPMX_terminal = acqActWrp.terminal.id_y+'';
                DPMX_pinPads = acqActWrp.devices.pinPads.pinPadsNumber+'';
                if(acqActWrp.ecommerce == 'N'){
                    DPMX_ecommerceCheckbox = 'No';
                }else {
                    DPMX_ecommerceCheckbox = 'Si';
                }
                DPMX_devicesNumber =  acqActWrp.devices.devicesNumber+'';

                //Comisiones simuladas - Se recogen antes DPMX_extraBilling, DPMX_billing, DPMX_cellnet

                //Tasas descuento propuestas
                list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> scenariosArry = new  list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'BREAK_EVEN') {
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
                        if (acqActFeesWrp.scenarios[i].scenarioType != 'GOOD') {
                            scenariosArry.add(acqActFeesWrp.scenarios[i]);
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
                    }

                    for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                        switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                            when 'DEBIT' {		
                                if(dynamicPricing.familia__c == Label.DPMX_GS){
                                    debitStr = returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                                }else{
                                    debitStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                                }
                            }	
                            when 'CREDIT' {		
                                creditStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                            when 'INTERNATIONAL' {		
                                internationalStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }
                    }
                    rent = returnIsPercent(scenariosArry[i].fees.profitability.percentage);
                    bai = returnCurrency(scenariosArry[i].fees.profitability.amount.amount);

                    scenarioMap.put('result', result);
                    scenarioMap.put('debit', debitStr);
                    scenarioMap.put('credit', creditStr);
                    scenarioMap.put('inter', internationalStr);
                    scenarioMap.put('rent', rent);
                    scenarioMap.put('bai', bai);
                    scenariosLst.add(scenarioMap);
                }

                //Scenario propio
                DPMX_Container_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                DPMX_Container_Ctrl.Discount_Rates_Wrapper discountRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                List<DPMX_Container_Ctrl.Company_Info> companies = new List<DPMX_Container_Ctrl.Company_Info>();
                Double debitt = dynamicPricing.CustomAcquiredFeesDebit__c;
                Double creditt = dynamicPricing.CustomAcquiredFeesCredit__c;
                Double internationalt = dynamicPricing.CustomAcquiredFeesInternational__c;

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

                if(profitabilityRates == 0 && debitt == 0 && creditt == 0 && internationalt == 0){
                    result = '---';
                } else if(profitabilityRates != 0 || debitt != 0 || creditt != 0 || internationalt != 0){
                    if (profitabilityRates >= optRat) {
                        result = 'Optimo';
                    } else if (profitabilityRates >= goodRat) {
                        result = 'Bueno';
                    } else {
                        result = 'Break even';
                    }
                } else {
                    result = '----';
                }

                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_debitPorpio = returnCurrency(dynamicPricing.CustomAcquiredFeesDebit__c);
                }else{
                    DPMX_debitPorpio = returnIsPercent(dynamicPricing.CustomAcquiredFeesDebit__c);
                }
                
                DPMX_creditPorpio = returnIsPercent(dynamicPricing.CustomAcquiredFeesCredit__c);
                DPMX_interPorpio = returnIsPercent(dynamicPricing.CustomAcquiredFeesInternational__c);
                DPMX_resultPorpio = result;
                if(profitabilityRates != null){
                    DPMX_rentPorpio = returnIsPercent(profitabilityRates.setscale(2));
                    DPMX_baiPorpio = returnCurrency(profitAmount.setscale(2));
                }
                

                //Oportunidades
                DPMX_oppPosExtra = returnCurrency(acqActWrp.commission.opportunity.posExtra.amount);
                DPMX_oppCallnet = returnCurrency(acqActWrp.commission.opportunity.cellnet.amount);
                DPMX_oppLowBilling = returnCurrency(acqActWrp.commission.opportunity.lowBilling.amount);

                //Referencias Gastos (ya tenemos anteriormente los gastos totales y los MID y eBind)
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
                    DPMX_interchangeRates_debit = returnCurrency(interchangeRates.debit);
                }else{
                    DPMX_interchangeRates_debit = returnIsPercent(interchangeRates.debit);
                }
                DPMX_interchangeRates_credit = returnIsPercent(interchangeRates.credit);
                DPMX_interchangeRates_International = returnIsPercent(interchangeRates.international);

                //Intercambio
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    DPMX_discountRates_debit = returnCurrency(acqActWrp.discount.monetaryCeiling.amount);
                }else{
                    DPMX_discountRates_debit = returnIsPercent(acqActWrp.discount.monetaryCeiling.amount);
                }
                
                DPMX_discountRates_credit = returnIsPercent(acqActWrp.commission.opportunity.posExtra.amount);
                DPMX_discountRates_International = returnIsPercent(acqActWrp.discount.percentage.international);

                //Descuento Maximo
                DPMX_DescuentoMaximo = returnIsPercent(acqActWrp.discount.monetaryCeiling.amount);

                //Información Tasa selecionada
                debitTasa = dynamicPricing.debitLastMonth__c;
                creditTasa = dynamicPricing.CreditLastMonth__c;
                internationalTasa = dynamicPricing.IntLastMonth__c;

            }else if(isSimulationTab){

                //Información Tasa selecionada
                debitTasa = dynamicPricing.debitSim__c;
                creditTasa = dynamicPricing.creditSim__c;
                internationalTasa = dynamicPricing.interSim__c;

                //Info cliente - Debito propio
                DPMX_transaction_y_debit_own =  dynamicPricing.Sim_Transaction_Debit_Own__c+'';
                DPMX_billing_debit_own =  returnCurrency(dynamicPricing.Sim_Billing_Debit_Own_Amount__c);
                DPMX_tickets_debit_own =  returnCurrency(dynamicPricing.Sim_Tickets_Debit_Own_Amount__c);
                DPMX_percentage_debit_own = returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixOwn__c.setscale(2));

                //Info cliente - Debito ajeno
                DPMX_transaction_y_debit_thirdParty = dynamicPricing.Sim_Transaction_Debit_ThirdParty__c+'';
                DPMX_billing_debit_thirdParty = returnCurrency(dynamicPricing.Sim_Billing_Debit_ThirdParty_Amount__c);
                DPMX_tickets_debit_thirdParty = returnCurrency(dynamicPricing.Sim_Tickets_Debit_ThirdParty_Amount__c);
                DPMX_percentage_debit_thirdParty = returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixExternal__c.setscale(2));

                //Info cliente - credit propio
                DPMX_transaction_y_credit_own = dynamicPricing.Sim_Transaction_Credit_Own__c+'';
                DPMX_billing_credit_own = returnCurrency(dynamicPricing.Sim_Billing_Credit_Own_Amount__c);
                DPMX_tickets_credit_own = returnCurrency(dynamicPricing.Sim_Tickets_Credit_Own_Amount__c);
                DPMX_percentage_credit_own = returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixOwn__c.setscale(2));

                //Info cliente - credit ajeno
                DPMX_transaction_y_credit_thirdParty = dynamicPricing.Sim_Transaction_Credit_ThirdParty__c+'';
                DPMX_billing_credit_thirdParty = returnCurrency(dynamicPricing.Sim_Billing_Credit_ThirdParty_Amount__c);
                DPMX_tickets_credit_thirdParty = returnCurrency(dynamicPricing.Sim_Tickets_Credit_ThirdParty_Amount__c);
                DPMX_percentage_credit_thirdParty = returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixExternal__c.setscale(2));

                //Info cliente - international
                DPMX_transaction_y_international =  dynamicPricing.Sim_Transaction_International__c+'';
                DPMX_billing_international = returnCurrency(dynamicPricing.Sim_Billing_International_Amount__c);
                DPMX_tickets_international = returnCurrency(dynamicPricing.Sim_Tickets_International_Amount__c);
                DPMX_percentage_international = returnIsPercent(dynamicPricing.Sim_Percentage_MixInternational__c.setscale(2));

                //Info cliente - total
                DPMX_transaction_y_total = dynamicPricing.Sim_Transaction_AcquirerAffiliation__c+'';
                DPMX_billing_total = returnCurrency(dynamicPricing.Sim_Billing_TotalAmount_Amount__c);
                DPMX_tickets_total = returnCurrency(dynamicPricing.Sim_Tickets_TotalAmount_Amount__c);
                DPMX_percentage_total = returnIsPercent(dynamicPricing.Sim_Percentage_Total__c.setscale(2));

                //Dispositivos simulados
                DPMX_terminal = dynamicPricing.Sim_Terminal_Id__c+'';
                DPMX_pinPads = dynamicPricing.Sim_PinPadsInfo_PinPads__c+'';
                if(!dynamicPricing.Sim_Ecommerce__c){
                    DPMX_ecommerceCheckbox = 'No';
                }else {
                    DPMX_ecommerceCheckbox = 'Si';
                }
                DPMX_devicesNumber =  dynamicPricing.Sim_DevicesInfo_Devices__c+'';

                //Comisiones simuladas - Se recogen antes DPMX_extraBilling, DPMX_billing, DPMX_cellnet

                //Tasas descuento propuestas
                list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> scenariosArry = new  list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'BREAK_EVEN') {
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
                        if (acqActFeesWrp.scenarios[i].scenarioType != 'GOOD') {
                            scenariosArry.add(acqActFeesWrp.scenarios[i]);
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
                    }

                    for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                        switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                            when 'DEBIT' {		
                                if(dynamicPricing.familia__c == Label.DPMX_GS){
                                    debitStr = returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                                }else{
                                    debitStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                                }
                            }	
                            when 'CREDIT' {		
                                creditStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                            when 'INTERNATIONAL' {		
                                internationalStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }
                    }
                    rent = returnIsPercent(scenariosArry[i].fees.profitability.percentage);
                    bai = returnCurrency(scenariosArry[i].fees.profitability.amount.amount);

                    scenarioMap.put('result', result);
                    scenarioMap.put('debit', debitStr);
                    scenarioMap.put('credit', creditStr);
                    scenarioMap.put('inter', internationalStr);
                    scenarioMap.put('rent', rent);
                    scenarioMap.put('bai', bai);
                    scenariosLst.add(scenarioMap);

                    //Scenario propio
                    DPMX_Container_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                    DPMX_Container_Ctrl.Discount_Rates_Wrapper discountRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                    List<DPMX_Container_Ctrl.Company_Info> companies = new List<DPMX_Container_Ctrl.Company_Info>();
                    Double debitt = dynamicPricing.CustomSimulatedDebit__c;
                    Double creditt = dynamicPricing.CustomSimulatedCredit__c;
                    Double internationalt = dynamicPricing.CustomSimulatedInternational__c;

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

                    decimal profitabilityRates = dynamicPricing.CustomSimulatedRent__c;
                    decimal profitAmount = dynamicPricing.CustomSimulatedBai__c;

                    //acqActFeesWrp
                    double optRat = 0;
                    double goodRat = 0;
                    double brkRat = 0;

                    for (Integer x = 0; x != (acqActFeesWrp.scenarios).size(); x++) {
                        if (acqActFeesWrp.scenarios[x].scenarioType == 'OPTIMAL') {
                            if (optRat == 0 || optRat > acqActFeesWrp.scenarios[x].fees.profitability.percentage) {
                                optRat = acqActFeesWrp.scenarios[x].fees.profitability.percentage;
                            }
                        } else if (acqActFeesWrp.scenarios[x].scenarioType == 'GOOD') {
                            if (goodRat == 0 || goodRat > acqActFeesWrp.scenarios[x].fees.profitability.percentage) {
                                goodRat = acqActFeesWrp.scenarios[x].fees.profitability.percentage;
                            }
                        } else {
                            if (brkRat == 0 || brkRat > acqActFeesWrp.scenarios[x].fees.profitability.percentage) {
                                brkRat = acqActFeesWrp.scenarios[x].fees.profitability.percentage;
                            }
                        }
                    }

                    if(profitabilityRates == 0 && debitt == 0 && creditt == 0 && internationalt == 0){
                        result = '---';
                    } else if(profitabilityRates != 0 || debitt != 0 || creditt != 0 || internationalt != 0){
                        if (profitabilityRates >= optRat) {
                            result = 'Optimo';
                        } else if (profitabilityRates >= goodRat) {
                            result = 'Bueno';
                        } else {
                            result = 'Break even';
                        }
                    } else {
                        result = '----';
                    }

                    if(dynamicPricing.familia__c == Label.DPMX_GS){
                        DPMX_debitPorpio = returnCurrency(dynamicPricing.CustomSimulatedDebit__c);
                    }else{
                        DPMX_debitPorpio = returnIsPercent(dynamicPricing.CustomSimulatedDebit__c);
                    }
                    
                    DPMX_creditPorpio = returnIsPercent(dynamicPricing.CustomSimulatedCredit__c);
                    DPMX_interPorpio = returnIsPercent(dynamicPricing.CustomSimulatedInternational__c);
                    DPMX_resultPorpio = result;
                    if(profitabilityRates != null){
                        DPMX_rentPorpio = returnIsPercent(profitabilityRates.setscale(2));
                        DPMX_baiPorpio = returnCurrency(profitAmount.setscale(2));
                    }
                }

            } else {
                errorTab = true;
            }

         retMap.put('errorTab', errorTab);
        //Mensaje de error por pesntaña no adecuada
        if(errorTab){
            retMap.put('msgErrorTab', 'Para usar en envio de correo debes etar en la pestaña de "Último mes del cliente" o "Simulación".');
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
            retMap.put('DPMX_totalAmount', DPMX_totalAmount);
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

            //Envio de correo de Tasa
            retMap.put('debitTasa', debitTasa);
            retMap.put('creditTasa', creditTasa);
            retMap.put('internationalTasa', internationalTasa);
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

        decimal debitTasa;
        decimal creditTasa;
        decimal internationalTasa;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
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
        final Map<String, Object> responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquiererActy_JSON__c);
        final List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMapAcqAct.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
        DPMX_AcquirerActivities_Wrapper acqActWrp = acquirerActivitiesWrapperLst[0];
        final Map<String, Object> responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquirerFees_JSON__c);
        final DPMX_AcquirerActivitiesFees_Wrapper acqActFeesWrp = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMapAcqFee.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
        final Map<String, Object> responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.corporateRates_JSON__c);
        final List<DPMX_CorporateRates_Wrapper> corpRatWrp = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMapCopRat.get('data')), List<DPMX_CorporateRates_Wrapper>.class);
        
        if(templateName == 'DPMX_SendReportTasa'){
            if(isLastMonthTab){
                if(dynamicPricing.resultLastMonth__c == 'BREAK_EVEN' || dynamicPricing.resultLastMonth__c == 'Minimo viable'){
                    if(returnAuthIsAccepted(recordId, ''+dynamicPricing.debitLastMonth__c, ''+dynamicPricing.CreditLastMonth__c, ''+dynamicPricing.IntLastMonth__c))
                    {
                        debitTasa = dynamicPricing.debitLastMonth__c;
                        creditTasa = dynamicPricing.CreditLastMonth__c;
                        internationalTasa = dynamicPricing.IntLastMonth__c;
                    }else {
                        status = 'El break even tiene que ser aceptado para poder enviarse.';
                        sendReport = false;
                    }
                }else {
                    debitTasa = dynamicPricing.debitLastMonth__c;
                    creditTasa = dynamicPricing.CreditLastMonth__c;
                    internationalTasa = dynamicPricing.IntLastMonth__c;
                }
            }else if(isSimulationTab){
                if(dynamicPricing.resultSim__c == 'BREAK_EVEN' || dynamicPricing.resultSim__c == 'Minimo viable'){
                    if(returnAuthIsAccepted(recordId, ''+dynamicPricing.debitSim__c, ''+dynamicPricing.creditSim__c, ''+dynamicPricing.interSim__c))
                    {
                        debitTasa = dynamicPricing.debitSim__c;
                        creditTasa = dynamicPricing.creditSim__c;
                        internationalTasa = dynamicPricing.interSim__c;
                    }else {
                        status = 'El break even tiene que ser aceptado para poder enviarse.';
                        sendReport = false;
                    }
                }else {
                    debitTasa = dynamicPricing.debitSim__c;
                    creditTasa = dynamicPricing.creditSim__c;
                    internationalTasa = dynamicPricing.interSim__c;
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
            htmlBody = htmlBody.replace('{!DPMX.Company_Name__c}', dynamicPricing.Company_Name__r.Name);
            htmlBody = htmlBody.replace('{!DPMX.familia__c}', dynamicPricing.familia__c);
            Local_Client__c localClient = DPMX_Utils.Local_ClientSelector(dynamicPricing.Company_Name__c);
            htmlBody = htmlBody.replace('{!DPMX.NumeroCliente__c}', localClient.unique_id__c);
            htmlBody = htmlBody.replace('{!consultDate}', consultDate);
            //Tasas descuento actuales
            if(dynamicPricing.familia__c == Label.DPMX_GS){
                acqActWrp.isGS = true;
                htmlBody = htmlBody.replace('{!DPMX.debit}', returnCurrency(acqActWrp.discount.debit.itemizeType.amount));
            }else{
                acqActWrp.isGS = false;
                htmlBody = htmlBody.replace('{!DPMX.debit}', returnIsPercent(acqActWrp.discount.debit.itemizeType.value));
            }
            htmlBody = htmlBody.replace('{!DPMX.credit}', returnIsPercent(acqActWrp.discount.percentage.credit));
            htmlBody = htmlBody.replace('{!DPMX.International}', returnIsPercent(acqActWrp.discount.percentage.international));
            htmlBody = htmlBody.replace('{!DPMX.Resultado}', dynamicPricing.familia__c);
            htmlBody = htmlBody.replace('{!DPMX.Rentabilidad}', returnIsPercent(acqActWrp.yieldPercentage));
            htmlBody = htmlBody.replace('{!DPMX.BAI}', returnCurrency(acqActWrp.taxAcquirer.amount));

            //Fecha ultimo mes del cliente
            htmlBody = htmlBody.replace('{!DPMX.Date}', acqActWrp.informationDate);

            //Resumen de información del último mes
            htmlBody = htmlBody.replace('{!DPMX.monetaryCeiling}', returnCurrency(acqActWrp.discount.monetaryCeiling.amount));
            htmlBody = htmlBody.replace('{!DPMX.extraBilling}', returnCurrency(acqActWrp.commission.extraBilling.amount));
            htmlBody = htmlBody.replace('{!DPMX.billing}', returnCurrency(acqActWrp.commission.billing.amount));
            htmlBody = htmlBody.replace('{!DPMX.cellnet}', returnCurrency(acqActWrp.commission.cellnet.amount));
            htmlBody = htmlBody.replace('{!DPMX.totalAmount}', returnCurrency(acqActWrp.expenses.totalAmount.amount));
            htmlBody = htmlBody.replace('{!DPMX.mit}', returnCurrency(acqActWrp.expenses.mit.amount));

            if(isLastMonthTab){
                //Info cliente - Debito propio
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.own}', acqActWrp.transaction_y.debit.own+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.own}', returnCurrency(acqActWrp.billing.debit.own.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.own}', returnCurrency(acqActWrp.tickets.debit.own.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.own}', returnIsPercent2(acqActWrp.percentage.debit.mixOwn));

                //Info cliente - Debito ajeno
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.thirdParty}', acqActWrp.transaction_y.debit.thirdParty+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.thirdParty}', returnCurrency(acqActWrp.billing.debit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.thirdParty}', returnCurrency(acqActWrp.tickets.debit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.thirdParty}', returnIsPercent2(acqActWrp.percentage.debit.mixExternal));

                //Info cliente - credit propio
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.own}', acqActWrp.transaction_y.credit.own+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.own}', returnCurrency(acqActWrp.billing.credit.own.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.own}', returnCurrency(acqActWrp.tickets.credit.own.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.own}', returnIsPercent2(acqActWrp.percentage.credit.mixOwn));

                //Info cliente - credit ajeno
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.thirdParty}', acqActWrp.transaction_y.credit.thirdParty+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.thirdParty}', returnCurrency(acqActWrp.billing.credit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.thirdParty}', returnCurrency(acqActWrp.tickets.credit.thirdParty.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.thirdParty}', returnIsPercent2(acqActWrp.percentage.credit.mixExternal));

                //Info cliente - international
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.international}', acqActWrp.transaction_y.international+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.international}', returnCurrency(acqActWrp.billing.international.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.international}', returnCurrency(acqActWrp.tickets.international.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.international}', returnIsPercent2(acqActWrp.percentage.mixInternational));

                //Info cliente - total
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.total}', acqActWrp.transaction_y.acquirerAffiliation+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.total}', returnCurrency(acqActWrp.billing.totalAmount.amount));
                htmlBody = htmlBody.replace('{!DPMX.tickets.total}', returnCurrency(acqActWrp.tickets.totalAmount.amount));
                htmlBody = htmlBody.replace('{!DPMX.percentage.total}', returnIsPercent2(acqActWrp.percentage.total));

                //Dispositivos simulados
                htmlBody = htmlBody.replace('{!DPMX.terminal}', acqActWrp.terminal.id_y+'');
                htmlBody = htmlBody.replace('{!DPMX.pinPads}', acqActWrp.devices.pinPads.pinPadsNumber+'');
                if(acqActWrp.ecommerce == 'N'){
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'No');
                }else {
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'Si');
                }
                htmlBody = htmlBody.replace('{!DPMX.devicesNumber}', acqActWrp.devices.devicesNumber+'');

                //Comisiones simuladas - Se recogen antes DPMX.extraBilling, DPMX.billing, DPMX.cellnet

                //Tasas descuento propuestas
                list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> scenariosArry = new  list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'BREAK_EVEN') {
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
                        if (acqActFeesWrp.scenarios[i].scenarioType != 'GOOD') {
                            scenariosArry.add(acqActFeesWrp.scenarios[i]);
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
                    }

                    for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                        switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                            when 'DEBIT' {		
                                if(dynamicPricing.familia__c == Label.DPMX_GS){
                                    debitStr = returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                                }else{
                                    debitStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                                }
                            }	
                            when 'CREDIT' {		
                                creditStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                            when 'INTERNATIONAL' {		
                                internationalStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }
                    }
                    rent = returnIsPercent(scenariosArry[i].fees.profitability.percentage);
                    bai = returnCurrency(scenariosArry[i].fees.profitability.amount.amount);
                    content = '<tr> <td> <p class="padding-left">'+debitStr+'</p> </td> <td> <p>'+creditStr+'</p> </td> <td> <p>'+internationalStr+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+rent+'</p> </td> <td> <p>'+bai+'</p> </td> </tr>';
                    scenarios = scenarios + content;
                }
                htmlBody = htmlBody.replace('{!DPMX.scenario}', scenarios);

                //Scenario propio
                DPMX_Container_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                DPMX_Container_Ctrl.Discount_Rates_Wrapper discountRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                List<DPMX_Container_Ctrl.Company_Info> companies = new List<DPMX_Container_Ctrl.Company_Info>();
                Double debitt = dynamicPricing.CustomAcquiredFeesDebit__c;
                Double creditt = dynamicPricing.CustomAcquiredFeesCredit__c;
                Double internationalt = dynamicPricing.CustomAcquiredFeesInternational__c;

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

                if(profitabilityRates == 0 && debitt == 0 && creditt == 0 && internationalt == 0){
                    result = '---';
                } else if(profitabilityRates != 0 || debitt != 0 || creditt != 0 || internationalt != 0){
                    if (profitabilityRates >= optRat) {
                        result = 'Optimo';
                    } else if (profitabilityRates >= goodRat) {
                        result = 'Bueno';
                    } else {
                        result = 'Break even';
                    }
                } else {
                    result = '----';
                }

                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    debitPropio = returnCurrency(dynamicPricing.CustomAcquiredFeesDebit__c);
                }else{
                    debitPropio = returnIsPercent(dynamicPricing.CustomAcquiredFeesDebit__c);
                }
                scenarios = '';
                content = '<tr> <td> <p class="padding-left">'+debitPropio+'</p> </td> <td> <p>'+returnIsPercent(dynamicPricing.CustomAcquiredFeesCredit__c)+'</p> </td> <td> <p>'+returnIsPercent(dynamicPricing.CustomAcquiredFeesInternational__c)+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+returnIsPercent(profitabilityRates.setscale(2))+'</p> </td> <td> <p>'+returnCurrency(profitAmount.setscale(2))+'</p> </td> </tr>';
                scenarios = titles + content;

                htmlBody = htmlBody.replace('{!DPMX.scenarioPropio}', scenarios);

                //Oportunidades
                htmlBody = htmlBody.replace('{!DPMX.oppPosExtra}', returnCurrency(acqActWrp.commission.opportunity.posExtra.amount));
                htmlBody = htmlBody.replace('{!DPMX.oppCallnet}', returnCurrency(acqActWrp.commission.opportunity.cellnet.amount));
                htmlBody = htmlBody.replace('{!DPMX.oppLowBilling}', returnCurrency(acqActWrp.commission.opportunity.lowBilling.amount));

                //Referencias Gastos (ya tenemos anteriormente los gastos totales y los MID y eBind)
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

                //Tasas de descuento máximas
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.interchangeRates.debit}', returnCurrency(interchangeRates.debit));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.interchangeRates.debit}', returnIsPercent(interchangeRates.debit));
                }
                
                htmlBody = htmlBody.replace('{!DPMX.interchangeRates.credit}', returnIsPercent(interchangeRates.credit));
                htmlBody = htmlBody.replace('{!DPMX.interchangeRates.International}', returnIsPercent(interchangeRates.international));

                //Intercambio
                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    acqActWrp.isGS = true;
                    htmlBody = htmlBody.replace('{!DPMX.discountRates.debit}', returnCurrency(acqActWrp.discount.monetaryCeiling.amount));
                }else{
                    acqActWrp.isGS = false;
                    htmlBody = htmlBody.replace('{!DPMX.discountRates.debit}', returnIsPercent(acqActWrp.discount.monetaryCeiling.amount));
                }
                
                htmlBody = htmlBody.replace('{!DPMX.discountRates.credit}', returnIsPercent(acqActWrp.commission.opportunity.posExtra.amount));
                htmlBody = htmlBody.replace('{!DPMX.discountRates.International}', returnIsPercent(acqActWrp.discount.percentage.international));

                //Descuento Maximo
                htmlBody = htmlBody.replace('{!DPMX.DescuentoMaximo}', returnIsPercent(acqActWrp.discount.monetaryCeiling.amount));

            }else if(isSimulationTab){
                //Info cliente - Debito propio
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.own}', dynamicPricing.Sim_Transaction_Debit_Own__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.own}', returnCurrency(dynamicPricing.Sim_Billing_Debit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.own}', returnCurrency(dynamicPricing.Sim_Tickets_Debit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.own}', returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixOwn__c.setscale(2)));

                //Info cliente - Debito ajeno
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.debit.thirdParty}', dynamicPricing.Sim_Transaction_Debit_ThirdParty__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.debit.thirdParty}', returnCurrency(dynamicPricing.Sim_Billing_Debit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.debit.thirdParty}', returnCurrency(dynamicPricing.Sim_Tickets_Debit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.debit.thirdParty}', returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixExternal__c.setscale(2)));

                //Info cliente - credit propio
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.own}', dynamicPricing.Sim_Transaction_Credit_Own__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.own}', returnCurrency(dynamicPricing.Sim_Billing_Credit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.own}', returnCurrency(dynamicPricing.Sim_Tickets_Credit_Own_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.own}', returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixOwn__c.setscale(2)));

                //Info cliente - credit ajeno
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.credit.thirdParty}', dynamicPricing.Sim_Transaction_Credit_ThirdParty__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.credit.thirdParty}', returnCurrency(dynamicPricing.Sim_Billing_Credit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.credit.thirdParty}', returnCurrency(dynamicPricing.Sim_Tickets_Credit_ThirdParty_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.credit.thirdParty}', returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixExternal__c.setscale(2)));

                //Info cliente - international
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.international}',  dynamicPricing.Sim_Transaction_International__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.international}', returnCurrency(dynamicPricing.Sim_Billing_International_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.international}', returnCurrency(dynamicPricing.Sim_Tickets_International_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.international}', returnIsPercent(dynamicPricing.Sim_Percentage_MixInternational__c.setscale(2)));

                //Info cliente - total
                htmlBody = htmlBody.replace('{!DPMX.transaction_y.total}', dynamicPricing.Sim_Transaction_AcquirerAffiliation__c+'');
                htmlBody = htmlBody.replace('{!DPMX.billing.total}', returnCurrency(dynamicPricing.Sim_Billing_TotalAmount_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.tickets.total}', returnCurrency(dynamicPricing.Sim_Tickets_TotalAmount_Amount__c));
                htmlBody = htmlBody.replace('{!DPMX.percentage.total}', returnIsPercent(dynamicPricing.Sim_Percentage_Total__c.setscale(2)));

                //Dispositivos simulados
                htmlBody = htmlBody.replace('{!DPMX.terminal}', dynamicPricing.Sim_Terminal_Id__c+'');
                htmlBody = htmlBody.replace('{!DPMX.pinPads}', dynamicPricing.Sim_PinPadsInfo_PinPads__c+'');
                if(!dynamicPricing.Sim_Ecommerce__c){
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'No');
                }else {
                    htmlBody = htmlBody.replace('{!DPMX.ecommerceCheckbox}', 'Si');
                }
                htmlBody = htmlBody.replace('{!DPMX.devicesNumber}', dynamicPricing.Sim_DevicesInfo_Devices__c+'');

                //Comisiones simuladas - Se recogen antes DPMX.extraBilling, DPMX.billing, DPMX.cellnet

                //Tasas descuento propuestas
                list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> scenariosArry = new  list<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
                for (Integer i = 0; i != (acqActFeesWrp.scenarios).size(); i++) {
                    if (acqActFeesWrp.scenarios[i].scenarioType == 'BREAK_EVEN') {
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
                        if (acqActFeesWrp.scenarios[i].scenarioType != 'GOOD') {
                            scenariosArry.add(acqActFeesWrp.scenarios[i]);
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
                    }

                    for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                        switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                            when 'DEBIT' {		
                                if(dynamicPricing.familia__c == Label.DPMX_GS){
                                    debitStr = returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                                }else{
                                    debitStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                                }
                            }	
                            when 'CREDIT' {		
                                creditStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                            when 'INTERNATIONAL' {		
                                internationalStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }
                    }
                    rent = returnIsPercent(scenariosArry[i].fees.profitability.percentage);
                    bai = returnCurrency(scenariosArry[i].fees.profitability.amount.amount);
                    content = '<tr> <td> <p class="padding-left">'+debitStr+'</p> </td> <td> <p>'+creditStr+'</p> </td> <td> <p>'+internationalStr+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+rent+'</p> </td> <td> <p>'+bai+'</p> </td> </tr>';
                    scenarios = scenarios + content;

                    //Scenario propio
                DPMX_Container_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                DPMX_Container_Ctrl.Discount_Rates_Wrapper discountRates = new DPMX_Container_Ctrl.Discount_Rates_Wrapper();
                List<DPMX_Container_Ctrl.Company_Info> companies = new List<DPMX_Container_Ctrl.Company_Info>();
                Double debitt = dynamicPricing.CustomSimulatedDebit__c;
                Double creditt = dynamicPricing.CustomSimulatedCredit__c;
                Double internationalt = dynamicPricing.CustomSimulatedInternational__c;

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
                
                string debitPropio = '';
                decimal profitabilityRates = dynamicPricing.CustomSimulatedRent__c;
                decimal profitAmount = dynamicPricing.CustomSimulatedBai__c;

                //acqActFeesWrp
                double optRat = 0;
                double goodRat = 0;
                double brkRat = 0;

                for (Integer x = 0; x != (scenariosArry[i].fees.itemizeFees).size(); x++) {
                    switch on scenariosArry[i].fees.itemizeFees[x].feeType {
                        when 'DEBIT' {		
                            if(dynamicPricing.familia__c == Label.DPMX_GS){
                                debitStr = returnCurrency(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.amount);
                            }else{
                                debitStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                            }
                        }	
                        when 'CREDIT' {		
                            creditStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                        }
                        when 'INTERNATIONAL' {		
                            internationalStr = returnIsPercent(scenariosArry[i].fees.itemizeFees[x].itemizeFeeUnit.value);
                        }
                    }
                }

                if(profitabilityRates == 0 && debitt == 0 && creditt == 0 && internationalt == 0){
                    result = '---';
                } else if(profitabilityRates != 0 || debitt != 0 || creditt != 0 || internationalt != 0){
                    if (profitabilityRates >= optRat) {
                        result = 'Optimo';
                    } else if (profitabilityRates >= goodRat) {
                        result = 'Bueno';
                    } else {
                        result = 'Break even';
                    }
                } else {
                    result = '----';
                }

                if(dynamicPricing.familia__c == Label.DPMX_GS){
                    debitPropio = returnCurrency(dynamicPricing.CustomSimulatedDebit__c);
                }else{
                    debitPropio = returnIsPercent(dynamicPricing.CustomSimulatedDebit__c);
                }
                scenarios = '';
                content = '<tr> <td> <p class="padding-left">'+debitPropio+'</p> </td> <td> <p>'+returnIsPercent(dynamicPricing.CustomSimulatedCredit__c)+'</p> </td> <td> <p>'+returnIsPercent(dynamicPricing.CustomSimulatedInternational__c)+'</p> </td> <td> <p>'+result+'</p> </td> <td> <p>'+returnIsPercent(profitabilityRates.setscale(2))+'</p> </td> <td> <p>'+returnCurrency(profitAmount.setscale(2))+'</p> </td> </tr>';
                scenarios = titles + content;

                htmlBody = htmlBody.replace('{!DPMX.scenarioPropio}', scenarios);
                }
                htmlBody = htmlBody.replace('{!DPMX.scenario}', scenarios);
            }
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