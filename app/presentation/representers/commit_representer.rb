# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module CodePraise
  module Representer
    # Represents essential Commit information for API output
    # USAGE:
    #   Commit = Database::MemberOrm.find(1)
    #   Representer::Member.new(member).to_json
    class Commit < Roar::Decorator
      include Roar::JSON

      property :sha
      property :commit_date
    end
  end
end
