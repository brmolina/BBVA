import { LightningElement, api } from 'lwc';
import aiChatRobot2_Thinking from '@salesforce/label/c.aiChatRobot2_Thinking';
import iconsZip from '@salesforce/resourceUrl/aiChatRobot2Icons';

export default class AiChatRobot2MessageList extends LightningElement {
    @api conversationId;
    @api userId;
    @api userCountry;
    @api userSegment;
    @api hideExpandButton = false;
    
    _messages = [];
    _isThinking = false;
    _sparklesInjected = false;
    _observer = null;
    _observerAttached = false;

    _sticky = true; 
    showActionsFlag = true;
    _pendingScrollToMessageId = null;
    _forceScrollTimers = [];
    label = { aiChatRobot2_Thinking };
    
    @api
    get isThinking() {
        return this._isThinking;
    }
    set isThinking(value) {
        const wasThinking = this._isThinking;
        this._isThinking = value;
        if (value !== wasThinking) {
            this._sparklesInjected = false;
            // Cuando thinking INICIA, hace scroll al fondo para que el usuario vea el indicador.
            // Cuando thinking TERMINA, NO hace auto-scroll — el handler de FINAL_ANSWER
            // llamara a forceScrollToMessage para posicionar al inicio de la respuesta AI.
            if (value) {
                this._sticky = true;
                this._scheduleScrollToBottom();
            }
        }
    }

    @api
    get messages() {
        return this._messages;
    }
    set messages(value) {
        const prev = this._messages;
        this._messages = Array.isArray(value) ? value : [];
        
        // Solo hace auto-scroll si hay mensajes reales de conversacion (mas que solo bienvenida)
        const hasConversation = this._messages.length > 1 || 
                               (this._messages.length === 1 && this._messages[0].role === 'user');
        
        if (hasConversation) {
            // Si hay un scroll-to-message pendiente, omite el scroll-to-bottom por defecto.
            // El renderedCallback + _scrollToMessage se encargaran del posicionamiento.
            if (this._pendingScrollToMessageId) {
                return;
            }
            // Detecta si el ultimo mensaje es una respuesta AI: hace scroll a su inicio en vez del fondo
            const lastMsg = this._messages[this._messages.length - 1];
            const prevLastMsg = prev && prev.length ? prev[prev.length - 1] : null;
            const isNewAiMessage = lastMsg && lastMsg.role === 'ai' && !lastMsg.isMocked
                && (!prevLastMsg || prevLastMsg.id !== lastMsg.id);
            if (isNewAiMessage) {
                // Programa scroll al inicio del nuevo mensaje AI despues del render.
                // Cancela timers de scroll-to-bottom en vuelo para que no lo sobreescriban.
                this._cancelForceScrollTimers();
                this._sticky = false;
                this._pendingScrollToMessageId = lastMsg.id;
                return;
            }
            // Por defecto: scroll al fondo (mensajes del usuario, marcadores de reporte, etc.)
            this._sticky = true;
            this._forceScroll();
        } else {
            // Mantiene scroll arriba para el mensaje de bienvenida
            this._sticky = false;
            this._scrollToTop();
        }
    }

    onScroll(event) {
        const el = event.target;
        const bottomThreshold = 40;
        const atBottom = el.scrollTop >= (el.scrollHeight - el.clientHeight - bottomThreshold);
        this._sticky = atBottom;
    }

    /** Cancela todos los timers pendientes de scroll-to-bottom */
    _cancelForceScrollTimers() {
        if (this._forceScrollTimers && this._forceScrollTimers.length) {
            this._forceScrollTimers.forEach(id => clearTimeout(id));
        }
        this._forceScrollTimers = [];
    }

