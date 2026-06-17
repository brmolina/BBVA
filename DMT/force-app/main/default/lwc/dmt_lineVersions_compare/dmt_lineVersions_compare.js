import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getSnapshotEvaluationVersions from '@salesforce/apex/DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions';
import getFilteredComponentItemOptions from '@salesforce/apex/DMT_ItemController.getFilteredComponentItemOptions';
import LOCALE from '@salesforce/i18n/locale';

import { MOCK_DATA_A, MOCK_DATA_B } from './mockData';

const USE_MOCK_DATA = false;

export default class DmtLineVersionsCompare extends LightningModal {
    @api allVersions = []; 
    @api lineId;          
    @api viewType;        

    validComponents = [];

    @track versionA;
    @track versionB;
    @track isLoading = false;

    // The Master List of all comparison data
    @track allSections = []; 
    
    // UX Toggles
    @track showDifferencesOnly = true; 
    @track isContentIdentical = false;
    @track isOrderDiffOnly = false;
    @track orderListA = [];
    @track orderListB = [];

    // Comparison Chronology labels for Logging
    labelA = '';
    labelB = '';

    jsonCacheMap = new Map();

    connectedCallback() {
        this.initializeCache();
    }

    async initializeCache() {
        this.isLoading = true;
        
        // Fetch Metadata Config
        const validComponents = await getFilteredComponentItemOptions({ viewType: this.viewType });
        this.validComponents = validComponents;
        console.log('Filtered Component Items:', validComponents);

        // OPTIMIZATION: Only pre-fetch the latest 5 versions to speed up load time.
        // We assume allVersions is already sorted or we sort it here to be safe.
        // Sort descending by versionNumber just in case.
        const sortedVersions = [...this.allVersions].sort((a, b) => {
            const numA = parseInt(a.versionNumber, 10) || 0;
            const numB = parseInt(b.versionNumber, 10) || 0;
            return numB - numA; // Newest first
        });

        const bufferSize = 5;
        const versionsToBuffer = sortedVersions.slice(0, bufferSize);

        console.log(` buffering latest ${versionsToBuffer.length} versions...`);

        // Fetch body for the buffer list
        await Promise.all(versionsToBuffer.map(v => this.ensureVersionData(v.version)));
        
        this.isLoading = false;
    }

    get isVersionBDisabled() { return !this.versionA; }
    get optionsA() { return this.allVersions.map(v => ({ label: `Version ${v.version}`, value: v.version })); }
    get optionsB() { return this.optionsA.filter(opt => opt.value !== this.versionA); }
    get hasSections() {
        return this.allSections && this.allSections.length > 0;
    }

    async ensureVersionData(versionId) {
        if (this.jsonCacheMap.has(versionId)) {
            console.log(`Cache hit for version ${versionId}`);
            return;
        }

        try {
            console.log(`Fetching version ${versionId}...`);
            const payload = `opportunityId=${this.lineId}&versionId=${versionId}`;
            const response = await getSnapshotEvaluationVersions({ requestStr: payload });
            const parsedResponse = JSON.parse(response);
            if (parsedResponse.success && parsedResponse.data.versions.length > 0) {
                const bodyJson = JSON.parse(parsedResponse.data.versions[0].body);
                this.jsonCacheMap.set(versionId, bodyJson);
                console.log(`Fetched and cached version ${versionId}`);
            }
        } catch (error) { 
            console.error(`Failed to fetch version ${versionId}:`, error); 
        }
    }

    async handleVersionAChange(event) {
        this.versionA = event.detail.value;
        await this.ensureVersionData(this.versionA);
        this.triggerComparison();
    }

    async handleVersionBChange(event) {
        this.versionB = event.detail.value;
        await this.ensureVersionData(this.versionB);
        this.triggerComparison();
    }

    handleToggleFilter(event) {
        this.showDifferencesOnly = event.target.checked;
    }

    handleSectionToggle(event) {
        const sectionName = event.currentTarget.dataset.name;
        const section = this.allSections.find(s => s.name === sectionName);
        
        if (section) {
            section.isOpen = !section.isOpen;
            // Calculate class string for HTML
            section.sectionClass = section.isOpen ? 'slds-section slds-is-open' : 'slds-section';
        }
    }

    // Getter to filter the view based on the Toggle
    get visibleSections() {
        if (this.showDifferencesOnly) {
            return this.allSections.filter(s => s.hasDifferences);
        }
        return this.allSections;
    }

