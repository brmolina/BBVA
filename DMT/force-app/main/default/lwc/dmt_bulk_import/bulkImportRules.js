/*
 * CIBGLOBALD-4851 - ORG RULES THE BULK IMPORT SCREEN COPIES - KEEP IN SYNC
 * (technical debt accepted with Diego, 2026-11-20)
 *
 * The Bulk Import screen (LWC dmt_bulk_import) predicts what the org will reject, so that a line is not moved (it stays
 * in Draft, or in its original status, with the reason shown) and the user is told before Process when a row will not be
 * saved. Every rule in this file is a COPY of a rule that lives in the org. When one of the org rules below changes, or a
 * rule is added to them, update its copy here (and the Apex copies listed below), or Bulk Import will try moves the org
 * rejects in the background, or flag lines that would pass.
 *
 * Each function takes the values the line will have once saved (built by dmt_bulk_import.js) and returns the reasons the
 * org would give, empty when it would accept: { message, source } (source = the exact org rule, logged with
 * console.info by dmt_bulk_import.js when the reason is applied, see logRuleReasons). No data access here.
 *
 *  Org rule (where it lives)                                          | Copy
 *  ------------------------------------------------------------------ | -----------------------------------------------
 *  Validation rule DMT_Line__c.Go_through_each_step                   | stepRuleReasons
 *  Apex DMT_Line_Helper.validateRiskLineTermContinuity                | termContinuityError
 *  (called by DMT_Line_TriggerHandler.beforeUpdate)                   |
 *  Apex DMT_Line_Helper.blockReadyToCloseWithProspectInMultiholder     | prospectReasons
 *  (called by DMT_Line_TriggerHandler.beforeUpdate)                   |
 *  Flow DMT_OTHER_Line_Validations (v3), Other Products lines         | otherProductsFlowReasons
 *  Flow CheckAmountsInLine (v3), Other Products lines                 | productsTotalReasons
 *  Flow DMT_TRSR_Line_Validations (v6), Treasury lines                | treasuryFlowReasons
 *  Validation rule DMT_Line__c.ApprovalProcessDataEdit                | approvalDataEditReasons
 *  Formula DMT_Line_Product_Item__c.DMT_RestrictionActive__c          | isActiveProduct
 *  Roll-up DMT_Line__c.DMT_DerivativesAmount__c (MAX)                 | treasuryFlowReasons (derivativesAmount)
 *  Formula DMT_Line__c.Client_Type__c                                 | dmt_bulk_import.js _savedClientType and Apex
 *                                                                     | DMT_BulkImportBatch.clientTypeOf
 *  Validation rule DMT_Line__c.Set_Closed_Won_Lost                    | Apex DMT_BulkImportBatch.buildLine (status code
 *                                                                     | saved in upper case: DMT_BatchSanctionAMIWEB sets
 *                                                                     | Closed__c only for CW / CL)
 *  Picklists DMT_Risk_Line_Term__c.DMT_Init_Term__c / DMT_End_Term__c | Apex DMT_BulkImportBatch.checkTermDays and termDays
 *  Apex DMT_BulkImportBatch.buildUnit (buildLine, putValue,           | rowSaveError (field types and picklist days come
 *  checkTermDays, parseDateValue, parseDecimal)                       | from DMT_BulkImportBatch.fileValueRules)
 *
 * NOT copied on purpose: rules the load itself relies on skipping with DMT_Line_God (the screen only opens with it):
 * validation rules NotBackFromApproval and DMT_NotEditCloseLine (the load sends non-Draft lines to Draft),
 * DMT_Draft_Status, Prospect_Block_Closed_Won and ClosedLine (they also skip DMT_Line_God), and the flow
 * DMT_Validate_Line_Final_Status_Change (the move straight to Ready to close / Closed).
 */

// ── Shared value helpers (also used by dmt_bulk_import.js) ───────────────────────────────────────────────────────────

