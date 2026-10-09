import { LightningElement, api } from 'lwc';
import dmt_cl_ProfMin_Text from '@salesforce/label/c.dmt_cl_ProfMin_Text';
import dmt_cl_ProfRange from '@salesforce/label/c.dmt_cl_ProfRange';
import getInitialOptions from '@salesforce/apex/DMT_ProfitabilityAxisSelectorController.getInitialOptions';

const EVT_NAME = 'changedvaluesaxis';
const DEFAULT_FIELD_TYPE = 'Decimal';
// FlexCard retirado — dmt_profitabilityTestInput ahora dispara un CustomEvent directo
// ('axisinputchange') en vez de usar el bus global omnistudio/pubsub (ver handleChildInputChange
// / dmt_ProfitabilityAxisSelector.html).
const AXIS_TYPES = { X: 'XAxis', Y: 'YAxis', CENTRAL: 'CentralAxis' };

// Field value IDs for rating axes (O(1) lookup via Set)
const RATING_FIELD_VALUES = new Set(['2', '9']);

// Field value IDs: 3=Fees Upfront, 4=Spread Drawn, 7=Fees Periodificable, 8=Spread Undrawn
const SPREAD_FEES_FIELD_VALUES = new Set(['3', '4', '7', '8']);
const SPREAD_FEES_MULTIPLIER = 9;
const SPREAD_FEES_MAX_THRESHOLD = 1000;

// Field value ID and maximum scenario value for the Term axis
const TERM_FIELD_VALUE = '1';
const TERM_MAX_THRESHOLD = 50;

// Field values filtered by opportunity data
const SPREAD_DRAWN_VALUE = '4';
const SPREAD_UNDRAWN_VALUE = '8';

// Field value for external ID (no min/range inputs)
const EXTERNAL_ID_VALUE = '10';

// Sort comparator for catalog ordering (null/undefined → end of list)
const ordenComparator = (a, b) =>
  (a.orden == null ? Infinity : Number(a.orden)) -
  (b.orden == null ? Infinity : Number(b.orden));

export default class Dmt_ProfitabilityAxisSelector extends LightningElement {
  label = { dmt_cl_ProfMin_Text, dmt_cl_ProfRange };

  @api catalogRating;
  @api catalogInternalRating;
  @api obsoletePassport;

  optionsX = [];
  optionsY = [];
  optionsCentral = [];
  xSelected = '';
  ySelected = '';
  centralSelected = '';
  xSelectedLabel = '';
  ySelectedLabel = '';
  centralSelectedLabel = '';
  xFieldType = DEFAULT_FIELD_TYPE;
  yFieldType = DEFAULT_FIELD_TYPE;
  disabledControls = false;
  errorMessage = '';
  xRatingRangeError = '';
  yRatingRangeError = '';
  xRowError = '';
  yRowError = '';

  // Internal state (not referenced in template)
  masterOptionsX = [];
  masterOptionsY = [];
  masterOptionsCentral = [];
  combos = [];
  focusedControl = null;
  _oppSelected;
  _productSelected;
  _oppSelectedData;
  _nominalAmountNew;
  _nominalFbNew;
  _childInputValues = {};
  _childInputErrors = {};
  _changeJustHandled = false;
  _validationScheduled = false;
  _cachedParsedOppData = null;
  _cachedXOptions = [];
  _cachedYOptions = [];
  _lastXSelected = '';
  _lastYSelected = '';
  _lastXCatalog = null;
  _lastYCatalog = null;


  connectedCallback() {
    this.loadInitialOptions();
  }

  disconnectedCallback() {
    // No-op: ya no hay suscripción a un bus global que dar de baja (ver Fase 3 del plan).
  }

  // ── Public API setters ──────────────────────────────────────────────────

  @api
  set oppSelected(value) {
    if (this._oppSelected !== value) {
      const prev = this._oppSelected;
      this._oppSelected = value;
      if (prev != null) this.handleUndo();
    }
  }
  get oppSelected() {
    return this._oppSelected;
  }

  @api
  set oppSelectedData(value) {
    // Main creates a new merged object on each render. Treat it as data only; real context
    // changes are handled by the stable oppSelected and productSelected identifiers.
    this._oppSelectedData = value;
    this._cachedParsedOppData = value;
  }
  get oppSelectedData() {
    return this._oppSelectedData;
  }

