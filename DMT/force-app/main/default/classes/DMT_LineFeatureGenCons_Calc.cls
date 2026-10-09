public with sharing class DMT_LineFeatureGenCons_Calc {
    public static List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> checkValidations(String recordId, String clientsGroup) {
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> mapFeatureResult = new List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations>();
        DMT_Line__c line = DMT_Passport_Selector.getLine(recordId);
        List<Object> clientsInGroups = (List<Object>)JSON.deserializeUntyped(clientsGroup);

        List<String> caIds = new List<String>{line.Custom_Association__c};
        List<Custom_Association_Client__c> caClient = DMT_Passport_Selector.getLineClients(caIds);
        List<DMT_Taxonomy_Values__c> taxonomies = DMT_Passport_Selector.getTaxonomyValues('F268');

        List<String> clientsCodeList = new List<String>();
        if(String.isBlank(line.Custom_Association__c)){
            clientsCodeList.add(line.Client_Code__c);
        }else{
            for(Custom_Association_Client__c oneCacClient : caClient){
                clientsCodeList.add(oneCacClient.Alpha_Code_Client__c);
            }
        }
        //mapFeatureResult.add(isCurrentLine(clientsCodeList, line.Start_Date__c, recordId));

        List<DMT_Line_Product_Item__c> lineProductItems = DMT_Passport_Selector.getProductLineItems(recordId);

        Set<Custom_Association_Client__c> listOfClients = new Set<Custom_Association_Client__c>();
        List<String> alphaCodeList = new List<String>();
        Map<String, Id> alphaCodeMap = new Map<String, Id>();

        for(Object c : clientsInGroups){
            Map<String, Object> client =  (Map<String, Object>)c;

            if(line.Client_Type__c == 'Group' || (line.Client_Type__c == 'Customer' && line.Client_Code__c == (String)client.get('customerId'))){
                if(client.get('customerId') != null){
                    alphaCodeList.add((String)client.get('customerId'));
                }
            } else{
                for(Custom_Association_Client__c oneCacClient : caClient){
                    if(oneCacClient.Alpha_Code_Client__c == (String)client.get('customerId')){
                        alphaCodeList.add((String)client.get('customerId'));
                    }
                }
            }

        }

       for(Account c : DMT_Passport_Selector.getLocalclient(alphaCodeList)){
            alphaCodeMap.put(c.g_customer_id__c, c.Id);
        }

        for(Object c : clientsInGroups){
            Map<String, Object> client =  (Map<String, Object>)c;

            if((line.Client_Type__c == 'Group' && client.get('customerId') != null && line.Booking_Geography__c == ((String)client.get('customerId')).substring(0,2) )|| (line.Client_Type__c == 'Customer' && line.Client_Code__c == (String)client.get('customerId'))){
                Custom_Association_Client__c ca = new Custom_Association_Client__c
                (
                    Alpha_Code_Client__c = client.get('customerId') == null ? '' : (String)client.get('customerId'),
                    DMT_ClientRating__c = null,
                    DMT_Client_Rating_Date__c = null,
                    DMT_ClientStarCode__c = client.get('customerCounterpartiesCodesDesc') == null ? '' : (String)client.get('customerCounterpartiesCodesDesc'),
                    DMT_ClientContracts__c = client.get('operationMitigantDesc') == null ? '' : (String)client.get('operationMitigantDesc'),
                    g_customer_id__c = (client.get('customerId') != null && alphaCodeMap.containsKey((String)client.get('customerId'))) ? (String)client.get('customerId') : null
                );

                if(client.get('scaleLastUpdDate') != null){

                    ca.DMT_Client_Rating_Date__c = client.get('scaleLastUpdDate') == null ? null : Date.valueOf((String)client.get('scaleLastUpdDate'));
                    ca.DMT_ClientRating__c = client.get('rtFfssvldydtmtNumber') == null ? '' : String.valueOf(Date.valueOf((String)client.get('ratingValidityStartDate')).addMonths(19) <= Date.today());
                }
                else if(client.get('currentRatingToolDate') != null){

                    ca.DMT_Client_Rating_Date__c = client.get('currentRatingToolDate') == null ? null : Date.valueOf((String)client.get('currentRatingToolDate'));
                    ca.DMT_ClientRating__c = client.get('ffssRegulatoryRatingDate') == null ? '' : String.valueOf(Date.valueOf((String)client.get('ffssRegulatoryRatingDate')).addMonths(19) <= Date.today());
                }


                listOfClients.add(ca);
            } else{
                for(Custom_Association_Client__c oneCacClient : caClient){
                    if(oneCacClient.Alpha_Code_Client__c == (String)client.get('customerId')){
                        Custom_Association_Client__c ca = new Custom_Association_Client__c
                        (
                            Alpha_Code_Client__c = client.get('customerId') == null ? '' : (String)client.get('customerId'),
                            DMT_ClientRating__c = null,
                            DMT_Client_Rating_Date__c = null,
                            DMT_ClientStarCode__c = client.get('customerCounterpartiesCodesDesc') == null ? '' : (String)client.get('customerCounterpartiesCodesDesc'),
                            DMT_ClientContracts__c = client.get('operationMitigantDesc') == null ? '' : (String)client.get('operationMitigantDesc'),
                            g_customer_id__c = (client.get('customerId') != null && alphaCodeMap.containsKey((String)client.get('customerId'))) ? (String)client.get('customerId') : null
                        );

                        if(client.get('scaleLastUpdDate') != null){
                            ca.DMT_Client_Rating_Date__c = client.get('scaleLastUpdDate') == null ? null : Date.valueOf((String)client.get('scaleLastUpdDate'));
                            ca.DMT_ClientRating__c = client.get('rtFfssvldydtmtNumber') == null ? '' : String.valueOf(Date.valueOf((String)client.get('ratingValidityStartDate')).addMonths(19) <= Date.today());
                            System.debug(client.get('ratingValidityStartDate'));
                        }
                        else if(client.get('currentRatingToolDate') != null){
                            ca.DMT_Client_Rating_Date__c = client.get('currentRatingToolDate') == null ? null : Date.valueOf((String)client.get('currentRatingToolDate'));
                            ca.DMT_ClientRating__c = client.get('ffssRegulatoryRatingDate') == null ? '' : String.valueOf(Date.valueOf((String)client.get('ffssRegulatoryRatingDate')).addMonths(19) <= Date.today());
                        }

                        listOfClients.add(ca);
                    }
                }
            }
        }

        if(line.RecordType.DeveloperName == 'TreasurySettlement'){
            System.debug('line.RecordType.DeveloperName:'+line.RecordType.DeveloperName);
            if(line.Client_Type__c == 'Group' || line.Client_Type__c == 'Custom') {
                mapFeatureResult.add(clientSelected(line, listOfClients));
                mapFeatureResult.add(customAssociationClientValidation(line));
            }
            List<DMT_Risk_Line_Term__c> riskLineDeri = DMT_Passport_Selector.getRiskLineTerm(line.Id);
            
            List<DMT_OperationalRestrictionsTRSR__mdt> listOperationalRestrictions = DMT_Passport_Selector.getOperationalRestrictionMDT(line.Booking_Geography__c);
            Map<String, DMT_OperationalRestrictionsTRSR__mdt> mapOpRestric = new Map<String, DMT_OperationalRestrictionsTRSR__mdt>();
            for (DMT_OperationalRestrictionsTRSR__mdt aux : listOperationalRestrictions) {
                mapOpRestric.put(aux.DMT_Operational_Restrictions_Name__c, aux);
            }

            mapFeatureResult.add(isCurrentLine(clientsCodeList, line.Start_Date__c, line));
            mapFeatureResult.add(restricGreaterTerm(lineProductItems, riskLineDeri));
            mapFeatureResult.add(deriRestricNOFdDvp(lineProductItems, mapOpRestric));
            if (line.Waiver__c == true) {
                mapFeatureResult.add(waiverValidation(line, riskLineDeri, lineProductItems));
            }
            mapFeatureResult.add(noSettlementAmount(lineProductItems, line));
            mapFeatureResult.add(startDate(line));
            mapFeatureResult.add(endDate(line));
            mapFeatureResult.add(counterparty(listOfClients));
            mapFeatureResult.add(rating(listOfClients));
            if (line.Booking_Geography__c == 'ES' || line.Booking_Geography__c == 'MX') {
                mapFeatureResult.add(isdaValidation(listOfClients, taxonomies, line));
            }

            if(line.Client_Type__c == 'Group' || line.Client_Type__c == 'Custom'){
                mapFeatureResult.add(isGDTClient(listOfClients));
            }
        } else{
            List<DMT_Risk_Line_Term__c> riskLine = DMT_Passport_Selector.getRiskLineAll(line.Id);

            mapFeatureResult.add(startDate(line));
            mapFeatureResult.add(rating(listOfClients));
            mapFeatureResult.add(isGDTClient(listOfClients));
            mapFeatureResult.add(amountHigher(riskLine, line));
        }

        return mapFeatureResult;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations waiverValidation(
        DMT_Line__c line,
        List<DMT_Risk_Line_Term__c> riskLineDeri,
        List<DMT_Line_Product_Item__c> lineProductItems
    ) {
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations waiverResult = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        waiverResult.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        waiverResult.name = DMT_Constants.FEATURE_NAME_WAIVER;
        waiverResult.message = DMT_Constants.WAIVER_GREENMESSAGE;

        if (line.Waiver__c != true) {
            return waiverResult;
        }

        Boolean hasDerivativesRisk = false;
        if (riskLineDeri != null) {
            for (DMT_Risk_Line_Term__c riskLine : riskLineDeri) {
                if (riskLine.DMT_Risk_Type__c == DMT_Constants.RSK_DERIVATIVES) {
                    hasDerivativesRisk = true;
                    break;
                }
            }
        }
        Boolean hasActiveRestriction = false;
        if (lineProductItems != null) {
            for (DMT_Line_Product_Item__c productItem : lineProductItems) {
                if (productItem.DMT_RestrictionActive__c == true) {
                    hasActiveRestriction = true;
                    break;
                }
            }
        }

        if (!hasDerivativesRisk || !hasActiveRestriction) {
            waiverResult.state = DMT_Constants.FEATURE_GC_STATE_RED;
            waiverResult.message = DMT_Constants.WAIVER_REDMESSAGE;
        }

        return waiverResult;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations amountHigher(List<DMT_Risk_Line_Term__c> riskLines, DMT_Line__c linelpi){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations amountHigher = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        List<String> productList = new List<String> ();
        amountHigher.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        amountHigher.name = DMT_Constants.FEATURE_NAME_AMOUNTHIGHER;
        amountHigher.message = DMT_Constants.AMOUNT_HIGHER_GREENMESSAGE;

        for(DMT_Risk_Line_Term__c rlt : riskLines){
            if(rlt.DMT_Amount__c > linelpi.Amount__c){
                productList.add(rlt.Name);
            }
        }
        if(!productList.isEmpty()){
            amountHigher.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            amountHigher.message = DMT_Constants.AMOUNT_HIGHER_REDMESSAGE + String.join(productList,', ');
        }

        return amountHigher;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations isGDTClient(Set<Custom_Association_Client__c> caClientList){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations gdtClientResult = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        gdtClientResult.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        gdtClientResult.name = DMT_Constants.FEATURE_NAME_ISGDTCLIENT;
        gdtClientResult.message = DMT_Constants.NO_GDT_CLIENT_GREENMESSAGE;
        List<String> clientCodeList = new List<String> ();
        for (Custom_Association_Client__c client : caClientList){
            if(String.isBlank(client.g_customer_id__c)){
                clientCodeList.add(client.Alpha_Code_Client__c);
            }
        }

        if(!clientCodeList.isEmpty()){
            gdtClientResult.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            gdtClientResult.message = DMT_Constants.NO_GDT_CLIENT_REDMESSAGE + processMessage(clientCodeList);
        }

        return gdtClientResult;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations isCurrentLine(List<String> clientsCodeList, Date lineStartDate, DMT_Line__c line){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations currentLineClientResult = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        currentLineClientResult.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        currentLineClientResult.name = DMT_Constants.FEATURE_NAME_ISCURRENTLINE;
        currentLineClientResult.message = DMT_Constants.CURRENT_CLIENT_LINE_GREENMESSAGE;
        Set<String> currentclientCodeList = new Set<String> ();
        System.debug('clientsCodeList, '+ clientsCodeList);
        System.debug('lineStartDate, '+ lineStartDate);
        DMT_Line__c lineChild = DMT_Passport_Selector.getLine(line.Id);
        List<DMT_Line__c> currentLinesList = DMT_Passport_Selector.getCurrentLinesByClient(lineStartDate, lineChild.Id, lineChild.DMT_Parent_Line__c);
        System.debug('currentLinesList, '+ currentLinesList);
        List<String> caInCurrentLines = new List<String>();
        for(DMT_Line__c currentLine : currentLinesList){
            System.debug('currentLine.Custom_Association__c, '+ currentLine.Custom_Association__c);
            System.debug('clientsCodeList, '+ clientsCodeList);
            System.debug('clientsCodeList.contains(currentLine.Client_Code__c), '+ clientsCodeList.contains(currentLine.Client_Code__c));
            if(String.isBlank(currentLine.Custom_Association__c) && clientsCodeList.contains(currentLine.Client_Code__c)){
                currentLineClientResult.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
                currentclientCodeList.add(currentLine.Client_Code__c);
                currentLineClientResult.message = DMT_Constants.CURRENT_CLIENT_LINE_REDMESSAGE + String.join(currentclientCodeList,', ');
            }else if(!String.isBlank(currentLine.Custom_Association__c)){
                caInCurrentLines.add(currentLine.Custom_Association__c);
            }
        }
        for(Custom_Association_Client__c cacCurrentLines : DMT_Passport_Selector.getLineClients(caInCurrentLines)){
            if(clientsCodeList.contains(cacCurrentLines.Alpha_Code_Client__c)){
                currentLineClientResult.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
                currentclientCodeList.add(cacCurrentLines.Alpha_Code_Client__c);
                currentLineClientResult.message = DMT_Constants.CURRENT_CLIENT_LINE_REDMESSAGE + String.join(currentclientCodeList,', ');
            }
        }
        System.debug('isCurrentLine currentLineClientResult, '+ JSON.serialize(currentLineClientResult));
        return currentLineClientResult;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations restricGreaterTerm(List<DMT_Line_Product_Item__c> lpiList, List<DMT_Risk_Line_Term__c> riskList){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectProductLineTerm = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectProductLineTerm.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectProductLineTerm.name = DMT_Constants.FEATURE_NAME_RESTRICGREATERTERM;
        incorrectProductLineTerm.message = DMT_Constants.GREATER_RESTRIC_TERM_GREENMESSAGE;
        Integer maxTerm = 0;
        for(DMT_Risk_Line_Term__c risk : riskList) {
            if(risk.DMT_End_Term__c != null && Integer.valueOf(risk.DMT_End_Term__c) > maxTerm) {
                maxTerm = Integer.valueOf(risk.DMT_End_Term__c);
            }
        }
        List<String> retrictGreaterTermMessageList = new List<String> ();
        for(DMT_Line_Product_Item__c lpi : lpiList){
            if(!String.isBlank(lpi.Max_Tenor_WC__c) && Integer.valueOf(lpi.Max_Tenor_WC__c) > maxTerm){
                incorrectProductLineTerm.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
                retrictGreaterTermMessageList.add(lpi.Name);
                incorrectProductLineTerm.message = DMT_Constants.GREATER_RESTRIC_TERM_REDMESSAGE + String.join(retrictGreaterTermMessageList,', ');
            }
        }

        return incorrectProductLineTerm;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations deriRestricNOFdDvp(List<DMT_Line_Product_Item__c> lpiList, Map<String, DMT_OperationalRestrictionsTRSR__mdt> mapOpRestric){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations deriRestricNoSettVali = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        deriRestricNoSettVali.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        deriRestricNoSettVali.name = DMT_Constants.FEATURE_NAME_DERIRESTRICNOFDDVP;
        deriRestricNoSettVali.message = DMT_Constants.DERIVATIVES_NOFDDVP_GREENMESSAGE;
        List<String> deriNoFddvpMessageList = new List<String> ();
        System.debug('lpiList, '+ lpiList);
        System.debug('mapOpRestric, '+ mapOpRestric);
        for(DMT_Line_Product_Item__c lpi : lpiList){
            if(lpi.DMT_DerivativeRestriction__c && mapOpRestric != null){
                // MÉXICO
                /*Boolean esMX = lpi.Line__r.Booking_Geography__c == 'MX';

                Boolean mxFOEXySinDVP    = esMX && lpi.Product_Code_Value__c == 'FOEX' && !lpi.DMT_DVPRestriction__c;
                Boolean mxCCSWySinFD     = esMX && lpi.Product_Code_Value__c == 'CCSW' && !lpi.DMT_FDRestriction__c;
                Boolean mxB_o_C_yAlgunaFalse = esMX && lpi.Product_Code_Value__c == 'DBIC' && 
                    (!lpi.DMT_FDRestriction__c || !lpi.DMT_DVPRestriction__c);
                Boolean mxEQSPSinDVP     = esMX && lpi.Product_Code_Value__c == 'EQSP' && !lpi.DMT_DVPRestriction__c;

                Boolean condicionMX = mxFOEXySinDVP || mxCCSWySinFD || mxB_o_C_yAlgunaFalse || mxEQSPSinDVP;

                // COLOMBIA
                Boolean esCO = lpi.Line__r.Booking_Geography__c == 'CO';

                Boolean coFOEXySinFD = esCO && lpi.Product_Code_Value__c == 'FOEX' && !lpi.DMT_FDRestriction__c;
                Boolean coCCSWySinFD = esCO && lpi.Product_Code_Value__c == 'CCSW' && !lpi.DMT_FDRestriction__c;

                Boolean condicionCO = coFOEXySinFD || coCCSWySinFD;

                // ARGENTINA
                Boolean esAR = lpi.Line__r.Booking_Geography__c == 'AR';

                Boolean arFXSinDVP = esAR && lpi.Product_Code_Value__c == 'FOEX' && !lpi.DMT_DVPRestriction__c;

                Boolean arEQSPSinDVP = esAR && lpi.Product_Code_Value__c == 'EQSP' && !lpi.DMT_DVPRestriction__c;

                Boolean condicionAR = arEQSPSinDVP || arFXSinDVP;

                // ESPAÑA
                Boolean esES = lpi.Line__r.Booking_Geography__c == 'ES';

                Boolean esFOEXyAlgunaFalse = esES && lpi.Product_Code_Value__c == 'FOEX' && 
                    (!lpi.DMT_FDRestriction__c || !lpi.DMT_DVPRestriction__c);
                Boolean esCCSWySinFD = esES && lpi.Product_Code_Value__c == 'CCSW' && !lpi.DMT_FDRestriction__c;
                Boolean esDBICyAlgunaFalse = esES && lpi.Product_Code_Value__c == 'DBIC' && 
                    (!lpi.DMT_FDRestriction__c || !lpi.DMT_DVPRestriction__c);

                Boolean condicionES = esFOEXyAlgunaFalse || esCCSWySinFD || esDBICyAlgunaFalse;

                // PERÚ
                Boolean esPE = lpi.Line__r.Booking_Geography__c == 'PE';

                Boolean peCCSWySinFD = esPE && lpi.Product_Code_Value__c == 'CCSW' && !lpi.DMT_FDRestriction__c;
                Boolean peEQSPSinDVP = esPE && lpi.Product_Code_Value__c == 'EQSP' && !lpi.DMT_DVPRestriction__c;

                Boolean condicionPE = peCCSWySinFD || peEQSPSinDVP;

                // CONDICIÓN FINAL
                Boolean entrarAlIf = condicionMX || condicionCO || condicionAR || condicionES || condicionPE;
                //09/05/25 - The condition is modified to exclude the equities product -  CIBGLOBALD-1200
                */


                if((mapOpRestric?.get(lpi.Product_Code_Value__c)?.Apply_Validations_FD__c == true && !lpi?.DMT_FDRestriction__c)||(mapOpRestric?.get(lpi.Product_Code_Value__c)?.Apply_Validations_DVP__c == true && !lpi?.DMT_DVPRestriction__c)){
                    deriRestricNoSettVali.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
                    deriNoFddvpMessageList.add(lpi.Name);
                    deriRestricNoSettVali.message = DMT_Constants.DERIVATIVES_NOFDDVP_REDMESSAGE + String.join(deriNoFddvpMessageList,', ');
                }
            }
        }

        return deriRestricNoSettVali;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations noSettlementAmount(List<DMT_Line_Product_Item__c> lpiList, DMT_Line__c linelpi){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectSettlementAmount = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectSettlementAmount.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectSettlementAmount.name = DMT_Constants.FEATURE_NAME_NOSETTLEMENTAMOUNT;
        if(linelpi.Booking_Geography__c.equals('AR')){
            incorrectSettlementAmount.message = DMT_Constants.NO_SETTLEMENT_GREENMESSAGE_AR;
        }else {
            incorrectSettlementAmount.message = DMT_Constants.NO_SETTLEMENT_GREENMESSAGE;  
        }
        
        String incorrectSettlementMessage = null;
        Set<String> settlementRestricMessageList = new Set<String> ();
        Boolean isFreeDelivery = false;
        Boolean isPayment = false;
        for(DMT_Line_Product_Item__c lpi : lpiList){
            if((linelpi.FD_Amount__c == 0 || linelpi.FD_Amount__c == null) && lpi.DMT_FDRestriction__c){
                isFreeDelivery = true;
                System.debug('linelpi: '+linelpi);
                settlementRestricMessageList.add(lpi.Name);
            }
            if((linelpi.DvP_Amount__c == 0 || linelpi.DvP_Amount__c == null) && lpi.DMT_DVPRestriction__c){
                isPayment = true;
                System.debug('linelpi: '+linelpi);
                settlementRestricMessageList.add(lpi.Name);
            }
        }

        if(!settlementRestricMessageList.isEmpty()){

            incorrectSettlementMessage = isFreeDelivery ? 'Free Delivery ' : incorrectSettlementMessage;
            if(isPayment){
                incorrectSettlementMessage = incorrectSettlementMessage == null ? 'Delivery versus Payment ' : incorrectSettlementMessage + 'and Delivery versus Payment ';
            }
            incorrectSettlementAmount.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            incorrectSettlementAmount.message = incorrectSettlementMessage + DMT_Constants.NO_SETTLEMENT_REDMESSAGE + String.join(settlementRestricMessageList,', ');
        }
        
        return incorrectSettlementAmount;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations startDate(DMT_Line__c linelpi){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectStartDate = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectStartDate.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectStartDate.name = DMT_Constants.FEATURE_NAME_STARTDATE;
        incorrectStartDate.message = DMT_Constants.START_DATE_GREENMESSAGE;

        if(linelpi.Start_Date__c < Date.today()){
            incorrectStartDate.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            incorrectStartDate.message = DMT_Constants.START_DATE_REDMESSAGE;
        }


        return incorrectStartDate;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations endDate(DMT_Line__c linelpi){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectEndDate = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectEndDate.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectEndDate.name = System.Label.dmt_cl_FeatureEndDateMessageTitle;
        incorrectEndDate.message = System.Label.dmt_cl_FeatureEndDateGreen;

        if(date.daysInMonth(linelpi.End_Date__c.year(),linelpi.End_Date__c.month()) != linelpi.End_Date__c.day()){
            incorrectEndDate.state = DMT_Constants.FEATURE_GC_STATE_RED;
            incorrectEndDate.message = System.Label.dmt_cl_FeatureEndDateRed;
        }


        return incorrectEndDate;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations customAssociationClientValidation(DMT_Line__c linelpi){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectCustomAssociationValidations = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectCustomAssociationValidations.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectCustomAssociationValidations.name = System.Label.dmt_cl_FeatureCACLimitTitle;
        incorrectCustomAssociationValidations.message = System.Label.dmt_cl_FeatureCACLimitGreen;

        List<Custom_Association_Client__c> auxCustomAssClient = DMT_Passport_Selector.getCustomAssociationClientLine(linelpi.Id);
        if(linelpi != null && auxCustomAssClient != null && auxCustomAssClient.size() > 0){   
            for(Custom_Association_Client__c aux : auxCustomAssClient){
                if(aux.DMT_Amount__c >= linelpi.DMT_DerivativesAmount__c || aux.DMT_FDAmount__c >= linelpi.FD_Amount__c || aux.DMT_DvPAmount__c >= linelpi.DvP_Amount__c){
                    incorrectCustomAssociationValidations.state = DMT_Constants.FEATURE_GC_STATE_RED;
                    incorrectCustomAssociationValidations.message = System.Label.dmt_cl_FeatureCACLimitRed;
                }
            }
        }


        return incorrectCustomAssociationValidations;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations clientSelected(DMT_Line__c line, Set<Custom_Association_Client__c> caClient) {
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations clientSelectedResult = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        clientSelectedResult.name = DMT_Constants.FEATURE_NAME_CLIENTS_SELECTED;
        clientSelectedResult.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        clientSelectedResult.message = DMT_Constants.CLIENT_SELECTED_GREENMESSAGE;

        if (line.Client_Type__c != null && line.Client_Type__c == DMT_Constants.TYPE_GROUP) {

            clientSelectedResult.state = DMT_Constants.FEATURE_GC_STATE_RED;
            clientSelectedResult.message = DMT_Constants.CLIENT_SELECTED_REDMESSAGE;
            return clientSelectedResult;

        }else if(line.Client_Type__c != null && line.Client_Type__c == DMT_Constants.TYPE_CUSTOM){
            if(caClient == null || caClient.size() <= 1){
                clientSelectedResult.state = DMT_Constants.FEATURE_GC_STATE_RED;
                clientSelectedResult.message = DMT_Constants.CLIENT_SELECTED_REDMESSAGE;
                return clientSelectedResult;
            }
        }

        return clientSelectedResult;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations counterparty (Set<Custom_Association_Client__c> caClient){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectCounterparty = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectCounterparty.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectCounterparty.name = DMT_Constants.FEATURE_NAME_COUNTERPARTY;
        incorrectCounterparty.message = DMT_Constants.COUNTERPARTY_GREENMESSAGE;

        List<String> clientCodeList = new List<String> ();

        for(Custom_Association_Client__c ca : caClient){
            if(String.isEmpty(ca.DMT_ClientStarCode__c)){
                clientCodeList.add(ca.Alpha_Code_Client__c);
            }
        }

        if(!clientCodeList.isEmpty()){
            incorrectCounterparty.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            incorrectCounterparty.message = DMT_Constants.COUNTERPARTY_REDMESSAGE + processMessage(clientCodeList);
        }

        return incorrectCounterparty;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations rating (Set<Custom_Association_Client__c> caClient){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectCounterparty = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectCounterparty.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectCounterparty.name = DMT_Constants.FEATURE_NAME_RATING;
        incorrectCounterparty.message = DMT_Constants.RATING_GREENMESSAGE;

        List<String> clientCodeList = new List<String> ();

        for(Custom_Association_Client__c ca : caClient){
            if(ca.DMT_Client_Rating_Date__c == null || ca.DMT_Client_Rating_Date__c.addMonths(12) <= Date.today() || String.isEmpty(ca.DMT_ClientRating__c) || Boolean.valueOf(ca.DMT_ClientRating__c)){
                clientCodeList.add(ca.Alpha_Code_Client__c);
            }
        }

        if(!clientCodeList.isEmpty()){
            incorrectCounterparty.state = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            incorrectCounterparty.message = DMT_Constants.RATING_REDMESSAGE + processMessage(clientCodeList);
        }

        return incorrectCounterparty;
    }

    public static DMT_Wrapper_Passport_Abs.FeatureGenConsiderations isdaValidation (Set<Custom_Association_Client__c> caClient, List<DMT_Taxonomy_Values__c> taxonomies, DMT_Line__c linelpi){
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations incorrectCounterparty = new DMT_Wrapper_Passport_Abs.FeatureGenConsiderations();
        incorrectCounterparty.state = DMT_Constants.FEATURE_GC_STATE_GREEN;
        incorrectCounterparty.name = DMT_Constants.FEATURE_NAME_ISDA;
        incorrectCounterparty.message = DMT_Constants.ISDA_GREENMESSAGE;

        List<String> clientCodeList = new List<String> ();

        if(linelpi.Booking_Geography__c == 'ES' || linelpi.Booking_Geography__c == 'MX'){
            for(Custom_Association_Client__c ca : caClient){
                Boolean isFound = false;
                for(DMT_Taxonomy_Values__c t : taxonomies){
                    if(ca.DMT_ClientContracts__c != null && t.DMT_Value__c != null && ca.DMT_ClientContracts__c.contains(t.DMT_Value__c)){
                        isFound = true;
                    }
                }

                if(!isFound){
                    clientCodeList.add(ca.Alpha_Code_Client__c);
                }
            }

            if(!clientCodeList.isEmpty()){
                incorrectCounterparty.state = linelpi.Waiver__c ? DMT_Constants.FEATURE_GC_STATE_YELLOW : DMT_Constants.FEATURE_GC_STATE_YELLOW;
                incorrectCounterparty.message = DMT_Constants.ISDA_REDMESSAGE + processMessage(clientCodeList);
            }
        }

        return incorrectCounterparty;
    }

    private static String processMessage(List<String> messageList){
        Integer count = 0;
        String message = '';

        if(messageList.size() <= 3){
            return String.join(messageList,', ');
        }

        for(String m : messageList){
            if(count < 3){
                message += m + ',';
                count++;
            } else {
                message += '...[' + (messageList.size() - 3) + ']';
                return message;
            }
        }

        return message;
    }

    public static Boolean validationRenovation(Id lineId, Id fatherLineId) {
        if (fatherLineId == null) {
            return false;
        }

        List<DMT_Line_Product_Item__c> lineProductItems = DMT_Passport_Selector.getProductLineItems(lineId);
        List<DMT_Line_Product_Item__c> fatherLineProductItems = DMT_Passport_Selector.getProductLineItems(fatherLineId);
        List<DMT_Risk_Line_Term__c> riskLine = DMT_Passport_Selector.getRiskLineTerm(lineId);
        List<DMT_Risk_Line_Term__c> fatherRiskLine = DMT_Passport_Selector.getRiskLineTerm(fatherLineId);

        Map<String, DMT_Line_Product_Item__c> lineProductItemsMap = new Map<String, DMT_Line_Product_Item__c>();
        Map<String, DMT_Line_Product_Item__c> fatherLineProductItemsMap = new Map<String, DMT_Line_Product_Item__c>();

        for (DMT_Line_Product_Item__c lp : lineProductItems) {
            lineProductItemsMap.put(lp.Name, lp);
        }

        for (DMT_Line_Product_Item__c lpf : fatherLineProductItems) {
            fatherLineProductItemsMap.put(lpf.Name, lpf);
        }

        for (String key : lineProductItemsMap.keySet()) {
            DMT_Line_Product_Item__c lineItem = lineProductItemsMap.get(key);
            DMT_Line_Product_Item__c fatherLineItem = fatherLineProductItemsMap.get(key);

            if (fatherLineItem == null) {
                return true;
            }

            Boolean isFDRestrictionChanged = lineItem.DMT_FDRestriction__c != fatherLineItem.DMT_FDRestriction__c;
            Boolean isDVPRestrictionChanged = lineItem.DMT_DVPRestriction__c != fatherLineItem.DMT_DVPRestriction__c;
            Boolean isMaxTenorChanged = lineItem.Max_Tenor_WC__c != fatherLineItem.Max_Tenor_WC__c;
            Boolean isDerivateRestrictionChanged = lineItem.DMT_DerivativeRestriction__c && !fatherLineItem.DMT_DerivativeRestriction__c;

            if (isFDRestrictionChanged || isDVPRestrictionChanged || isMaxTenorChanged || isDerivateRestrictionChanged) {
                if ((!String.isEmpty(lineItem.Max_Tenor_WC__c) && String.isEmpty(fatherLineItem.Max_Tenor_WC__c)) ||
                    (!String.isEmpty(lineItem.Max_Tenor_WC__c) && Integer.valueOf(lineItem.Max_Tenor_WC__c) > Integer.valueOf(fatherLineItem.Max_Tenor_WC__c))) {
                    return true;
                }

                if (lineItem.DMT_FDRestriction__c && !fatherLineItem.DMT_FDRestriction__c) {
                    return true;
                }

                if (lineItem.DMT_DVPRestriction__c && !fatherLineItem.DMT_DVPRestriction__c) {
                    return true;
                }

                if (lineItem.DMT_DerivativeRestriction__c && !fatherLineItem.DMT_DerivativeRestriction__c) {
                    return true;
                }
            }
        }

        if (fatherRiskLine.isEmpty()) {
            return true;
        }

        Integer fatherCount = 0;
        for (Integer i = 0; i < riskLine.size(); i++) {
            DMT_Risk_Line_Term__c fatherLine = fatherRiskLine.get(fatherCount);
            DMT_Risk_Line_Term__c childLine = riskLine.get(i);

            if (Integer.valueOf(fatherLine.DMT_End_Term__c) < Integer.valueOf(childLine.DMT_End_Term__c) ||
                fatherLine.DMT_Amount__c < childLine.DMT_Amount__c) {
                return true;
            }

            if (fatherCount < fatherRiskLine.size() - 1) {
                fatherCount++;
            }
        }

        return false;
    }

   public static Boolean validationRenovationOtherLines(Id lineId, Id fatherLineId){
        if (fatherLineId == null) {
            return false;
        }

        List<DMT_Risk_Line_Term__c> riskLineOther = DMT_Passport_Selector.getRiskLineTermWhithoutRiskType(lineId);
        List<DMT_Risk_Line_Term__c> fatherRiskLineOther = DMT_Passport_Selector.getRiskLineTermWhithoutRiskType(fatherLineId);


        if (fatherRiskLineOther.isEmpty()) {
            return true;
        }


        Integer fatherCountOther = 0;
        for (Integer i = 0; i < riskLineOther.size(); i++) {
            DMT_Risk_Line_Term__c fatherLineRisk = fatherRiskLineOther.get(fatherCountOther);
            DMT_Risk_Line_Term__c childLineRisk = riskLineOther.get(i);
            DMT_Line__c childLine = DMT_Passport_Selector.getLine(lineId);
            DMT_Line__c fatherLine = DMT_Passport_Selector.getLine(fatherLineId);

            if (fatherLineRisk.DMT_Amount__c < childLineRisk.DMT_Amount__c || fatherLine.Amount__c < childLine.Amount__c || childLineRisk.DMT_Parent_Product__c == null) {
                return true;
            }

            if (fatherCountOther < fatherRiskLineOther.size() - 1) {
                fatherCountOther++;
            }
        }

        return false;
    }
}