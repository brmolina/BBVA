import { LightningElement, api } from 'lwc';

/**
 * @component dynamic_path
 * @description Generic, reusable path/progress component for Salesforce LWC.
 *
 * Renders a visual step tracker in one of two modes, controlled by `useLightningPath`:
 *   - **Lightning mode** (default): uses `lightning-progress-indicator` (base component).
 *   - **Custom SLDS mode**: renders a fully custom SLDS path with finer visual control
 *     (e.g. completed steps show their label instead of a check icon).
 *
 * Both modes support:
 *   - Highlighting the current and selected steps.
 *   - An optional "mark complete" action button.
 *   - Grouping multiple picklist values under a single visual step via `groupedValues`.
 *   - Ordering steps via the `order` field on each step object.
 *
 * @fires stepselect - Fired when the user clicks a step. Detail: `{ stepKey: string }`.
 * @fires markcomplete - Fired when the user clicks the action button.
 *
 * @example
 * <!-- Basic usage -->
 * <c-dynamic_path
 *     steps={mySteps}
 *     current-step={currentStatus}
 *     selected-step={selectedStatus}
 *     display-button
 *     button-label="Save"
 *     onstepselect={handleStepSelect}
 *     onmarkcomplete={handleMarkComplete}>
 * </c-dynamic_path>
 *
 * @example
 * <!-- With grouped values and custom SLDS mode -->
 * <c-dynamic_path
 *     steps={mySteps}
 *     current-step={currentStatus}
 *     grouped-values={groupedValues}
 *     use-lightning-path="false"
 *     display-button
 *     onstepselect={handleStepSelect}
 *     onmarkcomplete={handleMarkComplete}>
 * </c-dynamic_path>
 */
export default class Dynamic_path extends LightningElement {
    /**
     * @type {{ label: string, value: string, order?: number }[]}
     * @description List of steps to display. Follows the same shape as Salesforce picklist entries.
     *   - `label`: display text shown in the path.
     *   - `value`: internal identifier used to match `currentStep` / `selectedStep`.
     *   - `order` (optional): numeric position. If any step has `order`, all steps are sorted by it;
     *     otherwise the original array order is preserved.
     */
    @api steps = [];

    /**
     * @type {string}
     * @description Value of the step that is currently active on the record (e.g. the field value
     * from Salesforce). Determines which step is highlighted as "current" and which ones
     * are rendered as "complete".
     */
    @api currentStep;

    /**
     * @type {string}
     * @description Value of the step the user has clicked/selected in the UI, before confirming
     * the change. When set, it overrides the visual highlight of `currentStep`.
     * Reset to null by the parent after a successful update.
     */
    @api selectedStep;

    /**
     * @type {Object.<string, string[]>}
     * @description Optional map of grouped step values. Allows collapsing multiple picklist values
     * into a single visual step on the path.
     *
     * Keys are the group label/value shown in the path.
     * Values are arrays of real picklist values that belong to the group.
     *
     * Behaviour:
     *   - If `currentStep` belongs to a group → that real value is shown instead of the group.
     *   - Otherwise → the group key is shown as a single step.
     *
     * Accepts a plain JS object (from parent JS) or a JSON string (from parent HTML attribute).
     *
     * @example
     * // In parent JS:
     * groupedValues = { Closed: ['Closed won', 'Discarded / Lost'] }
     */
    @api groupedValues;

    /**
     * @type {boolean}
     * @description Controls which rendering mode is used.
     *   - Omit or pass any truthy value → Lightning mode (`lightning-progress-indicator`).
     *   - Pass `false` → Custom SLDS mode (full markup control, no check icons on completed steps).
     *
     * Note: LWC boolean `@api` properties default to `false`, so the getter `renderLightningPath`
     * treats `undefined` (not passed) as Lightning mode.
     */
    @api useLightningPath;

    /**
     * @type {boolean}
     * @description When `true`, the action button is disabled. Typically bound to a parent getter
     * that checks whether a valid selection has been made.
     * @default false
     */
    @api disableMarkComplete = false;

    /**
     * @type {boolean}
     * @description When `true`, the action button is rendered. Set to `false` (default) to hide it
     * (e.g. for read-only path views).
     * @default false
     */
    @api displayButton = false;

    /**
     * @type {string}
     * @description Label displayed on the action button.
     * @default "Mark as Current Status of Action"
     */
    @api buttonLabel = "Mark as Current Status of Action";

    /**
     * @type {boolean}
     * @description When `true`, displays the Guidance for Success collapsible card.
     * @default false
     */
    @api hasGuidance = false;

    guidanceExpanded = true;

