import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getDMTData from '@salesforce/apex/DMT_TreasuryReportController.getDMTData'; 
import hasPermission from '@salesforce/customPermission/DMT_Line_God';
import hasAccessUO from '@salesforce/apex/DMT_TreasuryReportController.hasAccessUO';

export default class Dmt_treasuryreport extends NavigationMixin(LightningElement)  {
    @track hierarchicalData = [];
    @track filteredData = [];           // Datos filtrados para mostrar
    @track searchTerm = '';             // Término de búsqueda por Line ID
    @track selectedGeography = '';      // Filtro por Booking Geography
    @track generalSearchTerm = '';      // Búsqueda general en todos los campos
    @track isLoading = true;
    @track error;
    @track accessAllowed = true;

      get hasActiveFilters() {
        return this.searchTerm || this.selectedGeography || this.generalSearchTerm;
    }

    async connectedCallback() {
        try {
            if (hasPermission) {
                this.accessAllowed = true;
                return;
            }
            this.accessAllowed = await hasAccessUO();
        } catch (error) {
            this.accessAllowed = false;
            console.error('Error checking access:', error);
        } finally {
            if (!this.accessAllowed) this.isLoading = false;
        }
    }  

    @wire(getDMTData)
    wiredDMTData({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.hierarchicalData = this.processHierarchicalData(data);
            this.filteredData = this.hierarchicalData; // Mostrar todo inicialmente
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.hierarchicalData = [];
            this.filteredData = [];
            console.error('Error loading DMT data:', error);
        }
    }

processHierarchicalData(data) {
    if (!data || !Array.isArray(data)) return [];
    
    let allItems = [];
    let globalIndex = 0;
    
    // Recorrer toda la estructura
    data.forEach((group, groupIndex) => {
        group.clients.forEach((client, clientIndex) => {
            client.lines.forEach((line, lineIndex) => {
                // Procesar fechas de la línea
                const lineWithDates = {
                    ...line,
                    startDateFormatted: line.startDate ? this.formatDate(line.startDate) : '',
                    endDateFormatted: line.endDate ? this.formatDate(line.endDate) : ''
                };
                
                // Información común para todos los risks de esta línea
                const lineCommonInfo = {
                    // Información del grupo
                    groupCode: group.groupCode || '',
                    
                    // Información del cliente
                    accountName: client.accountName || '',
                    sector: client.sector || '',
                    customerId: client.customerId || '',
                    starCode: client.starCode || '',
                    fiscalId: client.fiscalId || '',
                    rating: client.rating || '',
                    
                    // Información de la línea
                    lineId: line.lineId || '',
                    dmtLineId: line.dmtLineId || '',
                    lastUpdated: line.lastUpdated || '',
                    status: line.status || '',
                    startDateFormatted: lineWithDates.startDateFormatted,
                    endDateFormatted: lineWithDates.endDateFormatted,
                    bookingGeography: line.bookingGeography || '',
                    currencyIsoCode: line.currencyIsoCode || '',
                    additionalProducts: line.addProd || '',
                    
                    // Metadatos para agrupación
                    groupIndex,
                    clientIndex,
                    lineIndex,
                    totalRisksInLine: line.risks ? line.risks.length : 1
                };
                
                // Si la línea tiene risks, crear un item por cada risk
                if (line.risks && line.risks.length > 0) {
                    line.risks.forEach((risk, riskIndex) => {console.log('line.lineId',line.lineId);console.log('risk',risk.naToNa);
                        // Procesar el risk con los valores formateados
                        const processedRisk = {
                            ...risk,
                            naToNa: this.formatCurrency(risk.naToNa, line.conversionFactor, line.conversionLabel),
                            zeroDaysTo3Years: this.formatCurrency(risk.zeroDaysTo3Years, line.conversionFactor, line.conversionLabel),
                            threeYearsTo5Years: this.formatCurrency(risk.threeYearsTo5Years, line.conversionFactor, line.conversionLabel),
                            fiveYearsTo8Years: this.formatCurrency(risk.fiveYearsTo8Years, line.conversionFactor, line.conversionLabel),
                            eightYearsTo10Years: this.formatCurrency(risk.eightYearsTo10Years, line.conversionFactor, line.conversionLabel)
                        };
                        
                        allItems.push({
                            key: `item-${groupIndex}-${clientIndex}-${lineIndex}-${riskIndex}`,
                            
                            // Toda la información común de la línea
                            ...lineCommonInfo,
                            
                            // Información específica del risk
                            typeOfRisk: processedRisk.typeOfRisk || '',
                            product: processedRisk.product || '',
                            naToNa: processedRisk.naToNa || '',
                            zeroDaysTo3Years: processedRisk.zeroDaysTo3Years || '',
                            threeYearsTo5Years: processedRisk.threeYearsTo5Years || '',
                            fiveYearsTo8Years: processedRisk.fiveYearsTo8Years || '',
                            eightYearsTo10Years: processedRisk.eightYearsTo10Years || '',
                            
                            // Flag para saber si es el primer risk de la línea
                            isFirstInLine: riskIndex === 0,
                            
                            // Metadata
                            riskIndex
                        });
                    });
                } else {
                    // Si la línea no tiene risks, crear un item con valores vacíos
                    allItems.push({
                        key: `item-${groupIndex}-${clientIndex}-${lineIndex}-norisk`,
                        
                        ...lineCommonInfo,
                        
                        typeOfRisk: '',
                        product: '',
                        naToNa: '',
                        zeroDaysTo3Years: '',
                        threeYearsTo5Years: '',
                        fiveYearsTo8Years: '',
                        eightYearsTo10Years: '',
                        
                        isFirstInLine: true,
                        riskIndex: -1
                    });
                }
            });
        });
    });
    
    return allItems?.sort((a, b) => new Date(b.lastUpdated) - new Date(a.lastUpdated));
}

