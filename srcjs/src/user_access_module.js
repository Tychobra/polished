



const user_access_module = (ns_prefix) => {
    
  $(`#${ns_prefix}users_table`).on("click", ".sign_in_as_btn", e => {
    $(e.currentTarget).tooltip("hide");
    Shiny.setInputValue(`${ns_prefix}sign_in_as_btn_user_uid`, e.currentTarget.id, { priority: "event"});
  });
  
  $(`#${ns_prefix}users_table`).on("click", ".delete_btn", e => {
    $(e.currentTarget).tooltip("hide");
    Shiny.setInputValue(`${ns_prefix}user_uid_to_delete`, e.currentTarget.id, { priority: "event"});
  });
  
  $(`#${ns_prefix}users_table`).on("click", ".edit_btn", e => {
    $(e.currentTarget).tooltip("hide");
    Shiny.setInputValue(`${ns_prefix}user_uid_to_edit`, e.currentTarget.id, { priority: "event"});
  });
  
  // Delete User w/ Enter key
  $(document).on("keypress", e => {
    if (e.which == 13) {
      if ($(`#${ns_prefix}submit_user_delete`).is(":visible")) {
        $(`#${ns_prefix}submit_user_delete`).click();
      }
    }
  });
};





