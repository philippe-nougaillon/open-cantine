# encoding: utf-8

require "open-uri"

class FacturesController < ApplicationController

  layout :determine_layout
  before_action :check, :except => ['index', 'new', 'new_all', 'create', 'stats_mensuelle_params', 'stats_mensuelle_do', 'facturation_speciale', 'facturation_speciale_do', 'action']

  def check
    unless Facture.where("id = ? AND mairie_id = ?", params[:id], session[:mairie]).any?
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
  # GET /factures.xls
  def index
    unless params[:sort].blank?
      sort = params[:sort]
      if session[:order_by] == sort
         sort = sort.split(" ").last == "DESC" ? sort.split(" ").first : sort + " DESC"   
      end  
      session[:order_by] = sort
    end

    @factures = Facture.search(params[:search],params[:page], session[:mairie], sort, params[:famille_id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => Facture.where(mairie_id:session[:mairie]).to_xml( :include => [:facture_lignes]) }
	    format.xls { @factures = Facture.where(mairie_id:session[:mairie]) }	
    end
  end

  # GET /factures/1
  # GET /factures/1.xml
  def show
    require 'factures.rb'
	  @images = get_etat_images
    @facture = Facture.find(params[:id])
    @famille = Famille.find(@facture.famille_id)
    @mairie  = Ville.find(session[:mairie])
    @prestations = Prestation.where(facture_id:@facture.id).order(:date, :enfant_id)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @facture }
      format.pdf do
 		    pdf = FacturePdf.new([@facture.id])
        send_data pdf.render, :type => "application/pdf", 
				:filename => "Facture_#{@facture.ref}_#{@facture.created_at.strftime("%d/%m/%Y")}.pdf"
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
    @mairie  = Ville.find(session[:mairie])
	
  	pdf = FacturePdf.new([@facture.id])
  	filename = @facture.id.to_s
    save_path = Rails.root.join('pdfs',"#{filename}.pdf")
  	pdf.render_file(save_path) # then save to a file
      
  	UserMailer.send_invoice(@mairie, @facture.famille, @facture).deliver_now
    @facture.envoyee = Time.now
    @facture.log_changes(1, session[:user])
  	@facture.save
  	flash[:notice] = "Facture #{@facture.ref} #{@facture.famille.nom} envoyée."
  	redirect_to factures_path
  end

  # GET /factures/1/edit
  def edit
    @facture = Facture.find(params[:id])
    @paiements = Paiement.where("famille_id = ? AND mairie_id = ?", @facture.famille_id, session[:mairie]).order('id DESC')
  end

  # GET /factures/new
  # GET /factures/new.xml
  def new

  end

  def new_all

  end

  def stats_mensuelle_params

  end


  def stats_mensuelle_do
    mairie = Ville.find(session[:mairie])
  	
    @stats_date = params[:stats][:an] + '-' + params[:stats][:mois] + '-01'
  	@facture_date = @stats_date.to_date
  	
  	@datedebut  = @facture_date.to_date.at_beginning_of_month
  	@datefin = @facture_date.to_date.at_beginning_of_month.next_month

  	@factures = mairie.factures.where("date between ? and ?", @datedebut, @datefin)

  	if @factures.any?
  		@total_cantine = 0.00
  		@total_garderie = 0.00
  		@total_centre = 0.00
  		@total_etude = 0.00
  		for f in @factures
  			@total_cantine += f.total_cantine if f.total_cantine
  			@total_garderie += f.total_garderie if f.total_garderie
  			@total_centre += f.total_centre if f.total_centre
  			@total_etude += f.total_etude if f.total_etude
  		end
  	else
  		flash[:notice] = "Pas de factures trouvées pour ce mois là."
  	end
  end	

  # POST /factures
  # POST /factures.xml
  def create
    mairie = Ville.find(session[:mairie])

    unless params[:famille_id] # Facture de toutes les familles
      nbr_facture = 0
      mairie.familles.each do |famille|
			  facture_id = create_facture(famille.id , 0, famille.mairie_id, false, params[:facturer][:mois], params[:facturer][:an], params[:facturer][:commentaire])
			  nbr_facture += 1 if facture_id 
		  end
		  flash[:notice] = "#{nbr_facture} factures créées avec succès..."
		  redirect_to factures_path, sort:'id DESC' 
    else 
   		facture_id = create_facture(params[:famille_id], 0, mairie.id, false, params[:facturer][:mois], params[:facturer][:an], params[:facturer][:commentaire])
 	    if facture_id 
	   		flash[:notice] = '1 facture créée avec succès...'
        redirect_to factures_path, sort:'id DESC' 
		  else
	   		flash[:warning] = 'Aucune prestation à facturer sur la période choisie.'
	   		redirect_to famille_path(params[:famille_id])
 	   	end
    end
  end

  # PUT /factures/1
  # PUT /factures/1.xml
  def update
    @facture = Facture.find(params[:id])
    @facture.attributes = facture_params 
    @facture.log_changes(1, session[:user])

    respond_to do |format|
      if @facture.save(validate:false)
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
    @facture.log_changes(2, session[:user])
    @facture.facture_lignes.delete_all
    result = Prestation.where(facture_id:@facture.id).update_all(facture_id:nil)
    @facture.destroy   

    flash[:notice] = 'Facture supprimée. Les prestations associées sont à jour.' 

    respond_to do |format|
      format.html { redirect_to(factures_url) }
      format.xml  { head :ok }
    end
  end

  def action
    require 'factures.rb'
    if params[:action_name] == "Générer PDF" and params[:facture_ids]
      pdf = FacturePdf.new(params[:facture_ids].keys)
      send_data pdf.render, type: "application/pdf", filename: "Factures.pdf"
    elsif params[:action_name] == "Envoyer par mail" and params[:facture_ids]
      params[:facture_ids].keys.each do | facture_id |
        @facture = Facture.find(facture_id)
        @mairie  = Ville.find(session[:mairie])
      
        pdf = FacturePdf.new([@facture.id])
        filename = @facture.id.to_s
        save_path = Rails.root.join('pdfs',"#{filename}.pdf")
        pdf.render_file(save_path) # then save to a file
          
        UserMailer.send_invoice(@mairie, @facture.famille, @facture).deliver_now
        @facture.envoyee = Time.now
        @facture.log_changes(1, session[:user])
        @facture.save
      end
      flash[:notice] = "Facture(s) envoyée(s)"
      redirect_to factures_path
    else 
      redirect_to factures_path
    end  
  end

  def facturation_speciale
    @user = User.find(session[:user])
    @familles = @user.ville.familles.order(:nom)
    @facture = Facture.new(mairie_id:@user.mairie_id) 
  end

  def facturation_speciale_do
    @user = User.find(session[:user]) 
    @familles = @user.ville.familles.order(:nom)
    @facture = Facture.new(facture_params)
    prochain = FactureChrono.where(mairie_id:@user.mairie_id).first.prochain
    texte = @facture.ref
    @facture.ref = "#{Date.today.month.to_s}-#{Date.today.year}/#{prochain}"
    @facture.echeance = Date.today.at_end_of_month
    unless params[:facture][:famille_id].blank?
      unless @facture.valid?
        flash[:warning] = "Données insuffisantes pour continuer"
        render action: "Facture_speciale" 
      else
        @facture.log_changes(0, @user.id)
        @facture.save
        FactureLigne.create(facture_id:@facture.id, texte:texte, qte:1, montant:@facture.montant, prix:@facture.montant) 
        FactureChrono.where(mairie_id:@facture.mairie_id).update_all(prochain:prochain + 1)
        flash[:notice] = "1 facture créée avec succès..."
        redirect_to factures_path
      end
    else
      @facture.famille_id = @familles.first.id
      unless @facture.valid?
        flash[:warning] = "Données insuffisantes pour continuer"
        render action: "Facture_speciale" 
      else
        @familles.each do |famille|
            prochain = FactureChrono.where(mairie_id:@facture.mairie_id).first.prochain
            f = @facture.dup
            f.famille_id = famille.id
            f.ref = "#{Date.today.month.to_s}-#{Date.today.year}/#{prochain}" 
            f.log_changes(0, @user.id)
            f.save
            FactureLigne.create(facture_id:f.id, texte:texte, qte:1, montant:f.montant, prix:f.montant)
            FactureChrono.where(mairie_id:@facture.mairie_id).update_all(prochain:prochain + 1)  
        end    
        flash[:notice] = "#{@familles.count} factures créées avec succès..."
        redirect_to factures_path
      end
    end  
  end


  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def facture_params
      params.require(:facture).permit(:famille_id,:reglement_id,:ref,:date,:montant,:echeance,:mairie_id,:SoldeFamille,:checked,:footer,:total_cantine,:total_garderie,:total_centre,:total_etude,:envoyee)
    end

