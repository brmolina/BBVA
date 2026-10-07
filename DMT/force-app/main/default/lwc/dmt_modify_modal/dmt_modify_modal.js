import { api, track } from "lwc";
import LightningModal from "lightning/modal";
import getModifyPayload from "@salesforce/apex/DMT_LinesBulkActionController.getModifyPayload";
import saveModifiedLines from "@salesforce/apex/DMT_LinesBulkActionController.saveModifiedLines";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const TREASURY_TEMPLATE_TYPE = "TL";
const DMT_LINE_OBJECT = "DMT_Line__c";
const RISK_LINE_TERM_OBJECT = "DMT_Risk_Line_Term__c";
const UNKNOWN_TEMPLATE_TYPE = "UNSPECIFIED";
const MERGED_AMOUNT_COLUMN_KEY = "MERGED::Amount";
const DERIVATIVES_AMOUNT_COLUMN_KEY = "DERIVATIVES::Amount";
const TREASURY_END_TERM_COLUMN_KEY = "TREASURY::EndTerm";
const AMOUNT_MERGE_TEMPLATE = "OL";
const LINE_AMOUNT_FIELD = "Amount__c";
const RISK_AMOUNT_FIELD = "DMT_Amount__c";
const DERIVATIVES_AMOUNT_FIELD = "DMT_DerivativesAmount__c";

export default class DmtModifyLinesModal extends LightningModal {
  @api lineIds = [];

  @track rows = [];
  @track bulkInputsByTable = {};
  activeBulkEditorKey;

  isLoading = false;
  loadingMessage = "Loading selected lines...";

  async connectedCallback() {
    await this.loadData();
    await loadStyle(this, DMT_Styles);
  }

  get hasRows() {
    return Array.isArray(this.rows) && this.rows.length > 0;
  }

  get tableGroups() {
    const groupsByTemplate = {};

    (this.rows || []).forEach((row) => {
      const templateType = row.templateType || UNKNOWN_TEMPLATE_TYPE;

      if (!groupsByTemplate[templateType]) {
        groupsByTemplate[templateType] = {
          key: templateType,
          templateType,
          columnsByKey: {},
          columnOrder: [],
          lineEntries: [],
          riskRowCount: 0
        };
      }

      const group = groupsByTemplate[templateType];

      (row.cells || []).forEach((cell) => {
        this.registerColumn(
          group,
          cell,
          DMT_LINE_OBJECT
        );
      });

      const riskSection = this.getRiskTermSection(row);
      const riskRecords = riskSection?.records || [];

      // For both TL and non-TL templates, register risk term columns
      riskRecords.forEach((record) => {
        (record.cells || []).forEach((cell) => {
          if (
            templateType === TREASURY_TEMPLATE_TYPE &&
            cell.fieldApiName === RISK_AMOUNT_FIELD
          ) {
            return;
          }

          this.registerColumn(
            group,
            cell,
            RISK_LINE_TERM_OBJECT
          );
        });
      });

      // Register Derivatives Amount column for Treasury Lines
      if (templateType === TREASURY_TEMPLATE_TYPE && row.derivativesAmount !== undefined) {
        this.registerDerivativesAmountColumn(group);
      }

      // Update risk row count for both TL and non-TL templates
      group.riskRowCount += riskRecords.length;
      group.lineEntries.push({ row, riskSection, riskRecords });
    });

    return Object.values(groupsByTemplate).map((group) => {
      const columns = group.columnOrder.map(
        (columnKey) => group.columnsByKey[columnKey]
      );

      const tableRows = [];

      group.lineEntries.forEach((entry) => {
        const isTreasuryTemplate = group.templateType === TREASURY_TEMPLATE_TYPE;
        const riskRecords = entry.riskRecords || [];
        const groupSize = isTreasuryTemplate
          ? 1 + riskRecords.length
          : 1 + riskRecords.length;

        tableRows.push(
          this.buildTableRow({
            rowKey: `${entry.row.id}-line`,
            rowType: "line",
            rowLabel: "-",
            lineRowData: entry.row,
            riskRecordData: null,
            sectionKey: null,
            showGroupCells: true,
            groupSize,
            columns
          })
        );

        // Show risk records for both TL (Treasury) and non-TL templates
        riskRecords.forEach((riskRecord, index) => {
          const isLastRiskRecord = index === riskRecords.length - 1;
          tableRows.push(
            this.buildTableRow({
              rowKey: `${entry.row.id}-risk-${riskRecord.id}`,
              rowType: "risk",
              rowLabel: this.resolveRiskLineTermName(riskRecord, index),
              lineRowData: entry.row,
              riskRecordData: riskRecord,
              sectionKey: entry.riskSection?.key,
              showGroupCells: false,
              groupSize: 0,
              columns,
              isEditableRiskRecord: isTreasuryTemplate && isLastRiskRecord,
              isReadonlyRiskRecord: isTreasuryTemplate && !isLastRiskRecord
            })
          );
        });
      });

      const columnsWithBulk = columns.map((column) => {
        const storedBulkValue =
          this.bulkInputsByTable?.[group.templateType]?.[column.key]?.value;

        const canBulkApply = column.isTreasuryEndTerm
          ? group.lineEntries.some((entry) =>
              this.hasEditableTreasuryEndTerm(entry.row)
            )
          : column.isMergedAmount
          ? group.lineEntries.length > 0 || group.riskRowCount > 0
          : column.isDerivativesAmount
            ? group.lineEntries.some((entry) =>
                this.hasEditableDerivativesAmount(entry.row)
              )
            : column.sourceObjectApiName === DMT_LINE_OBJECT
              ? group.lineEntries.length > 0
              : group.riskRowCount > 0;

        return {
          ...column,
          canBulkApply,
          bulkValue: storedBulkValue ?? "",
          bulkChecked: Boolean(storedBulkValue),
          isBulkEditorOpen:
            this.activeBulkEditorKey ===
            this.buildBulkEditorKey(group.templateType, column.key)
        };
      });

      return {
        key: group.key,
        templateType: group.templateType,
        title: this.getTemplateTitle(group.templateType),
        columns: columnsWithBulk,
        tableRows,
        rowCount: tableRows.length,
        lineCount: group.lineEntries.length,
        hasRiskRows: group.riskRowCount > 0
      };
    });
  }

