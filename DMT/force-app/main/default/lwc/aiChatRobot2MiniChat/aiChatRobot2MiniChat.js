/* eslint-disable one-var,no-console,no-undef,no-underscore-dangle,class-methods-use-this,sort-imports,id-length,no-magic-numbers,sort-keys*/

import { LightningElement, track, api, wire } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { CurrentPageReference } from 'lightning/navigation';
import aiChatRobot2_Title from '@salesforce/label/c.aiChatRobot2_Title';
import aiChatRobot2_Welcome from '@salesforce/label/c.aiChatRobot2_Welcome';
import aiChatRobot2_StatusReady from '@salesforce/label/c.aiChatRobot2_StatusReady';
import aiChatRobot2_StatusThinking from '@salesforce/label/c.aiChatRobot2_StatusThinking';
import aiChatRobot2_Err_ResponseProcessing from '@salesforce/label/c.aiChatRobot2_Err_ResponseProcessing';
import aiChatRobot2_Err_Timeout from '@salesforce/label/c.aiChatRobot2_Err_Timeout';
import aiChatRobot2_RequestReport from '@salesforce/label/c.aiChatRobot2_RequestReport';
import aiChatRobot2_ShowReport from '@salesforce/label/c.aiChatRobot2_ShowReport';
import aiChatRobot2_MiniChatTitle from '@salesforce/label/c.aiChatRobot2_MiniChatTitle';
import aiChatRobot2_Loading from '@salesforce/label/c.aiChatRobot2_Loading';
import getContextData from '@salesforce/apex/aiChatRobot2Controller.getContextData';
import saveContext from '@salesforce/apex/aiChatRobot2Controller.saveConversationContext';
import makeServiceRequest from '@salesforce/apex/aiChatRobot2Controller.makeServiceRequest';
import AiChatRobot2ExpandedModal from 'c/aiChatRobot2ExpandedModal';
import iconsZip from '@salesforce/resourceUrl/aiChatRobot2Icons';

export default class AiChatRobot2MiniChat extends LightningElement {
    // --- Estado ---
    @track messages = [];
    @track isThinking = false;
    @track selectedLanguage = 'EN';
    @track languageLocked = false;
    @track isSummaryOpen = false;
    @track hasSummaryData = false;
    @track hasRequestedReport = false;
    @track isConversationBlocked = false;
    @track isExpanded = false; // true cuando el modal esta abierto
    @track chatActivated = false; // false = mostrar boton lanzador

    _firstName;
    conversationId = null;
    subscription = null;
    lastSummaryData = null;
    summaryMessages = [];
    @api recordId;
    _pageRef;
    accountName;
    _userKey;
    _groupId;
    _lastMessageFromUser = true;
    _conversationRecordId = null;
    _userMessageCounter = 0;
    _error;
    _isFirstMessage = true;
    _timeoutHandle = null;
    _timeoutMs = null;
    _textInputCharLimit = null;
    _resizeHandler;
    _reportMarkerId = null;
    _launcherLogoInjected = false;
    _editIconInjected = false;
    @track _launcherLoading = false;
    _empApiErrorRegistered = false;
    _resubscribeAttempts = 0;

    // Datos de contexto del usuario para comentarios
    userKey = null;
    userCountry = null;
    userSegment = null;

    label = {
        aiChatRobot2_Title,
        aiChatRobot2_StatusReady,
        aiChatRobot2_StatusThinking,
        aiChatRobot2_Err_ResponseProcessing,
        aiChatRobot2_Err_Timeout,
        aiChatRobot2_RequestReport,
        aiChatRobot2_ShowReport,
        aiChatRobot2_MiniChatTitle,
        aiChatRobot2_Loading
    };

    // --- Ciclo de vida ---
    connectedCallback() {
        // Configura inicialmente solo el manejador de resize (alto del boton lanzador)
        this._resizeHandler = () => this._updateAvailableHeight();
        window.addEventListener('resize', this._resizeHandler);
    }

    /** Activa el chat: carga contexto, se suscribe a eventos y muestra la UI */
    handleActivateChat() {
        this._launcherLoading = true;
        this._initializeChat();
    }

    /** Obtiene la clase CSS del boton lanzador */
    get launcherBtnClass() {
        return `launcher-button${this._launcherLoading ? ' launcher-loading' : ''}`;
    }

