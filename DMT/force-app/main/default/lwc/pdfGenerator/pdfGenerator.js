import { LightningElement, api } from 'lwc';
import jsPdfLib from '@salesforce/resourceUrl/jsPDF_bundle';
import { loadScript } from 'lightning/platformResourceLoader';
import { defaults } from './defaults.js';

export default class PdfGenerator extends LightningElement {

    jsPdfInitialized = false;
    logo;
    currentX;

    @api format = defaults.format;
    @api orientation = defaults.orientation;
    @api unit = defaults.unit;
    @api marginTop = defaults.margin.top;
    @api marginBottom = defaults.margin.bottom;
    @api marginLeft = defaults.margin.left;
    @api marginRight = defaults.margin.right;
    @api showHeader = defaults.showHeader;
    @api showFooter = defaults.showFooter;
    @api showLogo = defaults.showLogo;
    @api showPageNumber = defaults.showPageNumber;
    @api showDate = defaults.showDate;
    @api title = defaults.title;
    @api fileName = defaults.filename;
    @api subtitle = defaults.subtitle;
    @api output = 'string'; // "string", "document" or "blob"
    @api jsonData;

    height;
    width;
    currentPage = 1;
    styles = defaults.styles;
    tableStyles = defaults.styles.table;
    valuesStyles = defaults.styles.values;
    values2Styles = defaults.styles.values2;
    doc;
    now =  new Date();

    renderedCallback() {
        if (this.jsPdfInitialized) {
            return;
        }
        this.jsPdfInitialized = true;
        Promise.all([
            loadScript(this, jsPdfLib + '/jsPDF.js').then(() => {
                return loadScript(this, jsPdfLib + '/jsPDF_AutoTable.js');
            }).catch((e) => {
                console.error('ERROR loading jsPDF library. ' + e);
            })
        ]);
    }

    get formatString(){
        return this.format.join(' ');
    }

    @api
    generatePDF() {

        // get doc properties from data
        this.format = this.jsonData.format || this.format;
        this.orientation = this.jsonData.orientation || this.orientation;
        this.unit = this.jsonData.unit || this.unit;
        this.marginTop = this.jsonData.margin.top || this.marginTop;
        this.marginBottom = this.jsonData.margin.bottom || this.marginBottom;
        this.marginLeft = this.jsonData.margin.left || this.marginLeft;
        this.marginRight = this.jsonData.margin.right || this.marginRight;
        this.title = this.jsonData.title || this.title;
        this.showHeader = this.jsonData.showHeader || this.showHeader;
        this.showFooter = this.jsonData.showFooter || this.showFooter;
        this.showPageNumber = this.jsonData.showPageNumber || this.showPageNumber;
        this.currentX = this.marginLeft;

        // merge and override default styles with custom styles
        if (this.jsonData.hasOwnProperty('styles')) {
            Object.keys(this.styles).forEach( style => {
                style = Object.assign(this.styles[style], this.jsonData.styles[style] ? this.jsonData.styles[style] : {});
            });
        }

        const { jsPDF } = window.jspdf;
        this.doc = new jsPDF({
            unit: this.unit,
            format: this.format,
            orientation: this.orientation
        });

        this.height = this.doc.internal.pageSize.height;
        this.width = this.doc.internal.pageSize.width;

        return this.createPDF();
    }

