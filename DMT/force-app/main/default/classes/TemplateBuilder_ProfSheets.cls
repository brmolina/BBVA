/**
* ____________________________________________________________________________
* Template Builder sample
* Local class implementing Callable methods
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-04-19
* @modified
* @systemLayer Service
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount, PMD.TooManyFields')
global with sharing class TemplateBuilder_ProfSheets implements Callable  {

    tmpb.TemplateBuilder.TemplateBuilderContent getContent(Id recordId) {

        final tmpb.TemplateBuilder.TemplateBuilderContent content = new tmpb.TemplateBuilder.TemplateBuilderContent();
        content.id = 'Content';
        content.name = 'Sample result content elements';
        content.categories = new List<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();

        final Map<String, Object> conditionsMap = getConditions(recordId);
        final Map<String, String> friendlyNames = getFriendlyNames();

        // Conditions
        for (String productKey : conditionsMap.keySet()) {

            final Map<String, Object> product = (Map<String, Object>)conditionsMap.get(productKey);
            final Map<String, Object> families = (Map<String, Object>)product.get('families');

            for (String familyKey : families.keySet()) {

                final Map<String, Object> family = (Map<String, Object>)families.get(familyKey);

                final tmpb.TemplateBuilder.TemplateBuilderContentCategory catConditions = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
                catConditions.id = familyKey;
                catConditions.title = product.get('name') + '/' + family.get('name');
                catConditions.description = 'Please select which conditions from this family will be sent in the report.';
                catConditions.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();

                final Map<String, Object> conditions = (Map<String, Object>)family.get('conditions');

                for (String condKey : conditions.keySet()) {
                    final Map<String, Object> condition = (Map<String, Object>)conditions.get(condKey);
                    final tmpb.TemplateBuilder.TemplateBuilderContentItem item = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
                    item.id = condKey;
                    item.title = friendlyName(String.valueOf(condition.get('name')), friendlyNames);
                    item.checked = product.get('name') == 'FX' ? false : true;
                    item.disabled = false;
                    catConditions.items.add(item);
                }
                content.categories.add(catConditions);
            }
        }

        //Flat Rates
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory catFlatRates= new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        catFlatRates.id = 'flatrates';
        catFlatRates.title = 'Flat rates';
        catFlatRates.description = 'Please select to include Flat Rates in the report.';
        catFlatRates.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();

        final tmpb.TemplateBuilder.TemplateBuilderContentItem itemFlatRates = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        itemFlatRates.id = 'yes';
        itemFlatRates.title = 'Include Flat Rates';
        itemFlatRates.checked = true;
        itemFlatRates.disabled = false;
        catFlatRates.items.add(itemFlatRates);
        content.categories.add(catFlatRates);

        //Participants
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory catParticipants = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        catParticipants.id = 'participants';
        catParticipants.title = 'Participants';
        catParticipants.description = 'Please select participants to include in the report.';
        catParticipants.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();

        final Map<Id, String> participants = getParticipants(recordId);
        for (Id participant : participants.keySet()) {
            final tmpb.TemplateBuilder.TemplateBuilderContentItem itemParticipant = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
            itemParticipant.id = participant;
            itemParticipant.title = participants.get(participant);
            itemParticipant.checked = true;
            itemParticipant.disabled = false;
            catParticipants.items.add(itemParticipant);
        }
        content.categories.add(catParticipants);

        return content;
    }

    tmpb.TemplateBuilder.TemplateBuilderContent getRecipients(Id recordId) {

        final tmpb.TemplateBuilder.TemplateBuilderContent recipients = new tmpb.TemplateBuilder.TemplateBuilderContent();
        recipients.id = 'recipientsCuco';
        recipients.name = 'Recipients Cuco';
        recipients.categories = new List<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();

        //get main participant id
        final cuco__profitability_sheet__c profSheet = [SELECT cuco__participant_id__c, cuco__participant_id__r.parentId, OwnerId, Owner.Name, Owner.Email FROM cuco__profitability_sheet__c WHERE Id =:recordId LIMIT 1];

        //Allow select Owner as recipient
        final tmpb.TemplateBuilder.TemplateBuilderContentCategory categoryBBVA = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
        categoryBBVA.id = 'bbva';
        categoryBBVA.title = 'BBVA recipients';
        categoryBBVA.icon = 'standard:user';
        categoryBBVA.description = 'Please, select BBVA recipients';
        categoryBBVA.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();

        final tmpb.TemplateBuilder.TemplateBuilderContentItem itemOwner = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
        itemOwner.id = profSheet.OwnerId;
        itemOwner.title = profSheet.Owner.Name;
        itemOwner.value = profSheet.Owner.Email;
        itemOwner.description = 'cc';
        itemOwner.disabled = false;
        itemOwner.checked = false;
        categoryBBVA.items.add(itemOwner);

        if (profSheet.OwnerId != UserInfo.getUserId()) {
            final tmpb.TemplateBuilder.TemplateBuilderContentItem itemUser = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
            itemUser.id = UserInfo.getUserId();
            itemUser.title = UserInfo.getName();
            itemUser.value = UserInfo.getUserEmail();
            itemUser.description = 'cc';
            itemUser.disabled = false;
            itemUser.checked = false;
            categoryBBVA.items.add(itemUser);
        }

        recipients.categories.add(categoryBBVA);

        // Main participant and parent
        final Set<Id> participantIds = new Set<Id>();
        if (!String.isEmpty(profSheet.cuco__participant_id__c)) {
            participantIds.add(profSheet.cuco__participant_id__c);
            if (profSheet.cuco__participant_id__r.parentId != null) {
                participantIds.add(profSheet.cuco__participant_id__r.parentId);
            }
        }

        // Participants
        final Map<Id, String> participants = getParticipants(recordId);
        for (Id participantId : participants.keySet()) {
            participantIds.add(participantId);
        }

        // Contacts from All participants and parent
        final Map<String, Object> contactsMap = updateContactsMap(participantIds);

        for (String key : contactsMap.keySet()) {

            final Map<String, Object> categoryMap = (Map<String, Object>)contactsMap.get(key);

            final tmpb.TemplateBuilder.TemplateBuilderContentCategory category = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
            category.id = key;
            category.title = (String)categoryMap.get('name');
            category.icon = 'standard:contact';
            category.description = 'Please, select contacts to send email to';
            category.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();

            final Map<String, Object> itemsMap = (Map<String, Object>)categoryMap.get('contacts');

            for(String key2 : itemsMap.keySet()){
                final Map<String, Object> itemMap = (Map<String, Object>)itemsMap.get(key2);
                final tmpb.TemplateBuilder.TemplateBuilderContentItem item = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
                item.id = key2;
                item.title = (String)itemMap.get('name');
                item.value = (String)itemMap.get('email');
                item.description = 'no';
                item.disabled = false;
                item.checked = false;
                category.items.add(item);
            }
            recipients.categories.add(category);
        }

        return recipients;
    }

    tmpb.TemplateBuilder.TemplateBuilderContent renderContent(Id recordId, Object args) {

        final Set<Id> conditionIds = new Set<Id>();
        final Set<Id> participantIds = new Set<Id>();
        Boolean showFlatRates = false;

        final tmpb.TemplateBuilder.TemplateBuilderContent renderedContent = new tmpb.TemplateBuilder.TemplateBuilderContent();

        renderedContent.rendered = new List<tmpb.TemplateBuilder.TemplateBuilderRenderedElement>();

        final tmpb.TemplateBuilder.TemplateBuilderArgs ids;

        try {

            final List<cuco__profitability_sheet__c> profSheet = [SELECT Name, cuco__participant_id__r.Name, cuco__gf_prftbly_sheet_end_date__c, gf_branch_id__c, cuco__gf_prftbly_sheet_stt_desc__c FROM cuco__profitability_sheet__c WHERE Id = :recordId LIMIT 1];
            ids = (tmpb.TemplateBuilder.TemplateBuilderArgs) System.JSON.deserialize((String)args, tmpb.TemplateBuilder.TemplateBuilderArgs.class);

            for (String selected : ids.selectedIds ) {
                List<String> pair = selected.split('-');
                switch on (String)pair[0] {
                    when 'participants' {
                        participantIds.add(pair[1]);
                    }
                    when 'flatrates' {
                        showFlatRates = true;
                    }
                    when else {
                        conditionIds.add(pair[1]);
                    }
                }
            }

            // Rendered Conditions
            if (conditionIds.size() > 0) {
                final Map<String, Object> conditionsMap = getConditions(recordId, conditionIds);
                final tmpb.TemplateBuilder.TemplateBuilderRenderedElement conditions = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
                conditions.key = 'conditions';
                conditions.value = getRenderedConditions(conditionsMap);
                renderedContent.rendered.add(conditions);
            }

            // Rendered Flat Rates
            if (showFlatRates) {
                final Map<String, Object> flatRatesMap = getFlatRates(recordId);
                final tmpb.TemplateBuilder.TemplateBuilderRenderedElement flatrates = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
                flatrates.key = 'flatrates';
                flatrates.value = getRenderedFlatRates(flatRatesMap);
                renderedContent.rendered.add(flatrates);
            }

            // Rendered Participants
            if (participantIds.size() > 0) {
                final tmpb.TemplateBuilder.TemplateBuilderRenderedElement participants = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
                participants.key = 'participants';
                participants.value = getRenderedParticipants(recordId, participantIds);
                renderedContent.rendered.add(participants);
            }

            // Expiry date
            final tmpb.TemplateBuilder.TemplateBuilderRenderedElement expiry = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
            expiry.key = 'expiry';
            Date expiryDate = (Date)profSheet[0].cuco__gf_prftbly_sheet_end_date__c;
            expiry.value = expiryDate.format();
            renderedContent.rendered.add(expiry);

            // Branch
            final tmpb.TemplateBuilder.TemplateBuilderRenderedElement branch = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
            branch.key = 'branch';
            branch.value = CUCO_Utils.getPicklistLabel('cuco__profitability_sheet__c', 'gf_branch_id__c', profSheet[0].gf_branch_id__c);
            renderedContent.rendered.add(branch);

            // Group
            final tmpb.TemplateBuilder.TemplateBuilderRenderedElement acc = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
            acc.key = 'account';
            acc.value = profSheet[0].cuco__participant_id__r.Name;
            renderedContent.rendered.add(acc);

            // Status
            final tmpb.TemplateBuilder.TemplateBuilderRenderedElement status = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
            status.key = 'status';

            switch on profSheet[0].cuco__gf_prftbly_sheet_stt_desc__c {
                when 'Valid'{
                    status.value = 'VIGENTE';
                }
                when 'Expired'{
                    status.value = 'VENCIDO';
                }
                when 'Cancelled'{
                    status.value = 'CANCELADO';
                }
                when else {
                    status.value = '';
                }
            }
            renderedContent.rendered.add(status);

        } catch(Exception e) {
            final tmpb.TemplateBuilder.TemplateBuilderRenderedElement element = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
            element.key ='error';
            element.value = e.getMessage();
            renderedContent.rendered.add(element);
        }

        return renderedContent;
    }

    Boolean handleResult(Id recordId, Object args) {
        return true;
    }

    Boolean isUserAllowed(Id recordId) {
        return true;
    }

    public Object call(String action, Map<String, Object> args) {
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
        return res;
    }

    private static Map<Id, String> getParticipants(Id profSheetId) {
        final Map<Id, String> res = new Map<Id, String>();
        final cuco.ProfitabilitySheetParticipant_Selector selector = new cuco.ProfitabilitySheetParticipant_Selector(new List<String>{'Error_Selector'});
        final List<cuco__profitability_sheet_participant__c> participants = selector.selectByProfSheet(new Set<Id>{profSheetId});
        for (cuco__profitability_sheet_participant__c participant : participants) {
            res.put(participant.cuco__participant_id__c, participant.cuco__participant_id__r.Name);
        }
        return res;
    }

    private static Map<String, Object> getConditions(Id recordId) {
        final Set<Id> conditionIds = new Set<Id>();
        final List<cuco.Conditions_Wrapper> responses = cuco.ProfitabilitySheetCondition_Service.getProfitabilitySheetConditions(recordId);
        for (cuco.Conditions_Wrapper response : responses) {
          conditionIds.add(response.id);
        }
        return getConditions(responses, conditionIds);
    }

    private static Map<String, Object> getConditions(Id recordId, Set<Id> conditionIds) {
        final List<cuco.Conditions_Wrapper> responses = cuco.ProfitabilitySheetCondition_Service.getProfitabilitySheetConditions(recordId);
        return getConditions(responses, conditionIds);
    }

    /**
    * @description get map of conditions
    */
    private static Map<String, Object> getConditions(List<cuco.Conditions_Wrapper> responses, Set<Id> conditionIds) {

        final Map<String, Object> conditions = new map<String, Object>();

        for (cuco.Conditions_Wrapper response : responses) {

            if (conditionIds.contains((Id)response.id)) {

                Map<String, Object> product = new Map<String, Object>();
                Map<String, Object> family = new Map<String, Object>();
                final Map<String, Object> condition = new Map<String, Object>();

                Map<String, Object> productFamilies = new Map<String, Object>();
                Map<String, Object> familyConditions = new Map<String, Object>();
                final Map<String, Object> conditionAtributes = new Map<String, Object>();

                if (conditions.containsKey(response.productName)) {
                    product = (Map<String, Object>)conditions.get(response.productName);
                    productFamilies = (Map<String, Object>)product.get('families');
                } else {
                    product.put('name', response.productName);
                    product.put('families', productFamilies);
                    conditions.put(response.productName, product);
                }

                if (productFamilies.containsKey(response.familyId)) {
                    family = (Map<String, Object>)productFamilies.get(response.familyId);
                    familyConditions = (Map<String, Object>)family.get('conditions');
                } else {
                    family.put('name', response.familyName);
                    family.put('conditions', familyConditions);
                    productFamilies.put(response.familyId, family);
                }

                condition.put('name', response.name);
                condition.put('id', response.id);
                condition.put('familyLevel', response.familyLevel);
                condition.put('source', response.source);
                condition.put('attributes', conditionAtributes);

                for (cuco.Conditions_Wrapper.ConditionAttribute attr : response.attributes) {
                    final Map<String, Object> attribute = new Map<String, Object>();
                    attribute.put('id', attr.id);
                    attribute.put('name', attr.name);
                    attribute.put('type', attr.type);
                    attribute.put('order', attr.order);
                    attribute.put('visible', attr.visible);
                    attribute.put('unitType', attr.unitType);
                    attribute.put('formatType', attr.formatType);
                    attribute.put('value', attr.value);
                    conditionAtributes.put(attr.id, attribute);
                }

                familyConditions.put(response.id, condition);
            }
        }
        return conditions;
    }

    /**
    * @description get map of flat rates
    */
    private static Map<String, Object> getFlatRates(Id profSheetId) {

        Map<String, Object> res = new Map<String, Object>();

        final Map<String,Object> mapPSDetails = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(profSheetId);

        if ((Boolean) mapPSDetails.get('success') && mapPSDetails.get('profSheetDetails') != null) {

            res.put('success', true);
            final cuco.ProfitabilitySheet_Wrapper psWrapp = (cuco.ProfitabilitySheet_Wrapper) mapPSDetails.get('profSheetDetails');
            res.put('flatRatesWrapper', mapPSDetails);
            res.put('flatRatesInfo', mapPSDetails.get('flatRates'));
            Map<String, Object> flatConditions = new Map<String, Object>();

            if (psWrapp.flatRates != null) {

                // Details
                res.put('chargeDay', psWrapp.flatRates.chargeDay);
                res.put('chargeType', CUCO_Utils.getPicklistLabel('cuco__profitability_sheet_flat_rates__c', 'cuco__gf_ps_fr_charge_type__c', psWrapp.flatRates.chargeType));
                res.put('fixedAmount', (psWrapp.flatRates.priceType == 'EF') ? 'Variable' : psWrapp.flatRates.fixedAmount.format() + '€');
                res.put('periodicity', CUCO_Utils.getPicklistLabel('cuco__profitability_sheet_flat_rates__c', 'cuco__gf_ps_fr_charge_pdicy_type__c', psWrapp.flatRates.periodicityChageType));

                // Conditions
                Set<Id> flatConditionIds = new Set<Id>();

                for (cuco.ProfitabilitySheet_Wrapper.Condition psWrappCond : psWrapp.conditionsList) {
                    if (String.valueOf(psWrappCond.source) == 'COMMISSIONS_FLAT') {
                        flatConditionIds.add(psWrappCond.id);
                    }
                }
                final cuco.PsCatalogCondition_Selector psCatSelector = new cuco.PsCatalogCondition_Selector(true);
                final List<cuco__ps_catalog_condition__c> lstPsCatCond = psCatSelector.selectById(flatConditionIds);
                for (cuco__ps_catalog_condition__c psCatCond : lstPsCatCond) {
                    flatConditions.put(psCatCond.id, psCatCond.Name);
                }
            }
            res.put('conditions', flatConditions);
        } else {
            res.put('success', false);
        }
        return res;
    }

    /**
    * @description get html formatted conditions
    */
    private static String getRenderedFlatRates(Map<String, Object> flatRatesMap) {

        Map<String, String> friendlyNames = getFriendlyNames();

        String res = '';
        String flatInfo = '';

        Map<String, String> fixedValues = new Map<String, String>{'fixedAmount' => 'Cargo Anual', 'periodicity' => 'Periodicidad', 'chargeDay' => 'Día de cargo', 'chargeType' => 'Tipo de cargo'};

        for (String fixedValue : fixedValues.keySet()) {
            if (flatRatesMap.get(fixedValue) != null) {
                flatInfo = flatInfo + '<tr style="border-bottom:1px solid #ddd;text-align:right"><td width=100% style="border-bottom:1px solid #ddd;text-align:left;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">';
                flatInfo = flatInfo + friendlyName((String)fixedValues.get(fixedValue), friendlyNames);
                flatInfo = flatInfo + '</td><td style="border-bottom:1px solid #ddd;text-align:right;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">';
                flatInfo = flatInfo + friendlyName((String)flatRatesMap.get(fixedValue), friendlyNames);
                flatInfo = flatInfo + '</td></tr>';
            }
        }

        final Map<String, Object> conditions = (Map<String, Object>)flatRatesMap.get('conditions');

        if (conditions.size() > 0 || !String.isEmpty(flatInfo)) {
            res = res + '<p style="font-size:18px;font-weight:600;padding-left:5px;">Flat Rates</p>';
            res = res + '<table cellpadding="5px">';

            if (!String.isEmpty(flatInfo)) {
                res = res + '<tr><th colspan="2" style="border-bottom:1px solid;font-size:14px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"></th></tr>';
                res = res + flatInfo;
            }

            res = res + '<tr><th  colspan="2" style="padding-right:15px;border-bottom:1px solid;font-size:14px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;text-align:left;white-space:nowrap;">Condiciones incluidas en Flat Rates</th></tr>';

            for(Id conditionId : conditions.keySet()) {
                res = res + '<tr style="border-bottom:1px solid #ddd;text-align:right">';
                res = res + '<td colspan="2" width="100%" style="border-bottom:1px solid #ddd;text-align:left;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">' + friendlyName((String)conditions.get(conditionId), friendlyNames) + '</td></tr>';
            }
            res = res + '</table>';
        }
        return res;
    }

    /**
    * @description get html formatted conditions
    */
    private static String getRenderedConditions(Map<String, Object> conditionsMap) {

        String res = '';

        Map<String, String> friendlyNames = getFriendlyNames();

        for (String productKey : conditionsMap.keySet()) {

            final Map<String, Object> product = (Map<String, Object>)conditionsMap.get(productKey);
            final Map<String, Object> families = (Map<String, Object>)product.get('families');

            // Product Header
            res = res + '<p style="font-size:18px;font-weight:600;padding-left:5px;">' + friendlyName(String.valueOf(product.get('name')), friendlyNames) + '</p>';

            for (String familyKey : families.keySet()) {

                final Map<String, Object> family = (Map<String, Object>)families.get(familyKey);
                final Map<String, Object> familyConditions = (Map<String, Object>)family.get('conditions');
                final Map<String, Object> familyAttributes = getFamilyAttributes(familyConditions);
                final Integer colspan = familyAttributes.size();

                // Family Header
                res = res + '<table cellpadding="5px"><tr><th style="border-bottom:1px solid;font-size:14px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;text-align:left;">' + friendlyName(String.valueOf(family.get('name')), friendlyNames) + '</th>';
                res = res + '<th colspan="' + colspan + '" style="padding-right:15px;border-bottom:1px solid;font-size:14px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;text-align:right;white-space: nowrap;">Tarifas autorizadas</th></tr>';

                // Attribute Legends
                res = res + '<tr style="border-bottom:1px solid #ddd;text-align:right">';
                res = res + '<th width=100%  style="border-bottom:1px solid #ddd;text-align:right"></th>';

                for (String attrKey : familyAttributes.keySet()) {
                    final Map<String, Object> attr = (Map<String, Object>)familyAttributes.get(attrKey);
                    res = res + '<th style="padding-right:15px;border-bottom:1px solid #ddd;font-size:12px;text-align:right;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">' + attr.get('label') + '</th>';
                }

                res = res + '</tr>';

                for (String condKey : familyConditions.keySet()) {

                    final Map<String, Object> familyCondition = (Map<String, Object>)familyConditions.get(condKey);
                    final Map<String, Object> conditionAttributes = (Map<String, Object>)familyCondition.get('attributes');

                    // Condition
                    res = res + '<tr style="border-bottom:1px solid #ddd;text-align:right">';
                    res = res + '<td width=100% style="border-bottom:1px solid #ddd;text-align:left;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">' + friendlyName(String.valueOf(familyCondition.get('name')), friendlyNames) + '</td>';

                    // Attributes
                    for (String attrKey2 : familyAttributes.keySet()) {

                        final Map<String, Object> familyAttr = (Map<String, Object>)familyAttributes.get(attrKey2);
                        res = res + '<td style="border-bottom:1px solid #ddd;text-align:right;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">';
                        res = res + getAttributeSuffix(familyAttr, conditionAttributes);
                        res = res +  '</td>';
                    }
                    res = res + '</tr>';
                }
                res = res + '</table>';
            }
        }
        return res;
    }

    /**
    * @description get html formatted list of participants
    */
    private static String getRenderedParticipants(Id recordId, Set<Id> participantIds) {
        String res = '';
        final Map<Id, String> participants = getParticipants(recordId);
        res = res + '<p style="font-size:18px;font-weight:600;padding-left:5px;">Subsidirias incluidas en este cuaderno de condiciones</p>';
        for (Id key : participants.keySet()) {
            if(participantIds.contains(key)) {
                res = res + '<p style="font-size:14px;padding-left:15px;">' + participants.get(key) + '</p>';
            }
        }
        return res;
    }

    /**
    * @description return friendly name if exists
    */
    private static String friendlyName(String key, Map<String, String> friendlyNames) {
        String res = key;
        if (friendlyNames.containsKey(key)) {
            res = friendlyNames.get(key);
        }
        return res;
    }

    /**
    * @description load friendly names from metadata
    */
    private static Map<String, String> getFriendlyNames() {
        Map<String, String> res = new Map<String, String>();
        List<Cuco_Friendly_Names__mdt> friendlynames = [select condition_id__c, friendly_name__c from Cuco_Friendly_Names__mdt];
        for (Cuco_Friendly_Names__mdt friendlyname : friendlynames) {
            res.put(friendlyname.condition_id__c, friendlyname.friendly_name__c);
        }
        return res;
    }

    /**
    * @description get family attributes
    */
    private static Map<String, Object> getFamilyAttributes(Map<String, Object> familyConditions) {
        final Map<String, Object> familyAttributes = new Map<String, Object>();
        for (String condKey : familyConditions.keySet()) {
            final Map<String, Object> condition = (Map<String, Object>)familyConditions.get(condKey);
            final Map<String, Object> attributes = (Map<String, Object>)condition.get('attributes');
            for (String attrKey : attributes.keySet()) {
                final Map<String, Object> attribute = (Map<String, Object>)attributes.get(attrKey);
                if (!familyAttributes.containsKey((String)attribute.get('id'))  && (Boolean)attribute.get('visible')) {
                    familyAttributes.put((String)attribute.get('id'), new Map<String, Object>{'id' => (String)attribute.get('id'), 'label' => (String)attribute.get('name'), 'type' => (String)attribute.get('type') });
                }
            }
        }
        return familyAttributes;
    }

    /**
    * @description Update contacts map
    */
    private static Map<string, Object> updateContactsMap(set<Id> participantIds) {

        Map<string, Object> contactsMap = new Map<String, Object>();

        final List<Contact> contacts = [SELECT Id, AccountId, Account.Name, Name, Email, Email_ExternalID__c FROM Contact WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE IsActive = true AND IsDirect = true AND AccountId IN :participantIds)];

        for (Contact cont : contacts) {

            Map<String, Object> contactsAccount = new Map<String, Object>();
            Map<String, Object> contactsContacts = new Map<String, Object>();
            Map<String, Object> contactsContact = new Map<String, Object>();

            if (contactsMap.containsKey(cont.AccountId)) {
                contactsAccount = (Map<String, Object>)contactsMap.get(cont.AccountId);
                contactsContacts = (Map<String, Object>)contactsAccount.get('contacts');
            } else {
                contactsAccount.put('name', cont.Account.Name);
                contactsAccount.put('contacts', contactsContacts);
                contactsMap.put(cont.AccountId, contactsAccount);
            }

            contactsContact.put('id', cont.Id);
            contactsContact.put('name', cont.Name);
            contactsContact.put('email', cont.Email_ExternalID__c);
            contactsContacts.put(cont.Id, contactsContact);
        }
        return contactsMap;
    }

    /**
    * @description return attribute suffix
    */
    private static String getAttributeSuffix (Map<String, Object> familyAttr, Map<String, Object> conditionAttributes) {
        String res = '';
        Set<String> attribList = (Set<String>)conditionAttributes.keySet();
        if (attribList.contains((String)familyAttr.get('id'))) {
            final Map<String, Object> attr = (Map<String, Object>)conditionAttributes.get((String)familyAttr.get('id'));
            switch on (String)familyAttr.get('type') {
                when  'Currency' {
                    res = (String)attr.get('value') + '€';
                }
                when 'Permillage' {
                    res = (String)attr.get('value') + '‰';
                }
                when 'Percent' {
                    res = (String)attr.get('value') + '%';
                }
                when else {
                    res = (String)attr.get('value');
                }
            }
        }
        return res;
    }

}