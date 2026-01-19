/*
* Chart utils
*/

var format = function(num) {
	return Math.round(num * 100) / 100;
}

var fullCurrency = function(value, currencyId) {
	return format(value).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + ' ' + currencyId;
}

var formatCurrencyLabel = function(value, currencyId) {
    if (value >= 1e12) {
        return (format(value/1e12)).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + 'B ' + currencyId;
      } else if(value >= 1e6) {
        return (format(value/1e6)).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + 'M ' + currencyId;
      } else if(value >= 1e3) {
        return (format(value/1e3)).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + 'M ' + currencyId;
      } else if(value == 0) {
        return (value).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
      } else {
        return fullCurrency(value, currencyId);
      }
}

export var sortedIds = ['90000', '80000', '80100', '80200', '70000', '50000', '10000', '10200', '10100', '20000', '20200', '20100', '30000', '40000', 'under', '130000', '140000', '60000', '888888', '999999', '200000', 'XXXXXX', '100100', '100200', '110000', '120000', '150000'];

export var chartColour = {
    'authorizedRiskAmount': 'rgba(45, 204, 205, 1)',
    'authorizedRiskAmount_hover': 'rgba(45, 204, 205, 1)',
    'cNotSignedTrConsumptionAmount': 'rgba(235, 235, 235, 1)',
    'cNotSignedTrConsumptionAmount_hover': 'rgba(235, 235, 235, 1)',
    'committedContractsDisposedAmount': 'rgba(25, 115, 184, 1)',
    'committedContractsDisposedAmount_hover': 'rgba(23, 110, 186, 1)',
    'committedContractsNonDisposedAmount': 'rgba(20, 100, 165, 1)',
    'committedContractsNonDisposedAmount_hover': 'rgba(20, 100, 165, 1)',
    'unavailableRiskAmount': 'rgba(2, 132, 132, 1)',
    'unavailableRiskAmount_hover': 'rgba(10, 123, 123, 1)',
    'uncommittedContractsDisposedAmount': 'rgba(90, 196, 196, 1)',
    'uncommittedContractsDisposedAmount_hover': 'rgba(66, 219, 219, 1)',
    'uncommittedContractsNonDisposedAmount':'rgba(36, 150, 234, 1)',
    'uncommittedContractsNonDisposedAmount_hover': 'rgba(36, 150, 234, 1)',
    'sumDisposedAmount': 'rgba(4, 50, 99, 1)',
    'sumDisposedAmount_hover': 'rgba(4, 50, 99, 1)',
    'limit': 'rgba(200, 0, 0, 1)',
    'limitborder': 'rgba(50, 0, 0, 1)',
    'totalbkg': 'rgba(255, 255, 255, .50)',
    'totalborder': 'rgba(255, 255, 255, .90)'
};

export function formatCurrency(value) {
    let currencyId = this.chart.data.currency;
    return formatCurrencyLabel(value, currencyId);
};

export function drawTargets() {
    var chartInstance = this.chart;
    var ctx = chartInstance.ctx;
    var xaxis = chartInstance.scales['xBar'];
    var nDatasets = this.data.datasets.length;
    var targets = this.data.targets;
    var currencyId = this.data.currency;
    var targetColor = chartColour.limit;

    ctx.textAlign = "left";
    ctx.font = "13px sans-serif";
    ctx.fillStyle = "#fff";

    window.Chart.helpers.each(this.data.datasets.forEach(function (dataset, i) {
        var meta = chartInstance.controller.getDatasetMeta(i);
        var posX = 0;
        window.Chart.helpers.each(meta.data.forEach(function (bar, index) {
            let posY = bar._model.y;
            let barHeight = bar._model.height;
            if (i === nDatasets - 1) {
                posX = xaxis.getPixelForValue(targets[index]);
                ctx.beginPath();
                ctx.moveTo(posX, posY);
                ctx.lineWidth = 3;
                ctx.moveTo(posX, posY - barHeight/2);
                ctx.strokeStyle = targetColor;
                ctx.lineTo(posX, posY + barHeight/2);
                ctx.fillStyle = chartColour.limit;
                ctx.fillText(formatCurrencyLabel(targets[index], currencyId), posX+6, posY + barHeight/2-6);
                ctx.stroke();
                ctx.draw;
            }
        }),this);
    }),this);
}