  @api
  set productSelected(value) {
    if (this._productSelected !== value) {
      const prev = this._productSelected;
      this._productSelected = value;
      if (prev != null) {
        this.handleUndo();
      }
    }
  }
  get productSelected() {
    return this._productSelected;
  }

  @api
  set nominalAmountNew(value) {
    // FlexCard retirado: ya no hace falta isValidOmniValue, Main pasa null/número directamente.
    const sanitized = value ?? null;
    if (this._nominalAmountNew !== sanitized) {
      const prev = this._nominalAmountNew;
      this._nominalAmountNew = sanitized;
      if (prev != null) this.handleUndo();
    }
  }
  get nominalAmountNew() {
    return this._nominalAmountNew;
  }

  @api
  set nominalFbNew(value) {
    const sanitized = value ?? null;
    if (this._nominalFbNew !== sanitized) {
      const prev = this._nominalFbNew;
      this._nominalFbNew = sanitized;
      if (prev != null) this.handleUndo();
    }
  }
  get nominalFbNew() {
    return this._nominalFbNew;
  }

  // ── Computed getters ────────────────────────────────────────────────────

  get disabledUndo() {
    return (
      this.disabledControls ||
      !(this.xSelected || this.ySelected || this.centralSelected)
    );
  }

  get _parsedOppData() {
    return this._cachedParsedOppData;
  }

  // Consolidated opportunity-based filtering (eliminates 3x duplication)
  get _effectiveMasterOptionsX() {
    return this._filterByOppData(this.masterOptionsX);
  }
  get _effectiveMasterOptionsY() {
    return this._filterByOppData(this.masterOptionsY);
  }
  get _effectiveMasterOptionsCentral() {
    return this._filterByOppData(this.masterOptionsCentral);
  }

  // Memoized rating catalog getters (same reference if inputs unchanged → skips child re-render)
  get _resolvedXOptions() {
    const selected = this.xSelected;
    const catalog = selected === '2' ? this.catalogInternalRating : selected === '9' ? this.catalogRating : null;
    if (selected === this._lastXSelected && catalog === this._lastXCatalog) {
      return this._cachedXOptions;
    }
    this._lastXSelected = selected;
    this._lastXCatalog = catalog;
    this._cachedXOptions = this._resolveRatingCatalog(selected);
    return this._cachedXOptions;
  }
  get _resolvedYOptions() {
    const selected = this.ySelected;
    const catalog = selected === '2' ? this.catalogInternalRating : selected === '9' ? this.catalogRating : null;
    if (selected === this._lastYSelected && catalog === this._lastYCatalog) {
      return this._cachedYOptions;
    }
    this._lastYSelected = selected;
    this._lastYCatalog = catalog;
    this._cachedYOptions = this._resolveRatingCatalog(selected);
    return this._cachedYOptions;
  }

  get showXInputs() {
    return this.xSelected !== EXTERNAL_ID_VALUE;
  }
  get showYInputs() {
    return this.ySelected !== EXTERNAL_ID_VALUE;
  }

  // ── Apex loading ────────────────────────────────────────────────────────

  async loadInitialOptions() {
    try {
      const resp = await getInitialOptions();
      const mapOpt = (o) => ({
        id: o.id,
        label: o.label,
        value: `${o.value}`,
        dataType: o.dataType
      });
      this.masterOptionsX = Array.isArray(resp.xOptions)
        ? resp.xOptions.map(mapOpt)
        : [];
      this.masterOptionsY = Array.isArray(resp.yOptions)
        ? resp.yOptions.map(mapOpt)
        : [];
      this.masterOptionsCentral = Array.isArray(resp.centralOptions)
        ? resp.centralOptions.map(mapOpt)
        : [];
      this.combos = Array.isArray(resp.combinations)
        ? resp.combinations.map((c) => ({
            xId: c.xId,
            yId: c.yId,
            centerId: c.centerId
          }))
        : [];
      this._resetOptions();
      this.updateFilteredOptions();
      this._validateOptions();
    } catch (error) {
      console.error('Error loading initial options', error);
      this._handleLoadError();
    }
  }

  // ── Event handlers ──────────────────────────────────────────────────────

