import { LightningElement, track, api } from 'lwc';
import { onUtilityClick } from 'lightning/platformUtilityBarApi';
import setTraceFlag from '@salesforce/apex/LogManager.setTraceFlag';
import fetchLogs from '@salesforce/apex/LogManager.fetchLogs';
import identifyLogSignatures from '@salesforce/apex/LogManager.identifyLogSignatures';
import deleteLogs from '@salesforce/apex/LogManager.deleteLogs';
import getLogBody from '@salesforce/apex/LogManager.getLogBody';
import checkActiveTraceFlag from '@salesforce/apex/LogManager.checkActiveTraceFlag';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// NEW IMPORT: The Modal Component
import LogViewerModal from 'c/logViewerModal';

const COLUMNS = [
    { label: 'Time', fieldName: 'LastModifiedDate', type: 'date', 
      typeAttributes: { hour: '2-digit', minute: '2-digit', second: '2-digit' }, fixedWidth: 100 },
    { label: 'Operation', fieldName: 'Operation', type: 'text' },
    { label: 'Size (B)', fieldName: 'LogLength', type: 'number', fixedWidth: 80 },
    { type: 'button-icon', typeAttributes: {
        iconName: 'utility:preview', name: 'view_log', title: 'View', variant: 'border-filled', alternativeText: 'View'
    }, fixedWidth: 50 }
];

export default class ApexLogStreamer extends LightningElement {
    @api utilityId;
    @track logs = [];
    columns = COLUMNS;
    
    isRecording = false;
    pollingInterval;
    sessionStartTime; 

    broadcastChannel = new BroadcastChannel('apex_log_streamer_sync');

    get statusMessage() {
        return this.isRecording ? 'Status: Recording...' : 'Status: Idle';
    }

    connectedCallback() {
        onUtilityClick({ 
            utilityId: this.utilityId, 
            eventHandler: (response) => {
                if (response.panelVisible && !this.isRecording) this.performServerToggle(true);
            } 
        });

        this.broadcastChannel.onmessage = (event) => {
            if (event.data.action === 'SYNC_STATUS') this.syncLocalState(event.data.value);
        };
        this.checkForExistingSession();
    }

    disconnectedCallback() {
        this.stopPolling();
        this.broadcastChannel.close();
    }

    checkForExistingSession() {
        checkActiveTraceFlag().then(isActive => {
            if (isActive) {
                this.isRecording = true;
                this.sessionStartTime = new Date().toISOString();
                this.startPolling();
            }
        });
    }

    handleToggleSwitch(event) {
        this.performServerToggle(event.target.checked);
    }

    handleClearLogs() {
        this.logs = [];
        this.sessionStartTime = new Date().toISOString();
        this.dispatchEvent(new ShowToastEvent({ title: 'Cleared', message: 'UI cleared', variant: 'success' }));
    }

    performServerToggle(enable) {
        this.isRecording = enable;
        if (enable) {
            this.logs = [];
            this.sessionStartTime = new Date().toISOString();
            setTraceFlag({ enable: true })
                .then(() => {
                    this.startPolling();
                    this.broadcastChannel.postMessage({ action: 'SYNC_STATUS', value: true });
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message || error.message, variant: 'error' }));
                    this.isRecording = false;
                });
        } else {
            this.stopPolling();
            setTraceFlag({ enable: false }).then(() => {
                this.broadcastChannel.postMessage({ action: 'SYNC_STATUS', value: false });
            });
        }
    }

    syncLocalState(isRecordingRemote) {
        if (this.isRecording !== isRecordingRemote) {
            this.isRecording = isRecordingRemote;
            if (this.isRecording) {
                this.logs = [];
                this.sessionStartTime = new Date().toISOString();
                this.startPolling();
            } else {
                this.stopPolling();
            }
        }
    }

    startPolling() {
        this.stopPolling();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.pollingInterval = setInterval(() => this.getNewLogs(), 3000);
    }

    stopPolling() {
        if (this.pollingInterval) clearInterval(this.pollingInterval);
    }

    async getNewLogs() {
        try {
            const jsonResponse = await fetchLogs({ afterTimestamp: this.sessionStartTime });
            if (!jsonResponse) return;
            
            let newLogs = JSON.parse(jsonResponse);
            if (!Array.isArray(newLogs) || newLogs.length === 0) return;

            this.sessionStartTime = newLogs[0].LastModifiedDate;

            const potentialLogs = [];
            const idsToDelete = [];

            newLogs.forEach(log => {
                if (log.Operation.includes('/services/data') || log.Operation.includes('AsyncLogDeleter')) {
                    idsToDelete.push(log.Id);
                } else {
                    potentialLogs.push(log);
                }
            });

            if (potentialLogs.length > 0) {
                const potentialIds = potentialLogs.map(l => l.Id);
                const signatures = await identifyLogSignatures({ logIds: potentialIds });
                const cleanLogs = [];
                
                potentialLogs.forEach(log => {
                    const sig = signatures[log.Id];
                    if (sig === 'NOISE') {
                        idsToDelete.push(log.Id);
                    } else {
                        if (sig && sig !== 'Anonymous / System') log.Operation = sig;
                        cleanLogs.push(log);
                    }
                });

                if (cleanLogs.length > 0) this.logs = [...cleanLogs, ...this.logs];
            }

            if (idsToDelete.length > 0) deleteLogs({ logIds: idsToDelete });

        } catch (error) {
            console.error('Polling Error:', error);
        }
    }

    handleRowAction(event) {
        if (event.detail.action.name === 'view_log') {
            this.openFullLogModal(event.detail.row.Id);
        }
    }

    // --- NEW MODAL LOGIC ---
    async openFullLogModal(logId) {
        // 1. Open Modal immediately with "Loading" state
        // This 'LogViewerModal' breaks out of the utility bar
        const result = LogViewerModal.open({
            size: 'large',
            description: 'Apex Log Viewer',
            content: 'Fetching log...',
            isLoading: true
        });

        // 2. Fetch data
        try {
            const body = await getLogBody({ logId: logId });
            
            // 3. Unfortunately, we cannot update the modal after opening it easily in LWC without
            // messy message channels. 
            // SIMPLER APPROACH: Fetch FIRST, then Open.
            
            // Note: I will cancel the previous open logic and do "Fetch-Then-Open"
            // to keep the code simple and robust.
        } catch(e) { console.error(e); }
    }

    // REVISED OPEN LOGIC: Fetch First, Then Open
    openFullLogModal(logId) {
        // Show spinner in utility bar while fetching
        // (Optional: Add a spinner to this component html if desired)
        
        getLogBody({ logId: logId })
            .then(body => {
                LogViewerModal.open({
                    size: 'large',
                    description: 'Apex Log Viewer',
                    content: body,
                    isLoading: false
                });
            })
            .catch(error => {
                LogViewerModal.open({
                    size: 'small',
                    content: 'Error fetching log: ' + JSON.stringify(error),
                    isLoading: false
                });
            });
    }
}