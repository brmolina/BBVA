/**
* ____________________________________________________________________________
* Controller class for DPMX_FormalizeAtam.cmp aura Component
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
public class DPMX_FormalizeAtam_ctrl {
    /**
        * @description Private constructor to avoid sonar err
        */
        public DPMX_FormalizeAtam_ctrl() {
    
        }
    
        /**
        * @description Get data from services
        * @param recordId : Dynamic Pricing Id
        * @return retMap ??????
        */
        @AuraEnabled
        public static Map<String,Object> getInitialData (String recordId) {
            System.debug('getInitialData');
            Map<String, Object> retMap = new Map<String, Object>();
            DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
            DPMX_Formalize__c formalize = DPMX_Utils.formalizeDPMXSelector(recordId);
            final Map<String, Object> responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquiererActy_JSON__c);
            final List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMapAcqAct.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
            DPMX_AcquirerActivities_Wrapper acqActWrp = acquirerActivitiesWrapperLst[0];
            final Map<String, Object> responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquirerFees_JSON__c);
            final DPMX_AcquirerActivitiesFees_Wrapper acqActFeesWrp = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMapAcqFee.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
            final Map<String, Object> responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.corporateRates_JSON__c);
            final List<DPMX_CorporateRates_Wrapper> corpRatWrp = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMapCopRat.get('data')), List<DPMX_CorporateRates_Wrapper>.class);
            boolean isSimulationTab = dynamicPricing.formalizeTab__c;
            retMap.put('dynamicPricing', dynamicPricing);

            String initDate = dynamicPricing.initDateFormalize__c;
            String revisionDate = dynamicPricing.revisionDateFormalize__c;

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

            if(!formalize.deniedCheck__c){
    
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
                        DPMX_debit =  DPMX_Utils.returnCurrency(acqActWrp.discount.debit.itemizeType.amount);
                    }else{
                        acqActWrp.isGS = false;
                        DPMX_debit =  DPMX_Utils.returnIsPercent(acqActWrp.discount.debit.itemizeType.value);
                    }
                    DPMX_credit = DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.credit);
                    DPMX_International = DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.international);
                    DPMX_Resultado = dynamicPricing.familia__c;
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

                    if(!isSimulationTab){
        
                        //Info cliente - Debito propio
                        DPMX_transaction_y_debit_own = (acqActWrp.transaction_y.debit.own + acqActWrp.transaction_y.debit.thirdParty)+'';
                        DPMX_billing_debit_own = DPMX_Utils.returnCurrency(acqActWrp.billing.debit.own.amount + acqActWrp.billing.debit.thirdParty.amount);
                        DPMX_tickets_debit_own = DPMX_Utils.returnCurrency(acqActWrp.tickets.debit.own.amount + acqActWrp.tickets.debit.thirdParty.amount);
                        DPMX_percentage_debit_own = DPMX_Utils.returnIsPercent2(acqActWrp.percentage.debit.mixOwn + acqActWrp.percentage.debit.mixExternal);

        
                        //Info cliente - Debito ajeno
                        DPMX_transaction_y_debit_thirdParty =  acqActWrp.transaction_y.debit.thirdParty+'';
                        DPMX_billing_debit_thirdParty =  DPMX_Utils.returnCurrency(acqActWrp.billing.debit.thirdParty.amount);
                        DPMX_tickets_debit_thirdParty =  DPMX_Utils.returnCurrency(acqActWrp.tickets.debit.thirdParty.amount);
                        DPMX_percentage_debit_thirdParty =  DPMX_Utils.returnIsPercent2(acqActWrp.percentage.debit.mixExternal);
        
                        //Info cliente - credit propio
                        DPMX_transaction_y_credit_own = (acqActWrp.transaction_y.credit.own + acqActWrp.transaction_y.credit.thirdParty)+'';
                        DPMX_billing_credit_own = DPMX_Utils.returnCurrency(acqActWrp.billing.credit.own.amount + acqActWrp.billing.credit.thirdParty.amount);
                        DPMX_tickets_credit_own = DPMX_Utils.returnCurrency(acqActWrp.tickets.credit.own.amount + acqActWrp.tickets.credit.thirdParty.amount);
                        DPMX_percentage_credit_own = DPMX_Utils.returnIsPercent2(acqActWrp.percentage.credit.mixOwn + acqActWrp.percentage.credit.mixExternal);

        
                        //Info cliente - credit ajeno
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
                            DPMX_debitPorpio = DPMX_Utils.returnCurrency(dynamicPricing.CustomAcquiredFeesDebit__c);
                        }else{
                            DPMX_debitPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesDebit__c);
                        }
                        
                        DPMX_creditPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesCredit__c);
                        DPMX_interPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomAcquiredFeesInternational__c);
                        DPMX_resultPorpio = result;
                        if(profitabilityRates != null){
                            DPMX_rentPorpio = DPMX_Utils.returnIsPercent(profitabilityRates.setscale(2));
                            DPMX_baiPorpio = DPMX_Utils.returnCurrency(profitAmount.setscale(2));
                        }
                        
        
                        //Oportunidades
                        DPMX_oppPosExtra = DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.posExtra.amount);
                        DPMX_oppCallnet = DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.cellnet.amount);
                        DPMX_oppLowBilling = DPMX_Utils.returnCurrency(acqActWrp.commission.opportunity.lowBilling.amount);
        
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
                            DPMX_interchangeRates_debit = DPMX_Utils.returnCurrency(interchangeRates.debit);
                        }else{
                            DPMX_interchangeRates_debit = DPMX_Utils.returnIsPercent(interchangeRates.debit);
                        }
                        DPMX_interchangeRates_credit = DPMX_Utils.returnIsPercent(interchangeRates.credit);
                        DPMX_interchangeRates_International = DPMX_Utils.returnIsPercent(interchangeRates.international);
        
                        //Intercambio
                        if(dynamicPricing.familia__c == Label.DPMX_GS){
                            DPMX_discountRates_debit = DPMX_Utils.returnCurrency(acqActWrp.discount.monetaryCeiling.amount);
                        }else{
                            DPMX_discountRates_debit = DPMX_Utils.returnIsPercent(acqActWrp.discount.monetaryCeiling.amount);
                        }
                        
                        DPMX_discountRates_credit = DPMX_Utils.returnIsPercent(acqActWrp.commission.opportunity.posExtra.amount);
                        DPMX_discountRates_International = DPMX_Utils.returnIsPercent(acqActWrp.discount.percentage.international);
        
                        //Descuento Maximo
                        DPMX_DescuentoMaximo = DPMX_Utils.returnIsPercent(acqActWrp.discount.monetaryCeiling.amount);
        
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
                        DPMX_billing_debit_own =  DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Debit_Own_Amount__c);
                        DPMX_tickets_debit_own =  DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Debit_Own_Amount__c);
                        DPMX_percentage_debit_own = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixOwn__c.setscale(2));
        
                        //Info cliente - Debito ajeno
                        DPMX_transaction_y_debit_thirdParty = dynamicPricing.Sim_Transaction_Debit_ThirdParty__c+'';
                        DPMX_billing_debit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Debit_ThirdParty_Amount__c);
                        DPMX_tickets_debit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Debit_ThirdParty_Amount__c);
                        DPMX_percentage_debit_thirdParty = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Debit_MixExternal__c.setscale(2));
        
                        //Info cliente - credit propio
                        DPMX_transaction_y_credit_own = dynamicPricing.Sim_Transaction_Credit_Own__c+'';
                        DPMX_billing_credit_own = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Credit_Own_Amount__c);
                        DPMX_tickets_credit_own = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Credit_Own_Amount__c);
                        DPMX_percentage_credit_own = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixOwn__c.setscale(2));
        
                        //Info cliente - credit ajeno
                        DPMX_transaction_y_credit_thirdParty = dynamicPricing.Sim_Transaction_Credit_ThirdParty__c+'';
                        DPMX_billing_credit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_Credit_ThirdParty_Amount__c);
                        DPMX_tickets_credit_thirdParty = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_Credit_ThirdParty_Amount__c);
                        DPMX_percentage_credit_thirdParty = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Credit_MixExternal__c.setscale(2));
        
                        //Info cliente - international
                        DPMX_transaction_y_international =  dynamicPricing.Sim_Transaction_International__c+'';
                        DPMX_billing_international = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_International_Amount__c);
                        DPMX_tickets_international = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_International_Amount__c);
                        DPMX_percentage_international = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_MixInternational__c.setscale(2));
        
                        //Info cliente - total
                        DPMX_transaction_y_total = dynamicPricing.Sim_Transaction_AcquirerAffiliation__c+'';
                        DPMX_billing_total = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Billing_TotalAmount_Amount__c);
                        DPMX_tickets_total = DPMX_Utils.returnCurrency(dynamicPricing.Sim_Tickets_TotalAmount_Amount__c);
                        DPMX_percentage_total = DPMX_Utils.returnIsPercent(dynamicPricing.Sim_Percentage_Total__c.setscale(2));
        
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
                                DPMX_debitPorpio = DPMX_Utils.returnCurrency(dynamicPricing.CustomSimulatedDebit__c);
                            }else{
                                DPMX_debitPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedDebit__c);
                            }
                            
                            DPMX_creditPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedCredit__c);
                            DPMX_interPorpio = DPMX_Utils.returnIsPercent(dynamicPricing.CustomSimulatedInternational__c);
                            DPMX_resultPorpio = result;
                            if(profitabilityRates != null){
                                DPMX_rentPorpio = DPMX_Utils.returnIsPercent(profitabilityRates.setscale(2));
                                DPMX_baiPorpio = DPMX_Utils.returnCurrency(profitAmount.setscale(2));
                            }
                        }
        
                    }


                
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

                    retMap.put('initDate', initDate);
                    retMap.put('revisionDate', revisionDate);

                    if(formalize.Dynamic_Pricing__c != null){
                        System.debug('if');
                        retMap.put('formalizeExist', true);
                        retMap.put('credit', formalize.credit__c);
                        retMap.put('debit', formalize.debit__c);
                        retMap.put('international', formalize.international__c);
            
                        retMap.put('FirmODTUser__c', formalize.FirmODTUser__c);
                        retMap.put('FirmOdtClient__c', formalize.FirmOdtClient__c);
                        retMap.put('NewODT__c', formalize.NewODT__c);
                        retMap.put('ScanODT__c', formalize.ScanODT__c);
                    }else {
                        System.debug('else');
                        retMap.put('formalizeExist', false);
                    }
                
            }
            
            retMap.put('formalizeDenied', formalize.deniedCheck__c);

            return retMap;
        }
    
        /**
        * @description retrieve Profitability Sheets related to the participant
        * @param recordId : Client Id
        * @return retMap status update 
        */
        @AuraEnabled
        public static Map<String,Object> sendReport (string recordId, string templateName, string saludo, string intro, string close, string[] sendCC, String asunto, boolean formalizeExist, string comentario) {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Map<String, Object> retMapUpdateRates = new Map<String, Object>();
            EmailTemplate emailTemp = DPMX_Utils.returnEmailTemp(templateName);
            Map<String, Object> retMap = new Map<String, Object>();
            DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
            string status = 'sendReport';
            Boolean sendReport = true;
            String htmlBody = emailTemp.HtmlValue;
            String customerId = '';
            DPMX_Formalize__c formalize = DPMX_Utils.formalizeDPMXSelector(recordId);

            String initDate = dynamicPricing.initDateFormalize__c;
            String revisionDate = dynamicPricing.revisionDateFormalize__c;

            if(!formalize.deniedCheck__c && !formalize.formalizeAccepted__c){
                
                htmlBody = htmlBody.replace('{!DPMX.saludo}',saludo);
                htmlBody = htmlBody.replace('{!DPMX.Introduccion}',intro);
                htmlBody = htmlBody.replace('{!DPMX.close}',close);
        
                if(sendReport){
                    try{
                        Local_Client__c localClient = [SELECT Id, unique_id__c FROM Local_Client__c WHERE Cib_Client__c =:dynamicPricing.Company_Name__c LIMIT 1];
                        customerId = localClient.unique_id__c;
                        retMap.put('succes', 'Cliente encontrado');
                    } catch(Exception ex){
                        retMap.put('error', 'Cliente no encontrado');
                    }
                    retMapUpdateRates = updateRatesPost(recordId, customerId);
                    updateFormalize(recordId, formalizeExist);
                    DateTime today = DateTime.now();
                    String consultDate = today.format('yyyy-MM-dd');
                    DPMX_Formalize__c formalizeId = DPMX_Utils.formalizeDPMXSelector(recordId);
                    htmlBody = htmlBody.replace('{!DPMX.fechaVigencia}', dynamicPricing.initDateFormalize__c);
                    htmlBody = htmlBody.replace('{!DPMX.fecha}', consultDate);
                    htmlBody = htmlBody.replace('{!DPMX.Cliente}', dynamicPricing.Company_Name__r.Name);
                    htmlBody = htmlBody.replace('{!DPMX.Link}', Label.DPMX_Link);
                    htmlBody = htmlBody.replace('{!DPMX.autId}', dynamicPricing.Id);
                    htmlBody = htmlBody.replace('{!DPMX.comentario}', comentario);
        
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTemplateId(emailTemp.Id);
                    mail.setTargetObjectId(dynamicPricing.OwnerId);
                    mail.setCcAddresses(sendCC);
                    mail.setHtmlBody(htmlBody);
                    mail.setSaveAsActivity(false);
                    mail.setSubject('Aceptación de orden de trabajo');
                    emailList.add(mail);
                    
                    if(Test.isRunningTest()){
                      status = 'Verificacion de envio de email para classes test.';
                      sendReport = true;  
                    }else  if(!emailList.isEmpty()){
                        Messaging.sendEmail(emailList);
                    }else {
                        status = 'fail send report';
                        sendReport = false;
                    }
                }
            }else{
                status = 'Formalización ya se ha denegado o se ha aceptado, no se puede enviar el correo.';
                sendReport = false;
            }
            retMap.put('sendReport', sendReport);
            retMap.put('status', status);
            return retMap;
        }

        /**
    * @description update fomrlize object
    * @param recordId : Dynamic Pricing Id
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> updateFormalize(string recordId, boolean formalizeExist){
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        DPMX_Formalize__c formalize = DPMX_Utils.formalizeDPMXSelector(recordId);

        if(formalize.Dynamic_Pricing__c != null)
        {
            formalize.NewODT__c = true;
            formalize.formalizeAccepted__c = true;
            update formalize;
            dynamicPricing.TAMAccepted__c = true;
            dynamicPricing.Stage__c = 'Closed';
            update dynamicPricing;
            retMap.put('NewODT__c',true);
        }

        return retMap;
    }

    @AuraEnabled
    public static Map<String,Object> updateRatesPost (String recordId, String customerId) {
        System.debug('_______*******______');
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        DPMX_Formalize__c formalize = DPMX_Utils.formalizeDPMXSelector(recordId);
        Decimal updDebit = formalize.debit__c;
        Decimal updCredit = formalize.credit__c;
        Decimal updInternational = formalize.international__c;
        String initDate = dynamicPricing.initDateFormalize__c;
        String revisionDate = dynamicPricing.revisionDateFormalize__c;
        System.debug(dynamicPricing.OwnerId);
        user userOwner = DPMX_Utils.userSelector(dynamicPricing.OwnerId);
        System.debug(userOwner);
        String userId = userOwner.ID_User__c;
        DPMX_UpdateRates_Wrapper updRates = new DPMX_UpdateRates_Wrapper();
        DPMX_UpdateRates_Wrapper.BusinessAgent agent = new DPMX_UpdateRates_Wrapper.BusinessAgent();
        DPMX_UpdateRates_Wrapper.BusinessAgentAuthorizes agentAut = new DPMX_UpdateRates_Wrapper.BusinessAgentAuthorizes();
        //try {
            Date myDate = date.newinstance(dynamicPricing.CreatedDate.year(), dynamicPricing.CreatedDate.month(), dynamicPricing.CreatedDate.day());
            System.debug(String.valueOf(myDate));
            updRates.customerId = customerId;
            updRates.storePay = 'PROPIO';
            updRates.startDate = initDate;
            updRates.expirationDate = revisionDate;
            agent.id = userId;
            updRates.businessAgent = agent;
            agentAut.id = userOwner.ID_User__c;
            updRates.businessAgentAuthorizes = agentAut;
            List<DPMX_UpdateRates_Wrapper.Rates> ratesLst = new List<DPMX_UpdateRates_Wrapper.Rates>();
            //rates Debit
            if(updDebit != 0){
                DPMX_UpdateRates_Wrapper.Rates ratesDb = new DPMX_UpdateRates_Wrapper.Rates();
                ratesDb.typeCode = 'TDDB';
                DPMX_UpdateRates_Wrapper.fee ratesDbfee = new DPMX_UpdateRates_Wrapper.fee();
                DPMX_UpdateRates_Wrapper.amount ratesDbfeeAmount = new DPMX_UpdateRates_Wrapper.amount();
                DPMX_UpdateRates_Wrapper.percentage ratesDbfeePerc = new DPMX_UpdateRates_Wrapper.percentage();
                System.debug(ratesDb.typeCode);
                if(dynamicPricing.familia__c == 'Grandes_Superficies'){
                    
                        System.debug('if');
                        ratesDbfeeAmount.amount= updDebit;
                        ratesDbfeeAmount.currency_c= 'MX';
                        ratesDbfee.amount = ratesDbfeeAmount;
                        ratesDb.fee = ratesDbfee;
                    
                } else{

                        System.debug('else');
                        ratesDbfeePerc.value = updDebit;
                        ratesDbfee.percentage = ratesDbfeePerc;
                        ratesDb.fee = ratesDbfee;
                    
                }
                ratesLst.add(ratesDb);
            }
            //rates Credit
            if(updCredit != 0){
                DPMX_UpdateRates_Wrapper.Rates ratesCr = new DPMX_UpdateRates_Wrapper.Rates();
                ratesCr.typeCode = 'TCDN';
                DPMX_UpdateRates_Wrapper.fee ratesCrfee = new DPMX_UpdateRates_Wrapper.fee();
                DPMX_UpdateRates_Wrapper.percentage ratesCrfeePerc = new DPMX_UpdateRates_Wrapper.percentage();
                ratesCrfeePerc.value = updCredit;
                ratesCrfee.percentage = ratesCrfeePerc;
                ratesCr.fee = ratesCrfee;
                ratesLst.add(ratesCr);
            }
            //rates International
            if(updInternational != 0){
                DPMX_UpdateRates_Wrapper.Rates ratesInt = new DPMX_UpdateRates_Wrapper.Rates();
                ratesInt.typeCode = 'TCDI';
                DPMX_UpdateRates_Wrapper.fee ratesIntfee = new DPMX_UpdateRates_Wrapper.fee();
                DPMX_UpdateRates_Wrapper.percentage ratesIntfeePerc = new DPMX_UpdateRates_Wrapper.percentage();
                ratesIntfeePerc.value = updInternational;
                ratesIntfee.percentage = ratesIntfeePerc;
                ratesInt.fee = ratesIntfee;
                ratesLst.add(ratesInt);
            }

            updRates.rates = ratesLst;
            String updRatesJson = JSON.serialize(updRates);
            updRatesJson = updRatesJson.replace('currency_c', 'currency');
            System.debug(updRatesJson);
            retMap.put('success', 'Se ha actualizado la tasa');
            retMap.put('updateRatesPost', updRatesJson);

            String acquirerId = dynamicPricing.familia_AcquiererCategories_Id__c;

            Map<String,String> jsonInputMap = new Map<String,String>();
            jsonInputMap.put('acquirerId', acquirerId);
            jsonInputMap.put('updRatesJson', updRatesJson);
            System.debug('_______*******______' + jsonInputMap);
            HttpResponse response = DPMX_Utils.callWebService('DPMX_UpdateRates', jsonInputMap);

            String responseReplace;
            if(Test.isRunningTest()){
				responseReplace = '{"data":{"folio":"242271301"}}';
            }else {
                responseReplace = response.getBody();
            }
            retMap.put('status', response.getStatusCode()+' - '+response.getStatus());

            switch on response.getStatusCode() {
                when 200 {
                    if(Test.isRunningTest()){
                        responseReplace = '{"data":{"folio":"242271301"}}';
                    }else {
                        responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                    }
                    System.debug(responseReplace);
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                    Map<String, Object> responseFolio = new Map<String, Object>();
                    System.debug(responseMap.get('data'));
                    responseFolio = (Map<String, Object>) responseMap.get('data');
                    System.debug(responseFolio.get('folio'));
                    list<DPMX_UpdtRatesxDynPric__c> relUpdRatDynPricLst = DPMX_Utils.DPMX_UpdtRatesxDynPricSelector(dynamicPricing.Id , (String )responseFolio.get('folio'));
                    if(relUpdRatDynPricLst.isEmpty()){
                        DPMX_UpdtRatesxDynPric__c relUpdRatDynPric = new DPMX_UpdtRatesxDynPric__c();
                        relUpdRatDynPric.DPMX__c = dynamicPricing.Id;
                        relUpdRatDynPric.folioUpdateRates__c = (String )responseFolio.get('folio') + '';
                        relUpdRatDynPric.initDateFormalize__c = dynamicPricing.initDateFormalize__c;
                        relUpdRatDynPric.revisionDateFormalize__c = dynamicPricing.revisionDateFormalize__c;
                        insert relUpdRatDynPric;
                    }
                    
                    //DPMX_getStatusFeeResponse_Wrapper getStatusResponseWrapper = (DPMX_UpdateRates_Wrapper) Json.deserialize(JSON.serialize(responseMap), DPMX_getStatusFeeResponse_Wrapper.class);
    
                    retMap.put('success', true);
                    System.debug('200');
                }
                when else {
                    System.debug('400');
                    retMap.put('success', false);
                }
            }
        /*}catch(Exception ex){
            retMap.put('error', 'json no creado');
        }*/
        

        return retMap;
    }
}