  handleChange(event) {
    const name = event.target.name;
    const value = event.detail.value;
    this._applyAxisSelection(name, value);
    this._changeJustHandled = true;
    this.updateFilteredOptions(name);
    this._dispatchChangeEvent();
  }

  handleFocus(event) {
    this.focusedControl = event.target.name;
  }

  handleBlur() {
    this.focusedControl = null;
    if (this._changeJustHandled) {
      this._changeJustHandled = false;
    } else {
      this.updateFilteredOptions();
    }
  }

  handleUndo() {
    this._clearSelections();
    const masterX = this._effectiveMasterOptionsX;
    const masterY = this._effectiveMasterOptionsY;
    this.optionsX = [...masterX];
    this.optionsY = [...masterY];
    this.optionsCentral = [...this._effectiveMasterOptionsCentral];
    this.xFieldType = masterX[0]?.dataType || DEFAULT_FIELD_TYPE;
    this.yFieldType = masterY[0]?.dataType || DEFAULT_FIELD_TYPE;
    this.updateFilteredOptions();
    this._dispatchChangeEvent();
  }

  @api
  reset() {
    this.handleUndo();
  }

  handleChangeProduct() {
    this._dispatchChangeEvent();
  }

  // ── Combo-constraint filtering ─────────────────────────────────────────

  updateFilteredOptions(changedAxis) {
    // Cache getters to avoid repeated JSON.parse inside _filterByOppData
    const masterX = this._effectiveMasterOptionsX;
    const masterY = this._effectiveMasterOptionsY;
    const masterC = this._effectiveMasterOptionsCentral;

    if (!this.combos || this.combos.length === 0) {
      this.optionsX = [...masterX];
      this.optionsY = [...masterY];
      this.optionsCentral = [...masterC];
      return;
    }

    const selXId = this.getIdByValue(masterX, this.xSelected);
    const selYId = this.getIdByValue(masterY, this.ySelected);
    const selCId = this.getIdByValue(masterC, this.centralSelected);

    const allowedX = new Set();
    const allowedY = new Set();
    const allowedC = new Set();

    for (const c of this.combos) {
      // Calculate requires all three axes, so incomplete rows are not valid triplets.
      if (!c.xId || !c.yId || !c.centerId) continue;
      const xMatch = !selXId || `${c.xId}` === `${selXId}`;
      const yMatch = !selYId || `${c.yId}` === `${selYId}`;
      const cMatch = !selCId || `${c.centerId}` === `${selCId}`;
      if (yMatch && cMatch && c.xId) allowedX.add(`${c.xId}`);
      if (xMatch && cMatch && c.yId) allowedY.add(`${c.yId}`);
      if (xMatch && yMatch && c.centerId) allowedC.add(`${c.centerId}`);
    }

    // Empty means that no active combination satisfies the selected facets.
    const filterByAllowed = (masterList, allowedSet) =>
      masterList.filter((opt) => allowedSet.has(`${opt.id}`));

    this.optionsX = filterByAllowed(masterX, allowedX);
    this.optionsY = filterByAllowed(masterY, allowedY);
    this.optionsCentral = filterByAllowed(masterC, allowedC);

    // Each axis is filtered only by the other two. If a stale value reaches the handler,
    // reject the latest change instead of clearing previously valid selections.
    if (changedAxis && this._clearInvalidAxisSelection(changedAxis)) {
      this.updateFilteredOptions();
    }
  }

  // ── Cross-validation de inputs hijos (dmt_profitabilityTestInput) ──────
  // FlexCard retirado: dmt_profitabilityTestInput es hijo directo de este componente (ver su
  // propio template) y ahora dispara un CustomEvent estándar `axisinputchange` (bubbles: true)
  // en vez de usar el bus global omnistudio/pubsub. El listener se declara directamente en
  // dmt_ProfitabilityAxisSelector.html (onaxisinputchange={handleChildInputChange}).