    _initializeChat() {
        if (!this.conversationId) {
            getContextData({ recordId: this.recordId })
                .then(response => {
                    if (!response.error) {
                        this.conversationId = response.conversationId;
                        this.accountName = response.clientName;
                        this._userKey = response.userKey;
                        this._groupId = response.clientGroupId;
                        this._firstName = (response.userFirstName || '').trim();

                        this.userKey = response.userKey;
                        this.userCountry = response.userCountry || 'ESP';
                        this.userSegment = response.clientGroupId || 'CIB';

                        const welcome = this._buildWelcome();
                        this.messages = [this._makeMsg('ai', welcome, true)];

                        const timeoutS = Number(response?.timeoutS);
                        this._timeoutMs = Number.isFinite(timeoutS) && timeoutS > 0 ? timeoutS * 1000 : null;

                        const charLimit = Number(response?.textInputCharLimit);
                        this._textInputCharLimit = Number.isFinite(charLimit) && charLimit > 0 ? charLimit : null;
                    } else {
                        this._error = response.error;
                        console.warn('Error al obtener el contexto: ', this._error);
                        this._errorManager({ detail: 'Error en la obtención del contexto de la conversación.' });
                    }
                })
                .catch(() => {
                    this._firstName = '';
                    this._timeoutMs = null;
                    const welcome = this._buildWelcome();
                    this.messages = [this._makeMsg('ai', welcome, true)];
                })
                .finally(() => {
                    this._launcherLoading = false;
                    this.chatActivated = true;
                    window.requestAnimationFrame(() => this._updateAvailableHeight());
                });
        }

        this._subscribeToPlatformEvent();
    }

