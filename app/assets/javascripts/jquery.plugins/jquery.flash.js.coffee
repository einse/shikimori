toastr = require 'toastr'
toastr.options.progressBar = true
toastr.options.closeDuration = 250
toastr.options.timeOut = 3000

(($) ->
  $.extend
    flash: (options) ->
      if "alert" of options
        toastr.error options.alert

      else if "info" of options
        toastr.info options.info

      else
        toastr.success options.notice

    alert: (text) ->
      toastr.error text if text

    info: (text) ->
      toastr.info text if text

    notice: (text) ->
      toastr.success text if text

) jQuery
