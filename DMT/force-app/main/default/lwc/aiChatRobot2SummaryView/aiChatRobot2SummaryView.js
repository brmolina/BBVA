import { LightningElement, api, track } from 'lwc';
import aiChatRobot2_Empty_Summary from '@salesforce/label/c.aiChatRobot2_Empty_Summary';
import aiChatRobot2_SummaryTitle from '@salesforce/label/c.aiChatRobot2_SummaryTitle';
import aiChatRobot2_GeneratingReport from '@salesforce/label/c.aiChatRobot2_GeneratingReport';
import aiChatRobot2_FullContent from '@salesforce/label/c.aiChatRobot2_FullContent';
import aiChatRobot2_Introduction from '@salesforce/label/c.aiChatRobot2_Introduction';
function escapeHtml(str) {
    return str.replace(/[&<>"']/g, function (tag) {
        const charsToReplace = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;'
        };
        return charsToReplace[tag] || tag;
    });
}
/**
 * Process inline markdown (bold, italic, bold+italic) within already-escaped HTML text.
 * Operates on escaped content so we use literal & sequences for special chars.
 */
function processInlineMarkdown(text) {
    // Bold + italic: ***text*** or ___text___
    text = text.replace(/\*\*\*(.*?)\*\*\*/gim, '<strong><em>$1</em></strong>');
    // Bold: **text**
    text = text.replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>');
    // Italic: *(text)* — use non-greedy, avoid matching bold remnants
    text = text.replace(/\*(.*?)\*/gim, '<em>$1</em>');
    return text;
}

/**
 * Parse the alignment from a markdown separator cell (e.g. "---", ":---", "---:", ":---:").
 * Returns a style string or empty string.
 */
function parseColumnAlignment(separatorCell) {
    const cell = separatorCell.trim();
    const left  = cell.startsWith(':');
    const right = cell.endsWith(':');
    if (left && right) return 'style="text-align:center"';
    if (right)         return 'style="text-align:right"';
    if (left)          return 'style="text-align:left"';
    return '';
}

