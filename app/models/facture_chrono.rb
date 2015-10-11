class FactureChrono < ActiveRecord::Base
  
  belongs_to :mairie

  validates_numericality_of :prochain

end
