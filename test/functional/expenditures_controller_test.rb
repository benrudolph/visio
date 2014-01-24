require 'test_helper'

class ExpendituresControllerTest < ActionController::TestCase
  def setup
    @s = strategies(:one)

    @plans = [plans(:one)]
    @ppgs = [ppgs(:one)]
    @rights_groups = [rights_groups(:one)]
    @goals = [goals(:one)]
    @pos = [problem_objectives(:one)]
    @outputs = [outputs(:one)]
    @indicators = [indicators(:one)]

    @so = strategy_objectives(:one)

    @so.goals << @goals
    @so.problem_objectives << @pos
    @so.outputs << @outputs
    @so.indicators << @indicators

    @s.plans << @plans
    @s.ppgs << @ppgs
    @s.rights_groups << @rights_groups

    @s.strategy_objectives << @so
  end

  test "should get no expenditure data" do
    get :synced

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 0, r["new"].length
    assert_equal 0, r["updated"].length
    assert_equal 0, r["deleted"].length
  end

  test "should get one new expenditure data" do
    datum = Expenditure.new()
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.output = outputs(:one)
    datum.save

    get :synced, { :strategy_id => @s.id }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r["new"].length
    assert_equal 0, r["updated"].length
    assert_equal 0, r["deleted"].length
  end
end

