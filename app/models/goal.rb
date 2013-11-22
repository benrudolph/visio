class Goal < ActiveRecord::Base
  extend Parameter
  attr_accessible :name

  self.primary_key  = :id
  has_many :indicator_data

  has_and_belongs_to_many :ppgs, :uniq => true
  has_and_belongs_to_many :rights_groups, :uniq => true
  has_and_belongs_to_many :operations, :uniq => true
end
