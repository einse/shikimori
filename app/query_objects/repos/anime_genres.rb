class Repos::AnimeGenres < Repos::RepositoryBase
  def find_mal_id mal_id
    collection.values.find { |genre| genre.mal_id == mal_id } ||
      (reset && collection.values.find { |genre| genre.mal_id == mal_id }) ||
      raise(ActiveRecord::RecordNotFound)
  end

private

  def scope
    Genre.where kind: :anime
  end
end