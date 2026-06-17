/* eslint-disable one-var,no-console,no-undef,no-underscore-dangle,class-methods-use-this,sort-imports,id-length,no-magic-numbers,sort-keys*/

import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import aiChatRobot2_Title from '@salesforce/label/c.aiChatRobot2_Title';
import aiChatRobot2_RequestReport from '@salesforce/label/c.aiChatRobot2_RequestReport';
import aiChatRobot2_MiniChatTitle from '@salesforce/label/c.aiChatRobot2_MiniChatTitle';
import aiChatRobot2_ShowReport from '@salesforce/label/c.aiChatRobot2_ShowReport';
import makeServiceRequest from '@salesforce/apex/aiChatRobot2Controller.makeServiceRequest';
import saveContext from '@salesforce/apex/aiChatRobot2Controller.saveConversationContext';

const TIMEOUT_MESSAGE = 'No hemos recibido respuesta a tiempo del servicio. Esta conversación ha sido cerrada. Inicia una nueva conversación.';

export default class AiChatRobot2ExpandedModal extends LightningModal {
    // --- Propiedades recibidas del padre (MiniChat) ---
    @api chatMessages = [];
    @api chatIsThinking = false;
    @api chatSelectedLanguage = 'EN';
    @api chatLanguageLocked = false;
    @api chatConversationId;
    @api chatAccountName;
    @api chatUserKey;
    @api chatUserCountry;
    @api chatUserSegment;
    @api chatInputDisabled = false;
    @api chatCharLimit;
    @api chatIsSummaryOpen = false;
    @api chatHasSummaryData = false;
    @api chatHasRequestedReport = false;
    @api chatSummaryMessages = [];
    @api chatLastSummaryData;
    @api chatIsConversationBlocked = false;

    // --- Estado local reactivo (copia mutable de props) ---
    @track messages = [];
    @track isThinking = false;
    @track selectedLanguage = 'EN';
    @track languageLocked = false;
    @track isSummaryOpen = false;
    @track hasSummaryData = false;
    @track hasRequestedReport = false;
    @track isConversationBlocked = false;
    @track summaryMessages = [];

    conversationId;
    accountName;
    userKey;
    userCountry;
    userSegment;
    charLimit;
    lastSummaryData;
    subscription = null;
    _isFirstMessage = true;
    _userKey;
    _groupId;
    _conversationRecordId;
    _lastMessageFromUser = true;
    _timeoutHandle = null;
    _timeoutMs = null;
    _summaryRestored = false;
    _empApiErrorRegistered = false;
    _resubscribeAttempts = 0;
    _labels = {};

    // --- Ciclo de vida ---
    connectedCallback() {
        super.connectedCallback();
        this._labels = {
            aiChatRobot2_MiniChatTitle,
            aiChatRobot2_RequestReport,
            aiChatRobot2_ShowReport
        };
        this.messages = this.chatMessages ? [...this.chatMessages] : [];
        this.isThinking = this.chatIsThinking;
        this.selectedLanguage = this.chatSelectedLanguage;
        this.languageLocked = this.chatLanguageLocked;
        this.conversationId = this.chatConversationId;
        this.accountName = this.chatAccountName;
        this.userKey = this.chatUserKey;
        this.userCountry = this.chatUserCountry;
        this.userSegment = this.chatUserSegment;
        this.charLimit = this.chatCharLimit;
        this.isSummaryOpen = this.chatIsSummaryOpen;
        this.hasSummaryData = this.chatHasSummaryData;
        this.hasRequestedReport = this.chatHasRequestedReport;
        this.summaryMessages = this.chatSummaryMessages ? [...this.chatSummaryMessages] : [];
        this.lastSummaryData = this.chatLastSummaryData;
        this.isConversationBlocked = this.chatIsConversationBlocked;

        this._userKey = this.userKey;
        this._groupId = this.userSegment;
        // Marca como nuevo hasta que se envÃ­e el primer mensaje de usuario
        this._isFirstMessage = !(this.messages && this.messages.some(m => m.role === 'user'));

        this._subscribeToPlatformEvent();
    }

    disconnectedCallback() {
        this._clearTimeoutTimer();
        if (this.subscription) {
            unsubscribe(this.subscription, () => {});
        }
    }

    renderedCallback() {
        // Restaura el estado de SummaryView una vez tras el primer render
        if (!this._summaryRestored && this.hasRequestedReport) {
            this._restoreSummaryState();
        }
    }

