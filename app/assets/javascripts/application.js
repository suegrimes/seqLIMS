// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.autocomplete
//= require jquery.ui.datepicker
//= require autocomplete-rails
//= require superfish
//= require jquery_nested_form

function add_fields(link, association, content) {  
var new_id = new Date().getTime();  
var regexp = new RegExp("new_" + association, "g");  
$(link).up().insert({  
before: content.replace(regexp, new_id)  
});  
}  

function remove_fields(link) {  
$(link).previous("input[type=hidden]").value = "1";  
$(link).up(".fields").hide();  
}

function checkUncheckAll(theElement) {
var theForm = theElement.form, z = 0;
for(z=0; z<theForm.length;z++){
if(theForm[z].type == 'checkbox' && theForm[z].name != 'checkall'){
theForm[z].checked = theElement.checked;
}
}
}

function num_date() {
    var mm = new Array("01", "02", "03","04", "05", "06", "07", "08", "09","10", "11", "12");
    var full_date = new Date();
    var curr_date = full_date.getDate();
    var curr_month = full_date.getMonth();
    var curr_year = full_date.getFullYear();
    var num_date = curr_year + "-" + mm[curr_month] + "-" + curr_date;
    return num_date;
}

var $j = jQuery.noConflict(); //use jQuery object with $j and won't conflict with other libraries

var load_del_date = function(id) {
    var delete_flag_id = "run_dir_" + id + "_delete_flag";
    var date_deleted_id = "run_dir_" + id + "_date_deleted";
	$j('#' + delete_flag_id).click(function() {
	    if ( $j('#' + delete_flag_id).is(':checked') ) { 
	        $j('#' + date_deleted_id).val(num_date());
        } else { 
	        $j('#' + date_deleted_id).val(''); 
        }
	});
};

function showHideDiv(elementId1, elementId2) {
  if (document.getElementById) {
    var element1 = document.getElementById(elementId1); //div with link to form
    var element2 = document.getElementById(elementId2); //div with form
    if (element2.style.display == 'none') {
      element2.style.display = 'block';
      element1.style.display = 'none';

    } else if (element2.style.display == 'block') {
      element2.style.display = 'none';

    }
  }
}

$j(function () {
  $('#add_items').click(function () {
    var show_err_id = $('#add_items').data('show_err_id')
    var items = $('#nr_items').val();
    if (!window.location.origin)
     window.location.origin = window.location.protocol+"//"+window.location.host;
    var curr_location = window.location.origin
    if (curr_location.match(/reve/)) {
      curr_location += '/seqLIMS/'
    }
    if ($.isNumeric(items)) {
      $("#" + show_err_id).fadeOut(); //.hide()
      $.get(curr_location + '/populate_items?nr_items='+items, null, null, null);
    } else {
      $("#" + show_err_id).show().text('Quantity of Items required');
    }
    //console.log(curr_location)
  })
});


