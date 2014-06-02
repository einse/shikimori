require_dependency 'genre'
require_dependency 'studio'
require_dependency 'publisher'

# TODO: класс нуждается в рефакторинге
class UserListsController < UsersController
  AnimeType = 1
  MangaType = 2

  before_action :set_params

  alias_method :users_show, :show
  helper_method :anime?

  # отображение аниме листа пользователяс с наложенными фильтрами
  def show
    unless params[:order]
      redirect_to ani_manga_list_url(params.merge(order: user_signed_in? ? current_user.preferences.default_sort : UserPreferences::DefaultSort))
      return
    end
    current_user.preferences.update_sorting(params[:order]) if user_signed_in?

    @params_type = params[:type]
    @page = (params[:page] || 1).to_i
    @limit = 400

    @klass = params[:list_type].capitalize.constantize

    # полный список
    full_list = Rails.cache.fetch(user_list_cache_key) do
      UserListQuery.new(@klass, @user, params.clone.merge(with_censored: true)).fetch
    end
    @list = prepare_list(full_list, @page, @limit)
    @add_postloader = @list.any? && (@list.keys.last != full_list.keys.last ||
        @list[@list.keys.last][:entries].size != full_list[full_list.keys.last].size)

    unless @add_postloader
      @total_stats = full_list.map {|k,v| list_stats(v, false) }.inject({}) do |rez,data|
        data.each do |k,v|
          rez[k] ||= 0
          rez[k] += v
        end
        rez
      end
      @total_stats[:days] = @total_stats[:days].round(2) if @total_stats[:days]
      @total_stats.delete_if {|k,v| !(v > 0) }
    end

    @page_title = UsersController.profile_title("Список #{anime? ? 'аниме' : 'манги'}", @user)
    params[:type] = "#{params[:list_type]}list"

    respond_to do |format|
      format.json do
        # первую страницу рисуем как обычно
        if @page == 1
          render json: {
            content: render_to_string(partial: 'ani_manga_list', layout: false, formats: :html),
            title_page: @page_title
          }
        # а все остальные лишь таблицей со списком
        else
          render json: {
            content: render_to_string(partial: 'user_lists/ani_manga_list_content', layout: false, formats: :html)
          }
        end
      end
      format.html { users_show }
    end
  end

  def edit
    raise Forbidden unless user_signed_in? && @user.can_be_edited_by?(current_user)
    @user_rate = @user.anime_rates.find_by(id: params[:user_rate_id]) || @user.manga_rates.find(params[:user_rate_id])
    render 'api/v1/user_rates/edit'
  end

  # история изменения списка аниме/манги
  def history
    limit = 90
    @page = (params[:page] || 1).to_i

    history = @user
      .all_history
      .offset(limit * (@page-1))
      .limit(limit + 1)
      .to_a

    @add_postloader = history.size > limit
    history = history.take(limit) if history.size > limit
    history.map!(&:decorate)

    @history = history.group_by do |v|
      today = DateTime.parse(Date.today.to_s)
      updated_at = v.updated_at.to_datetime
      if today < updated_at then 'Сегодня'
      elsif today - 1.day < updated_at then 'Вчера'
      elsif today - 1.week < updated_at then 'В течение недели'
      elsif today - 2.weeks < updated_at then 'Две недели назад'
      elsif today - 3.weeks < updated_at then 'Три недели назад'
      elsif today - 4.weeks < updated_at then 'Четыре недели назад'
      elsif today - 2.months < updated_at then 'Месяц назад'
      elsif today - 3.months < updated_at then 'Два месяца назад'
      elsif today - 4.months < updated_at then 'Три месяца назад'
      elsif today - 5.months < updated_at then 'Четыре месяца назад'
      elsif today - 6.months < updated_at then 'Пять месяцев назад'
      elsif today - 9.months < updated_at then 'Более полугода назад'
      elsif today - 1.year < updated_at then 'Почти год назад'
      elsif today - 2.year < updated_at then 'Более года назад'
      else 'Совсем давно'
      end
    end

    @page_title = UsersController.profile_title('История', @user)
    users_show
  end

  # экспорт аниме листа
  def export
    raise Forbidden unless user_signed_in? && @user.can_be_edited_by?(current_user)
    type = params[:list_type]
    if type == 'anime'
      @klass = Anime
      @list = @user.anime_rates.includes(:anime)
    else
      @klass = Manga
      @list = @user.manga_rates.includes(:manga)
    end

    response.headers['Content-Description'] = 'File Transfer';
    response.headers['Content-Disposition'] = "attachment; filename=#{type}list.xml";
    render template: 'user_lists/export', formats: :xml
  end

  # импорт списка
  def list_import
    raise Unauthorized unless user_signed_in?

    klass = Object.const_get(params[:klass].capitalize)
    rewrite = params[:rewrite] == true || params[:rewrite] == '1'

    # в ситуации, когда через yql не получилось, можно попробовать вручную скачать список
    #if params[:mal_login].present?
      #params[:file] = open "http://myanimelist.net/malappinfo.php?u=#{params[:mal_login]}&status=all&type=#{params[:klass]}"
      #params[:list_type] = 'xml'
    #end

    parser = UserListParser.new klass
    importer = UserRatesImporter.new current_user, klass
    @added, @updated, @not_imported = importer.import(parser.parse(params), rewrite)

    if @added.size > 0 || @updated.size > 0
      current_user.touch
      UserHistory.create(
        user_id: current_user.id,
        action: UserHistoryAction.const_get("#{params[:list_type].to_sym == :mal || params[:list_type].to_sym == :xml ? 'Mal' : 'Ap'}#{klass.name}Import"),
        value: @added.size + @updated.size
      )
    end

    message = []

    if @added.size > 0
      items = klass.where(id: @added).select([:id, :name])
      if klass == Manga
        message << "В ваш список #{Russian.p(@added.size, 'импортирована', 'импортированы', 'импортированы')} #{@added.size} #{Russian.p(@added.size, 'манга', 'манги', 'манги')}:"
      else
        message << "В ваш список #{Russian.p(@added.size, 'импортировано', 'импортированы', 'импортированы')} #{@added.size} #{Russian.p(@added.size, 'аниме', 'аниме', 'аниме')}:"
      end
      message = message + items.sort_by {|v| v.name }.map {|v| "<a class=\"bubbled\" data-remote=\"true\" href=\"#{url_for(v)}\">#{v.name}</a>" }
      message << ''
    end

    if @updated.size > 0
      items = klass.where(id: @updated).select([:id, :name])
      if klass == Manga
        message << "В вашем списке #{Russian.p(@updated.size, 'обновлена', 'обновлены', 'обновлены')} #{@updated.size} #{Russian.p(@updated.size, 'манга', 'манги', 'манги')}:"
      else
        message << "В вашем списке #{Russian.p(@updated.size, 'обновлено', 'обновлены', 'обновлены')} #{@updated.size} #{Russian.p(@updated.size, 'аниме', 'аниме', 'аниме')}:"
      end
      message = message + items.sort_by {|v| v.name }.map {|v| "<a class=\"bubbled\" data-remote=\"true\" href=\"#{url_for(v)}\">#{v.name}</a>" }
      message << ''
    end

    if @not_imported.size > 0
      message << "Не удалось импортировать (распознать) #{@not_imported.size} #{klass == Manga ? Russian.p(@not_imported.size, 'мангу', 'манги', 'манг') : 'аниме'}, пожалуйста, добавьте их в свой список самостоятельно:"
      message = message + @not_imported.sort
    end
    message << "Ничего нового не импортировано." if message.empty?

    poster = BotsService.get_poster
    messages = message.each_slice(400).to_a.reverse
    messages.each_with_index do |message,index|
      message = ['(продолжение предыдущего сообщения)<br>'] + message if index != messages.size - 1
      Message.create!(
        from_id: poster.id,
        to_id: current_user.id,
        kind: MessageType::Private,
        body: message.join('<br>')
      )
      sleep(1)
    end

    redirect_to messages_url(type: :inbox)
  rescue Exception => e
    redirect_to :back, alert: 'Произошла ошибка. Возможно, некорректный формат файла.'
  end

