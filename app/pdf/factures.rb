class FacturePdf < Prawn::Document
     
  def initialize(facture, view)
    super()
	@facture = facture

    text "This is an order invoice"
  end


end


