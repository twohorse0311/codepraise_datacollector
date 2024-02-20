# frozen_string_literal: false

require 'dry-types'
require 'dry-struct'

require_relative 'member'

module CodePraise
  module Entity
    #  Aggregate root for projects
    class Project < Dry::Struct
      include Dry.Types

      MAX_SIZE_KB = 1000

      attribute :id,            Integer.optional
      attribute :origin_id,     Strict::Integer
      attribute :name,          Strict::String
      attribute :size,          Strict::Integer
      attribute :ssh_url,       Strict::String
      attribute :http_url,      Strict::String
      attribute :owner,         Member
      attribute :contributors,  Strict::Array.of(Member)
      attribute :commits, Strict::Array.of(Commit).optional

      def fullname
        "#{owner.username}/#{name}"
      end

      def too_large?
        return false
        # size > MAX_SIZE_KB
      end

      def to_attr_hash
        # to_hash.reject { |key, _| %i[id owner contributors].include? key }
        to_hash.except(:id, :owner, :contributors, :commits)
      end
    end
  end
end
