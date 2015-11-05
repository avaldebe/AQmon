<script type="text/javascript">
var channel={id:37527,timezone:'Europe/Oslo',read_key:''};    // channel variables
var days = 2;

var fields=[                              // time series
  {name:'PM 1',  units:'ug/m3',number:4,color:'#FF3333'}, // pm01
  {name:'PM 2.5',units:'ug/m3',number:5,color:'#68CFE8'}, // pm25
  {name:'PM 10', units:'ug/m3',number:6,color:'#8BBC21'}];// pm10
fields.reverse(); // plot pm10,pm2.5,pm01

var chart_title = 'Particulate Matter';   // plot titles
var chart_subtitle = 'AQmon '+channel.id;

//var my_offset = new Date().getTimezoneOffset(); // user's timezone offset
var my_chart;                             // chart variable

$(document).on('ready', function() {      // when the document is ready
  addChart(fields);                       // add a blank chart
  addSeries(channel,fields,days,0);       // add time series
});

function addChart(fields) { // add the base chart
  var localDate;            // variable for the local date in milliseconds
  var chartOptions = {      // specify the chart options
    chart: {
      type: 'column',
      renderTo: 'container',
      backgroundColor: '#ffffff',
      events: { }
    },
    title:   { text: chart_title },
    subtitle:{ text: chart_subtitle },
    plotOptions: {
      column: {
        grouping: false,
        shadow: false,
        borderWidth: 0}
    },
    tooltip: {
      shared: true,
      xDateFormat: '%a, %b %e, %H:%M'
    },
    xAxis: [{ // Bottom X axis
      title: { text: channel.timezone },
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
    yAxis: [{ // common yAxis
        /*title: {
        text:fields[i].name+' ['+fields[i].units+']',
        style:{ color:fields[i].color } }, */
      title: null,
      labels: { format: '{value} '+fields[0].units },
      gridLineWidth:0,
      opposite:true,
    }],
    exporting: { enabled: false },
    legend: { enabled: false },
    credits: {
      text: 'ThingSpeak.com',
      href: 'https://thingspeak.com/channels/'+channel.id,
      style: { color: '#D62020' }
    }
  };

  // draw the chart
  my_chart = new Highcharts.Chart(chartOptions);
}

// add a series to the chart
function addSeries(channel, field, days, n) {
  if( n >= field.length ) return;

  var field_name = 'field' + field[n].number;

  // get the data with a webservice call
  $.getJSON('https://api.thingspeak.com/channels/'+channel.id+'/fields/'+field[n].number+
            '.json?timezone='+channel.timezone+'&round=2&average=60&days='+days+'&api_key='+channel.read_key,function(data) {

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
      name: field[n].name,
      color: field[n].color,
//    yAxis: yAxis,           // common yAxis
      tooltip: { valueSuffix: ' '+field[n].units }
    });

    addSeries(channel,fields,days,n+1); // plot next
  });
}

function getChartDate(d) {    // converts date format from JSON
  // get the data using javascript's date object (year, month, day, hour, minute, second)
  // months in javascript start at 0, so remember to subtract 1 when specifying the month
  // offset in minutes is converted to milliseconds and subtracted so that chart's x-axis is correct
  return Date.UTC(d.substring(0,4), d.substring(5,7)-1, d.substring(8,10), d.substring(11,13), d.substring(14,16), d.substring(17,19));// - (my_offset * 60000);
}
</script>