    _forceScroll() {
        // Cancela timers previos pendientes antes de crear nuevos
        this._cancelForceScrollTimers();

        // Multiples estrategias para asegurar que el scroll ocurra
        this._scrollToBottom();
        
        // Despues de frames de animacion
        requestAnimationFrame(() => {
            if (!this._pendingScrollToMessageId) this._scrollToBottom();
            requestAnimationFrame(() => {
                if (!this._pendingScrollToMessageId) this._scrollToBottom();
            });
        });
        
        // Despues de timeouts con delays mas largos — guarda IDs para poder cancelarlos
        const delays = [0, 10, 50, 100, 200, 300];
        delays.forEach(ms => {
            const tid = setTimeout(() => {
                if (!this._pendingScrollToMessageId) {
                    this._scrollToBottom();
                }
            }, ms);
            this._forceScrollTimers.push(tid);
        });
    }

    _scheduleScrollToBottom() {
        if (this._sticky) {
            this._forceScroll();
        }
    }

    _scrollToBottom() {
        const list = this.template.querySelector('.list-root');
        if (list) {
            // Fuerza scroll al fondo absoluto con buffer extra
            const scrollToMax = () => {
                list.scrollTop = list.scrollHeight + 1000;
            };

            // Ejecuta multiples veces con diferentes estrategias
            scrollToMax();

            // Intenta primero con el ancla inferior
            const anchor = this.template.querySelector('[data-anchor="bottom"]');
            if (anchor && typeof anchor.scrollIntoView === 'function') {
                anchor.scrollIntoView({ block: 'end', inline: 'nearest', behavior: 'auto' });
            }

            // Fuerza scroll de nuevo despues del ancla
            scrollToMax();

            // Como ultimo recurso, hace scroll al ultimo elemento de mensaje
            const all = list.querySelectorAll('c-ai-chat-robot2-message');
            const last = all && all.length ? all[all.length - 1] : null;
            if (last && typeof last.scrollIntoView === 'function') {
                last.scrollIntoView({ block: 'end', inline: 'nearest', behavior: 'auto' });
            }

            // Scroll final forzado
            scrollToMax();
        }
    }

    _scrollToTop() {
        const list = this.template.querySelector('.list-root');
        if (list) {
            list.scrollTop = 0;
            // Fuerza multiples veces para asegurar que funcione
            requestAnimationFrame(() => {
                list.scrollTop = 0;
            });
            setTimeout(() => {
                list.scrollTop = 0;
            }, 10);
        }
    }

    /**
     * Hace scroll en la lista para que el mensaje con el id dado quede al inicio
     * del area visible, permitiendo al usuario leer la respuesta AI desde el principio.
     * Usa calculo manual de scrollTop en vez de scrollIntoView para evitar
     * propagar scroll a contenedores ancestros (lo que causa "estiramiento" del layout).
     */
    _scrollToMessage(messageId) {
        if (!messageId) return false;
        const list = this.template.querySelector('.list-root');
        if (!list) return false;

        // Los mensajes se renderizan como <c-ai-chat-robot2-message> con propiedad @api message.
        // Se busca comparando el.message.id (API publica, sin necesidad de atravesar Shadow DOM).
        const allMsgs = list.querySelectorAll('c-ai-chat-robot2-message');
        let target = null;
        allMsgs.forEach(el => {
            if (el.message && el.message.id === messageId) {
                target = el;
            }
        });

        if (target) {
            // Calcula el offset del elemento objetivo relativo al contenedor de scroll.
            const listRect = list.getBoundingClientRect();
            const targetRect = target.getBoundingClientRect();
            // Offset visible actual del objetivo relativo al top de la lista + scrollTop actual
            const targetOffset = targetRect.top - listRect.top + list.scrollTop;
            // Pequeno padding para que el mensaje no quede pegado al borde superior
            const topPadding = 4;
            list.scrollTop = targetOffset - topPadding;
            // Desactiva sticky para que el MutationObserver no empuje inmediatamente al fondo
            this._sticky = false;
            return true;
        }
        return false;
    }

