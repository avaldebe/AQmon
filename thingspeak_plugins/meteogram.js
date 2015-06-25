<script type="text/javascript">
var channel={id:37527,read_key:''};       // channel variables
var days = 2;

var fields=[                              // time series
  {name:'Temperature', units:'°C' ,number:1,color:'#FF3333'}, // temp
  {name:'Rel.Humudity',units:'%'  ,number:2,color:'#68CFE8'}, // rhum
  {name:'Atm.Pressure',units:'hPa',number:3,color:'#8BBC21'}];// pres

var chart_title = 'Meteogram';            // plot titles
var chart_subtitle = 'AQmon '+channel.id;

var my_offset = new Date().getTimezoneOffset(); // user's timezone offset
    my_offset = 0; // show local time
var my_chart;                             // chart variable

$(document).on('ready', function() {      // when the document is ready
  addChart(fields);                       // add a blank chart
  for(var i=0; i<fields.length; i++) {    // add time series
    addSeries(channel,fields[i],days,i);
  }
});

function addChart(fields) { // add the base chart
  var localDate;            // variable for the local date in milliseconds
  var chartOptions = {      // specify the chart options
    chart: {
      renderTo: 'container',
      defaultSeriesType: 'line',
      backgroundColor: '#ffffff',
      events: { }
    },
    title:   { text: chart_title },
    subtitle:{ text: chart_subtitle },
    plotOptions: {
      series: {
        marker: { radius: 3 },
        animation: true,
        step: false,
        borderWidth: 0,
        turboThreshold: 0
      }
    },
    tooltip: {
      shared: true,
      xDateFormat: '%a, %b %e, %H:%M'
    },
    xAxis: [{ // Bottom X axis
      type: 'datetime',
      tickInterval: 6 * 36e5,   // six hours
      minorTickInterval: 36e5,  // one hour
    //tickLength: 0,
      gridLineWidth: 1,
      gridLineColor: (Highcharts.theme && Highcharts.theme.background2) || '#F0F0F0',
      startOnTick: false,
      endOnTick: false,
      minPadding: 0,
      maxPadding: 0,
      showLastLabel: true,
      labels: { format: '{value:%H}' }
    }, { // Top X axis
      linkedTo: 0,
      type: 'datetime',
      tickInterval: 24 * 36e5,  // 24 hours
      labels: {
        format: '{value:%a %b %e}',
        align: 'left',
        x: 3,
        y: -5
      },
      opposite: true,
      tickLength: 20,
      gridLineWidth: 1
    }],
    yAxis: [ /* fill up later */],
    exporting: { enabled: false },
    legend: { enabled: false },
    credits: {
      text: 'ThingSpeak.com',
      href: 'https://thingspeak.com/channels/'+channel.id,
      style: { color: '#D62020' }
    }
  };
  for(var i = 0; i < fields.length; i++) {
    chartOptions.yAxis[i]={ // i-th yAxis
    /*title: {
        text:fields[i].name+' ['+fields[i].units+']',
        style:{ color:fields[i].color } }, */
      title: null,
      labels: {
        format: '{value} '+fields[i].units,
        style: { color:fields[i].color } }
    };
    if(i>0){
      chartOptions.yAxis[i].gridLineWidth=0;
      chartOptions.yAxis[i].opposite=true;
    }
  }

  // draw the chart
  my_chart = new Highcharts.Chart(chartOptions);
}

// add a series to the chart
function addSeries(channel, field, days, yAxis) {
  var field_name = 'field' + field.number;

  // get the data with a webservice call
  $.getJSON('https://api.thingspeak.com/channels/'+channel.id+'/fields/'+field.number+
            '.json?offset=0&round=2&average=60&days='+days+'&api_key='+channel.read_key,function(data) {

    var chart_data = [];      // blank array for holding chart data

    // iterate through each feed
    $.each(data.feeds, function () {
      var value = this[field_name];
      var point = new Highcharts.Point();
      // set the proper values
      point.x = getChartDate(this.created_at);
      point.y = isNaN(parseInt(value))?null:parseFloat(value); // show gaps in the series
      // add location if possible
      if (this.location) { point.name = this.location; }
      chart_data.push(point);
    });

    my_chart.addSeries({      // add the chart data
      data: chart_data,
      name: field.name,
      color: field.color,
      yAxis: yAxis,
      tooltip: { valueSuffix: ' '+field.units }
    });
  });
}

function getChartDate(d) {    // converts date format from JSON
  // get the data using javascript's date object (year, month, day, hour, minute, second)
  // months in javascript start at 0, so remember to subtract 1 when specifying the month
  // offset in minutes is converted to milliseconds and subtracted so that chart's x-axis is correct
  return Date.UTC(d.substring(0,4), d.substring(5,7)-1, d.substring(8,10), d.substring(11,13), d.substring(14,16), d.substring(17,19)) - (my_offset * 60000);
}
</script>
