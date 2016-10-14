# encoding: utf-8

require 'prawn/table'

class FacturePdf < Prawn::Document

  include ActionView::Helpers::NumberHelper
   

  def initialize(ids)
      super(:page_size => "A4", :top_margin => 5, :bottom_margin => 5)

      ids.each_with_index do | id,index |
        @facture = Facture.find(id)
        @mairie = @facture.ville

        facture_content
        start_new_page if (index < ids.count - 1)
      end
  end

  def facture_content
	if @mairie.logo_url	
		if @mairie.logo_url.empty?
		   logo_url =  "#{Rails.root}/public/images/school.png" 
	       image logo_url, :height => 40
		else
		   logo_url =  @mairie.logo_url 
	       image open(logo_url, :allow_redirections => :safe), :height => 40
		end
		move_down 10
	else
		move_down 20
	end

    text @mairie.nom,  :size => 17, :style => :bold
	move_down 10

	text @mairie.adr,  :size => 14
	text "#{@mairie.cp} #{@mairie.ville}", :size => 14
	move_down 20

	text @mairie.readable_tel, :size => 12
	text @mairie.email, :size => 12
	move_down 30

	text "#{@facture.famille.civilité} #{@facture.famille.nom.to_s.upcase}", :indent_paragraphs => 300, :size => 14, :style =>  :bold
	move_down 10

	text @facture.famille.adresse, :indent_paragraphs => 300, :size => 12
	text "#{@facture.famille.cp} #{@facture.famille.ville}", :indent_paragraphs => 300, :size => 12

	move_down 30
	text "#{@mairie.ville}, le #{@facture.date.to_date.to_s(:fr)}", :indent_paragraphs => 300, :size => 14

	move_down 30
	text "Facture: #{@facture.ref }", :size => 14, :style => :bold

	move_down 50
	
	items = [["Désignation","Qté","Prix Unitaire","Total"]] 
	
	@facture.facture_lignes.each do |item|
		if item.montant != 0 #cacher ligne sans montant
			if item.prix
				@total_ligne = item.prix * item.qte
			end
    		items +=[[
					item.texte.gsub(";", ""), item.qte, 
					number_to_currency(item.prix, :locale => 'fr'),
					#number_to_currency(item.montant, :locale => 'fr')
					number_to_currency(@total_ligne, :locale => 'fr')
				]]
		end
	end

	items += [["","","",""]]
	items += [["TOTAL FACTURE","","", number_to_currency(@facture.montant, :locale => "fr") ]]

	table(items, :row_colors => ["F0F0F0", "FFFFFF"],  :width => 550) do
		self.header = true
		columns(0).align = :left
		columns(0).font_style = :bold
		columns(0).size = 10

		columns(1).align = :right
		columns(1).width = 50
		columns(1).size = 10

		columns(2).align = :right
		columns(2).width = 70
		columns(2).size = 10

		columns(3).align = :right
		columns(3).width = 70
		columns(3).size = 10
		columns(3).font_style = :bold
	end
	move_down 20

	if @facture.SoldeFamille and @mairie.id != 1 # pas de solde pour Attainville
		text "Avant cette facture, vous deviez : #{number_to_currency(@facture.SoldeFamille, :locale => 'fr')}", :size => 12
		text "Votre nouveau solde dû est maintenant de : #{number_to_currency((@facture.SoldeFamille + @facture.montant), :locale => 'fr')}", :size => 12, :style => :bold	
	end
	move_down 25

	if @facture.footer
		text @facture.footer, size:10, :style => :bold
	end

  end

end