    triggerComparison() {
        console.log('Triggering comparison...');
        console.log('versionA:', JSON.stringify(this.jsonCacheMap.get(this.versionA)));
        console.log('versionB:', JSON.stringify(this.jsonCacheMap.get(this.versionB)));
        if (this.versionA && this.versionB) {
            this.isLoading = true;
            setTimeout(() => {
                // FIX 1: Wrap in try/catch/finally to guarantee spinner goes away
                try {
                    let dataA, dataB;

                    if (USE_MOCK_DATA) {
                        console.warn('⚠️ USING MOCK DATA FOR UI TESTING ⚠️');
                        dataA = MOCK_DATA_A;
                        dataB = MOCK_DATA_B;
                    } else {
                        const rawA = this.jsonCacheMap.get(this.versionA);
                        const rawB = this.jsonCacheMap.get(this.versionB);
                        
                        dataA = rawA ? JSON.parse(JSON.stringify(rawA)) : null;
                        dataB = rawB ? JSON.parse(JSON.stringify(rawB)) : null;
                    }
                    
                    if (dataA && dataB) {
                        this.generateComparisonData(dataA, dataB);
                    } else {
                        console.error('Failed to load data for one or both versions.');
                    }
                } catch (error) {
                    console.error('CRITICAL ERROR during snapshot comparison:', error);
                } finally {
                    // This ALWAYS runs, preventing the infinite loading state
                    this.isLoading = false;
                }
            }, 50);
        }
    }