    async createPDF() {
        try {
            let pageHeight = this.doc.internal.pageSize.height;
            let startY = this.marginTop;
            const clonedData = JSON.parse(JSON.stringify(this.jsonData));
            const chartPromises = [];

            clonedData.components.forEach((component) => {
                component.content.forEach(element => {

                    // Set style for each element
                    this.setStyle(element.type, element.style || {});

                    // Make sure the element has a margin object
                    if (element.margin) {
                        element.margin = { top: element.margin.top || 0, left: element.margin.left || 0, right: element.margin.right || 0, bottom: element.margin.bottom || 0 };
                    } else {
                        element.margin = { top: 0, left: 0, right: 0, bottom: 0 };
                    }

                    console.log('adding element type: ', element.type, ' page: ', this.doc.internal.getCurrentPageInfo().pageNumber, ' startY: ', startY, ' marginTop: ' + element.margin.top, ' marginBottom: ' + element.margin.bottom);

                    if (element.type ==='title') {
                        startY = this.addTitle(element, startY);
                        return;
                    }

                    if (element.type === 'table') {
                        startY = this.addTable(element, startY);
                        return;
                    }

                    if (element.type === 'values') {
                        startY = this.addValues(element, startY);
                        return;
                    }

                    if (element.type === 'values2') {
                        startY = this.addValues2(element, startY);
                        return;
                    }

                    if (element.type === 'text') {
                        startY = this.addText(element, startY);
                        return;
                    }

                    if(element.type === 'pageBreak'){
                        startY = this.addPageBreak(element, startY);
                        return;
                    }

                    if(element.type === 'lineBreak'){
                        if (startY + 30 > pageHeight) {
                            startY = this.addNewPage()
                        }
                        // pass the element so addLineBreak can use element.margin / element.text
                        startY = this.addLineBreak(element, startY);
                        return;
                    }

                    if (element.type === 'image') {
                        startY = this.addImage(element, startY);
                        return
                    }

                    if (element.type === 'chart') {
                        startY = this.addChart(element, startY, chartPromises);
                        return;
                    }

                    if(element.type ===  'circle') {
                        startY = this.draw(startY, element);
                        return;
                    }

                    if(element.type ===  'rect') {
                        startY = this.draw(startY, element);
                        return;
                    }

                    if(element.type ===  'line') {
                        startY = this.draw(startY, element);
                        return;
                    }

                });
            });

            await Promise.all(chartPromises);
            this.jsonData = clonedData;
            //Add header and footer
            this.addHeaderAndFooter();

            //return PDF
            switch (this.output) {
                case 'document':
                    this.doc.save(this.fileName);
                    break;
                case 'blob':
                    return this.doc.output("blob");
                default:
                    return this.doc.output("datauristring");
            }

        } catch(error) { alert("Error when creating PDF" + error);}
    }

    setStyle(type, customStyle) {
        let style = JSON.parse(JSON.stringify(this.styles[type] || {}));
        Object.assign(style, customStyle ? customStyle : {});
        switch (type) {
            case 'headerTitle':
            case 'title':
            case 'header':
            case 'footer':
            case 'pageNumber':
            case 'date':
            case 'subtitle':
            case 'text':
                this.doc.setFont(style.font, style.fontStyle || 'normal', style.fontWeight || 'normal');
                this.doc.setFontSize(style.fontSize);
                this.doc.setTextColor(style.textColor);
                break;
            case 'circle':
            case 'rect':
            case 'line':
                this.doc.setDrawColor(style.drawColor);
                this.doc.setFillColor(style.fillColor);
                this.doc.setLineWidth(style.lineWidth);
                break;
            case 'table':
                this.tableStyles = style;
                break;
            case 'values':
                this.valuesStyles = style;
                break;
            case 'values2':
                this.values2Styles = style;
                break;
            default:
                break;
        }
    }

    addTitle (element, startY) {

        const textSize = this.doc.getTextDimensions(element.text);

        if (element.align === 'center') {
            this.currentX = this.marginLeft + (this.width - this.marginLeft - this.marginRight) / 2 - textSize.w / 2;
        }
        if (element.align === 'right') {
            this.currentX = this.width - this.marginRight - textSize.w;
        }
        let posX = this.currentX + element.margin.left;
        let posY = startY + textSize.h + element.margin.top;

        if (posY >= this.height - this.marginBottom) {
            posY = this.addNewPage() + textSize.h;
        }

        this.doc.text(element.text, posX, posY);

        this.calculateCurrentX(textSize.w + element.margin.left + element.margin.right, element.style?.nobreak);
        return element.style?.nobreak ? posY :  posY- textSize.h + (textSize.h * this.doc.getLineHeightFactor()) + element.margin.bottom;
    }

    addText (element, startY) {

        const textWidth = this.width - this.marginLeft - this.marginRight - element.margin.left - element.margin.right;
        const lines = this.doc.splitTextToSize(element.text, textWidth);
        const lineHeight = this.getTextDimensions().h * this.doc.getLineHeightFactor();

        let posX = this.marginLeft + element.margin.left;
        let posY = startY + lineHeight + element.margin.top;

        lines.forEach( line => {
            this.doc.text(line, posX, posY);
            posY += lineHeight;
            if (posY >= this.height - this.marginBottom) {
                posY = this.addNewPage();
                this.setStyle('text', element.style || {});
            }
        });
        return posY + element.margin.bottom;
    }

