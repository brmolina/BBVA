public with sharing class DMT_OppFeatureGenCons_Calc {
     public static List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> checkValidations(Opportunity opp,Account validationAccount,DMT_Opportunity_Client__c oppClient, String clientsGroup){
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> listFeatureReturn = new List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations>();
        List<Object> clientsInGroups = new List<Object>();
        if(String.isNotBlank(clientsGroup)){
           clientsInGroups = (List<Object>)JSON.deserializeUntyped(clientsGroup);
        }
        string customerID;

        //tengo que distinguir caso si es multiholder o  no:
        if( !opp.Custom_Associations__r.isEmpty() &&  opp.Custom_Associations__r.size() > 0){
            customerID = opp.Custom_Associations__r[0].g_customer_id__c;
        }else{
            customerID = opp.Account.g_customer_id__c ;
        }

        String foundClientRating = null;
        Decimal foundScoringRounded = null;
        String foundUnifiedExtRatgLtFcType = null;
        String foundFitchLtRatingLcType = null;
        String foundSpLtRatingLcType = null;
        String foundMoodysLtRatingLcType = null;
        String foundAssetAllocationSectorType = null;
        String foundAssetAllocationSubSecType = null;
        String foundAssetAllocationActvyType = null;
        String foundLeveragedLendingIndType = null;
        String foundActivityMinimumLevelCode = null;
        String foundScaleLastUpdDate = null;
        String foundRatingValidityStartDate = null;
        String foundCurrentRatingToolDate = null;
        String foundFfssRegulatoryRatingDate = null;
        Object foundRtFfssvldydtmtNumber = null;
        for (Object item : clientsInGroups) {
            Map<String, Object> row = (Map<String, Object>) item;
            String cid = (String) row.get('customerId');
            if (cid != null && cid == customerID) {
                foundClientRating = (String)row.get('updLmsclInternalRatgType');
                Object scoringRaw = row.get('totalRatingScoreNumber');
                if (scoringRaw != null) {
                    foundScoringRounded = ((Decimal)scoringRaw).setScale(2, RoundingMode.HALF_UP);
                }
                foundUnifiedExtRatgLtFcType = (String)row.get('unifiedExtRatgLtFcType');
                foundFitchLtRatingLcType    = (String)row.get('fitchLtRatingLcType');
                foundSpLtRatingLcType       = (String)row.get('spLtRatingLcType');
                foundMoodysLtRatingLcType   = (String)row.get('moodysLtRatingLcType');
                foundAssetAllocationSectorType  = (String)row.get('assetAllocationSectorType');
                foundAssetAllocationSubSecType  = (String)row.get('assetAllocationSubSecType');
                foundAssetAllocationActvyType   = (String)row.get('assetAllocationActvyType');
                foundLeveragedLendingIndType    = (String)row.get('leveragedLendingIndType');
                foundActivityMinimumLevelCode = (String)row.get('activityMinimumLevelCode');
                foundScaleLastUpdDate           = (String)row.get('scaleLastUpdDate');
                foundRatingValidityStartDate    = (String)row.get('ratingValidityStartDate');
                foundCurrentRatingToolDate      = (String)row.get('currentRatingToolDate');
                foundFfssRegulatoryRatingDate   = (String)row.get('ffssRegulatoryRatingDate');
                foundRtFfssvldydtmtNumber       = row.get('rtFfssvldydtmtNumber');
                break; // paramos en la primera coincidencia
            }
        }
        if(foundClientRating != null){
            System.debug('*** El rating que quiero: ' + foundClientRating);
        }

        final String OTHER_CLIENT_TYPE ='00004';
        if(opp != null){
            Map<Id,DMT_X_Sell__c> xSellmap = new Map<Id,DMT_X_Sell__c>(opp.X_sell__r);
            Map<Id,OpportunityLineItem> productsMap = new Map<Id,OpportunityLineItem>(opp.OpportunityLineItems);

            //Validate mandatory fields needed for Passport capabilities and workflows calculation
            List<String> missingMandatoryFields = getMissingMandatoryFieldsForPassport(opp, oppClient, productsMap);

            if(missingMandatoryFields.isEmpty()){
                listFeatureReturn.add(generateFeatureGenConsideration(
                    'All mandatory fields required for capabilities and workflows calculation are complete.',
                    DMT_Constants.FEATURE_GC_STATE_GREEN,
                    'Passport mandatory fields are complete'
                ));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration(
                    'Missing mandatory fields required for capabilities and workflows calculation: ' + String.join(missingMandatoryFields, ', ') + '.',
                    DMT_Constants.FEATURE_GC_STATE_YELLOW,
                    'Passport mandatory fields are missing'
                ));
            }

            List<DMT_Opportunity_Tenor__c> amortizationPayments = new List<DMT_Opportunity_Tenor__c>();
            for(OpportunityLineItem oli : productsMap.values()){
                if (oli.Opportunity_Tenors__r != null && !oli.Opportunity_Tenors__r.isEmpty()) {
                    amortizationPayments.addAll(oli.Opportunity_Tenors__r);
                }
            }
            Map<Id,DMT_Opportunity_Tenor__c> tenorsMap = new Map<Id,DMT_Opportunity_Tenor__c>(amortizationPayments);

            //Validate Internal Rating
            Boolean isInternalRatingEqual = oppClient != null && (foundClientRating == null || oppClient.g_upd_lmscl_internal_ratg_type__c == foundClientRating);
            if(isInternalRatingEqual){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Internal Rating matches the Client Internal Rating.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Rating matches'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Internal Rating does not match the Client Internal Rating.',DMT_Constants.FEATURE_GC_STATE_YELLOW,'Rating does not match'));
            }
            //Validate Client fields
            Boolean hasOppClient = oppClient != null;
            Boolean isClientRatingEqual = hasOppClient && (foundClientRating == null || oppClient.g_upd_lmscl_internal_ratg_type__c == foundClientRating);
            Boolean isScoringEqual = hasOppClient
                && (foundScoringRounded == null || (oppClient.DMT_Scoring__c != null && oppClient.DMT_Scoring__c == foundScoringRounded));
            String expectedExternalRatingValue = foundUnifiedExtRatgLtFcType == null ? 'NR' : foundUnifiedExtRatgLtFcType;
            String actualExternalRatingValue = String.isBlank(oppClient?.External_Rating__c)
                ? 'NR'
                : oppClient.External_Rating__c;
            Boolean isExternalRatingEqual = hasOppClient && actualExternalRatingValue == expectedExternalRatingValue;
            Boolean isFitchRatingEqual = hasOppClient && (foundFitchLtRatingLcType == null || oppClient.DMT_External_Rating_Fitch__c == foundFitchLtRatingLcType);
            Boolean isMoodysRatingEqual = hasOppClient && (foundMoodysLtRatingLcType == null || oppClient.DMT_External_Rating_Moodys__c == foundMoodysLtRatingLcType);
            Boolean isSpRatingEqual = hasOppClient && (foundSpLtRatingLcType == null || oppClient.DMT_External_Rating_SP__c == foundSpLtRatingLcType);
            Boolean isFoundLeveragedYes = String.isNotBlank(foundLeveragedLendingIndType) && foundLeveragedLendingIndType.equalsIgnoreCase('Yes');
            Boolean isClientLeveragedYes = hasOppClient && String.isNotBlank(oppClient.DMT_Leveraged_Lending__c)&& oppClient.DMT_Leveraged_Lending__c.equalsIgnoreCase('Yes');
            Boolean isLeveragedLendingEqual = hasOppClient && (String.isBlank(foundLeveragedLendingIndType) || isFoundLeveragedYes == isClientLeveragedYes);
            Boolean isSectorEqual = hasOppClient && (foundAssetAllocationSectorType == null || oppClient.DMT_Sector__c == foundAssetAllocationSectorType);
            Boolean isSubsectorEqual = hasOppClient && (foundAssetAllocationSubSecType == null || oppClient.DMT_Subsector__c == foundAssetAllocationSubSecType);
            Boolean isActivityEqual = hasOppClient && (foundAssetAllocationActvyType == null || oppClient.DMT_Activity__c == foundAssetAllocationActvyType);
            Boolean isCamnEqual = hasOppClient && (foundActivityMinimumLevelCode == null || oppClient.DMT_CAMN__c == foundActivityMinimumLevelCode);

            System.debug('*** allFieldsOriginal - hasOppClient: ' + hasOppClient);
            System.debug('*** allFieldsOriginal - isClientRatingEqual: ' + isClientRatingEqual + ' | oppClient=' + (hasOppClient ? oppClient.g_upd_lmscl_internal_ratg_type__c : null) + ' | expected=' + foundClientRating);
            System.debug('*** allFieldsOriginal - isScoringEqual: ' + isScoringEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_Scoring__c : null) + ' | expected=' + foundScoringRounded);
            System.debug('*** allFieldsOriginal - isExternalRatingEqual: ' + isExternalRatingEqual + ' | oppClient=' + actualExternalRatingValue + ' | expected=' + expectedExternalRatingValue);
            System.debug('*** allFieldsOriginal - isFitchRatingEqual: ' + isFitchRatingEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_External_Rating_Fitch__c : null) + ' | expected=' + foundFitchLtRatingLcType);
            System.debug('*** allFieldsOriginal - isMoodysRatingEqual: ' + isMoodysRatingEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_External_Rating_Moodys__c : null) + ' | expected=' + foundMoodysLtRatingLcType);
            System.debug('*** allFieldsOriginal - isSpRatingEqual: ' + isSpRatingEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_External_Rating_SP__c : null) + ' | expected=' + foundSpLtRatingLcType);
            System.debug('*** allFieldsOriginal - isLeveragedLendingEqual: ' + isLeveragedLendingEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_Leveraged_Lending__c : null) + ' | expected=' + isFoundLeveragedYes);
            System.debug('*** allFieldsOriginal - isSectorEqual: ' + isSectorEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_Sector__c : null) + ' | expected=' + foundAssetAllocationSectorType);
            System.debug('*** allFieldsOriginal - isSubsectorEqual: ' + isSubsectorEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_Subsector__c : null) + ' | expected=' + foundAssetAllocationSubSecType);
            System.debug('*** allFieldsOriginal - isActivityEqual: ' + isActivityEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_Activity__c : null) + ' | expected=' + foundAssetAllocationActvyType);
            System.debug('*** allFieldsOriginal - isCamnEqual: ' + isCamnEqual + ' | oppClient=' + (hasOppClient ? oppClient.DMT_CAMN__c : null) + ' | expected=' + foundActivityMinimumLevelCode);

            Boolean allFieldsOriginal = hasOppClient
            && isClientRatingEqual
            && isScoringEqual
            && isExternalRatingEqual
            && isFitchRatingEqual
            && isMoodysRatingEqual
            && isSpRatingEqual
            //&& oppClient.DMT_Industry__c == validationAccount.Industry
            && isLeveragedLendingEqual
            //&& (String.isBlank(validationAccount.DES_Segment__c) || validationAccount.DES_Segment__c == OTHER_CLIENT_TYPE || oppClient.Counterpart__c == transformSegmentToCounterpart(validationAccount.DES_Segment__c))
            && isSectorEqual
            && isSubsectorEqual
            && isActivityEqual
            && isCamnEqual;
            System.debug('*** allFieldsOriginal - finalResult: ' + allFieldsOriginal);
            if(allFieldsOriginal){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Client Information matches the original client data.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Client information matches original data'));
            }else{
                List<String> failedFields = new List<String>();
                if(!isClientRatingEqual) failedFields.add('Client Rating');
                if(!isScoringEqual) failedFields.add('Scoring');
                if(!isExternalRatingEqual) failedFields.add('External Rating');
                if(!isFitchRatingEqual) failedFields.add('Fitch Rating');
                if(!isMoodysRatingEqual) failedFields.add('Moodys Rating');
                if(!isSpRatingEqual) failedFields.add('S&P Rating');
                if(!isLeveragedLendingEqual) failedFields.add('Leveraged Lending');
                if(!isSectorEqual) failedFields.add('Sector');
                if(!isSubsectorEqual) failedFields.add('Subsector');
                if(!isActivityEqual) failedFields.add('Activity');
                if(!isCamnEqual) failedFields.add('CAMN');
                
                String failedFieldsMessage = String.join(failedFields, ', ');
                if(failedFields.size() > 1){
                    listFeatureReturn.add(generateFeatureGenConsideration(failedFieldsMessage + ' do not match the original client data.' ,DMT_Constants.FEATURE_GC_STATE_YELLOW,'Client information differs from original data'));

                }else{
                    listFeatureReturn.add(generateFeatureGenConsideration(failedFieldsMessage + ' does not match the original client data.' ,DMT_Constants.FEATURE_GC_STATE_YELLOW,'Client information differs from original data'));

                }
            }

            //Validate Client Type
            Boolean isClientTypeEqual = opp != null && (String.isBlank(validationAccount.DES_Segment__c) || validationAccount.DES_Segment__c == OTHER_CLIENT_TYPE || oppClient.Counterpart__c == transformSegmentToCounterpart(validationAccount.DES_Segment__c));
            if(isClientTypeEqual){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Client Type matches the Client Type.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Client Type matches'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Client Type does not match the Client Type.',DMT_Constants.FEATURE_GC_STATE_YELLOW,'Client Type does not match'));
            }

           /* //Validate XSELL
            Integer yearLimit = opp.DMT_DATE_Initial_Date__c != null ? opp.DMT_DATE_Initial_Date__c.year() + 5 : System.now().date().year() + 5;
            Boolean xSellLimit = false;
            for (DMT_X_Sell__c xSell : xSellmap.values()) {
                if (xSell.Year__c != null && Integer.valueOf(xSell.Year__c) > yearLimit) {
                    xSellLimit = true;
                }
            }
            if(xSellLimit){
                listFeatureReturn.add(generateFeatureGenConsideration('One or more Cross SELL records have a Year beyond 5 years from the Opportunity Initial Date',DMT_Constants.FEATURE_GC_STATE_YELLOW,'Cross SELL Year is inconsistent'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('All Cross SELL records have a Year within 5 years from the Opportunity Initial Date.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Cross SELL Year is consistent'));
            }*/

            //Validate Tenors
            Boolean userDefinedNotPaymentDate = false;
            for (DMT_Opportunity_Tenor__c tenorItem : tenorsMap.values()) {
                if (productsMap.get(tenorItem.DMT_Opportunity_Product__c).gf_amortization_type__c == 'User-Defined' && tenorItem.gf_tenor_date__c == null) {
                    userDefinedNotPaymentDate = true;
                }
            }
            if(userDefinedNotPaymentDate){
                listFeatureReturn.add(generateFeatureGenConsideration('One or more User-Defined tenors are missing a Payment Date.',DMT_Constants.FEATURE_GC_STATE_YELLOW,'Tenors Payment Date is missing'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('All User-Defined tenors have a Payment Date.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Tenors Payment Date is complete'));

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
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity tenor dates match the Opportunity Product dates.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Tenor dates match'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity tenor dates do not match the Opportunity Product dates.',DMT_Constants.FEATURE_GC_STATE_YELLOW,'Tenor dates do not match'));

            }

            //Validate Opportunity
            if(opp.DMT_CUR_Notional_Amount__c == opp.DMT_CUR_Notional__c){
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Notional Amount matches the sum of Opportunity Products Notional Amounts.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Notional Amount matches'));
            }else{
                listFeatureReturn.add(generateFeatureGenConsideration('Opportunity Notional Amount does not match the sum of Opportunity Products Notional Amounts.',DMT_Constants.FEATURE_GC_STATE_YELLOW,'Notional Amount does not match'));
            }

            //Validate approver fields
            if(opp.DMT_Approver__c != null && opp.DMT_ApproverGlobalBanker__c != null && opp.DMT_Booking_Unit_Risk_Analyst__c != null){
                listFeatureReturn.add(generateFeatureGenConsideration('All opportunity approver fields are filled in.',DMT_Constants.FEATURE_GC_STATE_GREEN,'Approver information is complete'));
            }else{
                 listFeatureReturn.add(generateFeatureGenConsideration('The opportunity approvers fields are not filled in.',DMT_Constants.FEATURE_GC_STATE_YELLOW,'The approvers information is inconsistent'));
            }

            //Validate rating existence and expiration
            listFeatureReturn.add(ratingExistenceExpiration(
                foundScaleLastUpdDate,
                foundRatingValidityStartDate,
                foundCurrentRatingToolDate,
                foundFfssRegulatoryRatingDate,
                foundRtFfssvldydtmtNumber
            ));

        }

        return listFeatureReturn;
    }

    private static List<String> getMissingMandatoryFieldsForPassport(Opportunity opp, DMT_Opportunity_Client__c oppClient, Map<Id, OpportunityLineItem> productsMap){
        Set<String> missingFields = new Set<String>();

        // Opportunity mandatory fields
        addIfBlank(missingFields, opp.Name, 'Name');
        addIfBlank(missingFields, opp.Entific__c, 'Entific');
        addIfBlank(missingFields, opp.DMT_Entity__c, 'Entity');
        addIfBlank(missingFields, opp.DES_Booking_Geography__c, 'Booking Geography');
        addIfNull(missingFields, opp.DMT_Tenor__c, 'Opportunity Tenor');
        addIfNull(missingFields, opp.DMT_CUR_Notional__c, 'Deal Amount');
        addIfNull(missingFields, opp.DMT_CUR_Notional_Amount__c, 'Notional Amount');
        addIfBlank(missingFields, opp.DMT_CurrencyText__c, 'Currency');
        addIfBlank(missingFields, opp.DMT_Product_Area__c, 'Product Area');
        addIfBlank(missingFields, opp.DMT_Threshold_Type__c, 'Client Threshold Type');

        // Client mandatory fields
        if(oppClient == null){
            missingFields.add('Internal Rating');
            missingFields.add('Scoring');
            missingFields.add('Client Type');
            missingFields.add('Sector - Asset Allocation');
        }else{
            addIfBlank(missingFields, oppClient.g_upd_lmscl_internal_ratg_type__c, 'Internal Rating');
            addIfNull(missingFields, oppClient.DMT_Scoring__c, 'Scoring');
            addIfBlank(missingFields, oppClient.Counterpart__c, 'Client Type');
            addIfBlank(missingFields, oppClient.DMT_Sector__c, 'Sector - Asset Allocation');
        }

        // Product mandatory fields
        if(productsMap == null || productsMap.isEmpty()){
            missingFields.add('Products');
        }else{
            for(OpportunityLineItem oli : productsMap.values()){
                Boolean isLineProduct = String.isNotBlank(oli.DMT_Line_Oneoffdeal__c)
                    && oli.DMT_Line_Oneoffdeal__c.equalsIgnoreCase('Line');

                addIfBlank(missingFields, oli.Name, 'Product Name');
                addIfNull(missingFields, oli.gf_initial_date__c, 'Product Start Date');
                addIfNull(missingFields, oli.gf_maturity_date__c, 'Product End Date');
                addIfBlank(missingFields, oli.DMT_Risk_Type__c, 'Risk Type');
                addIfBlank(missingFields, oli.g_currency_id__c, 'Product Currency');
                addIfBlank(missingFields, oli.gf_amortization_type__c, 'Amortization Type');
                if(!isLineProduct){
                    addIfNull(missingFields, oli.gf_accrual_fees_bp__c, 'Accrual Fee (BPS)');
                }
                //addIfNull(missingFields, oli.DMT_Extension_Duration_Fees__c, 'Extension/Duration Fees (BPS)');
                addIfBlank(missingFields, oli.Life_Funding_Type__c, 'Time of Cost of Funding');
                addIfBlank(missingFields, oli.DMT_sustainable_deal_assessment__c, 'Sustainable Deal Assessment');
            }
        }

        List<String> result = new List<String>();
        result.addAll(missingFields);
        result.sort();

        return result;
    }

    private static void addIfBlank(Set<String> missingFields, String value, String label){
        if(String.isBlank(value)){
            missingFields.add(label);
        }
    }

    private static void addIfNull(Set<String> missingFields, Object value, String label){
        if(value == null){
            missingFields.add(label);
        }
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations generateFeatureGenConsideration(String message, String state, String name){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations featureReturn = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        featureReturn.message = message;
        featureReturn.state = state;
        featureReturn.name = name;
        return featureReturn;
    }

    private static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations ratingExistenceExpiration(
        String scaleLastUpdDate,
        String ratingValidityStartDate,
        String currentRatingToolDate,
        String ffssRegulatoryRatingDate,
        Object rtFfssvldydtmtNumber) {

        Date ratingDate = null;
        String ratingValid = null;

        if (scaleLastUpdDate != null) {
            ratingDate  = Date.valueOf(scaleLastUpdDate);
            ratingValid = rtFfssvldydtmtNumber == null ? ''
                : String.valueOf(Date.valueOf(ratingValidityStartDate).addMonths(19) <= Date.today());
        } else if (currentRatingToolDate != null) {
            ratingDate  = Date.valueOf(currentRatingToolDate);
            ratingValid = ffssRegulatoryRatingDate == null ? ''
                : String.valueOf(Date.valueOf(ffssRegulatoryRatingDate).addMonths(19) <= Date.today());
        }

        Boolean isYellow = ratingDate == null
            || ratingDate.addMonths(12) <= Date.today()
            || String.isEmpty(ratingValid)
            || Boolean.valueOf(ratingValid);

        return generateFeatureGenConsideration(
            isYellow ? DMT_Constants.RATING_REDMESSAGE : DMT_Constants.RATING_GREENMESSAGE,
            isYellow ? DMT_Constants.FEATURE_GC_STATE_YELLOW : DMT_Constants.FEATURE_GC_STATE_GREEN,
            DMT_Constants.FEATURE_NAME_RATING
        );
    }

    public static String transformSegmentToCounterpart(String segmentValue) {
        final Map<String, String> transformMap = new Map<String, String>{
            '00001' => 'Sov',
            '00002' => 'Pub Inst',
            '00003' => 'SME',
            '00005' => 'Corporates',
            '00006' => 'Fin Inst-B'
        };
        return transformMap.get(segmentValue);
    }
}