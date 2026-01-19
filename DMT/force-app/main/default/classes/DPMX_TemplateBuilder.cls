/**
* ____________________________________________________________________________
* Controller class for templateBuilder.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-10-28
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* ____________________________________________________________________________
*/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount, PMD.TooManyFields')
global with sharing class DPMX_TemplateBuilder implements Callable {

    public Object call(String action, Map<String, Object> args) {
        System.debug('action: '+action);
        System.debug('args: '+args);
        Object res;
        switch on action {
            when 'isUserAllowed' {
                res = this.isUserAllowed((Id)args.get('recordId'));
            }
            when 'getContent' {
                res = this.getContent((Id)args.get('recordId'));
            }
            when 'getRecipients' {
                res = this.getRecipients((Id)args.get('recordId'));
            }
            when 'renderContent' {
                res = this.renderContent((Id)args.get('recordId'), args.get('args'));
            }
            when 'handleResult' {
                res = this.handleResult((Id)args.get('recordId'), args.get('args'));
            }
            when 'sendEmail' {
                res = true;
            }
            when else {
                throw new tmpb.TemplateBuilder.TemplateBuilderMalformedCallException('Method not implemented: ' + action +  ', recordId: ' + (Id)args.get('recordId'));
            }
        }
        System.debug('res: '+res);
        return res;
    }
    tmpb.TemplateBuilder.TemplateBuilderContent getContent(Id recordId) {
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        Local_Client__c localClient = [SELECT Id, unique_id__c FROM Local_Client__c WHERE Cib_Client__c =:dynamicPricing.Company_Name__c LIMIT 1];
		final Map<String, Object> responseMapAcqAct;
        final Map<String, Object> responseMapAcqFee;
        final Map<String, Object> responseMapCopRat;
        
        if(Test.isRunningTest()){
            responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped('{"data":[{"id_y":"98379569","businessInformation":{"companyName":"SANBORN HERMANOS SA DE CV","groupName":"GRUPO CARSO","familyAcquirer":"Grandes_Superficies"},"discount":{"debit":{"itemizeType":{"unitType":"AMOUNT","amount":1.24,"currency_y":"MXN"}},"percentage":{"credit":1.61,"international":2.34},"monetaryCeiling":{"amount":1.0E+15,"currency_y":"MXN"},"totalAmount":{"amount":853490.2,"currency_y":"MXN"}},"ratesResult":"NA","expenses":{"totalAmount":{"amount":-280481.56,"currency_y":"MXN"},"mit":{"amount":0.0,"currency_y":"MXN"}},"yieldPercentage":-0.18,"taxAcquirer":{"amount":-185993.95,"currency_y":"MXN"},"transaction_y":{"debit":{"own":62813.0,"thirdParty":137267.0},"credit":{"own":19048.0,"thirdParty":43292.0},"international":13068.0,"acquirerAffiliation":275488.0},"billing":{"debit":{"own":{"amount":22686012,"currency_y":"MXN"},"thirdParty":{"amount":44222424,"currency_y":"MXN"}},"credit":{"own":{"amount":8871839.0,"currency_y":"MXN"},"thirdParty":{"amount":1.81221E+7,"currency_y":"MXN"}},"international":{"amount":7298657.5,"currency_y":"MXN"},"totalAmount":{"amount":1.0120103E+8,"currency_y":"MXN"}},"tickets":{"debit":{"own":{"amount":361.17,"currency_y":"MXN"},"thirdParty":{"amount":322.16,"currency_y":"MXN"}},"credit":{"own":{"amount":465.76,"currency_y":"MXN"},"thirdParty":{"amount":418.6,"currency_y":"MXN"}},"international":{"amount":558.51,"currency_y":"MXN"},"totalAmount":{"amount":367.35,"currency_y":"MXN"}},"terminal":{"id_y":0},"percentage":{"debit":{"mixOwn":0.22,"mixExternal":0.44},"credit":{"mixOwn":0.09,"mixExternal":0.18},"mixInternational":0.07,"total":1.0},"devices":{"devicesNumber":53,"pinPads":{"pinPadsNumber":53}},"ecommerce":"N","informationDate":"agosto-2023","commission":{"billing":{"amount":0.0,"currency_y":"MXN"},"extraBilling":{"amount":0.0,"currency_y":"MXN"},"cellnet":{"amount":0.0,"currency_y":"MXN"},"opportunity":{"lowBilling":{"amount":0.0,"currency_y":"MXN"},"posExtra":{"amount":0.0,"currency_y":"MXN"},"cellnet":{"amount":0.0,"currency_y":"MXN"}}}}]}');
        }else {
            responseMapAcqAct = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquiererActy_JSON__c);
        }
        final List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMapAcqAct.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
        DPMX_AcquirerActivities_Wrapper acqActWrp = acquirerActivitiesWrapperLst[0];
        System.debug(acqActWrp);

        if(Test.isRunningTest()){
            responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped('{"data":{"id":"13","consultMonth":"agosto-2023","description":"Grandes_Superficies","scenarios":[{"commissionType":"ninguna","scenarioType":"OPTIMAL","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"AMOUNT","amount":2.3,"currency_y":"MXN"}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.05}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":4.0}}],"profitability":{"percentage":0.26,"amount":{"amount":270265.88,"currency_y":"MXN"}}}},{"commissionType":"ninguna","scenarioType":"GOOD","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"AMOUNT","amount":1.9,"currency_y":"MXN"}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.01}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.32}}],"profitability":{"percentage":0.13,"amount":{"amount":135132.94,"currency_y":"MXN"}}}},{"commissionType":"ninguna","scenarioType":"BREAK_EVEN","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"AMOUNT","amount":1.5,"currency_y":"MXN"}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":1.91}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.0}}],"profitability":{"percentage":0.0,"amount":{"amount":0.0,"currency_y":"MXN"}}}},{"commissionType":"ninguna","scenarioType":"GOOD","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"AMOUNT","amount":1.87,"currency_y":"MXN"}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.05}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.24}}],"profitability":{"percentage":0.13,"amount":{"amount":135132.94,"currency_y":"MXN"}}}}]}}');
        }else {
            responseMapAcqFee = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.acquirerFees_JSON__c);
		}
        final DPMX_AcquirerActivitiesFees_Wrapper acqActFeesWrp = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMapAcqFee.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
        System.debug(acqActFeesWrp);
        
        if(Test.isRunningTest()){
			responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped('{"data":[{"id_y":"DISCOUNT","lastUpdateDate":"2023-08-01","itemizeType":{"unitType":"AMOUNT","amount":1.24,"currency":"MXN"},"credit":{"value":1.53},"international":{"value":1.53}},{"id_y":"INTERCHANGE","lastUpdateDate":"2023-08-01","itemizeType":{"unitType":"AMOUNT","amount":3.0,"currency":"MXN"},"credit":{"value":2.05},"international":{"value":4.0}},{"id_y":"AVERAGE_DISCOUNT","lastUpdateDate":"2023-08-01","itemizeType":{"unitType":"AMOUNT","amount":1.44,"currency":"MXN"},"credit":{"value":1.8},"international":{"value":2.33}}]}');
        }else {
			responseMapCopRat = (Map<String, Object>) JSON.deserializeUntyped(dynamicPricing.corporateRates_JSON__c);
        }
        final List<DPMX_CorporateRates_Wrapper> corpRatWrp = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMapCopRat.get('data')), List<DPMX_CorporateRates_Wrapper>.class);  
        System.debug(corpRatWrp);

       Discount_Rates_Wrapper interchangeRates = new Discount_Rates_Wrapper();
                Discount_Rates_Wrapper discountRates = new Discount_Rates_Wrapper();
                List<Company_Info> companies = new List<Company_Info>();
                Double credit;
                Double international;
                Double debit;
                
                for (DPMX_CorporateRates_Wrapper CorporateRate: corpRatWrp) {

                credit = CorporateRate.credit.value;
                international = CorporateRate.international.value;
                if(CorporateRate.itemizeType.value == null){
                    debit = CorporateRate.itemizeType.amount;
                }else{
                    debit = CorporateRate.itemizeType.value;
                }
                    System.debug(CorporateRate);
                    System.debug('CorporateRate.id_y: '+CorporateRate.id_y);
                            System.debug('Credit: '+credit);
                            System.debug('debit: '+debit);
                            System.debug('international: '+international);
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
                            Company_Info familyAverage = new Company_Info();
                            familyAverage.id = '';
                            familyAverage.name = System.Label.DPMX_CompanyComparison_Row1;
                            familyAverage.credit = credit;
                            familyAverage.debit = debit;
                            familyAverage.international = international;
                            companies.add(familyAverage);
                        }
                    }
                }
        
        final tmpb.TemplateBuilder.TemplateBuilderContent content = new tmpb.TemplateBuilder.TemplateBuilderContent();
        content.id = 'Content';
        content.name = 'Sample result content elements';
        content.categories = new List<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory tasaDescuento = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        tasaDescuento.id = 'tasaDescuento';
        tasaDescuento.title = 'Tasa descuento actuales';
        tasaDescuento.description = '';
        tasaDescuento.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>(); 
		
        //System.debug(AcqActWrp.discount.debit.itemizeType.amount);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem tasaDescuentoDebit = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        tasaDescuentoDebit.id = 'Debito';
        if (AcqActWrp.BusinessInformation.familyAcquirer == Label.DPMX_GS) {
            tasaDescuentoDebit.title = '$'+AcqActWrp.discount.debit.itemizeType.amount+'MXN';
        } else {
            tasaDescuentoDebit.title = AcqActWrp.discount.debit.itemizeType.value+'';
        }
        tasaDescuentoDebit.checked = true;
        tasaDescuentoDebit.disabled = true;
        tasaDescuento.items.add(tasaDescuentoDebit);

        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info00E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info00E01.id = 'Credito';
        info00E01.title = AcqActWrp.discount.percentage.credit+'';
        info00E01.checked = true;
        info00E01.disabled = true;
        tasaDescuento.items.add(info00E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info00E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info00E02.id = 'International';
        info00E02.title = AcqActWrp.discount.percentage.international+'';
        info00E02.checked = true;
        info00E02.disabled = true;
        tasaDescuento.items.add(info00E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info00E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info00E03.id = 'Resultado';
        info00E03.title = AcqActWrp.ratesResult;
        info00E03.checked = true;
        info00E03.disabled = true;
        tasaDescuento.items.add(info00E03);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info00E04 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info00E04.id = 'rentabilidad';
        info00E04.title = AcqActWrp.yieldPercentage+'';
        info00E04.checked = true;
        info00E04.disabled = true;
        tasaDescuento.items.add(info00E04);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info00E05 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info00E05.id = 'BAI';
        info00E05.title = '$'+AcqActWrp.discount.totalAmount.amount+'MXN';
        info00E05.checked = true;
        info00E05.disabled = true;
        tasaDescuento.items.add(info00E05);

        content.categories.add(tasaDescuento);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info01 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info01.id = 'info01';
        info01.title = 'Resumen de información del último mes';
        info01.description = '';
        info01.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info01E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info01E00.id = 'Descuento total';
        info01E00.title = '$'+AcqActWrp.discount.monetaryCeiling.amount+'MXN';
        info01E00.checked = true;
        info01E00.disabled = true;
        info01.items.add(info01E00);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info01E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info01E01.id = 'TPV extra';
        info01E01.title = '$'+AcqActWrp.commission.extraBilling.amount+'MXN';
        info01E01.checked = true;
        info01E01.disabled = true;
        info01.items.add(info01E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info01E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info01E02.id = 'Baja facturación';
        info01E02.title = '$'+AcqActWrp.commission.billing.amount+'MXN';
        info01E02.checked = true;
        info01E02.disabled = true;
        info01.items.add(info01E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info01E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info01E03.id = 'Red celular';
        info01E03.title = '$'+AcqActWrp.commission.cellnet.amount+'MXN';
        info01E03.checked = true;
        info01E03.disabled = true;
        info01.items.add(info01E03);
        
        System.debug(AcqActWrp.expenses);
        System.debug(AcqActWrp.expenses.totalAmount.amount);

        final tmpb.TemplateBuilder.TemplateBuilderContentItem info01E04 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info01E04.id = 'Gastos totales';
        info01E04.title = '$'+AcqActWrp.expenses.totalAmount.amount+'MXN';
        info01E04.checked = true;
        info01E04.disabled = true;
        info01.items.add(info01E04);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info01E05 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info01E05.id = 'Gastos MIT y eBIND';
        info01E05.title = '$'+AcqActWrp.expenses.mit.amount+'MXN';
        info01E05.checked = true;
        info01E05.disabled = true;
        info01.items.add(info01E05);

        content.categories.add(info01);
		
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info02 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info02.id = 'info02';
        info02.title = 'Información simulada del cliente - Débito propio';
        info02.description = '';
        info02.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info02E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info02E00.id = '# Transacciones';
        info02E00.title = ''+AcqActWrp.transaction_y.debit.own;
        info02E00.checked = true;
        info02E00.disabled = true;
        info02.items.add(info02E00);
      
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info02E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info02E01.id = 'Facturación mensual';
        info02E01.title = '$'+AcqActWrp.billing.debit.own.amount+'MXN';
        info02E01.checked = true;
        info02E01.disabled = true;
        info02.items.add(info02E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info02E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info02E02.id = 'Ticket promedio';
        info02E02.title = '$'+AcqActWrp.tickets.debit.own.amount+'MXN';
        info02E02.checked = true;
        info02E02.disabled = true;
        info02.items.add(info02E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info02E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info02E03.id = '% Mix';
        info02E03.title = (AcqActWrp.percentage.debit.mixOwn * 100)+'%';
        info02E03.checked = true;
        info02E03.disabled = true;
        info02.items.add(info02E03);

        content.categories.add(info02);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info03 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info03.id = 'info03';
        info03.title = 'Información simulada del cliente - Débito ajeno';
        info03.description = '';
        info03.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info03E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info03E00.id = '# Transacciones';
        info03E00.title = ''+AcqActWrp.transaction_y.debit.thirdParty;
        info03E00.checked = true;
        info03E00.disabled = true;
        info03.items.add(info03E00);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info03E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info03E01.id = 'Facturación mensual';
        info03E01.title = '$'+AcqActWrp.billing.debit.thirdParty.amount+'MXN';
        info03E01.checked = true;
        info03E01.disabled = true;
        info03.items.add(info03E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info03E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info03E02.id = 'Ticket promedio';
        info03E02.title = '$'+AcqActWrp.tickets.debit.thirdParty.amount+'MXN';
        info03E02.checked = true;
        info03E02.disabled = true;
        info03.items.add(info03E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info03E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info03E03.id = '% Mix';
        info03E03.title = (AcqActWrp.percentage.debit.mixExternal * 100)+'%';
        info03E03.checked = true;
        info03E03.disabled = true;
        info03.items.add(info03E03);

        content.categories.add(info03);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info04 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info04.id = 'info04';
        info04.title = 'Información simulada del cliente - Crédito propio';
        info04.description = '';
        info04.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info04E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info04E00.id = '# Transacciones';
        info04E00.title = ''+AcqActWrp.transaction_y.credit.own;
        info04E00.checked = true;
        info04E00.disabled = true;
        info04.items.add(info04E00);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info04E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info04E01.id = 'Facturación mensual';
        info04E01.title = '$'+AcqActWrp.billing.credit.own.amount+'MXN';
        info04E01.checked = true;
        info04E01.disabled = true;
        info04.items.add(info04E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info04E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info04E02.id = 'Ticket promedio';
        info04E02.title = '$'+AcqActWrp.tickets.credit.own.amount+'MXN';
        info04E02.checked = true;
        info04E02.disabled = true;
        info04.items.add(info04E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info04E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info04E03.id = '% Mix';
        info04E03.title = (AcqActWrp.percentage.credit.mixOwn * 100)+'%';
        info04E03.checked = true;
        info04E03.disabled = true;
        info04.items.add(info04E03);

        content.categories.add(info04);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info05 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info05.id = 'info05';
        info05.title = 'Información simulada del cliente - Crédito ajeno';
        info05.description = '';
        info05.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info05E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info05E00.id = '# Transacciones';
        info05E00.title = ''+AcqActWrp.transaction_y.credit.thirdParty;
        info05E00.checked = true;
        info05E00.disabled = true;
        info05.items.add(info05E00);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info05E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info05E01.id = 'Facturación mensual';
        info05E01.title = '$'+AcqActWrp.billing.credit.thirdParty.amount+'MXN';
        info05E01.checked = true;
        info05E01.disabled = true;
        info05.items.add(info05E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info05E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info05E02.id = 'Ticket promedio';
        info05E02.title = '$'+AcqActWrp.tickets.credit.thirdParty.amount+'MXN';
        info05E02.checked = true;
        info05E02.disabled = true;
        info05.items.add(info05E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info05E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info05E03.id = '% Mix';
        info05E03.title = (AcqActWrp.percentage.credit.mixExternal * 100)+'%';
        info05E03.checked = true;
        info05E03.disabled = true;
        info05.items.add(info05E03);

        content.categories.add(info05);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info06 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info06.id = 'info06';
        info06.title = 'Información simulada del cliente - Internacional';
        info06.description = '';
        info06.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info06E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info06E00.id = '# Transacciones';
        info06E00.title = ''+AcqActWrp.transaction_y.international;
        info06E00.checked = true;
        info06E00.disabled = true;
        info06.items.add(info06E00);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info06E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info06E01.id = 'Facturación mensual';
        info06E01.title = '$'+AcqActWrp.billing.international.amount+'MXN';
        info06E01.checked = true;
        info06E01.disabled = true;
        info06.items.add(info06E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info06E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info06E02.id = 'Ticket promedio';
        info06E02.title = '$'+AcqActWrp.tickets.international.amount+'MXN';
        info06E02.checked = true;
        info06E02.disabled = true;
        info06.items.add(info06E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info06E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info06E03.id = '% Mix';
        info06E03.title = (AcqActWrp.percentage.mixInternational * 100)+'%';
        info06E03.checked = true;
        info06E03.disabled = true;
        info06.items.add(info06E03);

        content.categories.add(info06);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info07 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info07.id = 'info07';
        info07.title = 'Información simulada del cliente - Total';
        info07.description = '';
        info07.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info07E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info07E00.id = '# Transacciones';
        info07E00.title = ''+AcqActWrp.transaction_y.acquirerAffiliation;
        info07E00.checked = true;
        info07E00.disabled = true;
        info07.items.add(info07E00);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info07E01 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info07E01.id = 'Facturación mensual';
        info07E01.title = '$'+AcqActWrp.billing.totalAmount.amount+'MXN';
        info07E01.checked = true;
        info07E01.disabled = true;
        info07.items.add(info07E01);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info07E02 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info07E02.id = 'Ticket promedio';
        info07E02.title = '$'+AcqActWrp.tickets.totalAmount.amount+'MXN';
        info07E02.checked = true;
        info07E02.disabled = true;
        info07.items.add(info07E02);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info07E03 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info07E03.id = '% Mix';
        info07E03.title = (AcqActWrp.percentage.total * 100)+'%';
        info07E03.checked = true;
        info07E03.disabled = true;
        info07.items.add(info07E03);

        content.categories.add(info07);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info08 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info08.id = 'info08';
        info08.title = 'Dispositivos simulados - Terminal Punto de Venta';
        info08.description = '';
        info08.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info08E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info08E00.id = 'No. Dispositivos';
        info08E00.title = ''+AcqActWrp.terminal.id_y;
        info08E00.checked = true;
        info08E00.disabled = true;
        info08.items.add(info08E00);

        content.categories.add(info08);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info09 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info09.id = 'info09';
        info09.title = 'Dispositivos simulados - Interredes con pinpad';
        info09.description = '';
        info09.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info09E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info09E00.id = 'No. Dispositivos';
        info09E00.title = ''+AcqActWrp.devices.pinPads.pinPadsNumber;
        info09E00.checked = true;
        info09E00.disabled = true;
        info09.items.add(info09E00);

        content.categories.add(info09);
        
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info10 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info10.id = 'info10';
        info10.title = 'Dispositivos simulados - Ecommerce';
        info10.description = '';
        info10.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info10E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info10E00.id = 'No. Dispositivos';
        if(AcqActWrp.ecommerce == 'N'){
            info10E00.title = 'No';
        }else {
            info10E00.title = 'Si';
        }
        info10E00.checked = true;
        info10E00.disabled = true;
        info10.items.add(info10E00);

        content.categories.add(info10);

        final tmpb.TemplateBuilder.TemplateBuilderContentCategory info11 = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        info11.id = 'info11';
        info11.title = 'Dispositivos simulados - Total';
        info11.description = '';
        info11.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
		
        final tmpb.TemplateBuilder.TemplateBuilderContentItem info11E00 = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        info11E00.id = 'No. Dispositivos';
        info11E00.title = ''+AcqActWrp.devices.devicesNumber;
        info11E00.checked = true;
        info11E00.disabled = true;
        info11.items.add(info11E00);

        content.categories.add(info11);

        return content;
    }
    
    tmpb.TemplateBuilder.TemplateBuilderContent getRecipients(Id recordId) {
        /*final tmpb.TemplateBuilder.TemplateBuilderContent dpmxRecipientsContent = new tmpb.TemplateBuilder.TemplateBuilderContent();
        final list<tmpb.TemplateBuilder.TemplateBuilderContentCategory> dpmxRecipientsContentCategorylst = new list<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();
        final list<tmpb.TemplateBuilder.TemplateBuilderContentItem> dpmxRecipientsContentItemOwner = new list<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
        final list<tmpb.TemplateBuilder.TemplateBuilderContentItem> dpmxRecipientsContentItemlst = new list<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
        
        final DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT OwnerId, Owner.Name, Owner.Email, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Id =:recordId];
        final string companyNameId = dynamicPricing.Company_Name__c;

        dpmxRecipientsContentItemOwner.add(createTemplateBuilderContentItem(dynamicPricing.Owner.Id, dynamicPricing.Owner.Name, dynamicPricing.Owner.Email, '', 'cc', true, false));
        
        dpmxRecipientsContentCategorylst.add(createTemplateBuilderContentCategory('Owner_Id','BBVA recipients','standard:user','Please, select BBVA recipients', dpmxRecipientsContentItemOwner));
        
        dpmxRecipientsContent.id = 'dpmxRecipients';
        dpmxRecipientsContent.name = 'DPMX Recipients';
        dpmxRecipientsContent.categories = dpmxRecipientsContentCategorylst;
        
        return dpmxRecipientsContent;*/

        final tmpb.TemplateBuilder.TemplateBuilderContent dpmxRecipientsContent = new tmpb.TemplateBuilder.TemplateBuilderContent();
        final list<tmpb.TemplateBuilder.TemplateBuilderContentCategory> dpmxRecipientsContentCategorylst = new list<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();
        final list<tmpb.TemplateBuilder.TemplateBuilderContentItem> dpmxRecipientsContentItemOwner = new list<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
        final list<tmpb.TemplateBuilder.TemplateBuilderContentItem> dpmxRecipientsContentItemlst = new list<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
        
        final DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT OwnerId, Owner.Name, Owner.Email, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Id =:recordId];
        final string companyNameId = dynamicPricing.Company_Name__c;
        final List<Contact> contacts = [SELECT id, name, email FROM Contact WHERE AccountId =:companyNameId];
        
        dpmxRecipientsContentItemOwner.add(createTemplateBuilderContentItem(dynamicPricing.Owner.Id, dynamicPricing.Owner.Name, dynamicPricing.Owner.Email, '', 'to', true, false));
        
        dpmxRecipientsContentCategorylst.add(createTemplateBuilderContentCategory('Owner_Id','BBVA recipients','standard:user','Please, select BBVA recipients', dpmxRecipientsContentItemOwner));
        
        /*
        for(Contact cont : contacts)
        {
            dpmxRecipientsContentItemlst.add(createTemplateBuilderContentItem('2F0053M000003PHmsQAG', dynamicPricing.Owner.Name, dynamicPricing.Owner.Email, '', 'cc', true, false));
        }
        dpmxRecipientsContentCategorylst.add(createTemplateBuilderContentCategory('Contacts_Id','Contacts','standard:contact','Please, select contacts recipients', dpmxRecipientsContentItemlst));
        */
        dpmxRecipientsContent.id = 'dpmxRecipients';
        dpmxRecipientsContent.name = 'DPMX Recipients';
        dpmxRecipientsContent.categories = dpmxRecipientsContentCategorylst;
        
        return dpmxRecipientsContent;
    }
    
    tmpb.TemplateBuilder.TemplateBuilderContent renderContent(Id recordId, Object args) {
        final List<String> info00 = new List<String>();
        final List<String> conditionIds = new List<String>();
        
        final tmpb.TemplateBuilder.TemplateBuilderContent renderedContent = new tmpb.TemplateBuilder.TemplateBuilderContent();
        renderedContent.rendered = new List<tmpb.TemplateBuilder.TemplateBuilderRenderedElement>();
        
        System.debug('args: '+args);
        final tmpb.TemplateBuilder.TemplateBuilderRenderedElement renElement = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
            try {
                final tmpb.TemplateBuilder.TemplateBuilderArgs ids;
                ids = (tmpb.TemplateBuilder.TemplateBuilderArgs) System.JSON.deserialize((String)args, tmpb.TemplateBuilder.TemplateBuilderArgs.class);
                System.debug('ids: '+ids);
                System.debug('ids.TemplateBuilderArgs: '+ids.selectedIds);
                
                for (String selected : ids.selectedIds ) {
                	List<String> pair = selected.split('-');
                    System.debug('sw: '+pair);
                    renElement.key = pair[0];
                    renElement.value = pair[1];
                    renderedContent.rendered.add(renElement);
                    switch on (String)pair[0] {
                    	when 'info00' {
                        	System.debug('info00: '+pair[1]);
                            info00.add(pair[1]);
                    	}
                    	when 'flatrates' {
                        	System.debug('---: '+pair[1]);
                    	}
                    	when else {
                        	System.debug('Else-0: '+pair[0]);
                        	System.debug('Else-1: '+pair[1]);
                        	conditionIds.add(pair[1]);
                    	}
                	}
            	}
                System.debug('conditionIds: '+conditionIds);
                // Rendered Conditions
                if (info00.size() > 0) {
                    for(integer i=0; i != info00.size(); i++){
                        final tmpb.TemplateBuilder.TemplateBuilderRenderedElement info00Element = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
                    	info00Element.key = 'info00-'+i;
                    	info00Element.value = info00[i];
                    	System.debug('info00Element: '+info00Element);
                    	renderedContent.rendered.add(info00Element);
                    }
                }
            } catch(Exception e) {
                final tmpb.TemplateBuilder.TemplateBuilderRenderedElement element = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
                element.key ='error';
                element.value = e.getMessage();
                System.debug('e.getMessage();'+e.getMessage());
                renderedContent.rendered.add(element);
            }
            System.debug(renderedContent);
        return renderedContent;
    }
    Boolean handleResult(Id recordId, Object args) {
        return true;
    }
    Boolean isUserAllowed(Id recordId) {
        return true;
    }
    
    private static tmpb.TemplateBuilder.TemplateBuilderContent createTemplateBuilderContent (String id, String name, String description, List<tmpb.TemplateBuilder.TemplateBuilderContentCategory> categories, List<tmpb.TemplateBuilder.TemplateBuilderRenderedElement> rendered) {
        final tmpb.TemplateBuilder.TemplateBuilderContent content = new tmpb.TemplateBuilder.TemplateBuilderContent();
        content.id = id;
        content.name = name; //Not Req.
        content.description = description; //Not Req.
        content.categories = categories; //Not Req.
        content.rendered = rendered; //Not Req.
        
        return content;
    }
    
    private static tmpb.TemplateBuilder.TemplateBuilderContentCategory createTemplateBuilderContentCategory (String id, String title, String icon, String description, List<tmpb.TemplateBuilder.TemplateBuilderContentItem> items) {
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory category = new tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        category.id = id;
        category.title = title;
        category.icon = icon;
        category.description = description; //Not Req.
        category.items = items;
        
        return category;
    }
    
    private static tmpb.TemplateBuilder.TemplateBuilderContentItem createTemplateBuilderContentItem (String id, String title, String value, String type, String decription, Boolean checked, Boolean disabled) {
        final tmpb.TemplateBuilder.TemplateBuilderContentItem item = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        item.id = id;
        item.title = title;
        item.value = value;
        item.type = type;
        item.description = decription;
        item.checked = checked;
        item.disabled = disabled; //Not Req.
        
        return item;
    }

    public class Discount_Rates_Wrapper {
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal international {get; set;}
    }

    public class Company_Info {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal international {get; set;}
    }
}