    addTable(element, startY) {
        try {
            let headStyles = JSON.parse(JSON.stringify(defaults.styles.headStyles));
            Object.assign(headStyles, element.headStyles || {});

            let bodyStyles = JSON.parse(JSON.stringify(defaults.styles.bodyStyles));
            Object.assign(bodyStyles, element.bodyStyles || {});

            let columnStyles = element.columnStyles || {};

            // TRACKER: Initialize the max height tracker
            this.lastMaxY = 0;

            this.doc.autoTable({
                startY: startY + element.margin.top,
                head: element.head,
                body: element.body,
                theme: this.tableStyles.theme,
                pageBreak: this.tableStyles.pageBreak,
                rowPageBreak: this.tableStyles.rowPageBreak,
                tableWidth: this.tableStyles.tableWidth,
                showHead: this.tableStyles.showHead,
                showFoot: this.tableStyles.showFoot,
                tableLineWidth: this.tableStyles.tableLineWidth,
                tableLineColor: this.tableStyles.tableLineColor,
                styles: this.tableStyles,
                columnStyles: columnStyles,
                headStyles: headStyles,
                bodyStyles: bodyStyles,
                margin:{
                    top: this.marginTop,
                    bottom: this.marginBottom,
                    left: this.marginLeft + element.margin.left,
                    right: this.marginRight + element.margin.right
                },

                didDrawCell: (data) => {
                    if (data.cell.raw?.type === 'custom') {

                        const { x, y, width, height } = data.cell;
                        const paddingLeft = data.cell.styles.cellPadding.left || 0;
                        const paddingRight = data.cell.styles.cellPadding.right || 0;
                        const paddingTop = data.cell.styles.cellPadding.top || 0;
                        const paddingBottom = data.cell.styles.cellPadding.bottom || 0;

                        let posX = x + paddingLeft;
                        let posY = y + (height - paddingTop - paddingBottom);
                        let contentWidth = 0;

                        data.cell.raw.custom.forEach( (cellraw) => {
                            posX += cellraw.margin?.left || 0;
                            switch (cellraw.content.type) {
                                case 'circle':
                                    this.setStyle('circle', cellraw.styles);
                                    posY = this.draw(posY + (cellraw.margin?.top || 0), {type: 'circle', x: posX + cellraw.content.radius, y: posY - cellraw.content.radius, radius: cellraw.content.radius});
                                    posX += cellraw.content.radius * 2 + (cellraw.content.margin?.right || 0);
                                    break;
                                case 'rect':
                                    this.setStyle('rect', cellraw.styles);
                                    posY = this.draw(posY + (cellraw.margin?.top || 0), {type: 'rect', x: posX, y: posY - cellraw.content.width, width: cellraw.content.width, height: cellraw.content.height})
                                    posX += cellraw.content.width + (cellraw.content.margin?.right || 0);
                                    break;
                                case 'tableCustom':
                                    this.setStyle('table', cellraw.styles || {});

                                    // FIX 1: Calculate exact width to prevent squashing/overlap
                                    // Subtract padding (4) from the parent cell width
                                    let safeWidth = (width - paddingLeft - paddingRight - 4);

                                    this.doc.autoTable({
                                        startY: posY,
                                        margin: { left: posX },

                                        // FIX 2: Apply the safe width
                                        tableWidth: safeWidth,

                                        head: cellraw.content.head,
                                        body: cellraw.content.body,
                                        columns: cellraw.content.columns, // Use columns passed from Apex

                                        theme: cellraw.content.theme || this.tableStyles.theme,
                                        styles: cellraw.content.styles || this.tableStyles,
                                        headStyles: cellraw.content.headStyles || {},
                                        bodyStyles: cellraw.content.bodyStyles || {},
                                        columnStyles: cellraw.content.columnStyles || {},
                                        pageBreak: 'auto'
                                    });

                                    // Update cursor to end of table
                                    posY = this.doc.lastAutoTable.finalY;

                                    // FIX 3: Update tracker if this inner table went lower than others
                                    if (posY > this.lastMaxY) {
                                        this.lastMaxY = posY;
                                    }
                                    break;


                                default:
                                    this.doc.setFont(cellraw.styles?.font || this.tableStyles.font, cellraw?.fontStyle || 'normal', cellraw?.fontWeight || 'normal');
                                    this.doc.setFontSize(cellraw.styles?.fontSize || this.tableStyles.fontSize);
                                    this.doc.setTextColor(cellraw.styles?.textColor || this.tableStyles.textColor);
                                    this.doc.text(cellraw.content, posX, posY + (cellraw.margin?.top || 0));
                                    posX += this.doc.getTextWidth(cellraw.content) + (cellraw.content.margin?.right || 0);
                                    break;
                            }

                            // Check max height again after bottom margin
                            // (Simulating the margin addition from original code logic conceptually,
                            // though original code logic didn't explicitly add margin to posY here for tracking)
                            let currentBottomY = posY + (cellraw.margin?.bottom || 0);
                            if (currentBottomY > this.lastMaxY) {
                                this.lastMaxY = currentBottomY;
                            }
                        });
                    }
                }
            });

            // FIX 4: Determine the true bottom of the section
            // Compare the invisible master table's bottom vs. the deepest nested table
            let masterTableY = this.doc.lastAutoTable.finalY;
            let finalReturnY = this.lastMaxY > masterTableY ? this.lastMaxY : masterTableY;

            return finalReturnY + element.margin.bottom;
        } catch (error) {
            console.error('Error while creating table: ', error);
       }
    }