private
  # подготовка списка
  def prepare_list full_list, page, limit
    list = truncate_list(full_list, @page, @limit)

    list.each do |status,data|
      list[status][:stats] = list_stats(full_list[status]) if list[status][:stats]
      list[status][:size] = full_list[status].size
    end

    list
  end

  # формирование содержимого нужной страницы из списка
  def truncate_list full_list, page, limit
    list = {}
    from = limit * (page - 1)
    to = from + limit

    # счётчик общего числа элементах
    i = 0
    # счётчик числа элементов в пределах группы
    j = 0

    full_list.each do |status,entries|
      j = 0

      entries.each do |entry|
        j += 1
        i += 1

        next if i <= from
        if i > to
          list[status].delete(:stats) if list[status]
          break
        end

        list[status] ||= { entries: [], stats: {}, index: j }
        list[status][:entries] << entry
      end
    end
    list
  end

  # аггрегированная статистика по данным
  def list_stats data, reduce=true
    stats = {
      tv: data.sum {|v| v.target.kind == 'TV' ? 1 : 0 },
      movie: data.sum {|v| v.target.kind == 'Movie' ? 1 : 0 },
      ova: data.sum {|v| v.target.kind == 'OVA' || v.target.kind == 'ONA' ? 1 : 0 },
      #ona: data.sum {|v| v.target.kind == 'ONA' ? 1 : 0 },
      special: data.sum {|v| v.target.kind == 'Special' ? 1 : 0 },
      music: data.sum {|v| v.target.kind == 'Music' ? 1 : 0 },
      manga: data.sum {|v| ['Manga', 'Manhwa', 'Manhua'].include?(v.target.kind) ? 1 : 0 },
      #manhwa: data.sum {|v| v.target.kind == 'Manhwa' ? 1 : 0 },
      #manhua: data.sum {|v| v.target.kind == 'Manhua' ? 1 : 0 },
      oneshot: data.sum {|v| v.target.kind == 'One Shot' ? 1 : 0 },
      novel: data.sum {|v| v.target.kind == 'Novel' ? 1 : 0 },
      doujin: data.sum {|v| v.target.kind == 'Doujin' ? 1 : 0 }
    }
    if anime?
      stats[:episodes] = data.sum(&:episodes)
    else
      stats[:chapters] = data.sum(&:chapters)
    end
    stats[:days] = (data.sum {|v| (anime? ? v.episodes : v.chapters) * v.target.duration }.to_f / 60 / 24).round(2)

    reduce ? stats.select { |k,v| v > 0 }.to_hash : stats
  end

  # ключ от кеша для списка пользователя
  def user_list_cache_key
    [
      :user_list,
      :v3,
      @user,
      Digest::MD5.hexdigest(request.url.gsub(/\.json$/, '').gsub(/\/page\/\d+/, '')),
      user_signed_in? ? current_user.preferences.russian_names? : false
    ]
  end

  def anime?
    params[:list_type] == 'anime'
  end

  def set_params
    if @current_user && @current_user.preferences.russian_names? && params[:order] == 'name'
      params[:order] = 'russian'
    end
  end
end
