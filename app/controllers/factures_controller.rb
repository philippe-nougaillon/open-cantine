# encoding: utf-8

class FacturesController < ApplicationController

  layout :determine_layout

  before_filter :check, :except => ['index', 'new','new_all','create']

  def check
    unless Facture.find(:first, :conditions =>  [" id = ? AND mairie_id = ?", params[:id], session[:mairie]])
       redirect_to :action => 'index'
    end
  end

  def determine_layout
    if params[:action] == 'print'
      "printer"
    else
      "standard"
    end
  end

  # GET /factures
  # GET /factures.xml
  def index
    @factures = Facture.search(params[:search],params[:page], session[:mairie], params[:sort], params[:famille_id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => Facture.find_all_by_mairie_id(session[:mairie]).to_xml( :include => [:facture_lignes]) }
   end
  end

  # GET /factures/1
  # GET /factures/1.xml
  def show
	@images = get_etat_images
    @facture = Facture.find(params[:id])
    @famille = Famille.find(@facture.famille_id)
    @mairie  = Ville.find(session[:mairie])
    @prestations = Prestation.find_all_by_facture_id(@facture.id, :order => 'date, enfant_id')
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @facture }
      format.pdf do
	  	  filename = @facture.id.to_s
          render :pdf => filename ,
                 :template => 'factures/show.pdf.erb',
                 :layout => 'pdf',
		 		 :save_to_file => Rails.root + "pdfs/#{filename}.pdf"
      end   
    end
  end

  def print
    @facture = Facture.find(params[:id])
    @famille = Famille.find(@facture.famille_id)
    @mairie  = Ville.find(session[:mairie])
  end 

  def send_invoice
    @facture = Facture.find(params[:id])
    @famille = Famille.find(@facture.famille_id)
    @mairie  = Ville.find(session[:mairie])
    filename = Rails.root + "/pdfs/#{@facture.id.to_s}.pdf"
    if File.exist?(filename) 
       UserMailer.deliver_send_invoice(@mairie, @famille, @facture)
       flash[:notice] = "Facture envoyée."
    else
       redirect_to(:controller => 'factures')
       flash[:notice] = "PDF non créé. Veuillez cliquer sur l'icone PDF pour créer le fichier à envoyer."
    end
    
  end


  # GET /factures/1/edit
  def edit
    @facture = Facture.find(params[:id])
    @paiements = Paiement.find(:all, :order => 'id DESC', 
	:conditions =>  ["famille_id = ? AND mairie_id = ?", @facture.famille_id, session[:mairie]])
  end

  # GET /factures/new
  # GET /factures/new.xml
  def new

  end

  def new_all

  end

  # POST /factures
  # POST /factures.xml
  def create
    if !params[:famille_id]
        nbr_facture = 0
        Famille.find(:all, :conditions => ["mairie_id = ?", session[:mairie]]).each { 
			|famille|
			facture_id = create_facture(famille.id , 0, famille.mairie_id, false, params[:facturer][:mois], params[:facturer][:an], params[:facturer][:commentaire])
			nbr_facture += 1 if facture_id 
		}
		flash[:notice] = "#{nbr_facture} factures créées..."
		redirect_to(:controller => 'factures', :sort => 'id DESC') 
    else 
   		facture_id = create_facture(params[:famille_id], 0, session[:mairie], false, params[:facturer][:mois], params[:facturer][:an], params[:facturer][:commentaire])
 	    if facture_id 
	   		flash[:notice] = 'Facture créée.'
	   		redirect_to(:controller => 'factures', :action => 'print', :id => facture_id)
		else
	   		flash[:warning] = 'Rien à facturer.'
	   		redirect_to(:controller => 'familles', :action => 'show', :id => params[:famille_id])
 	   	end
    end
  end

  # PUT /factures/1
  # PUT /factures/1.xml
  def update
    @facture = Facture.find(params[:id])

    respond_to do |format|
      if @facture.update_attributes(params[:facture])
        flash[:notice] = 'Facture modifée...'
        format.html { redirect_to(factures_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @facture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /factures/1
  # DELETE /factures/1.xml
  def destroy
    @facture = Facture.find(params[:id])
    @facture.facture_lignes.delete_all
    result = Prestation.update_all("facture_id = null", ["facture_id = ?", @facture.id])
    @facture.destroy   

    flash[:notice] = 'Facture supprimée' 

    respond_to do |format|
      format.html { redirect_to(factures_url) }
      format.xml  { head :ok }
    end
  end

end

def create_facture(famille_id, facture_id, mairie_id, draft, mois, an, commentaire)
    
    hash_prestations = {'Repas' => 0,'GarderieAM' => 0.0,'GarderiePM' => 0.0, 'CentreAM' => 0, 'CentrePM' => 0, 'CentreAMPM' => 0, 
		'Etude' => 0, 'MntRepas' => 0,'MntGarderieAM' => 0.0,'MntGarderiePM' => 0.0, 'MntCentreAM' => 0, 'MntCentrePM' => 0, 
		'MntCentreAMPM' => 0, 'MntEtude' => 0, 'PrixRepas' => 0.0,'PrixGarderieAM' => 0.0,
		'PrixGarderiePM' => 0.0, 'PrixCentreAM' => 0.0, 'PrixCentrePM' => 0.0, 'PrixCentreAMPM' => 0.0, 
		'PrixEtude' => 0.0,'JoursRepas' => "",'JoursGarderieAM' => "",'JoursGarderiePM' => "", 
		'JoursCentreAM' =>"", 'JoursCentrePM' => "", 'JoursCentreAMPM' => "", 'JoursEtude' => ""} 

    grand_total = 0.00

    d = Date.new(an.to_i,  mois.to_i , 1)
    date_debut = d.at_beginning_of_month
    date_fin   = d.at_end_of_month
	

    # calcul du solde avant de créer cette facture
    @famille = Famille.find(famille_id)
    @sumP  = @famille.factures.sum('montant')
    @sumIn = @famille.paiements.sum('montant')
    @solde = @sumP - @sumIn  


    @prochain = FactureChrono.find(:first, :conditions => ["mairie_id = ?", mairie_id])
    @facture = Facture.new
    @facture.famille_id = famille_id
    @facture.mairie_id  = mairie_id
    @facture.date = DateTime.now
    @facture.echeance = date_fin
    @facture.ref = "#{date_debut.month.to_s}-#{Date.today.year}/#{@prochain.prochain}"
    @facture.SoldeFamille = @solde
    @facture.checked = false
	@facture.footer = commentaire
    @facture.save
    facture_id = @facture.id

    # pour chaque enfant de la famille
    enfants = Enfant.find_all_by_famille_id(famille_id)
    for enfant in enfants
      total = 0.00

      @prestations = Prestation.find(:all, :conditions => ['enfant_id = ? AND facture_id is null AND (date between ? AND ?)', enfant.id, date_debut, date_fin], :order => "date")      
      if @prestations.size > 0
          # calcul prestations type 1 ' Normale
          prestations_normales = hash_prestations.clone
          for prestation1 in @prestations
              prestations_normales = prestation1.calc_prestation(prestations_normales)
              prestation1.facture_id = facture_id # associe la presta à la facture
              prestation1.totalA = 0.00 # TODO : migration default totalA = 0
              prestation1.save
          end

          # calcul prestations type 3 ' Majoré
          prestations_majorees= hash_prestations.clone
          for prestation3 in @prestations
              prestations_majorees = prestation3.calc_majoration(prestations_majorees)
          end

          # calcul prestations type 2 ' Annulé par la famille
          prestations_annulees= hash_prestations.clone
          for prestation2 in @prestations
              prestations_annulees = prestation2.calc_annulation(prestations_annulees)
          end

          # calcul prestations type 4 ' Annulé maladie
          prestations_annulees_maladie = hash_prestations.clone
          for prestation4 in @prestations
              prestations_annulees_maladie = prestation4.calc_annulation_maladie(prestations_annulees_maladie)
          end
          
          # ajout des prestations
          total_prestations = prestations_normales['MntRepas'] + prestations_normales['MntGarderieAM'] + prestations_normales['MntGarderiePM'] + prestations_normales['MntCentreAM'] + prestations_normales['MntCentrePM'] + prestations_normales['MntCentreAMPM'] + prestations_normales['MntEtude']

          header = "#{format_mois(date_debut.month).upcase} - #{enfant.prenom} "
          FactureLigne.create(:facture_id => facture_id,:texte => header.to_s) 
    
          if total_prestations > 0
              if prestations_normales['Repas'] > 0
                ligne = " Repas: #{prestations_normales['JoursRepas']} #{format_mois(date_debut.month)};"
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['Repas'] ,:montant => prestations_normales['MntRepas'], :prix => prestations_normales['PrixRepas']) 
              end

              if prestations_normales['GarderieAM'] > 0
                ligne =  " Garderie matin: #{prestations_normales['JoursGarderieAM']} #{format_mois(date_debut.month)};"
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['GarderieAM'] ,:montant => prestations_normales['MntGarderieAM'],:prix => prestations_normales['PrixGarderieAM']) 
              end

              if prestations_normales['GarderiePM'] > 0
                ligne =  " Garderie soir: #{prestations_normales['JoursGarderiePM']} #{format_mois(date_debut.month)};"
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['GarderiePM'] ,:montant => prestations_normales['MntGarderiePM'], :prix => prestations_normales['PrixGarderiePM']) 
              end

              if prestations_normales['CentreAM'] > 0
                ligne =  " Centre matin: #{prestations_normales['JoursCentreAM']} #{format_mois(date_debut.month)};" if prestations_normales['CentreAM'] > 0
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['CentreAM'] ,:montant => prestations_normales['MntCentreAM'], :prix => prestations_normales['PrixCentreAM']) 
              end
              
              if prestations_normales['CentrePM'] > 0
                ligne =  " Centre soir: #{prestations_normales['JoursCentrePM']} #{format_mois(date_debut.month)};"
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['CentrePM'] ,:montant => prestations_normales['MntCentrePM'], :prix => prestations_normales['PrixCentrePM'])  
              end
              
              if prestations_normales['CentreAMPM'] > 0
                ligne =  " Centre journée: #{prestations_normales['JoursCentreAMPM']} #{format_mois(date_debut.month)};" if prestations_normales['CentreAMPM'] > 0
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['CentreAMPM'] ,:montant => prestations_normales['MntCentreAMPM'], :prix => prestations_normales['PrixCentreAMPM'])  
              end
              
              if prestations_normales['Etude'] > 0 
                ligne =  " Etude: #{prestations_normales['JoursEtude']} #{format_mois(date_debut.month)};" if prestations_normales['Etude'] > 0
                FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_normales['Etude'] ,:montant => prestations_normales['MntEtude'], :prix => prestations_normales['PrixEtude']) 
              end
          end

          # ajout des majorations
          total_majorations = prestations_majorees['MntRepas'] + prestations_majorees['MntGarderieAM'] + prestations_majorees['MntGarderiePM'] + prestations_majorees['MntCentreAM'] + prestations_majorees['MntCentrePM'] + prestations_majorees['MntCentreAMPM']

          if total_majorations > 0
            if prestations_majorees['Repas'] > 0
              ligne = " Repas majoré: #{prestations_majorees['JoursRepas']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_majorees['Repas'] ,:montant => prestations_majorees['MntRepas'],:prix => prestations_majorees['PrixRepas']) 
            end
            if prestations_majorees['GarderieAM'] > 0
              ligne = " Garderie matin majorée: #{prestations_majorees['JoursGarderieAM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_majorees['GarderieAM'] ,:montant => prestations_majorees['MntGarderieAM'],:prix => prestations_majorees['PrixGarderieAM'])  
            end
            if prestations_majorees['GarderiePM'] > 0
              ligne = " Garderie soir majorée: #{prestations_majorees['JoursGarderiePM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_majorees['GarderiePM'] ,:montant => prestations_majorees['MntGarderiePM'],:prix => prestations_majorees['PrixGarderiePM']) 
            end
            if prestations_majorees['CentreAM'] > 0
              ligne = " Centre matin majoré: #{prestations_majorees['JoursCentreAM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_majorees['CentreAM'] ,:montant => prestations_majorees['MntCentreAM'],:prix => prestations_majorees['PrixCentreAM']) 
            end
            if prestations_majorees['CentrePM'] > 0
              ligne = " Centre soir majoré: #{prestations_majorees['JoursCentrePM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_majorees['CentrePM'] ,:montant => prestations_majorees['MntCentrePM'],:prix => prestations_majorees['PrixCentrePM'])  
            end
            if prestations_majorees['CentreAMPM'] > 0
              ligne = " Centre journée majoré: #{prestations_majorees['JoursCentreAMPM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_majorees['CentreAMPM'] ,:montant => prestations_majorees['MntCentreAMPM'] ,:prix => prestations_majorees['PrixCentreAMPM'])  
            end
          end

          # annulation
          total_annulations = prestations_annulees['MntRepas'] + prestations_annulees['MntGarderieAM'] + prestations_annulees['MntGarderiePM'] + prestations_annulees['MntCentreAM'] + prestations_annulees['MntCentrePM'] + prestations_annulees['MntCentreAMPM']

          if total_annulations < 0
            if prestations_annulees['Repas'] > 0
              ligne = " Repas annulé: #{prestations_annulees['JoursRepas']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees['Repas'] ,:montant => prestations_annulees['MntRepas'] ,:prix => prestations_annulees['PrixRepas'])
            end
            if prestations_annulees['GarderieAM'] > 0
              ligne = " Garderie matin annulée: #{prestations_annulees['JoursGarderieAM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees['GarderieAM'] ,:montant => prestations_annulees['MntGarderieAM'],:prix => prestations_annulees['PrixGarderieAM']) 
            end
            if prestations_annulees['GarderiePM'] > 0
              ligne = " Garderie soir annulée: #{prestations_annulees['JoursGarderiePM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees['GarderiePM'] ,:montant => prestations_annulees['MntGarderiePM'],:prix => prestations_annulees['PrixGarderiePM']) 
            end
            if prestations_annulees['CentreAM'] > 0
              ligne = " Centre matin annulé: #{prestations_annulees['JoursCentreAM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees['CentreAM'] ,:montant => prestations_annulees['MntCentreAM'] ,:prix => prestations_annulees['PrixCentreAM']) 
            end
            if prestations_annulees['CentrePM'] > 0
              ligne = " Centre soir annulé: #{prestations_annulees['JoursCentrePM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees['CentrePM'] ,:montant => prestations_annulees['MntCentrePM'],:prix => prestations_annulees['PrixCentrePM']) 
            end
            if prestations_annulees['CentreAMPM'] > 0
              ligne = " Centre journée annulé: #{prestations_annulees['JoursCentreAMPM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees['CentreAMPM'] ,:montant => prestations_annulees['MntCentreAMPM'],:prix => prestations_annulees['PrixCentreAMPM']) 
            end
          end

          # annulation pour maladie
          total_annulations_maladie = prestations_annulees_maladie['MntRepas'] + prestations_annulees_maladie['MntGarderieAM'] + prestations_annulees_maladie['MntGarderiePM'] + prestations_annulees_maladie['MntCentreAM'] + prestations_annulees_maladie['MntCentrePM'] + prestations_annulees_maladie['MntCentreAMPM']

          if total_annulations_maladie < 0
            if prestations_annulees_maladie['Repas'] > 0
              ligne = " Repas annulé cause maladie: #{prestations_annulees_maladie['JoursRepas']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees_maladie['Repas'] ,:montant => prestations_annulees_maladie['MntRepas'],:prix => prestations_annulees_maladie['PrixRepas'])  
            end
            if prestations_annulees_maladie['GarderieAM'] > 0
              ligne = " Garderie matin annulée cause maladie: #{prestations_annulees_maladie['JoursGarderieAM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees_maladie['GarderieAM'] ,:montant => prestations_annulees_maladie['MntGarderieAM'],:prix => prestations_annulees_maladie['PrixGarderieAM'])  
            end
            if prestations_annulees_maladie['GarderiePM'] > 0
              ligne = " Garderie soir annulée cause maladie: #{prestations_annulees_maladie['JoursGarderiePM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees_maladie['GarderiePM'] ,:montant => prestations_annulees_maladie['MntGarderiePM'], :prix => prestations_annulees_maladie['PrixGarderiePM'])  
            end
            if prestations_annulees_maladie['CentreAM'] > 0
              ligne = " Centre matin annulé cause maladie: #{prestations_annulees_maladie['JoursCentreAM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees_maladie['CentreAM'] ,:montant => prestations_annulees_maladie['MntCentreAM'],:prix => prestations_annulees_maladie['PrixCentreAM'])  
            end
            if prestations_annulees_maladie['CentrePM'] > 0
              ligne = " Centre soir annulé cause maladie: #{prestations_annulees_maladie['JoursCentrePM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees_maladie['CentrePM'] ,:montant => prestations_annulees_maladie['MntCentrePM'],:prix => prestations_annulees_maladie['PrixCentrePM'])  
            end
            if prestations_annulees_maladie['CentreAMPM'] > 0
              ligne = " Centre journée annulé cause maladie: #{prestations_annulees_maladie['JoursCentreAMPM']} #{format_mois(date_debut.month)};"
              FactureLigne.create(:facture_id => facture_id, :texte => ligne.to_s, :qte => prestations_annulees_maladie['CentreAMPM'] ,:montant => prestations_annulees_maladie['MntCentreAMPM'],:prix => prestations_annulees_maladie['PrixCentreAMPM'])  
            end
          end
    
          total += total_prestations
          total += total_majorations
          total += total_annulations
          total += total_annulations_maladie
          grand_total = grand_total + total
        end
    end

    if grand_total > 0	
       @facture.montant    = grand_total
       @facture.save

       # incrémente le N° de facture
       @prochain = FactureChrono.find(:first, :conditions => ["mairie_id = ?", mairie_id])
       @prochain.prochain = @prochain.prochain + 1
       @prochain.save

       return @facture.id
    else
       @facture.destroy
       return nil
    end

end

