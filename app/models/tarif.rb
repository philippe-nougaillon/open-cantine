# encoding: utf-8
require 'concerns/logmodule.rb'

class Tarif < ActiveRecord::Base
	include LogModule

	attr_protected :id

	belongs_to :ville

	validates_numericality_of :RepasP, :GarderieAMP, :GarderiePMP, :CentreAMP, :CentrePMP, :CentreAMPMP, :Etude
	validates_presence_of :memo
 
end