    addValues2(element, startY) {
        const marginLeft = this.marginLeft + (element.margin?.left || 0);
        const marginRight = this.marginRight + (element.margin?.right || 0);
        const marginTop = this.marginTop + (element.margin?.top || 0);
        const marginBottom = this.marginBottom + (element.margin?.bottom || 0);

        const columnsCount = element.body.length;
        const rowsCount = Math.max(...element.body.map(col => col.length));
        const pageHeight = this.height - this.marginTop - this.marginBottom;
        const pageWidth = this.width - marginLeft - marginRight;
        const colSpacing = 3;
        const rowSpacing = 2;
        const colWidth = (pageWidth - (columnsCount - 1) * colSpacing) / columnsCount;

        let y = startY + element.margin.top;
        this.doc.setTextColor(this.values2Styles.textColor);

        const rowHeights = [];
        for (let rowIdx = 0; rowIdx < rowsCount; rowIdx++) {
            let maxHeight = 0;
            for (let colIdx = 0; colIdx < columnsCount; colIdx++) {
                const cell = element.body[colIdx][rowIdx];
                if (cell) {
                    // Name (bold)
                    this.doc.setFont(this.values2Styles.font || 'helvetica', 'bold');
                    this.doc.setFontSize(element.style?.fontSize - 1 || this.values2Styles.fontSize - 1 || 10);
                    const nameLines = this.doc.splitTextToSize(cell.name, colWidth);
                    // Value (normal)
                    this.doc.setFont(this.values2Styles.font || 'helvetica', 'normal');
                    this.doc.setFontSize(element.style?.fontSize || this.values2Styles.fontSize || 11);
                    const valueLines = this.doc.splitTextToSize(cell.value, colWidth);
                    const height = (nameLines.length + valueLines.length) * this.getTextDimensions('A').h * this.doc.getLineHeightFactor() + 3;
                    if (height > maxHeight) maxHeight = height;
                }
            }
            rowHeights[rowIdx] = maxHeight || 12;
        }

        for (let rowIdx = 0; rowIdx < rowsCount; rowIdx++) {
            if (y + rowHeights[rowIdx] + rowSpacing + marginBottom > this.height - this.marginBottom) {
                this.doc.addPage();
                y = this.marginTop;
            }
            let x = marginLeft;
            for (let colIdx = 0; colIdx < columnsCount; colIdx++) {
                const cell = element.body[colIdx][rowIdx];
                const cellHeight = rowHeights[rowIdx];
                if (cell) {
                    let cellY = y + 2;
                    // Name (bold)
                    this.doc.setFont(this.values2Styles.font || 'helvetica', 'bold');
                    this.doc.setFontSize(element.style?.fontSize - 1 || this.values2Styles.fontSize - 1 || 10);
                    const nameLines = this.doc.splitTextToSize(cell.name, colWidth);
                    nameLines.forEach(line => {
                        this.doc.text(line, x, cellY, { align: 'left', baseline: 'top' });
                        cellY += this.getTextDimensions(line).h * this.doc.getLineHeightFactor();
                    });
                    // Value (normal)
                    this.doc.setFont(this.values2Styles.font || 'helvetica', 'normal');
                    this.doc.setFontSize(element.style?.fontSize || this.values2Styles.fontSize || 11);
                    const valueLines = this.doc.splitTextToSize(cell.value, colWidth);
                    valueLines.forEach(line => {
                        if (cellY > this.height - this.marginBottom) {
                            this.doc.addPage();
                            y = this.marginTop;
                            cellY = y + 2;
                            this.doc.setFont(this.values2Styles.font || 'helvetica', 'bold');
                            this.doc.setFontSize(element.style?.fontSize - 1 || this.values2Styles.fontSize - 1 || 10);
                            nameLines.forEach(line2 => {
                                this.doc.text(line2, x, cellY, { align: 'left', baseline: 'top' });
                                cellY += this.getTextDimensions(line2).h * this.doc.getLineHeightFactor();
                            });
                            this.doc.setFont(this.values2Styles.font || 'helvetica', 'normal');
                            this.doc.setFontSize(element.style?.fontSize || this.values2Styles.fontSize || 11);
                        }
                        this.doc.text(line, x, cellY, { align: 'left', baseline: 'top' });
                        cellY += this.getTextDimensions(line).h * this.doc.getLineHeightFactor();
                    });
                }
                this.doc.setDrawColor(this.values2Styles.tableLineColor);
                this.doc.setLineWidth(this.values2Styles.tableLineWidth);
                this.doc.line(
                    x, y + rowHeights[rowIdx],
                    x + colWidth, y + rowHeights[rowIdx]
                );
                x += colWidth + colSpacing;
            }
            y += rowHeights[rowIdx] + rowSpacing;
        }

        return y + element.margin.bottom;
    }

