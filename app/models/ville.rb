# encoding: utf-8

require 'concerns/logmodule.rb'

class Ville < ActiveRecord::Base
 	include LogModule

	validates_presence_of :nom, :email, :message => "est requis..."
	validates_uniqueness_of :email, :message => "est déjà utilisé..."
	validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i , :message => " non valide..."

	has_many :users, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :tarifs, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :classrooms, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :vacances, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :familles, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :factures, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :factureChronos, :foreign_key => "mairie_id",  :dependent => :destroy
	has_many :paiements, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :enfants, :foreign_key => "mairie_id", through: :familles
	has_many :logs, through: :users

	def readable_tel
    	tel.gsub /\d\d(?=\d)/, '\\0 '
  	end

end