    // Crear risk vacío para líneas sin risks
    createEmptyRisk(lineKey) {
        return {
            key: `${lineKey}-empty-risk`,
            lastLevelId: '',
            typeOfRisk: '',
            product: '',
            naToNa: '',
            zeroDaysTo3Years: '',
            threeYearsTo5Years: '',
            fiveYearsTo8Years: '',
            eightYearsTo10Years: '',
            isFirstInGroup: false,
            isFirstInClient: false,
            isFirstInLine: true
        };
    }

    // Crear línea vacía para clients sin lines
    createEmptyLine(clientKey) {
        return {
            key: `${clientKey}-empty-line`,
            lineId: '',
            dmtLineId: '',
            currencyIsoCode: '',
            bookingGeography: '',
            startDate: null,
            endDate: null,
            status: '',
            startDateFormatted: '',
            endDateFormatted: '',
            risks: [this.createEmptyRisk(`${clientKey}-empty-line`)],
            totalRows: 1
        };
    }

      handleRowClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this.navigateToRecordEmergency(recordId);
        }

    }

    navigateToRecordEmergency(recordId) {
        console.log('=== EMERGENCY NAVIGATION CORREGIDO ===');

        const currentUrl = window.location.hostname;
        let baseUrl = '';

        if (currentUrl.includes('.vforce.com')) {
            // Para URLs de community tipo vforce
            baseUrl = currentUrl.split('/s/')[0];
        } else if (currentUrl.includes('.force.com')) {
            // Para URLs de community tipo force.com
            baseUrl = currentUrl.split('/s/')[0];
        } else {
            // Para cualquier otro caso, usar origin
            baseUrl = window.location.origin;
        }

        const recordUrl = `/lightning/r/DMT_Line__c/${recordId}/view`;
        window.open(recordUrl, '_blank');
    }


exportToExcel() {
    this.exportData('xlsx');
}

exportToCSV() {
    this.exportData('csv');
}