// A file or Salesforce value as trimmed text ('' for null / undefined)
export const valueText = v => (v === null || v === undefined) ? '' : String(v).trim();

// A file or Salesforce value in the form the comparison and the Apex save use: dates yyyy-mm-dd (also from dd/mm/yyyy),
// numbers with a decimal point, checkboxes true / false
export const normaliseValue = (type, v) => {
    const s = valueText(v);
    if (type === 'date') {
        const dmy = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
        return dmy ? `${dmy[3]}-${dmy[2].padStart(2, '0')}-${dmy[1].padStart(2, '0')}` : s.substring(0, 10);
    }
    if (type === 'number')  return s === '' ? '' : String(Number(s.replace(',', '.')));
    if (type === 'boolean') return ['true', '1', 'yes'].includes(s.toLowerCase()) ? 'true' : 'false';
    return s;
};

// Old Other Products files carry the term columns with this prefix ('DMT_Risk_Line_Term__c DMT_Amount__c')
export const TERM_COLUMN_PREFIX = 'DMT_Risk_Line_Term__c ';

// A term field of a product row, also from the prefixed columns of the old Other Products files
export const termValue = (term, field) => (field in term ? term[field] : term[TERM_COLUMN_PREFIX + field]);

// A checkbox value from a file cell (TRUE / 1 / yes) or from Salesforce (true)
export const isChecked = value => ['true', '1', 'yes'].includes(valueText(value).toLowerCase());

// A term in days as Apex DMT_BulkImportBatch.checkTermDays saves it (365.0 -> 365)
export const termDays = value => {
    const text = valueText(value);
    const number = Number(text.replace(',', '.'));
    return text !== '' && Number.isInteger(number) ? String(number) : text;
};

// A reason the org would give: the full message (toasts, console), a short one (the Status Change cell) and the exact org
// rule it comes from
const reason = (message, source, short) => ({ message, source, short: short || message });

// The messages of a list of reasons: full for toasts, short for the Status Change cell
export const reasonText = reasons => reasons.map(r => r.message).join(', ');
export const reasonShortText = reasons => reasons.map(r => r.short).join(', ');

/**
 * Logs each applied reason with its org source (console.info), so anyone can find where a 'stays in Draft' comes from.
 * Called by dmt_bulk_import when a Status Change cell shows the reason. what = 'stays in Draft, not moved to Proposal'...
 */
export function logRuleReasons(lineId, what, reasons) {
    reasons.forEach(r => {
        // eslint-disable-next-line no-console
        console.info(`[Bulk Import] ${lineId} ${what}: ${r.message} | Source: ${r.source} | Copy: bulkImportRules.js`);
    });
}

const amountOf = value => {
    const text = normaliseValue('number', value);
    return text === '' ? null : Number(text);
};

// ── Validation rule DMT_Line__c.Go_through_each_step ─────────────────────────────────────────────────────────────────

// Profiles the rule lets jump steps ($Profile.Name != 'Desktop Integration' && != 'System Administrator'); DMT_Line_God
// does not bypass it
export const STEP_BYPASS_PROFILES = ['System Administrator', 'Desktop Integration'];

/**
 * Source: validation rule DMT_Line__c.Go_through_each_step (Setup > Object Manager > DMT Line > Validation Rules).
 * From Draft a line may only go to Proposal; Approval, Ready to close and Closed need the previous step, unless the
 * running user's profile is in STEP_BYPASS_PROFILES (or DMT_Cancel__c, which the load never sets).
 */
export function stepRuleReasons(target, profileName) {
    return target !== 'Proposal' && !STEP_BYPASS_PROFILES.includes(profileName)
        ? [reason(`profile ${profileName} cannot jump from Draft`, 'Validation rule DMT_Line__c.Go_through_each_step', 'your profile must move one step at a time')] : [];
}

// ── Apex DMT_Line_Helper.validateRiskLineTermContinuity ──────────────────────────────────────────────────────────────