    get guidanceToggleIcon() {
        return this.guidanceExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get guidanceToggleAltText() {
        return this.guidanceExpanded ? 'Collapse Guidance' : 'Expand Guidance';
    }

    toggleGuidance() {
        this.guidanceExpanded = !this.guidanceExpanded;
    }

    /**
     * @returns {boolean} `true` when `lightning-progress-indicator` should be rendered.
     * Defaults to `true` unless `useLightningPath` is explicitly set to `false`.
     */
    get renderLightningPath() {
        return this.useLightningPath !== false;
    }

    /** @returns {string} Absolute URL to the SLDS check SVG icon. */
    get checkIconHref() {
        return '/_slds/icons/utility-sprite/svg/symbols.svg#check';
    }

    /**
     * @returns {Object.<string, string[]>} Normalised grouped values map.
     * Handles both plain object and JSON string inputs from `groupedValues`.
     */
    get groupedValuesMap() {
        if (!this.groupedValues) {
            return {};
        }

        if (typeof this.groupedValues === 'string') {
            try {
                const parsed = JSON.parse(this.groupedValues);
                return parsed && typeof parsed === 'object' ? parsed : {};
            } catch {
                return {};
            }
        }

        return typeof this.groupedValues === 'object' ? this.groupedValues : {};
    }

    /** @returns {[string, string[]][]} Iterable entries of the grouped values map. */
    get groupedValuesEntries() {
        return Object.entries(this.groupedValuesMap || {});
    }

    /**
     * Applies grouping rules to a list of steps.
     *
     * For each step:
     *   - If it belongs to a group and `currentStep` is also in that group → keep the real step
     *     only if it matches `currentStep` (shows the actual current value, not the group label).
     *   - If it belongs to a group and `currentStep` is NOT in that group → add the group key once
     *     as a representative step.
     *   - If it does not belong to any group → add it as-is.
     *
     * @param {Array} steps - Raw step array to process.
     * @returns {Array} Processed step array with grouping applied.
     */
    parseStepsValues(steps = []) {
        const parsedValues = [];

        for (const step of steps) {
            let wasGrouped = false;

            for (const [groupKey, values] of this.groupedValuesEntries) {
                const groupValues = Array.isArray(values) ? values : [];
                const isGroupedValue = groupValues.includes(step.value);

                if (!isGroupedValue) {
                    continue;
                }

                wasGrouped = true;
                const currentIsInThisGroup = groupValues.includes(this.currentStep);

                if (currentIsInThisGroup) {
                    if (this.currentStep === step.value) {
                        parsedValues.push(step);
                    }
                    continue;
                }

                if (!parsedValues.some((p) => p.value === groupKey)) {
                    parsedValues.push({
                        ...step,
                        value: groupKey,
                        label: groupKey
                    });
                }
            }

            if (!wasGrouped) {
                parsedValues.push(step);
            }
        }

        return parsedValues;
    }

    /**
     * @returns {Array} Final list of steps to render, after grouping and sorting.
     * Steps are sorted by `order` if at least one step has it defined;
     * otherwise the original array order is preserved.
     */
    get stepsForRender() {
        const parsed = this.parseStepsValues(this.steps || []);
        const hasOrder = parsed.some((s) => s.order != null);
        return hasOrder
            ? [...parsed].sort((a, b) => (a.order ?? Infinity) - (b.order ?? Infinity))
            : parsed;
    }

    /**
     * @returns {string} The `value` of the step that should appear highlighted.
     * Priority: `selectedStep` → `currentStep` → first step in the list.
     * Falls back gracefully if the active key is not present in the rendered steps
     * (e.g. when `groupedValues` hides it).
     */
    get activeStep() {
        const activeKey = this.selectedStep || this.currentStep;
        const steps = this.stepsForRender || [];

        if (steps.some((s) => s.value === activeKey)) {
            return activeKey;
        }

        if (steps.some((s) => s.value === this.currentStep)) {
            return this.currentStep;
        }

        return steps[0]?.value;
    }

    /**
     * @returns {string} Display label of the currently active step, shown in the stage area.
     */
    get selectedStepLabel() {
        const key = this.activeStep;
        return this.stepsForRender?.find((s) => s.value === key)?.label || '';
    }

    /**
     * @returns {Array} Enriched step list used by the custom SLDS path template.
     * Each step is extended with:
     *   - `liClass`: SLDS modifier classes (`slds-is-complete`, `slds-is-current`, etc.).
     *   - `ariaSelected`: accessibility attribute string.
     *   - `tabIndex`: `'0'` if the step is clickable, `'-1'` otherwise.
     *   - `isComplete`: `true` if the step precedes `currentStep` in the ordered list,
     *     used to render the step label instead of the check icon.
     */
    get stepsUi() {
        const steps = this.stepsForRender || [];
        const currentKey = this.currentStep;
        const selectedKey = this.activeStep;

        const currentIdx = steps.findIndex(s => s.value === currentKey);

        return steps.map((s, idx) => {
            const isCurrent = s.value === currentKey;
            const isSelected = s.value === selectedKey;
            const isComplete = currentIdx >= 0 && idx < currentIdx;

            let liClass = 'slds-path__item';

            // completo si está antes del current
            if (currentIdx >= 0 && idx < currentIdx) {
                liClass += ' slds-is-complete';
            } else {
                liClass += ' slds-is-incomplete';
            }

            // current tiene prioridad visual
            if (isCurrent) {
                liClass = 'slds-path__item slds-is-current slds-is-active';
            } else if (isSelected) {
                // seleccionado (pero no current)
                liClass += ' slds-is-active';
            }

            return {
                ...s,
                liClass,
                ariaSelected: isSelected ? 'true' : 'false',
                tabIndex: s.clickable ? '0' : '-1',
                isComplete
            };
        });
    }

    /**
     * Handles a click on any step in either render mode.
     * Reads the step value from `dataset.stepKey` (custom SLDS) or `event.target.value`
     * (lightning-progress-step), then fires a `stepselect` custom event with `{ stepKey }`.
     *
     * @param {Event} event - The click event from the step element.
     */
    handleStepClick(event) {
        if (event.currentTarget?.dataset?.stepKey) {
            event.preventDefault();
        }

        const stepKey =
            event.target?.value ||
            event.currentTarget?.value ||
            event.currentTarget?.dataset?.stepKey;
        if (!stepKey) return;

        const step = (this.stepsForRender || []).find((s) => s.value === stepKey);
        if(!step) return;
        this.dispatchEvent(new CustomEvent('stepselect', { detail: { stepKey } }));
    }

    /**
     * Fires a `markcomplete` custom event when the action button is clicked.
     * The parent is responsible for performing the actual record update.
     */
    handleMarkComplete() {
        this.dispatchEvent(new CustomEvent('markcomplete'));
    }
}