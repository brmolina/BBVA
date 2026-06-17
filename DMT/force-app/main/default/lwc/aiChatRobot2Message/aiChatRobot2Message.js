import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import giveMessageFeedback from '@salesforce/apex/aiChatRobot2Controller.makeServiceRequest';
import aiChatRobot2_Feedback_Like from '@salesforce/label/c.aiChatRobot2_Feedback_Like';
import aiChatRobot2_Feedback_Dislike from '@salesforce/label/c.aiChatRobot2_Feedback_Dislike';
import aiChatRobot2_Copy from '@salesforce/label/c.aiChatRobot2_Copy';
import aiChatRobot2_Err_SendFeedback_Title from '@salesforce/label/c.aiChatRobot2_Err_SendFeedback_Title';
import aiChatRobot2_Err_SendFeedback_Positive from '@salesforce/label/c.aiChatRobot2_Err_SendFeedback_Positive';
import aiChatRobot2_Err_SendFeedback_Fallback from '@salesforce/label/c.aiChatRobot2_Err_SendFeedback_Fallback';
import aiChatRobot2_Explicability_SQLQuery from '@salesforce/label/c.aiChatRobot2_Explicability_SQLQuery';
import aiChatRobot2_Explicability_NaturalLanguageQuery from '@salesforce/label/c.aiChatRobot2_Explicability_NaturalLanguageQuery';
import aiChatRobot2_Explicability_ToolsUsed from '@salesforce/label/c.aiChatRobot2_Explicability_ToolsUsed';
import aiChatRobot2_Explicability_AdditionalContext from '@salesforce/label/c.aiChatRobot2_Explicability_AdditionalContext';
import aiChatRobot2_Explicability_Reasoning from '@salesforce/label/c.aiChatRobot2_Explicability_Reasoning';
import aiChatRobot2_Explicability_Sources from '@salesforce/label/c.aiChatRobot2_Explicability_Sources';
import aiChatRobot2_Explicability_ConfidenceLevel from '@salesforce/label/c.aiChatRobot2_Explicability_ConfidenceLevel';
import aiChatRobot2_FeedbackSent from '@salesforce/label/c.aiChatRobot2_FeedbackSent';
import aiChatRobot2_ThanksForFeedback from '@salesforce/label/c.aiChatRobot2_ThanksForFeedback';
import iconsZip from '@salesforce/resourceUrl/aiChatRobot2Icons';

export default class AiChatRobot2Message extends LightningElement {
    @api message;
    @api isWelcome = false;
    @api showActions = false;
    @api conversationId;
    @api userId;    
    @api userCountry;
    @api userSegment;
    @api feedbackState = null; // null, 'liked', 'disliked'
    feedbackLocked = false; // true cuando el feedback ya fue enviado
    isSubmittingFeedback = false; // true mientras se está enviando el feedback
    showFeedbackModal = false;
    _iconsInjected = false;
    @track isExplicabilityExpanded = false;
    @track _expandedSectionsMap = {};

    label = {
        aiChatRobot2_Feedback_Like,
        aiChatRobot2_Feedback_Dislike,
        aiChatRobot2_Copy,
        aiChatRobot2_Err_SendFeedback_Title,
        aiChatRobot2_Err_SendFeedback_Positive,
        aiChatRobot2_Err_SendFeedback_Fallback,
        aiChatRobot2_Explicability_SQLQuery,
        aiChatRobot2_Explicability_NaturalLanguageQuery,
        aiChatRobot2_Explicability_ToolsUsed,
        aiChatRobot2_Explicability_AdditionalContext,
        aiChatRobot2_Explicability_Reasoning,
        aiChatRobot2_Explicability_Sources,
        aiChatRobot2_Explicability_ConfidenceLevel,
        aiChatRobot2_FeedbackSent,
        aiChatRobot2_ThanksForFeedback
    };

