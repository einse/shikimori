class AchievementsController < ShikimoriController
  before_action do
    og page_title: i18n_i('Achievement', :other)
  end

  def index
  end

  # rubocop:disable AbcSize
  def show
    @collection = NekoRepository.instance
      .select { |v| v[:neko_id] == params[:id].to_sym }
      .sort_by(&:sort_criteria)

    raise ActiveRecord::RecordNotFound if @collection.empty?

    @topic_resource = build_topic_resource @collection.first.topic_id

    og page_title: @collection.first.neko_name
    breadcrumb i18n_i('Achievement', :other), achievements_url
  end
  # rubocop:enable AbcSize

private

  def build_topic_resource topic_id
    return unless ru_host?
    return unless topic_id

    topic = Topic.find_by id: topic_id

    if topic
      OpenStruct.new(
        preview_topic_view: Topics::TopicViewFactory.new(true, false).build(
          topic
        )
      )
    end
  end
end
