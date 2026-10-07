// Converts an HTML snapshot version (produced by DMT_ViewController.loadComponentsForView)
// into the same {components:[{name, content:[...]}]} shape the JSON snapshot diff consumes.
//
// Two parsing paths:
//  1. Tagged path — uses data-dmt-* attributes (requires DMT_FormattingUtils tagging, Plan Step 1).
//  2. Heuristic path — parses the untagged renderer HTML by structural patterns:
//       <h2>/<h3>            → title block
//       <table> where first data cell has <strong>Label:</strong>  → values2 (field table)
//       <table> with colspan title row or gray-bg header row       → table (data table)

const TRAFFIC_COLOR_HEX = {
    RED: '#D73F52',
    YELLOW: '#F8CC52',
    GREEN: '#47AD5A',
    GREY: '#BDBDBD',
    WHITE: '#FFFFFF'
};

export function normalizeHtmlToComponents(htmlString) {
    if (!htmlString) {
        return { components: [] };
    }

    const doc = new DOMParser().parseFromString(htmlString, 'text/html');
    const sectionEls = Array.from(doc.querySelectorAll('[data-dmt-component="true"]'));

    if (sectionEls.length === 0) {
        // Whole-document fallback: no recognizable tagging at all.
        const text = ((doc.body && doc.body.textContent) || '').trim();
        return {
            components: [{
                name: 'Document',
                content: text ? [{ type: 'text', text }] : []
            }]
        };
    }

    const components = sectionEls.map((sectionEl) => ({
        name: sectionEl.getAttribute('data-dmt-component-name') || 'Untitled Section',
        content: extractSectionContent(sectionEl)
    }));

    return { components };
}

function extractSectionContent(sectionEl) {
    const content = [];
    walkBlocks(sectionEl, content);

    // Per-section fallback: nothing recognized — diff as one text block.
    if (content.length === 0) {
        const text = (sectionEl.textContent || '').trim();
        if (text) {
            content.push({ type: 'text', text });
        }
    }

    return content;
}

function walkBlocks(node, content) {
    Array.from(node.children || []).forEach((el) => {
        // --- Tagged path (data-dmt-* attributes) ---
        if (isRealTable(el)) {
            extractRealTable(el, content);
        } else if (isFieldTable(el)) {
            extractFieldTable(el, content);
        } else if (isTitleBlock(el)) {
            const text = (el.textContent || '').trim();
            if (text) content.push({ type: 'title', text });
        }
        // --- Heuristic path (untagged renderer HTML) ---
        else if (isHeadingEl(el)) {
            const text = (el.textContent || '').trim();
            if (text) content.push({ type: 'title', text });
        } else if (el.tagName === 'TABLE') {
            if (looksLikeFieldTable(el)) {
                extractHeuristicFieldTable(el, content);
            } else {
                extractHeuristicDataTable(el, content);
            }
        } else {
            walkBlocks(el, content);
        }
    });
}

// ─── Tagged element detectors ─────────────────────────────────────────────────

function isRealTable(el) {
    return el.tagName === 'TABLE' && el.getAttribute('data-dmt-table') === 'true';
}

function isFieldTable(el) {
    return el.tagName === 'TABLE' && !!el.querySelector('[data-dmt-row="field"]');
}

function isTitleBlock(el) {
    return el.getAttribute('data-dmt-row') === 'title';
}

function isHeadingEl(el) {
    return el.tagName === 'H1' || el.tagName === 'H2' || el.tagName === 'H3';
}

// ─── Tagged field / values2 tables ───────────────────────────────────────────

function extractFieldTable(tableEl, content) {
    const body = Array.from(tableEl.querySelectorAll('[data-dmt-row="field"]'))
        .map((fieldEl) => buildFieldRow(fieldEl))
        .filter((row) => row.length > 0);

    if (body.length > 0) {
        content.push({ type: 'values2', body });
    }
}

function buildFieldRow(fieldEl) {
    const pairedCells = Array.from(fieldEl.querySelectorAll('[data-dmt-pair]'));
    if (pairedCells.length > 0) {
        const pairs = { 1: {}, 2: {} };
        pairedCells.forEach((cell) => {
            const pairKey = cell.getAttribute('data-dmt-pair');
            const labelHost = cell.hasAttribute('data-dmt-label') ? cell : cell.querySelector('[data-dmt-label]');
            const valueHost = cell.getAttribute('data-dmt-value') === 'true' ? cell : cell.querySelector('[data-dmt-value="true"]');
            if (labelHost) {
                pairs[pairKey].name = labelHost.getAttribute('data-dmt-label');
            }
            if (valueHost) {
                pairs[pairKey].value = extractFieldValue(valueHost);
            }
        });

        const row = [];
        if (pairs[1].name !== undefined) row.push({ name: pairs[1].name, value: pairs[1].value });
        if (pairs[2].name !== undefined) row.push({ name: pairs[2].name, value: pairs[2].value });
        return row;
    }

    const labelEl = fieldEl.querySelector('[data-dmt-label]');
    if (!labelEl) return [];
    const valueEl = fieldEl.querySelector('[data-dmt-value="true"]');
    return [{ name: labelEl.getAttribute('data-dmt-label'), value: valueEl ? extractFieldValue(valueEl) : '' }];
}

function extractFieldValue(valueEl) {
    if (valueEl.hasAttribute('data-dmt-checked')) {
        return valueEl.getAttribute('data-dmt-checked') === 'true' ? 'Yes' : 'No';
    }
    return (valueEl.textContent || '').trim();
}