    renderedCallback() {
        const el = this.template.querySelector('.text');
        if (el && this.message) {
            const safe = this._toHtml(this.message.text);
 
            if (el.innerHTML !== safe) {
                el.innerHTML = safe;
            }
        }

        // Render sources tooltips
        if (this.hasSources) {
            this._renderSources();
        }

        // Render explicability sections content for expanded sections
        if (this.hasExplicability) {
            this._renderExplicabilitySections();
        }
        
        // Inject action icons from static resource
        if (!this._iconsInjected && this.showActions && !this.isUser && !this.isMocked) {
            this._injectActionIcons();
        }
    }

    /**
     * Renders the content of source tooltips
     */
    _renderSources() {
        const sources = this.sources;
        sources.forEach(source => {
            const tooltipEl = this.template.querySelector(`.source-tooltip[data-source-id="${source.id}"]`);
            if (tooltipEl && source.content) {
                const safeContent = this._toHtml(source.content);
                if (tooltipEl.innerHTML !== safeContent) {
                    tooltipEl.innerHTML = safeContent;
                }
            }
        });
        
        // Add hover event listeners to position tooltips
        this._attachTooltipListeners();
    }

    /**
     * Attaches hover event listeners to source pills for tooltip positioning
     */
    _attachTooltipListeners() {
        const pills = this.template.querySelectorAll('.source-pill');
        pills.forEach(pill => {
            if (!pill._hasTooltipListener) {
                pill.addEventListener('mouseenter', (e) => {
                    const tooltip = pill.querySelector('.source-tooltip');
                    if (tooltip) {
                        const pillRect = pill.getBoundingClientRect();
                        const tooltipRect = tooltip.getBoundingClientRect();
                        
                        // Position tooltip above the pill, centered
                        const left = pillRect.left + (pillRect.width / 2) - (tooltipRect.width / 2);
                        const top = pillRect.top - tooltipRect.height - 10;
                        
                        tooltip.style.left = `${Math.max(10, left)}px`;
                        tooltip.style.top = `${Math.max(10, top)}px`;
                    }
                });
                pill._hasTooltipListener = true;
            }
        });
    }

    /**
     * Renders the content of each explicability section
     */
    _renderExplicabilitySections() {
        const sections = this.explicabilitySections;
        sections.forEach(section => {
            const sectionEl = this.template.querySelector(`.explicability-text[data-section-id="${section.id}"]`);
            if (sectionEl && section.content) {
                let safeContent;
                // Si es tipo SQL, envolver en pre/code con clase especial
                if (section.isCodeType) {
                    const escapedCode = this._escapeHtml(section.content);
                    safeContent = `<pre class="sql-code-block"><code class="language-sql">${escapedCode}</code></pre>`;
                } else {
                    safeContent = this._toHtml(section.content);
                }
                if (sectionEl.innerHTML !== safeContent) {
                    sectionEl.innerHTML = safeContent;
                }
            }
        });
    }

