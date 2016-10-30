class Style < ActiveRecord::Base
  OWNER_TYPES = [User.name]

  belongs_to :owner, polymorphic: true, inverse_of: :style

  validates :owner, presence: true
  validates :owner_type, inclusion: { in: OWNER_TYPES }

  PAGE_BORDER_CSS = <<-CSS.strip.gsub(/^ +/, '')
    /* [generated=page_border] */
    .l-page:before, .l-page:after, .l-footer:before, .l-footer:after { display: %s; }
    /* [/generated] */
  CSS

  PAGE_BACKGROUND_COLOR_CSS = <<-CSS.strip.gsub(/^ +/, '')
    /* [generated=page_background_color] */
    .l-page { background-color: rgba(%d, %d, %d, %d); }
    /* [/generated] */
  CSS

  BODY_BACKGROUND_CSS = <<-CSS.strip.gsub(/^ +/, '')
    /* [generated=body_background] */
    body { background: %s; }
    /* [/generated] */
  CSS

  def compiled_css
    sanitize(camo_images(strip_comments(css)))
  end

private

  def camo_images css
    css.gsub(BbCodes::UrlTag::URL) do
      UrlGenerator.instance.camo_url $LAST_MATCH_INFO[:url]
    end
  end

  def strip_comments css
    css.gsub(%r{/\* .*? \*/[\n\r]*}mix, '')
  end

  def sanitize css
    Misc::SanitizeEvilCss.call(css).strip.gsub(/;;+/, ';').strip
  end
end