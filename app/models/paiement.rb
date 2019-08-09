require 'concerns/logmodule.rb'

class Paiement < ApplicationRecord
  include LogModule
  
  belongs_to :famille
  belongs_to :ville

  validates_presence_of :date, :montant, :montantGarderie, :montantCantine, :famille_id
  
end