    addValues(element, startY) {
        const nestedTableCell = {
            content: '',
            styles: { minCellHeight: 0 }
        }

        let lastY = 0;

        this.doc.autoTable({
            head: [new Array(element.body.length).fill('')],
            body: [[nestedTableCell]],
            foot: [new Array(element.body.length).fill('')],
            startY: startY,
            theme: 'plain',
            showHead: 'never',
            showFoot: 'never',
            cellPadding: { top: 0, right: 0, bottom: 0, left: 0 },
            tableLineWidth: 0,
            tableLineColor: 0,
            margin: {
                top: this.marginTop,
                bottom: this.marginBottom,
                left: this.marginLeft + element.margin.left,
                right: this.marginRight + element.margin.right
            },
            didDrawCell: (data) => {
                if (data.row.index === 0 && data.row.section === 'body') {
                    this.doc.autoTable({

                        startY: data.cell.y,
                        margin: {
                             top: this.marginTop,
                             bottom: this.marginBottom,
                             left: data.cell.x
                        },
                        tableWidth: data.cell.width - 2,

                        theme: this.valuesStyles.theme,
                        pageBreak: this.valuesStyles.pageBreak,
                        rowPageBreak: this.valuesStyles.rowPageBreak,
                        showHead: this.valuesStyles.showHead,
                        showFoot: this.valuesStyles.showFoot,
                        tableLineWidth: this.valuesStyles.tableLineWidth,
                        tableLineColor: this.valuesStyles.tableLineColor,
                        styles: this.valuesStyles,

                        columnStyles: { name: { halign: 'left', fontStyle: 'bold'}, value: { halign: 'right' } },
                        columns: [
                            { dataKey: 'name', header: 'Name' },
                            { dataKey: 'value', header: 'Value' },
                        ],
                        body: element.body[data.column.index]
                    });
                    lastY = this.doc.lastAutoTable.finalY;
                }
            }
        });
        return lastY + element.margin.bottom;
    }

    addImage(element, startY) {

        const factor = element.aspectRatio || 1/3;
        const posX = element.x ? this.parseValues(element.x) : this.currentX + element.margin.left;
        const posY = element.y ? this.parseValues(element.y) : startY + element.margin.top;
        const width = this.parseValues(element.width);
        const height = element.height ? this.parseValues(element.height) : width * factor;
        const format = element.format || 'PNG';
        const alias = `${element.name}${Date.now()}`;

        if (!element.y && posY + height > this.height - this.marginBottom) {
            startY = this.addNewPage()
        }
        if (!element.x) {
            this.calculateCurrentX(width, element.style?.nobreak);
        }
        if (!element.y) {
            startY = posY + height + element.margin.bottom;
        }
        this.doc.addImage(element.src, format, posX, posY, width, height, alias, 'FAST');
        return startY;

    }

