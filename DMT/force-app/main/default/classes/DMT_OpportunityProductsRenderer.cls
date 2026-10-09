// CIBGLOBALD-4117: renderHtml reads every field through the DMT_ViewController.OpportunityProduct
// wrapper (oppProduct.dealAmount etc.), not the underlying SObjects directly - the field lists below
// are the real OpportunityLineItem/child-object field each wrapper property is populated from (see
// DMT_ViewController.loadRelatedData, the "for (OpportunityLineItem oppItem : ...)" block), traced
// by hand since there is no buildRenderFields()-style single source to derive them from here.
public without sharing class DMT_OpportunityProductsRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // OpportunityLineItem fields behind every oppProduct.* property renderHtml reads, across both
    // the Line and One-Off Deal layouts (oppProduct.countryRating is commented out in renderHtml -
    // not tracked; oppProduct.oppMoneys/DMT_Opportunity_Money__c is populated but never rendered -
    // not tracked either). oldMoneyCalculated (One-Off layout) is a computed value, not its own
    // field - already covered by bbva_prtcp_tranche_amount__c/DMT_NewMoney_BBVA__c below; oldMoney
    // (DMT_OldMoney_BBVA__c) is still read directly by the Line layout, so it stays tracked too.
    private static final Set<String> OPPORTUNITY_LINE_ITEM_FIELDS = new Set<String>{
        'DMT_TXT_ProductNameOLI__c', 'DES_Product_Name__c', 'DMT_Line_Oneoffdeal__c', 'gf_initial_date__c', 'gf_maturity_date__c',
        'DMT_Risk_Type__c', 'loan_purpose_desc__c', 'DMT_TXT_Comentarios__c', 'DMT_Deal_amount__c', 'bbva_prtcp_tranche_amount__c',
        'DMT_NewMoney_BBVA__c', 'DMT_OldMoney_BBVA__c', 'entity_role_type__c', 'DMT_Sub_Limit__c', 'syndicated_loan_drawn_amount__c',
        'DMT_Expected_Drawn__c',
        'gf_amortization_type__c', 'gf_payment_frequency__c', 'DMT_RateType__c', 'g_currency_id__c', 'gf_accrual_fees_bp__c',
        'DMT_PricingGrid_OR_StepUps__c', 'Funding_Curve__c', 'gf_funding_cost_fb__c', 'gf_funding_cost_db__c', 'Life_Funding_Type__c',
        'DMT_sustainable_deal_assessment__c', 'DMT_Sustainable_Deal_Subtype__c', 'DMT_sustainable_deal_value__c',
        'DMT_Sustainability_deal_value_criteria__c', 'DMT_PER_Sustainability_Percentage__c', 'DMT_Sustainability_bonus_eligible__c',
        'gf_country_risk__c', 'g_line_commitment_level_type__c', 'DMT_Line_Tenor__c', 'DMT_Reference_Upfront_Fees__c',
        // CIBGLOBALD-4329 - edited via dmt_opp_product_details_schedule.js.
        'DMT_bullet_amortization_indicator__c', 'DMT_balloon_amortization_indicator__c'
        // CIBGLOBALD-4329 - not editable via dmt_opp_product_details_line_description anymore:
        // DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c,
        // DMT_TXT_Other_Fees_NonAccrual__c, DMT_Utilisation_Fee__c. Still read by
        // DMT_NBC_OppEconomicsRenderer, so kept in DMT_View_Selector's query.
        // CIBGLOBALD-4329 - not editable via dmt_opp_product_details_deal_description_fields.js
        // anymore: DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c,
        // DES_Other_Fees__c. DMT_Extension_Duration_Fees__c stays in DMT_View_Selector's query for
        // DMT_NBC_OppEconomicsRenderer.
    };

    private static final Set<String> OPPORTUNITY_TENOR_FIELDS = new Set<String>{
        'gf_tenor_date__c', 'gj_nominal_amount_db__c', 'gf_nominal_amount_fb__c', 'gf_spread_db__c',
        'gf_spread_fb__c', 'gf_accrual_fees_bp__c', 'gf_non_accrual_fees_bp__c'
    };

    private static final Set<String> OPPORTUNITY_MITIGANT_FIELDS = new Set<String>{
        'Mitigant_Type__c', 'Commercial_Percentage__c', 'Political_Percentage__c', 'End_Date__c',
        'Internal_Rating__c', 'External_Rating__c', 'DMT_Currency__c', 'DMT_Country_Guarantor__c',
        'Liquidation_Period__c', 'DMT_Guarantor_Display__c', 'DMT_Scoring__c'
    };

    // Rendered via buildUnderlyingRestrictionTable/buildUnderlyingProfitabilityTable for Line-type
    // deals - one section covers both tables (DMT_Underlying_Type__c distinguishes them), the same
    // "union the fields, one section per object" pattern opportunityBusinessPlan already uses.
    private static final Set<String> UNDERLYING_FIELDS = new Set<String>{
        'Name', 'DMT_Max_Amount__c', 'DMT_Max_Term__c', 'DMT_Other_restrictions__c',
        'DMT_Drawn_Reference_Amount__c', 'DMT_Undrawn_Reference_Amount__c', 'DMT_Term__c',
        'DMT_Drawn_Speed__c', 'DMT_Undrawn_Spread__c', 'DMT_Upfront_Fees__c', 'DMT_Upfront_Fees_amount__c',
        'DMT_Amortization_Type__c', 'DMT_Interest_Payment_Frequency__c', 'DMT_Currency__c',
        // CIBGLOBALD-4117 - decides which of the two tables (Restriction vs. Profitability) a row
        // renders into, per this class's own header comment above - the same
        // branch-selector-field-must-be-tracked pattern as Booking_Geography__c elsewhere in this
        // ticket. Found untracked via a field-drift audit.
        'DMT_Underlying_Type__c'
    };

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    // No top-level Opportunity fields to track here - everything lives in the child objects below.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>();
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'OpportunityLineItem' => new List<String>(OPPORTUNITY_LINE_ITEM_FIELDS),
            'DMT_Opportunity_Tenor__c' => new List<String>(OPPORTUNITY_TENOR_FIELDS),
            'DMT_Opportunity_Mitigant__c' => new List<String>(OPPORTUNITY_MITIGANT_FIELDS),
            'DMT_Underlying__c' => new List<String>(UNDERLYING_FIELDS)
        };
    }

    // All four are direct children of the Opportunity via a relationship path back to
    // OpportunityLineItem's own OpportunityId - parentValueField is 'Id' for all of them (the
    // Opportunity's own Id), childLookupField carries the (possibly cross-object) path to reach it.
    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row;
    //                         shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Shared across every component that reads the same child
    //                         object under the same key - fields from all of them get queried and
    //                         compared together, so add/remove fields on the OBJECT's
    //                         getTrackedFieldsByObject() map, never invent a new key for one field.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Opportunity/Line) whose value is matched
    //                         against childLookupField - almost always 'Id'; a different value here
    //                         means an extra hop (see Custom_Association_Client__c's hand-written
    //                         special case in DMT_ApprovalChangeStep_Handler for why that one isn't
    //                         generic).
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'opportunityLineItem', 'OpportunityLineItem', 'OpportunityId', 'Id', 'DMT_Deal_Amount_Tenors__c ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'opportunityTenor', 'DMT_Opportunity_Tenor__c', 'DMT_Opportunity_Product__r.OpportunityId', 'Id', 'gj_nominal_amount_db__c ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'opportunityMitigant', 'DMT_Opportunity_Mitigant__c', 'DMT_Opportunity_Product__r.OpportunityId', 'Id', 'Mitigant_Type__c ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'opportunityUnderlying', 'DMT_Underlying__c', 'DMT_Opportunity_Product__r.OpportunityId', 'Id'
            )
        };
    }

    // ==========================================
    // HELPER METHODS: Form Grids (DisplayFields)
    // ==========================================

    private List<DMT_FormattingUtils.DisplayField> buildDetailFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(oppProduct.name)),
            new DMT_FormattingUtils.DisplayField('Line / One Off Deal', DMT_FormattingUtils.checkNull(oppProduct.lineOneOffDeal)),
            new DMT_FormattingUtils.DisplayField('Product Start Date', DMT_FormattingUtils.changeDateFormat(oppProduct.initialDate)),
            new DMT_FormattingUtils.DisplayField('Product Maturity Date', DMT_FormattingUtils.changeDateFormat(oppProduct.maturityDate)),
            new DMT_FormattingUtils.DisplayField('Risk Type', DMT_FormattingUtils.checkNull(oppProduct.riskType)),
            new DMT_FormattingUtils.DisplayField('Use of Proceeds', DMT_FormattingUtils.checkNull(oppProduct.useOfProceeds)),
            new DMT_FormattingUtils.DisplayField('Comments:', DMT_FormattingUtils.checkNull(oppProduct.comments))
        };
    }

    // CIBGLOBALD-4329 - matches dmt_opp_product_details_deal_description_fields.js: Role of BBVA /
    // Sub-limit render last, and Liquidity Fee / Commitment Fee / Extension-Duration Fee / Other Fees
    // are gone (no longer editable in that LWC).
    private List<DMT_FormattingUtils.DisplayField> buildDealDescriptionFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> dealDescriptionFields = new List<DMT_FormattingUtils.DisplayField>();
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Deal amount', DMT_FormattingUtils.checkNull(oppProduct.dealAmount)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('BBVA commitment amount', DMT_FormattingUtils.checkNull(oppProduct.bbvaPrtcpTrancheAmount)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('New money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.newMoney)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Old money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.oldMoneyCalculated)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Expected BBVA Final Take', DMT_FormattingUtils.checkNull(oppProduct.expectedFinalTakeBBVA)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Expected Drawn (%)', DMT_FormattingUtils.checkNull(oppProduct.expectedDrawn)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Role of BBVA', DMT_FormattingUtils.checkNull(oppProduct.roleType)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Sub-limit (if any)', DMT_FormattingUtils.checkNull(oppProduct.subLimit)));
        return dealDescriptionFields;
    }

    // CIBGLOBALD-4329 - Interest Rate Period is hidden for Bullet amortization, matching
    // dmt_opp_product_details_schedule.js's own isHidden logic.
    private List<DMT_FormattingUtils.DisplayField> buildScheduleFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> scheduleFields = new List<DMT_FormattingUtils.DisplayField>();
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Amortization Type', DMT_FormattingUtils.checkNull(oppProduct.amortizationType)));
        if (oppProduct.amortizationType != 'Bullet') {
            scheduleFields.add(new DMT_FormattingUtils.DisplayField('Interest Rate Period', DMT_FormattingUtils.checkNull(oppProduct.paymentFrequency)));
        }
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Margin Rate Type', DMT_FormattingUtils.checkNull(oppProduct.rateType)));
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(oppProduct.TenorsCurrency)));
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Accrual Fees (BPS)', DMT_FormattingUtils.checkNull(oppProduct.gf_accrual_fees_bp)));
        return scheduleFields;
    }

    private List<DMT_FormattingUtils.DisplayField> buildPricingGridField(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Pricing Grid or Step-ups (if applicable)', DMT_FormattingUtils.checkNull(oppProduct.pricingGrid), 'FULL')
        };
    }

    private List<DMT_FormattingUtils.DisplayField> buildFundingFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> fundingFields = new List<DMT_FormattingUtils.DisplayField>();
        Boolean fundingManual = oppProduct.fundingCurve == 'Manual';

        fundingFields.add(new DMT_FormattingUtils.DisplayField('CoF Manual', fundingManual));
        if (fundingManual) {
            fundingFields.add(new DMT_FormattingUtils.DisplayField('CoF Drawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingDrawnBPS, oppProduct.TenorsCurrency)));
            fundingFields.add(new DMT_FormattingUtils.DisplayField('CoF Undrawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingUndrawnBPS, oppProduct.TenorsCurrency)));
        } else {
            fundingFields.add(new DMT_FormattingUtils.DisplayField('Time of Cost of Funding', DMT_FormattingUtils.checkNull(oppProduct.fundingTerm)));
        }
        return fundingFields;
    }

    private List<DMT_FormattingUtils.DisplayField> buildSustainabilityFields(DMT_ViewController.OpportunityProduct oppProduct) {
        // Assessment and Subtype are standard picklists
        String assessPickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem', 'DMT_sustainable_deal_assessment__c').get(oppProduct.sustainableDealAssessment);
        String subtypePickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem', 'DMT_Sustainable_Deal_Subtype__c').get(oppProduct.sustainableDealSubtype);

        // Ensure fallbacks if picklist labels return null
        assessPickLabel = assessPickLabel != null ? assessPickLabel : oppProduct.sustainableDealAssessment;
        subtypePickLabel = subtypePickLabel != null ? subtypePickLabel : oppProduct.sustainableDealSubtype;

        // Map Green Activity Filter
        String greenFilterLabel = '';
        if (oppProduct.greenActivityFilter == 'delegated') {
            greenFilterLabel = 'Delegated Label';
        } else if (oppProduct.greenActivityFilter == 'other') {
            greenFilterLabel = 'Other Green Activity';
        } else {
            greenFilterLabel = oppProduct.greenActivityFilter;
        }

        // Deal Label uses the translated value from the taxonomy query
        String dealLabel = oppProduct.sustainableDealLabel;

        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Assessment', DMT_FormattingUtils.checkNull(assessPickLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Subcategory', DMT_FormattingUtils.checkNull(subtypePickLabel)),

            // Row 2
            new DMT_FormattingUtils.DisplayField('Green Activity Filter', DMT_FormattingUtils.checkNull(greenFilterLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Label', DMT_FormattingUtils.checkNull(dealLabel)),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Sustainability Percentage (%)', DMT_FormattingUtils.checkNull(oppProduct.sustainablePercentage)),
            new DMT_FormattingUtils.DisplayField('Sustainability bonus-eligible', DMT_FormattingUtils.checkNull(oppProduct.sustainabilityBonusEligible))
        };
    }

    private List<DMT_FormattingUtils.DisplayField> buildCountryRiskFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Country', DMT_FormattingUtils.checkNull(oppProduct.country))
            // new DMT_FormattingUtils.DisplayField('Country Rating', DMT_FormattingUtils.checkNull(oppProduct.countryRating))
        };
    }

    private String getSafePercentage(Decimal val) {
        return val != null ? String.valueOf(Integer.valueOf(val)) : '';
    }

    // ==========================================
    // LINE-SPECIFIC HELPER METHODS
    // ==========================================

    private List<DMT_FormattingUtils.DisplayField> buildLineGeneralInfoFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(oppProduct.name)),
            new DMT_FormattingUtils.DisplayField('Line / One Off Deal', DMT_FormattingUtils.checkNull(oppProduct.lineOneOffDeal)),
            new DMT_FormattingUtils.DisplayField('Line Type', DMT_FormattingUtils.checkNull(oppProduct.lineType)),
            new DMT_FormattingUtils.DisplayField('Line Tenor', DMT_FormattingUtils.checkNull(getLineTenorLabel(oppProduct.lineTenor))),
            new DMT_FormattingUtils.DisplayField('Risk Type', DMT_FormattingUtils.checkNull(oppProduct.riskType)),
            new DMT_FormattingUtils.DisplayField('Use of Proceeds', DMT_FormattingUtils.checkNull(oppProduct.useOfProceeds)),
            new DMT_FormattingUtils.DisplayField('Comments', DMT_FormattingUtils.checkNull(oppProduct.comments))
        };
    }

    private static final Map<String, String> LINE_TENOR_LABEL_BY_VALUE = new Map<String, String>{
        '' => ' ',
        '0' => '0',
        '7' => '1 week',
        '15' => '2 weeks',
        '21' => '3 weeks',
        '31' => '1 month',
        '62' => '2 months',
        '92' => '3 months',
        '122' => '4 months',
        '153' => '5 months',
        '183' => '6 months',
        '214' => '7 months',
        '244' => '8 months',
        '275' => '9 months',
        '305' => '10 months',
        '336' => '11 months',
        '366' => '1 year',
        '397' => '13 months',
        '424' => '14 months',
        '454' => '15 months',
        '484' => '16 months',
        '514' => '17 months',
        '545' => '1,5 years',
        '575' => '19 months',
        '605' => '20 months',
        '635' => '21 months',
        '666' => '22 months',
        '696' => '23 months',
        '726' => '2 years',
        '756' => '25 months',
        '787' => '26 months',
        '817' => '27 months',
        '847' => '28 months',
        '877' => '29 months',
        '908' => '2,5 years',
        '938' => '31 months',
        '968' => '32 months',
        '998' => '33 months',
        '1029' => '34 months',
        '1059' => '35 months',
        '1089' => '3 years',
        '1119' => '37 months',
        '1150' => '38 months',
        '1180' => '39 months',
        '1210' => '40 months',
        '1240' => '41 months',
        '1271' => '3,5 years',
        '1301' => '43 months',
        '1331' => '44 months',
        '1361' => '45 months',
        '1392' => '46 months',
        '1422' => '47 months',
        '1452' => '4 years',
        '1482' => '49 months',
        '1513' => '50 months',
        '1543' => '51 months',
        '1573' => '52 months',
        '1603' => '53 months',
        '1634' => '4,5 years',
        '1664' => '55 months',
        '1694' => '56 months',
        '1724' => '57 months',
        '1755' => '58 months',
        '1785' => '59 months',
        '1815' => '5 years',
        '1918' => '5,25 years',
        '2009' => '5,5 years',
        '2100' => '5,75 years',
        '2192' => '6 years',
        '2283' => '6,25 years',
        '2374' => '6,5 years',
        '2465' => '6,75 years',
        '2557' => '7 years',
        '2648' => '7,25 years',
        '2739' => '7,5 years',
        '2831' => '7,75 years',
        '2922' => '8 years',
        '3013' => '8,25 years',
        '3105' => '8,5 years',
        '3196' => '8,75 years',
        '3287' => '9 years',
        '3379' => '9,25 years',
        '3470' => '9,5 years',
        '3561' => '9,75 years',
        '3653' => '10 years',
        '3835' => '10,5 years',
        '4018' => '11 years',
        '4200' => '11,5 years',
        '4383' => '12 years',
        '4566' => '12,5 years',
        '4748' => '13 years',
        '4931' => '13,5 years',
        '5114' => '14 years',
        '5296' => '14,5 years',
        '5479' => '15 years',
        '5844' => '16 years',
        '6209' => '17 years',
        '6575' => '18 years',
        '6940' => '19 years',
        '7305' => '20 years',
        '7670' => '21 years',
        '8036' => '22 years',
        '8401' => '23 years',
        '8766' => '24 years',
        '9131' => '25 years',
        '9497' => '26 years',
        '9862' => '27 years',
        '10227' => '28 years',
        '10592' => '29 years',
        '10958' => '30 years',
        '11323' => '31 years',
        '11688' => '32 years',
        '12053' => '33 years',
        '12419' => '34 years',
        '12784' => '35 years'
    };

    private String getLineTenorLabel(Decimal lineTenorValue) {
        if (lineTenorValue == null) return '';

        String tenorValue = String.valueOf(Integer.valueOf(lineTenorValue));
        return LINE_TENOR_LABEL_BY_VALUE.containsKey(tenorValue)
            ? LINE_TENOR_LABEL_BY_VALUE.get(tenorValue)
            : tenorValue;
    }

    // CIBGLOBALD-4329 - matches dmt_opp_product_details_line_description_fields.js's field order;
    // fee fields removed since they're no longer editable there.
    private List<DMT_FormattingUtils.DisplayField> buildLineDescriptionFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Line Amount', DMT_FormattingUtils.checkNull(oppProduct.lineAmount)),
            new DMT_FormattingUtils.DisplayField('BBVA Commitment Line Amount', DMT_FormattingUtils.checkNull(oppProduct.bbvaPrtcpTrancheAmount)),
            new DMT_FormattingUtils.DisplayField('New Money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.newMoney)),
            new DMT_FormattingUtils.DisplayField('Old Money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.oldMoney)),
            new DMT_FormattingUtils.DisplayField('Expected BBVA Final Take', DMT_FormattingUtils.checkNull(oppProduct.expectedFinalTakeBBVA)),
            new DMT_FormattingUtils.DisplayField('Expected Drawn (%)', DMT_FormattingUtils.checkNull(oppProduct.expectedDrawn)),
            new DMT_FormattingUtils.DisplayField('Role of BBVA', DMT_FormattingUtils.checkNull(oppProduct.roleType)),
            new DMT_FormattingUtils.DisplayField('Sub-limit (if any)', DMT_FormattingUtils.checkNull(oppProduct.subLimit)),
            new DMT_FormattingUtils.DisplayField('Line Currency', DMT_FormattingUtils.checkNull(oppProduct.lineCurrency)),
            new DMT_FormattingUtils.DisplayField('Reference Upfront Fees (BPS)', DMT_FormattingUtils.checkNull(oppProduct.referenceUpfrontFees))
        };
    }

    private DMT_FormattingUtils.DataTableWrapper buildUnderlyingRestrictionTable(DMT_ViewController.OpportunityProduct oppProduct) {
        // CIBGLOBALD-4117 - added a 'Type' column showing DMT_Underlying_Type__c's own raw value.
        // Which of these two tables a row lands in already reflects this field, but that's a subtler
        // signal than an explicit value (unlike Booking_Geography__c, which switches the whole
        // layout) - an approver could miss a row silently moving tables. Found via a field-drift audit.
        DMT_FormattingUtils.DataTableWrapper table = new DMT_FormattingUtils.DataTableWrapper('Underlying Restriction', new List<String>{
            'Underlying', 'Type', 'Max Amount', 'Max Term', 'Other restrictions'
        });
        for (DMT_Underlying__c und : oppProduct.oppUnderlyingsRestriction) {
            table.rows.add(new List<String>{
                DMT_FormattingUtils.checkNull(und.Name),
                DMT_FormattingUtils.checkNull(und.DMT_Underlying_Type__c),
                DMT_FormattingUtils.checkNull(und.DMT_Max_Amount__c),
                DMT_FormattingUtils.checkNull(und.DMT_Max_Term__c),
                DMT_FormattingUtils.checkNull(und.DMT_Other_restrictions__c)
            });
        }
        return table;
    }

    // CIBGLOBALD-4329 - mirrors dmt_opp_product_details_line_underlyings.js's _getUpfrontFeeUnit():
    // BPS only when DMT_Upfront_Fees__c is non-zero and DMT_Upfront_Fees_amount__c is zero.
    private Boolean isUnderlyingUpfrontFeeBps(DMT_Underlying__c und) {
        Decimal amountValue = und.DMT_Upfront_Fees_amount__c != null ? und.DMT_Upfront_Fees_amount__c : 0;
        Decimal bpsValue = und.DMT_Upfront_Fees__c != null ? und.DMT_Upfront_Fees__c : 0;
        return bpsValue != 0 && amountValue == 0;
    }

    private DMT_FormattingUtils.DataTableWrapper buildUnderlyingProfitabilityTable(DMT_ViewController.OpportunityProduct oppProduct) {
        // CIBGLOBALD-4329 - Interest Payment Frequency column only shows when at least one row is
        // not Bullet, matching dmt_opp_product_details_line_underlyings.js's showInterestPaymentFrequency.
        Boolean showInterestPaymentFrequency = false;
        for (DMT_Underlying__c und : oppProduct.oppUnderlyingsProfitability) {
            if (und.DMT_Amortization_Type__c != 'Bullet') {
                showInterestPaymentFrequency = true;
                break;
            }
        }

        List<String> headers = new List<String>{
            'Underlying', 'Type', 'Drawn Reference Amount', 'Undrawn Reference Amount', 'Term',
            'Drawn Spread (BPS)', 'Undrawn Spread (BPS)', 'Upfront Fees', 'Amount / BPS', 'Amortization Type'
        };
        if (showInterestPaymentFrequency) {
            headers.add('Interest Payment Frequency');
        }
        headers.add('Currency');

        DMT_FormattingUtils.DataTableWrapper table = new DMT_FormattingUtils.DataTableWrapper('Underlying Profitability', headers);
        for (DMT_Underlying__c und : oppProduct.oppUnderlyingsProfitability) {
            Boolean isBps = isUnderlyingUpfrontFeeBps(und);
            Decimal upfrontFeeValue = isBps ? und.DMT_Upfront_Fees__c : und.DMT_Upfront_Fees_amount__c;

            List<String> row = new List<String>{
                DMT_FormattingUtils.checkNull(und.Name),
                DMT_FormattingUtils.checkNull(und.DMT_Underlying_Type__c),
                DMT_FormattingUtils.checkNull(und.DMT_Drawn_Reference_Amount__c),
                DMT_FormattingUtils.checkNull(und.DMT_Undrawn_Reference_Amount__c),
                DMT_FormattingUtils.checkNull(und.DMT_Term__c),
                DMT_FormattingUtils.checkNull(und.DMT_Drawn_Speed__c),
                DMT_FormattingUtils.checkNull(und.DMT_Undrawn_Spread__c),
                DMT_FormattingUtils.checkNull(upfrontFeeValue),
                isBps ? 'BPS' : 'Amount',
                DMT_FormattingUtils.checkNull(und.DMT_Amortization_Type__c)
            };
            if (showInterestPaymentFrequency) {
                row.add(DMT_FormattingUtils.checkNull(und.DMT_Interest_Payment_Frequency__c));
            }
            row.add(DMT_FormattingUtils.checkNull(und.DMT_Currency__c));
            table.rows.add(row);
        }
        return table;
    }

    // ==========================================
    // DATA TABLE BUILDERS (For Lists of Records)
    // ==========================================

    // CIBGLOBALD-4329 - mirrors dmt_opp_product_table_tenors.js's _getNonAccrualUnit(): BPS only when
    // gf_non_accrual_fees_bp__c is non-zero and gf_accrual_fees_bp__c is zero.
    private Boolean isTenorNonAccrualBps(DMT_Opportunity_Tenor__c tenor) {
        Decimal amountValue = tenor.gf_accrual_fees_bp__c != null ? tenor.gf_accrual_fees_bp__c : 0;
        Decimal bpsValue = tenor.gf_non_accrual_fees_bp__c != null ? tenor.gf_non_accrual_fees_bp__c : 0;
        return bpsValue != 0 && amountValue == 0;
    }

    private DMT_FormattingUtils.DataTableWrapper buildTenorsTable(DMT_ViewController.OpportunityProduct oppProduct) {
        DMT_FormattingUtils.DataTableWrapper table = new DMT_FormattingUtils.DataTableWrapper('Repayment Schedule', new List<String>{
            'Payment Date', 'Drawn Amount', 'Undrawn Amount', 'Drawn Spread (BPS)', 'Undrawn Spread (BPS)', 'Non Accrual Fees', 'BPS/Amount'
        });

        if (!oppProduct.oppTenors.isEmpty()) {
            for (DMT_Opportunity_Tenor__c tenor : oppProduct.oppTenors) {
                Boolean isBps = isTenorNonAccrualBps(tenor);
                Decimal nonAccrualValue = isBps ? tenor.gf_non_accrual_fees_bp__c : tenor.gf_accrual_fees_bp__c;
                table.rows.add(new List<String>{
                    DMT_FormattingUtils.changeDateFormat(tenor.gf_tenor_date__c),
                    DMT_FormattingUtils.formatCurrencyAmount(tenor.gj_nominal_amount_db__c, oppProduct.TenorsCurrency),
                    DMT_FormattingUtils.formatCurrencyAmount(tenor.gf_nominal_amount_fb__c, oppProduct.TenorsCurrency),
                    DMT_FormattingUtils.checkNull(tenor.gf_spread_db__c),
                    DMT_FormattingUtils.checkNull(tenor.gf_spread_fb__c),
                    DMT_FormattingUtils.checkNull(nonAccrualValue),
                    isBps ? 'BPS' : 'Amount'
                });
            }
        }
        return table;
    }

    private List<DMT_FormattingUtils.DataTableWrapper> buildMitigantTables(DMT_ViewController.OpportunityProduct oppProduct) {
        DMT_FormattingUtils.DataTableWrapper collateralTable = new DMT_FormattingUtils.DataTableWrapper(System.Label.dmt_cl_Collateral_Guarantees_Text, new List<String>{
            'Collateral Type', 'Commercial Risk (%)', 'Political Risk (%)', 'End Date', 'Internal Rating', 'External Rating', 'Currency', 'Country Collateral', 'Liquidation Period'
        });

        DMT_FormattingUtils.DataTableWrapper guarantorTable = new DMT_FormattingUtils.DataTableWrapper(System.Label.dmt_cl_Guarantors_Text, new List<String>{
            'Mitigant Type', 'Guarantor (IDClient - Nombre)', 'Commercial Risk (%)', 'Political Risk (%)', 'End Date', 'Internal Rating', 'Scoring', 'External Rating', 'Currency'
        });

        Set<String> validCollateralTypes = new Set<String>{
            'Real > Mortgage guarantee', 'Real > Cash', 'Real > Gold Bullion', 'Real > Debt securities', 'Real > Debt securities issued by central governments or central Banks', 'Real > Receivables', 'Real > Index equities and Index convertible bonds', 'Real > Securitisation', 'Real > Others real'
        };

        Set<String> validUnfundedTypes = new Set<String>{
            'Others > Guarantee in favour of Public Administration', 'Others > ECA Guarantor (Exporte Credit agency)', 'Others > Shared maintenance clause', 'Personal > Parent guarantee', 'Personal > Corporate', 'Personal > Bank'
        };

        if (!oppProduct.oppMitigants.isEmpty()) {
            for (DMT_Opportunity_Mitigant__c mit : oppProduct.oppMitigants) {
                String type = mit.Mitigant_Type__c;
                if (String.isBlank(type)) continue;

                if (validCollateralTypes.contains(type)) {
                    collateralTable.rows.add(new List<String>{
                        DMT_FormattingUtils.checkNull(type),
                        getSafePercentage(mit.Commercial_Percentage__c),
                        getSafePercentage(mit.Political_Percentage__c),
                        DMT_FormattingUtils.checkNull(mit.End_Date__c),
                        DMT_FormattingUtils.checkNull(mit.Internal_Rating__c),
                        DMT_FormattingUtils.checkNull(mit.External_Rating__c),
                        DMT_FormattingUtils.checkNull(mit.DMT_Currency__c),
                        DMT_FormattingUtils.checkNull(mit.DMT_Country_Guarantor__c),
                        DMT_FormattingUtils.checkNull(mit.Liquidation_Period__c)
                    });
                } else if (validUnfundedTypes.contains(type)) {
                    guarantorTable.rows.add(new List<String>{
                        DMT_FormattingUtils.checkNull(type),
                        DMT_FormattingUtils.checkNull(mit.DMT_Guarantor_Display__c),
                        getSafePercentage(mit.Commercial_Percentage__c),
                        getSafePercentage(mit.Political_Percentage__c),
                        DMT_FormattingUtils.checkNull(mit.End_Date__c),
                        DMT_FormattingUtils.checkNull(mit.Internal_Rating__c),
                        String.valueOf(mit.DMT_Scoring__c != null ? mit.DMT_Scoring__c : 0),
                        DMT_FormattingUtils.checkNull(mit.External_Rating__c),
                        DMT_FormattingUtils.checkNull(mit.DMT_Currency__c)
                    });
                }
            }
        }

        return new List<DMT_FormattingUtils.DataTableWrapper>{ collateralTable, guarantorTable };
    }

    // ==========================================
    // MAIN RENDER METHODS
    // ==========================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppProducts.isEmpty()) return '<div>Product data not provided</div>';

        try {
            String htmlOutput = '<div><h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Products</h2>';

            for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {

                if (oppProduct.lineOneOffDeal == 'Line') {
                    // ===== LINE LAYOUT =====

                    // General Info
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">General Info</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildLineGeneralInfoFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    // Line Description
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Line Description</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildLineDescriptionFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    // UnderLyings
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">UnderLyings</h3><div class="slds-scope">';
                    htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(buildUnderlyingRestrictionTable(oppProduct)) + '</div>&nbsp;</br>';
                    htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(buildUnderlyingProfitabilityTable(oppProduct)) + '</div>&nbsp;</br>';
                    htmlOutput += '</div>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Cost of Funding</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildFundingFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Sustainability</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildSustainabilityFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Country Risk</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildCountryRiskFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Mitigants</h3><div class="slds-scope">';
                    List<DMT_FormattingUtils.DataTableWrapper> lineMitigantTables = buildMitigantTables(oppProduct);
                    for (DMT_FormattingUtils.DataTableWrapper mitTable : lineMitigantTables) {
                        htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(mitTable) + '</div>&nbsp;</br>';
                    }

                } else {
                    // ===== ONE-OFF DEAL LAYOUT (original) =====

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">General Info</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildDetailFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    //Deal Description
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Deal description</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildDealDescriptionFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    //Schedule
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Schedule</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildScheduleFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    // TENORS TABLE
                    htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(buildTenorsTable(oppProduct)) + '</div>';

                    // PRICING GRID (Immediately following table)
                    htmlOutput += '<div class="slds-scope">' + DMT_FormattingUtils.generateHtmlTable(buildPricingGridField(oppProduct)) + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Cost of Funding</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildFundingFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Sustainability</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildSustainabilityFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Country Risk</h3><div class="slds-scope">'
                                + DMT_FormattingUtils.generateHtmlTable(buildCountryRiskFields(oppProduct))
                                + '</div>&nbsp;</br>';

                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Mitigants</h3><div class="slds-scope">';

                    // MITIGANTS TABLES (Collateral & Guarantors)
                    List<DMT_FormattingUtils.DataTableWrapper> mitigantTables = buildMitigantTables(oppProduct);
                    for (DMT_FormattingUtils.DataTableWrapper mitTable : mitigantTables) {
                        htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(mitTable) + '</div>&nbsp;</br>';
                    }
                }
            }
            return htmlOutput + '</div>';

        } catch (Exception e){
            System.debug('Error in DMT_OpportunityProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}