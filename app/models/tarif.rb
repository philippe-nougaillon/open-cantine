class Tarif < ActiveRecord::Base

	attr_protected :id

	belongs_to :ville

	validates_numericality_of :RepasP, :GarderieAMP, :GarderiePMP, :CentreAMP, :CentrePMP, :CentreAMPMP, :Etude
	validates_presence_of :memo
 
end
