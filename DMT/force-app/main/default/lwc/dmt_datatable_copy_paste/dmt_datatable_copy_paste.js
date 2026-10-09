import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserIdsByUsernames from '@salesforce/apex/DMT_DataTableCopyPasteController.getUserIdsByUsernames';

const termOptions = [{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"21Y",value:"7665"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];

const termLabelToValueMap = {};
const valueToLabelMap = {};
termOptions.forEach(opt => {
    termLabelToValueMap[opt.label.toUpperCase()] = opt.value;
    valueToLabelMap[opt.value] = opt.label;
});

const booleanFields = ['derivativesLine', 'lineFD', 'lineDVP'];
const termFields = ['maxTerm', 'initTerm', 'endTerm'];

export default class Dmt_datatable_copy_paste extends LightningElement {

    @api isReadOnlyUser = false;

    @api context;
    @api recordId;
    tabletype;
    @track originalFieldNames = [];
    @track fieldLabelMap = {};
    _copyHandler;
    _pasteHandler;
    @api
    set tableColumns(value) {

        this.originalFieldNames = value.map(c => c.fieldName);
        this.formatColumns = JSON.parse(JSON.stringify(value));

        this.fieldLabelMap = {};
        value.forEach(col => {
            this.fieldLabelMap[col.fieldName] = col.label || col.fieldName;
        });

        this.formatColumns.forEach(column => {
            if (column.hasOwnProperty('editable')) {
                column.isEditable = column.editable;
            } else {
                column.isEditable = false;
            }
            column.editable = false;

            if (termFields.includes(column.fieldName)) {
                column.fieldName = column.fieldName + 'Label';
            }
        });

    }

    connectedCallback() {
        console.log('DMT_DataTableCopyPaste: connectedCallback - isReadOnlyUser =', this.isReadOnlyUser);
    }

    get tableColumns() {
        this.formatColumns;
    }

    @api rows;
    @api titletable;
    backData;

    @track formatColumns = [];
    @track showModal;
    @track tempSaveRows;

    openModal() {
        console.log("openModal");
        this.showModal = true;
        this.activateOverrideCopy();
        this.activateOverridePaste();

        // CLEAN DATE DISPLAY ON LOAD
        // Ensure all dates are YYYY-MM-DD so they display correctly and sort correctly later
        let cleanRows = (this.rows || []).map(row => {
            const newRow = { ...row };
            if (newRow.gf_tenor_date__c && typeof newRow.gf_tenor_date__c === 'string' && newRow.gf_tenor_date__c.includes('T')) {
                newRow.gf_tenor_date__c = newRow.gf_tenor_date__c.split('T')[0];
            }
            return newRow;
        });

        this.tempSaveRows = cleanRows;

        // Show labels
        let rowsWithLabels = this.addTermLabelsToRows(cleanRows) ?? [];
        this.rows = this.cleanNonEditableBooleans(rowsWithLabels) ?? [];

        console.log('DMT_DataTableCopyPaste: openModal - rows prepared for modal:', JSON.stringify(this.rows));
    }

    getTableType() {
        const overrideContexts = ['derivatives', 'depos', 'equities', 'tenors'];
        const ctx = (this.context || '').toLowerCase();

        if (!overrideContexts.includes(ctx)) {
            return this.rows?.[0]?.tabletype || '';
        }

        if (this.tabletype) return this.tabletype;

        const contextToTableTypeMap = {
            derivatives: 'Derivatives',
            depos: 'Depos',
            equities: 'Equities',
            tenors: 'Tenors'
        };

        this.tabletype = contextToTableTypeMap[ctx] || '';
        return this.tabletype;
    }

    closeModal() {
        console.log("closeModal");

        this.showModal = false;
        this.desactivateOverridePaste();
        this.desactivateOverrideCopy();
        this.rows = this.tempSaveRows;
    }

    saveModal() {
        console.log("saveModal");

        this.sendRowsEvent();
    }

    onClickTextArea() {
        console.log("onClickTextArea");

        this.activateOverridePaste();
    }

    callRowAction(event) {
        console.log("callRowAction");

        const row = event.detail.row;
        this.deleteRow(row);
    }

    deleteRow(row) {
        let recordIndex = this.rows.findIndex((record) => record.Id === row.Id);
        this.rows.splice(recordIndex, 1);
        this.rows = [...this.rows];
    }

    activateOverridePaste() {
        console.log("activateOverridePaste");

        this._pasteHandler = (event) => this.handlePaste(event)
        document.addEventListener('paste', this._pasteHandler)
    }

    activateOverrideCopy() {
        console.log("activateOverrideCopy");

        this._copyHandler = (event) => this.handleCopy(event)
        document.addEventListener('copy', this._copyHandler)
    }

    desactivateOverridePaste() {
        console.log("desactivateOverridePaste");

        document.removeEventListener('paste', this._pasteHandler)
    }

    desactivateOverrideCopy() {
        console.log("desactivateOverrideCopy");

        document.removeEventListener('copy', this._copyHandler)
    }

    addTermLabelsToRows(rows) {
        if (rows !== undefined && rows !== null && rows.length > 0) {
            return rows.map(row => ({
                ...row,
                maxTermLabel: valueToLabelMap[row.maxTerm] || row.maxTerm,
                initTermLabel: valueToLabelMap[row.initTerm] || row.initTerm,
                endTermLabel: valueToLabelMap[row.endTerm] || row.endTerm
            }));
        }
    }

    isEditableField(field, row) {
        // Let last row (endTerm) to be editable
        const currentRowIndex = this.rows.findIndex(r => r.Id === row.Id);
        const isLastRow = currentRowIndex === this.rows.length - 1;

        // Operational Restrictions table
        if (field === 'lineFD') return row.FDEdit === true;
        if (field === 'lineDVP') return row.DVPEdit === true;
        if (field === 'derivativesLine') return row.derivativesEdit === true;
        if (field === 'maxTerm') return row.deriVisible !== 'slds-hidden';

        // Depos Risk Line and Equities Wrong Way Risk tables
        if (field === 'initTerm') return row.initRead !== true && row.initRead !== 'true';
        if (field === 'endTerm') {
            if (isLastRow) return true;
            return row.pickDisabled !== true;
        }
        if (field === 'amount') return true;

        //One-off transaction
        if (field === 'DMT_Singular_Operation__c') return true;
        if (field === 'maxDate') return true;
        if (field === 'active') return true;

        // Approvers Users
        if (field === 'userName') return true;
        if (field === 'AccessLevel') return true;

        // Other fields are not editable
        return false;
    }

    cleanNonEditableBooleans(rows) {
        if (rows !== undefined && rows !== null && rows.length > 0) {
            return rows.map(row => {
                const newRow = { ...row };
                booleanFields.forEach(field => {
                    const isEditable = this.isEditableField(field, row);

                    if (!isEditable) {
                        // If not editable show empty
                        newRow[field] = '';
                    } else {
                        // If it is editable and the value is empty it must be false
                        const val = newRow[field];
                        if (val === '' || val === undefined || val === null) {
                            newRow[field] = false;
                        }
                    }
                });
                return newRow;
            });
        }
    }

    getFieldLabel(fieldName) {
        return this.fieldLabelMap[fieldName] || fieldName;
    }

    processParsedData(parsedData, userIdMap, recordId, tabletype) {
        console.info('--- START PASTE PROCESSING ---');

        // 1. Setup Context & Limits
        const ctx = this.getPasteContext(tabletype);
        let processedRows = [];
        let processErrors = [];

        // 2. Logic Branch
        if (ctx.isBulletOrLinear) {
            // A. Bullet / Linear Mode (Generic)
            const res = this.processBulletMode(parsedData, userIdMap, ctx);
            processedRows = res.rows;
            processErrors = res.errors;
        } else {
            // B. User Defined Mode (Split by Table Type)
            if (ctx.isTenorsTable) {
                // Tenors: Smart Replace (Clear Middle, First Wins, Fallbacks)
                const res = this.processSmartReplaceLogic(parsedData, userIdMap, ctx);
                processedRows = res.rows;
                processErrors = res.errors;
            } else {
                // Others: Generic Merge (Map by Index 0->0, 1->1)
                const res = this.processGenericMergeLogic(parsedData, userIdMap, ctx);
                processedRows = res.rows;
                processErrors = res.errors;
            }
        }

        // 3. Final Validation & Cleanup (Zeroing & Reverting)
        const { finalRows, validationErrors } = this.validateAndCleanRows(processedRows, ctx, recordId, tabletype);

        // 4. Update UI
        this.handlePasteCompletion(finalRows, [...processErrors, ...validationErrors]);
    }

    // --- HELPER 1: CONTEXT & LIMITS ---
    getPasteContext(tabletype) {
        const currentRows = this.tempSaveRows || [];
        const rowAmortization = currentRows.length > 0 ? currentRows[0].amortizationType : null;
        const isBulletOrLinear = (rowAmortization && rowAmortization !== 'User-Defined');
        const isTenorsTable = (tabletype === 'Tenors'); // Strict Check

        let limitMin = null;
        let limitMax = null;
        const isValidDate = (d) => /^\d{4}-\d{2}-\d{2}$/.test(d);

        currentRows.forEach(row => {
            const d = row.gf_tenor_date__c;
            if (d && isValidDate(d)) {
                if (!limitMin || d < limitMin) limitMin = d;
                if (!limitMax || d > limitMax) limitMax = d;
            }
        });

        return { currentRows, limitMin, limitMax, isBulletOrLinear, isTenorsTable, isValidDate };
    }

    // --- HELPER 2: ROW PARSER (Extracts Object from CSV Array) ---
    parseRowValues(rawValues, rowIndex, userIdMap) {
        let rowObj = {};
        let hasError = false;
        let errorMsg = null;

        const isEmptyRow = rawValues.every(val => !val || val.toString().trim() === '');
        if (isEmptyRow) return null;

        rowObj.Id = `NEW_${Date.now()}_${Math.random().toString(36).slice(2,7)}`;

        for (let colIndex = 0; colIndex < this.originalFieldNames.length; colIndex++) {
            const field = this.originalFieldNames[colIndex];
            const rawValue = rawValues[colIndex];
            const valueStr = rawValue ? rawValue.toString().trim() : '';
            let parsedValue = valueStr;

            // Date Parsing
            if (field.toLowerCase().includes('date') || field === 'gf_tenor_date__c') {
                const isoDateRegex = /^(\d{4})[\/\-](\d{2})[\/\-](\d{2})$/;
                const slashDateRegex = /^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/;

                if (isoDateRegex.test(valueStr)) {
                    parsedValue = valueStr.replace(isoDateRegex, "$1-$2-$3");
                } else {
                    const m = valueStr.match(slashDateRegex);
                    if (m) {
                        let [, a, b, year] = m;
                        a = parseInt(a, 10);
                        b = parseInt(b, 10);
                        let month, day;

                        if (a > 12 && b <= 12) {
                            day = a; month = b;
                        } else if (b > 12 && a <= 12) {
                            month = a; day = b;
                        } else {
                            month = a; day = b;
                        }

                        parsedValue = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
                    }
                }

                // Only validate format here
                if (valueStr !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(parsedValue)) {
                    errorMsg = `Row ${rowIndex + 1}: Invalid Date "${rawValue}".`;
                    hasError = true;
                }
            }
            // Number Parsing
            else if (field.includes('amount') || field.includes('spread') || field.includes('fees')) {
                if (valueStr === '') {
                    parsedValue = 0;
                } else {
                    // Normalize Excel-formatted numbers (thousands separators, EU/US decimal)
                    let normalized = valueStr.replace(/[€$£¥\s]/g, '');
                    const commaCount = (normalized.match(/,/g) || []).length;
                    const dotCount   = (normalized.match(/\./g) || []).length;

                    if (commaCount > 0 && dotCount > 0) {
                        const lastComma = normalized.lastIndexOf(',');
                        const lastDot   = normalized.lastIndexOf('.');
                        if (lastComma > lastDot) {
                            // EU format: 1.000,50 → 1000.50
                            normalized = normalized.replace(/\./g, '').replace(',', '.');
                        } else {
                            // US format: 1,000.50 → 1000.50
                            normalized = normalized.replace(/,/g, '');
                        }
                    } else if (commaCount > 0) {
                        const afterComma = normalized.slice(normalized.lastIndexOf(',') + 1);
                        if (afterComma.length === 3 && /^\d{3}$/.test(afterComma)) {
                            // Thousands separator: 1,000 → 1000
                            normalized = normalized.replace(/,/g, '');
                        } else {
                            // Decimal separator: 1,5 → 1.5
                            normalized = normalized.replace(',', '.');
                        }
                    } else if (dotCount > 1) {
                        // Multiple dots → thousands separators: 1.000.000 → 1000000
                        normalized = normalized.replace(/\./g, '');
                    }

                    const parsed = parseFloat(normalized);
                    if (isNaN(parsed)) {
                        errorMsg = `Row ${rowIndex + 1}: Invalid Number "${rawValue}".`;
                        hasError = true;
                    } else {
                        parsedValue = parsed;
                    }
                }
            }
            // Boolean
            else if (booleanFields.includes(field)) {
                parsedValue = (valueStr.toUpperCase() === 'TRUE');
            }
            // User
            else if (field === 'userName' && userIdMap && userIdMap[valueStr]) {
                rowObj.userId = userIdMap[valueStr];
            }

            rowObj[field] = parsedValue;
        }

        return { rowObj, hasError, errorMsg };
    }

    // --- HELPER 3: BULLET MODE LOGIC (Strict: 1 Value Row + 1 Zero Row) ---
    processBulletMode(parsedData, userIdMap, ctx) {
        const { currentRows, limitMin, limitMax } = ctx;
        let rows = [];
        let errors = [];

        // 1. Extract ONLY the first valid row from paste
        let firstValidPastedRow = null;
        for (let i = 0; i < parsedData.length; i++) {
            const result = this.parseRowValues(parsedData[i], i, userIdMap);
            // If we find a valid row, capture it and STOP looking.
            if (result && result.rowObj && !result.hasError) {
                firstValidPastedRow = result.rowObj;
                break; // Ignore any subsequent rows in the paste
            }
        }

        if (firstValidPastedRow) {
            // --- A. CONSTRUCT START ROW ---
            // Use values from paste, but FORCE date to be Initial Date
            let startRow = { ...firstValidPastedRow };
            startRow.gf_tenor_date__c = limitMin;

            // Preserve ID from existing Start Row if available
            const existingStart = currentRows.find(r => r.gf_tenor_date__c === limitMin);
            if (existingStart && existingStart.Id) {
                startRow.Id = existingStart.Id;
            }
            rows.push(startRow);

            // --- B. CONSTRUCT MATURITY ROW ---
            if (limitMin !== limitMax) {
                // Maturity row is ALWAYS zeroed for Bullet/Linear
                let endRow = {
                    Id: `NEW_${Date.now()}_AUTO_END`,
                    gf_tenor_date__c: limitMax
                };

                // Preserve ID from existing Maturity Row
                const existingEnd = currentRows.find(r => r.gf_tenor_date__c === limitMax);
                if (existingEnd && existingEnd.Id) {
                    endRow.Id = existingEnd.Id;
                }

                // Force Zeroes
                ['gj_nominal_amount_db__c','gf_nominal_amount_fb__c','gf_spread_db__c','gf_spread_fb__c','gf_accrual_fees_bp__c','gf_non_accrual_fees_bp__c']
                    .forEach(f => endRow[f] = 0);

                rows.push(endRow);
            }
        } else {
            // Fallback: If paste contained no valid data, keep table as is
            rows = [...currentRows];
        }

        return { rows, errors };
    }

    // --- HELPER 4: USER DEFINED LOGIC (Smart Replace / First Wins / Fallback) ---
    processSmartReplaceLogic(parsedData, userIdMap, ctx) {
        const { currentRows, limitMin, limitMax, isValidDate } = ctx;
        let errors = [];

        let initRow = currentRows.find(r => r.gf_tenor_date__c === limitMin) || { Id: 'INIT_SAFE', gf_tenor_date__c: limitMin };
        let matRow = currentRows.find(r => r.gf_tenor_date__c === limitMax) || { Id: 'MAT_SAFE', gf_tenor_date__c: limitMax };
        initRow = { ...initRow };
        matRow = { ...matRow };

        let middleRowsMap = new Map();
        let pastedDatesSet = new Set();

        for (let i = 0; i < parsedData.length; i++) {
            const result = this.parseRowValues(parsedData[i], i, userIdMap);
            if (!result) continue; // Empty

            const { rowObj: newObj, hasError, errorMsg } = result;
            const pDate = newObj.gf_tenor_date__c;

            if(errorMsg) errors.push(errorMsg);

            if (!pDate || !isValidDate(pDate)) continue; // Invalid Date

            // Bounds Check
            if (pDate < limitMin) { errors.push(`Row ${i+1}: Date ${pDate} is before Initial Date.`); continue; }
            if (pDate > limitMax) { errors.push(`Row ${i+1}: Date ${pDate} is after Maturity Date.`); continue; }

            // Duplicate Check (First Wins)
            if (pastedDatesSet.has(pDate)) { errors.push(`Row ${i+1}: Duplicate date ${pDate} ignored.`); continue; }
            pastedDatesSet.add(pDate);

            // Error Fallback (Revert to Original if parse error)
            let objectToUse = newObj;
            if (hasError) {
                const original = currentRows.find(r => r.gf_tenor_date__c === pDate);
                if (original) objectToUse = { ...original };
                else continue; // Skip bad new row
            }

            // Distribute
            if (pDate === limitMin) {
                const safeId = initRow.Id;
                Object.assign(initRow, objectToUse);
                initRow.Id = safeId;
                initRow.gf_tenor_date__c = limitMin;
            } else if (pDate === limitMax) {
                const safeId = matRow.Id;
                Object.assign(matRow, objectToUse);
                matRow.Id = safeId;
                matRow.gf_tenor_date__c = limitMax;
            } else {
                middleRowsMap.set(pDate, objectToUse);
            }
        }

        let sortedMiddle = Array.from(middleRowsMap.values()).sort((a, b) => a.gf_tenor_date__c.localeCompare(b.gf_tenor_date__c));
        let rows = [initRow, ...sortedMiddle];
        if (limitMin !== limitMax) rows.push(matRow);

        return { rows, errors };
    }

    // --- HELPER 5: GENERIC MERGE LOGIC (Other Tables) ---
    processGenericMergeLogic(parsedData, userIdMap, ctx) {
        const { currentRows } = ctx;
        let rows = [];
        let errors = [];

        // Map strictly by parsedData index (1-to-1)
        parsedData.forEach((rowValues, i) => {
            const result = this.parseRowValues(rowValues, i, userIdMap);
            if (!result) return; // Skip empty rows

            const { rowObj: newObj, hasError, errorMsg } = result;
            if(errorMsg) errors.push(errorMsg);

            const existingRow = currentRows[i];
            let mergedRow;

            if (existingRow) {
                // CASE A: UPDATE EXISTING ROW
                // We start with the existing row to keep ALL its hidden fields/IDs
                mergedRow = { ...existingRow };

                if (!hasError) {
                    // Overwrite only the parsed fields onto the existing row
                    // CRITICAL: We DO NOT overwrite the Id.
                    const originalId = existingRow.Id;
                    Object.assign(mergedRow, newObj);
                    mergedRow.Id = originalId;
                }
            } else {
                // CASE B: APPEND NEW ROW
                if (!hasError) {
                    // newObj already has a 'NEW_...' Id from parseRowValues
                    mergedRow = newObj;
                }
            }

            if (mergedRow) rows.push(mergedRow);
        });

        return { rows, errors };
    }

    // --- HELPER 6: FINAL VALIDATION & CLEANUP ---
    validateAndCleanRows(rows, ctx, recordId, tabletype) {
        let finalRows = [];
        let validationErrors = [];
        const { limitMax, limitMin, isTenorsTable, isBulletOrLinear, currentRows } = ctx;

        rows.forEach((row, i) => {
            // [FIX] ID SAFETY NET
            // 1. Try to get the ID from the function arguments (recordId) or class state (this.recordId)
            // 2. Fallback to the row's existing 'line' or 'lineId' property
            const finalLineId = recordId || this.recordId || row.line || row.lineId || '';

            // [FIX] SYNC BOTH FIELDS
            // This satisfies the "Required Field Missing: DMT_Line__c" error
            row.line = finalLineId;
            row.lineId = finalLineId;

            row.tabletype = tabletype;
            if (!row.recordId && this.rows[0]?.recordId) row.recordId = this.rows[0].recordId;

            // --- BRANCH A: TENORS RULES (STRICT) ---
            if (isTenorsTable) {
                // 1. Maturity Zero Rule
                if (row.gf_tenor_date__c === limitMax && limitMin !== limitMax) {
                    ['gj_nominal_amount_db__c','gf_nominal_amount_fb__c','gf_spread_db__c','gf_spread_fb__c','gf_accrual_fees_bp__c','gf_non_accrual_fees_bp__c']
                        .forEach(f => row[f] = 0);
                    finalRows.push(row);
                    return;
                }

                // 2. Amount > 0 Check (Only for User-Defined + Tenors)
                if (!isBulletOrLinear) {
                    const valDrawn = Number(row['gj_nominal_amount_db__c']) || 0;
                    const valUndrawn = Number(row['gf_nominal_amount_fb__c']) || 0;

                    if (valDrawn <= 0 && valUndrawn <= 0) {
                        validationErrors.push(`Date ${row.gf_tenor_date__c}: At least one Amount must be > 0.`);

                        // Revert to original
                        const original = currentRows.find(r => r.gf_tenor_date__c === row.gf_tenor_date__c);
                        if (original) {
                            let reverted = { ...original };
                            // Ensure the reverted row also gets the ID fix
                            reverted.line = finalLineId;
                            reverted.lineId = finalLineId;
                            reverted.tabletype = row.tabletype;
                            if(row.recordId) reverted.recordId = row.recordId;
                            finalRows.push(reverted);
                        }
                        return;
                    }
                }
            }

            // --- BRANCH B: GENERIC (Derivatives, etc.) ---
            // Just push the row with the fixed ID
            finalRows.push(row);
        });

        return { finalRows, validationErrors };
    }

    // --- HELPER 7: COMPLETION UI ---
    handlePasteCompletion(rows, errors) {
        if (errors.length > 0) {
            console.warn('Paste Validation Failed:', errors);
            const MAX_ERRORS_SHOWN = 5;
            let uniqueErrors = [...new Set(errors)];
            let msg = uniqueErrors.slice(0, MAX_ERRORS_SHOWN).join('\n');
            if (uniqueErrors.length > MAX_ERRORS_SHOWN) msg += `\n...and ${uniqueErrors.length - MAX_ERRORS_SHOWN} more.`;
            this.showErrorToast(msg, 'sticky');
        }

        console.log(`Processing Completed. Result: ${rows.length} rows.`);
        const rowsWithLabels = this.addTermLabelsToRows(rows);
        this.rows = this.cleanNonEditableBooleans(rowsWithLabels);

        console.log('Final Rows Set to DataTable:', JSON.stringify(this.rows));

        this.triggerCopyPasteAnimation();
    }

    triggerCopyPasteAnimation() {
        // This gives LWC time to render 'this.rows' into the DOM before we try to animate it.
        setTimeout(() => {
            const container = this.template.querySelector('.datatable-container');
            if (container) {
                // Reset animation
                container.classList.remove('paste-flash-animation');

                // Force Browser Reflow (The magic restart switch)
                void container.offsetWidth;

                // Start animation
                container.classList.add('paste-flash-animation');
            }
        }, 50); // 50ms delay is enough
    }

    handlePaste(event) {
        console.log("handlePaste", this.recordId);
        const pastedText = event.clipboardData.getData('text/plain');
        const parsedData = this.csvStringToArray(pastedText);

        // [FIX] Look for 'lineId' as well, since 'line' might be missing
        const recordId = this.rows?.[0]?.line || this.rows?.[0]?.lineId || this.recordId || '';
        const tabletype = this.getTableType();

        const usernameColIndex = this.originalFieldNames.findIndex(f => f.trim() === 'userName');
        const hasUserName = usernameColIndex !== -1;

        if (hasUserName) {
            const userNameList = parsedData.map(row => row[usernameColIndex]?.trim()).filter(Boolean);
            const uniqueUsernames = [...new Set(userNameList)];

            getUserIdsByUsernames({ userNames: uniqueUsernames })
                .then(result => {
                    const unresolved = uniqueUsernames.filter(name => !result[name]);
                    if (unresolved.length > 0) {
                        this.showErrorToast(`No users found for: ${unresolved.join(', ')}`);
                        return;
                    }
                    this.processParsedData(parsedData, result, recordId, tabletype);
                })
                .catch(error => {
                    console.error('Error fetching user IDs from Apex:', error);
                    console.warn('Error validating userName values with Salesforce.');
                });
            event.preventDefault();
        } else {
            this.processParsedData(parsedData, {}, recordId, tabletype);
            event.preventDefault();
        }
    }

    handleCopy(event) {
        console.log("handleCopy", this.titletable);
        console.log("event " + JSON.stringify(event));
        this.triggerCopyPasteAnimation();
        var copyText = '';
        var rowsAux = JSON.parse(JSON.stringify(this.rows));

        rowsAux.forEach(row => {
            const copiedRow = this.originalFieldNames.map(field => {
                const alwaysCopiedFields = ['products', 'initTerm', 'endTerm'];

                const colDef = this.formatColumns.find(c => c.fieldName === field);
                const editableFromColumn = colDef ? colDef.isEditable : false; // Safe access

                // Original logic: Check if field should be included in copy
                const isEditable = editableFromColumn || this.isEditableField(field, row) || alwaysCopiedFields.includes(field);

                let value = row[field];

                if (isEditable) {
                    // 1. Handle Booleans
                    if (booleanFields.includes(field)) {
                        if (value === true) return 'TRUE';
                        return 'FALSE';
                    }

                    // 2. Handle AccessLevel defaults
                    if (field === 'AccessLevel' && value === '') {
                        return 'Read';
                    }

                    // 3. Handle Term Fields (Value -> Label)
                    if (termFields.includes(field)) {
                        const label = valueToLabelMap[value];
                        return label || '';
                    }

                    // 4. Handle Dates (Normalize ISO DateTime to YYYY-MM-DD) CIBGLOBALD-2252
                    // If the value is a full ISO string (e.g. 2026-10-29T00:00:00.000Z), clean it.
                    if ((field.toLowerCase().includes('date') || field === 'gf_tenor_date__c') && typeof value === 'string') {
                        // Check if it looks like an ISO DateTime
                        if (value.includes('T')) {
                            // Slice to get just '2026-10-29'
                            return value.split('T')[0];
                        }
                    }

                    // 5. Default String handling
                    if (value === undefined || value === null) return '';

                    return String(value).trim();
                } else {
                    return '';
                }
            });

            copyText += copiedRow.join('\t') + '\n';
        });

        event.clipboardData.setData("text/plain", copyText);
        event.preventDefault();
    }

    showErrorToast(message, mode = 'dismissible') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
                mode: mode // 'sticky', 'pester', or 'dismissible'
            })
        );
    }

    sendRowsEvent() {
        let cleanedRows = this.rows.map((row, i) => {
            const newRow = { ...row };
            // If boolean fields !== true, set to false internally
            booleanFields.forEach(field => {
                const val = newRow[field];
                if (val !== true) {
                    newRow[field] = false;
                }
            });

            // If term fields empty, set to '' internally
            termFields.forEach(field => {
                if (!(field in newRow)) {
                    newRow[field] = '';
                }
            });

            // Delete fields that were empty before
            Object.keys(newRow).forEach(key => {
                // Never delete these fields
                if (['line'].includes(key)) return;

                const originalValue = this.tempSaveRows?.[i]?.[key];
                const isEmptyNow = newRow[key] === '' || newRow[key] === undefined;
                const wasEmptyBefore = originalValue === '' || originalValue === undefined;
                if (isEmptyNow && wasEmptyBefore) {
                    delete newRow[key];
                }
            });

            // Restore values from label
            termFields.forEach(field => {
                const labelField = field + 'Label';
                if (!newRow[field] && newRow[labelField]) {
                    const label = newRow[labelField].toUpperCase();
                    newRow[field] = termLabelToValueMap[label] || '';
                }
            });

            // Remove labels before sending
            termFields.forEach(field => {
                const labelField = field + 'Label';
                delete newRow[labelField];
            });

            return newRow;
        });

        cleanedRows = cleanedRows.map(row => ({
            ...row,
            tabletype: row.tabletype || this.getTableType()
        }));

        const selectedEvent = new CustomEvent("sendrowsevent", {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: { data: cleanedRows, context: this.context }
        });

        console.log('cleanedRows --> ' + JSON.stringify(cleanedRows));
        this.dispatchEvent(selectedEvent);
        this.tempSaveRows = this.rows;
        this.closeModal();
    }

    csvStringToArray(str) {
        var arr = [];
        var quote = false;
        for (var row = 0, col = 0, c = 0; c < str.length; c++) {
            var cc = str[c], nc = str[c + 1];
            arr[row] = arr[row] || [];
            arr[row][col] = arr[row][col] || '';
            if (cc == '"' && quote && nc == '"') { arr[row][col] += cc; ++c; continue; }
            if (cc == '"') { quote = !quote; continue; }
            if (cc == '\t' && !quote) { ++col; continue; }
            if (cc == '\r' && nc == '\n' && !quote) { ++row; col = 0; ++c; continue; }
            if (cc == '\n' && !quote) { ++row; col = 0; continue; }
            if (cc == '\r' && !quote) { ++row; col = 0; continue; }
            arr[row][col] += cc;
        }
        return arr;
    }
}