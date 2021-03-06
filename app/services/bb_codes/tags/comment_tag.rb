class BbCodes::Tags::CommentTag
  include Singleton

  REGEXP = %r{
    \[comment=(?<comment_id>\d+) (?<quote>\ quote)?\]
      (?<text> .*? )
    \[/comment\]
  }mix

  def format text
    text.gsub(REGEXP) do
      comment_to_html(
        $LAST_MATCH_INFO[:comment_id],
        $LAST_MATCH_INFO[:text],
        $LAST_MATCH_INFO[:quote].present?
      )
    end
  end

private

  def comment_to_html comment_id, text, is_quoted
    user = Comment.find_by(id: comment_id)&.user if is_quoted || text.blank?
    author_name = extract_author user, text, comment_id
    css_classes = [
      'bubbled',
      ('b-user16' if is_quoted)
    ].compact.join(' ')

    "[url=#{comment_url(comment_id)} #{css_classes}]" +
      author_html(is_quoted, user, author_name) +
      '[/url]'
  end

  def comment_url comment_id
    UrlGenerator.instance.comment_url comment_id
  end

  def author_html is_quoted, user, author_name
    if is_quoted
      quoteed_author_html user, author_name
    else
      "@#{author_name}"
    end
  end

  def quoteed_author_html user, author_name
    return "<span>#{author_name}</span>" unless user&.avatar&.present?

    <<-HTML.squish
      <img
        src="#{user.avatar_url 16}"
        srcset="#{user.avatar_url 32} 2x"
        alt="#{author_name}"
      /><span>#{author_name}</span>
    HTML
  end

  def extract_author user, text, comment_id
    ERB::Util.h(
      (text if text.present?) || user&.nickname || comment_id
    )
  end
end