  buildBulkEditorKey(tableKey, columnKey) {
    return `${tableKey}::${columnKey}`;
  }

  getTemplateTitle(templateType) {
    if (templateType === TREASURY_TEMPLATE_TYPE) {
      return "Treasury Line";
    }

    if (templateType === "OL") {
      return "Line (Other products)";
    }

    return `${templateType}`;
  }

  resolveRiskLineTermName(riskRecord, index) {
    if (!riskRecord) {
      return `Product ${index + 1}`;
    }

    const fromRecord = riskRecord.Name || riskRecord.name;

    if (fromRecord) {
      return String(fromRecord);
    }

    const fromValues = riskRecord.values?.Name || riskRecord.values?.name;

    if (fromValues) {
      return String(fromValues);
    }

    if (riskRecord.displayName) {
      return String(riskRecord.displayName);
    }

    return `Product ${index + 1}`;
  }

  get hasTableGroups() {
    return this.tableGroups.length > 0;
  }

  async loadData() {
    try {
      this.isLoading = true;
      this.loadingMessage = "Loading selected lines...";

      const payload = await getModifyPayload({
        lineIds: this.lineIds
      });

      this.rows = (payload?.rows || []).map((row) => this.normalizeRow(row));
    } catch (error) {
      this.showToast(
        "Error",
        error?.body?.message || error?.message || "Unknown error",
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  normalizeRow(row) {
    const cells = (row.cells || []).map((cell) => ({
      ...cell,
      value: cell.value ?? "",
      checked: cell.checked ?? false,
      options: cell.options || [],
      isPicklist: cell.isPicklist === true
    }));

    const isTreasuryLine = row.templateType === TREASURY_TEMPLATE_TYPE;

    const relatedSections = (row.relatedSections || []).map((section) => {
      const records = (section.records || []).map((record, index) => {
        const riskCells = (record.cells || []).map((cell) => ({
          ...cell,
          value: cell.value ?? "",
          checked: cell.checked ?? false,
          options: cell.options || [],
          isPicklist: cell.isPicklist === true
        }));
        const riskInitialValues = { ...(record.values || {}) };
        riskCells.forEach((cell) => {
          if (
            cell.fieldApiName &&
            !Object.prototype.hasOwnProperty.call(
              riskInitialValues,
              cell.fieldApiName
            )
          ) {
            riskInitialValues[cell.fieldApiName] = cell.value ?? "";
          }
        });
        return {
          ...record,
          rowNumber: index + 1,
          values: { ...(record.values || {}) },
          initialValues: riskInitialValues,
          cells: riskCells
        };
      });

      const isRiskTermSection =
        section.objectApiName === RISK_LINE_TERM_OBJECT;

      const columns =
        records.length > 0
          ? (records[0].cells || []).map((cell) => ({
              key: `${section.key}-${cell.fieldApiName}`,
              fieldApiName: cell.fieldApiName,
              label: cell.label
            }))
          : [];

      return {
        ...section,
        records,
        columns,
        hasRecords: records.length > 0,
        isRiskTermSection,
        isTreasuryRiskTable: isTreasuryLine && isRiskTermSection,
        compactTitle: section.label
      };
    });

const lineInitialValues = { ...(row.values || {}) };
  cells.forEach((cell) => {
    if (
      cell.fieldApiName &&
      !Object.prototype.hasOwnProperty.call(lineInitialValues, cell.fieldApiName)
    ) {
      lineInitialValues[cell.fieldApiName] = cell.value ?? "";
    }
  });

return {
  ...row,
  lineName: row.lineName || row.lineId,
  lineUrl: row.lineUrl || `/${row.id}`,
  derivativesAmount: row.derivativesAmount ?? null,
  initialDerivativesAmount: row.derivativesAmount ?? null,
  endTerm: row.endTerm ?? "",
  initialEndTerm: row.endTerm ?? "",
  // For TL, endTermRiskTermId should point to the last risk record (Derivatives type)
  endTermRiskTermId: this.getLastRiskTermIdForTL(row, relatedSections) || row.endTermRiskTermId || null,
  derivativesAmountDisplay: this.formatAmount(row.derivativesAmount),
  derivativesCurrencyIsoCode: row.currencyIsoCode || "",
  values: { ...(row.values || {}) },
  initialValues: lineInitialValues,
  cells,
  hasLineCells: cells.length > 0,
  isTreasuryLine,
  relatedSections,
  clientType: row.clientType || "",
  clientName: row.clientCode || null,
  clientAccountUrl: row.clientAccountId ? `/${row.clientAccountId}` : null,
  isCustomClient: row.isCustom === true,
  customClientNames: row.customClientIds || [],
  customClientNamesTooltip: (row.customClientIds || []).join(", ")
    };
  }

  registerColumn(group, cell, sourceObjectApiName) {
    if (!cell?.fieldApiName) {
      return;
    }

    if (group.templateType === AMOUNT_MERGE_TEMPLATE) {
      const isLineAmount =
        sourceObjectApiName === DMT_LINE_OBJECT &&
        cell.fieldApiName === LINE_AMOUNT_FIELD;
      const isRiskAmount =
        sourceObjectApiName === RISK_LINE_TERM_OBJECT &&
        cell.fieldApiName === RISK_AMOUNT_FIELD;

      if (isLineAmount || isRiskAmount) {
        if (!group.columnsByKey[MERGED_AMOUNT_COLUMN_KEY]) {
          group.columnsByKey[MERGED_AMOUNT_COLUMN_KEY] = {
            key: MERGED_AMOUNT_COLUMN_KEY,
            fieldApiName: MERGED_AMOUNT_COLUMN_KEY,
            label: cell.label || "Amount",
            inputType: "number",
            isPicklist: false,
            isCheckbox: false,
            options: [],
            required: cell.required === true,
            sourceObjectApiName: null,
            isMergedAmount: true,
            lineFieldApiName: LINE_AMOUNT_FIELD,
            riskFieldApiName: RISK_AMOUNT_FIELD,
            helpText:
              "Editable in applicable rows and only when applicable by geography."
          };
          group.columnOrder.push(MERGED_AMOUNT_COLUMN_KEY);
        }
        return;
      }
    }

    const columnKey = `${sourceObjectApiName}::${cell.fieldApiName}`;
    const isTreasuryEndTerm =
      sourceObjectApiName === RISK_LINE_TERM_OBJECT &&
      cell.fieldApiName === "DMT_End_Term__c";

    if (!group.columnsByKey[columnKey]) {
      group.columnsByKey[columnKey] = {
        key: columnKey,
        fieldApiName: cell.fieldApiName,
        label: cell.label,
        inputType: cell.inputType || "text",
        isPicklist: cell.isPicklist === true,
        isCheckbox: cell.inputType === "checkbox",
        options: cell.options || [],
        required: cell.required === true,
        sourceObjectApiName,
        isTreasuryEndTerm,
        helpText:
          sourceObjectApiName === DMT_LINE_OBJECT
            ? "Editable only in the main line row and only when applicable by geography."
            : "Editable in product rows and only when applicable by geography."
      };

      group.columnOrder.push(columnKey);
    }
  }

  registerDerivativesAmountColumn(group) {
    if (group.columnsByKey[DERIVATIVES_AMOUNT_COLUMN_KEY]) {
      return;
    }

    group.columnsByKey[DERIVATIVES_AMOUNT_COLUMN_KEY] = {
      key: DERIVATIVES_AMOUNT_COLUMN_KEY,
      fieldApiName: DERIVATIVES_AMOUNT_FIELD,
      label: "Derivatives Amount",
      inputType: "number",
      isPicklist: false,
      isCheckbox: false,
      options: [],
      required: false,
      sourceObjectApiName: DMT_LINE_OBJECT,
      isDerivativesAmount: true,
      helpText: "Editable only in the main line row. Updates the maximum DMT_Risk_Line_Term__c record."
    };

    group.columnOrder.push(DERIVATIVES_AMOUNT_COLUMN_KEY);
  }

  registerTreasuryEndTermColumn(group, row) {
    const options = this.getTreasuryEndTermOptions(row);

    if (!group.columnsByKey[TREASURY_END_TERM_COLUMN_KEY]) {
      group.columnsByKey[TREASURY_END_TERM_COLUMN_KEY] = {
        key: TREASURY_END_TERM_COLUMN_KEY,
        fieldApiName: "DMT_End_Term__c",
        label: "End Term",
        inputType: "picklist",
        isPicklist: true,
        isCheckbox: false,
        options,
        required: false,
        sourceObjectApiName: RISK_LINE_TERM_OBJECT,
        isTreasuryEndTerm: true,
        helpText: "Editable only on the selected Treasury risk term."
      };

      group.columnOrder.push(TREASURY_END_TERM_COLUMN_KEY);
      return;
    }

    if (
      group.columnsByKey[TREASURY_END_TERM_COLUMN_KEY].options.length === 0 &&
      options.length > 0
    ) {
      group.columnsByKey[TREASURY_END_TERM_COLUMN_KEY].options = options;
    }
  }

  getRiskTermSection(row) {
    return (row.relatedSections || []).find(
      (section) => section.objectApiName === RISK_LINE_TERM_OBJECT
    );
  }

  getLastRiskTermIdForTL(row, relatedSections) {
    // For Treasury Lines, find the last Derivatives risk term
    if (row.templateType !== TREASURY_TEMPLATE_TYPE) {
      return null;
    }

    const riskSection = (relatedSections || []).find(
      (section) => section.objectApiName === RISK_LINE_TERM_OBJECT
    );

    if (!riskSection || !riskSection.records || riskSection.records.length === 0) {
      return null;
    }

    // Return the ID of the last risk record
    return riskSection.records[riskSection.records.length - 1].id;
  }

  getTreasuryEndTermOptions(row) {
    const riskSection = this.getRiskTermSection(row);
    const selectedRecord = (riskSection?.records || []).find(
      (record) => String(record.id) === String(row.endTermRiskTermId)
    );
    const endTermCell = (selectedRecord?.cells || []).find(
      (cell) => cell.fieldApiName === "DMT_End_Term__c"
    );

    return endTermCell?.options || [];
  }

  hasEditableDerivativesAmount(row) {
    return Boolean(row?.endTermRiskTermId) &&
      row.derivativesAmount !== null &&
      row.derivativesAmount !== undefined &&
      row.derivativesAmount !== "";
  }

  hasEditableTreasuryEndTerm(row) {
    return Boolean(row?.endTermRiskTermId) &&
      row.endTerm !== null &&
      row.endTerm !== undefined &&
      row.endTerm !== "";
  }

  buildTableRow(config) {
    const {
      rowKey,
      rowType,
      rowLabel,
      lineRowData,
      riskRecordData,
      sectionKey,
      showGroupCells,
      groupSize,
      columns,
      isEditableRiskRecord,
      isReadonlyRiskRecord
    } = config;

    return {
      key: rowKey,
      rowType,
      rowLabel,
      lineRecordId: lineRowData.id,
      lineId: lineRowData.lineId,
      lineName: lineRowData.lineName,
      lineUrl: lineRowData.lineUrl,
      clientName: lineRowData.clientName,
      clientAccountUrl: lineRowData.clientAccountUrl,
      isCustomClient: lineRowData.isCustomClient,
      customClientNames: lineRowData.customClientNames,
      customClientNamesTooltip: lineRowData.customClientNamesTooltip,
      recordId: riskRecordData?.id,
      sectionKey,
      showGroupCells,
      groupSize,
      cells: columns.map((column) =>
        this.buildRenderedCell({
          rowType,
          lineRowData,
          riskRecordData,
          column,
          isEditableRiskRecord,
          isReadonlyRiskRecord
        })
      )
    };
  }

  buildRenderedCell(config) {
    const { rowType, lineRowData, riskRecordData, column, isReadonlyRiskRecord } = config;

    const currencyCode = lineRowData?.currencyIsoCode || "";

    // --- Merged Amount column (OL template: Amount__c + DMT_Amount__c share one column) ---
    if (column.isMergedAmount) {
      const isLine = rowType === "line";
      const effectiveField = isLine
        ? column.lineFieldApiName
        : column.riskFieldApiName;
      const effectiveObject = isLine ? DMT_LINE_OBJECT : RISK_LINE_TERM_OBJECT;
      const dataSource = isLine ? lineRowData : riskRecordData;

      const fieldApplies = this.hasFieldInCells(
        dataSource?.cells,
        effectiveField
      );

      let mergedValue = "";
      let mergedInitialValue;
      let mergedEditable = false;
      let mergedApplies = false;

      if (dataSource && fieldApplies) {
        mergedValue =
          this.getValueForField(
            dataSource.values,
            dataSource.cells,
            effectiveField
          ) ?? "";
        mergedInitialValue = this.getValueForField(
          dataSource.initialValues,
          dataSource.cells,
          effectiveField
        );
        mergedEditable = !isReadonlyRiskRecord;
        mergedApplies = true;
      }

      const mergedNormalized = mergedValue ?? "";
      const mergedIsChanged =
        mergedApplies &&
        this.areValuesDifferent(mergedNormalized, mergedInitialValue, "number");
      const baseDisplay = this.formatCellDisplayValue(
        mergedNormalized,
        column
      );
      const displayValue =
        mergedApplies && currencyCode && baseDisplay !== "-"
          ? `${baseDisplay} ${currencyCode}`
          : baseDisplay;

      return {
        key: `${lineRowData.id}-${riskRecordData?.id || "line"}-${column.key}`,
        columnKey: column.key,
        fieldApiName: effectiveField,
        label: column.label,
        sourceObjectApiName: effectiveObject,
        inputType: "number",
        isPicklist: false,
        isCheckbox: false,
        options: [],
        required: column.required,
        editable: mergedEditable,
        disabled: !mergedEditable,
        appliesToCurrentRow: mergedApplies,
        value: mergedNormalized,
        checked: false,
        isChanged: mergedIsChanged,
        cellClass: mergedIsChanged ? "changed-cell" : "",
        displayValue,
        isAmountCell: true,
        currencyCode
      };
    }
    // --- End merged amount ---

    if (column.isTreasuryEndTerm) {
      // For TL, EndTerm is now shown as a risk record cell
      // Only editable if this is a risk row AND it's the last risk record
      const endTermValue = riskRecordData?.values?.DMT_End_Term__c ?? "";
      const endTermEditable =
        rowType === "risk" &&
        !isReadonlyRiskRecord &&
        this.hasEditableTreasuryEndTerm(lineRowData);
      const initialValue = riskRecordData?.initialValues?.DMT_End_Term__c ?? "";
      const isChanged = this.areValuesDifferent(
        endTermValue,
        initialValue,
        "picklist"
      );

      return {
        key: `${lineRowData.id}-${riskRecordData?.id || "line"}-${column.key}`,
        columnKey: column.key,
        fieldApiName: "DMT_End_Term__c",
        label: column.label,
        sourceObjectApiName: RISK_LINE_TERM_OBJECT,
        inputType: "picklist",
        isPicklist: true,
        isCheckbox: false,
        options: column.options || [],
        required: false,
        editable: endTermEditable,
        disabled: !endTermEditable,
        appliesToCurrentRow: endTermEditable,
        value: endTermValue,
        checked: false,
        isChanged,
        cellClass: endTermEditable && isChanged ? "changed-cell" : "",
        displayValue: this.formatCellDisplayValue(endTermValue, column),
        isTreasuryEndTerm: true,
        isAmountCell: false,
        currencyCode: ""
      };
    }

    // --- Derivatives Amount column (TL template: editable on the last risk row) ---
    if (column.isDerivativesAmount) {
      const isRiskRow = rowType === "risk";
      const derivativesValue =
        isRiskRow && !isReadonlyRiskRecord
          ? lineRowData?.derivativesAmount ?? ""
          : isRiskRow
          ? this.getValueForField(
              riskRecordData?.values,
              riskRecordData?.cells,
              RISK_AMOUNT_FIELD
            ) ?? ""
            : "";
      const derivativesInitialValue = isRiskRow
        ? this.getValueForField(
            riskRecordData?.initialValues,
            riskRecordData?.cells,
            RISK_AMOUNT_FIELD
          ) ?? ""
        : "";
      const derivativesEditable =
        isRiskRow &&
        !isReadonlyRiskRecord &&
        this.hasEditableDerivativesAmount(lineRowData);
      const derivativesApplies = isRiskRow;

      const derivativesNormalized = derivativesValue ?? "";
      const derivativesIsChanged =
        derivativesApplies &&
        this.areValuesDifferent(derivativesNormalized, derivativesInitialValue, "number");
      const baseDisplay = this.formatCellDisplayValue(
        derivativesNormalized,
        column
      );
      const displayValue =
        derivativesApplies && currencyCode && baseDisplay !== "-"
          ? `${baseDisplay} ${currencyCode}`
          : baseDisplay;

      return {
        key: `${lineRowData.id}-${riskRecordData?.id || "line"}-${column.key}`,
        columnKey: column.key,
        fieldApiName: DERIVATIVES_AMOUNT_FIELD,
        label: column.label,
        sourceObjectApiName: DMT_LINE_OBJECT,
        inputType: "number",
        isPicklist: false,
        isCheckbox: false,
        options: [],
        required: column.required,
        editable: derivativesEditable,
        disabled: !derivativesEditable,
        appliesToCurrentRow: derivativesApplies,
        value: derivativesNormalized,
        checked: false,
        isChanged: derivativesIsChanged,
        cellClass: derivativesIsChanged ? "changed-cell" : "",
        displayValue,
        isAmountCell: true,
        isDerivativesAmount: true,
        currencyCode
      };
    }
    // --- End derivatives amount ---

    const isLineColumn = column.sourceObjectApiName === DMT_LINE_OBJECT;
    const isRiskColumn = column.sourceObjectApiName === RISK_LINE_TERM_OBJECT;
    const lineFieldApplies = this.hasFieldInCells(
      lineRowData?.cells,
      column.fieldApiName
    );
    const riskFieldApplies = this.hasFieldInCells(
      riskRecordData?.cells,
      column.fieldApiName
    );

    let value = "";
    let editable = false;
    let appliesToCurrentRow = false;
    let initialValue;

    if (isLineColumn && rowType === "line" && lineFieldApplies) {
      value = this.getValueForField(
        lineRowData.values,
        lineRowData.cells,
        column.fieldApiName
      );
      initialValue = this.getValueForField(
        lineRowData.initialValues,
        lineRowData.cells,
        column.fieldApiName
      );
      appliesToCurrentRow = true;
      editable = true;
    }

    if (isRiskColumn && rowType === "risk" && riskFieldApplies) {
      value = this.getValueForField(
        riskRecordData?.values,
        riskRecordData?.cells,
        column.fieldApiName
      );
      initialValue = this.getValueForField(
        riskRecordData?.initialValues,
        riskRecordData?.cells,
        column.fieldApiName
      );
      appliesToCurrentRow = true;
      // If this risk record is readonly (not the last one for TL), mark as not editable
      editable = !isReadonlyRiskRecord;
    }

    const normalizedValue = value ?? "";
    const isChanged =
      appliesToCurrentRow &&
      this.areValuesDifferent(normalizedValue, initialValue, column.inputType);

    const isAmountCell =
      column.inputType === "number" &&
      column.fieldApiName.toLowerCase().includes("amount");
    const baseDisplay = this.formatCellDisplayValue(normalizedValue, column);
    const displayValue =
      isAmountCell && appliesToCurrentRow && currencyCode && baseDisplay !== "-"
        ? `${baseDisplay} ${currencyCode}`
        : baseDisplay;

    return {
      key: `${lineRowData.id}-${riskRecordData?.id || "line"}-${column.key}`,
      columnKey: column.key,
      fieldApiName: column.fieldApiName,
      label: column.label,
      sourceObjectApiName: column.sourceObjectApiName,
      inputType: column.inputType,
      isPicklist: column.isPicklist,
      isCheckbox: column.isCheckbox,
      options: column.options || [],
      required: column.required,
      editable,
      disabled: !editable,
      appliesToCurrentRow,
      value: normalizedValue,
      checked: column.isCheckbox ? Boolean(normalizedValue) : false,
      isChanged,
      cellClass: isChanged ? "changed-cell" : "",
      displayValue,
      isAmountCell,
      currencyCode
    };
  }

  hasFieldInCells(cells, fieldApiName) {
    return (cells || []).some((cell) => cell.fieldApiName === fieldApiName);
  }

  getValueForField(valuesMap, cells, fieldApiName) {
    if (valuesMap && Object.prototype.hasOwnProperty.call(valuesMap, fieldApiName)) {
      return valuesMap[fieldApiName];
    }

    const matchingCell = (cells || []).find(
      (cell) => cell.fieldApiName === fieldApiName
    );

    return matchingCell?.value;
  }

  areValuesDifferent(currentValue, initialValue, inputType) {
    const normalizedCurrent = this.normalizeComparableValue(
      currentValue,
      inputType
    );
    const normalizedInitial = this.normalizeComparableValue(
      initialValue,
      inputType
    );

    return normalizedCurrent !== normalizedInitial;
  }

  normalizeComparableValue(value, inputType) {
    if (inputType === "checkbox") {
      return value === true;
    }

    if (value === null || value === undefined || value === "") {
      return null;
    }

    return String(value);
  }

  formatCellDisplayValue(value, column) {
    if (value === null || value === undefined || value === "") {
      return "-";
    }

    if (column.isCheckbox) {
      return value === true ? "Si" : "No";
    }

    if (column.isPicklist) {
      const selectedOption = (column.options || []).find(
        (option) => String(option.value) === String(value)
      );

      if (selectedOption?.label) {
        return selectedOption.label;
      }
    }

    return String(value);
  }

  formatAmount(value) {
    if (value === null || value === undefined || value === "") {
      return "-";
    }

    const numericValue = Number(value);

    if (Number.isNaN(numericValue)) {
      return value;
    }

    return new Intl.NumberFormat("es-ES", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(numericValue);
  }

  handleLineInputChange(event) {
    const rowId = event.target.dataset.rowId;
    const fieldApi = event.target.dataset.field;
    const value = this.getInputValue(event);

    this.rows = (this.rows || []).map((row) => {
      if (row.id !== rowId) {
        return row;
      }

      return {
        ...row,
        values: {
          ...(row.values || {}),
          [fieldApi]: value
        },
        cells: (row.cells || []).map((cell) =>
          cell.fieldApiName === fieldApi
            ? this.updateCellValue(cell, value, event.target.type)
            : cell
        )
      };
    });
  }

  handleTableInputChange(event) {
    const lineRecordId = event.target.dataset.lineRecordId;
    const rowType = event.target.dataset.rowType;
    const recordId = event.target.dataset.recordId;
    const sectionKey = event.target.dataset.sectionKey;
    const sourceObjectApiName = event.target.dataset.sourceObjectApiName;
    const fieldApi = event.target.dataset.field;
    const value = this.getInputValue(event);
    const isDerivativesAmount = event.target.dataset.isDerivativesAmount === "true";
    const isTreasuryEndTerm =
      event.target.dataset.isTreasuryEndTerm === "true";

    if (isTreasuryEndTerm && rowType === "line") {
      this.rows = (this.rows || []).map((row) =>
        String(row.id) === String(lineRecordId)
          ? { ...row, endTerm: value }
          : row
      );
      return;
    }

    // Handle Derivatives Amount through the line total, even when edited in a risk row
    if (isDerivativesAmount && (rowType === "line" || rowType === "risk")) {
      this.rows = (this.rows || []).map((row) => {
        if (String(row.id) !== String(lineRecordId)) {
          return row;
        }

        return {
          ...row,
          derivativesAmount: value
        };
      });
      return;
    }

    if (
      sourceObjectApiName === DMT_LINE_OBJECT &&
      rowType !== "line"
    ) {
      return;
    }

    if (
      sourceObjectApiName === RISK_LINE_TERM_OBJECT &&
      rowType !== "risk"
    ) {
      return;
    }

    this.rows = (this.rows || []).map((row) => {
      if (String(row.id) !== String(lineRecordId)) {
        return row;
      }

      if (sourceObjectApiName === DMT_LINE_OBJECT) {
        if (!this.hasFieldInCells(row.cells, fieldApi)) {
          return row;
        }

        return {
          ...row,
          values: {
            ...(row.values || {}),
            [fieldApi]: value
          },
          cells: (row.cells || []).map((cell) =>
            cell.fieldApiName === fieldApi
              ? this.updateCellValue(cell, value, event.target.type)
              : cell
          )
        };
      }

      return {
        ...row,
        relatedSections: (row.relatedSections || []).map((section) => {
          if (
            section.objectApiName !== sourceObjectApiName ||
            (sectionKey && section.key !== sectionKey)
          ) {
            return section;
          }

          return {
            ...section,
            records: (section.records || []).map((record) => {
              if (String(record.id) !== String(recordId)) {
                return record;
              }

              return {
                ...record,
                values: {
                  ...(record.values || {}),
                  [fieldApi]: value
                },
                cells: (record.cells || []).map((cell) =>
                  cell.fieldApiName === fieldApi
                    ? this.updateCellValue(cell, value, event.target.type)
                    : cell
                )
              };
            })
          };
        })
      };
    });
  }

  handleBulkInputChange(event) {
    const tableKey = event.target.dataset.tableKey;
    const columnKey = event.target.dataset.columnKey;
    const sourceObjectApiName = event.target.dataset.sourceObjectApiName;
    const fieldApiName = event.target.dataset.field;
    const value = this.getInputValue(event);

    const existingTableValues = this.bulkInputsByTable?.[tableKey] || {};

    this.bulkInputsByTable = {
      ...(this.bulkInputsByTable || {}),
      [tableKey]: {
        ...existingTableValues,
        [columnKey]: {
          sourceObjectApiName,
          fieldApiName,
          value
        }
      }
    };
  }

  handleOpenBulkEditor(event) {
    const tableKey = event.target.dataset.tableKey;
    const columnKey = event.target.dataset.columnKey;
    const sourceObjectApiName = event.target.dataset.sourceObjectApiName;
    const fieldApiName = event.target.dataset.field;

    this.activeBulkEditorKey = this.buildBulkEditorKey(tableKey, columnKey);

    const existingTableValues = this.bulkInputsByTable?.[tableKey] || {};

    if (!existingTableValues[columnKey]) {
      this.bulkInputsByTable = {
        ...(this.bulkInputsByTable || {}),
        [tableKey]: {
          ...existingTableValues,
          [columnKey]: {
            sourceObjectApiName,
            fieldApiName,
            value: ""
          }
        }
      };
    }
  }

  handleCloseBulkEditor() {
    this.activeBulkEditorKey = null;
  }

  handleApplyBulkChange(event) {
    const tableKey = event.target.dataset.tableKey;
    const columnKey = event.target.dataset.columnKey;

    const bulkDefinition =
      this.bulkInputsByTable?.[tableKey]?.[columnKey];

    if (!bulkDefinition) {
      return;
    }

    const { sourceObjectApiName, fieldApiName, value } = bulkDefinition;

    // Handle Merged Amount bulk apply (OL: updates Amount__c on lines and DMT_Amount__c on risk records)
    if (columnKey === MERGED_AMOUNT_COLUMN_KEY) {
      this.rows = (this.rows || []).map((row) => {
        if ((row.templateType || UNKNOWN_TEMPLATE_TYPE) !== tableKey) {
          return row;
        }

        const updatedRow = this.hasFieldInCells(row.cells, LINE_AMOUNT_FIELD)
          ? {
              ...row,
              values: { ...(row.values || {}), [LINE_AMOUNT_FIELD]: value },
              cells: (row.cells || []).map((cell) =>
                cell.fieldApiName === LINE_AMOUNT_FIELD
                  ? this.updateCellValue(cell, value, cell.inputType)
                  : cell
              )
            }
          : row;

        return {
          ...updatedRow,
          relatedSections: (updatedRow.relatedSections || []).map((section) => {
            if (section.objectApiName !== RISK_LINE_TERM_OBJECT) {
              return section;
            }

            return {
              ...section,
              records: (section.records || []).map((record) => {
                if (!this.hasFieldInCells(record.cells, RISK_AMOUNT_FIELD)) {
                  return record;
                }

                return {
                  ...record,
                  values: { ...(record.values || {}), [RISK_AMOUNT_FIELD]: value },
                  cells: (record.cells || []).map((cell) =>
                    cell.fieldApiName === RISK_AMOUNT_FIELD
                      ? this.updateCellValue(cell, value, cell.inputType)
                      : cell
                  )
                };
              })
            };
          })
        };
      });

      this.activeBulkEditorKey = null;
      return;
    }

    if (columnKey === TREASURY_END_TERM_COLUMN_KEY) {
      this.rows = (this.rows || []).map((row) => {
        const rowTemplateType = row.templateType || UNKNOWN_TEMPLATE_TYPE;

        if (
          rowTemplateType !== tableKey ||
          !this.hasEditableTreasuryEndTerm(row)
        ) {
          return row;
        }

        return {
          ...row,
          endTerm: value
        };
      });

      this.activeBulkEditorKey = null;
      return;
    }

    // Handle Derivatives Amount bulk apply
    if (columnKey === DERIVATIVES_AMOUNT_COLUMN_KEY) {
      this.rows = (this.rows || []).map((row) => {
        const rowTemplateType = row.templateType || UNKNOWN_TEMPLATE_TYPE;

        if (
          rowTemplateType !== tableKey ||
          !this.hasEditableDerivativesAmount(row)
        ) {
          return row;
        }

        return {
          ...row,
          derivativesAmount: value
        };
      });

      this.activeBulkEditorKey = null;
      return;
    }

    this.rows = (this.rows || []).map((row) => {
      const rowTemplateType = row.templateType || UNKNOWN_TEMPLATE_TYPE;

      if (rowTemplateType !== tableKey) {
        return row;
      }

      if (sourceObjectApiName === DMT_LINE_OBJECT) {
        if (!this.hasFieldInCells(row.cells, fieldApiName)) {
          return row;
        }

        return {
          ...row,
          values: {
            ...(row.values || {}),
            [fieldApiName]: value
          },
          cells: (row.cells || []).map((cell) =>
            cell.fieldApiName === fieldApiName
              ? this.updateCellValue(cell, value, cell.inputType)
              : cell
          )
        };
      }

      if (sourceObjectApiName === RISK_LINE_TERM_OBJECT) {
        return {
          ...row,
          relatedSections: (row.relatedSections || []).map((section) => {
            if (section.objectApiName !== RISK_LINE_TERM_OBJECT) {
              return section;
            }

            return {
              ...section,
              records: (section.records || []).map((record) => {
                if (!this.hasFieldInCells(record.cells, fieldApiName)) {
                  return record;
                }

                return {
                  ...record,
                  values: {
                    ...(record.values || {}),
                    [fieldApiName]: value
                  },
                  cells: (record.cells || []).map((cell) =>
                    cell.fieldApiName === fieldApiName
                      ? this.updateCellValue(cell, value, cell.inputType)
                      : cell
                  )
                };
              })
            };
          })
        };
      }

      return row;
    });

    this.activeBulkEditorKey = null;
  }

  handleRelatedInputChange(event) {
    const rowId = event.target.dataset.rowId;
    const sectionKey = event.target.dataset.sectionKey;
    const recordId = event.target.dataset.recordId;
    const fieldApi = event.target.dataset.field;
    const value = this.getInputValue(event);

    this.rows = (this.rows || []).map((row) => {
      if (row.id !== rowId) {
        return row;
      }

      return {
        ...row,
        relatedSections: (row.relatedSections || []).map((section) => {
          if (section.key !== sectionKey) {
            return section;
          }

          return {
            ...section,
            records: (section.records || []).map((record) => {
              if (record.id !== recordId) {
                return record;
              }

              return {
                ...record,
                values: {
                  ...(record.values || {}),
                  [fieldApi]: value
                },
                cells: (record.cells || []).map((cell) =>
                  cell.fieldApiName === fieldApi
                    ? this.updateCellValue(cell, value, event.target.type)
                    : cell
                )
              };
            })
          };
        })
      };
    });
  }

  getInputValue(event) {
    return event.target.type === "checkbox"
      ? event.target.checked
      : event.target.value;
  }

  updateCellValue(cell, value, inputType) {
    return {
      ...cell,
      value,
      checked: inputType === "checkbox" ? value : cell.checked
    };
  }

  getSaveValues(valuesMap, cells) {
    const allowedFields = new Set(
      (cells || []).map((cell) => cell.fieldApiName)
    );

    return Object.keys(valuesMap || {}).reduce((acc, fieldApiName) => {
      if (allowedFields.has(fieldApiName)) {
        acc[fieldApiName] = valuesMap[fieldApiName];
      }

      return acc;
    }, {});
  }

  async handleSave() {
    try {
      this.isLoading = true;
      this.loadingMessage = "Modifying selected lines...";

      const rowsToSave = (this.rows || []).map((row) => {
        let relatedSectionsToSave = (row.relatedSections || []).map(
          (section) => {
            let recordsToSave = (section.records || []);

            // For Treasury Lines, only include the last risk record
            if (
              row.templateType === TREASURY_TEMPLATE_TYPE &&
              section.objectApiName === RISK_LINE_TERM_OBJECT
            ) {
              recordsToSave =
                recordsToSave.length > 0
                  ? [recordsToSave[recordsToSave.length - 1]]
                  : [];
            }

            return {
              key: section.key,
              objectApiName: section.objectApiName,
              lookupField: section.lookupField,
              records: recordsToSave.map((record) => {
                const values = this.getSaveValues(record.values, record.cells);

                if (
                  row.templateType === TREASURY_TEMPLATE_TYPE &&
                  section.objectApiName === RISK_LINE_TERM_OBJECT
                ) {
                  delete values.DMT_Amount__c;
                }

                return {
                  id: record.id,
                  values
                };
              })
            };
          }
        );

        // For non-TL templates, filter out if no records, otherwise include all
        if (row.templateType !== TREASURY_TEMPLATE_TYPE) {
          relatedSectionsToSave = relatedSectionsToSave.filter(
            (section) => section.records.length > 0
          );
        }

        const payload = {
          id: row.id,
          lineId: row.lineId,
          values: this.getSaveValues(row.values, row.cells),
          relatedSections: relatedSectionsToSave
        };

        // Include derivativesAmount if it has changed
        if (
          row.derivativesAmount !== undefined &&
          row.derivativesAmount !== null &&
          row.derivativesAmount !== "" &&
          this.areValuesDifferent(row.derivativesAmount, row.initialDerivativesAmount, "number")
        ) {
          payload.derivativesAmount = row.derivativesAmount;
        }

        return payload;
      });

      await saveModifiedLines({
        rows: rowsToSave
      });

      this.close("saved");
    } catch (error) {
      this.showToast(
        "Error",
        error?.body?.message || error?.message || "Unknown error",
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  handleCancel() {
    this.close("cancel");
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}