    /**
     * Escapes HTML special characters
     */
    _escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    _injectActionIcons() {
        // Inject copy icon
        this._injectIcon('copy-icon-svg', ['copy.svg', 'Copy.svg'], `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M8 4V16C8 17.1046 8.89543 18 10 18H18C19.1046 18 20 17.1046 20 16V7.24162C20 6.7034 19.7831 6.18789 19.3982 5.81161L16.6569 3.10714C16.2842 2.73836 15.7873 2.52892 15.2676 2.51598L10 2.5C8.89543 2.5 8 3.39543 8 4.5V4Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M16 18V20.5C16 21.6046 15.1046 22.5 14 22.5H6C4.89543 22.5 4 21.6046 4 20.5V9.5C4 8.39543 4.89543 7.5 6 7.5H8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        `);
        
        // Inject like icon
        this._injectIcon('like-icon-svg', ['thumb-up.svg', 'Thumb-up.svg', 'thumbup.svg'], `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M7 22V11M2 13V20C2 21.1046 2.89543 22 4 22H17.4262C18.907 22 20.1662 20.9197 20.3914 19.4562L21.4683 12.4562C21.7479 10.6389 20.3418 9 18.5032 9H15V4C15 2.89543 14.1046 2 13 2C12.4477 2 12 2.44772 12 3V3.93551C12 4.68374 11.7111 5.40473 11.1934 5.94888L7.88197 9.47341C7.33736 10.0464 7 10.8183 7 11.6227V11.6227" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        `);
        
        // Inject dislike icon
        this._injectIcon('dislike-icon-svg', ['thumb-down.svg', 'Thumb-down.svg', 'thumbdown.svg'], `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M17 2V13M22 11V4C22 2.89543 21.1046 2 20 2H6.57384C5.09301 2 3.83384 3.08025 3.60858 4.54377L2.53165 11.5438C2.25211 13.3611 3.65823 15 5.49681 15H9V20C9 21.1046 9.89543 22 11 22C11.5523 22 12 21.5523 12 21V20.0645C12 19.3163 12.2889 18.5953 12.8066 18.0511L16.118 14.5266C16.6626 13.9536 17 13.1817 17 12.3773V12.3773" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        `);
        
        // Inject volume icon
        this._injectIcon('volume-icon-svg', ['volume.svg', 'Volume.svg', 'speaker.svg'], `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M11 5L6 9H2v6h4l5 4V5z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M15.54 8.46a5 5 0 010 7.07M19.07 4.93a10 10 0 010 14.14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        `);
        
        // Inject download icon
        this._injectIcon('download-icon-svg', ['download.svg', 'Download.svg'], `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        `);
        
        // Inject pencil-plus icon
        this._injectIcon('pencil-plus-icon-svg', ['pencil-plus.svg', 'Pencil-plus.svg', 'edit-plus.svg'], `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 20h9M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        `);
        
        this._iconsInjected = true;
    }

    _injectIcon(className, fileNames, fallbackSvg) {
        const host = this.template.querySelector(`.${className}`);
        if (!host) return;

        const tryFile = (index) => {
            if (index >= fileNames.length) {
                // Use fallback
                host.innerHTML = fallbackSvg.trim();
                return;
            }
            
            const svgUrl = `${iconsZip}/${fileNames[index]}`;
            fetch(svgUrl)
                .then((res) => {
                    if (!res.ok) {
                        return tryFile(index + 1);
                    }
                    return res.text();
                })
                .then((raw) => {
                    if (!raw) return;
                    let svg = raw.trim();

                    // Strip XML/DOCTYPE
                    svg = svg.replace(/<\?xml[\s\S]*?\?>/gi, '');
                    svg = svg.replace(/<!DOCTYPE[\s\S]*?>/gi, '');
                    svg = svg.replace(/<script[\s\S]*?<\/script>/gi, '');
                    svg = svg.replace(/\son\w+="[^"]*"/gi, '');
                    svg = svg.replace(/\son\w+='[^']*'/gi, '');

                    // Normalize to currentColor
                    svg = svg.replace(/(fill|stroke)="(.*?)"/gi, (full, attr, val) => {
                        const v = String(val || '').toLowerCase();
                        if (v === 'none') return full;
                        return `${attr}="currentColor"`;
                    });

                    // Set size
                    svg = svg.replace(/<svg([^>]*)>/i, (_m, attrs) => {
                        let a = attrs
                            .replace(/\swidth="[^"]*"/i, '')
                            .replace(/\sheight="[^"]*"/i, '')
                            .trim();
                        return `<svg ${a} width="16" height="16" style="display:block">`;
                    });

                    host.innerHTML = svg;
                })
                .catch(() => tryFile(index + 1));
        };
        
        tryFile(0);
    }

    get isUser() {
        return this.message?.role === 'user';
    }

    get isTimeout() {
        return this.message?.isTimeout === true;
    }

    get isMocked() {
        return this.message?.isMocked === true;
    }

    get messageTextClass() {
        return this.isTimeout ? 'text timeout-text' : 'text';
    }

    get aiTextWrapperClass() {
        return this.isTimeout ? 'text-wrapper timeout-message' : 'text-wrapper';
    }

    get hasExplicability() {
        const explicability = this.message?.explicability;
        return !this.isUser && !this.isWelcome && Array.isArray(explicability) && explicability.length > 0;
    }

