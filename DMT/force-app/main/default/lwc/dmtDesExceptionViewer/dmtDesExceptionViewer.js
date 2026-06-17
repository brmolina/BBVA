import { LightningElement, track } from 'lwc';
import getRecords from '@salesforce/apex/DMT_Des_ExceptionViewerController.getRecords';
import getReportData from '@salesforce/apex/DMT_Des_ExceptionViewerController.getReportData';

export default class DmtDesExceptionViewer extends LightningElement {
    @track copySummaryLabel = 'Copiar para Google Chat';
    rawReportData = []; // Guardará los datos crudos para el CSV
    @track records = [];
    @track filteredRecords = [];
    @track searchTimestampFrom = '';
    @track searchTimestampTo = '';
    @track showError = false;
    @track errorMessage = '';
    @track lastTimestamp = null;
    @track isLoading = false;
    @track projectFilter = '';
    @track typeFilter = '';
    @track classFilter = '';
    @track methodFilter = '';

    @track isModalOpen = false;
    @track selectedRecord = null;
    @track selectedRecordJson = '';
    @track copyButtonLabel = 'Copiar JSON';

    DEFAULT_LIMIT = 25;
    limitSize = this.DEFAULT_LIMIT;
    copyResetTimeout;

    // NUEVAS VARIABLES PARA EL REPORTE
    @track isReportModalOpen = false;
    @track isGeneratingReport = false;
    @track reportSummary = {
        totalRecords: 0,
        projectCounts: [],
        groupedErrors: []
    };

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSearch() {
        if (!this.searchTimestampFrom || !this.searchTimestampTo) {
            this.showError = true;
            this.errorMessage = 'Los campos "Fecha Desde" y "Fecha Hasta" son obligatorios.';
            return;
        }

        const fromDate = new Date(this.searchTimestampFrom);
        const toDate = new Date(this.searchTimestampTo);

        if (toDate < fromDate) {
            this.showError = true;
            this.errorMessage = '"Fecha Hasta" no puede ser anterior a "Fecha Desde".';
            return;
        }

        this.showError = false;
        this.errorMessage = '';
        this.lastTimestamp = null;
        this.records = [];
        this.filteredRecords = [];
        this.fetchRecords();
    }