    /**
     * API publica: hace scroll al inicio de un mensaje especifico por su id.
     * Util para que los componentes padre posicionen la vista al inicio de una respuesta AI.
     */
    @api
    forceScrollToMessage(messageId) {
        // Cancela timers pendientes de scroll-to-bottom para que no sobreescriban este
        this._cancelForceScrollTimers();
        this._sticky = false;
        this._pendingScrollToMessageId = messageId;
        // Intenta inmediatamente en caso de que el DOM ya este renderizado
        const found = this._scrollToMessage(messageId);
        if (found) {
            this._pendingScrollToMessageId = null;
        } else {
            // Reintenta despues de frames / timeouts (el DOM puede no estar listo aun)
            requestAnimationFrame(() => {
                if (this._pendingScrollToMessageId === messageId) {
                    const ok = this._scrollToMessage(messageId);
                    if (ok) this._pendingScrollToMessageId = null;
                }
            });
            setTimeout(() => {
                if (this._pendingScrollToMessageId === messageId) {
                    const ok = this._scrollToMessage(messageId);
                    if (ok) this._pendingScrollToMessageId = null;
                }
            }, 150);
            setTimeout(() => {
                if (this._pendingScrollToMessageId === messageId) {
                    const ok = this._scrollToMessage(messageId);
                    if (ok) this._pendingScrollToMessageId = null;
                }
            }, 400);
        }
    }

    renderedCallback() {
        const list = this.template.querySelector('.list-root');
        if (!list) return;
        
        // Si hay un scroll-to-message pendiente, lo intenta ahora (el DOM deberia estar listo)
        if (this._pendingScrollToMessageId) {
            const found = this._scrollToMessage(this._pendingScrollToMessageId);
            if (found) {
                this._pendingScrollToMessageId = null;
            }
        }

        // Adjunta un MutationObserver una sola vez para detectar cambios de contenido (incluido streaming)
        if (!this._observerAttached) {
            try {
                this._observer = new MutationObserver(() => {
                    // Si estamos esperando hacer scroll a un mensaje especifico, no hace auto-scroll al fondo
                    if (this._pendingScrollToMessageId) {
                        this._scrollToMessage(this._pendingScrollToMessageId);
                        return;
                    }
                    // Solo hace auto-scroll si hay conversacion activa y sticky esta activo
                    const hasConversation = this._messages.length > 1 || 
                                           (this._messages.length === 1 && this._messages[0].role === 'user');
                    if (hasConversation && this._sticky) {
                        this._scrollToBottom();
                    }
                });
                this._observer.observe(list, { childList: true, subtree: true, characterData: true });
                this._observerAttached = true;
            } catch (e) {
                // Ignora si MutationObserver no esta disponible
            }
        }

        // Verifica si debe hacer scroll (solo si no hay scroll-to-message pendiente)
        if (!this._pendingScrollToMessageId) {
            const hasConversation = this._messages.length > 1 || 
                                   (this._messages.length === 1 && this._messages[0].role === 'user');
            
            if (hasConversation && this._sticky) {
                this._scrollToBottom();
            } else if (!hasConversation) {
                this._scrollToTop();
            }
        }
        
        // Inyecta el icono de sparkles desde el recurso estatico
        this._injectSparklesIcon();
    }

    disconnectedCallback() {
        this._cancelForceScrollTimers();
        if (this._observer) {
            try { this._observer.disconnect(); } catch (e) {}
        }
        this._observer = null;
        this._observerAttached = false;
    }

