class Versions::CollectionVersion < Version
  def apply_changes
    item.class.transaction do
      item_diff.each do |(association, (_old_collection, new_collection))|
        item.send(association).delete_all
        import_collection association, new_collection
      end
      item.touch
    end
  end

  def rollback_changes
    item.class.transaction do
      item_diff.each do |(association, (old_collection, _new_collection))|
        item.send(association).delete_all
        import_collection association, old_collection
      end
      item.touch
    end
  end

private

  def import_collection association, collection
    klass = association.classify.constantize
    models = collection.map { |item| klass.new fix(item) }

    klass.import models
  end

  def fix hash
    hash.each_with_object({}) do |(key, value), memo|
      next if key == 'id'
      next if value.blank?

      memo[key] =
        if key.match?(/^[\w_]+_at$/) && value.present?
          Time.zone.parse(value)
        else
          value
        end
    end
  end
end
