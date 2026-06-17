/* eslint-disable one-var,no-console,no-undef,no-underscore-dangle,class-methods-use-this,sort-imports,id-length,no-magic-numbers,sort-keys*/

import { LightningElement, api, track } from 'lwc';
import aiChatRobot2_GeneratingReport from '@salesforce/label/c.aiChatRobot2_GeneratingReport';
import aiChatRobot2_ReportReady from '@salesforce/label/c.aiChatRobot2_ReportReady';

/* ── Markdown → HTML (same logic as SummaryView) ──────────────── */
function escapeHtml(str) {
    return str.replace(/[&<>"']/g, tag => {
        const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
        return map[tag] || tag;
    });
}

function markdownToHtml(md) {
    let html = md;
    const tableRegex = /^\|(.+)\|\s*\n\|[\s\-:|]+\|\s*\n((?:\|.+\|\s*\n?)+)/gm;
    html = html.replace(tableRegex, (_match, headerRow, bodyRows) => {
        const headers = headerRow.trim().split('|').map(h => h.trim()).filter(h => h.length > 0);
        const rows = bodyRows.trim().split('\n')
            .map(row => {
                let r = row.trim();
                if (r.startsWith('|')) r = r.substring(1);
                if (r.endsWith('|')) r = r.substring(0, r.length - 1);
                return r.split('|').map(c => c.trim());
            })
            .filter(r => r.length > 0);

        let t = '<div class="report-table-wrap"><table class="report-table"><thead><tr>';
        headers.forEach(h => {
            t += `<th>${h.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')}</th>`;
        });
        t += '</tr></thead><tbody>';
        rows.forEach(row => {
            t += '<tr>';
            row.forEach(cell => {
                t += `<td>${cell.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')}</td>`;
            });
            t += '</tr>';
        });
        t += '</tbody></table></div>';
        return t;
    });

    const parts = html.split(/(<div class="report-table-wrap">[\s\S]*?<\/div>)/);
    html = parts.map(part => {
        if (part.startsWith('<div class="report-table-wrap">')) return part;
        return escapeHtml(part)
            .replace(/^### (.*$)/gim, '<h3>$1</h3>')
            .replace(/^## (.*$)/gim, '<h2>$1</h2>')
            .replace(/^# (.*$)/gim, '<h1>$1</h1>')
            .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/gim, '<em>$1</em>')
            .replace(/---/gim, '<hr>')
            .replace(/^\d+\.\s+(.*$)/gim, '<li>$1</li>')
            .replace(/^-\s+(.*$)/gim, '<li>$1</li>')
            // Convierte líneas sueltas (no tags) en párrafos para separación natural
            .replace(/^(?!<[hul\d/]|$)(.*\S.*)$/gim, '<p>$1</p>')
            .replace(/\n+/g, '');
    }).join('');

    html = html.replace(/(<li>.*?<\/li>(?:<br>)?)+/gims, match =>
        '<ul>' + match.replace(/<br>/g, '') + '</ul>'
    );
    return html;
}

export default class AiChatRobot2InlineReport extends LightningElement {
    @api isLoading = false;
    @api hideExpandButton = false;
    @track _messages = [];
    @track _isExpanded = false;
    @track isCopied = false;
    _rendered = false;
    _copyTimeout = null;
    label = {
        aiChatRobot2_GeneratingReport,
        aiChatRobot2_ReportReady
    };

    @api
    get isExpanded() {
        return this._isExpanded;
    }
    set isExpanded(val) {
        const wasExpanded = this._isExpanded;
        this._isExpanded = val;
        // Si se expande desde afuera (ej: al volver del modal), los divs lwc:dom="manual"
        // se recrean vacíos — forzamos re-inyección del HTML en el próximo render cycle.
        if (val && !wasExpanded) {
            this._rendered = false;
        }
    }

    /* ── Public API ────────────────────────────────────────────── */

    /**
     * Receive an array of summary messages [{ messageId, content }]
     */
    @api
    get summaryMessages() {
        return this._messages;
    }
    set summaryMessages(val) {
        this._messages = Array.isArray(val) ? [...val] : [];
        this._rendered = false;
    }

    @api
    showLoading() {
        this.isLoading = true;
        this._messages = [];
        this.isExpanded = true;
        this._rendered = false;
    }

    @api
    addMessage(msg) {
        this.isLoading = false;
        if (msg && msg.messageId) {
            const exists = this._messages.some(m => m.messageId === msg.messageId);
            if (!exists) {
                this._messages = [...this._messages, msg];
            }
        }
        this.isExpanded = true;
        this._rendered = false;
    }

    @api
    reset() {
        this._messages = [];
        this.isLoading = false;
        this.isExpanded = false;
        this._rendered = false;
    }

    /* ── Computed ───────────────────────────────────────────────── */

    get hasContent() {
        return this._messages.length > 0;
    }

    get showBody() {
        return this.isExpanded && (this.isLoading || this.hasContent);
    }

    get chevronClass() {
        return this.isExpanded ? 'chevron expanded' : 'chevron';
    }

    get headerClass() {
        return this.isExpanded ? 'report-header expanded' : 'report-header';
    }

    get statusLabel() {
        if (this.isLoading) return this.label.aiChatRobot2_GeneratingReport;
        const count = this._messages.length;
        if (count === 0) return this.label.aiChatRobot2_GeneratingReport;
        return count === 1 ? this.label.aiChatRobot2_ReportReady : `${this.label.aiChatRobot2_ReportReady} (${count})`;
    }

    get containerClass() {
        return this.isExpanded ? 'inline-report expanded' : 'inline-report collapsed';
    }

    get showExpandButton() {
        return !this.hideExpandButton;
    }

    get copyBtnClass() {
        return this.isCopied ? 'copy-btn copied' : 'copy-btn';
    }

    get copyIconBtnClass() {
        return this.isCopied ? 'copy-icon-btn copied' : 'copy-icon-btn';
    }

    get copyTooltip() {
        return this.isCopied ? 'Copied!' : 'Copy report';
    }

    /* ── Handlers ──────────────────────────────────────────────── */

    handleToggle() {
        this.isExpanded = !this.isExpanded;
        // When re-expanding, the lwc:dom="manual" divs are recreated empty
        // so we must re-inject HTML on the next render cycle
        if (this.isExpanded) {
            this._rendered = false;
        }
    }

    handleOpenInModal() {
        this.dispatchEvent(new CustomEvent('openinmodal', {
            bubbles: true,
            composed: true
        }));
    }

    handleCopyContent() {
        if (this.isCopied) return;
        // Build plain text from all report messages
        const plainText = this._messages
            .map(msg => msg.content || '')
            .filter(c => c.length > 0)
            .join('\n\n');

        if (!plainText) return;

        // Use Clipboard API
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(plainText).then(() => {
                this._showCopiedFeedback();
            }).catch(() => {
                this._fallbackCopy(plainText);
            });
        } else {
            this._fallbackCopy(plainText);
        }
    }

    _showCopiedFeedback() {
        this.isCopied = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._copyTimeout = setTimeout(() => {
            this.isCopied = false;
        }, 2000);
    }

    _fallbackCopy(text) {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        try {
            document.execCommand('copy');
            this._showCopiedFeedback();
        } catch (err) {
            console.error('Copy failed', err);
        }
        document.body.removeChild(ta);
    }

    /* ── Rendering ─────────────────────────────────────────────── */

    disconnectedCallback() {
        if (this._copyTimeout) {
            clearTimeout(this._copyTimeout);
        }
    }

    renderedCallback() {
        if (this._rendered) return;
        this._rendered = true;

        this._messages.forEach((msg, idx) => {
            const el = this.template.querySelector(`.report-content[data-idx="${idx}"]`);
            if (el && msg.content) {
                const html = markdownToHtml(msg.content);
                if (el.innerHTML !== html) {
                    el.innerHTML = html;
                }
            }
        });
    }
}