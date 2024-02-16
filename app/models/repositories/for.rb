# frozen_string_literal: true

require_relative 'members'
require_relative 'projects'

module CodePraise
  module Repository
    # Finds the right repository for an entity object or class
    module For
      ENTITY_REPOSITORY = {
        Entity::Project => Projects,
        Entity::Member => Members,
        Entity::Commit => Commits
      }.freeze

      def self.klass(entity_klass)
        ENTITY_REPOSITORY[entity_klass]
      end

      def self.entity(entity_object)
        ENTITY_REPOSITORY[entity_object.class]
      end
    end
  end
end