export function customTooltip() {
    // Tooltip Element
    var tooltipModel = this._chart.tooltip._model;
    var currency = this._data.currency;
    var exchangeRate = this._data.exchangeRate;
    var values = [];

    this._data.datasets.forEach( dataset => {
        values.push(dataset.data);
    });
    var totals = values.reduce((r, a) => r.map((b, i) => a[i] + b));

    // Create element on first render
    var tooltipEl = document.getElementById('chartjs-tooltip');
    if (!tooltipEl) {
        tooltipEl = document.createElement('div');
        tooltipEl.id = 'chartjs-tooltip';
        tooltipEl.style.cssText = 'background-color: rgba(255, 255, 255, 0.9); border: solid 1px rgba(0, 0, 0, 0.4); border-radius: 4px; z-index: 99999999';
        tooltipEl.innerHTML = '<table></table>';
        document.body.appendChild(tooltipEl);
    }

    // Hide if no tooltip
    if (tooltipModel.opacity === 0) {
        tooltipEl.style.opacity = 0;
        return;
    }

    // Set caret Position
    tooltipEl.classList.remove('above', 'below', 'no-transform');
    if (tooltipModel.yAlign) {
        tooltipEl.classList.add(tooltipModel.yAlign);
    } else {
        tooltipEl.classList.add('no-transform');
    }

    function getBody(bodyItem) {
        return bodyItem.lines;
    }

    function getXLabel(dataPoint) {
        return dataPoint.xLabel;
    }

    // Set Text
    if (tooltipModel.body) {
        var titleLines = tooltipModel.title || [];
        var bodyLines = tooltipModel.body.slice(0, 4).map(getBody);

        // calculate totals and insert into labels array
        var totalAmount = tooltipModel.dataPoints.slice(0, 4).map(getXLabel).reduce((a, b) => a + b, 0);
        var targetAmount = this._data.targets[tooltipModel.dataPoints[0].index] || null;
        var draftAmount = tooltipModel.dataPoints.slice(-1)[0].xLabel;
        var remainingAmount = targetAmount - totalAmount - draftAmount;
        var totalBkg = {backgroundColor: chartColour.totalbkg, borderColor: chartColour.totalborder};
        var limitBkg = {backgroundColor: chartColour.limit, borderColor: chartColour.limitborder};
        var draftBkg = {backgroundColor: chartColour.cNotSignedTrConsumptionAmount, borderColor: chartColour.cNotSignedTrConsumptionAmount};

        var limitEUR = formatCurrencyLabel(targetAmount/exchangeRate, 'EUR');

        bodyLines.splice(bodyLines.length, 0 , ['Total Amount: ' + totalAmount], ['gap: 5'], ['Draft: ' + draftAmount], [(currency !== 'EUR') ? 'Limit [' + limitEUR + ']: ' + targetAmount : 'Limit: ' + targetAmount], [ ((remainingAmount < 0) ? 'Exceeded: ' : 'Remaining: ') + remainingAmount]);
        tooltipModel.labelColors.splice(tooltipModel.labelColors.slice(0, 4).length, 0 , totalBkg, '', draftBkg, limitBkg, totalBkg);

        var innerHtml = '<thead>';

        titleLines.forEach(function(title) {
            innerHtml += '<tr><th style="padding-bottom:5px;">' + title + '</th></tr>';
        });
        innerHtml += '</thead><tbody>';

        bodyLines.forEach(function(body, i) {
            var lbl = body[0].split(': ');
            if (lbl[0] === 'gap') {
                innerHtml += '<tr><td colspan=2 style="padding-bottom:' + lbl[1] + 'px;"></td></tr>'
            } else {
                var colors = tooltipModel.labelColors[i];
                var style = 'background:' + colors.backgroundColor;
                style += '; border-color:' + colors.borderColor;
                style += '; border-width: 2px';
                var span = '<span style="' + style + '">&nbsp;&nbsp&nbsp;&nbsp;</span>&nbsp;&nbsp;';
                innerHtml += '<tr';

                if (lbl[0] === 'Total Amount') {
                    innerHtml +=  ' style="border-top: 1px solid;"';
                }

                innerHtml += '><td>' + span + lbl[0] + ' </td><td style="text-align:right';
                innerHtml += ((lbl[1] < 0) ? ';color:red"' : '"') + '>&nbsp;'+ formatCurrencyLabel(lbl[1], currency) + '</td></tr>';
            }
        });
        innerHtml += '</tbody>';

        var tableRoot = tooltipEl.querySelector('table');
        tableRoot.innerHTML = innerHtml;
    }

    // `this` will be the overall tooltip
    var position = this._chart.canvas.getBoundingClientRect();

    // Display, position, and set styles for font
    tooltipEl.style.opacity = 1;
    tooltipEl.style.position = 'absolute';
    tooltipEl.style.left = position.left + window.pageXOffset + tooltipModel.caretX + 'px';
    tooltipEl.style.top = position.top + window.pageYOffset + tooltipModel.caretY + 'px';
    tooltipEl.style.fontFamily = tooltipModel._bodyFontFamily;
    tooltipEl.style.fontSize = tooltipModel.bodyFontSize + 'px';
    tooltipEl.style.fontStyle = tooltipModel._bodyFontStyle;
    tooltipEl.style.padding = tooltipModel.yPadding + 'px ' + tooltipModel.xPadding + 'px';
    tooltipEl.style.pointerEvents = 'none';
}