/**
 * Source: Apex DMT_Line_Helper.validateRiskLineTermContinuity + validateTermGroup, called by
 * DMT_Line_TriggerHandler.beforeUpdate on every status change of the line, no bypass. The Risk Line Terms of the line
 * (as they will be once saved), grouped by DMT_Risk_Type__c (blank type skipped), in their order (the Apex query has no
 * ORDER BY: insertion order): no repeated Init-End pair, every term with Init and End Term, End after Init, no partial
 * overlap, each term starting where the previous one ends. Returns the first problem, or ''.
 */
export function termContinuityError(terms) {
    const byType = new Map();
    terms.forEach(term => {
        const type = valueText(termValue(term, 'DMT_Risk_Type__c'));
        if (!type) return;
        if (!byType.has(type)) byType.set(type, []);
        byType.get(type).push({ init: termDays(termValue(term, 'DMT_Init_Term__c')), end: termDays(termValue(term, 'DMT_End_Term__c')) });
    });
    for (const [type, list] of byType) {
        // validateTermGroup, rule 4 in its comments: repeated Init-End
        const seen = new Set();
        for (const t of list) {
            if (seen.has(`${t.init}_${t.end}`)) return `${type} terms: ${t.init}-${t.end} repeated`;
            seen.add(`${t.init}_${t.end}`);
        }
        for (let i = 0; i < list.length; i++) {
            const current = list[i];
            // rule 1 (first term with Init and End Term) and empty intervals
            if (current.init === '' || current.end === '') return `${type} terms: a term without Init or End Term`;
            // End must be greater than Init
            if (Number(current.end) <= Number(current.init)) return `${type} terms: ${current.init}-${current.end} does not end after it starts`;
            // rule 5: partial overlap with any later term
            for (let j = i + 1; j < list.length; j++) {
                const other = list[j];
                if (other.init === '' || other.end === '') return `${type} terms: a term without Init or End Term`;
                if (Number(current.init) < Number(other.end) && Number(other.init) < Number(current.end) && current.end !== other.init) {
                    return `${type} terms: ${current.init}-${current.end} overlaps ${other.init}-${other.end}`;
                }
            }
            // rules 2 and 3: each term starts where the previous one ends
            if (i > 0 && current.init !== list[i - 1].end) {
                return `${type} terms: gap between ${list[i - 1].init}-${list[i - 1].end} and ${current.init}-${current.end}`;
            }
        }
    }
    return '';
}

// termContinuityError as a list of reasons with its source
export function termContinuityReasons(terms) {
    const error = termContinuityError(terms);
    return error ? [reason(error, 'Apex DMT_Line_Helper.validateRiskLineTermContinuity (DMT_Line_TriggerHandler.beforeUpdate)', error)] : [];
}

// ── Apex DMT_Line_Helper.blockReadyToCloseWithProspectInMultiholder ──────────────────────────────────────────────────

/**
 * Source: Apex DMT_Line_Helper.blockReadyToCloseWithProspectInMultiholder (+ getLineIdsWithProspectInClientOrMultiholder),
 * called by DMT_Line_TriggerHandler.beforeUpdate, no bypass: a line closed Won (Status__c Closed, Closed__c Won, from
 * code CW) whose client has record type Prospect_Group or Prospect_Subsidiary. The multiholder clients the Apex also
 * checks (Custom_Association_Client__c Alpha_Code_Client__c) are not copied.
 */
export function prospectReasons(target, code, clientRecordType) {
    return target === 'Closed' && code === 'CW' && /^Prospect_/.test(clientRecordType || '')
        ? [reason('a Prospect client cannot be closed Won',
                  'Apex DMT_Line_Helper.blockReadyToCloseWithProspectInMultiholder (DMT_Line_TriggerHandler.beforeUpdate)', 'a Prospect client cannot be closed Won')] : [];
}

