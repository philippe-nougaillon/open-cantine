# encoding: utf-8

class PrestationsController < ApplicationController

  before_filter :check, :only => ['edit', 'edit_from_enfants']
  layout :determine_layout, :except => ['create', 'refresh', 'ajaxupdate', 'new_manual_calc']

  def check
    @presta = Prestation.find(params[:id])
    @enfant = Enfant.find(@presta.enfant_id)
    unless Famille.find(:first, :conditions => [" id = ? AND mairie_id = ?", @enfant.famille_id, session[:mairie]])
       redirect_to :action => 'index'
    end
  rescue
    redirect_to :action => 'index'
  end

  def determine_layout
    if params[:action] == 'print'
      "printer"
    else
      "standard"
    end
  end

  # GET /prestations
  # GET /prestations.xml
  def index
     @images = get_etat_images
     if !params[:classe].blank? and !params[:toutlemois] and session[:user_readwrite]
		session[:date] = params[:prestation_date]
		session[:classe] = params[:classe]
		redirect_to '/presence'
     else
		refresh 	 
	end
  end

  def refresh
     params[:prestation_date] ||= Date.today.to_s(:fr)
     sort_param_in_session(params[:sort] ||= 'date,classe,nom,prenom', params[:page])
     @prestations = Prestation.search(params[:prestation_date], params[:classe], session[:mairie], params[:sort], session[:order], params[:toutlemois])
     @classrooms = Ville.find(session[:mairie]).classrooms
  end

  def print
	 @images = get_etat_images
     @prestations = Prestation.search(params[:search], params[:classe], session[:mairie], 'date,classe,nom,prenom', '', params[:toutlemois])
     @classrooms = Ville.find(session[:mairie]).classrooms
  end

  # GET /prestations/1
  # GET /prestations/1.xml
  def show
    @prestation = Prestation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prestation }
    end
  end

  # GET /prestations/new
  # GET /prestations/new.xml
  def new
    @prestation = Prestation.new
    @prestation.enfant_id = params[:enfant_id] if params[:enfant_id]
    @prestations = Prestation.find(:all)
    @enfants = Enfant.find(:all, :conditions => ["famille_id = ? ", params[:famille_id]]) if params[:famille_id]
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prestation }
    end
  end

  # GET /prestations/1/edit
  def edit
    @prestation = Prestation.find(params[:id])
    @enfant = Enfant.find(@prestation.enfant_id)
    @famille = Famille.find(@enfant.famille_id)
	@images = get_etat_images
  end

  # GET /prestations/1/edit
  def edit_from_enfants
    @prestation = Prestation.find(params[:id])
    params[:enfant_id] = @prestation.enfant_id
    @enfant  = Enfant.find(@prestation.enfant_id)
    @famille = Famille.find(@enfant.famille_id)
    @images = get_etat_images
  end

  def is_weekday?(date)
    date.wday != 0 && date.wday != 6
  end
  
  def days_in_month(date)
    year = date.year
    month = date.month
    d = (Date.new(year, 12, 31) << (12-month)).day
    return d
  end

  # POST /prestations
  # POST /prestations.xml
  def create
    @prestation_foo = Prestation.new(params[:prestation])
	@prestation_date = params[:prestation_date]

    if not @prestation_date.nil?

      unless params[:famille_id].blank?
          @famille_id = params[:famille_id]
          @enfants = Enfant.find_all_by_famille_id(@famille_id)
       else
          @enfants = Enfant.find(:all, :conditions => ["id = ? ", @prestation_foo.enfant_id])
       end

       @enfants.count.times { |i|
          @enfant = @enfants[i]

          start_date = @prestation_date.to_date

          if (params[:toutlemois] or params[:toutelannee]) and (params[:lundi] or params[:mardi] or params[:mercredi] or params[:jeudi] or params[:vendredi])
			   ndays = 5
               
              ndays = days_in_month(start_date) - (start_date.day - 1) if params[:toutlemois]
              ndays = (Date.parse("2013-07-05") - start_date).to_i if params[:toutelannee]
		
               date = start_date
               ndays.times {
                 if is_weekday?(date)
                    # test si date est dans une période de vacance
                    @vacances = Vacance.find(:all, :conditions => ["debut <= ? AND fin >= ? AND mairie_id = ?", date.to_s(:en), date.to_s(:en), session[:mairie]])

                    if (params[:mercredi] and date.wday == 3) or
                       (params[:lundi] and date.wday == 1) or
                       (params[:mardi] and date.wday == 2) or
                       (params[:jeudi] and date.wday == 4) or
                       (params[:vendredi] and date.wday == 5)
                          @prestation = Prestation.new(params[:prestation])
                          @prestation.etude = 0 if date.wday == 3 or not @vacances.empty?
                          @prestation.enfant_id = @enfant.id
			  			  # test si habitude enfant garderie
	       	 	  		  @prestation.garderieAM = @enfant.habitudeGarderieAM if @enfant.habitudeGarderieAM
	       		  		  @prestation.garderiePM = @enfant.habitudeGarderiePM if @enfant.habitudeGarderiePM 
                          @prestation.date = date
                          @prestation.totalP = 0.00
                          @prestation.totalA = 0.00
						  if @prestation.save
					          flash[:notice] = "Prestations ajoutées sur #{ndays} jours"
						  else
					          flash[:warning] = "Prestations ajoutées mais en doublons sur certaines dates.. Veuillez faire une vérification."
						  end
                    end
                 end
                 date = date + 1.day
               }
            else
               @prestation = Prestation.new(params[:prestation])
               @prestation.enfant_id = @enfant.id
	       	   # test si habitude enfant garderie
	       	   @prestation.garderieAM = @enfant.habitudeGarderieAM if @enfant.habitudeGarderieAM
	       	   @prestation.garderiePM = @enfant.habitudeGarderiePM if @enfant.habitudeGarderiePM 
               @prestation.date = @prestation_date
               @prestation.totalP = 0.00
               @prestation.totalA = 0.00
 			   if @prestation.save
		          flash[:notice] = 'Prestation ajoutée.'
			   else
		          flash[:warning] = "Erreur lors de l'ajout des prestation, peut-être en doublon..."
			   end
            end
         }
        flash[:notice] = 'Prestation(s) ajoutée(s).'

        if @famille_id
          redirect_to :controller => 'familles', :action => 'show', :id => @famille_id
        else
          redirect_to :controller => 'prestations', :action => 'new', :enfant_id => @enfant.id
        end
    else
       flash[:warning] = 'Manque date de début...'
       redirect_to :action => "new", :enfant_id => @prestation_foo.enfant_id
    end
  end

  def calendrier



  end


  # PUT /prestations/1
  # PUT /prestations/1.xml
  def update
    @prestation = Prestation.find(params[:id])

    respond_to do |format|
      if @prestation.update_attributes(params[:prestation])
        flash[:notice] = 'Prestation modifiée.'
        format.html { redirect_to :action => 'index'  }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prestation.errors, :status => :unprocessable_entity }
      end
    end
  end

   # GET /prestations/1/edit
  def test
    @prestation = Prestation.find(params[:id])
  end

  def ajaxupdate
    @prestation = Prestation.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  # PUT /prestations/1
  # PUT /prestations/1.xml
  def update_from_enfants
    @prestation = Prestation.find(params[:id])

    respond_to do |format|
      if @prestation.update_attributes(params[:prestation])
        flash[:notice] = 'Prestation modifiée.'
        format.html { redirect_to :controller => 'enfants', :id => @prestation.enfant_id, :action => "show" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prestation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /prestations/1
  # DELETE /prestations/1.xml
  def destroy
    @prestation = Prestation.find(params[:id])
    @prestation.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'enfants', :action => 'show', :id => @prestation.enfant_id }
      format.xml  { head :ok }
    end
  end

  def new_manual
    @mois = params[:mois]
    @year = params[:year]
    if @mois.to_i > 1
       @mois_down = @mois.to_i - 1
       @year_down = @year
    else
       @mois_down = 12
       @year_down = @year.to_i - 1
    end
    if @mois.to_i < 12
       @mois_up = @mois.to_i + 1
       @year_up = @year
    else
       @mois_up = 1
       @year_up = @year.to_i + 1
    end
    date = Date.new(@year.to_i, @mois.to_i, 1)
    @days=[]
    days_in_month(date).times {
      @days.push(date) if is_weekday?(date)
      date = date + 1.day
    }
    if params[:famille_id]
       @famille_id = params[:famille_id]
       @enfants = Enfant.find_by_famille_id(@famille_id)
       @enfant = @enfants[0]	
    else
       @enfant = Enfant.find(params[:id])
    end
    respond_to do |format|
        format.html
        format.js
    end
    
  end

  def new_manual_calc
    @mois = params[:mois]
    @year = params[:year]
    @total = 0.00

    if params[:famille_id]
       @famille_id = params[:famille_id]
       @enfants = Enfant.find_all_by_famille_id(@famille_id)
    else
       @enfants = Enfant.find(:all, :conditions => ["id = ? ", params[:enfant_id]])
    end

    @famille = Famille.find(@enfants[0].famille_id)
    @sumP  = @famille.factures.sum('montant')
    @sumIn = @famille.paiements.sum('montant')
    @solde = @sumIn - @sumP

    @enfants.count.times { |i|
        @enfant = @enfants[i]

	    date = Date.new(@year.to_i, @mois.to_i, 1)
  
        days_in_month(date).times {
          if params[:"#{date.day}RepasAM"] or
             params[:"#{date.day}GarderieAM"] or params[:"#{date.day}GarderiePM"] or
             params[:"#{date.day}CentreAM"] or params[:"#{date.day}CentrePM"] or params[:etude]

             # test si date est dans une période de vacance
             #@vacances = Vacance.find(:all, :conditions => ["debut <= ? AND fin >= ? AND mairie_id = ?", date.to_s(:en), date.to_s(:en), session[:mairie]])

             @prestation = Prestation.new
             @prestation.enfant_id = @enfant.id
             @prestation.date = date
             @prestation.repas = '1' if params[:"#{date.day}RepasAM"]
             @prestation.garderieAM = '1' if params[:"#{date.day}GarderieAM"]
             @prestation.garderiePM = '1' if params[:"#{date.day}GarderiePM"]
             @prestation.centreAM = '1' if params[:"#{date.day}CentreAM"]
             @prestation.centrePM = '1' if params[:"#{date.day}CentrePM"]
             @prestation.etude = '1' if params[:etude] and ( date.wday != 3 and date.wday != 6 and date.wday != 0 and @vacances.empty?)
             @prestation.totalA = 0.00

             # calcul prestations type 1 ' Normale
             nbr_prestation = {'Repas' => 0,'GarderieAM' => 0,'GarderiePM' => 0, 'CentreAM' => 0, 'CentrePM' => 0, 'CentreAMPM' => 0, 'Etude' => 0, 'MntRepas' => 0,'MntGarderieAM' => 0,'MntGarderiePM' => 0, 'MntCentreAM' => 0, 'MntCentrePM' => 0, 'MntCentreAMPM' => 0, 'MntEtude' => 0 ,'JoursRepas' => "",'JoursGarderieAM' => "",'JoursGarderiePM' => "", 'JoursCentreAM' =>"", 'JoursCentrePM' => "", 'JoursCentreAMPM' => "", 'JoursEtude' => "",'PrixCentreAMPM' => 0, 'PrixCentreAM' => 0, 'PrixCentrePM' => 0}

             nbr_prestation = @prestation.calc_prestation(nbr_prestation)
             
             total_prestations = nbr_prestation['MntRepas'] + nbr_prestation['MntGarderieAM'] + nbr_prestation['MntGarderiePM'] + nbr_prestation['MntCentreAM'] + nbr_prestation['MntCentrePM'] + nbr_prestation['MntCentreAMPM'] + nbr_prestation['Etude']
             @total = @total + total_prestations
             @prestation.totalP = total_prestations
	     @tarif = @prestation.tarif
	             
	    #if params[:enregistre] and (date.wday != 6 and date.wday != 0)	
		begin
		   @prestation.save!
		rescue ActiveRecord::RecordInvalid => error
		   #Doublon de prestation ?	
		   logger.info(error)
		   @prestation_originale = Prestation.find(:first , :conditions => ["enfant_id = ? and date = ?", @enfant.id, date])	
		   #On sauvegarde si pas facturée
		   if @prestation_originale.facture_id.nil?	
		      @prestation_originale.update_attribute(:repas, @prestation.repas)  
		      @prestation_originale.update_attribute(:garderieAM , @prestation.garderieAM)
		      @prestation_originale.update_attribute(:garderiePM , @prestation.garderiePM)		

		      @prestation_originale.update_attribute(:centreAM , @prestation.centreAM)
		      @prestation_originale.update_attribute(:centrePM , @prestation.centrePM)
		   end
 		end
	     end
          #end
          date = date + 1.day
        }
    }

    respond_to do |format|
       format.html
	   format.js
 	end
  end

  def new_manual_classroom
	@date = session[:date]
	@classe = session[:classe]

    @kids_to_show=[]
	@kids_to_show_presta=[]

	@enfants = Enfant.find_all_by_classe(@classe, :joins =>:famille, :order => 'nom')
	@enfants.each do |e|
		@kids_to_show.push(e)
		@presta = e.prestations.where("date = ? and facture_id is null", @date.to_date.to_s(:en)).last
		if @presta
		   @kids_to_show_presta.push(@presta)
		else
		   @kids_to_show_presta.push(nil)
		end
    end
    respond_to do |format|
        format.html
        format.js
    end
  end
  
  def new_manual_classroom_check
	@date   = session[:date] 
	@classe = session[:classe] 

	@enfants = Enfant.find_all_by_classe(@classe, :joins =>:famille, :order => 'nom')

	@enfants.each do |e|
		if params[:"#{e.id}RepasAM"] or params[:"#{e.id}GarderieAM"] or params[:"#{e.id}GarderiePM"] or params[:"#{e.id}CentreAM"] or params[:"#{e.id}CentrePM"] then
			@prestation = Prestation.find_or_create_by_date_and_enfant_id(@date.to_date.to_s(:en), e.id)
		    @prestation.repas = params[:"#{e.id}RepasAM"] ? '1' : '0'
		    @prestation.garderieAM = params[:"#{e.id}GarderieAM"] ? '1' : '0'
		    @prestation.garderiePM = params[:"#{e.id}GarderiePM"] ? '1' : '0'
		    @prestation.centreAM = params[:"#{e.id}CentreAM"] ? '1' : '0'
		    @prestation.centrePM = params[:"#{e.id}CentrePM"] ? '1' : '0'
			@prestation.save
		end
	end
	respond_to do |format|
        format.html
        format.js
    end
  end 

  def stats_mensuelle_params
	@classrooms = Ville.find(session[:mairie]).classrooms
  end

  def stats_mensuelle
	@stats_date = params[:stats][:an] + '-' + params[:stats][:mois] + '-01'
	@prestation_date = @stats_date.to_date
	@prestations = Prestation.search(@prestation_date, params[:stats][:classe], session[:mairie], 'nom,prenom', '', true)
	
	if @prestations.first
		@classrooms = Ville.find(session[:mairie]).classrooms
		@datedebut  = @prestation_date.to_date.at_beginning_of_month
		@datefin = @prestation_date.to_date.at_end_of_month	
		@classe = @prestations.first.enfant.classe
		@enfant_id = @prestations.first.enfant.id
	else
		flash[:notice] = "Pas de prestations ce mois là."
		redirect_to "/prestations/stats_mensuelle_params/0"
	end
  end	

end
