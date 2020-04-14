
const user_edit_module = (ns_prefix) => {
  $(document).on("keypress", e => {
    if (e.which == 13) {
      if ($(`#${ns_prefix}submit`).is(":visible")) {
        $(`#${ns_prefix}submit`).click();
      }
    }
  });
};