    _injectSparklesIcon() {
        if (this._sparklesInjected || !this.isThinking) {
            return;
        }

        const host = this.template.querySelector('.sparkles-svg');
        if (!host) {
            return;
        }

        const sparklesFiles = ['sparkles.svg', 'Sparkles.svg'];
        
        const trySparklesFile = (index) => {
            if (index >= sparklesFiles.length) {
                // Fallback a SVG inline
                host.innerHTML = `<svg class="sparkles" viewBox="0 0 24 24" aria-hidden="true">
                    <path class="star star-lg" d="M12 3.5 14.3 9 20.5 12 14.3 15 12 20.5 9.7 15 3.5 12 9.7 9Z"/>
                    <path class="star star-s1" d="M18 4.6 18.8 6.6 20.8 7.3 18.8 8.1 18 10.1 17.2 8.1 15.2 7.3 17.2 6.6Z"/>
                    <path class="star star-s2" d="M6 14.7 6.6 16.1 8 16.7 6.6 17.3 6 18.7 5.4 17.3 4 16.7 5.4 16.1Z"/>
                </svg>`;
                this._sparklesInjected = true;
                return;
            }
            
            const svgUrl = `${iconsZip}/${sparklesFiles[index]}`;
            fetch(svgUrl)
                .then((res) => {
                    if (!res.ok) {
                        return trySparklesFile(index + 1);
                    }
                    return res.text();
                })
                .then((raw) => {
                    if (!raw) return;
                    let svg = raw.trim();

                    // Elimina XML/DOCTYPE si esta presente
                    svg = svg.replace(/<\?xml[\s\S]*?\?>/gi, '');
                    svg = svg.replace(/<!DOCTYPE[\s\S]*?>/gi, '');
                    svg = svg.replace(/<script[\s\S]*?<\/script>/gi, '');
                    svg = svg.replace(/\son\w+="[^"]*"/gi, '');
                    svg = svg.replace(/\son\w+='[^']*'/gi, '');

                    // Normaliza stroke/fill a currentColor
                    svg = svg.replace(/(fill|stroke)="(.*?)"/gi, (full, attr, val) => {
                        const v = String(val || '').toLowerCase();
                        if (v === 'none') return full;
                        return `${attr}="currentColor"`;
                    });

                    // Asegura SVG inline con tamaño correcto
                    svg = svg.replace(/<svg([^>]*)>/i, (_m, attrs) => {
                        let a = attrs
                            .replace(/\swidth="[^"]*"/i, '')
                            .replace(/\sheight="[^"]*"/i, '')
                            .replace(/\sclass="[^"]*"/i, '')
                            .trim();
                        return `<svg ${a} class="sparkles" viewBox="0 0 24 24" aria-hidden="true" style="display:block">`;
                    });

                    host.innerHTML = svg;
                    this._sparklesInjected = true;
                })
                .catch(() => trySparklesFile(index + 1));
        };
        
        trySparklesFile(0);
    }

    get hasMessages() {
        return Array.isArray(this._messages) && this._messages.length > 0;
    }

    /**
     * Metodo publico para que el padre (MiniChat) pueda acceder al InlineReport
     * renderizado dentro del Shadow DOM de este componente.
     */
    @api
    getInlineReport() {
        return this.template.querySelector('c-ai-chat-robot2-inline-report');
    }

    /**
     * Metodo publico para forzar scroll al fondo de la lista de mensajes.
     * Llamado por MiniChat despues de insertar un marcador de reporte o cuando sea necesario.
     */
    @api
    forceScrollToBottom() {
        this._pendingScrollToMessageId = null;
        this._sticky = true;
        this._forceScroll();
    }

    // Ya no hay acciones en el footer; sugerencias y acciones ahora son por mensaje

    get hasAiMessage() {
        return !!this.lastAiMessage;
    }

    get messagesWithFlags() {
        if (!this.hasMessages) return [];
        
        // Si solo hay un mensaje y es AI, se marca como bienvenida
        const isOnlyOneMessage = this._messages.length === 1;
        
        // Filtra el mensaje de bienvenida si hay mas mensajes
        let messagesToShow = this._messages;
        if (!isOnlyOneMessage) {
            // Remueve el primer mensaje AI si era el mensaje de bienvenida
            const firstAiIndex = this._messages.findIndex(m => m.role === 'ai');
            if (firstAiIndex === 0) {
                messagesToShow = this._messages.slice(1);
            }
        }
        
        let marked = false;
        return messagesToShow.map((m) => {
            // Placeholder de reporte — se pasa con flag _isReport
            if (m.role === 'report') {
                return { ...m, _isReport: true };
            }
            if (!marked && m.role === 'ai' && isOnlyOneMessage) {
                marked = true;
                return { ...m, _isWelcome: true };
            }
            return { ...m, _isReport: false };
        });
    }

    handleOpenReportInModal(event) {
        // Re-despacha el evento para que MiniChat pueda manejarlo
        this.dispatchEvent(new CustomEvent('openreportinmodal', {
            bubbles: true,
            composed: true
        }));
    }

    
}