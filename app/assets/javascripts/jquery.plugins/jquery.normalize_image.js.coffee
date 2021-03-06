(($) ->
  # почему-то без задержки не работает
  check_image = ($image, options) ->
    $link = $image.parent()

    image_width = $image[0].naturalWidth || $image.width()
    image_height = $image[0].naturalHeight || $image.height()

    if image_width > 300 && !$image.attr('width') && !$image.attr('height')
      normalization_class = if image_width > image_height then 'normalized_width' else 'normalized_height'
      $image.addClass(normalization_class)

    if options.append_marker && !$link.children('.marker').exists() && (image_width > 300 && image_height > 300)
      $link.append "<span class='marker'>#{image_width}x#{image_height}</span>"

    if (image_width < 300 && image_height < 300) && $link.tagName() == 'a' && $link.prop('href') == $image.prop('src')
      $image.unwrap()

  $.fn.extend normalize_image: (options) ->
    @each ->
      $image = $(@)
      $image.imagesLoaded ->
        delay().then -> check_image $image, options
) jQuery
