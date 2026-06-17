import { LightningElement, api, track, wire } from 'lwc';
import { getRecords } from 'lightning/uiRecordApi';

const USER_FIRSTNAME = 'User.FirstName';
const USER_LASTNAME  = 'User.LastName';
const USER_NAME      = 'User.Name';

export default class Onb_userMultiPicker extends LightningElement {
    @api title;
    @api iconName;
    @api helpText;
    @api placeholder;

    showPicker = true;

    _userIds = [];
    @api
    get userIds() {
        return this._userIds;
    }
    set userIds(value) {
        const next = Array.isArray(value) ? value.filter(Boolean) : [];
        const same =
            next.length === this._userIds.length &&
            next.every((id, i) => id === this._userIds[i]);

        if (same) return;

        this._userIds = next;
        this._syncSelectedUsersFromIds();
    }

    @track selectedUsers = []; // [{ id, name }]

    get cardTitle() {
        return (this.title && this.title.trim().length > 0) ? this.title : '\u00A0';
    }

    get userFilter() {
        return {
            criteria: [{ fieldPath: 'IsActive', operator: 'eq', value: true }]
        };
    }

    get hasSelections() {
        return this.selectedUsers?.length > 0;
    }

    get recordsRequest() {
        const ids = (this.selectedUsers || []).map(u => u.id).filter(Boolean);
        if (!ids.length) return null;

        return [
            {
                recordIds: ids,
                fields: [USER_FIRSTNAME, USER_LASTNAME, USER_NAME]
            }
        ];
    }

    @wire(getRecords, { records: '$recordsRequest' })
    wiredUsers({ data }) {
        if (!data?.results) return;

        const idToLabel = new Map();
        data.results.forEach(r => {
            const res = r?.result;
            const id = res?.id;

            const first = res?.fields?.FirstName?.value || '';
            const last  = res?.fields?.LastName?.value || '';
            const name  = res?.fields?.Name?.value || '';

            const full = `${first} ${last}`.trim();
            const label = full || name;

            if (id && label) idToLabel.set(id, label);
        });

        let changed = false;
        const next = this.selectedUsers.map(u => {
            const resolved = idToLabel.get(u.id);
            if (resolved && u.name !== resolved) {
                changed = true;
                return { ...u, name: resolved };
            }
            return u;
        });

        if (changed) {
            this.selectedUsers = next;
        }
    }

    _syncSelectedUsersFromIds() {
        const currentById = new Map((this.selectedUsers || []).map(u => [u.id, u.name]));
        this.selectedUsers = (this._userIds || []).map(id => ({
            id,
            name: currentById.get(id) || '...'
        }));
    }

    handlePickerChange(event) {
        const pickedId = event?.detail?.recordId;
        if (!pickedId) return;

        if ((this._userIds || []).includes(pickedId)) {
            this._resetPickerHard();
            return;
        }

        this.dispatchEvent(
            new CustomEvent('useradd', {
                detail: { userId: pickedId }
            })
        );

        this._resetPickerHard();
    }

    handleRemove(event) {
        const idToRemove = event?.target?.name;
        if (!idToRemove) return;

        this.dispatchEvent(
            new CustomEvent('userremove', {
                detail: { userId: idToRemove }
            })
        );
    }

    _resetPickerHard() {
        this.showPicker = false;
        Promise.resolve().then(() => {
            this.showPicker = true;
        });
    }
}