    _restoreSummaryState(attempt = 0) {
        if (this._summaryRestored || attempt > 10) return;
        const sv = this.template.querySelector('c-ai-chat-robot2-summary-view');
        if (sv) {
            this._summaryRestored = true;
            if (this.summaryMessages && this.summaryMessages.length > 0) {
                sv.showSummary(this.summaryMessages);
            } else {
                // Se solicito el reporte pero aun no llegaron datos: mostrar carga
                sv.showLoading();
            }
        } else {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this._restoreSummaryState(attempt + 1), 100);
        }
    }

    // --- Calculados ---
    get titleText() {
        return this.accountName
            ? `${this._labels.aiChatRobot2_MiniChatTitle} - ${this.accountName}`
            : this._labels.aiChatRobot2_MiniChatTitle;
    }

    get reportButtonLabel() {
        return this.hasRequestedReport ? this._labels.aiChatRobot2_ShowReport : this._labels.aiChatRobot2_RequestReport;
    }

    get inputDisabled() {
        return this.isThinking || this.isConversationBlocked;
    }

    get showLanguageSelector() {
        return !this.languageLocked;
    }

    /** Filtra mensajes marcador de reporte para que InlineReport no se renderice en el modal */
    get displayMessages() {
        return (this.messages || []).filter(m => m.role !== 'report');
    }

    get showRequestReportButton() {
        return !this.hasRequestedReport;
    }

    get isRequestReportDisabled() {
        return this.isThinking || this.isConversationBlocked || this.hasRequestedReport;
    }

    get showSummaryButton() {
        return this.hasRequestedReport && !this.isSummaryOpen;
    }

    get layoutClass() {
        let cls = 'expanded-layout';
        if (this.isSummaryOpen) {
            cls += ' summary-open';
        }
        return cls;
    }

    // --- Cierre: siempre devuelve el estado al padre ---
    close(result) {
        super.close(result || this._buildReturnState());
    }

    _buildReturnState() {
        return {
            messages: [...this.messages],
            isThinking: this.isThinking,
            selectedLanguage: this.selectedLanguage,
            languageLocked: this.languageLocked,
            isSummaryOpen: this.isSummaryOpen,
            hasSummaryData: this.hasSummaryData,
            hasRequestedReport: this.hasRequestedReport,
            summaryMessages: this.summaryMessages ? [...this.summaryMessages] : [],
            lastSummaryData: this.lastSummaryData,
            isConversationBlocked: this.isConversationBlocked,
            reportExpanded: this.isSummaryOpen
        };
    }

    // --- Manejadores: Chat ---
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
        const userMessage = this._makeMsg('user', escappedText);
        userMessage.language = language;

        this.isThinking = true;
        this._saveConversationContext(true);
        this._sendOBMessage(userMessage);
        this.messages = [...this.messages, this._makeMsg('user', escappedText)];
        this._startTimeoutTimer();
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

    handleFeedback() {}
    handleFeedbackSent(event) {
        const { messageId, feedbackState } = event.detail || {};
        this._markMessageFeedbackSent(messageId, feedbackState);
    }
    handleCopied() {}

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

    // --- Manejadores: Reporte / Barra lateral de resumen ---
    handleRequestReport() {
        if (this.isRequestReportDisabled) return;
        this.hasRequestedReport = true;
        // Desactivamos el input de texto mientras dura la petición y procesamiento
        this.isThinking = true;

        const reportRequestMessage = this._makeMsg('user', '');
        reportRequestMessage.language = this.selectedLanguage || 'EN';
        this._saveConversationContext(true);

        // Abre la barra lateral de resumen con estado de carga
        this.isSummaryOpen = true;
        window.requestAnimationFrame(() => {
            const summaryView = this.template.querySelector('c-ai-chat-robot2-summary-view');
            if (summaryView) {
                summaryView.showLoading();
            }
        });

        this._sendOBMessageForReport(reportRequestMessage);
        this._startTimeoutTimer();
    }

    handleSummaryClose() {
        this.isSummaryOpen = false;
    }

    handleSummaryToggle() {
        if (this.isSummaryOpen) {
            this.isSummaryOpen = false;
            const sv = this.template.querySelector('c-ai-chat-robot2-summary-view');
            if (sv) {
                sv.closeSummary();
            }
        } else {
            this.isSummaryOpen = true;
            const sv = this.template.querySelector('c-ai-chat-robot2-summary-view');
            if (sv) {
                if (this.summaryMessages && this.summaryMessages.length > 0) {
                    sv.showSummary(this.summaryMessages);
                } else {
                    sv.showLoading();
                }
            }
        }
    }

    handleSummaryResize(event) {
        const { width } = event.detail;
        if (width) {
            this.template.host.style.setProperty('--summary-width', `${width}px`);
        }
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
                console.error('Error en empApi (modal):', JSON.stringify(error));
                // Intenta resuscribirse automaticamente ante desconexion del canal
                this._handleEmpApiDisconnect();
            });
        }

        subscribe(channelName, -1, event => {
            try {
                const payloadData = event?.data;
                if (!payloadData || !payloadData.payload) return;

                const payload = payloadData.payload;
                const convoId = payload.ConversationId__c;

                if (payload.ErrorStatus__c || payload.ErrorDescription__c) {
                    this._errorManager({
                        status: payload.ErrorStatus__c,
                        description: payload.ErrorDescription__c,
                        detail: payload.ErrorDetail__c
                    });
                    return;
                }

                const message = payload.Content__c;
                let explicability = null;
                if (payload.Explicability__c) {
                    try {
                        explicability = JSON.parse(payload.Explicability__c);
                    } catch (e) {
                        console.warn('Error parsing explicability:', e);
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

                        const aiMsg = this._makeMsg('ai', message, explicability);
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
            } catch (err) {
                console.error('Error procesando evento (modal):', err);
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

        if (this.isConversationBlocked) return;

        this._resubscribeAttempts = (this._resubscribeAttempts || 0) + 1;

        if (this._resubscribeAttempts <= MAX_RESUBSCRIBE_ATTEMPTS) {
            console.warn(`empApi (modal) desconectado. Intento de resuscripcion ${this._resubscribeAttempts}/${MAX_RESUBSCRIBE_ATTEMPTS}...`);
            if (this.subscription) {
                unsubscribe(this.subscription, () => {});
                this.subscription = null;
            }
            setTimeout(() => {
                this._subscribeToPlatformEvent();
            }, RESUBSCRIBE_DELAY_MS);
        } else {
            console.error('empApi (modal): se agotaron los intentos de resuscripcion.');
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

        const summaryView = this.template.querySelector('c-ai-chat-robot2-summary-view');
        if (summaryView) {
            this.isSummaryOpen = true;
            summaryView.showSummary(this.summaryMessages);
        }
        // Reactivamos el input tras procesar el informe
        this.isThinking = false;
    }

    /** Resetea silenciosamente el estado del informe cuando la respuesta no es SUMMARY.
     *  Cierra el SummaryView y resetea los flags para que el usuario pueda
     *  volver a solicitar el informe desde el botón. */
    _resetReportState() {
        // Cerrar y resetear el SummaryView si existe
        const summaryView = this.template.querySelector('c-ai-chat-robot2-summary-view');
        if (summaryView) {
            summaryView.closeSummary();
        }

        // Resetear todos los flags relacionados con el informe
        this.hasRequestedReport = false;
        this.hasSummaryData = false;
        this.isSummaryOpen = false;
        this.lastSummaryData = null;
        this.summaryMessages = [];
    }

    /** Resetea silenciosamente el estado del informe cuando la respuesta no es SUMMARY.
     *  Cierra el SummaryView y resetea los flags para que el usuario pueda
     *  volver a solicitar el informe desde el botón. */
    _resetReportState() {
        // Cerrar y resetear el SummaryView si existe
        const summaryView = this.template.querySelector('c-ai-chat-robot2-summary-view');
        if (summaryView) {
            summaryView.closeSummary();
        }

        // Resetear todos los flags relacionados con el informe
        this.hasRequestedReport = false;
        this.hasSummaryData = false;
        this.isSummaryOpen = false;
        this.lastSummaryData = null;
        this.summaryMessages = [];
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
            }
        });
    }

    _sendOBMessage(userMessage) {
        const isNewConversation = this._isFirstMessage ? true : false;
        this._isFirstMessage = false;

        const requestBody = {
            conversationId: this.conversationId,
            showSummary: this.isSummaryOpen,
            channel: 'GLOBAL_DESKTOP',
            isNewConversation: isNewConversation,
            userId: this._userKey,
            userCountry: this.userCountry,
            userSegment: this.userSegment,
            messageId: userMessage.id,
            content: userMessage.text,
            companyId: this._groupId,
            companyName: this.accountName,
            language: userMessage.language
        };

        makeServiceRequest({ serviceName: 'obmessage', requestBody }).then(response => {
            if (response?.isError) {
                this._errorManager({ detail: 'Ha fallado la comunicaciÃ³n con el servicio.' });
            }
        }).catch(() => {
            this._errorManager({ detail: 'Ha fallado la comunicaciÃ³n con el servicio.' });
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
    _makeMsg(role, text, explicability = null) {
        return {
            id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
            role,
            text,
            explicability,
            timestamp: new Date().toISOString()
        };
    }

    _errorManager() {
        // Evita cascada de mensajes de error si la conversacion ya esta bloqueada
        if (this.isConversationBlocked) return;

        const msg = 'Se ha producido un error en el procesamiento de la respuesta. Por favor, inicie otra conversación.';
        this.messages = [...this.messages, this._makeMsg('ai', msg)];
        this.isThinking = false;
        this.isConversationBlocked = true;
        this.conversationId = null;
        this._conversationRecordId = null;
        this._isFirstMessage = true;
        this._clearTimeoutTimer();
    }

    _startTimeoutTimer() {
        this._clearTimeoutTimer();
        if (!this._timeoutMs || this.isConversationBlocked) return;
        this._timeoutHandle = window.setTimeout(() => this._handleTimeout(), this._timeoutMs);
    }

    _clearTimeoutTimer() {
        if (this._timeoutHandle) {
            window.clearTimeout(this._timeoutHandle);
            this._timeoutHandle = null;
        }
    }

    _handleTimeout() {
        if (this.isConversationBlocked) return;
        const timeoutMsg = this._makeMsg('ai', TIMEOUT_MESSAGE);
        timeoutMsg.isTimeout = true;
        this.messages = [...this.messages, timeoutMsg];
        this.isThinking = false;
        this.isConversationBlocked = true;
        this.conversationId = null;
        this._conversationRecordId = null;
        this._isFirstMessage = true;
        this._clearTimeoutTimer();
    }
}