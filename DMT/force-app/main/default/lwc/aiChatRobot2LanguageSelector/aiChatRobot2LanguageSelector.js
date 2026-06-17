import { LightningElement, api, track } from 'lwc';
import aiChatRobot2_LanguageSelector_Label from '@salesforce/label/c.aiChatRobot2_LanguageSelector_Label';
import aiChatRobot2_Language_English from '@salesforce/label/c.aiChatRobot2_Language_English';
import aiChatRobot2_Language_Spanish from '@salesforce/label/c.aiChatRobot2_Language_Spanish';
import aiChatRobot2_LanguageSelector_Aria from '@salesforce/label/c.aiChatRobot2_LanguageSelector_Aria';

export default class AiChatRobot2LanguageSelector extends LightningElement {
    @track selectedLanguage = 'EN'; // Default: English
    
    label = {
        aiChatRobot2_LanguageSelector_Label,
        aiChatRobot2_Language_English,
        aiChatRobot2_Language_Spanish,
        aiChatRobot2_LanguageSelector_Aria
    };

    connectedCallback() {
        // Ingles por defecto y siempre enviado por detras aunque la UI este oculta.
        this.selectedLanguage = 'EN';
        this._dispatchLanguageChange('EN');
    }

    get isEnglish() {
        return this.selectedLanguage === 'EN';
    }

    get isSpanish() {
        return this.selectedLanguage === 'ES';
    }

    get englishButtonClass() {
        return `language-button ${this.isEnglish ? 'active' : ''}`.trim();
    }

    get spanishButtonClass() {
        return `language-button ${this.isSpanish ? 'active' : ''}`.trim();
    }

    handleEnglishClick() {
        this.selectedLanguage = 'EN';
        this._dispatchLanguageChange('EN');
    }

    handleSpanishClick() {
        this.selectedLanguage = 'EN';
        this._dispatchLanguageChange('EN');
    }

    _dispatchLanguageChange(language) {
        // Dispatch custom event to notify parent component
        this.dispatchEvent(new CustomEvent('languagechange', {
            detail: { language },
            bubbles: true,
            composed: true
        }));
    }

    @api
    getSelectedLanguage() {
        // Fallback to English if no language is selected
        return this.selectedLanguage || 'EN';
    }
}