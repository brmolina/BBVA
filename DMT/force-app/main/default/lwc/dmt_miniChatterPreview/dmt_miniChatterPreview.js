import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLatestComment from '@salesforce/apex/DMT_MiniChatterController.getLatestComment';

export default class MiniChatterPreview extends NavigationMixin(LightningElement) {
    @api recordId;
    latestMessage;
    authorName;
    isExpanded = false; // Por defecto empieza cerrado/minimizado

    get toggleIcon() {
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronup';
    }

    @wire(getLatestComment, { recordId: '$recordId' })
    wiredFeed({ error, data }) {
        if (data) {
            this.latestMessage = data;
            this.authorName = data.CreatedBy ? data.CreatedBy.Name : 'User';
        } else if (error) {
            console.error('Error retrieving latest Chatter:', error);
        }
    }

    toggleWidget() {
        this.isExpanded = !this.isExpanded;
    }

    handleOpenChatter(event) {
        // Evitamos que al clicar en el link interno se minimice el componente por el onclick del padre
        event.stopPropagation(); 
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            },
            state: {
                recordActionFilter: 'QuickAction.Opportunity.View_Chatter'
            }
        });
    }
}