// ─── Tagged real data tables ──────────────────────────────────────────────────

function extractRealTable(tableEl, content) {
    const titleRow = tableEl.querySelector('[data-dmt-table-title="true"]');
    if (titleRow) {
        const titleText = (titleRow.textContent || '').trim();
        if (titleText) {
            content.push({ type: 'title', text: titleText });
        }
    }

    const headerCells = Array.from(tableEl.querySelectorAll('[data-dmt-table-header="true"] [data-dmt-header-cell="true"]'));
    const head = headerCells.length > 0 ? [headerCells.map((c) => (c.textContent || '').trim())] : [];

    const body = Array.from(tableEl.querySelectorAll('[data-dmt-table-row="true"]')).map((rowEl) =>
        Array.from(rowEl.querySelectorAll('[data-dmt-cell="true"]')).map((cellEl) => extractTableCell(cellEl))
    );

    content.push({ type: 'table', head, body });
}

function extractTableCell(cellEl) {
    const trafficEl = cellEl.querySelector('[data-dmt-traffic]');
    if (trafficEl) {
        return buildTrafficLightCell(trafficEl);
    }
    return (cellEl.textContent || '').trim();
}

function buildTrafficLightCell(trafficEl) {
    const activeColor = (trafficEl.getAttribute('data-dmt-traffic') || 'GREY').toUpperCase();
    const mode = trafficEl.getAttribute('data-dmt-traffic-mode') || 'single';

    if (mode === 'triple') {
        const isRecognized = ['RED', 'YELLOW', 'GREEN'].includes(activeColor);
        const colorFor = (slot) =>
            activeColor === slot ? TRAFFIC_COLOR_HEX[slot] : (isRecognized ? TRAFFIC_COLOR_HEX.GREY : TRAFFIC_COLOR_HEX.WHITE);
        return {
            type: 'custom',
            custom: [
                { styles: { textColor: colorFor('RED') }, content: 'l' },
                { styles: { textColor: colorFor('YELLOW') }, content: 'l' },
                { styles: { textColor: colorFor('GREEN') }, content: 'l' }
            ]
        };
    }

    return {
        type: 'custom',
        custom: [{ styles: { textColor: TRAFFIC_COLOR_HEX[activeColor] || TRAFFIC_COLOR_HEX.GREY }, content: 'l' }]
    };
}

// ─── Heuristic parsing for untagged renderer HTML ─────────────────────────────
//
// The renderers produce a consistent structure:
//   Field tables:  <tr><td><strong>Label:</strong></td><td>value</td>...</tr>
//   Data tables:   optional colspan title row + gray-bg header row + plain data rows

function looksLikeFieldTable(tableEl) {
    const firstRow = tableEl.querySelector('tr');
    if (!firstRow) return false;
    const cells = Array.from(firstRow.querySelectorAll('td'));
    if (cells.length === 0) return false;
    // A colspan row is a data-table title, not a field row.
    if (cells.length === 1 && cells[0].getAttribute('colspan')) return false;
    const firstStrong = cells[0].querySelector('strong');
    if (!firstStrong) return false;
    // Field labels always end with ':' (e.g. "Line Id:", "Status:").
    return (firstStrong.textContent || '').trim().endsWith(':');
}

function extractHeuristicFieldTable(tableEl, content) {
    const body = Array.from(tableEl.querySelectorAll('tr'))
        .map(tr => buildHeuristicFieldRow(tr))
        .filter(row => row.length > 0);
    if (body.length > 0) {
        content.push({ type: 'values2', body });
    }
}

function buildHeuristicFieldRow(trEl) {
    const cells = Array.from(trEl.querySelectorAll('td'));
    if (cells.length === 0) return [];
    const pairs = [];
    let i = 0;
    while (i < cells.length) {
        const strongEl = cells[i].querySelector('strong');
        if (!strongEl) break;
        const name = (strongEl.textContent || '').trim();
        const valueCell = cells[i + 1];
        const value = valueCell ? (valueCell.textContent || '').trim() : '';
        pairs.push({ name, value });
        i += 2;
    }
    return pairs;
}

function extractHeuristicDataTable(tableEl, content) {
    const rows = Array.from(tableEl.querySelectorAll('tr'));
    if (rows.length === 0) return;

    let titleText = null;
    let head = [];
    let bodyRows = [];
    let headerParsed = false;

    for (const tr of rows) {
        const cells = Array.from(tr.querySelectorAll('td'));
        if (cells.length === 0) continue;

        // Title row: single cell with colspan (e.g. "SELECTED CLIENT" spanning all columns).
        if (cells.length === 1 && cells[0].getAttribute('colspan')) {
            const text = (cells[0].textContent || '').trim();
            if (text) titleText = text;
            continue;
        }

        // Header row: cells carry a background-color style (gray tint from renderHtmlDataTable).
        if (!headerParsed) {
            const firstStyle = cells[0].getAttribute('style') || '';
            if (firstStyle.includes('background-color') || firstStyle.includes('background:')) {
                head = [cells.map(c => (c.textContent || '').trim())];
                headerParsed = true;
                continue;
            }
        }

        // Data row — use extractTableCell so traffic-light cells (data-dmt-traffic) are captured.
        bodyRows.push(cells.map(c => extractTableCell(c)));
    }

    if (titleText) {
        content.push({ type: 'title', text: titleText });
    }
    if (head.length > 0 || bodyRows.length > 0) {
        content.push({ type: 'table', head, body: bodyRows });
    }
}