    addChart(element, startY, chartPromises) {

        const factor = element.aspectRatio || 1/3;
        let posY = element.y ? this.parseValues(element.y) : startY + element.margin.top;
        const posX = element.x ? this.parseValues(element.x) : this.currentX + element.margin.left;
        const width = this.parseValues(element.width);
        const height = width * factor;

        if (!element.y && posY + height > this.height - this.marginBottom) {
            startY = this.addNewPage();
            posY = startY;
        }
        if (!element.x) {
            this.calculateCurrentX(width, element.style?.nobreak);
        }
        if (!element.y) {
            startY = posY + height + element.margin.bottom;
        }

        const chartPage = this.doc.internal.getCurrentPageInfo().pageNumber;
        const chart = this.template.querySelector('c-' + element.chartType);
        const promise = chart.getChartImage(width, width * factor, JSON.parse(JSON.stringify(element.params))).then( imgBase64 => {
            const currentPage = this.doc.internal.getCurrentPageInfo().pageNumber;
            const alias = `${element.chartType}_${Date.now()}`;
            const format = element.format || 'PNG';
            this.doc.setPage(chartPage);
            console.log('Chart image ', alias, ': ', imgBase64);
            this.doc.addImage(imgBase64, format, posX, posY, width, height, alias, 'FAST');
            this.doc.setPage(currentPage);
        });
        chartPromises.push(promise);

        return startY;
    }

    draw(startY, element) {
        let width = 0;
        let posX = 0;
        let posY = 0;
        let elementWidth = 0;
        let elementHeight = 0;

        element.margin = { top: element.margin?.top || 0, left: element.margin?.left || 0, right: element.margin?.right || 0, bottom: element.margin?.bottom || 0 };

        switch(element.type) {
            case 'circle':
                posX = element.x ? this.parseValues(element.x) : this.currentX + element.radius + element.margin.left;
                posY = element.y ? this.parseValues(element.y) : startY + element.margin.top;
                elementWidth = this.parseValues(element.radius);
                this.doc.circle(posX, posY, elementWidth, 'FD');
                if(!element.y && !element.style?.nobreak) {
                    startY += element.margin.top + elementWidth + element.margin.bottom;
                }
                width = element.margin.left + elementWidth*2 + element.margin.right;
                break;

            case 'rect':
                posX = element.x ? this.parseValues(element.x) : this.currentX + element.margin.left;
                posY = element.y ? this.parseValues(element.y) : startY + element.margin.top;
                elementWidth = this.parseValues(element.width);
                elementHeight = this.parseValues(element.height);
                this.doc.rect(posX, posY, elementWidth, elementHeight, 'FD');
                if(!element.y && !element.style?.nobreak) {
                    startY += (element.margin.top + elementHeight + element.margin.bottom);
                }
                width = element.margin.left + elementWidth + element.margin.right;
                break;

            case 'line':
                const lineWidth = element.style?.lineWidth || this.styles.line.lineWidth;
                posX = element.x ? this.parseValues(element.x) : this.currentX + element.margin.left;
                posY = element.y ? this.parseValues(element.y) : startY + (lineWidth/2) + element.margin.top;
                const endX = element.endX ? this.parseValues(element.endX) : posX + this.width - this.currentX - element.margin.left - element.margin.right - this.marginRight
                const endY = element.endY ? this.parseValues(element.endY) : posY;
                this.doc.setLineWidth(lineWidth);
                this.doc.line(posX, posY, endX, endY);
                if(!element.style?.nobreak) {
                    startY += lineWidth + element.margin.bottom;
                }
                width = endX - posX;
                break;

            default:
                console.error('Unknown element type: ', element.type);
            break;
        }
        if (!element.x) {
            this.calculateCurrentX(width, element.style?.nobreak);
        }
        return startY;
    }

    addPageBreak(element, startY) {
        if (element.threshold) {
            if (this.height - this.marginBottom - element.threshold <= startY) {
                startY = this.addNewPage();
            }
        } else {
            startY = this.addNewPage()
        }
        return startY;
    }

    addNewPage() {
        this.currentPage++;
        this.doc.addPage();
        return this.marginTop;
    }

    calculateCurrentX(width, nobreak) {
        if (nobreak) {
            const maxWidth = (this.width - this.marginLeft - this.marginRight);
            this.currentX = (this.currentX + width) - Math.floor((width + this.currentX) / maxWidth) * maxWidth;
        } else {
            this.currentX = this.marginLeft;
        }
    }