    disconnectedCallback() {
        this._clearTimeoutTimer();
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('Desuscrito del canal Platform Event:', response);
            });
        }
        if (this._resizeHandler) {
            window.removeEventListener('resize', this._resizeHandler);
        }
    }

    renderedCallback() {
        this._updateAvailableHeight();
        this._injectLauncherLogo();
        this._injectEditIcon();
    }

    /** Inyecta el SVG del logo variant2 en el boton lanzador */
    _injectLauncherLogo() {
        if (this._launcherLogoInjected || this.chatActivated) return;
        const host = this.template.querySelector('.launcher-logo');
        if (!host) return;

        const possibleFiles = ['robot.svg', 'Robot.svg', 'Property 1=robot.svg'];
        const tryNextFile = (index) => {
            if (index >= possibleFiles.length) return;
            const svgUrl = `${iconsZip}/${possibleFiles[index]}`;
            fetch(svgUrl)
                .then(res => {
                    if (!res.ok) return tryNextFile(index + 1);
                    return res.text();
                })
                .then(raw => {
                    if (!raw) return;
                    let svg = raw.trim();
                    svg = svg.replace(/<\?xml[\s\S]*?\?>/gi, '');
                    svg = svg.replace(/<!DOCTYPE[\s\S]*?>/gi, '');
                    svg = svg.replace(/<script[\s\S]*?<\/script>/gi, '');
                    svg = svg.replace(/\son\w+="[^"]*"/gi, '');
                    svg = svg.replace(/\son\w+='[^']*'/gi, '');
                    const el = this.template.querySelector('.launcher-logo');
                    if (el) {
                        el.innerHTML = svg;
                        this._launcherLogoInjected = true;
                    }
                })
                .catch(() => tryNextFile(index + 1));
        };
        tryNextFile(0);
    }

    /** Inyecta el SVG del icono editar en el boton de nuevo chat (igual que en sidebar) */
    _injectEditIcon() {
        if (this._editIconInjected || !this.chatActivated) return;
        const host = this.template.querySelector('.new-chat-icon');
        if (!host) return;

        const editFiles = ['edit.svg', 'Edit.svg'];
        const tryEditFile = (index) => {
            if (index >= editFiles.length) {
                // Alternativa: icono lapiz inline
                host.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path>
                </svg>`;
                this._editIconInjected = true;
                return;
            }
            const svgUrl = `${iconsZip}/${editFiles[index]}`;
            fetch(svgUrl)
                .then(res => {
                    if (!res.ok) return tryEditFile(index + 1);
                    return res.text();
                })
                .then(raw => {
                    if (!raw) return;
                    let svg = raw.trim();
                    svg = svg.replace(/<\?xml[\s\S]*?\?>/gi, '');
                    svg = svg.replace(/<!DOCTYPE[\s\S]*?>/gi, '');
                    svg = svg.replace(/<script[\s\S]*?<\/script>/gi, '');
                    svg = svg.replace(/\son\w+="[^"]*"/gi, '');
                    svg = svg.replace(/\son\w+='[^']*'/gi, '');
                    svg = svg.replace(/(fill|stroke)="(.*?)"/gi, (full, attr, val) => {
                        const v = String(val || '').toLowerCase();
                        if (v === 'none') return full;
                        return `${attr}="currentColor"`;
                    });
                    svg = svg.replace(/<svg([^>]*)>/i, (_m, attrs) => {
                        let a = attrs
                            .replace(/\swidth="[^"]*"/i, '')
                            .replace(/\sheight="[^"]*"/i, '')
                            .trim();
                        return `<svg ${a} width="18" height="18" role="img" aria-label="New chat" focusable="false" style="display:block">`;
                    });
                    const el = this.template.querySelector('.new-chat-icon');
                    if (el) {
                        el.innerHTML = svg;
                        this._editIconInjected = true;
                    }
                })
                .catch(() => tryEditFile(index + 1));
        };
        tryEditFile(0);
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        this._pageRef = pageRef;
        const state = pageRef?.state || {};
        if (!this.recordId && state.c__recordId) {
            this.recordId = state.c__recordId;
        }
    }

    // --- Calculados ---
    get titleText() {
        return this.label.aiChatRobot2_MiniChatTitle;
    }

    get inputDisabled() {
        return this.isThinking || this.isConversationBlocked;
    }

    get showLanguageSelector() {
        return !this.languageLocked;
    }

    get showRequestReportButton() {
        return true;
    }

    get isReportButtonDisabled() {
        return !this.hasRequestedReport && (this.isThinking || this.isConversationBlocked);
    }

    get reportButtonLabel() {
        return this.hasRequestedReport ? this.label.aiChatRobot2_ShowReport : this.label.aiChatRobot2_RequestReport;
    }

    get reportButtonClass() {
        return this.hasRequestedReport ? 'request-report-button report-recalled' : 'request-report-button';
    }

    get footerClass() {
        return this.languageLocked ? 'input-footer fixed' : 'input-footer';
    }

    get layoutClass() {
        return 'mini-chat-layout';
    }

    // --- Manejadores: Encabezado ---
    handleNewConversation() {
        this._clearTimeoutTimer();
        this.isConversationBlocked = false;
        this._conversationRecordId = null;
        this._isFirstMessage = true;
        this.conversationId = null;
        this._resubscribeAttempts = 0;

        const welcome = this._buildWelcome();
        this.messages = [this._makeMsg('ai', welcome, true)];
        this.isThinking = false;
        this.languageLocked = false;

        this.hasRequestedReport = false;
        this.hasSummaryData = false;
        this.isSummaryOpen = false;
        this.lastSummaryData = null;
        this.summaryMessages = [];
        this._reportMarkerId = null;

        const inlineReport = this._getInlineReport();
        if (inlineReport) {
            inlineReport.reset();
        }

        getContextData({ recordId: this.recordId }).then(response => {
            if (!response.error) {
                this.conversationId = response.conversationId;
                this.accountName = response.clientName;
                this._userKey = response.userKey;
                this._groupId = response.clientGroupId;
                this._firstName = (response.userFirstName || '').trim();
                this.userKey = response.userKey;
                this.userCountry = response.userCountry || 'ESP';
                this.userSegment = response.clientGroupId || 'CIB';

                const charLimit = Number(response?.textInputCharLimit);
                this._textInputCharLimit = Number.isFinite(charLimit) && charLimit > 0 ? charLimit : null;
            }
        });
    }

    // --- Manejadores: Maximizar / Minimizar ---
    async handleMaximize() {
        this.isExpanded = true;
        try {
            // Desuscribe el MiniChat del Platform Event mientras el modal está abierto
            // para evitar que ambos componentes procesen el mismo evento simultáneamente
            if (this.subscription) {
                unsubscribe(this.subscription, () => {});
                this.subscription = null;
            }

            // Lee el estado expandido/colapsado de InlineReport antes de abrir el modal
            const inlineReport = this._getInlineReport();
            const reportExpanded = inlineReport ? inlineReport.isExpanded : false;

            const result = await AiChatRobot2ExpandedModal.open({
                size: 'full',
                label: this.titleText,
                // Pasa todo el estado del chat
                chatMessages: [...this.messages],
                chatIsThinking: this.isThinking,
                chatSelectedLanguage: this.selectedLanguage,
                chatLanguageLocked: this.languageLocked,
                chatConversationId: this.conversationId,
                chatAccountName: this.accountName,
                chatUserKey: this.userKey,
                chatUserCountry: this.userCountry,
                chatUserSegment: this.userSegment,
                chatInputDisabled: this.inputDisabled,
                chatCharLimit: this._textInputCharLimit,
                chatIsSummaryOpen: this.isSummaryOpen,
                chatHasSummaryData: this.hasSummaryData,
                chatHasRequestedReport: this.hasRequestedReport,
                chatSummaryMessages: this.summaryMessages ? [...this.summaryMessages] : [],
                chatLastSummaryData: this.lastSummaryData,
                chatIsConversationBlocked: this.isConversationBlocked,
                chatReportExpanded: reportExpanded
            });

            // Restaura el estado desde el modal cuando se cierra
            if (result) {
                this.messages = result.messages || this.messages;
                this.isThinking = result.isThinking ?? this.isThinking;
                this.selectedLanguage = result.selectedLanguage || this.selectedLanguage;
                this.languageLocked = result.languageLocked ?? this.languageLocked;
                this.isSummaryOpen = result.isSummaryOpen ?? this.isSummaryOpen;
                this.hasSummaryData = result.hasSummaryData ?? this.hasSummaryData;
                this.hasRequestedReport = result.hasRequestedReport ?? this.hasRequestedReport;
                this.summaryMessages = result.summaryMessages || this.summaryMessages;
                this.lastSummaryData = result.lastSummaryData ?? this.lastSummaryData;
                this.isConversationBlocked = result.isConversationBlocked ?? this.isConversationBlocked;

                // Si se solicito reporte (posiblemente desde modal) pero no hay marcador de reporte
                // en los mensajes, inyecta uno para que InlineReport se renderice en MiniChat
                if (this.hasRequestedReport) {
                    const hasMarker = this.messages.some(m => m.role === 'report');
                    if (!hasMarker) {
                        const reportMarker = {
                            id: `report-${Date.now()}`,
                            role: 'report',
                            text: '',
                            timestamp: new Date().toISOString()
                        };
                        this._reportMarkerId = reportMarker.id;
                        this.messages = [...this.messages, reportMarker];
                    }
                }

                // Vuelve a renderizar el reporte inline con el ultimo resumen (o estado de carga)
                if (this.hasRequestedReport) {
                    const hasSummaryData = this.summaryMessages && this.summaryMessages.length > 0;
                    // Respeta el estado del sidebar al cerrar el modal:
                    // si el usuario lo cerró dentro del modal, aparece colapsado en MiniChat.
                    // Si no hay dato de expanded en el result (ej: reporte pedido desde MiniChat),
                    // por defecto se expande solo si hay datos.
                    const reportExpState = result.reportExpanded ?? hasSummaryData;
                    // Usa multiples rAF + setTimeout para esperar el marcador de reporte
                    // para que renderice y el componente InlineReport este disponible
                    window.requestAnimationFrame(() => {
                        setTimeout(() => {
                            const ir = this._getInlineReport();
                            if (ir) {
                                if (hasSummaryData) {
                                    ir.summaryMessages = this.summaryMessages;
                                    ir.isLoading = false;
                                } else {
                                    // Se solicito reporte pero aun no hay datos: mostrar carga
                                    ir.showLoading();
                                }
                                window.requestAnimationFrame(() => {
                                    ir.isExpanded = reportExpState;
                                    this._forceMessageListScroll();
                                });
                            }
                        }, 150);
                    });
                }
            }
        } catch (err) {
            console.error('Error opening expanded modal:', err);
        } finally {
            this.isExpanded = false;
            // Re-subscribe el MiniChat ahora que el modal ya se cerró
            this._subscribeToPlatformEvent();
        }
    }

    // --- Manejadores: Conversacion ---
    handleSend(event) {
        const text = event.detail?.text?.trim();
        if (!text) return;
        if (this.isConversationBlocked) return;

        if (!this.languageLocked) {
            this.languageLocked = true;
        }
        // Reemplazamos los caracteres especiales que pueden romper el funcionamiento como los saltos de línea y los caracteres: " y \
        const escappedText = text.replace(/(\r\n|\r|\n)/g, '  ').replace(/\\/g, '/').replaceAll('"', '\'');
        const language = this.selectedLanguage || 'EN';
        const userMessage = this._makeMsg('user', escappedText, false);
        userMessage.language = language;

        this.isThinking = true;
        this._saveConversationContext(true);
        this._sendOBMessage(userMessage);
        this.messages = [...this.messages, this._makeMsg('user', escappedText, false)];
        this._startTimeoutTimer();
        // Fuerza scroll para que el mensaje nuevo + "Thinking..." sean visibles
        this._forceMessageListScroll();
    }

    handleLanguageChange(event) {
        const { language } = event.detail || {};
        if (language && !this.languageLocked) {
            this.selectedLanguage = language;
        }
    }

    handleSuggestionSelect(event) {
        const text = event.detail?.text;
        if (!text) return;
        this.handleSend({ detail: { text } });
    }

    handleFeedback() { /* manejado por el hijo */ }
    handleFeedbackSent(event) {
        const { messageId, feedbackState } = event.detail || {};
        this._markMessageFeedbackSent(messageId, feedbackState);
    }
    handleCopied() { /* manejado por el hijo */ }

    _markMessageFeedbackSent(messageId, feedbackState) {
        if (!messageId || !Array.isArray(this.messages)) return;

        this.messages = this.messages.map(message => {
            if (message.id !== messageId) {
                return message;
            }

            return {
                ...message,
                feedbackState: feedbackState ?? message.feedbackState ?? null,
                feedbackLocked: true
            };
        });
    }

    // --- Manejadores: Reporte / Resumen ---
    /** Dispatcher del botón de reporte: primera vez llama al servicio, las siguientes re-muestra el reporte cacheado */
    handleReportButtonClick() {
        if (this.isReportButtonDisabled) return;
        if (this.hasRequestedReport) {
            this.handleShowReport();
        } else {
            this.handleRequestReport();
        }
    }

    handleRequestReport() {
        if (this.isReportButtonDisabled) return;
        this.hasRequestedReport = true;
        // Desactivamos el input de texto mientras dura la petición y procesamiento
        this.isThinking = true;

        // Inserta un mensaje marcador de reporte en la posicion actual del flujo de chat
        const reportMarker = {
            id: `report-${Date.now()}`,
            role: 'report',
            text: '',
            timestamp: new Date().toISOString()
        };
        this._reportMarkerId = reportMarker.id;
        this.messages = [...this.messages, reportMarker];

        const reportRequestMessage = this._makeMsg('user', '', false);
        reportRequestMessage.language = this.selectedLanguage || 'EN';

        this.isSummaryOpen = true;

        window.requestAnimationFrame(() => {
            const inlineReport = this._getInlineReport();
            if (inlineReport) {
                inlineReport.showLoading();
            }
            // Fuerza scroll al final despues de renderizar la tarjeta de reporte
            this._forceMessageListScroll();
        });

        this._saveConversationContext(true);
        this._startTimeoutTimer();
        this._sendOBMessageForReport(reportRequestMessage);
    }

    handleOpenReportInModal() {
        this.handleMaximize();
    }

    /** Mueve el marcador de reporte existente al final del chat y hace scroll */
    handleShowReport() {
        if (!this.hasSummaryData || !this.summaryMessages || this.summaryMessages.length === 0) return;

        // Busca el marcador de reporte existente y lo mueve al final del array
        const reportIndex = this.messages.findIndex(m => m.role === 'report');
        if (reportIndex === -1) return;

        const reportMarker = this.messages[reportIndex];
        const withoutReport = this.messages.filter((_, i) => i !== reportIndex);
        this.messages = [...withoutReport, reportMarker];

        // Re-inyecta los datos y fuerza expansión tras el re-render con varios intentos
        // (LWC puede recrear el componente al moverlo, perdiendo el estado interno)
        const forceExpand = () => {
            const inlineReport = this._getInlineReport();
            if (inlineReport) {
                inlineReport.summaryMessages = [...this.summaryMessages];
                inlineReport.isLoading = false;
                inlineReport.isExpanded = true;
                this._forceMessageListScroll();
            }
        };

        window.requestAnimationFrame(() => {
            forceExpand();
            setTimeout(forceExpand, 100);
            setTimeout(forceExpand, 300);
        });
    }

    /** Encuentra el componente InlineReport dentro de MessageList via API publica */
    _getInlineReport() {
        const messageList = this.template.querySelector('c-ai-chat-robot2-message-list');
        if (messageList) {
            return messageList.getInlineReport();
        }
        return null;
    }

    /** Fuerza que MessageList haga scroll al final */
    _forceMessageListScroll() {
        const ml = this.template.querySelector('c-ai-chat-robot2-message-list');
        if (!ml) return;
        ml.forceScrollToBottom();
    }

    /** Fuerza que MessageList haga scroll al inicio de un mensaje especifico (por id) */
    _forceMessageListScrollToMessage(messageId) {
        const ml = this.template.querySelector('c-ai-chat-robot2-message-list');
        if (!ml) return;
        ml.forceScrollToMessage(messageId);
    }

    // --- Evento de plataforma ---
    _subscribeToPlatformEvent() {
        // Guard: evita crear suscripciones duplicadas
        if (this.subscription) return;

        const channelName = '/event/Chatbot_AI_Banker__e';

        // Registra el handler global de errores de empApi una sola vez
        if (!this._empApiErrorRegistered) {
            this._empApiErrorRegistered = true;
            onError(error => {
                console.error('Error en empApi:', JSON.stringify(error));
                // Intenta resuscribirse automaticamente ante desconexion del canal
                this._handleEmpApiDisconnect();
            });
        }

        subscribe(channelName, -1, event => {
            try {
                const payloadData = event?.data;
                if (!payloadData) {
                    this._errorManager({ detail: "La respuesta no contiene una estructura válida." });
                    return;
                }

                if (payloadData && payloadData.payload) {
                    const payload = payloadData.payload;
                    const convoId = payload.ConversationId__c;

                    if (!payload.ErrorStatus__c && !payload.ErrorDescription__c) {
                        const message = payload.Content__c;
                        let explicability = null;
                        if (payload.Explicability__c) {
                            try {
                                explicability = JSON.parse(payload.Explicability__c);
                            } catch (e) {
                                console.warn('Error parsing explicability JSON:', e);
                            }
                        }
                        const mode = payload.Mode__c;

                        if (convoId && convoId === this.conversationId) {
                            if (this.isConversationBlocked) return;
                            this._clearTimeoutTimer();

                            if (mode === 'SUMMARY') {
                                if (!this.summaryMessages) this.summaryMessages = [];
                                this.summaryMessages.push({
                                    messageId: payload.MessageId__c,
                                    content: message
                                });
                                this._handleSummaryEvent({
                                    messageId: payload.MessageId__c,
                                    content: message
                                });
                            } else if (mode === 'FINAL_ANSWER') {
                                // Si hay un informe pendiente sin datos, resetearlo silenciosamente
                                // para que no quede en estado de carga infinito
                                if (this.hasRequestedReport && (!this.summaryMessages || this.summaryMessages.length === 0)) {
                                    this._resetReportState();
                                }

                                const aiMsg = this._makeMsg('ai', message, false, explicability);
                                this.messages = [
                                    ...this.messages,
                                    aiMsg
                                ];
                                this._saveConversationContext(false);
                                this.isThinking = false;
                                // Scroll to the top of the new AI message so the user reads from the beginning
                                this._forceMessageListScrollToMessage(aiMsg.id);
                            }
                        }
                    } else {
                        this._errorManager({
                            status: payload.ErrorStatus__c,
                            description: payload.ErrorDescription__c,
                            detail: payload.ErrorDetail__c
                        });
                    }
                }
            } catch (err) {
                console.error('Error procesando evento:', err);
            }
        }).then(response => {
            this.subscription = response;
            this._resubscribeAttempts = 0; // Reset contador de reintentos tras suscripcion exitosa
        });
    }

    /** Intenta resuscribirse al canal de Platform Events tras una desconexion de empApi */
    _handleEmpApiDisconnect() {
        const MAX_RESUBSCRIBE_ATTEMPTS = 3;
        const RESUBSCRIBE_DELAY_MS = 3000;

        // Si ya esta bloqueada la conversacion (por error previo), no intenta resuscribir
        if (this.isConversationBlocked) return;

        this._resubscribeAttempts = (this._resubscribeAttempts || 0) + 1;

        if (this._resubscribeAttempts <= MAX_RESUBSCRIBE_ATTEMPTS) {
            console.warn(`empApi desconectado. Intento de resuscripcion ${this._resubscribeAttempts}/${MAX_RESUBSCRIBE_ATTEMPTS}...`);
            // Desuscribe la referencia anterior (si existe) antes de resuscribir
            if (this.subscription) {
                unsubscribe(this.subscription, () => {});
                this.subscription = null;
            }
            setTimeout(() => {
                this._subscribeToPlatformEvent();
            }, RESUBSCRIBE_DELAY_MS);
        } else {
            console.error('empApi: se agotaron los intentos de resuscripcion.');
            this._errorManager({ detail: 'Error en la suscripción al evento de plataforma.' });
        }
    }

    _handleSummaryEvent(summaryData) {
        if (!this.summaryMessages) this.summaryMessages = [];
        const exists = this.summaryMessages.some(m => m.messageId === summaryData.messageId);
        if (!exists) {
            this.summaryMessages.push(summaryData);
        }
        this.lastSummaryData = summaryData;
        this.hasSummaryData = true;

        const inlineReport = this._getInlineReport();
        if (inlineReport) {
            inlineReport.addMessage(summaryData);
            // Scroll al final despues de actualizar el contenido del reporte
            this._forceMessageListScroll();
        }
        // Reactivamos el input tras procesar el informe
        this.isThinking = false;
    }

    /** Resetea silenciosamente el estado del informe cuando la respuesta no es SUMMARY.
     *  Elimina el marcador de reporte del chat, resetea los flags y el InlineReport
     *  para que el usuario pueda volver a solicitar el informe desde el botón. */
    _resetReportState() {
        // Resetear el componente InlineReport si existe
        const inlineReport = this._getInlineReport();
        if (inlineReport) {
            inlineReport.reset();
        }

        // Eliminar el marcador de reporte de los mensajes del chat
        this.messages = this.messages.filter(m => m.role !== 'report');

        // Resetear todos los flags relacionados con el informe
        this.hasRequestedReport = false;
        this.hasSummaryData = false;
        this.isSummaryOpen = false;
        this.lastSummaryData = null;
        this.summaryMessages = [];
        this._reportMarkerId = null;
    }

    /** Resetea silenciosamente el estado del informe cuando la respuesta no es SUMMARY.
     *  Elimina el marcador de reporte del chat, resetea los flags y el InlineReport
     *  para que el usuario pueda volver a solicitar el informe desde el botón. */
    _resetReportState() {
        // Resetear el componente InlineReport si existe
        const inlineReport = this._getInlineReport();
        if (inlineReport) {
            inlineReport.reset();
        }

        // Eliminar el marcador de reporte de los mensajes del chat
        this.messages = this.messages.filter(m => m.role !== 'report');

        // Resetear todos los flags relacionados con el informe
        this.hasRequestedReport = false;
        this.hasSummaryData = false;
        this.isSummaryOpen = false;
        this.lastSummaryData = null;
        this.summaryMessages = [];
        this._reportMarkerId = null;
    }

    // --- Llamadas Apex ---
    _saveConversationContext(lastMessageFromUser) {
        this._lastMessageFromUser = lastMessageFromUser;
        saveContext({
            recordId: this._conversationRecordId,
            conversationId: this.conversationId,
            groupId: this._groupId,
            userKey: this._userKey,
            isLastMessageFromUser: this._lastMessageFromUser
        }).then(response => {
            if (!response.error) {
                this._conversationRecordId = response.recordId;
            } else {
                this._error = response.error;
                console.warn('Error al guardar el contexto: ', this._error);
            }
        });
    }

    _sendOBMessage (userMessage) {
        // Determina si es una conversacion nueva o existente
        const isNewConversation = this._isFirstMessage ? true : false;
        // Actualiza la variable de control
        this._isFirstMessage = false;
        
        // Construye el mensaje
        const requestBody =  {
            conversationId: this.conversationId,
            showSummary : this.isSummaryOpen, // Envía true si el sidebar de summary está abierto, false si está cerrado
            channel: 'GLOBAL_DESKTOP',
            isNewConversation : isNewConversation,
            userId: this._userKey, 	       
            userCountry: this.userCountry,	   
            userSegment: this.userSegment,
            messageId: userMessage.id,
            content: userMessage.text,
            companyId: this._groupId,
            companyName: this.accountName,
            language: userMessage.language
        };

        // Invoca el metodo Apex para enviar la solicitud
        makeServiceRequest({ serviceName: 'obmessage', requestBody: requestBody }).then(response => {
            if (response.isError) {
                this._errorManager({ detail: "Ha fallado la comunicación con el servicio." });
                return;
            }
        });
    }

    _sendOBMessageForReport(userMessage) {
        const isNewConversation = this._isFirstMessage;
        this._isFirstMessage = false;
        const requestBody = {
            conversationId: this.conversationId,
            isNewConversation: isNewConversation,
            showSummary: true,
            channel: 'GLOBAL_DESKTOP',
            language: userMessage.language,
            userId: this._userKey,
            userCountry: this.userCountry,
            userSegment: this.userSegment,
            messageId: userMessage.id,
            content: '',
            companyId: this._groupId,
            companyName: this.accountName
        };
        makeServiceRequest({ serviceName: 'obmessage', requestBody: requestBody }).then(response => {
            if (response.isError) {
                this._errorManager({ detail: "Ha fallado la comunicación con el servicio." });
                return;
            }
        });
    }

    // --- Utilidades ---
    _makeMsg(role, text, isMocked, explicability = null) {
        return {
            id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
            role,
            text,
            isMocked,
            explicability,
            timestamp: new Date().toISOString()
        };
    }

    _formatLabel(template, ...args) {
        if (!template) return '';
        return String(template).replace(/\{(\d+)\}/g, (m, i) => {
            const idx = Number(i);
            return args[idx] != null ? String(args[idx]) : '';
        });
    }

    _normalizeSpaces(s) {
        if (s == null) return '';
        return String(s).replace(/,(?=\S)/g, ', ').replace(/\s{2,}/g, ' ').trim();
    }

    _buildWelcome() {
        const name = (this._firstName || '').trim();
        const formatted = this._formatLabel(aiChatRobot2_Welcome, name);
        return this._normalizeSpaces(formatted);
    }

    _errorManager(serviceError) {
        console.error('Error:', JSON.stringify(serviceError));
        // Evita cascada de mensajes de error si la conversacion ya esta bloqueada
        if (this.isConversationBlocked) return;

        const userErrorMessage = this.label.aiChatRobot2_Err_ResponseProcessing;
        this.messages = [...this.messages, this._makeMsg('ai', userErrorMessage, true)];
        this.isThinking = false;
        this.isConversationBlocked = true;
        this._conversationRecordId = null;
        this._isFirstMessage = true;
        this._clearTimeoutTimer();
    }

    _startTimeoutTimer() {
        this._clearTimeoutTimer();
        if (!this._timeoutMs || this.isConversationBlocked) return;
        this._timeoutHandle = window.setTimeout(() => {
            this._handleTimeout();
        }, this._timeoutMs);
    }

    _clearTimeoutTimer() {
        if (this._timeoutHandle) {
            window.clearTimeout(this._timeoutHandle);
            this._timeoutHandle = null;
        }
    }

    _handleTimeout() {
        if (this.isConversationBlocked) return;
        const timeoutMsg = this._makeMsg('ai', this.label.aiChatRobot2_Err_Timeout, true);
        timeoutMsg.isTimeout = true;
        this.messages = [...this.messages, timeoutMsg];
        this.isThinking = false;
        this.isConversationBlocked = true;
        this._conversationRecordId = null;
        this._isFirstMessage = true;
        this._clearTimeoutTimer();
    }

    _updateAvailableHeight() {
        if (!this.template || !this.template.host) return;
        window.requestAnimationFrame(() => {
            const host = this.template.host;
            if (!host) return;
            const rect = host.getBoundingClientRect();
            // Espacio disponible desde el borde superior del componente hasta el fondo del viewport
            const available = window.innerHeight - rect.top - 20; // margen de 20px
            const height = Math.max(350, Math.min(available, window.innerHeight - 150));
            host.style.setProperty('--mini-chat-height', `${height}px`);
        });
    }
}