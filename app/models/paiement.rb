require 'concerns/logmodule.rb'

class Paiement < ActiveRecord::Base
  include LogModule
  
  belongs_to :famille
  belongs_to :ville

  validates_presence_of :date, :montant, :montantGarderie, :montantCantine, :famille_id
  
end
