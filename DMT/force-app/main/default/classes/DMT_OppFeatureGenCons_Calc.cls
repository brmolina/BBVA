public with sharing class DMT_OppFeatureGenCons_Calc {
     public static List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> checkValidations(Opportunity opp, String clientsGroup){
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> listFeatureReturn = new List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations>();
        if(opp != null){
            Map<Id,DMT_X_Sell__c> xSellmap = new Map<Id,DMT_X_Sell__c>(opp.X_sell__r);
            Map<Id,OpportunityLineItem> productsMap = new Map<Id,OpportunityLineItem>(opp.OpportunityLineItems);
            List<DMT_Opportunity_Tenor__c> amortizationPayments = new List<DMT_Opportunity_Tenor__c>();
            for(OpportunityLineItem oli : productsMap.values()){
                if (oli.Opportunity_Tenors__r != null && !oli.Opportunity_Tenors__r.isEmpty()) {
                    amortizationPayments.addAll(oli.Opportunity_Tenors__r);
                }
            }
            Map<Id,DMT_Opportunity_Tenor__c> tenorsMap = new Map<Id,DMT_Opportunity_Tenor__c>(amortizationPayments);
            DMT_Opportunity_Client__c oppClient = (opp.DMT_MDE_Opportunities_Clients__r?.isEmpty() == false) ? opp.DMT_MDE_Opportunities_Clients__r[0] : null;


            //Validate Internal Rating
            Boolean isInternalRatingEqual = oppClient != null && oppClient.g_upd_lmscl_internal_ratg_type__c == opp.Account.DES_Rating_Int__c;
            if(isInternalRatingEqual){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Internal Rating is consistent with Client Internal Rating.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Rating is consistent'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Internal Rating is not consistent with Client Internal Rating.',DMT_Constants.FEATURE_GC_STATE_RED,'Rating is inconsistent'));
            }

            //Validate Client Type
            Boolean isClientTypeEqual = opp != null && opp.DMT_Client_Type__c == opp.Account.DES_Client_Type__c;
            if(isClientTypeEqual){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Client Type is consistent with Client Type.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Client Type is consistent'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Client Type is not consistent with Client Type.',DMT_Constants.FEATURE_GC_STATE_RED,'Client Type is inconsistent'));
            }

            //Validate XSELL
            Integer yearLimit = opp.DMT_DATE_Initial_Date__c != null ? opp.DMT_DATE_Initial_Date__c.year() + 5 : System.now().date().year() + 5;
            Boolean xSellLimit = false;
            for (DMT_X_Sell__c xSell : xSellmap.values()) {
                if (xSell.Year__c != null && Integer.valueOf(xSell.Year__c) > yearLimit) {
                    xSellLimit = true;
                }
            }
            if(xSellLimit){
                listFeatureReturn.add(generateFeatureGenConsideration('One or more Cross SELL records have a Year beyond 5 years from the Opportunity Initial Date',DMT_Constants.FEATURE_GC_STATE_RED,'Cross SELL Year is inconsistent'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('All Cross SELL records have a Year within 5 years from the Opportunity Initial Date.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Cross SELL Year is consistent'));
            }

            //Validate Tenors
            Boolean userDefinedNotPaymentDate = false;
            for (DMT_Opportunity_Tenor__c tenorItem : tenorsMap.values()) {
                if (productsMap.get(tenorItem.DMT_Opportunity_Product__c).gf_amortization_type__c == 'User-Defined' && tenorItem.gf_tenor_date__c == null) {
                    userDefinedNotPaymentDate = true;
                }
            }
            if(userDefinedNotPaymentDate){
                listFeatureReturn.add(generateFeatureGenConsideration('Inconsistent Payment Date detected in Tenors for product type User-Defined',DMT_Constants.FEATURE_GC_STATE_RED,'Tenors Payment Date is inconsistent'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Consistent Payment Date detected in Tenors for product type User-Defined',DMT_Constants.FEATURE_GC_STATE_GREEN,'Tenors Payment Date is consistent'));

            }

            //Validate Opportunity Products
            Boolean oppProductInitialDate = false;
            Boolean oppProductMaturityDate = true;

            for (OpportunityLineItem oppProduct : productsMap.values()) {
                if(oppProduct.gf_initial_date__c != opp.DMT_DATE_Initial_Date__c) {
                    oppProductInitialDate = true;
                }
                if(oppProduct.gf_maturity_date__c != opp.DMT_DATE_Maturity_Date__c) {
                    oppProductMaturityDate = false;
                }

            }
            if(oppProductMaturityDate){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Maturity Date is consistent with Opportunity Products Maturity Dates',DMT_Constants.FEATURE_GC_STATE_GREEN,'Maturity Date consistency'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Maturity Date is not consistent with Opportunity Products Maturity Dates',DMT_Constants.FEATURE_GC_STATE_RED,'Maturity Date inconsistency'));

            }
            if(oppProductInitialDate){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Initial Date is not consistent with Opportunity Products Initial Dates',DMT_Constants.FEATURE_GC_STATE_RED,'Initial Date inconsistency'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Initial Date is consistent with Opportunity Products Initial Dates',DMT_Constants.FEATURE_GC_STATE_GREEN,'Initial Date consistency'));
            }

            //Validate Opportunity
            if(opp.DMT_CUR_Notional_Amount__c == opp.DMT_Notional_Items_Sum__c){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Notional Amount is consistent with Opportunity Products Notional Amounts Sum',DMT_Constants.FEATURE_GC_STATE_GREEN,'Notional Amount consistency'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Notional Amount is not consistent with Opportunity Products Notional Amounts Sum',DMT_Constants.FEATURE_GC_STATE_RED,'Notional Amount inconsistency'));
            }

            //Validate Line Relation to Opp
            List<String> productsNotLinked = new List<String>();
            String products = '';
            if(opp.DMT_Sanction__c != null){
                for(OpportunityLineItem opplineitem: productsMap.values()){
                    if(opplineitem.DMT_Associated_Line_Product__c == null){
                        productsNotLinked.add(opplineitem.Name);
                    }
                }
                if(!productsNotLinked.isEmpty()){
                    for(String productName : productsNotLinked){
                        if(productsNotLinked.indexOf(productName) == productsNotLinked.size() - 1 ){
                            products = products + 'and ' + productName;
                        }else{
                            products = products + productName + ',';
                        }
                    }
                    listFeatureReturn.add(generateFeatureGenConsideration('The following products have not been linked to risk approval line: ' + products,DMT_Constants.FEATURE_GC_STATE_RED,'Opportunity risk approval'));
                }else{
                    listFeatureReturn.add(generateFeatureGenConsideration('All opportunity products have risk approval line coverage' + products,DMT_Constants.FEATURE_GC_STATE_GREEN,'Opportunity risk approval'));
                }
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity risk to be checked under Finantial Program limits' + products,DMT_Constants.FEATURE_GC_STATE_GREEN,'Opportunity risk approval'));
            }
            
            
        }

        return listFeatureReturn;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations generateFeatureGenConsideration(String message, String state, String name){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations featureReturn = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        featureReturn.message = message;
        featureReturn.state = state;
        featureReturn.name = name;
        return featureReturn;
    }
}