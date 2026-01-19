import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getDMTData from '@salesforce/apex/DMT_TreasuryReportController.getDMTData';

export default class Dmt_treasuryreport extends NavigationMixin(LightningElement)  {
    @track hierarchicalData = [];
    @track filteredData = [];           // Datos filtrados para mostrar
    @track searchTerm = '';             // Término de búsqueda por Line ID
    @track selectedGeography = '';      // Filtro por Booking Geography
    @track generalSearchTerm = '';      // Búsqueda general en todos los campos
    @track isLoading = true;
    @track error;
    
      get hasActiveFilters() {
        return this.searchTerm || this.selectedGeography || this.generalSearchTerm;
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
        return data.map((group, groupIndex) => {
            let groupKey = `group-${groupIndex}`;
            let groupTotalRows = 0;

            const processedClients = group.clients.map((client, clientIndex) => {
                let clientKey = `client-${groupIndex}-${clientIndex}`;
                let clientTotalRows = 0;

                const processedLines = client.lines.map((line, lineIndex) => {
                    let lineKey = `line-${groupIndex}-${clientIndex}-${lineIndex}`;
                    
                    // Procesar fechas
                    const lineWithDates = {
                        ...line,
                        startDateFormatted: line.startDate ? this.formatDate(line.startDate) : '',
                        endDateFormatted: line.endDate ? this.formatDate(line.endDate) : ''
                    };

                    // === CORRECCIÓN: Procesar risks con flags de posición CORREGIDAS ===
                    const processedRisks = line.risks.map((risk, riskIndex) => {
                        // === NUEVO: Cálculo simplificado y correcto de las flags ===
                        const isFirstInGroup = (clientIndex == 0 && lineIndex == 0 && riskIndex == 0);
                        const isFirstInClient = (lineIndex == 0 && riskIndex == 0);
                        const isFirstInLine = (riskIndex == 0);
                        // === FIN NUEVO ===
                        
                        return {
                            ...risk,
                            key: `risk-${groupIndex}-${clientIndex}-${lineIndex}-${riskIndex}`,
                            // === NUEVO: Asignación de flags corregidas ===
                            isFirstInGroup: isFirstInGroup,
                            isFirstInClient: isFirstInClient,
                            isFirstInLine: isFirstInLine,
                            naToNa: this.formatCurrency(risk.naToNa, line.conversionFactor, line.conversionLabel),
                            zeroDaysTo3Years: this.formatCurrency(risk.zeroDaysTo3Years, line.conversionFactor, line.conversionLabel),
                            threeYearsTo5Years: this.formatCurrency(risk.threeYearsTo5Years, line.conversionFactor, line.conversionLabel),
                            fiveYearsTo8Years: this.formatCurrency(risk.fiveYearsTo8Years, line.conversionFactor, line.conversionLabel),
                            eightYearsTo10Years: this.formatCurrency(risk.eightYearsTo10Years, line.conversionFactor, line.conversionLabel)
                            // === FIN NUEVO ===
                        };
                    });

                    const lineTotalRows = processedRisks.length > 0 ? processedRisks.length : 1;
                    clientTotalRows += lineTotalRows;

                    return {
                        ...lineWithDates,
                        key: lineKey,
                        risks: processedRisks.length > 0 ? processedRisks : [this.createEmptyRisk(lineKey)],
                        totalRows: lineTotalRows
                    };
                });

                return {
                    ...client,
                    key: clientKey,
                    lines: processedLines.length > 0 ? processedLines : [this.createEmptyLine(clientKey)],
                    totalRows: clientTotalRows > 0 ? clientTotalRows : 1
                };
            });

            // Calcular total de filas para el grupo
            groupTotalRows = processedClients.reduce((total, client) => total + client.totalRows, 0);

            return {
                ...group,
                key: groupKey,
                clients: processedClients,
                totalRows: groupTotalRows
            };
        });
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
            'Group Name', 'Client Name', 'Sector', 'Customer ID', 'Fiscal ID',
            'Line ID', 'Currency', 'Booking Geography', 'Start Date', 'End Date', 'Status',
            'Type of Risk', 'Product', 'N/A to N/A', '0 Days to 3 Years', 
            '3 Years to 5 Years', '5 Years to 8 Years', '8 Years to 10 Years'
        ];

        // Aplanar datos jerárquicos para exportación
        const data = [];
        dataToExport.forEach(group => {
            group.clients.forEach(client => {
                client.lines.forEach(line => {
                    line.risks.forEach(risk => {
                        data.push([
                            group.groupCode || '',
                            client.accountName || '',
                            client.sector || '',
                            client.customerId || '',
                            client.starCode || '',
                            client.fiscalId || '',
                            line.lineId || '',
                            line.currencyIsoCode || '',
                            line.bookingGeography || '',
                            line.startDateFormatted || '',
                            line.endDateFormatted || '',
                            line.status || '',
                            risk.typeOfRisk || '',
                            risk.product || '',
                            risk.naToNa || '',
                            risk.zeroDaysTo3Years || '',
                            risk.threeYearsTo5Years || '',
                            risk.fiveYearsTo8Years || '',
                            risk.eightYearsTo10Years || ''
                        ]);
                    });
                });
            });
        });

