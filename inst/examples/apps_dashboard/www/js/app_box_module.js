


function app_box_module_js(id) {
  var ns_pound = NS(id, "#")

  $(ns_pound("go_to_back")).click(function(){
          
    $(ns_pound("go_to_back")).hide()
    $(ns_pound("go_to_front")).show()
  })
  
  $(ns_pound("go_to_front")).click(function(){
          
    $(ns_pound("go_to_front")).hide()
    $(ns_pound("go_to_back")).show()
  })
  
}
