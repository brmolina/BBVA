/* chart utils */

// return null value
export function isNull(value) {
    return [null, undefined, "", "null",[]].includes(value);
}

export function formatCurrency(value) {
    let currencyId = this.chart.data.currencyId;
    return formatCurrencyLabel(value, currencyId);
};

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
      } else if(value >= 1e4) {
        return (format(value/1e3)).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + 'K ' + currencyId;
      } else if(value == 0) {
        return (value).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
      } else {
        return fullCurrency(value, currencyId);
      }
}

var DEFAULT_GRAY_TRAFFIC_LIGHT = [
    {colour: 'rgba(163, 163, 163, 1)', pos: 0.0},
    {colour: 'rgba(163, 163, 163, 1)', pos: 0.35},
    {colour: 'rgba(211, 211, 211, 1)', pos: 1.0}
];

var colours = {
    trafficlights: {
        stroke: 'rgba(100, 100, 100, 1)',
        red: [
            {colour: 'rgba(218, 56, 81, 1)', pos: 0.0},
            {colour: 'rgba(218, 56, 81, 1)', pos: 0.35},
            {colour: 'rgba(231, 125, 142, 1)', pos: 1}
        ],
        orange: [
            {colour: 'rgba(248, 205, 81, 1)', pos: 0.0},
            {colour: 'rgba(248, 205, 81, 1)', pos: 0.35},
            {colour: 'rgba(250, 222, 142, 1)', pos: 1.0}
        ],
        yellow: [
            {colour: 'rgba(248, 205, 81, 1)', pos: 0.0},
            {colour: 'rgba(248, 205, 81, 1)', pos: 0.35},
            {colour: 'rgba(250, 222, 142, 1)', pos: 1.0}
        ],
        green: [
            {colour: 'rgba(72, 174, 100, 1)', pos: 0.0},
            {colour: 'rgba(72, 174, 100, 1)', pos: 0.35},
            {colour: 'rgba(136, 202, 154, 1)', pos: 1.0}
        ],
        gray: DEFAULT_GRAY_TRAFFIC_LIGHT
    }
}

export function getWrappedLines(ctx, text, maxWidth) {
    if (!text || maxWidth <= 0) {
        return [];
    }
    const words = String(text).split(' ');
    let line = '';
    const lines = [];

    words.forEach((word) => {
        const testLine = line ? `${line} ${word}` : word;
        const testWidth = ctx.measureText(testLine).width;

        if (testWidth > maxWidth && line) {
            lines.push(line);
            line = word;
        } else {
            line = testLine;
        }
    });

    if (line) {
        lines.push(line);
    }
    return lines;
}

function drawWrappedText(ctx, text, x, y, maxWidth, lineHeight) {
    const lines = getWrappedLines(ctx, text, maxWidth);
    lines.forEach((line, i) => ctx.fillText(line, x, y + (i * lineHeight)));
    return lines.length;
}

// toggle notices in traffic lights
export function toggleNotice(chart, ev)  {

    var offsetX = chart.canvas.getBoundingClientRect().x;
    var offsetY = chart.canvas.getBoundingClientRect().y;

    var posX = 0;
    var posY = 0;
    var show = false;
    var text2Show;
    var tlNotice = document.getElementById('chartjs-tlnotice');

    // Create element on first render
    if (!tlNotice) {
        tlNotice = document.createElement('div');
        tlNotice.id = 'chartjs-tlnotice';
        tlNotice.style.cssText = 'padding:5px;background-color: rgba(255, 255, 255, 0.9); border: solid 1px rgba(0, 0, 0, 0.4); border-radius: 4px; z-index: 99999999';
        tlNotice.style.position = 'absolute';
        tlNotice.innerHTML = '<table></table>';
        document.body.appendChild(tlNotice);
    }

    chart.data.trafficlights.forEach(tl => {

        var tlx = tl.x + offsetX;
        var tly = tl.y + offsetY;

        if (tlx <= ev.x && tlx + tl.width >= ev.x && tly <= ev.y && tly + tl.height > ev.y) {
            show = true;
            posX = tlx + tl.height/2;
            posY = tly + tl.height/2;
            text2Show = tl.label;
        }
    })

    if (show) {
        var innerHtml = '<tr><td style="font-size: 12px;">' + text2Show + '</td></tr>';
        tlNotice.style.opacity = 1;
        tlNotice.style.left = posX + window.scrollX + 'px';
        tlNotice.style.top = posY + window.scrollY + 'px';
        var tableRoot = tlNotice.querySelector('table');
        tableRoot.innerHTML = innerHtml;
    } else {
        tlNotice.style.opacity = 0;
        tlNotice.style.left = '0px';
        tlNotice.style.top = '0px';
    }
}