        if (format === 'csv') {
            this.downloadCSV(headers, data);
        } else {
            this.downloadExcel(headers, data);
        }
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

    downloadCSV(headers, data) {
        const csvContent = [
            headers.join(','),
            ...data.map(row => row.map(field => this.escapeCSV(field)).join(','))
        ].join('\n');

        var element = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Treasury Line Data.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }




    escapeCSV(field) {
        if (field === null || field === undefined) return '';
        const stringField = String(field);
        if (stringField.includes(',') || stringField.includes('"') || stringField.includes('\n')) {
            return `"${stringField.replace(/"/g, '""')}"`;
        }
        return stringField;
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
        console.log('generalSearch2Term: ' + this.generalSearchTerm)
        const searchLower = this.generalSearchTerm ? this.generalSearchTerm.toLowerCase() : '';
        
        // Filtrar manteniendo la estructura jerárquica
        const filteredGroups = this.hierarchicalData.map(group => {
            // Buscar en campos del grupo
            const groupMatches = searchLower ? 
                (group.groupCode && group.groupCode.toLowerCase().includes(searchLower)) : 
                false;
            
            // Filtrar clients
            const filteredClients = group.clients.map(client => {
                // Buscar en campos del cliente
                const clientMatches = searchLower ? (
                    (client.accountName && client.accountName.toLowerCase().includes(searchLower)) ||
                    (client.sector && client.sector.toLowerCase().includes(searchLower)) ||
                    (client.customerId && client.customerId.toLowerCase().includes(searchLower)) ||
                    (client.fiscalId && client.fiscalId.toLowerCase().includes(searchLower)) ||
                    (client.rating && client.rating.toLowerCase().includes(searchLower))
                ) : false;
                
                // Filtrar lines
                const filteredLines = client.lines.filter(line => {
                    // Aplicar filtro por Geography
                    let matchesGeography = true;
                    if (this.selectedGeography) {
                        matchesGeography = line.bookingGeography === this.selectedGeography;
                    }
                    
                    // Buscar en campos de la línea
                    let matchesSearch = true;
                    if (searchLower) {
                        matchesSearch = (
                            clientMatches || // Si el cliente ya coincide, incluir todas sus líneas
                            groupMatches ||  // Si el grupo ya coincide, incluir todas sus líneas
                            (line.lineId && line.lineId.toLowerCase().includes(searchLower)) ||
                            (line.currencyIsoCode && line.currencyIsoCode.toLowerCase().includes(searchLower)) ||
                            (line.bookingGeography && line.bookingGeography.toLowerCase().includes(searchLower)) ||
                            (line.status && line.status.toLowerCase().includes(searchLower)) ||
                            // Buscar en campos formateados también
                            (line.startDateFormatted && line.startDateFormatted.toLowerCase().includes(searchLower)) ||
                            (line.endDateFormatted && line.endDateFormatted.toLowerCase().includes(searchLower))
                        );
                    }
                    
                    // Buscar en los risks de esta línea
                    if (searchLower && !matchesSearch) {
                        const lineHasMatchingRisk = line.risks.some(risk => 
                            (risk.lastLevelId && risk.lastLevelId.toLowerCase().includes(searchLower)) ||
                            (risk.typeOfRisk && risk.typeOfRisk.toLowerCase().includes(searchLower)) ||
                            (risk.product && risk.product.toLowerCase().includes(searchLower)) ||
                            (risk.naToNa && risk.naToNa.toLowerCase().includes(searchLower)) ||
                            (risk.zeroDaysTo3Years && risk.zeroDaysTo3Years.toLowerCase().includes(searchLower)) ||
                            (risk.threeYearsTo5Years && risk.threeYearsTo5Years.toLowerCase().includes(searchLower)) ||
                            (risk.fiveYearsTo8Years && risk.fiveYearsTo8Years.toLowerCase().includes(searchLower)) ||
                            (risk.eightYearsTo10Years && risk.eightYearsTo10Years.toLowerCase().includes(searchLower))
                        );
                        matchesSearch = lineHasMatchingRisk;
                    }
                    
                    return matchesGeography && matchesSearch;
                });
                
                // Si el cliente tiene líneas que coinciden O el cliente mismo coincide, mantenerlo
                return filteredLines.length > 0 || clientMatches ? {
                    ...client,
                    lines: filteredLines
                } : null;
            }).filter(client => client !== null);
            
            // Si el grupo tiene clients que coinciden O el grupo mismo coincide, mantenerlo
            return filteredClients.length > 0 || groupMatches ? {
                ...group,
                clients: filteredClients
            } : null;
        }).filter(group => group !== null);
        
        // Reprocesar la jerarquía para recalcular flags
        this.filteredData = this.reprocessFilteredHierarchy(filteredGroups);
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