# уведомлялка о новых комментариях
# назначение класса - смотреть на странице новые комментаы и отображать информацию об этом
module.exports = class CommentsNotifier
  constructor: ->
    # дом элемент нотификатора
    @$notifier = null
    # текущее значение счётчика
    @current_counter = 0

    @comment_selector = 'div.b-appear_marker.active'
    @faye_loader_selector = '.faye-loader'

    # при загрузке новой страницы вставляем в DOM счётчик
    $(document).on 'page:load', @insert
    # при прочтении комментов, декрементим счётчик
    $(document).on 'appear', @appear
    # при добавление блока о новом комментарии/топике делаем инкремент
    $(document).on 'faye:added', @increment_counter
    # при загрузке контента аяксом, fayer-loader'ом, postloader'ом, при перезагрузке страницы
    $(document).on 'page:load page:restore faye:loaded ajax:success postloader:success', @refresh

    # явное указание о скрытии
    $(document).on 'disappear', @decrement_counter
    # при добавление блока о новом комментарии/топике делаем инкремент
    $(document).on 'reappear', @increment_counter

    # смещение вверх-вниз блока уведомлялки
    @max_top = 31
    @scroll = $(window).scrollTop()
    @block_top = 0

    $(window).scroll (e) =>
      @scroll = $(window).scrollTop()
      if @scroll <= @max_top || (@scroll > @max_top && @block_top != 0)
        @move()

    @insert()
    @move()
    @refresh()

  # вставка в DOM счётчика
  insert: =>
    alt = I18n.t('frontend.lib.comments_notifier.number_of_unread_comments')
    @$notifier = $("<div class='b-comments-notifier' style='display: none;' alt='#{alt}'></div>")
      .appendTo(document.body)
      .on 'click', =>
        $first_unread = $("#{@comment_selector}, #{@faye_loader_selector}").first()
        $.scrollTo $first_unread

    @scroll = $(window).scrollTop()

  # пересчёт значения счётчика
  refresh: =>
    delay().then =>
      $comment_new = $(@comment_selector)
      $faye_loader = $(@faye_loader_selector)
      count = $comment_new.length

      $faye_loader.each ->
        count += $(@).data('ids').length

      @update count

  # установление значение счётчика
  update: (count) ->
    @current_counter = count

    if count > 0
      @$notifier.show().html count
    else
      @$notifier.hide()

  # уменьшение счётчика по исчезанию элементов
  appear: (e, $appeared, by_click) =>
    $nodes = $appeared
      .filter("#{@comment_selector}, #{@faye_loader_selector}")
      .not -> $(@).data 'disabled'

    @update @current_counter - $nodes.length

  # уменьшение счётчика по исчезанию элемента
  decrement_counter: =>
    @update @current_counter - 1

  # увеличение счётчика по появлению новых элементов
  increment_counter: =>
    @update @current_counter + 1

  # смещение счётчика вслед за скролом страницы
  move: ->
    @block_top = [0, @max_top - @scroll].max()
    @$notifier.css top: @block_top