  handleChildInputChange(event) {
    const { inputId, value, errors } = event?.detail || {};
    if (inputId) {
      this._childInputValues = { ...this._childInputValues, [inputId]: value };
      this._childInputErrors = { ...this._childInputErrors, [inputId]: errors || [] };
      if (!this._validationScheduled) {
        this._validationScheduled = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => {
          this._validationScheduled = false;
          this._validateAllChildInputs();
        });
      }
    }
  }

  _validateAllChildInputs() {
  const minLabel = this.label.dmt_cl_ProfMin_Text;
  const xRangeLabel = RATING_FIELD_VALUES.has(this.xSelected) ? 'Max' : this.label.dmt_cl_ProfRange;
  const yRangeLabel = RATING_FIELD_VALUES.has(this.ySelected) ? 'Max' : this.label.dmt_cl_ProfRange;

    const xMsg = this._buildAxisRowMessage(
      this._childInputValues.xMin ?? '',
      this._childInputValues.xRange ?? '',
      this._childInputErrors.xMin || [],
      this._childInputErrors.xRange || [],
      this.xSelected,
      this.xSelectedLabel,
      minLabel,
      xRangeLabel
    );
    const yMsg = this._buildAxisRowMessage(
      this._childInputValues.yMin ?? '',
      this._childInputValues.yRange ?? '',
      this._childInputErrors.yMin || [],
      this._childInputErrors.yRange || [],
      this.ySelected,
      this.ySelectedLabel,
      minLabel,
      yRangeLabel
    );

    this.xRowError = xMsg;
    this.yRowError = yMsg;
    this.xRatingRangeError = xMsg;
    this.yRatingRangeError = yMsg;
    this._dispatchChangeEvent();
  }

  // Builds a single unified error message for an axis row with three-tier priority
  _buildAxisRowMessage(minVal, rangeVal, minErrors, rangeErrors, selected, selectedLabel, minLabel, rangeLabel) {
    const hasMin = minVal !== '' && minVal != null;
    const hasRange = rangeVal !== '' && rangeVal != null;

    // Priority 1: one input filled, the other is not
    if (hasMin && !hasRange) return `${rangeLabel} is required when ${minLabel} is set.`;
    if (!hasMin && hasRange) return `${minLabel} is required when ${rangeLabel} is set.`;

    // Neither filled — no error
    if (!hasMin && !hasRange) return '';

    // Priority 2: type / format errors reported by the child inputs
    const childErrors = [...minErrors, ...rangeErrors];
    if (childErrors.length > 0) return childErrors[0];

    // Priority 3: cross-input validations (both filled, no type errors)
    return this._validateAxisCross(minVal, rangeVal, selected, selectedLabel);
  }

  // Cross-input validations: rating order and spread/fees overflow
  _validateAxisCross(minVal, rangeVal, selected, selectedLabel) {
    // Rating range check
    if (RATING_FIELD_VALUES.has(selected)) {
      const catalog =
        selected === '2' ? this.catalogInternalRating : this.catalogRating;
      const ratingMsg = this._checkRatingPair(catalog, minVal, rangeVal);
      if (ratingMsg) return ratingMsg;
    }

    // Spread/fees overflow check
    const minNum = Number(minVal);
    const rangeNum = Number(rangeVal);
    if (
      !Number.isNaN(minNum) &&
      !Number.isNaN(rangeNum) &&
      SPREAD_FEES_FIELD_VALUES.has(`${selected}`)
    ) {
      if (minNum + rangeNum * SPREAD_FEES_MULTIPLIER >= SPREAD_FEES_MAX_THRESHOLD) {
        return (
          'The values provided for ' +
          selectedLabel +
          ' axis are outside the allowed range. Please verify the data.'
        );
      }
    }

    if (
      !Number.isNaN(minNum) &&
      !Number.isNaN(rangeNum) &&
      `${selected}` === TERM_FIELD_VALUE &&
      minNum + rangeNum * SPREAD_FEES_MULTIPLIER >= TERM_MAX_THRESHOLD
    ) {
      return (
        'The values provided for ' +
        selectedLabel +
        ' axis are outside the allowed range. Please verify the data.'
      );
    }

    return '';
  }

  _checkRatingPair(catalog, minValue, maxValue) {
    if (!Array.isArray(catalog) || !minValue || !maxValue) return '';
    const minOpt = catalog.find((o) => `${o.value}` === `${minValue}`);
    const maxOpt = catalog.find((o) => `${o.value}` === `${maxValue}`);
    if (!minOpt || !maxOpt || minOpt.orden == null || maxOpt.orden == null)
      return '';
    if (Number(minOpt.orden) <= Number(maxOpt.orden)) {
      return 'The Min rating must be of lower quality (higher orden) than the Max rating. Adjust the selection.';
    }
    return '';
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  _filterByOppData(options) {
    let filtered = [...options];
    const oppData = this._parsedOppData;
    const effectiveNominalAmount = this._nominalAmountNew != null ? Number(this._nominalAmountNew) : oppData?.nominalAmount;
    const effectiveNominalFb = this._nominalFbNew != null ? Number(this._nominalFbNew) : oppData?.nominalFb;

    if (effectiveNominalAmount === 0) {
      filtered = filtered.filter((o) => o.value !== SPREAD_DRAWN_VALUE);
    }
    if (effectiveNominalFb === 0) {
      filtered = filtered.filter((o) => o.value !== SPREAD_UNDRAWN_VALUE);
    }
    return filtered;
  }

  _resolveRatingCatalog(selected) {
    let catalog;
    if (selected === '2') {
      catalog = Array.isArray(this.catalogInternalRating)
        ? this.catalogInternalRating
        : [];
    } else if (selected === '9') {
      catalog = Array.isArray(this.catalogRating) ? this.catalogRating : [];
    } else {
      return [];
    }
    return [...catalog].sort(ordenComparator);
  }

  _applyAxisSelection(name, value) {
    if (name === AXIS_TYPES.X) {
      this.xSelected = value;
      const found = this.optionsX.find((o) => `${o.value}` === `${value}`);
      this.xFieldType = found?.dataType || DEFAULT_FIELD_TYPE;
      this.xSelectedLabel = found?.label || '';
    } else if (name === AXIS_TYPES.Y) {
      this.ySelected = value;
      const found = this.optionsY.find((o) => `${o.value}` === `${value}`);
      this.yFieldType = found?.dataType || DEFAULT_FIELD_TYPE;
      this.ySelectedLabel = found?.label || '';
    } else if (name === AXIS_TYPES.CENTRAL) {
      this.centralSelected = value;
      const found = this.optionsCentral.find(
        (o) => `${o.value}` === `${value}`
      );
      this.centralSelectedLabel = found?.label || '';
    }
  }

  _clearInvalidAxisSelection(axisType) {
    const axisConfig = {
      [AXIS_TYPES.X]: {
        selectedProp: 'xSelected',
        labelProp: 'xSelectedLabel',
        options: this.optionsX
      },
      [AXIS_TYPES.Y]: {
        selectedProp: 'ySelected',
        labelProp: 'ySelectedLabel',
        options: this.optionsY
      },
      [AXIS_TYPES.CENTRAL]: {
        selectedProp: 'centralSelected',
        labelProp: 'centralSelectedLabel',
        options: this.optionsCentral
      }
    };
    const config = axisConfig[axisType];
    if (
      !config ||
      !this[config.selectedProp] ||
      config.options.some(
        (option) => `${option.value}` === `${this[config.selectedProp]}`
      )
    ) {
      return false;
    }
    this[config.selectedProp] = '';
    this[config.labelProp] = '';
    return true;
  }

  _refreshChildInputs() {
    const inputs = this.template.querySelectorAll(
      'c-dmt_profitability-test-input'
    );
    if (inputs?.length) {
      inputs.forEach((inp) => {
        try {
          if (typeof inp.refresh === 'function') {
            inp.refresh();
          } else if (typeof inp.validate === 'function') {
            inp.validate();
          }
        } catch (err) {
          console.warn('Error refreshing child input', err);
        }
      });
    }
  }

  _resetOptions() {
    const masterX = this._effectiveMasterOptionsX;
    const masterY = this._effectiveMasterOptionsY;
    const masterC = this._effectiveMasterOptionsCentral;
    this.optionsX = [...masterX];
    this.optionsY = [...masterY];
    this.optionsCentral = [...masterC];
    this.xSelectedLabel = this.getLabelByValue(masterX, this.xSelected);
    this.ySelectedLabel = this.getLabelByValue(masterY, this.ySelected);
    this.centralSelectedLabel = this.getLabelByValue(masterC, this.centralSelected);
  }

  _validateOptions() {
    const missing = [];
    if (this.optionsX.length === 0) missing.push('eje X');
    if (this.optionsY.length === 0) missing.push('eje Y');
    if (this.optionsCentral.length === 0) missing.push('valor central');

    if (missing.length) {
      this.disabledControls = true;
      this.errorMessage = `Data is missing to use the calculator: ${missing.join(', ')}. Contact the administrator.`;
      this._clearSelections();
    } else {
      this.disabledControls = false;
      this.errorMessage = '';
      this.xFieldType = this.optionsX[0]?.dataType || DEFAULT_FIELD_TYPE;
      this.yFieldType = this.optionsY[0]?.dataType || DEFAULT_FIELD_TYPE;
    }
  }

  _clearSelections() {
    this.xSelected = '';
    this.ySelected = '';
    this.centralSelected = '';
    this.xSelectedLabel = '';
    this.ySelectedLabel = '';
    this.centralSelectedLabel = '';
    this.focusedControl = null;
    this._childInputValues = {};
    this._childInputErrors = {};
    this.xRatingRangeError = '';
    this.yRatingRangeError = '';
    this.xRowError = '';
    this.yRowError = '';
  }

  _handleLoadError() {
    this.optionsX = [];
    this.optionsY = [];
    this.optionsCentral = [];
    this.disabledControls = true;
    this.errorMessage =
      'Error loading options. Check the console and contact the administrator.';
  }

  _dispatchChangeEvent() {
    const payloadEvent = {
      xSelected: this.xSelected,
      ySelected: this.ySelected,
      centralSelected: this.centralSelected,
      xSelectedLabel: this.xSelectedLabel,
      ySelectedLabel: this.ySelectedLabel,
      centralSelectedLabel: this.centralSelectedLabel,
      xFieldType: this.xFieldType,
      yFieldType: this.yFieldType,
      // Min/range values entered on the child dmt_profitabilityTestInput instances, needed by
      // Main to build the real calculate request (minX/maxX/minY/maxY).
      xMin: this._childInputValues.xMin ?? '',
      xRange: this._childInputValues.xRange ?? '',
      yMin: this._childInputValues.yMin ?? '',
      yRange: this._childInputValues.yRange ?? '',
      disabledCalculate: !(
        this.xSelected &&
        this.ySelected &&
        this.centralSelected &&
        this.obsoletePassport !== true &&
        !this.xRatingRangeError &&
        !this.yRatingRangeError
      ),
      xRatingRangeError: this.xRatingRangeError,
      yRatingRangeError: this.yRatingRangeError,
      changedAxis: true
    };
    this.dispatchEvent(
      new CustomEvent(EVT_NAME, {
        detail: payloadEvent,
        bubbles: true,
        composed: true
      })
    );
  }

  // ── Utility ─────────────────────────────────────────────────────────────

  getIdByValue(masterList, value) {
    if (!value) return null;
    const found = masterList.find((o) => `${o.value}` === `${value}`);
    return found ? found.id : null;
  }

  getLabelByValue(masterList, value) {
    if (!value) return null;
    const found = masterList.find((o) => `${o.value}` === `${value}`);
    return found?.label || null;
  }

  _parseOppDataValue(data) {
    // FlexCard retirado: ya no llegan JSON strings desde OmniStudio, se deja comentado por
    // trazabilidad histórica en vez de eliminarlo directamente.
    // if (!data) return null;
    // try {
    //   return typeof data === 'string' ? JSON.parse(data) : data;
    // } catch (e) {
    //   return null;
    // }
    return data;
  }

  // FlexCard retirado (validaba JSON strings/placeholders sin resolver de OmniStudio) — se deja
  // comentado por trazabilidad histórica en vez de eliminarlo directamente.
  // isValidOmniValue(value) {
  //   if (value === null || value === undefined) return false;
  //
  //   if (typeof value === 'string') {
  //     const v = value.trim();
  //     if (v === '' || v.toLowerCase() === 'null') return false;
  //
  //     // placeholder simple como {overridefields} o {oppData} -> devolver false
  //     const placeholderRegex = /^\{\s*[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*\s*\}$/;
  //     if (placeholderRegex.test(v)) return false;
  //
  //     return true;
  //   } else if (typeof value === 'object') {
  //     return true;
  //   }
  //   return false;
  // }
}