    /**
     * Returns sources (Hover type) to display as pills below the message
     */
    get sources() {
        const explicability = this.message?.explicability;
        if (!Array.isArray(explicability)) {
            return [];
        }
        return explicability
            .filter(section => section.type === 'Hover')
            .map((section, index) => ({
                id: `source-${this.message.id}-${index}`,
                content: section.content || '',
                index: index + 1
            }));
    }

    get hasSources() {
        return this.sources.length > 0;
    }

    /**
     * Returns explicability sections sorted by order
     * Each section has: id, name, order, content, isExpanded, toggleLabel, toggleClass, contentClass
     */
    /**
     * Maps tipos de explicability y nombre a mostrar en el chat 
     */
    _getExplicabilityTypeName(type) {
        const typeMap = {
            'SQL': this.label.aiChatRobot2_Explicability_SQLQuery,
            'SQL-nat': this.label.aiChatRobot2_Explicability_NaturalLanguageQuery,
            'Tool': this.label.aiChatRobot2_Explicability_ToolsUsed,
            'Hover': this.label.aiChatRobot2_Explicability_AdditionalContext,
            'Reasoning': this.label.aiChatRobot2_Explicability_Reasoning,
            'Sources': this.label.aiChatRobot2_Explicability_Sources,
            'Confidence': this.label.aiChatRobot2_Explicability_ConfidenceLevel
        };
        return typeMap[type] || type || 'Details';
    }

    /**
     * Returns explicability sections sorted by order with toggle state
     * Excludes Hover type (sources are shown separately)
     */
    get explicabilitySections() {
        const explicability = this.message?.explicability;
        if (!Array.isArray(explicability)) {
            return [];
        }
        // Types that should be rendered as code blocks
        const codeTypes = ['SQL', 'sql', 'query', 'Query'];
        
        // Filter out Hover type and sort by order
        return [...explicability]
            .filter(section => section.type !== 'Hover')
            .sort((a, b) => (a.order || 0) - (b.order || 0))
            .map((section, index) => {
                const id = `explicability-section-${this.message.id}-${index}`;
                const isExpanded = !!this._expandedSectionsMap[id];
                const sectionName = this._getExplicabilityTypeName(section.type);
                const isCodeType = codeTypes.includes(section.type);
                return {
                    id,
                    name: sectionName,
                    type: section.type,
                    order: section.order || index,
                    content: section.content || '',
                    isExpanded,
                    isCodeType,
                    toggleLabel: isExpanded ? `Hide ${sectionName}` : `Show ${sectionName}`,
                    toggleClass: isExpanded ? 'explicability-toggle expanded' : 'explicability-toggle',
                    contentClass: isExpanded ? 'explicability-content expanded' : 'explicability-content'
                };
            });
    }

    get explicabilityToggleLabel() {
        return this.isExplicabilityExpanded ? 'Hide reasoning' : 'Show reasoning';
    }

    get explicabilityToggleClass() {
        return this.isExplicabilityExpanded ? 'explicability-toggle expanded' : 'explicability-toggle';
    }

    get explicabilityContentClass() {
        return this.isExplicabilityExpanded ? 'explicability-content expanded' : 'explicability-content';
    }

    handleExplicabilityToggle() {
        this.isExplicabilityExpanded = !this.isExplicabilityExpanded;
    }

    /**
     * Handles toggle for individual explicability section
     */
    handleSectionToggle(event) {
        const sectionId = event.currentTarget.dataset.sectionId;
        if (sectionId) {
            // Create a new object to trigger reactivity
            const newMap = { ...this._expandedSectionsMap };
            newMap[sectionId] = !newMap[sectionId];
            this._expandedSectionsMap = newMap;
        }
    }

    get containerClass() {
        if (this.isWelcome) return 'row welcome fade-in';
        return `row ${this.isUser ? 'right' : 'left'} fade-in`;
    }

    get currentFeedbackState() {
        return this.message?.feedbackState ?? this.feedbackState;
    }

    get isFeedbackLocked() {
        return this.message?.feedbackLocked === true || this.feedbackLocked;
    }

