import { api, track } from "lwc";
import LightningModal from "lightning/modal";
import getModifyPayload from "@salesforce/apex/DMT_LinesBulkActionController.getModifyPayload";
import saveModifiedLines from "@salesforce/apex/DMT_LinesBulkActionController.saveModifiedLines";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const TREASURY_TEMPLATE_TYPE = "TL";
const DMT_LINE_OBJECT = "DMT_Line__c";
const RISK_LINE_TERM_OBJECT = "DMT_Risk_Line_Term__c";
const UNKNOWN_TEMPLATE_TYPE = "UNSPECIFIED";

export default class DmtModifyLinesModal extends LightningModal {
  @api lineIds = [];

  @track rows = [];
  @track bulkInputsByTable = {};
  activeBulkEditorKey;

  isLoading = false;
  loadingMessage = "Loading selected lines...";

  async connectedCallback() {
    await this.loadData();
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

      riskRecords.forEach((record) => {
        (record.cells || []).forEach((cell) => {
          this.registerColumn(
            group,
            cell,
            RISK_LINE_TERM_OBJECT
          );
        });
      });

      group.riskRowCount += riskRecords.length;
      group.lineEntries.push({ row, riskSection, riskRecords });
    });

    return Object.values(groupsByTemplate).map((group) => {
      const columns = group.columnOrder.map(
        (columnKey) => group.columnsByKey[columnKey]
      );

      const tableRows = [];

      group.lineEntries.forEach((entry) => {
        const groupSize = 1 + (entry.riskRecords || []).length;

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

        (entry.riskRecords || []).forEach((riskRecord, index) => {
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
              columns
            })
          );
        });
      });

      const columnsWithBulk = columns.map((column) => {
        const storedBulkValue =
          this.bulkInputsByTable?.[group.templateType]?.[column.key]?.value;

        const canBulkApply =
          column.sourceObjectApiName === DMT_LINE_OBJECT
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
      return `Producto ${index + 1}`;
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

    return `Producto ${index + 1}`;
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
      const records = (section.records || []).map((record, index) => ({
        ...record,
        rowNumber: index + 1,
        values: { ...(record.values || {}) },
        initialValues: { ...(record.values || {}) },
        cells: (record.cells || []).map((cell) => ({
          ...cell,
          value: cell.value ?? "",
          checked: cell.checked ?? false,
          options: cell.options || [],
          isPicklist: cell.isPicklist === true
        }))
      }));

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

return {
  ...row,
  lineName: row.lineName || row.lineId,
  lineUrl: row.lineUrl || `/${row.id}`,
  derivativesAmountDisplay: this.formatAmount(row.derivativesAmount),
  derivativesCurrencyIsoCode: row.currencyIsoCode || "",
  values: { ...(row.values || {}) },
  initialValues: { ...(row.values || {}) },
  cells,
  hasLineCells: cells.length > 0,
  isTreasuryLine,
  relatedSections
    };
  }

  registerColumn(group, cell, sourceObjectApiName) {
    if (!cell?.fieldApiName) {
      return;
    }

    const columnKey = `${sourceObjectApiName}::${cell.fieldApiName}`;

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
        helpText:
          sourceObjectApiName === DMT_LINE_OBJECT
            ? "Editable only in the main line row and only when applicable by geography."
            : "Editable in product rows and only when applicable by geography."
      };

      group.columnOrder.push(columnKey);
    }
  }

  getRiskTermSection(row) {
    return (row.relatedSections || []).find(
      (section) => section.objectApiName === RISK_LINE_TERM_OBJECT
    );
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
      columns
    } = config;

    return {
      key: rowKey,
      rowType,
      rowLabel,
      lineRecordId: lineRowData.id,
      lineId: lineRowData.lineId,
      lineName: lineRowData.lineName,
      lineUrl: lineRowData.lineUrl,
      recordId: riskRecordData?.id,
      sectionKey,
      showGroupCells,
      groupSize,
      cells: columns.map((column) =>
        this.buildRenderedCell({
          rowType,
          lineRowData,
          riskRecordData,
          column
        })
      )
    };
  }

  buildRenderedCell(config) {
    const { rowType, lineRowData, riskRecordData, column } = config;

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
      editable = true;
    }

    const normalizedValue = value ?? "";
    const isChanged =
      appliesToCurrentRow &&
      this.areValuesDifferent(normalizedValue, initialValue, column.inputType);

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
      displayValue: this.formatCellDisplayValue(
        normalizedValue,
        column
      )
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

      const rowsToSave = (this.rows || []).map((row) => ({
        id: row.id,
        lineId: row.lineId,
        values: this.getSaveValues(row.values, row.cells),
        relatedSections: (row.relatedSections || []).map((section) => ({
          key: section.key,
          objectApiName: section.objectApiName,
          lookupField: section.lookupField,
          records: (section.records || []).map((record) => ({
            id: record.id,
            values: this.getSaveValues(record.values, record.cells)
          }))
        }))
      }));

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