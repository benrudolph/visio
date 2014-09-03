module AmountHelpers
  def synced_models(ids = {}, synced_date = nil, limit = nil, where = {})

    synced_amounts = {}
    conditions = []

    # TODO Check accuracy of using problem_objective and output with OR
    conditions << "operation_id IN ('#{ids[:operation_ids].join("','")}')" if ids[:operation_ids]
    conditions << "plan_id IN ('#{ids[:plan_ids].join("','")}')" if ids[:plan_ids]
    conditions << "ppg_id IN ('#{ids[:ppg_ids].join("','")}')" if ids[:ppg_ids]
    conditions << "goal_id IN ('#{ids[:goal_ids].join("','")}')" if ids[:goal_ids]
    conditions << "problem_objective_id IN ('#{ids[:problem_objective_ids].join("','")}')" if ids[:problem_objective_ids]
    conditions << "(output_id IN ('#{ids[:output_ids].join("','")}') OR output_id IS NULL)" if ids[:output_ids]

    query_string = conditions.join(' AND ')

    amounts = self.loaded

    if synced_date
      synced_amounts[:new] = amounts.where("#{query_string} AND
        created_at >= :synced_date AND
        is_deleted = false", { :synced_date => synced_date })
          .where(where).limit(limit)
      synced_amounts[:updated] = amounts.where("#{query_string} AND
        created_at < :synced_date AND
        updated_at >= :synced_date AND
        is_deleted = false", { :synced_date => synced_date })
          .where(where).limit(limit)
      synced_amounts[:deleted] = amounts.where("#{query_string} AND
        updated_at >= :synced_date AND
        is_deleted = true", { :synced_date => synced_date })
          .where(where).limit(limit)
    else
      synced_amounts[:new] = amounts.where("#{query_string} AND is_deleted = false")
        .where(where).limit(limit)
      synced_amounts[:updated] = synced_amounts[:deleted] = self.limit(0)
    end

    return synced_amounts
  end

  def synced_models_optimized(ids = {})
    conditions = []

    # TODO Check accuracy of using problem_objective and output with OR
    conditions << "operation_id IN ('#{ids[:operation_ids].join("','")}')" if ids[:operation_ids]
    conditions << "plan_id IN ('#{ids[:plan_ids].join("','")}')" if ids[:plan_ids]
    conditions << "ppg_id IN ('#{ids[:ppg_ids].join("','")}')" if ids[:ppg_ids]
    conditions << "goal_id IN ('#{ids[:goal_ids].join("','")}')" if ids[:goal_ids]
    conditions << "problem_objective_id IN ('#{ids[:problem_objective_ids].join("','")}')" if ids[:problem_objective_ids]
    conditions << "(output_id IN ('#{ids[:output_ids].join("','")}') OR output_id IS NULL)" if ids[:output_ids]

    query_string = conditions.join(' AND ')

    # Need to include Strategy Objective ids
    sql = "select array_to_json(array_agg(row_to_json(t)))
      from (
        select #{self.table_name}.*,
          (
            select array_to_json(array_agg(row_to_json(d)::json->'strategy_objective_id'))
            from (

              select strategy_objective_id
              from goals_strategy_objectives
              where goal_id = #{self.table_name}.goal_id

              INTERSECT

              select strategy_objective_id
              from problem_objectives_strategy_objectives
              where problem_objective_id = #{self.table_name}.problem_objective_id

              INTERSECT

              select strategy_objective_id
              from outputs_strategy_objectives
              where output_id = #{self.table_name}.output_id

            ) as d
        ) as strategy_objective_ids
      from #{self.table_name}
      ) t
      where #{query_string}"
    ActiveRecord::Base.connection.execute(sql)

  end
end