    addHeaderAndFooter() {

        let pagesTotal = this.doc.internal.getNumberOfPages();
        let logoWidth, logoHeight, logoX, logoY, logoSrc, img;

        if (this.showHeader && this.showLogo) {
            try {
                logoWidth = this.jsonData.logo?.width || defaults.logo.width;
                logoHeight = this.jsonData.logo?.height || defaults.logo.height;
                logoX = this.jsonData.logo?.x || defaults.logo.x;
                logoY = this.jsonData.logo?.y || defaults.logo.y;
                logoSrc = this.jsonData.logo ? '/resources/' + this.jsonData.logo.src : jsPdfLib + '/logo.png';
                img = new Image();
                img.src = logoSrc;
                img.decode();
            } catch (e) {
               console.error("Error while loading logo:", e);
            }
        }

        for(let i = 1; i <= pagesTotal; i++) {
            this.doc.setPage(i);

            //header
            if (this.showHeader) {
                if (this.showLogo) {
                    this.doc.addImage(img, 'PNG', logoX, logoY, logoWidth, logoHeight, 'logo', 'FAST');
                }
                this.addHeader();
            }

            //footer
            if (this.showFooter) {
                if (this.showPageNumber) {
                    this.addNumberPage(i, pagesTotal);
                }
            }
        }
    }

    addHeader() {
        // title
        if (this.title) {
            this.setStyle('headerTitle');
            this.doc.text(this.title, this.width - this.marginRight - 2, 14 + 4, { align: 'right' });
        }

        // date
        if (this.showDate) {
            this.setStyle('date');
            let dateHeader = Intl.DateTimeFormat(this.styles.dateFormat.locale, this.styles.dateFormat.options).format(this.now);
            this.doc.text(dateHeader, this.width - this.marginRight - 2, 20 + 3, { align: 'right' });
        }
    }

    addNumberPage(page, pagesTotal) {
        this.setStyle('pageNumber');
        this.doc.text(`Page ${page} of ${pagesTotal}`, this.width - this.marginRight, this.height - (this.marginBottom/2 + 5), { align: 'right' });
    }

    parseValues(value) {
        if (typeof value === 'string') {
            value = value.replace(/center/g, this.marginLeft + (this.width - this.marginLeft - this.marginRight) / 2);
            value = value.replace(/centerV/g, this.marginTop + (this.height - this.marginTop - this.marginBottom) / 2);
            value = value.replace(/height/g, this.height);
            value = value.replace(/width/g, this.width);
            value = value.replace(/top/g, this.marginTop);
            value = value.replace(/bottom/g, this.height - this.marginBottom);
            value = value.replace(/left/g, this.marginLeft);
            value = value.replace(/right/g, this.width - this.marginRight);
            value = value.replace(/content/g, this.width - this.marginRight - this.marginLeft);
            value = value.replace(/contentV/g, this.height - this.marginTop - this.marginBottom);
            value = value.replace(/currentX/g, this.currentX);
            //value = value.replace(/currentY/g, this.startY);
            value = value.replace(/[^0-9.\-\/\*\+\(\)]+/g, '');
            return eval(value);
        } else {
            return value;
        }
    }

    getTextDimensions(text) {
        if (!text) {
            text = 'ABCO1234567890abcdfg';
        }
        return this.doc.getTextDimensions(text);
    }

    addLineBreak(textOrElement, startY) {
        // support either passing the element object or a plain string
        let text = ' ';
        let marginTop = 0, marginLeft = 0, marginBottom = 0;

        if (typeof textOrElement === 'string') {
            text = textOrElement;
        } else if (textOrElement && typeof textOrElement === 'object') {
            text = textOrElement.text || ' ';
            marginTop = textOrElement.margin?.top || 0;
            marginLeft = textOrElement.margin?.left || 0;
            marginBottom = textOrElement.margin?.bottom || 0;
        }

        const lineHeight = this.getTextDimensions(text).h * this.doc.getLineHeightFactor();
        let posX = this.marginLeft + marginLeft;
        let posY = startY + marginTop + lineHeight;

        if (posY >= this.height - this.marginBottom) {
            // addNewPage returns the new startY (this.marginTop)
            posY = this.addNewPage();
        }

        // only print text when it's meaningful; otherwise just reserve space
        if (text && String(text).trim()) {
            this.doc.text(text, posX, posY);
        }

        // return next startY (leave space for marginBottom)
        return posY + marginBottom;
    }

}