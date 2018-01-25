/****
**@author Paul Hill
**/


/****
**Loadie
***/
(function( $ ) {
  var Loadie = {};

  /*
   * Generate a unique id for more than one loadie
   */
  Loadie.uid = function() {
    var newDate = new Date();
    return newDate.getTime();
  };

  /*
   * Finishes and fades the loadie out.
   */
  Loadie.finish = function(dom) {
    var loadie = $('#loadie-' + dom.data('loadie-id'), dom);
    loadie.fadeOut(200);
  };

  /*
   * Updates loadie with a float
   *
   * Loadie.update(0.2)
   * Loadie.update(1) // Finishes loadie, too
   */
  Loadie.update = function(dom, percent) {
    var loadie = $('#loadie-' + dom.data('loadie-id'), dom);
    var parentWidth = dom.width();
    loadie.css('width', Math.floor(percent * parentWidth) + "px");
  };

  /*
   * Loadie.js initializer
   */
  Loadie.init = function(dom, percent) {
    var uid = this.uid();
    var loadie = dom.append($('<div id="loadie-' + uid + '" class="loadie"></div>'));
    dom.data('loadie-id', uid);
    dom.css('position', 'relative');
    this.update(dom, percent);
  };

  $.fn.loadie = function(percent_in, callback) {
    var percent = percent_in || 0;
    var parent = $(this);

    if(parent.data('loadie-loaded') !== 1) {
      Loadie.init(parent, percent);
    } else {
      Loadie.update(parent, percent);
    }
    if(percent >= 1) {
      setTimeout(function() {
        Loadie.finish(parent);
      }, 200);
    }
    parent.data('loadie-loaded', 1);
    return this;
  };
}( jQuery ));



/******
**main
******/

var tabs = [0, 0, 0, 0, 0];
var ampData = [[],[],[],[],[],[],[],[],[],[]];
var freqData = [[],[],[],[],[],[],[],[],[],[]];

var chartAmpl = null;
var chartFreq = null;

var maxAmp = 1, minAmp = 0, maxFreq=62.5e6, minFreq=0;

var app_id = 'm-dds-seq';
var root_url = '';
var stop_app_url = root_url + '/bazaar?stop=';
var start_app_url = root_url + '/bazaar?start=' + app_id;
var get_url = root_url + '/data';
var timeout = 3000;//ms

var queue = [];
var index = 0;

var port = 0;

var sending = false;
var appStarted = false;

var phase_reset = false;

var retries = 0;


