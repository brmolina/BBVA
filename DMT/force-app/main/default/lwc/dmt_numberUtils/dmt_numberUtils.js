/**
 * @description Shared numeric parsing utilities for LWC data tables.
 *              Centralizes the K/M/B/T shorthand + locale decimal parsing logic
 *              previously duplicated across dmt_risk_limit_table, dmt_opp_product_table_tenors
 *              and dmt_table_tenors.
 */

/**
 * Parses a display string like "1,234.50", "1M", "1.5K" into a plain number.
 * @param {*} value          Raw display value (string or number).
 * @param {boolean} allowSuffix  Whether to interpret trailing K/M/B/T as a multiplier.
 * @returns {number|null}    Parsed numeric value, or null if not parseable.
 */
export function parseAbbreviatedNumber(value, allowSuffix = true) {
    if (value === null || value === undefined || value === '') return null;
    if (typeof value === 'number') return Number.isNaN(value) ? null : value;

    let raw = String(value).trim().toUpperCase().replace(/\s+/g, '').replace(/[€$]/g, '');
    let multiplier = 1;

    if (allowSuffix) {
        const suffixMatch = raw.match(/([KMBT])$/);
        if (suffixMatch) {
            const multipliers = { K: 1e3, M: 1e6, B: 1e9, T: 1e12 };
            multiplier = multipliers[suffixMatch[1]] || 1;
            raw = raw.slice(0, -1);
        }
    }

    const commaCount = (raw.match(/,/g) || []).length;
    const dotCount = (raw.match(/\./g) || []).length;

    if (commaCount && dotCount) {
        const lastComma = raw.lastIndexOf(',');
        const lastDot = raw.lastIndexOf('.');
        raw = lastComma > lastDot
            ? raw.replace(/\./g, '').replace(',', '.')
            : raw.replace(/,/g, '');
    } else if (commaCount === 1 && raw.split(',')[1].length <= 2) {
        raw = raw.replace(',', '.');
    } else if (commaCount) {
        raw = raw.replace(/,/g, '');
    } else if (dotCount > 1) {
        raw = raw.replace(/\./g, '');
    }

    const numeric = parseFloat(raw);
    return Number.isNaN(numeric) ? null : numeric * multiplier;
}