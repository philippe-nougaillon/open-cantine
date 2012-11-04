# encoding: utf-8

class Ville < ActiveRecord::Base

	attr_protected :id
	
	validates_presence_of :nom, :email, :message => " requis !"
	validates_uniqueness_of :email, :message => " déjà utilisée par un compte openCantine..."
        validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i , :message => " non valide..."

	has_many :users, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :tarifs, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :classrooms, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :vacances, 	:foreign_key => "mairie_id",  :dependent => :destroy

	has_many :familles, 	:foreign_key => "mairie_id",  :dependent => :destroy

	has_many :factures, 	:foreign_key => "mairie_id",  :dependent => :destroy
	has_many :factureChronos, :foreign_key => "mairie_id",  :dependent => :destroy

	has_many :paiements, 	:foreign_key => "mairie_id",  :dependent => :destroy


  def readable_tel
    tel.gsub /\d\d(?=\d)/, '\\0 '
  end


end