// ── Flow DMT_OTHER_Line_Validations (Other Products lines) ───────────────────────────────────────────────────────────

// Client types the flow accepts (decision is_client_type)
export const OL_CLIENT_TYPES = ['Customer', 'Custom', 'Golden'];

/**
 * Source: flow DMT_OTHER_Line_Validations (v3, record-triggered after save on DMT_Line__c: Status__c changed to other than
 * Draft, DMT_RecordTypeName__c 'Line', DMT_Cancel__c false), no bypass. Decisions in order: is_client_type (Customer,
 * Custom or Golden), Has_type_of_risk (DMT_LastLevelId__c), Has_line_amount (Amount__c not empty, not 0). Validation rule
 * CompulsoryAmountLastLevel (Proposal without Amount__c and DMT_LastLevelId__c) is covered by the last two.
 * @param line { clientType, typeOfRisk, amount } as saved
 */
export function otherProductsFlowReasons(line) {
    const reasons = [];
    const flow = 'Flow DMT_OTHER_Line_Validations';
    if (!OL_CLIENT_TYPES.includes(line.clientType)) {
        reasons.push(reason(`client type ${line.clientType || 'unknown'}, a customer is needed`,
                            `${flow} > decision is_client_type > error Client_Type_is_Not_customer_or_Custom`, `client type ${line.clientType || 'unknown'} is not allowed`));
    }
    if (valueText(line.typeOfRisk) === '') {
        reasons.push(reason('no type of risk (DMT_LastLevelId__c)', `${flow} > decision Has_type_of_risk > error Type_of_risk_is_empty`, 'the line has no type of risk'));
    }
    const amount = amountOf(line.amount);
    if (amount === null || amount === 0) {
        reasons.push(reason('no line amount (Amount__c)', `${flow} > decision Has_line_amount > error Line_amount_is_empty`, 'the line has no amount'));
    }
    return reasons;
}

// ── Flow CheckAmountsInLine (Other Products lines) ───────────────────────────────────────────────────────────────────

/**
 * Source: flow CheckAmountsInLine (v3, record-triggered before save on DMT_Line__c: Status__c changed to other than Draft,
 * DMT_line_template_type__c 'OL', Closed__c not Lost), no bypass. Get_Risk_Line_term: when a term has no amount the check
 * is skipped; IsAmountOfLineSmallerThanTotal: DMT_RollupAmount__c (sum of the term amounts) must cover Amount__c.
 * Only evaluated with a line amount (otherProductsFlowReasons reports the missing one); skipped for Closed Lost (code CL).
 */
export function productsTotalReasons(line, terms, target, code) {
    const amount = amountOf(line.amount);
    if (amount === null || amount === 0 || (target === 'Closed' && code === 'CL')) return [];
    const amounts = terms.map(t => normaliseValue('number', termValue(t, 'DMT_Amount__c')));
    if (amounts.includes('')) return [];
    const total = amounts.reduce((sum, a) => sum + (Number(a) || 0), 0);
    return total < amount
        ? [reason(`products total ${total} below the line amount ${amount}`, 'Flow CheckAmountsInLine > decision IsAmountOfLineSmallerthan_total', `products total ${total} is below the line amount ${amount}`)]
        : [];
}

// ── Flow DMT_TRSR_Line_Validations (Treasury lines) ──────────────────────────────────────────────────────────────────

// Formula DMT_Line_Product_Item__c.DMT_RestrictionActive__c: DMT_DerivativeRestriction__c || DMT_DVPRestriction__c ||
// DMT_FDRestriction__c, an 'available product' of the line
export const isActiveProduct = item => ['DMT_DerivativeRestriction__c', 'DMT_DVPRestriction__c', 'DMT_FDRestriction__c']
    .some(field => isChecked(item[field]));

// Flow DMT_TRSR_Line_Validations, element Collection_Filter_1 (Repos products filter)
export const REPO_PRODUCT_CODES = ['REAC', 'REPA'];

