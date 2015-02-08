module Routing
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    def default_url_options
      host = if Rails.env.test?
        'test.host'
      else
        if Draper::ViewContext.current.request.host == 'test.host'
          Site::DOMAIN
        else
          Draper::ViewContext.current.request.host
        end
      end

      { host: host }
    end
  end

  def topic_url topic, format = nil
    if topic.kind_of?(User)
      profile_url topic
    elsif topic.kind_of?(ContestComment) || topic.news? || topic.review?
      section_topic_url id: topic, section: topic.section, linked: nil, format: format
    else
      section_topic_url id: topic, section: topic.section, linked: topic.linked, format: format
    end
  end
end
