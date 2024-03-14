# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'


module CodePraise
  module Entity
    class Appraisal < Dry::Struct
      include Dry.Types

      attribute :id,           Strict::String
      attribute :project_name, Strict::String
      attribute :owner_name,   Strict::String      
      attribute :commit_year,   Strict::Integer
      attribute :sha,          Strict::String.optional
      attribute :appraisal,    Strict::Hash.optional
      attribute :state,        Strict::String.optional
      attribute :request_id,   Coercible::String.optional
      attribute :created_at,   Strict::Time
      attribute :updated_at,   Strict::Time

      def appraised?
        appraisal
      end

      def content
        appraisal
      end
    end
  end
end