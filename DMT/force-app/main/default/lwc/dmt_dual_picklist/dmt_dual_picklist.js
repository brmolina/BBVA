import { LightningElement, api } from 'lwc';
export default class dmt_dual_picklist extends LightningElement {
    @api options = [
    { value: 'Confirming financiación de proveedores / Confirmin Confirming financiación de proveedores / Confirmin', label: 'Confirming financiación de proveedores / Confirmin Confirming financiación de proveedores / Confirmin' },
    { value: 'Préstamos no Hipotecarios / Non Mortgage Loans', label: 'Préstamos no Hipotecarios / Non Mortgage Loans' },
    { value: 'Líneas de Prestamos No Hipotecarios / Non Mortage', label: 'Líneas de Prestamos No Hipotecarios / Non Mortage' },
    { value: 'Corporate Lending', label: 'Corporate Lending' },
    { value: 'Issuer Risk', label: 'Issuer Risk' },
    { value: 'Issuer Risk3', label: 'Issuer Risk3' }
];
    @api values = ['Corporate Lending', 'Issuer Risk', 'Confirming financiación de proveedores / Confirmin Confirming financiación de proveedores / Confirmin'
    ,'Préstamos no Hipotecarios / Non Mortgage Loans','Líneas de Prestamos No Hipotecarios / Non Mortage','Issuer Risk3'];
    @api requiredOptions = ['Issuer Risk'];

    connectedCallback() {
    }
}