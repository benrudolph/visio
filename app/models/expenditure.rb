class Expenditure < ActiveRecord::Base
  include SyncableModel

  attr_accessible :budget_type, :scenario, :amount, :plan_id, :ppg_id, :goal_id, :output_id,
    :problem_objective_id, :year

  belongs_to :plan
  belongs_to :ppg
  belongs_to :goal
  belongs_to :output
  belongs_to :problem_objective

  def self.loaded
    includes({ :goal => :strategy_objectives,
               :problem_objective => :strategy_objectives,
               :output => :strategy_objectives})
  end

  def self.synced_models(ids = {}, synced_date = nil, limit = nil, where = {})

    synced_expenditures = {}

    # TODO Check accuracy of using problem_objective and output with OR
    query_string = "plan_id IN ('#{ids[:plan_ids].join("','")}') AND
      ppg_id IN ('#{(ids[:ppg_ids] || []).join("','")}') AND
      goal_id IN ('#{(ids[:goal_ids] || []).join("','")}') AND
      problem_objective_id IN ('#{(ids[:problem_objective_ids] || []).join("','")}') AND
      output_id IN ('#{(ids[:output_ids] || []).join("','")}')"

    expenditures = Expenditure.loaded

    if synced_date
      synced_expenditures[:new] = expenditures.where("#{query_string} AND
        created_at >= :synced_date AND
        is_deleted = false", { :synced_date => synced_date })
          .where(where).limit(limit)
      synced_expenditures[:updated] = expenditures.where("#{query_string} AND
        created_at < :synced_date AND
        updated_at >= :synced_date AND
        is_deleted = false", { :synced_date => synced_date })
          .where(where).limit(limit)
      synced_expenditures[:deleted] = expenditures.where("#{query_string} AND
        updated_at >= :synced_date AND
        is_deleted = true", { :synced_date => synced_date })
          .where(where).limit(limit)
    else
      synced_expenditures[:new] = expenditures.where("#{query_string} AND is_deleted = false")
        .where(where).limit(limit)
      synced_expenditures[:updated] = synced_expenditures[:deleted] = Budget.limit(0)
    end

    return synced_expenditures
  end

  def to_jbuilder(options = {})
    Jbuilder.new do |json|
      json.extract! self, :id, :budget_type, :scenario, :amount, :plan_id, :ppg_id, :goal_id, :output_id,
        :problem_objective_id, :year

      strategy_objective_ids = self.goal.strategy_objective_ids &
        self.problem_objective.strategy_objective_ids &
        self.output.strategy_objective_ids

      json.strategy_objective_ids strategy_objective_ids
    end
  end

  def as_json(options = {})
    to_jbuilder(options).attributes!
  end
end
