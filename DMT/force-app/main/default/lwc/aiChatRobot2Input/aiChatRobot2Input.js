import { LightningElement, api, track } from 'lwc';
import aiChatRobot2_InputPlaceholder from '@salesforce/label/c.aiChatRobot2_InputPlaceholder';
import aiChatRobot2_Send from '@salesforce/label/c.aiChatRobot2_Send';
import aiChatRobot2_CharLimitExceeded from '@salesforce/label/c.aiChatRobot2_CharLimitExceeded';
import iconsZip from '@salesforce/resourceUrl/aiChatRobot2Icons';

export default class AiChatRobot2Input extends LightningElement {
    @api disabled = false; // Desactivado cuando la IA está respondiendo
    @api charLimit = null; // Límite de caracteres configurado desde Custom Metadata
    @track value = '';
    _iconsInjected = false;

    @api get placeholder() {
        // Usar etiqueta personalizada para i18n
        return aiChatRobot2_InputPlaceholder;
    }

    label = { aiChatRobot2_Send, aiChatRobot2_CharLimitExceeded };

    get exceedsCharLimit() {
        const limit = Number(this.charLimit);
        return Number.isFinite(limit) && limit > 0 && this.value.length > limit;
    }

    get charLimitMessage() {
        if (!this.exceedsCharLimit) return '';
        return aiChatRobot2_CharLimitExceeded.replace('{0}', String(this.charLimit));
    }

    get sendDisabled() {
        return this.disabled || !this.value.trim() || this.exceedsCharLimit;
    }

    get hasValue() {
        return this.value.trim().length > 0;
    }

    get showStopIcon() {
        return this.disabled && !this.hasValue;
    }

    get showMicrophoneIcon() {
        return !this.disabled && !this.hasValue;
    }

    get sendButtonClass() {
        return this.hasValue ? 'icon-button send-button active' : 'icon-button send-button';
    }

    get sendButtonTitle() {
        if (this.hasValue) return this.label.aiChatRobot2_Send;
        if (this.disabled) return 'Stop generating';
        return 'Voice input';
    }

    autoResize(event) {
        const ta = event.target;
        this.value = ta.value;
        ta.style.height = 'auto';
        ta.style.height = `${Math.min(ta.scrollHeight, 160)}px`;
    }

    handleKey(event) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            this.send();
        }
    }

    handleAddClick() {
        this.dispatchEvent(new CustomEvent('addclick'));
    }

    handleSendClick() {
        if (this.hasValue) {
            this.send();
        } else {
            // Handle voice input
            this.dispatchEvent(new CustomEvent('voiceclick'));
        }
    }

    send() {
        const text = this.value.trim();
        if (!text || this.disabled || this.exceedsCharLimit) return;
        this.dispatchEvent(new CustomEvent('messagesend', { detail: { text } }));
        this.value = '';
        const ta = this.template.querySelector('textarea');
        if (ta) {
            ta.value = '';
            ta.style.height = 'auto';
        }
    }

    // Public method: fill textarea with suggestion and focus
    @api fill(text) {
        const val = (text || '').toString();
        this.value = val;
        const ta = this.template.querySelector('textarea');
        if (ta) {
            ta.value = val;
            ta.style.height = 'auto';
            ta.style.height = `${Math.min(ta.scrollHeight, 160)}px`;
            ta.focus();
            // Move caret to end
            const end = val.length;
            ta.setSelectionRange(end, end);
        }
    }

    renderedCallback() {
        this._injectInputIcons();
    }

    _injectInputIcons() {
        // Inject plus icon (always present)
        const plusHost = this.template.querySelector('.plus-icon-svg');
        if (plusHost && !plusHost.innerHTML) {
            this._injectIcon('plus-icon-svg', ['plus.svg', 'Plus.svg'], `
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <path d="M12 5v14M5 12h14" stroke-width="2" stroke-linecap="round"/>
                </svg>
            `);
        }
        
        // Inject stop icon (when AI is thinking)
        const stopHost = this.template.querySelector('.stop-icon-svg');
        if (stopHost && !stopHost.innerHTML) {
            this._injectSendIcon('stop-icon-svg', ['stop-blue.svg', 'Stop-blue.svg', 'stop.svg', 'Stop.svg'], `
                <svg class="icon" viewBox="0 0 24 24" fill="currentColor">
                    <rect x="6" y="6" width="12" height="12" rx="2"/>
                </svg>
            `);
        }
        
        // Inject microphone icon (only when visible, i.e., when input is empty)
        const micHost = this.template.querySelector('.microphone-icon-svg');
        if (micHost && !micHost.innerHTML) {
            this._injectIcon('microphone-icon-svg', ['microphone.svg', 'Microphone.svg', 'mic.svg'], `
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" stroke-width="2"/>
                    <path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" stroke-width="2" stroke-linecap="round"/>
                </svg>
            `);
        }
        
        // Inject send icon (only when visible, i.e., when there's text)
        const sendHost = this.template.querySelector('.send-icon-svg');
        if (sendHost && !sendHost.innerHTML) {
            this._injectSendIcon('send-icon-svg', ['send-blue.svg', 'Send-blue.svg', 'send.svg', 'Send.svg'], `
                <svg class="icon" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3.478 2.405a.75.75 0 0 0-.926.94l2.432 7.905H13.5a.75.75 0 0 1 0 1.5H4.984l-2.432 7.905a.75.75 0 0 0 .926.94 60.519 60.519 0 0 0 18.445-8.986.75.75 0 0 0 0-1.218A60.517 60.517 0 0 0 3.478 2.405z"/>
                </svg>
            `);
        }
    }

    _injectSendIcon(className, fileNames, fallbackSvg) {
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

                    // DON'T normalize colors for send icon - keep original colors
                    
                    // Set size and class
                    svg = svg.replace(/<svg([^>]*)>/i, (_m, attrs) => {
                        let a = attrs
                            .replace(/\swidth="[^"]*"/i, '')
                            .replace(/\sheight="[^"]*"/i, '')
                            .replace(/\sclass="[^"]*"/i, '')
                            .trim();
                        return `<svg ${a} class="icon" style="display:block">`;
                    });

                    host.innerHTML = svg;
                })
                .catch(() => tryFile(index + 1));
        };
        
        tryFile(0);
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

                    // Set size and class
                    svg = svg.replace(/<svg([^>]*)>/i, (_m, attrs) => {
                        let a = attrs
                            .replace(/\swidth="[^"]*"/i, '')
                            .replace(/\sheight="[^"]*"/i, '')
                            .replace(/\sclass="[^"]*"/i, '')
                            .trim();
                        return `<svg ${a} class="icon" style="display:block">`;
                    });

                    host.innerHTML = svg;
                })
                .catch(() => tryFile(index + 1));
        };
        
        tryFile(0);
    }
}