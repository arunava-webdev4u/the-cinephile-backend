class DefaultList < List
    validates :name, inclusion: {
        in: [ "watchlist", "watched", "favourite_movies", "favourite_tv_Shows" ],
        message: "must be one of the predefined default list names"
    }

    # Override methods to prevent any kind of Write operation
    def can_be_created?
        false
    end

    def can_be_deleted?
        false
    end

    def can_be_updated?
        false
    end

  # Override methods to prevent any kind of Write operation
  # def destroy
  #     false
  # end
  # def destroy!
  #     raise ActiveRecord::RecordNotDestroyed, "Default lists cannot be deleted"
  # end
  # def update(attributes)
  #     false
  # end
  # def update!(attributes)
  #     raise ActiveRecord::RecordNotSaved, "Default lists cannot be updated"
  # end
  # def update_attribute(name, value)
  #     false
  # end
  # def update_attributes(attributes)
  #     false
  # end
  # def update_attributes!(attributes)
  #     raise ActiveRecord::RecordNotSaved, "Default lists cannot be updated"
  # end
end
