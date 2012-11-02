class FacturePdf < Prawn::Document
     
  def initialize(facture, mairie, view)
    super()
	@mairie = mairie
	@facture = facture

    text @facture.mairie.nom,  :size => 30, :style => :bold
  end


end