    get likeButtonClass() {
        const baseClass = 'feedback-btn';
        const selectedClass = this.currentFeedbackState === 'liked' ? 'selected filled' : '';
        const disabledClass = this.isFeedbackLocked || this.isSubmittingFeedback ? 'disabled' : '';
        const loadingClass = this.isSubmittingFeedback && this.currentFeedbackState === 'liked' ? 'loading' : '';
        return `${baseClass} ${selectedClass} ${disabledClass} ${loadingClass}`.trim();
    }

    get dislikeButtonClass() {
        const baseClass = 'feedback-btn';
        const selectedClass = this.currentFeedbackState === 'disliked' ? 'selected filled' : '';
        const disabledClass = this.isFeedbackLocked || this.isSubmittingFeedback ? 'disabled' : '';
        return `${baseClass} ${selectedClass} ${disabledClass}`.trim();
    }

    handleLike() {
        // Si el feedback ya fue enviado o se está enviando, no permitir cambios
        if (this.isFeedbackLocked) {
            return;
        }

        // Seleccionar dislike y abrir modal
        this.feedbackState = 'liked';
        this.showFeedbackModal = true;
    }

    handleDislike() {
        // Si el feedback ya fue enviado, no permitir cambios
        if (this.isFeedbackLocked) {
            return;
        }

        // Seleccionar dislike y abrir modal
        this.feedbackState = 'disliked';
        this.showFeedbackModal = true;
    }

    handleModalClose() {
        this.showFeedbackModal = false;
        // Si se cierra sin enviar, revertimos el estado
        if (!this.isFeedbackLocked) {
            this.feedbackState = null;
        }
    }

    handleFeedbackSent(event) {
        // El feedback fue enviado exitosamente
        this.showFeedbackModal = false;
        this.feedbackLocked = true;
        this.feedbackState = this.currentFeedbackState;
        
        // Notificar al componente padre
        this.dispatchEvent(new CustomEvent('feedbacksent', {
            detail: {
                ...(event.detail || {}),
                messageId: this.message?.id,
                feedbackState: this.currentFeedbackState
            },
            bubbles: true,
            composed: true
        }));
    }

    handleCopy() {
        const text = this.message?.text || '';
        if (navigator.clipboard && text) {
            // Clean markdown formatting before copying
            const cleanText = this._cleanMarkdown(text);
            navigator.clipboard.writeText(cleanText).then(() => {
                this.dispatchEvent(new CustomEvent('copied', {
                    detail: { messageId: this.message?.id },
                    bubbles: true,
                    composed: true
                }));
            }).catch(err => {
                console.error('Error al copiar:', err);
            });
        }
    }

    handleVolume() {
        // Dispatch event for read aloud functionality
        this.dispatchEvent(new CustomEvent('readaloud', {
            detail: { messageId: this.message?.id, text: this.message?.text },
            bubbles: true,
            composed: true
        }));
    }

    handleDownload() {
        // Dispatch event for download functionality
        this.dispatchEvent(new CustomEvent('download', {
            detail: { messageId: this.message?.id, text: this.message?.text },
            bubbles: true,
            composed: true
        }));
    }

    handleEdit() {
        // Dispatch event for edit functionality
        this.dispatchEvent(new CustomEvent('edit', {
            detail: { messageId: this.message?.id, text: this.message?.text },
            bubbles: true,
            composed: true
        }));
    }

    get suggestions() {
        const arr = this.message?.suggestions;
        return Array.isArray(arr) ? arr : [];
    }

    get hasSuggestions() {
        return this.suggestions.length > 0;
    }

    onSuggestionClick(event) {
        const text = event?.currentTarget?.dataset?.text;
        if (!text) return;
        this.dispatchEvent(new CustomEvent('suggestionselect', {
            detail: { text },
            bubbles: true,
            composed: true
        }));
    }

    get roleLabel() {
        return this.isUser ? 'Usuario' : 'IA';
    }

