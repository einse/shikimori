class PersonRole < ApplicationRecord
  belongs_to :anime, touch: true
  belongs_to :manga, touch: true
  belongs_to :character, touch: true
  belongs_to :person, touch: true

  scope :main, -> {
    where(role: 'Main')
      .where.not(character_id: 0)
  }
  scope :supporting, -> { where.not(role: 'Main', character_id: 0) }

  scope :people, -> {
    includes(:person)
      .where.not(person_id: 0, people: { name: '' })
  }
  scope :directors, -> {
    people.
      where "role ilike '%Director%' or role ilike '%Original Creator%' or role ilike '%Story & Art%' or role ilike '%Story%' or role ilike '%Art%'"
  }

  def entry
    anime || manga
  end
end