/**
 * Source: flow DMT_TRSR_Line_Validations (v6, 2026-10-06, record-triggered after save on DMT_Line__c: Status__c changed to
 * other than Draft, DMT_RecordTypeName__c 'Treasury Line', DMT_Cancel__c false). The flow skips System Administrator and
 * DMT_Line_God (decision is_admin_User), i.e. every Bulk Import user; Diego asked to apply it anyway (2026-11-20), because
 * the next normal user who moves the line hits it. Same order and messages as the flow; the flow stops at the first
 * error, this returns every error on the flow's path (a client type that is neither Customer nor Custom ends the path, as
 * in the flow). Flow element names in brackets.
 * @param line    { bookingGeography, endDate, clientType, fdAmount, dvpAmount, waiver } as saved
 * @param items   Line Product Items of the line once saved
 * @param terms   Risk Line Terms of the line once saved
 * @param clients Custom_Association_Client__c of the line (only read for Custom lines)
 */
export function treasuryFlowReasons(line, items, terms, clients) {
    const reasons = [];
    const flow = 'Flow DMT_TRSR_Line_Validations';
    // [Get_Operational_Restrictions]: items with DMT_RestrictionActive__c
    const activeItems = items.filter(isActiveProduct);
    // [At_least_one_Operational_Restriction] -> error No_operational_restrictions
    if (activeItems.length === 0) {
        reasons.push(reason('Available products must be added (at least one Line Product Item with Derivative, DvP or FD restriction)',
                            `${flow} > decision At_least_one_Operational_Restriction > error No_operational_restrictions`, 'no Line Product Item with a restriction checked'));
    }
    // [Filter_derivatives_restriction_without_term] (DMT_DerivativeRestriction__c true, Max_Tenor_WC__c empty) +
    // [Derivatives_restrictions_without_term] (Booking_Geography__c not CO) -> error Derivatives_without_restrictions
    const derivativesWithoutTerm = activeItems.filter(item => isChecked(item.DMT_DerivativeRestriction__c) && valueText(item.Max_Tenor_WC__c) === '');
    if (derivativesWithoutTerm.length > 0 && valueText(line.bookingGeography) !== 'CO') {
        reasons.push(reason('There are Available products for derivatives and without term (Max_Tenor_WC__c)',
                            `${flow} > decision Derivatives_restrictions_without_term > error Derivatives_without_restrictions`, 'a derivatives Line Product Item has no Max Tenor'));
    }
    // [is_endDate_EOM] formula EndDateisnotEOM (last day of the End_Date__c month) -> error End_Date_is_not_EOM_Message
    const endDate = normaliseValue('date', line.endDate);
    if (/^\d{4}-\d{2}-\d{2}$/.test(endDate)) {
        const [year, month, day] = endDate.split('-').map(Number);
        if (day !== new Date(Date.UTC(year, month, 0)).getUTCDate()) {
            reasons.push(reason('End Date should be the last day of the month', `${flow} > decision is_endDate_EOM > error End_Date_is_not_EOM_Message`, 'End Date must be the last day of a month'));
        }
    }
    // [is_client_type]: Customer ends the flow; neither Customer nor Custom -> error Client_Type_is_Not_customer_or_Custom
    if (line.clientType === 'Customer') return reasons;
    if (line.clientType !== 'Custom') {
        reasons.push(reason(`client type ${line.clientType || 'unknown'}: The line has been created, but you must select at least two customers`,
                            `${flow} > decision is_client_type > error Client_Type_is_Not_customer_or_Custom`, `client type ${line.clientType || 'unknown'} needs a Custom line with two clients`));
        return reasons;
    }
    // Custom lines: [getCustomAssociation] [getCustomAssociationClientsLoop]
    // [Collection_Filter_3] (DMT_Amount__c filled, DMT_Term__c empty) + [Decision_8] -> error incorrect_custom_client
    if (clients.some(c => c.DMT_Amount__c !== null && c.DMT_Amount__c !== undefined && !valueText(c.DMT_Term__c))) {
        reasons.push(reason('There are multiholder clients with amounts in derivatives but without a term',
                            `${flow} > decision Decision_8 > error incorrect_custom_client`, 'a client of the Custom line has an amount but no term'));
    }
    // [SetNumberOfCA] + [is_there_more_then_one_client_selected] -> error Client_Type_is_Not_customer_or_Custom2
    if (clients.length < 2) {
        reasons.push(reason('The line has been created, but you must select at least two customers',
                            `${flow} > decision is_there_more_then_one_client_selected > error Client_Type_is_Not_customer_or_Custom2`, 'a Custom line needs at least two clients'));
    }
    // [Loop_fill_CAC] + [Decision_5]: a client amount equal to or above the line's -> error Client_Amounts_are_not_correct.
    // Line amounts: roll-up DMT_DerivativesAmount__c (MAX of the Derivatives and Singular term amounts; empty without such
    // terms), FD_Amount__c, DvP_Amount__c. A flow comparison with an empty value is false: no error then.
    const derivativeAmounts = terms.filter(t => ['Derivatives', 'Singular'].includes(valueText(termValue(t, 'DMT_Risk_Type__c'))))
        .map(t => amountOf(termValue(t, 'DMT_Amount__c'))).filter(a => a !== null);
    const derivativesAmount = derivativeAmounts.length > 0 ? Math.max(...derivativeAmounts) : null;
    const fdAmount  = amountOf(line.fdAmount);
    const dvpAmount = amountOf(line.dvpAmount);
    const tooHigh = (clientValue, lineValue) => clientValue !== null && clientValue !== undefined
                                                && lineValue !== null && lineValue !== undefined && clientValue >= lineValue;
    if (clients.some(c => tooHigh(c.DMT_Amount__c, derivativesAmount) || tooHigh(c.DMT_FDAmount__c, fdAmount)
                          || tooHigh(c.DMT_DVPAmount__c, dvpAmount))) {
        reasons.push(reason('Among some of the selected client, there are some with an amount equal to or greater than those indicated in the line',
                            `${flow} > decision Decision_5 > error Client_Amounts_are_not_correct`, 'a client amount is equal to or above the line amount'));
    }
    // [Get_related_risk_line_term]: terms with an amount other than 0
    const amountTerms = terms.filter(t => { const a = amountOf(termValue(t, 'DMT_Amount__c')); return a !== null && a !== 0; });
    const typeOf = t => valueText(termValue(t, 'DMT_Risk_Type__c'));
    // [Filter_derivatives_risk_line_term] + [Waiver_requirements] (Waiver__c) -> error Waiver_without_requirements_error
    if (isChecked(line.waiver) && (!amountTerms.some(t => typeOf(t) === 'Derivatives') || activeItems.length === 0)) {
        reasons.push(reason('If Exception to the policy is selected, you must add a value to the derivatives risk line and add an available product',
                            `${flow} > decision Waiver_requirements > error Waiver_without_requirements_error`, 'Exception to the policy needs a derivatives amount and an available product'));
    }
    // [All_amount_are_null_or_zero] formulas FDAmountNULL / DvPAmountNULL -> error All_amounts_are_null_error
    if (amountTerms.length === 0 && !fdAmount && !dvpAmount) {
        reasons.push(reason('It is necessary to add some amount', `${flow} > decision All_amount_are_null_or_zero > error All_amounts_are_null_error`, 'the line has no amount in its terms, FD or DvP'));
    }
    // [Filter_equities_risk_line_term] [Filter_depos_in_risk] [Collection_Filter_1] + [Equities_in_line]
    // -> errors Equities_in_multiholder_error / Depos_and_repos_products
    if (amountTerms.some(t => typeOf(t) === 'Equities')) {
        reasons.push(reason('Equities WWR not valid for multiholder', `${flow} > decision Equities_in_line > error Equities_in_multiholder_error`, 'Equities are not allowed on a Custom line'));
    } else if (amountTerms.some(t => typeOf(t) === 'Depos')
               && activeItems.some(item => REPO_PRODUCT_CODES.includes(valueText(item.Product_Code_Value__c)))) {
        reasons.push(reason('Repo and Depos cannot be added', `${flow} > decision Equities_in_line > error Depos_and_repos_products`, 'Repo products cannot go with a Depos term'));
    }
    return reasons;
}

