import { LightningElement, api, track } from 'lwc';
import { CloseScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from "lightning/modal";
import updateMultiOperationTypeFromMap from '@salesforce/apex/DMT_ConsolidatedLineService.updateMultiOperationType';
import getConsolidatedLines from '@salesforce/apex/DMT_ConsolidatedLineService.getConsolidatedLines';

export default class Dmt_connect_operations extends LightningModal {
    // Atributos API recibidos desde la fresca
    @track linesTable = [];
    recordsLine = [];
    @track consolidatedLines = [];
    @api
    get lines() {
      //this.handledefaultLimit();
      return this.recordsLine;
    }
    set lines(value) {
      //this.linesTable = value;
        if (value && Array.isArray(value)) {
            // ✅ EXTRAER SOLO LOS IDs DEL CAMPO ESPECÍFICO
            const lineIds = value
                .map(item => item?.Line_Id__c)  // Extrae el campo que necesitas
                .filter(Id => Id != null);      // Limpia nulos
            
            this._lineIds = lineIds;
            this.cargarDatos(lineIds).then(() => {
                this.validateInput();
                this.initializeSelections();
                this.setupPagination();
            });
        }
        console.log('conso',JSON.stringify(this.linesTable))
        // this.validateInput();
        // this.initializeSelections();
        // this.setupPagination();
    }
    columns = [
    {

      "type": "text",
      "sortable": "true",
      "label": "Name",
      "hideDefaultActions": "true",
      "fieldName": "g_line_name_desc__c"
    },
    {

      "type": "text",
      "label": "Status",
      "sortable": "true",
      "hideDefaultActions": "true",
      "fieldName": "status__c"
    },
    {

      "type": "text",
      "label": "Line Id",
      "sortable": "true",
      "hideDefaultActions": "true",
      "fieldName": "line_id__c"
    }
  ] // Columnas para la datatable
    @api selectedLabel = 'Save'; // Label del botón save
    @api title = 'Select Lines'; // Título del flyout
    @api maxChanges = 20; // Máximo número de cambios permitidos (parametrizable)
    @api preselectedField = 'g_multioperation_ind_type__c'; // Campo que indica selección inicial
    
    // Variables internas
    @track selectedRows = [];
    @track isLoading = false;
    @track hasError = false;
    @track errorMessage = '';
    
    // Variables para paginación
    @track currentPage = 1;
    @track pageSize = 20; // Mostrar 20 registros por página
    @track paginatedLines = [];
    @track totalPages = 1;
    
    // Variables para control de cambios
    @track initialSelections = new Set(); // IDs inicialmente seleccionados
    @track changesMade = 0; // Contador de cambios realizados
    @track reachedMaxChanges = false;
    firstPage = true;
    lastPage = false;

    renderedCallback(){
        let elemento = this.template.querySelector('.slds-th__action_form');console.log('elemento', elemento);
        if (elemento) {
            elemento.style.display = 'none'; // o 'block', 'flex', etc.
        }
    }

    get currentPageSelectedRows() {
        const currentPageIds = this.currentPageData.map(row => row.Id);
        return this.selectedRows.filter(id => currentPageIds.includes(id));
    }
    
    // Método getter para las líneas de la página actual
    get currentPageData() {
        
        return this.paginatedLines;
    }
    
    // Método getter para líneas seleccionadas actualmente
    get selectedLines() {
        return this.currentPageData.filter(line => this.selectedRows.includes(line.Id));
    }
    
    // Método getter para verificar si hay selecciones
    get hasSelectedRows() {
        return this.selectedRows.length > 0;
    }
    
    // Getter para deshabilitar checkboxes si se alcanzó el límite
    get isSelectionDisabled() {
        return this.reachedMaxChanges && this.changesMade >= this.maxChanges;
    }
    

    cargarDatos(lineIds) {
        if (!lineIds || lineIds.length === 0) {
            this.linesTable = [];
            return;
        }

        this.isLoading = true;console.log('lineIds',JSON.stringify(lineIds))

        return getConsolidatedLines({ lineIds: lineIds })
            .then(result => {
            const transformedData = result.map(item => ({
            ...item,  // Mantiene todos los campos originales
            g_multioperation_ind_type__c: item.g_multioperation_ind_type__c !== 'x'  // X = false, cualquier otra cosa = true
            }));
                this.linesTable = transformedData;console.log('result',JSON.stringify(this.linesTable));
            })
            .catch(error => {
                this.linesTable = [];
                console.error('Error cargando líneas:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    // Validar datos de entrada
    validateInput() {
        if (!this.linesTable || this.linesTable.length === 0) {
            this.hasError = true;
            this.errorMessage = 'No lines data provided';
            return;
        }
        
        // Establecer columnas por defecto si no se proporcionan
        if (!this.columns || this.columns.length === 0) {
            this.setDefaultColumns();
        }
        
        // Añadir columna de checkbox con lógica condicional
        //this.addCheckboxColumn();
    }
    
    // Inicializar selecciones basadas en el campo preseleccionado
    initializeSelections() {
        this.linesTable.forEach(line => {
            if (line[this.preselectedField] === true) {
                this.selectedRows.push(line.Id);
                this.initialSelections.add(line.Id);
            }
        });
    }
    
    // Configurar paginación
    setupPagination() {
        this.totalPages = Math.ceil(this.linesTable.length / this.pageSize);
        this.updatePaginatedData();
    }
    
    // Actualizar datos paginados
    updatePaginatedData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.paginatedLines = this.linesTable.slice(startIndex, endIndex);
    }
    
    // Manejar selección de filas
    handleRowSelection(event) {console.log('prev',JSON.stringify(event.detail));
        this.isLoading = true;
        //if ( this.isLoading == false){
        const multiOp = event.detail.config.action == 'rowSelect' ? true : false;
        const selectId = this.linesTable.find(({ Id }) => Id === event.detail.config.value)?.line_id__c;
        if (event.detail.config.action == 'rowSelect'){
            this.selectedRows.push(event.detail.config.value);
            this.updateConsolidated(selectId, multiOp);
        } else if(event.detail.config.action == 'rowDeselect') {
            this.selectedRows = this.selectedRows.filter(Id => Id !== event.detail.config.value);
            this.updateConsolidated(selectId, multiOp);
        }
        
        //}
        this.isLoading = false;        
    }

    updateConsolidated(selectId, multiOp){
        
        updateMultiOperationTypeFromMap({ lineId: selectId , multiOperationTypeValue: multiOp})
            .then(result => {
                this.showToast('Success', 'The line has been reconnected correctly.', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred while trying to update the line. Please, ask functional support.', 'error');
                console.log('result.error', error);
            });
    }
    
    // Calcular número de cambios respecto a la selección inicial
    calculateChanges(newSelection) {
        const newSet = new Set(newSelection);
        let changes = 0;
        
        // Contar selecciones añadidas que no estaban inicialmente
        newSet.forEach(Id => {
            if (!this.initialSelections.has(Id)) {
                changes++;
            }
        });
        
        // Contar deselecciones que estaban inicialmente
        this.initialSelections.forEach(Id => {
            if (!newSet.has(Id)) {
                changes++;
            }
        });
        
        return changes;
    }
    
    // Restaurar selección anterior
    restorePreviousSelection() {
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.selectedRows = [...this.selectedRows];
        }
    }
    
    // Añadir columna de checkbox con lógica condicional
    addCheckboxColumn() {
        // Verificar si ya existe una columna de checkbox
        const hasCheckboxColumn = this.columns.some(col => col.type === 'checkbox');
        
        if (!hasCheckboxColumn) {
            this.columns.unshift({
                label: 'Select',
                type: 'checkbox',
                fieldName: 'checkbox',
                cellAttributes: {
                    class: {
                        fieldName: 'checkboxClass'
                    }
                }
            });
        }
    }
    
    // Establecer columnas por defecto
    setDefaultColumns() {
        this.columns = [
            { label: 'Line Name', fieldName: 'Name', type: 'text' },
            { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },
            { label: 'Account', fieldName: 'AccountName', type: 'text' }
        ];
    }
    
    // Manejar Save
async handleSave() {
    const lineUpdates = {};
    console.log('this.linesData', JSON.stringify(this.linesData));
    // Suponiendo que tienes los datos seleccionados
    this.linesData.forEach(record => {
        lineUpdates[record.line_id__c] = record.g_multioperation_ind_type__c;console.log('lineUpdates', JSON.stringify(lineUpdates));
    });
    
    try {
        const result = await updateMultiOperationTypeFromMap({ lineIdToValueMap: lineUpdates });
        
        if (result.success) {
            console.log('result.success', result.success);
        } else {
            console.log('result.errrrrro', result);
        }
    } catch (error) {
        console.log('result.error', error);
    }
}
    
    // Manejar Cancel
    handleCancel() {
        this.close()
    }
    
    // Navegación de paginación
    handleFirstPage() {
        this.currentPage = 1;
        this.firstPage = true;
        this.lastPage = this.currenPage === this.totalPages;
        this.updatePaginatedData();
    }
    
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.firstPage = this.currentPage === 1;;
            this.lastPage = this.currenPage === this.totalPages;
            this.updatePaginatedData();
        }
    }
    
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.firstPage = this.currentPage === 1;;
            this.lastPage = this.currenPage === this.totalPages;
            this.updatePaginatedData();
        }
    }
    
    handleLastPage() {
        this.currentPage = this.totalPages;
        this.firstPage = this.currentPage === 1;;
        this.lastPage = this.currenPage === this.totalPages;
        this.updatePaginatedData();
    }
    
    // Mostrar toast messages
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
    
    // Getter para información de paginación
    get pageInfo() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.linesTable.length);
        return `Showing ${start}-${end} of ${this.linesTable.length} records`;
    }
    
    get changesInfo() {
        return `Changes: ${this.changesMade}/${this.maxChanges}`;
    }
}