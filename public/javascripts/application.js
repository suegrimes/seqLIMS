// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

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

function toggle_list(id){
    ul = "ul_" + id;
    img = "img_" + id;
    ulElement = document.getElementById(ul);
    imgElement = document.getElementById(img);
    if (ulElement){
            if (ulElement.className == 'closed'){
                    ulElement.className = "open";
                    imgElement.src = "/images/opened.gif";
                    }else{
                    ulElement.className = "closed";
                    imgElement.src = "/images/closed.gif";
                    }
            }
    }  