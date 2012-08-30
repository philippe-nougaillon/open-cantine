class Mairie < ActiveRecord::Base
  has_many :tarifs
  has_many :classrooms
  has_many :familles
  has_many :factures
  has_many :paiements
  has_many :users
  has_many :facture_chronos
end
