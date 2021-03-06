require 'test_helper'

class NarrativesControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  def setup
    @s = strategies(:one)

    @operations = [operations(:one)]
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

    @s.operations << @operations
    @s.plans << @plans
    @s.ppgs << @ppgs
    @s.rights_groups << @rights_groups

    @s.strategy_objectives << @so

    @user = users(:one)
    @user.save

    sign_in @user
  end

  test "should block access for user" do
    sign_out @user

    get :index

    assert_response :redirect

  end


  test "should get no narrative data" do
    get :index

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 0, r.length
  end

  test "should get one new narrative data" do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.output = outputs(:one)
    datum.save

    get :index, { :strategy_id => @s.id }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r.length
  end

  test "should get one new narrative data - optimize" do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.output = outputs(:one)
    datum.save

    get :index, { :strategy_id => @s.id, :optimize => true }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r.length
  end

  test "should get zero new narrative data because deleted - optimize" do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.output = outputs(:one)
    datum.is_deleted = true
    datum.save

    get :index, { :strategy_id => @s.id, :optimize => true }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 0, r.length
  end


  test "should get one new narrative data - no output" do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.save

    get :index, { :strategy_id => @s.id }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r.length

  end

  test 'limit - should get one narrative' do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.save

    datum2 = Narrative.new()
    datum2.id = 'def'
    datum2.operation = operations(:one)
    datum2.plan = plans(:one)
    datum2.ppg = ppgs(:one)
    datum2.goal = goals(:one)
    datum2.problem_objective = problem_objectives(:one)
    datum2.save

    post :index, { :filter_ids => {
        :operation_ids => [datum.operation_id],
        :problem_objective_ids => [datum.problem_objective_id],
        :output_ids => [datum.output_id],
      }, :optimize => true, :limit => 1 }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r.length
  end

  test "should get one new narrative data - filter_ids - optimize" do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.output = outputs(:one)
    datum.save

    post :index, { :filter_ids => {
        :operation_ids => [datum.operation_id],
        :problem_objective_ids => [datum.problem_objective_id],
        :output_ids => [datum.output_id],
      } }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r.length
  end

  test "should get one new narrative data - filter_ids" do
    datum = Narrative.new()
    datum.id = 'abc'
    datum.operation = operations(:one)
    datum.plan = plans(:one)
    datum.ppg = ppgs(:one)
    datum.goal = goals(:one)
    datum.problem_objective = problem_objectives(:one)
    datum.output = outputs(:one)
    datum.save

    post :index, { :optimize => true, :filter_ids => {
        :operation_ids => [datum.operation_id],
        :ppg_ids => [datum.ppg_id],
        :goal_ids => [datum.goal_id],
        :problem_objective_ids => [datum.problem_objective_id],
        :output_ids => [datum.output_id],
      } }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 1, r.length
  end

  test "should get total characters" do

    get :total_characters, { :filter_ids => { :operation_ids => ['BEN', 'LISA'] } }

    assert_response :success

    r = JSON.parse(response.body)

    assert_equal 7, r['total_characters'].to_i

  end

end

