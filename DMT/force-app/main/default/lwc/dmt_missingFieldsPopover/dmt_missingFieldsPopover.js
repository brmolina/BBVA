import { LightningElement, api } from 'lwc';

const DEFAULT_DATA = { products: {}, opportunityInfo: [] };

// Key used by DMT_FieldsRequiredParser.parse() to group service paths that have no matching
// DMT_FieldsRequiredPassport__mdt record (e.g. a backend warning that hasn't been mapped to a
// tab yet). These fields have no tab/section to redirect to, so they're rendered as informational
// only (not clickable).
const UNMAPPED_TAB_KEY = 'unmapped';
const UNMAPPED_SECTION_LABEL = 'Other fields';
const UNMAPPED_SECTION_TOOLTIP = "These fields still need to be configured, so we can't redirect you to them automatically — you can search for them manually.";

// Converts a raw API field name (e.g. "mitigantType", "currencyId") into a
// human readable label (e.g. "Mitigant Type", "Currency Id"). Used only as a
// fallback when a leaf entry doesn't carry its own "label" (e.g. legacy data).
function humanizeFieldName(fieldName) {
    if (!fieldName) {
        return '';
    }
    const withSpaces = String(fieldName)
        .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
        .replace(/[_-]+/g, ' ')
        .trim();
    return withSpaces.replace(/\S+/g, (word) => word.charAt(0).toUpperCase() + word.slice(1));
}

/**
 * @description Reusable trigger + floating popover that lists pending/required fields.
 */
export default class Dmt_missingFieldsPopover extends LightningElement {
    @api title = 'Complete the fields';

    // Hierarchical structure coming from the form (as returned by
    // DMT_FieldsRequiredParser.parse()):
    // {
    //   products: { [productCode]: { [subsectionName]: Array<{ apiName, label }> } },
    //   opportunityInfo: Array<{ apiName, label }>
    // }
    @api data = DEFAULT_DATA;

    isOpen = false;
    _handleOutsideClick = this.handleOutsideClick.bind(this);

    // Flattens the hierarchical "data" structure into a single ordered list of
    // field descriptors, walking whatever tabs/keys actually exist in "data"
    // (no hardcoded "products"/"opportunityInfo" tab names). Any array found
    // along the way is treated as a list of { apiName, label } field entries;
    // any plain object is walked one level deeper (e.g. products -> productCode -> subsection).
    get allFields() {
        const source = this.data || DEFAULT_DATA;
        const flat = [];

        const walk = (node, path) => {
            if (Array.isArray(node)) {
                const isUnmapped = path[0] === UNMAPPED_TAB_KEY;
                node.forEach((entry) => {
                    const apiName = entry && typeof entry === 'object' ? entry.apiName : entry;
                    const label = (entry && typeof entry === 'object' && entry.label) || humanizeFieldName(apiName);
                    flat.push({
                        id: `${path.join('-')}-${apiName}`,
                        fieldName: apiName,
                        label,
                        sectionKey: path.join('-'),
                        sectionLabel: isUnmapped ? UNMAPPED_SECTION_LABEL : path.map(humanizeFieldName).join(' — '),
                        path,
                        pathJson: JSON.stringify(path),
                        isUnmapped
                    });
                });
            } else if (node && typeof node === 'object') {
                Object.keys(node).forEach((key) => walk(node[key], [...path, key]));
            }
        };

        Object.keys(source).forEach((key) => walk(source[key], [key]));

        return flat;
    }

    get hasFields() {
        return this.allFields.length > 0;
    }

    get resultsCount() {
        const count = this.allFields.length;
        return `${count} result${count === 1 ? '' : 's'}`;
    }

    // Groups the flattened fields by their section, preserving the order in
    // which each section was first encountered.
    get groupedFields() {
        const groups = [];
        const groupsBySection = new Map();
        this.allFields.forEach((field) => {
            let group = groupsBySection.get(field.sectionKey);
            if (!group) {
                group = {
                    key: field.sectionKey,
                    label: field.sectionLabel,
                    isUnmapped: field.isUnmapped,
                    tooltip: field.isUnmapped ? UNMAPPED_SECTION_TOOLTIP : null,
                    items: []
                };
                groupsBySection.set(field.sectionKey, group);
                groups.push(group);
            }
            group.items.push(field);
        });
        return groups;
    }

    handleToggle() {
        if (this.isOpen) {
            this.closePopover();
        } else {
            this.isOpen = true;
            document.addEventListener('click', this._handleOutsideClick);
        }
    }

    handleClose() {
        this.closePopover();
    }

    closePopover() {
        this.isOpen = false;
        document.removeEventListener('click', this._handleOutsideClick);
    }

    handleOutsideClick() {
        if (this.isOpen) {
            this.closePopover();
        }
    }

    handleContainerClick(event) {
        event.stopPropagation();
    }

    // Builds the "fieldsRequired" shaped payload for a single field, rebuilding
    // the exact nesting of keys ("path") that the field was found under in the
    // source "data" — no hardcoded tab names, works for any depth/shape. The
    // leaf is a single-element array with the { apiName, label } entry, matching
    // the shape emitted by DMT_FieldsRequiredParser.parse().
    buildFieldsRequiredForPath(path, apiName, label) {
        const fieldsRequired = {};
        let cursor = fieldsRequired;
        path.forEach((key, index) => {
            if (index === path.length - 1) {
                cursor[key] = [{ apiName, label }];
            } else {
                cursor[key] = {};
                cursor = cursor[key];
            }
        });
        return { fieldsRequired };
    }

    // NOTE: events prefixed with "notify" propagate up to the parent container
    // (dmt_opp_tab) where they are ultimately handled.
    handleFieldClick(event) {
        event.preventDefault();
        const { fieldname: fieldName, path, label } = event.currentTarget.dataset;
        const parsedPath = path ? JSON.parse(path) : [fieldName];
        // Unmapped fields (no DMT_FieldsRequiredPassport__mdt record) have no real tab to
        // redirect to, so clicking them is a no-op.
        if (parsedPath[0] === UNMAPPED_TAB_KEY) return;
        const detail = this.buildFieldsRequiredForPath(parsedPath, fieldName, label);
        // eslint-disable-next-line no-console
        console.log('dmt_missingFieldsPopover fieldsRequired', JSON.stringify(detail));
        this.dispatchEvent(
            new CustomEvent('passportfieldswarning', {
                detail,
                bubbles: true,
                composed: true
            })
        );
        this.closePopover();
    }

    handleHighlightAll(event) {
        event.preventDefault();
        const detail = { fieldsRequired: this.data };
        // eslint-disable-next-line no-console
        console.log('dmt_missingFieldsPopover fieldsRequired', JSON.stringify(detail));
        this.dispatchEvent(
            new CustomEvent('passportfieldswarning', {
                detail,
                bubbles: true,
                composed: true
            })
        );
        this.closePopover();
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._handleOutsideClick);
    }
}