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