    fetchRecords() {
        if (this.isLoading) return;

        const isNewSearch = !this.lastTimestamp;
        this.isLoading = true;

        const toDate = new Date(`${this.searchTimestampTo}T23:59:59.999`);
        const adjustedToTimestamp = toDate.toISOString();

        getRecords({
            timestampFrom: this.searchTimestampFrom,
            timestampTo: adjustedToTimestamp,
            limitSize: this.limitSize,
            lastTimestamp: this.lastTimestamp
        })
            .then(data => {
                const existingCount = this.records.length;

                const mappedRecords = (data || []).map((record, index) => ({
                    ...record,
                    rowKey: `${record.Timestamp__c || 'no-date'}-${record.Project__c || 'no-project'}-${existingCount + index}`,
                    formattedTimestamp: this.formatDate(record.Timestamp__c),
                    shortMessage: record.Message__c
                        ? record.Message__c.length > 100
                            ? `${record.Message__c.substring(0, 100)}...`
                            : record.Message__c
                        : ''
                }));

                if (mappedRecords.length > 0) {
                    this.records = isNewSearch
                        ? mappedRecords
                        : [...this.records, ...mappedRecords];

                    this.lastTimestamp = data[data.length - 1].Timestamp__c;
                } else if (isNewSearch) {
                    this.records = [];
                    this.lastTimestamp = null;
                }

                this.applyFilters();
            })
            .catch(error => {
                console.error('Error en fetchRecords:', error);

                if (isNewSearch) {
                    this.records = [];
                    this.filteredRecords = [];
                    this.lastTimestamp = null;
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadMoreRecords() {
        this.fetchRecords();
    }

    connectedCallback() {
        this.setDefaultDates();
        this.fetchRecords();
    }

    setDefaultDates() {
        const today = new Date();
        const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0);

        if (!this.searchTimestampFrom) {
            this.searchTimestampFrom = this.toLocalDateString(firstDay);
        }
        if (!this.searchTimestampTo) {
            this.searchTimestampTo = this.toLocalDateString(lastDay);
        }
    }

    toLocalDateString(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value.trim().toLowerCase();
        this.applyFilters();
    }

    applyFilters() {
        this.filteredRecords = this.records.filter(record => {
            return (
                (this.projectFilter === '' || (record.Project__c && record.Project__c.toLowerCase().includes(this.projectFilter))) &&
                (this.typeFilter === '' || (record.Type__c && record.Type__c.toLowerCase().includes(this.typeFilter))) &&
                (this.classFilter === '' || (record.Class_Name__c && record.Class_Name__c.toLowerCase().includes(this.classFilter))) &&
                (this.methodFilter === '' || (record.MethodName__c && record.MethodName__c.toLowerCase().includes(this.methodFilter)))
            );
        });
    }

    formatDate(timestamp) {
        if (!timestamp) return '';

        const date = new Date(timestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');

        return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
    }

    handleOpenModal(event) {
        const rowKey = event.currentTarget.dataset.id;

        const record =
            this.filteredRecords.find(rec => rec.rowKey === rowKey) ||
            this.records.find(rec => rec.rowKey === rowKey);

        if (!record) return;

        this.selectedRecord = record;
        this.selectedRecordJson = JSON.stringify(this.buildJsonPayload(record), null, 2);
        this.copyButtonLabel = 'Copiar JSON';
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedRecord = null;
        this.selectedRecordJson = '';
    }

    buildJsonPayload(record) {
        return {
            Timestamp__c: record.Timestamp__c ?? null,
            Project__c: record.Project__c ?? null,
            Type__c: record.Type__c ?? null,
            Class_Name__c: record.Class_Name__c ?? null,
            MethodName__c: record.MethodName__c ?? null,
            Message__c: record.Message__c ?? null,
            StackTrace__c: record.StackTrace__c ?? null,
            Object__c: record.Object__c ?? null,
            LineNumber__c: record.LineNumber__c ?? null,
            DML_Fields__c: record.DML_Fields__c ?? null,
            DML_StatusCode__c: record.DML_StatusCode__c ?? null
        };
    }

    async copyJson() {
        try {
            await navigator.clipboard.writeText(this.selectedRecordJson);
        } catch (error) {
            const textarea = this.template.querySelector('.json-textarea');
            if (textarea) {
                textarea.focus();
                textarea.select();
                textarea.setSelectionRange(0, textarea.value.length);
                document.execCommand('copy');
            }
        }

        this.copyButtonLabel = 'Copiado';

        window.clearTimeout(this.copyResetTimeout);
        this.copyResetTimeout = window.setTimeout(() => {
            this.copyButtonLabel = 'Copiar JSON';
        }, 2000);
    }

    // ==========================================
    // NUEVA LÓGICA DE REPORTING
    // ==========================================
    handleGenerateReport() {
        if (!this.searchTimestampFrom || !this.searchTimestampTo) {
            this.showError = true;
            this.errorMessage = 'Los campos "Fecha Desde" y "Fecha Hasta" son obligatorios para generar el reporte.';
            return;
        }

        const fromDate = new Date(`${this.searchTimestampFrom}T00:00:00.000Z`);
        const toDate = new Date(`${this.searchTimestampTo}T23:59:59.999Z`);

        if (toDate < fromDate) {
            this.showError = true;
            this.errorMessage = '"Fecha Hasta" no puede ser anterior a "Fecha Desde".';
            return;
        }

        this.showError = false;
        this.isReportModalOpen = true;
        this.isGeneratingReport = true;

        getReportData({
            timestampFrom: fromDate.toISOString(),
            timestampTo: toDate.toISOString()
        })
        .then(data => {
            this.rawReportData = data; // <-- AÑADIR ESTA LÍNEA
            this.processReportData(data);
        })
        .catch(error => {
            console.error('Error generando reporte:', error);
            this.errorMessage = 'Error al generar el reporte: ' + (error.body ? error.body.message : error.message);
            this.showError = true;
            this.isReportModalOpen = false;
        })
        .finally(() => {
            this.isGeneratingReport = false;
        });
    }

    processReportData(data) {
        let projMap = {};
        let errorMap = {};

        data.forEach(row => {
            // 1. Agrupar por Proyecto
            let pName = row.Project__c || 'Sin Proyecto';
            projMap[pName] = (projMap[pName] || 0) + 1;

            // 2. Agrupar por Clase + Método
            let cName = row.Class_Name__c || 'SinClase';
            let mName = row.MethodName__c || 'SinMetodo';
            let key = `${pName}-${cName}-${mName}`;

            if (!errorMap[key]) {
                errorMap[key] = {
                    id: key,
                    projectName: pName,
                    className: cName,
                    methodName: mName,
                    count: 0,
                    messagesSet: new Set(),
                    stackTracesSet: new Set()
                };
            }

            errorMap[key].count++;

            if (row.Message__c) {
                errorMap[key].messagesSet.add(row.Message__c);
            }
            if (row.StackTrace__c) {
                errorMap[key].stackTracesSet.add(row.StackTrace__c);
            }
        });

        // Convertir mapas a arrays para LWC iteration
        let projectCountsArr = Object.keys(projMap).map(key => ({
            name: key,
            count: projMap[key]
        })).sort((a, b) => b.count - a.count);

        let groupedErrorsArr = Object.values(errorMap).map(group => {
            // Convertir Sets a Arrays con IDs únicos
            let msgs = Array.from(group.messagesSet).map((m, i) => ({ id: `m_${i}`, text: m }));
            let stacks = Array.from(group.stackTracesSet).map((st, i) => ({ id: `st_${i}`, text: st }));

            return {
                id: group.id,
                // 👇 ESTAS 3 LÍNEAS FALTABAN 👇
                projectName: group.projectName,
                className: group.className,
                methodName: group.methodName,
                // 👆 ---------------------- 👆
                label: `[${group.projectName}] ${group.className}.${group.methodName} (${group.count} incidencias)`,
                count: group.count,
                messages: msgs,
                stackTraces: stacks
            };
        }).sort((a, b) => b.count - a.count);

        this.reportSummary = {
            totalRecords: data.length,
            projectCounts: projectCountsArr,
            groupedErrors: groupedErrorsArr
        };
    }

    closeReportModal() {
        this.isReportModalOpen = false;
    }

    // ==========================================
    // EXPORTACIÓN A CSV Y PORTAPAPELES
    // ==========================================

    exportToCSV() {
        if (!this.rawReportData || this.rawReportData.length === 0) return;

        // Definir cabeceras
        const headers = ['Proyecto', 'Clase', 'Método', 'Mensaje', 'Stack Trace'];
        let csvContent = headers.join(',') + '\n';

        // Construir filas escapando comillas y saltos de línea para que Excel no se rompa
        this.rawReportData.forEach(row => {
            let proj = row.Project__c || '';
            let cls = row.Class_Name__c || '';
            let mtd = row.MethodName__c || '';

            // Limpiar saltos de línea y escapar comillas dobles
            let msg = row.Message__c ? row.Message__c.replace(/"/g, '""').replace(/\r?\n|\r/g, ' ') : '';
            let stack = row.StackTrace__c ? row.StackTrace__c.replace(/"/g, '""').replace(/\r?\n|\r/g, ' ') : '';

            csvContent += `"${proj}","${cls}","${mtd}","${msg}","${stack}"\n`;
        });

        // Crear el archivo Blob y forzar descarga
        const blob = new Blob(["\uFEFF" + csvContent], { type: 'text/csv;charset=utf-8;' }); // \uFEFF fuerza UTF-8 en Excel
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `Errores_${this.searchTimestampFrom}_al_${this.searchTimestampTo}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    copyReportSummary() {
        if (!this.reportSummary || this.reportSummary.totalRecords === 0) return;

        // Construir el texto en formato Markdown sin emojis
        let text = `*Reporte de Excepciones Salesforce*\n`;
        text += `Fechas: ${this.searchTimestampFrom} a ${this.searchTimestampTo}\n`;
        text += `Total de errores analizados: ${this.reportSummary.totalRecords}\n\n`;

        text += `*Resumen por Proyecto:*\n`;
        this.reportSummary.projectCounts.forEach(p => {
            text += `- ${p.name}: ${p.count} errores\n`;
        });

        text += `\n*Top Errores Recurrentes (Clase.Método):*\n`;

        // Solo mostramos los 10 primeros para no saturar el chat
        this.reportSummary.groupedErrors.slice(0, 10).forEach(g => {
            text += `\n- *[${g.projectName}] ${g.className}.${g.methodName}* (${g.count} incidencias)\n`;

            // Añadir el primer mensaje detectado para esta agrupación
            if (g.messages && g.messages.length > 0) {
                // Quitamos los saltos de línea del mensaje para que ocupe una sola línea
                let msg = g.messages[0].text.replace(/\r?\n|\r/g, ' ');
                text += `  > *Mensaje:* ${msg}\n`;
            }

            // Añadir el primer Stack Trace detectado en formato de bloque de código
            if (g.stackTraces && g.stackTraces.length > 0) {
                let stack = g.stackTraces[0].text;
                text += `  \`\`\`\n${stack}\n  \`\`\`\n`;
            }
        });

        // Copiar al portapapeles
        navigator.clipboard.writeText(text).then(() => {
            this.copySummaryLabel = '¡Copiado!';
            setTimeout(() => {
                this.copySummaryLabel = 'Copiar para Slack/Teams';
            }, 3000);
        }).catch(err => {
            console.error('Error al copiar al portapapeles: ', err);
        });
    }
}