    get formattedTime() {
        try {
            const d = new Date(this.message?.timestamp);
            return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch (e) {
            return '';
        }
    }

    _cleanMarkdown(s) {
        // Eliminar formato markdown para copiar como texto plano
        let clean = String(s);
        
        // Eliminar bloques de código ```código```
            clean = clean.replace(/```[\w]*\n?([\s\S]*?)```/g, '$1');
        
        // Eliminar código inline `código`
        clean = clean.replace(/`([^`]+)`/g, '$1');
        
        // Reemplazar enlaces markdown [texto](url) con solo el texto
        clean = clean.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1');
        
        // Eliminar headers ###
        clean = clean.replace(/^#{1,6}\s+/gm, '');
        
        // Eliminar marcadores de negrita **texto** o __texto__
        clean = clean.replace(/\*\*([^\*]+)\*\*/g, '$1');
        clean = clean.replace(/__([^_]+)__/g, '$1');
        
        // Eliminar marcadores de cursiva *texto* o _texto_
        clean = clean.replace(/\*([^\*]+)\*/g, '$1');
        clean = clean.replace(/_([^_]+)_/g, '$1');
        
        // Eliminar tachado ~~texto~~
        clean = clean.replace(/~~([^~]+)~~/g, '$1');
        
        // Eliminar marcadores de citas
        clean = clean.replace(/^>\s+/gm, '');
        
        // Eliminar marcadores de listas
        clean = clean.replace(/^[•\-\*]\s+/gm, '• ');
        clean = clean.replace(/^\d+\.\s+/gm, '');
        
        // Eliminar separadores horizontales
        clean = clean.replace(/^---$/gm, '');
        clean = clean.replace(/^\*\*\*$/gm, '');
        
        return clean;
    }

    _escape(s) {
        return String(s)
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;');
    }

    _processTables(html) {
        const lines = html.split('\n');
        const result = [];
        let inTable = false;
        let tableRows = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            
            // Detectar si es una línea de tabla (contiene | al inicio y fin)
            if (line.startsWith('|') && line.endsWith('|')) {
                // Verificar si es la línea separadora (|---|---|)
                const isSeparator = /^\|[\s\-:|]+\|$/.test(line);
                
                if (!inTable && !isSeparator) {
                    // Inicio de tabla - esta es la fila de headers
                    inTable = true;
                    tableRows = [];
                    const cells = line.split('|').slice(1, -1).map(c => c.trim());
                    tableRows.push({ type: 'header', cells });
                } else if (inTable && isSeparator) {
                    // Línea separadora - la ignoramos
                    continue;
                } else if (inTable) {
                    // Fila de datos
                    const cells = line.split('|').slice(1, -1).map(c => c.trim());
                    tableRows.push({ type: 'data', cells });
                }
            } else {
                // No es una línea de tabla
                if (inTable) {
                    // Terminar la tabla y renderizarla
                    result.push(this._renderTable(tableRows));
                    inTable = false;
                    tableRows = [];
                }
                result.push(line);
            }
        }

        // Si quedó una tabla sin cerrar al final
        if (inTable && tableRows.length > 0) {
            result.push(this._renderTable(tableRows));
        }

        return result.join('\n');
    }

    _renderTable(rows) {
        if (rows.length === 0) return '';

        let html = '<table>';
        
        // Renderizar header
        const headerRow = rows.find(r => r.type === 'header');
        if (headerRow) {
            html += '<thead><tr>';
            headerRow.cells.forEach(cell => {
                html += `<th>${cell}</th>`;
            });
            html += '</tr></thead>';
        }

        // Renderizar body
        const dataRows = rows.filter(r => r.type === 'data');
        if (dataRows.length > 0) {
            html += '<tbody>';
            dataRows.forEach(row => {
                html += '<tr>';
                row.cells.forEach(cell => {
                    html += `<td>${cell}</td>`;
                });
                html += '</tr>';
            });
            html += '</tbody>';
        }

        html += '</table>';
        return html;
    }

    _toHtml(s) {
        let text = String(s);
        
        // 1. Guardar bloques de código para prevenir procesamiento interno
        const codeBlocks = [];
        text = text.replace(/```(\w+)?\n?([\s\S]*?)```/g, (match, lang, code) => {
            const placeholder = `§§§CODE§BLOCK§${codeBlocks.length}§§§`;
            codeBlocks.push({ lang: lang || 'plaintext', code: code.trim() });
            return placeholder;
        });
        
        // 2. Guardar código inline para prevenir procesamiento interno
        const inlineCodes = [];
        text = text.replace(/`([^`]+)`/g, (match, code) => {
            const placeholder = `§§§INLINE§CODE§${inlineCodes.length}§§§`;
            inlineCodes.push(code);
            return placeholder;
        });
        
        // 3. Guardar enlaces markdown con placeholders
        const links = [];
        text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (match, linkText, url) => {
            const placeholder = `§§§LINK§${links.length}§§§`;
            links.push({ text: linkText, url: url });
            return placeholder;
        });
        
        // 4. Escapar caracteres especiales HTML
        let html = this._escape(text);
        
        // 5. Procesar tablas markdown
        html = this._processTables(html);
        
        // 6. Procesar markdown a nivel de bloque (debe ir antes del inline)
        
        // Headers (deben estar al inicio de línea, de mayor a menor profundidad)
        html = html.replace(/^#### (.+)$/gm, '<h4>$1</h4>');
        html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>');
        html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>');
        html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>');
        
        // Separadores horizontales
        html = html.replace(/^---$/gm, '<hr/>');
        html = html.replace(/^\*\*\*$/gm, '<hr/>');
        
        // Citas (blockquotes)
        html = html.replace(/^&gt; (.+)$/gm, '<blockquote>$1</blockquote>');
        
        // Listas desordenadas (-, *, •)
        html = html.replace(/^[•\-\*] (.+)$/gm, '<li>$1</li>');
        
        // Listas ordenadas (1., 2., etc)
        html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>');
        
        // 6. Procesar markdown inline
        
        // Negrita **texto** o __texto__
        html = html.replace(/\*\*([\s\S]+?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/__([\s\S]+?)__/g, '<strong>$1</strong>');
        
        // Cursiva *texto* o _texto_ (pero no los placeholders §§§)
        html = html.replace(/(?<!_)\*([^\*\s][^\*]*?)\*/g, '<em>$1</em>');
        html = html.replace(/(?<!_)_([^_\s][^_]*?)_(?!_)/g, '<em>$1</em>');
        
        // Tachado ~~texto~~
        html = html.replace(/~~([\s\S]+?)~~/g, '<del>$1</del>');
        
        // 7. Restaurar código inline
        inlineCodes.forEach((code, i) => {
            const escapedCode = this._escape(code);
            html = html.replace(`§§§INLINE§CODE§${i}§§§`, `<code>${escapedCode}</code>`);
        });
        
        // 8. Restaurar bloques de código
        codeBlocks.forEach((block, i) => {
            const escapedCode = this._escape(block.code);
            html = html.replace(
                `§§§CODE§BLOCK§${i}§§§`, 
                `<pre><code class="language-${block.lang}">${escapedCode}</code></pre>`
            );
        });
        
        // 9. Restaurar enlaces como etiquetas HTML <a>
        links.forEach((link, i) => {
            const rawUrl = link.url.trim();
            // Bloquear protocolos peligrosos (javascript:, data:, vbscript:, etc.)
            const safeUrl = /^(https?:\/\/|\/|#)/i.test(rawUrl) ? rawUrl : '#';
            const escapedUrl = safeUrl.replace(/"/g, '&quot;');
            const escapedText = link.text; // El texto ya está escapado
            const linkHtml = `<a href="${escapedUrl}" target="_blank" rel="noopener noreferrer">${escapedText}</a>`;
            html = html.replace(`§§§LINK§${i}§§§`, linkHtml);
        });
        
        // 10. Convertir saltos de línea a <br/>
        html = html.replace(/\n/g, '<br/>');
        
        // 11. Envolver <li> consecutivos en <ul> y eliminar <br/> entre items
        html = html.replace(/(<li>.*?<\/li>(?:<br\/>)*)+/g, (match) => {
            // Eliminar todas las etiquetas <br/> entre items de lista
            const cleanList = match.replace(/<br\/>/g, '');
            return `<ul>${cleanList}</ul>`;
        });
        
        return html;
    }
}