// ── Validation rule DMT_Line__c.ApprovalProcessDataEdit ──────────────────────────────────────────────────────────────

// Fields of the rule a Bulk Import file can change, and the statuses where the rule blocks them
export const APPROVAL_DATA_FIELDS   = ['DMT_Comments__c', 'DMT_Additional_Restrictions__c', 'DMT_Client_Use__c'];
export const APPROVAL_DATA_STATUSES = ['Approval', 'Ready to close', 'Closed'];

/**
 * Source: validation rule DMT_Line__c.ApprovalProcessDataEdit (Setup > Object Manager > DMT Line > Validation Rules). The
 * save of the line is rejected when these fields change while the line stays in Approval, Ready to close or Closed:
 * Treasury lines always (no DMT_Line_God bypass); Other Products lines only when Closed Lost (otherwise DMT_Line_God
 * bypasses it). DMT_Allow_Approval_Edit__c allows it. The rule reads the new status, so the load sends such a line to Draft
 * and the change is saved (dmt_bulk_import _statusMove, DMT_BulkImportBatch.approvalDataLocked).
 * @param line { status, closed, allowApprovalEdit } in Salesforce; changedFields = file columns that differ
 */
export function approvalDataEditReasons(line, changedFields, isTreasury) {
    if (line.allowApprovalEdit) return [];
    const restricted = isTreasury ? APPROVAL_DATA_STATUSES.includes(line.status) : line.status === 'Closed' && line.closed === 'Lost';
    const changed = changedFields.filter(field => APPROVAL_DATA_FIELDS.includes(field));
    return restricted && changed.length > 0
        ? [reason(`${changed.join(', ')} cannot change in ${line.status} (rule ApprovalProcessDataEdit)`,
                  'Validation rule DMT_Line__c.ApprovalProcessDataEdit', `${changed.join(', ')} locked in ${line.status}`)]
        : [];
}