    generateComparisonData(dataA, dataB) {
     //   console.log('--- STARTING GENERATION ---');
        this.isContentIdentical = false;
        this.isOrderDiffOnly = false;
        this.orderListA = [];
        this.orderListB = [];
        
        // 1. Chronology: Who is Newer?
        const objA = this.allVersions.find(v => v.version === this.versionA);
        const objB = this.allVersions.find(v => v.version === this.versionB);

        const numA = objA ? parseInt(objA.versionNumber, 10) : 0;
        const numB = objB ? parseInt(objB.versionNumber, 10) : 0;
        const isANewer = numA > numB;

        const dateA = objA ? this.formatDate(objA.createdDate) : '';
        const dateB = objB ? this.formatDate(objB.createdDate) : '';

        // Label A
        this.labelA = {
            title: this.versionA,
            // e.g. "Feb 10, 2026 • Latest Version"
            subtitle: `${dateA} ${isANewer ? ' • (Latest)' : ''}`,
            class: 'slds-text-heading_small slds-text-align_center slds-p-bottom_xx-small'
        };

        // Label B
        this.labelB = {
            title: this.versionB,
            subtitle: `${dateB} ${!isANewer ? ' • (Latest)' : ''}`,
            class: 'slds-text-heading_small slds-text-align_center slds-p-bottom_xx-small'
        };

       // console.log(`Comparing: ${this.labelA} vs ${this.labelB}`);

        // 2. Normalize Data
        const mapA = this.normalizeComponents(dataA.components);
        const mapB = this.normalizeComponents(dataB.components);
        const rawOrderA = dataA.components ? dataA.components.filter(c => c.name !== 'Limit Visual').map(c => c.name) : [];
        const rawOrderB = dataB.components ? dataB.components.filter(c => c.name !== 'Limit Visual').map(c => c.name) : [];

        /* console.log('Components found in Version A:', JSON.stringify(Array.from(mapA.keys())));
        console.log('Components found in Version B:', JSON.stringify(Array.from(mapB.keys()))); */
        // 3. Master List
        const allSectionNames = new Set([
            ...mapA.keys(), 
            ...mapB.keys(),
            ...(this.validComponents || [])
        ]);

        const sections = [];

        allSectionNames.forEach(sectionName => {
            const compA = mapA.get(sectionName);
            const compB = mapB.get(sectionName);

            // If empty in both, skip
            if (!compA && !compB) return;

            const sectionResult = {
                name: sectionName,
                isOpen: false, 
                sectionClass: 'slds-section', 
                isPresentBoth: !!(compA && compB),
                isPresentA: !!compA,
                isPresentB: !!compB,
                hasDifferences: false,
                
                // New Properties for UX
                badgeLabel: null,    // 'Added', 'Removed', 'Changed'
                badgeClass: '',      // CSS class for the badge
                
                rows: [] 
            };

            // --- STATUS CALCULATION LOGIC ---

            // CASE 1: Both Exist -> Check for 'Changed'
            if (compA && compB) {
                sectionResult.rows = this.compareComponentContent(compA, compB, sectionName, isANewer, this.versionA, this.versionB);
                sectionResult.hasDifferences = sectionResult.rows.some(r => r.isDiff);
                
                if (sectionResult.hasDifferences) {
                    sectionResult.isOpen = true;
                    sectionResult.sectionClass = 'slds-section slds-is-open';
                    
                    // STATUS: CHANGED
                    sectionResult.badgeLabel = 'Changed';
                    sectionResult.badgeClass = 'slds-badge slds-theme_warning';

                    /* console.groupCollapsed(`%c[DIFF: SECTION] ${sectionName} has changes`, 'color: #e67e22; font-weight: bold; font-size: 12px; background: #fdf2e9; padding: 4px; border: 1px solid #e67e22;');
                    console.log('See detailed row/field logs above.');
                    console.groupEnd(); */
                }
            } 
            
            // CASE 2: Exists in A, Missing in B
            else if (compA && !compB) {
                const isAdded = isANewer; // A is newer and has it -> Added
                const actionLabel = isAdded ? 'ADDED' : 'REMOVED';
                const color = isAdded ? '#27ae60' : '#c0392b'; // Green vs Red
                const bg    = isAdded ? '#d5f5e3' : '#fadbd8';

                console.groupCollapsed(`%c[DIFF: SECTION ${actionLabel}] ${sectionName}`, `color: ${color}; font-weight: bold; background: ${bg}; padding: 4px;`);
                this.logEntireSection(compA); 
                console.groupEnd();
                sectionResult.hasDifferences = true;
                sectionResult.isOpen = true;
                sectionResult.sectionClass = 'slds-section slds-is-open';
                sectionResult.rows = this.extractRowsForDisplay(compA, 'left', isANewer);

                // STATUS LOGIC:
                // If A is Newer, we GAINED this section -> ADDED (Green)
                // If A is Older, we HAD this section -> REMOVED (Red) in the new version
                if (isANewer) {
                    sectionResult.badgeLabel = 'Added';
                    sectionResult.badgeClass = 'slds-badge slds-theme_success';
                } else {
                    sectionResult.badgeLabel = 'Removed';
                    sectionResult.badgeClass = 'slds-badge slds-theme_error';
                }
            }
            
            // CASE 3: Missing in A, Exists in B
            else if (!compA && compB) {
                const isRemoved = isANewer; // A is newer and lost it -> Removed
                const actionLabel = isRemoved ? 'REMOVED' : 'ADDED';
                const color = isRemoved ? '#c0392b' : '#27ae60';
                const bg    = isRemoved ? '#fadbd8' : '#d5f5e3';

                /* console.groupCollapsed(`%c[DIFF: SECTION ${actionLabel}] ${sectionName}`, `color: ${color}; font-weight: bold; background: ${bg}; padding: 4px;`);
                this.logEntireSection(compB);
                console.groupEnd(); */
                sectionResult.hasDifferences = true;
                sectionResult.isOpen = true;
                sectionResult.sectionClass = 'slds-section slds-is-open';
                sectionResult.rows = this.extractRowsForDisplay(compB, 'right', isANewer);

                // STATUS LOGIC:
                // If B is Newer, we GAINED this section -> ADDED (Green)
                // If B is Older, we HAD this section -> REMOVED (Red) in the new version
                if (!isANewer) {
                    sectionResult.badgeLabel = 'Added';
                    sectionResult.badgeClass = 'slds-badge slds-theme_success';
                } else {
                    sectionResult.badgeLabel = 'Removed';
                    sectionResult.badgeClass = 'slds-badge slds-theme_error';
                }
            }

            sections.push(sectionResult);
        });

        // 4. Global State & Sort
        const totalContentDiffs = sections.filter(s => s.hasDifferences).length;
        if (totalContentDiffs === 0) {
            const isOrderDifferent = JSON.stringify(rawOrderA) !== JSON.stringify(rawOrderB);
            if (isOrderDifferent) {
                this.isOrderDiffOnly = true;
                this.orderListA = rawOrderA.map((name, index) => ({ 
                    id: index, name: name, class: 'slds-theme_shade slds-m-bottom_xx-small slds-p-around_x-small'
                }));
                this.orderListB = rawOrderB.map((name, index) => ({ 
                    id: index, name: name, class: 'slds-theme_shade slds-m-bottom_xx-small slds-p-around_x-small'
                }));
                console.warn('[ORDER DIFF FOUND] Content identical, order changed.');
            } else {
                this.isContentIdentical = true;
                console.log('Versions are 100% identical.');
            }
        }
        this.allSections = this.sortSections(sections);
        console.log('--- END GENERATION ---');
    }

