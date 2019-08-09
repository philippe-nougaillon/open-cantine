class FactureChrono < ApplicationRecord
  
  belongs_to :mairie

  validates_numericality_of :prochain

end