//html loaded time to initialize js stuff
window.onload = function () {

  if(!DEBUGMODE)
    $('#testInput').css('display','none');

  //enable tooltips
  $('[data-toggle="tooltip"]').tooltip({
    container: 'body'
  });

  // prepare charts
    CanvasJS.addColorSet('colorSet',
     [//colorSet Array
       "#929600",
       "#a5609d",
       "#ffbf00",
       "#5d9ec8",
       "#c56e1a",
       "#8778b3",
       "#ec6235",
       "#8fb131",
       "#e7b050",
       "#5e81b5"
    ].reverse());
    chartAmpl = new CanvasJS.Chart("amplContainer", {
        backgroundColor: "#f5f5f5",//282c34",
        colorSet: 'colorSet',
        zoomEnabled: true,
        zoomType: "xy",
        axisX: {
          gridDashType: "dash",
			    gridThickness: 1,
          labelFontSize: 15,
          tickLength: 10,
          tickThickness:0,
          lineThickness: 2,
          title: "Time [s]",
          titleFontSize: 15
          //gridColor:"#3c4049"
        },
        axisY: {
          gridDashType: "dash",
			    gridThickness: 1,
          labelFontSize: 15,
          tickLength: 0,
          lineThickness: 2,
          title: "Amplitude [%]",
          titleFontSize: 15
          //gridColor:"#3c4049"
        },
        data: [{type: "line",visible:true, toolTipContent: '<strong>DDS1</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: [{x:0,y:1}]}, {type: "line",visible:true, toolTipContent: '<strong>DDS2</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS3</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS4</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},
          {type: "line",visible:true, toolTipContent: '<strong>DDS5</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS6</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS7</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS8</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS9</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS10</strong><br><span style="\'"color: {color};"\'">{x}s: {y}%</span>',dataPoints: null}]

    });
    chartFreq = new CanvasJS.Chart("freqContainer", {
      backgroundColor: "#f5f5f5",//282c34",
      colorSet: 'colorSet',
      zoomEnabled: true,
      zoomType: "xy",
      axisX: {
        gridDashType: "dash",
        gridThickness: 1,
        labelFontSize: 15,
        tickLength: 10,
        tickThickness:0,
        lineThickness: 2,
        title: "Time [s]",
        titleFontSize: 15
        //gridColor:"#3c4049"
      },
      axisY: {
        gridDashType: "dash",
        gridThickness: 1,
        labelFontSize: 15,
        tickLength: 0,
        lineThickness: 2,
        title: "Frequency [Hz]",
        titleFontSize: 15
        //gridColor:"#3c4049"
      },
      data: [{type: "line",visible:true, toolTipContent: '<strong>DDS1</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: [{x:0,y:1}]}, {type: "line",visible:true, toolTipContent: '<strong>DDS2</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS3</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS4</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},
        {type: "line",visible:true, toolTipContent: '<strong>DDS5</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS6</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS7</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS8</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS9</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null},  {type: "line",visible:true, toolTipContent: '<strong>DDS10</strong><br><span style="\'"color: {color};"\'">{x}s: {y}Hz</span>',dataPoints: null}]

    });
    chartFreq.render();
    chartAmpl.render();

    //register input data validation
    $('.time').change(inputTime);
    $('.amp').change(inputAmp);
    $('.freq').change(inputFreq);


    //dds-tab selection
    $('#dds1-tab').click(function(){
      tabs[0] = 0;
    });

    $('#dds5-tab').click(function(){
      tabs[0] = 1;
    });

    $('#dds2-tab').click(function(){
      tabs[1] = 0;
    });

    $('#dds6-tab').click(function(){
      tabs[1] = 1;
    });

    $('#dds3-tab').click(function(){
      tabs[2] = 0;
    });

    $('#dds7-tab').click(function(){
      tabs[2] = 1;
    });

    $('#dds8-tab').click(function(){
      tabs[2] = 2;
    });

    $('#dds4-tab').click(function(){
      tabs[3] = 0;
    });

    $('#dds9-tab').click(function(){
      tabs[3] = 1;
    });

    $('#dds10-tab').click(function(){
      tabs[3] = 2;
    });

    //register add listeners
    $('#add15').click(function(){
      if(tabs[0]===0)
        add(1);
      else
        add(5);
      $(this).blur();
    });

    $('#add26').click(function(){
      if(tabs[1]===0)
        add(2);
      else
        add(6);
      $(this).blur();
    });

    $('#add378').click(function(){
      switch(tabs[2]){
        case 0:
          add(3);
          break;
        case 1:
          add(7);
          break;
        case 2:
          add(8);
          break;
      }
      $(this).blur();
    });

    $('#add4910').click(function(){
      switch(tabs[3]){
        case 0:
          add(4);
          break;
        case 1:
          add(9);
          break;
        case 2:
          add(10);
          break;
      }
      $(this).blur();
    });

    //register refresh listeners
    $('#refresh15').click(function(){
      if(tabs[0]===0)
        refresh(1);
      else {
        refresh(5);
      }
      $(this).blur();
    });

    $('#refresh26').click(function(){
      if(tabs[1]===0)
        refresh(2);
      else {
        refresh(6);
      }
      $(this).blur();
    });

    $('#refresh378').click(function(){
      switch(tabs[2]){
        case 0:
          refresh(3);
          break;
        case 1:
          refresh(7);
          break;
        case 2:
          refresh(8);
          break;
      }
      $(this).blur();
    });

    $('#refresh4910').click(function(){
      switch(tabs[3]){
        case 0:
          refresh(4);
          break;
        case 1:
          refresh(9);
          break;
        case 2:
          refresh(10);
          break;
      }
      $(this).blur();
    });

    //register modal buttons
    $('.btn-app-restart').click(function(){
      document.location.href = '/m-dds-seq/?type=run';
    });

    //register dds chart buttons (to hide or show dds sequences)
    $('.dds-as').each(function(index, item){
      var i = $(item);
      i.click(function(){
        i.toggleClass('active');
        i.blur();
        chartAmpl.options.data[index].visible = !chartAmpl.options.data[index].visible;
        chartAmpl.render();
      });
    });

    $('.dds-fs').each(function(index, item){
      var i = $(item);
      i.click(function(){
        i.toggleClass('active');
        i.blur();
        chartFreq.options.data[index].visible = !chartFreq.options.data[index].visible;
        chartFreq.render();
      });
    });

    //chart zooming, panning reset
    $('.canvasjs-chart-toolbar').css('display','none');
    $('#ampZoom').click(function(){
      $(this).addClass('active');
      $('#ampPan').removeClass('active');
      chartAmpl.zoomEnabled = true;
      chartAmpl.panEnabled = false;
    });
    $('#ampPan').click(function(){
      $(this).addClass('active');
      $('#ampZoom').removeClass('active');
      chartAmpl.zoomEnabled = false;
      chartAmpl.panEnabled = true;
    });
    $('#ampReset').click(function(){
      reset(chartAmpl);
      $(this).blur();
    });
    $('#freqZoom').click(function(){
      $(this).addClass('active');
      $('#freqPan').removeClass('active');
      chartFreq.zoomEnabled = true;
      chartFreq.panEnabled = false;
    });
    $('#freqPan').click(function(){
      $(this).addClass('active');
      $('#freqZoom').removeClass('active');
      chartFreq.zoomEnabled = false;
      chartFreq.panEnabled = true;
    });
    $('#freqReset').click(function(){
      reset(chartFreq);
      $(this).blur();
    });


    //register refresh all
    $('#refresh').click(function(){
      for(var i=1;i<=10;++i){
        if(!refresh(i)){
          alert('Validation Error', 'Error while validation in DDS'+i+' sequence ', 'danger');
          break;
        }
      }
      $(this).blur();
    });

    //register send data
    $('#send-data').click(function(){
      if(!appStarted)
        return;
      sendData();
      $(this).blur();
    });

    //register send softwareTrigger
    $('#softwareTrigger').click(function(){
      if(!appStarted)
        return;
      softwareTrigger();
      $(this).blur();
    });

    //register set phase_reset
    $('#phaseReset').click(function(){
      $('#phaseReset').toggleClass('active');
      phase_reset=!phase_reset;
      setPhaseReset(phase_reset);
      $(this).blur();
    })

    //register leave awake
    $('#leaveAwake').click(function(){
      if(!appStarted)
        return;
      leaveAwake();
      $(this).blur();
    });

    //register upload sequences from RedPitaya
    $('#upload').click(function(){
      if(!appStarted)
        return;
      sending = true;
      $.ajax({
        url: 'http://'+(DEBUGMODE===2?'127.0.0.1':location.hostname)+':'+port,
        method: 'POST',
        data: '2',
        timeout: timeout,
      })
      .always(function(dresult){
        var data = JSON.parse(dresult);
        if(!('ampData' in data) || !('freqData' in data) || !loadData(data.ampData, data.freqData))
          alert('NETWORK ERROR',(typeof(dresult)==='object')?dresult.statusText:dresult, 'danger');
        sending = false;
      });
      $(this).blur();
    });

    //register download sequences to RedPitaya
    $('#download').click(function(){
      if(!appStarted)
        return;
      sending = true;
      var data = prepareData();
      if(data===false){
        $(this).blur();
        return;
      }
      $.ajax({
        url: 'http://'+(DEBUGMODE===2?'127.0.0.1':location.hostname)+':'+port,
        method: 'POST',
        data: '1'+JSON.stringify({ampData: ampData, freqData: freqData}),
        timeout: timeout,
      })
      .always(function(dresult){
        sending = false;
        if(dresult=='OK')
          return;
        alert('NETWORK ERROR',(typeof(dresult)==='object')?dresult.statusText:dresult, 'danger');
      });
      $(this).blur();

    });


    // Stop the application when page is unloaded
  window.onbeforeunload = function() {
    $.ajax({
      url: stop_app_url,
      async: false
    });
  };


    //init math.js, neccessary for bitwise operations with 64bit numbers
    math.config({
      number: 'BigNumber', // Default type of number:
                       // 'number' (default), 'BigNumber', or 'Fraction'
      precision: 128        // Number of significant digits for BigNumbers
  });

  //init loadie
  $('body').loadie();

  //start
  setTimeout(startApp,500);
};

//check every 2s if connection to http server on RedPitaya is still up
function checkConnection(){
  if(sending)
    return;
  sending = true;
  $.ajax({
    url: 'http://'+(DEBUGMODE===2?'127.0.0.1':location.hostname)+':'+port,
    method: 'POST',
    data: "3",
    timeout: timeout
  })
  .always(function(dresult){
    if(dresult!=='OK'){
      if(retries<3){
        setTimeout(checkConnection,2000);
        ++retries;
        sending = false;
        return;
      }
      showModalError((dresult.reason ? dresult.reason : 'RedPitaya is not reachable!'), false, true);
    }
    retries = 0;
    sending = false;
  });
}

//tell Nginx-RedPitaya-module to start the server side app
function startApp() {
  if(DEBUGMODE==2)
    return;
    $.get(
      start_app_url
    )
    .done(function(dresult) {
    	if(dresult.status == 'ERROR') {
      	showModalError((dresult.reason ? dresult.reason : 'Could not start the application.'), false, true);
      }else {
        appStarted = true;
        setTimeout(getPort,500);
	    }
    });
  }

//get HTTP server port
function getPort(){
  $.ajax({
    url: get_url,
    timeout: timeout,
    cache: false
  })
  .done(function(dresult) {
    if(dresult.status === 'ERROR') {
      showModalError((dresult.reason ? dresult.reason : 'Application error.'), false, true);
    }
    else if(dresult.datasets !== undefined && dresult.datasets.params !== undefined) {
      // Check if the application started on the server is the same as on client
      if(app_id !== dresult.app.id) {
        $('#new_app_id').text(dresult.app.id);
        $('#modal_app').modal('show');
        return;
      }
      port = dresult.datasets.params.port;
      setInterval(checkConnection, 500);
    }
    else {
      showModalError('Wrong application data received.', false, true);
    }
  })
  .fail(function(jqXHR, textStatus, errorThrown) {
    showModalError('Data receiving failed.<br>Error status: ' + textStatus, false, true);
  });
}

function showModalError(err_msg, retry_btn, restart_btn, ignore_btn) {
  var err_modal = $('#modal_err');

  err_modal.find('#btn_retry_get')[retry_btn ? 'show' : 'hide']();
  err_modal.find('.btn-app-restart')[restart_btn ? 'show' : 'hide']();
  err_modal.find('#btn_ignore')[ignore_btn ? 'show' : 'hide']();
  err_modal.find('.modal-body').html(err_msg);
  err_modal.modal('show');
}

function leaveAwake(btn){
  //dont notice app
  window.onbeforeunload = function() {
  };
  document.location.href = '/index.html';
}

//reset chart viewport
function reset(a){
  a.toolTip.hide();
  if (a.sessionVariables.axisX) {
      for (var b = 0; b < a.sessionVariables.axisX.length; b++) {
          a.sessionVariables.axisX[b].newViewportMinimum = null;
          a.sessionVariables.axisX[b].newViewportMaximum = null;
      }
  }
  if (a.sessionVariables.axisY) {
      for (var c = 0; c < a.sessionVariables.axisY.length; c++) {
          a.sessionVariables.axisY[c].newViewportMinimum = null;
          a.sessionVariables.axisY[c].newViewportMaximum = null;
      }
  }
  a.resetOverlayedCanvas();
  a._dispatchRangeEvent("rangeChanging",
      "reset");
  a.render();
  a._dispatchRangeEvent("rangeChanged", "reset");
}

//add more input fields
function add(dds_i){
  $('#dds'+dds_i+'_tb').append('<tr><td><input type="text" class="form-control time"></td><td><input type="text" class="form-control amp"></td><td><input type="text" class="form-control freq"></td></tr>'+
                        '<tr><td><input type="text" class="form-control time"></td><td><input type="text" class="form-control amp"></td><td><input type="text" class="form-control freq"></td></tr>'+
                        '<tr><td><input type="text" class="form-control time"></td><td><input type="text" class="form-control amp"></td><td><input type="text" class="form-control freq"></td></tr>'+
                        '<tr><td><input type="text" class="form-control time"></td><td><input type="text" class="form-control amp"></td><td><input type="text" class="form-control freq"></td></tr>'+
                        '<tr><td><input type="text" class="form-control time"></td><td><input type="text" class="form-control amp"></td><td><input type="text" class="form-control freq"></td></tr>');
  $('.time').change(inputTime);
  $('.amp').change(inputAmp);
  $('.freq').change(inputFreq);
}

//update new data and do some validation
function refresh(dds_i_in){
  var dds_i = dds_i_in -1;
  ampData[dds_i] = [];
  freqData[dds_i] = [];
  var error = false;
  $('#dds'+dds_i_in+'_tb tr').has('td').each(function(){
    var ampItem = {};
    var freqItem = {};
    var i = 0;
    var e = false;
    $('td input', $(this)).each(function(index, item) {
      if($(item).val()===''){
        ++i;
      }
      var v = parseFloat($(item).val());
      if(toFixedStr(v, 3)==='NaN')
        e = true;
      switch(index){
        case 0:
          ampItem.x = freqItem.x = v;
          break;
        case 1:
          ampItem.y = v;
          break;
        case 2:
          freqItem.y = v;
          break;
      }
    });
    if(i!=3){
      if(e){
        //$(this).css('background-color', '#ce5454');
        $(this).addClass('item bad');
        $(this).children('.alert-data').remove();
        $(this).append('<div class="alert alert-data">wrong input!</div>');
        error = true;
        return;
      }
      else if(ampData[dds_i].length===0 && ampItem.x!=0){
        $(this).addClass('item bad');
        $(this).children('.alert-data').remove();
        $(this).append('<div class="alert alert-data">first event must be at 0s!</div>');
        error = true;
        return;
      }
      else if(ampData[dds_i].length!==0 && ampData[dds_i][ampData[dds_i].length-1].x>= ampItem.x){
        $(this).addClass('item bad');
        $(this).children('.alert-data').remove();
        $(this).append('<div class="alert alert-data">event\'s time must be later!</div>');
        error = true;
        return;
      }
      else{
        $(this).removeClass('item bad');
        $(this).children('.alert-data').remove();
        ampData[dds_i].push(ampItem);
        freqData[dds_i].push(freqItem);
      }
    }else{
      $(this).removeClass('item bad');
      $(this).children('.alert-data').remove();
    }
  });

  if(!error){
    chartAmpl.options.data[dds_i].dataPoints = ampData[dds_i];
    chartFreq.options.data[dds_i].dataPoints = freqData[dds_i];
    chartAmpl.render();
    chartFreq.render();
    return true;
  }else {
    return false;
  }
}


//load stored data into tables
function loadData(ampData, freqData){
  if(ampData.length!=10 || freqData.length!=10)
    return false;
  for(var i=0;i<ampData.length;++i){
    if(ampData[i].length!=freqData[i].length)
      return false;
    $('#dds'+(i+1)+'_tb').empty();
    var j=0;
    for(;j<ampData[i].length;++j){
      $('#dds'+(i+1)+'_tb').append('<tr><td><input type="text" class="form-control time" value="'+ampData[i][j].x+'"></td><td><input type="text" class="form-control amp" value="'+ampData[i][j].y+'"></td><td><input type="text" class="form-control freq" value="'+freqData[i][j].y+'"></td></tr>');
    }
    if(j===0)
      $('#dds'+(i+1)+'_tb').append('<tr><td><input type="text" class="form-control time"></td><td><input type="text" class="form-control amp"></td><td><input type="text" class="form-control freq"></td></tr>');
  }
  $('.time').change(inputTime);
  $('.amp').change(inputAmp);
  $('.freq').change(inputFreq);
  for(var k=1;k<=10;++k){
    if(!refresh(k)){
      alert('Validation Error', 'Error while validation in DDS'+k+' sequence ', 'danger');
      break;
    }
  }
  return true;
}

//directly input validation
function inputTime(){
  inputChanged(this, 0);
}

function inputAmp(){
  inputChanged(this, 1);
}

function inputFreq(){
  inputChanged(this, 2);
}

function inputChanged(item, index){
  var v = parseFloat(item.value.replace(',','.'));
  if(toFixedStr(v, 3)=='NaN')
    item.value = '';
  else {
    if(index===1){
      if(v>maxAmp)
        v=maxAmp;
      else if(v<minAmp){
        v = minAmp;
      }
    }else if(index===2){
      if(v>maxFreq){
        v = maxFreq;
      }
      else if(v<minFreq){
        v = minFreq;
      }
    }else{
      if(v<0)
        v = 0;
    }
    item.value = toFixedStr(v, 3);
  }
}

function toFixedStr(num, digits) {
    var m = Math.pow(10, digits);
    return (Math.round(num*m)/m).toFixed(digits);
}

function alert(title, msg, level){
  $('body').append('<div class="alert alert-'+level+' alert-dismissable fade in refresh-alert">'+
    '<a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>'+
    '<strong>'+title+'</strong><br>'+msg+'</div>');
}


/*****
**Connection to RedPitaya
******/

function sendData(){
  sending = true;
  if(DEBUGMODE>=1){
    $.ajax({
      url: 'http://'+(DEBUGMODE===2?'127.0.0.1':location.hostname)+':'+port,
      method: 'POST',
      data: $('#testInput').val(),
      timeout: timeout,
    })
    .always(function(dresult){
      sending = false;
      if(dresult=='OK')
        return;
      alert('NETWORK ERROR',(typeof(dresult)==='object')?dresult.statusText:dresult, 'danger');
    });
    return;
  }
  var t = -1;
  var b = false;
  for(var i=0;i<ampData.length;++i){
    if(ampData[i].length>0){
      b = true;
      if(t===-1)
        t = ampData[i][ampData[i].length-1].x;
      else {
        if(t!==ampData[i][ampData[i].length-1].x){
          alert('Sending Data', 'DDS'+(i+1)+' sequence duration differs.<br> This may cause problems!', 'warning');
          break;
        }
      }
    }
  }

  if(queue.length!=index){
    alert('Sending Data', 'Already sending data!', 'warning');
  }

  /*1. prepare data array
  * 2. generate all needed fpga address-value pairs (SendFullSeqs) and store them in queue
  * 3. send them successively to the http server, where they're written to fpga
  */
  var data = prepareData();
  console.log(JSON.stringify(data));
  if(data===false)
    return;
  queue = [];
  index = 0;
  $('.loadie').fadeIn();
  $('body').loadie(0);
  ledsOn();//performs better with leds on!
  SendFullSeqs(data);
  //run redpitaya_write recursively
  redpitaya_write(queue[0].addr, queue[0].val, true);
}



//prepare secquences data for transferring to RedPitaya (pack data to an array which is later processed by the original, translated python code)
function prepareData(){
    var array = [];
    var a_i = 0;
    for(var i=0;i<ampData.length;++i){
      if(ampData[i].length===0)
        continue;
      if(ampData[i].length===1){
        alert('Preparing Data', 'DDS'+(i+1)+' sequence contains no events!', 'danger');
        return false;
      }
      array[a_i] = [];
      for(var k=0;k<ampData[i].length;++k){
        if(k===0){
          array[a_i][0] = [freqData[i][0].y, ampData[i][0].y];
        }
        else if(k===1){
          array[a_i][1] = [];
          array[a_i][1][k-1] = [ampData[i][k].x, freqData[i][k].y, ampData[i][k].y];
        }
        else{
          array[a_i][1][k-1] = [ampData[i][k].x, freqData[i][k].y, ampData[i][k].y];
        }
      }
      ++a_i;
    }
    if(array.length === 0){
      alert('Preparing Data', 'No events!', 'danger');
      return false;
    }
    return array;
}



/*****
**The original Python stuff translated to JS
** note that the library math.js because bitwise operations with 64bit numbers are neccessary
******/

/**"""
***The original python code was written by Jon Simon
***Send to RP
***"""
**/
//##########################################################################################################!!!!!
//#ADDRESSES IN THE MEMORY MAPPED ADDRESS SPACE

var DEBUGMODE = 0;

var LEDADDRESS                  = 0x40000030;    //address in FPGA memory map to control RP LEDS

var maxevents                   = 64*16;

var numbits                     = 32;

var DDS_CHANNEL_OFFSET          = 1076887552+4*0;                  //offset in WORDS (4 bytes) to the channel that we are currently writing to!
var DDSawaittrigger_OFFSET      = 1076887552+4*24;                 //offset in WORDS (4 bytes) to address where we write ANYTHING to tell system to reset and await trigger
var DDSsoftwaretrigger_OFFSET   = 1076887552+4*25;                 //offset in WORDS (4 bytes) to address where we write ANYTHING to give the system a software trigger!
var phase_reset_OFFSET          = 1076887552+4*26;                 //offset in WORDS (4 bytes) to address where we write 1 or 0 to specify wether to reset phase a sequence start or not
var DDSftw_IF_OFFSET            = 1076887552+4*1;                  //offset in WORDS (4 bytes) to the initial/final FTW for the current channel
var DDSamp_IF_OFFSET            = 1076887552+4*3;                  //offset in WORDS (4 bytes) to the initial/final amp for the current channel
var DDSsamples_OFFSET           = 1076887552+4*2;                  //offset in WORDS (4 bytes) to # of samples for the current channel

//####EXPECT LOW WORD AT LOWER MEMORY ADDRESS FOR FREQS (FTW) RAMS! ###
var DDSfreqs_OFFSET            = 1076887552+4*40;                      //offset in WORDS to the first element of the current freq list
var DDScycles_OFFSET           = DDSfreqs_OFFSET  + 4*maxevents*2;     //offset in WORDS to the first element of the current cyc. list
var DDSamps_OFFSET             = DDScycles_OFFSET + 4*maxevents*1;     //offset in WORDS to the first element of the current cyc. list
var DDSamps_last_OFFSET        = DDScycles_OFFSET + 4*maxevents*2 - 1; //offset in WORDS to the last  element of the current cyc. list

var maxsendlen=31*512;  //most FIR coefficients we can send at a time
var fclk_Hz=125*Math.pow(10,6); //redpitaya clock frequency
var DDSamp_fracbits = 14; //number of DDS bits to the right of the decimal point (all of them, of course!)
var DDSchannels = 10; //number of DDS freqs we can simultaneously output!

function pow2(a){
  return Math.pow(2,a);
}

function ledsOn(){
  queue.push({addr:LEDADDRESS,val:255});
}

function SendFullSeqs( AllSeqs ){
    //the data for each channel is an element of AllSeqs, sent as follows:
        //[[IFfreq_Hz,IFamp_frac],[[time_sec,freq_Hz,amp_frac]]]
    if (AllSeqs.length>DDSchannels){
        alert('Sending','TOO MANY CHANNELS FOR FPGA! FAIL!','danger');
        return;
    }
    for (var chan=0;chan<DDSchannels;++chan){
      var curdat = [];
        if (chan<AllSeqs.length)
            curdat=AllSeqs[chan];
        else
            curdat=[[0.0,0.0],[[0.0001,0.0,0.0]]];

        var IFfreq_Hz  = curdat[0][0];
        var IFamp_frac = curdat[0][1];

        var times_sec = [];
        var freqs_Hz = [];
        var amps_frac = [];
        for(var k=0;k<curdat[1].length;++k)
          times_sec.push(curdat[1][k][0]);
        for(var l=0;l<curdat[1].length;++l)
          freqs_Hz.push(curdat[1][l][1]);
        for(var j=0;j<curdat[1].length;++j)
          amps_frac.push(curdat[1][j][2]);

        SendSeqToChannel (chan,IFfreq_Hz,IFamp_frac,times_sec,freqs_Hz,amps_frac);
    }

    //reset the RP FSM and prepare it for a trigger!
    queue.push({addr:DDSawaittrigger_OFFSET,val:0});//value sent doesn't affect anything
}

function softwareTrigger(){
  sending = true;
  //reset the RP FSM and prepare it for a trigger!
  redpitaya_write(DDSawaittrigger_OFFSET, 0, false);//value sent doesn't affect anything

  //for now, give it a software trigger, for testing!
  redpitaya_write(DDSsoftwaretrigger_OFFSET, 0, false);//value sent doesn't affect anything
}

function setPhaseReset(phase_reset){
  sending = true;
  redpitaya_write(phase_reset_OFFSET, phase_reset?1:0, false);
}

function SendSeqToChannel(channel, IFfreq_hz, IFamp_frac, times_sec, freqs_hz, amps_frac ){
    if (times_sec.length>maxevents){
        alert('Sending', 'TOO MANY EDGES ON CHANNEL-- EXCEEDS RED PITAYA RAM SPACE OF ' + maxevents,'danger');
        return;
      }

    var IFamp_frac_c=Math.min(IFamp_frac,1.0-pow2(-DDSamp_fracbits)); //make sure we don't overflow the amplitude!
    var IF_ATW=Math.floor(IFamp_frac_c*pow2(DDSamp_fracbits));

    var amps_frac_c = [];
    var deltas_amp_frac = [];
    for(var k=0;k<amps_frac.length;++k)
      amps_frac_c.push(Math.min(amps_frac[k],1.0-pow2(-DDSamp_fracbits))); //make sure we don't overflow the amplitude!
    for(var i=0;i<times_sec.length-1;++i)
      deltas_amp_frac.push(amps_frac_c[i+1]-amps_frac_c[i]);

    deltas_amp_frac.splice(0,0,amps_frac_c[0]-IFamp_frac_c);

    var IF_FTW=HzToFTW(IFfreq_hz);
    var freqs_FTW=freqs_hz.map(HzToFTW);

    var deltas_FTW = [];
    for(var j=0;j<times_sec.length-1;++j)
      deltas_FTW.push(freqs_FTW[j+1]-freqs_FTW[j]);

    deltas_FTW.splice(0,0,freqs_FTW[0]-IF_FTW);

    var times_cyc=times_sec.map(SecToCycles);

    var dt_cyc = [];
    for(var l=0;l<times_sec.length-1;++l)
      dt_cyc.push(Math.max(2,Math.floor(Math.round(times_cyc[l+1]-times_cyc[l])))); //we use two cycles min, as the RAM might not be fast enough otherwise :(

    dt_cyc.splice(0,0,Math.max(1,Math.floor(Math.round(times_cyc[0]))));

    var df_FTW = [];
    var da_ATW = [];
    for(var m=0;m<dt_cyc.length;++m){
      df_FTW.push(math.floor(math.round(math.multiply(math.bignumber(pow2(32)),math.bignumber(deltas_FTW[m]/dt_cyc[m])))));
      da_ATW.push(math.round(math.multiply(math.bignumber(pow2(32+DDSamp_fracbits)),math.bignumber(deltas_amp_frac[m]/dt_cyc[m]))));
    }

    //console.log('Length of dt_cyc: ' + dt_cyc.length);
    //console.log('Length of dt_FTW: ' + dt_FTW.length);
    //console.log('IFamp: ' + IFamp_frac);

    //set the channel that we are writing to!
    queue.push({addr:DDS_CHANNEL_OFFSET,val:channel});

      //send the number of samples on each channel
      queue.push({addr:DDSsamples_OFFSET,val:times_sec.length});
      //console.log('listlen: ' + times_sec.length);

      //send step sizes for each ramp!
      console.log('[cycles,df,da]:');
      for(var n=0;n<dt_cyc.length;++n){ //data must be sent as dFTW,dAMP, and corresponding cycles, as the last is when all are written into the memory!
          sendpitaya_long(DDSfreqs_OFFSET  + 8*n,df_FTW[n] );  //these must be sent as 2's complement 64 bit numbers
          sendpitaya_long(DDSamps_OFFSET   + 8*n,da_ATW[n]  ); //these must be sent as 2's complement 64 bit numbers
          queue.push({addr:DDScycles_OFFSET + 4*n,val:dt_cyc[n]}); //these must be sent as unsigned 32 bit numbers
          console.log('['+dt_cyc[n]+','+df_FTW[n]+','+da_ATW[n]+']');
      }
      //send the I/F values of the  channel
      queue.push({addr:DDSftw_IF_OFFSET,val:Math.floor(IF_FTW)});//these must be sent as unsigned 32 bit numbers
      queue.push({addr:DDSamp_IF_OFFSET,val:Math.floor(IF_ATW)});//these must be sent as unsigned 32 bit numbers
      //console.log('----');
}

function HzToFTW( freq_hz ){ //take a frequency in Hz, and convert it to a RP FTW FLOAT, to minimize rounding error down the line! NO BITSHIFTS FOR NOW!
    return freq_hz*pow2(32)/fclk_Hz;
}

function SecToCycles ( t_sec ){//take a time in seconds and convert it to RP timesteps in cycles, without rounding, so we can do it later when we compute deltas!
    return t_sec*fclk_Hz;
}

function convert_2c(val, bits){ //take a signed integer and return it in 2c form
    if (val>=0)
        return math.bignumber(val);
    return math.add(math.eval('2^'+bits),math.bignumber(val));
  }

function sendpitaya_long(addr, val){ //addr is the address low word. addr+4*4 is where the high word goes!
                                //val is a float, that should be sent in 2c form!
    val2cH=math.divide(convert_2c(val,64),math.eval('2^32'));
    val2cL=math.bitAnd(val,math.bignumber(0xffffffff));
    queue.push({addr:addr,val:val2cL});
    queue.push({addr:addr+4,val:math.floor(val2cH)});
}

function redpitaya_write(addr, val, recursive){
  $.ajax({
    url: 'http://'+(DEBUGMODE===2?'127.0.0.1':location.hostname)+':'+port,
    method: 'POST',
    data: '0'+addr+';'+val+';',
    timeout: timeout
  })
  .always(function(dresult){
    if(dresult=='OK'){
      if(!recursive){
        sending = false;
        return;
      }
      ++index;
      $('body').loadie(index/queue.length);
      if(index<queue.length)
        redpitaya_write(queue[index].addr, queue[index].val, true);
      else {
        $('body').loadie(1);
        $('body').loadie(0);
        sending = false;
      }
      return;
    }
    if(recursive)
      index = queue.length;
    alert('NETWORK ERROR',(typeof(dresult)==='object')?dresult.statusText:dresult, 'danger');
    $('body').loadie(0);
    sending = false;
  });
}