end

def create_facture(famille_id, facture_id, mairie_id, draft, mois, an, commentaire)
    
    hash_prestations = {'Repas' => 0,'GarderieAM' => 0.0,'GarderiePM' => 0.0, 'CentreAM' => 0, 'CentrePM' => 0, 'CentreAMPM' => 0, 
		'Etude' => 0, 'MntRepas' => 0,'MntGarderieAM' => 0.0,'MntGarderiePM' => 0.0, 'MntCentreAM' => 0, 'MntCentrePM' => 0, 
		'MntCentreAMPM' => 0, 'MntEtude' => 0, 'PrixRepas' => 0.0,'PrixGarderieAM' => 0.0,
		'PrixGarderiePM' => 0.0, 'PrixCentreAM' => 0.0, 'PrixCentrePM' => 0.0, 'PrixCentreAMPM' => 0.0, 
		'PrixEtude' => 0.0,'JoursRepas' => "",'JoursGarderieAM' => "",'JoursGarderiePM' => "", 
		'JoursCentreAM' =>"", 'JoursCentrePM' => "", 'JoursCentreAMPM' => "", 'JoursEtude' => ""} 

    total_cantine = 0.00
	  total_garderie = 0.00
	  total_centre = 0.00
	  total_etude = 0.00
    grand_total = 0.00

    d = Date.new(an.to_i,  mois.to_i , 1)
    date_debut = d.at_beginning_of_month
    date_fin   = d.at_end_of_month
	

    # calcul du solde avant de créer cette facture
    @famille = Famille.find(famille_id)
    @sumP  = @famille.factures.sum('montant')
    @sumIn = @famille.paiements.sum('montant')
    @solde = @sumP - @sumIn


    #charge le module Facture de cette mairie
    @mairie = Ville.find(@famille.mairie_id)
    #load "Facture_modules/#{Ville.find(@mairie).FactureModuleName}"       

    @prochain = FactureChrono.find_by(mairie_id:mairie_id)
    @facture = Facture.new
    @facture.famille_id = famille_id
    @facture.mairie_id  = mairie_id
    @facture.date = DateTime.now
    @facture.echeance = date_fin
    @facture.ref = "#{date_debut.month.to_s}-#{Date.today.year}/#{@prochain.prochain}"
    @facture.SoldeFamille = @solde
    @facture.checked = false
	  @facture.footer = commentaire
    @facture.montant = 0
    @facture.save
    facture_id = @facture.id

    # pour chaque enfant de la famille
    enfants = Enfant.where(famille_id:famille_id)
    for enfant in enfants
      tarif = Facture.best_tarif(enfant)
      tarif_majoration = Tarif.where(mairie_id:@mairie.id, type_id:tarif.id).first
      total = 0.00

      @prestations = Prestation.where('enfant_id = ? AND facture_id is null AND (date between ? AND ?)', enfant.id, date_debut, date_fin).order(:date)
      if @prestations.size > 0
          # calcul prestations type 1 ' Normale
          prestations_normales = hash_prestations.clone
          for prestation1 in @prestations
              #prestations_normales = prestation1.calc_prestation(prestations_normales)
              prestations_normales = Facture.calc_prestation(prestations_normales, prestation1, tarif,  prestation1.date.day.to_s)
              prestation1.facture_id = facture_id # associe la presta à la facture
              prestation1.totalA = 0.00 # TODO : migration default totalA = 0
              prestation1.save
          end

          # calcul prestations type 3 ' Majorée
          prestations_majorees= hash_prestations.clone
          for prestation3 in @prestations
              #prestations_majorees = prestation3.calc_majoration(prestations_majorees)
              prestations_majorees = Facture.calc_majoration(prestations_majorees, prestation3, tarif, tarif_majoration, prestation3.date.day.to_s)
          end

          # calcul prestations type 2 ' Annulée par la famille
          prestations_annulees= hash_prestations.clone
          for prestation2 in @prestations
              #prestations_annulees = prestation2.calc_annulation(prestations_annulees)
              prestations_annulees = Facture.calc_annulation(prestations_annulees, prestation2, tarif, prestation2.date.day.to_s)
          end

          # calcul prestations type 4 ' Annulée maladie
          prestations_annulees_maladie = hash_prestations.clone
          for prestation4 in @prestations
              #prestations_annulees_maladie = prestation4.calc_annulation_maladie(prestations_annulees_maladie)
              prestations_annulees_maladie = Facture.calc_annulation_maladie(prestations_annulees_maladie, prestation4, tarif, prestation4.date.day.to_s)  
          end
          
          # ajout des prestations
          total_prestations = prestations_normales['MntRepas'] + prestations_normales['MntGarderieAM'] + prestations_normales['MntGarderiePM'] + prestations_normales['MntCentreAM'] + prestations_normales['MntCentrePM'] + prestations_normales['MntCentreAMPM'] + prestations_normales['MntEtude']

          header = "#{format_mois(date_debut.month).upcase} - #{enfant.nomfamille.upcase} #{enfant.prenom.upcase} (#{Classroom.find(enfant.classe).nom})"
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

		      total_cantine += prestations_normales['MntRepas'] + prestations_majorees['MntRepas'] + prestations_annulees['MntRepas'] + prestations_annulees_maladie['MntRepas']

		      total_garderie += prestations_normales['MntGarderieAM'] + prestations_majorees['MntGarderieAM'] + prestations_annulees['MntGarderieAM'] + prestations_annulees_maladie['MntGarderieAM']

		      total_garderie += prestations_normales['MntGarderiePM'] + prestations_majorees['MntGarderiePM'] + prestations_annulees['MntGarderiePM'] + prestations_annulees_maladie['MntGarderiePM']

		      total_centre += prestations_normales['MntCentreAMPM'] + prestations_majorees['MntCentreAMPM'] + prestations_annulees['MntCentreAMPM'] + prestations_annulees_maladie['MntCentreAMPM']

		      total_centre += prestations_normales['MntCentreAM'] + prestations_majorees['MntCentreAM'] + prestations_annulees['MntCentreAM'] + prestations_annulees_maladie['MntCentreAM']

		      total_centre += prestations_normales['MntCentrePM'] + prestations_majorees['MntCentrePM'] + prestations_annulees['MntCentrePM'] + prestations_annulees_maladie['MntCentrePM']

		      total_etude += prestations_normales['MntEtude'] + prestations_majorees['MntEtude'] + prestations_annulees['MntEtude'] + prestations_annulees_maladie['MntEtude']

        end
    end

    if grand_total > 0	
      @facture.montant  = grand_total
	    @facture.total_cantine = total_cantine
	    @facture.total_garderie = total_garderie
	    @facture.total_centre = total_centre
	    @facture.total_etude = total_etude 
      @facture.log_changes(0, session[:user])
      @facture.save

      # incrémente le N° de facture
      @prochain = FactureChrono.find_by(mairie_id:mairie_id)
      @prochain.prochain = @prochain.prochain + 1
      @prochain.save

      return @facture.id
    else
      @facture.destroy
      return nil
    end

end
