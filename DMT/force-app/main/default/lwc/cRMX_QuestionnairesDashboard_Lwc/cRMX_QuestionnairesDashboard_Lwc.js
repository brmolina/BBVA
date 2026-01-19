import { LightningElement, wire, track, api } from 'lwc';
import getQuestionnaires from '@salesforce/apex/CRMX_QuestionnaireBoard_Ctrl.getQuestionnaires';
import updateQuestionnaireStatus from '@salesforce/apex/CRMX_QuestionnaireBoard_Ctrl.updateQuestionnaireStatus';
import getPDFUrl from '@salesforce/apex/CRMX_QuestionnaireBoard_Ctrl.getPDFUrl';
import { refreshApex } from '@salesforce/apex';
import LABEL_CLIENT from '@salesforce/label/c.CRMX_Client';
import LABEL_LINKED_GROUP from '@salesforce/label/c.CRMX_Linked_Group';
import LABEL_STATUS from '@salesforce/label/c.Arc_Gen_TraceabilityState';
import LABEL_LAST_MODIFIED from '@salesforce/label/c.CRMX_Last_Modification_Date';
import LABEL_DOWNLOAD_PDF from '@salesforce/label/c.CRMX_Download_PDF';
import LABEL_TITLE_QUESTIONNAIRE from '@salesforce/label/c.CRMX_Title_Questionnaire_lwc';
import LABEL_SUBTITLE_QUESTIONNAIRE from '@salesforce/label/c.CRMX_SubTitle_Questionnaire_lwc';

const FIELD_NAMES = {
    CLIENT_NAME: 'clientName',
    LINKED_GROUP: 'linkedGroup',
    STATUS: 'strStatus',
    LAST_MODIFIED_DATE: 'lastModifiedDate'
};

const BUTTON_ATTRIBUTES = {
    NAME: 'download',
    ICON: 'utility:download',
    CLASS: 'download-button'
};

const labelTituloCuestionario  = LABEL_TITLE_QUESTIONNAIRE;
const labelSubTituloCuestionario  = LABEL_SUBTITLE_QUESTIONNAIRE;

const columns = [
    { label: LABEL_CLIENT, fieldName: FIELD_NAMES.CLIENT_NAME, initialWidth: 130 },
    { label: LABEL_LINKED_GROUP, fieldName: FIELD_NAMES.LINKED_GROUP, initialWidth: 130 },
    { label: LABEL_STATUS, fieldName: FIELD_NAMES.STATUS, initialWidth: 100 },
    {
        label: LABEL_LAST_MODIFIED,
        fieldName: FIELD_NAMES.LAST_MODIFIED_DATE,
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric'
        },
        initialWidth: 100
    },
    {
        type: 'button',
        typeAttributes: {
            label: LABEL_DOWNLOAD_PDF,
            name: BUTTON_ATTRIBUTES.NAME,
            iconName: BUTTON_ATTRIBUTES.ICON,
            disabled: { fieldName: 'canDownloadDisabled' },
            class: BUTTON_ATTRIBUTES.CLASS
        },
        initialWidth: 130
    }
];

export default class cRMX_QuestionnairesDashboard extends LightningElement {
    @api recordId;
    @track questionnaires = [];
    columns = columns;
    wiredQuestionnairesResult;

    @wire(getQuestionnaires, { clientId: '$recordId' })
    wiredQuestionnaires(result) {
        this.wiredQuestionnairesResult = result;
        if (result.data) {
            this.questionnaires = result.data.map(q => ({
                ...q,
                canDownloadDisabled: q.strStatus !== 'COMPLETED'
            }));
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'download') {
            this.downloadPDF(row.questionnaireId);
        }
    }

    downloadPDF(recordId) {
        getPDFUrl({ recordId })
            .then((pdfUrl) => {
                window.open(pdfUrl, '_blank');
                return updateQuestionnaireStatus({ questionnaireId: recordId, strStatus: 'SENT' });
            })
            .then(() => refreshApex(this.wiredQuestionnairesResult));
    }
}