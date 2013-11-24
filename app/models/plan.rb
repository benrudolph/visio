class Plan < ActiveRecord::Base
  extend Parameter
  attr_accessible :name, :operation_name, :year

  self.primary_key = :id
  has_and_belongs_to_many :ppgs, :uniq => true
  has_and_belongs_to_many :indicators, :uniq => true
  has_and_belongs_to_many :outputs, :uniq => true
  has_and_belongs_to_many :problem_objectives, :uniq => true
  has_and_belongs_to_many :rights_groups, :uniq => true
  has_and_belongs_to_many :goals, :uniq => true

  has_many :indicator_data

  belongs_to :operation

  def to_jbuilder(options = {})
    Jbuilder.new do |json|
      json.extract! self, :name, :operation_name, :year

      if options[:include] && options[:include][:counts] && options[:include][:counts]
        json.indicator_count self.indicators.count
        json.goal_count self.goals.count
        json.ppg_count self.ppgs.count
        json.output_count self.outputs.count
        json.problem_objective_count self.problem_objectives.count
      end
    end
  end

  def as_json(options = {})
    to_jbuilder(options).attributes!
  end
end
