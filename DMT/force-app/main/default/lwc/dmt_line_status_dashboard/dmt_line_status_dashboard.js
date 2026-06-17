import { LightningElement, track } from 'lwc';
import chartJs from '@salesforce/resourceUrl/HPG_ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';
import getFilterOptions from '@salesforce/apex/DMT_LineStatusDashboard.getFilterOptions';
import getDashboardData from '@salesforce/apex/DMT_LineStatusDashboard.getDashboardData';

export default class Dmt_line_status_dashboard extends LightningElement {
    @track filters = {
        startDate: null,
        endDate: null,
        lineTemplate: '',
        bookingGeography: ''
    };

    @track dashboard;
    @track error;
    @track isLoading = false;

    chart;
    chartJsLoaded = false;

    lineTemplateOptions = [{ label: 'All', value: '' }];
    bookingGeographyOptions = [{ label: 'All', value: '' }];

    columns = [
        { label: 'State', fieldName: 'state', type: 'text' },
        { label: 'Total Hours', fieldName: 'totalHours', type: 'number' },
        { label: 'Avg Hours', fieldName: 'avgHours', type: 'number' },
        { label: 'Record Count', fieldName: 'recordCount', type: 'number' }
    ];

    connectedCallback() {
        this.initialize();
    }

    async initialize() {
        this.isLoading = true;
        this.error = null;

        try {
            await this.loadChartJs();
            await this.loadFilterOptions();
            await this.loadDashboard();
        } catch (e) {
            this.handleError(e);
        } finally {
            this.isLoading = false;
        }
    }

    async loadChartJs() {
        if (this.chartJsLoaded) {
            return;
        }

        await loadScript(this, chartJs);
        this.chartJsLoaded = true;
    }

    async loadFilterOptions() {
        const data = await getFilterOptions();

        this.lineTemplateOptions = [
            { label: 'All', value: '' },
            ...(data.lineTemplates || []).map(v => ({ label: v, value: v }))
        ];

        this.bookingGeographyOptions = [
            { label: 'All', value: '' },
            ...(data.bookingGeographies || []).map(v => ({ label: v, value: v }))
        ];
    }

    async loadDashboard() {
        this.isLoading = true;
        this.error = null;

        try {
            const data = await getDashboardData({ filters: this.filters });
            this.dashboard = data;
            this.renderChart();
        } catch (e) {
            this.handleError(e);
        } finally {
            this.isLoading = false;
        }
    }

    renderChart() {
        if (!this.chartJsLoaded || !this.dashboard) {
            return;
        }

        const canvas = this.template.querySelector('canvas.statusChart');
        if (!canvas) {
            return;
        }

        const ctx = canvas.getContext('2d');

        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: this.dashboard.labels,
                datasets: [
                    {
                        label: 'Avg Hours per State',
                        data: this.dashboard.avgHoursPerState
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    }

    handleStartDateChange(event) {
        this.filters = { ...this.filters, startDate: event.target.value };
    }

    handleEndDateChange(event) {
        this.filters = { ...this.filters, endDate: event.target.value };
    }

    handleLineTemplateChange(event) {
        this.filters = { ...this.filters, lineTemplate: event.detail.value };
    }

    handleBookingGeographyChange(event) {
        this.filters = { ...this.filters, bookingGeography: event.detail.value };
    }

    handleReset() {
        this.filters = {
            startDate: null,
            endDate: null,
            lineTemplate: '',
            bookingGeography: ''
        };
        this.loadDashboard();
    }

    handleError(e) {
        this.error = e?.body?.message || e?.message || 'Unknown error';
        // eslint-disable-next-line no-console
        console.error(e);
    }
}