    // Helper: Turn JSON Array into Map<Name, Content>
    normalizeComponents(componentsList) {
        const map = new Map();
        if (!componentsList) return map;
        componentsList.forEach(comp => { 
            // Ignore 'Limit Visual' completely
            if (comp.name && comp.name !== 'Limit Visual') {
                map.set(comp.name, comp.content); 
            }
        });
        return map;
    }

    // ---------------------------------------------------------
    //  Comparison Logic (Logs Preserved)
    // ---------------------------------------------------------
    compareComponentContent(contentA, contentB, sectionName, isANewer, labelA, labelB) {
        let rows = [];
        const styleGreen = 'slds-theme_success'; 
        const styleRed   = 'slds-theme_error';
        
        // Log Styles
        /* const logStyleGreen = 'color: #27ae60; background: #d5f5e3; padding: 2px;';
        const logStyleRed   = 'color: #c0392b; background: #fadbd8; padding: 2px;';
        const styleLogA = isANewer ? logStyleGreen : logStyleRed;
        const styleLogB = isANewer ? logStyleRed : logStyleGreen; */

        const validTypes = ['values2', 'table', 'title'];
        
        // FIX 2a: Ensure content is an array before filtering
        const safeContentA = Array.isArray(contentA) ? contentA : (contentA ? [contentA] : []);
        const safeContentB = Array.isArray(contentB) ? contentB : (contentB ? [contentB] : []);

        const dataBlocksA = safeContentA.filter(c => validTypes.includes(c.type));
        const dataBlocksB = safeContentB.filter(c => validTypes.includes(c.type));
        
        const maxBlocks = Math.max(dataBlocksA.length, dataBlocksB.length);

        for (let i = 0; i < maxBlocks; i++) {
            const blockA = dataBlocksA[i];
            const blockB = dataBlocksB[i];

            if (!blockA || !blockB) {
                if(blockA) rows = [...rows, ...this.processSingleBlock(blockA, 'left', isANewer)];
                else if(blockB) rows = [...rows, ...this.processSingleBlock(blockB, 'right', isANewer)];
                continue;
            }

            // --- TITLE ---
            if (blockA.type === 'title') {
                rows.push({
                    id: this.generateUniqueId(),
                    isTitle: true,
                    text: blockA.text,
                    class: 'slds-text-heading_small slds-p-top_small slds-p-bottom_xx-small slds-text-title_caps section-title'
                });
            }

            // --- VALUES2 ---
            else if (blockA.type === 'values2') {
                const flatMapA = this.flattenValues(blockA.body);
                const flatMapB = this.flattenValues(blockB.body);
                const allKeys = new Set([...flatMapA.keys(), ...flatMapB.keys()]);

                allKeys.forEach(key => {
                    const valA = flatMapA.get(key);
                    const valB = flatMapB.get(key);
                    const cleanA = valA === undefined || valA === null ? '' : String(valA);
                    const cleanB = valB === undefined || valB === null ? '' : String(valB);
                    const isDiff = cleanA !== cleanB;

                    /* if (isDiff) {
                        console.groupCollapsed(`%c[DIFF: FIELD] ${sectionName} > ${key}`, 'color: #d35400; font-weight: bold; font-size: 11px;');
                        console.log(`%c${labelA.title}: "${cleanA}"`, styleLogA);
                        console.log(`%c${labelB.title}: "${cleanB}"`, styleLogB);
                        console.groupEnd();
                    } */

                    rows.push({
                        id: this.generateUniqueId(),
                        label: key, 
                        isField: true,
                        valA: cleanA === '' ? '\u00A0' : cleanA, 
                        valB: cleanB === '' ? '\u00A0' : cleanB,
                        classA: isDiff ? (isANewer ? styleGreen : styleRed) : '',
                        classB: isDiff ? (isANewer ? styleRed : styleGreen) : '',
                        isDiff: isDiff
                    });
                });
            }
            
            // --- TABLE ---
            else if (blockA.type === 'table') {
                let tableData = {
                    id: this.generateUniqueId(),
                    isWholeTable: true,
                    headers: [],
                    rows: [],
                    isDiff: false 
                };

                if (blockA.head && Array.isArray(blockA.head) && blockA.head.length > 0) {
                    tableData.headers = blockA.head[0]; 
                }

                // Safeguard against undefined bodies
                const bodyA = Array.isArray(blockA.body) ? blockA.body : [];
                const bodyB = Array.isArray(blockB.body) ? blockB.body : [];

                const maxRows = Math.max(bodyA.length, bodyB.length);
                
                for (let r = 0; r < maxRows; r++) {
                    const rawRowA = bodyA[r] || [];
                    const rawRowB = bodyB[r] || [];
                    
                    const maxCols = Math.max(rawRowA.length, rawRowB.length);
                    let rowCellsA = [];
                    let rowCellsB = [];
                    let isRowDiff = false; 

                    for (let c = 0; c < maxCols; c++) {
                        const valA = this.extractCellContent(rawRowA[c]);
                        const valB = this.extractCellContent(rawRowB[c]);

                        const isCellDiff = JSON.stringify(valA) !== JSON.stringify(valB);
                        if (isCellDiff) {
                            isRowDiff = true;
                            tableData.isDiff = true;
                        }
                        
                        const baseClass = isCellDiff ? 'diff-cell ' : ''; 
                        const colorClassA = isCellDiff ? (isANewer ? styleGreen : styleRed) : '';
                        const colorClassB = isCellDiff ? (isANewer ? styleRed : styleGreen) : '';

                        rowCellsA.push({ key: this.generateUniqueId(), value: valA, class: baseClass + colorClassA });
                        rowCellsB.push({ key: this.generateUniqueId(), value: valB, class: baseClass + colorClassB });
                    }

                    tableData.rows.push({ id: this.generateUniqueId(), key: r, cellsA: rowCellsA, cellsB: rowCellsB });
                }
                rows.push(tableData);
            }
        }
        return rows;
    }

