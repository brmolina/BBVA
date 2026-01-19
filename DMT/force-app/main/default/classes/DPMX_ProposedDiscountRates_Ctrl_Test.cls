/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_ProposedDiscountRates_Ctrl_Test
* Test class for DPMX_ProposedDiscountRates_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-22
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_ProposedDiscountRates_Ctrl_Test {
	@TestSetup
    static void createData() {

    }
    
    @IsTest
    static void updateFieldsIsGSTrueTest(){
        
        /************************ BEGINNING BILLING ************************************/
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bcoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bcoac.amount = 1;
                        bcoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bctac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bctac.amount = 2;
                        bctac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer bcot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    bcot.own = bcoac;
                    bcot.thirdParty = bctac;
        
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bdoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bdoac.amount = 3;
                        bdoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bdtac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bdtac.amount = 4;
                        bdtac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer bdot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    bdot.own = bdoac;
                    bdot.thirdParty = bdtac;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency biac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    biac.amount = 5;
                    biac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency btac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    btac.amount = 6;
                    btac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.billing bcdit = new DPMX_AcquirerActivity_Wrapper.Billing();
                bcdit.credit = bcot;
                bcdit.debit = bdot;
                bcdit.international = biac;
                bcdit.totalAmount = btac;
        /************************ END BILLING ************************************/
        
        
        /************************ BEGINNING DEVICESINFO ************************************/
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.DevicesInfo devInf = new DPMX_AcquirerActivity_Wrapper.DevicesInfo();
                devInf.devices = 7;
        /************************ END DEVICESINFO ************************************/
        
        
        /************************ BEGINNING DISCOUNT ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency daac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    daac.amount = 8;
                    daac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency dcac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    dcac.amount = 9;
                    dcac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.Debit ddmn = new DPMX_AcquirerActivity_Wrapper.Debit();
                    ddmn.mark = 'marca';
                    ddmn.number_y = 10;
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Percentage dpci = new DPMX_AcquirerActivity_Wrapper.Percentage();
                    dpci.credit = 11;
                    dpci.international = 12;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.discount dacdp = new DPMX_AcquirerActivity_Wrapper.discount();
                dacdp.amount = daac;
                dacdp.card = dcac;
                dacdp.debit = ddmn;
                dacdp.percentage = dpci;
        /************************ END DISCOUNT ************************************/
        
        
        /************************ BEGINNING EXPENSES ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency emac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    emac.amount = 13;
                    emac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency etac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    etac.amount = 14;
                    etac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.expenses emt = new DPMX_AcquirerActivity_Wrapper.expenses();
                emt.mit = emac;
                emt.totalAmount = etac;
        /************************ END EXPENSES ************************************/
        
        /************************ BEGINNING FEES ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency fbac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    fbac.amount = 15;
                    fbac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency fcac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    fcac.amount = 16;
                    fcac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency feac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    feac.amount = 17;
                    feac.currency_y = 'MXN';
        
                    //ROSA    
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency focac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        focac.amount = 18;
                        focac.currency_y = 'MXN';
                    //ROSA    
                     DPMX_AcquirerActivity_Wrapper.AmountCurrency folac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        folac.amount = 19;
                        folac.currency_y = 'MXN';
                    //ROSA    
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency fopac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        fopac.amount = 42;
                        fopac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Opportunity foclp = new DPMX_AcquirerActivity_Wrapper.Opportunity();
                    foclp.cellnet = focac;
                    foclp.lowBilling = folac;
                    foclp.posExtra = fopac;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.fees fbceo = new DPMX_AcquirerActivity_Wrapper.fees();
                fbceo.billing = fbac;
                fbceo.cellnet = fcac;
                fbceo.extraBilling = feac;
                fbceo.opportunity = foclp;
        /************************ END FEES ************************************/
        
        
        /************************ BEGINNING PERCENTAGE ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.Mix pcmm = new DPMX_AcquirerActivity_Wrapper.Mix();
                    pcmm.mixExternal = 20;
                    pcmm.mixOwn = 21;
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Mix pdmm = new DPMX_AcquirerActivity_Wrapper.Mix();
                    pdmm.mixExternal = 22;
                    pdmm.mixOwn = 23;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.PercentageContainer pcdmt = new DPMX_AcquirerActivity_Wrapper.PercentageContainer();
                pcdmt.credit = pcmm;
                pcdmt.debit = pcmm;
                pcdmt.mixInternational = 24;
                pcdmt.total = 25;
        /************************ END PERCENTAGE ************************************/
        
        
        /************************ BEGINNING PINPADSINFO ************************************/
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.pinPadsInfo pinPadsInfo = new DPMX_AcquirerActivity_Wrapper.pinPadsInfo();
                pinPadsInfo.pinPads = 26;
        /************************ END PINPADSINFO ************************************/
        
        
        /************************ BEGINNING TAXACQUIRER ************************************/
            //AMARILLO    
            DPMX_AcquirerActivity_Wrapper.AmountCurrency taxAcquirer = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                taxAcquirer.amount = 27;
                taxAcquirer.currency_y = 'MXN';
        /************************ END TAXACQUIRER ************************************/
        
        
        /************************ BEGINNING TERMINAL ************************************/
            //AMARILLO    
            DPMX_AcquirerActivity_Wrapper.terminal terminal = new DPMX_AcquirerActivity_Wrapper.terminal();
                terminal.id_y = 28;
        /************************ END TERMINAL ************************************/
        
        
        /************************ BEGINNING TICKETS ************************************/
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tcoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tcoac.amount = 29;
                        tcoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tctac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tctac.amount = 30;
                        tctac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer tcot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    tcot.own = tcoac;
                    tcot.thirdParty = tctac;
        
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tdoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tdoac.amount = 31;
                        tdoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tdtac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tdtac.amount = 32;
                        tdtac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer tdot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    tdot.own = bdoac;
                    tdot.thirdParty = bdtac;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency tiac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    tiac.amount = 33;
                    tiac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency ttac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    ttac.amount = 34;
                    ttac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.tickets tcdit = new DPMX_AcquirerActivity_Wrapper.tickets();
                tcdit.credit = tcot;
                tcdit.debit = tdot;
                tcdit.international = tiac;
                tcdit.totalAmount = ttac;
        /************************ END TICKET ************************************/
        
        
        /************************ BEGINNING TRANSACTION ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdParty tcoty = new DPMX_AcquirerActivity_Wrapper.OwnThirdParty();
                    tcoty.own = 36;
                    tcoty.thirdParty = 37;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdParty tdoty = new DPMX_AcquirerActivity_Wrapper.OwnThirdParty();
                    tdoty.own = 38;
                    tdoty.thirdParty = 39;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.Transaction_y tacdi = new DPMX_AcquirerActivity_Wrapper.Transaction_y();
                tacdi.acquirerAffiliation = 35;
                tacdi.credit = tcoty;
                tacdi.debit = tdoty;
                tacdi.international = 40;
        /************************ END TRANSACTION ************************************/

        //VERDE
        DPMX_AcquirerActivity_Wrapper acquirerActivityWrapper = new DPMX_AcquirerActivity_Wrapper();
            acquirerActivityWrapper.billing = bcdit;
            acquirerActivityWrapper.businessGroupName = 'businessGroupName';
            acquirerActivityWrapper.companyName = 'companyName';
            acquirerActivityWrapper.devicesInfo = devInf;
            acquirerActivityWrapper.discount = dacdp;
            acquirerActivityWrapper.ecommerce = 'ecommerce';
            acquirerActivityWrapper.expenses = emt;
            acquirerActivityWrapper.familyAcquirer ='familyAcquirer';
            acquirerActivityWrapper.fees = fbceo;
            acquirerActivityWrapper.infoDate = 'infoDate'; 
            acquirerActivityWrapper.percentage = pcdmt;
            acquirerActivityWrapper.pinPadsInfo = pinPadsInfo;
            acquirerActivityWrapper.ratesResult = 'ratesResult';
            acquirerActivityWrapper.taxAcquirer = taxAcquirer;
            acquirerActivityWrapper.terminal = terminal;
            acquirerActivityWrapper.tickets = tcdit;
            acquirerActivityWrapper.transaction_y = tacdi;
            acquirerActivityWrapper.yield = '41';//¿?STRING
       		acquirerActivityWrapper.isGS = true;
        
        /************************************************************************************/
        
        DPMX_ProposedDiscountRates_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_ProposedDiscountRates_Ctrl.Discount_Rates_Wrapper();
        	interchangeRates.credit = 1.2;
            interchangeRates.debit = 3.4;
            interchangeRates.international = 5.6;
        
        
        Test.startTest();
           	Map<String, Object> retMap = DPMX_ProposedDiscountRates_Ctrl.updateFields(acquirerActivityWrapper, interchangeRates, true, 6.5, 4.3, 2.1); 
    //    	System.assertEquals(retMap.get('dynamicPricingUpsert'), dynamicPricingTest, 'retMapDynamicPricing OK');
        Test.stopTest();
    }
    
    @IsTest
    static void updateFieldsIsGSFalseTest(){
        
        /************************ BEGINNING BILLING ************************************/
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bcoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bcoac.amount = 1;
                        bcoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bctac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bctac.amount = 2;
                        bctac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer bcot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    bcot.own = bcoac;
                    bcot.thirdParty = bctac;
        
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bdoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bdoac.amount = 3;
                        bdoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bdtac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bdtac.amount = 4;
                        bdtac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer bdot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    bdot.own = bdoac;
                    bdot.thirdParty = bdtac;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency biac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    biac.amount = 5;
                    biac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency btac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    btac.amount = 6;
                    btac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.billing bcdit = new DPMX_AcquirerActivity_Wrapper.Billing();
                bcdit.credit = bcot;
                bcdit.debit = bdot;
                bcdit.international = biac;
                bcdit.totalAmount = btac;
        /************************ END BILLING ************************************/
        
        
        /************************ BEGINNING DEVICESINFO ************************************/
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.DevicesInfo devInf = new DPMX_AcquirerActivity_Wrapper.DevicesInfo();
                devInf.devices = 7;
        /************************ END DEVICESINFO ************************************/
        
        
        /************************ BEGINNING DISCOUNT ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency daac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    daac.amount = 8;
                    daac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency dcac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    dcac.amount = 9;
                    dcac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.Debit ddmn = new DPMX_AcquirerActivity_Wrapper.Debit();
                    ddmn.mark = 'marca';
                    ddmn.number_y = 10;
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Percentage dpci = new DPMX_AcquirerActivity_Wrapper.Percentage();
                    dpci.credit = 11;
                    dpci.international = 12;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.discount dacdp = new DPMX_AcquirerActivity_Wrapper.discount();
                dacdp.amount = daac;
                dacdp.card = dcac;
                dacdp.debit = ddmn;
                dacdp.percentage = dpci;
        /************************ END DISCOUNT ************************************/
        
        
        /************************ BEGINNING EXPENSES ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency emac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    emac.amount = 13;
                    emac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency etac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    etac.amount = 14;
                    etac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.expenses emt = new DPMX_AcquirerActivity_Wrapper.expenses();
                emt.mit = emac;
                emt.totalAmount = etac;
        /************************ END EXPENSES ************************************/
        
        /************************ BEGINNING FEES ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency fbac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    fbac.amount = 15;
                    fbac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency fcac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    fcac.amount = 16;
                    fcac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency feac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    feac.amount = 17;
                    feac.currency_y = 'MXN';
        
                    //ROSA    
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency focac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        focac.amount = 18;
                        focac.currency_y = 'MXN';
                    //ROSA    
                     DPMX_AcquirerActivity_Wrapper.AmountCurrency folac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        folac.amount = 19;
                        folac.currency_y = 'MXN';
                    //ROSA    
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency fopac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        fopac.amount = 42;
                        fopac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Opportunity foclp = new DPMX_AcquirerActivity_Wrapper.Opportunity();
                    foclp.cellnet = focac;
                    foclp.lowBilling = folac;
                    foclp.posExtra = fopac;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.fees fbceo = new DPMX_AcquirerActivity_Wrapper.fees();
                fbceo.billing = fbac;
                fbceo.cellnet = fcac;
                fbceo.extraBilling = feac;
                fbceo.opportunity = foclp;
        /************************ END FEES ************************************/
        
        
        /************************ BEGINNING PERCENTAGE ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.Mix pcmm = new DPMX_AcquirerActivity_Wrapper.Mix();
                    pcmm.mixExternal = 20;
                    pcmm.mixOwn = 21;
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Mix pdmm = new DPMX_AcquirerActivity_Wrapper.Mix();
                    pdmm.mixExternal = 22;
                    pdmm.mixOwn = 23;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.PercentageContainer pcdmt = new DPMX_AcquirerActivity_Wrapper.PercentageContainer();
                pcdmt.credit = pcmm;
                pcdmt.debit = pcmm;
                pcdmt.mixInternational = 24;
                pcdmt.total = 25;
        /************************ END PERCENTAGE ************************************/
        
        
        /************************ BEGINNING PINPADSINFO ************************************/
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.pinPadsInfo pinPadsInfo = new DPMX_AcquirerActivity_Wrapper.pinPadsInfo();
                pinPadsInfo.pinPads = 26;
        /************************ END PINPADSINFO ************************************/
        
        
        /************************ BEGINNING TAXACQUIRER ************************************/
            //AMARILLO    
            DPMX_AcquirerActivity_Wrapper.AmountCurrency taxAcquirer = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                taxAcquirer.amount = 27;
                taxAcquirer.currency_y = 'MXN';
        /************************ END TAXACQUIRER ************************************/
        
        
        /************************ BEGINNING TERMINAL ************************************/
            //AMARILLO    
            DPMX_AcquirerActivity_Wrapper.terminal terminal = new DPMX_AcquirerActivity_Wrapper.terminal();
                terminal.id_y = 28;
        /************************ END TERMINAL ************************************/
        
        
        /************************ BEGINNING TICKETS ************************************/
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tcoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tcoac.amount = 29;
                        tcoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tctac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tctac.amount = 30;
                        tctac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer tcot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    tcot.own = tcoac;
                    tcot.thirdParty = tctac;
        
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tdoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tdoac.amount = 31;
                        tdoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tdtac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tdtac.amount = 32;
                        tdtac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer tdot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    tdot.own = bdoac;
                    tdot.thirdParty = bdtac;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency tiac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    tiac.amount = 33;
                    tiac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency ttac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    ttac.amount = 34;
                    ttac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.tickets tcdit = new DPMX_AcquirerActivity_Wrapper.tickets();
                tcdit.credit = tcot;
                tcdit.debit = tdot;
                tcdit.international = tiac;
                tcdit.totalAmount = ttac;
        /************************ END TICKET ************************************/
        
        
        /************************ BEGINNING TRANSACTION ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdParty tcoty = new DPMX_AcquirerActivity_Wrapper.OwnThirdParty();
                    tcoty.own = 36;
                    tcoty.thirdParty = 37;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdParty tdoty = new DPMX_AcquirerActivity_Wrapper.OwnThirdParty();
                    tdoty.own = 38;
                    tdoty.thirdParty = 39;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.Transaction_y tacdi = new DPMX_AcquirerActivity_Wrapper.Transaction_y();
                tacdi.acquirerAffiliation = 35;
                tacdi.credit = tcoty;
                tacdi.debit = tdoty;
                tacdi.international = 40;
        /************************ END TRANSACTION ************************************/

        //VERDE
        DPMX_AcquirerActivity_Wrapper acquirerActivityWrapper = new DPMX_AcquirerActivity_Wrapper();
            acquirerActivityWrapper.billing = bcdit;
            acquirerActivityWrapper.businessGroupName = 'businessGroupName';
            acquirerActivityWrapper.companyName = 'companyName';
            acquirerActivityWrapper.devicesInfo = devInf;
            acquirerActivityWrapper.discount = dacdp;
            acquirerActivityWrapper.ecommerce = 'ecommerce';
            acquirerActivityWrapper.expenses = emt;
            acquirerActivityWrapper.familyAcquirer ='familyAcquirer';
            acquirerActivityWrapper.fees = fbceo;
            acquirerActivityWrapper.infoDate = 'infoDate'; 
            acquirerActivityWrapper.percentage = pcdmt;
            acquirerActivityWrapper.pinPadsInfo = pinPadsInfo;
            acquirerActivityWrapper.ratesResult = 'ratesResult';
            acquirerActivityWrapper.taxAcquirer = taxAcquirer;
            acquirerActivityWrapper.terminal = terminal;
            acquirerActivityWrapper.tickets = tcdit;
            acquirerActivityWrapper.transaction_y = tacdi;
            acquirerActivityWrapper.yield = '41';//¿?STRING
       		acquirerActivityWrapper.isGS = false;
        
        /************************************************************************************/
        
        DPMX_ProposedDiscountRates_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_ProposedDiscountRates_Ctrl.Discount_Rates_Wrapper();
        	interchangeRates.credit = 1.2;
            interchangeRates.debit = 3.4;
            interchangeRates.international = 5.6;
        
        
        Test.startTest();
           	Map<String, Object> retMap = DPMX_ProposedDiscountRates_Ctrl.updateFields(acquirerActivityWrapper, interchangeRates, true, 6.5, 4.3, 2.1); 
    //    	System.assertEquals(retMap.get('dynamicPricingUpsert'), dynamicPricingTest, 'retMapDynamicPricing OK');
        Test.stopTest();
    }
    
    @IsTest
    static void updateFieldsIsGSFalseTest2(){
        
        /************************ BEGINNING BILLING ************************************/
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bcoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bcoac.amount = 1;
                        bcoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bctac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bctac.amount = 2;
                        bctac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer bcot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    bcot.own = bcoac;
                    bcot.thirdParty = bctac;
        
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bdoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bdoac.amount = 34;
                        bdoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency bdtac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        bdtac.amount = 4;
                        bdtac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer bdot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    bdot.own = bdoac;
                    bdot.thirdParty = bdtac;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency biac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    biac.amount = 5;
                    biac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency btac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    btac.amount = 6;
                    btac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.billing bcdit = new DPMX_AcquirerActivity_Wrapper.Billing();
                bcdit.credit = bcot;
                bcdit.debit = bdot;
                bcdit.international = biac;
                bcdit.totalAmount = btac;
        /************************ END BILLING ************************************/
        
        
        /************************ BEGINNING DEVICESINFO ************************************/
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.DevicesInfo devInf = new DPMX_AcquirerActivity_Wrapper.DevicesInfo();
                devInf.devices = 7;
        /************************ END DEVICESINFO ************************************/
        
        
        /************************ BEGINNING DISCOUNT ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency daac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    daac.amount = 8;
                    daac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency dcac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    dcac.amount = 9;
                    dcac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.Debit ddmn = new DPMX_AcquirerActivity_Wrapper.Debit();
                    ddmn.mark = 'marca';
                    ddmn.number_y = 10;
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Percentage dpci = new DPMX_AcquirerActivity_Wrapper.Percentage();
                    dpci.credit = 11;
                    dpci.international = 12;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.discount dacdp = new DPMX_AcquirerActivity_Wrapper.discount();
                dacdp.amount = daac;
                dacdp.card = dcac;
                dacdp.debit = ddmn;
                dacdp.percentage = dpci;
        /************************ END DISCOUNT ************************************/
        
        
        /************************ BEGINNING EXPENSES ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency emac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    emac.amount = 13;
                    emac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency etac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    etac.amount = 14;
                    etac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.expenses emt = new DPMX_AcquirerActivity_Wrapper.expenses();
                emt.mit = emac;
                emt.totalAmount = etac;
        /************************ END EXPENSES ************************************/
        
        /************************ BEGINNING FEES ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency fbac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    fbac.amount = 15;
                    fbac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency fcac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    fcac.amount = 16;
                    fcac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency feac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    feac.amount = 17;
                    feac.currency_y = 'MXN';
        
                    //ROSA    
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency focac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        focac.amount = 18;
                        focac.currency_y = 'MXN';
                    //ROSA    
                     DPMX_AcquirerActivity_Wrapper.AmountCurrency folac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        folac.amount = 19;
                        folac.currency_y = 'MXN';
                    //ROSA    
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency fopac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        fopac.amount = 42;
                        fopac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Opportunity foclp = new DPMX_AcquirerActivity_Wrapper.Opportunity();
                    foclp.cellnet = focac;
                    foclp.lowBilling = folac;
                    foclp.posExtra = fopac;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.fees fbceo = new DPMX_AcquirerActivity_Wrapper.fees();
                fbceo.billing = fbac;
                fbceo.cellnet = fcac;
                fbceo.extraBilling = feac;
                fbceo.opportunity = foclp;
        /************************ END FEES ************************************/
        
        
        /************************ BEGINNING PERCENTAGE ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.Mix pcmm = new DPMX_AcquirerActivity_Wrapper.Mix();
                    pcmm.mixExternal = 20;
                    pcmm.mixOwn = 21;
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.Mix pdmm = new DPMX_AcquirerActivity_Wrapper.Mix();
                    pdmm.mixExternal = 22;
                    pdmm.mixOwn = 23;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.PercentageContainer pcdmt = new DPMX_AcquirerActivity_Wrapper.PercentageContainer();
                pcdmt.credit = pcmm;
                pcdmt.debit = pcmm;
                pcdmt.mixInternational = 24;
                pcdmt.total = 25;
        /************************ END PERCENTAGE ************************************/
        
        
        /************************ BEGINNING PINPADSINFO ************************************/
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.pinPadsInfo pinPadsInfo = new DPMX_AcquirerActivity_Wrapper.pinPadsInfo();
                pinPadsInfo.pinPads = 26;
        /************************ END PINPADSINFO ************************************/
        
        
        /************************ BEGINNING TAXACQUIRER ************************************/
            //AMARILLO    
            DPMX_AcquirerActivity_Wrapper.AmountCurrency taxAcquirer = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                taxAcquirer.amount = 27;
                taxAcquirer.currency_y = 'MXN';
        /************************ END TAXACQUIRER ************************************/
        
        
        /************************ BEGINNING TERMINAL ************************************/
            //AMARILLO    
            DPMX_AcquirerActivity_Wrapper.terminal terminal = new DPMX_AcquirerActivity_Wrapper.terminal();
                terminal.id_y = 28;
        /************************ END TERMINAL ************************************/
        
        
        /************************ BEGINNING TICKETS ************************************/
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tcoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tcoac.amount = 29;
                        tcoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tctac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tctac.amount = 30;
                        tctac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer tcot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    tcot.own = tcoac;
                    tcot.thirdParty = tctac;
        
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tdoac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tdoac.amount = 31;
                        tdoac.currency_y = 'MXN';
                    //ROSA
                    DPMX_AcquirerActivity_Wrapper.AmountCurrency tdtac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                        tdtac.amount = 32;
                        tdtac.currency_y = 'MXN';
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer tdot = new DPMX_AcquirerActivity_Wrapper.OwnThirdPartyContainer();
                    tdot.own = bdoac;
                    tdot.thirdParty = bdtac;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.AmountCurrency tiac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    tiac.amount = 33;
                    tiac.currency_y = 'MXN';
                //AZUL    
                DPMX_AcquirerActivity_Wrapper.AmountCurrency ttac = new DPMX_AcquirerActivity_Wrapper.AmountCurrency();
                    ttac.amount = 34;
                    ttac.currency_y = 'MXN';
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.tickets tcdit = new DPMX_AcquirerActivity_Wrapper.tickets();
                tcdit.credit = tcot;
                tcdit.debit = tdot;
                tcdit.international = tiac;
                tcdit.totalAmount = ttac;
        /************************ END TICKET ************************************/
        
        
        /************************ BEGINNING TRANSACTION ************************************/
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdParty tcoty = new DPMX_AcquirerActivity_Wrapper.OwnThirdParty();
                    tcoty.own = 36;
                    tcoty.thirdParty = 37;
        
                //AZUL
                DPMX_AcquirerActivity_Wrapper.OwnThirdParty tdoty = new DPMX_AcquirerActivity_Wrapper.OwnThirdParty();
                    tdoty.own = 38;
                    tdoty.thirdParty = 39;
        
            //AMARILLO
            DPMX_AcquirerActivity_Wrapper.Transaction_y tacdi = new DPMX_AcquirerActivity_Wrapper.Transaction_y();
                tacdi.acquirerAffiliation = 35;
                tacdi.credit = tcoty;
                tacdi.debit = tdoty;
                tacdi.international = 40;
        /************************ END TRANSACTION ************************************/

        //VERDE
        DPMX_AcquirerActivity_Wrapper acquirerActivityWrapper = new DPMX_AcquirerActivity_Wrapper();
            acquirerActivityWrapper.billing = bcdit;
            acquirerActivityWrapper.businessGroupName = 'businessGroupName';
            acquirerActivityWrapper.companyName = 'companyName';
            acquirerActivityWrapper.devicesInfo = devInf;
            acquirerActivityWrapper.discount = dacdp;
            acquirerActivityWrapper.ecommerce = 'ecommerce';
            acquirerActivityWrapper.expenses = emt;
            acquirerActivityWrapper.familyAcquirer ='familyAcquirer';
            acquirerActivityWrapper.fees = fbceo;
            acquirerActivityWrapper.infoDate = 'infoDate'; 
            acquirerActivityWrapper.percentage = pcdmt;
            acquirerActivityWrapper.pinPadsInfo = pinPadsInfo;
            acquirerActivityWrapper.ratesResult = 'ratesResult';
            acquirerActivityWrapper.taxAcquirer = taxAcquirer;
            acquirerActivityWrapper.terminal = terminal;
            acquirerActivityWrapper.tickets = tcdit;
            acquirerActivityWrapper.transaction_y = tacdi;
            acquirerActivityWrapper.yield = '41';//¿?STRING
       		acquirerActivityWrapper.isGS = false;
        
        /************************************************************************************/
        
        DPMX_ProposedDiscountRates_Ctrl.Discount_Rates_Wrapper interchangeRates = new DPMX_ProposedDiscountRates_Ctrl.Discount_Rates_Wrapper();
        	interchangeRates.credit = 11411.2;
            interchangeRates.debit = 34233.4;
            interchangeRates.international = 41555.6;
        
        
        Test.startTest();
           	Map<String, Object> retMap = DPMX_ProposedDiscountRates_Ctrl.updateFields(acquirerActivityWrapper, interchangeRates, true, 23336.5, 44324.3, 12322.1); 
    //    	System.assertEquals(retMap.get('dynamicPricingUpsert'), dynamicPricingTest, 'retMapDynamicPricing OK');
        Test.stopTest();
    }
}