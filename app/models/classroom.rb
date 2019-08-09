# encoding: utf-8
require 'concerns/logmodule.rb'

class Classroom < ApplicationRecord
	include LogModule

	belongs_to :ville
	has_many :enfants

	validates_presence_of :nom, :referant
end