// ── Apex DMT_BulkImportBatch.buildUnit: the errors that reject a row at Process ──────────────────────────────────────

const SAVE_SOURCE = 'Apex DMT_BulkImportBatch.buildUnit (buildLine, putValue, checkTermDays)';
// the term fields checked against their picklist of days (DMT_BulkImportBatch.TERM_DAY_FIELDS)
const TERM_DAY_FIELDS = ['DMT_Init_Term__c', 'DMT_End_Term__c'];

// DMT_BulkImportBatch.parseDateValue: dd/mm/yyyy (three whole numbers) or yyyy-mm-dd in the first 10 characters
const isFileDate = text => (text.includes('/')
    ? text.split('/').length === 3 && text.split('/').every(part => /^\d+$/.test(part))
    : /^\d{4}-\d{1,2}-\d{1,2}$/.test(text.substring(0, 10)));
// DMT_BulkImportBatch.parseDecimal: Decimal.valueOf with every comma read as a decimal point
const isFileNumber = text => /^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/.test(text.replace(/,/g, '.'));
const FILE_FLAGS = ['true', '1', 'yes', 'false', '0', 'no'];

// The error putValue returns for a typed column ({ message, short }), null when the value saves; blank always saves
const fileValueError = (field, type, value) => {
    const text = valueText(value);
    if (text === '') return null;
    if (type === 'date' && !isFileDate(text)) {
        return { message: `${field}: invalid date ${text} (expected yyyy-mm-dd or dd/mm/yyyy).`,
                 short: `${field} ${text} is not a date (yyyy-mm-dd or dd/mm/yyyy)` };
    }
    if (type === 'number' && !isFileNumber(text)) {
        return { message: `${field}: invalid number ${text}.`, short: `${field} ${text} is not a number` };
    }
    if (type === 'boolean' && !FILE_FLAGS.includes(text.toLowerCase())) {
        return { message: `${field}: invalid checkbox value ${text} (expected TRUE or FALSE).`,
                 short: `${field} ${text} is not TRUE or FALSE` };
    }
    return null;
};

