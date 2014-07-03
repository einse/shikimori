class CosplayImage < ActiveRecord::Base
  PositionStep = 10

  belongs_to :gallery, class_name: 'CosplayGallery', foreign_key: :cosplay_gallery_id

  has_attached_file :image,
    styles: { preview: "178x534>" },
    url: "/images/cosplay_image/:style/:id.:extension",
    path: ":rails_root/public/images/cosplay_image/:style/:id.:extension",
    default_url: '/images/missing_:style.jpg'

  validates :image, attachment_content_type: { content_type: /\Aimage/ }
end
