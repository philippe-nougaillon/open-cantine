# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ -> $('.date').datepicker()

$ -> $('#check_all0').click -> $('.check_all0').attr "checked", @.checked
$ -> $('#check_all1').click -> $('.check_all1').attr "checked", @.checked
$ -> $('#check_all2').click -> $('.check_all2').attr "checked", @.checked
$ -> $('#check_all3').click -> $('.check_all3').attr "checked", @.checked
$ -> $('#check_all4').click -> $('.check_all4').attr "checked", @.checked