// The first typed column of a file row whose value does not save (columns in the row only; skip = columns not checked)
const firstValueError = (row, typeByField, skip) => {
    for (const field of Object.keys(typeByField || {})) {
        if (!(field in row) || (skip && skip(field))) continue;
        const error = fileValueError(field, typeByField[field], row[field]);
        if (error) return error;
    }
    return null;
};

// DMT_BulkImportBatch.checkTermDays: a term must be one of the picklist days (365.0 counts as 365)
const termDayError = (term, termDayValues) => {
    for (const field of TERM_DAY_FIELDS) {
        const text = valueText(term[field]);
        const values = (termDayValues || {})[field];
        if (text === '' || !values || values.includes(termDays(text))) continue;
        return { message: `${field}: invalid value ${text} (expected a number of days of the picklist, for example 0, 30, 365).`,
                 short: `${field} ${text} is not a number of days of the list (0, 30, 365...)` };
    }
    return null;
};

/**
 * Source: Apex DMT_BulkImportBatch.buildUnit, which rejects the whole row (line and products) at Process with the first
 * error it finds, in this order: the line columns (putValue: dates, numbers, checkboxes), the client (buildLine: a new line,
 * or a file with the Client_Code__c column, needs a code that is a customer or group code), then each Risk Line Term
 * (putValue, checkTermDays) and each Line Product Item (putValue). Returns that error as a reason, or null.
 * @param line { row, isNewLine, clientFound(code) } or null when the line itself is not saved (No Changes);
 *        rlt / lpi = the product rows the load sends for the line (null when not loaded); rules = getStatusContext
 *        fileValueRules ({ fieldTypes: { line, rlt, lpi }, termDays })
 */
export function rowSaveError(line, rlt, lpi, rules) {
    if (!rules || !rules.fieldTypes) return null;
    const asReason = (error, prefix, shortPrefix) => reason(`${prefix}${error.message}`, SAVE_SOURCE, `${shortPrefix}${error.short}`);
    if (line) {
        const keepWhenBlank = field => ['First_Breakclause__c', 'Breakclause_Frequency__c'].includes(field) && valueText(line.row[field]) === '';
        const error = firstValueError(line.row, rules.fieldTypes.line, keepWhenBlank);
        if (error) return asReason(error, '', '');
        if ('Client_Code__c' in line.row || line.isNewLine) {
            const code = valueText(line.row.Client_Code__c);
            if (code === '') {
                return reason('Client_Code__c is required: the line must be related to its client.', SAVE_SOURCE,
                              line.isNewLine ? 'a new line needs a Client_Code__c' : 'Client_Code__c is blank, the line needs its client');
            }
            if (!line.clientFound(code)) {
                return reason(`Client_Code__c ${code} was not found as a customer code or a group code.`, SAVE_SOURCE,
                              `client code ${code} was not found`);
            }
        }
    }
    for (const term of rlt || []) {
        const error = firstValueError(term, rules.fieldTypes.rlt) || termDayError(term, rules.termDays);
        if (error) return asReason(error, 'Risk Line Term: ', 'Risk Line Term ');
    }
    for (const item of lpi || []) {
        const error = firstValueError(item, rules.fieldTypes.lpi);
        if (error) return asReason(error, 'Line Product Item: ', 'Line Product Item ');
    }
    return null;
}