function markdownToHtml(md) {
    // Work line-by-line so we can handle each construct cleanly
    const lines = md.replace(/\r\n/g, '\n').split('\n');
    const output = [];
    let i = 0;

    while (i < lines.length) {
        const line = lines[i];

        // ── Horizontal rule: a line of only ---, ***, ___ (with optional spaces) ──
        if (/^\s*([-*_])\s*\1\s*\1[\s\1]*$/.test(line)) {
            output.push('<hr>');
            i++;
            continue;
        }

        // ── Markdown table: line starts and ends with | and next line is separator ──
        if (/^\|.+\|/.test(line) && i + 1 < lines.length && /^\|[\s\-:|]+\|/.test(lines[i + 1])) {
            // Collect all table lines
            const tableLines = [line];
            const separatorLine = lines[i + 1];
            let j = i + 2;
            while (j < lines.length && /^\|.+\|/.test(lines[j])) {
                tableLines.push(lines[j]);
                j++;
            }

            // Parse header cells
            const parseRow = (rowLine) => {
                const trimmed = rowLine.trim();
                const withoutEdges = trimmed.replace(/^\|/, '').replace(/\|$/, '');
                return withoutEdges.split('|').map(c => c.trim());
            };

            const headers = parseRow(line);

            // Parse separator to extract alignments
            const separatorCells = parseRow(separatorLine);
            const alignments = separatorCells.map(parseColumnAlignment);

            // Build table HTML (SLDS classes)
            let tableHtml = '<div class="slds-scrollable_x">\n';
            tableHtml += '<table class="slds-table slds-table_bordered slds-table_cell-buffer slds-table_striped">\n';
            tableHtml += '<thead>\n<tr class="slds-line-height_reset">\n';
            headers.forEach((header, idx) => {
                const align = alignments[idx] ? ` ${alignments[idx]}` : '';
                const cellContent = processInlineMarkdown(escapeHtml(header));
                tableHtml += `<th class="slds-text-title_caps" scope="col"${align}>${cellContent}</th>\n`;
            });
            tableHtml += '</tr>\n</thead>\n<tbody>\n';

            // Body rows (tableLines[0] is header, rest are body)
            for (let r = 1; r < tableLines.length; r++) {
                const cells = parseRow(tableLines[r]);
                tableHtml += '<tr class="slds-hint-parent">\n';
                cells.forEach((cell, idx) => {
                    const align = alignments[idx] ? ` ${alignments[idx]}` : '';
                    const cellContent = processInlineMarkdown(escapeHtml(cell));
                    const headerLabel = escapeHtml(headers[idx] || '');
                    tableHtml += `<td data-label="${headerLabel}"${align}>${cellContent}</td>\n`;
                });
                tableHtml += '</tr>\n';
            }
            tableHtml += '</tbody>\n</table>\n</div>';
            output.push(`<div style="margin-top:12px;margin-bottom:12px;">${tableHtml}</div>`);
            i = j;
            continue;
        }

        // ── Headings ──
        const h3Match = line.match(/^### (.+)$/);
        if (h3Match) {
            output.push(`<h3 class="slds-text-heading_small slds-m-top_medium">${processInlineMarkdown(escapeHtml(h3Match[1]))}</h3>`);
            i++; continue;
        }
        const h2Match = line.match(/^## (.+)$/);
        if (h2Match) {
            output.push(`<h2 class="slds-text-heading_medium slds-m-top_medium">${processInlineMarkdown(escapeHtml(h2Match[1]))}</h2>`);
            i++; continue;
        }
        const h1Match = line.match(/^# (.+)$/);
        if (h1Match) {
            output.push(`<h1 class="slds-text-heading_large slds-m-top_medium">${processInlineMarkdown(escapeHtml(h1Match[1]))}</h1>`);
            i++; continue;
        }

        // ── Blockquote ──
        const bqMatch = line.match(/^> (.+)$/);
        if (bqMatch) {
            output.push(`<blockquote class="slds-text-color_weak slds-p-left_small slds-m-vertical_x-small" style="border-left: 3px solid #0176d3; padding-left: 12px;">${processInlineMarkdown(escapeHtml(bqMatch[1]))}</blockquote>`);
            i++; continue;
        }

        // ── Unordered list block (collect consecutive - items) ──
        if (/^[-*]\s+/.test(line)) {
            const listItems = [];
            while (i < lines.length && /^[-*]\s+/.test(lines[i])) {
                const itemText = lines[i].replace(/^[-*]\s+/, '');
                listItems.push(`<li class="slds-m-left_large">${processInlineMarkdown(escapeHtml(itemText))}</li>`);
                i++;
            }
            output.push(`<ul class="slds-list_dotted slds-m-vertical_small">${listItems.join('')}</ul>`);
            continue;
        }

        // ── Ordered list block (collect consecutive N. items) ──
        if (/^\d+\.\s+/.test(line)) {
            const listItems = [];
            while (i < lines.length && /^\d+\.\s+/.test(lines[i])) {
                const itemText = lines[i].replace(/^\d+\.\s+/, '');
                listItems.push(`<li class="slds-m-left_large">${processInlineMarkdown(escapeHtml(itemText))}</li>`);
                i++;
            }
            output.push(`<ol class="slds-list_ordered slds-m-vertical_small">${listItems.join('')}</ol>`);
            continue;
        }

        // ── Blank line ──
        if (line.trim() === '') {
            output.push('');
            i++;
            continue;
        }

        // ── Regular paragraph line ──
        output.push(`<p class="slds-m-vertical_x-small">${processInlineMarkdown(escapeHtml(line))}</p>`);
        i++;
    }

    return output.join('\n');
}

export default class AiChatRobot2SummaryView extends LightningElement {
    @api isOpen = false;
    @track summaryMessages = [];
    @track summaryBlocks = [];
    @track showMessageId = false; // Set to true for debugging
    @track isLoading = false; // Loading state
    @track copiedSectionId = null;
    @track copiedAll = false;
    @track hoverHighlightSectionId = null;
    
    // Resizing properties
    isResizing = false;
    startX = 0;
    startWidth = 400;
    minWidth = 300;
    maxWidth = 800;
    copyResetTimer = null;
    hoverHighlightTimer = null;
    label = {
        aiChatRobot2_Empty_Summary,
        aiChatRobot2_SummaryTitle,
        aiChatRobot2_GeneratingReport,
        aiChatRobot2_FullContent,
        aiChatRobot2_Introduction
    };

    /**
     * Public method to show the summary
     * @param {Object} data - { messageId, content }
     */

    @api
    showSummary(data) {
        // Desactivar estado de carga cuando se reciben datos
        this.isLoading = false;
        
        // Permitir recibir un array de mensajes o un solo mensaje
        let newMessages = [];
        if (Array.isArray(data)) {
            newMessages = data;
        } else if (data && typeof data === 'object') {
            newMessages = [data];
        }
        // Fusionar todos los mensajes únicos por messageId
        // Fusionar mensajes nuevos con los existentes, sin perder los anteriores
        const uniqueMap = new Map();
        // Primero, agregar todos los mensajes ya existentes
        this.summaryMessages.forEach(msg => {
            if (msg && msg.messageId) {
                uniqueMap.set(msg.messageId, msg);
            }
        });
        // Luego, agregar/actualizar con los nuevos mensajes
        newMessages.forEach(msg => {
            if (msg && msg.messageId) {
                uniqueMap.set(msg.messageId, msg);
            }
        });
        this.summaryMessages = Array.from(uniqueMap.values());
        this.summaryBlocks = this._buildSummaryBlocks(this.summaryMessages);
        this.isOpen = true;
        // Scroll al inicio del summary para que el usuario lea desde el principio
        setTimeout(() => {
            const el = this.template.querySelector('.sidebar-content');
            if (el) el.scrollTop = 0;
        }, 100);
        console.log('Summary sidebar opened with data:', data);
    }

    /**
     * Public method to show loading state
     */
    @api
    showLoading() {
        this.isLoading = true;
        this.summaryMessages = [];
        this.summaryBlocks = [];
        this.isOpen = true;
        console.log('Summary sidebar showing loading state');
    }

    /**
     * Public method to hide the summary
     */
    @api
    hideSummary() {
        this.isOpen = false;
    }

    /**
     * Public method to close and clear the summary
     */
    @api
    closeSummary() {
        this.isOpen = false;
        // No borramos los mensajes acumulados
    }

    /**
     * Handle close button click
     */
    handleClose() {
        this.closeSummary();
        
        // Dispatch event to notify parent
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
     * Computed property for container CSS classes
     */
    get containerClass() {
        return `summary-sidebar-container ${this.isOpen ? 'open' : ''}`;
    }

    renderedCallback() {
        // Render markdown for each summary block
        this.summaryBlocks.forEach((block, idx) => {
            const el = this.template.querySelector(`.summary-block[data-idx="${idx}"] .text`);
            if (el && block.renderContent) {
                const html = markdownToHtml(block.renderContent);
                if (el.innerHTML !== html) {
                    el.innerHTML = html;
                }
            }
        });
    }

    // ---- SUMMARY SECTION COPY - START (portable block) ----
    _buildSummaryBlocks(messages) {
        const blocks = [];
        (Array.isArray(messages) ? messages : []).forEach((msg) => {
            const sections = this._parseSummarySections(msg?.content || '');
            sections.forEach((section, sectionIndex) => {
                if (!section.renderContent) return; // skip empty sections
                blocks.push({
                    id: `${msg?.messageId || 'summary'}-${sectionIndex}`,
                    messageId: msg?.messageId,
                    title: section.title,
                    renderContent: section.renderContent,
                    copyContent: section.copyContent
                });
            });
        });
        return blocks;
    }

    _asSingleSection(content, title) {
        const normalized = this._normalizeCopyText(content);
        return [{
            title: title || this.label.aiChatRobot2_FullContent,
            renderContent: normalized,
            copyContent: normalized
        }];
    }

    _extractHeadings(lines) {
        return lines.reduce((acc, line, idx) => {
            const m = line.match(/^(#{1,6})\s+(.+)$/);
            if (m) {
                acc.push({ idx, level: m[1].length, title: m[2].trim() });
            }
            return acc;
        }, []);
    }

    _parseSummarySections(content) {
        const normalized = String(content || '').replace(/\r\n/g, '\n').trim();
        if (!normalized) return [];

        const lines = normalized.split('\n');
        const headings = this._extractHeadings(lines);
        if (!headings.length) return this._asSingleSection(normalized);

        const splitLevel = headings.some((h) => h.level === 3)
            ? 3
            : Math.min(...headings.map((h) => h.level));
        const splitHeadings = headings.filter((h) => h.level === splitLevel);
        if (!splitHeadings.length) return this._asSingleSection(normalized);

        const sections = [];
        const intro = lines.slice(0, splitHeadings[0].idx).join('\n').trim();
        if (intro) {
            sections.push({
                title: this.label.aiChatRobot2_Introduction,
                renderContent: intro,
                copyContent: this._normalizeCopyText(intro)
            });
        }

        splitHeadings.forEach((heading, index) => {
            const start = heading.idx + 1;
            const end = index < splitHeadings.length - 1 ? splitHeadings[index + 1].idx : lines.length;
            const body = lines.slice(start, end).join('\n').trim();
            const header = `${'#'.repeat(splitLevel)} ${heading.title}`;
            sections.push({
                title: heading.title,
                renderContent: body,
                copyContent: this._normalizeCopyText(body ? `${header}\n\n${body}` : header)
            });
        });

        return sections.length ? sections : this._asSingleSection(normalized);
    }

    _normalizeCopyText(text) {
        return String(text || '')
            .replace(/\r\n/g, '\n')
            .replace(/[ \t]+\n/g, '\n')
            .replace(/\n{3,}/g, '\n\n')
            .trim();
    }

    handleCopyAll() {
        const text = this._normalizeCopyText(
            this.summaryBlocks.map((block) => block.copyContent).join('\n\n')
        );
        this._copyAndMark(text, { copiedAll: true, copiedSectionId: null });
    }

    handleCopySection(event) {
        const blockId = event?.currentTarget?.dataset?.blockId;
        const block = this.summaryBlocks.find((item) => item.id === blockId);
        if (!block) return;
        this._copyAndMark(block.copyContent, { copiedAll: false, copiedSectionId: block.id });
    }

    _copyAndMark(text, state) {
        if (!text) return;
        this._copyText(text, () => {
            this.copiedAll = state.copiedAll;
            this.copiedSectionId = state.copiedSectionId;
            this._scheduleCopyReset();
        });
    }

    _copyText(text, onSuccess) {
        const cleanText = this._normalizeCopyText(text);
        if (!cleanText) return;

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(cleanText)
                .then(() => {
                    if (typeof onSuccess === 'function') onSuccess();
                })
                .catch(() => this._copyTextFallback(cleanText, onSuccess));
            return;
        }
        this._copyTextFallback(cleanText, onSuccess);
    }

    _copyTextFallback(text, onSuccess) {
        const area = document.createElement('textarea');
        area.value = text;
        area.setAttribute('readonly', '');
        area.style.position = 'fixed';
        area.style.opacity = '0';
        document.body.appendChild(area);
        area.select();
        try {
            const ok = document.execCommand('copy');
            if (ok && typeof onSuccess === 'function') onSuccess();
        } catch (e) {
            // No-op
        } finally {
            document.body.removeChild(area);
        }
    }

    _scheduleCopyReset() {
        if (this.copyResetTimer) clearTimeout(this.copyResetTimer);
        this.copyResetTimer = setTimeout(() => {
            this.copiedSectionId = null;
            this.copiedAll = false;
            this.copyResetTimer = null;
        }, 1600);
    }

    get summaryTitle() {
        // Extract the first # heading from the content, fallback to label
        for (const msg of this.summaryMessages) {
            const content = msg?.content || '';
            const match = content.match(/^#\s+(.+)$/m);
            if (match) return match[1].trim();
        }
        return this.label.aiChatRobot2_SummaryTitle;
    }

    get hasSummaryBlocks() {
        return Array.isArray(this.summaryBlocks) && this.summaryBlocks.length > 0;
    }

    get copyAllLabel() {
        return this.copiedAll ? 'Copied' : 'Copy full';
    }

    get summaryBlocksWithState() {
        return this.summaryBlocks.map((block) => ({
            ...block,
            copyLabel: this.copiedSectionId === block.id ? 'Copied' : 'Copy section',
            rowClass: `content-section summary-block${this.hoverHighlightSectionId === block.id ? ' copy-hover-target' : ''}`
        }));
    }

    get showCopyAllInHeader() {
        return !this.isLoading && this.hasSummaryBlocks;
    }

    handleSectionCopyHoverIn(event) {
        const blockId = event?.currentTarget?.dataset?.blockId;
        if (!blockId) return;
        if (this.hoverHighlightTimer) {
            clearTimeout(this.hoverHighlightTimer);
        }
        this.hoverHighlightTimer = setTimeout(() => {
            this.hoverHighlightSectionId = blockId;
            this.hoverHighlightTimer = null;
        }, 500);
    }

    handleSectionCopyHoverOut() {
        if (this.hoverHighlightTimer) {
            clearTimeout(this.hoverHighlightTimer);
            this.hoverHighlightTimer = null;
        }
        this.hoverHighlightSectionId = null;
    }
    // ---- SUMMARY SECTION COPY - END ----

    /**
     * Handle mouse down on resizer
     */
    handleMouseDown(event) {
        event.preventDefault();
        this.isResizing = true;
        this.startX = event.clientX;
        this.startWidth = this.template.host.offsetWidth;
        
        // Add event listeners to document
        document.addEventListener('mousemove', this.handleMouseMove);
        document.addEventListener('mouseup', this.handleMouseUp);
        
        // Prevent text selection during resize
        document.body.style.userSelect = 'none';
        document.body.style.cursor = 'col-resize';
    }

    /**
     * Handle touch start on resizer
     */
    handleTouchStart(event) {
        if (event.touches.length === 1) {
            this.isResizing = true;
            this.startX = event.touches[0].clientX;
            this.startWidth = this.template.host.offsetWidth;
            
            document.addEventListener('touchmove', this.handleTouchMove);
            document.addEventListener('touchend', this.handleTouchEnd);
        }
    }

    /**
     * Handle mouse move during resize
     */
    handleMouseMove = (event) => {
        if (!this.isResizing) return;
        
        const deltaX = this.startX - event.clientX;
        const newWidth = Math.max(this.minWidth, Math.min(this.maxWidth, this.startWidth + deltaX));
        
        // Update CSS variable in parent container
        this.updateSummaryWidth(newWidth);
    }

    /**
     * Handle touch move during resize
     */
    handleTouchMove = (event) => {
        if (!this.isResizing || event.touches.length !== 1) return;
        
        const deltaX = this.startX - event.touches[0].clientX;
        const newWidth = Math.max(this.minWidth, Math.min(this.maxWidth, this.startWidth + deltaX));
        
        this.updateSummaryWidth(newWidth);
    }

    /**
     * Handle mouse up to stop resizing
     */
    handleMouseUp = () => {
        if (this.isResizing) {
            this.isResizing = false;
            document.removeEventListener('mousemove', this.handleMouseMove);
            document.removeEventListener('mouseup', this.handleMouseUp);
            document.body.style.userSelect = '';
            document.body.style.cursor = '';
        }
    }

    /**
     * Handle touch end to stop resizing
     */
    handleTouchEnd = () => {
        if (this.isResizing) {
            this.isResizing = false;
            document.removeEventListener('touchmove', this.handleTouchMove);
            document.removeEventListener('touchend', this.handleTouchEnd);
        }
    }

    /**
     * Update summary width via custom event
     */
    updateSummaryWidth(width) {
        this.dispatchEvent(new CustomEvent('resize', {
            detail: { width }
        }));
    }

    /**
     * Cleanup event listeners on disconnect
     */
    disconnectedCallback() {
        document.removeEventListener('mousemove', this.handleMouseMove);
        document.removeEventListener('mouseup', this.handleMouseUp);
        document.removeEventListener('touchmove', this.handleTouchMove);
        document.removeEventListener('touchend', this.handleTouchEnd);
        if (this.copyResetTimer) {
            clearTimeout(this.copyResetTimer);
            this.copyResetTimer = null;
        }
        if (this.hoverHighlightTimer) {
            clearTimeout(this.hoverHighlightTimer);
            this.hoverHighlightTimer = null;
        }
        document.body.style.userSelect = '';
        document.body.style.cursor = '';
    }
}