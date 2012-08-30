class FactureLigne < ActiveRecord::Base

  attr_protected :id

  belongs_to :facture
  
end