    // Helper: Smartly extract content from complex JSON objects
    extractCellContent(cell) {
        if (cell === undefined || cell === null) return '';
        if (typeof cell !== 'object') return cell;

        // 1. UNWRAP PROXY
        let cleanCell;
        try {
            cleanCell = JSON.parse(JSON.stringify(cell));
        } catch (e) {
            console.error('Failed to parse cell', e);
            return String(cell);
        }

        // 2. TRAFFIC LIGHT LOGIC
        const isCustom = cleanCell.type === 'custom';
        const hasCustomArray = cleanCell.custom && Array.isArray(cleanCell.custom);

        if (isCustom && hasCustomArray) {
            const lights = cleanCell.custom.map((item, index) => {
                // Normalize color to Uppercase for easier matching
                const color = (item.styles?.textColor || '').toUpperCase();
                let colorClass = 'traffic-dot_default'; 
                
                if (color === '#BDBDBD') colorClass = 'traffic-dot_grey';
                else if (color === '#F8CC52') colorClass = 'traffic-dot_yellow';
                else if (color === '#FFFFFF') colorClass = 'traffic-dot_white';
                // Handle different green shades
                else if (color === '#47AD5A' || color === '#27AE60') colorClass = 'traffic-dot_green';
                else if (color === '#D73F52') colorClass = 'traffic-dot_red';

                return {
                    id: index, 
                    className: `traffic-dot ${colorClass}`,
                    char: item.content
                };
            });

            return {
                isTrafficLight: true,
                lights: lights
            };
        } 

        // 3. CONTENT FALLBACK
        if (cleanCell.content !== undefined) return cleanCell.content;

        return JSON.stringify(cleanCell);
    }