// tooltip
export function customTooltip() {

    // Tooltip Element
    var tooltipModel = this._chart.tooltip._model;
    var tooltipEl = document.getElementById('chartjs-tooltip');
    var values = [];
    this._data.datasets.forEach( dataset => {
        values.push(dataset.data);
    });

    //var totals = values.reduce((r, a) => r.map((b, i) => a[i] + b));

    // Create element on first render
    if (!tooltipEl) {
        tooltipEl = document.createElement('div');
        tooltipEl.id = 'chartjs-tooltip';
        tooltipEl.style.cssText = 'background-color: rgba(255, 255, 255, 0.9); border: solid 1px rgba(0, 0, 0, 0.4); border-radius: 4px; z-index: 99999998';
        tooltipEl.style.position = 'absolute';
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

    if (tooltipModel.body) {

        var titleLines = tooltipModel.title ?? [];
        var bodyLines = tooltipModel.body.map(getBody);
        var dataPoints = tooltipModel.dataPoints || [];
        var newOpportunity = dataPoints.length >= 5 ? dataPoints[4].xLabel : 0;
        var totalAmount = dataPoints.map(getXLabel).reduce((a, b) => a + b, 0) - newOpportunity;
        var targetAmount = this._data.targets[dataPoints[0].index] ?? null;
        var currency = this._data.currencyId ?? null;
        var originTarget = this._data.currencies[dataPoints[0].index] ?? null;
        var originCurrency = this._data.currencies[dataPoints[0].index] ?? null;
        var remainingAmount = targetAmount - (totalAmount + newOpportunity);
        var totalBkg = {backgroundColor: "rgba(255, 255, 255, 0.9)",borderColor: "rgba(255, 255, 255, 0.9)"};
        var totalBkgLimit = {backgroundColor: "rgba(255, 0, 0, 0.9)",borderColor: "rgba(0, 0, 0, 0.9)"};

        bodyLines.splice(bodyLines.length - 1, 0 , ['Total Amount: ' + totalAmount], ['gap: 8']);
        bodyLines.splice(bodyLines.length , 0 , ['Limit' + ((originCurrency !== currency) ? ' [' + formatCurrencyLabel(targetAmount * (1/this._data.exchangeRate) ,originCurrency) + ']: ' : ': ') + targetAmount ], [((remainingAmount < 0) ? 'Exceeded: ' : 'Remaining: ') + remainingAmount]);

        tooltipModel.labelColors.splice(tooltipModel.labelColors.length - 1, 0 , totalBkg, totalBkg);
        tooltipModel.labelColors.splice(tooltipModel.labelColors.length, 0 , totalBkgLimit, totalBkg);

        var innerHtml = '<thead>';

        titleLines.forEach(function(title) {
            innerHtml += '<tr><th colspan="2"  style="font-size: 14px;">' + title + '</th></tr>';
        });

        innerHtml += '</thead><tbody>';

        bodyLines.forEach(function(body, i) {
            var lbl = body[0].split(': ');
            var span;

            if (lbl[0] === 'gap') {
                innerHtml += '<tr><td colspan=2 style="padding-bottom:' + lbl[1] + 'px;"></td></tr>'

            } else {

                innerHtml += '<tr';

                if (['Total Amount', 'Exceeded', 'Remaining'].join().includes(lbl[0])) {
                    innerHtml += ' style="border-top: 1px solid;"';
                }

                if (['Total', 'Excee', 'Remai'].join().includes(lbl[0].substr(0, 5))) {
                    span = '<span>&nbsp;&nbsp&nbsp;&nbsp;</span>&nbsp;&nbsp;';
                } else {
                    var colors = tooltipModel.labelColors[i];
                    var style = 'background:' + colors.backgroundColor;
                    style += '; border-color:' + colors.borderColor;
                    style += '; border-width: 2px';
                    span = '<span style="' + style + '">&nbsp;&nbsp&nbsp;&nbsp;</span>&nbsp;&nbsp;';
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
    tooltipEl.style.left = position.left + window.scrollX + tooltipModel.caretX + 'px';
    tooltipEl.style.top = position.top + window.scrollY + tooltipModel.caretY + 'px';
    tooltipEl.style.fontFamily = tooltipModel._bodyFontFamily;
    tooltipEl.style.fontSize = tooltipModel.bodyFontSize + 'px';
    tooltipEl.style.fontStyle = tooltipModel._bodyFontStyle;
    tooltipEl.style.padding = tooltipModel.yPadding + 'px ' + tooltipModel.xPadding + 'px';
    tooltipEl.style.pointerEvents = 'none';
}

// draw limits
export function drawTargets(chart) {

    // var chartInstance = this._data.chart;
    var chartInstance = chart.chart;
    var ctx = chartInstance.ctx;
    var xaxis = chartInstance.scales['xBar'];
    var yaxis = chartInstance.scales['yBar'];
    var nDatasets = chartInstance.data.datasets.length;
    var trafficlights = chartInstance.data.trafficlights;

    ctx.textAlign = "left";

    chartInstance.data.datasets.forEach(function(dataset, i) {
        var meta = chartInstance.getDatasetMeta(i);
        meta.data.forEach(function(bar, index) {

            var posY = bar._model.y;
            var barHeight = bar._model.height;
            var radius = 15;
            var posX = 0;
            var paddingLeft = chartInstance.options.layout.padding.left;

            if (i === nDatasets -1) {

                posX = xaxis.getPixelForValue(chartInstance.data.targets[index]);

                /* TARGETS */
                ctx.beginPath();
                ctx.moveTo(posX, posY);
                ctx.lineWidth = 4;
                ctx.moveTo(posX, posY - barHeight / 2);
                ctx.strokeStyle = chartInstance.data.targetColor;
                ctx.lineTo(posX, posY + barHeight / 2);
                ctx.fillStyle = "red";
                ctx.stroke();
                ctx.font = "13px sans-serif";
                ctx.fillText(formatCurrencyLabel(chartInstance.data.targets[index], chartInstance.data.currencyId), posX+6, posY + barHeight/2-6);

                /* LABELS - SUBLABELS */
                posX = 7 + paddingLeft;
                ctx.beginPath();
                ctx.moveTo(posX, posY);
                ctx.font = "13px sans-serif";
                ctx.fillStyle = "#777";

                if (chartInstance.data.showConditionDesc) {

                    // Etiqueta — una sola línea, encima de la barra
                    ctx.font = "13px sans-serif";
                    ctx.fillStyle = "#777";
                    ctx.fillText(bar._model.label, posX, posY - 6);

                    // Condición — debajo de la barra, empezando en x=0, con todo el ancho disponible
                    const conditionText = chartInstance.data.conditions?.[index] || chart.data.sublabels?.[index] || '';
                    const conditionPosX = xaxis.getPixelForValue(0);
                    const conditionPosY = posY + (barHeight / 2) + 14;
                    const conditionMaxWidth = Math.max(chartInstance.width - conditionPosX - 12, 100);

                    // Red de seguridad: recorta la fila a su propia banda vertical,
                    // desde el techo de esta barra hasta el techo de la siguiente
                    const rowTop = posY - barHeight;
                    const nextBar = meta.data[index + 1];
                    const rowBottom = nextBar ? (nextBar._model.y - nextBar._model.height) : chartInstance.height;

                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(0, rowTop, chartInstance.width, rowBottom - rowTop);
                    ctx.clip();
                    ctx.font = "12px sans-serif";
                    ctx.fillStyle = "#777";
                    drawWrappedText(ctx, conditionText, conditionPosX, conditionPosY, conditionMaxWidth, 16);
                    ctx.restore();

                } else {
                    ctx.fillText(bar._model.label, posX, posY - 6);
                    ctx.font = "13px sans-serif";
                    ctx.fillText(chart.data.sublabels[index], posX, posY + 9);
                }

                /* TRAFFIC LIGHTS */
                var colour = colours.trafficlights[trafficlights[index]?.colour] || DEFAULT_GRAY_TRAFFIC_LIGHT;

                ctx.strokeStyle = colours.trafficlights.stroke;
                ctx.beginPath();
                ctx.lineWidth = 0.5;

                var gradient = ctx.createLinearGradient(radius * 2, posY - radius, radius * 2, posY + radius);

                colour.forEach((stop, index) => {
                    gradient.addColorStop(stop.pos, stop.colour);
                });
                ctx.fillStyle = gradient;
                ctx.arc(radius * 2,  posY, radius, 0, 2 * Math.PI);
                ctx.fill();

                /* TRAFFIC LIGHTS HOVER MAP */
                trafficlights[index].x = radius;
                trafficlights[index].y = posY;
                trafficlights[index].height = radius * 2;
                trafficlights[index].width = xaxis.getPixelForValue(0) - radius - 5;
            }
        }, this);
    }, this);
}