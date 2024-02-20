# frozen_string_literal: true

require_relative 'members'

module CodePraise
  module Repository
    class Commits
      def self.all
        Database::CommitOrm.all.map { |db_commit| rebuild_entity(db_commit) }
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record
        Entity::Commit.new(
          id: db_record.id,
          sha: db_record.sha,
          commit_date: db_record.commit_date
        )
      end

      def self.rebuild_many(db_records)
        db_records.map do |db_member|
          Commits.rebuild_entity(db_member)
        end
      end

      def self.find_or_create(entity)
        Database::CommitOrm.find_or_create(entity.to_attr_hash)
      end
    end
  end
end