    // Helper: Extracts rows for a block (or list of blocks) that exists on only one side
    // Helper: Extracts rows for a block (or list of blocks) that exists on only one side
    extractRowsForDisplay(content, side, isANewer) {
        let rows = [];
        const blocks = Array.isArray(content) ? content : [content];

        let colorClassA = '';
        let colorClassB = '';

        if (side === 'left') {
            colorClassA = isANewer ? 'slds-theme_success' : 'slds-theme_error';
            colorClassB = isANewer ? 'slds-theme_error' : 'slds-theme_success'; 
        } else if (side === 'right') {
            colorClassB = !isANewer ? 'slds-theme_success' : 'slds-theme_error';
            colorClassA = !isANewer ? 'slds-theme_error' : 'slds-theme_success'; 
        }

        blocks.forEach(block => {
            if (!block) return;

            // --- TITLE LOGIC ---
            if (block.type === 'title') {
                rows.push({
                    id: this.generateUniqueId(), // FIX
                    isTitle: true,
                    text: block.text,
                    class: 'slds-text-heading_small slds-p-top_small slds-p-bottom_xx-small slds-text-title_caps section-title'
                });
            }

            // --- VALUES2 LOGIC ---
            else if (block.type === 'values2') {
                const flatMap = this.flattenValues(block.body);
                flatMap.forEach((val, key) => {
                    rows.push({
                        id: this.generateUniqueId(), // FIX
                        label: key,
                        isField: true,
                        valA: side === 'left' ? (val || '\u00A0') : '\u00A0',
                        valB: side === 'right' ? (val || '\u00A0') : '\u00A0',
                        classA: colorClassA, 
                        classB: colorClassB,
                        isDiff: true
                    });
                });
            } 
            
            // --- TABLE LOGIC ---
            else if (block.type === 'table') {
                let tableData = {
                    id: this.generateUniqueId(), // FIX
                    isWholeTable: true,
                    headers: [],
                    rows: [],
                    isDiff: true
                };

                if (block.head && Array.isArray(block.head) && block.head.length > 0) {
                    tableData.headers = block.head[0];
                }

                if (block.body) {
                    block.body.forEach((row, idx) => {
                        
                        const cellsA = row.map(c => ({ 
                            key: this.generateUniqueId(), 
                            value: side === 'left' ? this.extractCellContent(c) : '\u00A0', 
                            class: 'diff-cell ' + colorClassA 
                        }));
                        
                        const cellsB = row.map(c => ({ 
                            key: this.generateUniqueId(), 
                            value: side === 'right' ? this.extractCellContent(c) : '\u00A0', 
                            class: 'diff-cell ' + colorClassB 
                        }));

                        tableData.rows.push({
                            id: this.generateUniqueId(), // FIX
                            key: idx,
                            cellsA: cellsA,
                            cellsB: cellsB
                        });
                    });
                }
                rows.push(tableData);
            }
        });
        
        return rows;
    }

    // Helper for "Single Block" mismatches within a section
    processSingleBlock(block, side, isANewer) {
        // Reuse extractRows logic as it does exactly what we need
        return this.extractRowsForDisplay([block], side, isANewer);
    }

    flattenValues(bodyMatrix) {
        const map = new Map();
        if (!bodyMatrix || !Array.isArray(bodyMatrix)) {
            console.error('flattenValues: bodyMatrix is invalid', bodyMatrix);
            return map;
        }
        bodyMatrix.forEach((row) => {
            if(!Array.isArray(row)) return; 
            row.forEach(item => {
                if (item && item.name) {
                    const key = item.name.trim().replace(/:$/, ''); 
                    map.set(key, item.value);
                }
            });
        });
        return map;
    }

    logEntireSection(content) {
        if(!content) return;
        content.forEach(block => {
            if (block.type === 'values2') {
                const flatMap = this.flattenValues(block.body);
                flatMap.forEach((val, key) => console.log(`   ${key}: "${val}"`));
            } else if (block.type === 'table') {
                console.log('   [Table Data]:');
                block.body.forEach((row, idx) => {
                    const readable = row.map(c => this.extractCellContent(c));
                    console.log(`   Row ${idx+1}:`, JSON.stringify(readable));
                });
            }
        });
    }

    sortSections(sections) {
        if (!this.validComponents || this.validComponents.length === 0) return sections;
        return sections.sort((a, b) => {
            const indexA = this.validComponents.indexOf(a.name);
            const indexB = this.validComponents.indexOf(b.name);
            const idxA = indexA === -1 ? 999 : indexA;
            const idxB = indexB === -1 ? 999 : indexB;
            return idxA - idxB;
        });
    }

    // Helper to format Date safely
    formatDate(dateString) {
        if (!dateString) return '';
        
        const date = new Date(dateString);
        
        // 🚨 SAFETY CHECK: If the date string couldn't be parsed, Date.getTime() returns NaN
        if (isNaN(date.getTime())) {
            console.warn('⚠️ Invalid date format encountered:', dateString);
            return dateString; // Fallback: return the raw, unformatted string instead of crashing
        }
        
        // Results in "10/2/2026" (depending on LOCALE)
        try {
            return new Intl.DateTimeFormat(LOCALE, { 
                year: 'numeric', 
                month: 'numeric', 
                day: 'numeric'
            }).format(date);
        } catch (e) {
            console.warn('⚠️ Intl formatter failed on date:', dateString, e);
            return dateString; // Return raw string
        }
    }

    generateUniqueId() {
        return 'id_' + Math.random().toString(36).substr(2, 9);
    }
}