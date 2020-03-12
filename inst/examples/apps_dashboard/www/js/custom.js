
/* like shiny::NS
* 
* @param nd_id the id for the namespace
* @param prefix optional prefix for the namespace. e.g. "#"
* 
* @return a function to create the namespaced ids
* 
* @examples
* 
* // create a Shiny ns function
* var ns = NS("<ns_id>")`
*
* // create a Shiny ns function which returns namespaces prefixed by a "#".
* // useful when you need to find the elements by id
* var ns_pound = NS("<ns_id>", "#")
*
*/
function NS(ns_id, prefix = "") {
  return function(input_id) {
    return prefix + ns_id + "-" + input_id
  }
}
