class Classroom < ActiveRecord::Base

	attr_protected :id

	belongs_to :ville
	has_many :enfants

	validates_presence_of :nom, :referant

end