exportData(format) {
    const dataToExport = this.hasActiveFilters ? this.filteredData : this.hierarchicalData;
    
    if (dataToExport.length === 0) {
        this.showToast('No data to export', 'Please wait for data to load', 'warning');
        return;
    }

    const headers = [
        'Group Name', 'Client Name', 'Sector', 'Customer ID', 'Star Code', 'Fiscal ID', 'Rating',
        'Line ID', 'Last Updated', 'Status', 'Start Date', 'End Date', 'Geography',
        'Currency', 'Additional Products',
        'Type of Risk', 'Product', 'N/A to N/A', '0 Days to 3 Years',
        '3 Years to 5 Years', '5 Years to 8 Years', '8 Years to 10 Years'
    ];

    // Con la estructura plana, ya no necesitamos anidar bucles
    // Simplemente mapeamos cada item directamente a una fila
    const data = dataToExport.map(item => [
        item.groupCode || '',
        item.accountName || '',
        item.sector || '',
        item.customerId || '',
        item.starCode || '',
        item.fiscalId || '',
        item.rating || '',
        item.lineId || '',
        item.lastUpdated ? new Date(item.lastUpdated).toLocaleDateString('en-US') : '',
        item.status || '',
        item.startDateFormatted || '',
        item.endDateFormatted || '',
        item.bookingGeography || '',
        item.currencyIsoCode || '',
        item.additionalProducts || '',
        item.typeOfRisk || '',
        item.product || '',
        // Limpiar los valores de moneda para exportación (quitar puntos y símbolos)
        this.cleanCurrencyForExport(item.naToNa || ''),
        this.cleanCurrencyForExport(item.zeroDaysTo3Years || ''),
        this.cleanCurrencyForExport(item.threeYearsTo5Years || ''),
        this.cleanCurrencyForExport(item.fiveYearsTo8Years || ''),
        this.cleanCurrencyForExport(item.eightYearsTo10Years || '')
    ]);

    if (format === 'csv') {
        this.downloadCSV(headers, data);
    } else {
        this.downloadExcel(headers, data);
    }
}

// Método auxiliar para limpiar valores de moneda antes de exportar
cleanCurrencyForExport(value) {
    if (!value) return '';
    // Si es un string, eliminar puntos (separadores de miles) y el símbolo de moneda
    if (typeof value === 'string') {
        // Eliminar puntos y espacios, quedarse solo con números y posible signo negativo
        return value.replace(/[^\d-]/g, '');
    }
    return value;
}

downloadCSV(headers, data) {
    const csvContent = [
        headers.join(','),
        ...data.map(row => row.map(field => this.escapeCSV(field)).join(','))
    ].join('\n');

    const element = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
    const downloadElement = document.createElement('a');
    downloadElement.href = element;
    downloadElement.target = '_self';
    downloadElement.download = 'Treasury_Line_Data.csv';
    document.body.appendChild(downloadElement);
    downloadElement.click();
    document.body.removeChild(downloadElement);
}

// Método para Excel (puedes implementar downloadExcel si lo necesitas)
downloadExcel(headers, data) {
    // Por ahora usamos CSV también para Excel
    this.downloadCSV(headers, data);
}

escapeCSV(field) {
    if (field === null || field === undefined) return '';
    const stringField = String(field);
    if (stringField.includes(',') || stringField.includes('"') || stringField.includes('\n')) {
        return `"${stringField.replace(/"/g, '""')}"`;
    }
    return stringField;
}

formatCurrency(value, conversionFactor, conversionLabel) {
    if (!value) return '';

    // Convertir a número
    let num = Number(value);
    if (isNaN(num)) return value;

    // Redondear a 0 decimales
    num = Math.round(num) / conversionFactor;

    // Formatear con separador de miles (puntos)
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ' ' + conversionLabel;
}

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US');
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

        // === MÉTODO DE BÚSQUEDA POR LINE ID ===
    handleSearch(event) {
        this.searchTerm = event.target.value.trim();
        this.applyFilters();
    }

    // === MÉTODO DE FILTRADO POR BOOKING GEOGRAPHY ===
    handleGeographyChange(event) {
        this.selectedGeography = event.target.value;
        this.applyFilters();
    }

    handleGeneralSearch(event) {
        this.generalSearchTerm = event.target.value.trim();
        this.applyFilters();
    }

    handleGeneralSearchKeyDown(event) {
        if (event.key === 'Enter') {
            this.applyFilters();
        }
    }

    // === APLICAR AMBOS FILTROS ===
applyFilters() {
    if (!this.generalSearchTerm && !this.selectedGeography && !this.searchTerm) {
        this.filteredData = this.hierarchicalData;
        return;
    }

    const searchLower = this.generalSearchTerm ? this.generalSearchTerm.toLowerCase() : '';

    // Filtrar directamente sobre el array lineal
    this.filteredData = this.hierarchicalData.filter(item => {
        // Filtro por Geography
        let matchesGeography = true;
        if (this.selectedGeography) {
            matchesGeography = item.bookingGeography === this.selectedGeography;
        }

        // Filtro por búsqueda general
        let matchesSearch = true;
        if (searchLower) {
            matchesSearch = 
                (item.groupCode && item.groupCode.toLowerCase().includes(searchLower)) ||
                (item.accountName && item.accountName.toLowerCase().includes(searchLower)) ||
                (item.sector && item.sector.toLowerCase().includes(searchLower)) ||
                (item.customerId && item.customerId.toLowerCase().includes(searchLower)) ||
                (item.lineId && item.lineId.toLowerCase().includes(searchLower)) ||
                (item.currencyIsoCode && item.currencyIsoCode.toLowerCase().includes(searchLower)) ||
                (item.bookingGeography && item.bookingGeography.toLowerCase().includes(searchLower)) ||
                (item.status && item.status.toLowerCase().includes(searchLower)) ||
                (item.startDateFormatted && item.startDateFormatted.toLowerCase().includes(searchLower)) ||
                (item.endDateFormatted && item.endDateFormatted.toLowerCase().includes(searchLower)) ||
                (item.typeOfRisk && item.typeOfRisk.toLowerCase().includes(searchLower)) ||
                (item.product && item.product.toLowerCase().includes(searchLower));
        }

        // Filtro por Line ID específico
        let matchesLineId = true;
        if (this.searchTerm) {
            matchesLineId = item.lineId && item.lineId.toLowerCase().includes(this.searchTerm.toLowerCase());
        }

        return matchesGeography && matchesSearch && matchesLineId;
    });
}


// === NUEVO MÉTODO: REPROCESAR JERARQUÍA DESPUÉS DE FILTRAR ===
reprocessFilteredHierarchy(filteredGroups) {
    return filteredGroups.map((group, groupIndex) => {
        let groupTotalRows = 0;

        const processedClients = group.clients.map((client, clientIndex) => {
            let clientTotalRows = 0;

            const processedLines = client.lines.map((line, lineIndex) => {
                // Procesar risks con flags de posición CORRECTAS para el contexto filtrado
                const processedRisks = line.risks.map((risk, riskIndex) => {
                    // === CORRECCIÓN: Recalcular flags basadas en la posición REAL en los datos filtrados ===
                    const isFirstInGroup = (clientIndex === 0 && lineIndex === 0 && riskIndex === 0);
                    const isFirstInClient = (lineIndex === 0 && riskIndex === 0);
                    const isFirstInLine = (riskIndex === 0);

                    return {
                        ...risk,
                        key: `risk-${groupIndex}-${clientIndex}-${lineIndex}-${riskIndex}`,
                        isFirstInGroup: isFirstInGroup,
                        isFirstInClient: isFirstInClient,
                        isFirstInLine: isFirstInLine
                    };
                });

                const lineTotalRows = processedRisks.length > 0 ? processedRisks.length : 1;
                clientTotalRows += lineTotalRows;

                return {
                    ...line,
                    key: `line-${groupIndex}-${clientIndex}-${lineIndex}`,
                    risks: processedRisks.length > 0 ? processedRisks : [this.createEmptyRisk(`line-${groupIndex}-${clientIndex}-${lineIndex}`)],
                    totalRows: lineTotalRows
                };
            });

            clientTotalRows = clientTotalRows > 0 ? clientTotalRows : 1;

            return {
                ...client,
                key: `client-${groupIndex}-${clientIndex}`,
                lines: processedLines,
                totalRows: clientTotalRows
            };
        });

        // Calcular total de filas para el grupo
        groupTotalRows = processedClients.reduce((total, client) => total + client.totalRows, 0);

        return {
            ...group,
            key: `group-${groupIndex}`,
            clients: processedClients,
            totalRows: groupTotalRows
        };
    });
}

    // === LIMPIAR TODOS LOS FILTROS ===
    clearFilters() {
        this.searchTerm = '';
        this.selectedGeography = '';
        this.filteredData = this.hierarchicalData;

        // Limpiar los inputs
        const searchInput = this.template.querySelector('input[type="text"]');
        if (searchInput) {
            searchInput.value = '';
        }

        const geographySelect = this.template.querySelector('select');
        if (geographySelect) {
            geographySelect.value = '';
        }
    }

}